#!/bin/bash
set -euo pipefail
umask 077
BACKUP_DIR="/var/backups/etudiants/suppressions"
LOG_FILE="/var/log/suppression_comptes.log"

usage() {
    echo "Usage : sudo bash supprimer_comptes.sh [CSV_FILE] [-n]"
    echo "Supprime les comptes du fichier CSV apres sauvegarde de leurs homes."
    echo "-h, --help : afficher cette aide"
    echo "-n : simulation sans suppression ni sauvegarde"
}

if [[ "$EUID" -ne 0 ]]; then
    echo "Erreur : executez ce script avec sudo."
    exit 1
fi

CSV_FILE="data/etudiants.csv"
SIMULATION=false

for arg in "$@"; do
    case "$arg" in
        -h|--help)
            usage
            exit 0
            ;;
        -n)
            SIMULATION=true
            ;;
        *)
            CSV_FILE="$arg"
            ;;
    esac
done

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Erreur : fichier CSV introuvable : $CSV_FILE"
    exit 2
fi

if [[ "$SIMULATION" == false ]]; then
    mkdir -p "$BACKUP_DIR"
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
fi

DELETED=0
SIMULATED=0
IGNORED=0
ERRORS=0

log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message"

    if [[ "$SIMULATION" == false ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_FILE"
    fi
}

while IFS=';' read -r login _; do
    login="${login//$'\r'/}"

    if [[ "$login" == "login" || -z "$login" ]]; then
        continue
    fi

    if [[ ! "$login" =~ ^[a-z0-9]{3,16}$ ]]; then
        log_message "Ignore : login invalide ($login)."
        ((IGNORED+=1))
        continue
    fi

    if ! id "$login" &>/dev/null; then
        log_message "Ignore : utilisateur $login inexistant."
        ((IGNORED+=1))
        continue
    fi

    if [[ "$SIMULATION" == true ]]; then
        log_message "[SIMULATION] Sauvegarde puis suppression prevues pour $login."
        ((SIMULATED+=1))
        continue
    fi

    if [[ -d "/home/$login" ]]; then
        ARCHIVE="$BACKUP_DIR/${login}_$(date '+%Y%m%d_%H%M%S').tar.gz"

        if ! tar -czf "$ARCHIVE" -C /home "$login"; then
            log_message "Erreur : sauvegarde de $login impossible. Compte conserve."
            ((ERRORS+=1))
            continue
        fi
    fi

    if userdel -r "$login"; then
        log_message "Compte $login supprime apres sauvegarde."
        ((DELETED+=1))
    else
        log_message "Erreur : suppression de $login impossible."
        ((ERRORS+=1))
    fi

done < "$CSV_FILE"

if [[ "$SIMULATION" == true ]]; then
    log_message "Bilan : $SIMULATED suppression(s) simulee(s), $IGNORED ignore(s), $ERRORS erreur(s)."
else
    log_message "Bilan : $DELETED supprime(s), $IGNORED ignore(s), $ERRORS erreur(s)."
fi

if (( ERRORS > 0 )); then
    exit 1
fi

exit 0

#!/bin/bash
# creer_comptes.sh : création automatique des comptes étudiants depuis un CSV.
# Usage : sudo bash creer_comptes.sh [-n] fichier.csv
# -n : mode simulation sans modification du système.
# Codes de sortie : 0 = succès, 1 = erreur, 2 = mauvais usage.

set -euo pipefail
umask 077

# Fichiers et répertoires utilisés.
LOG_FILE="/var/log/creer_comptes.log"
CREDENTIALS_FILE="/root/etudiants_credentials.txt"
GROUPS_DIR="/srv/groupes"

# Initialisation.
SIMULATION=false
CREATED=0
IGNORED=0
ERRORS=0

# Vérifier les privilèges administrateur.
if [[ "$EUID" -ne 0 ]]; then
    echo "Erreur : ce script doit etre execute avec sudo." >&2
    exit 1
fi

# Activer le mode simulation.
if [[ "${1:-}" == "-n" ]]; then
    SIMULATION=true
    shift
fi

# Vérifier les arguments.
if [[ $# -ne 1 ]]; then
    echo "Usage : sudo bash $0 [-n] fichier.csv" >&2
    exit 2
fi

CSV_FILE="$1"

# Vérifier le fichier CSV.
if [[ ! -f "$CSV_FILE" || ! -r "$CSV_FILE" ]]; then
    echo "Erreur : fichier CSV introuvable ou illisible." >&2
    exit 2
fi

# Préparer les fichiers sécurisés hors simulation.
if [[ "$SIMULATION" == false ]]; then
    touch "$LOG_FILE" "$CREDENTIALS_FILE"
    chmod 600 "$LOG_FILE" "$CREDENTIALS_FILE"
    mkdir -p "$GROUPS_DIR"
fi

# Afficher et enregistrer les messages.
log_message() {
    local message="$1"

    if [[ "$SIMULATION" == true ]]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
    fi
}

# Traiter le fichier CSV.
while IFS=';' read -r login nom prenom groupe || [[ -n "${login:-}" ]]; do

    # Nettoyer les caractères Windows CRLF.
    login="${login%$'\r'}"
    nom="${nom%$'\r'}"
    prenom="${prenom%$'\r'}"
    groupe="${groupe%$'\r'}"

    # Ignorer l'en-tête et les lignes vides.
    [[ "${login:-}" == "login" ]] && continue
    [[ -z "${login:-}" ]] && continue

    # Vérifier les champs obligatoires.
    if [[ -z "${nom:-}" || -z "${prenom:-}" || -z "${groupe:-}" ]]; then
        log_message "Erreur : ligne CSV incomplete pour $login."
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # Vérifier le format du login.
    if [[ ! "$login" =~ ^[a-z0-9]{3,16}$ ]]; then
        log_message "Erreur : format du login $login invalide."
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # Vérifier le nom du groupe.
    if [[ ! "$groupe" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_message "Erreur : nom du groupe $groupe invalide."
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # Créer le groupe s'il n'existe pas.
    if ! getent group "$groupe" >/dev/null; then
        if [[ "$SIMULATION" == true ]]; then
            log_message "[SIMULATION] Creation du groupe $groupe."
        elif groupadd "$groupe"; then
            log_message "Groupe $groupe cree."
        else
            log_message "Erreur : creation du groupe $groupe impossible."
            ERRORS=$((ERRORS + 1))
            continue
        fi
    fi

    # Préparer le répertoire partagé du groupe.
    GROUP_DIR="$GROUPS_DIR/$groupe"

    if [[ "$SIMULATION" == true ]]; then
        log_message "[SIMULATION] Preparation du repertoire $GROUP_DIR avec les droits 2770 et SGID."
    else
        if mkdir -p "$GROUP_DIR" &&
           chown "root:$groupe" "$GROUP_DIR" &&
           chmod 2770 "$GROUP_DIR"; then
            log_message "Repertoire partage $GROUP_DIR configure."
        else
            log_message "Erreur : configuration du repertoire $GROUP_DIR."
            ERRORS=$((ERRORS + 1))
            continue
        fi
    fi

    # Ignorer les utilisateurs déjà existants.
    if id "$login" &>/dev/null; then
        log_message "Ignore : utilisateur $login existe deja."
        IGNORED=$((IGNORED + 1))
        continue
    fi

    # Mode simulation.
    if [[ "$SIMULATION" == true ]]; then
        log_message "[SIMULATION] Creation de l'utilisateur $login."
        log_message "[SIMULATION] Configuration du mot de passe et du repertoire personnel en 700."
        CREATED=$((CREATED + 1))
        continue
    fi

    # Générer un mot de passe aléatoire.
    if ! password=$(openssl rand -base64 12); then
        log_message "Erreur : generation du mot de passe pour $login."
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # Créer le compte utilisateur.
    if useradd -m -s /bin/bash -c "$prenom $nom" -g "$groupe" "$login"; then

        # Configurer le mot de passe et les droits du répertoire personnel.
        if printf '%s:%s\n' "$login" "$password" | chpasswd &&
           chage -d 0 "$login" &&
           chmod 700 "/home/$login"; then

            # Enregistrer les identifiants sans les afficher.
            if printf '%s;%s\n' "$login" "$password" >> "$CREDENTIALS_FILE"; then
                log_message "Utilisateur $login cree avec succes."
                CREATED=$((CREATED + 1))
            else
                log_message "Erreur : enregistrement des identifiants de $login."
                ERRORS=$((ERRORS + 1))
            fi
        else
            log_message "Erreur : configuration du compte $login."
            ERRORS=$((ERRORS + 1))
        fi
    else
        log_message "Erreur : creation du compte $login impossible."
        ERRORS=$((ERRORS + 1))
    fi

done < "$CSV_FILE"

# Afficher le bilan final.
log_message "Bilan : $CREATED cree(s), $IGNORED ignore(s), $ERRORS erreur(s)."

# Code de sortie final.
if [[ "$ERRORS" -gt 0 ]]; then
    exit 1
fi

exit 0

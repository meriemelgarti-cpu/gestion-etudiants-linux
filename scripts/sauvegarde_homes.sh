#!/bin/bash
set -euo pipefail

# Proteger les fichiers de sauvegarde.
umask 077

# Définir les chemins utilisés.
BACKUP_DIR="/var/backups/etudiants"
LOG_FILE="/var/log/sauvegarde_homes.log"

# Vérifier les droits administrateur.
if [[ "$EUID" -ne 0 ]]; then
    echo "Erreur : ce script doit etre execute avec sudo."
    exit 1
fi

# Vérifier la présence des répertoires à sauvegarder.
if [[ ! -d /home || ! -d /srv/groupes ]]; then
    echo "Erreur : repertoire /home ou /srv/groupes introuvable."
    exit 1
fi

# Créer et protéger le répertoire de sauvegarde.
mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# Préparer le fichier journal.
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"

# Fonction de journalisation.
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Générer le nom de l'archive.
DATE=$(date +%Y%m%d_%H%M%S)
ARCHIVE="$BACKUP_DIR/sauvegarde_$DATE.tar.gz"
TEMP_ARCHIVE="$ARCHIVE.tmp"

# Enregistrer le début de la sauvegarde.
log_message "Debut de la sauvegarde."

# Créer l'archive temporaire.
if tar -czf "$TEMP_ARCHIVE" /home /srv/groupes 2>/dev/null; then

    # Vérifier l'intégrité de l'archive.
    if tar -tzf "$TEMP_ARCHIVE" >/dev/null 2>&1; then
        mv "$TEMP_ARCHIVE" "$ARCHIVE"
        chmod 600 "$ARCHIVE"
        log_message "Sauvegarde reussie : $ARCHIVE"
    else
        rm -f "$TEMP_ARCHIVE"
        log_message "Erreur : archive invalide."
        exit 1
    fi

else
    # Supprimer l'archive incomplète en cas d'échec.
    rm -f "$TEMP_ARCHIVE"
    log_message "Erreur pendant la sauvegarde."
    exit 1
fi

# Conserver uniquement les sept archives les plus récentes.
find "$BACKUP_DIR" -maxdepth 1 -type f \
    -name 'sauvegarde_*.tar.gz' -printf '%T@ %p\n' |
    sort -rn |
    tail -n +8 |
    cut -d' ' -f2- |
    while IFS= read -r file; do
        rm -f -- "$file"
        log_message "Ancienne sauvegarde supprimee : $file"
    done

# Enregistrer la fin de l'opération.
log_message "Fin de la sauvegarde."
echo "Sauvegarde terminee : $ARCHIVE"

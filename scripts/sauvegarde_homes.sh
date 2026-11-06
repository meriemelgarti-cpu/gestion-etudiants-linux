#!/bin/bash
set -euo pipefail

# Protéger les nouvelles sauvegardes avec des permissions restrictives.
umask 077

# Définir le répertoire de sauvegarde et le fichier journal.
BACKUP_DIR="/var/backups/etudiants"
LOG_FILE="/var/log/sauvegarde_homes.log"

# Générer une date pour donner un nom unique à chaque archive.
DATE=$(date +%Y%m%d_%H%M%S)
ARCHIVE="$BACKUP_DIR/sauvegarde_$DATE.tar.gz"

# Vérifier que le script est exécuté avec les droits administrateur.
if [[ $EUID -ne 0 ]]; then
    echo "Erreur : ce script doit etre execute avec sudo."
    exit 1
fi

# Créer le répertoire de sauvegarde s'il n'existe pas.
mkdir -p "$BACKUP_DIR"

# Enregistrer le début de l'opération dans le journal.
echo "$(date '+%Y-%m-%d %H:%M:%S') - Debut de la sauvegarde" >> "$LOG_FILE"

# Compresser les répertoires personnels et les répertoires partagés.
if tar -czf "$ARCHIVE" /home /srv/groupes 2>/dev/null; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Sauvegarde reussie : $ARCHIVE" >> "$LOG_FILE"
else
    # Enregistrer l'erreur si la sauvegarde échoue.
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Erreur pendant la sauvegarde" >> "$LOG_FILE"
    exit 1
fi

# Conserver uniquement les sept sauvegardes les plus récentes.
# Supprimer les archives plus anciennes.
find "$BACKUP_DIR" -maxdepth 1 -type f -name 'sauvegarde_*.tar.gz' -printf '%T@ %p\n' |
    sort -rn |
    tail -n +8 |
    cut -d' ' -f2- |
    while IFS= read -r file; do
        rm -f -- "$file"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - Ancienne sauvegarde supprimee : $file" >> "$LOG_FILE"
    done

# Enregistrer la fin de l'opération et afficher le résultat.
echo "$(date '+%Y-%m-%d %H:%M:%S') - Fin de la sauvegarde" >> "$LOG_FILE"
echo "Sauvegarde terminee : $ARCHIVE"

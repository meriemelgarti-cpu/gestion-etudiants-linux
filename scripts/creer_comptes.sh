#!/bin/bash

# Fichiers utilisés pour enregistrer les journaux et les identifiants.
LOG_FILE="/var/log/creer_comptes.log"
CREDENTIALS_FILE="/root/etudiants_credentials.txt"

# Initialisation du mode simulation et du fichier CSV.
SIMULATION=false
CSV_FILE=""

# Compteurs pour le bilan final.
CREATED=0
IGNORED=0
ERRORS=0

# Vérification des privilèges administrateur.
if [[ $EUID -ne 0 ]]; then
    echo "Erreur : ce script doit être exécuté avec sudo."
    exit 1
fi

# Activation du mode simulation avec l'option -n.
if [[ "$1" == "-n" ]]; then
    SIMULATION=true
    shift
fi

# Vérification du nombre d'arguments.
if [[ $# -ne 1 ]]; then
    echo "Usage : sudo $0 [-n] fichier.csv"
    exit 2
fi

# Récupération du chemin du fichier CSV.
CSV_FILE="$1"

# Vérification de l'existence du fichier CSV.
if [[ ! -f "$CSV_FILE" ]]; then
    echo "Erreur : fichier CSV introuvable."
    exit 2
fi

# Préparation des fichiers de journalisation et des identifiants.
if [[ "$SIMULATION" == false ]]; then
    touch "$LOG_FILE"
    chmod 600 "$LOG_FILE"
    touch "$CREDENTIALS_FILE"
    chmod 600 "$CREDENTIALS_FILE"
fi

# Fonction permettant d'afficher et d'enregistrer les messages.
log_message() {
    local message="$1"

    if [[ "$SIMULATION" == true ]]; then
        echo "$message"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" | tee -a "$LOG_FILE"
    fi
}

# Lecture du fichier CSV ligne par ligne avec le séparateur point-virgule.
while IFS=';' read -r login nom prenom groupe || [[ -n "$login" ]]; do

    # Ignorer l'en-tête et les lignes vides.
    [[ "$login" == "login" ]] && continue
    [[ -z "$login" ]] && continue

    # Vérifier que toutes les informations obligatoires sont présentes.
    if [[ -z "$nom" || -z "$prenom" || -z "$groupe" ]]; then
        log_message "Erreur : ligne CSV incomplete pour $login"
        ((ERRORS++))
        continue
    fi

    # Vérifier si le compte utilisateur existe déjà.
    if id "$login" &>/dev/null; then
        log_message "Ignore : utilisateur $login existe deja."
        ((IGNORED++))
        continue
    fi

    # En mode simulation, afficher l'action sans créer de compte.
    if [[ "$SIMULATION" == true ]]; then
        log_message "[SIMULATION] Creation de $login dans le groupe $groupe"
        ((CREATED++))
        continue
    fi

    # Créer le groupe s'il n'existe pas déjà.
    if ! getent group "$groupe" >/dev/null; then
        if ! groupadd "$groupe"; then
            log_message "Erreur : creation du groupe $groupe impossible."
            ((ERRORS++))
            continue
        fi
    fi

    # Générer un mot de passe aléatoire pour le nouvel utilisateur.
    password=$(openssl rand -base64 12)

    # Créer le compte avec son répertoire personnel et son groupe principal.
    if useradd -m -s /bin/bash -c "$prenom $nom" -g "$groupe" "$login"; then

        # Définir le mot de passe, imposer son changement et protéger le home.
        if echo "$login:$password" | chpasswd &&
           chage -d 0 "$login" &&
           chmod 700 "/home/$login"; then

            # Enregistrer les identifiants dans le fichier sécurisé.
            echo "$login:$password" >> "$CREDENTIALS_FILE"
            log_message "Utilisateur $login cree avec succes."
            ((CREATED++))
        else
            log_message "Erreur : configuration du compte $login."
            ((ERRORS++))
        fi
    else
        log_message "Erreur : creation du compte $login impossible."
        ((ERRORS++))
    fi

# Fin du traitement du fichier CSV.
done < "$CSV_FILE"

# Afficher le bilan final des opérations.
log_message "Bilan : $CREATED cree(s), $IGNORED ignore(s), $ERRORS erreur(s)."

#!/bin/bash

# Vérifier que le script est exécuté avec les droits administrateur.
if [[ $EUID -ne 0 ]]; then
    echo "Erreur : executez ce script avec sudo."
    exit 1
fi

# Afficher l'aide si l'utilisateur demande -h ou --help.
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage : sudo bash supprimer_etudiant.sh LOGIN"
    echo "Supprime un compte etudiant et son repertoire personnel."
    exit 0
fi

# Vérifier qu'un seul argument (le login) a été fourni.
if [[ $# -ne 1 ]]; then
    echo "Erreur : vous devez indiquer un login."
    echo "Usage : sudo bash supprimer_etudiant.sh LOGIN"
    exit 1
fi

# Récupérer le login à supprimer.
LOGIN="$1"

# Vérifier le format du login : lettres minuscules et chiffres, de 3 à 16 caractères.
if [[ ! "$LOGIN" =~ ^[a-z0-9]{3,16}$ ]]; then
    echo "Erreur : login invalide."
    exit 1
fi

# Vérifier que le compte utilisateur existe.
if ! id "$LOGIN" &>/dev/null; then
    echo "Erreur : cet utilisateur n'existe pas."
    exit 1
fi

# Demander une confirmation avant la suppression définitive.
read -r -p "Confirmer la suppression de $LOGIN ? (oui/non) : " REPONSE

# Annuler l'opération si la réponse n'est pas exactement "oui".
if [[ "$REPONSE" != "oui" ]]; then
    echo "Suppression annulee."
    exit 0
fi

# Supprimer le compte utilisateur ainsi que son répertoire personnel.
if userdel -r "$LOGIN"; then
    echo "Compte $LOGIN supprime avec succes."
else
    echo "Erreur pendant la suppression."
    exit 1
fi

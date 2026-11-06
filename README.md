# Projet : Gestion des étudiants sous Linux

## 1. Présentation
Ce projet permet d'automatiser la gestion des comptes étudiants sous Linux à l'aide de scripts Bash.

## 2. Objectifs
- Créer automatiquement les comptes étudiants.
- Organiser les étudiants par groupes.
- Sécuriser les répertoires personnels.
- Supprimer les comptes étudiants.
- Sauvegarder les répertoires personnels.
- Automatiser les sauvegardes avec Cron.

## 3. Organisation du projet

- data/ : contient le fichier CSV des étudiants.
- scripts/ : contient les scripts Bash.
- docs/ : contient la documentation du projet.

## 4. Scripts utilisés

### creer_comptes.sh

Permet de créer les comptes étudiants à partir d'un fichier CSV et de les affecter à leurs groupes, avec génération de mots de passe.

### supprimer_etudiant.sh

Permet de supprimer un seul compte étudiant.

### supprimer_comptes.sh (Bonus)

Permet de supprimer plusieurs comptes à partir d'un fichier CSV, après avoir sauvegardé leurs répertoires personnels (Home). Il propose également un mode simulation (-n) et une option d'aide (-h).

### sauvegarde_homes.sh

Permet de sauvegarder les répertoires personnels des utilisateurs et de conserver les dernières archives.

## 5. Gestion des groupes
Les étudiants sont répartis dans les groupes gi1 et gi2.

Les répertoires partagés sont :
- /srv/groupes/gi1
- /srv/groupes/gi2

Le bit SGID est activé avec la permission 2770 afin que les fichiers créés héritent du groupe du répertoire.

## 6. Automatisation avec Cron
Une tâche planifiée est configurée pour lancer la sauvegarde chaque jour à 02:00.

## 7. Sécurité
- Les répertoires personnels sont protégés avec la permission 700.
- Le fichier des identifiants est protégé avec la permission 600.
- Les répertoires partagés sont accessibles uniquement aux membres du groupe concerné.

## 8. Vérification

Les quatre scripts ont été vérifiés avec :

- `bash -n`
- `ShellCheck`

La syntaxe des quatre scripts est correcte et ShellCheck n'a signalé aucun avertissement.

## 9. Conclusion
Ce projet permet de simplifier l'administration des comptes étudiants, d'organiser les accès par groupes et d'automatiser les sauvegardes dans un environnement Linux.

## Réalisé par
- El Garti Meriem (Monôme)

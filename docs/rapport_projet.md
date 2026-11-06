# Rapport de projet : Gestion des étudiants sous Linux

## 1. Introduction
Ce projet consiste à automatiser la gestion des comptes étudiants dans un environnement Linux à l'aide de scripts Bash.

## 2. Objectifs
- Créer automatiquement les comptes étudiants.
- Organiser les étudiants en groupes.
- Gérer les permissions et les accès.
- Supprimer les comptes étudiants.
- Sauvegarder les répertoires personnels.
- Automatiser les sauvegardes avec Cron.

## 3. Environnement de travail
- Système d'exploitation : Ubuntu Linux
- Environnement virtuel : VirtualBox
- Langage de programmation : Bash
- Outils : Cron, tar, ShellCheck et commandes Linux.

## 4. Organisation du projet
- data/etudiants.csv : fichier contenant les informations des étudiants.
- scripts/creer_comptes.sh : création des comptes.
- scripts/supprimer_etudiant.sh : suppression des comptes.
- scripts/sauvegarde_homes.sh : sauvegarde des répertoires.
- docs/ : documentation du projet.
- README.md : présentation générale du projet.

## 5. Gestion des comptes et des groupes
Les comptes étudiants sont créés à partir du fichier CSV.
Les étudiants sont répartis dans deux groupes :
- gi1
- gi2

Les répertoires personnels sont protégés avec la permission 700.

Le fichier contenant les identifiants est protégé avec la permission 600.

## 6. Répertoires partagés et SGID
Deux répertoires partagés ont été créés :
- /srv/groupes/gi1
- /srv/groupes/gi2

La permission 2770 est utilisée pour activer le bit SGID.
Ainsi, les fichiers créés dans chaque répertoire héritent du groupe associé.

## 7. Sauvegarde
Le script sauvegarde les répertoires /home et /srv/groupes dans :
/var/backups/etudiants

Les archives sont compressées au format tar.gz.
Les opérations sont enregistrées dans un fichier journal.
Le script conserve les sept sauvegardes les plus récentes.

La commande umask 077 protège les nouvelles sauvegardes.

## 8. Automatisation avec Cron
Une tâche planifiée est configurée pour exécuter le script de sauvegarde chaque jour à 02:00.

La commande utilisée pour vérifier la tâche est :
sudo crontab -l

Le service Cron a été vérifié et fonctionne.

## 9. Tests et vérifications
Les vérifications suivantes ont été effectuées :
- Simulation de création des comptes.
- Vérification des comptes et des groupes.
- Vérification des permissions des répertoires.
- Test du bit SGID.
- Exécution du script de sauvegarde.
- Vérification de la présence des archives.
- Vérification de l'intégrité d'une archive avec tar -tzf.
- Vérification de la syntaxe avec bash -n.
- Analyse des scripts avec ShellCheck.

Les scripts ne présentent aucune erreur de syntaxe ni aucun avertissement ShellCheck.

## 10. Conclusion
Ce projet permet de faciliter l'administration des comptes étudiants sous Linux.
Il améliore l'organisation des utilisateurs, la sécurité des accès et la protection des données grâce aux sauvegardes automatisées.

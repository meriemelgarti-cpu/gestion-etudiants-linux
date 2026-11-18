# Rapport de projet : Gestion des étudiants sous Linux

**Réalisé par : El Garti Meriem (Monôme)**

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

- Système d'exploitation : Ubuntu Linux.
- Environnement virtuel : VirtualBox.
- Langage de programmation : Bash.
- Outils : Cron, tar, ShellCheck et commandes Linux.

## 4. Organisation du projet

- `data/etudiants.csv` : fichier contenant les informations des étudiants.
- `scripts/creer_comptes.sh` : création des comptes.
- `scripts/supprimer_etudiant.sh` : suppression des comptes.
- `scripts/sauvegarde_homes.sh` : sauvegarde des répertoires.
- `docs/` : documentation du projet.
- `README.md` : présentation générale du projet.

## 5. Gestion des comptes et des groupes

Les comptes étudiants sont créés à partir du fichier CSV. Les étudiants sont répartis dans deux groupes :

- gi1
- gi2

Les répertoires personnels sont protégés avec la permission 700.

Le fichier contenant les identifiants est protégé avec la permission 600.

## 6. Répertoires partagés et SGID

Deux répertoires partagés ont été créés :

- `/srv/groupes/gi1`
- `/srv/groupes/gi2`

La permission 2770 est utilisée pour activer le bit SGID. Ainsi, les fichiers créés dans chaque répertoire héritent du groupe associé.

## 7. Sauvegarde

Le script sauvegarde les répertoires `/home` et `/srv/groupes` dans :

`/var/backups/etudiants`

Les archives sont compressées au format tar.gz. Les opérations sont enregistrées dans un fichier journal.

Le script conserve les sept sauvegardes les plus récentes.

La commande `umask 077` protège les nouvelles sauvegardes.

## 8. Automatisation avec Cron

Une tâche planifiée permet d'exécuter le script de sauvegarde chaque jour à 02:00.

Ligne utilisée dans la crontab de root :

```bash
0 2 * * * /bin/bash /home/maryam/projet_gestion_etudiants/scripts/sauvegarde_homes.sh
```

La commande utilisée pour vérifier la tâche est :

```bash
sudo crontab -l
```

Le service Cron a été vérifié et fonctionne.

## 9. Mode d'emploi des scripts

**Création des comptes :**

```bash
sudo bash scripts/creer_comptes.sh data/etudiants.csv
```

**Simulation sans création réelle :**

```bash
sudo bash scripts/creer_comptes.sh -n data/etudiants.csv
```

**Sauvegarde des répertoires :**

```bash
sudo bash scripts/sauvegarde_homes.sh
```

**Suppression d'un compte (bonus) :**

```bash
sudo bash scripts/supprimer_etudiant.sh login
```

## 10. Tests et vérifications

Les vérifications suivantes ont été effectuées :

- Test de création des comptes étudiants.
- Simulation de création avec l'option `-n`.
- Test d'un cas d'erreur.
- Vérification des comptes et des groupes.
- Vérification des permissions des répertoires.
- Vérification du bit SGID.
- Exécution du script de sauvegarde.
- Vérification de la présence des archives.
- Vérification de l'intégrité d'une archive avec `tar -tzf`.
- Vérification de la syntaxe avec `bash -n`.
- Analyse des scripts avec ShellCheck.

**Captures des tests :**

- Figure 1 : Exécution normale du script de création.
- Figure 2 : Exécution en mode simulation.
- Figure 3 : Gestion d'un cas d'erreur.
- Figure 4 : Résultat de l'analyse ShellCheck.

## 11. Vérification avec ShellCheck

Les scripts ont été analysés avec ShellCheck afin de détecter les erreurs et les mauvaises pratiques Bash.

Les résultats de l'analyse sont présentés dans la capture d'écran correspondante.

## 12. Difficultés rencontrées et solutions

- **Gestion des permissions :** certains répertoires étaient inaccessibles sans privilèges administrateur. La solution a été d'utiliser `sudo` et de configurer correctement les permissions.
- **Gestion des groupes :** le bit SGID a été utilisé pour garantir l'héritage automatique du groupe dans les répertoires partagés.
- **Exécution répétée du script :** les comptes déjà existants sont ignorés afin d'éviter les doublons.
- **Sauvegarde des données :** les archives sont protégées avec des permissions restrictives et leur intégrité est vérifiée avec `tar`.

## 13. Conclusion

Ce projet permet de faciliter l'administration des comptes étudiants sous Linux. Il améliore l'organisation des utilisateurs, la sécurité des accès et la protection des données grâce aux sauvegardes automatisées.

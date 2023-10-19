# TP1Bis
TP1 Vanessa

Pour des raisons de sécurité, il n'y a pas le fichier credentials.
Les fichiers de config présents sont généré à l'exectution des scripts.

Prerequis: python doit être installé pour installer Ansible.
Ajouter, en local un fichier json Credentials.

Pour deployer Wordpress, il fau executer le fichier script.sh.
Ce dernier ce charge d'exectuter le fichier terrarom main.tf pour créer les ressources sur GCP,
et d'exectuer le playbook Ansible wordpress.yml afin de configurer Wordpress et Mysql.

#!/bin/bash

# Fonction pour vérifier et installer Terraform
function Install-Terraform {
    if ! command -v terraform &>/dev/null; then
        echo "Installation de Terraform..."
        sudo apt-get install terraform
       
    fi
}

# Fonction pour vérifier et installer Ansible
function Install-Ansible {
    if ! command -v ansible &>/dev/null; then
        echo "Installation de Ansible..."
        pipx install --include-deps ansible
    fi
}

# Fonction pour vérifier et initialiser Terraform si nécessaire
function Initialize-Terraform {
    if [ ! -f "terraform.tfstate" ]; then
        echo "Initialisation de Terraform..."
        terraform init
    fi
}

# Fonction pour récupérer les adresses IP des VMs créées
#function Get-VM-IPs {
#    outputJson=$(terraform output -json)
#    wordpressIp=$(echo "$outputJson" | jq -r '.wordpress_ip.Value')
#    databaseIp=$(echo "$outputJson" | jq -r '.database_ip.Value')

#    echo "IP1 EST WP: $wordpressIp "
#    echo "IP1 EST DB : $databaseIp "
#}

# Fonction pour récupérer les adresses IP des VMs créées
function Get-VM-IPs {
    outputJson=$(terraform output -json)
    wordpressIp=$(echo "$outputJson" | jq -r '.wordpress_ip.value')
    databaseIp=$(echo "$outputJson" | jq -r '.database_ip.value')

    #echo "IP1 EST WP: $wordpressIp "
    #echo "IP2 EST DB : $databaseIp "

    echo "[wordpress]" 
    echo $wordpressIp
    echo
    echo "[database]" 
    echo $databaseIp

    #return $databaseIp
}

# Fonction pour vérifier et appliquer la création avec Terraform
function Apply-Terraform {
    echo "Création des VMs avec Terraform..."
    terraform apply -auto-approve

    # Mettre à jour le fichier d'inventaire Ansible avec les nouvelles adresses IP
    Get-VM-IPs > inventory.ini
}

# Fonction pour créer la clé SSH pour chaque VM et fournir la clé publique à Ansible et aux VMs
function Create-SSH-Key {
    privateKeyPath="/home/mansour/Bureau/TP1/.ssh/id_rsa"
    publicKeyPath="~/.ssh/id_rsa.pub"
    

    if [ ! -f "$privateKeyPath" ]; then
        echo "Création de la clé SSH..."
        #ssh-keygen -t rsa -b 4096 -N "" -f "$privateKeyPath"
        ssh-keygen -t rsa -f ~/.ssh/id_rsa -N ""
        #ssh-keygen -t rsa -f "$privateKeyPath" -N ""
        
    else
        echo "La clé SSH existe déjà."
    fi

    # Récupérer le contenu de la clé publique et le stocker dans une variable d'environnement
    publicKeyContent=$(cat "$publicKeyPath")
    export ANSIBLE_SSH_PUBLIC_KEY="$publicKeyContent"

    # Créer un fichier avec la clé publique pour Ansible
    echo "$publicKeyContent" > ansible_ssh.pub

    # Récupérer les adresses IP des VMs créées
    Get-VM-IPs

    # Créer la clé SSH pour la VM WordPress
    if [ ! -f ~/.ssh/known_hosts ]; then
        ssh-keyscan -H "$wordpressIp" >> ~/.ssh/known_hosts
    fi

    # Créer la clé SSH pour la VM de la base de données
    if [ ! -f ~/.ssh/known_hosts ]; then
        ssh-keyscan -H "$databaseIp" >> ~/.ssh/known_hosts
    fi
}

# Fonction pour vérifier et créer le fichier hosts d'Ansible si nécessaire
function Create-Ansible-Hosts {
    if [ ! -f "inventory.ini" ]; then
        echo "Création du fichier hosts pour Ansible..."
        cat <<EOL > inventory.ini
[wordpress]
<IP_de_la_VM_Wordpress>

[database]
<IP_de_la_VM_Base_de_donnees>
EOL
    fi
}

# Fonction pour déployer WordPress avec Ansible
function Deploy-WordPress-With-Ansible {
    echo "Déploiement de WordPress avec Ansible..."
    ansible-playbook -i inventory.ini wordpress6.yml -v
    #$vari = Get-VM-IPs
    #ansible-playbook -e $vari -i inventory.ini wordpress.yml -v
    #ansible-playbook -i inventory.ini -e "dbhost=$vari" -v wordpress.yml


}

# Fonction pour vérifier que WordPress est opérationnel
function Check-WordPress {
    echo "Vérification de l'application WordPress..."
    wordpressIp=$(Get-VM-IPs | head -n 1)
    curlResult=$(curl -s "$wordpressIp")
    if [[ $curlResult == *"Installation"* ]]; then
        echo "WordPress est opérationnel."
    else
        echo "WordPress n'est pas opérationnel."
    fi
}

# Appel des fonctions dans l'ordre approprié
Install-Terraform
Initialize-Terraform
Create-SSH-Key
Apply-Terraform
#ssh-keygen  -R 35.233.14.149
ssh-keygen  -R $wordpressIp
ssh-keygen  -R $databaseIp
sleep 20s
Install-Ansible
Create-Ansible-Hosts
Deploy-WordPress-With-Ansible
Check-WordPress

echo "Le déploiement est terminé !"

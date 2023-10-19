provider "google" {
  credentials = file("./credentials.json")
  project     = "zinc-strategy-393412"
  region      = "europe-west1"  # Changez selon votre région préférée
}

resource "google_compute_instance" "wordpress" {
  name         = "wordpress-instance"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"
  tags         = ["http-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"  # Changer l'image selon votre préférence
    }
  }

  network_interface {
    network = google_compute_network.my_network.id
    subnetwork = google_compute_subnetwork.my_subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys = "mansourcgi:${file("~/.ssh/id_rsa.pub")}" 
  }

}

resource "google_compute_instance" "database" {
  name         = "db-instance"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"
  tags         = ["db-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"  # Changer l'image selon votre préférence
    }
  }

  network_interface {
    network = google_compute_network.my_network.id
    subnetwork = google_compute_subnetwork.my_subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys = "mansourcgi:${file("~/.ssh/id_rsa.pub")}"   
     
  }
}






# Création d'un réseau (VPC)
resource "google_compute_network" "my_network" {
  name                    = "mon-reseau"
  auto_create_subnetworks = false # Désactivez la création automatique de sous-réseaux
}

# Création d'un sous-réseau (subnet) dans le réseau (VPC)
resource "google_compute_subnetwork" "my_subnet" {
  name          = "mon-sous-reseau"
  region        = "europe-west1"
  network       = google_compute_network.my_network.id
  ip_cidr_range = "10.0.1.0/24" # Spécifiez la plage d'adresses IP du sous-réseau
}

# Firewall rule to allow SSH, HTTP, and HTTPS access to the instances
resource "google_compute_firewall" "http-https" {
  name    = "allow-http-https"
  network = google_compute_network.my_network.self_link
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["http-server"]
  #source_tags = ["http-server"]
  ##target_tags = ["http-server", "db-server"] 
}

# Firewall rule to allow SSH, HTTP, and HTTPS access to the instances
resource "google_compute_firewall" "http-https-ssh" {
  name    = "allow-http-https-ssh"
  network = google_compute_network.my_network.self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  #target_tags = ["http-server", "db-server"] 
  #source_tags = ["my_network"]
  source_tags = ["http-server", "db-server"]
}

# Firewall rule to allow SSH, HTTP, and HTTPS access to the instances
resource "google_compute_firewall" "http-https-3306" {
  name    = "allow-3306"
  network = google_compute_network.my_network.self_link
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["http-server", "db-server"]
  #source_tags = ["http-server", "db-server"] 
}

# Définir les outputs pour les adresses IP des VMs
output "wordpress_ip" {
  value = google_compute_instance.wordpress.network_interface.0.access_config.0.nat_ip
}

output "database_ip" {
  value = google_compute_instance.database.network_interface.0.access_config.0.nat_ip
}

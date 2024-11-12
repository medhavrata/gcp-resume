# terraform {
#   required_providers {
#     google = {
#       source  = "hashicorp/google"
#       version = "6.8.0"
#     }
#   }
# }


provider "google" {
  project = "resume-project-436919" # Replace with your GCP project ID
  region  = "europe-west2"          # Choose your preferred region
  zone    = "europe-west2-a"
}

# Step 1: Create a Google Cloud Storage Bucket
resource "google_storage_bucket" "resume_bucket" {
  name     = "medhatyagi.uk" # Replace with your domain name
  location = "EU"

  website {
    main_page_suffix = "index.html"
  }

  # Make the bucket publicly accessible
  uniform_bucket_level_access = true
}

# Step 2: Create a Backend Bucket for the Load Balancer
resource "google_compute_backend_bucket" "resume_backend" {
  name        = "resume-backend"
  bucket_name = google_storage_bucket.resume_bucket.name
}

# Step 3: Create a Global IP Address for the Load Balancer
resource "google_compute_global_address" "resume_ip" {
  name = "resume-ip"
}

# Step 4: Create a Google-managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "resume_ssl" {
  name = "resume-ssl-cert"

  managed {
    domains = ["medhatyagi.uk", "www.medhatyagi.uk"] # Replace with your domain names
  }
}

# Step 5: Create a URL Map
resource "google_compute_url_map" "resume_url_map" {
  name            = "resume-url-map"
  default_service = google_compute_backend_bucket.resume_backend.id
}

# Step 6: Create a Target HTTPS Proxy
resource "google_compute_target_https_proxy" "resume_https_proxy" {
  name             = "resume-https-proxy"
  url_map          = google_compute_url_map.resume_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.resume_ssl.id]
}

# Step 7: Create a Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "resume_forwarding_rule" {
  name       = "resume-forwarding-rule"
  target     = google_compute_target_https_proxy.resume_https_proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.resume_ip.address
}

# Step 8: Output the Load Balancer IP Address
output "load_balancer_ip" {
  value = google_compute_global_address.resume_ip.address
}
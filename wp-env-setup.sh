#!/bin/bash

# ==========================================
# STRICT MODE & ERROR HANDLING
# ==========================================
# Exit immediately if a command exits with a non-zero status
set -e

# ==========================================
# GLOBAL VARIABLES & LOGGING
# ==========================================
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}"; }

# ==========================================
# FUNCTIONS (MODULAR COMPONENTS)
# ==========================================

# 1. Install PHP & Required Extensions
install_php_env() {
    log_info "Checking PHP environment..."
    if ! command -v php &> /dev/null; then
        log_info "Installing PHP and required WP extensions..."
        sudo apt update -y
        sudo apt install -y php-cli php-mysql php-zip php-gd php-mbstring php-curl php-xml php-bcmath unzip
        log_info "PHP installed successfully."
    else
        log_warn "PHP is already installed. Skipping..."
    fi
}

# 2. Install WP-CLI securely
install_wp_cli() {
    log_info "Checking WP-CLI..."
    if ! command -v wp &> /dev/null; then
        log_info "Downloading and configuring WP-CLI..."
        curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
        chmod +x wp-cli.phar
        sudo mv wp-cli.phar /usr/local/bin/wp
        log_info "WP-CLI installed successfully."
    else
        log_warn "WP-CLI is already installed. Skipping..."
    fi
}

# 3. Install Ansible for IaC
install_ansible() {
    log_info "Checking Ansible..."
    if ! command -v ansible &> /dev/null; then
        log_info "Installing Ansible..."
        sudo apt install -y software-properties-common
        sudo apt-add-repository --yes --update ppa:ansible/ansible
        sudo apt install -y ansible
        log_info "Ansible installed successfully."
    else
        log_warn "Ansible is already installed. Skipping..."
    fi
}

# 4. Verify System Readiness
verify_installations() {
    log_info "Verifying installed tool versions..."
    echo "------------------------------------------------"
    php -v | head -n 1
    wp --version || log_error "WP-CLI verification failed."
    ansible --version | head -n 1 || log_error "Ansible verification failed."
    echo "------------------------------------------------"
    log_info "✅ Environment setup complete and ready for Automation!"
}

# ==========================================
# MAIN EXECUTION (ENTRY POINT)
# ==========================================
main() {
    log_info "Starting Modular WP Environment Setup..."
    
    install_php_env
    install_wp_cli
    install_ansible
    
    verify_installations
}

# Execute the main function
main

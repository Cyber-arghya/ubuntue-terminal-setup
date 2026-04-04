#!/bin/bash

# ==========================================
# STRICT MODE & ERROR HANDLING
# ==========================================
set -euo pipefail
trap 'log_error "An unexpected error occurred at line $LINENO. Execution aborted."' ERR

# ==========================================
# CONFIGURATION VARIABLES
# ==========================================
DB_NAME="wp_headless"
DB_USER="root"
DB_PASS="rootpass"
DB_HOST="127.0.0.1"
DB_PORT="3306"
CONTAINER_NAME="headless-db"
DB_IMAGE="mysql:8.0" # Changed to standard MySQL for maximum compatibility

WP_PORT="8080"
WP_URL="http://localhost:${WP_PORT}"
WP_TITLE="Elite Headless WP"
ADMIN_USER="admin"
ADMIN_PASS="admin"
ADMIN_EMAIL="admin@example.com"

# ==========================================
# GLOBAL LOGGING FUNCTIONS
# ==========================================
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO] $1${NC}"; }
log_success() { echo -e "${GREEN}[SUCCESS] $1${NC}"; }
log_warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
log_error() { echo -e "${RED}[ERROR] $1${NC}" >&2; exit 1; }

# ==========================================
# MODULAR FUNCTIONS
# ==========================================

check_requirements() {
    log_info "Checking prerequisites..."
    if ! command -v docker &> /dev/null; then log_error "Docker is not installed or running."; fi
    if ! command -v wp &> /dev/null; then log_error "WP-CLI is not installed."; fi
}

start_database() {
    log_info "Step 1: Starting Database via Docker (${DB_IMAGE})..."
    
    if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        log_warn "Database container '${CONTAINER_NAME}' is already running."
    elif [ "$(docker ps -aq -f status=exited -f name=${CONTAINER_NAME})" ]; then
        log_info "Starting existing database container..."
        docker start ${CONTAINER_NAME} > /dev/null
    else
        log_info "Creating and spinning up MySQL container..."
        docker run -d --name ${CONTAINER_NAME} \
            -e MYSQL_ROOT_PASSWORD=${DB_PASS} \
            -e MYSQL_DATABASE=${DB_NAME} \
            -p ${DB_PORT}:3306 ${DB_IMAGE} > /dev/null
    fi

    log_info "Waiting for MySQL Database to be fully ready..."
    local max_attempts=45 # MySQL 8.0 takes slightly longer to initialize the first time
    local attempt=1
    
    # Industry Standard Check: Executing a real SQL query to verify engine is accepting queries
    while ! docker exec ${CONTAINER_NAME} mysql -u"${DB_USER}" -p"${DB_PASS}" -e "SELECT 1;" &>/dev/null; do
        if [ $attempt -eq $max_attempts ]; then
            log_error "Database failed to initialize within the expected time. Please check 'docker logs ${CONTAINER_NAME}'"
        fi
        sleep 2
        attempt=$((attempt + 1))
    done
    log_success "Database is up and accepting queries!"
}

download_configure_wp() {
    log_info "Step 2: Downloading & Configuring WordPress Core..."
    
    if [ ! -f "wp-includes/version.php" ]; then
        log_info "Downloading WordPress..."
        rm -rf wp-admin wp-includes wp-content *.php
        wp core download --quiet || log_error "Failed to download WordPress."
    else
        log_warn "WordPress core already exists. Skipping download."
    fi

    if [ ! -f wp-config.php ]; then
        log_info "Generating wp-config.php..."
        wp config create \
            --dbname=${DB_NAME} \
            --dbuser=${DB_USER} \
            --dbpass=${DB_PASS} \
            --dbhost=${DB_HOST}:${DB_PORT} \
            --quiet || log_error "Failed to create wp-config.php."
    else
        log_warn "wp-config.php already exists. Skipping config creation."
    fi
}

install_wordpress() {
    log_info "Step 3: Installing WordPress..."
    if ! wp core is-installed 2>/dev/null; then
        wp core install \
            --url=${WP_URL} \
            --title="${WP_TITLE}" \
            --admin_user=${ADMIN_USER} \
            --admin_password=${ADMIN_PASS} \
            --admin_email=${ADMIN_EMAIL} \
            --skip-email --quiet || log_error "WordPress installation failed."
            
        log_info "Setting permalinks to 'Post name'..."
        wp rewrite structure '/%postname%/' --quiet
    else
        log_warn "WordPress is already installed. Skipping installation."
    fi
}

setup_headless_plugins() {
    log_info "Step 4: Setting up Headless Environment (WPGraphQL)..."
    if ! wp plugin is-installed wp-graphql; then
        wp plugin install wp-graphql --activate --quiet || log_error "Failed to install WPGraphQL."
    else
        log_warn "WPGraphQL plugin is already installed."
    fi
}

print_summary() {
    echo -e "\n${GREEN}====================================================${NC}"
    echo -e "${GREEN}✅ WordPress Automation & Optimization Complete!${NC}"
    echo -e "Frontend URL: ${WP_URL}"
    echo -e "Admin Panel : ${WP_URL}/wp-admin"
    echo -e "Username    : ${ADMIN_USER}"
    echo -e "Password    : ${ADMIN_PASS}"
    echo -e "GraphQL API : ${WP_URL}/graphql"
    echo -e "${GREEN}====================================================${NC}\n"
}

start_server() {
    log_info "Step 5: Starting Native PHP Server on port ${WP_PORT}..."
    wp server --port=${WP_PORT}
}

# ==========================================
# MAIN EXECUTION
# ==========================================
main() {
    check_requirements
    start_database
    download_configure_wp
    install_wordpress
    setup_headless_plugins
    print_summary
    start_server
}

main
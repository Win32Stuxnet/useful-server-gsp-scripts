#!/bin/bash
set -euo pipefail

echo "Starting Panel Installation"
echo "Checking for required packages. Continue? (y/n)"

while true; do
    read -r choice
    case $choice in
        [Yy]* ) echo "Proceeding..."; break;;
        [Nn]* ) echo "Exiting..."; exit 0;;
        * ) echo "Invalid choice. Please enter y or n:";;
    esac
done

required=("curl" "git")
for cmd in "${required[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "$cmd not present"
        apt install "$cmd" -y
        logger "$cmd installed"
    fi
done

apt install -y curl ca-certificates gnupg2 sudo lsb-release

cat <<EOF | sudo tee /etc/apt/sources.list.d/sury-php.list
deb https://packages.sury.org/php/ $(lsb_release -sc) main
EOF

curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg

cat <<EOF | sudo tee /etc/apt/sources.list.d/redis.list
deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main
EOF

curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash

apt update
apt install -y php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server

curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# Prompt for database password before running SQL
echo "Enter password for pterodactyl database user:"
read -rs db_password
echo

mariadb -u root <<EOF
CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${db_password}';
CREATE DATABASE panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

cp .env.example .env

echo "Panel Installation Complete"
cat <<EOF
Panel URL: http://$(hostname -I | awk '{print $1}'):8080
Panel Username: pterodactyl
Panel Database: panel
Panel Database User: pterodactyl
Panel Database Password: ${db_password}
Panel Database Host: 127.0.0.1
Panel Database Port: 3306
EOF

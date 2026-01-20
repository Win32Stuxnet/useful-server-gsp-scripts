required=("curl" "git" "python3","lsb_release","docker")
for cmd in "${required[@]}"; do
    if ! command -v $cmd >/dev/null &>/dev/null; then
        echo "$cmd not present"
        apt install $cmd -y
        logger "$cmd installed"
    fi
# Install necessary packages
apt install -y curl ca-certificates gnupg2 sudo lsb-release

# Add additional repositories for PHP
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/sury-php.list
curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/sury-keyring.gpg

# Add Redis official APT repository (Debian 11 & 12)
curl -fsSL https://packages.redis.io/gpg | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

# MariaDB repo setup script (Debian 11 & 12)
curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash

# Update repositories list
apt update

# Install Dependencies
apt install -y php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx tar unzip git redis-server
apt install -y curl ca-certificates gnupg2 sudo lsb-release
curl -sS https://getcomposer.org/installer | sudo php -- --install-dir=/usr/local/bin --filename=composer

wait
done 


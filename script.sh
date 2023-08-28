#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."

    # Remove conflicting packages (optional)
    apt-get remove -y docker.io docker-doc docker-compose podman-docker containerd runc

    # Install prerequisites
    apt-get update
    apt-get install -y ca-certificates curl gnupg

    # Add Docker GPG key
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "Docker installed successfully."

else
    echo "Docker is already installed."
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Installing Docker Compose..."

    # Install Docker Compose
    apt-get update
    apt-get install -y docker-compose

    echo "Docker Compose installed successfully."

else
    echo "Docker Compose is already installed."
fi


# Check if site name argument was provided
if [ -z "$1" ]; then
  echo "Enter your site name as an argument."
  exit 1
fi
# Entry in /etc/hosts
site_name="$1"
echo "127.0.0.1:8080 $site_name" >> /etc/hosts

#creating required files
mkdir lemp-wordpress
cd lemp-wordpress
# Creating public and nginx
echo "Creating nginx configuration file"
mkdir wordpress nginx
cd nginx
touch default.conf 
echo '
server {
    listen 80;
    server_name $host;
    root /var/www/html;
    index  index.php index.htm index.html;
    location / {
        try_files $uri $uri/ /index.php?$is_args$args;
    }
    location ~ \.php$ {
        # include snippets/fastcgi-php.conf;
        try_files $uri =404;
        # fastcgi_pass unix:/run/php-fpm/www.sock;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass wordpress:9000;
        fastcgi_index   index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
        
    }

}
' >> default.conf

echo "Done"
cd ..
echo "Creating docker-compose file ..."
cat > docker-compose.yml << EOF 
version: '3.1'
services:
  #databse
  db:
    image: mysql:latest
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    ports:
      - '3306:3306'
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
      MYSQL_ROOT_PASSWORD: password
    networks:
      - wpsite
  #wordpress
  wordpress:
    depends_on: 
      - db
    image: wordpress:php8.2-fpm
    restart: always
    ports:
      - '9000:9000'
    volumes: ['./wordpress:/var/www/html']
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    networks:
      - wpsite
  #nginx
  proxy:
    image: nginx:latest
    depends_on:
      - db
      - wordpress
    ports:
      - '8080:80'
    volumes: 
      - ./wordpress:/var/www/html
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
    networks:
      - wpsite
networks:
  wpsite:
volumes:
  db_data:

EOF
echo "Done"
fuser -k 9000/tcp 8080/tcp
echo "Creating LEMP stck in docker for wordpress"
docker compose up -d
echo "Servers created"

# prompting user to open site in browser
echo "Site is up and healthy. Open $site_name in any browser to view it."
echo "Or click on the link -> http://localhost:8080"

# Adding subcommands to enbale/disable
if [ "$2" == "enable" ]; then
 docker compose start
elif [ "$2" == "disable" ]; then
 docker compose stop
fi

# Adding subcommands to delete site
if [ "$2" == "delete" ]; then
 docker compose down --volume
 #removing hosts entry
 sed "/$site_name/d" /etc/hosts
 #removing all local files
 cd ..
 rm -rf ./lemp-wordpress
fi

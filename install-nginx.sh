#!/bin/bash
# === Securing with nginx
sudo apt-get -y install nginx

# This probably will break if the password contains bash-recognised characters, but I was defeated
# by escaping.
sudo bash <<FOF
printf "$tm_username:$(openssl passwd -crypt ""$tm_password"")\n" >> /etc/nginx/htpasswd
chown root:www-data htpasswd
chmod 640 htpasswd
FOF

# In the following config, http_host is literally a dollar sign then http_host
# whereas IP is a shell variable that should be substituted at the time the config is written.
sudo tee /etc/nginx/sites-enabled/default <<FOF

server {
   listen 80;
   server_name localhost;
   # This configuration allows TileMill to coexist with the tile server (/datasource, /tile) on external port 80.
   location /tile/ {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20008;
   
        
        #proxy_cache my-cache;
        #proxy_cache_valid  200 302  60m;
        #proxy_cache_valid  404      1m;
    }
    location /datasource/ {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20008;
    }
    #location /maps {
    # alias   /usr/share/nginx/www/Project-OSRM-Web/WebContent/;
    #}
   location /tilemill {
       rewrite     ^(.*)$ http://$ip:5002 permanent;
   }

   location / {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20009;
        auth_basic "Restricted";
        auth_basic_user_file htpasswd;
    }
}

server {
   #listen $ip:20008;
   listen 5002;
   server_name localhost;
   location / {
        proxy_set_header Host \$http_host;
        proxy_pass http://127.0.0.1:20009;
        auth_basic "Restricted";
        auth_basic_user_file htpasswd;
    }
}
FOF


sudo service nginx restart

#!/bin/bash
# Configure the port
port=8443
cat /etc/apache2/ports.conf | sed -r "s/^Listen.+/Listen $port/" > /etc/apache2/ports.conf
# Enable authorization and add a user
a2enmod auth_basic
htpasswd -b -c /etc/apache2/.htpasswd rest api
# Loads server and virtualhost scripts from the GitHub repository
mkdir /var/www/api && touch /var/www/api/api.sh && chmod +x /var/www/api/api.sh
curl -s "https://raw.githubusercontent.com/Lifailon/bash-api-server/rsa/www/api/api.sh" > /var/www/api/api.sh
curl -s "https://raw.githubusercontent.com/Lifailon/bash-api-server/rsa/apache2/sites-available/api.conf" > /etc/apache2/sites-available/api.conf
# Activate the module and site
a2enmod cgi
a2ensite api.confs
# Grant sudo privileges to the www-data user to manage services
echo "www-data ALL=(ALL) NOPASSWD: /bin/systemctl start *, /bin/systemctl stop *, /bin/systemctl restart *" >> /etc/sudoers
# Start server
systemctl restart apache2
# Shell-API-Server

REST API server based on Apache and **backend Bash via cgi module** for remote managment Linux 🐧 using curl or Invoke-WebRequest in Windows.

Implemented Linux service management via **systemd** (`systemctl`) and used **basic authorization**.

## 🚀 Install

1. Install an Apache server and jqlang (in the example for Ubuntu/Debian):

```Bash
apt install apache2
apt install jq
```

2. Configure port `8443` (or use any other by specifying it in `VirtualHost`):

```Bash
cat /etc/apache2/ports.conf | sed -r "s/^Listen.+/Listen 8443/" > /etc/apache2/ports.conf
```

3. Activate the basic HTTP authentication module and add the user (enter the password for user `rest` manually):

```Bash
a2enmod auth_basic
htpasswd -c /etc/apache2/.htpasswd rest
```

4. Create a file at the path `/var/www/api/api.sh` and copy the contents of the `api.sh` script:

```Bash
mkdir /var/www/api
nano /var/www/api/api.sh
chmod +x /var/www/api/api.sh
```

5. Configure a **VirtualHost** (`/etc/apache2/sites-available/api.conf`) this way:

```Bash
<VirtualHost *:8443>
    ScriptAlias /api /var/www/api/api.sh
    <Directory "/var/www/api">
        Options +ExecCGI
        AddHandler cgi-script .sh
        AllowOverride None
        Require all granted
    </Directory>
    <Location "/api">
        AuthType Basic
        AuthName "Restricted Area"
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
        SetHandler cgi-script
        Options +ExecCGI
    </Location>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```

6. Activate the module for working cgi-scripts, activate the created VirtualHost and start the server:

```Bash
a2enmod cgi
a2ensite api.confs
systemctl restart apache2
```

7. In order for the Apache server to be able to manage services, the `www-data` user must be granted the appropriate sudo permissions:

```Bash
echo "www-data ALL=(ALL) NOPASSWD: /bin/systemctl start *, /bin/systemctl stop *, /bin/systemctl restart *" >> /etc/sudoers
```

## 📑 Examples

Get the status of the service specified in the header (the example, cron):

`curl -s -X GET http://192.168.3.101:8443/api/service/cron -u rest:api`

```json
{
  "unit": "cron.service",
  "load": "loaded",
  "active": "active",
  "sub": "running",
  "description": "Regular background program processing daemon",
  "uptime": "5h 1min",
  "startup": "enabled"
}
```

Stop the service:

`curl -s -X POST http://192.168.3.101:8443/api/service/cron -u rest:api -H "Status: stop"`

```json
{
  "unit": "cron.service",
  "load": "loaded",
  "active": "inactive",
  "sub": "dead",
  "description": "Regular background program processing daemon",
  "uptime": "108ms",
  "startup": "enabled"
}
```

Start the service:

`curl -s -X POST http://192.168.3.101:8443/api/service/cron -u rest:api -H "Status: start"`

```json
{
  "unit": "cron.service",
  "load": "loaded",
  "active": "active",
  "sub": "running",
  "description": "Regular background program processing daemon",
  "uptime": "104ms",
  "startup": "enabled"
}
```
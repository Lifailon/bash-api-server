# Bash API Server

REST API server based on Apache and **backend Bash via cgi module** for remote managment Linux 🐧 using curl or Invoke-WebRequest in Windows.

Implemented Linux service management via **systemd** (with `systemctl` commands) using **basic authorization**.

## 🚀 Install

Install an Apache server and [jqlang](https://github.com/jqlang/jq) for `json` processing (in the example for Ubuntu/Debian):

```Bash
apt install apache2 jq
```

The following described customization steps can be performed using the [build](https://github.com/Lifailon/Shell-API-Server/blob/rsa/build.sh) script.

1. Configure port `8443` (or use any other by specifying it in `VirtualHost`):

```Bash
cat /etc/apache2/ports.conf | sed -r "s/^Listen.+/Listen 8443/" > /etc/apache2/ports.conf
```

2. Activate the HTTP `Basic Authentication` module and add a user (in the example `rest` and password `api`):

```Bash
a2enmod auth_basic
htpasswd -b -c /etc/apache2/.htpasswd rest api
```

3. Create a file at the path `/var/www/api/api.sh` and copy the contents of the `api.sh` script:

```Bash
mkdir /var/www/api && touch /var/www/api/api.sh && chmod +x /var/www/api/api.sh
curl -s "https://raw.githubusercontent.com/Lifailon/Shell-API-Server/rsa/www/api/api.sh" > /var/www/api/api.sh
```

4. Configure a **VirtualHost** (`/etc/apache2/sites-available/api.conf`) this way:

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

5. Activate the module for working cgi-scripts, activate the created VirtualHost and start the server:

```Bash
a2enmod cgi
a2ensite api.confs
systemctl restart apache2
```

6. In order for the Apache server to be able to manage services, the `www-data` user must be granted the appropriate sudo permissions:

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

List of services in HTML table format when accessed through a Web browser:

![Image alt](https://github.com/Lifailon/Shell-API-Server/blob/rsa/image/service-list-html-table.jpg)

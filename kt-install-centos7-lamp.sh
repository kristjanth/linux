#!/bin/sh

ADMIN_MAIL="hostmaster@example.com"
HOST_NAME="host.example.com"
DOMAIN="example.com"
IPv4_ADDRESS="1.2.3.4"
IPv6_ADDRESS="2000::1"
BUILD_DATE=$(date +"%Y-%m-%d")

cat > /etc/motd <<EOF
--------------------------------------------------------------------------------

$HOST_NAME

IPv4: $IPv4_ADDRESS
IPv6: $IPv6_ADDRESS
Build: $BUILD_DATE
--------------------------------------------------------------------------------

EOF

yum update -y -q &> /dev/null
yum install -y -q vim-enhanced bind-utils telnet wget curl &> /dev/null
yum install -y -q httpd mod_ssl &> /dev/null

cp -f /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.org

cat > /etc/httpd/conf/httpd.conf <<EOF
ServerRoot "/etc/httpd"
Listen 80
Include conf.modules.d/*.conf
User apache
Group apache
ServerAdmin $ADMIN_MAIL
ServerName $HOST_NAME

<Directory />
    AllowOverride none
    Require all denied
</Directory>

DocumentRoot "/var/www/html"

<Directory "/var/www">
    AllowOverride None
    Require all granted
</Directory>

<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "logs/error_log"
LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" combined
</IfModule>

<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
</IfModule>

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule mime_module>
    TypesConfig /etc/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

#AddDefaultCharset UTF-8

<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>

EnableSendfile on

IncludeOptional conf.d/*.conf

NameVirtualHost *:80
Include /etc/httpd/sites-enabled/

EOF

mkdir /etc/httpd/sites-available
mkdir /etc/httpd/sites-enabled

cp -f /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.org

cat > /etc/httpd/conf.d/welcome.conf <<EOF
# This configuration file enables the default "Welcome" page if there
# is no default index page present for the root URL.  To disable the
# Welcome page, comment out all the lines below. 
#
# NOTE: if this file is removed, it will be restored on upgrades.
#
#<LocationMatch "^/+$">
#    Options -Indexes
#    ErrorDocument 403 /.noindex.html
#</LocationMatch>
#
#<Directory /usr/share/httpd/noindex>
#    AllowOverride None
#    Require all granted
#</Directory>
#
#Alias /.noindex.html /usr/share/httpd/noindex/index.html
#Alias /css/bootstrap.min.css /usr/share/httpd/noindex/css/bootstrap.min.css
#Alias /css/open-sans.css /usr/share/httpd/noindex/css/open-sans.css
#Alias /images/apache_pb.gif /usr/share/httpd/noindex/images/apache_pb.gif
#Alias /images/poweredby.png /usr/share/httpd/noindex/images/poweredby.png
#

EOF

cat > /var/www/html/index.html <<EOF
$HOST_NAME

EOF

yum install -y -q php php-mysql php-gd php-pear php-mbstring php-xml php-devel &> /dev/null

systemctl enable httpd.service
systemctl start httpd.service

yum install -y -q mariadb-server mariadb &> /dev/null

systemctl enable mariadb.service
systemctl start mariadb.service

wget -q -O /tmp/phpmyadmin.tar.gz http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/4.2.6/phpMyAdmin-4.2.6-english.tar.gz/download
tar -xzf /tmp/phpmyadmin.tar.gz -C /tmp
rm -rf /tmp/phpmyadmin.tar.gz
rm -rf /usr/share/phpmyadmin
mv /tmp/php* /usr/share/phpmyadmin

cat > /etc/httpd/conf.d/phpmyadmin.conf <<EOF
#
#  Web application to manage MySQL
#
#<Directory "/usr/share/phpmyadmin">
#  Order Deny,Allow
#  Deny from all
#  Allow from 127.0.0.1
#</Directory>

<Directory "/usr/share/phpmyadmin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

Alias /phpmyadmin /usr/share/phpmyadmin
Alias /phpMyAdmin /usr/share/phpmyadmin
Alias /mysqladmin /usr/share/phpmyadmin

EOF

yum install -y -q  logwatch &> /dev/null

echo -e MailFrom = hostmaster@"$DOMAIN\n"Service = -SSHD"\n"Service = -postfix"\n" >> /etc/logwatch/conf/logwatch.conf

echo -e root: "$ADMIN_MAIL\n" >> /etc/aliases

newaliases

systemctl start firewalld
firewall-cmd --permanent --zone=public --add-service=ssh &> /dev/null
firewall-cmd --permanent --zone=public --add-service=http &> /dev/null
firewall-cmd --permanent --zone=public --add-service=https &> /dev/null
firewall-cmd --reload &> /dev/null


echo "Post install tasks:"
echo " "
echo "1) MariaDB"
echo "/usr/bin/mysql_secure_installation"
echo " "


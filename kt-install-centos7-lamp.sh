#!/bin/sh

ADMIN_MAIL="hostmaster@example.com"
AUTHORIZED_KEYS="ssh-rsa KEY"
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

cp -f /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf.org &> /dev/null

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

mkdir /etc/httpd/sites-available &> /dev/null
mkdir /etc/httpd/sites-enabled &> /dev/null

cp -f /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf.org &> /dev/null

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

systemctl enable httpd.service &> /dev/null
systemctl start httpd.service &> /dev/null

yum install -y -q mariadb-server mariadb &> /dev/null

systemctl enable mariadb.service &> /dev/null
systemctl start mariadb.service &> /dev/null

wget -q -O /tmp/phpmyadmin.tar.gz http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/4.2.6/phpMyAdmin-4.2.6-english.tar.gz/download &> /dev/null
tar -xzf /tmp/phpmyadmin.tar.gz -C /tmp &> /dev/null
rm -f /tmp/phpmyadmin.tar.gz &> /dev/null
rm -rf /usr/share/phpmyadmin &> /dev/null
mv /tmp/php* /usr/share/phpmyadmin &> /dev/null

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

systemctl restart httpd.service &> /dev/null

yum install -y -q  logwatch &> /dev/null

cp -f /etc/logwatch/conf/logwatch.conf /etc/logwatch/conf/logwatch.conf.org &> /dev/null

cat > /etc/logwatch/conf/logwatch.conf <<EOF
# Local configuration options go here (defaults are in /usr/share/logwatch/default.conf/logwatch.conf)
MailFrom = hostmaster@$DOMAIN
Service = -SSHD
Service = -postfix

EOF

yum install -y -q  postfix &> /dev/null

cp -f /etc/postfix/main.cf /etc/postfix/main.cf.org &> /dev/null

cat > /etc/postfix/main.cf <<EOF
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix
mail_owner = postfix
myhostname = $HOST_NAME
mydomain = $DOMAIN
myorigin = $HOST_NAME
inet_interfaces = localhost
inet_protocols = all
mydestination = $HOST_NAME, localhost.$DOMAIN, localhost
unknown_local_recipient_reject_code = 550
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
smtpd_banner = $HOST_NAME
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix
mailq_path = /usr/bin/mailq.postfix
setgid_group = postdrop
html_directory = no
manpage_directory = /usr/share/man
sample_directory = /usr/share/doc/postfix-2.10.1/samples
readme_directory = /usr/share/doc/postfix-2.10.1/README_FILES

EOF

systemctl enable postfix.service &> /dev/null
systemctl start postfix.service &> /dev/null

cp -f /etc/aliases /etc/aliases.org &> /dev/null

cat > /etc/aliases <<EOF
# The program "newaliases" must be run after this file is
# updated for any changes to show through to sendmail
mailer-daemon:	postmaster
postmaster:	root
bin:		root
daemon:		root
adm:		root
lp:		root
sync:		root
shutdown:	root
halt:		root
mail:		root
news:		root
uucp:		root
operator:	root
games:		root
gopher:		root
ftp:		root
nobody:		root
radiusd:	root
nut:		root
dbus:		root
vcsa:		root
canna:		root
wnn:		root
rpm:		root
nscd:		root
pcap:		root
apache:		root
webalizer:	root
dovecot:	root
fax:		root
quagga:		root
radvd:		root
pvm:		root
amandabackup:		root
privoxy:	root
ident:		root
named:		root
xfs:		root
gdm:		root
mailnull:	root
postgres:	root
sshd:		root
smmsp:		root
postfix:	root
netdump:	root
ldap:		root
squid:		root
ntp:		root
mysql:		root
desktop:	root
rpcuser:	root
rpc:		root
nfsnobody:	root
ingres:		root
system:		root
toor:		root
manager:	root
dumper:		root
abuse:		root
www:		root
webmaster:	root
noc:		root
security:	root
hostmaster:	root
info:		postmaster
marketing:	postmaster
sales:		postmaster
support:	postmaster
root: $ADMIN_MAIL

EOF

newaliases &> /dev/null

systemctl start firewalld &> /dev/null
firewall-cmd --permanent --zone=public --add-service=ssh &> /dev/null
firewall-cmd --permanent --zone=public --add-service=http &> /dev/null
firewall-cmd --permanent --zone=public --add-service=https &> /dev/null
firewall-cmd --reload &> /dev/null

rm -f ~/.ssh/id_dsa* &> /dev/null
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa &> /dev/null
rm -f ~/.ssh/id_dsa* &> /dev/null
echo -e "$AUTHORIZED_KEYS\n" >> ~/.ssh/authorized_keys &> /dev/null

echo " "
echo "Post install tasks:"
echo "1) mariadb installation: /usr/bin/mysql_secure_installation"
echo " "


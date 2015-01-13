#!/bin/sh
ADMIN_MAIL="hostmaster@example.com"
AUTHORIZED_KEYS="ssh-rsa ssh-key"
HOST_NAME="host.example.com"
DOMAIN="example.com"
IPv4_ADDRESS="1.2.3.4"
IPv6_ADDRESS="2000::1"
# Choose "mysqld" for Mysql or "mariadb" for MariaDB
DBSERVER_TYPE="mariadb"
# Choose "lamp" for Apache or "lemp" for Nginx
WEBSERVER_TYPE="lamp"

# Do not chnage anything below this
BUILD_DATE=$(date +"%Y-%m-%d-%H%M")

echo "Starting server setup..."
echo " "

cat > /etc/motd <<EOF
--------------------------------------------------------------------------------

$HOST_NAME
$IPv4_ADDRESS $IPv6_ADDRESS

$BUILD_DATE
--------------------------------------------------------------------------------

EOF

cp -f /etc/hostname /etc/hostname-$BUILD_DATE &> /dev/null

cat > /etc/hostname <<EOF
$HOST_NAME

EOF

hostname $HOST_NAME &> /dev/null

yum update -y -q &> /dev/null
yum install -y -q vim-enhanced bind-utils telnet wget curl ftp &> /dev/null

cp -f /etc/selinux/config /etc/selinux/config-$BUILD_DATE &> /dev/null

cat > /etc/selinux/config  <<EOF
# This file controls the state of SELinux on the system.
# SELINUX= can take one of these three values:
#     enforcing - SELinux security policy is enforced.
#     permissive - SELinux prints warnings instead of enforcing.
#     disabled - No SELinux policy is loaded.
SELINUX=disabled
# SELINUXTYPE= can take one of these two values:
#     targeted - Targeted processes are protected,
#     minimum - Modification of targeted policy. Only selected processes are protected. 
#     mls - Multi Level Security protection.
SELINUXTYPE=targeted 

EOF

wget -q -O /tmp/phpmyadmin.tar.gz http://sourceforge.net/projects/phpmyadmin/files/phpMyAdmin/4.2.12/phpMyAdmin-4.2.12-english.tar.gz/download &> /dev/null
tar -xzf /tmp/phpmyadmin.tar.gz -C /tmp &> /dev/null
rm -f /tmp/phpmyadmin.tar.gz &> /dev/null
rm -rf /usr/share/phpmyadmin &> /dev/null
mv /tmp/php* /usr/share/phpmyadmin &> /dev/null

if [ $WEBSERVER_TYPE = "lamp" ]
then
yum install -y -q httpd mod_ssl &> /dev/null

cp -f /etc/httpd/conf/httpd.conf /etc/httpd/conf/httpd.conf-$BUILD_DATE &> /dev/null

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
IncludeOptional sites/*.conf

EOF

mkdir /etc/httpd/sites &> /dev/null

cp -f /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf-$BUILD_DATE &> /dev/null

cat > /etc/httpd/conf.d/welcome.conf <<EOF
# This configuration file enables the default "Welcome" page if there
# is no default index page present for the root URL.  To disable the
# Welcome page, comment out all the lines below. 
#
# NOTE: if this file is removed, it will be restored on upgrades.
#

EOF

cat > /var/www/html/index.html <<EOF
$HOST_NAME

EOF

cat > /var/www/html/info.php <<EOF
<?php
phpinfo();
?>

EOF

yum install -y -q php php-mysql php-gd php-pear php-mbstring php-xml php-devel &> /dev/null

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

systemctl enable httpd.service &> /dev/null
systemctl start httpd.service &> /dev/null
fi

if [ $WEBSERVER_TYPE = "lemp" ]
then
rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm &> /dev/null
yum install -y -q nginx &> /dev/null

yum install -y -q php php-mysql php-fpm php-gd php-pear php-mbstring php-xml php-devel &> /dev/null

cp -f /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html-$BUILD_DATE &> /dev/null

cat > /usr/share/nginx/html/index.html <<EOF
$HOST_NAME

EOF

cat > /usr/share/nginx/html/info.php <<EOF
<?php
phpinfo();
?>

EOF

cp -f /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf-$BUILD_DATE &> /dev/null

cat > /etc/php-fpm.d/www.conf <<EOF
[www]
;listen = 127.0.0.1:9000
listen = /var/run/php-fpm/php5-fpm.sock
;listen.backlog = -1
listen.allowed_clients = 127.0.0.1
;listen.owner = nobody
;listen.group = nobody
;listen.mode = 0666
user = apache
group = apache
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
;pm.max_requests = 500
;pm.status_path = /status
;ping.path = /ping
;ping.response = pong
;request_terminate_timeout = 0
;request_slowlog_timeout = 0
slowlog = /var/log/php-fpm/www-slow.log
;rlimit_files = 1024
;rlimit_core = 0
;chroot = 
;chdir = /var/www
;catch_workers_output = yes
;security.limit_extensions = .php .php3 .php4 .php5
;env[HOSTNAME] = $HOSTNAME
;env[PATH] = /usr/local/bin:/usr/bin:/bin
;env[TMP] = /tmp
;env[TMPDIR] = /tmp
;env[TEMP] = /tmp
;php_admin_value[sendmail_path] = /usr/sbin/sendmail -t -i -f www@my.domain.com
;php_flag[display_errors] = off
php_admin_value[error_log] = /var/log/php-fpm/www-error.log
php_admin_flag[log_errors] = on
;php_admin_value[memory_limit] = 128M
php_value[session.save_handler] = files
php_value[session.save_path] = /var/lib/php/session

EOF

cat > /etc/nginx/php-common.conf <<EOF
location / {
try_files $uri $uri/ /index.php?$args;
}

location ~* /(?:uploads|files)/.*\.php$ {
deny all;
}

error_page 404 /404.html;
error_page 500 502 503 504 /50x.html;
location = /50x.html {
root /usr/share/nginx/html;
}

location ~ \.php$ {
try_files $uri =404;
fastcgi_pass unix:/var/run/php-fpm/php5-fpm.sock;
fastcgi_index index.php;
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
include fastcgi_params;
}

location ~ /\.ht {
deny all;
}

EOF

cp -f /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf-$BUILD_DATE &> /dev/null

cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80;
    server_name $IPv4_ADDRESS;
    root /usr/share/nginx/html;
    index index.php index.html index.htm;
    include php-common.conf;
}

EOF

cp -f /etc/php.ini /etc/php.ini-$BUILD_DATE &> /dev/null

cat > /etc/php.ini <<EOF
[PHP]
engine = On
short_open_tag = Off
asp_tags = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off
implicit_flush = Off
unserialize_callback_func =
serialize_precision = 17
disable_functions =
disable_classes =
zend.enable_gc = On
expose_php = On
max_execution_time = 30
max_input_time = 60
memory_limit = 128M
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
display_startup_errors = Off
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = Off
ignore_repeated_source = Off
report_memleaks = On
track_errors = Off
html_errors = On
variables_order = "GPCS"
request_order = "GP"
register_argc_argv = Off
auto_globals_jit = On
post_max_size = 16M
auto_prepend_file =
auto_append_file =
default_mimetype = "text/html"
doc_root =
user_dir =
enable_dl = Off
cgi.fix_pathinfo=0
file_uploads = On
upload_max_filesize = 12M
max_file_uploads = 20
allow_url_fopen = On
allow_url_include = Off
default_socket_timeout = 60
[CLI Server]
cli_server.color = On
[Date]
;date.timezone =
date.timezone = Atlantic/Reykjavik
[filter]
[iconv]
[intl]
[sqlite]
[sqlite3]
[Pcre]
[Pdo]
[Pdo_mysql]
pdo_mysql.cache_size = 2000
pdo_mysql.default_socket=
[Phar]
[mail function]
SMTP = localhost
smtp_port = 25
sendmail_path = /usr/sbin/sendmail -t -i
mail.add_x_header = On
[SQL]
sql.safe_mode = Off
[ODBC]
odbc.allow_persistent = On
odbc.check_persistent = On
odbc.max_persistent = -1
odbc.max_links = -1
odbc.defaultlrl = 4096
odbc.defaultbinmode = 1
;birdstep.max_links = -1
[Interbase]
ibase.allow_persistent = 1
ibase.max_persistent = -1
ibase.max_links = -1
ibase.timestampformat = "\%Y-\%m-\%d \%H:\%M:\%S"
ibase.dateformat = "\%Y-\%m-\%d"
ibase.timeformat = "\%H:\%M:\%S"
[MySQL]
mysql.allow_local_infile = On
mysql.allow_persistent = On
mysql.cache_size = 2000
mysql.max_persistent = -1
mysql.max_links = -1
mysql.default_port =
mysql.default_socket =
mysql.default_host =
mysql.default_user =
mysql.default_password =
mysql.connect_timeout = 60
mysql.trace_mode = Off
[MySQLi]
mysqli.max_persistent = -1
mysqli.allow_persistent = On
mysqli.max_links = -1
mysqli.cache_size = 2000
mysqli.default_port = 3306
mysqli.default_socket =
mysqli.default_host =
mysqli.default_user =
mysqli.default_pw =
mysqli.reconnect = Off
[mysqlnd]
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off
[OCI8]
[PostgreSQL]
pgsql.allow_persistent = On
pgsql.auto_reset_persistent = Off
pgsql.max_persistent = -1
pgsql.max_links = -1
pgsql.ignore_notice = 0
pgsql.log_notice = 0
[Sybase-CT]
sybct.allow_persistent = On
sybct.max_persistent = -1
sybct.max_links = -1
sybct.min_server_severity = 10
sybct.min_client_severity = 10
[bcmath]
bcmath.scale = 0
[browscap]
[Session]
session.save_handler = files
session.use_cookies = 1
session.use_only_cookies = 1
session.name = PHPSESSID
session.auto_start = 0
session.cookie_lifetime = 0
session.cookie_path = /
session.cookie_domain =
session.cookie_httponly =
session.serialize_handler = php
session.gc_probability = 1
session.gc_divisor = 1000
session.gc_maxlifetime = 1440
session.bug_compat_42 = Off
session.bug_compat_warn = Off
session.referer_check =
session.cache_limiter = nocache
session.cache_expire = 180
session.use_trans_sid = 0
session.hash_function = 0
session.hash_bits_per_character = 5
url_rewriter.tags = "a=href,area=href,frame=src,input=src,form=fakeentry"
[MSSQL]
mssql.allow_persistent = On
mssql.max_persistent = -1
mssql.max_links = -1
mssql.min_error_severity = 10
mssql.min_message_severity = 10
mssql.compatability_mode = Off
mssql.secure_connection = Off
[Assertion]
[mbstring]
[gd]
[exif]
[Tidy]
tidy.clean_output = Off
[soap]
soap.wsdl_cache_enabled=1
soap.wsdl_cache_dir="/tmp"
soap.wsdl_cache_ttl=86400
soap.wsdl_cache_limit = 5
[sysvshm]
[ldap]
ldap.max_links = -1
[mcrypt]
[dba]

EOF

cp -f /etc/nginx/nginx.conf /etc/nginx/nginx.conf-$BUILD_DATE &> /dev/null

cat > /etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes 1;
pid /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
include /etc/nginx/mime.types;
default_type application/octet-stream;

log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
'\$status \$body_bytes_sent "\$http_referer" '
'"\$http_user_agent" "\$http_x_forwarded_for"';

sendfile on;
keepalive_timeout 65;
gzip on;

include /etc/nginx/conf.d/*.conf;
include /etc/nginx/sites/*.conf;
}

EOF

mkdir /etc/nginx/sites &> /dev/null

ln -s /usr/share/phpmyadmin /usr/share/nginx/html &> /dev/null

systemctl enable php-fpm.service &> /dev/null
systemctl start php-fpm.service &> /dev/null

systemctl enable nginx.service &> /dev/null
systemctl start nginx.service &> /dev/null

fi

if [ $DBSERVER_TYPE = "mysqld" ]
then
rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm &> /dev/null
yum install -y -q mysql-server &> /dev/null
systemctl enable mysqld.service &> /dev/null
systemctl start mysqld.service &> /dev/null
fi

if [ $DBSERVER_TYPE = "mariadb" ]
then
yum install -y -q mariadb-server mariadb &> /dev/null
systemctl enable mariadb.service &> /dev/null
systemctl start mariadb.service &> /dev/null
fi

cat > /root/.my.cnf <<EOF
[client]
user=root
password="your password here"

EOF

yum install -y -q  logwatch &> /dev/null

cp -f /etc/logwatch/conf/logwatch.conf /etc/logwatch/conf/logwatch.conf-$BUILD_DATE &> /dev/null

cat > /etc/logwatch/conf/logwatch.conf <<EOF
# Local configuration options go here (defaults are in /usr/share/logwatch/default.conf/logwatch.conf)
MailFrom = hostmaster@$DOMAIN

EOF

yum install -y -q  postfix &> /dev/null

cp -f /etc/postfix/main.cf /etc/postfix/main.cf-$BUILD_DATE &> /dev/null

cat > /etc/postfix/main.cf <<EOF
queue_directory = /var/spool/postfix
command_directory = /usr/sbin
daemon_directory = /usr/libexec/postfix
data_directory = /var/lib/postfix
mail_owner = postfix
myhostname = $HOST_NAME
mydomain = $DOMAIN
myorigin = \$myhostname
inet_interfaces = localhost
inet_protocols = all
mydestination = \$myorigin, localhost
unknown_local_recipient_reject_code = 550
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
smtpd_banner = \$myhostname
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

cp -f /etc/aliases /etc/aliases-$BUILD_DATE &> /dev/null

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

rm -f ~/.ssh &> /dev/null
ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa &> /dev/null
rm -f ~/.ssh/id_dsa* &> /dev/null

cat > ~/.ssh/authorized_keys <<EOF
$AUTHORIZED_KEYS

EOF

echo "Server setup finished"
echo " "

echo "Complete post setup tasks:"
echo "/usr/bin/mysql_secure_installation"
echo "vim /root/.my.cnf"
echo " "


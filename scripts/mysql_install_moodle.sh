#!/bin/bash

# The MIT License (MIT)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

#parameters
{
    moodleVersion=${1}
    glusterNode=${2}
    glusterVolume=${3}
    siteFQDN=${4}
    mysqlIP=${5}
    moodledbname=${6}
    moodledbuser=${7}
    moodledbpass=${8}
    adminpass=${9}
    mysqladminlogin=${10}
    mysqladminpass=${11}
    wabsacctname=${12}
    wabsacctkey=${13}
    azuremoodledbuser=${14}
    redisDns=${15}
    redisAuth=${16}
    elasticVm1IP=${17}

    echo $moodleVersion        >> /tmp/vars.txt
    echo $glusterNode          >> /tmp/vars.txt
    echo $glusterVolume        >> /tmp/vars.txt
    echo $siteFQDN             >> /tmp/vars.txt
    echo $mysqlIP              >> /tmp/vars.txt
    echo $moodledbname         >> /tmp/vars.txt
    echo $moodledbuser         >> /tmp/vars.txt
    echo $moodledbpass         >> /tmp/vars.txt
    echo    $adminpass         >> /tmp/vars.txt
    echo $mysqladminlogin      >> /tmp/vars.txt
    echo $mysqladminpass       >> /tmp/vars.txt
    echo $wabsacctname         >> /tmp/vars.txt
    echo $wabsacctkey          >> /tmp/vars.txt
    echo $azuremoodledbuser    >> /tmp/vars.txt
    echo $redisDns             >> /tmp/vars.txt
    echo $redisAuth            >> /tmp/vars.txt
    echo $elasticVm1IP         >> /tmp/vars.txt

    # make sure system does automatic updates and fail2ban
    sudo apt-get -y update
    sudo apt-get -y install unattended-upgrades fail2ban

    # configure fail2ban
    cat <<EOF > /etc/fail2ban/jail.conf
# Fail2Ban configuration file.
#
# This file was composed for Debian systems from the original one
# provided now under /usr/share/doc/fail2ban/examples/jail.conf
# for additional examples.
#
# Comments: use '#' for comment lines and ';' for inline comments
#
# To avoid merges during upgrades DO NOT MODIFY THIS FILE
# and rather provide your changes in /etc/fail2ban/jail.local
#

# The DEFAULT allows a global definition of the options. They can be overridden
# in each jail afterwards.

[DEFAULT]

# "ignoreip" can be an IP address, a CIDR mask or a DNS host. Fail2ban will not
# ban a host which matches an address in this list. Several addresses can be
# defined using space separator.
ignoreip = 127.0.0.1/8

# "bantime" is the number of seconds that a host is banned.
bantime  = 600

# A host is banned if it has generated "maxretry" during the last "findtime"
# seconds.
findtime = 600
maxretry = 3

# "backend" specifies the backend used to get files modification.
# Available options are "pyinotify", "gamin", "polling" and "auto".
# This option can be overridden in each jail as well.
#
# pyinotify: requires pyinotify (a file alteration monitor) to be installed.
#            If pyinotify is not installed, Fail2ban will use auto.
# gamin:     requires Gamin (a file alteration monitor) to be installed.
#            If Gamin is not installed, Fail2ban will use auto.
# polling:   uses a polling algorithm which does not require external libraries.
# auto:      will try to use the following backends, in order:
#            pyinotify, gamin, polling.
backend = auto

# "usedns" specifies if jails should trust hostnames in logs,
#   warn when reverse DNS lookups are performed, or ignore all hostnames in logs
#
# yes:   if a hostname is encountered, a reverse DNS lookup will be performed.
# warn:  if a hostname is encountered, a reverse DNS lookup will be performed,
#        but it will be logged as a warning.
# no:    if a hostname is encountered, will not be used for banning,
#        but it will be logged as info.
usedns = warn

#
# Destination email address used solely for the interpolations in
# jail.{conf,local} configuration files.
destemail = root@localhost

#
# Name of the sender for mta actions
sendername = Fail2Ban

#
# ACTIONS
#

# Default banning action (e.g. iptables, iptables-new,
# iptables-multiport, shorewall, etc) It is used to define
# action_* variables. Can be overridden globally or per
# section within jail.local file
banaction = iptables-multiport

# email action. Since 0.8.1 upstream fail2ban uses sendmail
# MTA for the mailing. Change mta configuration parameter to mail
# if you want to revert to conventional 'mail'.
mta = sendmail

# Default protocol
protocol = tcp

# Specify chain where jumps would need to be added in iptables-* actions
chain = INPUT

#
# Action shortcuts. To be used to define action parameter

# The simplest action to take: ban only
action_ = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]

# ban & send an e-mail with whois report to the destemail.
action_mw = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
              %(mta)s-whois[name=%(__name__)s, dest="%(destemail)s", protocol="%(protocol)s", chain="%(chain)s", sendername="%(sendername)s"]

# ban & send an e-mail with whois report and relevant log lines
# to the destemail.
action_mwl = %(banaction)s[name=%(__name__)s, port="%(port)s", protocol="%(protocol)s", chain="%(chain)s"]
               %(mta)s-whois-lines[name=%(__name__)s, dest="%(destemail)s", logpath=%(logpath)s, chain="%(chain)s", sendername="%(sendername)s"]

# Choose default action.  To change, just override value of 'action' with the
# interpolation to the chosen action shortcut (e.g.  action_mw, action_mwl, etc) in jail.local
# globally (section [DEFAULT]) or per specific section
action = %(action_)s

#
# JAILS
#

# Next jails corresponds to the standard configuration in Fail2ban 0.6 which
# was shipped in Debian. Enable any defined here jail by including
#
# [SECTION_NAME]
# enabled = true

#
# in /etc/fail2ban/jail.local.
#
# Optionally you may override any other parameter (e.g. banaction,
# action, port, logpath, etc) in that section within jail.local

[ssh]

enabled  = true
port     = ssh
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 6

[dropbear]

enabled  = false
port     = ssh
filter   = dropbear
logpath  = /var/log/auth.log
maxretry = 6

# Generic filter for pam. Has to be used with action which bans all ports
# such as iptables-allports, shorewall
[pam-generic]

enabled  = false
# pam-generic filter can be customized to monitor specific subset of 'tty's
filter   = pam-generic
# port actually must be irrelevant but lets leave it all for some possible uses
port     = all
banaction = iptables-allports
port     = anyport
logpath  = /var/log/auth.log
maxretry = 6

[xinetd-fail]

enabled   = false
filter    = xinetd-fail
port      = all
banaction = iptables-multiport-log
logpath   = /var/log/daemon.log
maxretry  = 2


[ssh-ddos]

enabled  = false
port     = ssh
filter   = sshd-ddos
logpath  = /var/log/auth.log
maxretry = 6


# Here we use blackhole routes for not requiring any additional kernel support
# to store large volumes of banned IPs

[ssh-route]

enabled = false
filter = sshd
action = route
logpath = /var/log/sshd.log
maxretry = 6

# Here we use a combination of Netfilter/Iptables and IPsets
# for storing large volumes of banned IPs
#
# IPset comes in two versions. See ipset -V for which one to use
# requires the ipset package and kernel support.
[ssh-iptables-ipset4]

enabled  = false
port     = ssh
filter   = sshd
banaction = iptables-ipset-proto4
logpath  = /var/log/sshd.log
maxretry = 6

[ssh-iptables-ipset6]

enabled  = false
port     = ssh
filter   = sshd
banaction = iptables-ipset-proto6
logpath  = /var/log/sshd.log
maxretry = 6


#
# HTTP servers
#

[apache]

enabled  = false
port     = http,https
filter   = apache-auth
logpath  = /var/log/apache*/*error.log
maxretry = 6

# default action is now multiport, so apache-multiport jail was left
# for compatibility with previous (<0.7.6-2) releases
[apache-multiport]

enabled   = false
port      = http,https
filter    = apache-auth
logpath   = /var/log/apache*/*error.log
maxretry  = 6

[apache-noscript]

enabled  = false
port     = http,https
filter   = apache-noscript
logpath  = /var/log/apache*/*error.log
maxretry = 6

[apache-overflows]

enabled  = false
port     = http,https
filter   = apache-overflows
logpath  = /var/log/apache*/*error.log
maxretry = 2

# Ban attackers that try to use PHP's URL-fopen() functionality
# through GET/POST variables. - Experimental, with more than a year
# of usage in production environments.

[php-url-fopen]

enabled = false
port    = http,https
filter  = php-url-fopen
logpath = /var/www/*/logs/access_log

# A simple PHP-fastcgi jail which works with lighttpd.
# If you run a lighttpd server, then you probably will
# find these kinds of messages in your error_log:
#   ALERT – tried to register forbidden variable ‘GLOBALS’
#   through GET variables (attacker '1.2.3.4', file '/var/www/default/htdocs/index.php')

[lighttpd-fastcgi]

enabled = false
port    = http,https
filter  = lighttpd-fastcgi
logpath = /var/log/lighttpd/error.log

# Same as above for mod_auth
# It catches wrong authentifications

[lighttpd-auth]

enabled = false
port    = http,https
filter  = suhosin
logpath = /var/log/lighttpd/error.log

[nginx-http-auth]

enabled = false
filter  = nginx-http-auth
port    = http,https
logpath = /var/log/nginx/error.log

# Monitor roundcube server

[roundcube-auth]

enabled  = false
filter   = roundcube-auth
port     = http,https
logpath  = /var/log/roundcube/userlogins


[sogo-auth]

enabled  = false
filter   = sogo-auth
port     = http, https
# without proxy this would be:
# port    = 20000
logpath  = /var/log/sogo/sogo.log


#
# FTP servers
#

[vsftpd]

enabled  = false
port     = ftp,ftp-data,ftps,ftps-data
filter   = vsftpd
logpath  = /var/log/vsftpd.log
# or overwrite it in jails.local to be
# logpath = /var/log/auth.log
# if you want to rely on PAM failed login attempts
# vsftpd's failregex should match both of those formats
maxretry = 6


[proftpd]

enabled  = false
port     = ftp,ftp-data,ftps,ftps-data
filter   = proftpd
logpath  = /var/log/proftpd/proftpd.log
maxretry = 6


[pure-ftpd]

enabled  = false
port     = ftp,ftp-data,ftps,ftps-data
filter   = pure-ftpd
logpath  = /var/log/syslog
maxretry = 6


[wuftpd]

enabled  = false
port     = ftp,ftp-data,ftps,ftps-data
filter   = wuftpd
logpath  = /var/log/syslog
maxretry = 6


#
# Mail servers
#

[postfix]

enabled  = false
port     = smtp,ssmtp,submission
filter   = postfix
logpath  = /var/log/mail.log


[couriersmtp]

enabled  = false
port     = smtp,ssmtp,submission
filter   = couriersmtp
logpath  = /var/log/mail.log


#
# Mail servers authenticators: might be used for smtp,ftp,imap servers, so
# all relevant ports get banned
#

[courierauth]

enabled  = false
port     = smtp,ssmtp,submission,imap2,imap3,imaps,pop3,pop3s
filter   = courierlogin
logpath  = /var/log/mail.log


[sasl]

enabled  = false
port     = smtp,ssmtp,submission,imap2,imap3,imaps,pop3,pop3s
filter   = postfix-sasl
# You might consider monitoring /var/log/mail.warn instead if you are
# running postfix since it would provide the same log lines at the
# "warn" level but overall at the smaller filesize.
logpath  = /var/log/mail.log

[dovecot]

enabled = false
port    = smtp,ssmtp,submission,imap2,imap3,imaps,pop3,pop3s
filter  = dovecot
logpath = /var/log/mail.log

# To log wrong MySQL access attempts add to /etc/my.cnf:
# log-error=/var/log/mysqld.log
# log-warning = 2
[mysqld-auth]

enabled  = false
filter   = mysqld-auth
port     = 3306
logpath  = /var/log/mysqld.log


# DNS Servers


# These jails block attacks against named (bind9). By default, logging is off
# with bind9 installation. You will need something like this:
#
# logging {
#     channel security_file {
#         file "/var/log/named/security.log" versions 3 size 30m;
#         severity dynamic;
#         print-time yes;
#     };
#     category security {
#         security_file;
#     };
# };
#
# in your named.conf to provide proper logging

# !!! WARNING !!!
#   Since UDP is connection-less protocol, spoofing of IP and imitation
#   of illegal actions is way too simple.  Thus enabling of this filter
#   might provide an easy way for implementing a DoS against a chosen
#   victim. See
#    http://nion.modprobe.de/blog/archives/690-fail2ban-+-dns-fail.html
#   Please DO NOT USE this jail unless you know what you are doing.
#[named-refused-udp]
#
#enabled  = false
#port     = domain,953
#protocol = udp
#filter   = named-refused
#logpath  = /var/log/named/security.log

[named-refused-tcp]

enabled  = false
port     = domain,953
protocol = tcp
filter   = named-refused
logpath  = /var/log/named/security.log

# Multiple jails, 1 per protocol, are necessary ATM:
# see https://github.com/fail2ban/fail2ban/issues/37
[asterisk-tcp]

enabled  = false
filter   = asterisk
port     = 5060,5061
protocol = tcp
logpath  = /var/log/asterisk/messages

[asterisk-udp]

enabled  = false
filter	 = asterisk
port     = 5060,5061
protocol = udp
logpath  = /var/log/asterisk/messages


# Jail for more extended banning of persistent abusers
# !!! WARNING !!!
#   Make sure that your loglevel specified in fail2ban.conf/.local
#   is not at DEBUG level -- which might then cause fail2ban to fall into
#   an infinite loop constantly feeding itself with non-informative lines
[recidive]

enabled  = false
filter   = recidive
logpath  = /var/log/fail2ban.log
action   = iptables-allports[name=recidive]
           sendmail-whois-lines[name=recidive, logpath=/var/log/fail2ban.log]
bantime  = 604800  ; 1 week
findtime = 86400   ; 1 day
maxretry = 5
EOF

    # create gluster mount point
    mkdir -p /moodle

    export DEBIAN_FRONTEND=noninteractive

    # configure gluster repository & install gluster client
    sudo add-apt-repository ppa:gluster/glusterfs-3.8 -y                     >> /tmp/apt1.log
    sudo apt-get -y update                                                   >> /tmp/apt2.log
    sudo apt-get -y --force-yes install rsyslog glusterfs-client mysql-client git    >> /tmp/apt3.log

    # install azure cli & setup container
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" | \
        sudo tee /etc/apt/sources.list.d/azure-cli.list

    sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893 >> /tmp/apt4.log
    sudo apt-get -y install apt-transport-https >> /tmp/apt4.log
    sudo apt-get -y update > /dev/null
    sudo apt-get -y install azure-cli >> /tmp/apt4.log

    az storage container create \
        --name objectfs \
        --account-name $wabsacctname \
        --account-key $wabsacctkey \
        --public-access off \
        --fail-on-exist >> /tmp/wabs.log

    az storage container policy create \
        --account-name $wabsacctname \
        --account-key $wabsacctkey \
        --container-name objectfs \
        --name readwrite \
        --start $(date --date="1 day ago" +%F) \
        --expiry $(date --date="2199-01-01" +%F) \
        --permissions rw >> /tmp/wabs.log

    sas=$(az storage container generate-sas \
        --account-name $wabsacctname \
        --account-key $wabsacctkey \
        --name objectfs \
        --policy readwrite \
        --output tsv)

    # mount gluster files system
    echo -e '\n\rInstalling GlusterFS on '$glusterNode':/'$glusterVolume '/moodle\n\r'
    sudo mount -t glusterfs $glusterNode:/$glusterVolume /moodle



    # install pre-requisites
    sudo apt-get install -y --fix-missing python-software-properties unzip

    # install the entire stack
    sudo apt-get -y  --force-yes install nginx php-fpm varnish >> /tmp/apt5a.log
    sudo apt-get -y  --force-yes install php php-cli php-curl php-zip >> /tmp/apt5b.log

    # Moodle requirements
    sudo apt-get -y update > /dev/null
    sudo apt-get install -y --force-yes graphviz aspell php-common php-soap php-json php-redis > /tmp/apt6.log
    sudo apt-get install -y --force-yes php-bcmath php-gd php-mysql php-xmlrpc php-intl php-xml php-bz2 >> /tmp/apt6.log


    # Set up initial moodle dirs
    mkdir -p /moodle/html
    mkdir -p /moodle/certs
    mkdir -p /moodle/moodledata
    chown -R www-data.www-data /moodle

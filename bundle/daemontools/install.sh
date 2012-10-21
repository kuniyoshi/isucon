#!/bin/sh

if [ `whoami` != 'root' ]
then
    echo 'need root privilege.'
    exit 1
fi

mkdir -p   /package
chmod 1755 /package

DAEMONTOOL=daemontools-0.76
tar zxf $DAEMONTOOL.tar.gz
(cd admin/$DAEMONTOOL && patch -p2 < ../../daemontools-for-redhat9.patch)
mv admin /package/admin && cd /package/admin/$DAEMONTOOL && package/install

if [ -n "`grep release\ 6 /etc/redhat-release`" ]
then
    (umask 022 && cat svscan.conf >/etc/init/svscan.conf)
    initctl reload-configuration
    initctl start svscan
fi

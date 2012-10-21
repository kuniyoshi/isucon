#!/bin/sh
NGINX=nginx-1.2.4
NGINX_BALL="${NGINX}.tar.gz"
OPTIONS=option.list
INIT_FILE=nginx

if [ `echo `whoami`` != "root" ]
then
    echo "need root privilege."
    exit 1
fi

rm -Rf $NGINX
tar zxf $NGINX_BALL
pushd $NGINX
cp ../$OPTIONS $OPTIONS
./configure $(cat $OPTIONS)
make && make install
popd
cp $INIT_FILE /etc/init.d/$INIT_FILE
chown root:root /etc/init.d/$INIT_FILE
chkconfig $INIT_FILE on
chkconfig --list $INIT_FILE

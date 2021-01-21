#!/bin/bash

if [ ! -z $MYADDR ]; then
    echo "Set Your IP Address to continue."
    exit 2
fi

MYDOMAIN=${MYDOMAIN:-ztncui.docker.test}   # Used for minica
ZTNCUI_PASSWD=${ZTNCUI_PASSWD:-password}   # Used for argon2g
MYADDR=${MYADDR}
HTTP_ALL_INTERFACES=${HTTP_ALL_INTERFACES}
HTTP_PORT=${HTTP_PORT:-3000}
HTTPS_PORT=${HTTPS_PORT:-3443}

while [ ! -f /var/lib/zerotier-one/authtoken.secret ]; do
    echo "ZT1 AuthToken is not found... Wait for ZT1 to start..."
    sleep 2
done
chown zerotier-one.zerotier-one /var/lib/zerotier-one/authtoken.secret
chmod 640 /var/lib/zerotier-one/authtoken.secret

cd /opt/key-networks/ztncui

echo "MYADDR=$MYADDR" > /opt/key-networks/ztncui/.env
echo "HTTP_PORT=$HTTP_PORT" >> /opt/key-networks/ztncui/.env
if [ ! -z $HTTP_ALL_INTERFACES ]; then
  echo "HTTP_ALL_INTERFACES=$HTTP_ALL_INTERFACES" >> /opt/key-networks/ztncui/.env
else
  [ ! -z $HTTPS_PORT ] && echo "HTTPS_PORT=$HTTPS_PORT" >> /opt/key-networks/ztncui/.env
fi

mkdir -p etc/storage 
mkdir -p etc/tls

if [ ! -f etc/passwd ]; then
    cd etc/passwd
    echo $ZTNCUI_PASSWD | /usr/bin/argon2g 
    cd ../../
fi

if [ ! -f etc/tls/fullchain.pem ] || [ ! -f etc/tls/privkey.pem ]; then
    cd etc/tls
    /usr/bin/minica -domains "$MYDOMAIN"
    cp -f "$MYDOMAIN/cert.pem" fullchain.pem
    cp -f "$MYDOMAIN/key.pem" privkey.pem
    cd ../../
fi

chown -R zerotier-one:zerotier-one /opt/key-networks/ztncui
chmod 0755 /opt/key-networks/ztncui/ztncui
chown root:root /opt/key-networks/ztncui/ztncui

gosu zerotier-one:zerotier-one /opt/key-networks/ztncui/ztncui
#!/bin/bash

set -x

if [[ $(id -u) != "0" ]]; then
    echo Run as root
    exit
fi

ip=1.1.1.1
nic=eth0

eap_user=myusername
eap_pass=astrongpassword

function install_dep()
{
    apt-get install -y strongswan strongswan-plugin-eap-mschapv2
}

function build_certs()
{
    ip=$1

    mkdir -p vpn-certs
    cd vpn-certs

    # CA
    ipsec pki --gen --type rsa --size 4096 --outform pem > server-root-key.pem
    ipsec pki --self --ca --lifetime 3650 \
        --in server-root-key.pem \
        --type rsa --dn "C=US, O=VPN Server, CN=VPN Server Root CA" \
        --outform pem > server-root-ca.pem

    # VPN
    ipsec pki --gen --type rsa --size 4096 --outform pem > vpn-server-key.pem
    ipsec pki --pub --in vpn-server-key.pem \
        --type rsa | ipsec pki --issue --lifetime 1825 \
        --cacert server-root-ca.pem \
        --cakey server-root-key.pem \
        --dn "C=US, O=VPN Server, CN=$ip" \
        --san $ip \
        --flag serverAuth --flag ikeIntermediate \
        --outform pem > vpn-server-cert.pem

    install -oroot -m600 vpn-server-cert.pem /etc/ipsec.d/certs/vpn-server-cert.pem
    install -oroot -m600 vpn-server-key.pem /etc/ipsec.d/private/vpn-server-key.pem
}

function configure_ipsec()
{
    ip=$1
    eap_user=$2
    eap_pass=$3

    cat > /etc/ipsec.conf<<EOF

config setup
  charondebug="ike 1, knl 1, cfg 0"
  uniqueids=no

conn ikev2-vpn
  auto=add
  compress=no
  type=tunnel
  keyexchange=ikev2
  fragmentation=yes
  forceencaps=yes
  ike=aes256-sha1-modp1024,3des-sha1-modp1024!
  esp=aes256-sha1,3des-sha1!
  dpdaction=clear
  dpddelay=300s
  rekey=no
  left=%any
  leftid=$ip
  leftcert=/etc/ipsec.d/certs/vpn-server-cert.pem
  leftsendcert=always
  leftsubnet=0.0.0.0/0
  right=%any
  rightid=%any
  rightauth=eap-mschapv2
  rightsourceip=10.10.10.0/24
  rightdns=8.8.8.8,8.8.4.4
  rightsendcert=never
  eap_identity=%identity

EOF
    cat > /etc/ipsec.secrets<<EOF

$ip : RSA "/etc/ipsec.d/private/vpn-server-key.pem"
$eap_user %any% : EAP "$eap_pass"

EOF

    ipsec stop
    ipsec start
}

function configure_iptables()
{
    nic=$1

    iptables -I INPUT -i lo -j ACCEPT
    iptables -A INPUT -p udp --dport  500 -j ACCEPT
    iptables -A INPUT -p udp --dport 4500 -j ACCEPT 

    iptables -I FORWARD --match policy --pol ipsec --dir in  --proto esp -s 10.10.10.10/24 -j ACCEPT
    iptables -I FORWARD --match policy --pol ipsec --dir out --proto esp -d 10.10.10.10/24 -j ACCEPT

    iptables -t nat -A POSTROUTING -s 10.10.10.10/24 -o $nic -m policy --pol ipsec --dir out -j ACCEPT
    iptables -t nat -A POSTROUTING -s 10.10.10.10/24 -o $nic -j MASQUERADE
}

function configure_sysctl()
{
    sysctl -w net.ipv4.ip_forward=1
    sysctl -w net.ipv4.conf.all.accept_redirects=0
}

function show_status()
{
    ipsec statusall
}

install_dep 
build_certs "$ip"
configure_ipsec "$ip" "$eap_user" "$eap_pass"
configure_iptables "$nic"
show_status


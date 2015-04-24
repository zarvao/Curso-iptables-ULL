#!/bin/bash

RATE=10
MAX=120
IPT=/sbin/iptables
IP6T=/sbin/ip6tables
TC=/sbin/tc
IF_EXT="enp0s3"

#Borramos la clase raiz
$TC qdisc del dev $IF_EXT root

#Crea la clase raiz

$TC qdisc add dev $IF_EXT root handle 1: htb default 13

#Anade la clase huja de root y pone como garantia RATE y como maximo ancho de banda MAX
$TC class add dev $IF_EXT parent 1: classid 1:1 htb rate ${RATE}kbit ceil ${MAX}kbit

$TC class add dev $IF_EXT parent 1:1 classid 1:10 htb rate 10kbit ceil ${MAX}kbit prio 1

$IPT -t mangle -A OUTPUT -p tcp --sport http -j MARK --set-mark 1
$IPT -t mangle -A OUTPUT -p tcp --sport http -j RETURN


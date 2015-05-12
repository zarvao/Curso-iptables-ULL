#!/bin/bash
#DATE: 12052015
#AUTHOR: Salvador Diego Martin Luis
#EMAIL CONTACT: zarvao@gmail.com
#DESCRIPTION: Script para crear un PORT KNOCKING como práctica final del curso de seguridad iptables
#Para poder abrir con el PORT KNOCKING podemos utilizar el siguiente script
#
#knock.sh
#HOST=$1
#shift
#for ARG in "$@"
#do
#    nmap -PN --host_timeout 201 --max-retries 0 -p $ARG $HOST
#done
#Para comprobar que efectivamente está abierto el puerto ejecutamos la siguiente sentencia con el nmap
#nmap -PN --host_timeout 201 --max-retries 0 -p <PORTKNOCKING> <HOST>
#Lo invocamos como sigue:
#sh knock.sh <HOST> FIRSTPORT SECONDPORT THIRDPORT
#Comprobamos con la sentencia nmap y vermos que ahora está abierto el puerto.
#Y podremos acceder a el servicio.
#
#Posibles mejoras:
#Hacer otro PORT KNOCKING para cerrar el puerto.
    
#Ruta del iptables.
IPT=/sbin/iptables
#Red interna
LAN=eth0 #En este caso es la subred 192.168.1.0
#Puertos del PORT KNOCKING
FIRSTPORT=5698
SECONDPORT=45875
THIRDPORT=1046
#Puerto que abriremos una vez realizado el PORTKNOCKING
OPENPORT=2222

#DEFAULT RULES
$IPT -P INPUT ACCEPT
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD ACCEPT

#Reset former rules to avoid conflicts
$IPT -F
$IPT -F -t nat
$IPT -X

#Esto es para que una vez que la conexion este establecida no vuelva a estar chequeando los paquetes
$IPT -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#Accept loopback established and/or related connections
$IPT -A INPUT -i lo -j ACCEPT

$IPT -A INPUT -i $LAN -p tcp --sport ssh -j ACCEPT
$IPT -A INPUT -i $LAN -p tcp --dport ssh -j ACCEPT

# Reglas de PortKnocking basado en tres puertos (6661, 6662, 6663)
# Las políticas por defecto están establecidas a DROP

# Creación del segundo Knock
$IPT -N IN-KNOCK2
$IPT -A IN-KNOCK2 -m recent --name KNOCK1 --remove
$IPT -A IN-KNOCK2 -m recent --name KNOCK2 --set

# Creación del tercer knock
$IPT -N IN-KNOCK3
$IPT -A IN-KNOCK3 -m recent --name KNOCK2 --remove
$IPT -A IN-KNOCK3 -m recent --name KNOCK3 --set

# Si deseamos mantener un log del knock sobre estos puertos, podemos agregar al final de la definición de cada chain, una linea similar a:
$IPT -A IN-KNOCK3 -j LOG --log-prefix "KNOCK INTRUDER!!!!"

# El mas sencillo, el primer KNOCK
$IPT -A INPUT -m recent --update --name KNOCK1

# Que hacer en caso de cada knock
$IPT -A INPUT  -m state --state NEW -p tcp --dport $FIRSTPORT -m recent --set --name KNOCK1
$IPT -A INPUT  -m state --state NEW -p tcp --dport $SECONDPORT -m recent --rcheck --name KNOCK1 -j IN-KNOCK2
$IPT -A INPUT  -m state --state NEW -p tcp --dport $THIRDPORT -m recent --rcheck --name KNOCK2 -j IN-KNOCK3

# Finalmente abrimos el puerto para quien haya realizado la secuencia correcta
$IPT -A INPUT -p tcp --dport $OPENPORT -m recent --rcheck --name KNOCK3 -j ACCEPT

$IPT -A INPUT -i $LAN -j DROP
$IPT -A FORWARD -i $LAN -j DROP

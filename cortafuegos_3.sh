IPT=/usr/bin/iptables
#Red externa
IFMEGAROUTER=enp0s3
IFWORKER=enp0s8
IFSERVER=enp0s10
IFADMON=enp0s9
IPLOCAL=192.168.4.201
IPSERVER=192.168.5.202

#DEFAULT RULES
$IPT -P INPUT ACCEPT
$IPT -P OUTPUT ACCEPT 
$IPT -P FORWARD ACCEPT

#Reset former rules to avoid conflicts
$IPT -F
$IPT -F -t nat
$IPT -X

#Esto es para que no tenga en cuenta las conexiones ya establecidas
$IPT -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

$IPT -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


#Permitimos trafico http y DNS
$IPT -A FORWARD -p tcp --dport http -j ACCEPT
$IPT -A FORWARD -p tcp --dport domain -j ACCEPT
$IPT -A FORWARD -p udp --dport domain -j ACCEPT

#Permisos a los administradores hacer ssh a todas las redes
$IPT -A FORWARD -p tcp --dport ssh -s 192.168.4.0/24 -j ACCEPT

#Vamos a limitar por tiempo
$IPT -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name malrollo 
$IPT -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 2 --rttl --name malrollo -j DROP
$IPT -A INPUT -p tcp --dport ssh -s 192.168.0.0/16 -j ACCEPT


#limitamos la cantidad de conexiones a uno para la red de Administradores
#$IPT -A INPUT -p tcp --dport ssh -i $IFADMON -j ACCEPT
$IPT -A INPUT -m connlimit --connlimit-upto 1 -p tcp -i $IFADMON --dport ssh -j ACCEPT
$IPT -A INPUT -m connlimit --connlimit-above 1 -p tcp -i $IFADMON --dport ssh -j DROP

#Ahora vamos a utilizar TARPIT
$IPT -A INPUT -i $IFMEGAROUTER -p tcp --dport ssh -j TARPIT

#Hacemos un NAT hacia el web server
$IPT -t nat -A PREROUTING -p tcp -d $IPLOCAL --dport http -j DNAT --to-destination $IPSERVER

#Reglas POSTROUTING
$IPT -t nat -A POSTROUTING -o $IFMEGAROUTER -j MASQUERADE

#Denegamos el resto
$IPT -A INPUT -j DROP
$IPT -A FORWARD -j LOG
$IPT -A FORWARD -j DROP




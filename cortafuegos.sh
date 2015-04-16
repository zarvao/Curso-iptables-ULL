IPT=/usr/bin/iptables
#Red externa
EXT=enp0s3 #En este caso es la subred 10.0.2.0
#Red interna
LAN=enp0s8 #En este caso es la subred 192.168.1.0
#Rango de ips locales (LAN)
IPRANGE=192.168.1.0/24

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

#Reglas INPUT - desde el router
$IPT -A INPUT -i $EXT -p tcp --dport ssh -j ACCEPT
$IPT -A INPUT -i $LAN -p tcp --sport ssh -j ACCEPT #Esto es para hacer ssh desde cortafuegos a la terminal
$IPT -A INPUT -i $EXT -p tcp --sport http -j ACCEPT
$IPT -A INPUT -i $EXT -p udp --sport domain -j ACCEPT
$IPT -A INPUT -i $EXT -p tcp --sport domain -j ACCEPT

#Reglas FORWARD - desde la LAN a Internet
#Habilitamos ssh desde la red de trabajo
$IPT -A FORWARD -i $LAN -p tcp --dport ssh -s $IPRANGE -j ACCEPT

#Habilitamos trafico para http desde la red de trabajo
$IPT -A FORWARD -i $LAN -p tcp --dport http -s $IPRANGE -j ACCEPT

#Habilitamos las consultas DNS para la red de trabajo
$IPT -A FORWARD -i $LAN -p udp --sport domain -s $IPRANGE -j ACCEPT
$IPT -A FORWARD -i $LAN -p tcp --sport domain -s $IPRANGE -j ACCEPT
$IPT -A FORWARD -i $LAN -p udp --dport domain -s $IPRANGE -j ACCEPT
$IPT -A FORWARD -i $LAN -p tcp --dport domain -s $IPRANGE -j ACCEPT

#Habilitamos el trafico FTP para la red interna
$IPT -A FORWARD  -p tcp -m tcp --dport ftp -s $IPRANGE -j ACCEPT
$IPT -A FORWARD  -p tcp -m tcp --dport ftp-data -s $IPRANGE -j ACCEPT
$IPT -A FORWARD  -p tcp -m tcp --sport 1024: --dport 1024: -s $IPRANGE -j ACCEPT



#Reglas POSTROUTING
iptables -t nat -A POSTROUTING -o $EXT -j MASQUERADE

#Denegamos el resto
$IPT -A INPUT -i $LAN -j DROP
$IPT -A FORWARD -i $LAN -j DROP
#$IPT -A FORWARD -i $LAN -j ACCEPT




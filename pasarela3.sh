clear;
echo "0- Instalando DNSMASQUERADE"
sudo killall dnsmasq;
sudo apt-get install dnsmasq;

echo "1- Configurando interfaces...";
sudo ifconfig eth0 down;
sudo ifconfig eth0 192.168.11.50 netmask 255.255.255.0 broadcast 192.168.11.255;
sudo ifconfig eth0:1 192.168.66.1 netmask 255.255.255.0 broadcast 192.168.66.255;
sudo route add default gw 192.168.10.10 eth0;
sudo ifconfig eth0 up;
sudo ifconfig eth0:1 up;

echo "2- Configurando pasarela...";

echo "Podemos indicar que el nameserver tambien es el proxy del centro"
sudo echo -n nameserver 8.8.8.8 > /etc/resolv.conf
sudo echo 1 > /proc/sys/net/ipv4/ip_forward

echo "3- Aplicando normas por defecto en pasarela...";
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT

echo "4- Aplicando FLUSH en las reglas especificas...";
sudo iptables -F INPUT
sudo iptables -F FORWARD
sudo iptables -F OUTPUT
sudo iptables -F -t nat

echo "5- Aplicando NUEVAS REGLAS especificas...";

# http://oceanpark.com/notes/firewall_example.html
## Forward all packets from eth1 (internal network) to eth0 (the internet).
sudo iptables -A FORWARD -i eth0:1 -o eth0 -j ACCEPT

# Forward packets that are part of existing and related connections from eth0 to eth1.
sudo iptables -A FORWARD -i eth0 -o eth0:1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Permit packets in to firewall itself that are part of existing and related connections.
sudo iptables -A INPUT -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

#Allow all inputs to firewall from the internal network and local interfaces
sudo iptables -A INPUT -i eth0:1 -s 0/0 -d 0/0 -j ACCEPT
sudo iptables -A INPUT -i lo -s 0/0 -d 0/0 -j ACCEPT

#Alternative to SNAT -- MASQUERADE
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "6- Miramos si esta activo el DNSMASQUERADE..."
sudo netstat -anlp | grep -w LISTEN

echo "6- Activamos el DNSMASQUERADE..."
sudo service dnsmasq stop
sudo service dnsmasq start

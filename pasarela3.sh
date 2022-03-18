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

echo "4- Aplicando FLUSH en las reglas especificas...";
sudo iptables -F INPUT
sudo iptables -F FORWARD
sudo iptables -F OUTPUT
sudo iptables -F -t nat

echo "3- Aplicando normas por defecto en pasarela...";
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
sudo iptables -P FORWARD ACCEPT

echo "5- Aplicando NUEVAS REGLAS especificas...";

#-j: La regla que se utilizara en las iptables specificadas.
#-i
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -j ACCEPT


sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -m state --state RELATED,ESTABLISHED -j ACCEPT


sudo iptables -A INPUT -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT


sudo iptables -A INPUT -i eth0:1 -s 0/0 -d 0/0 -j ACCEPT



#El nat se basa en una tabla interna en los routers, la cual tiene la funcion de asociar la IP privada de los dispositivos de la red local con una IP publica
#El MASQUERADE para enmascarar la dirección IP privada de un nodo con la dirección IP del cortafuegos/puerta de enlace.
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "6- Miramos si esta activo el DNSMASQUERADE..."
sudo netstat -anlp | grep -w LISTEN

echo "6- Activamos el DNSMASQUERADE..."
sudo service dnsmasq stop
sudo service dnsmasq start

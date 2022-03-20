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

#INPUT: Paquetes que vienen fuera de la maquina.
#OUTPUT: Paquetes generados en la maquina.
#FORWARD: Paquetes que pasan a traves de la maquina, de una intefaz a otra.

echo "5- Aplicando NUEVAS REGLAS especificas...";

#-j: La regla que se utilizara en las iptables specificadas.
#-i: Para especificar la intefaz por donde entran los paquetes.
#-o: Para especificar la interfaz por donde salen los paquetes.
#-A: Para añadir la regla.
sudo iptables -A FORWARD -i enp0s3 -o enp0s8 -j ACCEPT

#-m: especifica un modulo con una coincidencia a usar y si la coincidencia falla se detiene.
#ESTABLISEHD: Es una conexion que el servidor ya conoce.
#RELATED: Se considera una conexion relacionada cuando tiene relacion con una conexion ya establecida, no puede haber una conexion relacionada sin una establecida.
#--state: Los estados que se usan en la regla (creo XD).
sudo iptables -A FORWARD -i enp0s8 -o enp0s3 -m state --state RELATED,ESTABLISHED -j ACCEPT

#Lo mismo que en la anterior pero con INPUT.
sudo iptables -A INPUT -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT

#-s: source: De donde proviene.
#-d: destination: Hacia donde va.
#0/0: Acepta cualquier mascara de red y cualquier red (creo). Y si no es para denegar, pero no creo XD.
sudo iptables -A INPUT -i eth0:1 -s 0/0 -d 0/0 -j ACCEPT

#El nat se basa en una tabla interna en los routers, la cual tiene la funcion de asociar la IP privada de los dispositivos de la red local con una IP publica, tambien se consulta cuando se crea una nueva conexion.
#El MASQUERADE para enmascarar la dirección IP privada de un nodo con la dirección IP del cortafuegos/puerta de enlace.
#POSTROUTING: Paquetes que van a salir de la maquina.
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

echo "6- Miramos si esta activo el DNSMASQUERADE..."
sudo netstat -anlp | grep -w LISTEN

echo "6- Activamos el DNSMASQUERADE..."
sudo service dnsmasq stop
sudo service dnsmasq start

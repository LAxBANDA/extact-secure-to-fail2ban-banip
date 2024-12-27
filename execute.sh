#!/bin/bash

# Nombre de la sesión de screen (puedes cambiarlo si lo deseas)
SCREEN_SESSION_NAME="fail2ban-session"

# Ruta del archivo de Node.js que procesa los logs
NODE_SCRIPT="./procesar_logs.js"

# Verificar si el archivo de Node.js existe
if [ ! -f "$NODE_SCRIPT" ]; then
    echo "El script de Node.js ($NODE_SCRIPT) no existe. Asegúrate de que está en el directorio actual."
    exit 1
fi

# Verificar si la sesión de screen ya existe
if screen -list | grep -q "$SCREEN_SESSION_NAME"; then
    echo "La sesión de screen '$SCREEN_SESSION_NAME' ya está en ejecución."
else
    echo "Iniciando una nueva sesión de screen..."
    # Crear una nueva sesión de screen en segundo plano y ejecutar el script de Node.js
    screen -dmS "$SCREEN_SESSION_NAME" bash -c "node $NODE_SCRIPT"
    
    # Verificar si el script de Node.js se ejecutó correctamente
    if [ $? -ne 0 ]; then
        echo "Hubo un error al ejecutar el script de Node.js dentro de screen."
        exit 1
    fi
    echo "El script de Node.js se está ejecutando en la sesión de screen '$SCREEN_SESSION_NAME'."
fi

# Esperar un poco para asegurarse de que el script de Node.js termine su ejecución
echo "Esperando que el script de Node.js termine..."
sleep 10

# Ahora procesamos las IPs y ejecutamos los comandos fail2ban
# Directorio donde están los archivos generados por el programa de Node.js
DIRECTORY="./secure-failed-ips"

# Verificar si el directorio existe
if [ ! -d "$DIRECTORY" ]; then
    echo "El directorio $DIRECTORY no existe. Asegúrate de que el script Node.js generó los archivos correctamente."
    exit 1
fi

# Recorrer cada archivo dentro del directorio
for file in "$DIRECTORY"/*.txt; do
    # Verificar que haya archivos en el directorio
    if [ ! -e "$file" ]; then
        echo "No se encontraron archivos en $DIRECTORY."
        exit 1
    fi

    echo "Procesando archivo: $file"

    # Leer cada línea del archivo (cada línea contiene una IP)
    while IFS= read -r ip; do
        if [[ -n "$ip" ]]; then
            echo "Baneando IP: $ip"
            # Ejecutar el comando fail2ban-client para banear la IP
            fail2ban-client set sshd banip "$ip"
        fi
    done < "$file"
done

echo "Procesamiento completo."

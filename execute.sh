#!/bin/bash

# Ruta del archivo de Node.js que procesa los logs
NODE_SCRIPT="./procesar_logs.js"
PATTERN="${1:-secure}" # Por defecto, "secure"

SSH_IP=$(echo $SSH_CLIENT | awk '{ print $1 }')

# Verificar si el archivo de Node.js existe
if [ ! -f "$NODE_SCRIPT" ]; then
    echo "El script de Node.js ($NODE_SCRIPT) no existe. Asegúrate de que está en el directorio actual."
    exit 1
fi

node $NODE_SCRIPT $SSH_IP $PATTERN

# Crear una nueva sesión de tmux y ejecutar el script de Node.js con la IP SSH y la IP a excluir
echo "El script de Node.js se está ejecutando"

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

    # Eliminar el archivo después de procesarlo
    echo "Eliminando archivo: $file"
    rm "$file"
done

# Eliminar el directorio si está vacío
if [ -d "$DIRECTORY" ] && [ ! "$(ls -A $DIRECTORY)" ]; then
    echo "Eliminando directorio vacío: $DIRECTORY"
    rmdir "$DIRECTORY"
fi

echo "Procesamiento completo. Archivos eliminados."
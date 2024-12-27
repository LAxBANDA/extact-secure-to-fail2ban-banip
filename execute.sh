#!/bin/bash

# Ruta del archivo de Node.js que procesa los logs
NODE_SCRIPT="./procesar_logs.js"

# Verificar si el archivo de Node.js existe
if [ ! -f "$NODE_SCRIPT" ]; then
    echo "El script de Node.js ($NODE_SCRIPT) no existe. Asegúrate de que está en el directorio actual."
    exit 1
fi

# Ejecutar el script de Node.js
echo "Ejecutando el script de Node.js..."
node "$NODE_SCRIPT"

# Verificar si el script Node.js se ejecutó correctamente
if [ $? -ne 0 ]; then
    echo "El script de Node.js terminó con un error."
    exit 1
fi

echo "Script de Node.js ejecutado con éxito."

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

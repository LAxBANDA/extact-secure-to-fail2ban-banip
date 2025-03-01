const fs = require('fs');
const path = require('path');
const readline = require('readline');

const excludeIP = process.argv[2];
// Verificar si se pasó una IP como parámetro
if (!excludeIP || !/^(?:\d{1,3}\.){3}\d{1,3}$/.test(excludeIP)) {
    console.log('Debes pasar una IP válida para excluir como parámetro (tu ipv4 actual).');
    process.exit(1);
}

const pattern = process.argv[3] || "secure";

// Directorio donde buscar archivos
const logDirectory = '/var/log';

// Directorio de salida
const outputDirectory = path.join(process.cwd(), 'secure-failed-ips');

// Expresión regular para buscar direcciones IPv4 en una línea
const ipRegex = /(?:\d{1,3}\.){3}\d{1,3}/;

// Función para verificar si una línea contiene una IP y agregarla al Set
function parseLine(line, ips) {
    const match = line.match(ipRegex);
    if (match) {
        const ip = match[0];
        (ip !== excludeIP) && ips.add(ip); // Agrega al Set para evitar duplicados
    }
}

// Procesa un archivo y genera un archivo de salida con las IPs
async function processFile(filePath) {
    try {
        const fileName = path.basename(filePath);
        const ips = new Set();

        const fileStream = fs.createReadStream(filePath);
        const rl = readline.createInterface({
            input: fileStream,
            crlfDelay: Infinity, // Maneja diferentes finales de línea (\n, \r\n)
        });

        for await (const line of rl) {
            parseLine(line, ips); // Procesa cada línea
        }

        // Verificar si el directorio de salida existe; si no, crearlo
        if (!fs.existsSync(outputDirectory)) {
            fs.mkdirSync(outputDirectory, { recursive: true });
        }

        // Generar el archivo de salida
        const outputFilePath = path.join(outputDirectory, `${fileName}-ips.txt`);
        fs.writeFileSync(outputFilePath, Array.from(ips).join('\n'), 'utf8');
        console.log(`Archivo generado: ${outputFilePath}`);
    } catch (error) {
        console.error(`Error al procesar el archivo ${filePath}: ${error.message}`);
    }
}

// Buscar archivos en el directorio y procesarlos
function processLogs(directory) {
    try {
        const logFiles = fs.readdirSync(directory).filter((file) => file.includes(pattern) && !file.includes(".gz"))

        if (logFiles.length === 0) {
            console.log(`No se encontraron archivos en ${logsDir} que coincidan con el patrón: ${pattern}`);
            return;
        }

        logFiles.forEach((file) => {
            const filePath = path.join(directory, file);
            processFile(filePath); // Procesa cada archivo encontrado
        });
    } catch (error) {
        console.error(`Error al leer el directorio ${directory}: ${error.message}`);
    }
}

// Ejecutar la búsqueda y el procesamiento de archivos
processLogs(logDirectory);

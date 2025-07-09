#!/bin/bash
# ===============================================================================
# Auto Error Fixer - Monitorea error.log y aplica correcciones automáticas
# ===============================================================================
#
# Uso:
#   ./auto_error_fixer.sh
#
# Este script monitorea el archivo error.log en tiempo real y, cuando detecta
# un nuevo error, intenta aplicar una corrección automática según el tipo de error.
# Las acciones tomadas se registran en auto_error_fixer.log
# ===============================================================================

ERROR_LOG="error.log"
FIXER_LOG="auto_error_fixer.log"

# Función para registrar acciones del fixer
auto_log() {
    local msg="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" | tee -a "$FIXER_LOG"
}

# Función para intentar corregir errores conocidos
auto_fix_error() {
    local error_line="$1"
    auto_log "Detectado error: $error_line"

    # Corregir error de opción inválida
    if echo "$error_line" | grep -qi 'Unknown option'; then
        auto_log "Detectada opción inválida. Mostrando opciones válidas..."
        echo "Opciones válidas disponibles:"
        echo "  --log-level LEVEL    Set logging level (DEBUG, INFO, WARN, ERROR, FATAL)"
        echo "  --auto               Run in automatic mode without prompts"
        echo "  --dry-run            Simulate operations without making changes"
        echo "  --verbose            Enable verbose logging"
        echo "  --skip-tools         Skip installation of modern CLI tools"
        echo "  -h, --help           Show help message"
        echo "  -v, --version        Show version information"
        return
    fi

    # Ejemplo: Corregir error de falta de Starship
    if echo "$error_line" | grep -qi 'starship.*not found'; then
        auto_log "Intentando instalar Starship..."
        if command -v brew >/dev/null 2>&1; then
            brew install starship && auto_log "Starship instalado automáticamente." || auto_log "Fallo al instalar Starship."
        else
            auto_log "Homebrew no está instalado. No se puede instalar Starship automáticamente."
        fi
        return
    fi

    # Ejemplo: Corregir error de permisos en backup
    if echo "$error_line" | grep -qi 'Permission denied'; then
        auto_log "Detectado error de permisos. Sugerencia: Ejecutar con sudo o revisar permisos de directorio."
        return
    fi

    # Puedes agregar más reglas aquí para otros errores comunes

    auto_log "No hay autocorrección definida para este error."
}

# Monitorear error.log en tiempo real
auto_log "Iniciando monitoreo de $ERROR_LOG..."
tail -F "$ERROR_LOG" | while read -r line; do
    # Solo procesar líneas que sean ERROR o FATAL
    if echo "$line" | grep -qE '\b(ERROR|FATAL)\b'; then
        auto_fix_error "$line"
    fi
    # Puedes agregar lógica para evitar procesar la misma línea varias veces si reinicias el script
    # (por ejemplo, guardando el offset o usando un hash de la línea)
done 
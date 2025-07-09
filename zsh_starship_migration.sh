#!/usr/bin/env zsh
clear
# ===============================================================================
#
# Script de Migración de Oh My Zsh a Starship (Multiplataforma para cualquier Mac)
#
# Autor: Gemini (con IA)
# Versión: 1.2.0
#
# Este script automatiza la transición de una configuración de Oh My Zsh
# a una instalación "pura" de Zsh con Starship, plugins modernos y
# herramientas de línea de comandos mejoradas.
#
# Características principales:
#   - Migración automática y segura (con backup y rollback)
#   - Instalación de Starship, plugins y herramientas modernas (eza, bat, fd, fzf, ripgrep)
#   - Compatible con cualquier Mac (Intel o Apple Silicon)
#   - Reporte detallado del estado de la migración y entorno
#   - Logs claros y manejo robusto de errores
#   - Seguro para usuarios avanzados y principiantes
#
# Uso rápido:
#   chmod +x zsh_starship_migration.sh
#   ./zsh_starship_migration.sh           # Ejecuta la migración
#   ./zsh_starship_migration.sh rollback  # Restaura el backup anterior
#   ./zsh_starship_migration.sh report    # Muestra un reporte detallado
#   ./zsh_starship_migration.sh status    # Estado actual de la configuración
#   ./zsh_starship_migration.sh --help    # Ayuda y opciones
#
# Requiere Homebrew instalado. Si no lo tienes, instálalo desde https://brew.sh/
#
# ===============================================================================

# --- CONTEXTO DE ENSEÑANZA ---
# 'set -e' hace que el script termine inmediatamente si un comando falla.
# 'set -o pipefail' asegura que si un comando en una tubería (pipe) falla,
# el código de salida de toda la tubería sea el del comando fallido.
# Son fundamentales para crear scripts robustos y predecibles.
set -e
set -o pipefail

# --- DEFINICIÓN DE VARIABLES GLOBALES Y COLORES ---
# Usar variables para colores y textos mejora la legibilidad y facilita
# el mantenimiento del código. 'readonly' previene que se modifiquen.
readonly C_RED='\033[0;31m'        # #ff0000 - Errores y alertas críticas
readonly C_GREEN='\033[0;32m'      # #00ff00 - Éxitos y confirmaciones
readonly C_BLUE='\033[0;34m'       # #0000ff - Información y títulos
readonly C_YELLOW='\033[0;93m'     # #ffff00 - Advertencias y prompts
readonly C_CYAN='\033[0;36m'       # #00ffff - Información técnica
readonly C_MAGENTA='\033[0;35m'    # #ff00ff - Destacados especiales
readonly C_WHITE='\033[1;37m'      # #ffffff - Texto principal
readonly C_GRAY='\033[0;90m'       # #808080 - Texto secundario
readonly C_NC='\033[0m'            # Reset de color

# --- CONFIGURACIÓN DE GUM ---
readonly GUM_THEME=(
    --selected.foreground="#00ff00"
    --selected.background="#000000"
    --unselected.foreground="#ffffff"
    --unselected.background="#333333"
    --cursor.foreground="#ffff00"
    --cursor.background="#666666"
    --border.foreground="#00ff00"
    --title.foreground="#ffffff"
    --subtitle.foreground="#666666"
    --description.foreground="#cccccc"
)

readonly SCRIPT_VERSION="1.1.0"
readonly BACKUP_BASE_DIR="$HOME/.config/migration_backup"
readonly ZSH_PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"

# Flags para controlar el comportamiento del script. Se inicializan en 'false'.
# Se activarán al parsear los argumentos de entrada.
DRY_RUN=false
VERBOSE=false
SKIP_TOOLS=false
AUTO_MODE=false

# Detectar automáticamente si estamos en un contexto interactivo
if [[ ! -t 0 ]] || [[ -n "$CI" ]] || [[ -n "$NONINTERACTIVE" ]]; then
    AUTO_MODE=true
fi

# Variables para controlar la instalación de herramientas modernas
INSTALL_EZA=true
INSTALL_BAT=true
INSTALL_FD=true
INSTALL_RIPGREP=true
INSTALL_FZF=true

# Variables para plugins de Zsh (se inicializan en false, se activan en select_zsh_plugins)
INSTALL_AUTOSUGGESTIONS=false
INSTALL_SYNTAX_HIGHLIGHTING=false
INSTALL_COMPLETIONS=false
INSTALL_HISTORY_SUBSTRING=false
INSTALL_YOU_SHOULD_USE=false

# Variables para módulos adicionales de Starship
STARSHIP_AWS=false
STARSHIP_KUBERNETES=false

# Variables para funcionalidades avanzadas de DevOps/Developer
STARSHIP_RIGHT_FORMAT=false
STARSHIP_TERRAFORM_WORKSPACE=false

# Variables para personalizaciones adicionales de Zsh
ZSH_HISTORY_ENHANCED=false
ZSH_AUTOCOMPLETION_ENHANCED=false
ZSH_CORRECTION=false
ZSH_PRODUCTIVITY_FUNCTIONS=false

# --- VERIFICACIÓN DE DEPENDENCIAS GUI ---
check_gui_dependencies() {
    if ! command -v gum >/dev/null; then
        log_warn "Gum no está instalado. Instalando..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gum
        else
            log_error "Gum no está disponible. Instálalo manualmente desde: https://github.com/charmbracelet/gum"
            return 1
        fi
    fi
    return 0
}

# --- DETECCIÓN DE VERSIÓN DE GUM Y FLAGS COMPATIBLES ---
get_gum_version() {
    if ! command -v gum >/dev/null; then
        echo "0.0.0"
        return
    fi
    gum --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+'
}

supports_gum_unselected_flags() {
    local version=$(get_gum_version)
    local major=$(echo "$version" | cut -d. -f1)
    local minor=$(echo "$version" | cut -d. -f2)
    local patch=$(echo "$version" | cut -d. -f3)
    # gum >= 0.13.0 soporta los flags unselected
    if (( major > 0 )) || (( major == 0 && minor > 12 )) || (( major == 0 && minor == 12 && patch >= 0 )); then
        return 0
    else
        return 1
    fi
}

# --- DETECCIÓN DE TTY PARA GUM ---
require_tty() {
    if [[ ! -t 0 ]]; then
        echo -e "${C_RED}❌ Este menú requiere una terminal interactiva (TTY). Ejecutá el script desde una terminal real.${C_NC}"
        exit 2
    fi
}

# --- FUNCIONES DE GUI INTERACTIVA (ADAPTATIVAS) ---
show_gui_menu() {
    require_tty
    echo -e "${C_GRAY}[DEBUG] Mostrando menú GUI: $1${C_NC}"
    local title="$1"
    local subtitle="$2"
    local header="$3"
    shift 3
    local options=("$@")
    
    echo -e "${C_BLUE}📋 $title${C_NC}"
    echo -e "${C_GRAY}$subtitle${C_NC}"
    
    # Usar gum choose sin flags problemáticos
    gum choose \
        --header="$header" \
        "${options[@]}"
}

show_gui_multi_select() {
    require_tty
    echo -e "${C_GRAY}[DEBUG] Mostrando multi-select GUI: $1${C_NC}"
    local title="$1"
    local subtitle="$2"
    local header="$3"
    local limit="${4:-5}"
    shift 4
    local options=("$@")
    
    echo -e "${C_BLUE}📋 $title${C_NC}"
    echo -e "${C_GRAY}$subtitle${C_NC}"
    
    # Usar gum choose sin flags problemáticos
    gum choose \
        --header="$header" \
        --limit="$limit" \
        "${options[@]}"
}

show_gui_confirmation() {
    require_tty
    echo -e "${C_GRAY}[DEBUG] Mostrando confirmación GUI: $1${C_NC}"
    local message="$1"
    local affirmative="${2:-Sí, continuar}"
    local negative="${3:-No, cancelar}"
    
    # Usar gum confirm sin flags de color para evitar problemas
    gum confirm \
        --affirmative="$affirmative" \
        --negative="$negative" \
        "$message"
    local result=$?
    echo -e "${C_GRAY}[DEBUG] Resultado de confirmación: $result${C_NC}"
    return $result
}

show_gui_spinner() {
    local title="$1"
    shift
    
    gum spin \
        --spinner="dots" \
        --title="$title" \
        --spinner.foreground="#00ff00" \
        --title.foreground="#ffffff" \
        -- "$@"
}

show_gui_progress() {
    local title="$1"
    local percent="$2"
    
    gum progress \
        --percent="$percent" \
        --width=50 \
        --bar.foreground="#00ff00" \
        --percent.foreground="#ffffff" \
        --title="$title"
}

# --- FUNCIONES UTILITARIAS GLOBALES ---
# Función global para detectar el estado de módulos de Starship
get_starship_module_state() {
    local module="$1"
    local starship_toml="$HOME/.config/starship.toml"
    
    if [[ ! -f "$starship_toml" ]]; then
        echo "false"
        return
    fi
    
    case "$module" in
        "format")
            if grep -q '^format = ".*"' "$starship_toml" 2>/dev/null; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        "add_newline")
            if grep -q '^add_newline = true' "$starship_toml" 2>/dev/null; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        "right_format")
            if grep -q '^right_format = ".*"' "$starship_toml" 2>/dev/null; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        "git_branch"|"git_status")
            if grep -q "\[$module\]" "$starship_toml" 2>/dev/null; then
                if grep -A 5 "\[$module\]" "$starship_toml" 2>/dev/null | grep -q 'disabled = true'; then
                    echo "false"
                else
                    echo "true"
                fi
            else
                echo "false"
            fi
            ;;
        "nodejs"|"python"|"docker_context"|"kubernetes"|"cmd_duration"|"time"|"battery"|"package"|"aws"|"ai_ml"|"openai"|"jobs"|"username"|"hostname"|"shell"|"terraform")
            if grep -q "\[$module\]" "$starship_toml" 2>/dev/null; then
                if grep -A 5 "\[$module\]" "$starship_toml" 2>/dev/null | grep -q 'disabled = true'; then
                    echo "false"
                else
                    echo "true"
                fi
            else
                echo "false"
            fi
            ;;
        "multiline"|"trunc_dir"|"color_dir"|"lang_symbols"|"user_smart"|"host_smart")
            # Estos son configuraciones que se aplican a otros módulos, no módulos independientes
            # Verificamos si están en el format o en configuraciones específicas
            if grep -q "multiline\|truncation_length\|style.*directory\|style.*git\|style.*username\|style.*hostname" "$starship_toml" 2>/dev/null; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        "custom_symbols")
            # Verificar si hay símbolos personalizados en la configuración
            if grep -q "symbol.*=.*[^a-zA-Z0-9]" "$starship_toml" 2>/dev/null; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        *)
            # Para módulos que no están en la configuración actual
            echo "false"
            ;;
    esac
}

# Función global para detectar el estado de características de Zsh
get_zsh_feature_state() {
    local feature="$1"
    if [[ -f "$HOME/.zshrc" ]]; then
        case "$feature" in
            "history_enhanced")
                if grep -q "HISTSIZE\|SAVEHIST\|HISTFILE\|HISTDUP\|HISTCONTROL" "$HOME/.zshrc" 2>/dev/null; then
                    echo "true"
                else
                    echo "false"
                fi
                ;;
            "autocompletion_enhanced")
                if grep -q "autoload.*compinit\|zstyle.*completion\|zstyle.*menu" "$HOME/.zshrc" 2>/dev/null; then
                    echo "true"
                else
                    echo "false"
                fi
                ;;
            "correction")
                if grep -q "setopt.*correct\|setopt.*correctall\|CORRECT\|CORRECT_ALL" "$HOME/.zshrc" 2>/dev/null; then
                    echo "true"
                else
                    echo "false"
                fi
                ;;
            "productivity_functions")
                if grep -q "function.*mkcd\|function.*extract\|function.*backup" "$HOME/.zshrc" 2>/dev/null; then
                    echo "true"
                else
                    echo "false"
                fi
                ;;
            *)
                if grep -q "$feature" "$HOME/.zshrc" 2>/dev/null; then
                    echo "true"
                else
                    echo "false"
                fi
                ;;
        esac
    else
        echo "false"
    fi
}

# --- FUNCIONES DE LOGGING ---
# Modularizar el logging en funciones permite controlar el nivel de detalle
# (ej. modo --verbose) y estandarizar el formato de salida.

log_info() {
    echo -e "${C_BLUE}ℹ️  $1${C_NC}"
}

log_success() {
    echo -e "${C_GREEN}✅ $1${C_NC}"
}

log_error() {
    # Los errores se redirigen a stderr (> &2), que es la práctica estándar.
    echo -e "${C_RED}❌ $1${C_NC}" >&2
}

log_warn() {
    echo -e "${C_YELLOW}⚠️  $1${C_NC}"
}

log_verbose() {
    if [[ "$VERBOSE" = true ]]; then
        echo -e "${C_YELLOW}   [VERBOSE] $1${C_NC}"
    fi
}

# Nueva función para mostrar resultados concisos
log_result() {
    local success="$1"
    local message="$2"
    if [[ "$success" = true ]]; then
        echo -e "${C_GREEN}✅ $message${C_NC}"
    else
        echo -e "${C_RED}❌ $message${C_NC}"
    fi
}

# Función para capturar y loggear errores de Starship
log_starship_errors() {
    local starship_output
    starship_output=$(starship config --help 2>&1)
    if echo "$starship_output" | grep -q "WARN\|ERROR"; then
        log_warn "Starship detectó problemas en la configuración:"
        echo "$starship_output" | grep -E "WARN|ERROR" | while read -r line; do
            log_warn "  $line"
        done
        return 1
    fi
    return 0
}

# Función para capturar errores del sistema y terminal
log_system_errors() {
    local error_count=0
    
    # Verificar errores de iconv
    if grep -q "iconv" "$HOME/.zshrc" 2>/dev/null; then
        log_warn "Archivo .zshrc contiene referencias a iconv (puede causar errores)"
        ((error_count++))
    fi
    
    # Verificar funciones problemáticas
    if grep -q "omz_urlencode\|omz_urldecode" "$HOME/.zshrc" 2>/dev/null; then
        log_warn "Archivo .zshrc contiene funciones problemáticas (omz_urlencode/omz_urldecode)"
        ((error_count++))
    fi
    
    # Verificar plugin rand-quote
    if [[ -d "$ZSH/plugins/rand-quote" ]] && [[ ! -d "$ZSH/plugins/rand-quote.disabled" ]]; then
        log_warn "Plugin rand-quote está activo (puede causar errores iconv)"
        ((error_count++))
    fi
    
    # Verificar configuración de Starship
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        # Verificar formatos problemáticos (solo formatos vacíos como []() )
        if grep -q "format.*\[.*\].*\(\)" "$HOME/.config/starship.toml" | grep -v "\$"; then
            log_warn "Configuración Starship tiene formatos problemáticos"
            ((error_count++))
        fi
        
        # Verificar módulos custom problemáticos
        if grep -q "custom_public_ip\|custom_weather" "$HOME/.config/starship.toml"; then
            log_warn "Configuración Starship tiene módulos custom problemáticos"
            ((error_count++))
        fi
    fi
    
    # Verificar alias problemáticos
    if grep -q "alias grep.*ripgrep" "$HOME/.zshrc" 2>/dev/null; then
        log_warn "Alias de grep apunta a ripgrep en lugar de rg"
        ((error_count++))
    fi
    
    return $error_count
}

# Función para validar configuración de Starship
validate_starship_config() {
    log_verbose "Validando configuración de Starship..."
    
    # Verificar que el archivo de configuración existe
    if [[ ! -f "$HOME/.config/starship.toml" ]]; then
        log_error "Archivo de configuración de Starship no existe"
        return 1
    fi
    
    # Verificar que el formato no esté vacío
    if grep -q '^format = ""' "$HOME/.config/starship.toml"; then
        log_error "Formato de Starship está vacío - corrigiendo automáticamente"
        fix_starship_format
        return 1
    fi
    
    # Verificar que el formato tenga contenido válido
    if ! grep -q '^format = ".*\$.*"' "$HOME/.config/starship.toml"; then
        log_error "Formato de Starship no tiene variables válidas - corrigiendo automáticamente"
        fix_starship_format
        return 1
    fi
    
    # Verificar que no haya errores de configuración
    if ! log_starship_errors; then
        log_error "Configuración de Starship tiene errores"
        return 1
    fi
    
    log_verbose "Configuración de Starship válida"
    return 0
}

# Función para corregir automáticamente el formato de Starship
fix_starship_format() {
    log_info "🔧 Corrigiendo formato de Starship..."
    
    # Crear formato básico si no existe
    local starship_config="$HOME/.config/starship.toml"
    
    # Verificar si el archivo existe
    if [[ ! -f "$starship_config" ]]; then
        log_info "Creando configuración básica de Starship..."
        mkdir -p "$HOME/.config"
        cat > "$starship_config" << 'EOF'
# Configuración básica de Starship
add_newline = true

format = "$username$hostname$directory$git_branch$git_status$nodejs$python$docker_context$kubernetes$terraform$cmd_duration$character"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncation_length = 3
style = "bold blue"

[git_branch]
symbol = "🌱 "
style = "bold yellow"

[git_status]
style = "bold red"

[nodejs]
disabled = false

[python]
disabled = false

[docker_context]
disabled = false

[kubernetes]
disabled = false

[terraform]
disabled = false

[cmd_duration]
min_time = 500
format = "⏱ [$duration](\$style) "
style = "yellow bold"

[time]
disabled = false
format = "🕒 [\$time](\$style) "
style = "bold blue"

[battery]
disabled = false
full_symbol = "🔋"
charging_symbol = "⚡"
discharging_symbol = "🔌"
format = "[\$symbol\$percentage](\$style) "
style = "bold green"

[username]
disabled = false
format = "[\$user](\$style) "
style_user = "bold green"
show_always = false

[hostname]
disabled = false
format = "[\$hostname](\$style) "
style = "bold blue"
ssh_only = true
EOF
        log_success "Configuración básica de Starship creada"
        return 0
    fi
    
    # Corregir formato vacío
    if grep -q '^format = ""' "$starship_config"; then
        log_info "Corrigiendo formato vacío..."
        sed -i '' 's/format = ""/format = "$username$hostname$directory$git_branch$git_status$nodejs$python$docker_context$kubernetes$terraform$cmd_duration$character"/' "$starship_config"
        log_success "Formato corregido"
    fi
    
    # Corregir right_format vacío o duplicado
    if grep -q '^right_format = ""' "$starship_config" || grep -q 'right_format = ".*\$username.*"' "$starship_config"; then
        log_info "Corrigiendo right_format..."
        sed -i '' 's/right_format = ".*"/right_format = "$cmd_duration$time$battery"/' "$starship_config"
        log_success "Right format corregido"
    fi
    
    # Corregir configuración de battery si tiene claves inválidas
    if grep -q "charging_style\|discharging_style\|unknown_style" "$starship_config"; then
        log_info "Corrigiendo configuración de battery..."
        sed -i '' '/charging_style = /d' "$starship_config"
        sed -i '' '/discharging_style = /d' "$starship_config"
        sed -i '' '/unknown_style = /d' "$starship_config"
        log_success "Configuración de battery corregida"
    fi
    # Eliminar cualquier línea 'style = ...' dentro de [battery]
    if grep -q '^\[battery\]' "$starship_config"; then
        log_info "Eliminando 'style = ...' dentro de [battery] para evitar warnings"
        # Buscar el bloque [battery] y eliminar líneas style = ... dentro de ese bloque
        awk '
        BEGIN {in_battery=0}
        /^\[battery\]/ {in_battery=1; print; next}
        /^\[/ {in_battery=0}
        in_battery && /^style[ ]*=/ {next}
        {print}
        ' "$starship_config" > "$starship_config.tmp" && mv "$starship_config.tmp" "$starship_config"
        log_success "Líneas 'style = ...' eliminadas del bloque [battery]"
    fi
    
    # Verificar que el prompt funcione
    if starship prompt --status 0 >/dev/null 2>&1; then
        log_success "Prompt de Starship funcionando correctamente"
        return 0
    else
        log_error "Prompt de Starship aún no funciona"
        return 1
    fi
}

# Función de logging completo del sistema
comprehensive_logging() {
    # Log de errores del sistema
    log_system_errors
    local system_errors=$?
    
    # Log de errores de Starship
    local starship_errors=0
    if ! log_starship_errors; then
        starship_errors=1
    fi
    
    # Resumen final
    local total_errors=$((system_errors + starship_errors))
    if [[ $total_errors -eq 0 ]]; then
        log_result true "Verificación de errores"
    else
        log_result false "Verificación de errores ($total_errors problema(s))"
    fi
}

# --- FUNCIONES CORE DEL SCRIPT ---

# Valida que el sistema cumple los requisitos para la migración.
# Es una buena práctica validar el entorno antes de empezar a hacer cambios.
validate_system() {
    local has_error=false
    local omz_found=false
    
    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "Este script está optimizado para macOS. Se ha detectado '$OSTYPE'."
        exit 1
    fi

    command -v zsh >/dev/null || { log_error "Zsh no está instalado. Instala Zsh antes de continuar."; has_error=true; }
    command -v git >/dev/null || { log_error "Git no está instalado."; has_error=true; }
    command -v brew >/dev/null || { log_error "Homebrew no está instalado. Instálalo desde https://brew.sh/"; has_error=true; }
    ping -c 1 8.8.8.8 >/dev/null 2>&1 || { log_error "No hay conexión a internet."; has_error=true; }
    [[ -f "$HOME/.zshrc" ]] || { log_error "No se encontró el archivo ~/.zshrc. Se creará uno nuevo durante la migración."; }
    
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        omz_found=true
    fi

    if [[ "$has_error" = true ]]; then
        log_error "Fallo en la validación. Abortando misión."
        exit 1
    fi
    
    log_result true "Sistema validado"
    export OMZ_FOUND="$omz_found"
}

# Crea un backup de la configuración actual.
# La seguridad es lo primero: nunca hagas cambios destructivos sin un backup.
create_backup() {
    local timestamp
    timestamp=$(date +'%Y%m%d_%H%M%S')
    local backup_dir="$BACKUP_BASE_DIR/$timestamp"
    
    # Exportamos esta variable para que sea accesible en la función main al final.
    export MIGRATION_BACKUP_PATH="$backup_dir"

    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se crearía un backup en: $backup_dir"
        return
    fi
    
    mkdir -p "$backup_dir"

    # Respaldar .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$backup_dir/"
    fi

    # Respaldar directorio de Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        # Usamos cp -R para copiar el directorio de forma recursiva.
        cp -R "$HOME/.oh-my-zsh" "$backup_dir/"
    fi

    # Respaldar config existente de starship
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        cp "$HOME/.config/starship.toml" "$backup_dir/"
    fi
    
    log_result true "Backup creado"
}

# Analiza el .zshrc para extraer configuraciones personales.
# Utiliza 'grep' y 'awk' para parsear el archivo. Es una técnica de scripting
# muy potente para extraer datos de ficheros de texto.
analyze_config() {
    local zshrc_file="$HOME/.zshrc"

    # Extraer alias, excluyendo líneas comentadas y las que vienen de OMZ.
    USER_ALIASES=$(grep -E '^[[:space:]]*alias[[:space:]]' "$zshrc_file" | grep -v '^[[:space:]]*#' | sort -u)
    COUNT_ALIASES=$(echo "$USER_ALIASES" | grep -c '^alias' || echo 0)

    # Extraer exports.
    USER_EXPORTS=$(grep -E '^[[:space:]]*export[[:space:]]' "$zshrc_file" | grep -v '^[[:space:]]*#' | sort -u)
    COUNT_EXPORTS=$(echo "$USER_EXPORTS" | grep -c '^export' || echo 0)

    # Extraer funciones. Mejorado para soportar funciones complejas y anidadas.
    USER_FUNCTIONS=""
    if grep -qE '^[[:space:]]*(function[[:space:]]+[a-zA-Z0-9_-]+|[a-zA-Z0-9_-]+[[:space:]]*\(\)[[:space:]]*\{)' "$zshrc_file"; then
        USER_FUNCTIONS=$(awk '
            BEGIN { in_func=0; brace_count=0; buffer=""; }
            /^[[:space:]]*function[[:space:]]+[a-zA-Z0-9_-]+[[:space:]]*\(|^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*\(\)[[:space:]]*\{/ {
                if (in_func == 0) {
                    in_func=1;
                    buffer=$0;
                    brace_count=gsub(/{/, "{") - gsub(/}/, "}");
                    if (brace_count == 0 && $0 ~ /\{.*\}/) {
                        print buffer; in_func=0; buffer="";
                    }
                    next;
                }
            }
            in_func {
                buffer = buffer "\n" $0;
                brace_count += gsub(/{/, "{") - gsub(/}/, "}");
                if (brace_count == 0) {
                    print buffer; in_func=0; buffer="";
                }
            }
        ' "$zshrc_file")
        if [[ $? -ne 0 ]]; then
            log_error "Error al extraer funciones del .zshrc."
            USER_FUNCTIONS=""
        fi
    fi
    # Eliminar duplicaciones en funciones (mantener solo la primera ocurrencia de cada función)
    if [[ -n "$USER_FUNCTIONS" ]]; then
        USER_FUNCTIONS=$(echo "$USER_FUNCTIONS" | awk '
            BEGIN { 
                seen[""] = 0; 
                in_func = 0; 
                current_func = ""; 
                buffer = ""; 
                brace_count = 0;
            }
            /^[[:space:]]*function[[:space:]]+[a-zA-Z0-9_-]+[[:space:]]*\(|^[[:space:]]*[a-zA-Z0-9_-]+[[:space:]]*\(\)[[:space:]]*\{/ {
                # Extraer nombre de función
                if ($0 ~ /^[[:space:]]*function[[:space:]]+/) {
                    gsub(/^[[:space:]]*function[[:space:]]+/, "", $0);
                    gsub(/[[:space:]]*\(.*$/, "", $0);
                    func_name = $0;
                } else {
                    gsub(/^[[:space:]]*/, "", $0);
                    gsub(/[[:space:]]*\(\)[[:space:]]*\{.*$/, "", $0);
                    func_name = $0;
                }
                
                if (!(func_name in seen)) {
                    seen[func_name] = 1;
                    if (in_func) {
                        # Imprimir función anterior si existe
                        print buffer;
                    }
                    in_func = 1;
                    current_func = func_name;
                    buffer = $0;
                    brace_count = gsub(/{/, "{") - gsub(/}/, "}");
                } else {
                    in_func = 0;
                    buffer = "";
                    brace_count = 0;
                }
                next;
            }
            in_func {
                buffer = buffer "\n" $0;
                brace_count += gsub(/{/, "{") - gsub(/}/, "}");
                if (brace_count <= 0) {
                    print buffer;
                    in_func = 0;
                    buffer = "";
                    brace_count = 0;
                }
            }
            END {
                if (in_func && buffer != "") {
                    print buffer;
                }
            }
        ')
    fi
    COUNT_FUNCTIONS=$(echo "$USER_FUNCTIONS" | grep -Ec '^[[:space:]]*(function|[a-zA-Z0-9_-]+[[:space:]]*\(\))' || echo 0)

    # Exportar los contadores para el mensaje final.
    export COUNT_ALIASES COUNT_EXPORTS COUNT_FUNCTIONS
    log_result true "Configuración analizada ($COUNT_ALIASES alias, $COUNT_EXPORTS exports, $COUNT_FUNCTIONS funciones)"
}

# Selección de plugins de Zsh
select_zsh_plugins() {
    if [[ "$AUTO_MODE" = true ]]; then
        # Modo automático: instalar todos los plugins por defecto
        log_info "Modo automático: instalando todos los plugins por defecto"
        INSTALL_AUTOSUGGESTIONS=true
        INSTALL_SYNTAX_HIGHLIGHTING=true
        INSTALL_COMPLETIONS=true
        INSTALL_HISTORY_SUBSTRING=true
        INSTALL_YOU_SHOULD_USE=true
        export INSTALL_AUTOSUGGESTIONS INSTALL_SYNTAX_HIGHLIGHTING INSTALL_COMPLETIONS INSTALL_HISTORY_SUBSTRING INSTALL_YOU_SHOULD_USE
    else
        # Modo interactivo: usar GUI moderna
        check_gui_dependencies
        
        log_info "Configuración de plugins de Zsh:"
        
        local selected_plugins=$(show_gui_multi_select \
            "Plugins de Zsh" \
            "Selecciona los plugins que deseas instalar (espacio para marcar, enter para confirmar)" \
            "Plugins disponibles:" \
            5 \
            "zsh-autosuggestions [Sugerencias automáticas de comandos]" \
            "zsh-syntax-highlighting [Resaltado de sintaxis en tiempo real]" \
            "zsh-completions [Completado avanzado y mejorado]" \
            "zsh-history-substring-search [Búsqueda inteligente en historial]" \
            "zsh-you-should-use [Sugerencias de alias y comandos]")
        
        # Inicializar todos los plugins como false
        INSTALL_AUTOSUGGESTIONS=false
        INSTALL_SYNTAX_HIGHLIGHTING=false
        INSTALL_COMPLETIONS=false
        INSTALL_HISTORY_SUBSTRING=false
        INSTALL_YOU_SHOULD_USE=false
        
        # Activar plugins seleccionados
        while IFS= read -r plugin; do
            case "$plugin" in
                "zsh-autosuggestions [Sugerencias automáticas de comandos]")
                    INSTALL_AUTOSUGGESTIONS=true
                    ;;
                "zsh-syntax-highlighting [Resaltado de sintaxis en tiempo real]")
                    INSTALL_SYNTAX_HIGHLIGHTING=true
                    ;;
                "zsh-completions [Completado avanzado y mejorado]")
                    INSTALL_COMPLETIONS=true
                    ;;
                "zsh-history-substring-search [Búsqueda inteligente en historial]")
                    INSTALL_HISTORY_SUBSTRING=true
                    ;;
                "zsh-you-should-use [Sugerencias de alias y comandos]")
                    INSTALL_YOU_SHOULD_USE=true
                    ;;
            esac
        done <<< "$selected_plugins"
        
        export INSTALL_AUTOSUGGESTIONS INSTALL_SYNTAX_HIGHLIGHTING INSTALL_COMPLETIONS INSTALL_HISTORY_SUBSTRING INSTALL_YOU_SHOULD_USE
    fi
}

# Maneja las dependencias entre módulos de Starship
handle_dependencies() {
    log_verbose "Verificando dependencias entre módulos..."
    
    # Si right_format está desactivado, desactivar también los módulos que solo aparecen en el right prompt
    if [[ "$STARSHIP_RIGHT_FORMAT" = false ]]; then
        log_verbose "Right format desactivado - verificando módulos del right prompt..."
        # Estos módulos solo aparecen en el right prompt, así que los desactivamos si right_format está off
        if [[ "$STARSHIP_CMD_DURATION" = true ]]; then
            log_verbose "Desactivando cmd_duration (depende de right_format)"
            STARSHIP_CMD_DURATION=false
        fi
        if [[ "$STARSHIP_TIME" = true ]]; then
            log_verbose "Desactivando time (depende de right_format)"
            STARSHIP_TIME=false
        fi
        if [[ "$STARSHIP_BATTERY" = true ]]; then
            log_verbose "Desactivando battery (depende de right_format)"
            STARSHIP_BATTERY=false
        fi
        # Los módulos custom pueden aparecer en ambos prompts, así que los mantenemos
    fi
    
    # Si cmd_duration, time, battery están desactivados, verificar si right_format debería estar desactivado
    if [[ "$STARSHIP_RIGHT_FORMAT" = true ]]; then
        local right_modules_count=0
        [[ "$STARSHIP_CMD_DURATION" = true ]] && ((right_modules_count++))
        [[ "$STARSHIP_TIME" = true ]] && ((right_modules_count++))
        [[ "$STARSHIP_BATTERY" = true ]] && ((right_modules_count++))
        
        if [[ $right_modules_count -eq 0 ]]; then
            log_verbose "No hay módulos para el right prompt - desactivando right_format"
            STARSHIP_RIGHT_FORMAT=false
        fi
    fi
    
    # Dependencias de Kubernetes
    if [[ "$STARSHIP_KUBERNETES" = false ]]; then
        if [[ "$STARSHIP_KUBERNETES_CONTEXT" = true ]]; then
            log_verbose "Desactivando kubernetes_context (depende de kubernetes)"
            STARSHIP_KUBERNETES_CONTEXT=false
        fi
    fi
    
    # Dependencias de Docker
    if [[ "$STARSHIP_DOCKER" = false ]]; then
        if [[ "$STARSHIP_DOCKER_DETAILED" = true ]]; then
            log_verbose "Desactivando docker_detailed (depende de docker)"
            STARSHIP_DOCKER_DETAILED=false
        fi
    fi
    
    # Dependencias de batería
    if [[ "$STARSHIP_BATTERY" = false ]]; then
        if [[ "$STARSHIP_BATTERY_SMART" = true ]]; then
            log_verbose "Desactivando battery_smart (depende de battery)"
            STARSHIP_BATTERY_SMART=false
        fi
    fi
    
    log_verbose "Dependencias verificadas"
}

# Selección interactiva de customizaciones de Starship usando GUI moderna
select_starship_features() {
    if [[ "$AUTO_MODE" = true ]]; then
        # Modo automático: seleccionar todas las opciones sin interacción
        log_info "Modo automático: aplicando configuración completa por defecto"
        STARSHIP_THEME="Pastel Powerline"
        STARSHIP_BLANK_LINE=true
        STARSHIP_GIT=true
        STARSHIP_NODEJS=true
        STARSHIP_PYTHON=true
        STARSHIP_DOCKER=true
        STARSHIP_CUSTOM_SYMBOLS=true
        # Personalizaciones avanzadas
        STARSHIP_MULTILINE=true
        STARSHIP_TRUNC_DIR=true
        STARSHIP_COLOR_DIR=true
        STARSHIP_LANG_SYMBOLS=true
        STARSHIP_CMD_DURATION=true
        STARSHIP_USER_SMART=true
        STARSHIP_HOST_SMART=true
        STARSHIP_BATTERY=true
        STARSHIP_JOBS=true
        STARSHIP_TIME=true
        STARSHIP_PKG_VERSION=true
        STARSHIP_SHELL=true
        # Nuevos módulos
        STARSHIP_AWS=true
        STARSHIP_KUBERNETES=true
        # Funcionalidades avanzadas de DevOps/Developer
        STARSHIP_RIGHT_FORMAT=true
        STARSHIP_TERRAFORM_WORKSPACE=true
        # Personalizaciones de Zsh
        ZSH_HISTORY_ENHANCED=true
        ZSH_AUTOCOMPLETION_ENHANCED=true
        ZSH_CORRECTION=true
        ZSH_PRODUCTIVITY_FUNCTIONS=true
    else
        # Modo interactivo: usar GUI moderna
        check_gui_dependencies
        
        log_info "Configuración de personalizaciones de Starship:"
        
        # Selección de módulos básicos
        local basic_modules=$(show_gui_multi_select \
            "Módulos Básicos de Starship" \
            "Selecciona los módulos básicos que deseas habilitar" \
            "Módulos disponibles:" \
            7 \
            "Tema personalizado (Pastel Powerline) [Diseño visual]" \
            "Línea en blanco entre prompts [Mejor legibilidad]" \
            "Integración Git [Rama y estado del repositorio]" \
            "Módulo Node.js [Versión de Node.js]" \
            "Módulo Python [Versión de Python]" \
            "Módulo Docker [Contexto de Docker]" \
            "Símbolos personalizados [Iconos personalizados]")
        
        # Selección de personalizaciones avanzadas
        local advanced_features=$(show_gui_multi_select \
            "Personalizaciones Avanzadas" \
            "Selecciona las características avanzadas que deseas habilitar" \
            "Características disponibles:" \
            9 \
            "Prompt multilínea [Prompt en múltiples líneas]" \
            "Truncado de directorio [Rutas largas acortadas]" \
            "Colores de directorio [Colores en rutas]" \
            "Símbolos de lenguajes [Iconos de lenguajes]" \
            "Duración de comandos [Tiempo de ejecución]" \
            "Usuario inteligente [Mostrar solo si no es el usuario por defecto]" \
            "Host inteligente [Mostrar solo si no es localhost]" \
            "Batería [Estado de la batería]" \
            "Jobs en background [Procesos en segundo plano]")
        
        # Selección de módulos DevOps/Developer
        local devops_modules=$(show_gui_multi_select \
            "Módulos DevOps/Developer" \
            "Selecciona los módulos de desarrollo que deseas habilitar" \
            "Módulos disponibles:" \
            4 \
            "Módulo AWS [Información de AWS]" \
            "Módulo Kubernetes [Contexto de Kubernetes]" \
            "Right prompt [Prompt derecho con información adicional]" \
            "Workspace de Terraform [Estado de Terraform]")
        
        # Selección de personalizaciones de Zsh
        local zsh_features=$(show_gui_multi_select \
            "Personalizaciones de Zsh" \
            "Selecciona las mejoras de Zsh que deseas habilitar" \
            "Características disponibles:" \
            4 \
            "Historial mejorado [Configuración avanzada del historial]" \
            "Autocompletado mejorado [Completado más inteligente]" \
            "Corrección de comandos [Corrección automática]" \
            "Funciones de productividad [Funciones útiles adicionales]")
        
        # Inicializar todas las opciones como false
        STARSHIP_THEME=""
        STARSHIP_BLANK_LINE=false
        STARSHIP_GIT=false
        STARSHIP_NODEJS=false
        STARSHIP_PYTHON=false
        STARSHIP_DOCKER=false
        STARSHIP_CUSTOM_SYMBOLS=false
        STARSHIP_MULTILINE=false
        STARSHIP_TRUNC_DIR=false
        STARSHIP_COLOR_DIR=false
        STARSHIP_LANG_SYMBOLS=false
        STARSHIP_CMD_DURATION=false
        STARSHIP_USER_SMART=false
        STARSHIP_HOST_SMART=false
        STARSHIP_BATTERY=false
        STARSHIP_JOBS=false
        STARSHIP_TIME=false
        STARSHIP_PKG_VERSION=false
        STARSHIP_SHELL=false
        STARSHIP_AWS=false
        STARSHIP_KUBERNETES=false
        STARSHIP_RIGHT_FORMAT=false
        STARSHIP_TERRAFORM_WORKSPACE=false
        ZSH_HISTORY_ENHANCED=false
        ZSH_AUTOCOMPLETION_ENHANCED=false
        ZSH_CORRECTION=false
        ZSH_PRODUCTIVITY_FUNCTIONS=false
        
        # Procesar selecciones de módulos básicos
        while IFS= read -r module; do
            case "$module" in
                "Tema personalizado (Pastel Powerline) [Diseño visual]")
                    STARSHIP_THEME="Pastel Powerline"
                    ;;
                "Línea en blanco entre prompts [Mejor legibilidad]")
                    STARSHIP_BLANK_LINE=true
                    ;;
                "Integración Git [Rama y estado del repositorio]")
                    STARSHIP_GIT=true
                    ;;
                "Módulo Node.js [Versión de Node.js]")
                    STARSHIP_NODEJS=true
                    ;;
                "Módulo Python [Versión de Python]")
                    STARSHIP_PYTHON=true
                    ;;
                "Módulo Docker [Contexto de Docker]")
                    STARSHIP_DOCKER=true
                    ;;
                "Símbolos personalizados [Iconos personalizados]")
                    STARSHIP_CUSTOM_SYMBOLS=true
                    ;;
            esac
        done <<< "$basic_modules"
        
        # Procesar selecciones de características avanzadas
        while IFS= read -r feature; do
            case "$feature" in
                "Prompt multilínea [Prompt en múltiples líneas]")
                    STARSHIP_MULTILINE=true
                    ;;
                "Truncado de directorio [Rutas largas acortadas]")
                    STARSHIP_TRUNC_DIR=true
                    ;;
                "Colores de directorio [Colores en rutas]")
                    STARSHIP_COLOR_DIR=true
                    ;;
                "Símbolos de lenguajes [Iconos de lenguajes]")
                    STARSHIP_LANG_SYMBOLS=true
                    ;;
                "Duración de comandos [Tiempo de ejecución]")
                    STARSHIP_CMD_DURATION=true
                    ;;
                "Usuario inteligente [Mostrar solo si no es el usuario por defecto]")
                    STARSHIP_USER_SMART=true
                    ;;
                "Host inteligente [Mostrar solo si no es localhost]")
                    STARSHIP_HOST_SMART=true
                    ;;
                "Batería [Estado de la batería]")
                    STARSHIP_BATTERY=true
                    ;;
                "Jobs en background [Procesos en segundo plano]")
                    STARSHIP_JOBS=true
                    ;;
            esac
        done <<< "$advanced_features"
        
        # Procesar selecciones de módulos DevOps
        while IFS= read -r devops; do
            case "$devops" in
                "Módulo AWS [Información de AWS]")
                    STARSHIP_AWS=true
                    ;;
                "Módulo Kubernetes [Contexto de Kubernetes]")
                    STARSHIP_KUBERNETES=true
                    ;;
                "Right prompt [Prompt derecho con información adicional]")
                    STARSHIP_RIGHT_FORMAT=true
                    ;;
                "Workspace de Terraform [Estado de Terraform]")
                    STARSHIP_TERRAFORM_WORKSPACE=true
                    ;;
            esac
        done <<< "$devops_modules"
        
        # Procesar selecciones de características de Zsh
        while IFS= read -r zsh; do
            case "$zsh" in
                "Historial mejorado [Configuración avanzada del historial]")
                    ZSH_HISTORY_ENHANCED=true
                    ;;
                "Autocompletado mejorado [Completado más inteligente]")
                    ZSH_AUTOCOMPLETION_ENHANCED=true
                    ;;
                "Corrección de comandos [Corrección automática]")
                    ZSH_CORRECTION=true
                    ;;
                "Funciones de productividad [Funciones útiles adicionales]")
                    ZSH_PRODUCTIVITY_FUNCTIONS=true
                    ;;
            esac
        done <<< "$zsh_features"
        
        # Configuraciones adicionales basadas en selecciones
        if [[ "$STARSHIP_CMD_DURATION" = true || "$STARSHIP_TIME" = true || "$STARSHIP_BATTERY" = true ]]; then
            STARSHIP_TIME=true
            STARSHIP_PKG_VERSION=true
            STARSHIP_SHELL=true
        fi
        
        # Manejar dependencias
        handle_dependencies
        
        # Mostrar resumen
        log_verbose "Resumen de configuración final:"
        log_verbose "Right format: $STARSHIP_RIGHT_FORMAT"
        log_verbose "Cmd duration: $STARSHIP_CMD_DURATION"
        log_verbose "Time: $STARSHIP_TIME"
        log_verbose "Battery: $STARSHIP_BATTERY"
    fi
}

# Instala todas las dependencias necesarias.
# Abstraer la instalación en una función permite reutilizar la lógica
# y añadir o quitar dependencias fácilmente.
install_dependencies() {
    set +e  # Desactivar 'set -e' temporalmente para depuración
    
    # 1. Starship
    local starship_installed=true
    if ! command -v starship >/dev/null; then
        if [[ "$DRY_RUN" = true ]]; then
            log_warn "[DRY-RUN] Se ejecutaría: brew install starship"
        else
            brew install starship >/dev/null && starship_installed=true || starship_installed=false
        fi
    fi

    # 2. Plugins de Zsh
    local plugins_installed=true
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se clonarían los repositorios de plugins en $ZSH_PLUGINS_DIR"
    else
        # Verificar que el directorio de plugins existe y es escribible
        if [[ ! -d "$ZSH_PLUGINS_DIR" ]]; then
            mkdir -p "$ZSH_PLUGINS_DIR"
        fi
        
        if [[ ! -w "$ZSH_PLUGINS_DIR" ]]; then
            log_error "El directorio $ZSH_PLUGINS_DIR no es escribible"
            plugins_installed=false
        else
            # Instalar plugins
            local plugins_to_install=()
            [[ "$INSTALL_AUTOSUGGESTIONS" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]] && plugins_to_install+=("zsh-autosuggestions")
            [[ "$INSTALL_SYNTAX_HIGHLIGHTING" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]] && plugins_to_install+=("zsh-syntax-highlighting")
            [[ "$INSTALL_COMPLETIONS" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-completions" ]] && plugins_to_install+=("zsh-completions")
            [[ "$INSTALL_HISTORY_SUBSTRING" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-history-substring-search" ]] && plugins_to_install+=("zsh-history-substring-search")
            [[ "$INSTALL_YOU_SHOULD_USE" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-you-should-use" ]] && plugins_to_install+=("zsh-you-should-use")
            
            for plugin in "${plugins_to_install[@]}"; do
                case "$plugin" in
                    "zsh-autosuggestions")
                        git clone --quiet https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions" || plugins_installed=false
                        ;;
                    "zsh-syntax-highlighting")
                        git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" || plugins_installed=false
                        ;;
                    "zsh-completions")
                        git clone --quiet https://github.com/zsh-users/zsh-completions "$ZSH_PLUGINS_DIR/zsh-completions" || plugins_installed=false
                        ;;
                    "zsh-history-substring-search")
                        git clone --quiet https://github.com/zsh-users/zsh-history-substring-search "$ZSH_PLUGINS_DIR/zsh-history-substring-search" || plugins_installed=false
                        ;;
                    "zsh-you-should-use")
                        git clone --quiet https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_PLUGINS_DIR/zsh-you-should-use" || plugins_installed=false
                        ;;
                esac
            done
        fi
    fi

    # 3. Modern CLI tools (condicional)
    local tools_installed=true
    if [[ "$SKIP_TOOLS" = true ]]; then
        log_verbose "Se omite la instalación de herramientas modernas (--skip-tools)."
    else
        local tools_to_install=()
        [[ "$INSTALL_EZA" = true ]] && ! command -v eza >/dev/null && tools_to_install+=("eza")
        [[ "$INSTALL_BAT" = true ]] && ! command -v bat >/dev/null && tools_to_install+=("bat")
        [[ "$INSTALL_FD" = true ]] && ! command -v fd >/dev/null && tools_to_install+=("fd")
        [[ "$INSTALL_RIPGREP" = true ]] && ! command -v rg >/dev/null && tools_to_install+=("ripgrep")
        [[ "$INSTALL_FZF" = true ]] && ! command -v fzf >/dev/null && tools_to_install+=("fzf")
        
        if [[ ${#tools_to_install[@]} -gt 0 ]]; then
            if [[ "$DRY_RUN" = true ]]; then
                log_warn "[DRY-RUN] Se ejecutaría: brew install ${tools_to_install[*]}"
            else
                brew install ${tools_to_install[@]} >/dev/null || tools_installed=false
            fi
        fi
        
        # fzf requiere instalación post-brew
        if [[ "$DRY_RUN" = false ]] && command -v fzf >/dev/null; then
            "$(brew --prefix)"/opt/fzf/install --all --no-update-rc >/dev/null
        fi
    fi
    
    # Mostrar resultados
    log_result "$starship_installed" "Instalación Starship"
    log_result "$plugins_installed" "Instalación plugins"
    log_result "$tools_installed" "Instalación herramientas"
    
    set -e  # Restaurar 'set -e' al final de la función
}


# Genera los nuevos archivos de configuración .zshrc y starship.toml.
# Usar Here Documents (<<EOF) es una forma limpia de generar archivos de
# configuración multilínea desde un script.
generate_new_config() {
    # --- Generar .zshrc ---
    local new_zshrc_content
    # La sintaxis `new_zshrc_content=$(cat <<EOF)` sin comillas en EOF
    # permite la expansión de variables ($HOME, $USER_ALIASES etc) dentro del bloque,
    # que es exactamente lo que necesitamos aquí.
    new_zshrc_content=$(cat <<EOF
# ==============================================================================
# ~/.zshrc - Generado por el script de migración a Starship
# Fecha: $(date)
# ==============================================================================

# --- Opciones de Zsh ---
# Configura el historial de comandos para que sea más útil
HISTFILE=$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY           # Añade al historial, no sobrescribe
setopt EXTENDED_HISTORY         # Guarda timestamp y duración
setopt INC_APPEND_HISTORY       # Guarda comandos inmediatamente
setopt SHARE_HISTORY            # Comparte historial entre terminales
setopt HIST_IGNORE_DUPS         # No guarda duplicados consecutivos
setopt HIST_IGNORE_ALL_DUPS     # Borra duplicados antiguos
setopt HIST_FIND_NO_DUPS        # No muestra duplicados al buscar

# --- Configuración de Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
export ZSH_PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
ZSH_THEME="robbyrussell"

# --- Plugins de Zsh ---
plugins=(
EOF
)

    # Agregar plugins seleccionados
    if [[ "$INSTALL_AUTOSUGGESTIONS" = true ]]; then
        new_zshrc_content+="    zsh-autosuggestions\n"
    fi
    if [[ "$INSTALL_SYNTAX_HIGHLIGHTING" = true ]]; then
        new_zshrc_content+="    zsh-syntax-highlighting\n"
    fi
    if [[ "$INSTALL_COMPLETIONS" = true ]]; then
        new_zshrc_content+="    zsh-completions\n"
    fi
    if [[ "$INSTALL_HISTORY_SUBSTRING" = true ]]; then
        new_zshrc_content+="    zsh-history-substring-search\n"
    fi
    if [[ "$INSTALL_YOU_SHOULD_USE" = true ]]; then
        new_zshrc_content+="    zsh-you-should-use\n"
    fi

    new_zshrc_content+=$(cat <<'EOF'
)

source $ZSH/oh-my-zsh.sh

# --- Cargar plugins custom ---
if [[ -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
    source "$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
if [[ -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
    source "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
if [[ -d "$ZSH_PLUGINS_DIR/zsh-completions" ]]; then
    # zsh-completions puede tener diferentes nombres de archivo
    if [[ -f "$ZSH_PLUGINS_DIR/zsh-completions/zsh-completions.plugin.zsh" ]]; then
        source "$ZSH_PLUGINS_DIR/zsh-completions/zsh-completions.plugin.zsh"
    elif [[ -f "$ZSH_PLUGINS_DIR/zsh-completions/zsh-completions.zsh" ]]; then
        source "$ZSH_PLUGINS_DIR/zsh-completions/zsh-completions.zsh"
    fi
fi
if [[ -d "$ZSH_PLUGINS_DIR/zsh-history-substring-search" ]]; then
    source "$ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
fi
if [[ -d "$ZSH_PLUGINS_DIR/zsh-you-should-use" ]]; then
    # zsh-you-should-use puede tener diferentes nombres de archivo
    if [[ -f "$ZSH_PLUGINS_DIR/zsh-you-should-use/zsh-you-should-use.plugin.zsh" ]]; then
        source "$ZSH_PLUGINS_DIR/zsh-you-should-use/zsh-you-should-use.plugin.zsh"
    elif [[ -f "$ZSH_PLUGINS_DIR/zsh-you-should-use/zsh-you-should-use.zsh" ]]; then
        source "$ZSH_PLUGINS_DIR/zsh-you-should-use/zsh-you-should-use.zsh"
    fi
fi

# --- Personalizaciones adicionales de Zsh ---
# Autocompletado mejorado
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Corrección de comandos
setopt CORRECT
setopt CORRECT_ALL

# Búsqueda en historial con flechas
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Funciones de productividad
function mkcd() { mkdir -p "$1" && cd "$1"; }

# --- Alias agrupados por categorías ---
# Navegación
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Git
alias gst='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate --all -10'
alias gundo='git reset --soft HEAD~1'

# Docker
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dclean='docker system prune -f && docker volume prune -f'
alias dlogs='docker logs -f'

# Kubernetes
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs -f'
alias kp='kubectl port-forward'
alias kctx='kubectl config current-context'
alias kns='kubectl config set-context --current --namespace'

# Terraform
alias tf='terraform'
alias tfw='terraform workspace'
alias tfp='terraform plan'
alias tfa='terraform apply'
alias tfd='terraform destroy'

# Utilidades del sistema
alias ports='lsof -i -P -n | grep LISTEN'
alias myip='curl -s ifconfig.me'
alias localip='ifconfig | grep "inet " | grep -v 127.0.0.1 | awk "{print \$2}"'
alias weather='curl -s "wttr.in/?format=%C+%t"'
alias serve='python3 -m http.server 8000'

# Productividad
alias c='clear'
alias h='history'
alias j='jobs'
alias v='vim'
alias nv='nvim'
alias t='tmux'
alias ta='tmux attach'
alias tn='tmux new-session'
alias tl='tmux list-sessions'

# Modern tools (solo si existen)
if command -v eza >/dev/null; then
    alias ls='eza --icons'
    alias la='eza -a --icons'
    alias ll='eza -l --icons'
    alias l='eza -l --icons'
fi
if command -v bat >/dev/null; then alias cat='bat --paging=never'; fi
if command -v rg >/dev/null; then alias grep='rg'; fi

# --- Exports agrupados ---
# Exports de rutas
export PATH="/usr/local/bin:/usr/local/sbin:$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/bin:$PATH"

# --- Funciones agrupadas por categorías ---
# Funciones de navegación

# Funciones utilitarias

# Funciones DevOps/Developer
function ports() { lsof -i -P -n | grep LISTEN; }
function killport() { lsof -ti:$1 | xargs kill -9; }
function weather() { curl -s "wttr.in/$1?format=%C+%t"; }
function speedtest() { curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -; }
function backup() { tar -czf "$1_$(date +%Y%m%d_%H%M%S).tar.gz" "$1"; }
function gitlog() { git log --oneline --graph --decorate --all -10; }
function docker-clean() { docker system prune -f && docker volume prune -f; }
function k8s-context() { kubectl config current-context; }
function tf-workspace() { terraform workspace show 2>/dev/null || echo "No workspace"; }
function public-ip() { curl -s ifconfig.me; }
function local-ip() { ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'; }
function serve() { python3 -m http.server ${1:-8000}; }
function newproject() { mkdir -p "$1" && cd "$1" && git init && echo "# $1" > README.md; }
function deploy() { echo "Deploy function - customize for your workflow"; }
function test() { echo "Test function - customize for your workflow"; }
function build() { echo "Build function - customize for your workflow"; }
function clean() { find . -name "*.pyc" -delete && find . -name "__pycache__" -delete && find . -name "*.log" -delete; }

# ==============================================================================
# --- CONFIGURACIÓN PERSONAL DEL USUARIO (MIGRADA) ---
# ==============================================================================

# --- Alias Personales ---
EOF
)

    # Insertar alias del usuario si existen
    if [[ -n "$USER_ALIASES" ]]; then
        new_zshrc_content+="$USER_ALIASES\n\n"
    fi

    new_zshrc_content+=$(cat <<'EOF'
# --- Variables de Entorno (Exports) ---
EOF
)

    # Insertar exports del usuario si existen
    if [[ -n "$USER_EXPORTS" ]]; then
        new_zshrc_content+="$USER_EXPORTS\n\n"
    fi

    new_zshrc_content+=$(cat <<'EOF'
# --- Funciones Personales ---
EOF
)

    # Insertar funciones del usuario si existen (evitando duplicados)
    if [[ -n "$USER_FUNCTIONS" ]]; then
        # Filtrar funciones que ya están definidas en el script base
        local filtered_functions=$(echo "$USER_FUNCTIONS" | awk '
            BEGIN { 
                # Lista de funciones que ya están en el script base
                base_functions["mkcd"] = 1
                base_functions["ports"] = 1
                base_functions["killport"] = 1
                base_functions["weather"] = 1
                base_functions["speedtest"] = 1
                base_functions["backup"] = 1
                base_functions["gitlog"] = 1
                base_functions["docker-clean"] = 1
                base_functions["k8s-context"] = 1
                base_functions["tf-workspace"] = 1
                base_functions["public-ip"] = 1
                base_functions["local-ip"] = 1
                base_functions["serve"] = 1
                base_functions["newproject"] = 1
                base_functions["deploy"] = 1
                base_functions["test"] = 1
                base_functions["build"] = 1
                base_functions["clean"] = 1
                base_functions["extract"] = 1
            }
            /^function [a-zA-Z0-9_-]+\(\)/ {
                # Extraer nombre de función
                gsub(/^function /, "", $0)
                gsub(/\(\)/, "", $0)
                func_name = $0
                if (!(func_name in base_functions)) {
                    print $0
                    in_func = 1
                    buffer = $0
                } else {
                    in_func = 0
                    buffer = ""
                }
                next
            }
            in_func {
                buffer = buffer "\n" $0
            }
            END {
                if (in_func && buffer != "") {
                    print buffer
                }
            }
        ')
        if [[ -n "$filtered_functions" ]]; then
            new_zshrc_content+="$filtered_functions\n\n"
        fi
    fi

    new_zshrc_content+=$(cat <<EOF

# ==============================================================================
# --- INICIALIZACIÓN DE STARSHIP ---
# ¡La última línea debe ser esta para que el prompt funcione!
# ==============================================================================
eval "\$(starship init zsh)"

EOF
)

    # --- Generar starship.toml ---
    local starship_config_path="$HOME/.config/starship.toml"
    local starship_config_content
    # Logs temporales para depuración
    # Debug info removed for cleaner output
    starship_config_content="# Schema para autocompletado en editores\n"
    starship_config_content+="# \$schema = 'https://starship.rs/config-schema.json'\n\n"

    # Línea en blanco entre prompts
    if [[ "$STARSHIP_BLANK_LINE" = true ]]; then
        starship_config_content+="# Línea en blanco entre prompts\nadd_newline = true\n\n"
    fi

    # Prompt principal (izquierda)
    local left_format=""
    left_format+="$username$hostname$directory"
    [[ "$STARSHIP_GIT" = true ]] && left_format+="$git_branch$git_status"
    [[ "$STARSHIP_NODEJS" = true ]] && left_format+="$nodejs"
    [[ "$STARSHIP_PYTHON" = true ]] && left_format+="$python"
    [[ "$STARSHIP_DOCKER" = true ]] && left_format+="$docker_context"
    [[ "$STARSHIP_KUBERNETES" = true ]] && left_format+="$kubernetes"
    [[ "$STARSHIP_TERRAFORM_WORKSPACE" = true ]] && left_format+="$terraform"
    [[ "$STARSHIP_CMD_DURATION" = true ]] && left_format+="$cmd_duration"
    left_format+="$character"
    starship_config_content+="# Prompt principal (izquierda)\nformat = \"$left_format\"\n\n"

    # Prompt derecho (right prompt) - solo si right_format está habilitado y hay módulos
    if [[ "$STARSHIP_RIGHT_FORMAT" = true ]]; then
        local right_format=""
        local right_modules_count=0
        
        [[ "$STARSHIP_CMD_DURATION" = true ]] && right_format+="$cmd_duration" && ((right_modules_count++))
        [[ "$STARSHIP_TIME" = true ]] && right_format+="$time" && ((right_modules_count++))
        [[ "$STARSHIP_BATTERY" = true ]] && right_format+="$battery" && ((right_modules_count++))
        
        if [[ $right_modules_count -gt 0 ]]; then
            starship_config_content+="# Prompt derecho (right prompt)\nright_format = \"$right_format\"\n\n"
        else
            log_verbose "Right format habilitado pero no hay módulos disponibles - desactivando"
            STARSHIP_RIGHT_FORMAT=false
        fi
    fi

    # Módulos básicos
    starship_config_content+="[character]\nsuccess_symbol = \"[➜](bold green)\"\nerror_symbol = \"[✗](bold red)\"\n\n"
    starship_config_content+="[directory]\ntruncation_length = 3\nstyle = \"bold blue\"\n\n"

    # Git
    if [[ "$STARSHIP_GIT" = true ]]; then
        starship_config_content+="[git_branch]\nsymbol = \"🌱 \"\nstyle = \"bold yellow\"\n\n"
        starship_config_content+="[git_status]\nstyle = \"bold red\"\nstashed = \"📦\"\nahead = \"⇡ {count}\"\nbehind = \"⇣ {count}\"\ndiverged = \"⇕ ⇡ {ahead_count} ⇣ {behind_count}\"\nconflicted = \"🔥\"\ndeleted = \"🗑️ \"\nrenamed = \"🏷️ \"\nmodified = \"📝 \"\nstaged = '[++\\(\\)](green)'\nuntracked = \"🤷 \"\n\n"
    fi

    # Kubernetes
    if [[ "$STARSHIP_KUBERNETES" = true ]]; then
        starship_config_content+="[kubernetes]\ndisabled = false\nformat = \"on [](bold blue) \"\nsymbol = \"☸️  \"\nstyle = \"bold blue\"\ncontext_aliases = {}\n\n"
    fi

    # Duración de comandos
    if [[ "$STARSHIP_CMD_DURATION" = true ]]; then
        starship_config_content+="[cmd_duration]\nmin_time = 500\nformat = \"⏱ [\$duration](\$style) \"\nstyle = \"yellow bold\"\n\n"
    fi

    # Hora
    if [[ "$STARSHIP_TIME" = true ]]; then
        starship_config_content+="[time]\ndisabled = false\nformat = \"🕒 [\$time](\$style) \"\nstyle = \"bold blue\"\n\n"
    fi

    # Batería
    if [[ "$STARSHIP_BATTERY" = true ]]; then
        starship_config_content+="[battery]\ndisabled = false\nfull_symbol = \"🔋\"\ncharging_symbol = \"⚡\"\ndischarging_symbol = \"🔌\"\nformat = \"[\$symbol\$percentage](\$style) \"\ncharging_style = \"bold green\"\ndischarging_style = \"bold red\"\nunknown_style = \"bold yellow\"\n\n"
    fi

    # Módulos desactivados por defecto
    starship_config_content+="[package]\ndisabled = true\n\n"

    # Node.js
    if [[ "$STARSHIP_NODEJS" = true ]]; then
        starship_config_content+="[nodejs]\ndisabled = false\n\n"
    else
        starship_config_content+="[nodejs]\ndisabled = true\n\n"
    fi

    # Python
    if [[ "$STARSHIP_PYTHON" = true ]]; then
        starship_config_content+="[python]\ndisabled = false\n\n"
    else
        starship_config_content+="[python]\ndisabled = true\n\n"
    fi

    # Docker
    if [[ "$STARSHIP_DOCKER" = true ]]; then
        starship_config_content+="[docker_context]\ndisabled = false\nformat = \"🐳 [\$context](\$style) \"\nstyle = \"bold blue\"\n\n"
    fi

    # AWS
    if [[ "$STARSHIP_AWS" = true ]]; then
        starship_config_content+="[aws]\ndisabled = false\nformat = \"☁️  [\$symbol\$profile(\$region)](\$style) \"\nstyle = \"bold yellow\"\n\n"
    fi







    # Terraform
    if [[ "$STARSHIP_TERRAFORM_WORKSPACE" = true ]]; then
        starship_config_content+="[terraform]\ndisabled = false\nformat = \"Terraform: [\$version](\$style) \"\nstyle = \"bold purple\"\n\n"
    fi





    # shell
    if [[ "$STARSHIP_SHELL" = true ]]; then
        starship_config_content+="[shell]\ndisabled = false\nformat = \"🐚 [\$shell](\$style) \"\nstyle = \"bold cyan\"\n\n"
    fi

    # Jobs en background
    if [[ "$STARSHIP_JOBS" = true ]]; then
        starship_config_content+="[jobs]\ndisabled = false\nformat = \"[\$symbol\$number](\$style) \"\nstyle = \"bold blue\"\n\n"
    fi

    # Usuario inteligente
    if [[ "$STARSHIP_USER_SMART" = true ]]; then
        starship_config_content+="[username]\ndisabled = false\nformat = \"[\$user](\$style) \"\nstyle_user = \"bold green\"\nshow_always = false\n\n"
    fi

    # Host inteligente
    if [[ "$STARSHIP_HOST_SMART" = true ]]; then
        starship_config_content+="[hostname]\ndisabled = false\nformat = \"[\$hostname](\$style) \"\nstyle = \"bold blue\"\nssh_only = true\n\n"
    fi

    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se crearía ~/.zshrc.new y se validaría."
        log_warn "[DRY-RUN] Se crearía ~/.config/starship.toml."
        log_verbose "--- Contenido de .zshrc.new (dry-run) ---"
        log_verbose "$new_zshrc_content"
        log_verbose "-----------------------------------------"
        return
    fi
    
    # Escribir y validar el nuevo .zshrc
    local zshrc_ok=true
    local starship_ok=true
    
    echo "$new_zshrc_content" > "$HOME/.zshrc.new"
    if zsh -n "$HOME/.zshrc.new"; then
        mv "$HOME/.zshrc.new" "$HOME/.zshrc"
    else
        log_error "El .zshrc generado tiene un error de sintaxis. Abortando para prevenir problemas."
        rm "$HOME/.zshrc.new"
        exit 1
    fi
    
    # Escribir la configuración de Starship
    mkdir -p "$HOME/.config"
    echo -e "$starship_config_content" > "$starship_config_path"
    
    log_result "$zshrc_ok" "Generación .zshrc"
    log_result "$starship_ok" "Generación Starship"
}

# Restaura la configuración desde el último backup.
rollback_migration() {
    local latest_backup
    # Encuentra el backup más reciente ordenando por nombre (timestamp).
    latest_backup=$(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" | sort -r | head -n 1)

    if [[ -z "$latest_backup" ]]; then
        log_error "No se encontraron backups en $BACKUP_BASE_DIR. No se puede hacer rollback."
        exit 1
    fi

    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se restaurarían los archivos desde $latest_backup."
        return
    fi

    # Restaurar .zshrc
    if [[ -f "$latest_backup/.zshrc" ]]; then
        cp "$latest_backup/.zshrc" "$HOME/.zshrc"
    fi

    # Restaurar Oh My Zsh
    if [[ -d "$latest_backup/.oh-my-zsh" ]]; then
        # Borrar el directorio actual (si existe) y luego copiar el del backup
        rm -rf "$HOME/.oh-my-zsh"
        cp -R "$latest_backup/.oh-my-zsh" "$HOME/"
    fi
    
    # Restaurar starship.toml si existía en el backup
    if [[ -f "$latest_backup/starship.toml" ]]; then
        cp "$latest_backup/starship.toml" "$HOME/.config/starship.toml"
    else
        # Si no había backup, lo borramos para no dejar un estado mixto.
        rm -f "$HOME/.config/starship.toml"
    fi
    
    log_result true "Rollback completado"
                log_info "Reinicia tu terminal o ejecuta 'source ~/.zshrc'"
}

# Muestra el estado actual de la configuración de forma simplificada
show_status() {
    echo -e "${C_BLUE}Estado del Sistema${C_NC}"
    
    # Detectar configuración principal
    if grep -q "starship init zsh" "$HOME/.zshrc" &>/dev/null; then
        echo -e "${C_GREEN}✅ Starship activo${C_NC}"
    elif [[ -d "$HOME/.oh-my-zsh" ]]; then
        echo -e "${C_GREEN}✅ Oh My Zsh detectado${C_NC}"
    else
        echo -e "${C_YELLOW}⚠️  Configuración no detectada${C_NC}"
    fi
    
    # Resumen rápido de componentes
    local components=()
    
    # Plugins
    local plugins_active=0
    for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search zsh-you-should-use; do
        if [[ -d "$ZSH_PLUGINS_DIR/$plugin" ]] && grep -q "$plugin" "$HOME/.zshrc"; then
            ((plugins_active++))
        fi
    done
    components+=("Plugins: $plugins_active/5")
    
    # Herramientas
    local tools_active=0
    for tool in eza bat fd rg fzf; do
        if command -v $tool >/dev/null 2>&1; then
            ((tools_active++))
        fi
    done
    components+=("Herramientas: $tools_active/5")
    
    # Módulos Starship
    local modules_active=0
    local total_modules=0
    for module in right_format battery cmd_duration time kubernetes docker aws; do
        ((total_modules++))
        if [[ "$(get_starship_module_state "$module")" = "true" ]]; then
            ((modules_active++))
        fi
    done
    components+=("Módulos Starship: $modules_active/$total_modules")
    
    # Mostrar resumen
    echo -e "\n${C_BLUE}Componentes:${C_NC}"
    for component in "${components[@]}"; do
        echo -e "  $component"
    done
}

# Muestra la ayuda del script.
show_help() {
    # Usar 'cat <<EOF' es una forma limpia de imprimir bloques de texto.
    cat <<EOF
Script de Migración de Oh My Zsh a Starship (v${SCRIPT_VERSION})

Uso: ./zsh_starship_migration.sh [comando] [opciones]

Comandos:
  (sin comando)      Ejecuta la migración en modo interactivo (default).
  rollback           Restaura la configuración de Oh My Zsh desde el último backup.
  status             Muestra el estado actual de la configuración.
  help, -h, --help   Muestra esta ayuda.

Opciones:
  --dry-run          Muestra lo que haría el script sin ejecutar cambios reales.
  --verbose          Activa el logging detallado para depuración.
  --skip-tools       Migra solo el prompt (Starship) y los plugins, sin instalar exa, bat, etc.
  --auto             Aplica todas las customizaciones automáticamente (modo no interactivo).
--interactive      Fuerza el modo interactivo incluso en contextos no interactivos.
EOF
}

# Genera un reporte detallado del estado de la migración.
generate_report() {
    log_info "================ MIGRATION REPORT ================"
    echo -e "\n${C_BLUE}Fecha:${C_NC} $(date)"
    echo -e "${C_BLUE}Usuario:${C_NC} $USER"
    echo -e "${C_BLUE}Home:${C_NC} $HOME"
    echo -e "${C_BLUE}Backup más reciente:${C_NC} $(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" | sort -r | head -n 1)"
    echo -e "\n${C_BLUE}Prompt:${C_NC} $(grep -q 'starship init zsh' "$HOME/.zshrc" && echo 'Starship' || echo 'Otro/no detectado')"
    echo -e "\n${C_BLUE}Herramientas modernas instaladas:${C_NC}"
    for tool in eza bat fd rg fzf; do
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${C_GREEN}$tool: OK${C_NC} ($($tool --version | head -n1))"
        else
            echo -e "  ${C_RED}$tool: NO INSTALADO${C_NC}"
        fi
    done
    
    echo -e "\n${C_BLUE}Módulos adicionales de Starship:${C_NC}"
    [[ "$STARSHIP_AWS" = true ]] && echo -e "  ${C_GREEN}AWS: Configurado${C_NC}" || echo -e "  ${C_RED}AWS: No configurado${C_NC}"

    
    [[ "$STARSHIP_KUBERNETES" = true ]] && echo -e "  ${C_GREEN}Kubernetes: Configurado${C_NC}" || echo -e "  ${C_RED}Kubernetes: No configurado${C_NC}"
    
    echo -e "\n${C_BLUE}Funcionalidades avanzadas de DevOps/Developer:${C_NC}"
    [[ "$STARSHIP_RIGHT_FORMAT" = true ]] && echo -e "  ${C_GREEN}Right format: Configurado${C_NC}" || echo -e "  ${C_RED}Right format: No configurado${C_NC}"

    [[ "$STARSHIP_TERRAFORM_WORKSPACE" = true ]] && echo -e "  ${C_GREEN}Terraform workspace: Configurado${C_NC}" || echo -e "  ${C_RED}Terraform workspace: No configurado${C_NC}"
    
    echo -e "\n${C_BLUE}Personalizaciones de Zsh:${C_NC}"
    [[ "$ZSH_HISTORY_ENHANCED" = true ]] && echo -e "  ${C_GREEN}Historial mejorado: Activo${C_NC}" || echo -e "  ${C_RED}Historial mejorado: Inactivo${C_NC}"
    [[ "$ZSH_AUTOCOMPLETION_ENHANCED" = true ]] && echo -e "  ${C_GREEN}Autocompletado mejorado: Activo${C_NC}" || echo -e "  ${C_RED}Autocompletado mejorado: Inactivo${C_NC}"
    [[ "$ZSH_CORRECTION" = true ]] && echo -e "  ${C_GREEN}Corrección de comandos: Activa${C_NC}" || echo -e "  ${C_RED}Corrección de comandos: Inactiva${C_NC}"
    [[ "$ZSH_PRODUCTIVITY_FUNCTIONS" = true ]] && echo -e "  ${C_GREEN}Funciones de productividad: Activas${C_NC}" || echo -e "  ${C_RED}Funciones de productividad: Inactivas${C_NC}"
    echo -e "\n${C_BLUE}Alias activos (ls, la, ll, l):${C_NC}"
    for a in ls la ll l; do
        echo -e "  $a => $(alias $a 2>/dev/null | sed 's/alias //')"
    done
    echo -e "\n${C_BLUE}Configuración de Starship:${C_NC}"
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        echo -e "  ${C_GREEN}~/.config/starship.toml existe${C_NC}"
        head -n 10 "$HOME/.config/starship.toml" | sed 's/^/    /'
        echo -e "    ..."
    else
        echo -e "  ${C_RED}No existe ~/.config/starship.toml${C_NC}"
    fi
    echo -e "\n${C_BLUE}Alias personales:${C_NC}"
    alias | grep -vE "ls=|la=|ll=|l=" | sort | head -n 10 | sed 's/^/    /'
    echo -e "    ..."
    echo -e "\n${C_BLUE}Variables de entorno relevantes:${C_NC}"
    env | grep -E 'PATH|ZSH|PYENV|OLLAMA|HOMEBREW' | sed 's/^/    /'
    echo -e "\n${C_BLUE}==================================================${C_NC}\n"
}

# Validación y testeo post-migración
post_migration_validation() {
    echo -e "\n${C_BLUE}Validación post-migración:${C_NC}"
    
    local total_checks=0
    local passed_checks=0
    
    # Test alias principales
    for a in ls la ll l; do
        ((total_checks++))
        if zsh -i -c "$a --icons" &>/dev/null; then
            echo -e "  ${C_GREEN}✅ Alias $a OK${C_NC}"
            ((passed_checks++))
        else
            echo -e "  ${C_RED}❌ Alias $a FAIL${C_NC}"
        fi
    done
    
    # Test Starship prompt
    ((total_checks++))
    if zsh -i -c 'starship --version' &>/dev/null && grep -q 'starship init zsh' "$HOME/.zshrc"; then
        echo -e "  ${C_GREEN}✅ Starship activo${C_NC}"
        ((passed_checks++))
    else
        echo -e "  ${C_RED}❌ Starship inactivo${C_NC}"
    fi
    
    # Test plugins seleccionados
    for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-completions zsh-history-substring-search zsh-you-should-use; do
        ((total_checks++))
        if [[ -d "$ZSH_PLUGINS_DIR/$plugin" ]] && grep -q "$plugin" "$HOME/.zshrc"; then
            echo -e "  ${C_GREEN}✅ $plugin cargado${C_NC}"
            ((passed_checks++))
        else
            echo -e "  ${C_RED}❌ $plugin no cargado${C_NC}"
        fi
    done
    
    # Test herramientas modernas
    for tool in eza bat fd fzf; do
        ((total_checks++))
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${C_GREEN}✅ $tool OK${C_NC}"
            ((passed_checks++))
        else
            echo -e "  ${C_RED}❌ $tool NO INSTALADO${C_NC}"
        fi
    done
    
    # Test ripgrep (comando rg)
    ((total_checks++))
    if command -v rg &>/dev/null; then
        echo -e "  ${C_GREEN}✅ ripgrep (rg) OK${C_NC}"
        ((passed_checks++))
    else
        echo -e "  ${C_RED}❌ ripgrep (rg) NO INSTALADO${C_NC}"
    fi
    
    # Resumen de validación
    echo -e "\n${C_BLUE}Resumen de validación:${C_NC}"
    echo -e "  ${C_GREEN}$passed_checks OK${C_NC}  ${C_RED}$((total_checks - passed_checks)) FAIL${C_NC}"
    
    # Determinar si la validación fue exitosa (al menos 80% de éxito)
    local success_rate=$((passed_checks * 100 / total_checks))
    
    if [[ $success_rate -ge 80 ]]; then
        log_result true "Validación final ($success_rate%)"
        return 0
    else
        log_result false "Validación final ($success_rate%)"
        return 1
    fi
}

# --- FUNCIÓN PRINCIPAL (MAIN) ---
# El punto de entrada del script. Parsea los argumentos y llama a la
# función correspondiente. Es el "director de orquesta".
main() {
    # Parseo de argumentos. Un bucle `while` con `case` es el patrón más
    # robusto y extensible en shell para manejar argumentos.
    local command=""
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --skip-tools)
                SKIP_TOOLS=true
                shift
                ;;
            --auto)
                AUTO_MODE=true
                shift
                ;;
            --interactive)
                AUTO_MODE=false
                shift
                ;;
            help|-h|--help)
                show_help
                exit 0
                ;;
            rollback|status|report)
                if [[ -n "$command" ]]; then
                    log_error "Solo se puede especificar un comando a la vez."
                    exit 1
                fi
                command=$1
                shift
                ;;
            -*) # Captura cualquier otra opción no reconocida
                log_error "Opción no reconocida: $1"
                show_help
                exit 1
                ;;
            *) # Captura argumentos que no son opciones
                if [[ -z "$command" ]]; then
                    # Si no hay comando, esto es un error.
                    log_error "Comando no reconocido: $1"
                    show_help
                    exit 1
                else
                    # Si ya hay un comando, es un argumento extra no esperado.
                    log_error "Argumento inesperado: $1 para el comando '$command'"
                    exit 1
                fi
                ;;
        esac
    done

    # Modo verbose para el dry-run
    if [[ "$DRY_RUN" = true ]]; then
        # Activar verbose en dry-run es útil para ver qué se haría.
        VERBOSE=true
        set +e  # <--- PATCH: Disable exit on error in dry-run mode
        log_info "Modo DRY-RUN activado. No se realizarán cambios."
    fi

    # Mostrar estado antes de cualquier acción, excepto en status, help, rollback
    case "$command" in
        status|help|-h|--help|rollback)
            ;; # No mostrar status antes, ya que es el propio comando
        *)
            ;;
    esac

    # Mostrar el modo de ejecución
    if [[ "$AUTO_MODE" = true ]]; then
        log_info "🚀 Ejecutando en modo AUTOMÁTICO (no interactivo)"
    else
        log_info "🎯 Ejecutando en modo INTERACTIVO"
    fi
    
    # Validación automática del prompt (excepto para comandos específicos)
    case "$command" in
        status|help|-h|--help|rollback)
            # No validar para estos comandos
            ;;
        *)
            # Validar prompt para otros comandos
            if [[ -f "$HOME/.config/starship.toml" ]]; then
                log_verbose "🔍 Verificando estado del prompt..."
                if grep -q '^format = ""' "$HOME/.config/starship.toml"; then
                    log_warn "⚠️  Prompt vacío detectado - ejecuta la migración para corregir"
                elif ! starship prompt --status 0 >/dev/null 2>&1; then
                    log_warn "⚠️  Problemas con el prompt detectados - ejecuta la migración para corregir"
                else
                    log_verbose "✅ Prompt funcionando correctamente"
                fi
            fi
            ;;
    esac
    
            # Confirmación final en modo interactivo
        if [[ "$AUTO_MODE" != true ]]; then
            if show_gui_confirmation \
                "¿Deseas continuar con la migración?\n\nSe realizarán los siguientes cambios:\n• Backup de configuración actual\n• Instalación de Starship y plugins\n• Configuración de nuevo prompt\n• Instalación de herramientas modernas"; then
                log_info "Usuario confirmó la migración"
            else
                log_info "Migración cancelada por el usuario"
                exit 0
            fi
        fi
        
        # Ejecutar el comando principal
        local MIGRATION_OK=true
        local BACKUP_OK=false
        local ANALYZE_OK=false
        local INSTALL_OK=false
        local CONFIG_OK=false
        local VALIDATION_OK=false
        case $command in
        rollback)
            rollback_migration
            ;;
        status)
            # Función status ejecutándose
            show_status
            ;;
        report)
            generate_report
            ;;
        "") # Comando por defecto: migración
            # Paso 1: Selección de plugins de Zsh
            select_zsh_plugins
            # Paso 2: Selección de features/configuraciones de Starship
            select_starship_features
            
            validate_system || MIGRATION_OK=false
            detect_common_issues || log_verbose "Problemas detectados, se solucionarán automáticamente"
            create_backup && BACKUP_OK=true || log_error "Error en backup"
            analyze_config && ANALYZE_OK=true || log_error "Error en análisis"
            install_dependencies && INSTALL_OK=true || log_error "Error en instalación"
            generate_new_config && CONFIG_OK=true || log_error "Error en configuración"
            fix_common_issues || log_verbose "Algunos problemas comunes no se pudieron solucionar"
            
            # Validación y corrección automática del prompt
            log_info "🔍 Validando prompt de Starship..."
            if ! validate_starship_config; then
                log_warn "Problemas detectados en el prompt - corrigiendo automáticamente"
                fix_starship_format
                # Revalidar después de la corrección
                if validate_starship_config; then
                    log_success "Prompt corregido y funcionando"
                else
                    log_error "No se pudo corregir el prompt automáticamente"
                fi
            else
                log_success "Prompt de Starship funcionando correctamente"
            fi
            
            post_migration_validation && VALIDATION_OK=true || VALIDATION_OK=false
            
            # Logging completo del sistema
            comprehensive_logging
            
            # Resumen final simplificado
            if [[ "$BACKUP_OK" = true && "$ANALYZE_OK" = true && "$INSTALL_OK" = true && "$CONFIG_OK" = true && "$VALIDATION_OK" = true ]]; then
                echo -e "\n${C_GREEN}🎉 ¡Migración completada con éxito!${C_NC}"
                echo -e "   - Backup creado en: ${C_YELLOW}${MIGRATION_BACKUP_PATH}${C_NC}"
                echo -e "   - Para revertir, ejecuta: ${C_YELLOW}./zsh_starship_migration.sh rollback${C_NC}"
                echo -e "   - ${C_BLUE}Por favor, reinicia tu terminal o ejecuta 'source ~/.zshrc' para ver los cambios.${C_NC}"
            else
                echo -e "\n${C_RED}❌ Migración incompleta${C_NC}"
                echo -e "   - Revisa los errores anteriores"
                echo -e "   - Para revertir, ejecuta: ${C_YELLOW}./zsh_starship_migration.sh rollback${C_NC}"
            fi
            ;;
    esac
}

# --- FUNCIÓN PARA RECARGAR CONFIGURACIÓN ---
reload_configuration() {
    log_info "🔄 Recargando configuración..."
    
    # Verificar si estamos en una sesión interactiva
    if [[ -t 0 ]]; then
        # Estamos en una sesión interactiva, podemos recargar
        if [[ -f "$HOME/.zshrc" ]]; then
            log_info "Recargando ~/.zshrc..."
            # Intentar recargar de forma más robusta
            if source "$HOME/.zshrc" 2>/dev/null; then
                log_success "Configuración recargada exitosamente"
            else
                log_info "Recarga automática no disponible en este contexto"
                log_info "Los cambios se aplicarán en tu próxima sesión de terminal"
            fi

        fi
        
        # Verificar que Starship esté funcionando
        if command -v starship >/dev/null; then
            log_info "Verificando que Starship esté funcionando..."
            # Probar que starship puede generar un prompt
            if starship prompt --status 0 >/dev/null 2>&1; then
                log_success "Starship está funcionando correctamente"
            else
                log_warn "Starship podría no estar funcionando correctamente"
            fi
        fi
    else
        # No estamos en una sesión interactiva, mostrar instrucciones
        log_info "No se puede recargar automáticamente en modo no interactivo"
        log_info "Ejecuta 'source ~/.zshrc' para aplicar los cambios"
    fi
}

# --- FUNCIÓN PARA DETECTAR PROBLEMAS COMUNES ---
detect_common_issues() {
    local issues=()
    
    # Problema 1: Plugin rand-quote activo
    if [[ -d "$ZSH/plugins/rand-quote" ]] && [[ ! -d "$ZSH/plugins/rand-quote.disabled" ]]; then
        issues+=("Plugin rand-quote activo (puede causar errores de iconv)")
    fi
    
    # Problema 2: Módulos custom problemáticos en Starship
    if [[ -f "$HOME/.config/starship.toml" ]] && grep -q "custom_public_ip\|custom_weather" "$HOME/.config/starship.toml"; then
        issues+=("Módulos custom problemáticos en configuración de Starship")
    fi
    
    # Problema 3: Locale no configurado para UTF-8
    if [[ "$LANG" != *"UTF-8"* ]] || [[ "$LC_ALL" != *"UTF-8"* ]]; then
        issues+=("Locale no configurado para UTF-8")
    fi
    
    # Problema 4: Archivo .zshrc corrupto con referencias a iconv/omz_urlencode
    if [[ -f "$HOME/.zshrc" ]] && grep -q "omz_urlencode\|iconv" "$HOME/.zshrc"; then
        issues+=("Archivo .zshrc corrupto con referencias problemáticas")
    fi
    
    # Problema 5: Configuración de Starship con claves duplicadas
    if [[ -f "$HOME/.config/starship.toml" ]] && grep -A 1 -B 1 "style = " "$HOME/.config/starship.toml" | grep -c "style = " | grep -q "2"; then
        issues+=("Configuración de Starship con claves duplicadas")
    fi
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# --- FUNCIÓN PARA SOLUCIONAR PROBLEMAS COMUNES ---
fix_common_issues() {
    # Problema 1: Plugin rand-quote causando errores de iconv
    if [[ -d "$ZSH/plugins/rand-quote" ]]; then
        if [[ ! -d "$ZSH/plugins/rand-quote.disabled" ]]; then
            mv "$ZSH/plugins/rand-quote" "$ZSH/plugins/rand-quote.disabled"
        fi
    fi
    
    # Problema 2: Módulos custom de Starship no disponibles
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        if grep -q "custom_public_ip\|custom_weather" "$HOME/.config/starship.toml"; then
            sed -i.bak '/custom_public_ip\|custom_weather/d' "$HOME/.config/starship.toml"
        fi
    fi
    
    # Problema 3: Configuración de locale para UTF-8
    if [[ "$LANG" != *"UTF-8"* ]] || [[ "$LC_ALL" != *"UTF-8"* ]]; then
        export LANG=en_US.UTF-8
        export LC_ALL=en_US.UTF-8
    fi
    
    # Problema 4: Archivo .zshrc corrupto
    if [[ -f "$HOME/.zshrc" ]] && grep -q "omz_urlencode\|iconv" "$HOME/.zshrc"; then
        if [[ -f "$MIGRATION_BACKUP_PATH/.zshrc" ]]; then
            cp "$MIGRATION_BACKUP_PATH/.zshrc" "$HOME/.zshrc"
            # Eliminar líneas duplicadas
            sed -i.bak '/^export ZSH_PLUGINS_DIR=/d' "$HOME/.zshrc"
            sed -i.bak '/^export ZSH=/d' "$HOME/.zshrc"
            # Restaurar líneas correctas
            sed -i.bak "21i\\export ZSH_PLUGINS_DIR=\"$HOME/.oh-my-zsh/custom/plugins\"" "$HOME/.zshrc"
            sed -i.bak "20i\\export ZSH=\"$HOME/.oh-my-zsh\"" "$HOME/.zshrc"
        fi
    fi
    
    # Problema 5: Configuración de Starship con claves duplicadas
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        # Buscar y eliminar líneas duplicadas de style
        local temp_file=$(mktemp)
        local prev_line=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^[[:space:]]*style[[:space:]]*=[[:space:]]*\" && "$prev_line" =~ ^[[:space:]]*style[[:space:]]*=[[:space:]]*\" ]]; then
                continue
            fi
            echo "$line" >> "$temp_file"
            prev_line="$line"
        done < "$HOME/.config/starship.toml"
        mv "$temp_file" "$HOME/.config/starship.toml"
    fi
}

# --- Locale para evitar errores de iconv y UTF-8 ---
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# --- EJECUCIÓN DEL SCRIPT ---
# Llama a la función 'main' pasándole todos los argumentos que recibió el script.
# La construcción `"$@"` expande cada argumento como una cadena separada,
# preservando espacios si los hubiera, lo que es crucial para un parseo correcto.
main "$@"



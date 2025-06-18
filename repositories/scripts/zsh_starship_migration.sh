#!/usr/bin/env zsh

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
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
readonly C_YELLOW='\033[0;93m'
readonly C_NC='\033[0m' # No Color

readonly SCRIPT_VERSION="1.1.0"
readonly BACKUP_BASE_DIR="$HOME/.config/migration_backup"
readonly ZSH_PLUGINS_DIR="$HOME/.zsh/plugins"

# Flags para controlar el comportamiento del script. Se inicializan en 'false'.
# Se activarán al parsear los argumentos de entrada.
DRY_RUN=false
VERBOSE=false
SKIP_TOOLS=false

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
    echo -e "${C_RED}❌ ERROR: $1${C_NC}" >&2
}

log_warn() {
    echo -e "${C_YELLOW}⚠️  WARNING: $1${C_NC}"
}

log_verbose() {
    if [[ "$VERBOSE" = true ]]; then
        echo -e "${C_YELLOW}   [VERBOSE] $1${C_NC}"
    fi
}

# --- FUNCIONES CORE DEL SCRIPT ---

# Valida que el sistema cumple los requisitos para la migración.
# Es una buena práctica validar el entorno antes de empezar a hacer cambios.
validate_system() {
    log_info "Validando el sistema..."

    if [[ "$OSTYPE" != "darwin"* ]]; then
        log_error "Este script está optimizado para macOS. Se ha detectado '$OSTYPE'."
        exit 1
    fi

    local has_error=false
    command -v zsh >/dev/null || { log_error "Zsh no está instalado. Instala Zsh antes de continuar."; has_error=true; }
    command -v git >/dev/null || { log_error "Git no está instalado."; has_error=true; }
    command -v brew >/dev/null || { log_error "Homebrew no está instalado. Instálalo desde https://brew.sh/"; has_error=true; }
    ping -c 1 8.8.8.8 >/dev/null 2>&1 || { log_error "No hay conexión a internet."; has_error=true; }
    [[ -f "$HOME/.zshrc" ]] || { log_error "No se encontró el archivo ~/.zshrc. Se creará uno nuevo durante la migración."; }
    local omz_found=false
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        omz_found=true
        log_info "Se detectó Oh My Zsh. Se migrará desde OMZ."
    else
        log_warn "No se detectó el directorio ~/.oh-my-zsh. Se migrará desde una configuración estándar de Zsh."
    fi

    if [[ "$has_error" = true ]]; then
        log_error "Fallo en la validación. Abortando misión."
        exit 1
    fi
    log_success "Sistema validado."
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


    log_info "Creando backup..."
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se crearía un backup en: $backup_dir"
        return
    fi
    
    mkdir -p "$backup_dir"

    # Respaldar .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$backup_dir/"
        log_verbose "Backup de ~/.zshrc creado."
    fi

    # Respaldar directorio de Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        # Usamos cp -R para copiar el directorio de forma recursiva.
        cp -R "$HOME/.oh-my-zsh" "$backup_dir/"
        log_verbose "Backup de ~/.oh-my-zsh creado."
    fi

    # Respaldar config existente de starship
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        cp "$HOME/.config/starship.toml" "$backup_dir/"
        log_verbose "Backup de ~/.config/starship.toml creado."
    fi
    
    log_success "Backup creado en: $backup_dir"
}

# Analiza el .zshrc para extraer configuraciones personales.
# Utiliza 'grep' y 'awk' para parsear el archivo. Es una técnica de scripting
# muy potente para extraer datos de ficheros de texto.
analyze_config() {
    log_info "Analizando configuración actual de ~/.zshrc..."
    local zshrc_file="$HOME/.zshrc"

    # Extraer alias, excluyendo líneas comentadas y las que vienen de OMZ.
    USER_ALIASES=$(grep -E '^[[:space:]]*alias[[:space:]]' "$zshrc_file" | grep -v '^[[:space:]]*#')
    COUNT_ALIASES=$(echo "$USER_ALIASES" | grep -c '^alias' || echo 0)
    log_verbose "Extraídos $COUNT_ALIASES alias."

    # Extraer exports.
    USER_EXPORTS=$(grep -E '^[[:space:]]*export[[:space:]]' "$zshrc_file" | grep -v '^[[:space:]]*#')
    COUNT_EXPORTS=$(echo "$USER_EXPORTS" | grep -c '^export' || echo 0)
    log_verbose "Extraídos $COUNT_EXPORTS exports."

    # Extraer funciones. Mejorado para soportar funciones complejas y anidadas.
    log_verbose "Iniciando extracción de funciones..."
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
    COUNT_FUNCTIONS=$(echo "$USER_FUNCTIONS" | grep -Ec '^[[:space:]]*(function|[a-zA-Z0-9_-]+[[:space:]]*\(\))' || echo 0)
    log_verbose "Extraídas $COUNT_FUNCTIONS funciones."

    # Validar variables extraídas
    if [[ -z "$USER_ALIASES" ]]; then log_verbose "No se encontraron alias de usuario."; fi
    if [[ -z "$USER_EXPORTS" ]]; then log_verbose "No se encontraron exports de usuario."; fi
    if [[ -z "$USER_FUNCTIONS" ]]; then log_verbose "No se encontraron funciones de usuario."; fi

    # Exportar los contadores para el mensaje final.
    export COUNT_ALIASES COUNT_EXPORTS COUNT_FUNCTIONS
    log_verbose "Extracción de configuración completada."
}

# Selección interactiva de plugins de Zsh usando gum
select_zsh_plugins() {
    if ! command -v gum >/dev/null; then
        log_info "Instalando 'gum' para selección interactiva..."
        brew install gum >/dev/null
    fi
    log_info "Selecciona los plugins de Zsh que deseas instalar (espacio para marcar, enter para confirmar):"
    local options=(
        "zsh-autosuggestions [Sugerencias de comandos]"
        "zsh-syntax-highlighting [Resaltado de sintaxis]"
        "zsh-completions [Completado avanzado]"
        "zsh-history-substring-search [Búsqueda en historial]"
        "zsh-you-should-use [Sugerencias de alias]"
    )
    local selected
    selected=$(printf '%s\n' "${options[@]}" | gum choose --no-limit --header "Selecciona (espacio para marcar, enter para confirmar):")
    INSTALL_AUTOSUGGESTIONS=false
    INSTALL_SYNTAX_HIGHLIGHTING=false
    INSTALL_COMPLETIONS=false
    INSTALL_HISTORY_SUBSTRING=false
    INSTALL_YOU_SHOULD_USE=false
    while IFS= read -r line; do
        case "$line" in
            "zsh-autosuggestions"*) INSTALL_AUTOSUGGESTIONS=true ;;
            "zsh-syntax-highlighting"*) INSTALL_SYNTAX_HIGHLIGHTING=true ;;
            "zsh-completions"*) INSTALL_COMPLETIONS=true ;;
            "zsh-history-substring-search"*) INSTALL_HISTORY_SUBSTRING=true ;;
            "zsh-you-should-use"*) INSTALL_YOU_SHOULD_USE=true ;;
        esac
    done <<< "$selected"
    export INSTALL_AUTOSUGGESTIONS INSTALL_SYNTAX_HIGHLIGHTING INSTALL_COMPLETIONS INSTALL_HISTORY_SUBSTRING INSTALL_YOU_SHOULD_USE
}

# Selección interactiva de customizaciones de Starship usando gum
select_starship_features() {
    # Selección automática de todas las opciones por defecto (sin interacción)
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
    STARSHIP_PYENV=true
    STARSHIP_PKG_VERSION=true
    STARSHIP_SHELL=true
    export STARSHIP_THEME STARSHIP_BLANK_LINE STARSHIP_GIT STARSHIP_NODEJS STARSHIP_PYTHON STARSHIP_DOCKER STARSHIP_CUSTOM_SYMBOLS \
        STARSHIP_MULTILINE STARSHIP_TRUNC_DIR STARSHIP_COLOR_DIR STARSHIP_LANG_SYMBOLS STARSHIP_CMD_DURATION STARSHIP_USER_SMART \
        STARSHIP_HOST_SMART STARSHIP_BATTERY STARSHIP_JOBS STARSHIP_TIME STARSHIP_PYENV STARSHIP_PKG_VERSION STARSHIP_SHELL
}

# Instala todas las dependencias necesarias.
# Abstraer la instalación en una función permite reutilizar la lógica
# y añadir o quitar dependencias fácilmente.
install_dependencies() {
    log_info "Instalando dependencias..."
    set +e  # Desactivar 'set -e' temporalmente para depuración
    log_verbose "[DEBUG] Inicia bloque Starship"
    # 1. Starship
    if ! command -v starship >/dev/null; then
        log_info "Instalando Starship..."
        if [[ "$DRY_RUN" = true ]]; then
            log_warn "[DRY-RUN] Se ejecutaría: brew install starship"
        else
            brew install starship >/dev/null
        fi
        log_success "Starship instalado."
    else
        log_success "Starship ya está instalado."
    fi
    log_verbose "[DEBUG] Fin bloque Starship"

    log_verbose "[DEBUG] Inicia bloque plugins Zsh"
    log_info "Instalando plugins de Zsh..."
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se clonarían los repositorios de plugins en $ZSH_PLUGINS_DIR"
    else
        mkdir -p "$ZSH_PLUGINS_DIR"
        # zsh-autosuggestions
        if [[ "$INSTALL_AUTOSUGGESTIONS" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
            git clone --quiet https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
        fi
        # zsh-syntax-highlighting
        if [[ "$INSTALL_SYNTAX_HIGHLIGHTING" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
            git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"
        fi
        # zsh-completions
        if [[ "$INSTALL_COMPLETIONS" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-completions" ]]; then
            git clone --quiet https://github.com/zsh-users/zsh-completions "$ZSH_PLUGINS_DIR/zsh-completions"
        fi
        # zsh-history-substring-search
        if [[ "$INSTALL_HISTORY_SUBSTRING" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-history-substring-search" ]]; then
            git clone --quiet https://github.com/zsh-users/zsh-history-substring-search "$ZSH_PLUGINS_DIR/zsh-history-substring-search"
        fi
        # zsh-you-should-use
        if [[ "$INSTALL_YOU_SHOULD_USE" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-you-should-use" ]]; then
            git clone --quiet https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_PLUGINS_DIR/zsh-you-should-use"
        fi
    fi
    log_success "Plugins de Zsh instalados."
    log_verbose "[DEBUG] Fin bloque plugins Zsh"

    log_verbose "[DEBUG] Inicia bloque herramientas modernas"
    # 3. Modern CLI tools (condicional)
    if [[ "$SKIP_TOOLS" = true ]]; then
        log_info "Se omite la instalación de herramientas modernas (--skip-tools)."
        set -e  # Restaurar 'set -e' antes de salir
        return
    fi
    log_info "Instalando herramientas modernas (eza, bat, fd, ripgrep, fzf)..."
    local tools_to_install=()
    [[ "$INSTALL_EZA" = true ]] && ! command -v eza >/dev/null && tools_to_install+=("eza")
    [[ "$INSTALL_BAT" = true ]] && ! command -v bat >/dev/null && tools_to_install+=("bat")
    [[ "$INSTALL_FD" = true ]] && ! command -v fd >/dev/null && tools_to_install+=("fd")
    [[ "$INSTALL_RIPGREP" = true ]] && ! command -v ripgrep >/dev/null && tools_to_install+=("ripgrep")
    [[ "$INSTALL_FZF" = true ]] && ! command -v fzf >/dev/null && tools_to_install+=("fzf")
    if [[ ${#tools_to_install[@]} -gt 0 ]]; then
        if [[ "$DRY_RUN" = true ]]; then
            log_warn "[DRY-RUN] Se ejecutaría: brew install ${tools_to_install[*]}"
        else
            brew install ${tools_to_install[@]} >/dev/null
        fi
    fi
    # fzf requiere instalación post-brew
    if [[ "$DRY_RUN" = false ]] && command -v fzf >/dev/null; then
        "$(brew --prefix)"/opt/fzf/install --all --no-update-rc >/dev/null
    fi
    log_success "Herramientas modernas instaladas."
    log_verbose "[DEBUG] Fin bloque herramientas modernas"
    set -e  # Restaurar 'set -e' al final de la función
}


# Genera los nuevos archivos de configuración .zshrc y starship.toml.
# Usar Here Documents (<<EOF) es una forma limpia de generar archivos de
# configuración multilínea desde un script.
generate_new_config() {
    log_info "Generando nueva configuración..."
    
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
HISTFILE=\$HOME/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY           # Añade al historial, no sobrescribe
setopt EXTENDED_HISTORY         # Guarda timestamp y duración
setopt INC_APPEND_HISTORY       # Guarda comandos inmediatamente
setopt SHARE_HISTORY            # Comparte historial entre terminales
setopt HIST_IGNORE_DUPS         # No guarda duplicados consecutivos
setopt HIST_IGNORE_ALL_DUPS     # Borra duplicados antiguos
setopt HIST_FIND_NO_DUPS        # No muestra duplicados al buscar

# --- Path del Usuario ---
# Asegúrate de que Homebrew y otros directorios estén en el PATH
export PATH="/usr/local/bin:/usr/local/sbin:\$HOME/.local/bin:\$PATH"

# --- Plugins de Zsh ---
# Directorio donde se clonan los plugins de Zsh
ZSH_PLUGINS_DIR="\$HOME/.zsh/plugins"

# Cargar zsh-autosuggestions
if [ -f "\$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Cargar zsh-syntax-highlighting (DEBE SER EL ÚLTIMO PLUGIN EN CARGARSE)
if [ -f "\$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# --- Configuración de FZF (Búsqueda Fuzzy) ---
if command -v fzf >/dev/null; then
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# --- Alias para Herramientas Modernas ---
# Solo se añaden si los comandos existen
if command -v eza >/dev/null; then
    alias ls='eza --icons'
    alias la='eza -a --icons'
    alias ll='eza -l --icons'
    alias l='eza -l --icons'
fi
if command -v bat >/dev/null; then alias cat='bat --paging=never'; fi

# ==============================================================================
# --- CONFIGURACIÓN PERSONAL DEL USUARIO (MIGRADA) ---
# ==============================================================================

# --- Alias Personales ---
$USER_ALIASES

# --- Variables de Entorno (Exports) ---
$USER_EXPORTS

# --- Funciones Personales ---
$USER_FUNCTIONS

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
    starship_config_content=""
    # Tema base
    case "$STARSHIP_THEME" in
        "Pastel Powerline")
            starship_config_content+="# Pastel Powerline\n"
            ;;
        "Minimal")
            starship_config_content+="# Minimal\n"
            ;;
        "Nerd")
            starship_config_content+="# Nerd\n"
            ;;
    esac
    starship_config_content+="# Starship Configuration (starship.toml) - Creado por script de migración\n"
    starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
    if [[ "$STARSHIP_MULTILINE" = true ]]; then
        starship_config_content+='format = """$directory\n$character"""\n\n'
    fi
    if [[ "$STARSHIP_TRUNC_DIR" = true || "$STARSHIP_COLOR_DIR" = true ]]; then
        starship_config_content+="[directory]\n"
        [[ "$STARSHIP_TRUNC_DIR" = true ]] && starship_config_content+="truncation_length = 3\ntruncate_to_repo = true\n"
        [[ "$STARSHIP_COLOR_DIR" = true ]] && starship_config_content+="style = \"bold magenta\"\n"
        starship_config_content+="\n"
    fi
    if [[ "$STARSHIP_GIT" = true ]]; then
        starship_config_content+="[git_branch]\nsymbol = \"🌱 \"\nstyle = \"bold yellow\"\n\n[git_status]\nstyle = \"bold red\"\nstashed = \"📦\"\nahead = \"⇡\${count}\"\nbehind = \"⇣\${count}\"\ndiverged = \"⇕⇡\${ahead_count}⇣\${behind_count}\"\nconflicted = \"🔥\"\ndeleted = \"🗑️ \"\nrenamed = \"🏷️ \"\nmodified = \"📝 \"\nstaged = '[++\($count\)](green)'\nuntracked = \"🤷 \"\n\n"
    fi
    if [[ "$STARSHIP_NODEJS" = true ]]; then
        starship_config_content+="[nodejs]\nsymbol = \"🤖 \"\n\n"
    fi
    # Unificar bloque [python]
    if [[ "$STARSHIP_PYTHON" = true || "$STARSHIP_PYENV" = true ]]; then
        starship_config_content+="[python]\n"
        [[ "$STARSHIP_PYTHON" = true ]] && starship_config_content+="symbol = \"🐍 \"\n"
        [[ "$STARSHIP_PYENV" = true ]] && starship_config_content+="disabled = false\npyenv_version_name = true\n"
        starship_config_content+="\n"
    fi
    if [[ "$STARSHIP_DOCKER" = true ]]; then
        starship_config_content+="[docker_context]\nsymbol = \"🐳 \"\n\n"
    fi
    # Unificar bloque [character] y símbolos de lenguajes
    if [[ "$STARSHIP_CUSTOM_SYMBOLS" = true || "$STARSHIP_LANG_SYMBOLS" = true ]]; then
        starship_config_content+="[character]\nsuccess_symbol = \"[➜](bold green)\"\nerror_symbol = \"[✗](bold red)\"\nvicmd_symbol = \"[V](bold green)\"\n\n[golang]\nsymbol = \"🐹 \"\n[rust]\nsymbol = \"🦀 \"\n[conda]\nsymbol = \"🗂️  \"\n[terraform]\nsymbol = \"💠 \"\n\n"
    fi
    if [[ "$STARSHIP_CMD_DURATION" = true ]]; then
        starship_config_content+="[cmd_duration]\nmin_time = 500\nformat = \"took [$duration]($style) \"\nstyle = \"yellow bold\"\n\n"
    fi
    if [[ "$STARSHIP_USER_SMART" = true ]]; then
        starship_config_content+="[username]\ndisabled = false\nshow_always = false\n\n"
    fi
    if [[ "$STARSHIP_HOST_SMART" = true ]]; then
        starship_config_content+="[hostname]\ndisabled = false\nssh_only = true\n\n"
    fi
    if [[ "$STARSHIP_BATTERY" = true ]]; then
        starship_config_content+="[battery]\ndisabled = false\nfull_symbol = \"🔋\"\ndischarging_symbol = \"🔌\"\ncharging_symbol = \"⚡\"\n\n"
    fi
    if [[ "$STARSHIP_JOBS" = true ]]; then
        starship_config_content+="[jobs]\nsymbol = \"✦\"\nthreshold = 1\nstyle = \"bold blue\"\n\n"
    fi
    if [[ "$STARSHIP_TIME" = true ]]; then
        starship_config_content+="[time]\ndisabled = false\nformat = \"[$time]($style) \"\nstyle = \"bold yellow\"\n\n"
    fi
    if [[ "$STARSHIP_PKG_VERSION" = true ]]; then
        starship_config_content+="[package]\ndisabled = false\nformat = \"[$version](208 bold) \"\n\n"
    fi
    if [[ "$STARSHIP_SHELL" = true ]]; then
        starship_config_content+="[shell]\ndisabled = false\nformat = \"[$indicator]($style) \"\nstyle = \"bold green\"\n\n"
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
    echo "$new_zshrc_content" > "$HOME/.zshrc.new"
    if zsh -n "$HOME/.zshrc.new"; then
        mv "$HOME/.zshrc.new" "$HOME/.zshrc"
        log_success "Nuevo .zshrc generado (preservados $COUNT_ALIASES aliases, $COUNT_EXPORTS exports, $COUNT_FUNCTIONS funciones)."
    else
        log_error "El .zshrc generado tiene un error de sintaxis. Abortando para prevenir problemas."
        rm "$HOME/.zshrc.new"
        exit 1
    fi

    # Escribir la configuración de Starship
    mkdir -p "$HOME/.config"
    echo -e "$starship_config_content" > "$starship_config_path"
    log_success "Configuración de Starship creada en ~/.config/starship.toml."
}

# Restaura la configuración desde el último backup.
rollback_migration() {
    log_info "Iniciando rollback..."
    
    local latest_backup
    # Encuentra el backup más reciente ordenando por nombre (timestamp).
    latest_backup=$(find "$BACKUP_BASE_DIR" -maxdepth 1 -type d -name "20*" | sort -r | head -n 1)

    if [[ -z "$latest_backup" ]]; then
        log_error "No se encontraron backups en $BACKUP_BASE_DIR. No se puede hacer rollback."
        exit 1
    fi

    log_info "Restaurando desde el backup: $latest_backup"

    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se restaurarían los archivos desde $latest_backup."
        return
    fi

    # Restaurar .zshrc
    if [[ -f "$latest_backup/.zshrc" ]]; then
        cp "$latest_backup/.zshrc" "$HOME/.zshrc"
        log_verbose "Restaurado ~/.zshrc"
    fi

    # Restaurar Oh My Zsh
    if [[ -d "$latest_backup/.oh-my-zsh" ]]; then
        # Borrar el directorio actual (si existe) y luego copiar el del backup
        rm -rf "$HOME/.oh-my-zsh"
        cp -R "$latest_backup/.oh-my-zsh" "$HOME/"
        log_verbose "Restaurado ~/.oh-my-zsh/"
    fi
    
    # Restaurar starship.toml si existía en el backup
    if [[ -f "$latest_backup/starship.toml" ]]; then
        cp "$latest_backup/starship.toml" "$HOME/.config/starship.toml"
        log_verbose "Restaurado ~/.config/starship.toml"
    else
        # Si no había backup, lo borramos para no dejar un estado mixto.
        rm -f "$HOME/.config/starship.toml"
    fi
    
    log_success "Rollback completado. La configuración anterior ha sido restaurada."
    log_info "Reinicia tu terminal para aplicar los cambios."
}

# Muestra el estado actual de la configuración (OMZ o Starship).
show_status() {
    log_info "--- Estado de la Configuración de Zsh ---"
    if grep -q "starship init zsh" "$HOME/.zshrc" &>/dev/null; then
        log_success "Se detectó una configuración con Starship."
    elif [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_success "Se detectó una instalación de Oh My Zsh."
        local theme
        theme=$(grep -E '^\s*ZSH_THEME=' "$HOME/.zshrc" | cut -d'"' -f2)
        log_info "Tema actual de OMZ: $theme"
    else
        log_warn "Configuración no reconocida (ni OMZ ni Starship)."
    fi

    log_info "\n--- Herramientas y Plugins Detectados ---"
    command -v starship &>/dev/null && log_success "Starship: Instalado" || log_error "Starship: No instalado"
    [[ -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]] && log_success "zsh-autosuggestions: Instalado" || log_warn "zsh-autosuggestions: No instalado"
    [[ -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]] && log_success "zsh-syntax-highlighting: Instalado" || log_warn "zsh-syntax-highlighting: No instalado"
    
    log_info "\n--- Herramientas Modernas ---"
    for tool in eza bat fd ripgrep fzf; do
        if command -v "$tool" &>/dev/null; then
            log_success "$tool: Instalado"
        else
            log_warn "$tool: No instalado"
        fi
    done
}

# Muestra la ayuda del script.
show_help() {
    # Usar 'cat <<EOF' es una forma limpia de imprimir bloques de texto.
    cat <<EOF
Script de Migración de Oh My Zsh a Starship (v${SCRIPT_VERSION})

Uso: ./migrate.sh [comando] [opciones]

Comandos:
  (sin comando)      Ejecuta la migración automática (default).
  rollback           Restaura la configuración de Oh My Zsh desde el último backup.
  status             Muestra el estado actual de la configuración.
  help, -h, --help   Muestra esta ayuda.

Opciones:
  --dry-run          Muestra lo que haría el script sin ejecutar cambios reales.
  --verbose          Activa el logging detallado para depuración.
  --skip-tools       Migra solo el prompt (Starship) y los plugins, sin instalar exa, bat, etc.
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
    for tool in eza bat fd ripgrep fzf; do
        if command -v "$tool" &>/dev/null; then
            echo -e "  ${C_GREEN}$tool: OK${C_NC} ($($tool --version | head -n1))"
        else
            echo -e "  ${C_RED}$tool: NO INSTALADO${C_NC}"
        fi
    done
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
    log_info "Validando entorno tras la migración..."
    local ok=0
    local fail=0
    local results=()
    # Test alias principales
    for a in ls la ll l; do
        if zsh -i -c "$a --icons" &>/dev/null; then
            results+=("✅ Alias $a OK")
            ((ok++))
        else
            results+=("❌ Alias $a FAIL")
            ((fail++))
        fi
    done
    # Test Starship prompt
    if zsh -i -c 'starship --version' &>/dev/null && grep -q 'starship init zsh' "$HOME/.zshrc"; then
        results+=("✅ Starship activo")
        ((ok++))
    else
        results+=("❌ Starship no activo")
        ((fail++))
    fi
    # Test plugins seleccionados
    [[ "$INSTALL_AUTOSUGGESTIONS" = true ]] && grep -q 'zsh-autosuggestions' "$HOME/.zshrc" && results+=("✅ zsh-autosuggestions cargado") || { [[ "$INSTALL_AUTOSUGGESTIONS" = true ]] && results+=("❌ zsh-autosuggestions no cargado"); }
    [[ "$INSTALL_SYNTAX_HIGHLIGHTING" = true ]] && grep -q 'zsh-syntax-highlighting' "$HOME/.zshrc" && results+=("✅ zsh-syntax-highlighting cargado") || { [[ "$INSTALL_SYNTAX_HIGHLIGHTING" = true ]] && results+=("❌ zsh-syntax-highlighting no cargado"); }
    [[ "$INSTALL_COMPLETIONS" = true ]] && grep -q 'zsh-completions' "$HOME/.zshrc" && results+=("✅ zsh-completions cargado") || { [[ "$INSTALL_COMPLETIONS" = true ]] && results+=("❌ zsh-completions no cargado"); }
    [[ "$INSTALL_HISTORY_SUBSTRING" = true ]] && grep -q 'zsh-history-substring-search' "$HOME/.zshrc" && results+=("✅ zsh-history-substring-search cargado") || { [[ "$INSTALL_HISTORY_SUBSTRING" = true ]] && results+=("❌ zsh-history-substring-search no cargado"); }
    [[ "$INSTALL_YOU_SHOULD_USE" = true ]] && grep -q 'zsh-you-should-use' "$HOME/.zshrc" && results+=("✅ zsh-you-should-use cargado") || { [[ "$INSTALL_YOU_SHOULD_USE" = true ]] && results+=("❌ zsh-you-should-use no cargado"); }
    # Test herramientas modernas
    for tool in eza bat fd ripgrep fzf; do
        if command -v "$tool" &>/dev/null; then
            results+=("✅ $tool OK")
        else
            results+=("❌ $tool NO INSTALADO")
        fi
    done
    # Mostrar resumen
    echo -e "\n${C_BLUE}Validación post-migración:${C_NC}"
    for r in "${results[@]}"; do
        echo -e "  $r"
    done
    echo -e "\n${C_GREEN}$ok OK${C_NC}  ${C_RED}$fail FAIL${C_NC}"
    if [[ $fail -eq 0 ]]; then
        return 0
    else
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

    # Paso 1: Selección de plugins de Zsh
    select_zsh_plugins
    # Paso 2: Selección de features/configuraciones de Starship
    select_starship_features
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
            show_status
            ;;
        report)
            generate_report
            ;;
        "") # Comando por defecto: migración
            log_info "🚀 Iniciando migración de Oh My Zsh a Starship..."
            validate_system || MIGRATION_OK=false
            log_info "Creando backup..."
            create_backup && BACKUP_OK=true || log_error "Backup fallido"
            log_info "Analizando configuración..."
            analyze_config && ANALYZE_OK=true || log_error "Análisis fallido"
            log_info "[DEBUG] Llamando a install_dependencies..."
            log_info "Instalando dependencias..."
            install_dependencies && INSTALL_OK=true || log_error "Fallo en dependencias"
            log_info "Generando nueva configuración..."
            generate_new_config && CONFIG_OK=true || log_error "Fallo en configuración"
            post_migration_validation && VALIDATION_OK=true || VALIDATION_OK=false
            # Resumen final
            echo -e "\n${C_BLUE}Resumen de la migración:${C_NC}"
            [[ "$BACKUP_OK" = true ]] && echo -e "  ✅ Backup creado" || echo -e "  ❌ Backup fallido"
            [[ "$ANALYZE_OK" = true ]] && echo -e "  ✅ Análisis de configuración OK" || echo -e "  ❌ Análisis fallido"
            [[ "$INSTALL_OK" = true ]] && echo -e "  ✅ Dependencias instaladas" || echo -e "  ❌ Fallo en dependencias"
            [[ "$CONFIG_OK" = true ]] && echo -e "  ✅ Configuración generada" || echo -e "  ❌ Fallo en configuración"
            [[ "$VALIDATION_OK" = true ]] && echo -e "  ✅ Validación post-migración OK" || echo -e "  ❌ Validación post-migración con errores"
            if [[ "$BACKUP_OK" = true && "$ANALYZE_OK" = true && "$INSTALL_OK" = true && "$CONFIG_OK" = true && "$VALIDATION_OK" = true ]]; then
                echo -e "\n${C_GREEN}🎉 ¡Migración completada con éxito!${C_NC}"
                echo -e "   - Backup creado en: ${C_YELLOW}${MIGRATION_BACKUP_PATH}${C_NC}"
                echo -e "   - Para revertir, ejecuta: ${C_YELLOW}./migrate.sh rollback${C_NC}"
                echo -e "   - ${C_BLUE}Por favor, reinicia tu terminal o ejecuta 'source ~/.zshrc' para ver los cambios.${C_NC}"
            else
                echo -e "\n${C_RED}❌ La migración no se completó correctamente. Revisa los mensajes anteriores para más detalles.${C_NC}"
            fi
            ;;
    esac
}

# --- EJECUCIÓN DEL SCRIPT ---
# Llama a la función 'main' pasándole todos los argumentos que recibió el script.
# La construcción `"$@"` expande cada argumento como una cadena separada,
# preservando espacios si los hubiera, lo que es crucial para un parseo correcto.
main "$@"


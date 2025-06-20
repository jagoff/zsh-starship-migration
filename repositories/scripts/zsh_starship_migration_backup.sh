#!/usr/bin/env zsh

# ===============================================================================
#
# Script de Migración de Oh My Zsh a Starship (Multiplataforma para cualquier Mac)

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

    local has_error=false
    command -v zsh >/dev/null || { log_error "Zsh no está instalado. Instala Zsh antes de continuar."; has_error=true; }
    command -v git >/dev/null || { log_error "Git no está instalado."; has_error=true; }
    
    # Validar gestor de paquetes según plataforma
    case "$PLATFORM" in
        "macos")
            command -v brew >/dev/null || { log_error "Homebrew no está instalado. Instálalo desde https://brew.sh/"; has_error=true; }
            ;;
        "linux")
            case "$PACKAGE_MANAGER" in
                "apt")
                    command -v apt >/dev/null || { log_error "apt no está disponible."; has_error=true; }
                    ;;
                "dnf")
                    command -v dnf >/dev/null || { log_error "dnf no está disponible."; has_error=true; }
                    ;;
                "pacman")
                    command -v pacman >/dev/null || { log_error "pacman no está disponible."; has_error=true; }
                    ;;
                *)
                    log_warn "Gestor de paquetes no reconocido para Linux."
                    ;;
            esac
            ;;
        "windows")
            command -v choco >/dev/null || { log_warn "Chocolatey no está instalado. Algunas funciones pueden no funcionar."; }
            ;;
    esac
    
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
        "zsh-nvm [Gestión de Node.js]"
        "zsh-pyenv [Gestión de Python]"
        "zsh-autopair [Auto-cierre de paréntesis]"
        "zsh-sudo [Prefijo sudo con ESC]"
        "zsh-copyfile [Copia ruta al portapapeles]"
        "zsh-open-pr [Abre PRs desde terminal]"
        "zsh-docker-aliases [Alias útiles para Docker]"
        "zsh-git-aliases [Alias útiles para Git]"
        "zsh-kubectl-aliases [Alias útiles para Kubernetes]"
        "zsh-aws-vault [Gestión de credenciales AWS]"
    )
    local selected
    selected=$(printf '%s\n' "${options[@]}" | gum choose --no-limit --header "Selecciona (espacio para marcar, enter para confirmar):")
    
    # Inicializar todas las variables de plugins
    INSTALL_AUTOSUGGESTIONS=false
    INSTALL_SYNTAX_HIGHLIGHTING=false
    INSTALL_COMPLETIONS=false
    INSTALL_HISTORY_SUBSTRING=false
    INSTALL_YOU_SHOULD_USE=false
    INSTALL_NVM=false
    INSTALL_PYENV=false
    INSTALL_AUTOPAIR=false
    INSTALL_SUDO=false
    INSTALL_COPYFILE=false
    INSTALL_OPEN_PR=false
    INSTALL_DOCKER_ALIASES=false
    INSTALL_GIT_ALIASES=false
    INSTALL_KUBECTL_ALIASES=false
    INSTALL_AWS_VAULT=false
    
    while IFS= read -r line; do
        case "$line" in
            "zsh-autosuggestions"*) INSTALL_AUTOSUGGESTIONS=true ;;
            "zsh-syntax-highlighting"*) INSTALL_SYNTAX_HIGHLIGHTING=true ;;
            "zsh-completions"*) INSTALL_COMPLETIONS=true ;;
            "zsh-history-substring-search"*) INSTALL_HISTORY_SUBSTRING=true ;;
            "zsh-you-should-use"*) INSTALL_YOU_SHOULD_USE=true ;;
            "zsh-nvm"*) INSTALL_NVM=true ;;
            "zsh-pyenv"*) INSTALL_PYENV=true ;;
            "zsh-autopair"*) INSTALL_AUTOPAIR=true ;;
            "zsh-sudo"*) INSTALL_SUDO=true ;;
            "zsh-copyfile"*) INSTALL_COPYFILE=true ;;
            "zsh-open-pr"*) INSTALL_OPEN_PR=true ;;
            "zsh-docker-aliases"*) INSTALL_DOCKER_ALIASES=true ;;
            "zsh-git-aliases"*) INSTALL_GIT_ALIASES=true ;;
            "zsh-kubectl-aliases"*) INSTALL_KUBECTL_ALIASES=true ;;
            "zsh-aws-vault"*) INSTALL_AWS_VAULT=true ;;
        esac
    done <<< "$selected"
    
    export INSTALL_AUTOSUGGESTIONS INSTALL_SYNTAX_HIGHLIGHTING INSTALL_COMPLETIONS INSTALL_HISTORY_SUBSTRING INSTALL_YOU_SHOULD_USE \
           INSTALL_NVM INSTALL_PYENV INSTALL_AUTOPAIR INSTALL_SUDO INSTALL_COPYFILE INSTALL_OPEN_PR INSTALL_DOCKER_ALIASES \
           INSTALL_GIT_ALIASES INSTALL_KUBECTL_ALIASES INSTALL_AWS_VAULT
}

# Selección interactiva de customizaciones de Starship usando gum
select_starship_features() {
    log_info "Configurando temas y personalización de Starship..."
    
    # Nuevos temas avanzados disponibles
    local theme_options=(
        "Pastel Powerline [Clásico con colores suaves]"
        "Minimal [Minimalista y limpio]"
        "Nerd [Con símbolos Nerd Fonts]"
        "Cyberpunk [Colores neón futuristas]"
        "Minimalist Dark [Tema oscuro elegante]"
        "Professional [Tema corporativo]"
        "Developer [Optimizado para desarrollo]"
        "Gaming [Colores vibrantes gaming]"
        "Custom [Personalización completa]"
    )
    
    # Selección de tema con gum si está disponible
    if command -v gum >/dev/null; then
        log_info "Selecciona el tema de Starship:"
        local selected_theme
        selected_theme=$(printf '%s\n' "${theme_options[@]}" | gum choose --header "Tema de Starship:")
        case "$selected_theme" in
            "Pastel Powerline"*) STARSHIP_THEME="Pastel Powerline" ;;
            "Minimal"*) STARSHIP_THEME="Minimal" ;;
            "Nerd"*) STARSHIP_THEME="Nerd" ;;
            "Cyberpunk"*) STARSHIP_THEME="Cyberpunk" ;;
            "Minimalist Dark"*) STARSHIP_THEME="Minimalist Dark" ;;
            "Professional"*) STARSHIP_THEME="Professional" ;;
            "Developer"*) STARSHIP_THEME="Developer" ;;
            "Gaming"*) STARSHIP_THEME="Gaming" ;;
            "Custom"*) STARSHIP_THEME="Custom" ;;
            *) STARSHIP_THEME="Pastel Powerline" ;; # Default
        esac
    else
        # Fallback automático si gum no está disponible
        STARSHIP_THEME="Pastel Powerline"
        log_info "Usando tema por defecto: $STARSHIP_THEME"
    fi
    
    # Configuración de colores personalizados para tema Custom
    if [[ "$STARSHIP_THEME" = "Custom" ]]; then
        log_info "Configurando colores personalizados..."
        STARSHIP_CUSTOM_PRIMARY_COLOR="blue"
        STARSHIP_CUSTOM_SECONDARY_COLOR="green"
        STARSHIP_CUSTOM_ACCENT_COLOR="yellow"
        STARSHIP_CUSTOM_ERROR_COLOR="red"
        STARSHIP_CUSTOM_SUCCESS_COLOR="green"
    fi
    
    # Configuraciones base (todas activadas por defecto)
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
    
    # Nuevas features avanzadas
    STARSHIP_WEATHER=false
    STARSHIP_CRYPTO=false
    STARSHIP_KUBERNETES=true
    STARSHIP_AWS=true
    STARSHIP_DENO=true
    STARSHIP_ELIXIR=true
    STARSHIP_OCAML=true
    STARSHIP_PHP=true
    STARSHIP_RUBY=true
    STARSHIP_SWIFT=true
    STARSHIP_TERRAFORM=true
    STARSHIP_VAULT=true
    
    export STARSHIP_THEME STARSHIP_BLANK_LINE STARSHIP_GIT STARSHIP_NODEJS STARSHIP_PYTHON STARSHIP_DOCKER STARSHIP_CUSTOM_SYMBOLS \
        STARSHIP_MULTILINE STARSHIP_TRUNC_DIR STARSHIP_COLOR_DIR STARSHIP_LANG_SYMBOLS STARSHIP_CMD_DURATION STARSHIP_USER_SMART \
        STARSHIP_HOST_SMART STARSHIP_BATTERY STARSHIP_JOBS STARSHIP_TIME STARSHIP_PYENV STARSHIP_PKG_VERSION STARSHIP_SHELL \
        STARSHIP_CUSTOM_PRIMARY_COLOR STARSHIP_CUSTOM_SECONDARY_COLOR STARSHIP_CUSTOM_ACCENT_COLOR STARSHIP_CUSTOM_ERROR_COLOR STARSHIP_CUSTOM_SUCCESS_COLOR \
        STARSHIP_WEATHER STARSHIP_CRYPTO STARSHIP_KUBERNETES STARSHIP_AWS STARSHIP_DENO STARSHIP_ELIXIR STARSHIP_OCAML STARSHIP_PHP STARSHIP_RUBY STARSHIP_SWIFT STARSHIP_TERRAFORM STARSHIP_VAULT
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
        
        # Plugins básicos
        if [[ "$INSTALL_AUTOSUGGESTIONS" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-autosuggestions" ]]; then
            git clone --quiet https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS_DIR/zsh-autosuggestions"
        fi
        if [[ "$INSTALL_SYNTAX_HIGHLIGHTING" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting" ]]; then
            git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS_DIR/zsh-syntax-highlighting"
        fi
        if [[ "$INSTALL_COMPLETIONS" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-completions" ]]; then
            git clone --quiet https://github.com/zsh-users/zsh-completions "$ZSH_PLUGINS_DIR/zsh-completions"
        fi
        if [[ "$INSTALL_HISTORY_SUBSTRING" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-history-substring-search" ]]; then
            git clone --quiet https://github.com/zsh-users/zsh-history-substring-search "$ZSH_PLUGINS_DIR/zsh-history-substring-search"
        fi
        if [[ "$INSTALL_YOU_SHOULD_USE" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-you-should-use" ]]; then
            git clone --quiet https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_PLUGINS_DIR/zsh-you-should-use"
        fi
        
        # Plugins avanzados
        if [[ "$INSTALL_NVM" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-nvm" ]]; then
            git clone --quiet https://github.com/lukechilds/zsh-nvm "$ZSH_PLUGINS_DIR/zsh-nvm"
        fi
        if [[ "$INSTALL_PYENV" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-pyenv" ]]; then
            git clone --quiet https://github.com/davidparsson/zsh-pyenv-lazy "$ZSH_PLUGINS_DIR/zsh-pyenv"
        fi
        if [[ "$INSTALL_AUTOPAIR" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-autopair" ]]; then
            git clone --quiet https://github.com/hlissner/zsh-autopair "$ZSH_PLUGINS_DIR/zsh-autopair"
        fi
        if [[ "$INSTALL_SUDO" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-sudo" ]]; then
            git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_PLUGINS_DIR/ohmyzsh-temp" 2>/dev/null
            if [[ -d "$ZSH_PLUGINS_DIR/ohmyzsh-temp" ]]; then
                cp -r "$ZSH_PLUGINS_DIR/ohmyzsh-temp/plugins/sudo" "$ZSH_PLUGINS_DIR/zsh-sudo"
                rm -rf "$ZSH_PLUGINS_DIR/ohmyzsh-temp"
            fi
        fi
        if [[ "$INSTALL_COPYFILE" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-copyfile" ]]; then
            git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_PLUGINS_DIR/ohmyzsh-temp" 2>/dev/null
            if [[ -d "$ZSH_PLUGINS_DIR/ohmyzsh-temp" ]]; then
                cp -r "$ZSH_PLUGINS_DIR/ohmyzsh-temp/plugins/copyfile" "$ZSH_PLUGINS_DIR/zsh-copyfile"
                rm -rf "$ZSH_PLUGINS_DIR/ohmyzsh-temp"
            fi
        fi
        if [[ "$INSTALL_OPEN_PR" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-open-pr" ]]; then
            git clone --quiet https://github.com/paulirish/git-open "$ZSH_PLUGINS_DIR/zsh-open-pr"
        fi
        if [[ "$INSTALL_DOCKER_ALIASES" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-docker-aliases" ]]; then
            git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_PLUGINS_DIR/ohmyzsh-temp" 2>/dev/null
            if [[ -d "$ZSH_PLUGINS_DIR/ohmyzsh-temp" ]]; then
                cp -r "$ZSH_PLUGINS_DIR/ohmyzsh-temp/plugins/docker" "$ZSH_PLUGINS_DIR/zsh-docker-aliases"
                rm -rf "$ZSH_PLUGINS_DIR/ohmyzsh-temp"
            fi
        fi
        if [[ "$INSTALL_GIT_ALIASES" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-git-aliases" ]]; then
            git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_PLUGINS_DIR/ohmyzsh-temp" 2>/dev/null
            if [[ -d "$ZSH_PLUGINS_DIR/ohmyzsh-temp" ]]; then
                cp -r "$ZSH_PLUGINS_DIR/ohmyzsh-temp/plugins/git" "$ZSH_PLUGINS_DIR/zsh-git-aliases"
                rm -rf "$ZSH_PLUGINS_DIR/ohmyzsh-temp"
            fi
        fi
        if [[ "$INSTALL_KUBECTL_ALIASES" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-kubectl-aliases" ]]; then
            git clone --quiet https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_PLUGINS_DIR/ohmyzsh-temp" 2>/dev/null
            if [[ -d "$ZSH_PLUGINS_DIR/ohmyzsh-temp" ]]; then
                cp -r "$ZSH_PLUGINS_DIR/ohmyzsh-temp/plugins/kubectl" "$ZSH_PLUGINS_DIR/zsh-kubectl-aliases"
                rm -rf "$ZSH_PLUGINS_DIR/ohmyzsh-temp"
            fi
        fi
        if [[ "$INSTALL_AWS_VAULT" = true && ! -d "$ZSH_PLUGINS_DIR/zsh-aws-vault" ]]; then
            git clone --quiet https://github.com/blimmer/zsh-aws-vault "$ZSH_PLUGINS_DIR/zsh-aws-vault"
        fi
    fi
    log_success "Plugins de Zsh instalados."
    log_verbose "[DEBUG] Fin bloque plugins Zsh"

    log_verbose "[DEBUG] Inicia bloque herramientas modernas"
    # 3. Modern CLI tools (condicional)
    if [[ "$SKIP_TOOLS" = true ]]; then
        log_info "Se omite la instalación de herramientas modernas (--skip-tools)."
    else
        # 3.1 Herramientas modernas básicas
        log_info "Instalando herramientas modernas básicas..."
        local basic_tools_to_install=()
        [[ "$INSTALL_EZA" = true ]] && ! command -v eza >/dev/null && basic_tools_to_install+=("eza")
        [[ "$INSTALL_BAT" = true ]] && ! command -v bat >/dev/null && basic_tools_to_install+=("bat")
        [[ "$INSTALL_FD" = true ]] && ! command -v fd >/dev/null && basic_tools_to_install+=("fd")
        [[ "$INSTALL_RIPGREP" = true ]] && ! command -v ripgrep >/dev/null && basic_tools_to_install+=("ripgrep")
        [[ "$INSTALL_FZF" = true ]] && ! command -v fzf >/dev/null && basic_tools_to_install+=("fzf")
        
        if [[ ${#basic_tools_to_install[@]} -gt 0 ]]; then
            if [[ "$DRY_RUN" = true ]]; then
                log_warn "[DRY-RUN] Se ejecutaría: brew install ${basic_tools_to_install[*]}"
            else
                brew install ${basic_tools_to_install[@]} >/dev/null
            fi
        fi
        
        # fzf requiere instalación post-brew
        if [[ "$DRY_RUN" = false ]] && command -v fzf >/dev/null; then
            "$(brew --prefix)"/opt/fzf/install --all --no-update-rc >/dev/null
        fi
        log_success "Herramientas modernas básicas instaladas."
        
        # 3.2 Herramientas modernas avanzadas
        log_info "Instalando herramientas modernas avanzadas..."
        
        # Selección interactiva de herramientas avanzadas
        if command -v gum >/dev/null; then
            log_info "Selecciona las herramientas avanzadas que deseas instalar:"
            local advanced_tools_options=(
                "zoxide [Navegación inteligente de directorios]"
                "atuin [Historial de comandos mejorado]"
                "navi [Cheatsheets interactivas]"
                "tldr [Documentación simplificada]"
                "procs [Alternativa moderna a ps]"
                "du-dust [Análisis de uso de disco]"
                "bottom [Monitor de sistema moderno]"
                "gitui [Interfaz TUI para Git]"
                "lazygit [Interfaz TUI para Git (alternativa)]"
                "neovim [Editor moderno]"
                "tmux [Gestor de terminales]"
                "htop [Monitor de procesos]"
            )
            
            local selected_advanced_tools
            selected_advanced_tools=$(printf '%s\n' "${advanced_tools_options[@]}" | gum choose --no-limit --header "Herramientas avanzadas (espacio para marcar, enter para confirmar):")
            
            # Inicializar variables de herramientas avanzadas
            INSTALL_ZOXIDE=false
            INSTALL_ATUIN=false
            INSTALL_NAVI=false
            INSTALL_TLDR=false
            INSTALL_PROCS=false
            INSTALL_DU_DUST=false
            INSTALL_BOTTOM=false
            INSTALL_GITUI=false
            INSTALL_LAZYGIT=false
            INSTALL_NEOVIM=false
            INSTALL_TMUX=false
            INSTALL_HTOP=false
            
            # Procesar selección
            while IFS= read -r line; do
                case "$line" in
                    "zoxide"*) INSTALL_ZOXIDE=true ;;
                    "atuin"*) INSTALL_ATUIN=true ;;
                    "navi"*) INSTALL_NAVI=true ;;
                    "tldr"*) INSTALL_TLDR=true ;;
                    "procs"*) INSTALL_PROCS=true ;;
                    "du-dust"*) INSTALL_DU_DUST=true ;;
                    "bottom"*) INSTALL_BOTTOM=true ;;
                    "gitui"*) INSTALL_GITUI=true ;;
                    "lazygit"*) INSTALL_LAZYGIT=true ;;
                    "neovim"*) INSTALL_NEOVIM=true ;;
                    "tmux"*) INSTALL_TMUX=true ;;
                    "htop"*) INSTALL_HTOP=true ;;
                esac
            done <<< "$selected_advanced_tools"
        else
            # Fallback: instalar herramientas más importantes por defecto
            log_info "Instalando herramientas avanzadas por defecto (gum no disponible)..."
            INSTALL_ZOXIDE=true
            INSTALL_ATUIN=true
            INSTALL_NAVI=true
            INSTALL_TLDR=true
            INSTALL_PROCS=true
            INSTALL_DU_DUST=true
            INSTALL_BOTTOM=false
            INSTALL_GITUI=true
            INSTALL_LAZYGIT=false
            INSTALL_NEOVIM=false
            INSTALL_TMUX=true
            INSTALL_HTOP=true
        fi
        
        # Instalar herramientas seleccionadas
        local advanced_tools_to_install=()
        [[ "$INSTALL_ZOXIDE" = true ]] && ! command -v zoxide >/dev/null && advanced_tools_to_install+=("zoxide")
        [[ "$INSTALL_ATUIN" = true ]] && ! command -v atuin >/dev/null && advanced_tools_to_install+=("atuin")
        [[ "$INSTALL_NAVI" = true ]] && ! command -v navi >/dev/null && advanced_tools_to_install+=("navi")
        [[ "$INSTALL_TLDR" = true ]] && ! command -v tldr >/dev/null && advanced_tools_to_install+=("tealdeer")
        [[ "$INSTALL_PROCS" = true ]] && ! command -v procs >/dev/null && advanced_tools_to_install+=("procs")
        [[ "$INSTALL_DU_DUST" = true ]] && ! command -v dust >/dev/null && advanced_tools_to_install+=("du-dust")
        [[ "$INSTALL_BOTTOM" = true ]] && ! command -v btm >/dev/null && advanced_tools_to_install+=("bottom")
        [[ "$INSTALL_GITUI" = true ]] && ! command -v gitui >/dev/null && advanced_tools_to_install+=("gitui")
        [[ "$INSTALL_LAZYGIT" = true ]] && ! command -v lazygit >/dev/null && advanced_tools_to_install+=("lazygit")
        [[ "$INSTALL_NEOVIM" = true ]] && ! command -v nvim >/dev/null && advanced_tools_to_install+=("neovim")
        [[ "$INSTALL_TMUX" = true ]] && ! command -v tmux >/dev/null && advanced_tools_to_install+=("tmux")
        [[ "$INSTALL_HTOP" = true ]] && ! command -v htop >/dev/null && advanced_tools_to_install+=("htop")
        
        if [[ ${#advanced_tools_to_install[@]} -gt 0 ]]; then
            if [[ "$DRY_RUN" = true ]]; then
                log_warn "[DRY-RUN] Se ejecutaría: brew install ${advanced_tools_to_install[*]}"
            else
                brew install ${advanced_tools_to_install[@]} >/dev/null
            fi
        fi
        
        # Configuraciones post-instalación
        if [[ "$DRY_RUN" = false ]]; then
            # Configurar zoxide
            if command -v zoxide >/dev/null; then
                log_verbose "Configurando zoxide..."
                mkdir -p "$HOME/.zsh"
                zoxide init zsh > "$HOME/.zsh/zoxide.zsh" 2>/dev/null || true
            fi
            
            # Configurar atuin
            if command -v atuin >/dev/null; then
                log_verbose "Configurando atuin..."
                mkdir -p "$HOME/.zsh"
                atuin init zsh > "$HOME/.zsh/atuin.zsh" 2>/dev/null || true
            fi
        fi
        
        log_success "Herramientas modernas avanzadas instaladas."
    fi
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

# Cargar plugins básicos
if [ -f "\$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-completions/zsh-completions.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-completions/zsh-completions.plugin.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-you-should-use/you-should-use.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-you-should-use/you-should-use.plugin.zsh"
fi

# Cargar plugins avanzados
if [ -f "\$ZSH_PLUGINS_DIR/zsh-nvm/zsh-nvm.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-nvm/zsh-nvm.plugin.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-pyenv/pyenv.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-pyenv/pyenv.plugin.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-autopair/autopair.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-autopair/autopair.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-sudo/sudo.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-sudo/sudo.plugin.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-copyfile/copyfile.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-copyfile/copyfile.plugin.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-open-pr/git-open.sh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-open-pr/git-open.sh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-docker-aliases/docker.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-docker-aliases/docker.plugin.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-git-aliases/git.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-git-aliases/git.plugin.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-kubectl-aliases/kubectl.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-kubectl-aliases/kubectl.plugin.zsh"
fi

if [ -f "\$ZSH_PLUGINS_DIR/zsh-aws-vault/aws-vault.plugin.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-aws-vault/aws-vault.plugin.zsh"
fi

# Cargar zsh-syntax-highlighting (DEBE SER EL ÚLTIMO PLUGIN EN CARGARSE)
if [ -f "\$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "\$ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# --- Configuración de FZF (Búsqueda Fuzzy) ---
if command -v fzf >/dev/null; then
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
fi

# --- Configuración de Herramientas Avanzadas ---
# Zoxide - Navegación inteligente de directorios
if command -v zoxide >/dev/null; then
    [ -f ~/.zsh/zoxide.zsh ] && source ~/.zsh/zoxide.zsh
fi

# Atuin - Historial de comandos mejorado
if command -v atuin >/dev/null; then
    [ -f ~/.zsh/atuin.zsh ] && source ~/.zsh/atuin.zsh
fi

# --- Alias para Herramientas Modernas ---
# Solo se añaden si los comandos existen
if command -v eza >/dev/null; then
    alias ls='eza --icons'
    alias la='eza -a --icons'
    alias ll='eza -l --icons'
    alias l='eza -l --icons'
    alias lt='eza --tree --icons'
    alias lla='eza -la --icons'
fi

if command -v bat >/dev/null; then 
    alias cat='bat --paging=never'
    alias less='bat --paging=always'
fi

if command -v fd >/dev/null; then
    alias find='fd'
fi

if command -v ripgrep >/dev/null; then
    alias grep='ripgrep'
fi

if command -v procs >/dev/null; then
    alias ps='procs'
fi

if command -v dust >/dev/null; then
    alias du='dust'
fi

if command -v btm >/dev/null; then
    alias htop='btm'
fi

if command -v gitui >/dev/null; then
    alias gui='gitui'
fi

if command -v lazygit >/dev/null; then
    alias lg='lazygit'
fi

if command -v navi >/dev/null; then
    alias cheat='navi'
fi

if command -v tldr >/dev/null; then
    alias help='tldr'
fi

# --- Alias de Productividad ---
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'

# Docker shortcuts
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'

# Kubernetes shortcuts
alias k='kubectl'
alias kg='kubectl get'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kp='kubectl port-forward'

# System shortcuts
alias c='clear'
alias h='history'
alias j='jobs'
alias v='vim'
alias nv='nvim'
alias t='tmux'
alias ta='tmux attach'
alias tn='tmux new-session'
alias tl='tmux list-sessions'

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
    
    # Configuración base según el tema seleccionado
    case "$STARSHIP_THEME" in
        "Pastel Powerline")
            starship_config_content+="# Pastel Powerline Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
        "Minimal")
            starship_config_content+="# Minimal Theme\n"
            starship_config_content+="add_newline = false\n\n"
            ;;
        "Nerd")
            starship_config_content+="# Nerd Fonts Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
        "Cyberpunk")
            starship_config_content+="# Cyberpunk Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
        "Minimalist Dark")
            starship_config_content+="# Minimalist Dark Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
        "Professional")
            starship_config_content+="# Professional Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
        "Developer")
            starship_config_content+="# Developer Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
        "Gaming")
            starship_config_content+="# Gaming Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
        "Custom")
            starship_config_content+="# Custom Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
        *)
            starship_config_content+="# Default Theme\n"
            starship_config_content+="add_newline = $STARSHIP_BLANK_LINE\n\n"
            ;;
    esac
    
    # Configuración de formato multilínea
    if [[ "$STARSHIP_MULTILINE" = true ]]; then
        case "$STARSHIP_THEME" in
            "Minimal")
                starship_config_content+='format = "$directory$character"\n\n'
                ;;
            "Minimalist Dark")
                starship_config_content+='format = "$directory$character"\n\n'
                ;;
            *)
                starship_config_content+='format = """$directory\n$character"""\n\n'
                ;;
        esac
    fi
    
    # Configuración de directorio según tema
    if [[ "$STARSHIP_TRUNC_DIR" = true || "$STARSHIP_COLOR_DIR" = true ]]; then
        starship_config_content+="[directory]\n"
        [[ "$STARSHIP_TRUNC_DIR" = true ]] && starship_config_content+="truncation_length = 3\ntruncate_to_repo = true\n"
        
        # Colores de directorio según tema
        case "$STARSHIP_THEME" in
            "Cyberpunk")
                starship_config_content+="style = \"bold bright-cyan\"\n"
                ;;
            "Minimalist Dark")
                starship_config_content+="style = \"bold white\"\n"
                ;;
            "Professional")
                starship_config_content+="style = \"bold blue\"\n"
                ;;
            "Developer")
                starship_config_content+="style = \"bold green\"\n"
                ;;
            "Gaming")
                starship_config_content+="style = \"bold bright-purple\"\n"
                ;;
            "Custom")
                starship_config_content+="style = \"bold $STARSHIP_CUSTOM_PRIMARY_COLOR\"\n"
                ;;
            *)
                [[ "$STARSHIP_COLOR_DIR" = true ]] && starship_config_content+="style = \"bold magenta\"\n"
                ;;
        esac
        starship_config_content+="\n"
    fi
    
    # Configuración de Git según tema
    if [[ "$STARSHIP_GIT" = true ]]; then
        case "$STARSHIP_THEME" in
            "Nerd")
                starship_config_content+="[git_branch]\nsymbol = \"  \"\nstyle = \"bold yellow\"\n\n[git_status]\nstyle = \"bold red\"\nstashed = \" \"\nahead = \"⇡\${count}\"\nbehind = \"⇣\${count}\"\ndiverged = \"⇕⇡\${ahead_count}⇣\${behind_count}\"\nconflicted = \" \"\ndeleted = \" \"\nrenamed = \" \"\nmodified = \" \"\nstaged = '[++\($count\)](green)'\nuntracked = \" \"\n\n"
                ;;
            "Cyberpunk")
                starship_config_content+="[git_branch]\nsymbol = \"⚡ \"\nstyle = \"bold bright-green\"\n\n[git_status]\nstyle = \"bold bright-red\"\nstashed = \"💾\"\nahead = \"⬆️\${count}\"\nbehind = \"⬇️\${count}\"\ndiverged = \"⬆️⬇️\${ahead_count}\${behind_count}\"\nconflicted = \"💥\"\ndeleted = \"🗑️\"\nrenamed = \"🏷️\"\nmodified = \"⚡\"\nstaged = '[++\($count\)](bright-green)'\nuntracked = \"❓\"\n\n"
                ;;
            "Gaming")
                starship_config_content+="[git_branch]\nsymbol = \"🎮 \"\nstyle = \"bold bright-yellow\"\n\n[git_status]\nstyle = \"bold bright-red\"\nstashed = \"🎒\"\nahead = \"⬆️\${count}\"\nbehind = \"⬇️\${count}\"\ndiverged = \"⬆️⬇️\${ahead_count}\${behind_count}\"\nconflicted = \"💣\"\ndeleted = \"💀\"\nrenamed = \"🏆\"\nmodified = \"⚔️\"\nstaged = '[++\($count\)](bright-green)'\nuntracked = \"🎯\"\n\n"
                ;;
            *)
                starship_config_content+="[git_branch]\nsymbol = \"🌱 \"\nstyle = \"bold yellow\"\n\n[git_status]\nstyle = \"bold red\"\nstashed = \"📦\"\nahead = \"⇡\${count}\"\nbehind = \"⇣\${count}\"\ndiverged = \"⇕⇡\${ahead_count}⇣\${behind_count}\"\nconflicted = \"🔥\"\ndeleted = \"🗑️ \"\nrenamed = \"🏷️ \"\nmodified = \"📝 \"\nstaged = '[++\($count\)](green)'\nuntracked = \"🤷 \"\n\n"
                ;;
        esac
    fi
    
    # Configuración de lenguajes de programación
    if [[ "$STARSHIP_NODEJS" = true ]]; then
        case "$STARSHIP_THEME" in
            "Nerd")
                starship_config_content+="[nodejs]\nsymbol = \" \"\n\n"
                ;;
            "Cyberpunk")
                starship_config_content+="[nodejs]\nsymbol = \"⚡ \"\nstyle = \"bold bright-green\"\n\n"
                ;;
            *)
                starship_config_content+="[nodejs]\nsymbol = \"🤖 \"\n\n"
                ;;
        esac
    fi
    
    # Configuración de Python
    if [[ "$STARSHIP_PYTHON" = true || "$STARSHIP_PYENV" = true ]]; then
        starship_config_content+="[python]\n"
        case "$STARSHIP_THEME" in
            "Nerd")
                starship_config_content+="symbol = \" \"\n"
                ;;
            "Cyberpunk")
                starship_config_content+="symbol = \"⚡ \"\nstyle = \"bold bright-yellow\"\n"
                ;;
            *)
                starship_config_content+="symbol = \"🐍 \"\n"
                ;;
        esac
        [[ "$STARSHIP_PYENV" = true ]] && starship_config_content+="disabled = false\npyenv_version_name = true\n"
        starship_config_content+="\n"
    fi
    
    # Configuración de Docker
    if [[ "$STARSHIP_DOCKER" = true ]]; then
        case "$STARSHIP_THEME" in
            "Nerd")
                starship_config_content+="[docker_context]\nsymbol = \" \"\n\n"
                ;;
            *)
                starship_config_content+="[docker_context]\nsymbol = \"🐳 \"\n\n"
                ;;
        esac
    fi
    
    # Configuración de Kubernetes
    if [[ "$STARSHIP_KUBERNETES" = true ]]; then
        starship_config_content+="[kubernetes]\nsymbol = \"☸️ \"\nstyle = \"bold blue\"\n\n"
    fi
    
    # Configuración de AWS
    if [[ "$STARSHIP_AWS" = true ]]; then
        starship_config_content+="[aws]\nsymbol = \"☁️ \"\nstyle = \"bold yellow\"\n\n"
    fi
    
    # Configuración de Terraform
    if [[ "$STARSHIP_TERRAFORM" = true ]]; then
        starship_config_content+="[terraform]\nsymbol = \"💠 \"\nstyle = \"bold purple\"\n\n"
    fi
    
    # Configuración de Vault
    if [[ "$STARSHIP_VAULT" = true ]]; then
        starship_config_content+="[vault]\nsymbol = \"🔐 \"\nstyle = \"bold red\"\n\n"
    fi
    
    # Configuración de otros lenguajes
    if [[ "$STARSHIP_DENO" = true ]]; then
        starship_config_content+="[deno]\nsymbol = \"🦕 \"\n\n"
    fi
    
    if [[ "$STARSHIP_ELIXIR" = true ]]; then
        starship_config_content+="[elixir]\nsymbol = \"💧 \"\n\n"
    fi
    
    if [[ "$STARSHIP_OCAML" = true ]]; then
        starship_config_content+="[ocaml]\nsymbol = \"🐪 \"\n\n"
    fi
    
    if [[ "$STARSHIP_PHP" = true ]]; then
        starship_config_content+="[php]\nsymbol = \"🐘 \"\n\n"
    fi
    
    if [[ "$STARSHIP_RUBY" = true ]]; then
        starship_config_content+="[ruby]\nsymbol = \"💎 \"\n\n"
    fi
    
    if [[ "$STARSHIP_SWIFT" = true ]]; then
        starship_config_content+="[swift]\nsymbol = \"🦅 \"\n\n"
    fi
    
    # Configuración de character según tema
    if [[ "$STARSHIP_CUSTOM_SYMBOLS" = true || "$STARSHIP_LANG_SYMBOLS" = true ]]; then
        starship_config_content+="[character]\n"
        case "$STARSHIP_THEME" in
            "Nerd")
                starship_config_content+="success_symbol = \"[ ](bold green)\"\nerror_symbol = \"[ ](bold red)\"\nvicmd_symbol = \"[ ](bold green)\"\n\n"
                ;;
            "Cyberpunk")
                starship_config_content+="success_symbol = \"[⚡](bold bright-green)\"\nerror_symbol = \"[💥](bold bright-red)\"\nvicmd_symbol = \"[⚡](bold bright-green)\"\n\n"
                ;;
            "Gaming")
                starship_config_content+="success_symbol = \"[🎮](bold bright-green)\"\nerror_symbol = \"[💀](bold bright-red)\"\nvicmd_symbol = \"[🎮](bold bright-green)\"\n\n"
                ;;
            "Custom")
                starship_config_content+="success_symbol = \"[➜](bold $STARSHIP_CUSTOM_SUCCESS_COLOR)\"\nerror_symbol = \"[✗](bold $STARSHIP_CUSTOM_ERROR_COLOR)\"\nvicmd_symbol = \"[V](bold $STARSHIP_CUSTOM_SUCCESS_COLOR)\"\n\n"
                ;;
            *)
                starship_config_content+="success_symbol = \"[➜](bold green)\"\nerror_symbol = \"[✗](bold red)\"\nvicmd_symbol = \"[V](bold green)\"\n\n"
                ;;
        esac
        
        # Símbolos de lenguajes adicionales
        case "$STARSHIP_THEME" in
            "Nerd")
                starship_config_content+="[golang]\nsymbol = \" \"\n[rust]\nsymbol = \" \"\n[conda]\nsymbol = \" \"\n\n"
                ;;
            "Cyberpunk")
                starship_config_content+="[golang]\nsymbol = \"⚡ \"\n[rust]\nsymbol = \"⚡ \"\n[conda]\nsymbol = \"⚡ \"\n\n"
                ;;
            "Gaming")
                starship_config_content+="[golang]\nsymbol = \"🎮 \"\n[rust]\nsymbol = \"🎮 \"\n[conda]\nsymbol = \"🎮 \"\n\n"
                ;;
            *)
                starship_config_content+="[golang]\nsymbol = \"🐹 \"\n[rust]\nsymbol = \"🦀 \"\n[conda]\nsymbol = \"🗂️  \"\n\n"
                ;;
        esac
    fi
    
    # Configuración de duración de comandos
    if [[ "$STARSHIP_CMD_DURATION" = true ]]; then
        starship_config_content+="[cmd_duration]\nmin_time = 500\nformat = \"took [$duration]($style) \"\nstyle = \"yellow bold\"\n\n"
    fi
    
    # Configuración de usuario
    if [[ "$STARSHIP_USER_SMART" = true ]]; then
        starship_config_content+="[username]\ndisabled = false\nshow_always = false\n\n"
    fi
    
    # Configuración de hostname
    if [[ "$STARSHIP_HOST_SMART" = true ]]; then
        starship_config_content+="[hostname]\ndisabled = false\nssh_only = true\n\n"
    fi
    
    # Configuración de batería
    if [[ "$STARSHIP_BATTERY" = true ]]; then
        starship_config_content+="[battery]\ndisabled = false\nfull_symbol = \"🔋\"\ndischarging_symbol = \"🔌\"\ncharging_symbol = \"⚡\"\n\n"
    fi
    
    # Configuración de jobs
    if [[ "$STARSHIP_JOBS" = true ]]; then
        starship_config_content+="[jobs]\nsymbol = \"✦\"\nthreshold = 1\nstyle = \"bold blue\"\n\n"
    fi
    
    # Configuración de tiempo
    if [[ "$STARSHIP_TIME" = true ]]; then
        starship_config_content+="[time]\ndisabled = false\nformat = \"[$time]($style) \"\nstyle = \"bold yellow\"\n\n"
    fi
    
    # Configuración de paquetes
    if [[ "$STARSHIP_PKG_VERSION" = true ]]; then
        starship_config_content+="[package]\ndisabled = false\nformat = \"[$version](208 bold) \"\n\n"
    fi
    
    # Configuración de shell
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
  report             Genera un reporte detallado del estado de la migración.
  diagnose           Realiza un diagnóstico del entorno.
  security-check     Realiza un chequeo de seguridad del entorno.
  
  # Gestión de Configuraciones
  save-profile <nombre>     Guarda la configuración actual como un perfil.
  load-profile <nombre>     Carga una configuración desde un perfil.
  list-profiles             Lista todos los perfiles disponibles.
  export-profile <nombre>   Exporta un perfil a un archivo.
  import-profile <archivo>  Importa una configuración desde un archivo.
  sync-git <url>           Sincroniza configuraciones con un repositorio Git.
  
  help, -h, --help   Muestra esta ayuda.

Opciones:
  --dry-run          Muestra lo que haría el script sin ejecutar cambios reales.
  --verbose          Activa el logging detallado para depuración.
  --skip-tools       Migra solo el prompt (Starship) y los plugins, sin instalar herramientas modernas.

Características Avanzadas:
  - 9 temas predefinidos (Pastel Powerline, Cyberpunk, Gaming, etc.)
  - Selección interactiva de plugins y herramientas
  - Herramientas modernas: zoxide, atuin, navi, tldr, procs, etc.
  - Plugins avanzados: nvm, pyenv, autopair, sudo, etc.
  - Gestión de perfiles y sincronización Git
  - Validación automática post-migración
  - Backup automático con rollback

Ejemplos:
  ./migrate.sh                    # Migración completa interactiva
  ./migrate.sh --dry-run          # Simular migración sin cambios
  ./migrate.sh save-profile work  # Guardar perfil de trabajo
  ./migrate.sh load-profile dev   # Cargar perfil de desarrollo
  ./migrate.sh list-profiles      # Ver perfiles disponibles
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

# --- FUNCIONES DE GESTIÓN DE CONFIGURACIONES ---

# Guarda la configuración actual como un perfil
save_configuration_profile() {
    local profile_name="$1"
    if [[ -z "$profile_name" ]]; then
        log_error "Debe especificar un nombre para el perfil."
        return 1
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    local timestamp=$(date +'%Y%m%d_%H%M%S')
    
    log_info "Guardando perfil: $profile_name"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se crearía el perfil en: $profile_dir"
        return
    fi
    
    mkdir -p "$profile_dir"
    
    # Guardar configuración de Starship
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        cp "$HOME/.config/starship.toml" "$profile_dir/starship.toml"
    fi
    
    # Guardar .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$profile_dir/zshrc"
    fi
    
    # Guardar metadatos del perfil
    cat > "$profile_dir/metadata.json" <<EOF
{
    "name": "$profile_name",
    "created": "$timestamp",
    "description": "Perfil creado automáticamente",
    "version": "$SCRIPT_VERSION",
    "theme": "$STARSHIP_THEME",
    "plugins": {
        "autosuggestions": $INSTALL_AUTOSUGGESTIONS,
        "syntax_highlighting": $INSTALL_SYNTAX_HIGHLIGHTING,
        "completions": $INSTALL_COMPLETIONS,
        "history_substring": $INSTALL_HISTORY_SUBSTRING,
        "you_should_use": $INSTALL_YOU_SHOULD_USE
    }
}
EOF
    
    log_success "Perfil '$profile_name' guardado en: $profile_dir"
}

# Carga una configuración desde un perfil
load_configuration_profile() {
    local profile_name="$1"
    if [[ -z "$profile_name" ]]; then
        log_error "Debe especificar un nombre de perfil."
        return 1
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    
    if [[ ! -d "$profile_dir" ]]; then
        log_error "El perfil '$profile_name' no existe."
        return 1
    fi
    
    log_info "Cargando perfil: $profile_name"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se cargaría el perfil desde: $profile_dir"
        return
    fi
    
    # Crear backup antes de cargar
    create_backup
    
    # Cargar configuración de Starship
    if [[ -f "$profile_dir/starship.toml" ]]; then
        cp "$profile_dir/starship.toml" "$HOME/.config/starship.toml"
        log_verbose "Configuración de Starship cargada."
    fi
    
    # Cargar .zshrc
    if [[ -f "$profile_dir/zshrc" ]]; then
        cp "$profile_dir/zshrc" "$HOME/.zshrc"
        log_verbose "Configuración de Zsh cargada."
    fi
    
    log_success "Perfil '$profile_name' cargado exitosamente."
    log_info "Reinicia tu terminal o ejecuta 'source ~/.zshrc' para aplicar los cambios."
}

# Lista todos los perfiles disponibles
list_configuration_profiles() {
    local profiles_dir="$HOME/.config/starship_profiles"
    
    if [[ ! -d "$profiles_dir" ]]; then
        log_info "No hay perfiles guardados."
        return
    fi
    
    log_info "Perfiles disponibles:"
    for profile_dir in "$profiles_dir"/*; do
        if [[ -d "$profile_dir" ]]; then
            local profile_name=$(basename "$profile_dir")
            local metadata_file="$profile_dir/metadata.json"
            
            if [[ -f "$metadata_file" ]]; then
                local description=$(grep -o '"description": "[^"]*"' "$metadata_file" | cut -d'"' -f4)
                local created=$(grep -o '"created": "[^"]*"' "$metadata_file" | cut -d'"' -f4)
                echo -e "  ${C_GREEN}$profile_name${C_NC} - $description (Creado: $created)"
            else
                echo -e "  ${C_GREEN}$profile_name${C_NC} - Sin metadatos"
            fi
        fi
    done
}

# Exporta una configuración a un archivo
export_configuration() {
    local profile_name="$1"
    local export_path="$2"
    
    if [[ -z "$profile_name" ]]; then
        log_error "Debe especificar un nombre de perfil."
        return 1
    fi
    
    if [[ -z "$export_path" ]]; then
        export_path="$HOME/Desktop/starship_config_${profile_name}_$(date +'%Y%m%d_%H%M%S').tar.gz"
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    
    if [[ ! -d "$profile_dir" ]]; then
        log_error "El perfil '$profile_name' no existe."
        return 1
    fi
    
    log_info "Exportando perfil '$profile_name' a: $export_path"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se exportaría el perfil a: $export_path"
        return
    fi
    
    tar -czf "$export_path" -C "$profile_dir" .
    
    if [[ $? -eq 0 ]]; then
        log_success "Perfil exportado exitosamente a: $export_path"
    else
        log_error "Error al exportar el perfil."
        return 1
    fi
}

# Importa una configuración desde un archivo
import_configuration() {
    local import_path="$1"
    local profile_name="$2"
    
    if [[ -z "$import_path" ]]; then
        log_error "Debe especificar la ruta del archivo a importar."
        return 1
    fi
    
    if [[ -z "$profile_name" ]]; then
        profile_name="imported_$(date +'%Y%m%d_%H%M%S')"
    fi
    
    if [[ ! -f "$import_path" ]]; then
        log_error "El archivo '$import_path' no existe."
        return 1
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    
    log_info "Importando configuración como perfil: $profile_name"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se importaría el archivo a: $profile_dir"
        return
    fi
    
    mkdir -p "$profile_dir"
    tar -xzf "$import_path" -C "$profile_dir"
    
    if [[ $? -eq 0 ]]; then
        log_success "Configuración importada exitosamente como perfil: $profile_name"
    else
        log_error "Error al importar la configuración."
        return 1
    fi
}

# Sincroniza configuraciones con un repositorio Git
sync_configuration_with_git() {
    local repo_url="$1"
    local sync_dir="$HOME/.config/starship_sync"
    
    if [[ -z "$repo_url" ]]; then
        log_error "Debe especificar la URL del repositorio Git."
        return 1
    fi
    
    log_info "Sincronizando configuraciones con Git: $repo_url"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se sincronizaría con: $repo_url"
        return
    fi
    
    # Clonar o actualizar repositorio
    if [[ -d "$sync_dir" ]]; then
        cd "$sync_dir"
        git pull origin main >/dev/null 2>&1 || git pull origin master >/dev/null 2>&1
    else
        git clone "$repo_url" "$sync_dir" >/dev/null 2>&1
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "Configuraciones sincronizadas con Git exitosamente."
    else
        log_error "Error al sincronizar con Git."
        return 1
    fi
}

# --- GAMIFICACIÓN: LOGROS Y NIVELES ---
GAMIFICATION_FILE="$HOME/.config/starship_gamification.json"

init_gamification() {
    mkdir -p "$(dirname "$GAMIFICATION_FILE")"
    if [[ ! -f "$GAMIFICATION_FILE" ]]; then
        echo '{"level":1,"xp":0,"achievements":[]}' > "$GAMIFICATION_FILE"
    fi
}

get_gamification_value() {
    local key="$1"
    grep -o '"'"$key"'": *[0-9]*' "$GAMIFICATION_FILE" | grep -o '[0-9]*'
}

add_gamification_xp() {
    local add_xp="$1"
    local xp=$(get_gamification_value "xp")
    local level=$(get_gamification_value "level")
    local new_xp=$((xp+add_xp))
    local new_level=$level
    local level_up=false
    # Cada 100 XP sube de nivel
    while [[ $new_xp -ge 100 ]]; do
        new_xp=$((new_xp-100))
        new_level=$((new_level+1))
        level_up=true
    done
    # Actualiza archivo
    $SED_CMD -e "s/\"xp\": *[0-9]*/\"xp\": $new_xp/" "$GAMIFICATION_FILE"
    $SED_CMD -e "s/\"level\": *[0-9]*/\"level\": $new_level/" "$GAMIFICATION_FILE"
    if [[ $level_up == true ]]; then
        log_success "🎉 ¡Subiste al nivel $new_level! Sigue personalizando tu terminal."
    fi
}

unlock_achievement() {
    local achievement="$1"
    if ! grep -q '"'"$achievement"'"' "$GAMIFICATION_FILE"; then
        # Añadir logro
        $SED_CMD -e "s/\"achievements\": *\[/\"achievements\": [\"$achievement\",/" "$GAMIFICATION_FILE"
        log_success "🏅 ¡Logro desbloqueado: $achievement!"
    fi
}

show_gamification_status() {
    log_info "--- Gamificación ---"
    local level=$(get_gamification_value "level")
    local xp=$(get_gamification_value "xp")
    log_info "Nivel: $level | XP: $xp/100"
    log_info "Logros: $(grep -o '"achievements": *\[[^]]*\]' "$GAMIFICATION_FILE" | sed 's/.*\[//;s/\].*//;s/\"//g')"
}

# --- DIAGNÓSTICO RÁPIDO ---
diagnose_environment() {
    log_info "--- Diagnóstico rápido del entorno ---"
    local issues=0
    # Herramientas modernas
    for tool in starship eza bat fd fzf ripgrep; do
        if ! command -v $tool >/dev/null 2>&1; then
            log_warn "Falta la herramienta: $tool"
            issues=$((issues+1))
        fi
    done
    # Plugins
    [[ -d "$HOME/.zsh/plugins/zsh-autosuggestions" ]] || { log_warn "Plugin zsh-autosuggestions no instalado en ~/.zsh/plugins"; issues=$((issues+1)); }
    [[ -d "$HOME/.zsh/plugins/zsh-syntax-highlighting" ]] || { log_warn "Plugin zsh-syntax-highlighting no instalado en ~/.zsh/plugins"; issues=$((issues+1)); }
    # Archivos clave
    [[ -f "$HOME/.zshrc" ]] || { log_warn "Falta el archivo ~/.zshrc"; issues=$((issues+1)); }
    [[ -f "$HOME/.config/starship.toml" ]] || { log_warn "Falta el archivo ~/.config/starship.toml"; issues=$((issues+1)); }
    # Permisos
    [[ -w "$HOME/.zshrc" ]] || log_warn "No tienes permisos de escritura en ~/.zshrc"
    [[ -w "$HOME/.config/starship.toml" ]] || log_warn "No tienes permisos de escritura en ~/.config/starship.toml"
    # Sugerencias
    if [[ $issues -eq 0 ]]; then
        log_success "¡Todo está en orden!"
    else
        log_warn "Se detectaron $issues problema(s). Revisa las advertencias arriba."
    fi
}

# --- SEGURIDAD: CHEQUEOS DE INTEGRIDAD ---
security_check() {
    log_info "--- Chequeo de Seguridad ---"
    local security_issues=0
    
    # Verificar permisos de archivos de configuración
    if [[ -f "$HOME/.zshrc" ]]; then
        local perms=$($STAT_CMD "%Lp" "$HOME/.zshrc")
        if [[ "$perms" != "644" && "$perms" != "600" ]]; then
            log_warn "Permisos inseguros en ~/.zshrc: $perms (debería ser 644 o 600)"
            security_issues=$((security_issues+1))
        fi
    fi
    
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        local perms=$($STAT_CMD "%Lp" "$HOME/.config/starship.toml")
        if [[ "$perms" != "644" && "$perms" != "600" ]]; then
            log_warn "Permisos inseguros en ~/.config/starship.toml: $perms (debería ser 644 o 600)"
            security_issues=$((security_issues+1))
        fi
    fi
    
    # Verificar contenido sospechoso en .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        if grep -q "curl.*|.*bash\|wget.*|.*bash\|eval.*curl\|eval.*wget" "$HOME/.zshrc"; then
            log_warn "Contenido sospechoso detectado en ~/.zshrc (eval con curl/wget)"
            security_issues=$((security_issues+1))
        fi
        
        if grep -q "base64.*|.*bash\|base64.*|.*sh" "$HOME/.zshrc"; then
            log_warn "Contenido sospechoso detectado en ~/.zshrc (base64 decode)"
            security_issues=$((security_issues+1))
        fi
    fi
    
    # Verificar archivos de configuración de gamificación
    if [[ -f "$GAMIFICATION_FILE" ]]; then
        local perms=$($STAT_CMD "%Lp" "$GAMIFICATION_FILE")
        if [[ "$perms" != "644" && "$perms" != "600" ]]; then
            log_warn "Permisos inseguros en archivo de gamificación: $perms"
            security_issues=$((security_issues+1))
        fi
    fi
    
    # Verificar directorio de perfiles
    local profiles_dir="$HOME/.config/starship_profiles"
    if [[ -d "$profiles_dir" ]]; then
        local perms=$($STAT_CMD "%Lp" "$profiles_dir")
        if [[ "$perms" != "755" && "$perms" != "700" ]]; then
            log_warn "Permisos inseguros en directorio de perfiles: $perms"
            security_issues=$((security_issues+1))
        fi
    fi
    
    # Verificar integridad de archivos JSON
    if [[ -f "$GAMIFICATION_FILE" ]]; then
        if ! python3 -m json.tool "$GAMIFICATION_FILE" >/dev/null 2>&1; then
            log_warn "Archivo de gamificación corrupto o malformado"
            security_issues=$((security_issues+1))
        fi
    fi
    
    # Verificar archivos de backup
    if [[ -d "$BACKUP_BASE_DIR" ]]; then
        local backup_count=$(find "$BACKUP_BASE_DIR" -type f -name "*.zshrc" | wc -l)
        if [[ $backup_count -gt 10 ]]; then
            log_warn "Muchos archivos de backup ($backup_count). Considera limpiar backups antiguos."
        fi
    fi
    
    # Resumen de seguridad
    if [[ $security_issues -eq 0 ]]; then
        log_success "✅ No se detectaron problemas de seguridad."
    else
        log_warn "⚠️  Se detectaron $security_issues problema(s) de seguridad."
        log_info "Recomendación: Revisa los permisos y contenido de los archivos mencionados."
    fi
}

# --- FUNCIONES DE GESTIÓN DE CONFIGURACIONES ---

# Guarda la configuración actual como un perfil
save_configuration_profile() {
    local profile_name="$1"
    if [[ -z "$profile_name" ]]; then
        log_error "Debe especificar un nombre para el perfil."
        return 1
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    local timestamp=$(date +'%Y%m%d_%H%M%S')
    
    log_info "Guardando perfil: $profile_name"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se crearía el perfil en: $profile_dir"
        return
    fi
    
    mkdir -p "$profile_dir"
    
    # Guardar configuración de Starship
    if [[ -f "$HOME/.config/starship.toml" ]]; then
        cp "$HOME/.config/starship.toml" "$profile_dir/starship.toml"
    fi
    
    # Guardar .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$profile_dir/zshrc"
    fi
    
    # Guardar metadatos del perfil
    cat > "$profile_dir/metadata.json" <<EOF
{
    "name": "$profile_name",
    "created": "$timestamp",
    "description": "Perfil creado automáticamente",
    "version": "$SCRIPT_VERSION",
    "theme": "$STARSHIP_THEME",
    "plugins": {
        "autosuggestions": $INSTALL_AUTOSUGGESTIONS,
        "syntax_highlighting": $INSTALL_SYNTAX_HIGHLIGHTING,
        "completions": $INSTALL_COMPLETIONS,
        "history_substring": $INSTALL_HISTORY_SUBSTRING,
        "you_should_use": $INSTALL_YOU_SHOULD_USE
    }
}
EOF
    
    log_success "Perfil '$profile_name' guardado en: $profile_dir"
}

# Carga una configuración desde un perfil
load_configuration_profile() {
    local profile_name="$1"
    if [[ -z "$profile_name" ]]; then
        log_error "Debe especificar un nombre de perfil."
        return 1
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    
    if [[ ! -d "$profile_dir" ]]; then
        log_error "El perfil '$profile_name' no existe."
        return 1
    fi
    
    log_info "Cargando perfil: $profile_name"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se cargaría el perfil desde: $profile_dir"
        return
    fi
    
    # Crear backup antes de cargar
    create_backup
    
    # Cargar configuración de Starship
    if [[ -f "$profile_dir/starship.toml" ]]; then
        cp "$profile_dir/starship.toml" "$HOME/.config/starship.toml"
        log_verbose "Configuración de Starship cargada."
    fi
    
    # Cargar .zshrc
    if [[ -f "$profile_dir/zshrc" ]]; then
        cp "$profile_dir/zshrc" "$HOME/.zshrc"
        log_verbose "Configuración de Zsh cargada."
    fi
    
    log_success "Perfil '$profile_name' cargado exitosamente."
    log_info "Reinicia tu terminal o ejecuta 'source ~/.zshrc' para aplicar los cambios."
}

# Lista todos los perfiles disponibles
list_configuration_profiles() {
    local profiles_dir="$HOME/.config/starship_profiles"
    
    if [[ ! -d "$profiles_dir" ]]; then
        log_info "No hay perfiles guardados."
        return
    fi
    
    log_info "Perfiles disponibles:"
    for profile_dir in "$profiles_dir"/*; do
        if [[ -d "$profile_dir" ]]; then
            local profile_name=$(basename "$profile_dir")
            local metadata_file="$profile_dir/metadata.json"
            
            if [[ -f "$metadata_file" ]]; then
                local description=$(grep -o '"description": "[^"]*"' "$metadata_file" | cut -d'"' -f4)
                local created=$(grep -o '"created": "[^"]*"' "$metadata_file" | cut -d'"' -f4)
                echo -e "  ${C_GREEN}$profile_name${C_NC} - $description (Creado: $created)"
            else
                echo -e "  ${C_GREEN}$profile_name${C_NC} - Sin metadatos"
            fi
        fi
    done
}

# Exporta una configuración a un archivo
export_configuration() {
    local profile_name="$1"
    local export_path="$2"
    
    if [[ -z "$profile_name" ]]; then
        log_error "Debe especificar un nombre de perfil."
        return 1
    fi
    
    if [[ -z "$export_path" ]]; then
        export_path="$HOME/Desktop/starship_config_${profile_name}_$(date +'%Y%m%d_%H%M%S').tar.gz"
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    
    if [[ ! -d "$profile_dir" ]]; then
        log_error "El perfil '$profile_name' no existe."
        return 1
    fi
    
    log_info "Exportando perfil '$profile_name' a: $export_path"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se exportaría el perfil a: $export_path"
        return
    fi
    
    tar -czf "$export_path" -C "$profile_dir" .
    
    if [[ $? -eq 0 ]]; then
        log_success "Perfil exportado exitosamente a: $export_path"
    else
        log_error "Error al exportar el perfil."
        return 1
    fi
}

# Importa una configuración desde un archivo
import_configuration() {
    local import_path="$1"
    local profile_name="$2"
    
    if [[ -z "$import_path" ]]; then
        log_error "Debe especificar la ruta del archivo a importar."
        return 1
    fi
    
    if [[ -z "$profile_name" ]]; then
        profile_name="imported_$(date +'%Y%m%d_%H%M%S')"
    fi
    
    if [[ ! -f "$import_path" ]]; then
        log_error "El archivo '$import_path' no existe."
        return 1
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    
    log_info "Importando configuración como perfil: $profile_name"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se importaría el archivo a: $profile_dir"
        return
    fi
    
    mkdir -p "$profile_dir"
    tar -xzf "$import_path" -C "$profile_dir"
    
    if [[ $? -eq 0 ]]; then
        log_success "Configuración importada exitosamente como perfil: $profile_name"
    else
        log_error "Error al importar la configuración."
        return 1
    fi
}

# Sincroniza configuraciones con un repositorio Git
sync_configuration_with_git() {
    local repo_url="$1"
    local sync_dir="$HOME/.config/starship_sync"
    
    if [[ -z "$repo_url" ]]; then
        log_error "Debe especificar la URL del repositorio Git."
        return 1
    fi
    
    log_info "Sincronizando configuraciones con Git: $repo_url"
    
    if [[ "$DRY_RUN" = true ]]; then
        log_warn "[DRY-RUN] Se sincronizaría con: $repo_url"
        return
    fi
    
    # Clonar o actualizar repositorio
    if [[ -d "$sync_dir" ]]; then
        cd "$sync_dir"
        git pull origin main >/dev/null 2>&1 || git pull origin master >/dev/null 2>&1
    else
        git clone "$repo_url" "$sync_dir" >/dev/null 2>&1
    fi
    
    if [[ $? -eq 0 ]]; then
        log_success "Configuraciones sincronizadas con Git exitosamente."
    else
        log_error "Error al sincronizar con Git."
        return 1
    fi
}

# --- FUNCIÓN PRINCIPAL (MAIN) ---
# El punto de entrada del script. Parsea los argumentos y llama a la
# función correspondiente. Es el "director de orquesta".
main() {
    init_gamification
    detect_platform
    # Parseo de argumentos. Un bucle `while` con `case` es el patrón más
    # robusto y extensible en shell para manejar argumentos.
    local command=""
    local command_args=()
    
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
            rollback|status|report|diagnose|save-profile|load-profile|list-profiles|export-profile|import-profile|sync-git|security-check)
                if [[ -n "$command" ]]; then
                    log_error "Solo se puede especificar un comando a la vez."
                    exit 1
                fi
                command=$1
                shift
                # Collect all remaining arguments for this command
                while [[ $# -gt 0 && "$1" != -* ]]; do
                    command_args+=("$1")
                    shift
                done
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

    # Ejecutar el comando principal
    case $command in
        rollback)
            rollback_migration
            add_gamification_xp 10
            unlock_achievement "Rollback realizado"
            ;;
        status)
            show_status
            show_gamification_status
            add_gamification_xp 2
            ;;
        report)
            generate_report
            diagnose_environment
            security_check
            add_gamification_xp 2
            ;;
        diagnose)
            diagnose_environment
            add_gamification_xp 3
            unlock_achievement "Diagnóstico ejecutado"
            ;;
        save-profile)
            log_verbose "Command: $command"
            log_verbose "Command args count: ${#command_args[@]}"
            log_verbose "Command args: ${command_args[*]}"
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar un nombre para el perfil."
                show_help
                exit 1
            fi
            save_configuration_profile "${command_args[1]}"
            add_gamification_xp 5
            unlock_achievement "Perfil guardado"
            ;;
        load-profile)
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar un nombre de perfil."
                show_help
                exit 1
            fi
            load_configuration_profile "${command_args[1]}"
            add_gamification_xp 5
            unlock_achievement "Perfil cargado"
            ;;
        list-profiles)
            list_configuration_profiles
            add_gamification_xp 1
            ;;
        export-profile)
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar un nombre de perfil."
                show_help
                exit 1
            fi
            export_configuration "${command_args[1]}" "${command_args[2]:-}"
            add_gamification_xp 5
            unlock_achievement "Perfil exportado"
            ;;
        import-profile)
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar la ruta del archivo a importar."
                show_help
                exit 1
            fi
            import_configuration "${command_args[1]}" "${command_args[2]:-}"
            add_gamification_xp 5
            unlock_achievement "Perfil importado"
            ;;
        sync-git)
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar la URL del repositorio Git."
                show_help
                exit 1
            fi
            sync_configuration_with_git "${command_args[1]}"
            add_gamification_xp 10
            unlock_achievement "Sync Git"
            ;;
        security-check)
            security_check
            add_gamification_xp 5
            unlock_achievement "Seguridad verificada"
            ;;
        "") # Comando por defecto: migración
            # Paso 1: Selección de plugins de Zsh
            select_zsh_plugins
            # Paso 2: Selección de features/configuraciones de Starship
            select_starship_features
            
            log_info "🚀 Iniciando migración de Oh My Zsh a Starship..."
            local MIGRATION_OK=true
            local BACKUP_OK=false
            local ANALYZE_OK=false
            local INSTALL_OK=false
            local CONFIG_OK=false
            local VALIDATION_OK=false
            
            validate_system || MIGRATION_OK=false
            validate_platform || MIGRATION_OK=false
            install_platform_dependencies || log_warn "Algunas dependencias de plataforma no se pudieron instalar"
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
                add_gamification_xp 20
                unlock_achievement "Migración completada"
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

# --- DETECCIÓN MULTIPLATAFORMA ---
detect_platform() {
    log_verbose "Detectando plataforma..."
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
        PACKAGE_MANAGER="brew"
        STAT_CMD="stat -f"
        SED_CMD="sed -i ''"
        log_verbose "Plataforma detectada: macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        PLATFORM="linux"
        if command -v apt >/dev/null 2>&1; then
            PACKAGE_MANAGER="apt"
        elif command -v dnf >/dev/null 2>&1; then
            PACKAGE_MANAGER="dnf"
        elif command -v pacman >/dev/null 2>&1; then
            PACKAGE_MANAGER="pacman"
        else
            PACKAGE_MANAGER="unknown"
        fi
        STAT_CMD="stat -c"
        SED_CMD="sed -i"
        log_verbose "Plataforma detectada: Linux ($PACKAGE_MANAGER)"
    elif [[ "$OSTYPE" == "msys"* ]] || [[ "$OSTYPE" == "cygwin"* ]]; then
        PLATFORM="windows"
        PACKAGE_MANAGER="choco"
        STAT_CMD="stat -c"
        SED_CMD="sed -i"
        log_verbose "Plataforma detectada: Windows (WSL/Cygwin)"
    else
        PLATFORM="unknown"
        PACKAGE_MANAGER="unknown"
        STAT_CMD="stat -f"
        SED_CMD="sed -i"
        log_warn "Plataforma no reconocida: $OSTYPE"
    fi
    
    export PLATFORM PACKAGE_MANAGER STAT_CMD SED_CMD
}

# --- VALIDACIÓN MULTIPLATAFORMA ---
validate_platform() {
    log_info "Validando plataforma..."
    
    case "$PLATFORM" in
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                log_error "Homebrew no está instalado. Instálalo desde https://brew.sh/"
                return 1
            fi
            ;;
        "linux")
            case "$PACKAGE_MANAGER" in
                "apt")
                    if ! command -v apt >/dev/null 2>&1; then
                        log_error "apt no está disponible."
                        return 1
                    fi
                    ;;
                "dnf")
                    if ! command -v dnf >/dev/null 2>&1; then
                        log_error "dnf no está disponible."
                        return 1
                    fi
                    ;;
                "pacman")
                    if ! command -v pacman >/dev/null 2>&1; then
                        log_error "pacman no está disponible."
                        return 1
                    fi
                    ;;
                *)
                    log_warn "Gestor de paquetes no reconocido. Algunas funciones pueden no funcionar."
                    ;;
            esac
            ;;
        "windows")
            if ! command -v choco >/dev/null 2>&1; then
                log_warn "Chocolatey no está instalado. Algunas funciones pueden no funcionar."
            fi
            ;;
        *)
            log_warn "Plataforma no soportada. Algunas funciones pueden no funcionar."
            ;;
    esac
    
    log_success "Plataforma validada: $PLATFORM ($PACKAGE_MANAGER)"
}

# --- INSTALACIÓN MULTIPLATAFORMA ---
install_platform_dependencies() {
    log_info "Instalando dependencias específicas de la plataforma..."
    
    case "$PLATFORM" in
        "macos")
            # macOS ya tiene las dependencias instaladas via Homebrew
            log_verbose "macOS: Dependencias instaladas via Homebrew"
            ;;
        "linux")
            case "$PACKAGE_MANAGER" in
                "apt")
                    log_verbose "Instalando dependencias via apt..."
                    sudo apt update
                    sudo apt install -y curl git zsh python3 python3-pip
                    ;;
                "dnf")
                    log_verbose "Instalando dependencias via dnf..."
                    sudo dnf install -y curl git zsh python3 python3-pip
                    ;;
                "pacman")
                    log_verbose "Instalando dependencias via pacman..."
                    sudo pacman -S --noconfirm curl git zsh python python-pip
                    ;;
            esac
            ;;
        "windows")
            log_verbose "Windows: Instalando dependencias via Chocolatey..."
            choco install -y curl git python
            ;;
    esac
}

# --- INTEGRAR EN MAIN ---
# (Busca el bloque del main y agrega la detección de plataforma al inicio)

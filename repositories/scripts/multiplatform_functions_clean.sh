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

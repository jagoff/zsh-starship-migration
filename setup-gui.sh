#!/bin/bash
# ===============================================================================
# setup-gui.sh - Configuración Rápida de GUI Estándar para Proyectos
# ===============================================================================
#
# Este script configura una interfaz de usuario interactiva estándar
# para cualquier proyecto, basada en Gum y siguiendo las mejores prácticas
# de diseño de CLI.
#
# Uso:
#   chmod +x setup-gui.sh
#   ./setup-gui.sh
#
# ===============================================================================

# --- VARIABLES DE COLOR ESTÁNDAR ---
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

# --- FUNCIONES DE LOGGING ---
show_success() {
    echo -e "${C_GREEN}✅ $1${C_NC}"
}

show_error() {
    echo -e "${C_RED}❌ $1${C_NC}" >&2
}

show_warning() {
    echo -e "${C_YELLOW}⚠️  $1${C_NC}"
}

show_info() {
    echo -e "${C_BLUE}ℹ️  $1${C_NC}"
}

show_verbose() {
    if [[ "${VERBOSE:-false}" = true ]]; then
        echo -e "${C_GRAY}   [VERBOSE] $1${C_NC}"
    fi
}

# --- VERIFICACIÓN DE DEPENDENCIAS ---
check_dependencies() {
    show_info "Verificando dependencias..."
    
    local missing_deps=()
    
    # Verificar Gum
    if ! command -v gum >/dev/null; then
        missing_deps+=("gum")
    fi
    
    # Verificar Homebrew (para macOS)
    if [[ "$OSTYPE" == "darwin"* ]] && ! command -v brew >/dev/null; then
        missing_deps+=("homebrew")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        show_warning "Dependencias faltantes: ${missing_deps[*]}"
        
        if gum confirm \
            --affirmative="Sí, instalar" \
            --negative="No, cancelar" \
            "${GUM_THEME[@]}" \
            "¿Deseas instalar las dependencias faltantes?"; then
            
            install_dependencies "${missing_deps[@]}"
        else
            show_error "No se pueden instalar las dependencias. Abortando."
            exit 1
        fi
    else
        show_success "Todas las dependencias están instaladas"
    fi
}

# --- INSTALACIÓN DE DEPENDENCIAS ---
install_dependencies() {
    local deps=("$@")
    
    for dep in "${deps[@]}"; do
        case "$dep" in
            "gum")
                show_info "Instalando Gum..."
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    brew install gum
                elif command -v apt-get >/dev/null; then
                    sudo apt-get update && sudo apt-get install -y gum
                elif command -v yum >/dev/null; then
                    sudo yum install -y gum
                else
                    show_error "No se pudo instalar Gum automáticamente"
                    show_info "Instala Gum manualmente desde: https://github.com/charmbracelet/gum"
                    exit 1
                fi
                ;;
            "homebrew")
                show_info "Instalando Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                ;;
        esac
    done
    
    show_success "Dependencias instaladas correctamente"
}

# --- FUNCIONES DE MENÚ ESTÁNDAR ---
show_standard_menu() {
    local title="$1"
    local subtitle="$2"
    local header="$3"
    shift 3
    local options=("$@")
    
    echo -e "${C_BLUE}📋 $title${C_NC}"
    echo -e "${C_GRAY}$subtitle${C_NC}"
    
    gum choose \
        --header="$header" \
        "${GUM_THEME[@]}" \
        "${options[@]}"
}

show_multi_select() {
    local title="$1"
    local subtitle="$2"
    local header="$3"
    local limit="${4:-5}"
    shift 4
    local options=("$@")
    
    echo -e "${C_BLUE}📋 $title${C_NC}"
    echo -e "${C_GRAY}$subtitle${C_NC}"
    
    gum choose \
        --header="$header" \
        --limit="$limit" \
        "${GUM_THEME[@]}" \
        "${options[@]}"
}

show_confirmation() {
    local message="$1"
    local affirmative="${2:-Sí}"
    local negative="${3:-No}"
    
    gum confirm \
        --affirmative="$affirmative" \
        --negative="$negative" \
        "${GUM_THEME[@]}" \
        "$message"
}

show_input() {
    local prompt="$1"
    local placeholder="${2:-}"
    
    gum input \
        --prompt="$prompt" \
        --placeholder="$placeholder" \
        --prompt.foreground="#00ff00" \
        --placeholder.foreground="#666666" \
        --cursor.foreground="#ffff00"
}

show_spinner() {
    local title="$1"
    shift
    
    gum spin \
        --spinner="dots" \
        --title="$title" \
        --spinner.foreground="#00ff00" \
        --title.foreground="#ffffff" \
        -- "$@"
}

show_progress() {
    local title="$1"
    local percent="$2"
    
    gum progress \
        --percent="$percent" \
        --width=50 \
        --bar.foreground="#00ff00" \
        --percent.foreground="#ffffff" \
        --title="$title"
}

# --- FUNCIONES DE VALIDACIÓN ---
validate_input() {
    local input="$1"
    local pattern="$2"
    local error_message="${3:-Entrada inválida}"
    
    if [[ "$input" =~ $pattern ]]; then
        show_success "Entrada válida"
        return 0
    else
        show_error "$error_message"
        return 1
    fi
}

validate_email() {
    local email="$1"
    local pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    validate_input "$email" "$pattern" "Email inválido"
}

validate_url() {
    local url="$1"
    local pattern="^https?://[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
    validate_input "$url" "$pattern" "URL inválida"
}

# --- FUNCIONES DE CONFIGURACIÓN ---
create_gum_config() {
    local config_dir="$HOME/.config/gum"
    local config_file="$config_dir/config.yaml"
    
    show_info "Creando configuración de Gum..."
    
    mkdir -p "$config_dir"
    
    cat > "$config_file" << 'EOF'
theme:
  colors:
    selected:
      foreground: "#00ff00"
      background: "#000000"
    unselected:
      foreground: "#ffffff"
      background: "#333333"
    cursor:
      foreground: "#ffff00"
      background: "#666666"
    border:
      foreground: "#00ff00"
    title:
      foreground: "#ffffff"
    subtitle:
      foreground: "#666666"
    description:
      foreground: "#cccccc"
EOF
    
    show_success "Configuración de Gum creada en $config_file"
}

create_project_template() {
    local project_name="$1"
    local template_file="gui-template.sh"
    
    show_info "Creando template para el proyecto $project_name..."
    
    cat > "$template_file" << EOF
#!/bin/bash
# ===============================================================================
# $project_name - GUI Interactiva
# ===============================================================================

# --- VARIABLES DE COLOR ESTÁNDAR ---
readonly C_RED='\\033[0;31m'
readonly C_GREEN='\\033[0;32m'
readonly C_BLUE='\\033[0;34m'
readonly C_YELLOW='\\033[0;93m'
readonly C_CYAN='\\033[0;36m'
readonly C_MAGENTA='\\033[0;35m'
readonly C_WHITE='\\033[1;37m'
readonly C_GRAY='\\033[0;90m'
readonly C_NC='\\033[0m'

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

# --- FUNCIONES DE LOGGING ---
show_success() {
    echo -e "\\\${C_GREEN}✅ \\\$1\\\${C_NC}"
}

show_error() {
    echo -e "\\\${C_RED}❌ \\\$1\\\${C_NC}" >&2
}

show_warning() {
    echo -e "\\\${C_YELLOW}⚠️  \\\$1\\\${C_NC}"
}

show_info() {
    echo -e "\\\${C_BLUE}ℹ️  \\\$1\\\${C_NC}"
}

# --- FUNCIONES DE MENÚ ---
show_standard_menu() {
    local title="\\\$1"
    local subtitle="\\\$2"
    local header="\\\$3"
    shift 3
    local options=("\\\$@")
    
    echo -e "\\\${C_BLUE}📋 \\\$title\\\${C_NC}"
    echo -e "\\\${C_GRAY}\\\$subtitle\\\${C_NC}"
    
    gum choose \\
        --header="\\\$header" \\
        "\\\${GUM_THEME[@]}" \\
        "\\\${options[@]}"
}

show_confirmation() {
    local message="\\\$1"
    local affirmative="\\\${2:-Sí}"
    local negative="\\\${3:-No}"
    
    gum confirm \\
        --affirmative="\\\$affirmative" \\
        --negative="\\\$negative" \\
        "\\\${GUM_THEME[@]}" \\
        "\\\$message"
}

# --- FUNCIÓN PRINCIPAL ---
main() {
    show_info "Bienvenido a $project_name"
    
    local action=\$(show_standard_menu \\
        "Configuración del Proyecto" \\
        "Selecciona la acción que deseas realizar" \\
        "Elige una opción (enter para confirmar):" \\
        "Instalar dependencias" \\
        "Configurar entorno" \\
        "Ejecutar tests" \\
        "Deploy" \\
        "Salir")
    
    case "\\\$action" in
        "Instalar dependencias")
            show_success "Instalando dependencias..."
            ;;
        "Configurar entorno")
            show_info "Configurando entorno..."
            ;;
        "Ejecutar tests")
            show_warning "Ejecutando tests..."
            ;;
        "Deploy")
            show_error "Deploy no implementado"
            ;;
        "Salir")
            show_info "¡Hasta luego!"
            exit 0
            ;;
    esac
}

main "\\\$@"
EOF
    
    chmod +x "$template_file"
    show_success "Template creado: $template_file"
}

# --- FUNCIÓN PRINCIPAL ---
main() {
    echo -e "${C_BLUE}🎨 Configuración Rápida de GUI Estándar${C_NC}"
    echo -e "${C_GRAY}Configurando interfaz de usuario interactiva para proyectos${C_NC}"
    echo
    
    # Verificar dependencias
    check_dependencies
    
    # Menú principal
    local action=$(show_standard_menu \
        "Configuración de GUI" \
        "Selecciona la acción que deseas realizar" \
        "Elige una opción (enter para confirmar):" \
        "Crear configuración de Gum" \
        "Crear template de proyecto" \
        "Configurar variables de entorno" \
        "Mostrar ejemplos" \
        "Salir")
    
    case "$action" in
        "Crear configuración de Gum")
            create_gum_config
            ;;
        "Crear template de proyecto")
            local project_name=$(show_input "Nombre del proyecto:" "mi-proyecto")
            if [[ -n "$project_name" ]]; then
                create_project_template "$project_name"
            else
                show_error "Nombre de proyecto requerido"
            fi
            ;;
        "Configurar variables de entorno")
            show_info "Configurando variables de entorno..."
            local shell_config=""
            
            if [[ -f "$HOME/.zshrc" ]]; then
                shell_config="$HOME/.zshrc"
            elif [[ -f "$HOME/.bashrc" ]]; then
                shell_config="$HOME/.bashrc"
            fi
            
            if [[ -n "$shell_config" ]]; then
                cat >> "$shell_config" << 'EOF'

# --- Configuración de GUI Estándar ---
export GUM_CHOOSE_SELECTED_FOREGROUND="#00ff00"
export GUM_CHOOSE_SELECTED_BACKGROUND="#000000"
export GUM_CHOOSE_UNSELECTED_FOREGROUND="#ffffff"
export GUM_CHOOSE_UNSELECTED_BACKGROUND="#333333"
export GUM_CHOOSE_CURSOR_FOREGROUND="#ffff00"
export GUM_CHOOSE_CURSOR_BACKGROUND="#666666"
EOF
                show_success "Variables de entorno agregadas a $shell_config"
                show_info "Reinicia tu terminal o ejecuta 'source $shell_config'"
            else
                show_error "No se encontró archivo de configuración de shell"
            fi
            ;;
        "Mostrar ejemplos")
            show_info "Ejemplos de uso:"
            echo
            echo -e "${C_CYAN}1. Menú simple:${C_NC}"
            echo "   show_standard_menu \"Título\" \"Subtítulo\" \"Header\" \"Opción 1\" \"Opción 2\""
            echo
            echo -e "${C_CYAN}2. Confirmación:${C_NC}"
            echo "   if show_confirmation \"¿Continuar?\"; then echo \"Sí\"; fi"
            echo
            echo -e "${C_CYAN}3. Entrada de usuario:${C_NC}"
            echo "   name=\$(show_input \"Nombre:\" \"Tu nombre\")"
            echo
            echo -e "${C_CYAN}4. Spinner:${C_NC}"
            echo "   show_spinner \"Procesando...\" sleep 3"
            echo
            echo -e "${C_CYAN}5. Progreso:${C_NC}"
            echo "   show_progress \"Instalando...\" 75"
            ;;
        "Salir")
            show_info "¡Hasta luego!"
            exit 0
            ;;
    esac
    
    echo
    show_success "Configuración completada"
    show_info "Revisa la documentación en docs/GUI_SPECIFICATION.md para más detalles"
}

# --- EJECUCIÓN ---
main "$@" 
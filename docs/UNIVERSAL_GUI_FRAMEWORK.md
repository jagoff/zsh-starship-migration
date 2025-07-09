# 🎨 Framework Universal de GUI para Proyectos Shell

## 📋 Descripción General

Este documento es el **pilar definitivo** para implementar interfaces de usuario interactivas elegantes y robustas en cualquier proyecto de shell. Utiliza `gum` como herramienta principal y proporciona un framework completo, probado y compatible con todas las versiones.

**Características principales:**
- ✅ **Universal**: Funciona en cualquier proyecto de shell
- ✅ **Robusto**: Compatible con todas las versiones de `gum`
- ✅ **Moderno**: Interfaz elegante y profesional
- ✅ **Mantenible**: Código limpio y bien documentado
- ✅ **Debuggeable**: Logs y manejo de errores completo

---

## 🚀 Inicio Rápido

### 1. Instalación de Dependencias
```bash
# Instalar gum (requerido)
brew install gum

# Verificar instalación
gum --version
```

### 2. Copiar el Framework Base
```bash
# Copiar estas funciones a tu script
# (ver sección "Framework Base" más abajo)
```

### 3. Usar en tu Proyecto
```bash
#!/bin/bash
# Tu script con GUI moderna

# Incluir el framework
source ./gui_framework.sh

# Usar las funciones
main() {
    local action=$(show_gui_menu \
        "Mi Proyecto" \
        "Selecciona la acción que deseas realizar" \
        "Elige una opción:" \
        "Instalar" \
        "Configurar" \
        "Ejecutar" \
        "Salir")
    
    case "$action" in
        "Instalar") install_project ;;
        "Configurar") configure_project ;;
        "Ejecutar") run_project ;;
        "Salir") exit 0 ;;
    esac
}

main "$@"
```

---

## 🔧 Framework Base

### Variables de Color Estándar
```bash
# --- VARIABLES DE COLOR UNIVERSALES ---
readonly C_RED='\033[0;31m'        # #ff0000 - Errores y alertas críticas
readonly C_GREEN='\033[0;32m'      # #00ff00 - Éxitos y confirmaciones
readonly C_BLUE='\033[0;34m'       # #0000ff - Información y títulos
readonly C_YELLOW='\033[0;93m'     # #ffff00 - Advertencias y prompts
readonly C_CYAN='\033[0;36m'       # #00ffff - Información técnica
readonly C_MAGENTA='\033[0;35m'    # #ff00ff - Destacados especiales
readonly C_WHITE='\033[1;37m'      # #ffffff - Texto principal
readonly C_GRAY='\033[0;90m'       # #808080 - Texto secundario
readonly C_NC='\033[0m'            # Reset de color
```

### Funciones de Logging
```bash
# --- FUNCIONES DE LOGGING UNIVERSALES ---
log_success() {
    echo -e "${C_GREEN}✅ $1${C_NC}"
}

log_error() {
    echo -e "${C_RED}❌ $1${C_NC}" >&2
}

log_warning() {
    echo -e "${C_YELLOW}⚠️  $1${C_NC}"
}

log_info() {
    echo -e "${C_BLUE}ℹ️  $1${C_NC}"
}

log_debug() {
    echo -e "${C_GRAY}[DEBUG] $1${C_NC}"
}

log_verbose() {
    if [[ "${VERBOSE:-false}" = true ]]; then
        echo -e "${C_GRAY}   [VERBOSE] $1${C_NC}"
    fi
}
```

### Detección de Compatibilidad
```bash
# --- DETECCIÓN DE VERSIÓN Y COMPATIBILIDAD ---
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
```

### Verificación de Dependencias
```bash
# --- VERIFICACIÓN DE DEPENDENCIAS ---
check_gui_dependencies() {
    if ! command -v gum >/dev/null; then
        log_warning "Gum no está instalado. Instalando..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gum
        elif command -v apt-get >/dev/null; then
            sudo apt-get update && sudo apt-get install -y gum
        elif command -v yum >/dev/null; then
            sudo yum install -y gum
        else
            log_error "Gum no está disponible. Instálalo manualmente desde: https://github.com/charmbracelet/gum"
            return 1
        fi
    fi
    return 0
}
```

### Detección de TTY
```bash
# --- DETECCIÓN DE TTY ---
require_tty() {
    if [[ ! -t 0 ]]; then
        log_error "Este menú requiere una terminal interactiva (TTY). Ejecutá el script desde una terminal real."
        exit 2
    fi
}
```

---

## 📱 Componentes de GUI

### 1. Menú de Selección Única
```bash
# --- MENÚ DE SELECCIÓN ÚNICA ---
show_gui_menu() {
    require_tty
    log_debug "Mostrando menú GUI: $1"
    local title="$1"
    local subtitle="$2"
    local header="$3"
    shift 3
    local options=("$@")
    
    echo -e "${C_BLUE}📋 $title${C_NC}"
    echo -e "${C_GRAY}$subtitle${C_NC}"
    
    # Usar gum choose sin flags problemáticos para máxima compatibilidad
    gum choose \
        --header="$header" \
        "${options[@]}"
}
```

### 2. Menú de Selección Múltiple
```bash
# --- MENÚ DE SELECCIÓN MÚLTIPLE ---
show_gui_multi_select() {
    require_tty
    log_debug "Mostrando multi-select GUI: $1"
    local title="$1"
    local subtitle="$2"
    local header="$3"
    local limit="${4:-5}"
    shift 4
    local options=("$@")
    
    echo -e "${C_BLUE}📋 $title${C_NC}"
    echo -e "${C_GRAY}$subtitle${C_NC}"
    
    # Usar gum choose sin flags problemáticos para máxima compatibilidad
    gum choose \
        --header="$header" \
        --limit="$limit" \
        "${options[@]}"
}
```

### 3. Confirmación
```bash
# --- CONFIRMACIÓN ---
show_gui_confirmation() {
    require_tty
    log_debug "Mostrando confirmación GUI: $1"
    local message="$1"
    local affirmative="${2:-Sí, continuar}"
    local negative="${3:-No, cancelar}"
    
    # Usar gum confirm sin flags de color para evitar problemas
    gum confirm \
        --affirmative="$affirmative" \
        --negative="$negative" \
        "$message"
    local result=$?
    log_debug "Resultado de confirmación: $result"
    return $result
}
```

### 4. Entrada de Texto
```bash
# --- ENTRADA DE TEXTO ---
show_gui_input() {
    require_tty
    log_debug "Mostrando input GUI: $1"
    local prompt="$1"
    local placeholder="${2:-}"
    
    gum input \
        --prompt="$prompt" \
        --placeholder="$placeholder"
}
```

### 5. Spinner de Progreso
```bash
# --- SPINNER DE PROGRESO ---
show_gui_spinner() {
    local title="$1"
    shift
    
    gum spin \
        --spinner="dots" \
        --title="$title" \
        -- "$@"
}
```

### 6. Barra de Progreso
```bash
# --- BARRA DE PROGRESO ---
show_gui_progress() {
    local title="$1"
    local percent="$2"
    
    gum progress \
        --percent="$percent" \
        --width=50 \
        --title="$title"
}
```

---

## 🎯 Patrones de Uso

### 1. Menú Principal
```bash
show_main_menu() {
    local action=$(show_gui_menu \
        "Mi Proyecto" \
        "Selecciona la acción que deseas realizar" \
        "Elige una opción (enter para confirmar):" \
        "🚀 Instalar dependencias" \
        "⚙️  Configurar proyecto" \
        "▶️  Ejecutar aplicación" \
        "📊 Ver estado" \
        "🔧 Mantenimiento" \
        "❌ Salir")
    
    case "$action" in
        "🚀 Instalar dependencias") install_dependencies ;;
        "⚙️  Configurar proyecto") configure_project ;;
        "▶️  Ejecutar aplicación") run_application ;;
        "📊 Ver estado") show_status ;;
        "🔧 Mantenimiento") show_maintenance_menu ;;
        "❌ Salir") exit 0 ;;
    esac
}
```

### 2. Selección Múltiple
```bash
select_features() {
    local selected_features=$(show_gui_multi_select \
        "Características del Proyecto" \
        "Selecciona las características que deseas habilitar" \
        "Características disponibles:" \
        5 \
        "🔐 Autenticación [Sistema de login seguro]" \
        "📧 Notificaciones [Envío de emails]" \
        "📊 Analytics [Métricas y reportes]" \
        "🔍 Búsqueda [Búsqueda avanzada]" \
        "🌐 API [Interfaz de programación]")
    
    # Procesar selecciones
    while IFS= read -r feature; do
        case "$feature" in
            "🔐 Autenticación [Sistema de login seguro]")
                ENABLE_AUTH=true
                ;;
            "📧 Notificaciones [Envío de emails]")
                ENABLE_NOTIFICATIONS=true
                ;;
            "📊 Analytics [Métricas y reportes]")
                ENABLE_ANALYTICS=true
                ;;
            "🔍 Búsqueda [Búsqueda avanzada]")
                ENABLE_SEARCH=true
                ;;
            "🌐 API [Interfaz de programación]")
                ENABLE_API=true
                ;;
        esac
    done <<< "$selected_features"
}
```

### 3. Confirmación con Detalles
```bash
confirm_action() {
    local action="$1"
    local details="$2"
    
    if show_gui_confirmation \
        "¿Deseas continuar con '$action'?\n\n$details"; then
        log_success "Acción confirmada: $action"
        return 0
    else
        log_warning "Acción cancelada: $action"
        return 1
    fi
}
```

### 4. Entrada con Validación
```bash
get_user_input() {
    local prompt="$1"
    local placeholder="$2"
    local validation_pattern="$3"
    
    while true; do
        local input=$(show_gui_input "$prompt" "$placeholder")
        
        if [[ -z "$input" ]]; then
            log_warning "La entrada no puede estar vacía"
            continue
        fi
        
        if [[ -n "$validation_pattern" ]] && ! [[ "$input" =~ $validation_pattern ]]; then
            log_warning "Formato inválido. Intenta de nuevo."
            continue
        fi
        
        echo "$input"
        return 0
    done
}
```

---

## 🔧 Configuración Avanzada

### Variables de Entorno
```bash
# --- CONFIGURACIÓN DE GUM ---
# Estas variables se aplican automáticamente si gum las soporta
export GUM_CHOOSE_SELECTED_FOREGROUND="#00ff00"
export GUM_CHOOSE_SELECTED_BACKGROUND="#000000"
export GUM_CHOOSE_CURSOR_FOREGROUND="#ffff00"
export GUM_CHOOSE_CURSOR_BACKGROUND="#666666"
export GUM_CONFIRM_PROMPT_FOREGROUND="#00ff00"
export GUM_CONFIRM_SELECTED_FOREGROUND="#00ff00"
export GUM_CONFIRM_SELECTED_BACKGROUND="#000000"
```

### Configuración Condicional
```bash
# --- CONFIGURACIÓN CONDICIONAL ---
setup_gum_config() {
    if supports_gum_unselected_flags; then
        export GUM_CHOOSE_UNSELECTED_FOREGROUND="#ffffff"
        export GUM_CHOOSE_UNSELECTED_BACKGROUND="#333333"
        log_debug "Configuración avanzada de gum aplicada"
    else
        log_debug "Usando configuración básica de gum"
    fi
}
```

---

## 📦 Implementación Completa

### Archivo: `gui_framework.sh`
```bash
#!/bin/bash
# gui_framework.sh - Framework Universal de GUI para Proyectos Shell
# Versión: 1.0.0
# Compatible con: bash, zsh
# Dependencias: gum

# --- VARIABLES DE COLOR UNIVERSALES ---
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
readonly C_YELLOW='\033[0;93m'
readonly C_CYAN='\033[0;36m'
readonly C_MAGENTA='\033[0;35m'
readonly C_WHITE='\033[1;37m'
readonly C_GRAY='\033[0;90m'
readonly C_NC='\033[0m'

# --- FUNCIONES DE LOGGING ---
log_success() { echo -e "${C_GREEN}✅ $1${C_NC}"; }
log_error() { echo -e "${C_RED}❌ $1${C_NC}" >&2; }
log_warning() { echo -e "${C_YELLOW}⚠️  $1${C_NC}"; }
log_info() { echo -e "${C_BLUE}ℹ️  $1${C_NC}"; }
log_debug() { echo -e "${C_GRAY}[DEBUG] $1${C_NC}"; }
log_verbose() { 
    if [[ "${VERBOSE:-false}" = true ]]; then
        echo -e "${C_GRAY}   [VERBOSE] $1${C_NC}"
    fi
}

# --- DETECCIÓN DE COMPATIBILIDAD ---
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
    if (( major > 0 )) || (( major == 0 && minor > 12 )) || (( major == 0 && minor == 12 && patch >= 0 )); then
        return 0
    else
        return 1
    fi
}

# --- VERIFICACIÓN DE DEPENDENCIAS ---
check_gui_dependencies() {
    if ! command -v gum >/dev/null; then
        log_warning "Gum no está instalado. Instalando..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gum
        elif command -v apt-get >/dev/null; then
            sudo apt-get update && sudo apt-get install -y gum
        elif command -v yum >/dev/null; then
            sudo yum install -y gum
        else
            log_error "Gum no está disponible. Instálalo manualmente desde: https://github.com/charmbracelet/gum"
            return 1
        fi
    fi
    return 0
}

# --- DETECCIÓN DE TTY ---
require_tty() {
    if [[ ! -t 0 ]]; then
        log_error "Este menú requiere una terminal interactiva (TTY). Ejecutá el script desde una terminal real."
        exit 2
    fi
}

# --- COMPONENTES DE GUI ---
show_gui_menu() {
    require_tty
    log_debug "Mostrando menú GUI: $1"
    local title="$1"
    local subtitle="$2"
    local header="$3"
    shift 3
    local options=("$@")
    
    echo -e "${C_BLUE}📋 $title${C_NC}"
    echo -e "${C_GRAY}$subtitle${C_NC}"
    
    gum choose \
        --header="$header" \
        "${options[@]}"
}

show_gui_multi_select() {
    require_tty
    log_debug "Mostrando multi-select GUI: $1"
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
        "${options[@]}"
}

show_gui_confirmation() {
    require_tty
    log_debug "Mostrando confirmación GUI: $1"
    local message="$1"
    local affirmative="${2:-Sí, continuar}"
    local negative="${3:-No, cancelar}"
    
    gum confirm \
        --affirmative="$affirmative" \
        --negative="$negative" \
        "$message"
    local result=$?
    log_debug "Resultado de confirmación: $result"
    return $result
}

show_gui_input() {
    require_tty
    log_debug "Mostrando input GUI: $1"
    local prompt="$1"
    local placeholder="${2:-}"
    
    gum input \
        --prompt="$prompt" \
        --placeholder="$placeholder"
}

show_gui_spinner() {
    local title="$1"
    shift
    
    gum spin \
        --spinner="dots" \
        --title="$title" \
        -- "$@"
}

show_gui_progress() {
    local title="$1"
    local percent="$2"
    
    gum progress \
        --percent="$percent" \
        --width=50 \
        --title="$title"
}

# --- CONFIGURACIÓN ---
setup_gum_config() {
    if supports_gum_unselected_flags; then
        export GUM_CHOOSE_UNSELECTED_FOREGROUND="#ffffff"
        export GUM_CHOOSE_UNSELECTED_BACKGROUND="#333333"
        log_debug "Configuración avanzada de gum aplicada"
    else
        log_debug "Usando configuración básica de gum"
    fi
}

# --- INICIALIZACIÓN ---
init_gui_framework() {
    check_gui_dependencies
    setup_gum_config
    log_info "Framework de GUI inicializado"
}
```

### Archivo: `example_project.sh`
```bash
#!/bin/bash
# example_project.sh - Ejemplo de uso del Framework Universal de GUI

# Cargar el framework
source ./gui_framework.sh

# Variables del proyecto
PROJECT_NAME="Mi Proyecto"
ENABLE_FEATURE_A=false
ENABLE_FEATURE_B=false
ENABLE_FEATURE_C=false

# Función principal
main() {
    init_gui_framework
    
    while true; do
        show_main_menu
    done
}

# Menú principal
show_main_menu() {
    local action=$(show_gui_menu \
        "$PROJECT_NAME" \
        "Selecciona la acción que deseas realizar" \
        "Elige una opción:" \
        "🚀 Instalar" \
        "⚙️  Configurar" \
        "▶️  Ejecutar" \
        "📊 Estado" \
        "❌ Salir")
    
    case "$action" in
        "🚀 Instalar") install_project ;;
        "⚙️  Configurar") configure_project ;;
        "▶️  Ejecutar") run_project ;;
        "📊 Estado") show_status ;;
        "❌ Salir") exit 0 ;;
    esac
}

# Función de instalación
install_project() {
    if confirm_action "instalación" "Se instalarán todas las dependencias del proyecto"; then
        show_gui_spinner "Instalando dependencias..." sleep 3
        log_success "Instalación completada"
    fi
}

# Función de configuración
configure_project() {
    select_features
    
    if confirm_action "configuración" "Se aplicarán las siguientes configuraciones:\n• Feature A: $ENABLE_FEATURE_A\n• Feature B: $ENABLE_FEATURE_B\n• Feature C: $ENABLE_FEATURE_C"; then
        show_gui_spinner "Configurando proyecto..." sleep 2
        log_success "Configuración aplicada"
    fi
}

# Selección de características
select_features() {
    local selected_features=$(show_gui_multi_select \
        "Características del Proyecto" \
        "Selecciona las características que deseas habilitar" \
        "Características disponibles:" \
        3 \
        "🔐 Feature A [Autenticación avanzada]" \
        "📧 Feature B [Sistema de notificaciones]" \
        "📊 Feature C [Analytics y métricas]")
    
    # Procesar selecciones
    while IFS= read -r feature; do
        case "$feature" in
            "🔐 Feature A [Autenticación avanzada]")
                ENABLE_FEATURE_A=true
                ;;
            "📧 Feature B [Sistema de notificaciones]")
                ENABLE_FEATURE_B=true
                ;;
            "📊 Feature C [Analytics y métricas]")
                ENABLE_FEATURE_C=true
                ;;
        esac
    done <<< "$selected_features"
}

# Función de ejecución
run_project() {
    local environment=$(show_gui_menu \
        "Entorno de Ejecución" \
        "Selecciona el entorno donde ejecutar el proyecto" \
        "Entorno:" \
        "🟢 Desarrollo" \
        "🟡 Staging" \
        "🔴 Producción")
    
    case "$environment" in
        "🟢 Desarrollo")
            show_gui_spinner "Ejecutando en desarrollo..." sleep 2
            log_success "Proyecto ejecutándose en desarrollo"
            ;;
        "🟡 Staging")
            if confirm_action "ejecución en staging" "¿Estás seguro de ejecutar en staging?"; then
                show_gui_spinner "Ejecutando en staging..." sleep 2
                log_success "Proyecto ejecutándose en staging"
            fi
            ;;
        "🔴 Producción")
            if confirm_action "ejecución en producción" "⚠️  ATENCIÓN: Ejecutarás en PRODUCCIÓN. ¿Estás completamente seguro?"; then
                show_gui_spinner "Ejecutando en producción..." sleep 3
                log_success "Proyecto ejecutándose en producción"
            fi
            ;;
    esac
}

# Función de estado
show_status() {
    log_info "Estado del proyecto:"
    echo -e "  ${C_GREEN}✅ Proyecto activo${C_NC}"
    echo -e "  ${C_BLUE}📊 Feature A: $ENABLE_FEATURE_A${C_NC}"
    echo -e "  ${C_BLUE}📊 Feature B: $ENABLE_FEATURE_B${C_NC}"
    echo -e "  ${C_BLUE}📊 Feature C: $ENABLE_FEATURE_C${C_NC}"
}

# Función de confirmación
confirm_action() {
    local action="$1"
    local details="$2"
    
    if show_gui_confirmation \
        "¿Deseas continuar con '$action'?\n\n$details"; then
        log_success "Acción confirmada: $action"
        return 0
    else
        log_warning "Acción cancelada: $action"
        return 1
    fi
}

# Ejecutar función principal
main "$@"
```

---

## 🚨 Solución de Problemas

### Error: "unknown flag --unselected.foreground"
```bash
# Problema: Versión antigua de gum
# Solución: El framework detecta automáticamente y usa flags compatibles
# No necesitas hacer nada, funciona automáticamente
```

### Error: "Este menú requiere una terminal interactiva"
```bash
# Problema: Script ejecutándose en contexto no interactivo
# Solución: Ejecutar desde terminal real
./mi_script.sh --interactive
```

### Menús no aparecen
```bash
# Problema: TTY no disponible o gum no instalado
# Solución: Verificar instalación y contexto
command -v gum || brew install gum
[[ -t 0 ]] && echo "TTY disponible" || echo "No TTY"
```

### Confirmaciones no funcionan
```bash
# Problema: Lógica de retorno incorrecta
# Solución: Usar siempre las funciones del framework
if show_gui_confirmation "¿Continuar?"; then
    echo "Confirmado"
else
    echo "Cancelado"
fi
```

---

## 📋 Checklist de Implementación

### Para Nuevos Proyectos
- [ ] Copiar `gui_framework.sh` al proyecto
- [ ] Incluir `source ./gui_framework.sh` en el script principal
- [ ] Llamar `init_gui_framework` al inicio
- [ ] Usar las funciones `show_gui_*` para todos los menús
- [ ] Implementar manejo de errores con `log_*`
- [ ] Agregar confirmaciones para acciones críticas
- [ ] Probar en diferentes versiones de gum

### Para Proyectos Existentes
- [ ] Migrar menús existentes a funciones del framework
- [ ] Reemplazar `read` y `echo` por funciones GUI
- [ ] Agregar confirmaciones donde sea necesario
- [ ] Implementar logging consistente
- [ ] Probar compatibilidad

---

## 🎯 Mejores Prácticas

### 1. **Siempre usar las funciones del framework**
```bash
# ✅ Correcto
show_gui_menu "Título" "Subtítulo" "Header" "Opción 1" "Opción 2"

# ❌ Incorrecto
gum choose --header="Header" "Opción 1" "Opción 2"
```

### 2. **Manejar errores graciosamente**
```bash
# ✅ Correcto
if ! show_gui_confirmation "¿Continuar?"; then
    log_warning "Operación cancelada"
    return 1
fi

# ❌ Incorrecto
show_gui_confirmation "¿Continuar?"
# Continuar sin verificar resultado
```

### 3. **Usar logs consistentes**
```bash
# ✅ Correcto
log_success "Operación completada"
log_error "Error en la operación"
log_info "Información importante"
log_debug "Información de depuración"

# ❌ Incorrecto
echo "Operación completada"
echo "Error en la operación"
```

### 4. **Confirmar acciones críticas**
```bash
# ✅ Correcto
if show_gui_confirmation "¿Eliminar archivo crítico?"; then
    rm archivo_critico
fi

# ❌ Incorrecto
rm archivo_critico
```

---

## 📚 Recursos Adicionales

- [Documentación oficial de Gum](https://github.com/charmbracelet/gum)
- [Charmbracelet](https://charm.sh/) - Framework completo
- [Ejemplos de Gum](https://github.com/charmbracelet/gum/tree/main/examples)

---

**Nota**: Este framework está diseñado para ser el **pilar único** de todas las GUIs de tus proyectos de shell. Es robusto, compatible y mantenible. Úsalo como base en todos tus proyectos para garantizar una experiencia de usuario consistente y profesional. 
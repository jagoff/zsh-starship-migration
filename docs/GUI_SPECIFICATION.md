# 🎨 Especificación Completa de la GUI Interactiva

## 📋 Descripción General

Esta especificación detalla la implementación de una interfaz de usuario interactiva elegante para scripts de configuración y migración, utilizando `gum` como herramienta principal para crear experiencias de usuario modernas y intuitivas.

## 🛠️ Herramientas Principales

### Gum - CLI Framework
```bash
# Instalación
brew install gum

# Verificación
gum --version
```

### Características de Gum
- **Multiplataforma**: Funciona en macOS, Linux y Windows
- **Tema consistente**: Colores y estilos unificados
- **Interactividad**: Menús, formularios, confirmaciones
- **Personalizable**: Temas y estilos configurables

## 🎨 Esquema de Colores

### Colores Principales
```bash
# Variables de color para el script
readonly C_RED='\033[0;31m'        # #ff0000 - Errores y alertas críticas
readonly C_GREEN='\033[0;32m'      # #00ff00 - Éxitos y confirmaciones
readonly C_BLUE='\033[0;34m'       # #0000ff - Información y títulos
readonly C_YELLOW='\033[0;93m'     # #ffff00 - Advertencias y prompts
readonly C_NC='\033[0m'            # Reset de color
```

### Colores Secundarios
```bash
# Colores adicionales para enriquecer la interfaz
readonly C_CYAN='\033[0;36m'       # #00ffff - Información técnica
readonly C_MAGENTA='\033[0;35m'    # #ff00ff - Destacados especiales
readonly C_WHITE='\033[1;37m'      # #ffffff - Texto principal
readonly C_GRAY='\033[0;90m'       # #808080 - Texto secundario
```

## 🔧 Compatibilidad y Robustez

### Detección de Versión de Gum
```bash
# Función para detectar la versión de gum instalada
get_gum_version() {
    if ! command -v gum >/dev/null; then
        echo "0.0.0"
        return
    fi
    gum --version | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+'
}

# Función para verificar compatibilidad con flags avanzados
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

### Detección de TTY
```bash
# Función para requerir terminal interactiva
require_tty() {
    if [[ ! -t 0 ]]; then
        echo -e "${C_RED}❌ Este menú requiere una terminal interactiva (TTY). Ejecutá el script desde una terminal real.${C_NC}"
        exit 2
    fi
}
```

## 📱 Componentes de la Interfaz

### 1. Menú de Selección Múltiple (Checkbox) - Versión Robusta

#### Implementación Adaptativa
```bash
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
    
    # Usar gum choose sin flags problemáticos para máxima compatibilidad
    gum choose \
        --header="$header" \
        --limit="$limit" \
        "${options[@]}"
}
```

#### Uso
```bash
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
```

### 2. Menú de Selección Única (Radio) - Versión Robusta

#### Implementación Adaptativa
```bash
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
```

### 3. Confirmación con Spinner - Versión Robusta

#### Implementación Adaptativa
```bash
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
```

#### Uso
```bash
if show_gui_confirmation \
    "¿Deseas continuar con la instalación?\n\nSe realizarán los siguientes cambios:\n• Backup de configuración actual\n• Instalación de dependencias\n• Configuración del sistema"; then
    echo -e "${C_GREEN}✅ Instalación confirmada${C_NC}"
    # Continuar con la instalación
else
    echo -e "${C_YELLOW}⚠️  Instalación cancelada${C_NC}"
    exit 0
fi
```

### 4. Verificación de Dependencias

#### Implementación
```bash
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
```

## 🎯 Patrones de Diseño Mejorados

### 1. Estructura de Menú Robusta
```bash
# Patrón estándar para menús interactivos con detección de TTY
show_menu() {
    require_tty
    echo -e "${C_BLUE}📋 ${TITLE}${C_NC}"
    echo -e "${C_GRAY}${SUBTITLE}${C_NC}"
    
    local selection=$(gum choose \
        --header="${HEADER}" \
        "${OPTIONS[@]}")
    
    process_selection "$selection"
}
```

### 2. Manejo de Estados con Logs
```bash
# Estados visuales consistentes con logs de depuración
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

show_debug() {
    echo -e "${C_GRAY}[DEBUG] $1${C_NC}"
}
```

### 3. Validación Robusta
```bash
# Validación con feedback visual y detección de errores
validate_input() {
    local input="$1"
    local pattern="$2"
    
    if [[ "$input" =~ $pattern ]]; then
        show_success "Entrada válida"
        return 0
    else
        show_error "Entrada inválida"
        return 1
    fi
}
```

## 🔧 Configuración de Gum - Versión Simplificada

### Enfoque de Compatibilidad
```bash
# En lugar de usar flags de color complejos, usar solo los básicos
# Esto garantiza compatibilidad con todas las versiones de gum

# ✅ Compatible con todas las versiones
gum choose --header="Selecciona una opción" "Opción 1" "Opción 2"

# ❌ Puede fallar en versiones antiguas
gum choose --header="Selecciona" --selected.foreground="#00ff00" --unselected.foreground="#ffffff" "Opción 1" "Opción 2"
```

### Variables de Entorno (Opcional)
```bash
# Configuración global para versiones que lo soporten
export GUM_CHOOSE_SELECTED_FOREGROUND="#00ff00"
export GUM_CHOOSE_SELECTED_BACKGROUND="#000000"
export GUM_CHOOSE_CURSOR_FOREGROUND="#ffff00"
export GUM_CHOOSE_CURSOR_BACKGROUND="#666666"
```

## 📦 Implementación en Proyectos - Versión Mejorada

### Script de Configuración Rápida Robusto
```bash
#!/bin/bash
# setup-gui.sh - Configuración rápida de GUI robusta para proyectos

# Colores estándar
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
readonly C_YELLOW='\033[0;93m'
readonly C_GRAY='\033[0;90m'
readonly C_NC='\033[0m'

# Verificar dependencias
check_dependencies() {
    if ! command -v gum >/dev/null; then
        echo -e "${C_RED}❌ Gum no está instalado${C_NC}"
        echo -e "${C_BLUE}ℹ️  Instalando Gum...${C_NC}"
        brew install gum
    fi
}

# Detección de TTY
require_tty() {
    if [[ ! -t 0 ]]; then
        echo -e "${C_RED}❌ Este menú requiere una terminal interactiva (TTY). Ejecutá el script desde una terminal real.${C_NC}"
        exit 2
    fi
}

# Función de menú estándar robusta
show_standard_menu() {
    require_tty
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

# Función de confirmación robusta
show_standard_confirmation() {
    require_tty
    local message="$1"
    local affirmative="${2:-Sí, continuar}"
    local negative="${3:-No, cancelar}"
    
    gum confirm \
        --affirmative="$affirmative" \
        --negative="$negative" \
        "$message"
    return $?
}

# Ejemplo de uso
main() {
    check_dependencies
    
    local action=$(show_standard_menu \
        "Configuración del Proyecto" \
        "Selecciona la acción que deseas realizar" \
        "Elige una opción (enter para confirmar):" \
        "Instalar dependencias" \
        "Configurar entorno" \
        "Ejecutar tests" \
        "Deploy" \
        "Salir")
    
    case "$action" in
        "Instalar dependencias")
            if show_standard_confirmation "¿Deseas instalar las dependencias?"; then
                echo -e "${C_GREEN}✅ Instalando dependencias...${C_NC}"
            else
                echo -e "${C_YELLOW}⚠️  Instalación cancelada${C_NC}"
            fi
            ;;
        "Configurar entorno")
            echo -e "${C_BLUE}ℹ️  Configurando entorno...${C_NC}"
            ;;
        "Ejecutar tests")
            echo -e "${C_YELLOW}⚠️  Ejecutando tests...${C_NC}"
            ;;
        "Deploy")
            echo -e "${C_RED}❌ Deploy no implementado${C_NC}"
            ;;
        "Salir")
            echo -e "${C_GRAY}👋 ¡Hasta luego!${C_NC}"
            exit 0
            ;;
    esac
}

main "$@"
```

## 🎨 Personalización Avanzada - Versión Compatible

### Detección Automática de Capacidades
```bash
# Detectar automáticamente qué flags soporta la versión de gum
get_gum_capabilities() {
    local version=$(get_gum_version)
    local capabilities=()
    
    # Detectar soporte para flags de color
    if supports_gum_unselected_flags; then
        capabilities+=("color_flags")
    fi
    
    # Detectar soporte para otros flags según versión
    # (implementar según necesidad)
    
    echo "${capabilities[@]}"
}
```

### Configuración Condicional
```bash
# Aplicar configuración solo si es compatible
apply_gum_config() {
    local capabilities=($(get_gum_capabilities))
    
    if [[ " ${capabilities[@]} " =~ " color_flags " ]]; then
        # Aplicar configuración de colores
        export GUM_CHOOSE_SELECTED_FOREGROUND="#00ff00"
        export GUM_CHOOSE_SELECTED_BACKGROUND="#000000"
    else
        # Usar configuración básica
        echo "Usando configuración básica de gum"
    fi
}
```

## 📋 Checklist de Implementación Mejorada

### Para Nuevos Proyectos
- [ ] Instalar Gum: `brew install gum`
- [ ] Copiar variables de color estándar
- [ ] Implementar funciones de menú robustas con `require_tty()`
- [ ] Agregar detección de versión de gum
- [ ] Implementar funciones adaptativas
- [ ] Agregar validaciones visuales
- [ ] Implementar manejo de errores robusto
- [ ] Crear documentación de uso

### Para Proyectos Existentes
- [ ] Migrar menús existentes a funciones robustas
- [ ] Agregar detección de TTY
- [ ] Implementar compatibilidad con versiones antiguas
- [ ] Agregar logs de depuración
- [ ] Optimizar experiencia de usuario
- [ ] Documentar cambios

## 🔍 Mejores Prácticas Mejoradas

### 1. Robustez y Compatibilidad
- **Siempre usar `require_tty()`** antes de mostrar menús interactivos
- **Detectar versión de gum** y adaptar flags según compatibilidad
- **Usar flags básicos** para máxima compatibilidad
- **Agregar logs de depuración** para facilitar troubleshooting

### 2. Experiencia de Usuario
- **Proporcionar feedback inmediato** para todas las acciones
- **Incluir opciones de cancelación** en menús largos
- **Mostrar progreso** para operaciones que toman tiempo
- **Manejar errores graciosamente** con mensajes claros

### 3. Accesibilidad
- **Usar colores con suficiente contraste** cuando estén disponibles
- **Incluir descripciones claras** para cada opción
- **Proporcionar atajos de teclado** cuando sea posible
- **Funcionar en terminales sin color** como fallback

### 4. Mantenibilidad
- **Centralizar configuración** de colores y funciones
- **Crear funciones reutilizables** para patrones comunes
- **Documentar todas las personalizaciones**
- **Usar versionado semántico** para cambios en la API

## 🚨 Solución de Problemas Comunes

### Error: "unknown flag --unselected.foreground"
```bash
# Problema: Versión antigua de gum no soporta flags de color
# Solución: Usar solo flags básicos
gum choose --header="Selecciona" "Opción 1" "Opción 2"
```

### Error: "Este menú requiere una terminal interactiva"
```bash
# Problema: Script ejecutándose en contexto no interactivo
# Solución: Ejecutar desde terminal real, no desde editor
./script.sh --interactive
```

### Menús no aparecen
```bash
# Problema: TTY no disponible o gum no instalado
# Solución: Verificar instalación y contexto
command -v gum || brew install gum
[[ -t 0 ]] && echo "TTY disponible" || echo "No TTY"
```

## 📚 Recursos Adicionales

### Documentación Oficial
- [Gum Documentation](https://github.com/charmbracelet/gum)
- [Charmbracelet](https://charm.sh/) - Framework completo
- [Bubble Tea](https://github.com/charmbracelet/bubbletea) - Para aplicaciones más complejas

### Ejemplos y Templates
- [Gum Examples](https://github.com/charmbracelet/gum/tree/main/examples)
- [Charm Templates](https://github.com/charmbracelet/charm/tree/main/templates)

### Comunidad
- [Charm Discord](https://charm.sh/chat)
- [GitHub Discussions](https://github.com/charmbracelet/gum/discussions)

---

**Nota**: Esta especificación está diseñada para ser utilizada como base en todos los proyectos que requieran interfaces de usuario interactivas en la línea de comandos. La robustez y compatibilidad son fundamentales para la adopción y satisfacción del usuario final. La implementación debe funcionar en cualquier versión de gum y en cualquier contexto de terminal. 
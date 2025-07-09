# 🎨 GUI Interactiva Estándar

## 🚀 Uso Rápido

### 1. Configuración Inicial
```bash
# Clonar o descargar el script de configuración
chmod +x setup-gui.sh
./setup-gui.sh
```

### 2. Crear un Nuevo Proyecto con GUI
```bash
# El script te guiará para crear un template
./setup-gui.sh
# Selecciona "Crear template de proyecto"
# Ingresa el nombre de tu proyecto
```

### 3. Usar el Template Generado
```bash
# El template se guarda como gui-template.sh
chmod +x gui-template.sh
./gui-template.sh
```

## 🎯 Características Principales

### ✅ **Interfaz Consistente**
- Colores estándar en todos los proyectos
- Emojis descriptivos para mejor UX
- Navegación intuitiva con flechas

### ✅ **Componentes Reutilizables**
- Menús de selección única y múltiple
- Confirmaciones interactivas
- Entrada de datos con validación
- Spinners y barras de progreso

### ✅ **Configuración Automática**
- Instalación automática de dependencias
- Configuración de Gum global
- Variables de entorno predefinidas

## 🎨 Esquema de Colores

| Color | Código | Uso |
|-------|--------|-----|
| Verde | `#00ff00` | Éxitos, selecciones activas |
| Rojo | `#ff0000` | Errores, alertas críticas |
| Azul | `#0000ff` | Información, títulos |
| Amarillo | `#ffff00` | Advertencias, cursor |
| Blanco | `#ffffff` | Texto principal |
| Gris | `#666666` | Texto secundario |

## 📱 Componentes Disponibles

### Menú de Selección
```bash
show_standard_menu "Título" "Subtítulo" "Header" "Opción 1" "Opción 2"
```

### Selección Múltiple
```bash
show_multi_select "Título" "Subtítulo" "Header" 3 "Opción 1" "Opción 2" "Opción 3"
```

### Confirmación
```bash
if show_confirmation "¿Continuar?"; then
    echo "Usuario confirmó"
fi
```

### Entrada de Datos
```bash
name=$(show_input "Nombre:" "Tu nombre")
```

### Spinner
```bash
show_spinner "Procesando..." sleep 3
```

### Barra de Progreso
```bash
show_progress "Instalando..." 75
```

## 🔧 Configuración Avanzada

### Variables de Entorno
```bash
# Agregar a tu ~/.zshrc o ~/.bashrc
export GUM_CHOOSE_SELECTED_FOREGROUND="#00ff00"
export GUM_CHOOSE_SELECTED_BACKGROUND="#000000"
export GUM_CHOOSE_UNSELECTED_FOREGROUND="#ffffff"
export GUM_CHOOSE_UNSELECTED_BACKGROUND="#333333"
export GUM_CHOOSE_CURSOR_FOREGROUND="#ffff00"
export GUM_CHOOSE_CURSOR_BACKGROUND="#666666"
```

### Archivo de Configuración de Gum
```yaml
# ~/.config/gum/config.yaml
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
```

## 📋 Ejemplos de Uso

### Ejemplo 1: Configuración de Proyecto
```bash
#!/bin/bash
# config-project.sh

source ./gui-template.sh

main() {
    local action=$(show_standard_menu \
        "Configuración del Proyecto" \
        "Selecciona la acción que deseas realizar" \
        "Elige una opción:" \
        "Instalar dependencias" \
        "Configurar entorno" \
        "Ejecutar tests" \
        "Deploy")
    
    case "$action" in
        "Instalar dependencias")
            show_spinner "Instalando..." npm install
            show_success "Dependencias instaladas"
            ;;
        "Configurar entorno")
            local env=$(show_input "Entorno:" "development")
            show_info "Configurando entorno: $env"
            ;;
        "Ejecutar tests")
            show_spinner "Ejecutando tests..." npm test
            ;;
        "Deploy")
            if show_confirmation "¿Deploy a producción?"; then
                show_spinner "Deploying..." npm run deploy
            fi
            ;;
    esac
}

main "$@"
```

### Ejemplo 2: Instalador de Herramientas
```bash
#!/bin/bash
# install-tools.sh

source ./gui-template.sh

main() {
    local tools=$(show_multi_select \
        "Herramientas de Desarrollo" \
        "Selecciona las herramientas que deseas instalar" \
        "Espacio para marcar, enter para confirmar:" \
        5 \
        "Node.js [Runtime de JavaScript]" \
        "Python [Lenguaje de programación]" \
        "Docker [Contenedores]" \
        "Git [Control de versiones]" \
        "VS Code [Editor de código]")
    
    for tool in $tools; do
        case "$tool" in
            "Node.js"*)
                show_spinner "Instalando Node.js..." brew install node
                ;;
            "Python"*)
                show_spinner "Instalando Python..." brew install python
                ;;
            "Docker"*)
                show_spinner "Instalando Docker..." brew install docker
                ;;
            "Git"*)
                show_spinner "Instalando Git..." brew install git
                ;;
            "VS Code"*)
                show_spinner "Instalando VS Code..." brew install --cask visual-studio-code
                ;;
        esac
        show_success "Instalado: $tool"
    done
}

main "$@"
```

## 🚀 Integración con Proyectos Existentes

### 1. Copiar Variables de Color
```bash
# Agregar al inicio de tu script
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_BLUE='\033[0;34m'
readonly C_YELLOW='\033[0;93m'
readonly C_NC='\033[0m'
```

### 2. Copiar Funciones de Logging
```bash
show_success() { echo -e "${C_GREEN}✅ $1${C_NC}"; }
show_error() { echo -e "${C_RED}❌ $1${C_NC}" >&2; }
show_warning() { echo -e "${C_YELLOW}⚠️  $1${C_NC}"; }
show_info() { echo -e "${C_BLUE}ℹ️  $1${C_NC}"; }
```

### 3. Reemplazar Menús Existentes
```bash
# Antes (menú básico)
echo "1. Opción 1"
echo "2. Opción 2"
read -p "Selecciona: " choice

# Después (menú interactivo)
choice=$(show_standard_menu "Título" "Subtítulo" "Header" "Opción 1" "Opción 2")
```

## 🔍 Troubleshooting

### Problema: Gum no está instalado
```bash
# Solución automática
./setup-gui.sh
# El script detectará y instalará Gum automáticamente
```

### Problema: Colores no se muestran
```bash
# Verificar que tu terminal soporte colores
echo -e "\033[0;32mTest\033[0m"
# Si no ves "Test" en verde, tu terminal no soporta colores
```

### Problema: Menús no funcionan
```bash
# Verificar versión de Gum
gum --version
# Debe ser 0.9.0 o superior
```

## 📚 Recursos Adicionales

- [Especificación Completa](GUI_SPECIFICATION.md)
- [Documentación de Gum](https://github.com/charmbracelet/gum)
- [Ejemplos Avanzados](https://github.com/charmbracelet/gum/tree/main/examples)

## 🤝 Contribuir

Para mejorar esta GUI estándar:

1. Mantén la consistencia de colores
2. Usa emojis descriptivos
3. Proporciona feedback visual
4. Documenta nuevas funciones
5. Prueba en diferentes terminales

---

**¡Disfruta creando interfaces de usuario hermosas y funcionales!** 🎨✨ 
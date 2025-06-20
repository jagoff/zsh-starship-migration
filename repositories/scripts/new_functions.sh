# --- BÚSQUEDA E INSTALACIÓN DE TEMAS DE STARSHIP ---
search_starship_themes() {
    log_info "🔍 Buscando temas populares de Starship..."
    
    # Verificar si curl está disponible
    if ! command -v curl >/dev/null 2>&1; then
        log_error "curl no está instalado. Instala curl para buscar temas."
        return 1
    fi
    
    # Buscar temas en GitHub usando la API
    local search_url="https://api.github.com/search/repositories?q=starship+theme+language:toml&sort=stars&order=desc&per_page=20"
    
    log_verbose "Buscando temas en GitHub..."
    local response
    response=$(curl -s "$search_url" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        log_error "Error al buscar temas. Verifica tu conexión a internet."
        return 1
    fi
    
    # Parsear respuesta JSON y extraer información
    local themes_data
    themes_data=$(echo "$response" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for repo in data.get('items', []):
        name = repo['name']
        description = repo.get('description', 'Sin descripción')
        stars = repo['stargazers_count']
        downloads = repo.get('downloads', 0)
        url = repo['html_url']
        print(f'{name}|{description}|{stars}|{downloads}|{url}')
except:
    print('Error parsing JSON')
" 2>/dev/null)
    
    if [[ -z "$themes_data" ]]; then
        log_error "No se pudieron obtener los temas."
        return 1
    fi
    
    # Mostrar temas ordenados por estrellas
    echo -e "\n${C_BLUE}🎨 Temas Populares de Starship:${C_NC}"
    echo -e "${C_YELLOW}Ordenados por popularidad (estrellas)${C_NC}\n"
    
    local count=1
    echo "$themes_data" | while IFS='|' read -r name description stars downloads url; do
        if [[ -n "$name" ]]; then
            printf "${C_GREEN}%2d.${C_NC} ${C_BLUE}%-30s${C_NC} ⭐ %-6s 📥 %-6s\n" "$count" "$name" "$stars" "$downloads"
            printf "     ${C_YELLOW}%s${C_NC}\n" "$description"
            printf "     ${C_NC}URL: %s\n\n" "$url"
            count=$((count + 1))
        fi
    done
    
    # Opción para instalar un tema
    echo -e "${C_BLUE}¿Quieres instalar algún tema? (número o 'n' para saltar):${C_NC}"
    read -r theme_choice
    
    if [[ "$theme_choice" =~ ^[0-9]+$ ]] && [[ "$theme_choice" -ge 1 ]] && [[ "$theme_choice" -le 20 ]]; then
        local selected_theme
        selected_theme=$(echo "$themes_data" | sed -n "${theme_choice}p" | cut -d'|' -f1)
        local theme_url
        theme_url=$(echo "$themes_data" | sed -n "${theme_choice}p" | cut -d'|' -f5)
        
        if [[ -n "$selected_theme" ]]; then
            install_starship_theme "$selected_theme" "$theme_url"
        fi
    else
        log_info "Saltando instalación de tema."
    fi
}

install_starship_theme() {
    local theme_name="$1"
    local theme_url="$2"
    
    log_info "📦 Instalando tema: $theme_name"
    
    # Crear directorio de temas si no existe
    local themes_dir="$HOME/.config/starship/themes"
    mkdir -p "$themes_dir"
    
    # Descargar tema
    local theme_file="$themes_dir/${theme_name}.toml"
    
    if curl -s -L "$theme_url/raw/main/starship.toml" -o "$theme_file" 2>/dev/null; then
        log_success "✅ Tema '$theme_name' instalado en: $theme_file"
        
        # Actualizar configuración de Starship para usar el tema
        if [[ -f "$HOME/.config/starship.toml" ]]; then
            # Agregar referencia al tema en la configuración
            if ! grep -q "theme = \"$theme_name\"" "$HOME/.config/starship.toml"; then
                safe_sed_inplace "1i\\\n[theme]\\\ntheme = \"$theme_name\"" "$HOME/.config/starship.toml"
                log_success "✅ Tema '$theme_name' configurado como predeterminado"
            fi
        fi
        
        add_gamification_xp 10
        unlock_achievement "Tema personalizado instalado"
    else
        log_error "❌ Error al instalar el tema '$theme_name'"
    fi
}

# --- INSTALACIÓN AUTOMÁTICA DE GESTORES DE PAQUETES ---
install_package_manager() {
    log_info "📦 Detectando e instalando gestor de paquetes..."
    
    case "$PLATFORM" in
        "macos")
            if ! command -v brew >/dev/null 2>&1; then
                log_info "Instalando Homebrew..."
                if [[ "$DRY_RUN" = true ]]; then
                    log_warn "[DRY-RUN] Se instalaría Homebrew"
                    return
                fi
                
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                if [[ $? -eq 0 ]]; then
                    log_success "✅ Homebrew instalado correctamente"
                    # Agregar Homebrew al PATH si es necesario
                    if [[ -f "/opt/homebrew/bin/brew" ]]; then
                        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
                    fi
                    add_gamification_xp 15
                    unlock_achievement "Homebrew instalado"
                else
                    log_error "❌ Error al instalar Homebrew"
                    return 1
                fi
            fi
            ;;
        "linux")
            case "$PACKAGE_MANAGER" in
                "apt")
                    if ! command -v apt >/dev/null 2>&1; then
                        log_info "Instalando apt..."
                        # En la mayoría de distribuciones Debian/Ubuntu, apt ya viene instalado
                        log_warn "apt debería estar disponible en tu distribución"
                    fi
                    ;;
                "dnf")
                    if ! command -v dnf >/dev/null 2>&1; then
                        log_info "Instalando dnf..."
                        # Intentar instalar dnf si no está disponible
                        if command -v yum >/dev/null 2>&1; then
                            sudo yum install -y dnf
                        fi
                    fi
                    ;;
                "pacman")
                    if ! command -v pacman >/dev/null 2>&1; then
                        log_warn "pacman debería estar disponible en Arch Linux"
                    fi
                    ;;
                *)
                    log_warn "Gestor de paquetes no reconocido. Instala manualmente el gestor de tu distribución."
                    ;;
            esac
            ;;
        "windows")
            if ! command -v choco >/dev/null 2>&1; then
                log_info "Instalando Chocolatey..."
                if [[ "$DRY_RUN" = true ]]; then
                    log_warn "[DRY-RUN] Se instalaría Chocolatey"
                    return
                fi
                
                # Instalar Chocolatey en PowerShell como administrador
                log_warn "Para instalar Chocolatey, ejecuta PowerShell como administrador y corre:"
                echo "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
            fi
            ;;
    esac
}

# --- EXPORTACIÓN/IMPORTACIÓN CON GITHUB GIST ---
export_to_gist() {
    local profile_name="$1"
    local gist_description="${2:-Starship configuration profile: $profile_name}"
    
    if [[ -z "$profile_name" ]]; then
        log_error "Debe especificar un nombre de perfil."
        return 1
    fi
    
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    if [[ ! -d "$profile_dir" ]]; then
        log_error "El perfil '$profile_name' no existe."
        return 1
    fi
    
    log_info "📤 Exportando perfil '$profile_name' a GitHub Gist..."
    
    # Crear archivo temporal con la configuración
    local temp_file
    temp_file=$(mktemp)
    
    # Crear contenido del Gist
    cat > "$temp_file" <<EOF
# Starship Configuration Profile: $profile_name

## Starship Configuration
\`\`\`toml
$(cat "$profile_dir/starship.toml" 2>/dev/null || echo "# No starship.toml found")
\`\`\`

## Zsh Configuration
\`\`\`bash
$(cat "$profile_dir/zshrc" 2>/dev/null || echo "# No zshrc found")
\`\`\`

## Metadata
\`\`\`json
$(cat "$profile_dir/metadata.json" 2>/dev/null || echo "{}")
\`\`\`

---
*Exported by Zsh Starship Migration Script v$SCRIPT_VERSION*
EOF
    
    # Verificar si gh CLI está disponible
    if command -v gh >/dev/null 2>&1; then
        log_info "Usando GitHub CLI para crear Gist..."
        local gist_url
        gist_url=$(gh gist create --public --desc "$gist_description" "$temp_file" 2>/dev/null)
        
        if [[ $? -eq 0 ]]; then
            log_success "✅ Gist creado: $gist_url"
            echo "$gist_url" > "$profile_dir/gist_url.txt"
            add_gamification_xp 10
            unlock_achievement "Gist creado"
        else
            log_error "❌ Error al crear Gist con GitHub CLI"
        fi
    else
        log_warn "GitHub CLI no está instalado. Instálalo para exportar a Gist automáticamente."
        log_info "Contenido del perfil preparado en: $temp_file"
        log_info "Copia el contenido y créalo manualmente en: https://gist.github.com/"
    fi
    
    rm -f "$temp_file"
}

import_from_gist() {
    local gist_url="$1"
    local profile_name="${2:-gist_import}"
    
    if [[ -z "$gist_url" ]]; then
        log_error "Debe especificar la URL del Gist."
        return 1
    fi
    
    log_info "📥 Importando desde Gist: $gist_url"
    
    # Extraer ID del Gist de la URL
    local gist_id
    gist_id=$(echo "$gist_url" | sed 's/.*gist\.github\.com\///' | sed 's/\/.*//')
    
    if [[ -z "$gist_id" ]]; then
        log_error "URL de Gist inválida."
        return 1
    fi
    
    # Crear directorio del perfil
    local profile_dir="$HOME/.config/starship_profiles/$profile_name"
    mkdir -p "$profile_dir"
    
    # Descargar contenido del Gist
    local gist_api_url="https://api.github.com/gists/$gist_id"
    local gist_data
    gist_data=$(curl -s "$gist_api_url" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        log_error "Error al descargar Gist."
        return 1
    fi
    
    # Extraer archivos del Gist
    local files
    files=$(echo "$gist_data" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for filename, file_data in data['files'].items():
        content = file_data.get('content', '')
        print(f'{filename}|{content}')
except:
    print('Error parsing Gist data')
" 2>/dev/null)
    
    if [[ -z "$files" ]]; then
        log_error "No se pudieron extraer archivos del Gist."
        return 1
    fi
    
    # Procesar archivos
    echo "$files" | while IFS='|' read -r filename content; do
        if [[ -n "$filename" ]]; then
            case "$filename" in
                "starship.toml"|"*.toml")
                    echo "$content" > "$profile_dir/starship.toml"
                    log_verbose "Configuración de Starship importada"
                    ;;
                "zshrc"|"*.zshrc"|"*.bashrc")
                    echo "$content" > "$profile_dir/zshrc"
                    log_verbose "Configuración de Zsh importada"
                    ;;
                "metadata.json"|"*.json")
                    echo "$content" > "$profile_dir/metadata.json"
                    log_verbose "Metadatos importados"
                    ;;
                *)
                    echo "$content" > "$profile_dir/$filename"
                    log_verbose "Archivo '$filename' importado"
                    ;;
            esac
        fi
    done
    
    log_success "✅ Perfil '$profile_name' importado desde Gist"
    add_gamification_xp 10
    unlock_achievement "Gist importado"
}

# --- NOTIFICACIONES DE ESCRITORIO ---
send_desktop_notification() {
    local title="$1"
    local message="$2"
    local type="${3:-info}"
    
    case "$PLATFORM" in
        "macos")
            if command -v osascript >/dev/null 2>&1; then
                case "$type" in
                    "success")
                        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Glass\""
                        ;;
                    "error")
                        osascript -e "display notification \"$message\" with title \"$title\" sound name \"Basso\""
                        ;;
                    *)
                        osascript -e "display notification \"$message\" with title \"$title\""
                        ;;
                esac
            fi
            ;;
        "linux")
            if command -v notify-send >/dev/null 2>&1; then
                case "$type" in
                    "success")
                        notify-send -i dialog-ok "$title" "$message"
                        ;;
                    "error")
                        notify-send -i dialog-error "$title" "$message"
                        ;;
                    *)
                        notify-send "$title" "$message"
                        ;;
                esac
            fi
            ;;
        "windows")
            if command -v powershell >/dev/null 2>&1; then
                powershell -Command "New-BurntToastNotification -Text '$title', '$message'"
            fi
            ;;
    esac
}

# --- MODO DRY RUN VISUAL ---
show_dry_run_summary() {
    log_info "🔍 Resumen de cambios (DRY RUN)"
    echo -e "\n${C_BLUE}📋 Archivos que se modificarían:${C_NC}"
    
    # Backup
    local timestamp
    timestamp=$(date +'%Y%m%d_%H%M%S')
    local backup_dir="$BACKUP_BASE_DIR/$timestamp"
    echo "  📦 Backup: $backup_dir"
    echo "    ├── ~/.zshrc"
    echo "    ├── ~/.oh-my-zsh/ (si existe)"
    echo "    └── ~/.config/starship.toml (si existe)"
    
    # Nuevos archivos
    echo -e "\n${C_GREEN}📄 Archivos que se crearían:${C_NC}"
    echo "  ⚙️  ~/.config/starship.toml"
    echo "  📁 ~/.zsh/plugins/"
    echo "  🎮 ~/.config/starship_gamification.json"
    
    # Herramientas a instalar
    if [[ "$SKIP_TOOLS" = false ]]; then
        echo -e "\n${C_YELLOW}🛠️  Herramientas que se instalarían:${C_NC}"
        echo "  ⭐ starship"
        echo "  🔍 ripgrep, fd, fzf"
        echo "  📖 bat, eza"
        echo "  🎯 zoxide, atuin (opcional)"
    fi
    
    # Plugins a instalar
    echo -e "\n${C_MAGENTA}🔌 Plugins que se instalarían:${C_NC}"
    echo "  💡 zsh-autosuggestions"
    echo "  🌈 zsh-syntax-highlighting"
    echo "  ⌨️  zsh-completions"
    echo "  ⬆️  zsh-history-substring-search"
    echo "  💭 zsh-you-should-use"
    
    # Comandos que se ejecutarían
    echo -e "\n${C_CYAN}⚡ Comandos principales:${C_NC}"
    echo "  📦 brew install starship ripgrep fd fzf bat eza"
    echo "  🔧 git clone plugins a ~/.zsh/plugins/"
    echo "  ⚙️  Generar ~/.config/starship.toml"
    echo "  📝 Actualizar ~/.zshrc"
    
    echo -e "\n${C_BLUE}💡 Para ejecutar la migración real, quita --dry-run${C_NC}"
}

# Migrador de Oh My Zsh a Starship (Multiplataforma, avanzado)

Este script automatiza la migración de una configuración de Oh My Zsh a un entorno moderno con Zsh puro, Starship, plugins y herramientas de línea de comandos mejoradas. Es seguro, multiplataforma (Mac, Linux, WSL) y apto para usuarios avanzados y principiantes.

---

## Características principales

- **Migración automática y segura** (con backup y rollback)
- **Instalación de Starship, plugins y herramientas modernas** (`eza`, `bat`, `fd`, `fzf`, `ripgrep`, `zoxide`, `atuin`, `navi`, `tldr`, `procs`, etc.)
- **Compatible con Mac (Intel/Apple Silicon), Linux y WSL**
- **Gestión avanzada de perfiles**: guarda, carga, exporta, importa y sincroniza configuraciones
- **Gamificación**: sistema de XP, logros y niveles por usar el script y personalizar tu terminal
- **Diagnóstico y seguridad**: chequeos de integridad, permisos, contenido sospechoso y reporte de problemas
- **Selección interactiva de temas y plugins** (9 temas Starship, plugins modernos y avanzados)
- **Validación automática post-migración**
- **Logs claros y manejo robusto de errores**
- **Modo dry-run y verbose para depuración**
- **Sincronización con Git de perfiles/configuraciones**
- **Soporte multiplataforma real**: detección y adaptación automática de comandos y rutas

---

## Requisitos

- **macOS**, **Linux** o **WSL**
- **Homebrew** (Mac), **apt/dnf/pacman** (Linux), **choco** (WSL/Windows) instalado

---

## Instalación y uso rápido

```sh
chmod +x zsh_starship_migration.sh
./zsh_starship_migration.sh           # Migración completa interactiva
./zsh_starship_migration.sh --help    # Ver todas las opciones y comandos
```

---

## Comandos disponibles

```
./zsh_starship_migration.sh                # Migración completa interactiva
./zsh_starship_migration.sh rollback       # Restaura el backup anterior
./zsh_starship_migration.sh report         # Muestra un reporte detallado del entorno y diagnóstico
./zsh_starship_migration.sh status         # Estado actual de la configuración y gamificación
./zsh_starship_migration.sh diagnose       # Diagnóstico rápido del entorno y herramientas
./zsh_starship_migration.sh security-check # Chequeo de seguridad e integridad
./zsh_starship_migration.sh save-profile <nombre>   # Guarda la configuración actual como perfil
./zsh_starship_migration.sh load-profile <nombre>   # Carga una configuración desde un perfil
./zsh_starship_migration.sh list-profiles           # Lista todos los perfiles disponibles
./zsh_starship_migration.sh export-profile <nombre> # Exporta un perfil a un archivo
./zsh_starship_migration.sh import-profile <archivo> # Importa una configuración desde un archivo
./zsh_starship_migration.sh sync-git <url>          # Sincroniza configuraciones con un repositorio Git
./zsh_starship_migration.sh --dry-run               # Simula la migración sin hacer cambios
./zsh_starship_migration.sh --verbose               # Modo detallado para depuración
./zsh_starship_migration.sh --skip-tools            # Migra solo el prompt y plugins, sin instalar herramientas modernas
./zsh_starship_migration.sh --help                  # Ayuda y opciones
```

---

## ¿Qué hace el script?

- Valida tu sistema y dependencias (según plataforma)
- Crea un backup seguro de tu configuración actual
- Extrae alias, exports y funciones personales
- Instala Starship, plugins y herramientas modernas
- Genera un nuevo `.zshrc` y `starship.toml` personalizados
- Permite rollback, gestión de perfiles y sincronización Git
- Diagnóstico rápido y chequeo de seguridad
- Gamificación: XP, logros y niveles por personalización y uso

---

## Personalización y extensibilidad

- Elige entre 9 temas Starship y plugins avanzados (nvm, pyenv, autopair, sudo, etc.)
- Añade tus propios alias, herramientas o plugins fácilmente
- Exporta, importa y sincroniza perfiles entre equipos
- Compatible con cualquier gestor de paquetes moderno

---

## Propuestas de nuevas funcionalidades

- **Integración con Oh My Posh** para usuarios de Windows puro
- **Panel web de configuración** (dashboard local)
- **Notificaciones de logros vía desktop/terminal**
- **Integración con dotfiles y gestores de secretos**
- **Soporte para migrar Fish y Bash a Zsh/Starship**
- **Modo "empresa" para estandarizar entornos de equipos**
- **Auto-actualización del script y de plugins**
- **Integración con plataformas de aprendizaje (badges, retos, etc.)**

---

## Autor

**Fernando Ferrari** - fernando.ferrari@gmail.com

¿Dudas, sugerencias o mejoras? ¡Contribuye o contacta al autor! 
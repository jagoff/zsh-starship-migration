# CHANGELOG

## [2.0.0] - 2025-06-18
### Añadido
- **Sistema de gamificación completo**: XP, logros, niveles y mensajes motivacionales
- **Gestión avanzada de perfiles**: save-profile, load-profile, list-profiles, export-profile, import-profile
- **Sincronización con Git**: sync-git para compartir configuraciones entre equipos
- **Diagnóstico rápido**: comando diagnose para verificar herramientas, plugins y archivos clave
- **Chequeo de seguridad**: security-check para validar permisos, contenido sospechoso e integridad
- **Soporte multiplataforma real**: detección automática de macOS, Linux y WSL
- **Adaptación automática de comandos**: stat, sed y gestores de paquetes según plataforma
- **Instalación de dependencias multiplataforma**: apt, dnf, pacman, choco según sistema
- **9 temas Starship avanzados**: Pastel Powerline, Cyberpunk, Gaming, Minimal, etc.
- **Plugins avanzados**: nvm, pyenv, autopair, sudo, copyfile, git-open, docker-aliases, etc.
- **Herramientas modernas adicionales**: zoxide, atuin, navi, tldr, procs, dust, btm, gitui, lazygit
- **Validación multiplataforma**: detección y validación de gestores de paquetes según sistema
- **Integración de diagnóstico en reportes**: report ahora incluye diagnose y security-check

### Mejorado
- **Parser de argumentos robusto**: soporte para comandos con parámetros (save-profile, load-profile, etc.)
- **Sistema de logging mejorado**: mensajes más claros y detallados
- **Validación de sistema multiplataforma**: adaptación automática según plataforma detectada
- **Gestión de errores mejorada**: mejor manejo de casos edge y errores multiplataforma
- **Documentación completa**: README actualizado con todas las nuevas funcionalidades
- **Ayuda integrada**: show_help actualizado con todos los comandos disponibles

### Corregido
- **Array indexing en Zsh**: corrección de acceso a arrays (1-indexed vs 0-indexed)
- **Argumentos de comandos**: parser mejorado para comandos con parámetros
- **Compatibilidad multiplataforma**: eliminación de dependencias específicas de macOS
- **Permisos y rutas**: adaptación automática según sistema operativo

### Autor
**Fernando Ferrari** - fernando.ferrari@gmail.com

---

## [1.2.0] - 2025-06-17
### Añadido
- Cabecera profesional y autodescriptiva, con instrucciones rápidas y advertencias.
- Opción `report` para generar un reporte detallado del estado de la migración, herramientas, alias y entorno.
- README completo y claro para usuarios de cualquier nivel.
- Compatibilidad multiplataforma para cualquier Mac (Intel o Apple Silicon).

### Mejorado
- Alias de `ls`, `la`, `ll`, `l` ahora usan `eza` (sustituyendo a `exa`), eliminando conflictos y warnings.
- Extracción de funciones en `.zshrc` ahora es robusta y soporta casos complejos.
- Logs más detallados y manejo de errores explícito en cada paso.
- Validación y reporte de herramientas modernas instaladas.

### Corregido
- Eliminados alias antiguos de `exa` tras la migración para evitar conflictos.
- Corrección de PATH y variables de entorno duplicadas.

---

## [1.1.0] - 2025-06-16
### Añadido
- Instalación automática de Starship, plugins modernos y herramientas CLI (`exa`, `bat`, `fd`, `ripgrep`, `fzf`).
- Backup seguro de `.zshrc`, `.oh-my-zsh` y `starship.toml` antes de cualquier cambio.
- Rollback automático a la configuración anterior.
- Opción `--dry-run` para simular la migración sin hacer cambios.
- Opción `--skip-tools` para migrar solo el prompt y plugins.
- Opción `status` para mostrar el estado actual de la configuración.

### Mejorado
- Generación automática de `.zshrc` y `starship.toml` con alias, exports y funciones migradas.
- Mensajes de log claros y coloridos para cada paso.

---

## [1.0.0] - 2025-06-15
### Añadido
- Versión inicial del script de migración de Oh My Zsh a Starship.
- Validación de sistema y dependencias.
- Extracción básica de alias y exports del `.zshrc`.
- Instalación de Starship y plugins esenciales de Zsh.
- Generación de nuevo `.zshrc` y configuración básica de Starship. 
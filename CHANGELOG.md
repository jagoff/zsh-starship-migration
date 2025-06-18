# CHANGELOG

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
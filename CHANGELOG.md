# CHANGELOG

## [1.2.8] - 2025-01-09
### Corregido
- **Inconsistencia en el comportamiento de la interfaz gráfica** - Sistema de modos interactivo/automático completamente reescrito
- **Detección automática de contexto inconsistente** - Ahora detecta correctamente si está en un contexto interactivo
- **Falta de opción para forzar modo interactivo** - Agregada opción `--interactive`
- **Manejo de dependencias inconsistente** - Ahora se manejan correctamente en ambos modos

### Añadido
- **Detección automática mejorada** - Detecta automáticamente contextos no interactivos (CI, NONINTERACTIVE, ! -t 0)
- **Opción `--interactive`** - Permite forzar el modo interactivo incluso en contextos no interactivos
- **Feedback visual del modo** - Muestra claramente si está ejecutándose en modo automático o interactivo
- **Documentación completa** - Nuevo archivo `docs/INTERACTIVE_MODE_FIX.md` explicando el sistema de modos

### Mejorado
- **Comportamiento predecible** - El script ahora es consistente en su comportamiento
- **Control explícito de modos** - Se puede forzar cualquier modo independientemente del contexto
- **Logs más claros** - Indica claramente en qué modo se está ejecutando
- **Manejo robusto de dependencias** - Las dependencias se manejan correctamente en ambos modos

---

## [1.2.7] - 2025-01-09
### Corregido
- **Módulo `openai` inexistente en Starship** - Eliminado módulo que causaba warnings
- **Warnings de configuración de Starship** - Configuración completamente limpia
- **Prompt con errores cortados** - Sin warnings ni errores en el prompt

### Mejorado
- Configuración de Starship más estable y compatible
- Solo módulos disponibles y funcionales
- Prompt completamente limpio y funcional

---

## [1.2.6] - 2025-01-09
### Corregido
- **Migración automática no activaba todos los módulos** - Función `handle_dependencies()` corregida
- **Módulos faltantes en configuración de Starship** - Agregados Docker, AWS, AI/ML, Jobs, Usuario, Host
- **Dependencias se ejecutaban en modo automático** - Ahora solo se ejecutan en modo interactivo
- **Formatos de Starship con variables incorrectas** - Corregidos `${variable}` por `$variable`
- **Detección de módulos incompleta** - Función `get_starship_module_state()` actualizada

### Mejorado
- Migración automática ahora activa correctamente todos los módulos disponibles
- Lista de customizaciones refleja el estado real de todos los módulos
- Configuración de Starship más completa y funcional
- Sistema de logging más preciso sin falsos positivos

---

## [1.2.5] - 2025-01-09
### Corregido
- **Formatos vacíos en configuración de Starship** (format, right_format, cmd_duration, time, battery)
- **Lista de customizaciones no se actualizaba** - Función `get_starship_module_state()` mejorada
- **Warnings incorrectos** de módulos no habilitados que aparecían como errores
- **Prompt con warnings cortados** - Configuración de Starship completamente limpia
- **Detección incorrecta del estado de módulos** - Ahora lee correctamente la configuración actual

### Mejorado
- Función `get_starship_module_state()` ahora detecta correctamente el estado real de cada módulo
- Configuración de Starship más robusta con formatos válidos
- Lista de customizaciones refleja el estado real del sistema
- Prompt completamente funcional sin errores ni warnings

---

## [1.2.4] - 2025-01-09
### Añadido
- Sistema de logging mejorado con funciones específicas para diferentes tipos de mensajes
- Validación automática de configuración de Starship con `validate_starship_config()`
- Función `comprehensive_logging()` para diagnóstico completo del sistema
- Función `log_starship_errors()` para capturar warnings y errores de Starship
- Función `log_system_errors()` para detectar problemas del sistema
- Detección automática de formatos problemáticos en configuración de Starship
- Verificación de módulos custom problemáticos y alias conflictivos
- Integración del logging completo en la validación post-migración

### Corregido
- Formato problemático en módulo kubernetes de Starship (línea 40)
- Sistema de logging ahora captura todos los errores y warnings del sistema
- Validación mejorada que detecta problemas antes de que causen errores
- Logging más detallado y específico para cada tipo de problema
- Error de caracteres de escape en función `comprehensive_logging()`
- Prompt limpio sin warnings cortados de Starship

### Mejorado
- Configuración de Starship más estable y sin warnings
- Script genera configuración limpia y válida por defecto
- Mejor manejo de caracteres especiales en formatos de Starship

---

## [1.2.3] - 2025-01-09
### Corregido
- Errores de sintaxis en configuración de Starship (schema, format, kubernetes)
- Módulos custom problemáticos deshabilitados por defecto (custom_public_ip, custom_weather)
- Format vacío en prompt principal y right_format
- Error de sintaxis en formato de kubernetes con caracteres especiales
- Warnings de Starship que causaban problemas en el prompt

### Mejorado
- Configuración de Starship más estable y sin warnings
- Script genera configuración limpia y válida por defecto
- Mejor manejo de caracteres especiales en formatos de Starship

---

## [1.2.2] - 2025-01-09
### Corregido
- Funciones duplicadas en .zshrc que causaban terminal colgada o sin prompt
- Filtrado automático de funciones del usuario para evitar conflictos con funciones base del script
- Mejorada la extracción de funciones para manejar correctamente llaves anidadas
- Eliminación de módulos custom problemáticos de Starship (custom_public_ip, custom_weather)

### Mejorado
- Script más robusto que evita generar duplicados en la configuración
- Mejor manejo de funciones complejas con múltiples llaves
- Validación mejorada de sintaxis antes de aplicar cambios

---

## [1.2.1] - 2025-01-08
### Corregido
- Error de instalación de plugins de Zsh con mensajes "Read-only file system" y "No such file or directory"
- Configuración de Starship con claves duplicadas que causaba errores de parsing TOML
- Variables hardcodeadas en el script que causaban problemas de expansión
- Mejorado el manejo de errores en la instalación de plugins con validaciones adicionales

### Mejorado
- Agregadas validaciones para verificar que el directorio de plugins existe y es escribible
- Logs más detallados para debugging de problemas de instalación
- Detección automática y corrección de problemas comunes en la configuración
- Documentación actualizada con soluciones para problemas conocidos

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
# Migrador de Oh My Zsh a Starship para Mac

Este script automatiza la migración de una configuración de Oh My Zsh a un entorno moderno con Zsh puro, Starship, plugins y herramientas de línea de comandos mejoradas. Es seguro, multiplataforma (cualquier Mac) y apto para usuarios avanzados y principiantes.

## Características principales
- Migración automática y segura (con backup y rollback)
- Instalación de Starship, plugins y herramientas modernas (`eza`, `bat`, `fd`, `fzf`, `ripgrep`)
- Compatible con cualquier Mac (Intel o Apple Silicon)
- Reporte detallado del estado de la migración y entorno
- Logs claros y manejo robusto de errores
- Seguro para usuarios avanzados y principiantes

## Requisitos
- **macOS** (cualquier versión moderna)
- **Homebrew** instalado ([instrucciones](https://brew.sh/))

## Instalación y uso rápido
1. Descarga el script `zsh_starship_migration.sh` en tu Mac.
2. Dale permisos de ejecución:
   ```sh
   chmod +x zsh_starship_migration.sh
   ```
3. Ejecuta la migración:
   ```sh
   ./zsh_starship_migration.sh
   ```

## Opciones y comandos disponibles
- `./zsh_starship_migration.sh`           → Ejecuta la migración automática
- `./zsh_starship_migration.sh rollback`  → Restaura el backup anterior
- `./zsh_starship_migration.sh report`    → Muestra un reporte detallado del entorno
- `./zsh_starship_migration.sh status`    → Estado actual de la configuración
- `./zsh_starship_migration.sh --help`    → Ayuda y opciones
- `./zsh_starship_migration.sh --dry-run` → Simula la migración sin hacer cambios
- `./zsh_starship_migration.sh --verbose` → Modo detallado para depuración
- `./zsh_starship_migration.sh --skip-tools` → Migra solo el prompt y plugins, sin instalar herramientas modernas

## Ejemplo de uso
```sh
# Migrar tu entorno actual
./zsh_starship_migration.sh

# Ver el estado de la migración
./zsh_starship_migration.sh report

# Revertir la migración
./zsh_starship_migration.sh rollback
```

## ¿Qué hace el script?
- Valida tu sistema y dependencias
- Crea un backup seguro de tu configuración actual
- Extrae alias, exports y funciones personales
- Instala Starship, plugins y herramientas modernas
- Genera un nuevo `.zshrc` y `starship.toml` personalizados
- Permite rollback y muestra reportes claros

## Advertencias
- **Requiere Homebrew**. Si no lo tienes, instálalo primero desde [brew.sh](https://brew.sh/).
- El script es seguro: nunca borra tu configuración sin hacer backup.
- Si tienes funciones muy complejas en tu `.zshrc`, el script las migrará, pero revisa el resultado si tienes personalizaciones avanzadas.

## Personalización
Puedes modificar el script para añadir tus propios plugins, alias o herramientas. El código es claro y modular.

---

¿Dudas, sugerencias o mejoras? ¡Contribuye o contacta al autor! 
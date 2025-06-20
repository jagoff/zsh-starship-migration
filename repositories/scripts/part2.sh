main() {
    init_gamification
    detect_platform
    # Parseo de argumentos. Un bucle `while` con `case` es el patrón más
    # robusto y extensible en shell para manejar argumentos.
    local command=""
    local command_args=()
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --skip-tools)
                SKIP_TOOLS=true
                shift
                ;;
            help|-h|--help)
                show_help
                exit 0
                ;;
            rollback|status|report|diagnose|save-profile|load-profile|list-profiles|export-profile|import-profile|sync-git|security-check)
                if [[ -n "$command" ]]; then
                    log_error "Solo se puede especificar un comando a la vez."
                    exit 1
                fi
                command=$1
                shift
                # Collect all remaining arguments for this command
                while [[ $# -gt 0 && "$1" != -* ]]; do
                    command_args+=("$1")
                    shift
                done
                ;;
            -*) # Captura cualquier otra opción no reconocida
                log_error "Opción no reconocida: $1"
                show_help
                exit 1
                ;;
            *) # Captura argumentos que no son opciones
                if [[ -z "$command" ]]; then
                    # Si no hay comando, esto es un error.
                    log_error "Comando no reconocido: $1"
                    show_help
                    exit 1
                else
                    # Si ya hay un comando, es un argumento extra no esperado.
                    log_error "Argumento inesperado: $1 para el comando '$command'"
                    exit 1
                fi
                ;;
        esac
    done

    # Modo verbose para el dry-run
    if [[ "$DRY_RUN" = true ]]; then
        # Activar verbose en dry-run es útil para ver qué se haría.
        VERBOSE=true
        set +e  # <--- PATCH: Disable exit on error in dry-run mode
        log_info "Modo DRY-RUN activado. No se realizarán cambios."
    fi

    # Ejecutar el comando principal
    case $command in
        rollback)
            rollback_migration
            add_gamification_xp 10
            unlock_achievement "Rollback realizado"
            ;;
        status)
            show_status
            show_gamification_status
            add_gamification_xp 2
            ;;
        report)
            generate_report
            diagnose_environment
            security_check
            add_gamification_xp 2
            ;;
        diagnose)
            diagnose_environment
            add_gamification_xp 3
            unlock_achievement "Diagnóstico ejecutado"
            ;;
        save-profile)
            log_verbose "Command: $command"
            log_verbose "Command args count: ${#command_args[@]}"
            log_verbose "Command args: ${command_args[*]}"
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar un nombre para el perfil."
                show_help
                exit 1
            fi
            save_configuration_profile "${command_args[1]}"
            add_gamification_xp 5
            unlock_achievement "Perfil guardado"
            ;;
        load-profile)
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar un nombre de perfil."
                show_help
                exit 1
            fi
            load_configuration_profile "${command_args[1]}"
            add_gamification_xp 5
            unlock_achievement "Perfil cargado"
            ;;
        list-profiles)
            list_configuration_profiles
            add_gamification_xp 1
            ;;
        export-profile)
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar un nombre de perfil."
                show_help
                exit 1
            fi
            export_configuration "${command_args[1]}" "${command_args[2]:-}"
            add_gamification_xp 5
            unlock_achievement "Perfil exportado"
            ;;
        import-profile)
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar la ruta del archivo a importar."
                show_help
                exit 1
            fi
            import_configuration "${command_args[1]}" "${command_args[2]:-}"
            add_gamification_xp 5
            unlock_achievement "Perfil importado"
            ;;
        sync-git)
            if [[ ${#command_args} -eq 0 ]]; then
                log_error "Debe especificar la URL del repositorio Git."
                show_help
                exit 1
            fi
            sync_configuration_with_git "${command_args[1]}"
            add_gamification_xp 10
            unlock_achievement "Sync Git"
            ;;
        security-check)
            security_check
            add_gamification_xp 5
            unlock_achievement "Seguridad verificada"
            ;;
        "") # Comando por defecto: migración
            # Paso 1: Selección de plugins de Zsh
            select_zsh_plugins
            # Paso 2: Selección de features/configuraciones de Starship
            select_starship_features
            
            log_info "🚀 Iniciando migración de Oh My Zsh a Starship..."
            local MIGRATION_OK=true
            local BACKUP_OK=false
            local ANALYZE_OK=false
            local INSTALL_OK=false
            local CONFIG_OK=false
            local VALIDATION_OK=false
            
            validate_system || MIGRATION_OK=false
            validate_platform || MIGRATION_OK=false
            install_platform_dependencies || log_warn "Algunas dependencias de plataforma no se pudieron instalar"
            log_info "Creando backup..."
            create_backup && BACKUP_OK=true || log_error "Backup fallido"
            log_info "Analizando configuración..."
            analyze_config && ANALYZE_OK=true || log_error "Análisis fallido"
            log_info "[DEBUG] Llamando a install_dependencies..."
            log_info "Instalando dependencias..."
            install_dependencies && INSTALL_OK=true || log_error "Fallo en dependencias"
            log_info "Generando nueva configuración..."
            generate_new_config && CONFIG_OK=true || log_error "Fallo en configuración"
            post_migration_validation && VALIDATION_OK=true || VALIDATION_OK=false
            # Resumen final
            echo -e "\n${C_BLUE}Resumen de la migración:${C_NC}"
            [[ "$BACKUP_OK" = true ]] && echo -e "  ✅ Backup creado" || echo -e "  ❌ Backup fallido"
            [[ "$ANALYZE_OK" = true ]] && echo -e "  ✅ Análisis de configuración OK" || echo -e "  ❌ Análisis fallido"
            [[ "$INSTALL_OK" = true ]] && echo -e "  ✅ Dependencias instaladas" || echo -e "  ❌ Fallo en dependencias"
            [[ "$CONFIG_OK" = true ]] && echo -e "  ✅ Configuración generada" || echo -e "  ❌ Fallo en configuración"
            [[ "$VALIDATION_OK" = true ]] && echo -e "  ✅ Validación post-migración OK" || echo -e "  ❌ Validación post-migración con errores"
            if [[ "$BACKUP_OK" = true && "$ANALYZE_OK" = true && "$INSTALL_OK" = true && "$CONFIG_OK" = true && "$VALIDATION_OK" = true ]]; then
                echo -e "\n${C_GREEN}🎉 ¡Migración completada con éxito!${C_NC}"
                echo -e "   - Backup creado en: ${C_YELLOW}${MIGRATION_BACKUP_PATH}${C_NC}"
                echo -e "   - Para revertir, ejecuta: ${C_YELLOW}./migrate.sh rollback${C_NC}"
                echo -e "   - ${C_BLUE}Por favor, reinicia tu terminal o ejecuta 'source ~/.zshrc' para ver los cambios.${C_NC}"
                add_gamification_xp 20
                unlock_achievement "Migración completada"
            else
                echo -e "\n${C_RED}❌ La migración no se completó correctamente. Revisa los mensajes anteriores para más detalles.${C_NC}"
            fi
            ;;
    esac
}

# --- EJECUCIÓN DEL SCRIPT ---
# Llama a la función 'main' pasándole todos los argumentos que recibió el script.
# La construcción `"$@"` expande cada argumento como una cadena separada,
# preservando espacios si los hubiera, lo que es crucial para un parseo correcto.
main "$@"

# --- DETECCIÓN MULTIPLATAFORMA ---
    esac
}

# --- INTEGRAR EN MAIN ---
# (Busca el bloque del main y agrega la detección de plataforma al inicio)

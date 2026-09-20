---
name: godot-prolijidad
description: Guia operativa para mantener este proyecto Godot limpio, modular y testeado en cada cambio.
---

# Objetivo

Mantener el codigo de este repo prolijo y estable: cambios chicos, servicios dedicados, tipado explicito y suite verde.

# Reglas obligatorias

1. No hacer refactors masivos de una sola vez. Separar en lotes pequenos y verificables.
2. Antes de tocar una funcion larga en main.gd o save_manager.gd, extraer logica pura a un servicio nuevo en res://.
3. Mantener comportamiento existente: priorizar wrappers/delegacion en vez de reescritura completa.
4. En GDScript, usar tipos explicitos cuando haya inferencia dudosa o warning potencial.
5. No mezclar cambios de UI visual con cambios de reglas de juego en el mismo commit.
6. Si agregas archivo de servicio, agregar al menos un test unitario dedicado.
7. Si tocas flujos de partida (checkpoint, wildcard, slots, economia), correr toda la suite.
8. Nunca dejar el proyecto con errores de parseo o scripts sin cargar.
9. Evitar dependencias ciclicas entre servicios; los servicios deben ser puros o casi puros.
10. Si un cambio no es seguro, introducir feature wrappers y migrar llamadas gradualmente.

# Zonas de alta sensibilidad

- main.gd: input, resolucion de turno, overlays, layout HUD.
- save_manager.gd: persistencia y sincronizacion con GameState.
- game_engine.gd / game_rules.gd: reglas base y progresion.

# Patron recomendado

1. Identificar bloque espagueti (alta mezcla de responsabilidades).
2. Crear servicio con API chica y testeable.
3. Redirigir una sola funcion al servicio.
4. Agregar test del servicio.
5. Correr tests.
6. Repetir.

# Definicion de listo (DoD)

- Servicio nuevo con nombre claro y responsabilidad unica.
- Uso real del servicio desde caller principal.
- Tests nuevos o ajustados pasando.
- tests/run_all_tests.sh finaliza con "All tests passed.".
- Sin warnings/errores nuevos en los archivos tocados.

# Comandos de validacion

- bash tests/run_all_tests.sh
- Revisar que no haya "Failed to load script" en salida.

# Convenciones de extraccion en este repo

- Servicios de flujo: *_flow_service.gd
- Servicios de layout/hud: *_layout_service.gd
- Servicios de persistencia: *_repository.gd o *_adapter.gd
- Helpers de UI: *_builder.gd o *_theme_service.gd

# Nota de compatibilidad

Mantener ASCII por defecto en nuevos archivos/cambios tecnicos cuando sea posible.

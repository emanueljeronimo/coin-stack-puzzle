# Coin Stack Puzzle

## Validacion local rapida

- Ejecutar suite completa:

```bash
bash tests/run_all_tests.sh
```

- Criterio de exito:
  - El script termina con `All tests passed.`
  - No debe aparecer `Failed to load script` para los tests del proyecto.

## Pre-push gate (opcional, recomendado)

1. Dar permisos al hook:

```bash
chmod +x .githooks/pre-push
```

2. Activar hooks versionados del repo:

```bash
git config core.hooksPath .githooks
```

Desde ese momento, cada `git push` corre automaticamente la suite.

## Notas de test/headless

- El audio de tablero se omite en modo headless para evitar ruido de import durante pruebas.
- El bridge MCP en `addons/godot_mcp` se deja parseable para no romper el arranque en test.

## Guia de prolijidad

- Skill del repo: [.github/skills/godot-prolijidad/SKILL.md](.github/skills/godot-prolijidad/SKILL.md)

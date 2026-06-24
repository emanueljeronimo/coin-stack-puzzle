# TODO LIST — COIN STACK PUZZLE

## 1. CORE DATA STRUCTURES
### 1.1 Moneda
- [ ] Crear clase/estructura Moneda
  - Definir propiedad: valor (int)
  - Definir getter/setter
  - Asegurar validación de valores positivos

### 1.2 Pila (Stack)
- [ ] Crear clase Pila
  - Implementar estructura LIFO
  - Definir capacidad máxima (10)
  - Métodos:
    - push(moneda)
    - pop()
    - peek()
    - isEmpty()
    - isFull()
  - Método para detectar estado:
    - vacía
    - mixta
    - homogénea
    - completa

### 1.3 Tablero
- [ ] Crear clase Tablero
  - Definir grilla (3x5 = 15 slots)
  - Manejar slots habilitados vs bloqueados
  - Métodos:
    - obtener pilas disponibles
    - verificar espacio global
    - desbloquear ranura

---

## 2. SISTEMA DE MOVIMIENTO
### 2.1 Movimiento individual
- [ ] Implementar validación:
  - origen no vacío
  - destino no lleno
  - destino vacío o mismo valor
- [ ] Ejecutar movimiento

### 2.2 Movimiento de bloque
- [ ] Detectar bloque homogéneo en el tope
- [ ] Validar espacio en destino
- [ ] Manejar overflow parcial
- [ ] Transferir múltiples monedas

---

## 3. SISTEMA DE FUSIÓN
- [ ] Detectar pila completa homogénea
- [ ] Reemplazar 10 monedas por 1 de valor+1
- [ ] Implementar fusión automática
- [ ] Implementar fusión en cadena (loop hasta que no haya más)

---

## 4. SISTEMA DE NIVEL
- [ ] Crear sistema de niveles
  - valor máximo actual
- [ ] Detectar condición de subida de nivel
- [ ] Persistir tablero
- [ ] Actualizar valor máximo
- [ ] Habilitar nuevos valores en tirada

---

## 5. SISTEMA DE RANURAS
- [ ] Inicializar 5 slots activos
- [ ] Implementar desbloqueo automático (cada 2 niveles)
- [ ] Implementar compra:
  - temporal
  - permanente

---

## 6. SISTEMA DE TIRADA
- [ ] Generar monedas aleatorias
  - dentro del rango permitido
  - excluir valor máximo
- [ ] Insertar monedas en pilas aleatorias
- [ ] Validar espacio disponible
- [ ] Detectar fin de vida si no hay espacio
- [ ] Trigger de fusiones post-inserción

---

## 7. SISTEMA DE ESTADO DEL JUEGO
- [ ] Detectar:
  - en progreso
  - bloqueado
  - ganado
- [ ] Verificar movimientos posibles
- [ ] Implementar lógica de bloqueo

---

## 8. SISTEMA DE VIDAS
- [ ] Implementar contador de vidas (max 5)
- [ ] Restar vida al perder
- [ ] Timer de regeneración (30 min)
- [ ] Compra de vidas con diamantes
- [ ] Checkpoint de nivel

---

## 9. SISTEMA ECONÓMICO
- [ ] Crear sistema de diamantes
- [ ] Implementar ganancias:
  - subir nivel
  - bonus diario
- [ ] Implementar gastos:
  - comodines
  - ranuras
  - vidas

---

## 10. BONUS DIARIO
- [ ] Sistema de login diario
- [ ] Progresión secuencial
- [ ] Integrar recompensas
- [ ] Integrar anuncios (stub)

---

## 11. COMODINES
### 11.1 Implementar
- [ ] Vaciar ranura
- [ ] Reordenar tablero

### 11.2 Pendientes
- [ ] Definir comodines día 3 y 4

---

## 12. PRESTIGE
- [ ] Detectar condición de prestige
- [ ] Resetear tablero
- [ ] Mantener valores altos
- [ ] Ajustar dificultad

---

## 13. EDGE CASES
- [ ] Validar movimientos inválidos
- [ ] Manejar overflow
- [ ] Manejar tirada sin espacio
- [ ] Validar fusiones automáticas
- [ ] Manejar bloqueo del juego

---

## 14. LOOP PRINCIPAL
- [ ] Implementar game loop:
  - analizar tablero
  - input jugador
  - validar acción
  - aplicar cambios
  - verificar fusiones
  - evaluar estado
  - repetir

---

## 15. BALANCE Y AJUSTES
- [ ] Ajustar probabilidades de tirada
- [ ] Ajustar economía
- [ ] Ajustar dificultad progresiva
- [ ] Playtesting

---

## 16. UI / UX (SI APLICA)
- [ ] Render de tablero
- [ ] Animaciones de movimiento
- [ ] Animaciones de fusión
- [ ] Feedback visual de errores
- [ ] UI de vidas, monedas, nivel

---

## 17. SONIDO (OPCIONAL)
- [ ] Efectos de movimiento
- [ ] Efectos de fusión
- [ ] Feedback de error

---

## 18. DEBUG Y HERRAMIENTAS
- [ ] Logs de estado
- [ ] Herramientas de testing rápido
- [ ] Simulación de tiradas

---

FIN

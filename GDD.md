🧩 COIN STACK PUZZLE
Game Design Document
v1.0 — 2025



1. Concepto General
Juego de puzzle móvil donde el jugador organiza monedas numeradas en pilas (columnas). El objetivo es agrupar monedas del mismo valor para generar fusiones que las convierten en monedas de mayor valor, liberando espacio y habilitando nuevas combinaciones.

El desafío combina tres pilares:
Gestión del espacio
Planificación de movimientos
Optimización de fusiones

Inspiración: combina la mecánica de clasificación de puzzles de ordenamiento con la fusión progresiva del estilo 2048.




2. Entidades del Sistema
2.1 Moneda
Propiedad
Descripción
Valor
Entero positivo (1, 2, 3, …)
Comportamiento
Solo se interactúa con la moneda superior de cada pila


2.2 Pila (Columna)
Propiedad
Descripción
Estructura
Stack (LIFO)
Capacidad máxima
10 monedas fijo (no cambia nunca)
Estados posibles
Vacía / Mixta / Homogénea / Completa


2.3 Tablero
Propiedad
Descripción
Ranuras totales
15 (3 filas × 5 columnas) — a confirmar con playtest
Ranuras iniciales
5 habilitadas al comenzar
Ranuras bloqueadas
Visibles con candado y precio en diamantes




3. Estados del Sistema
3.1 Estados de una Pila
Estado
Descripción
Vacía
No tiene monedas
Mixta
Tiene monedas de distintos valores
Homogénea
Todas las monedas tienen el mismo valor
Completa
Homogénea + llena (lista para fusión automática)


3.2 Estados del Juego
Estado
Descripción
En progreso
El jugador puede realizar acciones
Ganado (nivel)
Se completó la pila con el valor máximo del nivel actual
Bloqueado
No hay movimientos válidos posibles




4. Acciones del Jugador
4.1 Mover Moneda Individual
Condiciones para que el movimiento sea válido:
La pila origen no está vacía
La pila destino no está llena
El destino está vacío, O la moneda superior del destino tiene el mismo valor

4.2 Mover Bloque Homogéneo
Permite mover varias monedas juntas cuando el tope de la pila origen forma una secuencia de igual valor.
Se mueve el bloque completo
El destino debe estar vacío, o tener el mismo valor en el tope
Debe haber espacio suficiente en el destino
Si no entra el bloque completo, se mueven solo las necesarias para completar la pila destino

Ejemplo de overflow: Pila A tiene [1,1,2,2], Pila B tiene [2,2,2]. Solo se puede mover un 2 de A a B para completarla.




5. Sistema de Fusión
5.1 Condición de Fusión
Una fusión ocurre automáticamente cuando una pila está completa (homogénea y llena de 10 monedas del mismo valor).

Resultado: [X, X, X, X, X, X, X, X, X, X] → [X+1]


5.2 Fusión en Cadena
Si al fusionarse se genera una moneda que completa otra pila, la fusión ocurre automáticamente también. Las cadenas son automáticas e instantáneas.

5.3 El Valor Máximo NO sale de la Tirada
El valor máximo del nivel actual solo se puede obtener por fusión, nunca por la tirada aleatoria. Una vez que se sube al siguiente nivel, ese valor pasa a estar disponible en la tirada.

Ejemplo: En el nivel donde el máximo es 5, el 5 no aparece en la tirada. Cuando se sube al nivel siguiente (máximo 6), el 5 comienza a aparecer en la tirada pero el 6 no.




6. Progresión de Niveles
6.1 Condición de Subida de Nivel (Micro-loop)
Se sube de nivel cuando se completa una pila entera con el valor máximo del nivel actual, generando una fusión en el valor siguiente.
El tablero persiste entre niveles (no se reinicia)
La moneda recién generada queda en el tablero como moneda jugable normal
El nuevo valor máximo pasa a ser el objetivo del siguiente nivel

Ejemplo: Nivel 1 tiene monedas 1-5. Al completar una pila de 5s, se fusiona en un 6. Arranca el Nivel 2. El 6 queda en el tablero y ahora hay que completar una pila de 6s para subir al Nivel 3.


6.2 Desbloqueo de Ranuras
Método
Descripción
Automático
Una ranura nueva cada 2 niveles (a ajustar con playtest)
Manual (temporal)
Compra con 250 💎, duración a definir
Manual (permanente)
Compra con 600 💎


6.3 Prestige (Macro-loop)
Cuando se completa la pila del valor equivalente a la cantidad máxima de ranuras (ej: 15 ranuras → completar pila de 14s → se genera un 15):
El tablero se vacía
Se vuelve a 5 ranuras habilitadas
Los números NO se reinician (se continúa con valores altos)
Una tirada inicial automática puebla el tablero
Cada prestige es más difícil: las ranuras se desbloquean más lento (cada 3 niveles, luego cada 4, etc.)

Ejemplo: Después del primer prestige, el tablero empieza con monedas de valor 9-13 en 5 ranuras.




7. Tirada de Monedas
7.1 Activación
Usable en cualquier momento durante la partida
Sin costo y sin límite de usos
Si el tablero se llena completamente y no hay espacio → fin de vida

7.2 Generación de Monedas
Se detectan los valores presentes en el nivel actual
Se generan monedas aleatoriamente dentro de ese rango
El valor máximo del nivel NUNCA aparece en la tirada
La distribución busca un mix entre lo que el jugador necesita y azar puro (a afinar con playtest)

7.3 Inserción
Las monedas se insertan en pilas elegidas aleatoriamente
Pueden caer en pilas vacías o con monedas (aunque no coincidan en valor)
No todas las pilas tienen que recibir monedas
Si una pila está llena, no recibe monedas
Si no hay espacio en ninguna pila para una moneda → fin de vida



8. Sistema de Vidas
Parámetro
Valor
Máximo de vidas
5
Pérdida de vida
El tablero se llena sin espacio disponible
Recarga automática
1 vida cada 30 minutos
Recarga full (compra)
300 💎 para reponer las 5 vidas
Checkpoint
Inicio del último nivel alcanzado


Vidas ilimitadas temporales (bonus diario día 5): durante 15 minutos el jugador puede usar más de 5 vidas. Al terminar el tiempo, las vidas quedan en 5.




9. Sistema Económico (Diamantes 💎)
9.1 Fuentes de Diamantes
Fuente
Cantidad
Subir de nivel
X 💎 (a definir)
Bonus diario día 1
25 💎 gratis
Bonus diario día 2
25 💎 viendo publicidad
Compra real
Paquetes a definir


9.2 Gastos
Item
Precio
Comodín
100 💎
Ranura temporal
250 💎
Ranura permanente
600 💎
Reponer 5 vidas
300 💎


9.3 Bonus Diario (Cadena Secuencial)
Se reinicia cada 24 hs. Para desbloquear un paso hay que completar el anterior.

Día
Recompensa
Requisito
1
25 💎
Gratis (solo loguearse)
2
25 💎
Ver 1 publicidad
3
Comodín (a definir)
Ver 1 publicidad
4
Comodín (a definir)
Ver 1 publicidad
5
15 min vidas ilimitadas
Ver 1 publicidad




10. Comodines
10.1 Comodines Definidos
Comodín
Efecto
Vaciar ranura
El jugador elige una pila y se eliminan todas sus monedas
Reordenar tablero
Todas las monedas del tablero se reordenan automáticamente por valor


10.2 Comodines Pendientes de Definir
Comodín del bonus día 3 (a definir)
Comodín del bonus día 4 (a definir)
Otros comodines a explorar en playtest



11. Edge Cases
Caso
Comportamiento
Movimiento inválido
Pila origen vacía, destino lleno, o valores incompatibles → no se permite
Pila parcialmente homogénea
Solo se puede mover el bloque del tope. Ej: [1,1,2,2] → solo se mueven los 2s del tope
Overflow de pila
Si el bloque no entra completo, se mueven solo las monedas necesarias para completar el destino
Fusión en cadena
Automática e instantánea cuando la fusión genera una nueva fusión posible
Bloqueo del juego
No hay movimientos válidos → el jugador puede usar tirada, comodín, o deshacer
Tirada sin espacio
Si no hay lugar para ninguna moneda → fin de vida → checkpoint en inicio del nivel
Fusión al generar monedas
Si la tirada completa una pila → fusión automática




12. Loop de Gameplay
Analizar tablero
Ejecutar movimiento (o tirada)
Validar acción
Aplicar fusión automática si corresponde
Re-evaluar estado del juego
¿Bloqueado? → usar tirada / comodín / deshacer
¿Nivel completado? → subir nivel, persistir tablero
¿Prestige alcanzado? → vaciar tablero, tirada inicial, aumentar dificultad
Repetir



13. Escalado de Dificultad
Etapa
Características
🟢 Early Game
Pocos valores (1-5), muchas ranuras disponibles, baja densidad
🟡 Mid Game
Más valores, menos espacio libre, requiere planificación
🔴 Late Game
Muchos valores, alta densidad, uso clave de tiradas y comodines
⚡ Post-Prestige
Mismos parámetros pero desbloqueo de ranuras más lento (cada 3-4 niveles)




14. Pendientes y A Definir
Cantidad exacta de diamantes ganados por nivel
Comodines del bonus diario día 3 y día 4
Precio de paquetes de diamantes (compra real)
Algoritmo exacto de bias de la tirada (útil vs caos)
Confirmar 15 ranuras totales con playtest
Ritmo de desbloqueo en prestige 2, 3, etc.
Definir si el comodín 'vaciar ranura' elimina o solo desplaza las monedas

— fin del documento —

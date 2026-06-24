# UI DESIGN SPEC – JUEGO DE FICHAS 

## CONTEXTO GENERAL

Quiero implementar una interfaz de usuario mobile (vertical) para un juego de puzzle basado en pilas de fichas numeradas.

El estilo visual debe ser:

* Relajante / zen
* Minimalista pero cálido
* Inspirado en naturaleza (verde, hojas, luz suave)
* Bordes redondeados en TODOS los elementos
* Sombras suaves (no duras)
* Sin colores saturados

Resolución base:

* 1080x1920 (vertical)
* Adaptable a diferentes aspect ratios

---

## 1. FONDO (BACKGROUND)

### Descripción:

* Imagen tipo ilustración suave
* Camino de bosque con perspectiva hacia el centro
* Luz difusa en el centro (blanco/amarillo muy suave)
* Bordes con hojas verdes desenfocadas
* Detalles:

  * Piedras pequeñas
  * Flores blancas
  * Vegetación en esquinas inferiores
* Estilo: painterly / acuarela digital

### Reglas:

* Debe tener un degradado natural hacia el centro para mejorar legibilidad
* NO usar patrones repetitivos
* NO usar alto contraste

---

## 2. CONTENEDOR PRINCIPAL (GAME BOARD PANEL)

### Descripción:

* Caja central donde está el juego
* Color: crema / verde muy claro
* Bordes:

  * Border radius grande (20–30px)
* Sombra:

  * Muy suave, tipo elevación leve
* Padding interno amplio

### Layout:

* Centrado horizontal
* Ocupa ~70% de la altura de la pantalla

---

## 3. HEADER SUPERIOR (TOP BAR)

### Contenido:

Distribución horizontal:

#### 3.1 Botón Home

* Icono de casa
* Botón circular
* Fondo blanco con sombra suave

#### 3.2 Vidas

* Icono: corazón rojo
* Texto: "5 Lleno"
* Estilo cápsula (pill)
* Fondo blanco

#### 3.3 Gemas

* Icono: diamante violeta
* Texto: "756"
* Botón "+" pequeño al lado
* Fondo blanco

#### 3.4 Configuración

* Icono de engranaje
* Botón circular

---

## 4. PROGRESO DE NIVEL

### Elementos:

* Número: "233"
* Barra de progreso
* Texto: "25%"

### Diseño:

* Barra horizontal
* Color verde suave
* Fondo gris claro
* Thumb/indicador redondeado

---

## 5. FILA DE SLOTS SUPERIORES (LOCKS / BOOSTERS)

### Estructura:

Fila horizontal de slots rectangulares

#### Tipos:

1. Slot activo (verde):

   * Número (ej: 236)
   * Icono de candado abierto
   * Costo: "600" con icono de gema

2. Slots bloqueados:

   * Icono de candado
   * Color gris claro

3. Slot de tiempo:

   * Icono reloj de arena
   * Texto: "60 seg"

---

## 6. AREA DE JUEGO (FICHAS)

### Layout:

* Grid de columnas
* Cada columna = stack vertical de fichas

### Fichas:

* Forma: cilindro/apiladas
* Colores:

  * Gris (86)
  * Violeta (90)
  * Verde (89)
  * Azul (88)
  * Rojo (83)
  * Celeste (88)
  * Naranja (85)
  * Amarillo (87)
  * Beige (84)

### Estilo:

* Sombreado suave
* Ligero efecto 3D (pero no realista)
* Número centrado

### Interacción visual:

* Una pila seleccionada tiene un highlight suave
* Puede tener base resaltada (indicador de selección)

---

## 7. BOTÓN PRINCIPAL (CTA – REPARTIR)

### Diseño:

* Botón grande centrado abajo
* Texto: "Repartir"
* Color: verde suave
* Bordes redondeados (muy alto radius)
* Sombra leve

### Importancia:

* Elemento más destacado de la UI
* Debe ser fácilmente clickeable

---

## 8. BOTONES INFERIORES (BOOSTERS)

### Layout:

Fila horizontal de 3 botones:

#### 8.1 Mezclar

* Icono de shuffle
* Botón circular
* Texto debajo

#### 8.2 Martillo

* Icono martillo

#### 8.3 Guante

* Icono mano

### Extra:

* Cada botón tiene un pequeño "+" verde
* Indica que se puede comprar o aumentar

---

## 9. ESTILO VISUAL GLOBAL

### Colores:

* Paleta pastel:

  * Verde claro dominante
  * Blancos cálidos
  * Grises suaves

### Sombras:

* Muy suaves
* Blur alto
* Baja opacidad

### Bordes:

* TODOS redondeados
* Nada sharp

### Animaciones (IMPORTANTE):

* Transiciones suaves (ease-in-out)
* Nada brusco
* Duración media (0.2–0.4s)

---

## 10. JERARQUÍA VISUAL

Orden de importancia:

1. Botón "Repartir"
2. Área de fichas
3. Progreso
4. Recursos (vidas/gemas)
5. Boosters

---

## 11. REGLAS UX

* Todo debe ser claro sin texto explicativo
* Iconos universales
* Feedback visual inmediato al interactuar
* Evitar saturación visual

---

## 12. IMPLEMENTACIÓN EN GODOT (SUGERIDO)

### Nodos:

* Control (root)

  * TextureRect (background)
  * VBoxContainer (main layout)

    * HBoxContainer (top bar)
    * ProgressBar
    * HBoxContainer (slots)
    * GridContainer (fichas)
    * Button (Repartir)
    * HBoxContainer (boosters)

---

## OBJETIVO FINAL

Crear una UI que:

* Sea relajante visualmente
* Invite a jugar sin estrés
* Sea clara e intuitiva
* Tenga estética premium tipo juego mobile moderno

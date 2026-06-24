# 🎮 GDScript Cheat Sheet - Guía Completa para Godot

## 📋 Índice
1. Sintaxis Básica
2. Variables y Tipos de Datos
3. Funciones del Ciclo de Vida
4. Control de Flujo
5. Funciones y Métodos
6. Nodos y Escenas
7. Input (Entrada del Usuario)
8. Física y Colisiones
9. Señales (Signals)
10. Arrays y Diccionarios
11. Vectores y Matemáticas
12. Recursos Útiles

---

## 1️⃣ Sintaxis Básica

```gdscript
# Comentarios con #
extends Node2D  # Herencia de clase

# Variables
var nombre = "Jugador"
var vida: int = 100
const VELOCIDAD = 200
@export var puntos = 0  # Editable en el inspector

# Tipado estático (recomendado)
var posicion: Vector2 = Vector2.ZERO
var enemigos: Array[Node] = []
```

---

## 2️⃣ Variables y Tipos de Datos

### Tipos Básicos
```gdscript
var entero: int = 42
var decimal: float = 3.14
var texto: String = "Hola"
var booleano: bool = true
var nulo = null
```

### Tipos de Godot
```gdscript
var vector2: Vector2 = Vector2(100, 200)
var vector3: Vector3 = Vector3(1, 2, 3)
var color: Color = Color.RED
var nodo: Node = null
```

### Constantes Útiles
```gdscript
Vector2.ZERO        # (0, 0)
Vector2.ONE         # (1, 1)
Vector2.UP          # (0, -1)
Vector2.DOWN        # (0, 1)
Vector2.LEFT        # (-1, 0)
Vector2.RIGHT       # (1, 0)
```

---

## 3️⃣ Funciones del Ciclo de Vida

```gdscript
# Se ejecuta al crear el nodo
func _init():
    print("Inicializando")

# Se ejecuta cuando entra al árbol de escenas
func _ready():
    print("Listo!")

# Se ejecuta cada frame
func _process(delta):
    # delta = tiempo desde el último frame
    position.x += 100 * delta

# Se ejecuta cada frame de física (60 FPS)
func _physics_process(delta):
    # Ideal para movimiento y física
    move_and_slide()

# Input sin procesar
func _input(event):
    if event is InputEventKey:
        print("Tecla presionada")

# Input con prioridad
func _unhandled_input(event):
    pass
```

---

## 4️⃣ Control de Flujo

### Condicionales
```gdscript
if vida > 50:
    print("Saludable")
elif vida > 0:
    print("Herido")
else:
    print("Muerto")

# Operador ternario
var estado = "Vivo" if vida > 0 else "Muerto"

# Match (como switch)
match arma:
    "espada":
        danio = 10
    "arco":
        danio = 5
    _:  # default
        danio = 1
```

### Bucles
```gdscript
# For
for i in 10:
    print(i)  # 0 a 9

for i in range(5, 10):
    print(i)  # 5 a 9

for enemigo in enemigos:
    enemigo.recibir_danio(10)

# While
while vida > 0:
    jugar()
```

---

## 5️⃣ Funciones y Métodos

```gdscript
# Función básica
func saludar():
    print("Hola")

# Con parámetros
func atacar(objetivo: Node, danio: int):
    objetivo.vida -= danio

# Con retorno
func calcular_distancia(punto: Vector2) -> float:
    return position.distance_to(punto)

# Con valor por defecto
func curar(cantidad: int = 20):
    vida += cantidad

# Función estática
static func suma(a: int, b: int) -> int:
    return a + b
```

---

## 6️⃣ Nodos y Escenas

### Obtener Nodos
```gdscript
# Por ruta
var jugador = $Jugador
var sprite = $Jugador/Sprite2D
var hijo = get_node("HijoNodo")

# Por nombre
var nodo = get_node_or_null("NombreNodo")

# Padre
var padre = get_parent()

# Hijos
var hijos = get_children()
for hijo in hijos:
    print(hijo.name)

# Buscar en el árbol
var nodo = get_tree().root.find_child("NombreNodo", true, false)
```

### Manipular Nodos
```gdscript
# Añadir hijo
var nuevo = Node2D.new()
add_child(nuevo)

# Instanciar escena
var escena = preload("res://enemigo.tscn")
var instancia = escena.instantiate()
add_child(instancia)

# Eliminar
queue_free()  # Al final del frame
remove_child(hijo)  # Eliminar hijo

# Duplicar
var copia = duplicate()
```

---

## 7️⃣ Input (Entrada del Usuario)

### Método 1: _input()
```gdscript
func _input(event):
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_SPACE:
            saltar()
    
    if event is InputEventMouseButton and event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            disparar()
```

### Método 2: Input.is_action_pressed()
```gdscript
func _process(delta):
    # Configurar en Project > Project Settings > Input Map
    if Input.is_action_pressed("ui_right"):
        position.x += velocidad * delta
    
    if Input.is_action_just_pressed("saltar"):
        saltar()
    
    if Input.is_action_just_released("disparar"):
        disparar()
```

### Input de Movimiento
```gdscript
func _physics_process(delta):
    var direccion = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    velocity = direccion * VELOCIDAD
    move_and_slide()
```

---

## 8️⃣ Física y Colisiones

### CharacterBody2D
```gdscript
extends CharacterBody2D

const VELOCIDAD = 200.0
const SALTO = -400.0
var gravedad = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta):
    # Gravedad
    if not is_on_floor():
        velocity.y += gravedad * delta
    
    # Salto
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = SALTO
    
    # Movimiento horizontal
    var direccion = Input.get_axis("ui_left", "ui_right")
    velocity.x = direccion * VELOCIDAD
    
    move_and_slide()
```

### Detectar Colisiones
```gdscript
# CharacterBody2D
for i in get_slide_collision_count():
    var colision = get_slide_collision(i)
    var colisionador = colision.get_collider()
    print("Chocó con: ", colisionador.name)

# Area2D con señales
func _ready():
    body_entered.connect(_on_body_entered)

func _on_body_entered(body):
    if body.name == "Jugador":
        print("Jugador entró al área")
```

### RayCast2D
```gdscript
@onready var raycast = $RayCast2D

func _process(delta):
    if raycast.is_colliding():
        var colisionador = raycast.get_collider()
        print("Ray detectó: ", colisionador.name)
```

---

## 9️⃣ Señales (Signals)

### Crear y Emitir
```gdscript
# Definir señal
signal vida_cambio(nueva_vida)
signal jugador_murio

# Emitir señal
func recibir_danio(cantidad):
    vida -= cantidad
    vida_cambio.emit(vida)
    
    if vida <= 0:
        jugador_murio.emit()
```

### Conectar Señales
```gdscript
# Método 1: Por código
func _ready():
    $Jugador.vida_cambio.connect(_on_vida_cambio)
    $Boton.pressed.connect(_on_boton_presionado)

func _on_vida_cambio(nueva_vida):
    print("Vida: ", nueva_vida)

func _on_boton_presionado():
    print("Botón clickeado")

# Método 2: Editor
# Click derecho en nodo > Conectar señal
```

---

## 🔟 Arrays y Diccionarios

### Arrays
```gdscript
var frutas = ["manzana", "banana", "naranja"]
var numeros: Array[int] = [1, 2, 3, 4, 5]

# Agregar
frutas.append("uva")
frutas.push_back("pera")

# Acceder
print(frutas[0])  # "manzana"

# Iterar
for fruta in frutas:
    print(fruta)

# Métodos útiles
frutas.size()           # Tamaño
frutas.has("banana")    # Contiene
frutas.erase("banana")  # Eliminar
frutas.clear()          # Vaciar
frutas.pop_back()       # Eliminar último
```

### Diccionarios
```gdscript
var jugador = {
    "nombre": "Hero",
    "vida": 100,
    "nivel": 5
}

# Acceder
print(jugador["nombre"])
print(jugador.vida)  # Sintaxis alternativa

# Modificar
jugador["vida"] = 80
jugador.nivel += 1

# Agregar
jugador["mana"] = 50

# Verificar
if "vida" in jugador:
    print("Tiene vida")

# Iterar
for clave in jugador:
    print(clave, ": ", jugador[clave])
```

---

## 1️⃣1️⃣ Vectores y Matemáticas

### Vector2
```gdscript
var pos = Vector2(100, 200)

# Operaciones
pos += Vector2(10, 0)
pos *= 2
var normalizado = pos.normalized()  # Longitud 1
var longitud = pos.length()

# Distancia
var distancia = pos.distance_to(objetivo_pos)

# Dirección
var direccion = (objetivo_pos - pos).normalized()

# Lerp (interpolación)
pos = pos.lerp(objetivo_pos, 0.1)

# Ángulo
var angulo = pos.angle()  # En radianes
```

### Funciones Matemáticas
```gdscript
# Básicas
abs(-5)         # 5
min(3, 7)       # 3
max(3, 7)       # 7
clamp(15, 0, 10)  # 10 (limita entre 0 y 10)

# Redondeo
floor(3.7)      # 3
ceil(3.2)       # 4
round(3.5)      # 4

# Interpolación
lerp(0, 100, 0.5)  # 50
move_toward(10, 20, 3)  # 13

# Aleatorio
randi()                    # Entero aleatorio
randf()                    # Float 0.0 a 1.0
randi_range(1, 6)         # Dado (1-6)
randf_range(0.0, 10.0)    # Float entre 0 y 10
```

---

## 1️⃣2️⃣ Trucos y Consejos

### Temporizadores
```gdscript
# Crear temporizador
var timer = Timer.new()
add_child(timer)
timer.wait_time = 2.0
timer.timeout.connect(_on_timer_timeout)
timer.start()

func _on_timer_timeout():
    print("¡Tiempo!")

# Alternativa con await
await get_tree().create_timer(2.0).timeout
print("2 segundos después")
```

### Cambiar Escenas
```gdscript
# Cambiar escena
get_tree().change_scene_to_file("res://nivel2.tscn")

# Reiniciar escena actual
get_tree().reload_current_scene()

# Pausar juego
get_tree().paused = true
```

### Debug
```gdscript
print("Mensaje simple")
print_debug("Con info de línea")
printerr("Error en rojo")
push_warning("Advertencia amarilla")

# Dibujar en pantalla (para debug)
func _draw():
    draw_circle(Vector2.ZERO, 50, Color.RED)
    draw_line(Vector2.ZERO, Vector2(100, 100), Color.BLUE, 2.0)
```

### Optimización
```gdscript
# @onready para referencias (más eficiente)
@onready var sprite = $Sprite2D
@onready var timer = $Timer

# Preload (carga al compilar)
const ENEMIGO = preload("res://enemigo.tscn")

# Load (carga al ejecutar)
var escena = load("res://nivel.tscn")
```

---

## 🎯 Plantilla de Script Completa

```gdscript
extends CharacterBody2D

# Constantes
const VELOCIDAD = 200
const SALTO = -400

# Variables exportadas
@export var vida_maxima: int = 100
@export var danio_ataque: int = 10

# Variables
var vida: int
var en_aire: bool = false

# Referencias a nodos
@onready var sprite = $Sprite2D
@onready var animacion = $AnimationPlayer

# Señales
signal vida_cambio(nueva_vida)
signal murio

func _ready():
    vida = vida_maxima
    conectar_senales()

func _physics_process(delta):
    aplicar_gravedad(delta)
    manejar_input()
    move_and_slide()
    actualizar_animacion()

func aplicar_gravedad(delta):
    if not is_on_floor():
        velocity.y += get_gravity().y * delta

func manejar_input():
    # Salto
    if Input.is_action_just_pressed("saltar") and is_on_floor():
        velocity.y = SALTO
    
    # Movimiento
    var direccion = Input.get_axis("izquierda", "derecha")
    velocity.x = direccion * VELOCIDAD

func actualizar_animacion():
    if velocity.x != 0:
        animacion.play("correr")
        sprite.flip_h = velocity.x < 0
    else:
        animacion.play("idle")

func recibir_danio(cantidad: int):
    vida -= cantidad
    vida_cambio.emit(vida)
    
    if vida <= 0:
        morir()

func morir():
    murio.emit()
    queue_free()

func conectar_senales():
    pass
```

---

## 📚 Recursos y Referencias

**Documentación Oficial:**
- https://docs.godotengine.org/es/stable/

**Shortcuts del Editor:**
- F1: Buscar ayuda
- F5: Ejecutar proyecto
- F6: Ejecutar escena actual
- Ctrl+S: Guardar
- Ctrl+Shift+S: Guardar todo

**Comunidad:**
- Reddit: r/godot
- Discord: Godot Engine
- YouTube: GDQuest, Brackeys, HeartBeast

---

💡 **Tips Finales:**
- Usa tipado estático para evitar errores
- Comenta tu código complejo
- Usa @onready para referencias a nodos
- Practica con proyectos pequeños
- Lee la documentación oficial

¡Buena suerte con tu juego! 🎮✨
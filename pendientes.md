Estado del proyecto CoinStackPuzzle — Godot 4.6.1
Configuración inicial

Proyecto creado en Godot 4.6.1 con renderer Mobile
Tamaño de pantalla: 1080 x 1920 (vertical, móvil)
Stretch Mode: canvas_items

Archivos creados
coin.tscn + coin.gd

Nodo raíz: Area2D llamado Coin
Hijos: Sprite2D (imagen custom) + Label + CollisionShape2D
El Label tiene size 180x180 y position -90,-90 para centrarse
Script actual:

gdscriptextends Area2D

var value: int = 1

@onready var label = $Label

func _ready() -> void:
    if label:
        update_display()
    else:
        print("ERROR: No se encontró el Label en coin.tscn")

func update_display() -> void:
    if label:
        label.text = str(value)

func set_value(new_value: int) -> void:
    value = new_value
    update_display()
stack.tscn + stack.gd

Nodo raíz: Node2D llamado Stack
Hijos: Sprite2D (imagen custom)
Tiene un ColorRect gris (80x150) creado por código para visualizar la pila
Las monedas se apilan verticalmente con scale = Vector2(0.3, 0.3)
Script actual:

gdscriptextends Node2D

const MAX_CAPACITY = 10
const CoinScene = preload("res://coin.tscn")

var coins: Array = []
var coin_nodes: Array = []

func _ready() -> void:
    var rect = ColorRect.new()
    rect.size = Vector2(80, 150)
    rect.color = Color.DARK_GRAY
    add_child(rect)

func is_empty() -> bool:
    return coins.size() == 0

func is_full() -> bool:
    return coins.size() >= MAX_CAPACITY

func top_value() -> int:
    if is_empty():
        return -1
    return coins[-1]

func top_block_size() -> int:
    if is_empty():
        return 0
    var top = coins[-1]
    var count = 0
    for i in range(coins.size() - 1, -1, -1):
        if coins[i] == top:
            count += 1
        else:
            break
    return count

func is_homogeneous() -> bool:
    if is_empty():
        return false
    var top = coins[0]
    for c in coins:
        if c != top:
            return false
    return true

func is_ready_to_fuse() -> bool:
    return is_full() and is_homogeneous()


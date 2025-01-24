extends CharacterBody2D

@export var cell_size: int = 16  # Tamanho da célula em pixels
var target_position: Vector2  # Posição-alvo em pixels
var is_moving: bool = false  # Indica se o jogador está se movendo

@onready var raycast = $RayCast2D

func _ready():
	# Define a posição inicial como uma célula do grid
	target_position = position.snapped(Vector2(cell_size, cell_size))






func _process(delta):
	# Atualiza a posição atual para o alvo gradualmente
	if is_moving:
		position = position.move_toward(target_position, cell_size * delta * 10)  # Velocidade ajustável
		if position.distance_to(target_position) < 0.1:
			position = target_position  # Alinha ao alvo
			is_moving = false

func _input(event):
	# Processa entrada do jogador
	if event is InputEventKey and event.pressed and not is_moving:
		var direction = Vector2.ZERO

		# Checar teclas para definir direção
		if event.is_action_pressed("ui_up"):  # Cima
			direction = Vector2(0, -1)
		elif event.is_action_pressed("ui_down"):  # Baixo
			direction = Vector2(0, 1)
		elif event.is_action_pressed("ui_left"):  # Esquerda
			direction = Vector2(-1, 0)
		elif event.is_action_pressed("ui_right"):  # Direita
			direction = Vector2(1, 0)

		# Define a nova posição-alvo no grid
		if direction != Vector2.ZERO:
			var new_target = target_position + direction * cell_size
			# Verifica limites do grid (adicione sua lógica aqui)
			if can_move_to(new_target, direction):
				target_position = new_target
				is_moving = true
				
				

func can_move_to(position: Vector2, direction: Vector2) -> bool:
	# Ajusta o RayCast2D para verificar na direção do movimento
	raycast.enabled = true
	raycast.target_position = direction * cell_size
	raycast.force_raycast_update()

	# Retorna falso se o RayCast2D detectar uma colisão com um TileMap no grupo "Wall"
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("Wall"):
			return false

	return true

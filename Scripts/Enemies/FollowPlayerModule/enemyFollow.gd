extends CharacterBody2D

@export var speed: float = 2000


@onready var player: Node2D = get_parent().get_node("Player")
@onready var navigationAgent : NavigationAgent2D = get_node("NavigationAgent2D")

# Vamos controlar o "estado" do inimigo:
var canCalc : bool = true
var state: String = "IDLE"
var wait_timer: float = 0.0

func _physics_process(delta: float) -> void:
	# Sempre define o target para a posição atual do Player,
	# para que o NavigationAgent2D calcule a rota interna.
	actor_setup()
	print(navigationAgent.velocity)
	print(state)
	match state:
		"IDLE":
			if !navigationAgent.is_navigation_finished():
				state = "MOVE"
			else:
				velocity = Vector2.ZERO
				# Continua em IDLE caso não haja caminho disponível

		"MOVE":
			# Se já não há mais pontos no caminho, voltamos para IDLE.
			if navigationAgent.is_navigation_finished():
				navigationAgent.velocity = Vector2.ZERO
				state = "IDLE"
			else:
				if(navigationAgent.is_target_reachable()):
					# Caminha em direção ao cell_target
					var dir =  navigationAgent.get_next_path_position() - global_position
					velocity = dir.normalized() * 20
					move_and_slide()
func actor_setup():
	await(get_tree().physics_frame)
	if(canCalc):
		navigationAgent.target_position = player.global_position
		canCalc = false
		await(get_tree().create_timer(1.0).timeout)
		canCalc = true

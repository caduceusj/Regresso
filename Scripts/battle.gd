extends Control

signal turnFinished

@export var enemyInfo : Resource
@export var playerInfo : Resource
@export var skillInfoAux : Resource



@onready var skillButton  = preload("res://Cenas/Prefab/skill_button.tscn")
@onready var skillContainer = get_node("Panel/SkillContainer")
@onready var feedback = get_node("Panel/Feedback")

var playerTurn : bool = true

var feedbackText : String = ""

@onready var enemyController = get_node("Minimax")

var enemyDEF : int
var enemyATK : int
var enemyAGL : int
var enemyHP : int
var enemyDefending : bool = false
var enemyBuffArray : Array[int] = [1,1,1]



var playerDEF : int
var playerATK : int
var playerAGL : int
var playerHP : int
var playerDefending : bool = false
var playerBuffArray : Array[int] = [1,1,1]


func _ready() -> void:
	loadPlayer()
	loadEnemy()
	initializePlayerButtons()
	turnController(true)





func turnController(turn):
	if(playerHP > 0 and enemyHP > 0):
		if(turn == true):
			await(turnFinished)
			turn = false
			turnController(turn)
		else:
			enemyController.enemyTurn()
			await(turnFinished)
			turn = true
			turnController(turn)
	elif(playerHP <= 0):
		feedbackText = "O "+ enemyInfo.name + " venceu"
		get_tree().change_scene_to_file("res://Cenas/world.tscn")
	else:
		feedbackText = "Olhe só "+playerInfo.name + "venceu"
		get_tree().change_scene_to_file("res://Cenas/world.tscn")

func _physics_process(delta: float) -> void:
	if(feedbackText != ""):
		feedback.text = feedbackText
		feedbackText = ""
		skillContainer.hide()
		await(get_tree().create_timer(3.0).timeout)
		feedback.text = ""
		emit_signal("turnFinished")
		skillContainer.show()
		




func loadPlayer():
	playerDEF = playerInfo.DEF
	playerATK = playerInfo.ATK
	playerAGL = playerInfo.AGL
	playerHP = playerInfo.HP

func loadEnemy():
	enemyDEF = enemyInfo.DEF
	enemyATK = enemyInfo.ATK
	enemyAGL = enemyInfo.AGL
	enemyHP = enemyInfo.HP

func initializePlayerButtons():
	for x in playerInfo.skillList.size():
		#INSTANCIAR BOTÕES
		var prefabAux = skillButton.instantiate()
		prefabAux.text = playerInfo.skillList[x]
		prefabAux.pressed.connect(self.skillSelected.bind(playerInfo.skillList[x]))
		skillContainer.add_child(prefabAux)
	pass


func skillSelected(extra_arg : String = ""):
	if(extra_arg == ""):
		pass
	else:
		print(extra_arg)
		Global.useSkill("player", "enemy", extra_arg)


func hitTarget(entityDamaging, entityDamaged, subtractor: int = 0) -> bool:
	# Ajuste nos cálculos de chance de acerto
	var damaging_agl = get(str(entityDamaging) + "AGL")
	var damaging_buff = get(str(entityDamaging) + "BuffArray")[2]  # Buff de agilidade
	var damaged_agl = get(str(entityDamaged) + "AGL")
	var damaged_buff = get(str(entityDamaged) + "BuffArray")[2]  # Buff de agilidade

	# Calculando a chance de acerto
	var hitChance: float = (
		6 + (damaging_agl * damaging_buff * 0.3) - subtractor
	) - (damaged_agl * damaged_buff * 0.3)

	# Evitar valores muito baixos ou altos de chance
	hitChance = clamp(hitChance, 0, 10)

	randomize()
	var hitOverall = randf_range(0, 10)
	if hitOverall <= hitChance:
		print("Attack connected!")
		return true
	else:
		print("Attack missed!")
		return false

func dealDamage(entityDamaging, entityDamaged, statScale: String = "ATK", attackMultiplier: float = 1.0):
	# Obter os atributos relevantes
	var damaging_atk = get(str(entityDamaging) + str(statScale))  # Força de ataque
	var damaging_buff = get(str(entityDamaging) + "BuffArray")[0]  # Buff de ataque
	var damaged_def = get(str(entityDamaged) + "DEF")  # Defesa
	var damaged_buff = get(str(entityDamaged) + "BuffArray")[1]  # Buff de defesa

	# Cálculo de dano ajustado para Goblins ou inimigos fracos
	var dealtDamage: float = (
		1 + (damaging_atk * damaging_buff * attackMultiplier) - ((damaged_def * damaged_buff) / 2)
	)
	# Certificar que o dano mínimo é sempre 1
	if dealtDamage <= 0:
		dealtDamage = 1

	# Aplicar dano reduzido se o alvo estiver defendendo
	if get(str(entityDamaged) + "Defending"):
		set(str(entityDamaged) + "HP", get(str(entityDamaged) + "HP") - int(dealtDamage / 2))
		print(get(str(entityDamaged) + "Info").name + " HP (Defending): " + str(get(str(entityDamaged) + "HP")))
		set(str(entityDamaged) + "Defending", false)
	else:
		set(str(entityDamaged) + "HP", get(str(entityDamaged) + "HP") - int(dealtDamage))
		print(get(str(entityDamaged) + "Info").name + " HP: " + str(get(str(entityDamaged) + "HP")))

	# Animação de dano
	if entityDamaged == "enemy":
		$AnimationPlayer.play("RivalDamage")
	else:
		$AnimationPlayer.play("PlayerDamaged")

func buffSkill(entity, stat, value):
	# Atualiza um buff específico no array de buffs
	get(str(entity) + "BuffArray")[stat] = value
	print("Buff atualizado para", str(entity), ": ", str(stat), " => ", str(value))

func guard(entity):
	# Ativa a defesa para reduzir dano no próximo ataque
	set(str(entity) + "Defending", true)
	print(str(entity) + " está defendendo!")

func killBuffs(entity):
	# Remove todos os buffs do alvo
	set(str(entity) + "BuffArray", [1, 1, 1])
	print("Todos os buffs de", str(entity), "foram removidos!")

# Função para calcular o dano baseado nos atributos e buffs
func calculateDamage(entityDamaging: String, entityDamaged: String, statScale: String = "ATK", attackMultiplier: float = 1.0) -> int:
	# Obter atributos e buffs relevantes
	var damaging_atk = get(str(entityDamaging) + str(statScale))  # Força de ataque do atacante
	var damaging_buff = get(str(entityDamaging) + "BuffArray")[0]  # Buff de ataque do atacante
	var damaged_def = get(str(entityDamaged) + "DEF")  # Defesa do alvo
	var damaged_buff = get(str(entityDamaged) + "BuffArray")[1]  # Buff de defesa do alvo

	# Calcular o dano base
	var dealtDamage: float = (
		1 + (damaging_atk * damaging_buff * attackMultiplier) - ((damaged_def * damaged_buff) / 2)
	)

	# Garante que o dano mínimo seja 1
	if dealtDamage <= 0:
		dealtDamage = 1

	return int(dealtDamage)

extends Node

@export var DEPTH_LEVEL: int = 3  # Profundidade para Minimax
@export var ENEMY_RESOURCE: Resource  # Recurso do inimigo

@onready var bn = get_node("/root/Battle")  # Nó de batalha

var SURPLUS: int = 0
var lastAction: String = ""

# Estado inicial do inimigo e jogador será atualizado dinamicamente
var enemyState = {}
var playerState = {}

func _ready() -> void:
	# Inicializa os estados do inimigo e jogador a partir do nó de batalha
	update_states()

# Atualiza os estados do inimigo e do jogador a partir do nó de batalha
func update_states():
	enemyState = {
		"HP": bn.enemyHP,
		"buffs": bn.enemyBuffArray,
		"defending": bn.enemyDefending
	}
	playerState = {
		"HP": bn.playerHP,
		"buffs": bn.playerBuffArray,
		"defending": bn.playerDefending
	}

# Executa o ataque escolhendo a melhor ação
func enemyTurn():
	update_states()  # Atualiza os estados antes de tomar uma decisão
	var bestAction = choose_best_action(enemyState, playerState, DEPTH_LEVEL)  # Escolhe a melhor ação
	executeAction(bestAction)

# Executa a ação escolhida
func executeAction(action: String):
	Global.useSkill("enemy","player",action)

	lastAction = action  # Atualiza a última ação realizada


# Avaliação do estado atual
func evaluate_state(enemyHP, playerHP, enemyBuffs, playerBuffs, enemyDefending, playerDefending) -> float:
	var score = 0.0

	# 1. Diferença de HP (prioriza manter a vantagem)
	score += (enemyHP - playerHP) * 0.7  # Aumenta o peso da diferença de HP para encorajar decisões agressivas

	# 2. Buffs do inimigo e penalização de buffs do jogador
	# Buff de ataque: Prioriza ataques se o inimigo tiver buffs suficientes
	score += (enemyBuffs[0] - playerBuffs[0]) * 10  # Buff de ataque mais relevante
	score += (enemyBuffs[1] - playerBuffs[1]) * 7   # Buff de defesa ajuda em situações prolongadas
	score += (enemyBuffs[2] - playerBuffs[2]) * 5   # Buff de agilidade ajuda a atingir alvos

	# 3. Penalidades e vantagens baseadas em HP
	if enemyHP < 30:
		if playerHP > 50:
			score -= 25  # Enfatiza a defesa se o inimigo estiver em risco e o jogador em vantagem
		else:
			score += 5  # Encoraja atacar mesmo em vida baixa se o jogador estiver vulnerável
	if playerHP < 30:
		score += 20  # Prioriza finalizar o jogador com vida baixa

	# 4. Condição de defesa
	if enemyDefending:
		if enemyHP > 50:
			score -= 10  # Penaliza a defesa em situações em que o inimigo está saudável
		else:
			score += 5  # Permite defesa se o inimigo estiver em risco
	if playerDefending:
		score += 10  # Incentiva buffs ou ataques quando o jogador se defende

	# 5. Incentivar buffs em momentos oportunos
	if enemyBuffs[0] < 2:  # Buff de ataque baixo
		score += 15  # Prioriza Buff ATK para maximizar o dano futuro
	if enemyBuffs[1] < 2 and enemyHP < 50:  # Buff de defesa e vida baixa
		score += 10  # Prioriza Buff DEF em situações de risco
	if enemyBuffs[2] < 2:  # Buff de agilidade baixo
		score += 8  # Prioriza Buff AGL para aumentar chance de esquiva

	# 6. Restrições para evitar valores extremos
	return clamp(score, -50, 50)


# Gerar todas as ações possíveis
func generate_actions() -> Array:
	return ["Attack", "Buff ATK", "Buff DEF", "Buff AGL", "killBuffs", "Defend"]

# Simula o resultado de uma ação específica
# Avaliar o resultado de uma ação específica
func simulate_action(action: String, enemyState: Dictionary, playerState: Dictionary) -> Dictionary:
	# Copiar os estados para evitar alterações nos originais
	var newEnemyState = enemyState.duplicate(true)
	var newPlayerState = playerState.duplicate(true)

	match action:
		"Attack":
			# Calcula o dano ao jogador
			if bn.hitTarget("enemy", "player"):
				var damage = bn.calculateDamage("enemy", "player")
				newPlayerState["HP"] -= damage
		"Buff ATK":
			newEnemyState["buffs"][0] += 1  # Incrementa o buff de ataque
		"Buff DEF":
			newEnemyState["buffs"][1] += 1  # Incrementa o buff de defesa
		"Buff AGL":
			newEnemyState["buffs"][2] += 1  # Incrementa o buff de agilidade
		"killBuffs":
			newPlayerState["buffs"] = [1, 1, 1]  # Remove os buffs do jogador
		"Defend":
			newEnemyState["defending"] = true  # Ativa a defesa para o inimigo

	return {"enemy": newEnemyState, "player": newPlayerState}

# Minimax com poda alfa-beta
func minimax(enemyState, playerState, depth: int, maximizingPlayer: bool, alpha: float, beta: float) -> float:
	if depth == 0 or enemyState["HP"] <= 0 or playerState["HP"] <= 0:
		return evaluate_state(
			enemyState["HP"], playerState["HP"],
			enemyState["buffs"], playerState["buffs"],
			enemyState["defending"], playerState["defending"]
		)

	if maximizingPlayer:
		var maxEval = -INF
		for action in generate_actions():
			var simulated = simulate_action(action, enemyState, playerState)
			var eval = minimax(simulated["enemy"], simulated["player"], depth - 1, false, alpha, beta)
			maxEval = max(maxEval, eval)
			alpha = max(alpha, eval)
			if beta <= alpha:
				break
		return maxEval
	else:
		var minEval = INF
		for action in generate_actions():
			var simulated = simulate_action(action, enemyState, playerState)
			var eval = minimax(simulated["enemy"], simulated["player"], depth - 1, true, alpha, beta)
			minEval = min(minEval, eval)
			beta = min(beta, eval)
			if beta <= alpha:
				break
		return minEval

# Escolhe a melhor ação para o inimigo
func choose_best_action(enemyState, playerState, depth: int) -> String:
	var bestAction = ""
	var bestScore = -INF

	for action in generate_actions():
		var simulated = simulate_action(action, enemyState, playerState)
		var score = minimax(simulated["enemy"], simulated["player"], depth - 1, false, -INF, INF)
		if score > bestScore:
			bestScore = score
			bestAction = action

	print("Melhor ação:", bestAction, "com pontuação:", bestScore)
	return bestAction

extends Node

var battleNode
func useSkill(caster : String = "player", target : String = "enemy" , spellName : String = ""):
	print(spellName)
	battleNode = get_node("/root/Battle")
	if(spellName == ""):
		pass
	else:
		if(spellName == "Attack"):
			
			print(battleNode.name)
			if(battleNode.hitTarget(caster, target) == true):
				battleNode.dealDamage(caster, target)
				battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " atacou " + battleNode.get(str(target)+"Info").name + " e sucedeu"
			else:
				get_node("/root/Battle/Minimax").SURPLUS += 7
				battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " tentou atacar " + battleNode.get(str(target)+"Info").name + " mas falhou."
		elif(spellName == "Defend"):
			battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " se prepara para defender um ataque "
			battleNode.guard(caster)
		elif(spellName == "Slash"):
			print(battleNode.name)
			if(battleNode.hitTarget(caster, target, -1) == true):
				battleNode.dealDamage(caster, target, "ATK", 1.5)
				battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " fez um corte em " + battleNode.get(str(target)+"Info").name + " e sucedeu"
			else:
				get_node("/root/Battle/Minimax").SURPLUS += 7
				battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " tentou cortar " + battleNode.get(str(target)+"Info").name + " mas falhou."
		elif(spellName == "Buff ATK"):
			battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " Carrega um ataque "
			battleNode.buffSkill(caster, 1, 2)
		elif(spellName == "Buff AGL"):
			battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " Se sente mais ágil "
			battleNode.buffSkill(caster, 2, 2)
		elif(spellName == "Buff DEF"):
			battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " Fortifica seu corpo "
			battleNode.buffSkill(caster, 0, 2)
		elif(spellName == "Buff ALL"):
			pass
		elif(spellName == "killBuffs"):
			battleNode.feedbackText = battleNode.get(str(caster)+"Info").name + " retira as fortificações de  " + battleNode.get(str(target)+"Info").name
			battleNode.killBuffs(target)

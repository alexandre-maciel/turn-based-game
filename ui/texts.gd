class_name Texts
extends RefCounted
## Todos os textos visíveis ao jogador ficam aqui (facilita traduzir depois).

const LOAD_ERROR := "Erro ao carregar personagem"
const CHAT_TEXT := "[Sistema] Bem-vindo a Eldoria!\n[Mundo] O chat chegará em breve."
const PANEL_TITLE := "Personagem"
const SECTION_ATTRIBUTES := "Atributos"
const SECTION_COMBAT := "Combate"
const HP := "HP"
const XP := "XP"

const TRAINING_TITLE := "Campo de Treino"
const FIGHT := "Lutar"
const ENEMIES_LOAD_ERROR := "Erro ao carregar inimigos"
const FLED := "Você fugiu do combate"
const CRITICAL := "CRÍTICO!"
const VICTORY := "Vitória!"
const DEFEAT := "Derrota"
const DEFEAT_TEXT := "Você foi derrotado. Treine e tente de novo."
const BACK_TO_CITY := "Voltar à cidade"

const BATTLE_ACTIONS := {
	"attack": "Atacar",
	"defend": "Defender",
	"flee": "Fugir",
}

const SKILLS := {"fireball": "Bola de Fogo"}

const CLASS_LABELS := {"mage": "Mago"}

const BUILDINGS := {
	"castle": "Castelo",
	"tower": "Torre",
	"blacksmith": "Ferreiro",
	"market": "Mercado",
	"arena": "Arena",
	"training": "Treino",
}

const MENU := {
	"character": "Personagem",
	"bag": "Mochila",
	"skills": "Habilidades",
	"quests": "Missões",
	"guild": "Guilda",
	"settings": "Config",
}

const ATTRIBUTES := {
	"strength": "Força",
	"agility": "Agilidade",
	"intelligence": "Inteligência",
	"vitality": "Vitalidade",
}

const COMBAT_STATS := {
	"attack": "Ataque",
	"defense": "Defesa",
	"crit_chance": "Crítico",
	"speed": "Velocidade",
}

const SLOTS := {
	"helmet": "Elmo",
	"armor": "Armadura",
	"boots": "Botas",
	"necklace": "Colar",
	"ring": "Anel",
	"cape": "Capa",
	"weapon": "Arma",
	"shield": "Escudo",
}


static func coming_soon(display_name: String) -> String:
	return "%s — em breve" % display_name


static func class_label(hero_class: String) -> String:
	return CLASS_LABELS.get(hero_class, hero_class)


static func class_and_level(hero_class: String, level: int) -> String:
	return "%s · Nível %d" % [class_label(hero_class), level]


static func short_level(level: int) -> String:
	return "Nv %d" % level


static func fraction(current: int, maximum: int) -> String:
	return "%d / %d" % [current, maximum]


## 4.0 → "4%", 4.5 → "4,5%".
static func percent(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d%%" % roundi(value)
	return ("%.1f%%" % value).replace(".", ",")


## 1234567 → "1.234.567".
static func thousands(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	while digits.length() > 3:
		grouped = "." + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped


## "+20 XP · +15 ouro"
static func rewards(xp: int, gold: int) -> String:
	return "%s · %s" % [xp_gain(xp), gold_gain(gold)]


static func xp_gain(xp: int) -> String:
	return "+%s XP" % thousands(xp)


static func gold_gain(gold: int) -> String:
	return "+%s ouro" % thousands(gold)


static func level_up(level: int) -> String:
	return "Subiu para o nível %d!" % level


static func battle_round(number: int) -> String:
	return "Rodada %d" % number


## "Bola de Fogo" ou, em recarga, "Bola de Fogo (2)".
static func skill_button(skill_id: String, cooldown: int) -> String:
	var skill_name: String = SKILLS.get(skill_id, skill_id)
	return skill_name if cooldown == 0 else "%s (%d)" % [skill_name, cooldown]


static func damage_popup(amount: int, critical: bool) -> String:
	return ("%s\n-%d" % [CRITICAL, amount]) if critical else "-%d" % amount


## Linha do registro do combate para um evento.
static func battle_log(event: BattleEvent, skill_id: String) -> String:
	var actor := event.actor.combatant_name
	match event.kind:
		BattleEvent.Kind.HIT:
			var target := event.target.combatant_name
			var line := "%s ataca %s: %d de dano." % [actor, target, event.damage]
			if event.skill:
				line = "%s usa %s em %s: %d de dano." % [actor, SKILLS.get(skill_id, skill_id), target, event.damage]
			return ("Crítico! " + line) if event.critical else line
		BattleEvent.Kind.DEFEND:
			return "%s se defende." % actor
		BattleEvent.Kind.FLEE:
			return "%s foge do combate." % actor
		BattleEvent.Kind.DEFEATED:
			return "%s foi derrotado!" % actor
	return ""

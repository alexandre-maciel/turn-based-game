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

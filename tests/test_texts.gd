extends BaseTest
## Formatação de textos exibidos ao jogador.


func test_coming_soon() -> void:
	assert_eq(Texts.coming_soon("Torre"), "Torre — em breve")


func test_class_and_level() -> void:
	assert_eq(Texts.class_and_level("mage", 1), "Mago · Nível 1")
	assert_eq(Texts.short_level(7), "Nv 7")


func test_unknown_class_label_falls_back_to_id() -> void:
	assert_eq(Texts.class_label("druid"), "druid")


func test_fraction() -> void:
	assert_eq(Texts.fraction(35, 100), "35 / 100")


func test_percent_hides_zero_decimal_and_uses_comma() -> void:
	assert_eq(Texts.percent(4.0), "4%")
	assert_eq(Texts.percent(4.5), "4,5%")
	assert_eq(Texts.percent(0.0), "0%")


func test_thousands_separator() -> void:
	assert_eq(Texts.thousands(0), "0")
	assert_eq(Texts.thousands(20), "20")
	assert_eq(Texts.thousands(1250), "1.250")
	assert_eq(Texts.thousands(1234567), "1.234.567")
	assert_eq(Texts.thousands(-1250), "-1.250")


func test_six_buildings_without_tavern() -> void:
	assert_eq(Texts.BUILDINGS.keys(), ["castle", "tower", "blacksmith", "market", "arena", "training"])
	assert_eq(Texts.BUILDINGS["tower"], "Torre")

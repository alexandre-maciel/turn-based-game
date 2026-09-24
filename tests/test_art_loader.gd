extends BaseTest
## Arte opcional: null quando o arquivo não existe.


func test_missing_file_returns_null() -> void:
	assert_true(ArtLoader.texture_or_null("res://assets/nao_existe.png") == null)


func test_existing_image_returns_texture() -> void:
	var texture := ArtLoader.texture_or_null("res://tests/fixtures/pixel.svg")
	assert_true(texture != null, "o fixture pixel.svg deveria carregar")
	assert_true(texture is Texture2D)

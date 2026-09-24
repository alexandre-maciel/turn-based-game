class_name ArtLoader
extends RefCounted
## Carrega arte opcional de assets/. Se o arquivo não existir, devolve null e o
## componente desenha seu placeholder. Arte nova: coloque o PNG com o nome da
## lista (assets/README.md) e abra o projeto no editor uma vez para importar.


static func texture_or_null(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

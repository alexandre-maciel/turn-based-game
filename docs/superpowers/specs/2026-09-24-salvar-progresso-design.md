# Salvar o progresso (design)

**Data:** 2026-09-24
**Engine:** Godot 4.7.2
**Depende de:** combate por turnos (`2026-09-24-combate-por-turnos-design.md`)
**Status:** aprovado e implementado

### Desvios na implementação
- No lugar do sinal `notice(message)`: `GameState.save_failed(error)` e `GameState.load_warning` (texto do último carregamento). O `main.gd` escolhe o texto do Toast, então o `GameState` não depende de `Texts`. O aviso de save danificado é lido pelo `main.gd` no `_ready()`, porque o `GameState` carrega antes de a cena existir.
- Proteção dos testes: em vez de o executor trocar o repositório, o próprio `GameState` escolhe o padrão. Quando o `SceneTree` tem script (rodando por `--script`: testes e `tools/screenshot.gd`), usa `LocalHeroRepository`, só leitura. Assim o save de verdade nem chega a ser lido.
- `LocalHeroRepository.parse_player(root, source)` virou público para o `SaveGameRepository` reaproveitar a validação.
- Se o save danificado não puder ser renomeado, o carregamento falha (tela de erro) em vez de começar um jogo novo, para nunca gravar por cima do único exemplar.

## 1. Objetivo

Hoje o XP, o ouro e o nível ganhos no Treino somem quando o jogo fecha. Com esta mudança, o jogo grava o jogador num arquivo local e o carrega ao abrir.

**Critério de sucesso:** o jogador vence o Rato Gigante, fecha o jogo e abre de novo. O HUD mostra o XP e o ouro de antes. Na primeira vez que o jogo abre, sem arquivo salvo, começa com o Aldric de exemplo. Os testes nunca tocam no save de verdade.

### Decisões propostas (revisar)
| Tema | Proposta | Motivo |
|---|---|---|
| Quando salvar | **Automático**, logo depois de cada mudança no jogador (hoje: fim de combate) | Não existe botão de salvar para esquecer; como toda mudança já passa pelo `GameState`, o gancho é um só |
| Onde | `user://save.json` (no Windows: `%APPDATA%\Godot\app_userdata\Primeiro Jogo\save.json`) | Pasta própria do Godot para dados do usuário; funciona no export Web também |
| Formato | O mesmo JSON do `sample_hero.json` + `"version": 1` | O validador que já existe lê o save; `version` permite migrar o formato no futuro |
| Primeira vez (sem save) | Começa um jogo novo a partir de `res://data/sample_hero.json` | O herói fixo continua sendo o ponto de partida |
| Save corrompido | Renomeia para `save.corrompido-<data>.json`, começa um jogo novo e avisa com o Toast | Nada se perde (o arquivo fica guardado) e o jogador não fica preso na tela de erro |
| Falha ao gravar | Toast "Não foi possível salvar o progresso"; o jogo continua | Disco cheio ou sem permissão não pode derrubar o jogo |
| Gravação segura | Grava em `save.json.tmp` e depois troca pelo `save.json` | Se o jogo fechar no meio da gravação, o save anterior continua inteiro |
| Um só save | Sem vários slots | Existe um herói só; slots entram com a criação de personagem |

### Fora do escopo
Vários slots, botão "Novo jogo" (o botão Config continua "em breve"; para recomeçar, apague o arquivo), salvar na nuvem ou no servidor, criptografia ou proteção contra edição, e salvar no meio do combate (fechar durante uma luta perde só aquela luta).

## 2. Arquitetura

O repositório passa a também gravar. A UI continua sem saber de onde vêm os dados.

```
data/
├── hero_repository.gd          + save_player(player) -> String   ("" = ok, senão a mensagem de erro)
├── local_hero_repository.gd    só leitura: save_player() não faz nada e devolve ""
├── hero_serializer.gd          HeroSerializer.to_dict(player) -> Dictionary (formato do JSON)
└── save_game_repository.gd     SaveGameRepository: lê/grava user://save.json
game/game_state.gd              repositório padrão = SaveGameRepository; salva depois de cada mudança
```

### `SaveGameRepository`
- `_init(save_path = "user://save.json", template_path = "res://data/sample_hero.json")`: os dois caminhos são injetáveis para os testes.
- `load_player()`:
  1. Se `save_path` não existe, carrega o `template_path` com `LocalHeroRepository`. É um jogo novo.
  2. Se existe, carrega com `LocalHeroRepository(save_path)` (mesma validação do herói de exemplo) e confere o `version`.
  3. Se o save for inválido, renomeia para `save.corrompido-AAAAMMDD-HHMMSS.json`, carrega o template e preenche `LoadResult.warning` com o aviso.
- `save_player(player)`: `HeroSerializer.to_dict()` → `JSON.stringify(dados, "  ")` → grava `save.json.tmp` → `DirAccess.rename_absolute` para `save.json`. Devolve `""` se deu certo, senão a mensagem de erro.
- `version` ausente é aceito como 1 (saves antigos que não tinham o campo). `version` maior que o suportado é tratado como save inválido.

### `GameState`
- `repository` padrão: `SaveGameRepository.new()`.
- Sinal novo: `notice(message: String)`, para avisos que o `main.gd` mostra no Toast (save corrompido, falha ao gravar).
- `reload()`: se o `LoadResult` tiver `warning`, emite `notice(warning)` depois do `player_changed`.
- `apply_battle_result()`: depois de alterar o `Player`, chama `_save()`. `_save()` chama `repository.save_player(player)`; se falhar, faz `push_error` e emite `notice(Texts.SAVE_FAILED)`.
- Regra para o futuro, que vai para o CLAUDE.md: **todo método do `GameState` que altera o `Player` termina com `_save()`**.

### `LoadResult`
Ganha `warning: String = ""`, usado quando o carregamento deu certo mas houve algo a avisar.

## 3. Formato do save

```json
{
  "version": 1,
  "hero": {
    "id": "hero-001", "name": "Aldric", "class": "mage",
    "level": 2, "xp": 5, "current_hp": 260,
    "attributes": { "strength": 5, "agility": 8, "intelligence": 14, "vitality": 12 }
  },
  "currencies": { "gold": 1265, "gems": 20 }
}
```
`HeroSerializer.to_dict()` gera exatamente esse formato. O teste de ida e volta (`to_dict` → gravar → ler) garante que o validador aceita o que o serializador produz.

## 4. Testes

**Os testes nunca podem ler nem gravar o `user://save.json` de verdade.**
- O executor (`tests/run_tests.gd`) troca o `GameState.repository` por `LocalHeroRepository` (só leitura) antes do primeiro teste. O `BaseTest.cleanup()` já restaura esse repositório.
- Os testes do `SaveGameRepository` usam `user://test_saves/` e apagam a pasta no `after_each`.

Cobertura:
- **`test_hero_serializer`**: o dicionário tem todos os campos e o `version`; ida e volta com o `LocalHeroRepository` devolve os mesmos valores.
- **`test_save_game_repository`**: sem save, carrega o template; grava e lê de volta (nível, XP, ouro); grava por cima de um save existente; save corrompido é renomeado, carrega o template e preenche `warning`; `version` futura é tratada como inválida; sem `version` é aceito; não sobra `.tmp` depois de gravar; caminho impossível de gravar devolve erro sem derrubar nada.
- **`test_game_state`** (acréscimos, com um `RecordingHeroRepository` falso que guarda o que recebeu em `save_player`): vitória salva o jogador atualizado; fuga e derrota também salvam (o HP volta ao máximo); falha ao salvar emite `notice`; `warning` no carregamento emite `notice`.
- **`test_hud`** (acréscimo): `GameState.notice` aparece no Toast.

## 5. Textos novos
| Constante | Texto |
|---|---|
| `SAVE_FAILED` | Não foi possível salvar o progresso |
| `SAVE_CORRUPTED` | Save danificado; um novo jogo foi iniciado (cópia guardada) |

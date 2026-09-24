# MVP: Cidade + Menu do Personagem (design)

**Data:** 2026-09-24
**Engine:** Godot 4.7.2 (`Godot_v4.7.2-stable_win64.exe/`)
**Status:** aprovado em conversa, aguardando revisão da spec

## 1. Objetivo

Primeiro MVP de um jogo inspirado em **Legend Online** (RPG de browser da Oasis Games). O projeto deve crescer até um jogo completo e, no futuro, **online**. Por isso a base separa desde já as regras e os dados da interface.

**Critério de sucesso:** ao abrir o jogo, o jogador vê a cidade com o HUD do herói. Ao clicar em **Personagem** na barra inferior, abre-se um painel com os status do herói, calculados corretamente pelas fórmulas. Os testes automatizados passam pela linha de comando.

### Decisões tomadas
| Tema | Decisão |
|---|---|
| Objetivo | Jogo de verdade (base sólida, não protótipo descartável) |
| Futuro online | Sim: dados e regras isolados da UI, carregados via repositório trocável |
| Arte | Placeholders desenhados no Godot + lista de artes (seção 8) que substitui sem mexer no código |
| Personagem | Herói fixo de exemplo ("Aldric", Mago nível 1), sem tela de criação |
| Painel de status | Só exibição |
| Layout da cidade | **B**: barra de ícones no canto inferior direito e chat visual no inferior esquerdo |
| Layout do painel | **A**: tudo em uma tela (herói e slots à esquerda, status à direita) |

### Fora do escopo
Criação de personagem, distribuição de pontos, equipamentos funcionais, inventário, combate, chat real, salvamento de progresso, servidor/rede, som, interior das construções e o modo de andares da Torre.

## 2. Configuração do projeto

- Renderer **Compatibility** (roda em PCs modestos e facilita um export Web futuro).
- Resolução base **1280×720**, `display/window/stretch/mode = canvas_items`, `aspect = expand`.
- Cena principal: `res://ui/main.tscn`.
- Autoload: `GameState` → `res://game/game_state.gd`.
- Textos de interface em português, reunidos em `res://ui/texts.gd` (constantes) para facilitar tradução futura.

## 3. Arquitetura

```
primeiro-jogo/
├── project.godot
├── domain/                     regras puras (RefCounted), sem nós e sem UI
│   ├── attributes.gd           Attributes: strength, agility, intelligence, vitality
│   ├── hero.gd                 Hero: id, name, hero_class, level, xp, current_hp, attributes
│   ├── player.gd               Player: hero + gold + gems
│   └── stat_formulas.gd        funções estáticas de cálculo (seção 4)
├── data/
│   ├── hero_repository.gd      interface: load_player() -> LoadResult
│   ├── load_result.gd          LoadResult: player (ou null) + error (String)
│   ├── local_hero_repository.gd  lê e valida o JSON local
│   └── sample_hero.json
├── game/
│   └── game_state.gd           autoload: carrega via repositório, guarda o Player, emite sinais
├── ui/
│   ├── main.tscn / main.gd
│   ├── texts.gd
│   ├── art_loader.gd           texture_or_null(path)
│   ├── city/                   city_screen.tscn, building.tscn/.gd
│   ├── hud/                    hero_hud, currency_hud, chat_box, toast
│   ├── bottom_bar/             bottom_bar.tscn/.gd
│   ├── character_panel/        character_panel.tscn/.gd
│   └── theme/game_theme.tres
├── assets/                     city/, icons/, portraits/, ui/ (arte opcional, seção 8)
└── tests/
    ├── run_tests.gd
    ├── test_stat_formulas.gd
    ├── test_local_hero_repository.gd
    ├── test_main_smoke.gd
    └── fixtures/               JSONs inválidos para teste
```

### Fluxo de dados (sempre em uma só direção)
```
sample_hero.json → LocalHeroRepository.load_player() → GameState
                                                         │ player_changed(player) / load_failed(msg)
                                                         ▼
                                   HeroHud, CurrencyHud, CharacterPanel (usam StatFormulas para exibir)
```

Regras:
- `domain/` não depende de nós nem de cenas. É a parte que um servidor poderia reutilizar.
- A UI **nunca altera** `Player`/`Hero`. Só lê o que recebe no sinal. Ações futuras viram métodos do `GameState`.
- Nenhum componente de UI guarda uma cópia própria dos dados. Todos se redesenham a cada `player_changed`.
- O `GameState` recebe o repositório por injeção (`GameState.repository`, padrão `LocalHeroRepository`), para que os testes e o futuro modo online troquem a fonte de dados.

## 4. Domínio

### Formato do JSON (`data/sample_hero.json`)
```json
{
  "hero": {
    "id": "hero-001", "name": "Aldric", "class": "mage",
    "level": 1, "xp": 35, "current_hp": 240,
    "attributes": { "strength": 5, "agility": 8, "intelligence": 14, "vitality": 12 }
  },
  "currencies": { "gold": 1250, "gems": 20 }
}
```
As moedas ficam fora do herói porque, no online, pertencem à conta.

### Classes
| `class` | Nome exibido | Atributo principal |
|---|---|---|
| `mage` | Mago | intelligence |

Por enquanto existe **só o Mago**. As classes ficam em um dicionário `CLASSES` dentro de `StatFormulas`, então adicionar outra depois é acrescentar uma linha, sem mudar as fórmulas.

### Fórmulas (`StatFormulas`, estáticas e puras)
Divisões inteiras arredondam para baixo.

| Função | Fórmula | Aldric |
|---|---|---|
| `max_hp(hero)` | 100 + vitality×10 + level×20 | 240 |
| `attack(hero)` | atributo_principal×2 + level | 29 |
| `defense(hero)` | vitality + agility÷2 + level | 17 |
| `crit_chance(hero)` | agility×0,5 (float, em %) | 4,0 |
| `speed(hero)` | 100 + agility | 108 |
| `xp_to_next_level(level)` | round(100 × level^1,5) | 100 |

### Validação (em `LocalHeroRepository`)
Cada falha gera um `LoadResult` com `player = null` e uma `error` descritiva:
- arquivo inexistente ou JSON malformado;
- campo obrigatório ausente ou com tipo errado (todos os campos do exemplo são obrigatórios);
- `class` fora da tabela de classes;
- `level < 1`, `xp < 0`, atributo negativo, `gold < 0` ou `gems < 0`.

Correção silenciosa (sem erro): `current_hp` é limitado ao intervalo `[0, max_hp]`.

## 5. Interface

### Árvore da cena `Main`
```
Main (Node)
├── CityScreen (Node2D)          fundo + 6 Buildings
├── HUDLayer (CanvasLayer, layer 1)
│   ├── HeroHud                  canto sup. esq.: retrato, nome, "Nv X", barras de HP e XP
│   ├── CurrencyHud              canto sup. dir.: ouro e gemas
│   ├── ChatBox                  canto inf. esq.: só visual, com "[Sistema] Bem-vindo a Eldoria!"
│   ├── BottomBar                canto inf. dir.: 6 botões
│   └── Toast                    aviso temporário centralizado no alto
└── WindowLayer (CanvasLayer, layer 2)
    └── CharacterPanel           fundo escurecido + janela
```

### Construções (posições em pixels na base 1280×720)
| id | Nome | x | y | largura | altura |
|---|---|---|---|---|---|
| `castle` | Castelo | 512 | 173 | 230 | 187 |
| `tower` | Torre | 138 | 206 | 120 | 190 |
| `blacksmith` | Ferreiro | 320 | 360 | 141 | 108 |
| `market` | Mercado | 819 | 317 | 154 | 115 |
| `arena` | Arena | 1024 | 216 | 166 | 130 |
| `training` | Treino | 602 | 410 | 154 | 94 |

A **Torre** será o futuro modo de andares, no estilo do labirinto do Legend Online (subir andar por andar enfrentando inimigos). No MVP ela é só uma construção "em breve", como as outras; o modo de andares está fora do escopo. É a única construção alta e estreita: o placeholder dela é um retângulo alto com telhado pontudo.

Placeholder: um retângulo com telhado triangular e o nome embaixo. Ao passar o mouse, o prédio brilha e o cursor vira mão. Ao clicar, aparece o Toast "<Nome> — em breve" por 2 s.

### Barra inferior
Botões na ordem: **Personagem** (funcional), Mochila, Habilidades, Missões, Guilda e Config (esmaecidos; ao clicar, mostram o Toast "<Nome> — em breve"). Cada botão tem ícone e rótulo curto.

### Painel do Personagem (layout A)
- **Título** "Personagem" e botão ✕.
- **Esquerda:** nome, "<Classe> · Nível X", retrato de corpo inteiro no centro e 8 slots vazios ao redor (Elmo, Armadura e Botas à esquerda; Colar, Anel e Capa à direita; Arma e Escudo embaixo).
- **Direita:**
  - HP `atual / máx` com barra vermelha; XP `atual / próximo` com barra dourada;
  - bloco **Atributos**: Força, Agilidade, Inteligência, Vitalidade;
  - bloco **Combate**: Ataque, Defesa, Crítico (`4%`, sem casa decimal quando inteiro), Velocidade.
- **Abre** pelo botão Personagem. **Fecha** pelo ✕, pela tecla Esc ou por qualquer clique no fundo escurecido.
- Com o painel aberto, o fundo escurecido (tela inteira, na `WindowLayer`) bloqueia os cliques na cidade e na barra. Um clique sobre o botão Personagem cai no fundo e fecha o painel, e o jogador percebe isso como abrir e fechar pelo mesmo botão.

### Arte e placeholders
`ArtLoader.texture_or_null(path)` retorna a textura se o arquivo existir e `null` se não existir. Quando recebe `null`, cada componente desenha seu placeholder. Um único `game_theme.tres` define as cores (marrom `#3d2a16`/`#2a1c0e` e dourado `#c9a24a`), as bordas e a fonte.

## 6. Tratamento de erros

- O `GameState` carrega em `_ready()`. Se falhar: emite `load_failed(error)`, registra com `push_error` e guarda `player = null`.
- Na falha, a UI continua de pé: a cidade aparece, o `HeroHud` mostra "Erro ao carregar personagem", o `CurrencyHud` fica vazio e o botão Personagem fica desativado.
- Dados ruins nunca derrubam o jogo.

## 7. Testes

Executor próprio, sem plugins: `tests/run_tests.gd` (`extends SceneTree`) descobre `tests/test_*.gd`, instancia cada um, roda os métodos `test_*`, imprime o resultado e encerra com `quit(0)` se tudo passou ou `quit(1)` se algo falhou. Asserções simples (`assert_eq`, `assert_true`) ficam numa classe base `tests/test_case.gd`.

```
Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/run_tests.gd
```

Cobertura:
- **`test_stat_formulas`**: todos os valores do Aldric; o ataque do Mago usa inteligência e não força; atributos zerados; `xp_to_next_level` nos níveis 1, 2 e 10.
- **`test_local_hero_repository`**: carregar o exemplo válido; arquivo inexistente; JSON malformado; campo ausente; classe inválida (ex.: `"warrior"`); nível 0; `current_hp` acima do máximo é limitado.
- **`test_main_smoke`**: instancia `main.tscn` com repositório de exemplo, confere o nome no HUD, abre o painel pelo botão Personagem, confere "29" no Ataque, fecha com Esc; com repositório que falha, confere a mensagem de erro e o botão desativado.

## 8. Lista de artes (opcional; o jogo funciona sem elas)

Tudo em PNG. Os nomes de arquivo precisam ser exatamente estes.

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `assets/city/background.png` | 1280×720 | Fundo da cidade sem as construções |
| `assets/city/castle.png`, `tower.png`, `blacksmith.png`, `market.png`, `arena.png`, `training.png` | caber na caixa da tabela da seção 5, fundo transparente | Cada construção isolada |
| `assets/icons/character.png`, `bag.png`, `skills.png`, `quests.png`, `guild.png`, `settings.png` | 64×64, transparente | Ícones da barra inferior |
| `assets/icons/gold.png`, `gems.png` | 32×32, transparente | Ícones de moeda |
| `assets/portraits/mage_face.png` | 128×128 | Rosto para o HUD (o jogo recorta em círculo) |
| `assets/portraits/mage_full.png` | 300×450, transparente | Corpo inteiro para o painel |
| `assets/ui/panel_frame.png` | 96×96, 9-slice com bordas de 24 px | Moldura das janelas |
| `assets/ui/slot_empty.png` | 64×64 | Slot de equipamento vazio |

Estilo de referência: fantasia medieval ilustrada, com paleta quente de marrom e dourado, como no Legend Online.

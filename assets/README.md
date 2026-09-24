# Arte do jogo

O jogo funciona sem nenhuma destas imagens: cada uma tem um placeholder desenhado.
Para usar arte de verdade, salve o PNG **com o nome exato** na pasta indicada e
abra o projeto no editor do Godot uma vez (ele importa o arquivo). Não precisa mexer em código.

Estilo de referência: fantasia medieval ilustrada, paleta quente de marrom e dourado, como no Legend Online.

| Arquivo | Tamanho | Conteúdo |
|---|---|---|
| `city/background.png` | 1280×720 | Fundo da cidade sem as construções |
| `city/castle.png` | até 230×187, fundo transparente | Castelo |
| `city/tower.png` | até 120×190, fundo transparente | Torre (futuro modo de andares) |
| `city/blacksmith.png` | até 141×108, fundo transparente | Ferreiro |
| `city/market.png` | até 154×115, fundo transparente | Mercado |
| `city/arena.png` | até 166×130, fundo transparente | Arena |
| `city/training.png` | até 154×94, fundo transparente | Campo de treino |
| `icons/character.png`, `bag.png`, `skills.png`, `quests.png`, `guild.png`, `settings.png` | 64×64, transparente | Ícones da barra de menu |
| `icons/gold.png`, `icons/gems.png` | 32×32, transparente | Moedas |
| `portraits/mage_face.png` | 128×128 | Rosto do Mago para o HUD (o jogo recorta em círculo) |
| `portraits/mage_full.png` | 300×450, transparente | Mago de corpo inteiro para o painel |
| `ui/panel_frame.png` | 96×96, 9-slice com bordas de 24 px | Moldura das janelas |
| `ui/slot_empty.png` | 64×64 | Slot de equipamento vazio |
| `battle/background.png` | 1280×720 | Fundo do combate (campo de treino); esticado para a tela toda |
| `enemies/giant_rat.png`, `wolf.png`, `ogre.png` | até 220×250, transparente | Inimigos virados para a esquerda (nome = `id` em `data/enemies.json`) |

Posição de cada construção no palco de 1280×720 (canto superior esquerdo x, y):
castelo (512, 173), torre (138, 206), ferreiro (320, 360), mercado (819, 317),
arena (1024, 216), treino (602, 410). A arte é encaixada na caixa mantendo a
proporção, alinhada embaixo e no centro.

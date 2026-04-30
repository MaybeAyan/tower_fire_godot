# 苍纹牌阵

一个 Godot 4 战术牌组构筑原型：抽牌、消耗能量、在棋盘上移动、从合适的位置攻击，然后撑过敌方回合。

方向是“牌组构筑 roguelike + 战棋站位 + 明亮奇幻战术风格”。角色、卡牌名、设定和素材都是原创占位内容。

## 运行方式

1. 用 Godot 4.6 打开这个文件夹。
2. 运行项目。
3. 点击卡牌，再点击棋盘上的发光格子。

## 当前循环

- 7x5 战术棋盘上的一名主角。
- 三名敌人，会靠近或在相邻时攻击。
- 起始牌组包含攻击、移动、格挡、治疗和力量成长牌。
- 已实现抽牌堆、弃牌堆、回合结束弃手牌、能量刷新、胜利、战败和重开。
- 已接入生成素材：战场背景、单位头像和卡牌插画。
- UI 已中文化，并整理了顶部状态、右侧战斗面板和底部手牌区。

## 美术素材

- `assets/art/battlefield-academy-courtyard-1280x720.jpg`
- `assets/art/tokens/astra-hero.png`
- `assets/art/tokens/blade-acolyte.png`
- `assets/art/tokens/rune-flare.png`
- `assets/art/tokens/shield-vow.png`
- `assets/art/cards/quick-slash.png`
- `assets/art/cards/radiant-lance.png`
- `assets/art/cards/step-command.png`
- `assets/art/cards/guard-bloom.png`
- `assets/art/cards/engage-crest.png`
- `assets/art/cards/mend-light.png`

## 后续适合添加

- 战斗后的奖励选牌。
- 职业和被动技能。
- 地形效果，比如掩体、荆棘、治疗格和危险格。
- 路线地图和多场遭遇。
- 更完整的原创角色立绘、动作特效和音效。

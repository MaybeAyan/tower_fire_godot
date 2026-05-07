# AI 美术资产工作流

## 1. 目标

《苍纹牌阵》后续美术资源默认优先通过 AI 辅助生成，但必须把“氛围参考图”和“可直接进入 Godot 2D 流程的资产图”严格分开。

核心原则：

- 同样是 AI 图，不同用途必须分轨
- 氛围图服务方向判断
- 资产图服务可落地制作
- 不把概念图直接拿去当地编蓝图

## 2. 两条主线

### A 线：氛围概念图

用途：

- 确认章节气氛
- 确认建筑语汇
- 确认材质、配色、光照、节奏感
- 确认 UI 与场景是否像同一款游戏

特点：

- 允许更强叙事感
- 允许更自由构图
- 允许局部伪 2.5D 空间感
- 不要求每块 tile 严格等大

不适合：

- 直接切 TileSet
- 直接当逐格地图蓝图
- 直接导入 Godot 当可重复平铺素材

### B 线：生产级 2D 资产图

用途：

- TileSet
- 地编模块
- 地块贴图
- 楼梯、栏杆、立柱、平台模块
- 独立装饰 props
- UI 框体、按钮、底板

特点：

- 必须正交
- 必须尺寸一致
- 必须模块化
- 必须容易拆分
- 必须服务 Godot 2D

不适合：

- 追求重透视场景震撼感
- 把所有功能混在一张大图里

## 3. 推荐资产类型拆分

### 3.1 场景气氛图

目标：

- 圣庭庭院
- 回廊
- 演武庭
- 章节地图 / 营地

输出：

- 单张宽图
- 关键配色与材质方向
- 光照与情绪说明

### 3.2 地编 TileSet 图

目标：

- floor
- wall
- pillar
- gate
- high
- holy
- fire
- marker

输出：

- 严格等格
- 统一 tile 尺寸
- 模块边界清晰
- 不带重透视

### 3.3 地编模块图

目标：

- 楼梯
- 平台边缘
- 栏杆
- 小型桥段
- 装饰柱
- 墙角与断口

输出：

- 可独立摆放
- 可叠加到 TileMap 或装饰层
- 不破坏格子阅读

### 3.4 UI 资产图

目标：

- 大面板底图
- 小按钮
- 状态面板
- 技能栏底板
- 教学卡与目标卡框体

输出：

- 无文字
- 可切片
- 风格一致

## 4. 提示词策略

### 氛围图关键词

- story-driven tactical RPG
- Japanese fantasy oil painting
- bright sacred courtyard
- luminous holy corridor
- elegant parchment UI
- pseudo 2.5D depth illusion
- narrative atmosphere

### 生产级 2D 资产关键词

- strict orthographic
- uniform tile size
- modular 2D game asset
- grid-aligned
- flat square tactical tiles
- 2D tactical tileset production
- Godot 2D ready
- no perspective distortion

## 5. 质量门槛

### 氛围图通过标准

- 一眼能看出章节场所
- 一眼能看出本作气质
- 不会误导玩法实现方向

### 资产图通过标准

- Tile 大小视觉一致
- 模块边界清楚
- 能想象如何拆成 Godot 资源
- 不需要大量手工纠正透视

## 6. 建议批次顺序

1. 先做场景气氛图
2. 再做严格等格 TileSet 参考
3. 再做地编模块
4. 最后做 UI 资产图

不要反过来先做复杂 TileSet 再补气氛，不然很容易做成技术上规整但气质不对的资产。

## 7. 当前结论

《苍纹牌阵》当前正式方向固定为：

- 玩法：2D 正交战棋
- 表现：伪 2.5D 空间感
- 资产：优先生成可拆分、可复用、可落入 Godot 2D 流程的 2D 素材

因此今后默认要求：

- 棋盘逻辑图与地编资产图必须强调 `strict orthographic`
- 章节氛围图可以保留 `pseudo 2.5D`
- 不再把“看起来有空间感”的概念图直接视为可用 TileSet 蓝图

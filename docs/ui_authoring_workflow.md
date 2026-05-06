# UI 节点化与 Hastur 工作流

这份文档约定《苍纹牌阵》后续的 UI 开发方式，目标是让界面修改变成一条稳定、可重复、可验证的工作流，而不是每次都回到 `_draw()` 里硬改坐标。

## 1. 当前正式 UI 结构

项目现在的正式 UI 容器位于 [Main.tscn](/E:/godotPro/tower_fire_godot/scenes/Main.tscn) 的 `UiCanvas` 下：

- `BattleHudRoot`
- `BattleOverlayRoot`
- `ChapterFlowRoot`

它们分别负责：

- `BattleHudRoot`：战斗 HUD，含右侧战术面板、底部技能栏、左上教学卡、右上目标卡
- `BattleOverlayRoot`：开场对白、战斗结算、奖励选择、转职
- `ChapterFlowRoot`：章节地图、营地详情、章节完成

以下内容目前仍保留代码绘制：

- 棋盘与地形
- 单位与特效
- 侧面战斗演出

## 2. 日常编辑入口

### 快速调界面

优先打开：

- [UiPreview.tscn](/E:/godotPro/tower_fire_godot/scenes/UiPreview.tscn)

这个场景专门用于 UI 预览，支持在 Inspector 里切换：

- `preview_phase`
- `show_camp_detail`
- `selected_unit_index`

常用预览模式：

- `battle`
- `intro`
- `reward`
- `result`
- `promotion`
- `chapter_map`
- `complete`

它的作用是让你不必每次都跑完整战斗流程，就能直接调整节点位置、字体、边距和层级。

### 联调真实流程

当某个界面在预览场景里调得差不多后，再回到：

- [Main.tscn](/E:/godotPro/tower_fire_godot/scenes/Main.tscn)

验证真实状态切换、按钮行为和棋盘遮挡关系。

## 3. Hastur Editor Executor 用法

### Godot 内插件设置

项目已经启用 `HasturOperationGD` 编辑器插件。

相关设置位于 Project Settings：

- `hastur_operation/broker_host`
- `hastur_operation/broker_port`

默认值：

- host: `localhost`
- port: `5301`

### 推荐使用方式

1. 启动 Hastur broker
2. 打开 Godot 编辑器并加载本项目
3. 在编辑器中打开 `UiPreview.tscn` 或 `Main.tscn`
4. 通过 Hastur editor executor 做以下事情：
   - 查询当前场景树
   - 批量调整节点属性
   - 创建或重命名节点
   - 保存场景
   - 快速检查某个节点路径是否存在

推荐优先用 Hastur 做“结构性操作”，例如：

- 创建面板骨架
- 批量改锚点
- 改导出属性
- 检查节点命名与层级

而视觉细调仍建议你在编辑器里直接拖。

## 4. 推荐迭代节奏

每次只走一个小闭环：

1. 在 `UiPreview.tscn` 里调目标界面
2. 在 `Main.tscn` 里验证真实流程
3. 运行检查脚本
4. 记录需要继续节点化的剩余绘制逻辑

不要同时散改多个阶段界面。

推荐顺序：

1. 先把当前正在做的界面节点化
2. 再统一贴图、颜色、边距和字号
3. 最后才补动画和更细的观感修饰

## 5. 验证命令

每次提交前至少运行：

```powershell
powershell -ExecutionPolicy Bypass -File E:\godotPro\tower_fire_godot\tools\check_all.ps1
```

这个脚本会检查：

- 项目数据校验
- 战斗状态回归
- Godot headless 启动

如果要连同节点化 UI 工具链一起做日常自检，再运行：

```powershell
powershell -ExecutionPolicy Bypass -File E:\godotPro\tower_fire_godot\tools\check_ui_workflow.ps1
```

它会额外检查：

- `UiPreview.tscn` 与正式 `UiCanvas` 相关场景/脚本是否存在
- 共享玻璃主题资源是否存在
- Hastur 常用端口 `5301` / `5302` 是否可达

注意：本项目在这台机器上必须继续使用 `.godot` 下的显式日志路径，不能回退到默认日志写法。

## 6. 后续节点化优先级

虽然已经建立正式 `UiCanvas`，但仍有剩余工作：

### 高优先

- 章节地图与营地的视觉样式细化
- 对话、奖励、转职的正式贴图和交互动效
- 新节点 UI 与角色资源的风格进一步统一

### 中优先

- 章节完成界面的排版精修
- 预览场景加入更多假数据切换
- 旧绘制视图脚本进一步瘦身，避免与正式节点 UI 重复表达

### 低优先

- 把不影响编辑性的旧辅助绘制层进一步拆散

## 7. 约束

- HUD 与流程面板优先节点化
- 棋盘、地形、单位、VFX 目前不强行改成节点
- 所有正式文本继续由引擎渲染
- 不允许重新引入旧像素按钮和旧中世纪厚框风格

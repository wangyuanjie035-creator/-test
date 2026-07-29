# 140 住屋携带物槽位选择

## 目标

承接 [139_safehouse_prep_attributes.md](139_safehouse_prep_attributes.md)，把“准备携带物”从一个固定准备行动，升级成真正的出门负载选择。

核心区别：

- 准备行动回答“今天花时间做什么”。
- 携带物回答“这次出门身上带什么”。

## 当前规则

- 每次出门最多携带 `2` 件物品。
- 选择携带物不消耗准备行动点。
- 已选物品可以取下，再换成别的物品。
- 槽位满时，未选物品按钮禁用。
- 携带物影响下一次校园候选池评分。
- 点击“下一天”会清空携带物，需要重新选择。

## 携带物清单

| 携带物 | 目的 | 地图倾向 |
| --- | --- | --- |
| `笔记本电脑` | 现场处理数据、草稿和文献，适合写作/数据路线 | 数据 / 草稿 / 写作 / 方法 |
| `实验耗材包` | 临时补齐实验耗材，适合实验楼和设备路线 | 实验室 / 设备 / 数据 |
| `正装外套` | 应对汇报、行政窗口和委员会场合，降低第一印象风险 | 会议 / 导师 / 委员会 / 行政 / 声望 |
| `咖啡零食` | 支撑长时间探索，给休息、食堂和灵感事件留余地 | 照护 / 灵感 / 食堂 / 恢复 |
| `导师批注稿` | 带着关键批注出门，适合导师、写作和返修路线 | 导师 / 草稿 / 写作 / 返修 |
| `同门联络表` | 提前准备协作窗口，适合同门、合作和社交路线 | 同门 / 合作 / 社交 |

## 生成影响

携带物在候选池评分中比普通准备行动略重：

```text
阶段必需标签 > 阶段焦点标签 > 主题三选一 > 携带物 > 住屋准备倾向 > 点位类型基础分
```

当前每命中一个携带物标签，额外加 `22` 分。

## 实现记录

- [campus_overworld_scene.gd](../../../scripts/overworld/campus_overworld_scene.gd)
  - 新增 `SAFEHOUSE_CARRY_SLOT_COUNT = 2`。
  - 新增 `SAFEHOUSE_CARRY_TAG_SCORE = 22`。
  - 新增 `safehouse_selected_carry_item_ids`。
  - 住屋 UI 新增携带物槽位文本和 6 个携带物按钮。
  - 新增 `toggle_safehouse_carry_item(item_id)`。
  - 新增 `get_safehouse_carry_item_summary()`。
  - 新增 `get_safehouse_selected_carry_item_ids_summary()`。
  - 候选池评分新增 `_score_safehouse_carry_item_candidate()`。
  - 候选池审查新增 `carry=...` 和 `carry_hits=x/12`。
  - 原 `准备携带物` 准备行动改名为 `材料归档`，避免和携带物槽位重复。

## 验证记录

远程 Godot 执行器验证：

```text
scene_reload=0
carry_initial=无
select_laptop=true
select_jacket=true
select_third_blocked=false
carry_after_two=笔记本电脑 / 正装外套
carry_ids_after_two=formal_jacket,laptop
deselect_laptop=true
select_coffee=true
carry_after_swap=正装外套 / 咖啡零食
carry_ids_after_swap=coffee_snack,formal_jacket
apply_material_old_id=false
apply_material_new_id=true
mode_after_depart=overworld
audit=pool=20,target=12,selected=12,missing=0,focus_hits=7/7,theme=recovery_day,theme_hits=5/12,prep=补给 / 方法笔记 / 草稿 / 数据,prep_hits=8/12,carry=会议 / 导师 / 委员会 / 行政 / 声望 / 照护 / 灵感 / 食堂 / 恢复,carry_hits=6/12
carry_next_day=无
carry_ids_next_day=
```

## 手测重点

1. 住屋界面应显示 `携带物：0/2`。
2. 点击任意两件物品后，应显示 `2/2`，且两个按钮高亮。
3. 槽位满时，第三件未选物品应不可选。
4. 再次点击已选物品应取下，并释放槽位。
5. 出门后候选池审查应显示 `carry=...` 与 `carry_hits=...`。
6. 点击下一天后，携带物应清空。

## 下一步

1. 给携带物增加正式图标或像素小物件。
2. 携带物具体点位触发已在 [141_carry_item_interaction_triggers.md](141_carry_item_interaction_triggers.md) 中完成第一版。
3. 后续加入携带物解锁、升级和耐久/消耗规则。

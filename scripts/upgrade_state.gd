extends Node
## 全局升级状态（autoload 单例 UpgradeState）。
## 记录玩家通过升级卡片获得的各类加成，子弹创建时读取。

## 红球初始伤害加成
var red_base_damage_bonus: float = 0.0
## 红球每次撞击玩家增加的伤害加成
var red_hit_bonus: float = 0.0
## 橙球初始伤害加成
var orange_base_damage_bonus: float = 0.0
## 橙球撞击四面墙时的伤害倍率加成
var orange_multiplier_bonus: float = 0.0
## 蓝球初始伤害加成
var blue_base_damage_bonus: float = 0.0
## 蓝球每秒伤害加成
var blue_dps_bonus: float = 0.0

## 是否处于升级选择中（选择前禁止发射子弹）
var upgrading: bool = false

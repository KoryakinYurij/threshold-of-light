class_name EnemyBase extends CharacterBody2D
## Общая база врагов (T-03b Блок 3): белая вспышка при попадании, смерть-фейд,
## элитный аффикс (HP×2.5 / скорость×1.5 / урон×1.6), фаза отчаяния
## (< 25% HP: скорость ×1.4, кулдаун −30%, смена цвета — телеграф у каждого
## вида свой, одобренный владельцем не ломаем).
## Runtime-спавн: HealthComponent/Hurtbox/CollisionShape строятся кодом в _init
## (сцена арены не содержит врагов, их спавнит волна).
## Подвиды (Pursuer/Swarm/Shooter) наследуют и рисуют себя сами.

const DEATH_FADE: float = 0.28
const HIT_FLASH_SECONDS: float = 0.1
const ENEMY_LAYER: int = 8  # Hurtbox врага (мели-хёртбокс скаута ищет его)

## Множители элитного аффикса (контракт ТЗ: HP×2.5 / скорость×1.5 / урон×1.6).
const ELITE_HP_MULT: float = 2.5
const ELITE_SPEED_MULT: float = 1.5
const ELITE_DAMAGE_MULT: float = 1.6
## Фаза отчаяния: скорость ×1.4, кулдаун атаки ×0.7 (−30%).
const DESPAIR_SPEED_MULT: float = 1.4
const DESPAIR_COOLDOWN_MULT: float = 0.7
const DESPAIR_HP_FRACTION: float = 0.25

var arena: Node
var target: Node
var dead: bool = false
var is_elite: bool = false
var hit_flash: float = 0.0
var death_fade: float = 0.0
var _last_hp: int = -1

var health: HealthComponent
var hurtbox: Hurtbox

## Конструктор строит боевые узлы: HealthComponent + Hurtbox с кругом.
## Радиус фигуры — у вида свой (pursuer 16, swarm 10, shooter 13).
func _init() -> void:
	health = HealthComponent.new()
	add_child(health)
	hurtbox = Hurtbox.new()
	hurtbox.collision_layer = ENEMY_LAYER
	hurtbox.collision_mask = 0
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	(shape.shape as CircleShape2D).radius = _fx_radius()
	hurtbox.add_child(shape)
	add_child(hurtbox)

## Вызывается ареной после добавления в дерево: arena, цель, элитность.
func setup_enemy(arena_node: Node, t: Node, elite: bool) -> void:
	arena = arena_node
	target = t
	is_elite = elite
	health.health_changed.connect(_on_enemy_health_changed)
	health.died.connect(_on_enemy_died)
	_last_hp = health.current
	# Элитный аффикс: HP ×2.5 (скорость/урон применяются в eff_speed/eff_damage).
	if is_elite:
		health.set_maximum(maxi(1, roundi(health.maximum * ELITE_HP_MULT)))
		health.current = health.maximum
	queue_redraw()

func in_despair() -> bool:
	return not dead and health.current <= int(health.maximum * DESPAIR_HP_FRACTION)

## Итоговая скорость: базовая × элита × отчаяние.
func eff_speed(base: float) -> float:
	var s: float = base * (ELITE_SPEED_MULT if is_elite else 1.0)
	if in_despair():
		s *= DESPAIR_SPEED_MULT
	return s

## Итоговый урон: базовый × элита (отчаяние даёт только скорость и кулдаун).
func eff_damage(base: float) -> float:
	return base * (ELITE_DAMAGE_MULT if is_elite else 1.0)

## Кулдаун атаки с учётом отчаяния (−30%).
func eff_cooldown(base: float) -> float:
	if in_despair():
		return base * DESPAIR_COOLDOWN_MULT
	return base

## Общий таймер флеша/фейда. Вызывать из _physics_process подвида.
func tick_fx(delta: float) -> void:
	if death_fade > 0.0:
		death_fade -= delta
		if death_fade <= 0.0:
			queue_free()
		return
	hit_flash = maxf(0.0, hit_flash - delta)

func _on_enemy_health_changed(current: int, _maximum: int) -> void:
	if _last_hp >= 0 and current < _last_hp:
		hit_flash = HIT_FLASH_SECONDS
	_last_hp = current

func _on_enemy_died() -> void:
	if dead:
		return
	dead = true
	death_fade = DEATH_FADE
	arena.notify_enemy_died(self)
	queue_redraw()

## HealthComponent цели (runtime-враги и скаут могут называться по-разному).
func find_health(entity: Node) -> Node:
	for child: Node in entity.get_children():
		if child.get_script() != null and child.get_script().get_global_name() == "HealthComponent":
			return child
	return entity.get_node_or_null(NodePath("HealthComponent"))

## Вспышка попадания + элитная окантовка/отчаяние (цвет-индикатор).
## Подвиды зовут внутри своего _draw после своей фигуры.
func draw_fx() -> void:
	if hit_flash > 0.0:
		draw_circle(Vector2.ZERO, _fx_radius() + 3.0, Color(1.0, 1.0, 1.0, hit_flash / HIT_FLASH_SECONDS * 0.85))
	if is_elite:
		draw_circle(Vector2.ZERO, _fx_radius() + 6.0, Color("#ff9d2e", 0.9), false, 3.0)
	if in_despair():
		draw_arc(Vector2.ZERO, _fx_radius() + 9.0, 0.0, TAU, 20, Color("#ff3d81", 0.8), 3.0)

func _fx_radius() -> float:
	return 16.0

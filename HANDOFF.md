# HANDOFF — T-03 закрыт

## Состояние

- Ветка: `прототип-дипсик`, Windows-копия `D:\Code AI\Games\Godot v1`.
- Коммит: `5f545a7` (T-03), запушен в origin. Рабочее дерево чистое.
- T-03 «Бой и панель тюнинга» закрыт. T-04 намеренно не начинался.

## Что вошло в T-03

- Скаут (`scenes/combat/scout.gd`): WASD, дэш с i-frames, мели-атака, буфер ввода.
- Враг-преследователь (`scenes/combat/pursuer.gd`): FSM IDLE/SEEK/TELEGRAPH/ATTACK/RECOVER.
- Боевые компоненты (`scripts/combat/`): `damage_data.gd`, `health_component.gd`,
  `hurtbox.gd`, `melee_hitbox.gd` — урон: DamageData -> MeleeHitbox -> Hurtbox
  -> HealthComponent (godot-combat-system).
- Арена (`scenes/combat/combat_arena.gd` + `.tscn`): hit-stop, screenshake, HUD,
  смерть скаута (R — рестарт), Esc — в хаб.
- F1-панель (`scenes/ui/tuning_panel.gd`): 6 ползунков, применяются на лету,
  сохраняются в `user://settings.cfg` (секция `combat`) через SettingsStore.
- Интеграция: кнопка «Тестовый бой» в хабе -> `EventBus.combat_requested`
  -> SceneRouter -> арена. AGENTS.md: обязательный первый шаг «load project
  skills» из `.agents/skills`.
- Отчёт: `docs/prototype/REPORT-T-03.md` (дефолты + обоснование + решения).
- Смоук-тест: `tests/combat_smoke.tscn`/`.gd` (5 проверок: HP врага 30/30,
  мели-урон 30->20, урон по скауту 100->75, 6 ползунков, i-frames 0.18).

## Проверки (зелёные)

- `tools\test.cmd` — 75/75.
- Headless-запуск проекта и арены — чистый.
- Смоук-тест боя — 5/5.
- `tools\build.cmd` — успешно, `build\windows\ThresholdOfLight.exe` собран.
- Запуск собранного exe headless — чистый.

## ВАЖНО для следующего агента

1. **Сначала прочитай скиллы** в `.agents/skills` (правило в AGENTS.md):
   минимум `godot-combat-system`, `godot-input-handling`,
   `godot-state-machine-advanced`, `godot-characterbody-2d`.
2. **Рабочая среда — только Windows** через ssh-windows (туннель 2222).
   Путь: `D:\Code AI\Games\Godot v1`. Ветки `master` и `proto/v0.1` не трогать.
3. **Транспорт файлов:** кавычки через ssh-цепочку (bash -> OpenSSH -> cmd)
   ненадёжны для путей с пробелами. Рабочий приём: писать файлы локально
   (staging), `scp` в каталог без пробелов (`C:\Users\Fixed\`), затем
   `cmd /d /c "cd /d D:\Code AI\Games\Godot v1 && move /y C:\Users\Fixed\<f> <отн.путь>"`.
   Команды, работающие для проверок: `cmd /d /c "cd /d ... && ..."` без кавычек
   в путях, относительные пути.
4. **После добавления новых class_name-скриптов** обязательно прогоняй
   `godot --headless --path . --import`, иначе глобальные классы не видны.
5. Кодировка: файлы UTF-8 (русский в UI валиден). «Мусор» в консоли cmd —
   отображение, сами байты целы (проверено sha256).
6. Один таск — один коммит; после T-03 коммит `5f545a7` менять не нужно.

## Дальше (T-04, не начинать без задания)

Карта экспедиции, extraction, death-loss, игровые точки сохранения; вход в
арену через карту, а не кнопку хаба; снаряды (Forge of Form) — T-06.

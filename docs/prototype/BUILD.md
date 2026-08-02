# Сборка прототипа v0.1 (каркас T-02)

## Одной командой

```cmd
tools\build.cmd
```

Импорт ресурсов → тесты → экспорт. Результат: `build\windows\ThresholdOfLight.exe`
(рядом ложится `.pck` — оба файла нужны, `embed_pck` выключен).
`build\` в `.gitignore`: билд не коммитится.

Только тесты, без сборки:

```cmd
tools\test.cmd
```

Ненулевой код возврата = красный тест. `build.cmd` на красных тестах останавливается;
обойти — `tools\build.cmd --no-tests`.

## Что должно стоять на машине

- Godot `4.7.1.stable` — `D:\Tools\Godot\4.7.1\godot.cmd`, он же в `PATH`.
  Переопределяется переменной `GODOT`.
- **Шаблоны экспорта 4.7.1** в `%APPDATA%\Godot\export_templates\4.7.1.stable\`.
  Без них экспорт падает, а редактор их не ставит сам в headless-режиме.

Установка шаблонов без редактора (так же это делают CI-образы `godot-ci`):

```cmd
curl.exe -sSL -o "%TEMP%\tpz.zip" https://github.com/godotengine/godot/releases/download/4.7.1-stable/Godot_v4.7.1-stable_export_templates.tpz
mkdir "%APPDATA%\Godot\export_templates\4.7.1.stable"
tar.exe -xf "%TEMP%\tpz.zip" -C "%TEMP%"
move "%TEMP%\templates\*" "%APPDATA%\Godot\export_templates\4.7.1.stable\"
```

`.tpz` — обычный zip, `tar.exe` из состава Windows его распаковывает.
Внутри архива всё лежит в папке `templates/`, а Godot ждёт файлы **прямо** в
`4.7.1.stable\` — отсюда `move` последним шагом. Проверка: в папке должен быть
`windows_release_x86_64.exe`.

## Где лежат сейвы

`%APPDATA%\ThresholdOfLight\` — слоты в `saves\slot_N.json`, бэкапы `slot_N.bak.json`,
настройки `settings.cfg`.

Путь задан явно (`config/use_custom_user_dir` в `project.godot`), потому что имя
проекта кириллическое: по умолчанию Godot положил бы сейвы в
`%APPDATA%\Godot\app_userdata\Порог Света`, что неудобно смотреть из `cmd.exe`.

## Кириллица в логах

`chcp 65001` перед запуском Godot, иначе русский текст в выводе поедет.
`build.cmd` и `test.cmd` делают это сами.

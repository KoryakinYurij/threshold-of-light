# 📙 Дополнение №3: производственный пайплайн, инструменты и AI-workflow

> **Это четвёртый документ серии `docs/research/`.** Он собран из переданной вами четырёхчастной текстовой коллекции («Пайплайн и философия», «Архитектура Godot 4.x», «Стек инструментов», «AI-workflow и промпты»), **отфильтрованной под Threshold of Light** и дополненной независимой проверкой источников (июль 2026).
>
> Соседние документы:
> - `game-dev-handbook.md` — основы: слои, паттерны, принципы работы с ИИ, Git, MVP.
> - `godot-47-supplement.md` — техника: Godot 4.7/GDScript, autoloads, бой, сиды, тесты.
> - `design-and-release-supplement.md` — дизайн: экономика, риск/награда, граф, свет, релиз.
> - **Этот документ** — производство и операционка: фазы, инструменты, CI, SaveManager, промпты.
>
> Где этот текст расходится с остальными устоявшимися документами проекта — расхождение **помечено явно** (см. особенно §7 про именование файлов).

---

## 🧭 Оглавление

0. [Как пользоваться документом](#0-как-пользоваться-документом)
1. [Кураторская таблица: что берём, куда ссылаемся, что отклоняем](#1-кураторская-таблица-что-берём-куда-сылаемся-что-отклоняем)
2. [Производственный пайплайн ToL: прототип ≠ вертикальный слайс](#2-производственный-пайплайн-tol-прототип--вертикальный-слайс)
3. [Рабочий ритм: dogfooding, плейтест-каданс, always shippable](#3-рабочий-ритм-dogfooding-плейтест-каданс-always-shippable)
4. [Инструментарий соло+ИИ (адаптировано под проект)](#4-инструментарий-солои-адаптировано-под-проект)
5. [CI/CD: линт, тесты, экспорт, публикация](#5-cicd-линт-тесты-экспорт-публикация)
6. [SaveManager: production-референс](#6-savemanager-production-референс)
7. [Антипаттерны кодовой базы (перед / после)](#7-антипаттерны-кодовой-базы-перед--после)
8. [⚠️ Конфликт именования и его разрешение](#8-️-конфликт-именования-и-его-разрешение)
9. [AI-workflow: проверяемый цикл и гигиена контекста](#9-ai-workflow-проверяемый-цикл-и-гигиена-контекста)
10. [Библиотека промптов под Threshold of Light](#10-библиотека-промптов-под-threshold-of-light)
11. [One-Page GDD, заполненный под проект](#11-one-page-gdd-заполненный-под-проект)
12. [Чек-листы операционки](#12-чек-листы-операционки)
13. [Источники](#13-источники)

---

## 0. Как пользоваться документом

- 📌 Раздел **1** — прямой ответ на вопрос «что из присланного подходит и стоит добавить». Всё остальное — результат этого отбора в форме, готовой к применению.
- 🎯 Действия в первую очередь: раздел **2** (сверить фазы проекта с пайплайном), раздел **8** (разрешить конфликт именования), раздел **6** (когда дойдёт очередь до `persistence/`).
- 🤖 Раздел **10** (промпты) — операционный: копируйте в сессии с ИИ, подставляя ссылки на `CONTEXT.md` и research-документы.

---

## 1. Кураторская таблица: что берём, куда ссылаемся, что отклоняем

| Часть источника | Вердикт | Куда пошло / почему |
|-----------------|---------|----------------------|
| **1.1** Таймлайн «Идеация → Прототип → Слайс → Production → Alpha → Beta → RC → Release» | ✅ Берём | §2 — с привязкой к вашим Phase 0–4 |
| **1.1** Прототип vs вертикальный слайс (Рами Исмаил) | ✅ Берём | §2.1 — ключевое концептуальное уточнение; источник верифицирован |
| **1.1** Таблица сжатия фаз с ИИ | ⚠️ Частично | §2.3 с оговоркой: цифры иллюстративны, не обещание |
| **1.2–1.3** Find the fun, greybox, dogfooding | ✅ Берём ядро | §3; общие мотивы есть в handbook §12 — здесь лишь проектная конкретика |
| **1.3** Таблица частоты плейтестов | ✅ Берём | §3.2 — дополняет протокол из design-supplement §9 (каданс + протокол = полный цикл) |
| **1.4** Small scope, «на каждую фичу удаляю старую», scope-freeze, public deadline, always shippable | ✅ Берём | §3.3 |
| **1.5** GDD традиционный | ❌ Дубль | уже есть в handbook §13.3 |
| **1.5** One-Page GDD | ✅ Берём | §11 — сразу **заполнен под ToL** как готовый артефакт |
| **2.1** Структура папок Godot | ❌ Дубль | см. README («Architecture») и godot-47-supplement §1; ваша `res://scenes + /scripts + /data` уже корректна |
| **2.2** Resource vs Node vs Saved state | ❌ Дубль | см. godot-47-supplement §4 и пересмотр промта («Ревизия… Custom Resources / Nodes / Plain state») |
| **2.3** «Call down, signal up», EventBus, Components, FSM | ⚠️ Частично | правило «call down, signal up» как названный принцип → §7.1; остальное покрыто godot-47-supplement §3,5,7 |
| **2.4** SaveManager production (atomic + .bak + migration + группы) | ✅ Берём целиком | §6 — крупнейшая ценность Части 2; в docs ничего подобного нет |
| **2.5** Антипаттерны с примерами | ✅ Берём | §7 — компактный before/after справочник |
| **2.1** snake_case для файлов | ✅ Берём + конфликт | §8 — обнаружено противоречие с `CONTEXT.md`, разрешено в пользу Godot convention и вашего же репозитория |
| **3.1** Движки-сравнение | ❌ Дубль | решение принято и зафиксировано в ADR-001 |
| **3.2–3.5** Арт/звук/шрифты/ассеты | ✅ Берём | §4 — с акцентом на лицензии и **кириллицу в шрифтах** (связка с design-supplement §8) |
| **3.6–3.7** Git basics, GUT intro | ❌ Дубль | handbook §11, godot-47-supplement §14 |
| **3.7–3.9** gdtoolkit, GUT headless-команда, CI-workflow, Butler-каналы | ✅ Берём | §5 — как референс-каркас CI |
| **3.10–3.13** Скиллы и зоны ИИ (хорошо/плохо) | ⚠️ Частично | «плохо» в геймдев-терминах → §4.4; общие принципы — дубль handbook §2.1 |
| **4.1–4.2** Spec-driven, цикл spec→plan→implement→test | ❌ Дубль | handbook §2.3 (правила 3–5) |
| **4.3** «Дай ИИ проверку» | ✅ Берём | §9.1 — самое ценное правило; конкретизировано под Godot |
| **4.4** Эвристики контекста | ✅ Берём | §9.2 |
| **4.5** CLAUDE.md / MEMORY.md / specs/ | ⚠️ Адаптировано | §9.3 — в вашем репо роль project-rules играет `CONTEXT.md`; нативная схема файлов скорректирована, чтобы не плодить дубли |
| **4.6** Инструменты ИИ (Claude Code / Cursor / Aider / чат) | ✅ Берём | §9.4 — таблица «сценарий → инструмент» |
| **4.7** 12 промт-шаблонов | ✅ Берём подмножество | §10 — 9 шаблонов, адаптированных под ToL (без дублей архитектуры/GDD из старых разделов) |
| **4.7** Промты №1 (GDD) и №2 (структура) | ❌ Не нужны | GDD и структура у вас уже есть; вместо них — §11 и README |

**Итог курирования:** из ~40 блоков коллекции — 16 берём целиком, 8 адаптируем, 16 отклоняем как дубли существующей трилогии и проектных документов. Коллекция в целом качественная и по фактам (проверенные позиции подтвердились: Исмаил, simondalvai, gdtoolkit, Godot docs); её главная проблема для вас — **перекрёстное дублирование**, а не ошибки.

---

## 2. Производственный пайплайн ToL: прототип ≠ вертикальный слайс

### 2.1. Ключевое различие (Рами Исмаил, «LTPF: Prototypes & Vertical Slice», 2022 — верифицировано)

Ориентир профессионального пайплайна:

```
Идеация → Прототипирование → Вертикальный слайс → Production →
Alpha (Feature Complete) → Beta (Content Complete) → Release Candidate → Release
```

Смыслы, которые путают новички:

| Инструмент | Вопрос | Что доказывает | Как выглядитв ToL |
|------------|--------|----------------|--------------------|
| **Прототип** | «**Стоит ли** делать эту игру?» | Дизайн: фан механики | Серые боксы: квадрат разведчик бегает по 3 узлам и эвакуируется |
| **Вертикальный слайс** | «**Смогу ли** я её сделать?» | Производство: весь пайплайн собирается в шипабельное качество | Один полный цикл со ВСЕМИ дисциплинами: арт-слой, звук, UI, туториализация |

- Прототипов может быть много, они **грязные и изолированные** (каждый проверяет один вопрос: «фан ли бой?», «фан лириск/награда?»).
- Слайс — один, и он обязан работать **как кусок готовой игры**, включая онбординг: плейтестеры без вас должны понять, что происходит (антипаттерн «дам им слайс с 5-го уровня» — они не поймут управление и дадут мусорный фидбек).
- Для соло+ИИ слайс дополнительно проверяет: **ваш AI-workflow вообще способен собрать все системы без трещин**.

### 2.2. Отображение на план ToL

Ваш план (README Phase 1 + design-supplement §11) уже следует этой логике; зафиксируем термины:

| Пайплайн Исмаила | Ваш проект | Критерий выхода |
|------------------|------------|------------------|
| Идеация | Промт + research-документы | ✅ Сделано |
| Прототипы | ToL-специфик: отдельные грязные проверки боя и цикла (опционально, если сомневаетесь в фане) | 1–2 проверенных вопроса |
| Вертикальный слайс | **Phase 1 (greybox) + Phase 2 (systemic slice)** | Полный цикл играбелен чужими руками |
| Production | Phase 3 (контент, пулы, баланс) | Alpha: все системы на месте |
| Alpha (Feature Complete) | Конец Phase 3 | Фичи заморожены (scope-freeze) |
| Beta (Content Complete) | Phase 4 (полировка, контент допилен) | Остаются только баги и feel |
| RC / Release | Релизный трек (design-supplement §10): демо → Next Fest → запуск | Ship |

### 2.3. Сжатие фаз с ИИ — честная оговорка

Источник предлагает пропорции «прототип: 1–2 недели → 2–4 дня; слайс: 1–2 месяца → 1–2 недели». Относитесь как к **иллюстрации порядка величины, а не обещанию**: реальное сжатие сильно зависит от вашего уровня ревью (handbook §2: ИИ слабеет на >10k строк и в связных системах). Практический вывод верен независимо от цифр: **ранние фазы настолько дешевле поздних, что выбросить прототип — нормально, а переделывать слайс — только по данным плейтеста**.

---

## 3. Рабочий ритм: dogfooding, плейтест-каданс, always shippable

### 3.1. Dogfooding

Играйте в свою игру **каждый день, минимум 5 минут**. Не «когда будет что-то новое», а ежедневно: чужой плейтестер ловит то, что мозг разработчика дорисовывает, а ваш ежедневный прогон ловит регрессии «вчера работало». Связка: протокол сессии с внешними игроками — в design-supplement §9.1.

### 3.2. Плейтест-каданс (дополняет, не заменяет протокол)

| Этап | Частота | Кто | Формат |
|------|---------|-----|--------|
| Прототип / greybox | Каждый день | Вы сами | 5–10 мин dogfooding |
| Вертикальный слайс | Раз в неделю | 1–2 друга | По протоколу §9.1 design-supplement |
| Production | Раз в 2 недели | 3–5 плейтестеров | Протокол + телеметрия (воронки) |
| Beta / перед релизом | Одна волна | Закрытая группа 5–10 | itch.io закрытой страницей (раздел 5.3) |

Правила фиксации: записывайте только наблюдения («застрял на выборе узла 40 сек», «не понял, что добыча нестабильна»), не защищайте дизайн в моменте, после сессии — **одно** главное изменение.

### 3.3. Дисциплина скоупа и релиза

- **Always shippable:** каждый коммит в `main` собирается и запускается (раздел 5 закрывает это механически).
- **Public deadline:** объявите дату (джем, пост, вишлист-страница) до готовности — внешнее обязательство заменяет силу воли.
- **Правило обмена:** новая фича в план = одна вырезанная фича. Держит размер MVP неизменным.
- **Scope-freeze перед Beta:** после этой даты — только багфиксы и game feel.
- **Cut, don't extend:** порядок приоритетов промта (`fun > понятность риска > сейвы > расширяемость > контент > полировка`) — это порядок резки при нехватке времени: режется снизу вверх.

---

## 4. Инструментарий соло+ИИ (адаптировано под проект)

### 4.1. Таблица инструментов

| Слой | Инструмент | Лицензия/цена | Заметка для ToL |
|------|-----------|----------------|------------------|
| Плейсхолдер-арт | **Kenney.nl** | CC0 (даже коммерчески, без атрибуции) | Стандарт для грейбокса; берите UI-паки для хаба |
| Пиксель-арт | **Aseprite** | ~$20 или сборка из исходников (MIT) | Де-факто стандарт; анимации разведчика/врагов |
| — бесплатная альтернатива | **LibreSprite** / **Piskel** | бесплатно | Piskel — в браузере, для простых случаев |
| Растр/концепты | **Krita** | бесплатно | Концепт-арт маяка, кей-арт для капсул |
| SFX-генератор | **bfxr / jsfxr** | бесплатно | 5 базовых звуков за час: выстрел, попадание, подбор, эвакуация, смерть |
| SFX-библиотека | **Freesound.org** | CC — **проверять каждый звук** | Архив лицензий в `assets/audio/LICENSES.md` |
| Аудиоредактор | **Audacity** | бесплатно | Нормализация, обрезка тишины |
| AI-музыка | Suno / Udio | условия меняются | Только со скриншотом лицензии на дату генерации; Phase 2+ |
| Шрифты | **Google Fonts**, Font Squirrel, Game-icons.net | бесплатно/OFL | ⚠️ **проверка кириллических глифов обязательна** — см. design-supplement §8.1 (пиксельные: Press Start 2P — кириллица есть; VT323 — есть; m6x11 — есть) |
| Git LFS | `.gitattributes` для `*.png`, `*.wav`, `*.ogg`, `*.mp4` | бесплатно | Включить **до** первых больших бинарников |
| Линт/формат GDScript | **gdtoolkit** (`gdlint`, `gdformat`) — PyPI | MIT, `pip install "gdtoolkit==4.*"` | Верифицировано; гонять до коммита |
| Тесты | **GUT 9.7.1** (Godot 4.7.x; ветка `godot_4_7`) | MIT, в `addons/` | headless-команда — раздел 5.1 |
| Хостинг билдов | **itch.io + butler** | бесплатно | Дельта-патчи; каналы windows/linux/html5 |

### 4.2. AI-арт: реальные ограничения (для плана ассетов)

ИИ-арт стабильно **ломается** на: консистентности персонажа между позами, анимационных кадрах (плывут), стыковке tileset'ов. Рабочий воркфлоу для ToL:

1. **Грейбокс (сейчас):** примитивы + Kenney. Никакого ИИ-арта.
2. **Vertical slice:** ИИ для **концептов** (настроение маяка, тьмы), затем ручная нарезка/доводка в Aseprite; НЕ для финальных анимаций.
3. **Кей-арт капсул Steam** (design-supplement §10.2): ИИ-концепт + ручная финиш-сборка — это одно статичное изображение, здесь консистентность не нужна.
4. Пиксель-арт мелких силуэтов разведчика/врагов: часто **быстрее нарисовать**, чем воевать с ИИ-консистентностью.

### 4.3. Звук: минимальный план

- Phase 1: без звука (как решено).
- Phase 2: 5–7 bfxr-эффектов + AudioBus `master/sfx/music` заложить сразу.
- Phase 4: музыка (1–2 петли), мастеринг в Audacity. Политика лицензий: скриншот условий AI-генераторов в `docs/`.

### 4.4. Что ИИ делает плохо — в геймдев-терминах (дополняет handbook §2.1)

- **Долгосрочная консистентность:** через 10 файлов забывает архитектурные решения → якорь: `CONTEXT.md` + чек-лист сессии (§12).
- **Game feel:** тайминги, кривые, тряска — ИИ не «чувствует». Только ваши руки + плейтесты (design-supplement §6).
- **Глобальная архитектура:** локально-оптимальные решения, глобально вредные → архитектуру держит человек, ИИ — в роли джуна.
- **Консистентный арт/анимация** — см. §4.2.
- **Уверенные математические ошибки** без верификации → правило «дай проверку» (§9.1).

### 4.5. Минимум хард-скиллов для вас

1. Читать GDScript на уровне «понимаю, что делает этот файл» (ревью ИИ).
2. Сцены/ноды/сигналы/ресурсы/autoload — ментальная модель.
3. Git: коммит, ветка, конфликт, тег.
4. Экспорт и публикация на itch.
5. Формулировать «не фан» в изменение спеки.

---

## 5. CI/CD: линт, тесты, экспорт, публикация

Цель: пайплайн «пуш в `main` → проверки → живой билд на itch.io». Это и есть «always shippable» из §3.3 и «дай ИИ проверку» из §9.1.

### 5.1. Команды (зафиксировать в CONTEXT.md, когда появятся)

```bash
# Линт и формат (gdtoolkit, pip install "gdtoolkit==4.*")
gdlint $(find . -name "*.gd" -not -path "./addons/*")
gdformat --check $(find . -name "*.gd" -not -path "./addons/*")

# Тесты GUT (после добавления GUT в addons/)
godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit

# Экспорт (headless; требует export_presets.cfg и шаблоны)
godot --headless --export-release "Windows Desktop" build/windows/tol.exe
```

### 5.2. Референс-каркас GitHub Actions

Ниже — проверенная по независимым источникам схема (контейнер `barichello/godot-ci` + Butler). Это **каркас**: версии, имена пресетов и каналов подставьте свои.

```yaml
name: build-and-publish
on:
  push:
    branches: [ main ]

jobs:
  checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: gdtoolkit
        run: pip install "gdtoolkit==4.*"
      - name: lint
        run: gdlint $(find . -name "*.gd" -not -path "./addons/*")
      - name: format check
        run: gdformat --check $(find . -name "*.gd" -not -path "./addons/*")

  export-html5:
    needs: checks
    runs-on: ubuntu-latest
    container:
      image: barichello/godot-ci:4.7.1   # держать вровень со stable проекта (тег проверен: Docker Hub, 2026-07)
    steps:
      - uses: actions/checkout@v4
      - name: GUT tests
        run: godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit
      - name: Export Web
        run: |
          mkdir -p build/web
          godot --headless --export-release "Web" build/web/index.html
      - name: Publish to itch.io (butler)
        env:
          BUTLER_API_KEY: ${{ secrets.BUTLER_API_KEY }}
        run: |
          curl -L -o butler.zip https://broth.itch.zone/butler/linux-amd64/LATEST/archive/default
          unzip butler.zip && chmod +x butler
          ./butler push build/web YOUR_ITCH/threshold-of-light:html5
```

Замечания:
- `export_presets.cfg` должен лежать в репозитории (не в `.gitignore`) — иначе CI нечем экспортировать.
- Альтернатива контейнеру — action `firebelley/godot-export` (design-supplement §10.5): он же умеет собрать все пресеты и оформить GitHub Release с semver.
- Mac-подпись/notarization — позже ($99/год Apple Developer); на старте: Windows + Web.
- GUT-тесты запускаются внутри контейнера — плагин GUT в `addons/` коммитим (исключение из правила «`.godot/` игнорируем» тут не нужно: `addons/` коммитится).

### 5.3. itch.io как закрытый плейтест-стенд

Страница в режиме **Restricted (пароль)** = бесплатный приватный стенд для волн из §3.2. Butler-каналы: `html5` (игра в браузере — низший барьер для тестеров), `windows`. Оживление страницы в публичный режим — отдельное решение по готовности вертикального слайса (design-supplement §10.4).

---

## 6. SaveManager: production-референс

Контракт из промта §14 (атомарная запись, версии, миграции, backup, 3 слота, обработка повреждённых файлов, раздельные settings/profile/hub/run) + архитектура из CONTEXT.md (никаких Node-ссылок в сейвах; восстановление визуала из состояния). Ниже — референс-реализация для `scripts/persistence/`, соответствующая обоим. **Это образец, а не готовый файл** — имена систем подставит `/implement`-поток.

### 6.1. Pipeline записи (10 шагов)

```
1. Собрать typed state → SaveEnvelope {save_version, profile, hub_state, run_state?}.
2. Валидация обязательных полей и диапазона версии.
3. Сериализация только primitive/array/dictionary (никаких Node/Callable/NodePath/Resource refs).
4. Записать в user://save_<slot>.json.tmp.
5. Закрыть файл; перечитать размер (защита от write-ошибок).
6. Существующий save_<slot>.json → скопировать в save_<slot>.json.bak.
7. rename tmp → save_<slot>.json (атомарно на уровне ОС).
8. При загрузке: основной файл → при сбое backup → при сбое "fresh profile".
9. Прогнать цепочку миграций до CURRENT_VERSION.
10. Только после успешной валидации — реконструировать Nodes из ID.
```

### 6.2. Код (GDScript, типизированный)

```gdscript
# scripts/persistence/save_manager.gd  (autoload "SaveManager")
class_name SaveManager
extends Node

const CURRENT_VERSION: int = 3
const SLOT_COUNT: int = 3

signal save_completed(slot: int)
signal save_failed(slot: int, reason: String)

func _slot_path(slot: int) -> String:
    assert(slot >= 1 and slot <= SLOT_COUNT, "invalid save slot")
    return "user://save_%d.json" % slot

func save_to_slot(slot: int, envelope: Dictionary) -> bool:
    envelope["save_version"] = CURRENT_VERSION
    var path := _slot_path(slot)
    var tmp_path := path + ".tmp"

    var f := FileAccess.open(tmp_path, FileAccess.WRITE)
    if f == null:
        save_failed.emit(slot, "cannot open tmp file")
        return false
    f.store_string(JSON.stringify(envelope, "\t"))
    f.close()

    # write-verify: перечитали размер (ловит усечённую запись)
    var written := FileAccess.get_file_as_string(tmp_path)
    if written.is_empty():
        save_failed.emit(slot, "write verification failed")
        return false

    _backup_existing(path)
    var err := DirAccess.rename_absolute(tmp_path, path)  # атомарно на ОС
    if err != OK:
        save_failed.emit(slot, "rename failed: %d" % err)
        return false
    save_completed.emit(slot)
    return true

func load_from_slot(slot: int) -> Dictionary:
    var path := _slot_path(slot)
    var data := _read_json(path)
    if data.is_empty():
        data = _read_json(path + ".bak")      # fallback на backup (шаг 8)
    if data.is_empty():
        return {}
    var version: int = int(data.get("save_version", 1))
    if version > CURRENT_VERSION:
        push_warning("Save from newer version; loading best-effort")
        return data
    return _migrate(data, version)

func _migrate(data: Dictionary, from_v: int) -> Dictionary:
    var v := from_v
    var out := data
    while v < CURRENT_VERSION:
        var step := Callable(self, "_migrate_v%d_to_v%d" % [v, v + 1])
        if not step.is_valid():
            push_error("Missing migration v%d->v%d" % [v, v + 1])
            break
        out = step.call(out)
        v += 1
    out["save_version"] = CURRENT_VERSION
    return out

# Пример звена миграции (реальные правила — под ваши изменения схемы):
func _migrate_v1_to_v2(d: Dictionary) -> Dictionary:
    # v2: hub_state.modules: Dictionary по ID вместо массива
    if d.has("hub_state") and d["hub_state"].get("modules") is Array:
        var by_id: Dictionary = {}
        for m in d["hub_state"]["modules"]:
            by_id[ m.get("id", "unknown") ] = m
        d["hub_state"]["modules"] = by_id
    return d

func _migrate_v2_to_v3(d: Dictionary) -> Dictionary:
    # v3: добавлено поле profile.settings_version
    d.get_or_add("profile", {}).get_or_add("settings_version", 1)
    return d

func _backup_existing(path: String) -> void:
    if FileAccess.file_exists(path):
        DirAccess.copy_absolute(path, path + ".bak")

func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var text := FileAccess.get_file_as_string(path)
    var parsed: Variant = JSON.parse_string(text)
    if typeof(parsed) != TYPE_DICTIONARY:
        push_warning("corrupted save: %s" % path)
        return {}
    return parsed
```

### 6.3. Сбор данных через группу `saveable`

```gdscript
# Внутри сборщика конверта: узлы, владеющие runtime-состоянием сцены,
# помещаются в группу "saveable" и реализуют контракт двух методов.
func _collect_nodes_section() -> Array[Dictionary]:
    var out: Array[Dictionary] = []
    for node in get_tree().get_nodes_in_group("saveable"):
        if node.has_method("get_save_data"):
            out.append(node.get_save_data())  # содержит стабильный id + plain data
    return out

# Контракт на стороне узла (пример):
# func get_save_data() -> Dictionary:
#     return {"id": stable_id, "type": "module", "level": 2}
# func load_save_data(d: Dictionary) -> void:
#     apply levels/flags -> затем реконструировать визуал из Definition
```

### 6.4. Что НЕ сохранять (красные линии)
- ❌ Ссылки на `Node`, `NodePath`, `Callable`, `Signal`, `Resource` — только **стабильные ID** (`enemy_id: &"chaser"`), восстановление по ID из `data/*.tres`.
- ❌ Визуальное состояние (кадр анимации, позиция tween) — реконструируется логикой `_ready`.
- ❌ `run_state` во время боя (запрет промта). Точки записи: хаб, безопасный узел, после завершения узла.

### 6.5. Тесты (GUT-разметка)

```gdscript
# tests/persistence/test_save_manager.gd
extends GutTest

func test_atomic_write_creates_bak_and_tmp_is_gone() -> void: ...
func test_corrupted_main_falls_back_to_bak() -> void: ...
func test_missing_and_corrupted_gives_empty() -> void: ...
func test_migration_chain_v1_to_current() -> void: ...
func test_invalid_slot_asserts_or_rejected() -> void: ...
func test_roundtrip_preserves_module_levels() -> void: ...
```

---

## 7. Антипаттерны кодовой базы (перед / после)

### 7.1. Правило-флаг: «call down, signal up»

Родитель **вызывает** детей напрямую; дети сообщают родителю **только сигналами**. Дочерний компонент не знает, кто его родитель.

```gdscript
# HealthComponent.gd — ничего не знает про Player
signal health_changed(value: int)
var current_hp: int
func take_damage(amount: int) -> void:
    current_hp -= amount
    health_changed.emit(current_hp)

# Player.gd — родитель вызывает вниз и подписан снизу
func _ready() -> void:
    health_component.health_changed.connect(_on_health_changed)
func on_enemy_hit(dmg: int) -> void:
    health_component.take_damage(dmg)
```

### 7.2. Таблица антипаттернов

| Антипаттерн | ❌ Было | ✅ Стало |
|-------------|---------|----------|
| Хардкод-пути в цикле | `get_node("/root/Main/Arena/Enemy"+str(i))` в `_process` | `@onready`/кэш через `get_tree().get_nodes_in_group("enemies")` в `_ready` |
| God object | `player.gd` на 2000 строк | Компоненты: `HealthComponent`, `HitboxComponent`, `MovementController` (scenes/entities/) |
| Данные в коде | `const MAX_HP = 100` в `enemy.gd` | `@export` поля в `EnemyDefinition.tres` (data-driven) |
| Динамика без типов | `func take_damage(amount):` | `func take_damage(amount: int) -> void:` |
| Быстрый autoload на всё | `Game`, `Utils`, `Global`, `Common`… | Чек-лист из godot-47-supplement §6 (4 вопроса); лимит autoload'ов |
| Сигнал на локальное | `EventBus` для «подобрал монетку» в той же сцене | Прямой сигнал `collected` внутри сцены; EventBus — для межсистемных событий |

(Пункты 2–6 детализированы в godot-47-supplement §§3–6; здесь они собраны как дежурный список для промта-ревью §10/№4.)

---

## 8. ⚠️ Конфликт именования и его разрешение

**Обнаружено противоречие между документами проекта и практикой репозитория:**

| Где | Что написано/как есть |
|-----|------------------------|
| `CONTEXT.md` (Naming) | «Scenes: PascalCase (`HubScreen.tscn`); Scripts: PascalCase matching attached node (пример: `hub_screen.gd`)» — **пример противоречит правилу** |
| Репозиторий | `scenes/main/main_menu.tscn`, `main_menu.gd` — **snake_case** |
| Официальная конвенция Godot | snake_case для файлов и папок (кроме C#), PascalCase для **имён нод** (`class_name`) — docs.godotengine.org «Project organization» |
| Присланная коллекция (Часть 2) | snake_case для файлов, по тем же причинам (case-sensitivity при экспорте на Windows) |

**Разрешение (принято в пользу Godot convention и фактического состояния репо):**
- Файлы сцен и скриптов — **snake_case** (`hub_screen.tscn`, `hub_screen.gd`).
- `class_name` и имена нод в сценах — **PascalCase** (`HubScreen`).
- Группы — snake_case (`enemies`, `interactables`).
- Файлы ресурсов-определений — как есть: PascalCase + `Definition` (`EnemyDefinition.tres`) — локальная конвенция проекта, безвредна, оставляем.

`CONTEXT.md` скорректирован соответственно (см. историю коммитов этого документа). Если примете иное решение — правьте `CONTEXT.md` и этот раздел синхронно.

---

## 9. AI-workflow: проверяемый цикл и гигиена контекста

### 9.1. Главное правило: «дай ИИ проверку, которую он может запустить»

Без проверки агент останавливается на «выглядит готово». С проверкой цикл замыкается сам:

```
ИИ делает → запускает проверку → читает результат → итерирует до pass
```

Проверки для Godot-проекта (в порядке дешевизны):
1. `gdlint` / `gdformat --check` — секунды.
2. `godot --headless -s addons/gut/gut_cmdln.gd -gexit` — unit-уровень.
3. Headless-экспорт (собирается ли проект вообще) — раздел 5.
4. Запуск сцены и скриншот/лог — для визуальных и поведенческих изменений (отладочный запуск с `RunLogger` — design-supplement §9.2).

Каждый промт на реализацию (§10) должен заканчиваться строкой проверки — это часть шаблона, не опция.

### 9.2. Гигиена контекста (эвристики)

- Debug-сессия длится **>30 минут** → контекст загрязнён стек-трейсами; начните новую сессию со сводкой проблемы.
- Изменено **>5 файлов** → убедитесь, что агент ещё держит архитектурные правила (спросите его: «перечисли правила из CONTEXT.md, которые сейчас действуют»).
- Новая фича → **новая сессия** + `CONTEXT.md` + релевантный research-раздел, а не «продолжаем вчерашний чат».
- Разведка («найди, где формируется граф») — отдельная сессия/subagent, чтобы не засорять основную.
- Course-correct: поправляйте агента сразу, а не после третьей итерации.

### 9.3. Файлы памяти проекта — адаптация под ваш репозиторий

Коллекция предлагает `CLAUDE.md` + `MEMORY.md` + `specs/CONTEXT.md`. В вашем случае роли уже распределены — **не плодите дубли**:

| Роль | Где живёт у вас | Примечание |
|------|------------------|------------|
| Постоянные правила проекта (стек, архитектура, naming) | **`CONTEXT.md`** | Это и есть «CLAUDE.md-позиция»; ИИ читает первым |
| Навигация по навыкам агента | `AGENTS.md` | Не смешивать с правилами кода |
| Решения и «почему» | `docs/adr/` | ADR-002, ADR-003… вместо «MEMORY.md» |
| Живой статус (что сделано/в работе/баги) | обновляемый блок **в конце `CONTEXT.md`** или `docs/status.md` | Обновлять промтом §10/№9 в конце сессии |
| Спеки систем (requirements/design/tasks на систему) | `docs/specs/<system>/` — **опционально**, когда система >1 сессии | НЕ называйте файл `specs/CONTEXT.md` — конфликтует с корневым `CONTEXT.md` по смыслу |
| Дизайн-контракты | research-Тетралогия + промт-GDD | Единый источник правды |

### 9.4. Инструменты ИИ: сценарий → инструмент

| Сценарий | Инструмент | Почему |
|----------|-----------|--------|
| Брейншторм, объяснение, разбор ошибки | Обычный чат | Дешево, не пачкает репо |
| Архитектура и многофайловая реализация | Агент с файловым доступом (Claude Code / Cursor / Aider) | Plan-mode + проверки §9.1 |
| Мелкая рутинная правка | Лёгкий агент (Aider-стиль) | Прозрачная стоимость, git-коммит на изменение |
| Ревью перед коммитом | Второй агент/чат — придирчивый ревью (§10/№4) | Adversarial review ловит то, что автор упустил |

Принцип не меняется от инструмента: **спека в репо, проверка в CI, решения в ADR** — тогда замена инструмента не рвёт память проекта.

---

## 10. Библиотека промптов под Threshold of Light

Каждый промт = роль + контекст-пакет (ссылки на файлы проекта) + задача + формат вывода + **строка проверки**. Контекст-пакет по умолчанию: «прочитай `CONTEXT.md`, `docs/prompt_hub_expeditions_professional.md` (соответствующий раздел), при необходимости — раздел из `docs/research/…`».

**№1. Старт сессии (plan-first, read-only)**
```
[Plan mode] Прочитай CONTEXT.md и docs/status.md. Не пиши код.
Задача сессии: [фича]. Разбей на шаги; для каждого: затрагиваемые файлы,
риски, способ проверки (lint/GUT/экспорт/ручной прогон).
Задай уточняющие вопросы. Жди подтверждения.
```

**№2. Реализация системы с тестами**
```
Реализуй [система] по docs/specs/[система]/ (или по моему описанию ниже).
Соблюдай CONTEXT.md: типизация, call down/signal up, без новых autoload
без обоснования, данные — в .tres. Напиши GUT-тесты на happy path,
границы и ошибочные входы.
Проверка: gdlint + godot --headless -s addons/gut/gut_cmdln.gd -gexit — доложи вывод.
```

**№3. SaveManager (когда дойдёт persistence)**
```
Реализуй persistence по образцу docs/research/production-and-ai-workflow-supplement.md §6:
atomic write (.tmp→rename), .bak, save_version + цепочка миграций, группа saveable,
3 слота, запрет сохранения в бою. Покрой §6.5 тестами. Не сериализуй Node-ссылки.
Проверка: GUT-прогон модуля persistence.
```

**№4. Придирчивое ревью (adversarial, раз в неделю)**
```
Ты — вредный ревьюер Godot-кода. Проверь [файлы] по CONTEXT.md и по списку
антипаттернов docs/research/production-and-ai-workflow-supplement.md §7:
god objects, get_node-пути, call down/signal up, типы, данные в коде вместо .tres,
утечки connect без disconnect, нагрузка в _process.
Вывод: таблица (файл:строка | проблема | critical/warning/info | фикс). Код не пиши.
```

**№5. Баланс через ресурсы**
```
Спроектируй [ModuleDefinition/EnemyDefinition] поля под CONTEXT.md.
Сгенерируй N .tres-вариантов с нарастающей силой по спредшиту
docs/research/design-and-release-supplement.md §3.3. Объясни формулу и как
тюнить без правки кода. Вывод: код Definition + содержимое .tres текстом.
Проверка: ресурсы грузятся в редакторе без ошибок импорта.
```

**№6. Дебаг**
```
Ошибка: [stacktrace]. Код: [файл]. Цель: [что должно]. Уже пробовал: […].
Ищи root cause, не симптом. Минимальный фикс + проверка, что не сломал соседей.
После правки — GUT-прогон по затронутому модулю; доложи результат.
```

**№7. Генератор графа с инвариантами**
```
Реализуй RouteGraph.generate(seed: int) -> RouteGraph как чистую функцию в core/
(без узлов сцены) по инвариантам G1–G8 из design-and-release-supplement §4.2.
RNG — локальный RandomNumberGenerator из SeedService (поток graph).
Напиши тесты §4.3 на 100 сидах. Проверка: GUT-прогон зелёный.
```

**№8. UI-экран ставок (RiskPanel)**
```
Сверстай RiskPanel (Control, контейнеры, из контекста design-supplement §8):
строки через tr() ключей, показ: награда узла, известная угроза, потери при смерти,
кнопка "к ближайшей эвакуации". Данные — параметром от ExpeditionController,
решение — сигналом вверх. Проверка: сцена открывается отдельно (F6) с тестовыми данными.
```

**№9. Конец сессии (обновление памяти)**
```
Сессия закончена. Обнови docs/status.md: сделано / в работе / баги / следующие 3 задачи /
изменённые файлы. Если принято неочевидное решение — оформи черновик ADR-00N
в docs/adr/. Синхронизируй CONTEXT.md при смене правил.
```

> Правила хороших промптов (принципы): один промт — одна система; сначала план, потом код; контекст — файлами, не пересказом; каждая задача заканчивается проверкой (§9.1).

---

## 11. One-Page GDD, заполненный под проект

Готовый артефакт-«паспорт» игры (полезен как самая короткая выжимка для ИИ и для страницы itch.io):

```markdown
# Threshold of Light (Порог Света)

Elevator pitch: Управляй живым маяком на границе тьмы: строй модули в хабе
и отправляй разведчика в короткие экспедиции — реши, рисковать глубже или
эвакуироваться с добычей, потому что модули меняют правила экспедиции,
а экспедиции меняют хаб.

Жанр: 2D hub-builder + extraction-lite + action-roguelite, top-down.
Референсы: Slay the Spire (граф), Loop Hero (отступление по ставкам),
Dome Keeper (добыча↔база), Hades (run/meta), Tarkov (экстракция).
Платформа: PC (Windows), позже Web. Движок: Godot 4.7, GDScript, Compatibility.
Аудитория: игроки в сессионные roguelite 15-30 минут, любители "push your luck".

Core loop:
построй модуль → выбери маршрут → сражайся на узлах →
реши: глубже или эвакуация → добыча в постройку → правила изменились.

Ключевые механики:
1. Хаб-маяк: 5 модулей × 3 уровня, каждый меняет >=1 правило экспедиции с trade-off.
2. Экспедиция: seed-граф из 7 узлов, sequential choice 2-3 варианта, 5-12 минут.
3. Push-your-luck: нестабильная добыча теряется при смерти; эвакуация её банкует.
4. Бой: 1 оружие, 1 способность, 1 уклонение, 3 врага, телеграфы.
5. Мета: 4 ресурса (Свет/Материалы/Воспоминания/Нестабильная добыча);
   горизонтальные разблокировки вместо "+X%".

Win condition: пройти узел guardian и вернуться (конец маршрута).
Lose condition: смерть = потеря нестабильной добычи; закреплённое сохраняется.

Art style: 2D top-down; greybox → пиксель-арт; ключевой визуал — свет маяка
против тьмы (PointLight2D + окклюдеры, additive-fake glow).

Хук: твой хаб — это билд; каждая экспедиция — новые правила, потому что
ты сам их собрал.
```

---

## 12. Чек-листы операционки

### Старт сессии с ИИ
- [ ] Новая сессия; агент прочитал `CONTEXT.md` (+ `docs/status.md`).
- [ ] Задача — одна, сформулирована как шаг (промт №1).
- [ ] Приложены: соответствующий раздел промта/спеки + research-раздел.
- [ ] Получен и утверждён план с проверками.

### Конец сессии
- [ ] Проверки зелёные (lint, тесты, экспорт — что применимо).
- [ ] Коммит маленький и понятный.
- [ ] `docs/status.md` обновлён (промт №9); решения → черновик ADR.

### Ship-ready (повторять с Phase 2)
- [ ] `export_presets.cfg` в репозитории; CI идёт в `main` зелёным.
- [ ] Butler-публикация в закрытый itch-канал работает одной командой.
- [ ] Плейтест-каданс §3.2 соблюдён; гипотезы промта §18 проверены.
- [ ] Скоуп-фриз объявлен; известные баги перечислены.

---

## 13. Источники

**Коллекция пользователя (проверенные позиции отмечены ✅):**
- Rami Ismail — «Prototypes & Vertical Slice», LTPF (2022) ✅ https://ltpf.ramiismail.com/prototypes-and-vertical-slice/ + «Milestones» https://ltpf.ramiismail.com/milestones/
- simondalvai — Godot best practices (структура папок, директория на сцену) ✅ https://simondalvai.org/blog/godot-best-practices/
- Godot docs — Project organization (snake_case для файлов) ✅ https://docs.godotengine.org/en/stable/tutorials/best_practices/project_organization.html
- gdtoolkit (Scony) — `gdlint`/`gdformat`, pip ✅ https://pypi.org/project/gdtoolkit/
- GDQuest — Event Bus singleton; Entity-Component pattern ✅ https://gdquest.com/tutorial/godot/design-patterns/event-bus-singleton
- GUT (bitwes/Gut) — v9 для Godot 4, headless CLI ✅ https://github.com/bitwes/Gut
- barichello/godot-ci — Docker-контейнер экспорта ✅ https://github.com/abarichello/godot-ci
- itch.io butler — дельта-загрузки в каналы ✅ https://itch.io/docs/butler/
- Anthropic — Claude Code Best Practices (проверяемый цикл, контекст, CLAUDE.md) ✅ https://www.anthropic.com/engineering/claude-code-best-practices
- addyosmani — Good Spec (спека как source of truth, 6 областей) https://addyosmani.com/blog/good-spec
- Ask a Game Dev — vertical slice glossary; Indie Game Academy; Game Design Skills (One-Page GDD шаблоны); GameDevArtisan (call down, signal up); abmarnie (архитектура важна с масштабом); youssof20/savestate (SaveManager-паттерны); Camperotacti (resource bus); requesty.ai / dev.to (сравнение ИИ-инструментов); Kenney.nl; bfxr; Aseprite; Audacity; Suno/Udio (лецензии — перепроверять на дату генерации).

**Независимая верификация (этот документ):** факты по Исмаилу, simondalvai, gdtoolkit и Godot naming conventions подтверждены независимым поиском (июль 2026). Остальная фактура коллекции согласуется с или ссылается на уже верифицированную базу документов `docs/research/`.

---

> 🛠️ **Резюме дополнения №3:** коллекция «Части 1–4» стоит добавлять — но не целиком: её инженерная половина уже покрыта вашими документами, а ценность концентрируется в четырёх местах — различие **прототип/слайс** (§2), **production-SaveManager** (§6), **CI «always shippable»** (§5) и **проверяемый AI-цикл с промптом-библиотекой** (§9–10). Плюс одна бесплатная находка: конфликт именования в `CONTEXT.md`, разрешённый в §8.

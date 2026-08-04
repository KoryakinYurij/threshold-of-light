@echo off
rem Прогон проверок каркаса (run_tests.tscn) и смоук-теста боя (combat_smoke.tscn).
rem Сначала импорт: новые скрипты с class_name должны попасть в кэш, иначе
rem «Could not find type ...» (см. build.cmd, шаг [1/3]).
rem Ненулевой код возврата = красный тест.
chcp 65001 >nul
setlocal

set "PROJECT_DIR=%~dp0.."
if not defined GODOT set "GODOT=godot.cmd"
where %GODOT% >nul 2>&1 || set "GODOT=D:\Tools\Godot\4.7.1\godot.cmd"

pushd "%PROJECT_DIR%"
call "%GODOT%" --headless --path . --import
if errorlevel 1 goto :done
call "%GODOT%" --headless --path . res://tests/run_tests.tscn
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" goto :done
call "%GODOT%" --headless --path . res://tests/combat_smoke.tscn
set "RC=%ERRORLEVEL%"
:done
popd

endlocal & exit /b %RC%

@echo off
rem Прогон проверок каркаса (tests/run_tests.tscn). Ненулевой код возврата = красный тест.
chcp 65001 >nul
setlocal

set "PROJECT_DIR=%~dp0.."
if not defined GODOT set "GODOT=godot.cmd"
where %GODOT% >nul 2>&1 || set "GODOT=D:\Tools\Godot\4.7.1\godot.cmd"

pushd "%PROJECT_DIR%"
call "%GODOT%" --headless --path . res://tests/run_tests.tscn
set "RC=%ERRORLEVEL%"
popd

endlocal & exit /b %RC%

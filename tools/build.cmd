@echo off
rem Сборка Windows-билда одной командой: импорт -> тесты -> экспорт.
rem   tools\build.cmd            полный прогон
rem   tools\build.cmd --no-tests пропустить тесты
chcp 65001 >nul
setlocal

set "PROJECT_DIR=%~dp0.."
set "PRESET=Windows Desktop"
set "OUT_DIR=%PROJECT_DIR%\build\windows"
set "OUT_EXE=%OUT_DIR%\ThresholdOfLight.exe"

if not defined GODOT set "GODOT=godot.cmd"
where %GODOT% >nul 2>&1 || set "GODOT=D:\Tools\Godot\4.7.1\godot.cmd"

pushd "%PROJECT_DIR%"

echo [1/3] Импорт ресурсов
"%GODOT%" --headless --path . --import
if errorlevel 1 goto :fail_import

if "%~1"=="--no-tests" (
	echo [2/3] Тесты пропущены
) else (
	echo [2/3] Тесты
	call "%~dp0test.cmd"
	if errorlevel 1 goto :fail_tests
)

echo [3/3] Экспорт
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
"%GODOT%" --headless --path . --export-release "%PRESET%" "%OUT_EXE%"
if errorlevel 1 goto :fail_export
if not exist "%OUT_EXE%" goto :fail_export

echo.
echo ГОТОВО: %OUT_EXE%
popd
endlocal & exit /b 0

:fail_import
echo.
echo ОШИБКА: импорт не прошёл
goto :fail

:fail_tests
echo.
echo ОШИБКА: тесты красные, сборка остановлена
goto :fail

:fail_export
echo.
echo ОШИБКА: экспорт не прошёл. Проверь, что установлены шаблоны экспорта 4.7.1
echo         (%%APPDATA%%\Godot\export_templates\4.7.1.stable) — см. docs/prototype/BUILD.md
goto :fail

:fail
popd
endlocal & exit /b 1

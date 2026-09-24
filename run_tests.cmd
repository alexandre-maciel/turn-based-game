@echo off
rem Roda os testes em modo headless. Uso: run_tests.cmd [--only=parte_do_nome]
cd /d "%~dp0"
rem Aceita o Godot como pasta (zip extraído, com o _console.exe) ou como exe solto.
set GODOT=Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe
if not exist "%GODOT%" set GODOT=%~dp0Godot_v4.7.2-stable_win64.exe
"%GODOT%" --headless --path . --import >nul 2>&1
"%GODOT%" --headless --path . --script res://tests/run_tests.gd -- %*

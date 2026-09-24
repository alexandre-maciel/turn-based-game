#!/usr/bin/env bash
# Roda os testes em modo headless. Uso: bash run_tests.sh [--only=parte_do_nome]
set -u
cd "$(dirname "$0")"
GODOT="Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe"
# Aceita o Godot como pasta (zip extraído, com o _console.exe) ou como exe solto.
[ -f "$GODOT" ] || GODOT="./Godot_v4.7.2-stable_win64.exe"
# Importa antes (registra class_name novos e arte nova).
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --script res://tests/run_tests.gd -- "$@"

#!/bin/bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

input=$(/bin/cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Last API call tokens
last_call=$(echo "$input" | jq -r '.context_window.current_usage')
if [ "$last_call" != "null" ]; then
    last_input=$(echo "$last_call" | jq -r '.input_tokens // 0')
    last_output=$(echo "$last_call" | jq -r '.output_tokens // 0')
    last_tokens="[$((last_input + last_output))]"
else
    last_tokens="[0]"
fi

# Session time from cost.total_duration_ms
duration_sec=$((duration_ms / 1000))
hours=$((duration_sec / 3600))
minutes=$(((duration_sec % 3600) / 60))
seconds=$((duration_sec % 60))
if [ $hours -gt 0 ]; then
    session_time="${hours}h ${minutes}m"
elif [ $minutes -gt 0 ]; then
    session_time="${minutes}m ${seconds}s"
else
    session_time="${seconds}s"
fi

# Progress bar with Unicode block characters
bar_width=20
if [ -z "$used_pct" ] || [ "$used_pct" = "null" ]; then
    used_pct=0
fi
filled=$((used_pct * bar_width / 100))
empty=$((bar_width - filled))

# Build the bar string character by character
filled_bar=""
empty_bar=""
for ((i=0; i<filled; i++)); do filled_bar+="█"; done
for ((i=0; i<empty; i++)); do empty_bar+="░"; done

# Catppuccin Mocha colors (ANSI 256-color)
LAVENDER='\033[38;5;147m'
BLUE='\033[38;5;111m'
GREEN='\033[38;5;151m'
MAUVE='\033[38;5;183m'
PEACH='\033[38;5;216m'
SKY='\033[38;5;117m'
RESET='\033[0m'
BG_CRUST='\033[48;5;235m'
FILL_COLOR='\033[38;5;151m'
EMPTY_COLOR='\033[38;5;240m'

# Context bar with dark background
context_bar="${BG_CRUST}${FILL_COLOR}${filled_bar}${RESET}${BG_CRUST}${EMPTY_COLOR}${empty_bar}${RESET} ${MAUVE}${used_pct}%${RESET}"

printf '%b' "${LAVENDER}${cwd}${RESET} | ${BLUE}${model}${RESET} | ${context_bar} | ${PEACH}$((total_input / 1000))k/$((total_output / 1000))k${RESET} ${SKY}${last_tokens}${RESET} | ${MAUVE}${session_time}${RESET}\n"

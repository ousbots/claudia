#!/bin/bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Catppuccin Mocha colors (ANSI 256-color)
LAVENDER='\033[38;5;147m'
BLUE='\033[38;5;111m'
GREEN='\033[38;5;151m'
MAUVE='\033[38;5;183m'
PEACH='\033[38;5;216m'
SKY='\033[38;5;117m'
SUNRISE='\033[38;5;222m'
SUNSET='\033[38;5;210m'

BG_CRUST='\033[48;5;235m'
EMPTY_COLOR='\033[38;5;240m'
RESET='\033[0m'

# Build a progress bar with color-coded percentage.
build_progress_bar() {
    local pct=$1
    local width=12
    local f=$((pct * width / 100))
    local e=$((width - f))
    local fb="" eb=""
    for ((i=0; i<f; i++)); do fb+="█"; done
    for ((i=0; i<e; i++)); do eb+="░"; done
    local color
    color=$(rate_color "$pct")
    echo "${BG_CRUST}${color}${fb}${RESET}${BG_CRUST}${EMPTY_COLOR}${eb}${RESET} ${color}${pct}%${RESET}"
}

# Format milliseconds as a human-readable duration.
format_duration() {
    local ms=$1
    local sec=$((ms / 1000))
    local h=$((sec / 3600))
    local m=$(((sec % 3600) / 60))
    local s=$((sec % 60))
    if [ $h -gt 0 ]; then
        echo "${h}h ${m}m"
    elif [ $m -gt 0 ]; then
        echo "${m}m ${s}s"
    else
        echo "${s}s"
    fi
}

if [ -z "$used_pct" ] || [ "$used_pct" = "null" ]; then
    used_pct=0
fi

# Format seconds until reset as a human-readable countdown.
format_epoch() {
    local reset_epoch=$1
    local now
    now=$(date +%s)
    local diff=$((reset_epoch - now))
    if [ $diff -le 0 ]; then
        echo "now"
        return
    fi
    local d=$((diff / 86400))
    local h=$(((diff % 86400) / 3600))
    local m=$(((diff % 3600) / 60))
    if [ $d -gt 0 ]; then
        echo "${d}d${h}h"
    elif [ $h -gt 0 ]; then
        echo "${h}h${m}m"
    else
        echo "${m}m"
    fi
}

# Pick a color based on usage percentage: green < 50, yellow < 80, red >= 80.
rate_color() {
    local pct=$1
    if [ "$pct" -ge 80 ]; then
        echo "$SUNSET"
    elif [ "$pct" -ge 50 ]; then
        echo "$SUNRISE"
    else
        echo "$GREEN"
    fi
}

input=$(/bin/cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir')
model=$(echo "$input" | jq -r '.model.display_name')
total_input=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
total_output=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Rate limits
five_h_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty' | cut -d. -f1)
five_h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty' | cut -d. -f1)
seven_d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# Last API call tokens
last_call=$(echo "$input" | jq -r '.context_window.current_usage')
if [ "$last_call" != "null" ]; then
    last_input=$(echo "$last_call" | jq -r '.input_tokens // 0')
    last_output=$(echo "$last_call" | jq -r '.output_tokens // 0')
    last_tokens="[$((last_input + last_output))]"
else
    last_tokens="[0]"
fi

context_bar=$(build_progress_bar "$used_pct")

daily_rate_limit=""
if [ -n "$five_h_pct" ]; then
    daily_rate_limit=$(build_progress_bar "$five_h_pct")
    [ -n "$five_h_reset" ] && daily_rate_limit+=" ${MAUVE}$(format_epoch "$five_h_reset")${RESET}"
fi

weekly_rate_limit=""
if [ -n "$seven_d_pct" ]; then
    weekly_rate_limit=$(build_progress_bar "$seven_d_pct")
    [ -n "$seven_d_reset" ] && weekly_rate_limit+=" ${MAUVE}$(format_epoch "$seven_d_reset")${RESET}"
fi

# Build output.
output="${LAVENDER}${cwd}${RESET} | ${BLUE}${model}${RESET} | ${context_bar}"
[ -n "$daily_rate_limit" ] && output+=" | ${daily_rate_limit}"
[ -n "$weekly_rate_limit" ] && output+=" | ${weekly_rate_limit}"
output+=" | ${PEACH}$((total_input / 1000))k/$((total_output / 1000))k${RESET} ${SKY}${last_tokens}${RESET} | ${MAUVE}$(format_duration "$duration_ms")${RESET}"

printf '%b' "${output}\n"

#!/usr/bin/env bash
# Claude Code status line — Catppuccin-style, merged

set -f

input=$(cat)
[ -z "$input" ] && printf "Claude" && exit 0

# ===== Colors (Catppuccin Mocha accents — brighter than Macchiato, same family) =====
blue='\033[38;2;137;180;250m'    # Blue    #89b4fa
amber='\033[38;2;249;226;175m'   # Yellow  #f9e2af  (Opus tag)
cyan='\033[38;2;148;226;213m'    # Teal    #94e2d5  (Haiku tag)
green='\033[38;2;166;227;161m'   # Green   #a6e3a1
orange='\033[38;2;250;179;135m'  # Peach   #fab387
yellow='\033[38;2;249;226;175m'  # Yellow  #f9e2af
red='\033[38;2;243;139;168m'     # Red     #f38ba8
magenta='\033[38;2;203;166;247m' # Mauve   #cba6f7
dim='\033[38;2;147;154;183m'     # Overlay2 #939ab7 — muted but legible
reset='\033[0m'

sep=" ${dim}│${reset} "

# ===== Helpers =====

fmt_time() {
    local m="$1"
    [ -z "$m" ] && return
    if [ "$m" -lt 60 ]; then
        echo "${m}m"
    elif [ "$m" -lt 1440 ]; then
        local h=$((m / 60)) rem=$((m % 60))
        [ "$rem" -eq 0 ] && echo "${h}h" || echo "${h}h${rem}m"
    else
        local d=$((m / 1440)) rh=$(( (m % 1440) / 60 ))
        [ "$rh" -eq 0 ] && echo "${d}d" || echo "${d}d${rh}h"
    fi
}

# projected% = used% × duration / elapsed
# ↑ will exhaust before reset | → on pace | ↓ under-consuming
pace_arrow() {
    local used_pct="$1" resets_at="$2" duration="$3" now="$4"
    [ -z "$used_pct" ] || [ -z "$resets_at" ] && return
    local elapsed=$(( now - (resets_at - duration) ))
    [ "$elapsed" -le $(( duration / 50 )) ] && return
    local projected
    projected=$(echo "$used_pct * $duration / $elapsed" | bc 2>/dev/null)
    [ -z "$projected" ] && return
    local time_left_m remaining_m time_color time_left_fmt arrow_str
    time_left_m=$(echo "(100 - $used_pct) * $elapsed / $used_pct / 60" | bc 2>/dev/null)
    remaining_m=$(( (resets_at - now) / 60 ))

    time_color="$green"
    if [ -n "$time_left_m" ] && [ "$remaining_m" -gt 0 ] 2>/dev/null; then
        local ratio_pct=$(( time_left_m * 100 / remaining_m ))
        if   [ "$ratio_pct" -lt 33 ]; then time_color="$red"
        elif [ "$ratio_pct" -lt 66 ]; then time_color="$orange"
        fi
    fi

    if   [ "$projected" -gt 115 ]; then arrow_str="${red}↑${reset}"
    elif [ "$projected" -gt 85  ]; then arrow_str="${yellow}→${reset}"
    else                                 printf " ${green}↓${reset}"; return
    fi

    local tl=""
    [ -n "$time_left_m" ] && tl=" ${time_color}$(fmt_time "$time_left_m")${reset}"
    printf " %b%b" "$arrow_str" "$tl"
}

add() { [ -z "$out" ] && out+="$1" || out+="${sep}$1"; }

# ===== Extract data =====
model=$(echo "$input" | jq -r '.model.display_name // empty')
cwd=$(echo "$input"   | jq -r '.workspace.current_dir // .cwd // empty')
used=$(echo "$input"  | jq -r '.context_window.used_percentage // empty')
lines_added=$(echo "$input"   | jq -r '.cost.total_lines_added // empty')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // empty')

# "Claude Opus 4.6 (1M context)" → "Opus 4.6 (1M)"
model="${model#Claude }"
model="${model/ context/}"

# Shortened path: ~/dotfiles, ~, or basename
short_cwd=""
if [ -n "$cwd" ]; then
    case "$cwd" in
        "$HOME")   short_cwd="~" ;;
        "$HOME"/*) short_cwd="~/$(basename "$cwd")" ;;
        *)         short_cwd="$(basename "$cwd")" ;;
    esac
fi

branch=""
[ -n "$cwd" ] && branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)

now=$(date +%s)
rl_five=$(echo "$input"      | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_seven=$(echo "$input"     | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_resets_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_resets_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# ===== Assemble =====
out=""

# Model — amber for Opus, cyan for Haiku, blue otherwise
if [ -n "$model" ]; then
    model_color="$blue"
    case "$model" in *Opus*)  model_color="$amber" ;; *Haiku*) model_color="$cyan" ;; esac
    add "${model_color}${model}${reset}"
fi

# CWD
[ -n "$short_cwd" ] && add "${dim}${short_cwd}${reset}"

# Git branch
[ -n "$branch" ] && add "${dim}⎇${reset} ${magenta}${branch}${reset}"

# Context window %
if [ -n "$used" ]; then
    ctx_pct=$(printf "%.0f" "$used")
    if   [ "$ctx_pct" -ge 80 ]; then ctx_color="$red"
    elif [ "$ctx_pct" -ge 50 ]; then ctx_color="$orange"
    else ctx_color="$cyan"; fi
    add "${dim}ctx${reset} ${ctx_color}${ctx_pct}%${reset}"
fi

# Rate limits — 5h
if [ -n "$rl_five" ]; then
    f=$(printf "%.0f" "$rl_five")
    arrow5=$(pace_arrow "$rl_five" "$rl_resets_5h" 18000 "$now")

    if   [ "$f" -ge 80 ]; then pct_color="$red"
    elif [ "$f" -ge 50 ]; then pct_color="$yellow"
    else pct_color="$cyan"; fi

    t5=""
    [ -n "$rl_resets_5h" ] && [ "$rl_resets_5h" -gt "$now" ] 2>/dev/null && \
        t5=$(fmt_time $(( (rl_resets_5h - now) / 60 )))

    seg="${dim}5h${reset} ${pct_color}${f}%${reset}${arrow5}"
    [ -n "$t5" ] && seg="${seg} ${dim}· reset ${t5}${reset}"
    add "$seg"
fi

# Rate limits — 7d
if [ -n "$rl_seven" ]; then
    s=$(printf "%.0f" "$rl_seven")
    arrow7=$(pace_arrow "$rl_seven" "$rl_resets_7d" 604800 "$now")

    t7=""
    [ -n "$rl_resets_7d" ] && [ "$rl_resets_7d" -gt "$now" ] 2>/dev/null && \
        t7=$(fmt_time $(( (rl_resets_7d - now) / 60 )))

    seg="${dim}7d${reset} ${cyan}${s}%${reset}${arrow7}"
    [ -n "$t7" ] && seg="${seg} ${dim}· reset ${t7}${reset}"
    add "$seg"
fi

# Lines changed (+added -removed)
if [ -n "$lines_added" ] || [ -n "$lines_removed" ]; then
    la="${lines_added:-0}"
    lr="${lines_removed:-0}"
    if [ "$la" -gt 0 ] 2>/dev/null || [ "$lr" -gt 0 ] 2>/dev/null; then
        add "${green}+${la}${reset} ${red}-${lr}${reset}"
    fi
fi

printf "%b\n" "$out"

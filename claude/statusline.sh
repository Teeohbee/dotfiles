#!/usr/bin/env bash
# Claude Code status line - Monokai Pro edition
#
# Segments (in order): working dir | git branch/dirty | model | context gauge | 5h window gauge
# Reads the status line JSON from stdin. Requires: bash, jq, git, awk.

input=$(cat)

# Hand the payload to Barista (session panel) when it's checked out; never slows or breaks this line.
barista_bridge=~/Projects/barista/hooks/status_bridge.py
[ -f "$barista_bridge" ] && { printf '%s' "$input" | BARISTA_CLAUDE_PID=$PPID python3 "$barista_bridge" >/dev/null 2>&1 & }

GAUGE_CELLS=10             # width of each braille meter, in cells

# ---- Colour depth -----------------------------------------------------------
# Truecolour gives the exact palette; flip USE_TRUECOLOR=0 to force the 256-colour palette.
USE_TRUECOLOR=1
case "$COLORTERM" in
  truecolor|24bit) : ;;                              # explicitly supported
  "") : ;;                                           # unknown - assume yes
  *) USE_TRUECOLOR=0 ;;                              # explicitly something lesser
esac

RESET=$'\033[0m'
DIM=$'\033[2m'

# fg R G B [C256] -> foreground SGR (truecolour, or the 256 fallback if not).
fg() {
  if [ "$USE_TRUECOLOR" = 1 ]; then
    printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"
  else
    printf '\033[38;5;%dm' "${4:-15}"
  fi
}

# ---- Monokai Pro palette ---------------------------------------------------
CYAN=$(fg    120 220 232 117)   # working directory
GREEN=$(fg   169 220 118 150)   # git clean / low usage
AMBER=$(fg   255 216 102 221)   # git dirty / mid usage
RED=$(fg     255  97 136 204)   # git conflict / high usage
PURPLE=$(fg  171 157 242 141)   # model
GIT_FG=$(fg     120 190 130  108)  # git branch - softer sage, easier on the eye
SEPC=$(fg    114 112 114 243)   # separator

# ---- Glyphs -----------------------------------------------------------------
# Braille meter glyphs (literal UTF-8 so they work on macOS bash 3.2).
B_FULL='⣿'                 # U+28FF, all 8 dots - filled cell
B_TRACK='⣿'                # empty cell - same glyph, rendered dim

# Icons. Nerd Font versions need a patched font; set USE_NERD_FONT=0 to fall back
# to plain Unicode if they render as tofu boxes. Built via hex bytes for bash 3.2.
USE_NERD_FONT=1
[ "$TERM_PROGRAM" = "iTerm.app" ] && USE_NERD_FONT=0
if [ "$USE_NERD_FONT" = 1 ]; then
  GIT_ICON=$(printf '\xee\x9c\xa5')    # U+E725 nf-dev-git_branch
  MODEL_ICON=$(printf '\xef\x8b\x9b')  # U+F2DB nf-fa-microchip
else
  GIT_ICON='⎇'                         # U+2387
  MODEL_ICON='⬢'                       # U+2B22
fi

# Gradient stops for a scheme: "r0 g0 b0  r1 g1 b1  r2 g2 b2" (low / mid / high).
grad_stops() {
  case "$1" in
    usage)     echo "169 220 118  255 216 102  255 97 136" ;;  # green -> yellow -> red
    synthwave) echo "170 95 255   255 70 180  255 155 70" ;;  # electric violet -> hot pink -> sunset orange
    *)         echo "120 220 232  171 157 242  255 97 136" ;;  # cyan -> purple -> red
  esac
}

# Gradient colour for a 0-100 percentage. $1=percent, $2=scheme. Prints an SGR.
# Falls back to the threshold colour in 256-colour mode.
grad_colour() {
  local pct="$1" stops
  if [ "$USE_TRUECOLOR" = 1 ]; then
    stops=$(grad_stops "$2")
    awk -v p="$pct" -v s="$stops" 'BEGIN{
      split(s, c);
      f=p/100; if(f<0)f=0; if(f>1)f=1;
      if (f<0.5) { t=f/0.5;       r=c[1]+(c[4]-c[1])*t; g=c[2]+(c[5]-c[2])*t; b=c[3]+(c[6]-c[3])*t }
      else       { t=(f-0.5)/0.5; r=c[4]+(c[7]-c[4])*t; g=c[5]+(c[8]-c[5])*t; b=c[6]+(c[9]-c[6])*t }
      printf "\033[38;2;%d;%d;%dm", r, g, b
    }'
  else
    usage_colour "$pct"
  fi
}

# Threshold colour for a usage percentage (higher = worse). 256-mode gradient uses this.
usage_colour() {
  local u
  u=$(printf '%.0f' "$1")
  if [ "$u" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$u" -ge 50 ]; then printf '%s' "$AMBER"
  else printf '%s' "$GREEN"; fi
}

# Render the meter: $1=percent (0-100), $2=cell count, $3=scheme.
# Truecolour: each filled cell fades along the scheme's gradient by its position
# (btop-style), so the leading edge's colour signals how full it is. Track is dim.
braille_bar() {
  local pct="$1" cells="$2" stops
  if [ "$USE_TRUECOLOR" = 1 ]; then
    stops=$(grad_stops "$3")
    awk -v p="$pct" -v cells="$cells" -v s="$stops" 'BEGIN{
      split(s, c);
      if(p<0)p=0; if(p>100)p=100;
      filled=int(p/100*cells + 0.5);
      full="'"$B_FULL"'"; track="'"$B_TRACK"'";
      for (i=0; i<cells; i++) {
        if (i<filled) {
          f=(cells>1)?i/(cells-1):0;
          if (f<0.5) { t=f/0.5;       r=c[1]+(c[4]-c[1])*t; gg=c[2]+(c[5]-c[2])*t; b=c[3]+(c[6]-c[3])*t }
          else       { t=(f-0.5)/0.5; r=c[4]+(c[7]-c[4])*t; gg=c[5]+(c[8]-c[5])*t; b=c[6]+(c[9]-c[6])*t }
          printf "\033[38;2;%d;%d;%dm%s", r, gg, b, full;
        } else {
          printf "\033[38;2;64;62;65m%s", track;   # dim rail
        }
      }
      printf "\033[0m";
    }'
  else
    local filled i out
    filled=$(awk -v p="$pct" -v c="$cells" 'BEGIN{ if(p<0)p=0; if(p>100)p=100; printf "%.0f", p/100*c }')
    out="$(usage_colour "$pct")"
    for (( i=0; i<cells; i++ )); do
      if [ "$i" -lt "$filled" ]; then
        out="${out}${B_FULL}"
      else
        [ "$i" -eq "$filled" ] && out="${out}${RESET}${DIM}"
        out="${out}${B_TRACK}"
      fi
    done
    printf '%s%s' "$out" "$RESET"
  fi
}

# Compact token count, matching /context (e.g. 74000 -> 74k, 1200 -> 1.2k).
fmt_tokens() {
  awk -v n="$1" 'BEGIN{
    if (n+0 >= 1000000)   { s=sprintf("%.1f", n/1000000); sub(/\.0$/,"",s); printf "%sm", s }
    else if (n+0 >= 1000) { s=sprintf("%.1f", n/1000);    sub(/\.0$/,"",s); printf "%sk", s }
    else                    printf "%d", n
  }'
}

# ---- Parse all fields in a single jq pass -----------------------------------
# Joined on ASCII Unit Separator (0x1f), NOT tab: tab is IFS-whitespace, so read
# would collapse empty fields (null values) and shift every var left.
IFS=$'\x1f' read -r cwd model ctx_used ctx_rem ctx_tok ctx_size win_used < <(
  printf '%s' "$input" | jq -r '[
    .cwd,
    .model.display_name,
    .context_window.used_percentage,
    .context_window.remaining_percentage,
    .context_window.total_input_tokens,
    .context_window.context_window_size,
    .rate_limits.five_hour.used_percentage
  ] | map(if . == null then "" else tostring end) | join("")'
)
[ -z "$cwd" ] && cwd="$PWD"

# ---- 1. Working directory (shortened) ---------------------------------------
dir_display="$cwd"
case "$dir_display" in
  "$HOME") dir_display="~" ;;
  "$HOME"/*) dir_display="~${dir_display#"$HOME"}" ;;
esac

IFS='/' read -r -a dir_parts <<< "$dir_display"
part_count=${#dir_parts[@]}
if [ "$part_count" -gt 3 ]; then
  dir_display=".../${dir_parts[$((part_count-2))]}/${dir_parts[$((part_count-1))]}"
fi

# Dim the parent path, brighten (+bold) the current dir so the eye lands on it.
BOLD=$'\033[1m'
leaf="${dir_display##*/}"
parent="${dir_display%/*}"
if [ "$parent" = "$dir_display" ]; then
  dir_segment="${CYAN}${BOLD}${dir_display}${RESET}"                                   # no slash - all leaf
else
  dir_segment="${DIM}${CYAN}${parent}/${RESET}${CYAN}${BOLD}${leaf}${RESET}"
fi

# ---- 2. Git branch (name only) ----------------------------------------------
# symbolic-ref reads .git/HEAD directly - no worktree scan, so it stays fast even
# in huge repos. Detached HEAD falls back to a short SHA; empty if not a repo.
git_segment=""
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --quiet --short HEAD 2>/dev/null)
[ -z "$branch" ] && branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
[ -n "$branch" ] && git_segment="${GIT_FG}${GIT_ICON} ${branch}${RESET}"

# ---- 3. Model display name (drop the parenthetical, e.g. "(1M context)") ----
model="${model% (*}"
model_segment=""
[ -n "$model" ] && model_segment="${PURPLE}${MODEL_ICON} ${model}${RESET}"

# ---- 4. Context window usage gauge ------------------------------------------
# Prefer used_percentage; fall back to 100-remaining, then to tokens/size.
if [ -z "$ctx_used" ] && [ -n "$ctx_rem" ]; then
  ctx_used=$(awk -v r="$ctx_rem" 'BEGIN{printf "%.0f", 100 - r}')
fi
if [ -z "$ctx_used" ] && [ -n "$ctx_tok" ] && [ -n "$ctx_size" ]; then
  ctx_used=$(awk -v u="$ctx_tok" -v s="$ctx_size" 'BEGIN{ if (s+0>0) printf "%.0f", u/s*100 }')
fi

context_segment=""
if [ -n "$ctx_used" ]; then
  ctx_used=$(printf '%.0f' "$ctx_used")
  lc=$(grad_colour "$ctx_used" context)

  # Label with total tokens used (e.g. 74k). Fall back to a percentage when the
  # count isn't positive yet - a fresh session reports 0 tokens, and a bare "0"
  # reads as broken, whereas "0%" reads as a real (empty) measurement.
  if [ -n "$ctx_tok" ] && [ "$ctx_tok" -gt 0 ] 2>/dev/null; then
    ctx_label="$(fmt_tokens "$ctx_tok")"
  else
    ctx_label="${ctx_used}%"
  fi

  context_segment="${DIM}CTX${RESET} $(braille_bar "$ctx_used" "$GAUGE_CELLS" context) ${lc}${ctx_label}${RESET}"
fi

# ---- 5. 5-hour rate-limit window usage gauge --------------------------------
window_segment=""
if [ -n "$win_used" ]; then
  win_used=$(printf '%.0f' "$win_used")
  wl=$(grad_colour "$win_used" usage)
  window_segment="${DIM}5H${RESET} $(braille_bar "$win_used" "$GAUGE_CELLS" usage) ${wl}${win_used}%${RESET}"
fi

# ---- Assemble ---------------------------------------------------------------
segments=()
[ -n "$dir_segment" ] && segments+=("$dir_segment")
[ -n "$git_segment" ] && segments+=("$git_segment")
[ -n "$model_segment" ] && segments+=("$model_segment")
[ -n "$context_segment" ] && segments+=("$context_segment")
[ -n "$window_segment" ] && segments+=("$window_segment")

sep="${DIM}${SEPC} ╱ ${RESET}"
output=""
for i in "${!segments[@]}"; do
  if [ "$i" -eq 0 ]; then
    output="${segments[$i]}"
  else
    output="${output}${sep}${segments[$i]}"
  fi
done

printf '%s\n' "$output"

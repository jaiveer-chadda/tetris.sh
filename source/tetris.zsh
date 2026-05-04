#!/usr/bin/env zsh

# ——————————————————————————————————————————————————————————————————————————— #

tetris::buffer_setup() {
  local -r alt_buffer_on=$'\e[?1049h'
  local -r hide_cursor=$'⁠\e[?25l'

  echo -n "$alt_buffer_on$hide_cursor"
}

tetris::buffer_cleanup() {
  local -r alt_buffer_off=$'⁠\e[?1049l'
  local -r show_cursor=$'⁠\e[?25h'

  echo -n "$alt_buffer_off$show_cursor"
}

# ——————————————————————————————————————————————————————————————————————————— #

tetris::check_tty_size() {
  local -ri 10  width=$display_width
  local -ri 10 height=$display_height

  if (( COLUMNS < width || LINES < height )) {
    {
      echo 'tetris: Screen too small'
      echo "\tScreen has to be at least : ${(l:3:)width} cols x $height rows"
      echo "\tScreen is currently       : ${(l:3:)COLUMNS} cols x $LINES rows"
    } >&2
    return 1
  }
}

# ——————————————————————————————————————————————————————————————————————————— #

tetris::display_setup() {
  local -ri 10 padding_x=$(( ( COLUMNS - display_width  ) / 2 ))
  local -ri 10 padding_y=$(( ( LINES   - display_height ) / 2 ))

  local -r NL=$'\n'
  local -r x_pad_str="${(r:$padding_x:)}"
  local -r y_pad_str="${(pr:$padding_y::$NL:)}"

  # vertical offset of the grid
  echo "$y_pad_str"
  # add the padding before the first line, and after every newline
  echo "$x_pad_str${display//$NL/$NL$x_pad_str}"
}

# ——————————————————————————————————————————————————————————————————————————— #

tetris() {

  # — Admin & Setup ————————————————————————————————————————————————————————— #

  setopt local_options       # these options will be unset on function exit
  setopt local_traps         # the traps set below will be unset on exit
  setopt warn_create_global  # warn if one of the vars below will be global
  setopt warn_nested_var     # warn if a child process overwrites a local var

  # EXIT doesn't need to be sent `kill`, so just clean up the buffer
  trap 'tetris::buffer_cleanup' EXIT
  # restart the buffer etc. if we exited with ^Z, then return with `fg`
  trap 'tetris::buffer_setup' SIGCONT

  local sig
  # I know the 'SIG' in SIGINT, SIGTERM, etc. is superfluous,
  #  but I've left it in for clarity
  for sig in SIG{INT,TERM,QUIT,HUP,TSTP}; {
    # clean up buffer, unset the trap, and send the signal to the shell (`$$`)
    trap "tetris::buffer_cleanup; trap - $sig; kill -$sig \$\$" $sig
  }

  # — Import, Verify, & Display Screen ————————————————————————————————————— #

  local -r display="$( cat ../resources/out/display.txt )"

  local -ri 10 display_width=${#display/%$'\n'*}
  local -ri 10 display_height=$(( "${#display//[^$'\n']}" + 1 ))

  # make sure the screen's large enough to fit the display
  tetris::check_tty_size || return 1

  # ————————————————————————————————————————————— #

  tetris::buffer_setup   # set up the buffer and hide the cursor
  tetris::display_setup  # print the base display, without anything filled in

  # ————————————————————————————————————————————————————————————————————————— #

  while { :; }
}

# ——————————————————————————————————————————————————————————————————————————— #

# if __name__ == "__main__"
if [[ "$ZSH_EVAL_CONTEXT" == 'toplevel' ]] tetris "$@"

# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore TSTP

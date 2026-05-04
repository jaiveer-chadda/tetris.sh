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
  if (( COLUMNS < bg_width || LINES < bg_height )) {
    {
      echo 'tetris: Screen too small'
      echo "\tMinimum dimensions : ${(l:3:)bg_width} cols x $bg_height rows"
      echo "\tCurrent dimensions : ${(l:3:)COLUMNS} cols x $LINES rows"
    } >&2
    return 1
  }
}

# ——————————————————————————————————————————————————————————————————————————— #

tetris::background_setup() {
  local -ri 10 padding_x=$(( ( COLUMNS - bg_width  ) / 2 ))
  local -ri 10 padding_y=$(( ( LINES   - bg_height ) / 2 ))

  local -r NL=$'\n'
  local -r x_pad_str="${(r:$padding_x:)}"
  local -r y_pad_str="${(pr:$padding_y::$NL:)}"

  # vertical offset of the grid
  echo "$y_pad_str"
  # add the padding before the first line, and after every newline
  echo "$x_pad_str${background//$NL/$NL$x_pad_str}"
}

# ——————————————————————————————————————————————————————————————————————————— #

tetris() {

  # — Admin & Setup ————————————————————————————————————————————————————————— #

  setopt local_options       # these options will be unset on function exit
  setopt local_traps         # the traps set below will be unset on exit
  setopt warn_create_global  # warn if any of the vars set will become global
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

  local -r background="$( cat ../resources/out/background.txt )"

  local -ri 10 bg_width=${#background/%$'\n'*}
  local -ri 10 bg_height=$(( ${#background//[^$'\n']} + 1 ))

  # make sure the screen's large enough to fit the background
  tetris::check_tty_size || return 1

  # ————————————————————————————————————————————— #

  tetris::buffer_setup      # set up the buffer and hide the cursor
  tetris::background_setup  # print the background without any info filled in

  # ————————————————————————————————————————————————————————————————————————— #

  while { :; }
}

# ——————————————————————————————————————————————————————————————————————————— #

# if __name__ == "__main__"
if [[ "$ZSH_EVAL_CONTEXT" == 'toplevel' ]] tetris "$@"

# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore TSTP

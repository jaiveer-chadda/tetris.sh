#!/usr/bin/env zsh

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

tetris() {

  # — Admin & Setup ————————————————————————————————————————————————————————— #

  setopt local_options       # these options will be unset on function exit
  setopt local_traps         # the traps set below will be unset on exit
  setopt warn_create_global  # warn if one of the vars below will be global
  setopt warn_nested_var     # warn if a child process overwrites a local var

  # exit the buffer and re-show the cursor if the program ever stops
  trap 'tetris::buffer_cleanup' EXIT SIG{INT,QUIT,TERM,HUP,TSTP}
  # restart buffer and re-hide cursor if we exited with ^Z, then come back
  trap 'tetris::buffer_setup' SIGCONT

  # set up the buffer and hide the cursor
  tetris::buffer_setup

  # ————————————————————————————————————————————————————————————————————————— #

  sleep 1
  echo 'this is some text'
  sleep 1
  echo 'in fact, there'\''s more text'
  sleep 1

}

# ——————————————————————————————————————————————————————————————————————————— #

if [[ $ZSH_EVAL_CONTEXT == 'toplevel' ]] tetris

# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignore TSTP

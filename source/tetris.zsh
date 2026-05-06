#!/usr/bin/env zsh

# ——————————————————————————————————————————————————————————————————————————— #

tetris::buffer_setup   () { echo -n "$alt_buffer_on$hide_cursor"  ; }
tetris::buffer_cleanup () { echo -n "$alt_buffer_off$show_cursor" ; }

# ——————————————————————————————————————————————————————————————————————————— #

tetris::check_tty_size() {
  if (( _columns < bg_width || _lines < bg_height )) {
    {
      echo 'tetris: Screen too small'
      echo "\tMinimum dimensions : ${(l:3:)bg_width} cols x $bg_height rows"
      echo "\tCurrent dimensions : ${(l:3:)_columns} cols x $_lines rows"
    } >&2
    return 1
  }
}

# ——————————————————————————————————————————————————————————————————————————— #

tetris::redraw_background() {
  local -a term_size
  # leaving  `$( stty size )` unquoted, since it's just gonna be 2 raw numbers
  term_size=( $( stty size ) ) || return 1

  local -i 10 _lines=$term_size[1]
  local -i 10 _columns=$term_size[2]

  # make sure the screen's actually large enough to fit the background
  tetris::check_tty_size || return 1

  padding_x=$(( ( _columns - bg_width  ) / 2 ))
  padding_y=$(( ( _lines   - bg_height ) / 2 ))

  local x_pad_str="${(r:$padding_x:)}"
  local y_pad_str="${(pr:$padding_y::$NL:)}"

  echo -n "$clear_screen$cursor_home"
  echo "$y_pad_str"
  # add padding before the first line, and after every newline
  echo "$x_pad_str${background//$NL/$NL$x_pad_str}"
}

# ——————————————————————————————————————————————————————————————————————————— #

tetris() {

  # — Control Constants ————————————————————————————————————————————————————— #
  
  local -r  alt_buffer_on=$'\e[?1049h'
  local -r alt_buffer_off=$'⁠\e[?1049l'

  local -r    hide_cursor=$'⁠\e[?25l'
  local -r    show_cursor=$'⁠\e[?25h'

  local -r   clear_screen=$'\e[2J'
  local -r    cursor_home=$'\e[H'

  local -r NL=$'\n'

  # — Admin & Setup ————————————————————————————————————————————————————————— #

  setopt local_options       # these options will be unset on function exit
  setopt local_traps         # the traps set below will be unset on exit
  setopt warn_create_global  # warn if any of the vars set will become global

  # EXIT doesn't need to be sent `kill`, so just clean up the buffer
  trap 'tetris::buffer_cleanup' EXIT

  # I know the 'SIG' in SIGINT etc. is superfluous, but I kept it for clarity
  # SIGINT  : interrupt with ^C
  # SIGTERM : terminate with `kill`
  # SIGQUIT : quit with ^/ (more 'forceful' than ^C)
  # SIGHUP  : hang up when the term is quit
  # SIGTSTP : stop by backgrounding (^Z) the job
  local sig
  for sig in SIG{INT,TERM,QUIT,HUP,TSTP}; {
    # clean up buffer, unset the trap, and send the signal to the shell (`$$`)
    trap "tetris::buffer_cleanup; trap - $sig; kill -$sig \$\$" $sig
  }

  # restart the buffer if we exited with ^Z (or `bg`), then return with `fg`
  trap 'tetris::buffer_setup' SIGCONT
  trap 'tetris::redraw_background || return 1' SIGWINCH

  # — Import, Verify, & Display Screen ————————————————————————————————————— #

  local -r background="$( cat '../resources/out/background.txt' )"

  local -ri 10 bg_width=${#background/%$'\n'*}
  local -ri 10 bg_height=$(( ${#background//[^$'\n']} + 1 ))

  # ————————————————————————————————————————————— #

  # set up the buffer and hide the cursor
  tetris::buffer_setup
  # print the background without any info filled in
  tetris::redraw_background || return 1

  # ————————————————————————————————————————————————————————————————————————— #

  while { sleep 0.1; }
}

# ——————————————————————————————————————————————————————————————————————————— #

# if __name__ == "__main__"
if [[ "$ZSH_EVAL_CONTEXT" == 'toplevel' ]] {
  {
    # date $'+%y-%m-%d %R:%S\t' | tr -d $'\n'
    tetris "$@"
  } # 2>./2.log
  # cat './2.log'
}

# ——————————————————————————————————————————————————————————————————————————— #

# spell:ignoreRegExp /\w*TSTP/g

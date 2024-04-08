#!/usr/bin/env bash

# where is history written to?
HISTORY_FILE=~/history.txt

# dimensions
NUM_HISTORY_LINES=5
WINDOW_WIDTH=40

# 6 is cyan
HISTORY_FONT_COLOR=6

#-------------------------------------------------------------------------------
# below here hopefully nothing to adapt

print_line () {
    local row=$((1 + $1))
    local col=$2

    # move cursor to specific position
    echo -ne "\033[${row};${col}H"

    local string_length=${#4}
    local window_with_buffer=$((WINDOW_WIDTH + 2))
    local padding_length=$((window_with_buffer - string_length))
    local padding
    padding=$(printf '%.0s ' $(seq 1 ${padding_length}))
    local string_with_padding="${4}${padding}"
    local trimmed_string="${string_with_padding:0:${window_with_buffer}}"

    printf '%s%s%s' "$3" "${trimmed_string}" "$5"
    # To allow customizations
}

show_history_block() {
    # save the current cursor position
    echo -ne "\033[s"

    # save the default color
    default_color=$(tput sgr0)

    # change the font color
    color=$(tput setaf ${HISTORY_FONT_COLOR})
    echo -n "${color}"

    local terminal_width
    terminal_width=$(tput cols)
    local col=$((terminal_width - WINDOW_WIDTH - 4))
    local width_with_padding=$((WINDOW_WIDTH + 2))

    local repeated_chars
    repeated_chars=$(printf '%.0s_' $(seq 1 ${width_with_padding}))
    print_line 0 ${col} " " "${repeated_chars}" " "

    for (( i = 1; i <= NUM_HISTORY_LINES; i++ )); do
        local depth=$((NUM_HISTORY_LINES + 1 - i))
        local line
        line=$(tail -n ${depth} ${HISTORY_FILE} | head -n 1)
        print_line $i ${col} "|" " ${line}" "|"
    done

    local repeated_chars
    repeated_chars=$(printf '%.0s‾' $(seq 1 ${width_with_padding}))
    print_line $((1 + NUM_HISTORY_LINES)) ${col} " " "${repeated_chars}" " "

    # restore the default font color
    echo -n "${default_color}"

    # restore the cursor to the previous position
    echo -ne "\033[u"
    customizations
}

bash_log_commands () {
    # https://superuser.com/questions/175799
    [ -n "$COMP_LINE" ] && return  # do nothing if completing
    [[ "$PROMPT_COMMAND" =~ "$BASH_COMMAND" ]] && return # don't cause a preexec for $PROMPT_COMMAND
    local this_command
    this_command=$(HISTTIMEFORMAT='' history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//");
    echo "$this_command" >> "$HISTORY_FILE"
}

customizations () {
   # Make it possible to use customizations without affecting simple way
   # the defaults are to be used
   # Overide font color
   if [ ! -z ${HISTORY_FONT_COLOR} ]
   then 
      HISTORY_FONT_COLOR=${HISTORY_FONT_COLOR}	   
   fi

   #overide 
   if [ ! -z ${WINDOW_WIDTH} ]
   then
      WINDOW_WIDTH=${WINDOW_WIDTH}
   fi


   # overide font color
   if [ ! -z ${HISTORY_FILE} ]
   then
      HISTORY_FILE=${HISTORY_FILE}
   fi

   #overide number of lines displayes
   if [ ! -z ${  NUM_HISTORY_LINES} ]
   then
      NUM_HISTORY_LINES=${NUM_HISTORY_LINES}
   fi
 

}

# if history file does not exist, create it
# and write a couple of empty lines to it
if [ ! -f "$HISTORY_FILE" ]; then
    touch "$HISTORY_FILE"
    for (( i = 1; i <= NUM_HISTORY_LINES; i++ )); do
        echo "" >> "$HISTORY_FILE"
    done
fi

trap 'bash_log_commands' DEBUG

export PROMPT_COMMAND=show_history_block

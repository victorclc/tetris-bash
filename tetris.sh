#!/usr/bin/env bash

# BOARD CONFIGURATION

LINES=20
COLUMNS=10
TICK_DELAY=1

# BINDS CONFIGURATION

CMD_DOWN='s'

tetrominos=(
    "0010001000100010" # I-Block
    "0100011000100000" # S-block
    "0010011001000000" # Z-block
    "0110011000000000" # O-block
    "0110010001000000" # J block
    "0110001000100000" # L-block
    "0010001100100000" # T-Block
)

# GAME STATE VARIABLES

declare -a lines_state
current_piece_index=$((RANDOM % 7))
current_piece_rotation=0 # 0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees
current_piece_pos_y=0
current_piece_pos_x=0

j=0


function init() {
    for i in {0..20}; do
        lines_state[$i]="`printf '0%.0s' {0..10}`"
    done
}

function tick() {
    while true; do 
        echo -n $CMD_DOWN 
        sleep $TICK_DELAY
    done
}

function controller() {
    local command
    while true; do
        draw_board
        read -s -n 1 command

        case $command in
            $CMD_DOWN)
                move_down
                ;;
            *)
                ;;
        esac
    done
}

function draw_board() {
    clear
    declare -a board_view

    for line in "${lines_state[@]}"; do
        line=$(echo -e ${line//0/'. '})
        line=$(echo -e ${line//1/'[]'})
        printf "<!%s!>\n" "$line"
    done
    echo -n "<!=====================!>"
}

function input_reader() {
    while read -s -n 1 input; do
        echo $input
    done
}

function move_down() {
        lines_state[$j]="`printf '0%.0s' {0..10}`"
        ((j++))
        lines_state[$j]="`printf '1%.0s' {0..10}`"
}

function main() {
    init
    ((tick &);  input_reader) | controller
}

main 

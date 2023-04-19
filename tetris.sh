#!/usr/bin/env bash

LINES=20
COLUMNS=10
TICK_DELAY=1

CMD_DOWN=0

declare -a lines_state
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

#!/usr/bin/env bash

# BOARD CONFIGURATION

FIELD_HEIGHT=20
FIELD_WIDTH=10
TICK_DELAY=1

# BINDS CONFIGURATION

CMD_DOWN='s'
CMD_LEFT='a'
CMD_RIGHT='d'
CMD_ROTATE='r'

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

current_piece_index=$((RANDOM % 7))
current_piece_rotation=0 # 0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees
current_piece_pos_y=0
current_piece_pos_x=3 # FIELD_WIDTH / 5

declare playing_field 


function replace_char() {
    local string=$1
    local index=$2
    local new_char=$3

    local new_string="${string:0:index}${new_char}${string:index+1}"

    echo $new_string
}

function init() {
    for ((x = 0; x < $((FIELD_WIDTH * FIELD_HEIGHT)); x++)); do
        playing_field+="0"
    done
    for ((x = 0; x < $FIELD_WIDTH; x++)); do
        for ((y = 0; y < $FIELD_HEIGHT; y++)); do
            local index=$((y * FIELD_WIDTH + x))
            if (( x == 0 || x == FIELD_WIDTH - 1 )); then
                playing_field=$(replace_char $playing_field $index 9)
            elif (( y == FIELD_HEIGHT -1  )); then
                playing_field=$(replace_char $playing_field $index 8)
            fi
        done
    done
}

function tick() {
    sleep $TICK_DELAY
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
            $CMD_LEFT)
                move_left
                ;;
            $CMD_RIGHT)
                move_right
                ;;
            $CMD_ROTATE)
                rotate_piece
                ;;
            *)
                ;;
        esac
    done
}

function draw_board() {
    clear
    declare -a board_view

    for ((y = 0; y < $FIELD_HEIGHT; y++)); do
        board_view[$y]=${playing_field:y*FIELD_WIDTH:FIELD_WIDTH}
    done
    for px in {0..3}; do
        for py in {0..3}; do
            rotate $px $py $current_piece_rotation
            local index=$?
            if [[ ${tetrominos[$current_piece_index]:$index:1} == 1 ]]; then
                board_view[$((current_piece_pos_y + py))]=$(replace_char ${board_view[$((current_piece_pos_y + py))]} $((px + current_piece_pos_x)) 1)
            fi
        done
    done
    # screen[(nCurrentY + py + 2)*nScreenWidth + (nCurrentX + px + 2)] = nCurrentPiece
    for line in "${board_view[@]}"; do
        line=$(echo -e ${line//0/". "})
        line=$(echo -e ${line//1/"[]"})
        line=$(echo -e ${line//8/"##"})
        line=$(echo -e ${line//9/'#'})
        printf "%s\n" "$line"
    done
}

function input_reader() {
    while read -s -n 1 input; do
        echo $input
    done
}

function move_down() {
    if does_piece_fit $current_piece_index $current_piece_rotation $current_piece_pos_x $((current_piece_pos_y + 1)); then
        ((current_piece_pos_y++))
    fi
}


function move_right() {
    if does_piece_fit $current_piece_index $current_piece_rotation $(current_piece_pos_x - 1) $current_piece_pos_y; then
        ((current_piece_pos_x++))
    fi
}

function move_left() {
    if does_piece_fit $current_piece_index $current_piece_rotation $(current_piece_pos_x - 1) $current_piece_pos_y; then
        ((current_piece_pos_x--))
    fi
}

function rotate_piece() {
    if does_piece_fit $current_piece_index $(((current_piece_rotation + 1) % 4)) $urrent_piece_pos_x $current_piece_pos_y; then
        current_piece_rotation=$(((current_piece_rotation + 1) % 4))
    fi
}


function rotate() {
    local piece_x=$1
    local piece_y=$2
    local rotation=$3

    case $rotation in
        0)
            return $((piece_y * 4 + piece_x))
            ;;
        1)
            return $((12 + piece_y - (piece_x * 4)))
            ;;
        2)
            return $((15 - (piece_y * 4) - piece_x))
            ;;
        3)
            return $((3 - piece_y + (piece_x * 4)))
            ;;
        *)
            return 0
            ;;
    esac
}

function does_piece_fit() {
    local piece=$1
    local rotation=$2
    local piece_pos_x=$3
    local piece_pos_y=$4

    for piece_x in {0..3}; do
        for piece_y in {0..3}; do
            rotate $piece_x $piece_y $rotation
            local piece_index=$?
            local field_index=$(((piece_pos_y + piece_y) * FIELD_WIDTH + (piece_pos_x + piece_x)))

            if [[ $((piece_pos_x + piece_x >= 0)) && $((piece_pos_x + piece_x < FIELD_WIDTH)) ]]; then
                if [[ $((piece_pos_y + piece_y >= 0)) && $((piece_pos_y + piece_y < FIELD_HEIGHT)) ]]; then
                    if [[ ${tetrominos[$piece]:$piece_index:1} == 1 && ${playing_field:$field_index:1} != 0 ]]; then
                        return 1
                    fi
                fi
            fi
        done
    done

    return 0
}

function main() {
    init
    ((tick &);  input_reader) | controller
}

main 


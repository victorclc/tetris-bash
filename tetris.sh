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

declare playing_field 
declare current_piece_index
declare current_piece_rotation
declare current_piece_pos_x
declare current_piece_pos_y

declare FILLED_LINE
declare score


function replace_char() {
    local string=$1
    local index=$2
    local new_char=$3

    local new_string="${string:0:index}${new_char}${string:index+1}"

    echo $new_string
}

function initializize_new_piece {
    current_piece_index=$((RANDOM % 7))
    current_piece_rotation=0 # 0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degrees
    current_piece_pos_y=0
    current_piece_pos_x=3
}

function init() {
    initializize_new_piece
    score=0

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
    
    for ((x = 0; x < $FIELD_WIDTH; x++)); do
        if (( x == 0 || x == FIELD_WIDTH - 1 )); then
            FILLED_LINE+="9"
        else 
            FILLED_LINE+="1"
        fi
    done
}

function tick() {
    while true; do 
        sleep $TICK_DELAY
        echo -n $CMD_DOWN 
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
    echo "Score: $score"
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

function handle_complete_lines() {
    # Split playing_field into rows
    declare -a rows
    for ((y = 0; y < $FIELD_HEIGHT; y++)); do
        rows[$y]=${playing_field:y*FIELD_WIDTH:FIELD_WIDTH}
    done

    # Save the floor row separately
    local floor_row=${rows[$((FIELD_HEIGHT-1))]}

    # Collect non-complete rows (excluding the floor)
    declare -a remaining
    for ((y = 0; y < $FIELD_HEIGHT - 1; y++)); do
        if [[ "${rows[$y]}" != "$FILLED_LINE" ]]; then
            remaining+=("${rows[$y]}")
        fi
    done

    # Compute number of cleared lines
    local cleared=$(( FIELD_HEIGHT - 1 - ${#remaining[@]} ))
    if (( cleared > 0 )); then
        # Update score for cleared lines
        case $cleared in
            1) score=$((score+40)) ;;
            2) score=$((score+100)) ;;
            3) score=$((score+300)) ;;
            4) score=$((score+1200)) ;;
        esac
        # Build an empty row (walls at edges, empty inside)
        local empty_row=""
        for ((x = 0; x < $FIELD_WIDTH; x++)); do
            if (( x == 0 || x == FIELD_WIDTH - 1 )); then
                empty_row+="9"
            else
                empty_row+="0"
            fi
        done

        # Prepend empty rows for each cleared line
        for ((i = 0; i < cleared; i++)); do
            remaining=( "$empty_row" "${remaining[@]}" )
        done

        # Rebuild playing_field with remaining rows + floor
        playing_field=""
        for ((i = 0; i < $FIELD_HEIGHT - 1; i++)); do
            playing_field+="${remaining[$i]}"
        done
        playing_field+="$floor_row"
    fi

}

function lock_current_piece {
    for px in {0..3}; do
        for py in {0..3}; do
            rotate $px $py $current_piece_rotation
            local index=$?
            if [[ ${tetrominos[$current_piece_index]:$index:1} == 1 ]]; then
                playing_field=$(replace_char $playing_field $(( (current_piece_pos_y + py) * FIELD_WIDTH + (current_piece_pos_x + px) )) 1)
            fi
        done
    done
}

function move_down() {
    if does_piece_fit $current_piece_index $current_piece_rotation $current_piece_pos_x $((current_piece_pos_y + 1)); then
        ((current_piece_pos_y++))
    else
        lock_current_piece
        handle_complete_lines
        initializize_new_piece
    fi
}


function move_right() {
    if does_piece_fit $current_piece_index $current_piece_rotation $((current_piece_pos_x + 1)) $current_piece_pos_y; then
        ((current_piece_pos_x++))
    fi
}

function move_left() {
    if does_piece_fit $current_piece_index $current_piece_rotation $((current_piece_pos_x - 1)) $current_piece_pos_y; then
        ((current_piece_pos_x--))
    fi
}

function rotate_piece() {
    if does_piece_fit $current_piece_index $(( (current_piece_rotation + 1) % 4 )) $current_piece_pos_x $current_piece_pos_y; then
        current_piece_rotation=$(( (current_piece_rotation + 1) % 4 ))
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
            local field_index=$(( (piece_pos_y + piece_y) * FIELD_WIDTH + (piece_pos_x + piece_x) ))

            if [[ ${tetrominos[$piece]:$piece_index:1} -eq 1 && ${playing_field:$field_index:1} -ne 0 ]]; then
                return 1
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


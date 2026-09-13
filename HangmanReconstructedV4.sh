#!/bin/bash

ALPHABET="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
GAME_ABANDONED=1
GAME_LOST=2
GAME_WON=3
MAXWRONG=6

WELCOME="Welcome to HANGMAN!"
TOO_LONG="Invalid: You must enter only 1 letter at a time!"
NOT_A_LETTER="Invalid: The character you typed was not a letter!"
DUPLICATE_WRONG="Invalid: You have already guessed this letter and it was wrong!"
DUPLICATE_RIGHT="Invalid: You have already guessed this letter and it was correct!"
LETTER_WRONG="Sorry, the word does not contain this letter."
LETTER_RIGHT="Well done! A correct letter!"

DEFAULT_WORDS=(
    "AUTOMOBILE" "NETWORKING" "PRACTICAL"
    "CONGRESS" "COMMANDER" "STAPLER" "ENTERPRISE"
    "ESCALATION" "HAPPINESS" "WEDNESDAY" "THUNDER"
    "MARATHON" "LABORATORY" "HARBINGER" "SUNSHINE"
    "JOURNEY" "FANTASTIC" "DISCOVERY" "BOOKCASE"
    "HANGMAN"
)

pick_random_word() {
    if [[ -f "WordList.txt" ]]; then
        local words=()
        while IFS= read -r line; do
            line=$(echo "$line" | xargs | tr '[:lower:]' '[:upper:]')
            [[ -n "$line" ]] && words+=("$line")
        done < "WordList.txt"
        
        if [[ ${#words[@]} -gt 0 ]]; then
            local idx=$((RANDOM % ${#words[@]}))
            echo "${words[$idx]}"
            return
        fi
    fi
    
    local idx=$((RANDOM % ${#DEFAULT_WORDS[@]}))
    echo "${DEFAULT_WORDS[$idx]}"
}

build_hangman() {
    local misses=$1
    [[ $misses -lt 0 ]] && misses=0
    [[ $misses -gt 6 ]] && misses=6
    
    local stages=(
        "   +---+
   |   |
       |
       |
       |
       |
  ======="
        "   +---+
   |   |
   O   |
       |
       |
       |
  ======="
        "   +---+
   |   |
   O   |
   |   |
       |
       |
  ======="
        "   +---+
   |   |
   O   |
  /|   |
       |
       |
  ======="
        "   +---+
   |   |
   O   |
  /|\\  |
       |
       |
  ======="
        "   +---+
   |   |
   O   |
  /|\\  |
  /    |
       |
  ======="
        "   +---+
   |   |
   O   |
  /|\\  |
  / \\  |
       |
  ======="
    )
    echo "${stages[$misses]}"
}

get_wrong_guesses() {
    local wrong=""
    for ((i=0; i<26; i++)); do
        [[ ${guess_tracker[$i]} -eq -1 ]] && wrong+="${ALPHABET:$i:1} "
    done
    
    [[ -z "${wrong// }" ]] && echo "None" || echo "${wrong% }"
}

get_choice() {
    local message="$1"
    local wrong_guesses=$(get_wrong_guesses)
    local hangman=$(build_hangman "$no_misses")
    
    echo ""
    echo ""
    echo "$message"
    echo ""
    echo "	Word: $partial_solution"
    echo "	Misses: $no_misses / $MAXWRONG"
    echo "	Incorrect: $wrong_guesses"
    echo "	Hangman:"
    echo "$hangman"
    echo ""
    echo "Type one letter, or leave blank to abandon the game."
    read -p "> " choice
    echo "$choice"
}

initialize_game() {
    game_word=$(pick_random_word)
    declare -ga guess_tracker=()
    for ((i=0; i<26; i++)); do
        guess_tracker+=( 0 )
    done
    
    partial_solution=""
    for ((i=0; i<${#game_word}; i++)); do
        partial_solution+="_"
    done
    
    no_misses=0
    game_ended=0
    outcome=0
}

play() {
    choice=$(get_choice "$WELCOME")
    
    while [[ $game_ended -eq 0 ]]; do
        if [[ -z "$choice" ]]; then
            game_ended=1
            outcome=$GAME_ABANDONED
        elif [[ ${#choice} -gt 1 ]]; then
            choice=$(get_choice "$TOO_LONG")
        else
            choice=$(echo "$choice" | tr '[:lower:]' '[:upper:]')
            letter_pos=$(echo "$ALPHABET" | grep -o "$choice" | head -1)
            letter_index=-1
            
            for ((i=0; i<26; i++)); do
                [[ "${ALPHABET:$i:1}" == "$choice" ]] && letter_index=$i && break
            done
            
            if [[ $letter_index -eq -1 ]]; then
                choice=$(get_choice "$NOT_A_LETTER")
            elif [[ ${guess_tracker[$letter_index]} -eq -1 ]]; then
                choice=$(get_choice "$DUPLICATE_WRONG")
            elif [[ ${guess_tracker[$letter_index]} -eq 1 ]]; then
                choice=$(get_choice "$DUPLICATE_RIGHT")
            else
                game_letter_pos=-1
                for ((i=0; i<${#game_word}; i++)); do
                    [[ "${game_word:$i:1}" == "$choice" ]] && game_letter_pos=$i && break
                done
                
                if [[ $game_letter_pos -eq -1 ]]; then
                    ((no_misses++))
                    guess_tracker[$letter_index]=-1
                    
                    if [[ $no_misses -ge $MAXWRONG ]]; then
                        game_ended=1
                        outcome=$GAME_LOST
                    else
                        choice=$(get_choice "$LETTER_WRONG")
                    fi
                else
                    new_partial_sol=""
                    for ((i=0; i<${#game_word}; i++)); do
                        if [[ "${game_word:$i:1}" == "$choice" ]]; then
                            new_partial_sol+="$choice"
                        else
                            new_partial_sol+="${partial_solution:$i:1}"
                        fi
                    done
                    
                    partial_solution="$new_partial_sol"
                    guess_tracker[$letter_index]=1
                    
                    if [[ "$partial_solution" == "$game_word" ]]; then
                        game_ended=1
                        outcome=$GAME_WON
                    else
                        choice=$(get_choice "$LETTER_RIGHT")
                    fi
                fi
            fi
        fi
    done
}

report_outcome() {
    case $outcome in
        $GAME_ABANDONED)
            echo "You abandoned the game. The word was $game_word"
            ;;
        $GAME_LOST)
            echo "$LETTER_WRONG"
            echo "You lose. The word was $game_word"
            ;;
        $GAME_WON)
            echo "$LETTER_RIGHT"
            echo "Congratulations! You win! The word was $game_word"
            ;;
    esac
}

initialize_game
play
report_outcome

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>

#define ALPHABET "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
#define GAME_ABANDONED 1
#define GAME_LOST 2
#define GAME_WON 3
#define MAXWRONG 6
#define MAX_WORD_LEN 20
#define MAX_WORDS 20

const char *DEFAULT_WORDS[] = {
    "AUTOMOBILE", "NETWORKING", "PRACTICAL",
    "CONGRESS", "COMMANDER", "STAPLER", "ENTERPRISE",
    "ESCALATION", "HAPPINESS", "WEDNESDAY", "THUNDER",
    "MARATHON", "LABORATORY", "HARBINGER", "SUNSHINE",
    "JOURNEY", "FANTASTIC", "DISCOVERY", "BOOKCASE",
    "HANGMAN"
};

const char *WELCOME = "Welcome to HANGMAN!";
const char *TOO_LONG = "Invalid: You must enter only 1 letter at a time!";
const char *NOT_A_LETTER = "Invalid: The character you typed was not a letter!";
const char *DUPLICATE_WRONG = "Invalid: You have already guessed this letter and it was wrong!";
const char *DUPLICATE_RIGHT = "Invalid: You have already guessed this letter and it was correct!";
const char *LETTER_WRONG = "Sorry, the word does not contain this letter.";
const char *LETTER_RIGHT = "Well done! A correct letter!";

typedef struct {
    char game_word[MAX_WORD_LEN];
    int guess_tracker[26];
    char partial_solution[MAX_WORD_LEN];
    int no_misses;
    int game_ended;
    int outcome;
} GameState;

void build_hangman(int misses, char *output) {
    const char *stages[] = {
        "   +---+\n   |   |\n       |\n       |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n       |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n   |   |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n  /|   |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n  /|\\  |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n  /|\\  |\n  /    |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n  /|\\  |\n  / \\  |\n       |\n  ======="
    };
    if (misses < 0) misses = 0;
    if (misses > 6) misses = 6;
    strcpy(output, stages[misses]);
}

void get_wrong_guesses(GameState *state, char *output) {
    output[0] = '\0';
    for (int i = 0; i < 26; i++) {
        if (state->guess_tracker[i] == -1) {
            strncat(output, (char[]){ALPHABET[i], ' ', '\0'}, 2);
        }
    }
    if (strlen(output) == 0) {
        strcpy(output, "None");
    }
}

char *pick_random_word() {
    FILE *file = fopen("WordList.txt", "r");
    if (file != NULL) {
        char line[MAX_WORD_LEN];
        int count = 0;
        char words[MAX_WORDS][MAX_WORD_LEN];
        
        while (fgets(line, sizeof(line), file) != NULL) {
            char *word = line;
            while (*word && isspace(*word)) word++;
            if (*word) {
                int len = strlen(word) - 1;
                if (word[len] == '\n') word[len] = '\0';
                for (int i = 0; word[i]; i++) {
                    word[i] = toupper((unsigned char)word[i]);
                }
                if (count < MAX_WORDS) {
                    strcpy(words[count], word);
                    count++;
                }
            }
        }
        fclose(file);
        
        if (count > 0) {
            return (char *)DEFAULT_WORDS[rand() % count];
        }
    }
    return (char *)DEFAULT_WORDS[rand() % MAX_WORDS];
}

void get_choice(GameState *state, const char *message, char *input) {
    char wrong_guesses[100];
    char hangman[300];
    
    get_wrong_guesses(state, wrong_guesses);
    build_hangman(state->no_misses, hangman);
    
    printf("\n\n%s\n\n\tWord: %s\n\tMisses: %d / %d\n\tIncorrect: %s\n\tHangman:\n%s\n\n", 
           message, state->partial_solution, state->no_misses, MAXWRONG, wrong_guesses, hangman);
    printf("Type one letter, or leave blank to abandon the game.\n> ");
    
    if (fgets(input, 256, stdin) != NULL) {
        input[strcspn(input, "\n")] = 0;
    }
}

int index_of(const char *str, char c) {
    for (int i = 0; str[i] != '\0'; i++) {
        if (str[i] == c) return i;
    }
    return -1;
}

void initialize_game(GameState *state) {
    strcpy(state->game_word, pick_random_word());
    for (int i = 0; i < 26; i++) {
        state->guess_tracker[i] = 0;
    }
    int len = strlen(state->game_word);
    for (int i = 0; i < len; i++) {
        state->partial_solution[i] = '_';
    }
    state->partial_solution[len] = '\0';
    state->no_misses = 0;
    state->game_ended = 0;
    state->outcome = 0;
}

void play(GameState *state) {
    char choice[256];
    
    get_choice(state, WELCOME, choice);
    
    while (!state->game_ended) {
        if (strlen(choice) == 0) {
            state->game_ended = 1;
            state->outcome = GAME_ABANDONED;
        } else if (strlen(choice) > 1) {
            get_choice(state, TOO_LONG, choice);
        } else {
            choice[0] = toupper((unsigned char)choice[0]);
            int letter_pos = index_of(ALPHABET, choice[0]);
            
            if (letter_pos == -1) {
                get_choice(state, NOT_A_LETTER, choice);
            } else if (state->guess_tracker[letter_pos] == -1) {
                get_choice(state, DUPLICATE_WRONG, choice);
            } else if (state->guess_tracker[letter_pos] == 1) {
                get_choice(state, DUPLICATE_RIGHT, choice);
            } else {
                int game_letter_pos = index_of(state->game_word, choice[0]);
                
                if (game_letter_pos == -1) {
                    state->no_misses++;
                    state->guess_tracker[letter_pos] = -1;
                    
                    if (state->no_misses >= MAXWRONG) {
                        state->game_ended = 1;
                        state->outcome = GAME_LOST;
                    } else {
                        get_choice(state, LETTER_WRONG, choice);
                    }
                } else {
                    char new_partial[MAX_WORD_LEN];
                    for (int i = 0; i < strlen(state->game_word); i++) {
                        if (state->game_word[i] == choice[0]) {
                            new_partial[i] = choice[0];
                        } else {
                            new_partial[i] = state->partial_solution[i];
                        }
                    }
                    new_partial[strlen(state->game_word)] = '\0';
                    strcpy(state->partial_solution, new_partial);
                    
                    state->guess_tracker[letter_pos] = 1;
                    
                    if (strcmp(state->partial_solution, state->game_word) == 0) {
                        state->game_ended = 1;
                        state->outcome = GAME_WON;
                    } else {
                        get_choice(state, LETTER_RIGHT, choice);
                    }
                }
            }
        }
    }
}

void report_outcome(GameState *state) {
    switch (state->outcome) {
        case GAME_ABANDONED:
            printf("You abandoned the game. The word was %s\n", state->game_word);
            break;
        case GAME_LOST:
            printf("%s\nYou lose. The word was %s\n", LETTER_WRONG, state->game_word);
            break;
        case GAME_WON:
            printf("%s\nCongratulations! You win! The word was %s\n", LETTER_RIGHT, state->game_word);
            break;
    }
}

int main() {
    srand((unsigned int)time(NULL));
    GameState state;
    initialize_game(&state);
    play(&state);
    report_outcome(&state);
    return 0;
}

import random
import os

WELCOME = "Welcome to HANGMAN!"
ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
GAME_ABANDONED = 1
GAME_LOST = 2
GAME_WON = 3
MAXWRONG = 6

TOO_LONG = "Invalid: You must enter only 1 letter at a time!"
NOT_A_LETTER = "Invalid: The character you typed was not a letter!"
DUPLICATE_WRONG = "Invalid: You have already guessed this letter and it was wrong!"
DUPLICATE_RIGHT = "Invalid: You have already guessed this letter and it was correct!"
LETTER_WRONG = "Sorry, the word does not contain this letter."
LETTER_RIGHT = "Well done! A correct letter!"

DEFAULT_WORDS = [
    "AUTOMOBILE", "NETWORKING", "PRACTICAL",
    "CONGRESS", "COMMANDER", "STAPLER", "ENTERPRISE",
    "ESCALATION", "HAPPINESS", "WEDNESDAY", "THUNDER",
    "MARATHON", "LABORATORY", "HARBINGER", "SUNSHINE",
    "JOURNEY", "FANTASTIC", "DISCOVERY", "BOOKCASE",
    "HANGMAN"
]

class HangmanGame:
    def __init__(self):
        self.game_word = self.pick_random_word()
        self.guess_tracker = [0] * 26
        self.partial_solution = "_" * len(self.game_word)
        self.no_misses = 0
        self.game_ended = False
        self.outcome = None
    
    def pick_random_word(self):
        word_list_file = "WordList.txt"
        try:
            if os.path.exists(word_list_file):
                with open(word_list_file, 'r') as f:
                    words = [w.strip().upper() for w in f.readlines() if w.strip()]
                    if words:
                        return random.choice(words)
        except IOError:
            pass
        return random.choice(DEFAULT_WORDS)
    
    def build_hangman(self, misses):
        stages = [
            "   +---+\n   |   |\n       |\n       |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n       |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n   |   |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n  /|   |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n  /|\\  |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n  /|\\  |\n  /    |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n  /|\\  |\n  / \\  |\n       |\n  ======="
        ]
        clamped_misses = max(0, min(6, misses))
        return stages[clamped_misses]
    
    def get_wrong_guesses(self):
        wrong_guesses = ""
        for i in range(26):
            if self.guess_tracker[i] == -1:
                wrong_guesses += ALPHABET[i] + " "
        return wrong_guesses.strip() if wrong_guesses.strip() else "None"
    
    def get_choice(self, message):
        wrong_guesses = self.get_wrong_guesses()
        prompt = f"\n\n{message}\n\n\tWord: {self.partial_solution}\n\tMisses: {self.no_misses} / {MAXWRONG}\n\tIncorrect: {wrong_guesses}\n\tHangman:\n{self.build_hangman(self.no_misses)}\n\nType one letter, or leave blank to abandon the game.\n> "
        return input(prompt)
    
    def play(self):
        choice = self.get_choice(WELCOME)
        
        while not self.game_ended:
            if choice == "":
                self.game_ended = True
                self.outcome = GAME_ABANDONED
            elif len(choice) > 1:
                choice = self.get_choice(TOO_LONG)
            else:
                choice = choice.upper()
                letter_pos = ALPHABET.find(choice)
                
                if letter_pos == -1:
                    choice = self.get_choice(NOT_A_LETTER)
                elif self.guess_tracker[letter_pos] == -1:
                    choice = self.get_choice(DUPLICATE_WRONG)
                elif self.guess_tracker[letter_pos] == 1:
                    choice = self.get_choice(DUPLICATE_RIGHT)
                else:
                    game_letter_pos = self.game_word.find(choice)
                    
                    if game_letter_pos == -1:
                        self.no_misses += 1
                        self.guess_tracker[letter_pos] = -1
                        
                        if self.no_misses >= MAXWRONG:
                            self.game_ended = True
                            self.outcome = GAME_LOST
                        else:
                            choice = self.get_choice(LETTER_WRONG)
                    else:
                        new_partial_sol = ""
                        for i in range(len(self.game_word)):
                            if self.game_word[i] == choice:
                                new_partial_sol += choice
                            else:
                                new_partial_sol += self.partial_solution[i]
                        
                        self.partial_solution = new_partial_sol
                        self.guess_tracker[letter_pos] = 1
                        
                        if self.partial_solution == self.game_word:
                            self.game_ended = True
                            self.outcome = GAME_WON
                        else:
                            choice = self.get_choice(LETTER_RIGHT)
    
    def report_outcome(self):
        if self.outcome == GAME_ABANDONED:
            print(f"You abandoned the game. The word was {self.game_word}")
        elif self.outcome == GAME_LOST:
            print(f"{LETTER_WRONG}\nYou lose. The word was {self.game_word}")
        elif self.outcome == GAME_WON:
            print(f"{LETTER_RIGHT}\nCongratulations! You win! The word was {self.game_word}")

if __name__ == "__main__":
    game = HangmanGame()
    game.play()
    game.report_outcome()

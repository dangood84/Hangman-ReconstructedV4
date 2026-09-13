#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <algorithm>
#include <cstdlib>
#include <ctime>
#include <cctype>

using namespace std;

const string ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const int GAME_ABANDONED = 1;
const int GAME_LOST = 2;
const int GAME_WON = 3;
const int MAXWRONG = 6;

const string WELCOME = "Welcome to HANGMAN!";
const string TOO_LONG = "Invalid: You must enter only 1 letter at a time!";
const string NOT_A_LETTER = "Invalid: The character you typed was not a letter!";
const string DUPLICATE_WRONG = "Invalid: You have already guessed this letter and it was wrong!";
const string DUPLICATE_RIGHT = "Invalid: You have already guessed this letter and it was correct!";
const string LETTER_WRONG = "Sorry, the word does not contain this letter.";
const string LETTER_RIGHT = "Well done! A correct letter!";

static const vector<string> getDefaultWords() {
    vector<string> words;
    words.push_back("AUTOMOBILE");
    words.push_back("NETWORKING");
    words.push_back("PRACTICAL");
    words.push_back("CONGRESS");
    words.push_back("COMMANDER");
    words.push_back("STAPLER");
    words.push_back("ENTERPRISE");
    words.push_back("ESCALATION");
    words.push_back("HAPPINESS");
    words.push_back("WEDNESDAY");
    words.push_back("THUNDER");
    words.push_back("MARATHON");
    words.push_back("LABORATORY");
    words.push_back("HARBINGER");
    words.push_back("SUNSHINE");
    words.push_back("JOURNEY");
    words.push_back("FANTASTIC");
    words.push_back("DISCOVERY");
    words.push_back("BOOKCASE");
    words.push_back("HANGMAN");
    return words;
}

const vector<string> DEFAULT_WORDS = getDefaultWords();

class HangmanGame {
private:
    string gameWord;
    int guessTracker[26];
    string partialSolution;
    int noMisses;
    bool gameEnded;
    int outcome;
    
public:
    HangmanGame() {
        gameWord = pickRandomWord();
        for (int i = 0; i < 26; i++) {
            guessTracker[i] = 0;
        }
        partialSolution = string(gameWord.length(), '_');
        noMisses = 0;
        gameEnded = false;
        outcome = 0;
    }
    
    string pickRandomWord() {
        ifstream file("WordList.txt");
        if (file.is_open()) {
            vector<string> words;
            string line;
            while (getline(file, line)) {
                string word = line;
                word.erase(0, word.find_first_not_of(" \t\r\n"));
                word.erase(word.find_last_not_of(" \t\r\n") + 1);
                if (!word.empty()) {
                    transform(word.begin(), word.end(), word.begin(), ::toupper);
                    words.push_back(word);
                }
            }
            file.close();
            if (!words.empty()) {
                return words[rand() % words.size()];
            }
        }
        return DEFAULT_WORDS[rand() % DEFAULT_WORDS.size()];
    }
    
    string buildHangman(int misses) {
        vector<string> stages;
        stages.push_back("   +---+\n   |   |\n       |\n       |\n       |\n       |\n  =======");
        stages.push_back("   +---+\n   |   |\n   O   |\n       |\n       |\n       |\n  =======");
        stages.push_back("   +---+\n   |   |\n   O   |\n   |   |\n       |\n       |\n  =======");
        stages.push_back("   +---+\n   |   |\n   O   |\n  /|   |\n       |\n       |\n  =======");
        stages.push_back("   +---+\n   |   |\n   O   |\n  /|\\  |\n       |\n       |\n  =======");
        stages.push_back("   +---+\n   |   |\n   O   |\n  /|\\  |\n  /    |\n       |\n  =======");
        stages.push_back("   +---+\n   |   |\n   O   |\n  /|\\  |\n  / \\  |\n       |\n  =======");
        if (misses < 0) misses = 0;
        if (misses > 6) misses = 6;
        return stages[misses];
    }
    
    string getWrongGuesses() {
        string wrongGuesses = "";
        for (int i = 0; i < 26; i++) {
            if (guessTracker[i] == -1) {
                wrongGuesses += ALPHABET[i];
                wrongGuesses += " ";
            }
        }
        if (wrongGuesses.empty()) {
            return "None";
        }
        wrongGuesses.pop_back();
        return wrongGuesses;
    }
    
    string getChoice(const string& message) {
        string wrongGuesses = getWrongGuesses();
        cout << "\n\n" << message << "\n\n";
        cout << "\tWord: " << partialSolution << "\n";
        cout << "\tMisses: " << noMisses << " / " << MAXWRONG << "\n";
        cout << "\tIncorrect: " << wrongGuesses << "\n";
        cout << "\tHangman:\n" << buildHangman(noMisses) << "\n\n";
        cout << "Type one letter, or leave blank to abandon the game.\n> ";
        
        string choice;
        getline(cin, choice);
        return choice;
    }
    
    void play() {
        string choice = getChoice(WELCOME);
        
        while (!gameEnded) {
            if (choice.empty()) {
                gameEnded = true;
                outcome = GAME_ABANDONED;
            } else if (choice.length() > 1) {
                choice = getChoice(TOO_LONG);
            } else {
                choice[0] = toupper(choice[0]);
                size_t letterPos = ALPHABET.find(choice[0]);
                
                if (letterPos == string::npos) {
                    choice = getChoice(NOT_A_LETTER);
                } else if (guessTracker[letterPos] == -1) {
                    choice = getChoice(DUPLICATE_WRONG);
                } else if (guessTracker[letterPos] == 1) {
                    choice = getChoice(DUPLICATE_RIGHT);
                } else {
                    size_t gameLetterPos = gameWord.find(choice[0]);
                    
                    if (gameLetterPos == string::npos) {
                        noMisses++;
                        guessTracker[letterPos] = -1;
                        
                        if (noMisses >= MAXWRONG) {
                            gameEnded = true;
                            outcome = GAME_LOST;
                        } else {
                            choice = getChoice(LETTER_WRONG);
                        }
                    } else {
                        string newPartialSol = "";
                        for (size_t i = 0; i < gameWord.length(); i++) {
                            if (gameWord[i] == choice[0]) {
                                newPartialSol += choice[0];
                            } else {
                                newPartialSol += partialSolution[i];
                            }
                        }
                        
                        partialSolution = newPartialSol;
                        guessTracker[letterPos] = 1;
                        
                        if (partialSolution == gameWord) {
                            gameEnded = true;
                            outcome = GAME_WON;
                        } else {
                            choice = getChoice(LETTER_RIGHT);
                        }
                    }
                }
            }
        }
    }
    
    void reportOutcome() {
        switch (outcome) {
            case GAME_ABANDONED:
                cout << "You abandoned the game. The word was " << gameWord << "\n";
                break;
            case GAME_LOST:
                cout << LETTER_WRONG << "\nYou lose. The word was " << gameWord << "\n";
                break;
            case GAME_WON:
                cout << LETTER_RIGHT << "\nCongratulations! You win! The word was " << gameWord << "\n";
                break;
        }
    }
};

int main() {
    srand(static_cast<unsigned int>(time(NULL)));
    HangmanGame game;
    game.play();
    game.reportOutcome();
    return 0;
}

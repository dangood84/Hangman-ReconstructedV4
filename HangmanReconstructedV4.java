import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.Random;

public class HangmanReconstructedV4 {
    static final String WELCOME = "Welcome to HANGMAN!";
    static final String ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    static final int GAME_ABANDONED = 1;
    static final int GAME_LOST = 2;
    static final int GAME_WON = 3;
    static final int MAXWRONG = 6;
    
    static final String TOO_LONG = "Invalid: You must enter only 1 letter at a time!";
    static final String NOT_A_LETTER = "Invalid: The character you typed was not a letter!";
    static final String DUPLICATE_WRONG = "Invalid: You have already guessed this letter and it was wrong!";
    static final String DUPLICATE_RIGHT = "Invalid: You have already guessed this letter and it was correct!";
    static final String LETTER_WRONG = "Sorry, the word does not contain this letter.";
    static final String LETTER_RIGHT = "Well done! A correct letter!";
    
    static final String[] DEFAULT_WORDS = {
        "AUTOMOBILE", "NETWORKING", "PRACTICAL",
        "CONGRESS", "COMMANDER", "STAPLER", "ENTERPRISE",
        "ESCALATION", "HAPPINESS", "WEDNESDAY", "THUNDER",
        "MARATHON", "LABORATORY", "HARBINGER", "SUNSHINE",
        "JOURNEY", "FANTASTIC", "DISCOVERY", "BOOKCASE",
        "HANGMAN"
    };
    
    String gameWord;
    int[] guessTracker;
    String partialSolution;
    int noMisses;
    boolean gameEnded;
    int outcome;
    
    BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
    Random random = new Random();
    
    public HangmanReconstructedV4() {
        gameWord = pickRandomWord();
        guessTracker = new int[26];
        partialSolution = "_".repeat(gameWord.length());
        noMisses = 0;
        gameEnded = false;
        outcome = 0;
    }
    
    String pickRandomWord() {
        File wordListFile = new File("WordList.txt");
        try {
            if (wordListFile.exists()) {
                ArrayList<String> words = new ArrayList<>();
                BufferedReader fileReader = new BufferedReader(new FileReader(wordListFile));
                String line;
                while ((line = fileReader.readLine()) != null) {
                    String word = line.trim().toUpperCase();
                    if (!word.isEmpty()) {
                        words.add(word);
                    }
                }
                fileReader.close();
                if (!words.isEmpty()) {
                    return words.get(random.nextInt(words.size()));
                }
            }
        } catch (IOException e) {
            // Fall through to defaults
        }
        return DEFAULT_WORDS[random.nextInt(DEFAULT_WORDS.length)];
    }
    
    String buildHangman(int misses) {
        String[] stages = {
            "   +---+\n   |   |\n       |\n       |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n       |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n   |   |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n  /|   |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n  /|\\  |\n       |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n  /|\\  |\n  /    |\n       |\n  =======",
            "   +---+\n   |   |\n   O   |\n  /|\\  |\n  / \\  |\n       |\n  ======="
        };
        int clampedMisses = Math.max(0, Math.min(6, misses));
        return stages[clampedMisses];
    }
    
    String getWrongGuesses() {
        StringBuilder wrongGuesses = new StringBuilder();
        for (int i = 0; i < 26; i++) {
            if (guessTracker[i] == -1) {
                wrongGuesses.append(ALPHABET.charAt(i)).append(" ");
            }
        }
        String result = wrongGuesses.toString().trim();
        return result.isEmpty() ? "None" : result;
    }
    
    String getChoice(String message) throws IOException {
        String wrongGuesses = getWrongGuesses();
        String prompt = String.format("\n\n%s\n\n\tWord: %s\n\tMisses: %d / %d\n\tIncorrect: %s\n\tHangman:\n%s\n\nType one letter, or leave blank to abandon the game.\n> ",
            message, partialSolution, noMisses, MAXWRONG, wrongGuesses, buildHangman(noMisses));
        System.out.print(prompt);
        return reader.readLine();
    }
    
    void play() throws IOException {
        String choice = getChoice(WELCOME);
        
        while (!gameEnded) {
            if (choice.isEmpty()) {
                gameEnded = true;
                outcome = GAME_ABANDONED;
            } else if (choice.length() > 1) {
                choice = getChoice(TOO_LONG);
            } else {
                choice = choice.toUpperCase();
                int letterPos = ALPHABET.indexOf(choice);
                
                if (letterPos == -1) {
                    choice = getChoice(NOT_A_LETTER);
                } else if (guessTracker[letterPos] == -1) {
                    choice = getChoice(DUPLICATE_WRONG);
                } else if (guessTracker[letterPos] == 1) {
                    choice = getChoice(DUPLICATE_RIGHT);
                } else {
                    int gameLetterPos = gameWord.indexOf(choice);
                    
                    if (gameLetterPos == -1) {
                        noMisses++;
                        guessTracker[letterPos] = -1;
                        
                        if (noMisses >= MAXWRONG) {
                            gameEnded = true;
                            outcome = GAME_LOST;
                        } else {
                            choice = getChoice(LETTER_WRONG);
                        }
                    } else {
                        StringBuilder newPartialSol = new StringBuilder();
                        for (int i = 0; i < gameWord.length(); i++) {
                            if (gameWord.charAt(i) == choice.charAt(0)) {
                                newPartialSol.append(choice);
                            } else {
                                newPartialSol.append(partialSolution.charAt(i));
                            }
                        }
                        
                        partialSolution = newPartialSol.toString();
                        guessTracker[letterPos] = 1;
                        
                        if (partialSolution.equals(gameWord)) {
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
                System.out.println("You abandoned the game. The word was " + gameWord);
                break;
            case GAME_LOST:
                System.out.println(LETTER_WRONG + "\nYou lose. The word was " + gameWord);
                break;
            case GAME_WON:
                System.out.println(LETTER_RIGHT + "\nCongratulations! You win! The word was " + gameWord);
                break;
        }
    }
    
    public static void main(String[] args) throws IOException {
        HangmanReconstructedV4 game = new HangmanReconstructedV4();
        game.play();
        game.reportOutcome();
    }
}

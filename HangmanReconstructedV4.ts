import * as readlineSync from 'readline-sync';
import * as fs from 'fs';

const WELCOME = "Welcome to HANGMAN!";
const ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const GAME_ABANDONED = 1;
const GAME_LOST = 2;
const GAME_WON = 3;
const MAXWRONG = 6;

const TOO_LONG = "Invalid: You must enter only 1 letter at a time!";
const NOT_A_LETTER = "Invalid: The character you typed was not a letter!";
const DUPLICATE_WRONG = "Invalid: You have already guessed this letter and it was wrong!";
const DUPLICATE_RIGHT = "Invalid: You have already guessed this letter and it was correct!";
const LETTER_WRONG = "Sorry, the word does not contain this letter.";
const LETTER_RIGHT = "Well done! A correct letter!";

const DEFAULT_WORDS = [
    "AUTOMOBILE", "NETWORKING", "PRACTICAL",
    "CONGRESS", "COMMANDER", "STAPLER", "ENTERPRISE",
    "ESCALATION", "HAPPINESS", "WEDNESDAY", "THUNDER",
    "MARATHON", "LABORATORY", "HARBINGER", "SUNSHINE",
    "JOURNEY", "FANTASTIC", "DISCOVERY", "BOOKCASE",
    "HANGMAN"
];

let gameWord: string;
let guessTracker: number[];
let partialSolution: string;
let noMisses: number;
let gameEnded: boolean;
let outcome: number | null;

function pickRandomWord(): string {
    const wordListFile = "WordList.txt";
    try {
        if (fs.existsSync(wordListFile)) {
            const content = fs.readFileSync(wordListFile, 'utf-8');
            const words = content.split('\n').map(w => w.trim().toUpperCase()).filter(w => w.length > 0);
            if (words.length > 0) {
                return words[Math.floor(Math.random() * words.length)];
            }
        }
    } catch (e) {
        // File error, fall through
    }
    return DEFAULT_WORDS[Math.floor(Math.random() * DEFAULT_WORDS.length)];
}

function initializeGame(): void {
    gameWord = pickRandomWord();
    guessTracker = new Array(26).fill(0);
    partialSolution = "_".repeat(gameWord.length);
    noMisses = 0;
    gameEnded = false;
    outcome = null;
}

function buildHangman(misses: number): string {
    const stages = [
        "   +---+\n   |   |\n       |\n       |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n       |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n   |   |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n  /|   |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n  /|\\  |\n       |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n  /|\\  |\n  /    |\n       |\n  =======",
        "   +---+\n   |   |\n   O   |\n  /|\\  |\n  / \\  |\n       |\n  ======="
    ];
    const clampedMisses = Math.max(0, Math.min(6, misses));
    return stages[clampedMisses];
}

function getWrongGuesses(): string {
    let wrongGuesses = "";
    for (let i = 0; i < 26; i++) {
        if (guessTracker[i] === -1) {
            wrongGuesses += ALPHABET[i] + " ";
        }
    }
    return wrongGuesses.trim() === "" ? "None" : wrongGuesses.trim();
}

function getChoice(message: string): string {
    const wrongGuesses = getWrongGuesses();
    const prompt = `\n\n${message}\n\n\tWord: ${partialSolution}\n\tMisses: ${noMisses} / ${MAXWRONG}\n\tIncorrect: ${wrongGuesses}\n\tHangman:\n${buildHangman(noMisses)}\n\nType one letter, or leave blank to abandon the game.`;
    
    return readlineSync.question(prompt + "\n> ");
}

function gameLoop(): void {
    let choice = getChoice(WELCOME);
    
    while (!gameEnded) {
        if (choice === "") {
            gameEnded = true;
            outcome = GAME_ABANDONED;
        } else if (choice.length > 1) {
            choice = getChoice(TOO_LONG);
        } else {
            choice = choice.toUpperCase();
            const letterPos = ALPHABET.indexOf(choice);
            
            if (letterPos === -1) {
                choice = getChoice(NOT_A_LETTER);
            } else if (guessTracker[letterPos] === -1) {
                choice = getChoice(DUPLICATE_WRONG);
            } else if (guessTracker[letterPos] === 1) {
                choice = getChoice(DUPLICATE_RIGHT);
            } else {
                const gameLetterPos = gameWord.indexOf(choice);
                
                if (gameLetterPos === -1) {
                    noMisses++;
                    guessTracker[letterPos] = -1;
                    
                    if (noMisses >= MAXWRONG) {
                        gameEnded = true;
                        outcome = GAME_LOST;
                    } else {
                        choice = getChoice(LETTER_WRONG);
                    }
                } else {
                    let newPartialSol = "";
                    for (let i = 0; i < gameWord.length; i++) {
                        if (gameWord[i] === choice) {
                            newPartialSol += choice;
                        } else {
                            newPartialSol += partialSolution[i];
                        }
                    }
                    
                    partialSolution = newPartialSol;
                    guessTracker[letterPos] = 1;
                    
                    if (partialSolution === gameWord) {
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

function reportOutcome(): void {
    switch (outcome) {
        case GAME_ABANDONED:
            console.log(`You abandoned the game. The word was ${gameWord}`);
            break;
        case GAME_LOST:
            console.log(`${LETTER_WRONG}\nYou lose. The word was ${gameWord}`);
            break;
        case GAME_WON:
            console.log(`${LETTER_RIGHT}\nCongratulations! You win! The word was ${gameWord}`);
            break;
    }
}

initializeGame();
gameLoop();
reportOutcome();

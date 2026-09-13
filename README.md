# Hangman Reconstructed V4

A single-player, command-line Hangman game reconstructed with enhanced features including visual ASCII art hangman display, improved word list handling, and a cleaner code structure.

This version improves upon V3 with:
- Visual hangman ASCII art that progresses through 7 stages as wrong guesses increase
- Better word selection logic with robust file handling
- Built-in fallback word list for when WordList.txt is unavailable
- Improved user interface with better status feedback
- Cleaner code organization across all language implementations

## Gameplay

- A random word is selected from the project word list or built-in defaults.
- The player guesses one letter at a time.
- Empty input abandons the game.
- Six wrong guesses lose the game.
- Correct guesses reveal all occurrences of that letter.

See [EXECUTION_FLOW.md](EXECUTION_FLOW.md) for the game loop and [WORKINGS.md](WORKINGS.md)
for the shared state model and porting notes.

## Versions and commands

| Language | File | Command |
| --- | --- | --- |
| JavaScript | [HangmanReconstructedV4.js](HangmanReconstructedV4.js) | `npm install && npm start` |
| TypeScript | [HangmanReconstructedV4.ts](HangmanReconstructedV4.ts) | `node --experimental-strip-types HangmanReconstructedV4.ts` |
| Python | [HangmanReconstructedV4.py](HangmanReconstructedV4.py) | `python3 HangmanReconstructedV4.py` |
| Java | [HangmanReconstructedV4.java](HangmanReconstructedV4.java) | `javac HangmanReconstructedV4.java && java HangmanReconstructedV4` |
| C | [HangmanReconstructedV4.c](HangmanReconstructedV4.c) | `cc HangmanReconstructedV4.c -o hangman_c && ./hangman_c` |
| C++ | [HangmanReconstructedV4.cpp](HangmanReconstructedV4.cpp) | `c++ -std=c++17 HangmanReconstructedV4.cpp -o hangman_cpp && ./hangman_cpp` |
| Bash | [HangmanReconstructedV4.sh](HangmanReconstructedV4.sh) | `chmod +x HangmanReconstructedV4.sh && ./HangmanReconstructedV4.sh` |
| Pascal | [HangmanReconstructedV4.pas](HangmanReconstructedV4.pas) | `fpc HangmanReconstructedV4.pas && ./HangmanReconstructedV4` |
| Fortran | [HangmanReconstructedV4.f90](HangmanReconstructedV4.f90) | `gfortran HangmanReconstructedV4.f90 -o hangman_f90 && ./hangman_f90` |
| Prolog | [HangmanReconstructedV4.pl](HangmanReconstructedV4.pl) | `swipl HangmanReconstructedV4.pl` |
| VBScript | [HangmanReconstructedv4.vbs](HangmanReconstructedv4.vbs) | `cscript HangmanReconstructedv4.vbs` (Windows only) |

## Prerequisites

- Node.js 22.6+ for the JavaScript/TypeScript path, plus `npm install`.
- Python 3 and Bash 4+.
- A Java JDK, C/C++ compiler, Free Pascal, `gfortran`, and SWI-Prolog for the other ports.

The ports are intentionally small and self-contained. Native compilers may leave build
products in the folder; the shared `.gitignore` excludes those products and dependencies.

## Enhanced V4 Features

### Visual Hangman Display
The game now displays a 7-stage ASCII art hangman that visually progresses as the player makes wrong guesses:
- Stage 0-1: Head appears
- Stage 1-2: Body appears
- Stage 3: Left arm appears
- Stage 4: Right arm appears
- Stage 5: Left leg appears
- Stage 6: Right leg (game lost)

### Improved Word Selection
The `PickRandomWord()` function intelligently handles word list files:
- Attempts to read from WordList.txt
- Strips whitespace and converts to uppercase
- Falls back to built-in default word list if file is missing or empty
- No need for separate file existence checks in client code

### Better User Interface
The input prompt now shows:
- Current word with revealed letters
- Miss count as a ratio (e.g., "Misses: 2 / 6")
- "None" when no incorrect guesses have been made (instead of blank)
- ASCII art hangman visualization
- Clear instructions

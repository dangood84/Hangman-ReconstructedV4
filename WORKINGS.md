# Workings

This project follows the control flow of the enhanced `HangmanReconstructedv4.vbs` with significant improvements over V3. The ports use the same five pieces of game state with enhanced features for better user experience.

## Shared state

| State | Meaning |
| --- | --- |
| Secret word | One word selected randomly from the project word list, with intelligent fallback to defaults. |
| Guess mask | Underscores with correctly guessed letters revealed in place. |
| Miss count | Number of wrong letters; the game is lost at six. |
| Letter tracker | One A-Z slot: `0` unused, `1` correct, `-1` wrong. |
| Outcome | Abandoned, lost, or won; set only when the loop ends. |

## V4 Enhancements over V3

### Visual ASCII Hangman Display
- Seven-stage ASCII art visualization that builds progressively with each wrong guess
- Stage 0: Empty gallows
- Stage 1: Head
- Stage 2: Body
- Stage 3: Left arm
- Stage 4: Right arm
- Stage 5: Left leg
- Stage 6: Right leg (game over)
- Displays in every prompt for immediate visual feedback

### Improved Word Selection Logic
- `PickRandomWord()` now handles file I/O robustly
- Reads all words from WordList.txt if available
- Strips whitespace automatically
- Converts to uppercase for consistency
- Falls back seamlessly to built-in 20-word list if file doesn't exist or is empty
- More reliable across platforms and environments

### Better User Interface
- Misses shown as ratio: "Misses: 2 / 6" instead of just "No of misses: 2"
- Incorrect letters show "None" when list is empty (instead of blank)
- Consistent spacing and formatting across all implementations
- Clearer prompts and status messages

### Improved Variable Naming
- Uses `blnGameRunning` instead of `blnEndOfGame` (more intuitive logic)
- Consistent naming conventions across implementations
- Better array indexing (0-based consistently)

## V4 translation notes

- All implementations maintain the same core logic and game flow from VBScript v4
- The visual hangman display is rendered as multi-line ASCII strings, compatible with all platforms
- Word list file handling is consistent: file read errors gracefully fall back to defaults
- File I/O errors do not crash the game; they simply trigger the default word list
- Array indexing conventions:
  - Letter tracker uses 0-based indexing (0-25 for A-Z) in most languages
  - VBScript uses 1-based indexing
  - Conversions handled transparently in each language

## Shared constants

**Words:** `AUTOMOBILE`, `NETWORKING`, `PRACTICAL`, `CONGRESS`, `COMMANDER`, `STAPLER`,
`ENTERPRISE`, `ESCALATION`, `HAPPINESS`, `WEDNESDAY`, `THUNDER`, `MARATHON`,
`LABORATORY`, `HARBINGER`, `SUNSHINE`, `JOURNEY`, `FANTASTIC`, `DISCOVERY`,
`BOOKCASE`, `HANGMAN`.

**Alphabet:** `ABCDEFGHIJKLMNOPQRSTUVWXYZ`

**Maximum wrong guesses:** `6`

## Key differences from V3

| Feature | V3 | V4 |
| --- | --- | --- |
| Hangman visualization | None | 7-stage ASCII art in each prompt |
| Word selection | Basic file reading | Robust with automatic fallback |
| Misses display | "No of misses: X" | "Misses: X / 6" |
| Empty wrong list | Blank | "None" |
| Code organization | Functional | Object-oriented where applicable |
| Prompt formatting | Basic | Enhanced with visual feedback |

## Implementation Details

### Visual Stages
Each stage is stored as a multi-line string with embedded newlines:
- `\n` or equivalent for line breaks
- Fixed-width ASCII for consistent display
- 7 total stages indexed 0-6

### File Handling Pattern
```
Try to open WordList.txt
  Read all lines
  Strip whitespace and uppercase
  Return random selection if found
Catch any errors (file not found, read errors, empty file)
  Fall back to DEFAULT_WORDS array
  Return random selection
```

### State Updates
- Wrong guess: increment misses, mark letter as -1, check for loss condition
- Correct guess: rebuild mask with all matching letters, mark letter as 1, check for win condition
- Invalid input: reprompt without state change

## Language-Specific Adaptations

### JavaScript/TypeScript
- Uses `readline-sync` npm package for interactive input
- String array for word list
- Dynamic array for guess tracking

### Python
- Object-oriented with HangmanGame class
- File operations with standard library
- List comprehensions for filtering

### Java
- Class-based design with instance variables
- ArrayList for dynamic word list loading
- Standard IOException handling

### C
- Struct for game state
- Fixed-size arrays (MAX_WORD_LEN = 20)
- Manual memory management minimal

### C++
- Class encapsulation
- Vector for dynamic arrays
- Standard file I/O and string operations

### Bash
- Array variables for word storage
- Parameter expansion for string operations
- File read loop with input handling

### Pascal
- Record type for game state
- Array structures for fixed word count
- File operations with error handling

### Fortran
- Module-based organization
- Fixed and dynamic array support
- Intrinsic functions for string manipulation

### Prolog
- Dynamic predicates for game state
- Backtracking for word selection
- Recursive game loop implementation

## Testing Recommendations

1. Test word selection from both file and defaults
2. Verify hangman display at each stage (0-6 misses)
3. Test all three exit conditions: abandon, lose, win
4. Verify duplicate guess handling for both right and wrong letters
5. Test multi-letter input rejection
6. Test non-alphabetic character rejection
7. Verify correct letter reveal across all positions
8. Test game doesn't end prematurely on duplicate correct guess

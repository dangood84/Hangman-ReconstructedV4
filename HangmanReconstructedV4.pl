:- initialization(main).

:- dynamic(game_word/1).
:- dynamic(guess_tracker/2).
:- dynamic(partial_solution/1).
:- dynamic(no_misses/1).

% Constants
alphabet('ABCDEFGHIJKLMNOPQRSTUVWXYZ').
game_abandoned(1).
game_lost(2).
game_won(3).
maxwrong(6).

welcome('Welcome to HANGMAN!').
too_long('Invalid: You must enter only 1 letter at a time!').
not_a_letter('Invalid: The character you typed was not a letter!').
duplicate_wrong('Invalid: You have already guessed this letter and it was wrong!').
duplicate_right('Invalid: You have already guessed this letter and it was correct!').
letter_wrong('Sorry, the word does not contain this letter.').
letter_right('Well done! A correct letter!').

default_word('AUTOMOBILE').
default_word('NETWORKING').
default_word('PRACTICAL').
default_word('CONGRESS').
default_word('COMMANDER').
default_word('STAPLER').
default_word('ENTERPRISE').
default_word('ESCALATION').
default_word('HAPPINESS').
default_word('WEDNESDAY').
default_word('THUNDER').
default_word('MARATHON').
default_word('LABORATORY').
default_word('HARBINGER').
default_word('SUNSHINE').
default_word('JOURNEY').
default_word('FANTASTIC').
default_word('DISCOVERY').
default_word('BOOKCASE').
default_word('HANGMAN').

% Pick a random word
pick_random_word(Word) :-
    (exists_file('WordList.txt') -> 
        read_word_list('WordList.txt', Words),
        (Words \= [] ->
            random_member(Word, Words)
        ;
            random_default_word(Word)
        )
    ;
        random_default_word(Word)
    ).

read_word_list(File, Words) :-
    catch(
        (open(File, read, Stream),
         read_words(Stream, Words),
         close(Stream)),
        _,
        Words = []
    ).

read_words(Stream, Words) :-
    read_line_to_codes(Stream, Line),
    (Line = end_of_file ->
        Words = []
    ;
        atom_codes(Atom, Line),
        upcase_atom(Atom, Upper),
        (Atom = '' ->
            read_words(Stream, Words)
        ;
            read_words(Stream, RestWords),
            Words = [Upper|RestWords]
        )
    ).

random_default_word(Word) :-
    findall(W, default_word(W), Words),
    random_member(Word, Words).

% Build hangman stages
hangman_stage(0, '   +---+\n   |   |\n       |\n       |\n       |\n       |\n  =======').
hangman_stage(1, '   +---+\n   |   |\n   O   |\n       |\n       |\n       |\n  =======').
hangman_stage(2, '   +---+\n   |   |\n   O   |\n   |   |\n       |\n       |\n  =======').
hangman_stage(3, '   +---+\n   |   |\n   O   |\n  /|   |\n       |\n       |\n  =======').
hangman_stage(4, '   +---+\n   |   |\n   O   |\n  /|\\  |\n       |\n       |\n  =======').
hangman_stage(5, '   +---+\n   |   |\n   O   |\n  /|\\  |\n  /    |\n       |\n  =======').
hangman_stage(6, '   +---+\n   |   |\n   O   |\n  /|\\  |\n  / \\  |\n       |\n  =======').

build_hangman(Misses, Hangman) :-
    Clamped is max(0, min(6, Misses)),
    hangman_stage(Clamped, Hangman).

% Get wrong guesses
get_wrong_guesses(WrongGuesses) :-
    alphabet(Alpha),
    findall(Letter, (between(1, 26, N), letter_at_pos(Alpha, N, Letter), guess_tracker(N, -1)), Letters),
    (Letters = [] ->
        WrongGuesses = 'None'
    ;
        atomic_list_concat(Letters, ' ', WrongGuesses)
    ).

letter_at_pos(Alpha, N, Letter) :-
    atom_codes(Alpha, Codes),
    nth0(N1, Codes, Code),
    N1 is N - 1,
    atom_codes(Letter, [Code]).

% Index of letter in alphabet (1-based)
letter_index(Letter, Index) :-
    alphabet(Alpha),
    atom_codes(Alpha, Codes),
    atom_codes(Letter, [LetterCode]),
    nth0(N, Codes, LetterCode),
    Index is N + 1.

% Initialize guess tracker
init_tracker :-
    retractall(guess_tracker(_, _)),
    forall(between(1, 26, N), assertz(guess_tracker(N, 0))).

% Get choice from user
get_choice(Message, Choice) :-
    nl, nl,
    write(Message), nl, nl,
    partial_solution(Partial),
    no_misses(Misses),
    maxwrong(MaxWrong),
    get_wrong_guesses(WrongGuesses),
    no_misses(Misses),
    build_hangman(Misses, Hangman),
    format('~tWord: ~w~n', [Partial]),
    format('~tMisses: ~w / ~w~n', [Misses, MaxWrong]),
    format('~tIncorrect: ~w~n', [WrongGuesses]),
    format('~tHangman:~n~w~n', [Hangman]),
    nl,
    write('Type one letter, or leave blank to abandon the game.'), nl,
    write('> '),
    read_line_to_codes(user_input, Input),
    (Input = [] ->
        Choice = ''
    ;
        atom_codes(Atom, Input),
        upcase_atom(Atom, Choice)
    ).

% Process a guess
process_guess(Choice, GameEnded, Outcome) :-
    alphabet(Alpha),
    (atom_codes(Choice, [Code]), atom_codes(LetterUpper, [Code]) ->
        letter_index(LetterUpper, LetterPos)
    ;
        process_invalid(GameEnded, Outcome),
        !
    ),
    guess_tracker(LetterPos, Status),
    (Status = -1 ->
        duplicate_wrong(Msg),
        get_choice(Msg, NextChoice),
        game_loop(NextChoice, GameEnded, Outcome)
    ; Status = 1 ->
        duplicate_right(Msg),
        get_choice(Msg, NextChoice),
        game_loop(NextChoice, GameEnded, Outcome)
    ;
        game_word(Word),
        (atom_codes(Word, WordCodes), member(Code, WordCodes) ->
            reveal_letters(Choice, Word)
        ;
            retract(no_misses(Misses)),
            NewMisses is Misses + 1,
            assertz(no_misses(NewMisses)),
            retract(guess_tracker(LetterPos, _)),
            assertz(guess_tracker(LetterPos, -1)),
            (NewMisses >= 6 ->
                game_lost(Outcome),
                GameEnded = true
            ;
                letter_wrong(Msg),
                get_choice(Msg, NextChoice),
                game_loop(NextChoice, GameEnded, Outcome)
            )
        )
    ).

% Process invalid input
process_invalid(GameEnded, Outcome) :-
    length_error,
    GameEnded = false.

% Reveal letters in the partial solution
reveal_letters(Letter, Word) :-
    partial_solution(OldPartial),
    atom_codes(Word, WordCodes),
    atom_codes(Letter, [LetterCode]),
    rebuild_partial(OldPartial, WordCodes, LetterCode, NewPartial),
    retract(partial_solution(_)),
    assertz(partial_solution(NewPartial)),
    letter_index(Letter, LetterPos),
    retract(guess_tracker(LetterPos, _)),
    assertz(guess_tracker(LetterPos, 1)),
    (atom_codes(Word, WordCodes), NewPartial = Word ->
        game_won(Outcome)
    ;
        letter_right(Msg),
        get_choice(Msg, NextChoice),
        game_loop(NextChoice, _, Outcome)
    ).

rebuild_partial(Partial, WordCodes, LetterCode, NewPartial) :-
    atom_codes(Partial, PartialCodes),
    rebuild_partial_codes(PartialCodes, WordCodes, LetterCode, NewPartialCodes),
    atom_codes(NewPartial, NewPartialCodes).

rebuild_partial_codes([], [], _, []).
rebuild_partial_codes([P|Ps], [W|Ws], L, [R|Rs]) :-
    (W = L ->
        R = L
    ;
        R = P
    ),
    rebuild_partial_codes(Ps, Ws, L, Rs).

% Game loop
game_loop(Choice, GameEnded, Outcome) :-
    (atom_codes(Choice, []) ->
        game_abandoned(Outcome),
        GameEnded = true
    ; atom_length(Choice, Len), Len > 1 ->
        too_long(Msg),
        get_choice(Msg, NextChoice),
        game_loop(NextChoice, GameEnded, Outcome)
    ; \+ atom_codes(Choice, [_]) ->
        not_a_letter(Msg),
        get_choice(Msg, NextChoice),
        game_loop(NextChoice, GameEnded, Outcome)
    ;
        process_guess(Choice, GameEnded, Outcome)
    ).

% Report outcome
report_outcome(Outcome) :-
    game_word(Word),
    game_abandoned(Outcome) ->
        format('You abandoned the game. The word was ~w~n', [Word])
    ; game_lost(Outcome) ->
        letter_wrong(Msg),
        format('~w~n', [Msg]),
        format('You lose. The word was ~w~n', [Word])
    ; game_won(Outcome) ->
        letter_right(Msg),
        format('~w~n', [Msg]),
        format('Congratulations! You win! The word was ~w~n', [Word])
    .

% Main entry point
main :-
    pick_random_word(Word),
    assertz(game_word(Word)),
    init_tracker,
    atom_length(Word, Len),
    atom_codes(Word, _),
    PartialSol = '_',
    length(UnderscoreCodes, Len),
    maplist(=(95), UnderscoreCodes),
    atom_codes(PartialSol, UnderscoreCodes),
    assertz(partial_solution(PartialSol)),
    assertz(no_misses(0)),
    welcome(Msg),
    get_choice(Msg, Choice),
    game_loop(Choice, _, Outcome),
    report_outcome(Outcome),
    halt.

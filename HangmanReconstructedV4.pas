Program HangmanReconstructedV4;

Const
    ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    GAME_ABANDONED = 1;
    GAME_LOST = 2;
    GAME_WON = 3;
    MAXWRONG = 6;
    MAX_WORD_LEN = 20;
    MAX_WORDS = 20;
    
    WELCOME = 'Welcome to HANGMAN!';
    TOO_LONG = 'Invalid: You must enter only 1 letter at a time!';
    NOT_A_LETTER = 'Invalid: The character you typed was not a letter!';
    DUPLICATE_WRONG = 'Invalid: You have already guessed this letter and it was wrong!';
    DUPLICATE_RIGHT = 'Invalid: You have already guessed this letter and it was correct!';
    LETTER_WRONG = 'Sorry, the word does not contain this letter.';
    LETTER_RIGHT = 'Well done! A correct letter!';

Type
    WordArray = Array [1..MAX_WORDS] Of String;
    GuessArray = Array [1..26] Of Integer;
    GameStateType = Record
        GameWord: String;
        GuessTracker: GuessArray;
        PartialSolution: String;
        NoMisses: Integer;
        GameEnded: Boolean;
        Outcome: Integer;
    End;

Var
    DefaultWords: WordArray = (
        'AUTOMOBILE', 'NETWORKING', 'PRACTICAL',
        'CONGRESS', 'COMMANDER', 'STAPLER', 'ENTERPRISE',
        'ESCALATION', 'HAPPINESS', 'WEDNESDAY', 'THUNDER',
        'MARATHON', 'LABORATORY', 'HARBINGER', 'SUNSHINE',
        'JOURNEY', 'FANTASTIC', 'DISCOVERY', 'BOOKCASE',
        'HANGMAN', ''
    );

Function BuildHangman(Misses: Integer): String;
Const
    Stages: Array [0..6] Of String = (
        '   +---+' + #10 + '   |   |' + #10 + '       |' + #10 + '       |' + #10 + '       |' + #10 + '       |' + #10 + '  =======',
        '   +---+' + #10 + '   |   |' + #10 + '   O   |' + #10 + '       |' + #10 + '       |' + #10 + '       |' + #10 + '  =======',
        '   +---+' + #10 + '   |   |' + #10 + '   O   |' + #10 + '   |   |' + #10 + '       |' + #10 + '       |' + #10 + '  =======',
        '   +---+' + #10 + '   |   |' + #10 + '   O   |' + #10 + '  /|   |' + #10 + '       |' + #10 + '       |' + #10 + '  =======',
        '   +---+' + #10 + '   |   |' + #10 + '   O   |' + #10 + '  /|\  |' + #10 + '       |' + #10 + '       |' + #10 + '  =======',
        '   +---+' + #10 + '   |   |' + #10 + '   O   |' + #10 + '  /|\  |' + #10 + '  /    |' + #10 + '       |' + #10 + '  =======',
        '   +---+' + #10 + '   |   |' + #10 + '   O   |' + #10 + '  /|\  |' + #10 + '  / \  |' + #10 + '       |' + #10 + '  ======='
    );
Var
    ClampedMisses: Integer;
Begin
    ClampedMisses := Misses;
    If ClampedMisses < 0 Then ClampedMisses := 0;
    If ClampedMisses > 6 Then ClampedMisses := 6;
    BuildHangman := Stages[ClampedMisses];
End;

Function GetWrongGuesses(Var State: GameStateType): String;
Var
    WrongGuesses: String;
    I: Integer;
Begin
    WrongGuesses := '';
    For I := 1 To 26 Do
        If State.GuessTracker[I] = -1 Then
            WrongGuesses := WrongGuesses + ALPHABET[I] + ' ';
    
    If Length(Trim(WrongGuesses)) = 0 Then
        GetWrongGuesses := 'None'
    Else
        GetWrongGuesses := Trim(WrongGuesses);
End;

Function IndexOf(Const S: String; C: Char): Integer;
Var
    I: Integer;
Begin
    IndexOf := -1;
    For I := 1 To Length(S) Do
        If S[I] = C Then
        Begin
            IndexOf := I;
            Exit;
        End;
End;

Procedure PickRandomWord(Var State: GameStateType);
Var
    F: Text;
    Line: String;
    WordCount: Integer;
    Words: Array [1..MAX_WORDS] Of String;
    I: Integer;
Begin
    Assign(F, 'WordList.txt');
    {$I-}
    Reset(F);
    {$I+}
    
    If IOResult = 0 Then
    Begin
        WordCount := 0;
        While Not Eof(F) And (WordCount < MAX_WORDS) Do
        Begin
            ReadLn(F, Line);
            Line := Trim(UpperCase(Line));
            If Length(Line) > 0 Then
            Begin
                Inc(WordCount);
                Words[WordCount] := Line;
            End;
        End;
        Close(F);
        
        If WordCount > 0 Then
        Begin
            State.GameWord := Words[Random(WordCount) + 1];
            Exit;
        End;
    End;
    
    State.GameWord := DefaultWords[Random(MAX_WORDS) + 1];
End;

Procedure InitializeGame(Var State: GameStateType);
Var
    I: Integer;
Begin
    PickRandomWord(State);
    For I := 1 To 26 Do
        State.GuessTracker[I] := 0;
    State.PartialSolution := StringOfChar('_', Length(State.GameWord));
    State.NoMisses := 0;
    State.GameEnded := False;
    State.Outcome := 0;
End;

Procedure GetChoice(Var State: GameStateType; Message: String; Var Choice: String);
Var
    WrongGuesses: String;
Begin
    WriteLn;
    WriteLn;
    WriteLn(Message);
    WriteLn;
    Write(#9, 'Word: ');
    WriteLn(State.PartialSolution);
    Write(#9, 'Misses: ');
    WriteLn(State.NoMisses, ' / ', MAXWRONG);
    WrongGuesses := GetWrongGuesses(State);
    Write(#9, 'Incorrect: ');
    WriteLn(WrongGuesses);
    WriteLn(#9, 'Hangman:');
    WriteLn(BuildHangman(State.NoMisses));
    WriteLn;
    WriteLn('Type one letter, or leave blank to abandon the game.');
    Write('> ');
    ReadLn(Choice);
    Choice := UpperCase(Choice);
End;

Procedure Play(Var State: GameStateType);
Var
    Choice: String;
    LetterPos: Integer;
    GameLetterPos: Integer;
    NewPartialSol: String;
    I: Integer;
Begin
    GetChoice(State, WELCOME, Choice);
    
    While Not State.GameEnded Do
    Begin
        If Length(Choice) = 0 Then
        Begin
            State.GameEnded := True;
            State.Outcome := GAME_ABANDONED;
        End
        Else If Length(Choice) > 1 Then
            GetChoice(State, TOO_LONG, Choice)
        Else
        Begin
            Choice := UpperCase(Choice);
            LetterPos := IndexOf(ALPHABET, Choice[1]);
            
            If LetterPos = -1 Then
                GetChoice(State, NOT_A_LETTER, Choice)
            Else If State.GuessTracker[LetterPos] = -1 Then
                GetChoice(State, DUPLICATE_WRONG, Choice)
            Else If State.GuessTracker[LetterPos] = 1 Then
                GetChoice(State, DUPLICATE_RIGHT, Choice)
            Else
            Begin
                GameLetterPos := IndexOf(State.GameWord, Choice[1]);
                
                If GameLetterPos = -1 Then
                Begin
                    Inc(State.NoMisses);
                    State.GuessTracker[LetterPos] := -1;
                    
                    If State.NoMisses >= MAXWRONG Then
                    Begin
                        State.GameEnded := True;
                        State.Outcome := GAME_LOST;
                    End
                    Else
                        GetChoice(State, LETTER_WRONG, Choice);
                End
                Else
                Begin
                    NewPartialSol := '';
                    For I := 1 To Length(State.GameWord) Do
                    Begin
                        If State.GameWord[I] = Choice[1] Then
                            NewPartialSol := NewPartialSol + Choice[1]
                        Else
                            NewPartialSol := NewPartialSol + State.PartialSolution[I];
                    End;
                    
                    State.PartialSolution := NewPartialSol;
                    State.GuessTracker[LetterPos] := 1;
                    
                    If State.PartialSolution = State.GameWord Then
                    Begin
                        State.GameEnded := True;
                        State.Outcome := GAME_WON;
                    End
                    Else
                        GetChoice(State, LETTER_RIGHT, Choice);
                End;
            End;
        End;
    End;
End;

Procedure ReportOutcome(Var State: GameStateType);
Begin
    Case State.Outcome Of
        GAME_ABANDONED:
            WriteLn('You abandoned the game. The word was ', State.GameWord);
        GAME_LOST:
            Begin
                WriteLn(LETTER_WRONG);
                WriteLn('You lose. The word was ', State.GameWord);
            End;
        GAME_WON:
            Begin
                WriteLn(LETTER_RIGHT);
                WriteLn('Congratulations! You win! The word was ', State.GameWord);
            End;
    End;
End;

Var
    State: GameStateType;
Begin
    Randomize;
    InitializeGame(State);
    Play(State);
    ReportOutcome(State);
End.

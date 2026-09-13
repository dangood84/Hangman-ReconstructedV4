Option Explicit

Dim intRandomNo, intLen, intNoMisses, intHowEnded
Dim intLetterPos, intGameLetterPos, intLetterCtr
Dim aintLetterUsed()

Dim astrWordList
astrWordList = Array("AUTOMOBILE", "NETWORKING", "PRACTICAL", _
    "CONGRESS", "COMMANDER", "STAPLER", "ENTERPRISE", _
    "ESCALATION", "HAPPINESS", "WEDNESDAY", "THUNDER", _
    "MARATHON", "LABORATORY", "HARBINGER", "SUNSHINE", _
    "JOURNEY", "FANTASTIC", "DISCOVERY", "BOOKCASE", _
    "HANGMAN")

Dim strGameWord, strWrongGuesses, strPartialSol
Dim strNewPartialSol, strPartialLetter, strWordLetter, strChoice
Dim blnGameRunning

Dim objFso, objFileHandle
Dim strWordListFile, strFileContents
Dim arrWordList, intWordCount

Const WELCOME        = "Welcome to HANGMAN!"
Const ALPHABET       = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
Const GAME_ABANDONED = 1
Const GAME_LOST      = 2
Const GAME_WON       = 3
Const MAXWRONG       = 6

Const TOO_LONG       = "Invalid: You must enter only 1 letter at a time!"
Const NOT_A_LETTER   = "Invalid: The character you typed was not a letter!"
Const DUPLICATE_WRONG= "Invalid: You have already guessed this letter and it was wrong!"
Const DUPLICATE_RIGHT= "Invalid: You have already guessed this letter and it was correct!"
Const LETTER_WRONG   = "Sorry, the word does not contain this letter."
Const LETTER_RIGHT   = "Well done! A correct letter!"

Set objFso = WScript.CreateObject("Scripting.FileSystemObject")
strWordListFile = "WordList.txt"

strGameWord = PickRandomWord()
InitializeGame

strChoice = GetChoice(WELCOME)
blnGameRunning = True

Do While blnGameRunning
    If strChoice = vbNullString Then
        blnGameRunning = False
        intHowEnded = GAME_ABANDONED
    ElseIf Len(strChoice) > 1 Then
        strChoice = GetChoice(TOO_LONG)
    Else
        strChoice = UCase(strChoice)
        intLetterPos = InStr(ALPHABET, strChoice)
        If intLetterPos = 0 Then
            strChoice = GetChoice(NOT_A_LETTER)
        Else
            If aintLetterUsed(intLetterPos - 1) = -1 Then
                strChoice = GetChoice(DUPLICATE_WRONG)
            ElseIf aintLetterUsed(intLetterPos - 1) = 1 Then
                strChoice = GetChoice(DUPLICATE_RIGHT)
            Else
                intGameLetterPos = InStr(strGameWord, strChoice)

                If intGameLetterPos = 0 Then
                    intNoMisses = intNoMisses + 1
                    aintLetterUsed(intLetterPos - 1) = -1

                    If intNoMisses >= MAXWRONG Then
                        blnGameRunning = False
                        intHowEnded = GAME_LOST
                    Else
                        strChoice = GetChoice(LETTER_WRONG)
                    End If
                Else
                    strNewPartialSol = ""
                    For intLetterCtr = 1 To intLen
                        strPartialLetter = Mid(strPartialSol, intLetterCtr, 1)
                        strWordLetter = Mid(strGameWord, intLetterCtr, 1)

                        If strWordLetter = strChoice Then
                            strNewPartialSol = strNewPartialSol & strChoice
                        Else
                            strNewPartialSol = strNewPartialSol & strPartialLetter
                        End If
                    Next

                    strPartialSol = strNewPartialSol
                    aintLetterUsed(intLetterPos - 1) = 1

                    If strPartialSol = strGameWord Then
                        blnGameRunning = False
                        intHowEnded = GAME_WON
                    Else
                        strChoice = GetChoice(LETTER_RIGHT)
                    End If
                End If
            End If
        End If
    End If
Loop

Select Case intHowEnded
    Case GAME_ABANDONED
        MsgBox "You abandoned the game. The word was " & strGameWord, vbInformation, "VBScript Hangman"
    Case GAME_LOST
        MsgBox LETTER_WRONG & vbCrLf & "You lose. The word was " & strGameWord, vbInformation, "VBScript Hangman"
    Case GAME_WON
        MsgBox LETTER_RIGHT & vbCrLf & "Congratulations! You win! The word was " & strGameWord, vbInformation, "VBScript Hangman"
End Select

Sub InitializeGame()
    ReDim aintLetterUsed(25)
    For intLetterCtr = 0 To 25
        aintLetterUsed(intLetterCtr) = 0
    Next

    intLen = Len(strGameWord)
    strPartialSol = String(intLen, "_")
    intNoMisses = 0
    strWrongGuesses = ""
End Sub

Function GetChoice(strMessage)
    strWrongGuesses = ""

    For intLetterCtr = 1 To Len(ALPHABET)
        If aintLetterUsed(intLetterCtr - 1) = -1 Then
            strWrongGuesses = strWrongGuesses & Mid(ALPHABET, intLetterCtr, 1) & " "
        End If
    Next

    If Trim(strWrongGuesses) = "" Then
        strWrongGuesses = "None"
    End If

    GetChoice = InputBox(vbCrLf & vbCrLf & strMessage & vbCrLf & _
        vbCrLf & vbTab & "Word: " & strPartialSol & _
        vbCrLf & vbTab & "Misses: " & intNoMisses & " / " & MAXWRONG & _
        vbCrLf & vbTab & "Incorrect: " & strWrongGuesses & _
        vbCrLf & vbTab & "Hangman:" & vbCrLf & BuildHangman(intNoMisses) & _
        vbCrLf & "Type one letter, or leave blank to abandon the game.", "VBScript Hangman")
End Function

Function PickRandomWord()
    Dim arrFileWords(), strWord, i

    If objFso.FileExists(strWordListFile) Then
        Set objFileHandle = objFso.OpenTextFile(strWordListFile, 1, False)
        strFileContents = objFileHandle.ReadAll()
        objFileHandle.Close()

        If Len(Trim(strFileContents)) > 0 Then
            arrWordList = Split(strFileContents, vbCrLf)
            intWordCount = 0
            ReDim arrFileWords(0)

            For i = 0 To UBound(arrWordList)
                strWord = UCase(Trim(arrWordList(i)))
                If Len(strWord) > 0 Then
                    If intWordCount = 0 Then
                        arrFileWords(0) = strWord
                        intWordCount = 1
                    Else
                        ReDim Preserve arrFileWords(intWordCount)
                        arrFileWords(intWordCount) = strWord
                        intWordCount = intWordCount + 1
                    End If
                End If
            Next

            If intWordCount > 0 Then
                Randomize
                intRandomNo = Int(intWordCount * Rnd)
                PickRandomWord = arrFileWords(intRandomNo)
                Exit Function
            End If
        End If
    End If

    Randomize
    intRandomNo = Int((UBound(astrWordList) + 1) * Rnd)
    PickRandomWord = astrWordList(intRandomNo)
End Function

Function BuildHangman(intMisses)
    Dim arrStages(6)

    arrStages(0) = "   +---+" & vbCrLf & "   |   |" & vbCrLf & "       |" & vbCrLf & "       |" & vbCrLf & "       |" & vbCrLf & "       |" & vbCrLf & "  ======="
    arrStages(1) = "   +---+" & vbCrLf & "   |   |" & vbCrLf & "   O   |" & vbCrLf & "       |" & vbCrLf & "       |" & vbCrLf & "       |" & vbCrLf & "  ======="
    arrStages(2) = "   +---+" & vbCrLf & "   |   |" & vbCrLf & "   O   |" & vbCrLf & "   |   |" & vbCrLf & "       |" & vbCrLf & "       |" & vbCrLf & "  ======="
    arrStages(3) = "   +---+" & vbCrLf & "   |   |" & vbCrLf & "   O   |" & vbCrLf & "  /|   |" & vbCrLf & "       |" & vbCrLf & "       |" & vbCrLf & "  ======="
    arrStages(4) = "   +---+" & vbCrLf & "   |   |" & vbCrLf & "   O   |" & vbCrLf & "  /|\  |" & vbCrLf & "       |" & vbCrLf & "       |" & vbCrLf & "  ======="
    arrStages(5) = "   +---+" & vbCrLf & "   |   |" & vbCrLf & "   O   |" & vbCrLf & "  /|\  |" & vbCrLf & "  /    |" & vbCrLf & "       |" & vbCrLf & "  ======="
    arrStages(6) = "   +---+" & vbCrLf & "   |   |" & vbCrLf & "   O   |" & vbCrLf & "  /|\  |" & vbCrLf & "  / \  |" & vbCrLf & "       |" & vbCrLf & "  ======="

    If intMisses < 0 Then intMisses = 0
    If intMisses > 6 Then intMisses = 6

    BuildHangman = arrStages(intMisses)
End Function
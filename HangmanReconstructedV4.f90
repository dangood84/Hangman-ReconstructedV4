program HangmanReconstructedV4
    implicit none
    
    character(len=26), parameter :: ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    integer, parameter :: GAME_ABANDONED = 1
    integer, parameter :: GAME_LOST = 2
    integer, parameter :: GAME_WON = 3
    integer, parameter :: MAXWRONG = 6
    integer, parameter :: MAX_WORD_LEN = 20
    integer, parameter :: MAX_WORDS = 20
    
    character(len=*), parameter :: WELCOME = 'Welcome to HANGMAN!'
    character(len=*), parameter :: TOO_LONG = 'Invalid: You must enter only 1 letter at a time!'
    character(len=*), parameter :: NOT_A_LETTER = 'Invalid: The character you typed was not a letter!'
    character(len=*), parameter :: DUPLICATE_WRONG = 'Invalid: You have already guessed this letter and it was wrong!'
    character(len=*), parameter :: DUPLICATE_RIGHT = 'Invalid: You have already guessed this letter and it was correct!'
    character(len=*), parameter :: LETTER_WRONG = 'Sorry, the word does not contain this letter.'
    character(len=*), parameter :: LETTER_RIGHT = 'Well done! A correct letter!'
    
    character(len=MAX_WORD_LEN), dimension(MAX_WORDS) :: DEFAULT_WORDS
    integer :: game_outcome
    
    DATA DEFAULT_WORDS / &
        'AUTOMOBILE     ', 'NETWORKING     ', 'PRACTICAL      ', &
        'CONGRESS       ', 'COMMANDER      ', 'STAPLER        ', &
        'ENTERPRISE     ', 'ESCALATION     ', 'HAPPINESS      ', &
        'WEDNESDAY      ', 'THUNDER        ', 'MARATHON       ', &
        'LABORATORY     ', 'HARBINGER      ', 'SUNSHINE       ', &
        'JOURNEY        ', 'FANTASTIC      ', 'DISCOVERY      ', &
        'BOOKCASE       ', 'HANGMAN        ' /
    
    call play_game(game_outcome)

contains

    subroutine play_game(outcome)
        integer, intent(out) :: outcome
        character(len=MAX_WORD_LEN) :: game_word, partial_solution
        integer :: guess_tracker(26)
        integer :: no_misses
        logical :: game_ended
        character(len=256) :: choice
        
        game_word = pick_random_word()
        guess_tracker = 0
        partial_solution = repeat('_', len_trim(game_word))
        no_misses = 0
        game_ended = .false.
        
        call get_choice(WELCOME, guess_tracker, partial_solution, no_misses, choice)
        
        do while (.not. game_ended)
            if (len_trim(choice) == 0) then
                game_ended = .true.
                outcome = GAME_ABANDONED
            else if (len_trim(choice) > 1) then
                call get_choice(TOO_LONG, guess_tracker, partial_solution, no_misses, choice)
            else
                choice = upper_case(choice)
                
                if (index(ALPHABET, trim(choice)) == 0) then
                    call get_choice(NOT_A_LETTER, guess_tracker, partial_solution, no_misses, choice)
                else
                    call process_guess(game_word, guess_tracker, partial_solution, &
                        no_misses, choice, game_ended, outcome)
                    if (.not. game_ended) then
                        call get_choice(LETTER_RIGHT, guess_tracker, partial_solution, no_misses, choice)
                    end if
                end if
            end if
        end do
        
        call report_outcome(outcome, game_word)
    end subroutine play_game
    
    subroutine process_guess(game_word, guess_tracker, partial_solution, no_misses, choice, game_ended, outcome)
        character(len=*), intent(in) :: game_word
        integer, intent(inout) :: guess_tracker(26)
        character(len=*), intent(inout) :: partial_solution
        integer, intent(inout) :: no_misses
        character(len=*), intent(in) :: choice
        logical, intent(inout) :: game_ended
        integer, intent(inout) :: outcome
        
        integer :: letter_pos, i
        logical :: found
        character(len=MAX_WORD_LEN) :: new_partial
        
        letter_pos = index(ALPHABET, trim(choice))
        
        if (guess_tracker(letter_pos) == -1) then
            return  ! Already wrong
        else if (guess_tracker(letter_pos) == 1) then
            return  ! Already right
        else
            found = .false.
            do i = 1, len_trim(game_word)
                if (game_word(i:i) == trim(choice)) then
                    found = .true.
                    exit
                end if
            end do
            
            if (.not. found) then
                no_misses = no_misses + 1
                guess_tracker(letter_pos) = -1
                if (no_misses >= MAXWRONG) then
                    game_ended = .true.
                    outcome = GAME_LOST
                end if
            else
                new_partial = ''
                do i = 1, len_trim(game_word)
                    if (game_word(i:i) == trim(choice)) then
                        new_partial = trim(new_partial) // trim(choice)
                    else
                        new_partial = trim(new_partial) // partial_solution(i:i)
                    end if
                end do
                partial_solution = new_partial
                guess_tracker(letter_pos) = 1
                
                if (trim(partial_solution) == trim(game_word)) then
                    game_ended = .true.
                    outcome = GAME_WON
                end if
            end if
        end if
    end subroutine process_guess
    
    function pick_random_word() result(word)
        character(len=MAX_WORD_LEN) :: word
        integer :: idx, seed_size, clock, i
        integer, allocatable :: seed(:)
        real :: temp
        
        call random_seed(size=seed_size)
        allocate(seed(seed_size))
        call system_clock(count=clock)
        seed = clock + 37 * (/ (i, i=1,seed_size) /)
        call random_seed(put=seed)
        deallocate(seed)
        call random_number(temp)
        idx = int(temp * MAX_WORDS) + 1
        word = DEFAULT_WORDS(idx)
    end function pick_random_word
    
    function upper_case(str) result(upper_str)
        character(len=*), intent(in) :: str
        character(len=len(str)) :: upper_str
        integer :: i, char_code
        
        do i = 1, len(str)
            char_code = iachar(str(i:i))
            if (char_code >= iachar('a') .and. char_code <= iachar('z')) then
                upper_str(i:i) = achar(char_code - 32)
            else
                upper_str(i:i) = str(i:i)
            end if
        end do
    end function upper_case
    
    subroutine build_hangman(misses, hangman_str)
        integer, intent(in) :: misses
        character(len=*), intent(out) :: hangman_str
        character(len=80), dimension(0:6) :: stages
        integer :: clamped
        
        stages(0) = '   +---+' // new_line('A') // '   |   |' // new_line('A') // '       |' // &
                    new_line('A') // '       |' // new_line('A') // '       |' // new_line('A') // &
                    '       |' // new_line('A') // '  ======='
        stages(1) = '   +---+' // new_line('A') // '   |   |' // new_line('A') // '   O   |' // &
                    new_line('A') // '       |' // new_line('A') // '       |' // new_line('A') // &
                    '       |' // new_line('A') // '  ======='
        stages(2) = '   +---+' // new_line('A') // '   |   |' // new_line('A') // '   O   |' // &
                    new_line('A') // '   |   |' // new_line('A') // '       |' // new_line('A') // &
                    '       |' // new_line('A') // '  ======='
        stages(3) = '   +---+' // new_line('A') // '   |   |' // new_line('A') // '   O   |' // &
                    new_line('A') // '  /|   |' // new_line('A') // '       |' // new_line('A') // &
                    '       |' // new_line('A') // '  ======='
        stages(4) = '   +---+' // new_line('A') // '   |   |' // new_line('A') // '   O   |' // &
                    new_line('A') // '  /|\  |' // new_line('A') // '       |' // new_line('A') // &
                    '       |' // new_line('A') // '  ======='
        stages(5) = '   +---+' // new_line('A') // '   |   |' // new_line('A') // '   O   |' // &
                    new_line('A') // '  /|\  |' // new_line('A') // '  /    |' // new_line('A') // &
                    '       |' // new_line('A') // '  ======='
        stages(6) = '   +---+' // new_line('A') // '   |   |' // new_line('A') // '   O   |' // &
                    new_line('A') // '  /|\  |' // new_line('A') // '  / \  |' // new_line('A') // &
                    '       |' // new_line('A') // '  ======='
        
        clamped = max(0, min(6, misses))
        hangman_str = stages(clamped)
    end subroutine build_hangman
    
    subroutine get_choice(message, guess_tracker, partial_solution, no_misses, choice)
        character(len=*), intent(in) :: message
        integer, intent(in) :: guess_tracker(26)
        integer, intent(in) :: no_misses
        character(len=*), intent(in) :: partial_solution
        character(len=*), intent(out) :: choice
        character(len=512) :: wrong_guesses, hangman_str
        integer :: i
        
        wrong_guesses = ''
        do i = 1, 26
            if (guess_tracker(i) == -1) then
                wrong_guesses = trim(wrong_guesses) // ALPHABET(i:i) // ' '
            end if
        end do
        
        if (len_trim(wrong_guesses) == 0) then
            wrong_guesses = 'None'
        end if
        
        call build_hangman(no_misses, hangman_str)
        
        write(*, '(A)') ''
        write(*, '(A)') trim(message)
        write(*, '(A)') ''
        write(*, '(A,A)') achar(9) // 'Word: ', trim(partial_solution)
        write(*, '(A,I0,A,I0)') achar(9) // 'Misses: ', no_misses, ' / ', MAXWRONG
        write(*, '(A,A)') achar(9) // 'Incorrect: ', trim(wrong_guesses)
        write(*, '(A)') achar(9) // 'Hangman:'
        write(*, '(A)') trim(hangman_str)
        write(*, '(A)') ''
        write(*, '(A)') 'Type one letter, or leave blank to abandon the game.'
        write(*, '(A)', advance='no') '> '
        read(*, '(A)') choice
    end subroutine get_choice
    
    subroutine report_outcome(outcome, game_word)
        integer, intent(in) :: outcome
        character(len=*), intent(in) :: game_word
        
        select case (outcome)
            case (GAME_ABANDONED)
                write(*, '(A,A)') 'You abandoned the game. The word was ', trim(game_word)
            case (GAME_LOST)
                write(*, '(A)') LETTER_WRONG
                write(*, '(A,A)') 'You lose. The word was ', trim(game_word)
            case (GAME_WON)
                write(*, '(A)') LETTER_RIGHT
                write(*, '(A,A)') 'Congratulations! You win! The word was ', trim(game_word)
        end select
    end subroutine report_outcome

end program HangmanReconstructedV4

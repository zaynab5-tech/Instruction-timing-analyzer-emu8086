; 8086 INSTRUCTION TIMING ANALYZER - PERFECT VERSION

#MAKE_COM#
ORG 100h

JMP START

; DATA SECTION 
MSG_WELCOME DB '8086 INSTRUCTION TIMING ANALYZER', 13, 10
           DB '                                 ', 13, 10, 13, 10, '$'

MSG_MENU   DB 'MAIN MENU:', 13, 10
           DB '1. Analyze Single Instruction', 13, 10
           DB '2. Analyze Code Block', 13, 10
           DB '3. Timing Reference Table', 13, 10
           DB '4. Exit', 13, 10, 13, 10
           DB 'Enter choice (1-4): $'

MSG_PROMPT DB 13, 10, 'ANALYZE> $'
MSG_RESULT DB 13, 10, 'RESULT:', 13, 10, 13, 10, '$'
MSG_TOTAL  DB 'Total Clock Cycles: $'
MSG_INVALID DB 13, 10, 'ERROR: Invalid input!', 13, 10, '$'
MSG_BYE    DB 13, 10, 'Thank you for using Timing Analyzer!', 13, 10, '$'

; Reference table
REF_TITLE  DB 13, 10, '8086 TIMING REFERENCE TABLE', 13, 10
           DB , 13, 10, 13, 10, '$'
           
REF_LINE1  DB 'MOV reg,reg      :  2 cycles', 13, 10, '$'
REF_LINE2  DB 'MOV reg,mem      :  8 + EA cycles', 13, 10, '$'
REF_LINE3  DB 'MOV mem,reg      :  9 + EA cycles', 13, 10, 13, 10, '$'
REF_LINE4  DB 'ADD/SUB reg,reg  :  3 cycles', 13, 10, '$'
REF_LINE5  DB 'ADD/SUB reg,mem  :  9 + EA cycles', 13, 10, 13, 10, '$'
REF_LINE6  DB 'JMP short        : 15 cycles', 13, 10, '$'
REF_LINE7  DB 'INC/DEC reg      :  2 cycles', 13, 10, 13, 10, '$'
REF_LINE8  DB 'EA CALCULATION:', 13, 10, '$'
REF_LINE9  DB '[BX],[SI],[DI]   :  5 cycles', 13, 10, '$'
REF_LINE10 DB '[BX+SI]          :  7 cycles', 13, 10, '$'
REF_LINE11 DB '[BX+DI]          :  8 cycles', 13, 10, '$'
REF_LINE12 DB 'Press any key to continue...$'

; Code block messages
BLOCK_MSG1 DB 13, 10, 'Code Block Analysis (Type END to finish):', 13, 10, '$'
BLOCK_MSG2 DB 13, 10, 'Analysis Complete!', 13, 10, '$'
BLOCK_MSG3 DB 'Total Instructions: $'
BLOCK_MSG4 DB 'Total Clock Cycles: $'

; Buffers
CHOICE       DB ?
INSTR_BUFFER DB 50 DUP(0)
RESULT_STR   DB 10 DUP('$')
TEMP_NUM     DW ?
LINE_COUNT   DB 0

; CODE SECTION 
START:
    CALL CLEAR_SCREEN
    LEA DX, MSG_WELCOME
    CALL PRINT_STRING

MAIN_LOOP:
    LEA DX, MSG_MENU
    CALL PRINT_STRING
    
    ; Read user choice
    MOV AH, 01h
    INT 21h
    MOV CHOICE, AL
    
    CALL NEW_LINE
    CALL NEW_LINE
    
    ; Process choice
    CMP CHOICE, '1'
    JE OPTION1
    CMP CHOICE, '2'
    JE OPTION2
    CMP CHOICE, '3'
    JE OPTION3
    CMP CHOICE, '4'
    JE OPTION4
    
    ; Invalid choice
    LEA DX, MSG_INVALID
    CALL PRINT_STRING
    JMP MAIN_LOOP

OPTION1:
    CALL ANALYZE_SINGLE
    JMP MAIN_LOOP

OPTION2:
    CALL ANALYZE_BLOCK
    JMP MAIN_LOOP

OPTION3:
    CALL SHOW_REFERENCE
    JMP MAIN_LOOP

OPTION4:
    CALL NEW_LINE
    LEA DX, MSG_BYE
    CALL PRINT_STRING
    MOV AH, 4Ch
    INT 21h

; UTILITY FUNCTIONS
CLEAR_SCREEN PROC
    MOV AX, 0600h
    MOV BH, 07h
    MOV CX, 0000h
    MOV DX, 184Fh
    INT 10h
    
    MOV AH, 02h
    MOV BH, 00h
    MOV DX, 0000h
    INT 10h
    RET
CLEAR_SCREEN ENDP

NEW_LINE PROC
    PUSH AX
    PUSH DX
    MOV AH, 02h
    MOV DL, 13
    INT 21h
    MOV DL, 10
    INT 21h
    POP DX
    POP AX
    RET
NEW_LINE ENDP

PRINT_STRING PROC
    PUSH AX
    MOV AH, 09h
    INT 21h
    POP AX
    RET
PRINT_STRING ENDP

GET_INPUT PROC
    LEA SI, INSTR_BUFFER
INPUT_LOOP:
    MOV AH, 01h
    INT 21h
    CMP AL, 13      ; Enter key
    JE INPUT_DONE
    MOV [SI], AL
    INC SI
    JMP INPUT_LOOP
INPUT_DONE:
    MOV BYTE PTR [SI], '$'
    RET
GET_INPUT ENDP

TO_UPPERCASE PROC
    LEA SI, INSTR_BUFFER
UPPER_LOOP:
    MOV AL, [SI]
    CMP AL, '$'
    JE UPPER_DONE
    CMP AL, 'a'
    JB NOT_LOWER
    CMP AL, 'z'
    JA NOT_LOWER
    SUB AL, 32
    MOV [SI], AL
NOT_LOWER:
    INC SI
    JMP UPPER_LOOP
UPPER_DONE:
    RET
TO_UPPERCASE ENDP

; Check if instruction has brackets [ ]
HAS_BRACKETS PROC
    LEA SI, INSTR_BUFFER
    MOV AL, 0
CHECK_BRACKET_LOOP:
    MOV BL, [SI]
    CMP BL, '$'
    JE CHECK_BRACKET_DONE
    CMP BL, '['
    JE FOUND_BRACKET
    CMP BL, ']'
    JE FOUND_BRACKET
    INC SI
    JMP CHECK_BRACKET_LOOP
FOUND_BRACKET:
    MOV AL, 1
CHECK_BRACKET_DONE:
    RET
HAS_BRACKETS ENDP

; Convert number to string
NUMBER_TO_STRING PROC
    MOV CX, 0
    MOV BX, 10
    LEA DI, RESULT_STR
    
    CMP AX, 0
    JNE CONVERT_LOOP
    MOV BYTE PTR [DI], '0'
    MOV BYTE PTR [DI+1], '$'
    RET
    
CONVERT_LOOP:
    XOR DX, DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX, 0
    JNE CONVERT_LOOP
    
STORE_LOOP:
    POP AX
    ADD AL, '0'
    MOV [DI], AL
    INC DI
    LOOP STORE_LOOP
    
    MOV BYTE PTR [DI], '$'
    RET
NUMBER_TO_STRING ENDP


; OPTION 1: Analyze Single Instruction
ANALYZE_SINGLE PROC
    LEA DX, MSG_PROMPT
    CALL PRINT_STRING
    
    ; Get instruction
    CALL GET_INPUT
    
    CALL NEW_LINE
    LEA DX, MSG_RESULT
    CALL PRINT_STRING
    
    ; Display instruction
    LEA DX, INSTR_BUFFER
    CALL PRINT_STRING
    CALL NEW_LINE
    
    ; Calculate timing - SIMPLE BUT CORRECT METHOD
    CALL CALCULATE_CORRECT_TIMING
    
    ; Display result
    LEA DX, MSG_TOTAL
    CALL PRINT_STRING
    
    MOV AX, TEMP_NUM
    CALL NUMBER_TO_STRING
    LEA DX, RESULT_STR
    CALL PRINT_STRING
    
    CALL NEW_LINE
    CALL NEW_LINE
    RET
ANALYZE_SINGLE ENDP

; SIMPLE BUT CORRECT TIMING CALCULATION
CALCULATE_CORRECT_TIMING PROC
    ; First convert to uppercase
    CALL TO_UPPERCASE
    
    ; Check if it has brackets
    CALL HAS_BRACKETS
    MOV BL, AL  ; BL = 1 if has brackets, 0 if not
    
    ; Get first character of instruction
    LEA SI, INSTR_BUFFER
    MOV AL, [SI]
    
    ; Check instruction type
    CMP AL, 'M'  ; MOV instruction
    JE IS_MOV_INST
    CMP AL, 'A'  ; ADD instruction
    JE IS_ADD_INST
    CMP AL, 'S'  ; SUB instruction
    JE IS_SUB_INST
    CMP AL, 'J'  ; JMP instruction
    JE IS_JMP_INST
    CMP AL, 'I'  ; INC instruction
    JE IS_INC_INST
    CMP AL, 'D'  ; DEC instruction
    JE IS_DEC_INST
    
    ; Default for unknown
    MOV TEMP_NUM, 10
    RET
    
IS_MOV_INST:
    CMP BL, 1
    JE MOV_WITH_MEM
    MOV TEMP_NUM, 6   ; MOV reg,reg = 2 exec + 4 base
    RET
MOV_WITH_MEM:
    MOV TEMP_NUM, 17  ; MOV reg,mem = 8 exec + 5 EA + 4 base
    RET
    
IS_ADD_INST:
    CMP BL, 1
    JE ADD_WITH_MEM
    MOV TEMP_NUM, 7   ; ADD reg,reg = 3 exec + 4 base
    RET
ADD_WITH_MEM:
    MOV TEMP_NUM, 18  ; ADD reg,mem = 9 exec + 5 EA + 4 base
    RET
    
IS_SUB_INST:
    CMP BL, 1
    JE SUB_WITH_MEM
    MOV TEMP_NUM, 7   ; SUB reg,reg = 3 exec + 4 base
    RET
SUB_WITH_MEM:
    MOV TEMP_NUM, 18  ; SUB reg,mem = 9 exec + 5 EA + 4 base
    RET
    
IS_JMP_INST:
    MOV TEMP_NUM, 15  ; JMP short = 11 exec + 4 base
    RET
    
IS_INC_INST:
    CMP BL, 1
    JE INC_WITH_MEM
    MOV TEMP_NUM, 6   ; INC reg = 2 exec + 4 base
    RET
INC_WITH_MEM:
    MOV TEMP_NUM, 24  ; INC mem = 15 exec + 5 EA + 4 base
    RET
    
IS_DEC_INST:
    CMP BL, 1
    JE DEC_WITH_MEM
    MOV TEMP_NUM, 6   ; DEC reg = 2 exec + 4 base
    RET
DEC_WITH_MEM:
    MOV TEMP_NUM, 24  ; DEC mem = 15 exec + 5 EA + 4 base
    RET
    
CALCULATE_CORRECT_TIMING ENDP

; OPTION 2: Analyze Code Block (FIXED)
ANALYZE_BLOCK PROC
    CALL NEW_LINE
    LEA DX, BLOCK_MSG1
    CALL PRINT_STRING
    
    MOV LINE_COUNT, 0
    MOV TEMP_NUM, 0
    
BLOCK_LOOP:
    ; Display line number - FIXED
    MOV AH, 02h
    MOV DL, '['
    INT 21h
    
    ; Calculate line number to display (1-based)
    MOV AL, LINE_COUNT
    INC AL  ; Make it 1-based
    
    ; Convert to decimal and display
    XOR AH, AH
    MOV BL, 10
    DIV BL  ; AL = tens, AH = ones
    
    ; Display tens digit (if any)
    OR AL, AL
    JZ NO_TENS_BLOCK
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 02h
    INT 21h
    
NO_TENS_BLOCK:
    ; Display ones digit
    MOV AL, AH
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 02h
    INT 21h
    
    ; Close bracket and space
    MOV DL, ']'
    INT 21h
    MOV DL, ' '
    INT 21h
    
    ; Get instruction
    CALL GET_INPUT
    CALL NEW_LINE
    
    ; Convert to uppercase for END check
    CALL TO_UPPERCASE
    
    ; Check for END
    LEA SI, INSTR_BUFFER
    CMP BYTE PTR [SI], 'E'
    JNE NOT_END_BLOCK
    CMP BYTE PTR [SI+1], 'N'
    JNE NOT_END_BLOCK
    CMP BYTE PTR [SI+2], 'D'
    JE BLOCK_DONE
    
NOT_END_BLOCK:
    ; Calculate timing for this line
    PUSH TEMP_NUM
    CALL CALCULATE_CORRECT_TIMING
    POP AX
    ADD AX, TEMP_NUM
    MOV TEMP_NUM, AX
    
    INC LINE_COUNT
    CMP LINE_COUNT, 10
    JL BLOCK_LOOP
    
BLOCK_DONE:
    CALL NEW_LINE
    LEA DX, BLOCK_MSG2
    CALL PRINT_STRING
    
    ; Display line count
    CALL NEW_LINE
    LEA DX, BLOCK_MSG3
    CALL PRINT_STRING
    
    ; Show number of instructions
    MOV AL, LINE_COUNT
    CALL SHOW_NUMBER
    
    ; Display total cycles
    CALL NEW_LINE
    LEA DX, BLOCK_MSG4
    CALL PRINT_STRING
    MOV AX, TEMP_NUM
    CALL NUMBER_TO_STRING
    LEA DX, RESULT_STR
    CALL PRINT_STRING
    
    CALL NEW_LINE
    CALL NEW_LINE
    RET
ANALYZE_BLOCK ENDP

; Show 2-digit number
SHOW_NUMBER PROC
    ; AL = number to display (0-99)
    XOR AH, AH
    MOV BL, 10
    DIV BL
    
    PUSH AX
    ; Display tens digit
    OR AL, AL
    JZ NO_TENS_NUM
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 02h
    INT 21h
    
NO_TENS_NUM:
    POP AX
    ; Display ones digit
    MOV AL, AH
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 02h
    INT 21h
    RET
SHOW_NUMBER ENDP

; OPTION 3: Show Reference Table
SHOW_REFERENCE PROC
    CALL CLEAR_SCREEN
    
    LEA DX, MSG_WELCOME
    CALL PRINT_STRING
    
    LEA DX, REF_TITLE
    CALL PRINT_STRING
    
    LEA DX, REF_LINE1
    CALL PRINT_STRING
    
    LEA DX, REF_LINE2
    CALL PRINT_STRING
    
    LEA DX, REF_LINE3
    CALL PRINT_STRING
    
    LEA DX, REF_LINE4
    CALL PRINT_STRING
    
    LEA DX, REF_LINE5
    CALL PRINT_STRING
    
    LEA DX, REF_LINE6
    CALL PRINT_STRING
    
    LEA DX, REF_LINE7
    CALL PRINT_STRING
    
    LEA DX, REF_LINE8
    CALL PRINT_STRING
    
    LEA DX, REF_LINE9
    CALL PRINT_STRING
    
    LEA DX, REF_LINE10
    CALL PRINT_STRING
    
    LEA DX, REF_LINE11
    CALL PRINT_STRING
    
    LEA DX, REF_LINE12
    CALL PRINT_STRING
    
    ; Wait for key press
    MOV AH, 00h
    INT 16h
    
    RET
SHOW_REFERENCE ENDP

END START

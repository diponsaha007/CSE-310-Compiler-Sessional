.MODEL SMALL
.STACK 100H
.DATA
	CR EQU 0DH
	LF EQU 0AH
.CODE
PRINTLN PROC
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	CMP AX,0
	JGE HERE
	PUSH AX
	MOV AH, 2
	MOV DL, '-'
	INT 21H
	POP AX
	NEG AX
HERE:
	XOR CX,CX
	MOV BX , 10
LOOP_:
	CMP AX,0
	JE END_LOOP
	XOR DX,DX
	DIV BX
	PUSH DX
	INC CX
	JMP LOOP_
END_LOOP:
	CMP CX,0
	JNE PRINTER
	MOV AH,2
	MOV DL,'0'
	INT 21H
	JMP ENDER
PRINTER:
	MOV AH,2
	POP DX
	OR DL,30H
	INT 21H
	LOOP PRINTER
ENDER:
	MOV AH, 2
	MOV DL , LF
	INT 21H
	MOV DL , CR
	INT 21H
	POP DX
	POP CX
	POP BX
	POP AX
	RET
PRINTLN ENDP
MAIN PROC
	MOV AX, @DATA
	MOV DS, AX
	PUSH 0
	PUSH 0
	PUSH 0
	MOV AX,3
	MOV BP,SP
	MOV [BP+4] , AX
	MOV AX,8
	MOV BP,SP
	MOV [BP+2] , AX
	MOV AX,6
	MOV BP,SP
	MOV [BP+0] , AX
	PUSH 3
	MOV BP,SP
	MOV AX, [BP+6]
	CMP AX , [BP+0]
	JE LABEL0
	MOV BX,0
	JMP LABEL1
LABEL0:
	MOV BX,1
LABEL1:
	POP DX
	PUSH BX
	MOV BP,SP
	CMP [BP+0] , 0
	JE LABEL2
	MOV BP,SP
	MOV AX, [BP+ 4]
	CALL PRINTLN
LABEL2:
	POP DX
	PUSH 8
	MOV BP,SP
	MOV AX, [BP+4]
	CMP AX , [BP+0]
	JL LABEL3
	MOV BX,0
	JMP LABEL4
LABEL3:
	MOV BX,1
LABEL4:
	POP DX
	PUSH BX
	MOV BP,SP
	CMP [BP+ 0] , 0
	JE LABEL5
	MOV BP,SP
	MOV AX, [BP+ 6]
	CALL PRINTLN
	JMP LABEL6
LABEL5:
	MOV BP,SP
	MOV AX, [BP+ 2]
	CALL PRINTLN
LABEL6:
	POP DX
	PUSH 6
	MOV BP,SP
	MOV AX, [BP+2]
	CMP AX , [BP+0]
	JNE LABEL7
	MOV BX,0
	JMP LABEL8
LABEL7:
	MOV BX,1
LABEL8:
	POP DX
	PUSH BX
	MOV BP,SP
	CMP [BP+ 0] , 0
	JE LABEL17
	MOV BP,SP
	MOV AX, [BP+ 2]
	CALL PRINTLN
	JMP LABEL18
LABEL17:
	PUSH 8
	MOV BP,SP
	MOV AX, [BP+6]
	CMP AX , [BP+0]
	JG LABEL9
	MOV BX,0
	JMP LABEL10
LABEL9:
	MOV BX,1
LABEL10:
	POP DX
	PUSH BX
	MOV BP,SP
	CMP [BP+ 0] , 0
	JE LABEL15
	MOV BP,SP
	MOV AX, [BP+ 6]
	CALL PRINTLN
	JMP LABEL16
LABEL15:
	PUSH 5
	MOV BP,SP
	MOV AX, [BP+10]
	CMP AX , [BP+0]
	JL LABEL11
	MOV BX,0
	JMP LABEL12
LABEL11:
	MOV BX,1
LABEL12:
	POP DX
	PUSH BX
	MOV BP,SP
	CMP [BP+ 0] , 0
	JE LABEL13
	MOV BP,SP
	MOV AX, [BP+ 10]
	CALL PRINTLN
	JMP LABEL14
LABEL13:
	MOV AX,0
	MOV BP,SP
	MOV [BP+6] , AX
	MOV BP,SP
	MOV AX, [BP+ 6]
	CALL PRINTLN
LABEL14:
	POP DX
LABEL16:
	POP DX
LABEL18:
	POP DX
	MOV AH, 4CH
	INT 21H
	MOV AH, 4CH
	INT 21H
MAIN ENDP
END MAIN

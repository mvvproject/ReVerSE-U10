		DEVICE	ZXSPECTRUM48

		org	#0000

; -----------------------------------------------------------------------------
; FAT16 autoloader
; -----------------------------------------------------------------------------
StartProg:
		NOP
		DI
		JP RTC_LOADER
SD_LOADER	
		LD A,#05
		OUT (#FE),A
		CALL COM_SD    
		DB 0
		CP 0
		JR NZ,ERR
		LD HL,#8000
		LD BC,#0000
		LD DE,#0000
		CALL COM_SD
		DB 2		; читаем MBR
		LD A,(#81C6)
		PUSH AF
		LD E,A
		LD D,0
		LD BC,#0000
		LD HL,#8000
		CALL COM_SD
		DB 2		; читаем BOOT RECORD на логическом разделе
		LD A,(#800E)
		LD C,A
		LD HL,(#8016)	; читаем размер FAT-каталога
		ADD HL,HL	; умножаем на два
		LD B,0
		ADD HL,BC	; прибавляем размер Reserved sectors
		LD C,#20
		ADD HL,BC	; прибавляем константу из расчета "два каталога FAT" и "размер сектора = 512байт".
		POP AF
		LD C,A
		ADD HL,BC	; прибавляем смещение между физическими и логическими секторами
		LD D,H
		LD E,L 			
		PUSH DE		; сохраняем полученный номер первого сектора с образом ПЗУ
		LD BC,#0000
		LD HL,#0000
		LD A,#40
		CALL COM_SD
		DB 3		; читаем первые 32кб ПЗУ
		CP 0
		JR NZ,ERR
		POP HL
		LD DE,#0040
		ADD HL,DE
		LD D,H
		LD E,L		; номер сектора с ПЗУ + 40h
		LD SP,#4999
		LD HL,#8000
		LD BC,#0000    
		LD A,#40
		CALL COM_SD
		DB 3    	; читаем вторую половину ПЗУ
		CP 0
		JR NZ,ERR
		LD A,#03
		OUT (#FE),A
		JP #0000
ERR		LD A,2		; AHTUNG! Что-то отвалилось... Или забыли вставить карту ;)
		OUT (254),A
		HALT			

P_DATA		EQU #57
P_CONF		EQU #77

CMD_09		EQU #49		;SEND_CSD
CMD_10		EQU #4A		;SEND_CID
CMD_12		EQU #4C		;STOP_TRANSMISSION
CMD_17		EQU #51		;READ_SINGLE_BLOCK
CMD_18		EQU #52		;READ_MULTIPLE_BLOCK
CMD_24		EQU #58		;WRITE_BLOCK
CMD_25		EQU #59		;WRITE_MULTIPLE_BLOCK
CMD_55		EQU #77		;APP_CMD
CMD_58		EQU #7A		;READ_OCR
CMD_59		EQU #7B		;CRC_ON_OFF
ACMD_41		EQU #69		;SD_SEND_OP_COND

Sd_init		EQU 0
Sd__off		EQU 1
Rdsingl		EQU 2
Rdmulti		EQU 3
Wrsingl		EQU 4
Wrmulti		EQU 5

COM_SD	
		EX AF,AF'
		EX (SP),HL
		LD A,(HL)
		INC HL
		EX (SP),HL
		ADD A,A
		PUSH HL
		LD HL,TABLSDZ
		ADD A,L
		LD L,A
		LD A,H
		ADC A,0
		LD H,A
		LD A,(HL)
		INC HL
		LD H,(HL)
		LD L,A
		EX AF,AF'
		EX (SP),HL
		RET

TABLSDZ		DW SD_INIT	; 0 параметров не требует, на выходе A
				; смотри выше первые 2 значения
		DW SD__OFF	; 1 просто вырубает питание карты
		DW RDSINGL	; 2
		DW RDMULTI	; 3
		DW WRSINGL	; 4
		DW WRMULTI	; 5

SD_INIT		CALL CS_HIGH
		LD BC,P_DATA
		LD DE,#10FF
		OUT (C),E
		DEC D
		JR NZ,$-3
		XOR A
		EX AF,AF'
ZAW001		LD HL,CMD00
		CALL OUTCOM
		CALL IN_OOUT
		EX AF,AF'
		DEC A
		JR Z,ZAW003
		EX AF,AF'
		DEC A
		JR NZ,ZAW001
		LD HL,CMD08
		CALL OUTCOM
		CALL IN_OOUT
		IN H,(C)
		NOP
		IN H,(C)
		NOP
		IN H,(C)
		NOP
		IN H,(C)
		LD HL,0
		BIT 2,A
		JR NZ,ZAW006
		LD H,#40
ZAW006		LD A,CMD_55
		CALL OUT_COM
		CALL IN_OOUT
		LD A,ACMD_41
		OUT (C),A
		NOP
		OUT (C),H
		NOP
		OUT (C),L
		NOP
		OUT (C),L
		NOP
		OUT (C),L
		LD A,#FF
		OUT (C),A
		CALL IN_OOUT
		AND A
		JR NZ,ZAW006
ZAW004		LD A,CMD_59
		CALL OUT_COM
		CALL IN_OOUT
		AND A
		JR NZ,ZAW004
ZAW005		LD HL,CMD16
		CALL OUTCOM
		CALL IN_OOUT
		AND A
		JR NZ,ZAW005

CS_HIGH		PUSH AF
		LD A,3
		OUT (P_CONF),A
		XOR A
		OUT (P_DATA),A
		POP AF
		RET

ZAW003		CALL SD__OFF
		INC A
		RET

SD__OFF		XOR A
		OUT (P_CONF),A
		OUT (P_DATA),A
		RET

CS__LOW		PUSH AF
		LD A,1
		OUT (P_CONF),A
		POP AF
		RET

OUTCOM		CALL CS__LOW
		PUSH BC
		LD BC,#0600+P_DATA
		OTIR
		POP BC
		RET

OUT_COM		PUSH BC
		CALL CS__LOW
		LD BC,P_DATA
		OUT (C),A
		XOR A
		OUT (C),A
		NOP
		OUT (C),A
		NOP
		OUT (C),A
		NOP
		OUT (C),A
		DEC A
		OUT (C),A
		POP BC
		RET

SECM200		PUSH HL
		PUSH DE
		PUSH BC
		PUSH AF
		PUSH BC

		LD A,CMD_58
		LD BC,P_DATA
		CALL OUT_COM
		CALL IN_OOUT
		IN A,(C)
		NOP
		IN H,(C)
		NOP
		IN H,(C)
		NOP
		IN H,(C)
		
		BIT 6,A
		POP HL
		JR NZ,SECN200
		EX DE,HL
		ADD HL,HL
		EX DE,HL
		ADC HL,HL
		LD H,L
		LD L,D
		LD D,E
		LD E,0
SECN200		POP AF
		LD BC,P_DATA
		OUT (C),A
		NOP
		OUT (C),H
		NOP
		OUT (C),L
		NOP
		OUT (C),D
		NOP
		OUT (C),E
		LD A,#FF
		OUT (C),A
		POP BC
		POP DE
		POP HL
		RET

IN_OOUT		PUSH DE
		LD DE,#20FF
IN_WAIT		IN A,(P_DATA)
		CP E
		JR NZ,IN_EXIT
IN_NEXT		DEC D
		JR NZ,IN_WAIT
IN_EXIT		POP DE
		RET

CMD00		DB #40,#00,#00,#00,#00,#95	; GO_IDLE_STATE
CMD08		DB #48,#00,#00,#01,#AA,#87	; SEND_IF_COND
CMD16		DB #50,#00,#00,#02,#00,#FF	; SET_BLOCKEN

RD_SECT		PUSH BC
		LD BC,P_DATA
		INIR 
		NOP
		INIR
		NOP
		IN A,(C)
		NOP
		IN A,(C)
		POP BC
		RET

WR_SECT		PUSH BC
		LD BC,P_DATA
		OTIR
		NOP
		OTIR
		LD A,#FF
		OUT (C),A
		NOP
		OUT (C),A
		POP BC
		RET

RDMULTI		EX AF,AF'
		LD A,CMD_18
		CALL SECM200
		EX AF,AF'
RDMULT1		EX AF,AF'
		CALL IN_OOUT
		CP #FE
		JR NZ,$-5
		CALL RD_SECT
		EX AF,AF'
		DEC A
		JR NZ,RDMULT1
		LD A,CMD_12
		CALL OUT_COM
		CALL IN_OOUT
		INC A
		JR NZ,$-4
		JP CS_HIGH

RDSINGL		LD A,CMD_17
		CALL SECM200
		CALL IN_OOUT
		CP #FE
		JR NZ,$-5
		CALL RD_SECT
		CALL IN_OOUT
		INC A
		JR NZ,$-4
		JP CS_HIGH

WRSINGL		LD A,CMD_24
		CALL SECM200
		CALL IN_OOUT
		INC A
		JR NZ,$-4
		LD A,#FE
		CALL WR_SECT
		CALL IN_OOUT
		INC A
		JR NZ,$-4
		JP CS_HIGH

WRMULTI		EX AF,AF'
		LD A,CMD_25
		CALL SECM200
		CALL IN_OOUT
		INC A
		JR NZ,$-4
		EX AF,AF'
WRMULT1		EX AF,AF'
		LD A,#FC
		CALL WR_SECT
		CALL IN_OOUT
		INC A
		JR NZ,$-4
		EX AF,AF'
		DEC A
		JR NZ,WRMULT1
		LD C,P_DATA
		LD A,#FD
		OUT (C),A
		CALL IN_OOUT
		INC A
		JR NZ,$-4
		JP CS_HIGH		
		
		
; -----------------------------------------------------------------------------	
; PCF8583 -> Virtual RTC 
; -----------------------------------------------------------------------------
; Ports:
; 2FFD DATA	R/W
; 3FFD LENGTH	W
; 4FFD STATUS	W: bit1=STOP_EN, bit0=REQ; R: bit2=ERR, bit1=DONE, bit0=ACK

RTC_LOADER	LD A,#06
		OUT (#FE),A

; [S][SLAVE ADDRES W][A][WORD ADDRES][A][S][SLAVE ADDRESS R][A][BYTE n][A][LAST BYTE][1][P]
		LD A,#01
		LD BC,#3FFD
		OUT (C),A	; LEN
		LD A,#A0	; SLAVE ADDRESS = [1 0 1 0 0 0 A0 R/Wn]
		LD B,#2F
		OUT (C),A
		LD A,#01
		LD B,#4F
		OUT (C),A	; bit1:STOP = 0; bit0:REQ = 1
RTC_ACK		IN A,(C)
		RRA
		JR NC,RTC_ACK	; ACK ?
		LD A,#00	; WORD ADDRESS
		LD B,#2F
		OUT (C),A
RTC_DONE	IN A,(C)
		RRA
		JR NC,RTC_DONE	; DONE ?
		
		LD A,#10	; SLAVE ADDRESS + 16 BYTE READ
		LD B,#3F
		OUT (C),A	; LEN
		LD A,#A1	; SLAVE ADDRESS = [1 0 1 0 0 0 A0 R/Wn]
		LD B,#2F
		OUT (C),A
		LD A,#03
		LD B,#4F
		OUT (C),A	; bit1:STOP = 1; bit0:REQ = 1 

		LD E,#0F
		LD HL,#4900
RTC_ACK1	LD B,#4F
		IN A,(C)
		RRA
		JR NC,RTC_ACK1	; ACK ?
		LD B,#2F
		IN A,(C)
		LD (HL),A
		INC HL
		DEC E
		JR NZ,RTC_ACK1
		
		LD A,#00
		LD B,#4F
		OUT (C),A	; bit1:STOP = 0; bit0:REQ = 0
		
		LD A,#80
		LD BC,#EFF7
		OUT(C),A

; REGISTER B
		LD A,#0B
		LD B,#DF
		OUT (C),A
		LD A,#82
		LD B,#BF
		OUT (C),A
; SECONDS
		LD A,#00
		LD B,#DF
		OUT (C),A
		LD A,(#4902)
		LD B,#BF
		OUT (C),A
; MINUTES		
		LD A,#02
		LD B,#DF
		OUT (C),A
		LD A,(#4903)
		LD B,#BF
		OUT (C),A
; HOURS		
		LD A,#04
		LD B,#DF
		OUT (C),A
		LD A,(#4904)
		AND #3F
		LD B,#BF
		OUT (C),A
; DAY OF THE WEEK		
		LD A,#06
		LD B,#DF
		OUT (C),A
		LD A,(#4906)
		AND #E0
		RLCA
		RLCA
		RLCA
		LD B,#BF
		OUT (C),A
; DATE OF THE MONTH
		LD A,#07
		LD B,#DF
		OUT (C),A
		LD A,(#4905)
		AND #3F
		LD B,#BF
		OUT (C),A
; MONTH
		LD A,#08
		LD B,#DF
		OUT (C),A
		LD A,(#4906)
		AND #1F
		LD B,#BF
		OUT (C),A
; YEAR
		LD A,#09
		LD B,#DF
		OUT (C),A
		LD A,(#4905)
		AND #C0
		RLCA
		RLCA
		LD B,#BF
		OUT (C),A
; REGISTER B
		LD A,#0B
		LD B,#DF
		OUT (C),A
		LD A,#02
		LD B,#BF
		OUT (C),A

		LD A,#00
		LD BC,#EFF7
		OUT(C),A

		LD A,#07
		OUT (#FE),A
		JP SD_LOADER
		
		
		savebin "boot.bin",StartProg, 4096
		savesna "boot.sna",StartProg	
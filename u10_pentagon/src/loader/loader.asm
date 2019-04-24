 		DEVICE	ZXSPECTRUM48
; -----------------------------------------------------------------------------
; LOADER
; -----------------------------------------------------------------------------
; By MVV
; Version  : 0.01 [Rev.20110729]
; Devboard : U9EP3C

		ORG #0000
StartProg:
		DI
		LD SP,#7FFE

; -----------------------------------------------------------------------------
; SPI loader
; -----------------------------------------------------------------------------
		CALL SPI_START
		LD D,%10101011	; Command = SIGNATURE
		CALL SPI_RW
		LD D,#00
		CALL SPI_RW	; 3 DUMMY BYTES
		CALL SPI_RW
		CALL SPI_RW
		CALL SPI_RW
		LD C,A
		CALL SPI_END
		LD A,#12
		CP C		; Проверка сигнатуры M25P40 = 12h?
		JP NZ,SPI_LOADER0
		
		CALL SPI_START
		LD D,%00000011	; Команда = READ
		CALL SPI_RW
		LD D,#06	; Address = #060000
		CALL SPI_RW
		LD D,#00
		CALL SPI_RW
		LD D,#00
		CALL SPI_RW
		
		LD BC,#0218	; B= страниц, C= страница ROM
		LD D,#FF
SPI_LOADER2	LD HL,#8000	; Адрес страницы ROM
		LD A,C
		OUT (#00),A	; Страница по адресу #8000 для ROM
SPI_LOADER1	CALL SPI_RW
		LD (HL),A
		LD (22528),A
		INC HL
		LD A,H
		CP #C0
		JR NZ,SPI_LOADER1
		INC C
		DJNZ SPI_LOADER2
		CALL SPI_END
		LD A,#02
		OUT (#00),A
		LD SP,#FFFF
		JP #0000

SPI_LOADER0	LD A,#02
		OUT (#FE),A
		JR SPI_LOADER0

; -----------------------------------------------------------------------------	
; SPI 
; -----------------------------------------------------------------------------
; Ports:
; #02: Data Buffer (write/read)
;	bit 7-0	= Stores SPI read/write data

; #03: Command/Status Register (write)
;	bit 7-2	= Reserved
;	bit 1	= IRQEN 	(Generate IRQ at end of transfer)
;	bit 0	= END   	(Deselect device after transfer/or immediately if START = '0')
; #03: Command/Status Register (read):
; 	bit 7	= BUSY		(Currently transmitting data)
;	bit 6	= DESEL		(Deselect device)
;	bit 5-0	= Reserved

P_SPIDATA	EQU #02
P_SPICONF	EQU #03

SPI_END		LD A,%00000001	; Config = END
		OUT (P_SPICONF),A
		RET
		
SPI_START	XOR A
		OUT (P_SPICONF),A
		RET
		
SPI_RW		IN A,(P_SPICONF)
		RLCA
		JR C,SPI_RW
		LD A,D
		OUT (P_SPIDATA),A
SPI_RW1		IN A,(P_SPICONF)
		RLCA
		JR C,SPI_RW1
		IN A,(P_SPIDATA)
		RET

		savebin "loader.bin",StartProg, 1024
;		savesna "loader.sna",StartProg	
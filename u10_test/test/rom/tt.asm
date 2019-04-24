; U10EP3C Rev.12 POST v0.03 By MVV

; 18.09.2010 Last Edition

; MemPage   70h
; VideoChar 90h
; Cursor_X  91h
; Cursor_Y  92h


;Test MemPort
           xor a
           out (70h),a          ; Bank0
           in a,(70h)
           cp 00h
           jr nz,t0err
           ld a,01h
           out (70h),a
           in a,(70h)
           cp 01h
           jr z,t0
t0err:
           ld ix,t0p
           jp cls
t0p:
           ld ix,err12
           ld hl,Text11
           ld de,4000h          ; Video Memory address
           jp prn_txt

;Test Memory
t0:
           ld ix,t1
           ld hl,8000h
           jp test_mem          ;4000h - BFFFh
t1:
           jr nc,t2             ;no error
err1:
           ld ix,err11
           jp cls
err11:
           ld ix,err12
           ld hl,Text7
           ld de,4000h          ; Video Memory address
           jp prn_txt
err12:
           jp err12             ;CPU Stop
t2:
           ld ix,t2ok
           jp cls
t2ok:
           ld ix,t3
           ld hl,Text1
           ld de,4000h
           jp prn_txt
t3:
           ld ix,t4
           ld hl,Text6
           ld de,4050h
           jp prn_txt
t4:
           ld ix,t5
           ld hl,Text3          ; OK
           jp prn_txt

;Test SRAM 512K
t5:
           ld ix,t6
           ld hl,Text5
           ld de,40A0h
           jp prn_txt
t6:
           ld ix,t6p
           ld hl,Text8P
           ld de,40F0h
           jp prn_txt
t6p:
           ld b,20h             ; 32 Page x 16K = 512K
t6pm:
           ld a,b
           dec a
           out (70h),a
           ld a,b
           ld (#C000),a
           djnz t6pm

           ld b,20h             ; 32 Page x 16K = 512K
t6pt:
           ld a,b
           dec a
           out (70h),a
           ld a,(000h)
           cp b
           ld a,3Dh             ;=
           jr z, t6ok
           ld a,23h             ;#
t6ok:
           ld (de),a
           inc de
           djnz t6pt
;----------
           ld ix,t6c
           ld hl,Text8D
           ld de,4118h
           jp prn_txt
t6c:
           ld ix,t7
           ld hl,#c000
           jp test_mem
t7:
           ld a,3Dh             ;=
           jr nc,t7ok
           ld a,23h             ;#
t7ok:
           ld (de),a
           inc de
           in a,(70h)
           inc a
           cp 32
           jr nc,t8
           out (70h),a
           jr t6c
t8:
           ld ix,t12
           ld hl,Text9
           ld de,41e0h
           jp prn_txt
t12:
           ld de,4230h
           ld ix,t13
           ld hl,Text2
           jp prn_txt
t13:
           ld sp,#BFF0
setprint:
           ld de,4281h
           ld bc,30
loopprint:
           push bc
           push de
           call delay
           ld hl,41EBh
           in a,(71h)
           ld b,8
port1:
           rlca
           ld c,30h
           jr nc,port0
           ld c,31h
port0:
           ld (hl),c
           inc hl
           djnz port1
looppr2:
           pop de
           pop bc
           in a,(80h)
           or a
           jr z,loopprint
           cp 1Bh               ;ESC
           jr z,go_on
looppr3:
           ld (de),a
           inc de
           dec bc
           ld a,b
           or c
           jr z,setprint
           jr loopprint
go_on:
           ld de,42D0h          ; Video Memory address
           ld hl,Text10
           ld ix,ext
           jp prn_txt
ext:
           jp ext
;------------------------------------------------------------
; Test Block 16K
;IX = return
;HL = start
test_mem:
           ld bc,4000h
test_mem1:
           ld (hl),l
           inc hl
           dec bc
           ld a,b
           or c
           jr nz,test_mem1
           ld b,40h
test_mem2:
           dec hl
           ld a,l
           cp (hl)
           jr nz,test_err
           dec bc
           ld a,b
           or c
           jr nz,test_mem2
           ld b,40h
test_mem3:
           ld (hl),l
           inc hl
           dec bc
           ld a,b
           or c
           jr nz,test_mem3
           ld b,40h
test_mem4:
           dec hl
           ld a,l
           cp (hl)
           jr nz,test_err
           dec bc
           ld a,b
           or c
           jr nz,test_mem4
           jp (ix)                      ;C=0 No Error
test_err:
           scf                          ;C=1 Error
           jp (ix)

;------------------------------------------------------------
;IX = return
;HL = start
;DE = screen
prn_txt:
           ld a,(hl)
           or a
           jr z,prn_txt1
           ld (de),a
           inc hl
           inc de
           jr prn_txt
prn_txt1:
           jp (ix)

;---------------------------------------
delay:
           ld a,10
loop5:
           push af
           ld bc,5000             ; Every delay has at least 255 loops
loop6:
           dec bc                ; Start counting backwards
           ld a,b
           or c
           jr nz,loop6          ; If A greather than 0, continue loop
           pop af               ; Get multiplier back
           dec a                ;
           jr nz,loop5
           ret                  ; return to calling program

;----------------------------------
;ix = return
cls:
        xor a
        out (91h),a      ; video cursor x = 0
        out (92h),a      ; video cursor y = 0
        ld bc,3200
cls1:
        ld a,20h
        out (90h),a      ; print character to video
                             ; cursor x,y is automatically updated
                             ; by hardware
        dec bc
        ld a,b
        or c
        jr nz,cls1
        jp (ix)
        
           
Text1:
           db "U10EP3C POST v0.03 By MVV",0
Text2:
           db "Keyboard Test (ESC=Exit)... ",0
Text3:
           db "OK",0
Text4:
           db "ERROR",0
Text5:
           db "Test SRAM (512K) ",0
Text6:
           db "Internal RAM Test... ",0
Text7:
           db "INTERNAL RAM ERROR! CPU HALT.",0
Text8P:
           db "Page: ",0
Text8D:
           db "Date: ",0
Text9:
           db "PS/2 GPIO: ",0
Text10:
           db "Test Complete. Press RESET.",0
Text11:
           db "Port I/O ERROR! CPU HALT.",0
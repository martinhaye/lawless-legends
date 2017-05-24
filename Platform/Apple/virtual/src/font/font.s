;****************************************************************************************
; Copyright (C) 2015 The 8-Bit Bunch. Licensed under the Apache License, Version 1.1 
; (the "License"); you may not use this file except in compliance with the License.
; You may obtain a copy of the License at <http://www.apache.org/licenses/LICENSE-1.1>.
; Unless required by applicable law or agreed to in writing, software distributed under 
; the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF 
; ANY KIND, either express or implied. See the License for the specific language 
; governing permissions and limitations under the License.
;****************************************************************************************

*=$6000
 !byte 3,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;0 space
 !byte 2,$03,$03,$03,$03,$00,$03,$03,$00,$00 ;1 ! exclamation mark
 !byte 5,$1B,$1B,$1B,$00,$00,$00,$00,$00,$00 ;2 " double quote
 !byte 7,$36,$36,$7F,$36,$7F,$36,$36,$00,$00 ;3 # pound sign
 !byte 7,$18,$7E,$1B,$3E,$6C,$3F,$0C,$00,$00 ;4 $ dollar sign
 !byte 5,$1B,$1B,$18,$0E,$03,$1B,$1B,$00,$00 ;5 % percent
 !byte 7,$0E,$1B,$1B,$04,$6B,$13,$6E,$00,$00 ;6 ampersand
 !byte 2,$03,$03,$03,$00,$00,$00,$00,$00,$00 ;7 single quote
 !byte 4,$0C,$06,$03,$03,$03,$06,$0C,$00,$00 ;8 left parenthesis
 !byte 4,$03,$06,$0C,$0C,$0C,$06,$03,$00,$00 ;9 right parenthesis
 !byte 7,$08,$1C,$7F,$3E,$1C,$3E,$36,$00,$00 ;10 asterisk
 !byte 4,$00,$00,$06,$0F,$06,$00,$00,$00,$00 ;11 plus
 !byte 3,$00,$00,$00,$00,$00,$06,$06,$03,$00 ;12 comma
 !byte 3,$00,$00,$00,$07,$00,$00,$00,$00,$00 ;13 minus
 !byte 2,$00,$00,$00,$00,$00,$00,$03,$00,$00 ;14 period
 !byte 4,$00,$0C,$0C,$06,$06,$03,$03,$00,$00 ;15 right slash
 !byte 5,$0E,$1B,$1B,$1B,$1B,$1B,$0E,$00,$00 ;16 0
 !byte 5,$0C,$0E,$0E,$0C,$0C,$1E,$1E,$00,$00 ;17 1
 !byte 6,$1F,$3B,$38,$0C,$06,$33,$3F,$00,$00 ;18 2
 !byte 6,$1F,$3B,$30,$1C,$30,$3B,$1F,$00,$00 ;19 3
 !byte 7,$33,$33,$33,$3E,$30,$78,$78,$00,$00 ;20 4
 !byte 6,$3F,$33,$03,$1F,$38,$3B,$1F,$00,$00 ;21 5
 !byte 6,$3E,$33,$03,$1F,$33,$33,$1E,$00,$00 ;22 6
 !byte 6,$3F,$3B,$18,$0C,$0C,$06,$06,$00,$00 ;23 7
 !byte 7,$1C,$77,$77,$3E,$62,$63,$3E,$00,$00 ;24 8
 !byte 6,$3E,$33,$33,$3E,$38,$30,$30,$00,$00 ;25 9
 !byte 2,$00,$03,$03,$00,$03,$03,$00,$00,$00 ;26 colon
 !byte 3,$00,$00,$06,$00,$00,$06,$06,$03,$00 ;27 semicolon
 !byte 4,$00,$0C,$06,$03,$06,$0C,$00,$00,$00 ;28 less than
 !byte 3,$00,$00,$07,$00,$07,$00,$00,$00,$00 ;29 equals
 !byte 4,$00,$03,$06,$0C,$06,$03,$00,$00,$00 ;30 greater than
 !byte 5,$0E,$1B,$18,$0C,$0C,$00,$0C,$00,$00 ;31 question mark
 !byte 6,$1E,$33,$3B,$3B,$3B,$03,$1E,$00,$00 ;32 at sign
 !byte 8,$3C,$7E,$66,$FF,$83,$E7,$E7,$00,$00 ;33 A
 !byte 6,$0F,$1B,$1B,$1F,$33,$33,$1F,$00,$00 ;34 B
 !byte 7,$1E,$77,$63,$03,$63,$77,$1E,$00,$00 ;35 C
 !byte 6,$0F,$1B,$33,$33,$33,$37,$1F,$00,$00 ;36 D
 !byte 6,$3F,$33,$03,$1F,$03,$33,$3F,$00,$00 ;37 E
 !byte 6,$3F,$33,$03,$0F,$03,$03,$03,$00,$00 ;38 F
 !byte 7,$3E,$33,$03,$7B,$7B,$33,$3E,$00,$00 ;39 G
 !byte 7,$77,$77,$63,$7F,$63,$77,$77,$00,$00 ;40 H
 !byte 4,$0F,$0F,$06,$06,$06,$0F,$0F,$00,$00 ;41 I
 !byte 6,$3E,$36,$30,$30,$33,$33,$1E,$00,$00 ;42 J
 !byte 6,$1B,$1B,$0F,$07,$1F,$3B,$33,$00,$00 ;43 K
 !byte 6,$07,$07,$03,$03,$33,$3B,$3F,$00,$00 ;44 L
 !byte 8,$C3,$E7,$DB,$DB,$C3,$E7,$E7,$00,$00 ;45 M
 !byte 8,$F3,$F7,$6F,$7F,$7B,$F7,$E7,$00,$00 ;46 N
 !byte 6,$1E,$33,$33,$33,$33,$33,$1E,$00,$00 ;47 O
 !byte 6,$1F,$3B,$33,$3F,$1B,$03,$03,$00,$00 ;48 P
 !byte 6,$1E,$33,$33,$37,$3B,$3B,$7E,$60,$00 ;49 Q
 !byte 7,$0F,$1B,$1B,$0F,$1F,$3B,$33,$00,$00 ;50 R
 !byte 6,$3E,$33,$07,$1E,$38,$33,$1F,$00,$00 ;51 S
 !byte 8,$FF,$FF,$DB,$18,$18,$3C,$3C,$00,$00 ;52 T
 !byte 7,$77,$77,$63,$63,$63,$7F,$3E,$00,$00 ;53 U
 !byte 7,$63,$63,$63,$77,$36,$3E,$1C,$00,$00 ;54 V
 !byte 8,$E7,$E7,$C3,$DB,$DB,$DB,$66,$00,$00 ;55 W
 !byte 6,$33,$33,$1E,$0C,$0E,$33,$33,$00,$00 ;56 X
 !byte 7,$77,$77,$63,$3E,$1C,$1C,$1C,$00,$00 ;57 Y
 !byte 7,$3F,$33,$18,$3F,$06,$33,$3F,$00,$00 ;58 Z
 !byte 4,$0F,$03,$03,$03,$03,$03,$0F,$00,$00 ;59 left sqr bracket
 !byte 4,$03,$03,$06,$06,$06,$0C,$0C,$00,$00 ;60 left slash
 !byte 4,$0F,$0C,$0C,$0C,$0C,$0C,$0F,$00,$00 ;61 right sqr bracket
 !byte 5,$04,$0E,$1B,$00,$00,$00,$00,$00,$00 ;62 carrot
 !byte 4,$00,$00,$00,$00,$00,$00,$1F,$00,$00 ;63 underscore
 !byte 3,$03,$03,$06,$00,$00,$00,$00,$00,$00 ;64 left single quote
 !byte 5,$00,$00,$1E,$1B,$1B,$1B,$1E,$00,$00 ;65 a
 !byte 5,$03,$03,$0F,$1B,$1B,$1B,$0F,$00,$00 ;66 b
 !byte 5,$00,$00,$0E,$1B,$03,$1B,$0E,$00,$00 ;67 c
 !byte 5,$18,$18,$1E,$1B,$1B,$1B,$1E,$00,$00 ;68 d
 !byte 5,$00,$00,$0E,$1B,$1F,$03,$0E,$00,$00 ;69 e
 !byte 5,$0C,$1E,$06,$1F,$06,$06,$06,$00,$00 ;70 f
 !byte 5,$00,$00,$1E,$1B,$1B,$1B,$1E,$18,$0F ;71 g
 !byte 5,$03,$03,$0F,$1F,$1B,$1B,$1B,$00,$00 ;72 h
 !byte 2,$03,$00,$03,$03,$03,$03,$03,$00,$00 ;73 i
 !byte 4,$0C,$00,$0C,$0C,$0C,$0C,$0C,$0F,$06 ;74 j
 !byte 5,$03,$03,$1B,$0F,$07,$0F,$1B,$00,$00 ;75 k
 !byte 2,$03,$03,$03,$03,$03,$03,$03,$00,$00 ;76 l
 !byte 8,$00,$00,$67,$DB,$DB,$DB,$C3,$00,$00 ;77 m
 !byte 5,$00,$00,$0F,$1B,$1B,$1B,$1B,$00,$00 ;78 n
 !byte 5,$00,$00,$0E,$1B,$1B,$1B,$0E,$00,$00 ;79 o
 !byte 5,$00,$00,$0F,$1B,$1B,$1B,$0F,$03,$03 ;80 p
 !byte 6,$00,$00,$0E,$1B,$1B,$1B,$1E,$18,$18 ;81 q
 !byte 4,$00,$00,$0F,$07,$03,$03,$03,$00,$00 ;82 r
 !byte 4,$00,$00,$0E,$03,$06,$0C,$07,$00,$00 ;83 s
 !byte 4,$00,$06,$0F,$06,$06,$06,$0C,$00,$00 ;84 t
 !byte 5,$00,$00,$1B,$1B,$1B,$1B,$1E,$00,$00 ;85 u
 !byte 5,$00,$00,$1B,$1B,$1B,$0F,$06,$00,$00 ;86 v
 !byte 8,$00,$00,$C3,$C3,$DB,$DB,$66,$00,$00 ;87 w
 !byte 5,$00,$00,$1B,$1B,$0E,$1B,$1B,$00,$00 ;88 x
 !byte 5,$00,$00,$1B,$1B,$1B,$1B,$1E,$18,$0E ;89 y
 !byte 5,$00,$00,$1F,$0C,$06,$03,$1F,$00,$00 ;90 z
 !byte 4,$0C,$06,$06,$03,$06,$06,$0C,$00,$00 ;91 left curly brkt
 !byte 2,$03,$03,$03,$00,$03,$03,$03,$00,$00 ;92 vertical bar
 !byte 4,$03,$06,$06,$0C,$06,$06,$03,$00,$00 ;93 right curly brkt
 !byte 6,$00,$36,$1B,$00,$00,$00,$00,$00,$00 ;94 tilde
 !byte 5,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F ;95 solid cursor blk
 !byte 6,$00,$00,$12,$00,$0C,$21,$1E,$00,$00 ;96 smile
 !byte 7,$00,$36,$7F,$7F,$3E,$3E,$1C,$08,$00 ;97 heart
 !byte 7,$00,$08,$1C,$3E,$7F,$3E,$1C,$08,$00 ;98 diamond
 !byte 7,$08,$1C,$3E,$7F,$7F,$3E,$08,$1C,$00 ;99 spade
 !byte 8,$18,$3C,$18,$5A,$FF,$5A,$18,$3C,$00 ;100 club
 !byte 4,$18,$08,$08,$08,$0E,$0F,$06,$00,$00 ;101 note1
 !byte 4,$0F,$08,$08,$0E,$0F,$06,$00,$00,$00 ;102 note2
 !byte 8,$18,$18,$1A,$5B,$DB,$DE,$78,$18,$18 ;103 cactus
 !byte 8,$00,$43,$FE,$FF,$1B,$0F,$03,$00,$00 ;104 gun1
 !byte 8,$00,$C2,$7F,$FF,$D8,$F0,$C0,$00,$00 ;105 gun2
 !byte 7,$60,$30,$30,$18,$1B,$0E,$06,$00,$00 ;106 check mark
 !byte 7,$06,$6F,$3C,$18,$1C,$76,$33,$00,$00 ;107 X mark
 !byte 2,$03,$03,$03,$03,$03,$03,$03,$03,$03 ;108 full bar
 !byte 6,$00,$1E,$3F,$3F,$3F,$1E,$00,$00,$00 ;109 circl blt
 !byte 4,$01,$03,$07,$0F,$07,$03,$01,$00,$00 ;110 triang blt
 !byte 5,$32,$3B,$2C,$38,$30,$18,$34,$23,$02 ;111 skull1o2
 !byte 6,$13,$37,$0D,$07,$03,$06,$0B,$31,$10 ;112 skull2o2
 !byte 8,$1E,$B3,$DE,$B3,$BB,$B3,$B7,$5E,$00 ;113 mug


;xkas 0.06
hirom
;header
org $C20000


;Entry points - All battle code from outside the bank calls to here
LC20000:  JMP $000C
LC20003:  JMP $111B
LC20006:  JMP $0E77      ;load equipment data for character in A
LC20009:  JMP $4730


LC2000C:  PHP
LC2000D:  SEP #$30
LC2000F:  LDA #$7E
LC20011:  PHA            ;Put on stack
LC20012:  PLB            ;set Data Bank register to 7E
LC20013:  JSR $261E
LC20016:  JSR $23ED      ;Initialize many things at battle start
LC20019:  INC $BE        ;increment RNG table index.  start of MAIN BATTLE LOOP.
LC2001B:  LDA $3402      ;Get the number of turns due to Quick
LC2001E:  BNE LC20023    ;Branch if not zero; either we are in a regular (i.e. non-Quick
                         ;turn, or else we are in the process of executing Quick turns.
                         ;Only if the final Quick turn just passed will we do the next line.
                         ;Either way, we still need to decrement the number of Quick turns.
LC20020:  DEC $3402      ;Decrement the number of turns due to Quick
LC20023:  LDA #$01
LC20025:  JSR $6411
LC20028:  JSR $2095      ;Recalculate applicable characters' properties from their current
                         ;equipment and relics
LC2002B:  LDA $3A58      ;was anybody's main menu flagged to be redrawn
                         ;right away?
LC2002E:  BEQ LC20033    ;branch if not
LC20030:  JSR $00CC      ;redraw the applicable menus
LC20033:  LDA $340A      ;get entry point to Special Action Queue.  high-priority stuff,
                         ;including auto-spellcasts from equipment, and timed statuses
                         ;expiring.
LC20036:  CMP #$FF
LC20038:  BEQ LC2003D    ;branch if it's null, as queue is empty
LC2003A:  JMP $2163      ;Process one record from Special Action linked list queue
LC2003D:  LDA #$04
LC2003F:  TRB $3A46      ;clear flag
LC20042:  BEQ LC20049    ;branch if we're not about to have Gau return at the end of
                         ;a Veldt battle
LC20044:  JSR $0A91      ;for all living, present, non-Jumping characters: remove entity
                         ;from Wait Queue, remove all records from their conventional
                         ;linked list queue, and default some poses
LC20047:  BRA LC20019    ;branch to top of main battle loop
LC20049:  LDX $3407      ;did we leave off processing an entity's Counterattack and
                         ;Periodic Damage/Healing linked list queue?
LC2004C:  BPL LC2005F    ;if so, go resume processing it
LC2004E:  LDX $3A68      ;get position of next Counterattack and Periodic Damage/Healing
                         ;[from Seizure/Regen/etc.] Queue slot to read.
LC20051:  CPX $3A69      ;does it match position of the next available [unused]
                         ;queue slot?  iow, have we read through the end of queue?
LC20054:  BEQ LC20062    ;if so, branch
LC20056:  INC $3A68      ;increment next Counterattack / Periodic Damage Queue position
LC20059:  LDA $3920,X    ;see who's in line at current position
LC2005C:  BMI LC2004E    ;if it's null entry, skip it and check next one
LC2005E:  TAX
LC2005F:  JMP $4B7B      ;process one or two records from entity's Counterattack and
                         ;Periodic Damage/Healing linked list queue
LC20062:  LDA $3A3A      ;bitfield of dead-ish monsters
LC20065:  AND $2F2F      ;bitfield of remaining enemies
LC20068:  BEQ LC2006F
LC2006A:  TRB $2F2F      ;if any entity in both, rectify by clearing from latter...
LC2006D:  BRA LC20019    ;...and go to start of main battle loop
LC2006F:  LDA #$20
LC20071:  TRB $B0        ;clear flag
LC20073:  BEQ LC2007D    ;branch if no entity has executed conventional turn since
                         ;this point was last reached
LC20075:  JSR $5C73      ;Update Can't Escape, Can't Run, Run Difficulty, and
                         ;onscreen list of enemy names, based on currently present
                         ;enemies
LC20078:  LDA #$06
LC2007A:  JSR $6411
LC2007D:  LDA #$04
LC2007F:  TRB $B0        ;indicate that we've reached this point since C2/5BF3 last
                         ;executed [and considered queueing Flee command]
LC20081:  JSR $47ED
LC20084:  LDA #$FF
LC20086:  LDX #$03
LC20088:  STA $33FC,X    ;batch of Counterattacks and Periodic Damage/Healing is
                         ;over, so null two bitfields:
                         ;16-bit $33FC (Entity has done a "Run Monster Script"
                         ; [Command 1Fh] in this batch
                         ;16-bit $33FE (Entity was targeted in the attack that
                         ; triggered its counter, and by somebody/something other
                         ; than itself)
LC2008B:  DEX
LC2008C:  BPL LC20088
LC2008E:  LDA #$01
LC20090:  TRB $B1        ;indicate it's a conventional attack
LC20092:  LDX $3A64      ;get position of next Wait Queue slot to read.
                         ;yes, we even wait in order to wait; they're very polite
                         ;over in Japan.
LC20095:  CPX $3A65      ;does it match position of the next available [unused]
                         ;queue slot?  iow, have we read through the end of queue?
LC20098:  BEQ LC200A6    ;if so, branch
LC2009A:  INC $3A64      ;increment next Wait Queue position
LC2009D:  LDA $3720,X    ;see who's in line at current position
LC200A0:  BMI LC20092    ;if it's null entry, skip it and check next one
LC200A2:  TAX
LC200A3:  JMP $2188      ;Do early processing of one record from entity's
                         ;conventional linked list queue, establish "time to wait",
                         ;and visually enter ready stance if character
LC200A6:  LDX $3406      ;did we leave off processing an entity's conventional
                         ;linked list queue?
LC200A9:  BPL LC200C2    ;if so, go resume processing it
LC200AB:  LDX $3A66      ;get position of next Action Queue slot to read
LC200AE:  CPX $3A67      ;does it match position of the next available [unused]
                         ;queue slot?  iow, have we read through the end of queue?
LC200B1:  BNE LC200B9    ;if not, branch
LC200B3:  STZ $3A95      ;allow C2/47FB to check for combat end
LC200B6:  JMP $0019      ;branch to start of main battle loop
LC200B9:  INC $3A66      ;increment next Action Queue position
LC200BC:  LDA $3820,X    ;see who's in line at current position
LC200BF:  BMI LC200AB    ;if it's null entry, which can happen from Palidor
                         ;and who knows what else, skip it and check next one
LC200C1:  TAX
LC200C2:  JMP $00F9      ;Do later processing of one or more records from entity's
                         ;conventional linked list queue


LC200C5:  LDA #$09
LC200C7:  JSR $6411
LC200CA:  PLP
LC200CB:  RTL


;Redraw main menus of characters who requested it in C2/527D
;Will keep grayed versus white commands up-to-date.)

LC200CC:  LDX #$06
LC200CE:  LDA $3018,X
LC200D1:  TRB $3A58      ;clear flag to redraw this character's menu
                         ;[note that switching between characters with
                         ;X and Y will still redraw]
LC200D4:  BEQ LC200DF    ;branch if it hadn't been set
LC200D6:  STX $10
LC200D8:  LSR $10
LC200DA:  LDA #$0B
LC200DC:  JSR $6411      ;this must be responsible for the menu redrawing
LC200DF:  DEX
LC200E0:  DEX
LC200E1:  BPL LC200CE    ;loop for all 4 party members
LC200E3:  RTS


LC200E4:  TSB $3F2C      ;set "Jumping" flag for whomever is held in A
LC200E7:  SEP #$20       ;Set 8-bit Accumulator
LC200E9:  LDA $3AA0,X
LC200EC:  ORA #$08
LC200EE:  AND #$DF
LC200F0:  STA $3AA0,X    ;$3AA0: turn on bit 3 and turn off bit 5
LC200F3:  STZ $3AB5,X    ;zero top byte of Wait Timer
LC200F6:  JMP $4E66      ;put entity in wait queue


;Do later processing of one or more records from entity's conventional linked list queue

LC200F9:  SEC
LC200FA:  ROR $3406      ;make $3406 negative.  this defaults to not leaving
                         ;off processing any entity.
LC200FD:  PEA $0018      ;will return to C2/0019
LC20100:  LDA #$12
LC20102:  STA $B5
LC20104:  STA $3A7C
LC20107:  LDA $32CC,X    ;get entry point to entity's conventional linked list
                         ;queue
LC2010A:  BMI LC20183    ;branch if null.  that can happen if a monster script
                         ;ran and didn't perform anything; e.g. Command F0h
                         ;chose an FEh.  alternatively, a monster script ran when
                         ;this linked list queue was otherwise empty, so command
                         ;it queued added records to both this list and the $3820
                         ;"who" queue.  then this list is emptied right before
                         ;executing the command, without adjusting $3A66 to delete
                         ;the $3820 queue record.
                         ;in any case, with this test as a safeguard and C2/00B9
                         ;getting rid of the stranded $3820 record, we're good.
LC2010C:  ASL
LC2010D:  TAY            ;adjust pointer for 16-bit fields
LC2010E:  LDA $3420,Y    ;get command from conventional linked list queue
LC20111:  CMP #$12
LC20113:  BNE LC20118    ;Branch if not Mimic
LC20115:  JSR $01D9      ;Copy contents of Mimic variables over [and possibly
                         ;after] queued command, attack, and targets data
LC20118:  SEC
LC20119:  JSR $0276      ;Load command, attack, targets, and MP cost from queued
                         ;data.  Some commands become Fight if tried by an Imp.
LC2011C:  CMP #$1F       ;is the command "Run Monster Script"?
LC2011E:  BNE LC2013E    ;branch if not
LC20120:  JSR $0301      ;Remove current first record from entity's conventional
                         ;linked list queue, and update their entry point
                         ;accordingly
LC20123:  LDA $3A97
LC20126:  BNE LC20134    ;branch if in the Colosseum
LC20128:  LDA $3395,X
LC2012B:  BPL LC20134    ;branch if the monster is Charmed
LC2012D:  LDA $3EE5,X
LC20130:  BIT #$30
LC20132:  BEQ LC20139    ;Branch if not Berserk or Muddled
LC20134:  JSR $0634      ;Picks random command for monsters
LC20137:  BRA LC20100    ;go load next record in entity's conventional linked
                         ;list queue
LC20139:  JSR $02DC      ;Run Monster Script, main portion
LC2013C:  BRA LC20100    ;go load next record in said queue
LC2013E:  CMP #$16       ;is the command Jump?
LC20140:  BNE LC2014E    ;branch if not
LC20142:  REP #$20       ;Set 16-bit Accumulator
LC20144:  LDA $3018,X
LC20147:  TRB $3F2C      ;clear the entity's "Jumping" flag
LC2014A:  BEQ LC200E4    ;if it hadn't been set, we're currently initiating a
                         ;jump rather than landing from one, so go set the
                         ;flag and do some other preparation.
LC2014C:  SEP #$20
LC2014E:  LDA $32CC,X    ;get entry point to queue
LC20151:  TAY
LC20152:  LDA $3184,Y    ;get the pointer/ID of record stored at that entry point
LC20155:  CMP $32CC,X    ;do the contents of that field match the position of
                         ;the record?  that is, it's a standalone record or the
                         ;last record in the linked list.
LC20158:  BNE LC2016D    ;branch if that's not the case.  the main goal seems to
                         ;be skipping code for non-final Gem Box attacks.
LC2015A:  LDA #$80
LC2015C:  TRB $B1
LC2015E:  LDA #$FF
LC20160:  CPX $3404      ;Is this target under the influence of Quick?
LC20163:  BNE LC2016D    ;Branch if not
LC20165:  DEC $3402      ;Decrement the number of turns due to Quick
LC20168:  BNE LC2016D    ;Branch if this was not the last Quick turn
LC2016A:  STA $3404      ;If it was, store an #$FF (empty) in Quick's target byte
LC2016D:  XBA
LC2016E:  LDA $3AA0,X
LC20171:  BIT #$50
LC20173:  BEQ LC2017A    ;branch if bits 4 and 6 both unset
LC20175:  LDA #$80
LC20177:  JMP $5BAB      ;set bit 7 of $3AA1,X
LC2017A:  LDA #$FF
LC2017C:  STA $3184,Y    ;null current first record in entity's conventional
                         ;linked list queue
LC2017F:  XBA
LC20180:  STA $32CC,X    ;either make entry point index next record, or null it
LC20183:  LDA $3AA0,X
LC20186:  AND #$D7
LC20188:  ORA #$40
LC2018A:  STA $3AA0,X    ;turn off bits 3 and 5.  turn on bit 6.
LC2018D:  LSR
LC2018E:  BCC LC201A6    ;branch if entity not present in battle
LC20190:  LDA $3204,X
LC20193:  ORA #$04
LC20195:  STA $3204,X
LC20198:  LDA $3205,X
LC2019B:  ORA #$80
LC2019D:  STA $3205,X    ;indicate entity has taken a conventional turn
                         ;[including landing one] since boarding Palidor
LC201A0:  JSR $13D3      ;Character/Monster Takes One Turn
LC201A3:  JSR $021E      ;Save this command's info in Mimic variables so Gogo
                         ;will be able to Mimic it if he/she tries.
LC201A6:  LDA #$A0
LC201A8:  TSB $B0        ;indicate entity has executed conventional turn since
;                                     LC20073 was last reached, and indicate we're in middle
                         ;of processing a conventional linked list queue
LC201AA:  LDA #$10
LC201AC:  TRB $3A46      ;clear "Palidor was summoned this turn" flag
LC201AF:  BNE LC201B7    ;branch if it had been set
LC201B1:  LDA $32CC,X    ;get entry point to entity's conventional linked list
                         ;queue
LC201B4:  INC
LC201B5:  BNE LC201D5    ;branch if it's valid
LC201B7:  LDA $3AA0,X
LC201BA:  BIT #$08
LC201BC:  BNE LC201C6
LC201BE:  INC $3219,X
LC201C1:  BNE LC201C6
LC201C3:  DEC $3219,X    ;increment top byte of ATB counter if not 255
LC201C6:  LDA #$FF
LC201C8:  STA $322C,X
LC201CB:  STZ $3AB5,X    ;zero top byte of Wait Timer
LC201CE:  LDA #$80
LC201D0:  TRB $B0        ;we're not in middle of processing a conventional
                         ;linked list queue
LC201D2:  JMP $0267
LC201D5:  STX $3406      ;leave off processing entity in X
LC201D8:  RTS


;Replace queued command, attack, and targets with contents of Mimic variables.
; And if mimicking X-Magic, add queue entry for second spell.)

LC201D9:  LDA $3F28      ;16h if last character command was Jump,
                         ;12h if it's a different command
LC201DC:  CMP #$16
LC201DE:  BNE LC201F1    ;branch if not Jump
LC201E0:  REP #$20
LC201E2:  LDA $3F28      ;Last command and attack [Jump and 00h]
LC201E5:  STA $3420,Y    ;update command and attack in entity's conventional
                         ;linked list queue
LC201E8:  LDA $3F2A      ;Last targets
LC201EB:  STA $3520,Y    ;update targets in entity's conventional linked
                         ;list queue
LC201EE:  SEP #$20
LC201F0:  RTS

LC201F1:  REP #$20
LC201F3:  LDA $3F20      ;Last command and attack
LC201F6:  STA $3420,Y    ;update command and attack in entity's conventional
                         ;linked list queue
LC201F9:  LDA $3F22      ;Last targets
LC201FC:  STA $3520,Y    ;update targets in entity's conventional linked
                         ;list queue
LC201FF:  SEP #$20
LC20201:  LDA $3F24      ;Last command and attack (second attack w/ Gem Box)
LC20204:  CMP #$12
LC20206:  BEQ LC201D8    ;exit if there was none
LC20208:  REP #$20
LC2020A:  LDA $3F24      ;Last command and attack (second attack w/ Gem Box)
LC2020D:  STA $3A7A
LC20210:  LDA $3F26      ;Last targets (second attack w/ Gem Box)
LC20213:  STA $B8
LC20215:  SEP #$20
LC20217:  LDA #$40
LC20219:  TSB $B1        ;stops Function C2/4F08 from deducting MP cost for second
                         ;Gem Box spell.  no precaution needed for first, as the
                         ;function is run with a command of 12h [Mimic] then.
LC2021B:  JMP $4ECB      ;queue the second X-Magic spell, in entity's
                         ;conventional queue


;Save this command's info in Mimic variables so Gogo will be able to
; Mimic it if he/she tries.)

LC2021E:  PHX
LC2021F:  PHP
LC20220:  CPX #$08
LC20222:  BCS LC20264    ;exit if it's a monster taking this turn
LC20224:  LDA $3A7C      ;get original command of just-executed turn
LC20227:  CMP #$1E
LC20229:  BCS LC20264    ;exit if not a normal character command.  iow,
                         ;if it was enemy Roulette, "Run Monster Script",
                         ;periodic damage/healing, etc.
LC2022B:  ASL
LC2022C:  TAX
LC2022D:  LDA $CFFE00,X  ;get command data
LC20231:  BIT #$02
LC20233:  BEQ LC20264    ;exit if this command can't be Mimicked.  such
                         ;commands are Morph, Revert, Control, Leap, Row,
                         ;Defense, Jump, and Possess.
                         ;But Jump can be mimicked!, you say.  true, but
                         ;unlike other commands, which become mimicable
                         ;after they're executed, this one becomes fair
                         ;game after the character enters their ready stance
                         ;[i.e. when they leap].  that way, Gogo doesn't have
                         ;to wait til a Jumper lands to copy them.  this
                         ;special case is handled in C2/2188, so we don't want
                         ;Jump among the Mimicable commands in $CFFE00
LC20235:  LDA #$12
LC20237:  STA $3F28      ;indicate to Mimic that the command is something
                         ;other than Jump?
LC2023A:  LDA $3A7C      ;get original command of just-executed turn
LC2023D:  CMP #$17
LC2023F:  BEQ LC20256    ;branch if command was X-Magic.  it seems the first turn
                         ;of a Gem Box sequence has Magic in the command ID, and
                         ;the second turn has X-Magic.
LC20241:  LDA #$12
LC20243:  STA $3F24      ;Last command and attack (second attack w/ Gem Box
                         ;(for use by Mimic.  in other words, default to indicating
                         ;there was no 2nd Gem Box attack.
LC20246:  REP #$20
LC20248:  LDA $3A7C      ;get original command of just-executed turn
LC2024B:  STA $3F20      ;Last command and attack (for use by Mimic)
LC2024E:  LDA $3A30      ;get backup targets from just-executed turn
LC20251:  STA $3F22      ;Last targets (for use by Mimic)
LC20254:  BRA LC20264
LC20256:  REP #$20
LC20258:  LDA $3A7C      ;get original command of just-executed turn
LC2025B:  STA $3F24      ;Last command and attack (second attack w/ Gem Box
                         ;(for use by Mimic)
LC2025E:  LDA $3A30      ;get backup targets from just-executed turn
LC20261:  STA $3F26      ;Last targets (second attack w/ Gem Box) (for use by Mimic)
LC20264:  PLP
LC20265:  PLX
LC20266:  RTS


LC20267:  LDA #$0D
LC20269:  STA $2D6E      ;first byte of first entry of ($76) buffer
LC2026C:  LDA #$FF
LC2026E:  STA $2D72      ;first byte of second entry of ($76) buffer
LC20271:  LDA #$04
LC20273:  JMP $6411      ;Execute animation queue


;Load command, attack, targets, and MP cost from queued data.  If attacker Imped and
; command not supported while Imped, turn into Fight.)

LC20276:  PHP
LC20277:  REP #$20       ;Set 16-bit Accumulator
LC20279:  LDA $3520,Y    ;get targets from a linked list queue [one of three
                         ;queue types, depending on caller]
LC2027C:  STA $B8        ;save as targets
LC2027E:  LDA $3420,Y    ;get command and attack from same linked list queue
LC20281:  STA $3A7C      ;save as original command
LC20284:  STA $B5        ;save as command
LC20286:  PLP
LC20287:  PHA            ;Put on stack
LC20288:  BCC LC2029A    ;branch if not a conventional turn
LC2028A:  CMP #$1D
LC2028C:  BCS LC2029A    ;Branch if command is MagiTek or a non-character
                         ;command?
LC2028E:  LDA $3018,X
LC20291:  TRB $3A4A      ;clear "Entity's Zombie or Muddled changed since
                         ;last command or ready stance entering"
LC20294:  BEQ LC2029A    ;branch if it was already clear
LC20296:  STZ $B8
LC20298:  STZ $B9        ;clear attack's targets
LC2029A:  LDA $3620,Y    ;get MP cost from a linked list queue [one of three
                         ;queue types, depending on caller]
LC2029D:  STA $3A4C      ;save actual MP cost to caster
LC202A0:  LDA $3EE4,X
LC202A3:  BIT #$20       ;Check for Imp Status
LC202A5:  BEQ LC202DA    ;Branch if not imp
LC202A7:  LDA $B5        ;get command
LC202A9:  CMP #$1E
LC202AB:  BCS LC202DA    ;branch if not character command
LC202AD:  PHX
LC202AE:  ASL
LC202AF:  TAX
LC202B0:  LDA $CFFE00,X  ;get command data

;Bit 2 set for Fight, Item, Magic, Revert,
; Mimic, Row, Def., Jump, X-Magic,
; Health, Shock)

;0F, 07, 07, 00, 04, 0B, 0B, 03
; 03, 03, 03, 03, 03, 03, 01, 03
; 0B, 00, 05, 03, 04, 04, 05, 07
; 03, 03, 06, 06, 01, 0A, 00, 00 )

LC202B4:  PLX
LC202B5:  BIT #$04
LC202B7:  BNE LC202DA    ;branch if command is supported while Imped
LC202B9:  STZ $3A4C      ;zero actual MP cost to caster
LC202BC:  PHX
LC202BD:  TDC            ;clear 16-bit A
LC202BE:  CPX #$08       ;set Carry if monster attacker
LC202C0:  ROL
LC202C1:  TAX            ;move Carry into X
LC202C2:  LDA $B8,X      ;get targets from $B8 or $B9
LC202C4:  AND $3A40,X    ;characters acting as enemies.  i believe $3A41
                         ;will always be zero.
LC202C7:  STA $B8,X      ;remove all targets who weren't members of opposition
LC202C9:  REP #$20
LC202CB:  STZ $3A7C
LC202CE:  STZ $B5        ;zero out command, making it Fight
LC202D0:  LDA $B8        ;get all targets of attack
LC202D2:  JSR $522A      ;pick one at random
LC202D5:  STA $B8
LC202D7:  SEP #$20
LC202D9:  PLX
LC202DA:  PLA
LC202DB:  RTS


;Run Monster Script [Command 1Fh], main portion, and handle bookmarking

LC202DC:  REP #$20
LC202DE:  STZ $3A98      ;don't prohibit any script commands for upcoming call
LC202E1:  LDA $3254,X    ;offset of monster's main script
LC202E4:  STA $F0        ;upcoming $1A2F call will start at this position
LC202E6:  LDA $3D0C,X    ;main script position after last executed FD command.
                         ;iow, where we left off.  applicable when $3240,X =/=
                         ;FFh.
LC202E9:  STA $F2
LC202EB:  LDA $3240,X    ;index of sub-block in main script where we left off
                         ;if we exited script due to FD command, null FFh
                         ;otherwise.
LC202EE:  STA $F4
LC202F0:  CLC
LC202F1:  JSR $1A2F      ;Process monster's main script, backing up targets first
LC202F4:  LDA $F2
LC202F6:  STA $3D0C,X    ;save main script position after last executed FD
                         ;command.  iow, where we're leaving off.
LC202F9:  SEP #$20
LC202FB:  LDA $F5
LC202FD:  STA $3240,X    ;if we exited script due to FD command, save sub-block
                         ;index of main script where we left off.  if we exited
                         ;due to executing FE command or executing/reaching
                         ;FF command, save null FFh.
LC20300:  RTS


;Remove current first record from entity's conventional linked list queue, and update
;their entry point accordingly  (operates on different list if called from C2/4C54)

LC20301:  LDA $32CC,X    ;get entry point to entity's [conventional or other]
                         ;linked list queue
LC20304:  BMI LC2031B    ;exit if null [list is empty]
LC20306:  PHY
LC20307:  TAY
LC20308:  LDA $3184,Y    ;read pointer/ID of current first record in entity's
                         ;[conventional or other] linked list queue
LC2030B:  CMP $32CC,X    ;if field's contents match record's position, it's a
                         ;standalone record, or the last in the list
LC2030E:  BNE LC20312    ;branch if not, as there are more records left
LC20310:  LDA #$FF
LC20312:  STA $32CC,X    ;either make entry point index next record, or null it
LC20315:  LDA #$FF
LC20317:  STA $3184,Y    ;null current first record in entity's [conventional
                         ;or other] linked list queue
LC2031A:  PLY
LC2031B:  RTS


LC2031C:  STZ $B8
LC2031E:  STZ $B9
LC20320:  INC $322C,X
LC20323:  BEQ LC20328
LC20325:  DEC $322C,X    ;if Time to Wait is FFh, set it to 0
LC20328:  JSR $0A41      ;clear Defending flag
LC2032B:  LDA $3E4C,X
LC2032E:  AND #$FA
LC20330:  STA $3E4C,X    ;Clear Retort and Runic
LC20333:  CPX #$08
LC20335:  BCC LC20344    ;branch if character
LC20337:  LDA $32CC,X    ;get entry point to entity's conventional linked list
                         ;queue
LC2033A:  BPL LC20357    ;branch if valid
LC2033C:  LDA #$1F
LC2033E:  STA $3A7A      ;set command to "Run Monster Script"
LC20341:  JMP $4ECB      ;queue it, in entity's conventional queue


LC20344:  LDA $3018,X
LC20347:  TRB $3A4A      ;clear "Entity's Zombie or Muddled changed since
                         ;last command or ready stance entering"
LC2034A:  LDA $3255,X    ;top byte of offset of main script
LC2034D:  BMI LC20352    ;branch if character has no main script
LC2034F:  JMP $02DC      ;Run Monster Script, main portion


LC20352:  LDA $32CC,X    ;get entry point to entity's conventional linked list
                         ;queue
LC20355:  BMI LC2037B    ;branch if null
LC20357:  PHA            ;Put on stack
LC20358:  ASL
LC20359:  TAY            ;adjust index for 16-bit fields
LC2035A:  REP #$20
LC2035C:  LDA $3520,Y    ;get targets from entity's conventional linked list
                         ;queue
LC2035F:  STA $B8        ;save as targets
LC20361:  LDA $3420,Y    ;get command and attack from entity's conventional
                         ;linked list queue
LC20364:  JSR $03E4      ;Determine command's "time to wait", recalculate
                         ;targets if there aren't any
LC20367:  LDA $B8        ;get targets, possibly modified if there weren't any
                         ;before function call
LC20369:  STA $3520,Y    ;save in entity's conventional linked list queue
LC2036C:  SEP #$20
LC2036E:  PLA
LC2036F:  TAY            ;adjust index for 8-bit field
LC20370:  CMP $3184,Y    ;does pointer/ID of this record in conventional linked
                         ;list queue match its position?
LC20373:  BEQ LC2037A    ;if so, it's a standalone record or the last record
                         ;in the list, so exit
LC20375:  LDA $3184,Y    ;otherwise, it should point to another record, so...
LC20378:  BRA LC20357    ;...loop and check that one.
LC2037A:  RTS


LC2037B:  LDA $3EF8,X
LC2037E:  LSR
LC2037F:  BCS LC203D7    ;Branch if Dance status
LC20381:  LDA $3EF9,X
LC20384:  LSR
LC20385:  BCS LC203CE    ;Branch if Rage status
LC20387:  LDA $3EE4,X
LC2038A:  BIT #$08
LC2038C:  BNE LC203C6    ;Branch if M-Tek status
LC2038E:  JSR $0420      ;pick action to take if character Berserked,
                         ;Zombied, Muddled, Charmed, or in the Colosseum
LC20391:  CMP #$17
LC20393:  BNE LC203B0    ;Branch if chosen command not X-Magic
LC20395:  PHA            ;save command on stack
LC20396:  XBA
LC20397:  PHA            ;Put on stack
LC20398:  PHA            ;save attack/spell on stack twice
LC20399:  TXY
LC2039A:  JSR $051A      ;Pick another spell
LC2039D:  STA $01,S      ;replace latter stack copy with that spell
LC2039F:  PLA
LC203A0:  XBA
LC203A1:  LDA #$02       ;ID of Magic command
LC203A3:  JSR $03E4      ;Determine command's "time to wait", recalculate
                         ;targets if there aren't any
LC203A6:  JSR $4ECB      ;queue that spell under Magic command, in entity's
                         ;conventional queue
LC203A9:  STZ $B8
LC203AB:  STZ $B9        ;clear any targets set by above C2/03E4 call, so
                         ;next one can choose its own
LC203AD:  PLA            ;retrieve initial attack/spell from stack
LC203AE:  XBA
LC203AF:  PLA            ;retrieve initial command from stack
LC203B0:  JSR $03B9      ;Swap Roulette to Enemy Roulette
LC203B3:  JSR $03E4      ;Determine command's "time to wait", recalculate
                         ;targets if there aren't any
LC203B6:  JMP $4ECB      ;queue earlier-chosen spell under X-Magic command,
                         ;in entity's conventional queue


;Swap Roulette to Enemy Roulette

LC203B9:  PHP
LC203BA:  REP #$20
LC203BC:  CMP #$8C0C     ;is the command Lore and the attack Roulette?
LC203BF:  BNE LC203C4    ;branch if not
LC203C1:  LDA #$8C1E     ;set command to Enemy Roulette, keep attack as
                         ;Roulette
LC203C4:  PLP
LC203C5:  RTS


LC203C6:  JSR $0584      ;randomly pick a Magitek attack
LC203C9:  XBA
LC203CA:  LDA #$1D       ;Magitek command ID
LC203CC:  BRA LC203DE


LC203CE:  TXY
LC203CF:  JSR $05D1      ;Picks a Rage [when Muddled/Berserked/etc], and picks
                         ;the Rage move
LC203D2:  XBA
LC203D3:  LDA #$10       ;Rage command ID
LC203D5:  BRA LC203DE


LC203D7:  TXY
LC203D8:  JSR $059C      ;picks a Dance and a dance move
LC203DB:  XBA
LC203DC:  LDA #$13       ;Dance command ID
LC203DE:  JSR $03E4      ;Determine command's "time to wait", recalculate
                         ;targets if there aren't any
LC203E1:  JMP $4ECB      ;queue chosen Dance move, in entity's conventional
                         ;queue


;Determine command's "time to wait" [e.g. for character's ready stance], recalculate
; targets if there aren't any)

LC203E4:  PHP
LC203E5:  SEP #$30       ;Set 8-bit A, X, & Y
LC203E7:  STA $3A7A      ;save command in temporary variable
LC203EA:  XBA
LC203EB:  STA $3A7B      ;save attack in temporary variable
LC203EE:  XBA
LC203EF:  CMP #$1E
LC203F1:  BCS LC2041E    ;branch if command is 1Eh or above.. i.e. it's
                         ;enemy Roulette or "Run Monster Script"
LC203F3:  PHA            ;Put on stack
LC203F4:  PHX
LC203F5:  TAX
LC203F6:  LDA $C2067B,X  ;get command's "time to wait"
LC203FA:  PLX
LC203FB:  CLC
LC203FC:  ADC $322C,X    ;add it to character's existing "time to wait"
LC203FF:  BCS LC20404
LC20401:  INC
LC20402:  BNE LC20406
LC20404:  LDA #$FF
LC20406:  DEC            ;if sum overflowed or equalled FFh, set it to FEh.
                         ;otherwise, keep it.
LC20407:  STA $322C,X    ;update time to wait
LC2040A:  PLA
LC2040B:  JSR $26D3      ;Load data for command and attack/sub-command, held
                         ;in A.bottom and A.top
LC2040E:  LDA #$04
LC20410:  TRB $BA        ;Clear "Don't retarget if target invalid"
LC20412:  REP #$20
LC20414:  LDA $B8
LC20416:  BNE LC2041E    ;branch if there are already targets
LC20418:  STZ $3A4E      ;clear backup already-hit targets
LC2041B:  JSR $587E      ;targeting function
LC2041E:  PLP
LC2041F:  RTS


;Pick action to take if character Berserked, Zombied, Muddled, Charmed, or in the Colosseum

LC20420:  TXA
LC20421:  XBA
LC20422:  LDA #$06
LC20424:  JSR $4781      ;X * 6
LC20427:  TAY
LC20428:  STZ $FE        ;save Fight as Command 5
LC2042A:  STZ $FF
LC2042C:  LDA $202E,Y    ;get Command 1
LC2042F:  STA $F6
LC20431:  LDA $2031,Y    ;get Command 2
LC20434:  STA $F8
LC20436:  LDA $2034,Y    ;get Command 3
LC20439:  STA $FA
LC2043B:  LDA $2037,Y    ;get Command 4
LC2043E:  STA $FC
LC20440:  LDA #$05       ;indicate 5 valid commands to choose from..
                         ;this number may drop.
LC20442:  STA $F5

LC20444:  LDA $3EE5,X    ;Status byte 2
LC20447:  ASL
LC20448:  ASL
LC20449:  STA $F4        ;Bit 7 = Muddled, Bit 6 = Berserk, etc
LC2044B:  ASL
LC2044C:  BPL LC20452    ;Branch if no Berserk status
LC2044E:  STZ $F4        ;Clear $F4, then skip Charm and Colosseum checks
                         ;if Berserked
LC20450:  BRA LC2045E
LC20452:  LDA $3395,X    ;Which target Charmed you, FFh if none did
LC20455:  EOR #$80       ;Bit 7 will now be set if there IS a Charmer
LC20457:  TSB $F4
LC20459:  LDA $3A97      ;FFh if Colosseum battle, 00h otherwise
LC2045C:  TSB $F4        ;so set Bit 7 [and others] if in Colosseum

;Note that Berserk status will override Muddle/Charm/Colosseum for purposes of
; determining whether we choose from the C2/04D0 or the C2/04D4 command list.
; In contrast, Zombie will not; Charm/Colosseum/Muddle override it.)

LC2045E:  TXY            ;Y now points to the attacker who is taking this
                         ;turn.  will be used by the $04E2 and $04EC
                         ;functions, since X gets overwritten.

LC2045F:  PHX
LC20460:  LDX #$06       ;start checking 4th command slot
LC20462:  PHX            ;save slot position
LC20463:  LDA $F6,X
LC20465:  PHA            ;save command
LC20466:  BMI LC20482    ;branch if slot empty
LC20468:  CLC            ;clear Carry
LC20469:  JSR $5217      ;X = A DIV 8, A = 2 ^ (A MOD 8)
LC2046C:  AND $C204D0,X  ;is command allowed when Muddled/Charmed/Colosseum?
LC20470:  BEQ LC20482    ;branch if not
LC20472:  LDA $F4
LC20474:  BMI LC20488    ;Branch if Muddled/Charmed/Colosseum but not Berserked
LC20476:  LDA $01,S      ;get command
LC20478:  CLC
LC20479:  JSR $5217      ;X = A DIV 8, A = 2 ^ (A MOD 8)
LC2047C:  AND $C204D4,X  ;is command allowed when Berserked/Zombied?
LC20480:  BNE LC20488    ;branch if so

LC20482:  LDA #$FF
LC20484:  STA $01,S      ;replace command on stack with Empty entry
LC20486:  DEC $F5        ;decrement number of valid commands
LC20488:  TDC            ;clear 16-bit A
LC20489:  LDA $01,S      ;get current command

;NOTE: Like the code above with $C204D0 and $C204D4, this next section makes use
; of pairs of tables.  However, UNLIKE that code, this doesn't seem to treat one
; table differently than the other.  I believe the pairs of tables are just to
; allow two commands to be compared per loop iteration, halving the number of
; iterations and speeding things up a little.  Were you only to compare one
; command per iteration -- simply using offsets $C204D8,X and ($04E2,X) --
; this loop would occupy less space.. hmmm...)

;Loop below sees if our current command is one that requires special code to
; work with Muddle/Charm/Colosseum/Berserk/Zombie.  If it is, a special function
; is called for the command.)

LC2048B:  LDX #$08
LC2048D:  CMP $C204D8,X  ;does our current command match one from table?
LC20491:  BNE LC20499    ;if not, compare it to a second command in this
                         ;loop iteration
LC20493:  JSR ($04E2,X)  ;if it does, call the special code used by
                         ;that command
LC20496:  XBA            ;put attack/spell # in top of A
LC20497:  BRA LC204A9    ;exit loop, as we found our command
LC20499:  CMP $C204D9,X  ;does our current command match one from table?
LC2049D:  BNE LC204A5    ;if not, our current command didn't match either
                         ;compared one.  so move to new pair of commands
                         ;in table, and repeat loop
LC2049F:  JSR ($04EC,X)  ;if it did match, call the special code used
                         ;by that command
LC204A2:  XBA            ;put attack/spell # in top of A
LC204A3:  BRA LC204A9    ;exit loop, as we found our command
LC204A5:  DEX
LC204A6:  DEX
LC204A7:  BPL LC2048D    ;Loop to compare current command to all 10 commands
                         ;that utilize special code.
                         ;If this loop doesn't exit before X becomes negative,
                         ;that means our current command has no special function,
                         ;and the Attack # in the top half of A will be zero.
LC204A9:  PLA            ;get command # from stack
LC204AA:  PLX            ;get command slot from stack
LC204AB:  STA $F6,X      ;save command # in current command slot
LC204AD:  XBA
LC204AE:  STA $F7,X      ;save attack/spell # corresponding to that attack
LC204B0:  DEX
LC204B1:  DEX
LC204B2:  BPL LC20462    ;loop for first 4 command slots

;Fight has been put in the 5th command slot.  Any valid commands, with their
; accompanying attack/spell numbers, have been established for slots 1 thru 4.
; Now we shall randomly pick from those commands.  Each slot should have equal
; probability of being chosen.)

LC204B4:  LDA $F5        ;# of valid command slots
LC204B6:  JSR $4B65      ;RNG: 0 to A - 1 .  we're randomly picking a command
LC204B9:  TAY
LC204BA:  LDX #$08       ;start pointing to Command slot 5
LC204BC:  LDA $F6,X
LC204BE:  BMI LC204C3    ;if that command slot is Empty, move to next one
LC204C0:  DEY            ;only decrement when on a valid command slot
LC204C1:  BMI LC204CA    ;If Y is negative, we've found our Nth valid command
                         ;[starting with the last valid command and counting
                         ;backward], where N is the number returned from the
                         ;RNG plus 1.
                         ;This is what we wanted, so branch.

LC204C3:  DEX
LC204C4:  DEX
LC204C5:  BPL LC204BC    ;loop for all 5 command slots
LC204C7:  TDC            ;clear 16-bit A
LC204C8:  BRA LC204CE    ;clean up stack and exit function.  A is zero,
                         ;indicating Fight, which must be a fallback in case
                         ;all 5 Command slots somehow came up useless.  not
                         ;sure how that'd happen, as Slot #5 should always
                         ;hold Fight anyway...

LC204CA:  XBA
LC204CB:  LDA $F7,X
LC204CD:  XBA            ;bottom of A = command # from $F6,X
                         ;top of A = attack/spell # from $F7,X
LC204CE:  PLX
LC204CF:  RTS


;Data - commands allowed when Muddled/Charmed/Colosseum brawling

LC204D0: db $ED  ;Fight, Magic, Morph, Steal, Capture, SwdTech
LC204D1: db $3E  ;Tools, Blitz, Runic, Lore, Sketch
LC204D2: db $DD  ;Rage, Mimic, Dance, Row, Jump, X-Magic
LC204D3: db $2D  ;GP Rain, Health, Shock, MagiTek

;in other words: Item, Revert, Throw, Control, Slot, Leap, Def., Summon, and Possess
;are excluded)

;Data - commands allowed when Berserked/Zombied

LC204D4: db $41  ;Fight, Capture
LC204D5: db $00  ;none
LC204D6: db $41  ;Rage, Jump
LC204D7: db $20  ;MagiTek


;Commands that need special functions when character acts automatically

LC204D8: db $02   ;Magic
LC204D9: db $17   ;X-Magic
LC204DA: db $07   ;SwdTech
LC204DB: db $0A   ;Blitz
LC204DC: db $10   ;Rage
LC204DD: db $13   ;Dance
LC204DE: db $0C   ;Lore
LC204DF: db $03   ;Morph
LC204E0: db $1D   ;MagiTek
LC204E1: db $09   ;Tools


;Code pointers

LC204E2: dw $051A     ;Magic
LC204E4: dw $0560     ;SwdTech
LC204E6: dw $05D1     ;Rage
LC204E8: dw $04F6     ;Lore
LC204EA: dw $0584     ;MagiTek

LC204EC: dw $051A     ;X-Magic
LC204EE: dw $0575     ;Blitz
LC204F0: dw $059C     ;Dance
LC204F2: dw $0557     ;Morph
LC204F4: dw $058D     ;Tools


;Lore
LC204F6:  LDA $3EE5,Y    ;Status Byte 2
LC204F9:  BIT #$08
LC204FB:  BNE LC2054F    ;Branch if Mute
LC204FD:  LDA $3A87      ;Number of Lores possessed
LC20500:  BEQ LC2054F    ;if there's zero, don't use Lore command
LC20502:  PHA            ;Put on stack
LC20503:  REP #$21       ;Set 16-bit A, Clear Carry
LC20505:  LDA $302C,Y    ;starting address of Magic menu [actually address
                         ;of Esper menu]
LC20508:  ADC #$00D8     ;add 54 spells * 4 to get to next menu, which is
                         ;Lore [loop at C2/0534 won't use the 0 index, which
                         ;is why it won't wrongly select the last Magic spell]
LC2050B:  STA $EE
LC2050D:  SEP #$20       ;Set 8-bit Accumulator
LC2050F:  PLA
LC20510:  XBA            ;put # of Lores possessed in top of A
LC20511:  LDA #$60       ;there are 24 Lores, and each menu slot must occupy
                         ;4 bytes, so set loop limit to 96
LC20513:  JSR $0534      ;randomly pick a valid Lore menu slot
LC20516:  CLC
LC20517:  ADC #$8B       ;first Lore is #139, Condemned
LC20519:  RTS


;Magic and X-Magic
LC2051A:  LDA $3EE5,Y    ;Status Byte 2
LC2051D:  BIT #$08
LC2051F:  BNE LC2054F    ;Branch if Mute
LC20521:  LDA $3CF8,Y    ;Number of spells possessed by this character
LC20524:  BEQ LC2054F    ;if there's zero, don't use Magic/X-Magic command
LC20526:  PHA            ;Put on stack
LC20527:  REP #$20       ;Set 16-bit Accumulator
LC20529:  LDA $302C,Y    ;starting address of Magic menu [actually address of
                         ;Esper menu, but loop at C2/0534 won't use the 0 index]
LC2052C:  STA $EE
LC2052E:  SEP #$20       ;Set 8-bit Accumulator
LC20530:  PLA
LC20531:  XBA            ;put # of spells possessed in top of A
LC20532:  LDA #$D8       ;there are 54 spells, and each menu slot must occupy
                         ;4 bytes, so set loop limit to 216
LC20534:  PHX
LC20535:  PHY
LC20536:  TAY
LC20537:  XBA            ;retrieve number of spells/Lores possessed
LC20538:  JSR $4B65      ;RNG: 0 to A - 1 . we're randomly picking a
                         ;spell/lore
LC2053B:  TAX
LC2053C:  LDA ($EE),Y    ;get what's in this Magic/Lore menu slot
LC2053E:  CMP #$FF       ;is it null?
LC20540:  BEQ LC20545    ;if so, skip to next slot
LC20542:  DEX
LC20543:  BMI LC2054C    ;If X becomes negative, that means we've found the
                         ;Nth valid slot [starting with the last valid slot
                         ;and counting backward], where N is the X returned
                         ;from our RNG plus 1.
                         ;This is what we wanted, so branch.
LC20545:  DEY
LC20546:  DEY
LC20547:  DEY
LC20548:  DEY
LC20549:  BNE LC2053C    ;loop and check next slot
LC2054B:  TDC            ;if we didn't get any matches, just use Fire
                         ;[or Condemned for Lore, since 139 gets added]
LC2054C:  PLY
LC2054D:  PLX
LC2054E:  RTS


;Randomly chosen command failed, for whatever reason
LC2054F:  DEC $F5        ;decrement # of valid command slots
LC20551:  LDA #$FF
LC20553:  STA $03,S      ;store Empty in current command slot, indicating
                         ;that it cannot be chosen
LC20555:  TDC            ;clear 16-bit A.  note that only the bottom 8-bits,
                         ;which indicate the attack/spell #, matter..
                         ;the command # is loaded by the stack retrieval at
;                                     LC204A9, and will obviously be FFh in this case.)
LC20556:  RTS


;Morph
LC20557:  LDA #$0F
LC20559:  CMP $1CF6      ;Morph supply
LC2055C:  TDC            ;clear 16-bit A
LC2055D:  BCS LC2054F    ;if Morph supply isn't at least 16, don't allow
                         ;Morph command
LC2055F:  RTS


;SwdTech
LC20560:  LDA $3BA4,Y    ;Special properties for right-hand weapon slot
LC20563:  ORA $3BA5,Y    ;'' for left-hand
LC20566:  BIT #$02       ;is Swdtech allowed by at least one hand?
LC20568:  BEQ LC2054F    ;if not, don't use Swdtech as command
LC2056A:  LDA $2020      ;index of highest known Swdtech
LC2056D:  INC            ;# of known Swdtechs
LC2056E:  JSR $4B65      ;random #: 0 to A-1.  Pick a known Swdtech.
LC20571:  CLC
LC20572:  ADC #$55       ;first Swdtech is #85, Dispatch
LC20574:  RTS


;Blitz
LC20575:  TDC
LC20576:  LDA $1D28      ;Known Blitzes
LC20579:  JSR $522A      ;Pick a random bit that is set
LC2057C:  JSR $51F0      ;Get which bit is picked
LC2057F:  TXA
LC20580:  CLC
LC20581:  ADC #$5D       ;first Blitz is #93, Pummel
LC20583:  RTS


;MagiTek
LC20584:  LDA #$03
LC20586:  JSR $4B65      ;0 to 2 -- only pick between first 3 MagiTek moves,
                         ;since anybody besides Terra can only use
                         ;Fire Beam + Bolt Beam + Ice Beam + Heal Force,
                         ;but there's Bio Blast in between those last two.

                         ;just picking from the first three simplifies code,
                         ;although decent planning would have had Heal Force
                         ;before Bio Blast..  or add a few instructions here
                         ;and include Heal Force anyway.
LC20589:  CLC
LC2058A:  ADC #$83       ;first MagiTek move is #131, Fire Beam
LC2058C:  RTS


;Tools
LC2058D:  TDC
LC2058E:  LDA $3A9B      ;Which tools are owned
LC20591:  JSR $522A      ;Pick a random tool that is owned
LC20594:  JSR $51F0      ;Get which bit is set, thus returning a 0-7
                         ;Tool index
LC20597:  TXA
LC20598:  CLC
LC20599:  ADC #$A3       ;item number of first tool, NoiseBlaster, is 163
LC2059B:  RTS


;Picks dance, and dance move

LC2059C:  PHX
LC2059D:  LDA $32E1,Y    ;get the dance number
LC205A0:  CMP #$FF       ;is it null?
LC205A2:  BNE LC205B2    ;if it's valid, a Dance has already been chosen,
                         ;so just proceed to choose a step
LC205A4:  TDC            ;clear 16-bit A
LC205A5:  LDA $1D4C      ;bitfield of known Dances
LC205A8:  JSR $522A      ;Pick a random bit that is set
LC205AB:  JSR $51F0      ;X = Get which bit is picked
LC205AE:  TXA
LC205AF:  STA $32E1,Y    ;save our Dance #
LC205B2:  ASL
LC205B3:  ASL            ;* 4
LC205B4:  STA $EE        ;Each Dance has 4 steps, and occupies 4 bytes
                         ;in the Dance Step --> Attack Number table
                         ;at $CFFE80
LC205B6:  JSR $4B5A      ;RNG: 0 to 255
LC205B9:  LDX #$02
LC205BB:  CMP $C205CE,X  ;see data below for chances of each step
LC205BF:  BCS LC205C3
LC205C1:  INC $EE        ;move to next step for this Dance
LC205C3:  DEX
LC205C4:  BPL LC205BB    ;loop until we reach step determined by random #
LC205C6:  LDX $EE        ;= (Dance * 4) + step
LC205C8:  LDA $CFFE80,X  ;get attack # for the Dance step used
LC205CC:  PLX
LC205CD:  RTS


;Data - for chances of each dance step
;Probabilities: Dance Step 0 = 7/16, Step 1 = 6/16, Step 2 = 2/16, Step 3 = 1/16)

LC205CE: db $10
LC205CF: db $30
LC205D0: db $90


;Picks a Rage [when Muddled/Berserked/etc], and picks the Rage move

LC205D1:  PHX
LC205D2:  PHP
LC205D3:  TDC
LC205D4:  STA $33A9,Y
LC205D7:  LDA $33A8,Y    ;which monster it is
LC205DA:  CMP #$FF
LC205DC:  BNE LC20600    ;branch if a non-null monster was passed
LC205DE:  INC
LC205DF:  STA $33A8,Y    ;store enemy #0, Guard
LC205E2:  LDA $3A9A      ;# of rages possessed
LC205E5:  JSR $4B65
LC205E8:  INC            ;random #: 1 to $3A9A
LC205E9:  STA $EE
LC205EB:  LDX #$00
LC205ED:  LDA $257E,X    ;Rage menu.  was filled in C2/580C routine.
LC205F0:  CMP #$FF
LC205F2:  BEQ LC20600    ;branch if that menu slot was null, which means
                         ;enemy #0 should be defaulted to
LC205F4:  DEC $EE        ;decrement our random index
LC205F6:  BEQ LC205FD    ;if it's zero, branch, and use the menu item last read
LC205F8:  INX
LC205F9:  BNE LC205ED    ;loop again to check next menu entry
LC205FB:  BRA LC20600    ;if we've looped a full 256 times and somehow there's
                         ;been no match with the random index, branch and just
                         ;use enemy #0

;i'm not sure what the purpose of the above loop is..  it selects Enemy #0
; if any menu slots up to and including the randomly chosen one hold FFh.  maybe it's a check
; to see if the list got "broken," as a normally generated one should never have any nulls
; in the middle.)

LC205FD:  STA $33A8,Y    ;store enemy number
LC20600:  JSR $4B53      ;random: 0 or 1 in Carry flag
LC20603:  REP #$30
LC20605:  ROL
LC20606:  TAX            ;X: 0 or 1
LC20607:  SEP #$20       ;Set 8-bit Accumulator
LC20609:  LDA $CF4600,X  ;load Rage move
LC2060D:  PLP
LC2060E:  PLX
LC2060F:  RTS


;Load monster Battle and Special graphics, its special attack, and
; elemental/status/special properties)

LC20610:  PHP
LC20611:  LDA $33A8,Y    ;Which monster it is
LC20614:  TAX
LC20615:  XBA
LC20616:  LDA $CF37C0,X  ;get enemy Special move graphic
LC2061A:  STA $3C81,Y
LC2061D:  LDA #$20
LC2061F:  JSR $4781      ;get monster # * 32 to access the monster
                         ;data block
LC20622:  REP #$10
LC20624:  TAX
LC20625:  LDA $CF001A,X  ;monster's regular weapon graphic
LC20629:  STA $3CA8,Y
LC2062C:  STA $3CA9,Y
LC2062F:  JSR $2DC1      ;load monster's special attack, elemental properties,
                         ;statuses, status immunities, special properties like
                         ;Human/Undead/Dies at MP=0 , etc
LC20632:  PLP
LC20633:  RTS


;Picks command for Muddled/Charmed/Berserk/Colosseum monsters

LC20634:  PHX
LC20635:  REP #$30       ;Set 16-bit A, X, & Y
LC20637:  LDA $1FF9,X    ;Which monster it is
LC2063A:  ASL
LC2063B:  ASL
LC2063C:  TAX            ;multiply monster # by 4 to index its
                         ;Control/Muddled/Charm/Colosseum attack table
LC2063D:  LDA $CF3D00,X  ;Muddled commands 1 and 2
LC20641:  STA $F0
LC20643:  LDA $CF3D02,X  ;Muddled commands 3 and 4
LC20647:  STA $F2
LC20649:  SEP #$30       ;Set 8-bit A, X, & Y
LC2064B:  STZ $EE
LC2064D:  JSR $4B5A      ;random: 0 to 255
LC20650:  AND #$03       ;0 to 3 - point to a random attack slot
LC20652:  TAX
LC20653:  LDA $F0,X
LC20655:  CMP #$FF
LC20657:  BNE LC20664    ;branch if valid attack in slot
LC20659:  DEX
LC2065A:  BPL LC20653    ;loop through remainder of attack slots
LC2065C:  INC $EE        ;if we couldn't find any valid attacks,
                         ;increment counter
LC2065E:  BEQ LC20664    ;give up if we've incremented it 256 times?
                         ;i can't see why more than 1 time would be
                         ;necessary..  if we give up, it appears
                         ;FFh is retained as the attack #, which
                         ;should make the monster do nothing..
                         ;it would've been far faster to change C2/064B
                         ;to "LDA #$FF / STA $EE" and this BEQ to a BNE.
LC20660:  LDX #$03       ;if randomly chosen attack slot and all the
                         ;ones below it were Empty, go do the loop again,
                         ;this time starting with the highest
                         ;numbered slot.  this way, we'll check EVERY
                         ;slot before throwing in the towel.
LC20662:  BRA LC20653
LC20664:  PLX
LC20665:  PHA            ;Put on stack
LC20666:  LDA $3EE5,X
LC20669:  BIT #$10
LC2066B:  BEQ LC20671    ;Branch if not Berserk
LC2066D:  LDA #$EE
LC2066F:  STA $01,S      ;Set attack to Battle
LC20671:  PLA
LC20672:  JSR $1DBF      ;choose a command based on attack #
LC20675:  JSR $03E4      ;Determine command's "time to wait", recalculate
                         ;targets if there aren't any
LC20678:  JMP $4ECB      ;queue chosen command and attack, in entity's
                         ;conventional queue


;Data - Time to wait after entering a command until character actually
;performs it (iow, how long they spend in their ready stance).  This
;value * 256 is compared to their $3AB4 counter.  I'm really not sure
;how this applies to enemies.

LC2067B: db $10   ;Fight
LC2067C: db $10   ;Item
LC2067D: db $20   ;Magic
LC2067E: db $00   ;Morph
LC2067F: db $00   ;Revert
LC20680: db $10   ;Steal
LC20681: db $10   ;Capture
LC20682: db $10   ;SwdTech
LC20683: db $10   ;Throw
LC20684: db $10   ;Tools
LC20685: db $10   ;Blitz
LC20686: db $10   ;Runic
LC20687: db $20   ;Lore
LC20688: db $10   ;Sketch
LC20689: db $10   ;Control
LC2068A: db $10   ;Slot
LC2068B: db $10   ;Rage
LC2068C: db $10   ;Leap
LC2068D: db $10   ;Mimic
LC2068E: db $10   ;Dance
LC2068F: db $10   ;Row
LC20690: db $10   ;Def.
LC20691: db $E0   ;Jump
LC20692: db $20   ;X-Magic
LC20693: db $10   ;GP Rain
LC20694: db $10   ;Summon
LC20695: db $20   ;Health
LC20696: db $20   ;Shock
LC20697: db $10   ;Possess
LC20698: db $10   ;MagiTek
LC20699: db $00
LC2069A: db $00


;Do various responses to three mortal statuses

LC2069B:  LDX #$12
LC2069D:  LDA $3AA0,X
LC206A0:  LSR
LC206A1:  BCC LC20700    ;if this entity not present, branch to next one
LC206A3:  REP #$20
LC206A5:  LDA $3018,X
LC206A8:  BIT $2F4E      ;is this entity marked to enter battlefield?
LC206AB:  SEP #$20
LC206AD:  BNE LC20700    ;branch to next one if so
LC206AF:  JSR $07AD      ;Mark Control links to be deactivated if entity
                         ;possesses certain statuses
LC206B2:  LDA $3EE4,X
LC206B5:  BIT #$82       ;Check for Dead or Zombie Status
LC206B7:  BEQ LC206BF    ;branch if none set
LC206B9:  STZ $3BF4,X
LC206BC:  STZ $3BF5,X    ;Set HP to 0
LC206BF:  LDA $3EE4,X
LC206C2:  BIT #$C2       ;Check for Dead, Zombie, or Petrify status
LC206C4:  BEQ LC206CF    ;branch if none set
LC206C6:  LDA $3019,X
LC206C9:  TSB $3A3A      ;add to bitfield of dead-ish monsters
LC206CC:  JSR $07C8      ;Clear Zinger, Love Token, and Charm bonds, and
                         ;clear applicable Quick variables
LC206CF:  LDA $3EE4,X
LC206D2:  BPL LC20700    ;Branch if alive
LC206D4:  CPX #$08
LC206D6:  BCS LC206E4    ;branch if monster
LC206D8:  LDA $3ED8,X    ;Which character
LC206DB:  CMP #$0E
LC206DD:  BNE LC206E4    ;Branch if not Banon
LC206DF:  LDA #$06
LC206E1:  STA $3A6E      ;Banon fell... "End of combat" method #6
LC206E4:  JSR $0710      ;If Wound status set on mid-Jump entity, replace
                         ;it with Air Anchor effect so they can land first
LC206E7:  LDA $3EE4,X
LC206EA:  BIT #$02
LC206EC:  BEQ LC206F1    ;branch if no Zombie Status
LC206EE:  JSR $0728      ;clear Wound status, and some other bit
LC206F1:  LDA $3EE4,X
LC206F4:  BPL LC20700    ;Branch if alive
LC206F6:  LDA $3EF9,X
LC206F9:  BIT #$04
LC206FB:  BEQ LC20700    ;branch if no Life 3 status
LC206FD:  JSR $0799      ;prepare Life 3 revival
LC20700:  DEX
LC20701:  DEX
LC20702:  BPL LC2069D    ;iterate for all 10 entities
LC20704:  LDX #$12
LC20706:  JSR $0739      ;clean up Control if flagged
LC20709:  DEX
LC2070A:  DEX
LC2070B:  BPL LC20706    ;loop for every entity onscreen
LC2070D:  JMP $5D26      ;Copy Current and Max HP and MP, and statuses to
                         ;displayable variables


;If Wound status set on mid-Jump entity, replace it with Air Anchor effect so
; they can land first)

LC20710:  REP #$20
LC20712:  LDA $3018,X
LC20715:  BIT $3F2C      ;are they in the middle of a Jump?
LC20718:  SEP #$20
LC2071A:  BEQ LC20727    ;Exit function if not
LC2071C:  JSR $0728      ;clear Wound for now, so they don't actually croak
                         ;in mid-air
LC2071F:  LDA $3205,X
LC20722:  AND #$FB
LC20724:  STA $3205,X    ;Set Air Anchor effect
LC20727:  RTS


LC20728:  LDA $3EE4,X
LC2072B:  AND #$7F       ;Clear death status
LC2072D:  STA $3EE4,X
LC20730:  LDA $3204,X
LC20733:  AND #$BF       ;clear bit 6
LC20735:  STA $3204,X
LC20738:  RTS


;Remove Control's influence from this entity and its Controller/Controllee if
; Control was flagged to be deactivated due to:
;  - C2/07AD found certain statuses on entity [doesn't matter whether
;    it's the Controller or it's the Controllee])
;  - this entity is a Controllee and C2/0C2D detected them sustaining physical
;    damage [healing or 0 damage will count, but a non-damaging attack -- i.e.
;    one with no damage numerals -- will not] )

LC20739:  LDA $32B9,X   ;(who's Controlling this entity?
LC2073C:  CMP #$FF
LC2073E:  BEQ LC20748   ;(branch if nobody controls them
LC20740:  BPL LC20748   ;(branch if somebody controls them, and Control
                        ; wasn't flagged to be deactivated
LC20742:  AND #$7F
LC20744:  TAY           ;(put Controller in Y  [Controllee is in X]
LC20745:  JSR $075B     ;(clear Control info for the Controller and
                        ; Controllee [this entity]
LC20748:  LDA $32B8,X   ;(now see who this entity Controls
LC2074B:  CMP #$FF
LC2074D:  BEQ LC2075A   ;(branch if they control nobody
LC2074F:  BPL LC2075A   ;(branch if they control somebody, and Control
                        ; wasn't flagged to be deactivated
LC20751:  AND #$7F
LC20753:  PHX
LC20754:  TXY           ;(put Controller in Y
LC20755:  TAX           ;(put Controllee in X
LC20756:  JSR $075B     ;(clear Control info for the Controller [this
                        ; entity] and Controllee
LC20759:  PLX
LC2075A:  RTS


;Clear Control-related data for a Controller, addressed by Y, and
; a Controllee, addressed by X)

LC2075B:  LDA $3E4D,Y
LC2075E:  AND #$FE
LC20760:  STA $3E4D,Y
LC20763:  LDA $3EF9,Y
LC20766:  AND #$EF
LC20768:  STA $3EF9,Y    ;clear "Chant" status from Controller
LC2076B:  LDA #$FF
LC2076D:  STA $32B9,X    ;set to nobody controlling Controllee
LC20770:  STA $32B8,Y    ;set to Controller controlling nobody
LC20773:  LDA $3019,X
LC20776:  TRB $2F54      ;cancel visual flipping of Controllee
LC20779:  PHX
LC2077A:  JSR $0783
LC2077D:  TYX
LC2077E:  JSR $0783
LC20781:  PLX
LC20782:  RTS


LC20783:  LDA #$40
LC20785:  JSR $5BAB      ;set bit 6 of $3AA1,X
LC20788:  LDA $3204,X
LC2078B:  ORA #$40
LC2078D:  STA $3204,X    ;set bit 6
LC20790:  LDA #$7F
LC20792:  AND $3AA0,X
LC20795:  STA $3AA0,X    ;clear bit 7
LC20798:  RTS


;Prepare Life 3 revival

LC20799:  AND #$FB
LC2079B:  STA $3EF9,X    ;clear Life 3 status
LC2079E:  LDA $3019,X
LC207A1:  TRB $2F2F      ;remove from bitfield of remaining enemies?
LC207A4:  LDA #$30       ;Life spell ID
LC207A6:  STA $B8
LC207A8:  LDA #$26       ;command #$26
LC207AA:  JMP $4E91      ;queue it, in global Special Action queue


;Mark Control links to be deactivated if entity possesses certain statuses

LC207AD:  PEA $B0C2      ;Sleep, Muddled, Berserk, Death, Petrify, Zombie
LC207B0:  PEA $0311      ;Rage, Freeze, Dance, Stop
LC207B3:  TXY
LC207B4:  JSR $5864
LC207B7:  BCS LC207C7    ;Exit function if none of those statuses set
LC207B9:  ASL $32B8,X
LC207BC:  SEC
LC207BD:  ROR $32B8,X    ;flag "Who you control" link to be deactivated
LC207C0:  ASL $32B9,X
LC207C3:  SEC
LC207C4:  ROR $32B9,X    ;flag "Who controls you" link to be deactivated
LC207C7:  RTS


;Clear Zinger, Love Token, and Charm bonds, and clear applicable Quick variables

LC207C8:  CPX $33F9
LC207CB:  BNE LC207F5    ;branch if you're not being Zingered
LC207CD:  PHX
LC207CE:  LDX $33F8      ;who's doing the Zingering
LC207D1:  LDA $3019,X
LC207D4:  STA $B9
LC207D6:  LDA #$04
LC207D8:  STA $B8
LC207DA:  LDX #$00
LC207DC:  LDA #$24
LC207DE:  JSR $4E91      ;queue Command F5 04, with an animation of 00,
                         ;in global Special Action queue
LC207E1:  LDA #$02
LC207E3:  STA $B8
LC207E5:  LDX #$08
LC207E7:  LDA #$24
LC207E9:  JSR $4E91      ;queue Command F5 02, with an animation of 08,
                         ;in global Special Action queue
LC207EC:  LDA #$FF
LC207EE:  STA $33F8      ;nobody's Zingering
LC207F1:  STA $33F9      ;nobody's being Zingered
LC207F4:  PLX
LC207F5:  LDA $336C,X
LC207F8:  BMI LC207FE    ;branch if you have no Love Token slave
LC207FA:  TAY
LC207FB:  JSR $082D      ;Clear Love Token links between you and slave
LC207FE:  LDA $336D,X
LC20801:  BMI LC2080A    ;branch if you're nobody's Love Token slave
LC20803:  PHX
LC20804:  TXY
LC20805:  TAX
LC20806:  JSR $082D      ;Clear Love Token links between you and master
LC20809:  PLX
LC2080A:  LDA $3394,X
LC2080D:  BMI LC20813    ;branch if you're not Charming anybody
LC2080F:  TAY
LC20810:  JSR $0836      ;Clear Charm links between you and your Charmee
LC20813:  LDA $3395,X
LC20816:  BMI LC2081F    ;branch if you're not Charmed by anybody
LC20818:  PHX
LC20819:  TXY
LC2081A:  TAX
LC2081B:  JSR $0836      ;Clear Charm links between you and Charmer
LC2081E:  PLX
LC2081F:  CPX $3404      ;Compare to Quick's target byte
LC20822:  BNE LC2082C    ;Exit If this actor does not get extra turn due to Quick
LC20824:  LDA #$FF
LC20826:  STA $3404      ;Store #$FF (empty) to Quick's target byte
LC20829:  STA $3402      ;Store #$FF (for none) to the number of turns due to Quick
LC2082C:  RTS


;Clear Love Token effects

LC2082D:  LDA #$FF
LC2082F:  STA $336C,X    ;Love Token master now has no slave
LC20832:  STA $336D,Y    ;and Love Token slave now has no master
LC20835:  RTS


;Clear Charm effects

LC20836:  LDA #$FF
LC20838:  STA $3394,X    ;Charmer is now Charming nobody
LC2083B:  STA $3395,Y    ;and Charmee is now being Charmed by nobody
LC2083E:  RTS


;Update a variety of things when the battle starts, when the enemy formation
; is switched, and at the end of each turn [after the turn's animation plays out])

LC2083F:  LDX #$12
LC20841:  LDA $3AA0,X
LC20844:  LSR
LC20845:  BCC LC208BE    ;if this entity not present, branch to next one
LC20847:  ASL $32E0,X
LC2084A:  LSR $32E0,X    ;clear Bit 7 of $32E0.  this prevents C2/4C5B
                         ;from triggering a counterattack for a once-attacked
                         ;entity turn after turn, while still preserving the
                         ;attacker in Bits 0-6.
LC2084D:  LDA $3EE4,X
LC20850:  BMI LC20859    ;Branch if dead
LC20852:  LDA $3AA1,X
LC20855:  BIT #$40
LC20857:  BEQ LC2085C    ;Branch if bit 6 of $3AA1,X is not set
LC20859:  JSR $0977
LC2085C:  LDA $3204,X
LC2085F:  BEQ LC208AB
LC20861:  LSR
LC20862:  BCC LC20867    ;branch if bit 0 of $3204,X isn't set, meaning entity
                         ;wasn't target of a Palidor summon this turn
LC20864:  JSR $0B4A      ;if it was, do some more Palidor setup
LC20867:  ASL $3204,X
LC2086A:  BCC LC2086F    ;Branch if bit 7 of $3204,X is not set.
                         ;It is set for an entity when their Imp status is
                         ;toggled, the attack/spell costs them MP to cast, or
                         ;the attack itself affects their MP because they're a
                         ;target [or the caster, if it's a draining attack]
LC2086C:  JSR $5763      ;Update availability of entries on Esper, Magic,
                         ;and Lore menus
LC2086F:  ASL $3204,X
LC20872:  BCC LC2087C    ;Branch if bit 6 of $3204,X is not set
LC20874:  JSR $0A0F      ;Remove entity from Wait Queue, remove all records from
                         ;their conventional linked list queue, and default some
                         ;poses if character
LC20877:  LDA #$80
LC20879:  JSR $5BAB      ;set bit 7 of $3AA1,X
LC2087C:  ASL $3204,X
LC2087F:  BCC LC20884    ;Branch if bit 5 of $3204,X is not set.
                         ;It is set for an entity upon Condemned status
                         ;being set.
LC20881:  JSR $09B4      ;Assign a starting value to Condemned counter
LC20884:  ASL $3204,X
LC20887:  BCC LC2088C    ;Branch if bit 4 of $3204,X is not set.
                         ;It is set for an entity when Condemned expires or
                         ;is otherwise cleared.
LC20889:  JSR $09CE      ;Zero the Condemned counter
LC2088C:  ASL $3204,X
LC2088F:  BCC LC20898    ;Branch if bit 3 of $3204,X is not set.
                         ;It is set for an entity when Mute or Imp status
                         ;is toggled.
LC20891:  CPX #$08
LC20893:  BCS LC20898    ;Branch if not a character
LC20895:  JSR $527D      ;Update availability of commands on character's
                         ;main menu
LC20898:  ASL $3204,X
LC2089B:  BCC LC208A0    ;Branch if bit 2 of $3204,X is not set.
                         ;It is set for an entity when Haste or Slow is toggled,
                         ;and a couple other cases I'm not sure of.
LC2089D:  JSR $09D2      ;Recalculate the amount by which to increase the ATB
                         ;gauge.  Affects various other timers, too.
LC208A0:  ASL $3204,X
LC208A3:  BCC LC208A8    ;Branch if bit 1 of $3204,X is not set.
                         ;It is set for an entity when Morph status is toggled.
LC208A5:  JSR $0AA8      ;switch command on main menu between Morph and Revert,
                         ;and adjust Morph-related variables like timers
LC208A8:  ASL $3204,X    ;clear former Bit 0, just like we've already cleared
                         ;all the other bits with our shifting.
LC208AB:  JSR $091F
LC208AE:  JSR $08C6
LC208B1:  LDA $3AA0,X
LC208B4:  BIT #$50
LC208B6:  BEQ LC208BB
LC208B8:  JSR $0A41      ;clear Defending flag
LC208BB:  JSR $0A4A      ;Prepare equipment spell activations on low HP
LC208BE:  DEX
LC208BF:  DEX
LC208C0:  BMI LC208C5
LC208C2:  JMP $0841      ;iterate for all 10 entities
LC208C5:  RTS


LC208C6:  LDA #$50
LC208C8:  JSR $11B4      ;set Bits 4 and 6 of $3AA0,X
LC208CB:  LDA $3404
LC208CE:  BMI LC208D5    ;branch if no targets under the influence of Quick
LC208D0:  CPX $3404      ;Is this target under the influence of Quick?
LC208D3:  BNE LC208C5    ;branch if not
LC208D5:  LDA $3EE4,X
LC208D8:  BIT #$C0
LC208DA:  BNE LC208C5    ;Exit if dead or Petrify
LC208DC:  LDA $3EF8,X
LC208DF:  BIT #$10
LC208E1:  BNE LC208C5    ;Exit if stop
LC208E3:  LDA #$EF
LC208E5:  JSR $0792      ;clear Bit 4 of $3AA0,X
LC208E8:  LDA $32B9,X
LC208EB:  BPL LC208C5    ;Exit if you are controlled
LC208ED:  LDA $3EE5,X
LC208F0:  BMI LC208C5    ;Exit if asleep
LC208F2:  LDA $3EF9,X
LC208F5:  BIT #$02
LC208F7:  BNE LC208C5    ;Exit if Freeze
LC208F9:  LDA $3359,X
LC208FC:  BPL LC208C5    ;Exit if seized
LC208FE:  LDA #$BF
LC20900:  JSR $0792      ;clear Bit 6 of $3AA0,X
LC20903:  LDA $3AA1,X
LC20906:  BPL LC208C5    ;Exit if bit 7 of $3AA1 is not set
LC20908:  AND #$7F       ;Clear bit 7
LC2090A:  STA $3AA1,X
LC2090D:  LDA $32CC,X    ;get entry point to entity's conventional linked
                         ;list queue
LC20910:  INC
LC20911:  BEQ LC208C5    ;Exit if null, as list is empty
LC20913:  LDA $3AA1,X
LC20916:  LSR
LC20917:  BCC LC2091C    ;Branch if bit 0 of $3AA1 is not set
LC20919:  JMP $4E77      ;put entity in action queue
LC2091C:  JMP $4E66      ;put entity in wait queue


LC2091F:  CPX #$08
LC20921:  BCS LC208C5    ;exit if monster
LC20923:  LDA $3ED8,X    ;Which character it is
LC20926:  CMP #$0D
LC20928:  BEQ LC208C5    ;Exit if Umaro
LC2092A:  LDA $3255,X    ;top byte of offset of main script
LC2092D:  BPL LC208C5    ;branch if character has a main script
LC2092F:  LDA $3A97
LC20932:  BNE LC208C5    ;exit if in the Colosseum
LC20934:  LDA #$02
LC20936:  STA $EE
LC20938:  CPX $3404      ;Is this target under the influence of Quick?
LC2093B:  BNE LC20941    ;branch if not
LC2093D:  LDA #$88
LC2093F:  TSB $EE
LC20941:  LDA $EE
LC20943:  JSR $11B4
LC20946:  LDA $3018,X
LC20949:  BIT $2F4C      ;is entity marked to leave battlefield?
LC2094C:  BNE LC20986    ;branch if so
LC2094E:  LDA $3359,X
LC20951:  AND $3395,X
LC20954:  BPL LC20986    ;branch if Seized or Charmed
LC20956:  PEA $B0C2      ;Sleep, Muddled, Berserk, Death, Petrify, Zombie
LC20959:  PEA $2101      ;Dance, Hide, Rage
LC2095C:  TXY
LC2095D:  JSR $5864
LC20960:  BCC LC20986    ;Branch if any set
LC20962:  LDA $3AA0,X
LC20965:  BPL LC209CD
LC20967:  LDA $32CC,X    ;get entry point to entity's conventional linked
                         ;list queue
LC2096A:  BPL LC209CD    ;exit if non-null, i.e. list has a record
LC2096C:  LDA $3AA0,X
LC2096F:  ORA #$08
LC20971:  STA $3AA0,X    ;turn on bit 3
LC20974:  JMP $11EF


LC20977:  REP #$20
LC20979:  LDA #$BFD3
LC2097C:  JSR $0792
LC2097F:  SEP #$20
LC20981:  LDA #$01
LC20983:  STA $3219,X
LC20986:  LDA #$F9
LC20988:  XBA
LC20989:  LDA $3EF9,X
LC2098C:  BIT #$20
LC2098E:  BNE LC209A3    ;Branch if Hide status
LC20990:  LDA $3018,X
LC20993:  BIT $2F4C      ;is entity marked to leave battlefield?
LC20996:  BNE LC209A3    ;branch if so
LC20998:  LDA $3AA0,X
LC2099B:  BPL LC209A3    ;Branch if bit 7 of $3AA0 is not set
LC2099D:  LDA #$79
LC2099F:  XBA
LC209A0:  JSR $4E66      ;put entity in wait queue
LC209A3:  XBA
LC209A4:  JSR $0792
LC209A7:  CPX #$08
LC209A9:  BCS LC209CD    ;Exit function if monster
LC209AB:  TXA
LC209AC:  LSR
LC209AD:  STA $10
LC209AF:  LDA #$03
LC209B1:  JMP $6411


;Assign a starting value to Condemned counter
;Counter = 81 - (Attacker Level + [0..(Attacker Level - 1)]), with a minimum of 20 .
; For purposes of a starting status, Attacker Level is treated as 20.)

LC209B4:  LDA $11AF      ;Attacker Level
LC209B7:  JSR $4B65      ;random: 0 to Level - 1
LC209BA:  CLC
LC209BB:  ADC $11AF      ;Add to level
LC209BE:  STA $EE
LC209C0:  SEC
LC209C1:  LDA #$3C
LC209C3:  SBC $EE        ;Subtract from 60
LC209C5:  BCS LC209C8
LC209C7:  TDC            ;Set to 0 if less than 0
LC209C8:  ADC #$14       ;Add 21.  if it was less than 0, add 20 instead,
                         ;giving it a starting value of 20.
LC209CA:  STA $3B05,X    ;set Condemned counter
                         ;note that this counter is "one off" from the
                         ;actual numerals you'll see onscreen:
                         ;   00 value = numerals disabled
                         ;   01 value = numerals at "00"
                         ;   02 value = numerals at "01"
                         ;   03 value = numerals at "02" , etc.
LC209CD:  RTS


;Zero and Disable Condemned counter

LC209CE:  STZ $3B05,X    ;Condemned counter = 0, disabled
LC209D1:  RTS


;Battle Time Counter function
;Recalculate the ATB multiplier, which affects: the Condemned counter, invisible
; timers for auto-expiring statuses, and the frequency of damage/healing from
; statuses like Regen and Poison.
; Also recalculate the amount by which to increase the ATB gauge, and the related
; amount for the "wait timer" [which determines how long a character is in their
; ready stance].)

LC209D2:  PHP
LC209D3:  LDY #$20      ;ATB multiplier = 32 if slowed
LC209D5:  LDA $3EF8,X
LC209D8:  BIT #$04
LC209DA:  BNE LC209E4   ;Branch if Slow
LC209DC:  LDY #$40      ;ATB multiplier = 64 normally
LC209DE:  BIT #$08
LC209E0:  BEQ LC209E4   ;Branch if not Haste
LC209E2:  LDY #$54      ;ATB multiplier = 84 if hasted
LC209E4:  TYA
LC209E5:  STA $3ADD,X   ;save the ATB multiplier
LC209E8:  TYA           ;this instruction seems frivolous
LC209E9:  PHA            ;Put on stack
LC209EA:  CLC
LC209EB:  LSR
LC209EC:  ADC $01,S
LC209EE:  STA $01,S     ;ATB multiplier *= 1.5
LC209F0:  LDA $3B19,X   ;Speed
LC209F3:  ADC #$14
LC209F5:  XBA           ;Speed + 20 in top byte of Accumulator
LC209F6:  CPX #$08
LC209F8:  BCC LC20A00   ;branch if not an enemy
LC209FA:  LDA $3A90     ;= 255 - (Battle Speed setting * 24)
                        ;remember that what you see on the Config menu is
                        ;Battle Speed + 1
LC209FD:  JSR $4781     ;A = (speed + 20) * $3A90
LC20A00:  PLA           ;bottom byte of A is now Slow/Normal/Haste Constant
LC20A01:  JSR $4781     ;Let C be the Slow/Normal/Haste constant, equal to
                        ;48, 96, or 126, respectively.
                        ;for characters:
                        ;A = (Speed + 20 * C
                        ;for enemies:
                        ;A = ( ((Speed + 20) * $3A90) DIV 256) * C
LC20A04:  REP #$20
LC20A06:  LSR
LC20A07:  LSR
LC20A08:  LSR
LC20A09:  LSR           ;A = A / 16
LC20A0A:  STA $3AC8,X   ;Save as amount by which to increase ATB timer.
LC20A0D:  PLP
LC20A0E:  RTS


;Remove entity from Wait Queue, remove all records from their conventional linked list
; queue, do ????, and default some poses if character)

LC20A0F:  JSR $0301      ;Remove current first record from entity's
                         ;conventional linked list queue, and update their
                         ;entry point accordingly
LC20A12:  LDA $32CC,X
LC20A15:  BPL LC20A0F    ;repeat as long as their queue has a valid entry
                         ;point [i.e. it's not empty]
LC20A17:  LDY $3A64      ;get position of next Wait Queue slot to read
LC20A1A:  TXA
LC20A1B:  CMP $3720,Y    ;does queue entry match our current entity?
LC20A1E:  BNE LC20A25    ;if not, branch and move to next entry
LC20A20:  LDA #$FF
LC20A22:  STA $3720,Y    ;if there was a match, null out this Wait Queue
                         ;entry
LC20A25:  INY            ;move to next entry
LC20A26:  CPY $3A65
LC20A29:  BCC LC20A1A    ;keep looping until position matches next available
                         ;queue slot -- i.e., we've checked through the end of
                         ;the queue
LC20A2B:  LDA $3219,X
LC20A2E:  BNE LC20A38    ;branch if top byte of ATB counter is not 0
LC20A30:  DEC $3219,X    ;make it 255
LC20A33:  LDA #$D3
LC20A35:  JSR $0792      ;clear Bits 2, 3, and 5 of $3AA0,X
LC20A38:  CPX #$08
LC20A3A:  BCS LC20A49    ;exit if monster
LC20A3C:  LDA #$2C
LC20A3E:  JMP $4E91      ;queue command to buffer Battle Dynamics Command 0Eh,
                         ;graphics related [defaulting character poses?], in
                         ;global Special Action queue.  see Function C2/51A8
                         ;for more info.


;Clear Defending flag

LC20A41:  LDA #$FD
LC20A43:  AND $3AA1,X
LC20A46:  STA $3AA1,X    ;clear Defending flag.  or other bit(s if
                         ;entered via C2/0A43.
LC20A49:  RTS


;Prepare equipment spell activations on low HP

LC20A4A:  LDA $3AA0,X
LC20A4D:  BIT #$10       ;is entity Wounded, Petrified, or Stopped, or is
                         ;somebody else under the influence of Quick?
LC20A4F:  BNE LC20A90    ;Exit function if any are true
LC20A51:  LDA #$02
LC20A53:  BIT $3EE5,X
LC20A56:  BEQ LC20A90    ;Branch if not Near Fatal
LC20A58:  BIT $3205,X    ;is bit 1 set?
LC20A5B:  BEQ LC20A90    ;exit if not, meaning we've already activated
                         ;a spell on low HP this battle
LC20A5D:  EOR $3205,X
LC20A60:  STA $3205,X    ;toggle off bit 1
LC20A63:  LDA $3C59,X
LC20A66:  LSR
LC20A67:  BCC LC20A74    ;Branch if not Shell when low HP
LC20A69:  PHA            ;Put on stack
LC20A6A:  LDA #$25
LC20A6C:  STA $B8        ;Shell spell ID
LC20A6E:  LDA #$26
LC20A70:  JSR $4E91      ;queue Command #$26, in global Special Action queue
LC20A73:  PLA
LC20A74:  LSR
LC20A75:  BCC LC20A82    ;branch if not Safe when low HP
LC20A77:  PHA            ;Put on stack
LC20A78:  LDA #$1C
LC20A7A:  STA $B8        ;Safe spell ID
LC20A7C:  LDA #$26
LC20A7E:  JSR $4E91      ;queue Command #$26, in global Special Action queue
LC20A81:  PLA
LC20A82:  LSR
LC20A83:  BCC LC20A90    ;branch if not Reflect when low HP [no item
                         ;in game has this feature, but it's possible]
LC20A85:  PHA            ;Put on stack
LC20A86:  LDA #$24
LC20A88:  STA $B8        ;Rflect spell ID
LC20A8A:  LDA #$26
LC20A8C:  JSR $4E91      ;queue Command #$26, in global Special Action queue
LC20A8F:  PLA
LC20A90:  RTS


LC20A91:  LDX #$06
LC20A93:  LDA $3018,X
LC20A96:  BIT $3A74      ;is this character among alive and present ones?
LC20A99:  BEQ LC20AA3    ;skip to next one if not
LC20A9B:  BIT $3F2C      ;are they a Jumper?
LC20A9E:  BNE LC20AA3    ;skip to next one if so
LC20AA0:  JSR $0A0F      ;Remove entity from Wait Queue, remove all records
                         ;from their conventional linked list queue, and
                         ;default some poses if character
LC20AA3:  DEX
LC20AA4:  DEX
LC20AA5:  BPL LC20A93    ;loop for all 4 characters
LC20AA7:  RTS


;Switch command on main menu between Morph and Revert, and adjust
; Morph-related variables like timers)

LC20AA8:  LDA $B1
LC20AAA:  LSR            ;is it an unconventional turn?  in this context,
                         ;that's auto-Revert.
LC20AAB:  BCS LC20AB7    ;branch if so
LC20AAD:  LDA $3219,X    ;Load top byte of this target's ATB counter
LC20AB0:  BNE LC20AB7    ;branch if not zero
LC20AB2:  LDA #$88
LC20AB4:  JSR $11B4
LC20AB7:  PHX
LC20AB8:  LDA $3EF9,X
LC20ABB:  EOR #$08       ;get opposite of Morph status
LC20ABD:  LSR
LC20ABE:  LSR
LC20ABF:  LSR
LC20AC0:  LSR
LC20AC1:  PHP            ;save Carry flag, which is opposite of
                         ;"currently Morphed"
LC20AC2:  TDC
LC20AC3:  ADC #$03
LC20AC5:  STA $EE        ;$EE = 3 or 4, depending on carry flag
LC20AC7:  TXA
LC20AC8:  XBA
LC20AC9:  LDA #$06
LC20ACB:  JSR $4781
LC20ACE:  TAX
LC20ACF:  LDY #$04
LC20AD1:  LDA $202E,X    ;get contents of menu slot
LC20AD4:  CMP $EE
LC20AD6:  BNE LC20ADD    ;if Morphed and menu item isn't Morph(3, branch  -OR-
                         ;if not Morphed and menu item isn't Revert(4), branch
LC20AD8:  EOR #$07
LC20ADA:  STA $202E,X    ;toggle menu item between Morph(3) and Revert(4)
LC20ADD:  INX
LC20ADE:  INX
LC20ADF:  INX
LC20AE0:  DEY
LC20AE1:  BNE LC20AD1    ;loop for all 4 menu items
LC20AE3:  PLP
LC20AE4:  PLX
LC20AE5:  BCC LC20B01    ;Branch if currently Morphed
LC20AE7:  PHP
LC20AE8:  JSR $0B36      ;Establish new value for Morph supply based on its
                         ;previous value and the current Morph timer
LC20AEB:  LDA #$FF
LC20AED:  STA $3EE2      ;Store null as Morphed character
LC20AF0:  STZ $3B04,X    ;Set the Morph gauge for this entity to 0
LC20AF3:  CPX #$08       ;Compare target number to 8
LC20AF5:  BCS LC20AFA    ;Branch if it's greater (not a character)
LC20AF7:  JSR $527D      ;Update availability of commands on character's
                         ;main menu - grey out or enable
LC20AFA:  REP #$20
LC20AFC:  STZ $3F30      ;morph timer = 0
LC20AFF:  PLP
LC20B00:  RTS


;If no one is already Morphed: designate character in X as Morphed, start Morph
; timer at 65535, and establish amount to decrement morph time counter based on
; Morph supply)

LC20B01:  PHX
LC20B02:  PHP
LC20B03:  LDA $3EE2      ;Which target is Morphed
LC20B06:  BPL LC20B33    ;Exit function if someone is already Morphed
LC20B08:  LDA $3EBB
LC20B0B:  LSR
LC20B0C:  LSR
LC20B0D:  ROR
LC20B0E:  BCS LC20B33    ;Exit function if bit 2 of $3EBB is set..
                         ;Set for just Phunbaba battle #4 [i.e. Terra's
                         ;second Phunbaba encounter]
LC20B10:  ASL            ;Put Bit 1 into Carry
LC20B11:  STX $3EE2      ;store target in X as Morphed character
LC20B14:  TDC
LC20B15:  REP #$20       ;Set 16-bit Accumulator
LC20B17:  DEC
LC20B18:  STA $3F30      ;Morph timer = 65535
LC20B1B:  LDX $1CF6      ;Morph supply
LC20B1E:  JSR $4792      ;65535 / Morph supply
LC20B21:  BCC LC20B24    ;Branch if bit 1 of $3EBB not set.
                         ;This bit is set in Terra's 2nd Phunbaba battle
                         ;[i.e. Phunbaba #4], and lasts afterward.  So
                         ;Terra gains some resolve here. ^__^
LC20B23:  LSR
LC20B24:  LSR
LC20B25:  LSR
LC20B26:  LSR            ;A = (65535 / Morph supply / 8  [pre-Phunbaba]
                         ;A = (65535 / Morph supply) / 16  [post-Phunbaba]
LC20B27:  CMP #$0800
LC20B2A:  BCC LC20B2F
LC20B2C:  LDA #$07FF     ;this will cap amount to decrement morph time
                         ;counter at 2048
LC20B2F:  INC
LC20B30:  STA $3F32      ;Amount to decrement morph time counter
LC20B33:  PLP
LC20B34:  PLX
LC20B35:  RTS


;Establish new value for Morph supply based on its previous value and
; the current Morph timer)

LC20B36:  LDA $3EE2      ;Which target is Morphed
LC20B39:  BMI LC20B49    ;Exit if no one is Morphed
LC20B3B:  LDA $1CF6
LC20B3E:  XBA
LC20B3F:  LDA $3F31
LC20B42:  JSR $4781      ;16-bit A = morph supply * (morph timer DIV 256)
LC20B45:  XBA
LC20B46:  STA $1CF6      ;morph supply =
                         ;(morph supply * (morph timer DIV 256)) DIV 256
LC20B49:  RTS


;Called after turn when Palidor used

LC20B4A:  REP #$20       ;Set 16-bit Accumulator
LC20B4C:  LDA $3018,X
LC20B4F:  TSB $3F2C      ;flag entity as Jumping
LC20B52:  SEP #$20       ;Set 8-bit Accumulator
LC20B54:  LDA $3AA0,X
LC20B57:  AND #$9B
LC20B59:  ORA #$08
LC20B5B:  STA $3AA0,X
LC20B5E:  LDY $3A66      ;get current action queue position
LC20B61:  TXA
LC20B62:  CMP $3820,Y    ;does queue entry match our current entity?
LC20B65:  BNE LC20B6C    ;if not, branch and move to next entry
LC20B67:  LDA #$FF
LC20B69:  STA $3820,Y    ;if there was a match, null out this action queue
                         ;entry
LC20B6C:  INY            ;move to next entry
LC20B6D:  CPY $3A67
LC20B70:  BCC LC20B61    ;keep looping until position matches next available
                         ;queue slot -- i.e., we've checked through the end of
                         ;the queue
LC20B72:  LDA $3205,X
LC20B75:  AND #$7F
LC20B77:  STA $3205,X    ;indicate entity has not taken a conventional turn
                         ;[including landing one] since boarding Palidor
LC20B7A:  STZ $3AB5,X    ;zero top byte of Wait Timer
LC20B7D:  LDA #$E0
LC20B7F:  STA $322C,X    ;save delay between inputting command and performing it.
                         ;iow, how long you spend in the "ready stance."  E0h
                         ;is the same delay as the Jump command, and its ready
                         ;stance constitutes the character being airborne.
LC20B82:  RTS


;Modify Damage, Heal Undead, and Elemental modification

LC20B83:  PHP
LC20B84:  SEP #$20
LC20B86:  LDA $11A6      ;Battle Power
LC20B89:  BNE LC20B8E    ;Branch if not 0
LC20B8B:  JMP $0C2B      ;Exit function if 0
LC20B8E:  LDA $11A4      ;Special Byte 2
LC20B91:  BMI LC20B98    ;Branch if power = factor of HP
LC20B93:  JSR $0C9E      ;Damage modification
LC20B96:  BRA LC20B9B
LC20B98:  JSR $0D87      ;Figure HP-based or MP-based damage
LC20B9B:  STZ $F2
LC20B9D:  LDA $3EE4,Y    ;Status byte 1 of target
LC20BA0:  ASL
LC20BA1:  BMI LC20BFA    ;Branch if target is Petrify, damage = 0

LC20BA3:  LDA $11A4
LC20BA6:  STA $F2        ;Store special byte 2 in $F2.  what we're looking
                         ;at is Bit 0, the Heal flag.
LC20BA8:  LDA $11A2
LC20BAB:  BIT #$08
LC20BAD:  BEQ LC20BD3    ;Branch if not Invert Damage on Undead
LC20BAF:  LDA $3C95,Y
LC20BB2:  BPL LC20BBF    ;Branch if not undead
LC20BB4:  LDA $11AA
LC20BB7:  BIT #$82       ;Check if dead or zombie attack
LC20BB9:  BNE LC20C2B    ;Exit if ^
LC20BBB:  STZ $F2        ;Clear heal flag
LC20BBD:  BRA LC20BC6
LC20BBF:  LDA $3EE4,Y
LC20BC2:  BIT #$02       ;Check for Zombie status
LC20BC4:  BEQ LC20BD3    ;Branch if not zombie
LC20BC6:  LDA $11A4
LC20BC9:  BIT #$02
LC20BCB:  BEQ LC20BD3    ;Branch if not redirection
LC20BCD:  LDA $F2
LC20BCF:  EOR #$01
LC20BD1:  STA $F2        ;Toggle heal flag

LC20BD3:  LDA $11A1
LC20BD6:  BEQ LC20C1E    ;Branch if non-elemental
LC20BD8:  LDA $3EC8      ;Forcefield nullified elements
LC20BDB:  EOR #$FF
LC20BDD:  AND $11A1
LC20BE0:  BEQ LC20BFA    ;Set damage to 0 if element nullified
LC20BE2:  LDA $3BCC,Y    ;Absorbed elements
LC20BE5:  BIT $11A1
LC20BE8:  BEQ LC20BF2    ;branch if none are used in attack
LC20BEA:  LDA $F2
LC20BEC:  EOR #$01
LC20BEE:  STA $F2        ;toggle healing flag
LC20BF0:  BRA LC20C1E
LC20BF2:  LDA $3BCD,Y    ;Nullified elements
LC20BF5:  BIT $11A1
LC20BF8:  BEQ LC20C00    ;branch if none are used in attack
LC20BFA:  STZ $F0
LC20BFC:  STZ $F1        ;Set damage to 0
LC20BFE:  BRA LC20C1E
LC20C00:  LDA $3BE1,Y    ;Elements cut in half
LC20C03:  BIT $11A1
LC20C06:  BEQ LC20C0E    ;branch if none are used in attack
LC20C08:  LSR $F1
LC20C0A:  ROR $F0        ;Cut damage in half
LC20C0C:  BRA LC20C1E
LC20C0E:  LDA $3BE0,Y    ;Weak elements
LC20C11:  BIT $11A1
LC20C14:  BEQ LC20C1E    ;branch if none are used in attack
LC20C16:  LDA $F1
LC20C18:  BMI LC20C1E    ;Don't double damage if over 32768
LC20C1A:  ASL $F0
LC20C1C:  ROL $F1        ;Double damage
LC20C1E:  LDA $11A9      ;get attack special effect
LC20C21:  CMP #$04
LC20C23:  BNE LC20C28    ;Branch if not Atma Weapon
LC20C25:  JSR $0E39      ;Atma Weapon damage modification
LC20C28:  JSR $0C2D      ;see description 3 lines below
LC20C2B:  PLP
LC20C2C:  RTS


;For physical attacks, handle random Zombie-inflicted ailments, and set up removal
; of Sleep, Muddled, and Control.  Handle drainage.  Enforce 9999 damage cap.)

LC20C2D:  LDA $11A2
LC20C30:  LSR
LC20C31:  BCC LC20C5D    ;Branch if not physical damage
LC20C33:  LDA $3A82
LC20C36:  AND $3A83
LC20C39:  BPL LC20C5D    ;Branch if blocked by Golem or dog
LC20C3B:  LDA $3EE4,X
LC20C3E:  BIT #$02       ;Check for Zombie Status on attacker
LC20C40:  BEQ LC20C45    ;Branch if not zombie
LC20C42:  JSR $0E21      ;Poison / Dark status for zombies
LC20C45:  LDA $11AB      ;Status set by attack 2
LC20C48:  EOR #$A0       ;Sleep & Muddled
LC20C4A:  AND #$A0
LC20C4C:  AND $3EE5,Y    ;Status byte 2
LC20C4F:  ORA $3DFD,Y
LC20C52:  STA $3DFD,Y    ;mark Sleep & Muddled to be cleared from target,
                         ;provided it already has the statuses, and
                         ;the attack itself isn't trying to inflict or remove
                         ;them
LC20C55:  LDA $32B9,Y
LC20C58:  ORA #$80
LC20C5A:  STA $32B9,Y    ;Flag target to be released from Control at end of
                         ;turn
LC20C5D:  LDA $11A4
LC20C60:  BIT #$02
LC20C62:  BEQ LC20C75    ;Branch if not redirection
LC20C64:  JSR $0DED      ;Cap damage/healing based on max HP/MP of drainer,
                         ;and remaining HP/MP of drainee
LC20C67:  PHX            ;save attacker index
LC20C68:  PHY            ;save target index
LC20C69:  PHY
LC20C6A:  TXY            ;put old attacker index into target index
LC20C6B:  PLX            ;put old target index into attacker index
LC20C6C:  JSR $362F      ;save target as attacker's attacker in a counterattack
                         ;variable [provided attacker doesn't yet have another
                         ;attacker].  reciprocity and all, man.
                         ;however, the Carry Flag state passed to this function
                         ;seems to be quite arbitrary, particularly if this
                         ;is a physical attack [usually being set, but sometimes
                         ;not if attacker is a Zombie].  it'll never be set for
                         ;magical attacks, which seems suspect as well.
LC20C6F:  SEC            ;enforce 9999 cap for redirection for attacker
LC20C70:  JSR $0C76
LC20C73:  PLY            ;restore target index
LC20C74:  PLX            ;restore attacker index
LC20C75:  CLC            ;now enforce 9999 cap for target
LC20C76:  PHY
LC20C77:  PHP
LC20C78:  ROL
LC20C79:  EOR $F2        ;get Carry XOR attack's heal bit
LC20C7B:  LSR
LC20C7C:  BCC LC20C82    ;branch if:
                         ; - we're checking attacker and attack "reverse" drains
                         ;   [e.g. because target is undead or absorbs element]
                         ; - we're checking target and attack damages [includes
                         ;   draining]
LC20C7E:  TYA
LC20C7F:  ADC #$13
LC20C81:  TAY            ;point to Healing instead of Damage
LC20C82:  REP #$20
LC20C84:  LDA $33D0,Y    ;Damage Taken / Healing Done
LC20C87:  INC
LC20C88:  BEQ LC20C8B    ;if no [i.e. FFFFh] damage, treat as zero
LC20C8A:  DEC            ;otherwise, keep as-is
LC20C8B:  CLC
LC20C8C:  ADC $F0        ;add Damage/Healing so far to $F0, which is the lowest of:
                         ; - attack damage
                         ; - HP of target [or attacker if reverse drain]
                         ; - Max HP - HP of attacker [or target if reverse drain]
LC20C8E:  BCS LC20C95    ;if total Damage/Healing to this target overflowed,
                         ;branch and set it to 9999
LC20C90:  CMP #$2710     ;If over 9999
LC20C93:  BCC LC20C98
LC20C95:  LDA #$270F     ;Truncate Damage to 9999
LC20C98:  STA $33D0,Y    ;Damage Taken / Healing Done
LC20C9A:  PLP
LC20C9C:  PLY
LC20C9D:  RTS


;Damage modification (Randomness, Row, Self Damage, and more

LC20C9E:  PHP
LC20C9F:  REP #$20
LC20CA1:  LDA $11B0      ;Maximum Damage
LC20CA4:  STA $F0
LC20CA6:  SEP #$20       ;Set 8-bit Accumulator
LC20CA8:  LDA $3414
LC20CAB:  BNE LC20CB0
LC20CAD:  JMP $0D3B      ;Exit if Skip damage modification
LC20CB0:  JSR $4B5A      ;Random number 0 to 255
LC20CB3:  ORA #$E0       ;Set bits 7,6,5; bits 0,1,2,3,4 are random
LC20CB5:  STA $E8        ;Random number [224..255]
LC20CB7:  JSR $0D3D      ;Damage randomness
LC20CBA:  CLC
LC20CBB:  LDA $11A3
LC20CBE:  BMI LC20CC4    ;Branch if Concern MP
LC20CC0:  LDA $11A2
LC20CC3:  LSR            ;isolate magical vs. physical property
LC20CC4:  LDA $11A2
LC20CC7:  BIT #$20
LC20CC9:  BNE LC20D22    ;Branch if ignores defense
LC20CCB:  PHP            ;save Carry flag, which equals
                         ;(physical attack) AND NOT(Concern MP)
LC20CCC:  LDA $3BB9,Y    ;Magic Defense
LC20CCF:  BCC LC20CD4    ;Branch if concern MP or Magical damage
LC20CD1:  LDA $3BB8,Y    ;Defense
LC20CD4:  INC
LC20CD5:  BEQ LC20CE7    ;Branch if = 255
LC20CD7:  XBA
LC20CD8:  LDA $3A82
LC20CDB:  AND $3A83
LC20CDE:  BMI LC20CE3    ;If Blocked by Golem or Dog, defense = 192
LC20CE0:  LDA #$C1
LC20CE2:  XBA
LC20CE3:  XBA
LC20CE4:  DEC
LC20CE5:  EOR #$FF
LC20CE7:  STA $E8        ;= 255 - Defense
LC20CE9:  JSR $0D3D      ;Multiply damage by (255 - Defense / 256 ,
                         ;then add 1
LC20CEC:  LDA $01,S
LC20CEE:  LSR
LC20CEF:  LDA $3EF8,Y    ;Status byte 3
LC20CF2:  BCS LC20CF5    ;Branch if physical attack without Concerns MP
LC20CF4:  ASL
LC20CF5:  ASL
LC20CF6:  BPL LC20CFF    ;Branch if no Safe / Shell on target
LC20CF8:  LDA #$AA
LC20CFA:  STA $E8
LC20CFC:  JSR $0D3D      ;Multiply damage by 170 / 256 , then add 1
LC20CFF:  PLP
LC20D00:  BCC LC20D17    ;Skip row check if magical attack or Concern MP
LC20D02:  LDA $3AA1,Y
LC20D05:  BIT #$02
LC20D07:  BEQ LC20D0D    ;Branch if target not defending
LC20D09:  LSR $F1
LC20D0B:  ROR $F0        ;Cut damage in half
LC20D0D:  BIT #$20       ;Check row
LC20D0F:  BEQ LC20D22    ;Branch if target in front row
LC20D11:  LSR $F1
LC20D13:  ROR $F0        ;Cut damage in half
LC20D15:  BRA LC20D22    ;Skip morph if physical attack
LC20D17:  LDA $3EF9,Y
LC20D1A:  BIT #$08
LC20D1C:  BEQ LC20D22    ;Branch if target not morphed
LC20D1E:  LSR $F1
LC20D20:  ROR $F0        ;Cut damage in half
LC20D22:  REP #$20       ;Set 16-bit Accumulator
LC20D24:  LDA $11A4
LC20D27:  LSR
LC20D28:  BCS LC20D34    ;Branch if heal; heal skips self damage theory
LC20D2A:  CPY #$08
LC20D2C:  BCS LC20D34    ;Branch if target is a monster
LC20D2E:  CPX #$08
LC20D30:  BCS LC20D34    ;Branch if attacker is monster
LC20D32:  LSR $F0        ;Cut damage in half if party attacks party
LC20D34:  LDA $F0
LC20D36:  JSR $370B      ;Increment damage using $BC
LC20D39:  STA $F0
LC20D3B:  PLP
LC20D3C:  RTS


;Multiplies damage by $E8 / 256 and adds 1
;Used by damage randomness, etc.)

LC20D3D:  PHP
LC20D3E:  REP #$20       ;Set 16-bit Accumulator
LC20D40:  LDA $F0        ;Load damage
LC20D42:  JSR $47B7      ;Multiply by randomness byte
LC20D45:  INC            ;Add 1 to damage
LC20D46:  STA $F0
LC20D48:  PLP
LC20D49:  RTS


;Atlas Armlet / Earring Function

LC20D4A:  PHP
LC20D4B:  LDA $11A4      ;Special Byte 2
LC20D4E:  LSR
LC20D4F:  BCS LC20D85    ;Exits function if attack heals
LC20D51:  LDA $11A3
LC20D54:  BMI LC20D5A    ;Branch if concern MP
LC20D56:  LDA $11A2      ;Special Byte 1
LC20D59:  LSR            ;Check for physical / magic
LC20D5A:  REP #$20       ;Set 16-bit Accumulator
LC20D5C:  LDA $11B0      ;Max Damage
LC20D5F:  STA $EE        ;Stores damage at $EE
LC20D61:  LDA $3C44,X    ;Relic effects
LC20D64:  SEP #$20       ;Set 8-bit Accumulator
LC20D66:  BCS LC20D6E    ;Branch if physical damage unless concerns mp
LC20D68:  BIT #$02
LC20D6A:  BNE LC20D75    ;Branch double earrings - add 50% damage
LC20D6C:  XBA
LC20D6D:  LSR
LC20D6E:  LSR
LC20D6F:  BCC LC20D85    ;Exits function if not Atlas Armlet / Earring
LC20D71:  LSR $EF        ;Halves damage
LC20D73:  ROR $EE
LC20D75:  REP #$20       ;Set 16-bit Accumulator
LC20D77:  LDA $EE
LC20D79:  LSR            ;Halves damage
LC20D7A:  CLC
LC20D7B:  ADC $11B0      ;Adds to damage
LC20D7E:  BCC LC20D82
LC20D80:  TDC
LC20D81:  DEC
LC20D82:  STA $11B0      ;Stores result back in damage
LC20D85:  PLP
LC20D86:  RTS


;Figure damage if based on HP or MP

LC20D87:  PHX
LC20D88:  PHY
LC20D89:  PHP
LC20D8A:  REP #$20       ;Set 16-bit Accumulator
LC20D8C:  LDA $33D0,Y    ;Damage already Taken.  normally none [FFFFh], but
                         ;exists for Launcher and fictional reflected spells.
LC20D8F:  INC
LC20D90:  BEQ LC20D93    ;If damage taken is none, treat as 0
LC20D92:  DEC
LC20D93:  STA $EE        ;save it in temp variable
LC20D95:  SEP #$20       ;Set 8-bit Accumulator
LC20D97:  JSR $0DDD      ;Use MP if concerns MP
LC20D9A:  LDA $11A6      ;Spell Power
LC20D9D:  STA $E8
LC20D9F:  LDA $B5
LC20DA1:  CMP #$01
LC20DA3:  BEQ LC20DAB    ;if command = item, then always use Max HP or MP
LC20DA5:  LDA $11A2
LC20DA8:  LSR
LC20DA9:  LSR
LC20DAA:  LSR
LC20DAB:  REP #$20       ;Set 16-bit Accumulator
LC20DAD:  BCS LC20DBA    ;If hit only the (dead XOR undead, then use Max HP
                         ;or MP
LC20DAF:  SEC            ;Else use current HP or MP
LC20DB0:  LDA $3BF4,Y    ;Current HP or MP
LC20DB3:  SBC $EE        ;Subtract damage already taken this strike.  relevant
                         ;for Launcher and fictional reflected spells.
LC20DB5:  BCS LC20DBD
LC20DB7:  TDC            ;if that more than depletes HP or MP, then use 0
LC20DB8:  BRA LC20DBD
LC20DBA:  LDA $3C1C,Y    ;Max HP or MP
LC20DBD:  JSR $0DCB      ;A = (Spell Power * HP or MP) / 16
LC20DC0:  PHA            ;Put on stack
LC20DC1:  PLA            ;set Zero and Negative flags based on A
                         ;ASL/ROR would be a little faster...
LC20DC2:  BNE LC20DC5
LC20DC4:  INC            ;if damage is 0, set to 1
LC20DC5:  STA $F0
LC20DC7:  PLP
LC20DC8:  PLY
LC20DC9:  PLX
LC20DCA:  RTS


;Spell Power * HP / 16
;if entered at C2/0DD1, does a more general division of a 32-bit value
;[though most callers assume it's 24-bit] by 2^(A+1).

LC20DCB:  JSR $47B7      ;24-bit $E8 = 8-bit $E8 * 16-bit A
LC20DCE:  LDA #$0003     ;will be 4 iterations to loop
LC20DD1:  PHX            ;but some callers enter here
LC20DD2:  TAX
LC20DD3:  LDA $E8        ;A = bottom two bytes of Spell Power * HP
LC20DD5:  LSR $EA        ;Cut top two bytes in half
LC20DD7:  ROR            ;do same for bottom two
LC20DD8:  DEX
LC20DD9:  BPL LC20DD5    ;Do it N+1 iterations, where N is the value
                         ;of X after C2/0DD2
LC20DDB:  PLX
LC20DDC:  RTS


;Make damage affect MP if concerns MP

LC20DDD:  LDA $11A3
LC20DE0:  BPL LC20DEC    ;Branch if not Concern MP
LC20DE2:  TYA
LC20DE3:  CLC
LC20DE4:  ADC #$14
LC20DE6:  TAY
LC20DE7:  TXA
LC20DE8:  CLC
LC20DE9:  ADC #$14
LC20DEB:  TAX
LC20DEC:  RTS


;Set $F0 to lowest of ($F0, HP/MP of drainee, Max HP/MP - HP/MP of drainer
;If bit 0 of $F2 is set, switch so attacker is drainee and target is drainer
;If bit 7 of $B2 is not set, compare only $F0 and HP/MP of drainee

LC20DED:  PHX
LC20DEE:  PHY
LC20DEF:  PHP
LC20DF0:  JSR $0DDD      ;Set to use MP if Concern MP
LC20DF3:  LDA $3414
LC20DF6:  BPL LC20E1D    ;Exit if Skip damage modification
LC20DF8:  REP #$20
LC20DFA:  LDA $F2
LC20DFC:  LSR
LC20DFD:  BCC LC20E02    ;branch if not healing target
LC20DFF:  PHX
LC20E00:  TYX
LC20E01:  PLY            ;Switch target and attacker
LC20E02:  LDA $3BF4,Y    ;Current HP or MP of drainee
LC20E05:  CMP $F0
LC20E07:  BCS LC20E0B    ;branch if HP or MP >= $F0
LC20E09:  STA $F0
LC20E0B:  LDA $B1
LC20E0D:  BPL LC20E1D    ;Branch if top bit of $B2 is clear; it's
                         ;cleared by the Drain while Seized used by
                         ;Tentacles
LC20E0F:  TXY            ;Put drainer in Y.  Why bother?  Just use
                         ;X below instead.
LC20E10:  SEC
LC20E11:  LDA $3C1C,Y    ;Max HP or MP of drainer
LC20E14:  SBC $3BF4,Y    ;Current HP or MP of drainer
LC20E17:  CMP $F0
LC20E19:  BCS LC20E1D    ;branch if difference >= $F0
LC20E1B:  STA $F0
LC20E1D:  PLP
LC20E1E:  PLY
LC20E1F:  PLX
LC20E20:  RTS


;Called if Zombie
;1 in 16 chance inflict Dark    -OR-
;1 in 16 chance inflict Poison

LC20E21:  JSR $4B5A      ;Random number 0 to 255
LC20E24:  CMP #$10
LC20E26:  BCS LC20E2C
LC20E28:  LDA #$04       ;will mark Poison status to be set
LC20E2A:  BRA LC20E32
LC20E2C:  CMP #$20
LC20E2E:  BCS LC20E20    ;Exit function
LC20E30:  LDA #$01       ;will mark Dark status to be set
LC20E32:  ORA $3DD4,Y    ;Status to set byte 1
LC20E35:  STA $3DD4,Y
LC20E38:  RTS


;Atma Weapon damage modification

LC20E39:  PHP
LC20E3A:  PHX
LC20E3B:  PHY
LC20E3C:  TXY            ;Y points to attacker
LC20E3D:  LDA $3BF5,Y    ;HP / 256
LC20E40:  INC
LC20E41:  XBA
LC20E42:  LDA $3B18,Y    ;Level
LC20E45:  JSR $4781      ;Level * ((HP / 256) + 1)
LC20E48:  LDX $3C1D,Y    ;Max HP / 256
LC20E4B:  INX
LC20E4C:  JSR $4792      ;(Level * ((HP / 256) + 1)) / ((Max HP / 256) + 1)
LC20E4F:  STA $E8        ;save modifier quotient
LC20E51:  REP #$20
LC20E53:  LDA $F0        ;load damage so far
LC20E55:  JSR $47B7      ;24-bit $E8 = modifier in 8-bit $E8 * 16-bit damage
LC20E58:  LDA #$0005
LC20E5B:  JSR $0DD1      ;Divide 24-bit Damage in $E8 by 64. [note that
                         ;calculation operates on 4 bytes]
LC20E5E:  INC            ;+1
LC20E5F:  STA $F0        ;save final damage
                         ;note that we're assuming damage fit into 16 bits,
                         ;which is true outside of hacks that give Atma
                         ;Weapon 2-hand or elemental properties.
LC20E61:  CMP #$01F5
LC20E64:  BCC LC20E73    ;branch if < 501
LC20E66:  LDX #$5B       ;put index for alternate, bigger weapon
                         ;graphic, into X
LC20E68:  CMP #$03E9
LC20E6B:  BCC LC20E6E    ;branch if < 1001
LC20E6D:  INX            ;make graphic bigger yet
LC20E6E:  STX $B7        ;save graphic index
LC20E70:  JSR $35BB      ;Update a previous entry in ($76 animation buffer
                         ;with data in $B4 - $B7)  (Changes Atma Weapon length
LC20E73:  PLY
LC20E74:  PLX
LC20E75:  PLP
LC20E76:  RTS


;Equipment Check Function (Called from other bank)

LC20E77:  PHX            ;Save X
LC20E78:  PHY
LC20E79:  PHB
LC20E7A:  PHP
LC20E7B:  SEP #$30       ;Set 8-bit Accumulator, X and Y
LC20E7D:  PHA            ;Put on stack
LC20E7E:  AND #$0F
LC20E80:  LDA #$7E
LC20E82:  PHA            ;Put on stack
LC20E83:  PLB            ;set Data Bank register to 7E
LC20E84:  PLA
LC20E85:  LDX #$3E
LC20E87:  STZ $11A0,X
LC20E8A:  DEX
LC20E8B:  BPL LC20E87    ;zero out $11A0 - $11DE
LC20E8D:  INC
LC20E8E:  XBA
LC20E8F:  LDA #$25       ;37 bytes of info per character, see Tashibana's
                         ;ff6zst.txt for details.  this block is documented as
                         ;starting at $1600, but the INC above means X is boosted
                         ;by 37 -- perhaps to avoid a negative X later -- so the
                         ;base addy is 15DB
LC20E91:  JSR $4781
LC20E94:  REP #$10       ;Set 16-bit X and Y
LC20E96:  TAX
LC20E97:  LDA $15DB,X    ;get sprite, which doubles as character index??
LC20E9A:  XBA
LC20E9B:  LDA #$16       ;22 startup bytes per character
LC20E9D:  JSR $4781
LC20EA0:  PHX
LC20EA1:  TAX            ;X indexes character startup block
LC20EA2:  LDA $ED7CAA,X  ;get character Battle Power
LC20EA6:  STA $11AC
LC20EA9:  STA $11AD      ;store it in both hands
LC20EAC:  REP #$20       ;Set 16-bit Accumulator
LC20EAE:  LDA $ED7CAB,X  ;character Defense and Magic Defense
LC20EB2:  STA $11BA
LC20EB5:  LDA $ED7CAD,X  ;character Evade and MBlock
LC20EB9:  SEP #$20       ;Set 8-bit Accumulator
LC20EBB:  STA $11A8      ;save Evade here
LC20EBE:  XBA
LC20EBF:  STA $11AA      ;save MBlock here
LC20EC2:  LDA $ED7CB5,X  ;character start level info
LC20EC6:  AND #$03
LC20EC8:  EOR #$03
LC20ECA:  INC
LC20ECB:  INC
LC20ECC:  STA $11DC      ;invert and add 2.  this gives you
                         ;5 - (bottom two bits of Level byte ,
                         ;the amount to add to the character's
                         ;"Run Success" variable.
LC20ECF:  PLX            ;X indexes into character info block again
LC20ED0:  LDY #$0006     ;point to Vigor item in character info
LC20ED3:  LDA $15F5,X
LC20ED6:  STA $11A0,Y    ;$11A6 = Vigor, 11A4 = Speed, 11A2 = Stamina,
                         ;11A0 = Mag Pwr
LC20ED9:  INX
LC20EDA:  DEY
LC20EDB:  DEY
LC20EDC:  BPL LC20ED3    ;loop 4 times
LC20EDE:  LDA $15EB,X    ;get character Status 1
LC20EE1:  STA $FE        ;save it; it'll be used for tests with Imp equip
LC20EE3:  LDY #$0005     ;point to last relic slot
LC20EE6:  LDA $15FB,X
LC20EE8:  STA $11C6,Y    ;save the item #
LC20EEC:  JSR $0F9A      ;load item data for a slot
LC20EEF:  DEX
LC20EF0:  DEY
LC20EF1:  BPL LC20EE6    ;loop for all 6 equipment+relic slots
LC20EF3:  LDA $15ED,X    ;get top byte of Maximum MP
LC20EF6:  AND #$3F       ;zero out top 2 bits, so MP can't exceed 16383
LC20EF8:  STA $FF        ;store top byte of Max MP.
                         ;Note: X would be -2 here for Character 0 had the extra
                         ;37 not been added earlier.  i don't think indexed
                         ;addressing modes are signed or allow "wrapping", so
                         ;that was a good precaution.
LC20EFA:  LDA #$40       ;first boost we will check is MP + 50%, then lower %
LC20EFC:  JSR $0F7D      ;jump off to handle % MP boosts from equipment
LC20EFF:  ORA $FF
LC20F01:  STA $15ED,X    ;store boost in highest 2 bits of MP
LC20F04:  LDA $15E9,X    ;get top byte of Maximum HP
LC20F07:  AND #$3F       ;zero out top 2 bits, so HP can't exceed 16383
LC20F09:  STA $FF        ;store top byte of Max HP
LC20F0B:  LDA #$08
LC20F0D:  JSR $0F7D      ;go check HP + 50% boost, then lower %
LC20F10:  ORA $FF
LC20F12:  STA $15E9,X    ;store boost in highest 2 bits of HP
LC20F15:  LDX #$000A
LC20F18:  LDA $11A1,X    ;did MBlock/Evade/Vigor/Speed/Stamina/MagPwr
                         ;exceed 255 with equipment boosts?
LC20F1B:  BEQ LC20F26    ;if not, look at the next stat
LC20F1D:  ASL            ;if the topmost bit of the stat is set, it's negative
                         ;thanks to horrid equipment.  so bring it up to Zero
LC20F1E:  TDC
LC20F1F:  BCS LC20F23    ;if the topmost bit wasn't set, the stat is just big
LC20F21:  LDA #$FF       ;..  in which case we bring it down to 255
LC20F23:  STA $11A0,X
LC20F26:  DEX
LC20F27:  DEX
LC20F28:  BPL LC20F18    ;loop for all aforementioned stats
LC20F2A:  LDX $11CE      ;call a function pointer depending on what
                         ;is in each hand
LC20F2D:  JSR ($0F47,X)
LC20F30:  LDA $11D7
LC20F33:  BPL LC20F42    ;if Boost Vigor bit isn't set, exit function
LC20F35:  REP #$20       ;Set 16-bit Accumulator
LC20F37:  LDA $11A6
LC20F3A:  LSR
LC20F3B:  CLC
LC20F3C:  ADC $11A6
LC20F3F:  STA $11A6      ;if Boost Vigor was set, add 50% to Vigor
LC20F42:  PLP
LC20F43:  PLB
LC20F44:  PLY
LC20F45:  PLX
LC20F46:  RTL


;Code Pointers

LC20F47: dw $0F67 ;Do nothing (shouldn't be called, as i can't get shields in both hands)
LC20F49: dw $0F61 ;2nd hand is occupied by weapon, 1st hand holds nonweapon
                  ;so 2nd hand will strike.  i.e. it retains some Battle Power
LC20F4B: dw $0F68 ;1st hand is occupied by weapon, 2nd hand holds nonweapon
                  ;so 1st hand will strike
LC20F4D: dw $0F6F ;1st and 2nd hand are both occupied by weapon
LC20F4F: dw $0F61 ;2nd hand is empty, 1st hand holds nonweapon
                  ;so 2nd hand will strike
LC20F51: dw $0F67 ;Do nothing  (filler.. shouldn't be called, contradictory 2nd hand)
LC20F53: dw $0F6B ;2nd hand is empty, 1st is occupied by weapon
                  ;(so 1st hand will strike, Gauntlet-ized if applicable)
LC20F55: dw $0F67 ;Do nothing  (filler.. shouldn't be called, contradictory 2nd hand)
LC20F57: dw $0F68 ;1st hand is empty, 2nd hand holds nonweapon
                  ;so 1st hand will strike
LC20F59: dw $0F64 ;1st hand is empty, 2nd hand occupied by weapon
                  ;so 2nd hand will strike, Gauntlet-ized if applicable
LC20F5B: dw $0F67 ;Do nothing  (filler.. shouldn't be called, contradictory 1st hand)
LC20F5D: dw $0F67 ;Do nothing  (filler.. shouldn't be called, contradictory 1st hand)
LC20F5F: dw $0F68 ;1st and 2nd hand both empty)
                  ;so might as well strike with 1st hand

;view C2/10B2 to see how the bits for each hand were set


LC20F61:  JSR $0F74
LC20F64:  STZ $11AC      ;clear Battle Power for 1st hand
LC20F67:  RTS

LC20F68:  JSR $0F74
LC20F6B:  STZ $11AD      ;clear Battle Power for 2nd hand
LC20F6E:  RTS


;NOTE: C2/0F6F is only called if you have weapons in both hands, which means that's
;the ONLY situation where the Genji Glove effect is cleared.  So you'll do full damage
;with each strike if you have two weapons, but have it reduced by 1/4 if you have zero
;or one weapon.  This is widely acknowledged as ass-backwards; common sense tells you that
;1 weapon should hardly be more cumbersome than 2...  Nor should a magic glove make
;gripping one a tall feat.

;I suspect Square was thrown by their own byte $11CF, as "set effect to be cleared"
;sounds like an oxymoron.  They were probably trying to *enable* the genji effect below
;(after all, TSB usually _does_ _enable_ things).  At least that's what my forthcoming
;patch will assume... ^__^

LC20F6F:  LDA #$10       ;Genji Glove Effect
LC20F71:  TSB $11CF      ;Sets Genji Glove effect to be cleared
LC20F74:  LDA #$40
LC20F76:  TRB $11DA      ;turn off Gauntlet effect for 1st hand
LC20F79:  TRB $11DB      ;turn off Gauntlet effect for 2nd hand
LC20F7C:  RTS


;11D5 =
;01: Raise Attack Damage         10: Raise HP by 12.5%
;02: Raise Magic Damage          20: Raise MP by 25%
;04: Raise HP by 25%             40: Raise MP by 50%
;08: Raise HP by 50%             80: Raise MP by 12.5% .  from yousei's doc)

LC20F7D:  BIT $11D5
LC20F80:  BEQ LC20F85
LC20F82:  LDA #$80       ;if bit is set, store 50% boost
LC20F84:  RTS

LC20F85:  LSR
LC20F86:  BIT $11D5
LC20F89:  BEQ LC20F8E
LC20F8B:  LDA #$40       ;if bit is set, store 25% boost
LC20F8D:  RTS

LC20F8E:  ASL
LC20F8F:  ASL
LC20F90:  BIT $11D5
LC20F93:  BEQ LC20F98
LC20F95:  LDA #$C0       ;if bit is set, store 12.5% boost
LC20F97:  RTS

LC20F98:  TDC            ;if none of the bits were set, store 0% boost
LC20F99:  RTS


;Loads item data into memory

LC20F9A:  PHX
LC20F9B:  PHY            ;Y = equip/relic slot, 0 to 5?
LC20F9C:  XBA
LC20F9D:  LDA #$1E
LC20F9F:  JSR $4781      ;multiply index by size of item data block
                         ;JSR $2B63?
LC20FA2:  TAX
LC20FA3:  LDA $D85005,X  ;field effects
LC20FA7:  TSB $11DF
LC20FAA:  REP #$20       ;Set 16-bit accumulator
LC20FAC:  LDA $D85006,X
LC20FB0:  TSB $11D2      ;status bytes 1 and 2 protection
LC20FB3:  LDA $D85008,X
LC20FB7:  TSB $11D4      ;11D4 = equipment status byte 3,
                         ;11D5 = raise attack damage, raise magic damage,
                         ;and HP and MP % boosts
LC20FBA:  LDA $D8500A,X

;battle effects 1 and "status effects 2".  latter is nothing to do with status ailments.
;11D6:
;01: Increase Preemptive Atk chance  10: Sketch -> Control
;02: Prevent Back/Pincer attacks     20: Slot -> GP Rain
;    (this won't work for battles
;     where back/pincer are forced)
;04: Fight -> Jump                   40: Steal -> Capture
;08: Magic -> X-Magic                80: Jump continuously

;11D7:
;01: Increase Steal Rate         10: 100% Hit Rate
;02: --                          20: Halve MP Consumption
;04: Increase Sketch Rate        40: Reduce MP Consumption to 1
;08: Increase Control Rate       80: Raise Vigor               .  yousei's doc)

LC20FBE:  TSB $11D6
LC20FC1:  LDA $D8500C,X  ;battle effects 2 and 3
LC20FC5:  TSB $11D8

;11D8:
;01: Fight -> X-Fight                    10: Can equip a weapon in each hand
;02: Randomly Counter Attacks            20: Wearer can equip heavy armor
;04: Increases chance of evading attack  40: Wearer protects those with low HP
;08: Attack with two hands               80:

;11D9:
;01: Casts Shell when HP is low          10: Doubles Gold received
;02: Casts Safe when HP is low           20:
;04: Casts Rflect when HP is low         40:
;08: Doubles Experience received         80: Makes body cold

LC20FC8:  LDA $D85010,X  ;Vigor+ / Speed+ / Stamina+ / MagPwr+ , by ascending address
LC20FCC:  LDY #$0006
LC20FCF:  PHA            ;Put on stack
LC20FD0:  AND #$000F     ;isolate bottom nibble
LC20FD3:  BIT #$0008     ;if top bit of stat boost is set, adjustment will be negative
LC20FD6:  BEQ LC20FDC    ;if not, branch
LC20FD8:  EOR #$FFF7     ;create a signed 16-bit negative value
LC20FDB:  INC            ;A = 65536 - bottom 3 bits.  iow, negation of
                         ;3-bit value.
LC20FDC:  CLC
LC20FDD:  ADC $11A0,Y
LC20FE0:  STA $11A0,Y    ;make adjustment to stat, ranging from -7 to +7
                         ;$11A6 = Vigor, 11A4 = Speed, 11A2 = Stamina, 11A0 = Mag Pwr
LC20FE3:  PLA
LC20FE4:  LSR
LC20FE5:  LSR
LC20FE6:  LSR
LC20FE7:  LSR            ;get next highest nibble
LC20FE8:  DEY
LC20FE9:  DEY
LC20FEA:  BPL LC20FCF    ;loop for all 4 stats
LC20FEC:  LDA $D8501A,X  ;Evade/MBlock byte in bottom of A
LC20FF0:  PHX
LC20FF1:  PHA            ;Put on stack
LC20FF2:  AND #$000F     ;isolate evade
LC20FF5:  ASL
LC20FF6:  TAX            ;evade nibble * 2, turn into pointer
LC20FF7:  LDA $C21105,X  ;get actual evade boost/reduction of item
LC20FFB:  CLC
LC20FFC:  ADC $11A8
LC20FFF:  STA $11A8      ;add it to other evade boosts
LC21002:  PLA
LC21003:  AND #$00F0     ;isolate mblock
LC21006:  LSR
LC21007:  LSR
LC21008:  LSR
LC21009:  TAX            ;mblock nibble * 2, turn into pointer
LC2100A:  LDA $C21105,X  ;get actual mblock boost/reduction of item
LC2100E:  CLC
LC2100F:  ADC $11AA
LC21012:  STA $11AA      ;add it to other mblock boosts
LC21015:  PLX
LC21016:  SEP #$20       ;Set 8-bit Accumulator
LC21018:  LDA $D85014,X  ;get weapon battle power / armor defense power
LC2101C:  XBA
LC2101D:  LDA $D85002,X  ;get top byte of equippable chars
LC21021:  ASL
LC21022:  ASL            ;carry = Specs active when Imp?
LC21023:  LDA $FE        ;Character Status Byte 1
LC21025:  BCS LC21029    ;branch if imp-activated
LC21027:  EOR #$20       ;flip Imp status
LC21029:  BIT #$20       ;character has Imp status?
LC2102B:  BNE LC21030
LC2102D:  LDA #$01       ;if you're an Imp and specs aren't Imp-activated,
                         ;defense/battle power = 1.  or if you're not an Imp
                         ;and the specs are Imp-activated, battle/defense
                         ;power = 1
LC2102F:  XBA
LC21030:  XBA            ;if imp-activation and imp status match, put the
                         ;original Battle/Defense Power back in bottom of A

;note that Item #255 has a Battle Power of 10, so bare hands will actually be
; stronger than Imp Halberd on a non-Imp)

LC21031:  STA $FD
LC21033:  LDA $D85000,X  ;item type
LC21037:  AND #$07       ;isolate classification
LC21039:  DEC
LC2103A:  BEQ LC210B2    ;if it's a weapon, branch and load its data
LC2103C:  LDA $D85019,X
LC21040:  TSB $11BC      ;equipment status byte 2
LC21043:  LDA $D8500F,X  ;50% resist elements
LC21047:  XBA
LC21048:  LDA $D85018,X  ;weak to elements
LC2104C:  REP #$20       ;Set 16-bit Accumulator
LC2104E:  TSB $11B8      ;bottom = weak elements, top = 50% resist elements
LC21051:  LDA $D85016,X
LC21055:  TSB $11B6      ;bottom = absorbed elements, top = nullified elements
LC21058:  SEP #$20       ;Set 8-bit Accumulator
LC2105A:  CLC
LC2105B:  LDA $FD        ;get equipment Defense Power
LC2105D:  ADC $11BA      ;add it into Defense so far
LC21060:  BCC LC21064
LC21062:  LDA #$FF
LC21064:  STA $11BA      ;if defense exceeds 255, make it 255
LC21067:  CLC
LC21068:  LDA $D85015,X  ;get equipment Magic Defense
LC2106C:  ADC $11BB      ;add it into MagDef so far
LC2106F:  BCC LC21073
LC21071:  LDA #$FF
LC21073:  STA $11BB      ;if magic defense exceeds 255, make it 255
LC21076:  PLY
LC21077:  LDA #$02
LC21079:  TRB $11D5      ;clear "raise magic damage" bit in Item Bonuses --
                         ;raise fight, raise magic, HP + %, MP + %
LC2107C:  BEQ LC21086
LC2107E:  TSB $11D7      ;if Earring effect is set in current equipment slot, set
                         ;it in Item Special 2:
                         ;boost steal, single Earring, boost sketch, boost control,
                         ;sniper sight, gold hairpin, economizer, vigor + 50%
LC21081:  BEQ LC21086
LC21083:  TSB $11D5      ;if Earring effect had also been set by other equipment
                         ;slots, set it again in item bonuses, where it will actually
                         ;represent _double_ Earring, even though the initial data
                         ;byte would have it set even for a lone Earring
                         ;if all this crazy bit swapping seems convuluted, keep in
                         ;mind that $11D5 isn't RELOADED for each equipment slot
                         ;it's ADDED to via the TSB at C2/0FB7.  thus, we must clear
                         ;the Earring bit in $11D5 for each of the 6 equip slots if
                         ;we wish to see whether the CURRENT slot gives us the
                         ;Earring effect.

LC21086:  TDC
LC21087:  LDA $D8501B,X  ;item byte 1B, special action
LC2108B:  STA $11BE,Y
LC2108E:  BIT #$0C       ;shield animation for blocked physical/magic attacks
                         ;or weapon parry
LC21090:  BEQ LC210B0    ;if none of above, branch
LC21092:  PHA            ;save old Byte 1B
LC21093:  AND #$03       ;isolate bottom 2 bits.  for a given item:
                         ;bit 0 = big weapon parry anim.
                         ;bit 1 = "any" shield block, all except cursed shld.
                         ;both = zephyr cape.  neither = small weapon parry.
                         ;bit 2 = physical block: shield, weapon parry, or zephyr cape
                         ;bit 3 = magical shield block.  shields only?

LC21095:  TAX            ;put Acc in X.  Following loop gives us 2^X
LC21096:  TDC            ;clear Acc
LC21097:  SEC            ;set carry flag
LC21098:  ROL            ;rotate carry into lowest bit of Acc
LC21099:  DEX            ;decrement X, which was 0-3
LC2109A:  BPL LC21098    ;loop if X >= 0
LC2109C:  XBA
LC2109D:  PLA            ;retrieve item byte 1B
LC2109E:  BIT #$04
LC210A0:  BEQ LC210A7    ;branch if physical block animation not set
LC210A2:  XBA
LC210A3:  TSB $11D0      ;if one of above was set, store our 2^X value
LC210A6:  XBA
LC210A7:  BIT #$08
LC210A9:  BEQ LC210B0    ;if no magic attack block for shield, branch
LC210AB:  XBA
LC210AC:  TSB $11D1      ;if there was, store our 2^X value
LC210AF:  XBA
LC210B0:  PLX
LC210B1:  RTS


;Load weapon properties from an arm slot

LC210B2:  TDC
LC210B3:  INC
LC210B4:  TAY            ;Y = 1
LC210B5:  INC            ;Accumulator = 2
LC210B6:  STA $FF
LC210B8:  LDA $01,S      ;equipment/relic slot - 0 to 5
LC210BA:  CMP #$02
LC210BC:  BCS LC21076    ;if it's not slot 0 or 1, one of the arms, return
                         ;to caller
LC210BE:  DEC
LC210BF:  BEQ LC210C4    ;if it was slot 1, branch
LC210C1:  DEY            ;point to slot 0
LC210C2:  ASL $FF        ;$FF = 4
LC210C4:  LDA $11C6,Y    ;get item # from the slot
LC210C7:  INC
LC210C8:  BNE LC210CE    ;if the item is not Empty #255, branch
LC210CA:  ASL $FF
LC210CC:  ASL $FF
LC210CE:  LDA $FF        ;$FF = 2 if this is 2nd hand and it's occupied by weapon,
                         ;4 if this is 1st hand and it's occupied by weapon,
                         ;8 if this is 2nd hand and it's empty,
                         ;16 if this is 1st hand and it's empty.
                         ;And $FF is never set if the hand holds a nonweapon
LC210D0:  TSB $11CE      ;turn on the current $FF bit in $11CE, which
                         ;will hold info about both hands
LC210D3:  LDA $D85016,X
LC210D7:  STA $11B2,Y
LC210DA:  LDA $D8500F,X  ;elemental properties
LC210DE:  STA $11B0,Y
LC210E1:  LDA $FD        ;get equipment Battle Power
LC210E3:  ADC $11AC,Y    ;add it to Battle Power so far
LC210E6:  BCC LC210EA
LC210E8:  LDA #$FF
LC210EA:  STA $11AC,Y    ;if the Battle Power exceeded 255, make it 255
LC210ED:  LDA $D85015,X  ;hit rate
LC210F1:  STA $11AE,Y
LC210F4:  LDA $D85012,X  ;random weapon spellcast
LC210F8:  STA $11B4,Y
LC210FB:  LDA $D85013,X  ;weapon properties
LC210FF:  STA $11DA,Y    ;11DA=

;                        01:          10: --
;                        02: SwdTech             20: Same damage from back row
;                        04: --                  40: 2-Hand
;                        08: --                  80: Runic)

LC21102:  JMP $1076


;Data - Evade and Mblock Boosts/Reductions

LC21105: dw $0000   ;0
LC21107: dw $000A   ;+10
LC21109: dw $0014   ;+20
LC2110B: dw $001E   ;+30
LC2110D: dw $0028   ;+40
LC2110F: dw $0032   ;+50
LC21111: dw $FFF6   ;-10
LC21113: dw $FFEC   ;-20
LC21115: dw $FFE2   ;-30
LC21117: dw $FFD8   ;-40
LC21119: dw $FFCE   ;-50


;Called every frame

LC2111B:  PHP
LC2111C:  SEP #$30       ;Set 8-bit A, X, & Y
LC2111E:  JSR $4D1F      ;Handle player-confirmed commands
LC21121:  LDA $2F41      ;are we in a menu?
LC21124:  AND $3A8F      ;is Config set to wait battle?
LC21127:  BNE LC2118B    ;Exit function if both
LC21129:  LDA $3A6C      ;get backup frame counter
LC2112C:  LDX #$02
LC2112E:  CMP $0E        ;compare to current frame counter?
LC21130:  BEQ LC21190    ;Exit function if $3A6C = $000E.  Doing this check
                         ;twice serves to exit if the function was already
                         ;called the current frame [which i don't think ever
                         ;happens] or if it was called last frame.
LC21132:  INC
LC21133:  DEX
LC21134:  BNE LC2112E    ;Check and exit if $3A6C + 1 = $000E
LC21136:  INC $3A3E      ;Increment battle time counter
LC21139:  BNE LC2113E
LC2113B:  INC $3A3F      ;Increment battle time counter
LC2113E:  JSR $5A83      ;Handles various time-based events for entities.
                         ;Advances their timers, does periodic damage/healing
                         ;from Poison/Regen/etc., checks for running, and more.
LC21141:  LDX #$12
LC21143:  CPX $3EE2      ;Is this target Morphed?
LC21146:  BNE LC2114B    ;Branch if not
LC21148:  JSR $1211      ;Do morph timer decrement
LC2114B:  LDA $3AA0,X
LC2114E:  LSR
LC2114F:  BCC LC21184    ;If entity not present in battle, branch to next one
LC21151:  CPX $33F8      ;Has this target used Zinger?
LC21154:  BEQ LC21184    ;If it has, branch to next target
LC21156:  BIT #$3A
LC21158:  BNE LC21184    ;If any of bits 6, 5, 4, or 2 are set in $3AA0,X ,
                         ;branch to next target
LC2115A:  BIT #$04
LC2115C:  BEQ LC2117C    ;If bit 3 isn't set in $3AA0,X , branch to load
                         ;this target's ATB
LC2115E:  LDA $2F45      ;party trying to run: 0 = no, 1 = yes
LC21161:  BEQ LC21179    ;If no one is trying to run, branch to Advance Wait Timer
                         ;function
LC21163:  LDA $3EE4,X
LC21166:  BIT #$02       ;Check for Zombie Status
LC21168:  BNE LC21179    ;If zombie, branch to Advance Wait Timer function
LC2116A:  LDA $3018,X
LC2116D:  BEQ LC21179    ;If monster, branch to Advance Wait Timer function
LC2116F:  BIT $3F2C
LC21172:  BNE LC21179    ;If jumping, branch to Advance Wait Timer function
LC21174:  BIT $3A40
LC21177:  BEQ LC2117C    ;If not character acting as an enemy, skip Advance
                         ;Wait Timer function
LC21179:  JSR $1193      ;Advance Wait Timer function
LC2117C:  LDA $3219,X    ;Load top byte of this target's ATB counter
LC2117F:  BEQ LC21184    ;If it's 0, branch to next target
LC21181:  JSR $11BB
LC21184:  DEX
LC21185:  DEX
LC21186:  BPL LC21143    ;Loop if targets remaining
LC21188:  JSR $5C54      ;Copy ATB timer, Morph gauge, and Condemned counter to
                         ;displayable variables
LC2118B:  LDA $0E
LC2118D:  STA $3A6C      ;copy current frame counter to backup frame counter?
LC21190:  TDC
LC21191:  PLP
LC21192:  RTL


;Advance Wait Timer.  This is what controls how long a character
; spends in his or her "ready stance" before executing a move.)

LC21193:  REP #$20       ;16-bit accumulator
LC21195:  LDA $3AC8,X    ;amount to increase ATB timer by
LC21198:  LSR            ;div by 2
LC21199:  CLC
LC2119A:  ADC $3AB4,X
LC2119D:  STA $3AB4,X    ;add to Wait Timer
LC211A0:  SEP #$20       ;8-bit accumulator
LC211A2:  BCS LC211AA    ;if that timer overflowed, branch
LC211A4:  XBA            ;get top byte of the timer
LC211A5:  CMP $322C,X    ;compare to time to wait after inputting
                         ;a command
LC211A8:  BCC LC211BA    ;if it's less, we're not ready yet
LC211AA:  LDA #$FF
LC211AC:  STA $322C,X
LC211AF:  JSR $4E77      ;put entity in action queue
LC211B2:  LDA #$20
LC211B4:  ORA $3AA0,X    ;many other functions can enter here to set
                         ;other bits
LC211B7:  STA $3AA0,X    ;set bit 5
LC211BA:  RTS


LC211BB:  REP #$21
LC211BD:  LDA $3218,X    ;current ATB timer count
LC211C0:  ADC $3AC8,X    ;amount to increase timer by
LC211C3:  STA $3218,X    ;save updated timer
LC211C6:  SEP #$20
LC211C8:  BCC LC211BA    ;if timer didn't pass 0, exit
LC211CA:  CPX #$08
LC211CC:  BCS LC211D1    ;branch if a monster
LC211CE:  JSR $5BE2
LC211D1:  STZ $3219,X    ;zero top byte of ATB Timer
LC211D4:  STZ $3AB5,X    ;zero top byte of Wait Timer
LC211D7:  LDA #$FF
LC211D9:  STA $322C,X
LC211DC:  LDA #$08
LC211DE:  BIT $3AA0,X
LC211E1:  BNE LC211EA
LC211E3:  JSR $11B4
LC211E6:  BIT #$02
LC211E8:  BEQ LC2120E
LC211EA:  LDA #$80
LC211EC:  JSR $11B4
LC211EF:  CPX #$08
LC211F1:  BCS LC2120E
LC211F3:  LDA $3205,X
LC211F6:  BPL LC211BA    ;Exit function if entity has not taken a conventional
                         ;turn [including landing one] since boarding Palidor
LC211F8:  LDA $B1
LC211FA:  BMI LC211BA    ;Exit function
LC211FC:  LDA #$04
LC211FE:  JSR $11B4
LC21201:  LDA $3E4D,X    ;Bit 0 is set on entity who's Controlling another.
                         ;this is an addition in FF3us to prevent a bug caused
                         ;by Ripplering off the "Spell Chant" status.
LC21204:  LSR
LC21205:  TXA
LC21206:  ROR
LC21207:  STA $10
LC21209:  LDA #$02
LC2120B:  JMP $6411

LC2120E:  JMP $4E66      ;put entity in wait queue


;Decrease Morph timer.  If it's run out, zero related Morph variables,
; and queue the Revert command.)

LC21211:  REP #$20       ;Set 16-bit Accumulator
LC21213:  SEC
LC21214:  LDA $3F30      ;Load the morph timer
LC21217:  SBC $3F32      ;Subtract morph decrement amount
LC2121A:  STA $3F30      ;Save the new morph timer
LC2121D:  SEP #$20       ;Set 8-bit Accumulator
LC2121F:  BCS LC21234    ;Branch if it's greater than zero
LC21221:  STZ $3F31      ;zero top byte of Morph timer.  i assume we're
                         ;neglecting to zero $3F30 just to avoid adding a
                         ;"REP" instruction.
LC21224:  JSR $0B36      ;adjust Morph supply [in this case, zero it]
                         ;to match our new Morph timer
LC21227:  LDA #$FF
LC21229:  STA $3EE2      ;Store #$FF to Morphed targets byte [no longer have a
                         ;Morphed target]
LC2122C:  LDA #$04
LC2122E:  STA $3A7A      ;Store Revert as command
LC21231:  JSR $4EB2      ;queue it, in entity's counterattack and periodic
                         ;damage/healing queue
LC21234:  LDA $3F31      ;Load the remaining amount of morph time DIV 256, if any
LC21237:  STA $3B04,X    ;Store it to the character's Morph gauge
;Why do we bother zeroing all these timers and variables here when the forthcoming
; Revert can handle it?  Presumably to avoid gauge screwiness and a bunch of pointless
; calls to this function should Terra's Morph timer run down in the middle of an attack
; animation..)
LC2123A:  RTS


;True Knight and Love Token

LC2123B:  PHX
LC2123C:  PHP
LC2123D:  LDA $B2
LC2123F:  BIT #$0002     ;Is "No critical and Ignore True Knight" set?
LC21242:  BNE LC212A5    ;Exit if so
LC21244:  LDA $B8        ;intended target(s.  to my knowledge, there's only one
                         ;intended target set if we call this function..
LC21246:  BEQ LC212A5    ;Exit if none
LC21248:  LDY #$FF
LC2124A:  STY $F4        ;default to no bodyguards.
LC2124C:  JSR $51F9      ;Y = index of our highest intended target.
                         ;0, 2, 4, or 6 for characters.  8, 10, 12, 14, 16, or 18
                         ;for monsters.
LC2124F:  STY $F8        ;save target index
LC21251:  STZ $F2        ;Highest Bodyguard HP So Far = 0.  this makes
                         ;the first eligible bodyguard we check get accepted.
                         ;later ones may replace him/her if they have more HP.
LC21253:  PHX
LC21254:  LDX $336C,Y    ;Love Token - which target takes damage for you
LC21257:  BMI LC2125F    ;Branch if none do
LC21259:  JSR $12C0      ;consider this target as a bodyguard
LC2125C:  JSR $12A8      ;if it was valid, make it intercept the attack
LC2125F:  PLX
LC21260:  LDA $3EE4,Y
LC21263:  BIT #$0200
LC21266:  BEQ LC212A5    ;Branch if target not Near Fatal
LC21268:  BIT #$0010
LC2126B:  BNE LC212A5    ;Branch if Clear
LC2126D:  LDA $3358,Y    ;$3359 = who is Seizing you
LC21270:  BPL LC212A5    ;Branch if target is seized
LC21272:  LDA #$000F     ;Load all characters as potential bodyguards
LC21275:  CPY #$08
LC21277:  BCC LC2127C    ;Branch if target is character
LC21279:  LDA #$3F00     ;Load all monsters as potential bodyguards instead
LC2127C:  STA $F0        ;Save potential bodyguards
LC2127E:  LDA $3018,Y    ;bit representing target) (was typoed as "LDA $3018,X"
LC21281:  ORA $3018,X    ;bit representing attacker
LC21284:  TRB $F0        ;Clear attacker and target from potential bodyguards
LC21286:  LDX #$12
LC21288:  LDA $3C58,X
LC2128B:  BIT #$0040
LC2128E:  BEQ LC2129A    ;Branch if no True Knight effect
LC21290:  LDA $3018,X
LC21293:  BIT $F0
LC21295:  BEQ LC2129A    ;Branch if this candidate isn't on the same
                         ;team as the target
LC21297:  JSR $12C0      ;consider them as candidate bodyguard.  if they're
                         ;valid and their HP is >= past valid candidates,
                         ;they become the new frontrunner.
LC2129A:  DEX
LC2129B:  DEX
LC2129C:  BPL LC21288    ;Do for all characters and monsters
LC2129E:  LDA $F2
LC212A0:  BEQ LC212A5    ;Exit if no bodyguard found [or if the selfless
                         ;soul has 0 HP, which shouldn't be possible outside
                         ;of bugs].
LC212A2:  JSR $12A8      ;make chosen bodyguard -- provided there was one --
                         ;intercept attack.  if somebody's already been slated
                         ;to intercept it [i.e. due to Love Token], the True
                         ;Knight will sensibly defer to them.
LC212A5:  PLP
LC212A6:  PLX
LC212A7:  RTS


;Make chosen bodyguard intercept attack, provided one hasn't been
; marked to do so already.)

LC212A8:  LDX $F4
LC212AA:  BMI LC212BF    ;exit if no bodyguard found
LC212AC:  CPY $F8
LC212AE:  BNE LC212BF    ;exit if $F8 no longer points to the original target,
                         ;which means we've already assigned a bodyguard with
                         ;this function.
LC212B0:  STX $F8        ;save bodyguard's index
LC212B2:  STY $A8        ;save intended target's index
LC212B4:  LSR $A8        ;.. but for the latter, use 0,1,2,etc rather
                         ;than 0,2,4,etc
LC212B6:  PHP
LC212B7:  REP #$20       ;set 16-bit A
LC212B9:  LDA $3018,X
LC212BC:  STA $B8        ;save bodyguard as the new target of attack
LC212BE:  PLP
LC212BF:  RTS


;Consider candidate bodyguard for True Knight or Love Token

LC212C0:  PHP
LC212C1:  REP #$20       ;Set 16-bit Accumulator
LC212C3:  LDA $3AA0,X
LC212C6:  LSR
LC212C7:  BCC LC212F3    ;Exit function if entity not present in battle?
LC212C9:  LDA $32B8,X    ;$32B9 = who is Controlling you
LC212CC:  BPL LC212F3    ;Exit if you're controlled
LC212CE:  LDA $3358,X    ;$3359 = who is Seizing you
LC212D1:  BPL LC212F3    ;Exit if you're Seized
LC212D3:  LDA $3EE4,X
LC212D6:  BIT #$A0D2     ;Death, Petrify, Clear, Zombie, Sleep, Muddled
LC212D9:  BNE LC212F3    ;Exit if any set
LC212DB:  LDA $3EF8,X
LC212DE:  BIT #$3210     ;Stop, Freeze, Spell Chant, Hide
LC212E1:  BNE LC212F3    ;Exit if any set
LC212E3:  LDA $3018,X
LC212E6:  TSB $A6        ;make this potential guard jump in front of the
                         ;target, can accompany others
LC212E8:  LDA $3BF4,X    ;HP of this potential bodyguard
LC212EB:  CMP $F2
LC212ED:  BCC LC212F3    ;branch if it's not >= the highest HP of the
                         ;other bodyguards considered so far for this attack.
LC212EF:  STA $F2        ;if it is, save this entity's HP as the highest
                         ;HP so far.
LC212F1:  STX $F4        ;and this entity becomes the new bodyguard.
LC212F3:  PLP
LC212F4:  RTS


;Do HP or MP Damage/Healing to an entity

LC212F5:  PHX
LC212F6:  PHP
LC212F7:  LDX #$02
LC212F9:  LDA $11A2
LC212FC:  BMI LC21300    ;Branch if concerns MP
LC212FE:  LDX #$00
LC21300:  JSR ($131F,X)  ;Deal damage and/or healing
LC21303:  SEP #$20       ;Set 8-bit Accumulator
LC21305:  BCC LC2131C    ;Branch if no damage done to target, or
                         ;if healing done on same strike matched
                         ;or exceeded damage
LC21307:  LDA $02,S      ;get attacker
LC21309:  TAX            ;save in X
LC2130A:  STX $EE        ;and in a RAM variable, too
LC2130C:  JSR $362F      ;Mark entity X as the last attacker of entity Y,
                         ;unless Y already has an attacker this turn.  Set flag
                         ;indicating that entity Y was attacked this turn, and
                         ;this might be the lone context where doing so isn't
                         ;arbitrary.
LC2130F:  CPY $EE        ;does target == attacker?
LC21311:  BEQ LC2131C    ;branch if so
LC21313:  STA $327C,Y    ;save attacker [original, not any reflector] in byte
                         ;that's used by FC 05 script command
LC21316:  LDA $3018,Y
LC21319:  TRB $3419      ;indicate target as being damaged [by an
                         ;attacker other than themselves] this turn.
                         ;will be used by Black Belt function.
LC2131C:  PLP
LC2131D:  PLX
LC2131E:  RTS


;Code pointers

LC2131F: dw $1323     ;HP damage
LC21321: dw $1350     ;MP damage


;Deal HP Damage/Healing
;Returns in Carry:
; Set if damage done to target, and damage exceeds any healing done on same strike.
; Clear if damage not done to target, or if healing done on same strike matches
; or exceeds it.)

LC21323:  JSR $13A7      ;Returns Damage Healed - Damage Taken
LC21326:  BEQ LC2133B    ;Exit function if 0 damage [damage = healing]
LC21328:  BCC LC2133D    ;If Damage > Healing, deal HP damage
LC2132A:  CLC            ;Otherwise, deal HP healing
LC2132B:  ADC $3BF4,Y    ;Add to HP
LC2132E:  BCS LC21335
LC21330:  CMP $3C1C,Y
LC21333:  BCC LC21338
LC21335:  LDA $3C1C,Y    ;If over Max HP, set to Max HP
LC21338:  STA $3BF4,Y
LC2133B:  CLC
LC2133C:  RTS


LC2133D:  EOR #$FFFF
LC21340:  STA $EE        ;65535 - [Healing - Damage].  This gives us the
                         ;Net Damage minus 1, and that 1 is cancelled out
                         ;by the SBC below, which is done with Carry clear.
LC21342:  LDA $3BF4,Y
LC21345:  SBC $EE        ;Subtract damage from HP
LC21347:  STA $3BF4,Y
LC2134A:  BEQ LC21390    ;branch if 0 HP
LC2134C:  BCS LC2133C    ;Exit If > 0 HP
LC2134E:  BRA LC21390    ;If < 0 HP


;Deal MP Damage/Healing
;Returns in Carry:
; Set if damage done to target, and damage exceeds any healing done on same strike.
; Clear if damage not done to target, or if healing done on same strike matches
; or exceeds it.)

LC21350:  JSR $13A7      ;Returns Damage Healed - Damage Taken
LC21353:  BEQ LC2133B    ;Exit function if 0 damage [damage = healing]
LC21355:  BCC LC2136B    ;If Damage > Healing, deal MP damage
LC21357:  CLC            ;Otherwise, deal MP healing
LC21358:  ADC $3C08,Y    ;Add A to MP
LC2135B:  BCS LC21362
LC2135D:  CMP $3C30,Y
LC21360:  BCC LC21365
LC21362:  LDA $3C30,Y    ;If result over Max MP, set Current MP to Max MP
LC21365:  STA $3C08,Y
LC21368:  CLC
LC21369:  BRA LC2138A

LC2136B:  EOR #$FFFF
LC2136E:  STA $EE        ;65535 - [Healing - Damage].  This gives us the
                         ;Net Damage minus 1, and that 1 is cancelled out
                         ;by the SBC below, which is done with Carry clear.
LC21370:  LDA $3C08,Y
LC21373:  SBC $EE
LC21375:  STA $3C08,Y    ;Subtract from MP
LC21378:  BEQ LC2137C    ;branch if MP = 0
LC2137A:  BCS LC2138A    ;branch if MP > 0
LC2137C:  TDC            ;If it's less than 0,
LC2137D:  STA $3C08,Y    ;Store 0 in MP
LC21380:  LDA $3C95,Y
LC21383:  LSR
LC21384:  BCC LC21389    ;Branch if not Die at 0 MP
LC21386:  JSR $1390      ;Call lethal damage function if Dies at 0 MP
LC21389:  SEC
LC2138A:  LDA #$0080
LC2138D:  JMP $464C


;If character/monster takes lethal damage

LC21390:  SEC
LC21391:  TDC            ;Clear accumulator
LC21392:  TAX
LC21393:  STX $3A89      ;turn off random weapon spellcast
LC21396:  STA $3BF4,Y    ;Set HP to 0
LC21399:  LDA $3EE4,Y
LC2139C:  BIT #$0002
LC2139F:  BNE LC2133C    ;Exit function if Zombie
LC213A1:  LDA #$0080
LC213A4:  JMP $0E32      ;Sets $3DD4 for death status


;Returns Damage Healed - Damage Taken

LC213A7:  LDA $33D0,Y    ;Damage Taken
LC213AA:  INC
LC213AB:  BEQ LC213BC    ;If no damage, branch and save damage as 0
LC213AD:  LDA $3018,Y
LC213B0:  BIT $3A3C
LC213B3:  BEQ LC213B9    ;Branch if not invincible
LC213B5:  TDC
LC213B6:  STA $33D0,Y    ;Set damage to 0
LC213B9:  LDA $33D0,Y
LC213BC:  STA $EE
LC213BE:  LDA $3A81
LC213C1:  AND $3A82
LC213C4:  BMI LC213C8    ;Branch if no Golem or dog block
LC213C6:  STZ $EE        ;Set damage to 0
LC213C8:  LDA $33E4,Y    ;Damage Healed
LC213CB:  INC
LC213CC:  BEQ LC213CF    ;If no healing, branch and treat healing as 0
LC213CE:  DEC            ;get healing amount again
LC213CF:  SEC
LC213D0:  SBC $EE        ;Subtract damage
LC213D2:  RTS


;Character/Monster Takes One Turn

LC213D3:  PHX
LC213D4:  PHP
LC213D5:  JSR $2639      ;Clear animation buffer pointers, extra strike
                         ;quantity, and various backup targets
LC213D8:  LDA #$10
LC213DA:  TSB $B0        ;related to characters stepping forward and
                         ;getting circular or triangular pattern around
                         ;them when casting Magic or Lores.
LC213DC:  LDA #$06
LC213DE:  STA $B4
LC213E0:  STZ $BD        ;zero turn-wide Damage Incrementor
LC213E2:  STZ $3A89      ;disable weapon addition magic
LC213E5:  STZ $3EC9      ;Set # of targets to zero
LC213E8:  STZ $3A8E      ;disable Continuous Jump
LC213EB:  TXY
LC213EC:  LDA #$FF
LC213EE:  STA $B2
LC213F0:  STA $B3
LC213F2:  LDX #$0F
LC213F4:  STA $3410,X    ;$3410 - $341F = FFh
LC213F7:  DEX
LC213F8:  BPL LC213F4
LC213FA:  LDA $B5        ;Load command
LC213FC:  ASL
LC213FD:  TAX
LC213FE:  JSR ($19C7,X)  ;Execute command
LC21401:  LDA #$FF
LC21403:  STA $3417      ;indicate null Sketcher/Sketchee.  not sure why
                         ;this is needed, given the C2/13F4 loop.
LC21406:  JSR $629B      ;Copy A to $3A28, and copy $3A28-$3A2B variables
                         ;into ($76) buffer
LC21409:  JSR $069B      ;Do various responses to three mortal statuses
LC2140C:  JSR $4C5B      ;prepare any applicable counterattacks
LC2140F:  JSR $1429      ;Remove dead-ish enemies from list of remaining
                         ;enemies, if Piranha or other conditions met
LC21412:  LDA #$04
LC21414:  JSR $6411      ;Execute animation queue
LC21417:  JSR $4AB9      ;Update lists and counts of present and/or living
                         ;characters and monsters
LC2141A:  JSR $147A      ;Place marked entities in $2F4E on battlefield
LC2141D:  JSR $083F
LC21420:  JSR $144F      ;Remove marked entities in $2F4C from battlefield
LC21423:  JSR $62C7      ;Add Stolen or Metamorphed item to a temporary
                         ;$602D-$6031 [plus offset] buffer.  Also, add back
                         ;an item used via Equipment Magic if the item isn't
                         ;destroyed upon use [no equipment in the game works
                         ;that way, but it's fully possible].
                         ;then _that_ buffer gets added to Item menu by
                         ;having the triangle cursor switch onto a new
                         ;character, or if that somehow doesn't happen, then
                         ;at end of battle.
LC21426:  PLP
LC21427:  PLX
LC21428:  RTS


;Remove dead-ish enemies from list of remaining enemies, provided that: they have no
; counterattack or periodic damage/healing queued, they are Hidden, or they are Piranha)

LC21429:  LDX #$0A
LC2142B:  LDA $3021,X
LC2142E:  BIT $3A3A      ;is it in list of dead-ish enemies?
LC21431:  BEQ LC2144A    ;branch to next monster if not
LC21433:  XBA
LC21434:  LDA $3F01,X    ;normally accessed as $3EF9,X
LC21437:  BIT #$20
LC21439:  BNE LC21446    ;branch if Hide status
LC2143B:  LDA $3E54,X    ;normally accessed as $3E4C,X
LC2143E:  BMI LC21446    ;branch if some custom flag is set, which only
                         ;Piranha has.  the other effect of this
                         ;status byte-derived property is to give removable
                         ;Float, which i always thought pointless, given
                         ;Piranha also has permanent Float.
LC21440:  LDA $32D5,X    ;normally accessed as $32CD,X.  get entry point into
                         ;this entity's counterattack or periodic
                         ;damage/healing linked list queue.
LC21443:  INC
LC21444:  BNE LC2144A    ;branch if value wasn't a null FFh.  i.e. branch if
                         ;entity has a counterattack or periodic damage/healing
                         ;queued.
LC21446:  XBA
LC21447:  TRB $2F2F      ;remove from bitfield of remaining enemies?
LC2144A:  DEX
LC2144B:  DEX
LC2144C:  BPL LC2142B    ;iterate for all 6 monsters
LC2144E:  RTS


;Remove marked entities in $2F4C from battlefield

LC2144F:  PHP
LC21450:  REP #$20       ;Set 16-bit Accumulator
LC21452:  LDX #$12
LC21454:  LDA $3018,X
LC21457:  TRB $2F4C      ;clear flag marking entity to be removed from
                         ;battlefield
LC2145A:  BEQ LC21474    ;branch if it hadn't been set
LC2145C:  SEP #$20       ;Set 8-bit Accumulator
LC2145E:  XBA
LC2145F:  TRB $2F2F      ;if enemy, clear it from bitfield of remaining
                         ;enemies?
LC21462:  LDA #$FE
LC21464:  JSR $0792      ;clear Bit 0 of $3AA0,X , indicating that entity
                         ;is absent
LC21467:  LDA $3EF9,X
LC2146A:  ORA #$20
LC2146C:  STA $3EF9,X    ;Set Hide status
LC2146F:  JSR $07C8      ;Clear Zinger, Love Token, and Charm bonds, and
                         ;clear applicable Quick variables
LC21472:  REP #$20
LC21474:  DEX
LC21475:  DEX
LC21476:  BPL LC21454    ;iterate for all 10 entities
LC21478:  PLP
LC21479:  RTS


;Place marked entities in $2F4E on battlefield, and remove any terminal ailments
; or Imp status they may have)

LC2147A:  PHP
LC2147B:  REP #$20       ;Set 16-bit Accumulator
LC2147D:  LDX #$12
LC2147F:  LDA $3018,X
LC21482:  TRB $2F4E      ;clear flag
LC21485:  BEQ LC214A7    ;branch if entity hadn't been marked to enter
                         ;battlefield
LC21487:  SEP #$20       ;Set 8-bit Accumulator
LC21489:  XBA
LC2148A:  TSB $2F2F      ;if enemy, mark it in bitfield of remaining
                         ;enemies?
LC2148D:  LDA #$01
LC2148F:  JSR $11B4      ;set Bit 0 of $3AA0,X , which indicates that
                         ;entity is present
LC21492:  LDA $3EE4,X
LC21495:  AND #$1D
LC21497:  STA $3EE4,X    ;Clear Zombie, Imp, Petrify, Death
LC2149A:  LDA $3EF9,X
LC2149D:  AND #$DF
LC2149F:  STA $3EF9,X    ;Clear Hide
LC214A2:  JSR $2DA0      ;Handle "Attack First" property for monster.
                         ;And make Carry Flag match the property's state
                         ;[it will be clear for characters].
LC214A5:  REP #$20
LC214A7:  DEX
LC214A8:  DEX
LC214A9:  BPL LC2147F    ;iterate for all 10 entities
LC214AB:  PLP
LC214AC:  RTS


;Check if hitting target(s in back

LC214AD:  LDA $11A2
LC214B0:  LSR
LC214B1:  BCC LC21511    ;Exit function if magical damage
LC214B3:  CPX #$08
LC214B5:  BCS LC214E5    ;Branch if monster attacker
LC214B7:  LDA $201F      ;get encounter type:  0 = front, 1 = back,
                         ;2 = pincer, 3 = side
LC214BA:  CMP #$03
LC214BC:  BNE LC21511    ;Exit function if not Side attack
LC214BE:  LDA $3018,X    ;Holds $01 for character 1, $02 for character 2,
                         ;$04 for character 3, $08 for character 4
LC214C1:  AND $2F50      ;bitfield of which way all the characters face
LC214C4:  STA $EE        ;will be default of 0 if character attacker faces left,
                         ;nonzero if they face right
LC214C6:  LDY #$0A
LC214C8:  LDA $EE
LC214CA:  XBA            ;save attacking character's direction variable
LC214CB:  LDA $3021,Y    ;Holds $01 for monster 1, $02 for monster 2,
                         ;$04 for monster 3, etc.  Note we'd normally access this
                         ;as $3019; $3021 is an adjustment for the loop iterator.
LC214CE:  BIT $2F51      ;bitfield of which way all the monsters face
LC214D1:  BEQ LC214D8    ;branch if this monster faces left
LC214D3:  XBA
LC214D4:  EOR $3018,X    ;A = reverse of attacking character's direction
LC214D7:  XBA
LC214D8:  XBA
LC214D9:  BNE LC214DF    ;branch if the character and monster are facing
                         ;each other
LC214DB:  XBA            ;get $3021,Y
LC214DC:  TSB $3A55      ;so we'll turn on this monster's bit if the
                         ;attacking character is facing their back
LC214DF:  DEY
LC214E0:  DEY
LC214E1:  BPL LC214C8    ;loop for all 6 monsters
LC214E3:  BRA LC21511    ;Exit Function


LC214E5:  LDA $201F      ;get encounter type: 0 = front, 1 = back,
                         ;2 = pincer, 3 = side
LC214E8:  CMP #$02
LC214EA:  BNE LC21511    ;exit function if not Pincer attack
LC214EC:  LDA $3019,X    ;Holds $01 for monster 1, $02 for monster 2,
                         ;$04 for monster 3, etc.
LC214EF:  AND $2F51      ;bitfield of which way all the monsters face
LC214F2:  STA $EE        ;will be 0 if monster attacker faces left,
                         ;nonzero default if they face right
LC214F4:  LDY #$06
LC214F6:  LDA $EE
LC214F8:  XBA            ;save attacking monster's direction variable
LC214F9:  LDA $3018,Y    ;Holds $01 for character 1, $02 for character 2,
                         ;$04 for character 3, $08 for character 4
LC214FC:  BIT $2F50      ;bitfield of which way all the characters face
LC214FF:  BEQ LC21506    ;branch if this character faces left
LC21501:  XBA
LC21502:  EOR $3019,X    ;A = reverse of attacking monster's direction
LC21505:  XBA
LC21506:  XBA
LC21507:  BNE LC2150D    ;branch if the monster and character are facing
                         ;each other
LC21509:  XBA            ;get $3018,Y
LC2150A:  TSB $3A54      ;so we'll turn on this character's bit if the
                         ;attacking monster is facing their back
LC2150D:  DEY
LC2150E:  DEY
LC2150F:  BPL LC214F6    ;loop for all 4 characters
LC21511:  RTS


;Increment damage if weapon is spear: Set $BD, turn-wide Damage Incrementor, to 2 if
;Item ID in A is between #$1D and #$24 (inclusive)

LC21512:  CMP #$1D
LC21514:  BCC LC2151E    ;Exit if ID < 29d
LC21516:  CMP #$25
LC21518:  BCS LC2151E    ;Exit if ID >= 37d
LC2151A:  LDA #$02
LC2151C:  STA $BD        ;set turn-wide Damage Incrementor to 2
LC2151E:  RTS


;Sketch

LC2151F:  TYX
LC21520:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC21523:  LDA #$FF
LC21525:  STA $B7        ;start with null graphic index, in case it misses
LC21527:  LDA #$AA
LC21529:  STA $11A9      ;Store Sketch in special effect
LC2152C:  JSR $317B      ;entity executes one hit
LC2152F:  LDY $3417      ;get the Sketchee
LC21532:  BMI LC2151E    ;Exit if it's null
LC21534:  STX $3417      ;save the attacker as the SketcheR
LC21537:  LDA $3C81,Y    ;get target [enemy] Special attack graphic
LC2153A:  STA $3C81,X    ;copy to attacker
LC2153D:  LDA $322D,Y    ;get target Special attack
LC21540:  STA $322D,X    ;copy to attacker
LC21543:  STZ $3415      ;will force randomization and skip backing up of
                         ;targets
LC21546:  LDA $3400
LC21549:  STA $B6        ;copy "spell # of second attack" into normal
                         ;spell variable
LC2154B:  LDA #$FF
LC2154D:  STA $3400      ;clear "spell # of second attack"
LC21550:  LDA #$01
LC21552:  TSB $B2        ;will allow name of attack to be displayed atop
                         ;screen for its first strike
LC21554:  LDA $B6
LC21556:  JSR $1DBF      ;choose a command based on spell #
LC21559:  STA $B5
LC2155B:  ASL
LC2155C:  TAX
LC2155D:  JMP ($19C7,X)  ;execute that command


;Rage

LC21560:  LDA $33A8,Y    ;get monster #
LC21563:  INC
LC21564:  BNE LC21579    ;branch if it's already defined
LC21566:  LDX $3A93      ;if it's undefined [like with Mimic], get the
                         ;index of another Rager, so we can copy their
                         ;monster #
LC21569:  CPX #$14
LC2156B:  BCC LC2156F    ;if the Rager index corresponds to a character
                         ;[0, 2, 4, 6] or an enemy [8, 10, 12, 14, 16, 18],
                         ;consider it valid and branch.
LC2156D:  LDX #$00       ;if not, default to looking at character #1
LC2156F:  LDA $33A8,X    ;get that other Rager's monster
LC21572:  STA $33A8,Y    ;save it as our current Rager's monster
LC21575:  TDC
LC21576:  STA $33A9,Y
LC21579:  STY $3A93      ;save the index of our current Rager
LC2157C:  LDA $3EF9,Y
LC2157F:  ORA #$01
LC21581:  STA $3EF9,Y    ;Set Rage status
LC21584:  JSR $0610      ;Load monster Battle and Special graphics, its special
                         ;attack, elemental properties, status immunities, startup
                         ;statuses [to be set later], and special properties
LC21587:  TYX
LC21588:  JSR $2650      ;deal with Instant Death protection, and Poison elemental
                         ;nullification giving immunity to Poison status
LC2158B:  JSR $1554      ;Commands code.
                         ;note that the attack's "Update Status" function will also
                         ;be used to give the monster's statuses to the Rager.
LC2158E:  JMP $2675      ;make some monster statuses permanent by setting immunity
                         ;to them.  also handle immunity to "mutually exclusive"
                         ;statuses.


;Steal

LC21591:  TYX
LC21592:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC21595:  LDA #$A4
LC21597:  STA $11A9      ;Store steal in special effect
LC2159A:  JMP $317B      ;entity executes one hit


;Blitz

LC2159D:  LDA $B6
LC2159F:  BPL LC215B0    ;branch if the spell # indicates a Blitz
LC215A1:  LDA #$01
LC215A3:  TRB $B3        ;this will clear targets for a failed Blitz input
LC215A5:  LDA #$43
LC215A7:  STA $3401      ;Set to display Text $43 - "Incorrect Blitz input!"
LC215AA:  LDA #$5D
LC215AC:  STA $B6        ;store Pummel's spell number
LC215AE:  BRA LC215B5
LC215B0:  LDA #$08
LC215B2:  STA $3412      ;will display a Blitz name atop screen
LC215B5:  LDA $B6
LC215B7:  PHA            ;Put on stack
LC215B8:  SEC
LC215B9:  SBC #$5D       ;subtract Pummel's spell index from our spell #
LC215BB:  STA $B6        ;save our 0 thru 7 "Blitz index", likely used for
                         ;animation
LC215BD:  PLA            ;but use our original spell # for loading spell data
LC215BE:  TYX
LC215BF:  JSR $19C1      ;Load data for command and attack/sub-command, held
                         ;in $B5 and A
LC215C2:  JSR $2951      ;Load Magic Power / Vigor and Level
LC215C5:  JMP $317B      ;entity executes one hit


;Fight - check for Desperation attack first

LC215C8:  CPY #$08
LC215CA:  BCS LC21610    ;No DA if monster
LC215CC:  LDA $3A3F
LC215CF:  CMP #$03
LC215D1:  BCC LC21610    ;No DA if time counter is 767 or less
LC215D3:  LDA $3EE5,Y
LC215D6:  BIT #$02
LC215D8:  BEQ LC21610    ;No DA If not Near Fatal
LC215DA:  BIT #$24
LC215DC:  BNE LC21610    ;No DA If Muddled or Image
LC215DE:  LDA $3EE4,Y
LC215E1:  BIT #$12
LC215E3:  BNE LC21610    ;No DA If Clear or Zombie
LC215E5:  LDA $B9
LC215E7:  BEQ LC21610    ;No DA if no monsters targeted
LC215E9:  JSR $4B5A      ;Random number 0 to 255
LC215EC:  AND #$0F       ;0 to 15
LC215EE:  BNE LC21610    ;1 in 16 chance for DA
LC215F0:  LDA $3018,Y
LC215F3:  TSB $3F2F      ;mark as ineligible to use a desperation attack again
LC215F6:  BNE LC21610    ;No DA if this character already used it this combat
LC215F8:  LDA $3ED8,Y    ;Which character it is
LC215FB:  CMP #$0C
LC215FD:  BEQ LC21604    ;branch if Gogo
LC215FF:  CMP #$0B
LC21601:  BCS LC21610    ;branch if Character 11 or above: Gau, Umaro, or
                         ;special character.  none of these characters have DAs
LC21603:  INC
LC21604:  DEC            ;if it was Gogo, we decrement the DA by 1 to account
                         ;for Gau -- who's before Gogo -- not having one
LC21605:  ORA #$F0
LC21607:  STA $B6        ;add F0h to modified character #, then save as attack #
LC21609:  LDA #$10
LC2160B:  TRB $B0        ;???  See functions C2/13D3 and C2/57C2 for usual
                         ;purpose; dunno whether it does anything here.
LC2160D:  JMP $1714

LC21610:  CPY #$08       ;Capture enters here
LC21612:  BCS LC2161B    ;branch if monster
LC21614:  LDA $3ED8,Y    ;Which character it is
LC21617:  CMP #$0D
LC21619:  BEQ LC2163B    ;branch if Umaro
LC2161B:  TYX
LC2161C:  LDA $3C58,X
LC2161F:  LSR
LC21620:  LDA #$01
LC21622:  BCC LC21626    ;branch if no offering
LC21624:  LDA #$07
LC21626:  STA $3A70      ;# of attacks
LC21629:  JSR $5A4D      ;Remove dead and hidden targets
LC2162C:  JSR $3865      ;depending on $3415, copy targets into backup targets
                         ;and add to "already hit targets" list, or copy backup
                         ;targets into targets.
LC2162F:  LDA #$02
LC21631:  TRB $B2        ;clear no critical & ignore true knight
LC21633:  LDA $B5
LC21635:  STA $3413      ;save backup command [Fight or Capture].  used for
                         ;multi-strike turns where a spell is cast by a weapon,
                         ;thus overwriting the command #.
LC21638:  JMP $317B      ;entity executes one hit (loops for multiple-strike
                         ;attack)


;Determine which type of attack Umaro uses

LC2163B:  STZ $FE        ;start off allowing neither Storm nor Throw attack
LC2163D:  LDA #$C6
LC2163F:  CMP $3CD0,Y
LC21642:  BEQ LC21649    ;Branch if Rage Ring equipped in relic slot 1
LC21644:  CMP $3CD1,Y    ;Check Slot 2
LC21647:  BNE LC21656    ;Branch if Rage Ring not equipped
LC21649:  TDC
LC2164A:  LDA $3018,Y
LC2164D:  EOR $3A74
LC21650:  BEQ LC21656    ;Branch if Umaro is the only present character alive
LC21652:  LDA #$04
LC21654:  TSB $FE        ;allow for Throw character attack
LC21656:  LDA #$C5
LC21658:  CMP $3CD0,Y
LC2165B:  BEQ LC21662    ;Branch if Blizzard Orb equipped in relic slot 1
LC2165D:  CMP $3CD1,Y    ;Check Slot 2
LC21660:  BNE LC21666    ;Branch if Blizzard Orb not equipped
LC21662:  LDA #$08
LC21664:  TSB $FE        ;allow for Storm attack
LC21666:  LDA $FE
LC21668:  TAX            ;form a pointer based on availability of Storm and/or
                         ;Throw.  it will pick 1 of Umaro's 4 probability sets,
                         ;each of which holds the chances for his 4 attacks.
LC21669:  ORA #$30       ;always allow Normal attack and Charge
LC2166B:  ASL
LC2166C:  ASL
LC2166D:  JSR $5247      ;X = Pick attack type to use.  Will return 0 for
                         ;Throw character, 1 for Storm, 2 for Charge,
                         ;3 for Normal attack.
LC21670:  TXA
LC21671:  ASL
LC21672:  TAX
LC21673:  JMP ($1676,X)


;Code pointers

LC21676: dw $1692     ;Throw character
LC21678: dw $170D     ;Storm
LC2167A: dw $167E     ;Charge
LC2167C: dw $161B     ;Normal attack


;Umaro's Charge attack

LC2167E:  TYX
LC2167F:  JSR $17C7      ;attack Battle Power = sum of battle power of
                         ;Umaro's hands.  initialize various other stuff.
LC21682:  LDA #$20
LC21684:  TSB $11A2      ;Set ignore defense
LC21687:  LDA #$02
LC21689:  TRB $B2        ;Clear no critical and ignore True Knight
LC2168B:  LDA #$23
LC2168D:  STA $B5        ;Set command for animation purposes to #$23
LC2168F:  JMP $317B      ;entity executes one hit


;Umaro's Throw character attack

LC21692:  TYX
LC21693:  JSR $17C7      ;attack Battle Power = sum of battle power of
                         ;Umaro's hands.  initialize various other stuff.
LC21696:  LDA $3018,X
LC21699:  EOR $3A74      ;Remove Umaro from possible characters to throw
LC2169C:  LDX #$06       ;Start pointing at 4th character slot
LC2169E:  BIT $3018,X    ;Check each character
LC216A1:  BEQ LC216BF    ;Branch to check next character if this one is not
                         ;present or not alive, or if we've already decided on
                         ;a character due to them having Muddled or Sleep.
LC216A3:  XBA
LC216A4:  LDA $3EF9,X
LC216A7:  BIT #$20
LC216A9:  BEQ LC216B2    ;Branch if not Hide
LC216AB:  XBA
LC216AC:  EOR $3018,X    ;Remove this character from list of characters to throw
LC216AF:  XBA
LC216B0:  BRA LC216BE    ;Check next character
LC216B2:  LDA $3EE5,X
LC216B5:  BIT #$A0
LC216B7:  BEQ LC216BE    ;Branch if no Muddled or Sleep
LC216B9:  XBA
LC216BA:  LDA $3018,X    ;Set to automatically throw this character
LC216BD:  XBA
LC216BE:  XBA
LC216BF:  DEX
LC216C0:  DEX
LC216C1:  BPL LC2169E    ;iterate for all 4 characters
LC216C3:  PHA            ;Put on stack
LC216C4:  TDC
LC216C5:  PLA            ;clear top half of A
LC216C6:  BEQ LC2167E    ;Do Umaro's charge attack if no characters can be thrown
LC216C8:  JSR $522A      ;Pick a random character to throw
LC216CB:  JSR $51F9      ;Set Y to character thrown
LC216CE:  TYX            ;put throwee in X, so they'll essentially be treated as
                         ;the "attacker" from here on out
LC216CF:  LDA $3ED8,X    ;Which character is thrown
LC216D2:  CMP #$0A
LC216D4:  BNE LC216DA    ;Branch if not Mog
LC216D6:  LDA #$02
LC216D8:  TRB $B3        ;Set always critical..  too bad we don't clear
                         ;"Ignore damage increment on Ignore Defense", meaning
                         ;this does nothing. :'(  similarly, the normal 1-in-32
                         ;critical will be for nought.  i'm not sure what stops
                         ;the game from flashing the screen, though..
LC216DA:  LDA $3B68,X
LC216DD:  ADC $3B69,X    ;add Battle power of thrown character's left hand to
                         ;their right hand
                         ;there should really be a CLC before this, as there's no
                         ;reason to give Mog, Gau, and Gogo a 1-point advantage
                         ;over other characters.  but it does reduce Mog's
                         ;snubbing somewhat. :P
LC216E0:  BCC LC216E4
LC216E2:  LDA #$FE       ;if that overflowed, treat throwee's overall
                         ;Battle Power as 255 [Carry is set]
                         ;can replace last 2 instructions with "BCS LC216E9"
LC216E4:  ADC $11A6      ;Add to battle power of attack
LC216E7:  BCC LC216EB
LC216E9:  LDA #$FF       ;if that overflowed, set overall Battle Power
                         ;to 255
LC216EB:  STA $11A6      ;Store in new battle power for attack
LC216EE:  LDA #$24
LC216F0:  STA $B5        ;Set command for animation purposes to #$24
LC216F2:  LDA #$20
LC216F4:  TSB $11A2      ;Set ignore defense
LC216F7:  LDA #$02
LC216F9:  TRB $B2        ;Clear no critical and ignore True Knight
LC216FB:  LDA #$01
LC216FD:  TSB $BA        ;Exclude Attacker [i.e. the throwee] from Targets
LC216FF:  LDA $3EE5,X
LC21702:  AND #$A0
LC21704:  ORA $3DFD,X
LC21707:  STA $3DFD,X    ;Set to clear Sleep and Muddled on thrown character,
                         ;provided the character already possesses them
LC2170A:  JMP $317B      ;entity executes one hit


;Storm

LC2170D:  STZ $3415      ;will force to randomly retarget
LC21710:  LDA #$54       ;Storm
LC21712:  STA $B6        ;Set spell/animation
LC21714:  LDA #$02       ;Magic
LC21716:  STA $B5        ;Set command
LC21718:  BRA LC2175F


;<>Shock

LC2171A:  LDA #$82       ;"Megahit" spell, which is what has Shock's data
LC2171C:  BRA LC21720    ;go set that as spell/animation


;Health

LC2171E:  LDA #$2E       ;Cure 2
LC21720:  STA $B6        ;Set spell/animation
LC21722:  LDA #$05
LC21724:  BRA LC21765


;<>Slot

LC21726:  LDA #$10
LC21728:  TRB $B0        ;???  See functions C2/13D3 and C2/57C2 for usual
                         ;purpose; dunno whether it does anything here.
LC2172A:  LDA $B6
LC2172C:  CMP #$94
LC2172E:  BNE LC21734    ;branch if not L.5 Doom [i.e. one of the Joker Dooms]
LC21730:  LDA #$07
LC21732:  BRA LC21765
LC21734:  CMP #$51
LC21736:  BCC LC21763    ;branch if spell # is below Fire Skean.  iow, branch
                         ;if Slot's summoning an Esper.
LC21738:  CMP #$FE
LC2173A:  BNE LC21741    ;Branch if not Lagomorph
LC2173C:  LDA #$07
LC2173E:  STA $3401      ;Set to display text 7
LC21741:  CPY #$08       ;Magic command enters here
LC21743:  BCS LC2175F    ;Branch if attacker is monster
LC21745:  LDA $3ED8,Y
LC21748:  CMP #$00
LC2174A:  BNE LC2175F    ;Branch if not Terra
LC2174C:  LDA #$02
LC2174E:  TRB $3EBC      ;Clear bit for that classic Terra/Locke/Edgar
                         ;"M..M..Magic" skit, as it only happens once.
                         ;Keep in mind the game will also clear this when
                         ;exiting Figaro Cave to the South Figaro plains.
LC21751:  BEQ LC2175F    ;If it wasn't set, skip the special spellcast
                         ;and the ensuing convo
LC21753:  LDX #$06       ;Attack
LC21755:  LDA #$23       ;Command is Battle Event, and Attack in X indicates
                         ;it's number 6, Terra/Locke/Edgar "M..M..Magic"
LC21757:  JSR $4E91      ;queue it, in global Special Action queue
LC2175A:  LDA #$20
LC2175C:  TSB $11A4      ;Set can't be dodged
LC2175F:  LDA #$00       ;Lore / Enemy attack / Magitek commands enter here
LC21761:  BRA LC21765
LC21763:  LDA #$02       ;Summon enters here
LC21765:  STA $3412      ;depending on how we reached here, will display
                         ;various things atop the screen: an Esper Summon
                         ;a Magic spell, Lore, enemy attack/spell, Magitek
                         ;attack, Dance move, a Slot move [aside from
                         ;Lagomorph and Joker Doom], or "Storm"; "Health" or
                         ;"Shock"; or "Joker Doom"
LC21768:  TYX
LC21769:  LDA $B6
LC2176B:  JSR $19C1      ;Load data for command and attack/sub-command, held
                         ;in $B5 and A
LC2176E:  JSR $2951      ;Load Magic Power / Vigor and Level
LC21771:  LDA $B5
LC21773:  CMP #$0F
LC21775:  BNE LC2177A    ;branch if command is not Slot
LC21777:  STZ $11A5      ;Set MP cost to 0
LC2177A:  JMP $317B      ;entity executes one hit


;Dance

LC2177D:  LDA $3EF8,Y
LC21780:  ORA #$01
LC21782:  STA $3EF8,Y    ;Set Dance status
LC21785:  LDA #$FF
LC21787:  STA $B7        ;default animation to not affecting background
LC21789:  LDA $32E1,Y    ;Which dance is selected for this character
LC2178C:  BPL LC21794    ;branch if already defined
LC2178E:  LDA $3A6F      ;if not, read a "global" dance variable set
                         ;by last character to choose Dance
LC21791:  STA $32E1,Y    ;and save it as this character's dance
LC21794:  LDX $11E2
LC21797:  CMP $ED8E5B,X  ;Check if current background is associated with
                         ;this dance
LC2179B:  BEQ LC21741    ;Branch if it is
LC2179D:  JSR $4B53      ;random, 0 or 1 in Carry
LC217A0:  BCC LC217AF    ;50% chance of branch and stumble
LC217A2:  TAX
LC217A3:  LDA $D1F9AB,X  ;get default background for this Dance
LC217A7:  STA $B7        ;set it in animation
LC217A9:  STA $11E2      ;and change current background to it
LC217AC:  JMP $1741      ;BRA LC21741?


;Stumble when trying to dance

LC217AF:  LDA $3EF8,Y
LC217B2:  AND #$FE
LC217B4:  STA $3EF8,Y    ;Clear Dance status
LC217B7:  TYX
LC217B8:  LDA #$06
LC217BA:  STA $3401      ;Set to display stumble message
LC217BD:  LDA #$20
LC217BF:  STA $B5        ;set command for animation purposes to Stumble?
LC217C1:  JSR $298D      ;Load placeholder command data, and clear special
                         ;effect, magic power, etc.
LC217C4:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Attack Battle Power = sum of battle power of Umaro's hands.  initialize various
; other stuff.)

LC217C7:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC217CA:  CLC
LC217CB:  LDA $3B68,X    ;Battle Power for 1st hand
LC217CE:  ADC $3B69,X    ;add Battle Power for 2nd hand
LC217D1:  BCC LC217D5
LC217D3:  LDA #$FF       ;if sum overflowed, treat combined Battle Power
                         ;as 255
LC217D5:  STA $11A6      ;Battle Power or Spell Power
LC217D8:  LDA $3B18,X    ;attacker Level
LC217DB:  STA $11AF      ;attack's Level
LC217DE:  LDA $3B2C,X    ;attacker Vigor * 2
LC217E1:  STA $11AE      ;attack's Vigor * 2 or Magic Power
LC217E4:  RTS


;Possess

LC217E5:  TYX
LC217E6:  JSR $19C1      ;Load data for command held in $B5, and data of
                         ;"Battle" spell
LC217E9:  LDA #$20
LC217EB:  TSB $11A4      ;Set can't be dodged
LC217EE:  LDA #$A0
LC217F0:  STA $11A9      ;Stores Possess in special effect
LC217F3:  JMP $317B      ;entity executes one hit


;Jump

LC217F6:  TYX
LC217F7:  JSR $19C1      ;Load data for command held in $B5, and data of
                         ;"Battle" spell
LC217FA:  LDA $3B69,X    ;Battle Power - left hand
LC217FD:  BEQ LC21808    ;if no battle power, call subfunction with carry unset
                         ;to indicate right hand
LC217FF:  SEC            ;set carry to indicate left hand
LC21800:  LDA $3B68,X    ;Battle Power - right hand
LC21803:  BEQ LC21808    ;if no bat pwr, call subfunction with carry set
LC21805:  JSR $4B53      ;0 or 1 RNG - if both hands have weapon, carry flag
                         ;will select hand used
LC21808:  JSR $299F      ;Load weapon data into attack data.
                         ;Plus Sniper Sight, Offering and more.
LC2180B:  LDA #$20
LC2180D:  STA $11A4      ;Set can't be dodged only
LC21810:  TSB $B3        ;Set ignore attacker row
LC21812:  INC $BD        ;Increment damage.  since $BD is zeroed right before
                         ;this in function C2/13D3, it should be 1 now.
LC21814:  LDA $3CA8,X    ;Weapon in right hand
LC21817:  JSR $1512      ;Set $BD, turn-wide damage incrementor, to 2 if spear
LC2181A:  LDA $3CA9,X    ;Weapon in left hand
LC2181D:  JSR $1512      ;Set $BD, turn-wide damage incrementor, to 2 if spear
LC21820:  LDA $3C44,X
LC21823:  BPL LC2183C    ;Branch if not jump continously [Dragon Horn]
LC21825:  DEC $3A8E      ;make a variable FFh to indicate the attack is
                         ;a continuous jump
LC21828:  JSR $4B5A      ;random: 0 to 255
LC2182B:  INC $3A70      ;Add 1 attack
LC2182E:  CMP #$40
LC21830:  BCS LC2183C    ;75% chance branch
LC21832:  INC $3A70      ;Add 1 attack
LC21835:  CMP #$10
LC21837:  BCS LC2183C    ;75% chance branch - so there's a 1/16 overall
                         ;chance of 4 attacks
LC21839:  INC $3A70      ;Add 1 attack
LC2183C:  LDA $3EF9,X
LC2183F:  AND #$DF
LC21841:  STA $3EF9,X    ;Clear Hide status
LC21844:  JMP $317B      ;entity executes one hit (loops for multiple-strike
                         ;attack)


;Swdtech

LC21847:  TYX
LC21848:  LDA $B6        ;Battle animation
LC2184A:  PHA            ;Put on stack
LC2184B:  SEC
LC2184C:  SBC #$55
LC2184E:  STA $B6        ;save unique index of the SwdTech.  0 = Dispatch,
                         ;1 = Retort, etc.
LC21850:  PLA
LC21851:  JSR $19C1      ;Load data for command and attack/sub-command, held
                         ;in $B5 and A
LC21854:  JSR $2951      ;Load Magic Power / Vigor and Level
LC21857:  LDA $B6
LC21859:  CMP #$01
LC2185B:  BNE LC2187D    ;branch if not Retort
LC2185D:  LDA $3E4C,X
LC21860:  EOR #$01
LC21862:  STA $3E4C,X    ;Toggle Retort condition
LC21865:  LSR
LC21866:  BCC LC21879    ;branch if we're doing the actual retaliation
                         ;as opposed to the preparation
LC21868:  ROR $B6        ;$B6 is now 80h
LC2186A:  STZ $11A6      ;Sets power to 0
LC2186D:  LDA #$20
LC2186F:  TSB $11A4      ;Set can't be dodged
LC21872:  LDA #$01
LC21874:  TRB $11A2      ;Sets to magical damage
LC21877:  BRA LC21882
LC21879:  LDA #$10
LC2187B:  TRB $B0        ;???  See functions C2/13D3 and C2/57C2 for usual
                         ;purpose; dunno whether it does anything here.
LC2187D:  LDA #$04
LC2187F:  STA $3412      ;will display a SwdTech name atop screen
LC21882:  JMP $317B      ;entity executes one hit (loops for multiple-strike
                         ;attack)


;Tools

LC21885:  LDA $B6
LC21887:  SBC #$A2       ;carry was clear, so subtract 163
LC21889:  STA $B6        ;save unique Tool index.  0 = NoiseBlaster,
                         ;1 = Bio Blaster, etc.
LC2188B:  BRA LC2189E


;<>Throw

LC2188D:  LDA #$02
LC2188F:  STA $BD        ;Increment damage by 100%
LC21891:  LDA #$10
LC21893:  TRB $B3        ;Clear Ignore Damage Increment on Ignore Defense
LC21895:  BRA LC2189E


;<>Item

LC21897:  STZ $3414      ;Set ignore damage modification
LC2189A:  LDA #$80
LC2189C:  TRB $B3        ;Set Ignore Clear
LC2189E:  TYX
LC2189F:  LDA #$01
LC218A1:  STA $3412      ;will display an Item name atop screen
LC218A4:  LDA $3A7D
LC218A7:  JSR $19C1      ;Load data for command and attack/sub-command, held
                         ;in $B5 and A
LC218AA:  LDA #$10
LC218AC:  TRB $B1        ;clear "don't deplete from Item inventory" flag
LC218AE:  BNE LC218B5    ;branch if it was set
LC218B0:  LDA #$FF
LC218B2:  STA $32F4,X    ;null item index to add to inventory.  this means
                         ;the item will stay deducted from your inventory.
LC218B5:  LDA $3018,X
LC218B8:  TSB $3A8C      ;flag character to have any applicable item in
                         ;$32F4,X added back to inventory when turn is over.
LC218BB:  LDA $B5        ;Command #
LC218BD:  BCC LC218E3    ;Carry is set (by the $19C1 call for:
                         ; - Skeans/Tools that don't use a spell
                         ; - normal Item usage
                         ;which means it isn't set for:
                         ; - Equipment Magic or Skeans/Tools that do use a spell
LC218BF:  CMP #$02       ;Carry will now be set if Command >=2, so for Throw and
                         ;Tools, but not plain Item
LC218C1:  LDA $3411      ;get item #
LC218C4:  JSR $2A37      ;item usage setup
LC218C7:  LDA $11AA
LC218CA:  BIT #$C2       ;Check if Dead, Petrify or Zombie attack
LC218CC:  BNE LC218E0    ;if so, branch
LC218CE:  REP #$20       ;Set 16-bit Accumulator
LC218D0:  LDA $3A74      ;alive and present characters [non-enemy] and monsters
LC218D3:  ORA $3A42      ;list of present and living characters acting
                         ;as enemies?
LC218D6:  AND $B8        ;clear targets that are in none of above categories
LC218D8:  STA $B8
LC218DA:  SEP #$20       ;Set 8-bit Accumulator
LC218DC:  LDA #$04
LC218DE:  TRB $B3        ;prevents "Retarget if target invalid" at C2/31C5
LC218E0:  JMP $317B      ;entity executes one hit


LC218E3:  CMP #$01       ;is command Item?
LC218E5:  BNE LC218EE
LC218E7:  INC $B5        ;if so, bump it up to Magic, as we've reached this
                         ;point thanks to Equipment Magic
LC218E9:  LDA $3410      ;get spell #
LC218EC:  STA $B6
LC218EE:  STZ $BD        ;if we reached here for Throw, it's for a Skean
                         ;casting magic, so zero out the Damage Increment
                         ;given by the Throw command.
LC218F0:  JSR $2951      ;Load Magic Power / Vigor and Level
LC218F3:  LDA #$02
LC218F5:  TSB $11A3      ;Set Not reflectable
LC218F8:  LDA #$20
LC218FA:  TSB $11A4      ;Set unblockable
LC218FD:  LDA #$08
LC218FF:  TRB $BA        ;Clear "can target dead/hidden targets"
LC21901:  STZ $11A5      ;Set MP cost to 0
LC21904:  JMP $317B      ;entity executes one hit


;GP Rain

LC21907:  TYX
LC21908:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC2190B:  INC $11A6      ;Set spell power to 1
LC2190E:  LDA #$60
LC21910:  TSB $11A2      ;Set ignore defense, no split damage
LC21913:  STZ $3414      ;Skip damage modification
LC21916:  CPX #$08
LC21918:  BCC LC2191F    ;branch if character
LC2191A:  LDA #$05
LC2191C:  STA $3412      ;will display "GP Rain" atop screen.
                         ;differentiated from "Health" and "Shock"
                         ;by $B5 holding command 18h in this case.
LC2191F:  LDA #$A2
LC21921:  STA $11A9      ;Store GP Rain in special effect
LC21924:  JMP $317B      ;entity executes one hit


;Revert

LC21927:  LDA $3EF9,Y
LC2192A:  BIT #$08
LC2192C:  BNE LC21937    ;Branch if Morphed
LC2192E:  TYA
LC2192F:  LSR
LC21930:  XBA
LC21931:  LDA #$0E
LC21933:  JMP $62BF


;Morph

LC21936:  SEC            ;tell upcoming shared code it's Morph, not Revert
LC21937:  PHP
LC21938:  TYX
LC21939:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC2193C:  PLP
LC2193D:  LDA #$08
LC2193F:  STA $11AD      ;mark attack to affect Morph status
LC21942:  BCC LC21945    ;branch if we're running Revert
LC21944:  TDC
LC21945:  LSR
LC21946:  TSB $11A4      ;if Carry was clear, turn on Lift Status property.
                         ;otherwise, the attack will just default to setting
                         ;the status.
LC21949:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Row

LC2194C:  TYX
LC2194D:  LDA $3AA1,X
LC21950:  EOR #$20
LC21952:  STA $3AA1,X    ;Toggle Row
LC21955:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC21958:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Runic

LC2195B:  TYX
LC2195C:  LDA $3E4C,X
LC2195F:  ORA #$04
LC21961:  STA $3E4C,X    ;Set runic
LC21964:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC21967:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Defend

LC2196A:  TYX
LC2196B:  LDA #$02
LC2196D:  JSR $5BAB      ;set Defending flag
LC21970:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC21973:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Control

LC21976:  LDA $3EF9,Y
LC21979:  BIT #$10
LC2197B:  BEQ LC21987    ;Branch if no spell/chant status
LC2197D:  JSR $192E
LC21980:  LDA $32B8,Y    ;Get whom this entity controls
LC21983:  TAY
LC21984:  JMP $1554      ;Commands code


LC21987:  TYX
LC21988:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC2198B:  LDA #$A6
LC2198D:  STA $11A9      ;Store control in special effect
LC21990:  LDA #$01
LC21992:  TRB $11A2      ;Sets to magical damage
LC21995:  LDA #$20
LC21997:  TSB $11A4      ;Sets unblockable
LC2199A:  JMP $317B      ;entity executes one hit


;Leap

LC2199D:  TYX
LC2199E:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC219A1:  LDA #$A8
LC219A3:  STA $11A9      ;Store Leap in special effect
LC219A6:  LDA #$01
LC219A8:  TRB $11A2      ;Sets to magical damage
LC219AB:  LDA #$40
LC219AD:  STA $BB        ;Sets to Cursor start on enemy only
LC219AF:  JMP $317B      ;entity executes one hit


;Enemy Roulette

LC219B2:  LDA #$0C
LC219B4:  STA $B5        ;Sets command to Lore
LC219B6:  JSR $175F
LC219B9:  LDA #$21
LC219BB:  XBA
LC219BC:  LDA #$06
LC219BE:  JMP $62BF


;Load data for command and attack/sub-command, passed in $B5 and A, respectively

LC219C1:  XBA
LC219C2:  LDA $B5
LC219C4:  JMP $26D3      ;Load command and attack/sub-command data,
                         ;takes parameters in A.bottom and A.top


;Code pointers for commands; special commands start at C2/1A03

LC219C7: dw $15C8     ;(Fight)
LC219C9: dw $1897     ;(Item)
LC219CB: dw $1741     ;(Magic)
LC219CD: dw $1936     ;(Morph)
LC219CF: dw $1927     ;(Revert)
LC219D1: dw $1591     ;(Steal)   (05)
LC219D3: dw $1610     ;(Capture)
LC219D5: dw $1847     ;(Swdtech)
LC219D7: dw $188D     ;(Throw)
LC219D9: dw $1885     ;(Tools)
LC219DB: dw $159D     ;(Blitz)   (0A)
LC219DD: dw $195B     ;(Runic)
LC219DF: dw $175F     ;(Lore)
LC219E1: dw $151F     ;(Sketch)
LC219E3: dw $1976     ;(Control)
LC219E5: dw $1726     ;(Slot)
LC219E7: dw $1560     ;(Rage)    (10)
LC219E9: dw $199D     ;(Leap)
LC219EB: dw $151E     ;(Mimic)
LC219ED: dw $177D     ;(Dance)
LC219EF: dw $194C     ;(Row)
LC219F1: dw $196A     ;(Def.)    (15)
LC219F3: dw $17F6     ;(Jump)
LC219F5: dw $1741     ;(X-Magic)
LC219F7: dw $1907     ;(GP Rain)
LC219F9: dw $1763     ;(Summon)
LC219FB: dw $171E     ;(Health)  (1A)
LC219FD: dw $171A     ;(Shock)
LC219FF: dw $17E5     ;(Possess)
LC21A01: dw $175F     ;(Magitek)
LC21A03: dw $19B2     ;(1E) (Enemy Roulette)
LC21A05: dw $151E     ;(1F) (Jumps to RTS)
LC21A07: dw $5072     ;(20) (#$F2 Command script)
LC21A09: dw $50D1     ;(21) (#$F3 Command script)
LC21A0B: dw $500B     ;(22) (Poison, Regen, and Seizure/Phantasm damage or healing)
LC21A0D: dw $4F57     ;(23) (#$F7 Command script)
LC21A0F: dw $4F97     ;(24) (#$F5 Command script)
LC21A11: dw $50CD     ;(25)
LC21A13: dw $4F5F     ;(26) (Doom cast when Condemned countdown reaches 0; Safe, Shell, or
                      ;      Reflect* cast when character enters Near Fatal (* no items
                      ;      actually do this, but it's supported); or revival due to Life 3.
LC21A15: dw $50DD     ;(27) (Display Scan info)
LC21A17: dw $151E     ;(28) (Jumps to RTS)
LC21A19: dw $5161     ;(29) (Remove Stop, Reflect, Freeze, or Sleep when time is up)
LC21A1B: dw $20DE     ;(2A) (Run)
LC21A1D: dw $642D     ;(2B) (#$FA Command script)
LC21A1F: dw $51A8     ;(2C)
LC21A21: dw $51B2     ;(2D) (Drain from being seized)
LC21A23: dw $1DFA     ;(2E) (#$F8 Command script)
LC21A25: dw $1E1A     ;(2F) (#$F9 Command script)
LC21A27: dw $1E5E     ;(30) (#$FB Command script)
LC21A29: dw $151E     ;(31) (Jumps to RTS)
LC21A2B: dw $151E     ;(32) (Jumps to RTS)
LC21A2D: dw $151E     ;(33) (Jumps to RTS)


;Process a monster's main or counterattack script, backing up targets first

LC21A2F:  PHX
LC21A30:  PHP
LC21A31:  LDA $B8        ;get targets
LC21A33:  STA $FC        ;save as working copy
LC21A35:  STA $FE        ;and as backup copy
LC21A37:  SEP #$20
LC21A39:  STZ $F5        ;start at sub-block index 0 in this
                         ;main script or counterattack script
LC21A3B:  STX $F6        ;save target # of entity running script
LC21A3D:  JSR $1AAF      ;go parse the script and do commands
LC21A40:  PLP
LC21A41:  PLX
LC21A42:  RTS


;Read command script, up through an FEh or FFh command, advancing position in X

LC21A43:  TDC
LC21A44:  LDA $CF8700,X  ;read first byte of command
LC21A48:  INX
LC21A49:  CMP #$FE
LC21A4B:  BCS LC21A42    ;Exit if #$FE or #$FF - Done with commands
LC21A4D:  SBC #$EF       ;subtract F0h
LC21A4F:  BCC LC21A44    ;Branch if not a control command
LC21A51:  PHX
LC21A52:  TAX
LC21A53:  LDA $C21DAF,X  ;# of bytes in the control command
LC21A57:  PLX
LC21A58:  DEX
LC21A59:  INX
LC21A5A:  DEC
LC21A5B:  BNE LC21A59    ;loop through the whole command to reach
                         ;the next one
LC21A5D:  BRA LC21A44    ;go read the first byte of next command


;Read 4 bytes from command script (without advancing script position

LC21A5F:  PHP
LC21A60:  REP #$20
LC21A62:  LDX $F0        ;get current script position
LC21A64:  LDA $CF8702,X
LC21A68:  STA $3A2E
LC21A6B:  LDA $CF8700,X  ;Command scripts
LC21A6F:  STA $3A2C
LC21A72:  PLP
LC21A73:  RTS


;Command Script #$FD

LC21A74:  REP #$20       ;Set 16-bit Accumulator
LC21A76:  LDA $F0
LC21A78:  STA $F2        ;save current script address as left-off-at
                         ;address
LC21A7A:  RTS


;Command Script #$FE and #$FF

LC21A7B:  LDA #$FF
LC21A7D:  STA $F5        ;null sub-block index, so caller of $1A2F
                         ;doesn't think we left off anywhere
LC21A7F:  RTS


;Pick which attack of three to use; FEh will do nothing and exit caller

LC21A80:  LDA #$03
LC21A82:  JSR $4B65      ;random #: 0 to 2
LC21A85:  TAX
LC21A86:  LDA $3A2D,X    ;Byte 1 to 3 of 4-byte command
LC21A89:  CMP #$FE
LC21A8B:  BNE LC21A42    ;Exit if not FEh
LC21A8D:  PLA
LC21A8E:  PLA            ;remove caller address from stack
LC21A8F:  BRA LC21AB4    ;resume parsing script


;Command Script #$FC
;Also handles bulk of the script-parsing logic, with additional entry points at
; C2/1AAF and C2/1AB4.)

LC21A91:  LDA $3A2D      ;Byte 1 of command
LC21A94:  ASL
LC21A95:  TAX
LC21A96:  JSR ($1D55,X)  ;Do an FC subcommand, which is an If Statement
                         ;of various conditions
LC21A99:  BCS LC21AB4    ;branch if it passed as True
LC21A9B:  REP #$30       ;Set 16-bit A, X, & Y
LC21A9D:  LDA $FE
LC21A9F:  STA $FC        ;copy backup targets to working targets
LC21AA1:  SEP #$20       ;Set 8-bit A
LC21AA3:  LDX $F0        ;get script position to start reading from
LC21AA5:  JSR $1A43      ;Read command script, up through an FEh or FFh
                         ;command, advancing position in X
LC21AA8:  INC
LC21AA9:  BEQ LC21A7B    ;branch if FFh command was last thing read
LC21AAB:  STX $F0        ;save script position of next command
LC21AAD:  INC $F5        ;increment current sub-block index
LC21AAF:  LDA $3A98
LC21AB2:  STA $F8        ;save whether caller [C2/02DC or C2/4BF4] is
                         ;preventing most types of script commands:
                         ;00h = no, FFh = yes.
                         ;a couple commands can override this.
LC21AB4:  SEP #$20       ;Set 8-bit Accumulator
LC21AB6:  REP #$10       ;Set 16-bit X & Y
LC21AB8:  JSR $1A5F      ;Read 4 bytes from command script, w/o advance
LC21ABB:  CMP #$FC       ;compare the first one to FCh
LC21ABD:  BCS LC21AD0    ;Branch if command is FCh or higher
LC21ABF:  LDA $F5        ;current sub-block index, where a sub-block is a
                         ;portion of script ending with an FEh or FFh.
LC21AC1:  CMP $F4        ;compare to the sub-block we left off at due to
                         ;an FD command.  there are separate "bookmarks"
                         ;for the main and counterattack scripts.
LC21AC3:  BNE LC21AD0    ;branch if they don't match
LC21AC5:  LDA #$FF
LC21AC7:  STA $F4        ;null left-off-at sub-block index, as we're
                         ;already resuming in the one we sought
LC21AC9:  LDX $F2        ;get script position after last executed FDh
                         ;command.  there are separate "bookmarks" for the
                         ;main and counterattack scripts.
LC21ACB:  STX $F0        ;make that our current script position
LC21ACD:  JSR $1A5F      ;Read 4 bytes from command script, w/o advance
LC21AD0:  TDC            ;A = 0
LC21AD1:  SEC
LC21AD2:  TXY            ;Y = script position
LC21AD3:  LDA $3A2C      ;Command to execute
LC21AD6:  SBC #$F0
LC21AD8:  BCS LC21ADC    ;Branch if control command
LC21ADA:  LDA #$0F       ;if not control command, it'll be 1 byte long
LC21ADC:  TAX
LC21ADD:  LDA $C21DAF,X  ;# of bytes in the command
LC21AE1:  TAX
LC21AE2:  INY
LC21AE3:  DEX
LC21AE4:  BNE LC21AE2    ;loop, advancing Y by size of command
LC21AE6:  STY $F0        ;save updated script position
LC21AE8:  SEP #$10       ;Set 8-bit X, & Y
LC21AEA:  LDA $F8
LC21AEC:  BEQ LC21AF5    ;if caller didn't disable most counter types,
                         ;or if we executed a FC 1C or a successful FC 12
                         ;in this sub-block on this script "visit",
                         ;branch
LC21AEE:  LDA $3A2C      ;Command to execute
LC21AF1:  CMP #$FC
LC21AF3:  BCC LC21A9B    ;branch if command is FBh or lower
LC21AF5:  LDY $F6        ;get target # of entity running script
LC21AF7:  LDA $3A2C      ;Command to execute
LC21AFA:  CMP #$F0
LC21AFC:  BCC LC21B25    ;Branch if not control command; it's just an
                         ;attack/spell
LC21AFE:  AND #$0F       ;get command # - F0h
LC21B00:  ASL
LC21B01:  TAX
LC21B02:  JMP ($1D8F,X)  ;execute the command


;Command Script #$F6

LC21B05:  LDA #$01
LC21B07:  XBA
LC21B08:  LDA $3A2D      ;Item or Throw
LC21B0B:  BEQ LC21B10    ;Branch if item
LC21B0D:  LDA #$08
LC21B0F:  XBA
LC21B10:  LDA $3A2E      ;Item to use or throw
LC21B13:  STA $3A2D
LC21B16:  JSR $1A80      ;Pick which attack of three to use; FEh will do
                         ;nothing and exit this function
LC21B19:  XBA
LC21B1A:  BRA LC21B28


;<>Command Script #$F4

LC21B1C:  TDC
LC21B1D:  JSR $1A80      ;Pick which attack of three to use; FEh will do
                         ;nothing and exit this function
LC21B20:  BRA LC21B28


;<>Command Script #$F0

LC21B22:  JSR $1A80      ;Pick which attack of three to use; FEh will do
                         ;nothing and exit this function
LC21B25:  JSR $1DBF      ;choose a command based on attack #
LC21B28:  TYX
LC21B29:  REP #$20
LC21B2B:  PHA            ;Put on stack
LC21B2C:  LDA $FC
LC21B2E:  STA $B8
LC21B30:  LDA $3EE4,X
LC21B33:  BIT #$2000
LC21B36:  BEQ LC21B3A    ;Branch if not Muddled
LC21B38:  STZ $B8        ;clear targets, so they can be chosen randomly
LC21B3A:  PLA
LC21B3B:  JSR $03B9      ;Swap Roulette to Enemy Roulette
LC21B3E:  JSR $03E4      ;Determine command's "time to wait", recalculate
                         ;targets if there aren't any
LC21B41:  JSR $4EAD      ;queue command and attack.  script section we're
                         ;running [indicated by Bit 0 of $B1] determines
                         ;which of entity's queues used.
LC21B44:  JMP $1AB4      ;resume parsing script


;Command Script #$F1

LC21B47:  LDA $3A2D      ;Script byte 1
LC21B4A:  CLC
LC21B4B:  JSR $1F25
LC21B4E:  REP #$20
LC21B50:  LDA $B8
LC21B52:  STA $FC
LC21B54:  JMP $1AB4      ;resume parsing script


;Command Script #$F5

LC21B57:  LDA $3A2F
LC21B5A:  BNE LC21B62    ;branch if command already has targets
LC21B5C:  LDA $3019,Y
LC21B5F:  STA $3A2F      ;if it doesn't, save the monster who issued command
                         ;as the target
LC21B62:  LDA #$24
LC21B64:  BRA LC21B78


;<>Command Script #$F3

LC21B66:  LDA #$21
LC21B68:  BRA LC21B78


;<>Command Script #$FB

LC21B6A:  LDA #$30
LC21B6C:  BRA LC21B78


;<>Command Script #$F2

LC21B6E:  LDA #$20
LC21B70:  BRA LC21B78


;<>Command Script #$F8

LC21B72:  LDA #$2E
LC21B74:  BRA LC21B78


;<>Command Script #$F9

LC21B76:  LDA #$2F
LC21B78:  XBA
LC21B79:  LDA $3A2D
LC21B7C:  XBA
LC21B7D:  REP #$20       ;Set 16-bit Accumulator
LC21B7F:  STA $3A7A
LC21B82:  LDA $3A2E
LC21B85:  STA $B8
LC21B87:  TYX
LC21B88:  JSR $4EAD
LC21B8B:  JMP $1AB4      ;resume parsing script


;Command Script #$F7

LC21B8E:  TYX
LC21B8F:  LDA #$23
LC21B91:  STA $3A7A      ;command is Battle Event
LC21B94:  LDA $3A2D      ;script byte 1
LC21B97:  STA $3A7B      ;attack is index of Battle Event
LC21B9A:  JSR $4EAD      ;queue it.  script section we're running [indicated
                         ;by Bit 0 of $B1] determines which of entity's
                         ;queues used.
LC21B9D:  JMP $1AB4      ;resume parsing script


;Command Script #$FA

LC21BA0:  TYX
LC21BA1:  LDA $3A2D
LC21BA4:  XBA
LC21BA5:  LDA #$2B
LC21BA7:  REP #$20
LC21BA9:  STA $3A7A
LC21BAC:  LDA $3A2E
LC21BAF:  STA $B8
LC21BB1:  JSR $4EAD
LC21BB4:  JMP $1AB4      ;resume parsing script


;Command 06 for FC

LC21BB7:  JSR $1D34      ;Set who to check for using command 17
LC21BBA:  BCC LC21BC7    ;Exit if no counter for command 17
LC21BBC:  TDC
LC21BBD:  LDA $3A2F
LC21BC0:  XBA
LC21BC1:  REP #$20
LC21BC3:  LSR
LC21BC4:  CMP $3BF4,Y    ;Compare HP vs. second byte * 128
LC21BC7:  RTS


;Command 07 for FC

LC21BC8:  JSR $1D34      ;Do command 17 for FC
LC21BCB:  BCC LC21BD6    ;Exit if no counter for command 17
LC21BCD:  TDC
LC21BCE:  LDA $3A2F      ;Second byte for FC
LC21BD1:  REP #$20
LC21BD3:  CMP $3C08,Y    ;Compare MP vs. second byte
LC21BD6:  RTS


;Command 08 for FC

LC21BD7:  JSR $1D34      ;Do command 17 for FC
LC21BDA:  BCC LC21C25    ;Exit if no counter for command 17
LC21BDC:  LDA $3A2F      ;Second byte for FC
LC21BDF:  CMP #$10
LC21BE1:  BCC LC21BEE    ;Branch if less than 10
LC21BE3:  REP #$20
LC21BE5:  LDA $3A74      ;list of present and living characters and enemies
LC21BE8:  AND $FC
LC21BEA:  STA $FC
LC21BEC:  SEP #$20       ;Set 8-bit Accumulator
LC21BEE:  LDA #$10
LC21BF0:  TRB $3A2F      ;Second byte for FC
LC21BF3:  REP #$20       ;Set 16-bit Accumulator
LC21BF5:  BNE LC21BFC    ;If FC over 10
LC21BF7:  LDA #$3EE4
LC21BFA:  BRA LC21BFF
LC21BFC:  LDA #$3EF8
LC21BFF:  STA $FA
LC21C01:  LDX $3A2F      ;Second byte for FC
LC21C04:  JSR $1D2D      ;Set bit #X in A
LC21C07:  STA $EE
LC21C09:  LDY #$12
LC21C0B:  LDA ($FA),Y
LC21C0D:  BIT $EE
LC21C0F:  BNE LC21C16
LC21C11:  LDA $3018,Y
LC21C14:  TRB $FC
LC21C16:  DEY
LC21C17:  DEY
LC21C18:  BPL LC21C0B
LC21C1A:  CLC
LC21C1B:  LDA $FC
LC21C1D:  BEQ LC21C25
LC21C1F:  JSR $522A
LC21C22:  STA $FC
LC21C24:  SEC
LC21C25:  RTS


;Command 09 for FC

LC21C26:  JSR $1BD7      ;Do command 08 for FC
LC21C29:  JMP $1D26


;Command 1A for FC

LC21C2C:  JSR $1D34      ;Do command 17 for FC
LC21C2F:  BCC LC21C3A
LC21C31:  LDA $3BE0,Y
LC21C34:  BIT $3A2F
LC21C37:  BNE LC21C3A
LC21C39:  CLC
LC21C3A:  RTS


;Command 03 for FC - Counter Item usage

LC21C3B:  TYA
LC21C3C:  ADC #$13
LC21C3E:  TAY
LC21C3F:  INY            ;Command 02 for FC - counter Spell usage - jumps here
LC21C40:  TYX            ;Command 01 for FC - counter a command - jumps here
LC21C41:  LDY $3290,X    ;get $3290 or $3291 or $32A4, depending on where
                         ;we entered function.  this is the attacker index [or
                         ;in the case of reflection, the reflector] for the
                         ;the command/spell/item usage.
LC21C44:  BMI LC21C53
LC21C46:  LDA $3D48,X    ;get $3D48 or $3D49 or $3D5C, depending on where we
                         ;entered function.  attack's Command/Spell/Item ID.
LC21C49:  CMP $3A2E      ;does it match first parameter in script?
LC21C4C:  BEQ LC21C55    ;branch if so
LC21C4E:  CMP $3A2F      ;does it match second parameter in script?
LC21C51:  BEQ LC21C55    ;branch if so
LC21C53:  CLC
LC21C54:  RTS


LC21C55:  REP #$20
LC21C57:  LDA $3018,Y    ;get target bit of attacker index
LC21C5A:  STA $FC
LC21C5C:  SEC
LC21C5D:  RTS


;Command 04 for FC

LC21C5E:  TYA
LC21C5F:  ADC #$15
LC21C61:  TAX            ;could swap these 3 for "TYX" [and a needed "CLC"]
                         ;and use higher offsets below.  maybe this function
                         ;was once intended to handle more commands?
LC21C62:  LDY $3290,X    ;get attacker index.  [or in the case of reflection,
                         ;the reflector.]  accessed as $32A5 in C2/35E3.
LC21C65:  BMI LC21C6F
LC21C67:  LDA $3D48,X    ;get attack's element(s.  accessed as $3D5D
                         ;in C2/35E3.
LC21C6A:  BIT $3A2E      ;compare to script element(s) [1st byte for FC]
LC21C6D:  BNE LC21C55    ;branch if any matches
LC21C6F:  RTS


;Command 05 for FC

LC21C70:  TYX
LC21C71:  LDY $327C,X    ;last attacker [original, not any reflector] to do
                         ;damage to this target, not including the target
                         ;itself
LC21C74:  BMI LC21C7E    ;branch if none
LC21C76:  REP #$20
LC21C78:  LDA $3018,Y
LC21C7B:  STA $FC
LC21C7D:  SEC
LC21C7E:  RTS


;Command 16 for FC

LC21C7F:  REP #$20
LC21C81:  LDA $3A44      ;get Global battle time counter
LC21C84:  BRA LC21C8B


;<>Command 0B for FC

LC21C86:  REP #$20
LC21C88:  LDA $3DC0,Y    ;get monster time counter
LC21C8B:  LSR            ;divide timer by 2 before comparing to script
                         ;value
LC21C8C:  CMP $3A2E
LC21C8F:  RTS


;Command 0D for FC

LC21C90:  LDX $3A2E      ;First byte for FC
LC21C93:  JSR $1E45      ;$EE = variable #X
LC21C96:  LDA $EE
LC21C98:  CMP $3A2F
LC21C9B:  RTS


;Command 0C for FC

LC21C9C:  JSR $1C90      ;Do command 0D for FC
LC21C9F:  JMP $1D26


;Command 14 for FC

LC21CA2:  LDX $3A2F      ;Second byte for FC
LC21CA5:  JSR $1D2D      ;Set bit #X in A
LC21CA8:  LDX $3A2E      ;First byte for FC
LC21CAB:  JSR $1E45      ;$EE = variable #X
LC21CAE:  BIT $EE
LC21CB0:  BEQ LC21CB3
LC21CB2:  SEC
LC21CB3:  RTS


;Command 15 for FC

LC21CB4:  JSR $1CA2      ;Do command 14 for FC
LC21CB7:  JMP $1D26


;Command 0F for FC

LC21CBA:  JSR $1D34      ;Do command 17 for FC
LC21CBD:  BCC LC21CC5
LC21CBF:  LDA $3B18,Y    ;Level
LC21CC2:  CMP $3A2F
LC21CC5:  RTS


;Command 0E for FC

LC21CC6:  JSR $1CBA      ;Do command 0F for FC
LC21CC9:  JMP $1D26


;Command 10 for FC

LC21CCC:  LDA #$01
LC21CCE:  CMP $3ECA      ;Only counter if one type of monster active
                         ;specifically, this variable is the number of
                         ;unique enemy names still active in battle.
                         ;it's capped at 4, since it's based on the
                         ;enemy list on the bottom left of the screen
                         ;in battle, but that limitation doesn't matter
                         ;since we're only comparing it to #$01 here.
LC21CD1:  RTS


;Command 19 for FC

LC21CD2:  LDA $3019,Y
LC21CD5:  BIT $3A2E
LC21CD8:  BEQ LC21CDB
LC21CDA:  SEC
LC21CDB:  RTS


;Command 11 for FC

LC21CDC:  JSR $1DEE      ;if first byte of FC command is 0,
                         ;set it to current monster
LC21CDF:  LDA $3A75      ;list of present and living enemies
LC21CE2:  BRA LC21CEF


;<>Command 12 for FC

LC21CE4:  STZ $F8        ;tell caller not to prohibit any script commands
                         ;will be of use if this one passes.
LC21CE6:  JSR $1DEE      ;if first byte of FC command is 0,
                         ;set it to current monster
LC21CE9:  LDA $3A73      ;bitfield of monsters in formation
LC21CEC:  EOR $3A75      ;exclude present and living enemies
LC21CEF:  AND $3A2E
LC21CF2:  CMP $3A2E      ;does result include at least all targets marked
                         ;in first FC byte?
LC21CF5:  CLC            ;default to false
LC21CF6:  BNE LC21CF9    ;exit if above answer is no
LC21CF8:  SEC            ;return true
LC21CF9:  RTS


;Command 13 for FC

LC21CFA:  LDA $3A2E      ;First byte for FC
LC21CFD:  BNE LC21D06    ;branch if it indicates we're testing enemy party
LC21CFF:  LDA $3A76      ;Number of present and living characters in party
LC21D02:  CMP $3A2F      ;Second byte for FC
LC21D05:  RTS

LC21D06:  LDA $3A2F      ;Second byte for FC
LC21D09:  CMP $3A77      ;Number of monsters left in combat
LC21D0C:  RTS


;Command 18 for FC

LC21D0D:  LDA $1EDF
LC21D10:  BIT #$08       ;is Gau enlisted and not Leapt?
LC21D12:  BNE LC21D15    ;branch if so
LC21D14:  SEC
LC21D15:  RTS


;Command 1B for FC

LC21D16:  REP #$20
LC21D18:  LDA $3A2E      ;First byte for FC
LC21D1B:  CMP $11E0      ;Battle formation
LC21D1E:  BEQ LC21D21
LC21D20:  CLC
LC21D21:  RTS


;Command 1C for FC

LC21D22:  STZ $F8        ;tell caller not to prohibit any script commands
LC21D24:  SEC            ;always return true
LC21D25:  RTS


;Toggle the Carry Flag.  Will also zero Bit 7 of A for no good reason,
; but callers overwrite A afterwards anyway.)

LC21D26:  SEP #$20
LC21D28:  ROL
LC21D29:  EOR #$01
LC21D2B:  LSR            ;would change to ROR if we wanted
                         ;A unchanged
LC21D2C:  RTS


;Sets bit #X in A (C2/1E57 and this are identical

LC21D2D:  TDC
LC21D2E:  SEC
LC21D2F:  ROL
LC21D30:  DEX
LC21D31:  BPL LC21D2F
LC21D33:  RTS


;Command 17 for FC

LC21D34:  LDA $3A2E      ;Load first byte for FC
LC21D37:  PHA            ;Put on stack
LC21D38:  SEC
LC21D39:  JSR $1F25      ;Set target using first byte as parameter
LC21D3C:  BCC LC21D49    ;If invalid or no targets
LC21D3E:  REP #$20       ;Set 16-bit Accumulator
LC21D40:  LDA $B8
LC21D42:  STA $FC
LC21D44:  JSR $51F9      ;Y = highest targest number * 2
LC21D47:  SEP #$21
LC21D49:  PLA
LC21D4A:  PHP
LC21D4B:  CMP #$36
LC21D4D:  BNE LC21D53    ;Branch if not targeting self
LC21D4F:  STZ $FC        ;Clear character targets
LC21D51:  STZ $FC        ;Clear them again.  why??
LC21D53:  PLP
LC21D54:  RTS


;Code pointers for command #$FC

LC21D55: dw $1D2C     ;(00) (No counter)
LC21D57: dw $1C40     ;(01) (Command counter)
LC21D59: dw $1C3F     ;(02) (Spell counter)
LC21D5B: dw $1C3B     ;(03) (Item counter)
LC21D5D: dw $1C5E     ;(04) (Elemental counter)
LC21D5F: dw $1C70     ;(05) (Counter if damaged)
LC21D61: dw $1BB7     ;(06) (HP low counter)
LC21D63: dw $1BC8     ;(07) (MP low counter)
LC21D65: dw $1BD7     ;(08) (Status counter)
LC21D67: dw $1C26     ;(09) (Status counter (counter if not present))
LC21D69: dw $1D2C     ;(0A) (No counter)
LC21D6B: dw $1C86     ;(0B) (Counter depending on time monster has been alive)
LC21D6D: dw $1C9C     ;(0C) (Variable counter (less than))
LC21D6F: dw $1C90     ;(0D) (Variable counter (greater than or equal to))
LC21D71: dw $1CC6     ;(0E) (Level counter (less than))
LC21D73: dw $1CBA     ;(0F) (Level counter (greater than or equal to))
LC21D75: dw $1CCC     ;(10) (Counter if only one type of monster alive)
LC21D77: dw $1CDC     ;(11) (Counter if target alive)
LC21D79: dw $1CE4     ;(12) (Counter if target dead (final attack))
LC21D7A: dw $1CFA     ;(13) (if first byte is 0, check for # of characters, if 1, check for
                      ;       # of monsters
LC21D7D: dw $1CA2     ;(14) (Variable bit check)
LC21D7F: dw $1CB4     ;(15) (Variable bit check (inverse))
LC21D81: dw $1C7F     ;(16) (Counter depending on time combat has lasted)
LC21D83: dw $1D34     ;(17) (Aims like F1, Counter if valid target(s))
LC21D85: dw $1D0D     ;(18) (Counter if party hasn't gotten Gau (or Gau has leaped and is
                      ;       on Veldt)
LC21D87: dw $1CD2     ;(19) (Counter depending on monster # in formation)
LC21D89: dw $1C2C     ;(1A) (Weak vs. element counter)
LC21D8B: dw $1D16     ;(1B) (Counter if specific battle formation)
LC21D8D: dw $1D22     ;(1C) (Always counter (ignores Quick on other entity))


;Code pointers for control commands (monster scripts

LC21D8F: dw $1B22     ;(F0)
LC21D91: dw $1B47     ;(F1)
LC21D93: dw $1B6E     ;(F2)
LC21D95: dw $1B66     ;(F3)
LC21D97: dw $1B1C     ;(F4)
LC21D99: dw $1B57     ;(F5)
LC21D9B: dw $1B05     ;(F6)
LC21D9D: dw $1B8E     ;(F7)
LC21D9F: dw $1B72     ;(F8)
LC21DA1: dw $1B76     ;(F9)
LC21DA3: dw $1BA0     ;(FA)
LC21DA5: dw $1B6A     ;(FB)
LC21DA7: dw $1A91     ;(FC)
LC21DA9: dw $1A74     ;(FD)
LC21DAB: dw $1A7B     ;(FE)
LC21DAD: dw $1A7B     ;(FF)


;# of bytes for control command

LC21DAF: db $04   ;(F0)
LC21DB0: db $02   ;(F1)
LC21DB1: db $04   ;(F2)
LC21DB2: db $03   ;(F3)
LC21DB3: db $04   ;(F4)
LC21DB4: db $04   ;(F5)
LC21DB5: db $04   ;(F6)
LC21DB6: db $02   ;(F7)
LC21DB7: db $03   ;(F8)
LC21DB8: db $04   ;(F9)
LC21DB9: db $04   ;(FA)
LC21DBA: db $03   ;(FB)
LC21DBB: db $04   ;(FC)
LC21DBC: db $01   ;(FD)
LC21DBD: db $01   ;(FE)
LC21DBE: db $01   ;(FF)


;Figure what type of attack it is (spell, esper, blitz, etc. , and
;return command in A

LC21DBF:  PHX
LC21DC0:  PHA            ;Put on stack
LC21DC1:  XBA
LC21DC2:  PLA            ;Spell # is now in bottom of A and top of A
LC21DC3:  LDX #$0A
LC21DC5:  CMP $C21DD8,X  ;pick an attack category?
LC21DC9:  BCC LC21DD1    ;if attack is in a lower category, try the next one
LC21DCB:  LDA $C21DE3,X  ;choose a command
LC21DCF:  BRA LC21DD6
LC21DD1:  DEX
LC21DD2:  BPL LC21DC5
LC21DD4:  LDA #$02       ;if spell matched nothing in loop, it was between
                         ;0 and 35h, making it Magic command
LC21DD6:  PLX
LC21DD7:  RTS


;Data - used to delimit which spell #s are which command

LC21DD8: db $36        ;(Esper)
LC21DD9: db $51        ;(Skean)
LC21DDA: db $55        ;(Swdtech)
LC21DDB: db $5D        ;(Blitz)
LC21DDC: db $65        ;(Dance Move)
LC21DDD: db $7D        ;(Slot Move, or Tools??)
LC21DDE: db $82        ;(Shock)
LC21DDF: db $83        ;(Magitek)
LC21DE0: db $8B        ;(Enemy Attack / Lore)
LC21DE1: db $EE        ;(Battle, Special)
LC21DE2: db $F0        ;(Desperation Attack, Interceptor)


;Data - the command #

LC21DE3: db $19   ;(Summon)
LC21DE4: db $02   ;(Magic)
LC21DE5: db $07   ;(Swdtech)
LC21DE6: db $0A   ;(Blitz)
LC21DE7: db $02   ;(Magic)
LC21DE8: db $09   ;(Tools)
LC21DE9: db $1B   ;(Shock)
LC21DEA: db $1D   ;(Magitek)
LC21DEB: db $0C   ;(Lore)
LC21DEC: db $00   ;(Fight)
LC21DED: db $02   ;(Magic)


;If first byte of FC command is 0, set it to current monster.

LC21DEE:  LDA $3A2E
LC21DF1:  BNE LC21DF9
LC21DF3:  LDA $3019,Y
LC21DF6:  STA $3A2E
LC21DF9:  RTS


;Variable Manipulation
;Operand in bottom 6 bits of $B8, Operation in top 2 bits.
; Bits 7 and 6 =
;  0 and 0, or 0 and 1: Set variable to operand
;  1 and 0: Add operand to variable
;  1 and 1: Subtract operand from variable)

LC21DFA:  LDX $B6
LC21DFC:  JSR $1E45      ;Load variable X into $EE
LC21DFF:  LDA #$80
LC21E01:  TRB $B8        ;Clear bit 7 of byte 1
LC21E03:  BNE LC21E0A    ;Branch if bit 7 of byte 1 was set
LC21E05:  LSR            ;A = 40h, Carry clear
LC21E06:  TRB $B8        ;Clear bit 6 of byte 1
LC21E08:  STZ $EE
LC21E0A:  LDA $B8
LC21E0C:  BIT #$40
LC21E0E:  BEQ LC21E13    ;Branch if bit 6 of byte 1 is clear
LC21E10:  EOR #$BF       ;Toggle all but bit 6.  that bit is on and
                         ;bit 7 was off, so this gives us:
                         ;192 + (63 - (bottom 6 bits of $B8)).  clever!
LC21E12:  INC            ;so A = 256 - (bottom 6 bits of $B8.
                         ;iow, the negation of the 6-bit value.
LC21E13:  ADC $EE
LC21E15:  STA $EE
LC21E17:  JMP $1E38      ;Store $EE into variable X
                         ;BRA LC21E38?


;Code for command #$2F (used by #$F9 monster script command

LC21E1A:  LDX $B9        ;Byte 3
LC21E1C:  JSR $1E57      ;Set only bit #X in A
LC21E1F:  LDX $B8        ;Byte 2
LC21E21:  JSR $1E45      ;Load variable X into $EE
LC21E24:  DEC $B6        ;Byte 1: 0 for Toggle bit, 1 for Set bit,
                         ;2 for Clear bit
LC21E26:  BPL LC21E2C
LC21E28:  EOR $EE
LC21E2A:  BRA LC21E38
LC21E2C:  DEC $B6
LC21E2E:  BPL LC21E34
LC21E30:  ORA $EE
LC21E32:  BRA LC21E38
LC21E34:  EOR #$FF
LC21E36:  AND $EE
LC21E38:  CPX #$24
LC21E3A:  BCS LC21E41
LC21E3C:  STA $3EB0,X
LC21E3F:  BRA LC21E44
LC21E41:  STA $3DAC,Y
LC21E44:  RTS


;Load variable X into $EE

LC21E45:  PHA            ;Put on stack
LC21E46:  CPX #$24
LC21E48:  BCS LC21E4F
LC21E4A:  LDA $3EB0,X
LC21E4D:  BRA LC21E52
LC21E4F:  LDA $3DAC,Y
LC21E52:  STA $EE
LC21E54:  PLA
LC21E55:  CLC
LC21E56:  RTS


;Sets bit #X in A (C2/1D2D and this are identical

LC21E57:  TDC
LC21E58:  SEC
LC21E59:  ROL
LC21E5A:  DEX
LC21E5B:  BPL LC21E59
LC21E5D:  RTS


;Monster command script command #$FB

LC21E5E:  LDA $B6
LC21E60:  ASL
LC21E61:  TAX
LC21E62:  LDA $B8
LC21E64:  JMP ($1F09,X)


;Operation 0 for #$FB
;Clears monster time counter

LC21E67:  TDC
LC21E68:  STA $3DC0,Y
LC21E6B:  STA $3DC1,Y
LC21E6E:  RTS


;Operation 9 for #$FB

LC21E6F:  LDA #$0A
LC21E71:  BRA LC21E75
LC21E73:  LDA #$08       ;Operation 2 jumps here
LC21E75:  STA $3A6E      ;"End of combat" method #8, monster script command
LC21E78:  RTS


;Operation 1 for #$FB

LC21E79:  PHP
LC21E7A:  SEC
LC21E7B:  JSR $1F25
LC21E7E:  REP #$20
LC21E80:  LDA $B8
LC21E82:  TSB $3A3C      ;mark target(s) as invincible
LC21E85:  PLP
LC21E86:  RTS


;Operation 5 for #$FB

LC21E87:  PHP
LC21E88:  SEC
LC21E89:  JSR $1F25
LC21E8C:  REP #$20
LC21E8E:  LDA $B8
LC21E90:  TRB $3A3C      ;clear invincibility from target(s)
LC21E93:  PLP
LC21E94:  RTS


;Operation 6 for #$FB

LC21E95:  SEC
LC21E96:  JSR $1F25
LC21E99:  LDA $B9
LC21E9B:  TSB $2F46      ;make monster(s targetable again.  can undo
                         ;Operation 7 below, or untargetability
                         ;caused by formation data special event.
LC21E9E:  RTS


;Operation 7 for #$FB

LC21E9F:  SEC
LC21EA0:  JSR $1F25
LC21EA3:  LDA $B9
LC21EA5:  TRB $2F46      ;make monster(s) untargetable
LC21EA8:  RTS


;Operation 3 for #$FB

LC21EA9:  LDA #$08
LC21EAB:  TSB $1EDF      ;mark Gau as enlisted and not Leapt?
LC21EAE:  LDA $3ED9,Y    ;0-15 roster position of this party member
LC21EB1:  TAX
LC21EB2:  LDA $1850,X    ;get character roster information
                         ;Bit 7: 1 = party leader, as set in non-overworld areas
                         ;Bit 6: main menu presence?
                         ;Bit 5: row, 0 = front, 1 = back
                         ;Bit 3-4: position in party, 0-3
                         ;Bit 0-2: which party in; 1-3, or 0 if none
LC21EB5:  ORA #$40       ;turn on main menu presence?
LC21EB7:  AND #$E0       ;keep party leader flag, main menu presence, and row
                         ;flag
LC21EB9:  ORA $1A6D      ;combine with Active Party number [1-3]
LC21EBC:  STA $EE
LC21EBE:  TYA
LC21EBF:  ASL
LC21EC0:  ASL            ;convert target # into position in party
LC21EC1:  ORA $EE
LC21EC3:  STA $1850,X    ;save updated roster info
LC21EC6:  RTS


;Operation 4 for #$FB

LC21EC7:  STZ $3A44
LC21ECA:  STZ $3A45      ;zero Global battle time counter
LC21ECD:  RTS


;Operation 8 for #$FB
;Not used by any monster)

LC21ECE:  SEC            ;don't exclude Dead/Hidden/etc entities
                         ;from targets
LC21ECF:  JSR $1F25
LC21ED2:  BCC LC21ED9    ;branch if desired target(s) not found
LC21ED4:  LDA #$FF
LC21ED6:  STA $3AC9,Y    ;set top byte of own "Amount to increment
                         ;ATB Timer and Wait Timer" REALLY high.
                         ;iow, near-instantaneous ATB refill.
LC21ED9:  RTS


;Operation C for #$FB
;Quietly lose status)

LC21EDA:  JSR $1EEB      ;flag chosen status in attack data
LC21EDD:  LDA #$04
LC21EDF:  TSB $11A4      ;indicate Lift Status
LC21EE2:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Operation B for #$FB
;Quietly gain status)

LC21EE5:  JSR $1EEB      ;flag chosen status in attack data
LC21EE8:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


LC21EEB:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC21EEE:  CLC
LC21EEF:  LDA $B8        ;Get status # of 0-31
LC21EF1:  JSR $5217      ;X = A / 8, A = 2 ^ (A MOD 8)
LC21EF4:  ORA $11AA,X
LC21EF7:  STA $11AA,X    ;mark chosen status in attack's status
LC21EFA:  TYX
LC21EFB:  LDA #$12
LC21EFD:  STA $B5        ;Store Mimic in command for animation
LC21EFF:  RTS


;Operation D for #$FB

LC21F00:  LDA $3EF9,Y
LC21F03:  ORA #$20
LC21F05:  STA $3EF9,Y    ;Set Hide status on self
LC21F08:  RTS


;Code pointers for command #$FB

LC21F09: dw $1E67  ;(00)
LC21F0B: dw $1E79  ;(01)
LC21F0D: dw $1E73  ;(02)
LC21F0F: dw $1EA9  ;(03)
LC21F11: dw $1EC7  ;(04)
LC21F13: dw $1E87  ;(05)
LC21F15: dw $1E95  ;(06)
LC21F17: dw $1E9F  ;(07)
LC21F19: dw $1ECE  ;(08)
LC21F1B: dw $1E6F  ;(09)
LC21F1D: dw $1F08  ;(0A) (jumps to RTS)
LC21F1F: dw $1EE5  ;(0B)
LC21F21: dw $1EDA  ;(0C)
LC21F23: dw $1F00  ;(0D)


LC21F25:  PHX
LC21F26:  PHY
LC21F27:  PHA            ;Put on stack
LC21F28:  STZ $B8
LC21F2A:  LDX #$06
LC21F2C:  LDA $3ED8,X  ;(Which character it is
LC21F2F:  BMI LC21F36  ;(Branch if not present
LC21F31:  LDA $3018,X
LC21F34:  TSB $B8      ;(Set character as target
LC21F36:  DEX
LC21F37:  DEX
LC21F38:  BPL LC21F2C
LC21F3A:  STZ $B9      ;(Set no monsters as target
LC21F3C:  LDX #$0A
LC21F3E:  LDA $2002,X
LC21F41:  BMI LC21F48
LC21F43:  LDA $3021,X
LC21F46:  TSB $B9      ;(Set monster as target
LC21F48:  DEX
LC21F49:  DEX
LC21F4A:  BPL LC21F3E
LC21F4C:  BCS LC21F54
LC21F4E:  JSR $5A4D    ;(Remove dead and hidden targets
LC21F51:  JSR $5917
LC21F54:  PLA
LC21F55:  CMP #$30
LC21F57:  BCS LC21F6D
LC21F59:  LDX #$06
LC21F5B:  CMP $3ED8,X  ;(Which character it is
LC21F5E:  BNE LC21F67
LC21F60:  LDA $3018,X
LC21F63:  STA $B8
LC21F65:  BRA LC21FA1
LC21F67:  DEX
LC21F68:  DEX
LC21F69:  BPL LC21F5B
LC21F6B:  BRA LC21F9F
LC21F6D:  CMP #$36
LC21F6F:  BCS LC21F81
LC21F71:  SBC #$2F
LC21F73:  ASL
LC21F74:  TAX
LC21F75:  LDA $2002,X
LC21F78:  BMI LC21F9F
LC21F7A:  LDA $3021,X
LC21F7D:  STA $B9
LC21F7F:  BRA LC21FA8
LC21F81:  SBC #$36
LC21F83:  ASL
LC21F84:  TAX
LC21F85:  JMP ($2065,X)


;44

LC21F88:  STZ $B9
LC21F8A:  REP #$20
LC21F8C:  LDA $B8
LC21F8E:  JSR $522A   ;(randomly pick a bit that is set
LC21F91:  STA $B8
LC21F93:  REP #$20    ;(46 jumps here
LC21F95:  LDA $B8
LC21F97:  SEP #$21    ;(set 8-bit Accumulator, and
                      ;set Carry
LC21F99:  BNE LC21F9C
LC21F9B:  CLC
LC21F9C:  PLY
LC21F9D:  PLX
LC21F9E:  RTS

;47

LC21F9F:  STZ $B8
LC21FA1:  STZ $B9     ;(43 jumps here
LC21FA3:  BRA LC21F93

;37

LC21FA5:  JSR $202D
LC21FA8:  STZ $B8     ;(38 jumps here
LC21FAA:  BRA LC21F93

;39

LC21FAC:  JSR $202D
LC21FAF:  STZ $B8     ;(3A jumps here
LC21FB1:  BRA LC21F8A

;3B

LC21FB3:  JSR $2037
LC21FB6:  BRA LC21FA1

;3C

LC21FB8:  JSR $2037
LC21FBB:  BRA LC21F88

;3D

LC21FBD:  JSR $2037
LC21FC0:  BRA LC21FA8

;3E

LC21FC2:  JSR $2037
LC21FC5:  BRA LC21FAF

;3F

LC21FC7:  JSR $204E
LC21FCA:  BRA LC21FA1

;40

LC21FCC:  JSR $204E
LC21FCF:  BRA LC21F88

;41

LC21FD1:  JSR $204E
LC21FD4:  BRA LC21FA8

;42

LC21FD6:  JSR $204E
LC21FD9:  BRA LC21FAF

;4C

LC21FDB:  JSR $202D      ;Remove self as target
LC21FDE:  JSR $4B53      ;random: 0 or 1 in Carry
LC21FE1:  BCC LC21F8A
LC21FE3:  BRA LC21F93

;4D

LC21FE5:  LDX $32F5,Y
LC21FE8:  BMI LC21F9F    ;No targets
LC21FEA:  LDA #$FF
LC21FEC:  STA $32F5,Y
LC21FEF:  REP #$20
LC21FF1:  LDA $3018,X
LC21FF4:  STA $B8
LC21FF6:  JSR $5A4D      ;Remove dead and hidden targets
LC21FF9:  BRA LC21F93

;45

LC21FFB:  STZ $B8
LC21FFD:  STZ $B9
LC21FFF:  LDA $32E0,Y    ;get last entity to attack monster.
                         ;0-9 indicates a valid previous attacker.
                         ;7Fh indicates no previous attacker.
LC22002:  CMP #$0A
LC22004:  BCS LC21F93    ;branch if no previous attacker
LC22006:  ASL
LC22007:  TAX            ;turn our 0-9 index into the more common
                         ;0,2,4,6,8,10,12,14,16,18 index used to
                         ;address battle entities.
LC22008:  REP #$20
LC2200A:  LDA $3018,X
LC2200D:  STA $B8
LC2200F:  BRA LC21F93


;48) (49) (4A) (4B

LC22011:  TXA
LC22012:  SEC
LC22013:  SBC #$24
LC22015:  TAX
LC22016:  LDA $3AA0,X
LC22019:  LSR
LC2201A:  BCC LC21F9F
LC2201C:  LDA $3018,X
LC2201F:  STA $B8
LC22021:  BRA LC21FCA

;36

LC22023:  REP #$20
LC22025:  LDA $3018,Y
LC22028:  STA $B8
LC2202A:  JMP $1F93


;Remove self as target

LC2202D:  PHP
LC2202E:  REP #$20
LC22030:  LDA $3018,Y
LC22033:  TRB $B8
LC22035:  PLP
LC22036:  RTS


;Sets targets to all dead monsters and characters

LC22037:  PHP            ;Set 16-bit Accumulator
LC22038:  REP #$20
LC2203A:  STZ $B8        ;start off with no targets
LC2203C:  LDX #$12
LC2203E:  LDA $3EE3,X
LC22041:  BPL LC22048    ;Branch if not dead
LC22043:  LDA $3018,X
LC22046:  TSB $B8        ;mark entity as target
LC22048:  DEX
LC22049:  DEX
LC2204A:  BPL LC2203E    ;loop for all entities
LC2204C:  PLP
LC2204D:  RTS


;Sets all monsters and characters with Reflect status as targets

LC2204E:  PHP
LC2204F:  REP #$20       ;Set 16-bit Accumulator
LC22051:  STZ $B8        ;start off with no targets
LC22053:  LDX #$12
LC22055:  LDA $3EF7,X
LC22058:  BPL LC2205F    ;Branch if not Reflect status
LC2205A:  LDA $3018,X
LC2205D:  TSB $B8        ;mark entity as target
LC2205F:  DEX
LC22060:  DEX
LC22061:  BPL LC22055    ;loop for all entities
LC22063:  PLP
LC22064:  RTS


;Code pointers for command F1 targets

LC22065: dw $2023     ;(36)
LC22067: dw $1FA5     ;(37)
LC22069: dw $1FA8     ;(38)
LC2206B: dw $1FAC     ;(39)
LC2206D: dw $1FAF     ;(3A)
LC2206F: dw $1FB3     ;(3B)
LC22071: dw $1FB8     ;(3C)
LC22073: dw $1FBD     ;(3D)
LC22075: dw $1FC2     ;(3E)
LC22077: dw $1FC7     ;(3F)
LC22079: dw $1FCC     ;(40)
LC2207B: dw $1FD1     ;(41)
LC2207D: dw $1FD6     ;(42)
LC2207F: dw $1FA1     ;(43)
LC22081: dw $1F88     ;(44)
LC22083: dw $1FFB     ;(45)
LC22085: dw $1F93     ;(46)
LC22087: dw $1F9F     ;(47)
LC22089: dw $2011     ;(48)
LC2208B: dw $2011     ;(49)
LC2208D: dw $2011     ;(4A)
LC2208F: dw $2011     ;(4B)
LC22091: dw $1FDB     ;(4C)
LC22093: dw $1FE5     ;(4D)


;Recalculate applicable characters' properties from their current equipment and relics

LC22095:  LDX #$03
LC22097:  LDA $2F30,X    ;was character flagged to have his/her properties be
                         ;recalculated from his/her equipment at end of turn?
LC2209A:  BEQ LC220DA    ;skip to next character if not
LC2209C:  STZ $2F30,X    ;clear this character's flag
LC2209F:  PHX
LC220A0:  PHY
LC220A1:  TXA
LC220A2:  STA $EE
LC220A4:  ASL
LC220A5:  STA $EF        ;save X * 2
LC220A7:  ASL
LC220A8:  ADC $EE
LC220AA:  TAX            ;X = X * 5
LC220AB:  LDA $2B86,X    ;character's right hand in menu data
LC220AE:  XBA
LC220AF:  LDA $2B9A,X    ;character's left hand in menu data
LC220B2:  LDX $EF
LC220B4:  REP #$10       ;Set 16-bit X and Y
LC220B6:  LDY $3010,X    ;get offset to character info block
LC220B9:  STA $1620,Y    ;save contents of left hand in main character block
LC220BC:  XBA
LC220BD:  STA $161F,Y    ;save contents of right hand in main character block
LC220C0:  LDA $3EE4,X    ;in-battle Status Byte 1
LC220C3:  STA $1614,Y    ;update outside battle Status Byte 1
LC220C6:  SEP #$10       ;Set 8-bit X and Y
LC220C8:  LDA $3ED9,X    ;0-15 roster position of this party member
LC220CB:  JSR $C20E77    ;load equipment data for character in A
LC220CF:  JSR $286D      ;Initialize in-battle character properties from
                         ;equipment properties
LC220D2:  JSR $527D      ;Update availability of commands on character's
                         ;main menu - gray out or enable
LC220D5:  JSR $2675      ;make some equipment statuses permanent by setting
                         ;immunity to them.  also handle immunity to mutually
                         ;exclusive "mirror statuses".
LC220D8:  PLY
LC220D9:  PLX
LC220DA:  DEX
LC220DB:  BPL LC22097    ;loop for all 4 onscreen characters
LC220DD:  RTS


;Command #$2A
;Flee, or fail to, from running)

LC220DE:  LDA $2F45      ;party trying to run: 0 = no, 1 = yes
LC220E1:  BEQ LC22162    ;exit if not trying to run
LC220E3:  REP #$20
LC220E5:  LDA #$0902
LC220E8:  STA $3A28      ;default some animation variable to unsuccessful
                         ;run?
                         ;temporary bytes 1 and 2 for ($76) animation buffer
LC220EB:  SEP #$20
LC220ED:  LDA $B1
LC220EF:  BIT #$02       ;is Can't Run set?
LC220F1:  BNE LC2215F    ;branch if so
LC220F3:  LDA $3A38      ;characters who are ready to run
LC220F6:  BEQ LC22162    ;branch if none
LC220F8:  STA $B8        ;save copy of ready to run characters
LC220FA:  STZ $3A38      ;clear original list
LC220FD:  JSR $6400      ;Zero $A0 through $AF
LC22100:  LDX #$06
LC22102:  LDA $3018,X
LC22105:  TRB $B8        ;remove current party member from copy list
                         ;of ready to run characters
LC22107:  BEQ LC22144    ;skip to next party member if they were
                         ;never in it
LC22109:  XBA
LC2210A:  LDA $3219,X    ;top byte of ATB timer, which is zeroed
                         ;when the gauge is full
LC2210D:  BNE LC22144    ;it it's nonzero, the gauge isn't full,
                         ;so skip to next party member
LC2210F:  LDA $3AA0,X
LC22112:  BIT #$50       ;???
LC22114:  BNE LC22144
LC22116:  LSR            ;is entity even present in the battle?
LC22117:  BCC LC22144    ;skip to next party member if not
LC22119:  LDA $3EE4,X
LC2211C:  BIT #$02       ;Check for Zombie status
LC2211E:  BNE LC22144    ;branch if possessed
LC22120:  LDA $3EF9,X
LC22123:  BIT #$20
LC22125:  BNE LC22144    ;Branch if Hide status
LC22127:  XBA
LC22128:  TSB $B8        ;tell this function character is successfully
                         ;running
LC2212A:  TSB $3A39      ;add to list of escaped characters
LC2212D:  TSB $2F4C      ;mark runner to be removed from the battlefield
LC22130:  LDA $3AA1,X
LC22133:  ORA #$40
LC22135:  STA $3AA1,X    ;Set bit 6 of $3AA1
LC22138:  LDA $3204,X
LC2213B:  ORA #$40
LC2213D:  STA $3204,X    ;set bit 6 of $3204
LC22140:  JSR $07C8      ;Clear Zinger, Love Token, and Charm bonds, and
                         ;clear applicable Quick variables
LC22143:  TXY
LC22144:  DEX
LC22145:  DEX
LC22146:  BPL LC22102    ;loop for all 4 party members
LC22148:  LDA $B8        ;get successfully running characters
LC2214A:  BEQ LC22162    ;branch if none
LC2214C:  STZ $B9        ;no monster targets
LC2214E:  TYX
LC2214F:  JSR $57C2      ;Update $An variables with targets in $B8-$B9,
                         ;and do other stuff
LC22152:  JSR $63DB      ;Copy $An variables to ($78) buffer
LC22155:  REP #$20       ;set 16-bit Accumulator
LC22157:  LDA #$2206
LC2215A:  STA $3A28      ;change some animation variable to successful run?
                         ;temporary bytes 1 and 2 for ($76) animation buffer
LC2215D:  SEP #$20       ;set 8-bit Accumulator
LC2215F:  JSR $629E      ;Copy $3A28-$3A2B variables into ($76) buffer
LC22162:  RTS


;Process one record from Special Action linked list queue.  Note that unlike with
; other lists, all entities here are mingled together.)

LC22163:  PEA $0018      ;will return to C2/0019
LC22166:  PHA            ;Put on stack
LC22167:  ASL
LC22168:  TAY            ;adjust pointer for 16-bit fields
LC22169:  CLC
LC2216A:  JSR $0276      ;Load command, attack, targets, and MP cost from queued
                         ;data.  Some commands become Fight if tried by an Imp.
LC2216D:  PLA
LC2216E:  TAY            ;restore pointer for 8-bit fields
LC2216F:  LDA $3184,Y    ;get ID/pointer of first record in Special Action linked
                         ;list queue
LC22172:  CMP $340A      ;if that field's contents match record's position, it's
                         ;a standalone record, or the last in the list
LC22175:  BNE LC22179    ;branch if not, as there are more records left
LC22177:  LDA #$FF
LC22179:  STA $340A      ;either make entry point index next record, or null it
LC2217C:  LDA #$FF
LC2217E:  STA $3184,Y    ;null current first record in Special Action linked list
                         ;queue
LC22181:  LDA #$01
LC22183:  TSB $B1        ;indicate it's an unconventional attack
LC22185:  JMP $13D3      ;Character/Monster Takes One Turn


;Do early processing of one record from entity's conventional linked list queue, establish
; "time to wait", and visually enter ready stance if character)

LC22188:  LDA #$80
LC2218A:  JSR $5BAB
LC2218D:  LDA $3AA0,X
LC22190:  BIT #$50
LC22192:  BNE LC2220A
LC22194:  LDA $3AA1,X
LC22197:  AND #$7F       ;Clear bit 7
LC22199:  ORA #$01       ;Set bit 0
LC2219B:  STA $3AA1,X
LC2219E:  JSR $031C
LC221A1:  LDA $32CC,X    ;get entry point to entity's conventional linked list
                         ;queue
LC221A4:  BMI LC2220A    ;exit if null
LC221A6:  ASL
LC221A7:  TAY            ;adjust pointer for 16-bit fields
LC221A8:  LDA $3420,Y    ;get command from entity's conventional linked list
                         ;queue
LC221AB:  CMP #$1E
LC221AD:  BCS LC2220A    ;exit if not a normal character command.  iow,
                         ;if it was enemy Roulette, "Run Monster Script",
                         ;periodic damage/healing, etc.
LC221AF:  STA $2D6F      ;second byte of first entry of ($76) buffer
LC221B2:  CMP #$16       ;is it Jump?
LC221B4:  BEQ LC221BC    ;branch if so
LC221B6:  CPX #$08
LC221B8:  BCC LC221E6    ;branch if character
LC221BA:  BRA LC2220A    ;it's a monster [with no visible ready stance],
                         ;so exit
LC221BC:  LDA $3205,X
LC221BF:  BPL LC2220A    ;Exit function if entity has not taken a conventional
                         ;turn [including landing one] since boarding Palidor
LC221C1:  REP #$20
LC221C3:  CPX #$08
LC221C5:  BCS LC221D3    ;branch if monster, so it doesn't affect Mimic
LC221C7:  LDA #$0016
LC221CA:  STA $3F28      ;tell Mimic last command was Jump
LC221CD:  LDA $3520,Y    ;get targets from entity's conventional linked list
                         ;queue
LC221D0:  STA $3F2A      ;save last targets, Jump-specific, for Mimic
LC221D3:  LDA $3018,X
LC221D6:  TSB $3F2C      ;mark entity as a Jumper
LC221D9:  SEP #$20
LC221DB:  LDA $3EF9,X
LC221DE:  ORA #$20
LC221E0:  STA $3EF9,X    ;Set Hide Status
LC221E3:  JSR $5D26      ;Copy Current and Max HP and MP, and statuses to
                         ;displayable variables
LC221E6:  JSR $2639      ;Clear animation buffer pointers, extra strike
                         ;quantity, and various backup targets
LC221E9:  JSR $6400      ;Zero $A0 through $AF
LC221EC:  REP #$20
LC221EE:  LDA $3520,Y    ;get targets from entity's conventional linked list
                         ;queue
LC221F1:  STA $B8        ;save as current targets
LC221F3:  SEP #$20
LC221F5:  LDA #$0C
LC221F7:  STA $2D6E      ;first byte of first entry of ($76) buffer
LC221FA:  LDA #$FF
LC221FC:  STA $2D72      ;first byte of second entry of ($76) buffer
LC221FF:  JSR $57C2
LC22202:  JSR $63DB      ;Copy $An variables to ($78) buffer
LC22205:  LDA #$04
LC22207:  JSR $6411      ;Execute animation queue
LC2220A:  JMP $0019      ;branch to start of main battle loop


;Determine whether attack hits
;Result in Carry Flag: Clear = hit [includes Golem and Dog block], Set = miss)

LC2220D:  PHA            ;Put on stack
LC2220E:  PHX
LC2220F:  CLC            ;start off assuming hit
LC22210:  PHP            ;preserve Carry Flag, among others
LC22211:  SEP #$20       ;set 8-bit accumulator
LC22213:  STZ $FE
LC22215:  LDA $B3
LC22217:  BPL LC22235    ;Skip Clear check if bit 7 of $B3 not set
LC22219:  LDA $3EE4,Y
LC2221C:  BIT #$10       ;Check for Clear status
LC2221E:  BEQ LC22235    ;Branch if not vanished
LC22220:  LDA $11A4
LC22223:  ASL
LC22224:  BMI LC2222D    ;Branch if L.X spell
LC22226:  LDA $11A2
LC22229:  LSR
LC2222A:  JMP $22B3      ;If physical attack then miss, otherwise hit
LC2222D:  LDA $3DFC,Y
LC22230:  ORA #$10
LC22232:  STA $3DFC,Y    ;mark Clear status to be cleared.  that way,
                         ;it'll still be removed even if the attack
                         ;misses and C2/4406, which is what normally
                         ;removes Clear, is skipped.
LC22235:  LDA $11A3
LC22238:  BIT #$02       ;Check for not reflectable
LC2223A:  BNE LC2224B    ;Branch if ^
LC2223C:  LDA $3EF8,Y
LC2223F:  BPL LC2224B    ;Branch if target does not have Reflect
LC22241:  REP #$20       ;set 16-bit accumulator
LC22243:  LDA $3018,Y
LC22246:  TSB $A6        ;turn on target in "reflected off of" byte
LC22248:  JMP $22E5      ;Always miss if reflecting off target
LC2224B:  LDA $11A2
LC2224E:  BIT #$02       ;Check for spell miss if instant death protected
LC22250:  BEQ LC22259    ;Branch if not ^
LC22252:  LDA $3AA1,Y
LC22255:  BIT #$04
LC22257:  BNE LC222B5    ;Always miss if Protected from instant death
LC22259:  LDA $11A2
LC2225C:  BIT #$04       ;Check for hit only (dead XOR undead) targets
LC2225E:  BEQ LC22268
LC22260:  LDA $3EE4,Y
LC22263:  EOR $3C95,Y    ;death status XOR undead attribute
LC22266:  BPL LC222B5    ;If neither or both of above set, then miss
LC22268:  LDA $B5
LC2226A:  CMP #$00
LC2226C:  BEQ LC22272    ;Branch if command is Fight
LC2226E:  CMP #$06
LC22270:  BNE LC222A1    ;Branch if command not Capture
LC22272:  LDA $11A9
LC22275:  BNE LC222A1    ;Branch if has special effect
LC22277:  LDA $3EC9
LC2227A:  CMP #$01
LC2227C:  BNE LC222A1    ;branch if # of targets isn't 1
LC2227E:  CPY #$08
LC22280:  BCS LC222A1    ;Branch if target is monster
LC22282:  LDA $3EF9,Y
LC22285:  ASL
LC22286:  BPL LC22293    ;Branch if not dog block
LC22288:  JSR $4B53      ;0 or 1
LC2228B:  BCC LC22293    ;50% chance
LC2228D:  LDA #$40
LC2228F:  STA $FE        ;set dog block animation flag
LC22291:  BRA LC222B5    ;Miss
LC22293:  LDA $3A36
LC22296:  ORA $3A37
LC22299:  BEQ LC222A1    ;Branch if no Golem
LC2229B:  LDA #$20
LC2229D:  STA $FE        ;set golem block animation flag
LC2229F:  BRA LC222B5    ;Miss
LC222A1:  LDA $11A4
LC222A4:  BIT #$20       ;Check for can't be dodged
LC222A6:  BNE LC222E8    ;Always hit if can't be dodged
LC222A8:  BIT #$40
LC222AA:  BNE LC222EC    ;Check if hit for L? Spells
LC222AC:  BIT #$10
LC222AE:  BEQ LC222FB    ;Check if hit if Stamina not involved
LC222B0:  JSR $239C      ;Check if hit if Stamina involved
LC222B3:  BCC LC222E8    ;branch if hits
LC222B5:  LDA $3EE4,Y
LC222B8:  BIT #$1A       ;Check target for Clear, M-Tek, or Zombie
LC222BA:  BNE LC222D1    ;Always miss if ^
LC222BC:  CPY #$08       ;Check if target is monster
LC222BE:  BCS LC222D1    ;Always miss if ^
LC222C0:  JSR $23BF      ;Determine miss animation
LC222C3:  CMP #$06
LC222C5:  BCC LC222D1    ;if it's not Golem or Dog Block, always miss
LC222C7:  LDX #$03
LC222C9:  STZ $11AA,X    ;Clear all status modifying effects of attack
LC222CC:  DEX
LC222CD:  BPL LC222C9
LC222CF:  BRA LC222E8    ;Always hit [Carry will be cleared]
LC222D1:  LDA #$02
LC222D3:  TSB $B2        ;Set no critical and ignore True Knight
LC222D5:  STZ $3A89      ;turn off random weapon spellcast
LC222D8:  LDA $341C      ;0 if current strike is missable weapon spellcast
LC222DB:  BEQ LC222E5    ;if it is, skip flagging the "Miss" message,
                         ;since we'll be skipping the animation
                         ;entirely.
LC222DD:  REP #$20
LC222DF:  LDA $3018,Y
LC222E2:  TSB $3A5A      ;Set target as missed
LC222E5:  PLP
LC222E6:  SEC            ;Makes attack miss
LC222E7:  PHP
LC222E8:  PLP
LC222E9:  PLX
LC222EA:  PLA
LC222EB:  RTS


;Determines if attack hits for L? spells

LC222EC:  LDX $11A8      ;Hit Rate
LC222EF:  TDC
LC222F0:  LDA $3B18,Y    ;Level
LC222F3:  JSR $4792      ;Division, X = Hit Rate MOD Level
LC222F6:  TXA
LC222F7:  BNE LC222D1    ;Always miss
LC222F9:  BRA LC222E8    ;Always Hit


;Determines if attack hits

LC222FB:  PEA $8040      ;Sleep, Petrify
LC222FE:  PEA $0210      ;Freeze, Stop
LC22301:  JSR $5864
LC22304:  BCC LC222E8    ;Always hit if any set
LC22306:  REP #$20
LC22308:  LDA $3018,Y
LC2230B:  BIT $3A54      ;Check if hitting in back
LC2230E:  SEP #$20       ;Set 8-bit A
LC22310:  BNE LC222E8    ;Always hit if hitting back of target
LC22312:  LDA $11A8      ;Hit Rate
LC22315:  CMP #$FF
LC22317:  BEQ LC222E8    ;Automatically hit if Hit Rate is 255
LC22319:  STA $EE
LC2231B:  LDA $11A2
LC2231E:  LSR
LC2231F:  BCC LC2233F    ;If Magic attack then skip this next code
LC22321:  LDA $3E4C,Y
LC22324:  LSR            ;Check for retort
LC22325:  BCS LC222E8    ;Always hits
LC22327:  LDA $3EE5,Y    ;Check for image status
LC2232A:  BIT #$04

;--------------------------------------------------
;Original Code)

LC2232C:  BEQ LC2233F    ;Branch if not Image status on target
LC2232E:  JSR $4B5A
LC22331:  CMP #$40       ;1 in 4 chance clear Image status
LC22333:  BCS LC222D1    ;Always misses
LC22335:  LDA $3DFD,Y
LC22338:  ORA #$04
LC2233A:  STA $3DFD,Y    ;Clear Image status
LC2233D:  BRA LC222D1    ;Always misses
LC2233F:  LDA $3B54,Y    ;255 - Evade * 2 + 1
LC22342:  BCS LC22347
LC22344:  LDA $3B55,Y    ;255 - MBlock * 2 + 1
LC22347:  PHA            ;Put on stack
LC22348:  BCC LC22388


;Evade Patch Applied

;LC2232C:  BEQ LC22345    ;Branch if not Image status on target
;LC2232E:  JSR $4B5A
;LC22331:  CMP #$40       ;1 in 4 chance clear Image status
;LC22333:  BCS LC222D1    ;Always misses
;LC22335:  LDA $3DFD,Y
;LC22338:  ORA #$04
;LC2233A:  STA $3DFD,Y    ;Clear Image status
;LC2233D:  BRA LC222D1    ;Always misses
;LC2233F:  LDA $3B55,Y    ;255 - MBlock * 2 + 1
;LC22342:  PHA            ;Put on stack
;LC22343:  BRA LC22388
;<>LC22345:  LDA $3B54,Y    ;255 - Evade * 2 + 1
;LC22348:  PHA            ;Put on stack
;LC22349:  NOP

;-------------------------------------------------

LC2234A:  LDA $3EE4,X
LC2234D:  LSR
LC2234E:  BCC LC22352    ;Branch if attacker not blinded [Dark status]
LC22350:  LSR $EE        ;Cut hit rate in half
LC22352:  LDA $3C58,Y
LC22355:  BIT #$04
LC22357:  BEQ LC2235B    ;Branch if no Beads
LC22359:  LSR $EE        ;Cut hit rate in half
LC2235B:  PEA $2003      ;Muddled, Dark, Zombie
LC2235E:  PEA $0404      ;Life 3, Slow
LC22361:  JSR $5864
LC22364:  BCS LC22372    ;Branch if none set on target
LC22366:  LDA $EE
LC22368:  LSR
LC22369:  LSR
LC2236A:  ADC $EE        ;Adds 1/4 to hit rate
LC2236C:  BCC LC22370
LC2236E:  LDA #$FF
LC22370:  STA $EE        ;if hit rate overflowed, set to 255
LC22372:  PEA $4204      ;Seizure, Near Fatal, Poison
LC22375:  PEA $0008      ;Haste
LC22378:  JSR $5864
LC2237B:  BCS LC22388    ;Branch if none set on target
LC2237D:  LDA $EE
LC2237F:  LSR $EE
LC22381:  LSR $EE
LC22383:  SEC
LC22384:  SBC $EE        ;Subtracts 1/4 from hit rate
LC22386:  STA $EE
LC22388:  PLA
LC22389:  XBA
LC2238A:  LDA $EE        ;Hit Rate
LC2238C:  JSR $4781      ;Multiply Evade/Mblock * Hit Rate
LC2238F:  XBA
LC22390:  STA $EE        ;High byte of Evade/Mblock * Hit Rate
LC22392:  LDA #$64
LC22394:  JSR $4B65      ;Random number 0 to 99
LC22397:  CMP $EE
LC22399:  JMP $22B3


;Check if hit if Stamina involved

LC2239C:  LDA $3B55,Y    ;MBlock
LC2239F:  XBA
LC223A0:  LDA $11A8      ;Hit Rate
LC223A3:  JSR $4781      ;Multiplication Function
LC223A6:  XBA
LC223A7:  STA $EE        ;High byte of Mblock * Hit Rate
LC223A9:  LDA #$64
LC223AB:  JSR $4B65      ;Random Number 0 to 99
LC223AE:  CMP $EE
LC223B0:  BCS LC223BE    ;Attack misses, so exit
LC223B2:  JSR $4B5A      ;Random Number 0 to 255
LC223B5:  AND #$7F       ;0 to 127
LC223B7:  STA $EE
LC223B9:  LDA $3B40,Y    ;Stamina
LC223BC:  CMP $EE
LC223BE:  RTS


;Dog/Golem/Equipment miss check

LC223BF:  PHY
LC223C0:  LDA $11A2
LC223C3:  LSR
LC223C4:  BCS LC223C7    ;Branch if physical attack
LC223C6:  INY            ;if it was magical, read from 3CE5,old_Y instead
LC223C7:  TDC
LC223C8:  LDA $3CE4,Y    ;shield/weapon miss animations
LC223CB:  ORA $FE        ;miss due to Interceptor/Golem
LC223CD:  BEQ LC223EB    ;Exit function if none of above
LC223CF:  JSR $522A      ;Pick a random bit that is set
LC223D2:  BIT #$40
LC223D4:  BEQ LC223D9    ;Branch if no dog protection
LC223D6:  STY $3A83      ;save character target in "Dog blocked" byte
LC223D9:  BIT #$20
LC223DB:  BEQ LC223E0    ;Branch if no Golem protection
LC223DD:  STY $3A82      ;save character target in "Golem blocked" byte
LC223E0:  JSR $51F0      ;X = position of highest [and only] bit that is set
LC223E3:  TYA
LC223E4:  LSR
LC223E5:  TAY            ;Y = Y DIV 2, so it won't matter if Y was incremented
                         ;above.  it now holds a 0-3 character #.
LC223E6:  TXA
LC223E7:  INC
LC223E8:  STA $00AA,Y    ;save the dodge animation type for this character?
LC223EB:  PLY
LC223EC:  RTS


;Initialize many things.  Called at battle start.

LC223ED:  PHP
LC223EE:  REP #$30       ;Set 16-bit A, X, & Y
LC223F0:  LDX #$0258
LC223F3:  STZ $3A20,X
LC223F6:  STZ $3C7A,X
LC223F9:  DEX
LC223FA:  DEX
LC223FB:  BPL LC223F3
LC223FD:  TDC
LC223FE:  DEC
LC223FF:  LDX #$0A0E
LC22402:  STA $2000,X
LC22405:  STA $2A10,X
LC22408:  DEX
LC22409:  DEX
LC2240A:  BPL LC22402
LC2240C:  STZ $2F44
LC2240F:  STZ $2F4C      ;clear list of entities to be removed from battlefield
LC22412:  STZ $2F4E      ;clear list of entities to enter battlefield
LC22415:  STZ $2F53      ;clear list of visually flipped entities
LC22418:  STZ $B0
LC2241A:  STZ $B2
LC2241C:  LDX #$2602
LC2241F:  LDY #$3018
LC22422:  LDA #$001B
LC22424:  MVN $C27E    ;copy C2/2602 - C2/261D to 7E/3018 - 7E/3033.
                         ;unique bits identifying entities, and starting
                         ;addresses of characters' Magic menus
LC22427:  LDA $11E0
LC2242B:  CMP #$01D7     ;Check for Short Arm, Long arm, Face formation
LC2242E:  SEP #$30       ;Set 8-bit A, X & Y
LC22430:  BNE LC22435    ;branch if it's not 1st tier of final 4-tier
                         ;multi-battle
LC22432:  STZ $3EE0      ;zero byte to indicate that we're in the final
                         ;4-tier multi-battle
LC22435:  LDX #$13
LC22437:  LDA $1DC9,X
LC2243A:  STA $3EB4,X
LC2243D:  DEX
LC2243E:  BPL LC22437
LC22440:  LDA $021E      ;1-60 frame counter
LC22443:  ASL
LC22444:  ASL            ;* 4, so it's now 4, 8, 12, ... , 236, 240
LC22445:  STA $BE        ;Save as RNG Table index
LC22447:  JSR $30E8      ;Loads battle formation data
LC2244A:  JSR $2F2F      ;load some character properties, and set up special
                         ;event for formation or for possible Gau Veldt return
LC2244D:  LDA #$80
LC2244F:  TRB $3EBB
LC22452:  LDA #$91
LC22454:  TRB $3EBC      ;clear event bits indicating battle ended in loss,
                         ;Warp/escape, or full-party Engulfing
LC22457:  LDX #$12
LC22459:  JSR $4B5A      ;random: 0 to 255
LC2245C:  STA $3AF0,X    ;Store it.  This randomization serves to stagger when
                         ;entities get periodic damage/healing from Seizure,
                         ;Regen, Phantasm, Poison, or from being a Tentacle
                         ;who's Seize draining.
LC2245F:  LDA #$BC
LC22461:  CPX $3EE2      ;is this target Morphed?
LC22464:  BNE LC22468    ;branch if not
LC22466:  ORA #$02
LC22468:  STA $3204,X
LC2246B:  DEX
LC2246C:  DEX
LC2246D:  BPL LC22459    ;iterate for all 10 entities
LC2246F:  JSR $2544
LC22472:  LDA $1D4D      ;from Configuration menu: Battle Mode, Battle Speed,
                         ;Message Speed, and Command Set
LC22475:  BMI LC2247A    ;branch if "Short" Command Set
LC22477:  STZ $2F2E      ;otherwise, it's "Window"
LC2247A:  BIT #$08       ;is "Wait" Battle Mode set?
LC2247C:  BEQ LC22481    ;branch if not, meaning it's Active
LC2247E:  INC $3A8F
LC22481:  AND #$07       ;Isolate Battle Speed.  Note that its actual value
                         ;ranges from 0 to 5, but the menu choices the player
                         ;sees are 1 thru 6.
LC22483:  ASL
LC22484:  ASL
LC22485:  ASL
LC22486:  STA $EE        ;Battle Speed * 8
LC22488:  ASL            ;'' * 16
LC22489:  ADC $EE        ;'' * 24
LC2248B:  EOR #$FF
LC2248D:  STA $3A90      ;= 255 - (Battle Speed * 24)
                         ;this variable is a multiplier which is used for
                         ;slowing down enemies in the Battle Time Counter
                         ;Function at C2/09D2.  as you can see here and
                         ;from experience, a Battle Speed of zero will leave
                         ;enemies the fastest.
LC22490:  LDA $1D4E      ;from Configuration menu: Window Background #, Reequip,
                         ;Sound, Cursor, and Gauge
LC22493:  BPL LC22498    ;branch if the Gauge is not disabled
LC22495:  STZ $2021      ;zero for gauge disabling [was set to FFh at C2/2402]
LC22498:  STZ $2F41      ;clear "in a menu" flag
LC2249B:  JSR $546E      ;Construct in-battle Item menu, equipment sub-menus, and
                         ;possessed Tools bitfield, based off of equipped and
                         ;possessed items.
LC2249E:  JSR $580C      ;Construct Dance and Rage menus, and get number of known
                         ;Blitzes and highest known SwdTech index
LC224A1:  JSR $2EE1      ;Initialize some enemy presence variables, and load enemy
                         ;names and stats
LC224A4:  JSR $4391      ;update status effects for all applicable entities
LC224A7:  JSR $069B      ;Do various responses to three mortal statuses
LC224AA:  LDA #$14
LC224AC:  STA $11AF      ;treat attacker level as 20 for purpose of
                         ;initializing Condemned counters
LC224AF:  JSR $083F
LC224B2:  JSR $4AB9      ;Update lists and counts of present and/or living
                         ;characters and monsters
LC224B5:  JSR $2E3A      ;Determine if front, back, pincer, or side attack
LC224B8:  JSR $26C9      ;Give immunity to permanent statuses, and handle immunity
                         ;to "mirror" statuses, for all entities.
LC224BB:  JSR $2E68      ;Disable Veldt return on all but Front attack, change rows
                         ;or see if preemptive attack when applicable
LC224BE:  JSR $2575      ;Initialize ATB Timers
LC224C1:  LDX #$00       ;start off with no message about encounter
LC224C3:  LDA $2F4B      ;extra formation data, byte 3
LC224C6:  BIT #$04
LC224C8:  BNE LC224EA    ;branch if "hide starting messages" set
LC224CA:  LDA $201F      ;get encounter type.  0 = front, 1 = back,
                         ;2 = pincer, 3 = side
LC224CD:  CMP #$01
LC224CF:  BNE LC224D5    ;branch if not back attack
LC224D1:  LDX #$23       ;"Back attack" message ID
LC224D3:  BRA LC224EA
LC224D5:  CMP #$02
LC224D7:  BNE LC224DD    ;branch if not pincer attack
LC224D9:  LDX #$25       ;"Pincer attack" message ID
LC224DB:  BRA LC224EA
LC224DD:  CMP #$03
LC224DF:  BNE LC224E3    ;branch if not side attack
LC224E1:  LDX #$24       ;"Side attack" message ID
LC224E3:  LDA $B0
LC224E5:  ASL
LC224E6:  BPL LC224EA    ;branch if not preemptive attack
LC224E8:  LDX #$22       ;"Preemptive attack" message ID
LC224EA:  TXY
LC224EB:  BEQ LC224F2    ;branch if no encounter message forthcoming
LC224ED:  LDA #$25       ;command which prepares text display
LC224EF:  JSR $4E91      ;queue it, in global Special Action queue
LC224F2:  JSR $5C73      ;Update Can't Escape, Can't Run, Run Difficulty, and
                         ;onscreen list of enemy names, based on currently present
                         ;enemies
LC224F5:  JSR $5C54      ;Copy ATB timer, Morph gauge, and Condemned counter to
                         ;displayable variables
LC224F8:  STZ $B8
LC224FA:  STZ $B9        ;clear targets, so any Jumps queued below will choose
                         ;theirs randomly?
LC224FC:  LDX #$06
LC224FE:  LDA $3018,X
LC22501:  BIT $3F2C
LC22504:  BEQ LC2251C    ;branch if not Jumping
LC22506:  LDA $3AA0,X
LC22509:  ORA #$28
LC2250B:  STA $3AA0,X
LC2250E:  STZ $3219,X    ;zero top byte of ATB Timer
LC22511:  JSR $4E77      ;put character in action queue
LC22514:  LDA #$16
LC22516:  STA $3A7A      ;Jump command
LC22519:  JSR $4ECB      ;queue it, in entity's conventional queue
LC2251C:  DEX
LC2251D:  DEX
LC2251E:  BPL LC224FE    ;loop for all 4 party members
LC22520:  LDA $3EE1
LC22523:  INC
LC22524:  BEQ LC2253F    ;branch if not one of last 3 tiers of final
                         ;4-tier multi-battle?
LC22526:  DEC
LC22527:  STA $2D6F      ;second byte of first entry of ($76) buffer
LC2252A:  LDA #$12
LC2252C:  STA $2D6E      ;first byte of first entry of ($76) buffer
LC2252F:  LDA $3A75      ;list of present and living enemies
LC22532:  STA $2D71      ;fourth byte of first entry of ($76) buffer
LC22535:  LDA #$FF
LC22537:  STA $2D70      ;third byte of first entry of ($76) buffer
LC2253A:  STA $2D72      ;first byte of second entry of ($76) buffer
LC2253D:  LDA #$04
LC2253F:  JSR $6411      ;Execute animation queue
LC22542:  PLP
LC22543:  RTS


LC22544:  JSR $5551      ;Generate Lore menus based on known Lores, and generate
                         ;Magic menus based on spells known by ANY character.
                         ;upcoming C2/568D call will refine as needed.
LC22547:  LDX #$06
LC22549:  LDA $3ED8,X    ;Which character it is
LC2254C:  BMI LC22570    ;Branch if slot empty?
LC2254E:  CMP #$10
LC22550:  BCS LC22557    ;branch if character # is above 10h
LC22552:  TAY
LC22553:  TXA
LC22554:  STA $3000,Y    ;save 0, 2, 4, 6 party position of where this specific
                         ;character is found
LC22557:  LDA $3018,X
LC2255A:  TSB $3A8D      ;save active characters in list which will be checked by
                         ;battle ending code as pertains to Engulf
LC2255D:  LDA $3ED9,X    ;0-15 roster position of this party member
LC22560:  JSR $C20E77    ;load equipment data for character in A
LC22564:  JSR $286D      ;Initialize in-battle character properties from
                         ;equipment properties
LC22567:  JSR $27A8      ;copy character's out of battle stats into battle stats,
                         ;and mark out of battle and equipment statuses to be set
LC2256A:  JSR $568D      ;Generate a character's Esper menu, blank out unknown
                         ;spells from their Magic menu, and adjust spell and Lore
                         ;MP costs based on equipped Relics.
LC2256D:  JSR $532C      ;Change character commands when wearing MagiTek armor or
                         ;visiting Fanatics' Tower, or based on Relics.  Blank
                         ;certain commands.  Zero MP based on known
                         ;commands/spells.
LC22570:  DEX
LC22571:  DEX
LC22572:  BPL LC22549    ;iterate for all 4 party members
LC22574:  RTS


;Initialize ATB Timers

LC22575:  PHP
LC22576:  STZ $F3        ;zero General Incrementor
LC22578:  LDY #$12
LC2257A:  LDA $3AA0,Y
LC2257D:  LSR
LC2257E:  BCS LC22587    ;branch if entity is present in battle?
LC22580:  CLC
LC22581:  LDA #$10
LC22583:  ADC $F3
LC22585:  STA $F3        ;add 16 to $F3 [our General Incrementor] for
                         ;each entity shy of the possible 10
LC22587:  DEY
LC22588:  DEY
LC22589:  BPL LC2257A    ;loop for all 10 characters and monsters
LC2258B:  REP #$20       ;Set 16-bit accumulator
LC2258D:  LDA #$03FF     ;10 bits set, 10 possible entities in battle
LC22590:  STA $F0
LC22592:  LDY #$12
LC22594:  LDA $F0
LC22596:  JSR $522A      ;randomly choose one of the 10 bits [targets]
LC22599:  TRB $F0        ;and clear it, so it won't be used for
                         ;subsequent iterations of loop
LC2259B:  JSR $51F0      ;X = bit # of the chosen bit, thus a 0-9
                         ;target #
LC2259E:  SEP #$20       ;Set 8-bit accumulator
LC225A0:  TXA
LC225A1:  ASL
LC225A2:  ASL
LC225A3:  ASL
LC225A4:  STA $F2        ;save [0..9] * 8 in our Specific Incrementor
                         ;the result is that each entity is randomly
                         ;assigned a different value for $F2:
                         ;0, 8, 16, 24, 32, 40, 48, 56, 64, 72
LC225A6:  LDA $3219,Y    ;get top byte of ATB Timer
LC225A9:  INC
LC225AA:  BNE LC225FA    ;skip to next target if it wasn't FFh
LC225AC:  LDA $3EE1      ;FFh in every case, except for last 3 tiers
                         ;of final 4-tier multi-battle?
LC225AF:  INC
LC225B0:  BNE LC225FA    ;skip to next target if one of those 3 tiers
LC225B2:  LDX $201F      ;get encounter type.  0 = front, 1 = back,
                         ;2 = pincer, 3 = side
LC225B5:  LDA $3018,Y
LC225B8:  BIT $3A40      ;is target a character acting as enemy?
LC225BB:  BNE LC225D1    ;branch if so
LC225BD:  CPY #$08
LC225BF:  BCS LC225D1    ;branch if target is a monster
LC225C1:  LDA $B0
LC225C3:  ASL
LC225C4:  BMI LC225FA    ;skip to next target if Preemptive Attack
LC225C6:  DEX            ;decrement encounter type
LC225C7:  BMI LC225DE    ;branch if front attack
LC225C9:  DEX
LC225CA:  DEX
LC225CB:  BEQ LC225FA    ;skip to next target if side attack
LC225CD:  LDA $F2
LC225CF:  BRA LC225F3    ;it's a back or pincer attack
                         ;go set top byte of ATB timer to $F2 + 1
LC225D1:  LDA $B0        ;we'll reach here only if target is monster
                         ;or character acting as enemy
LC225D3:  ASL
LC225D4:  BMI LC225DA    ;branch if Preemptive Attack
LC225D6:  CPX #$03       ;checking encounter type again
LC225D8:  BNE LC225DE    ;branch if not side attack
LC225DA:  LDA #$01
LC225DC:  BRA LC225F3    ;go set top byte of ATB timer to 2
LC225DE:  LDA $3B19,Y    ;A = Speed
LC225E1:  JSR $4B65      ;random #: 0 to A - 1
LC225E4:  ADC $3B19,Y    ;A = random: Speed to ((2 * Speed) - 1)
LC225E7:  BCS LC225F1    ;branch if exceeded 255
LC225E9:  ADC $F2        ;add entity's Specific Incrementor, a
                         ;0,8,16,24,32,40,48,56,64,72 random boost
LC225EB:  BCS LC225F1    ;branch if exceeded 255
LC225ED:  ADC $F3        ;add our General Incrementor,
                         ;10 - number of valid entities) * 16
LC225EF:  BCC LC225F3    ;branch if byte didn't exceed 255
LC225F1:  LDA #$FF       ;if it overflowed, set it to FFh [255d]
LC225F3:  INC
LC225F4:  BNE LC225F7
LC225F6:  DEC            ;so A is incremented if it was < FFh
LC225F7:  STA $3219,Y    ;save top byte of ATB timer
LC225FA:  REP #$20
LC225FC:  DEY
LC225FD:  DEY
LC225FE:  BPL LC22594    ;loop for all 10 possible characters and
                         ;monsters
LC22600:  PLP
LC22601:  RTS


;Data to load into $3018 and $3019 - unique bits identifying entities

LC22602: dw $0001
LC22604: dw $0002
LC22606: dw $0004
LC22608: dw $0008
LC2260A: dw $0100
LC2260C: dw $0200
LC2260E: dw $0400
LC22610: dw $0800
LC22612: dw $1000
LC22614: dw $2000


;Data - starting addresses of characters' Magic menus

LC22616: dw $208E
LC22618: dw $21CA
LC2261A: dw $2306
LC2261C: dw $2442


LC2261E:  TDC            ;A = 0
LC2261F:  LDX #$5F
LC22621:  STA $3EE4,X
LC22624:  DEX
LC22625:  BPL LC22621    ;set $3EE4 through $3F43 to zero.  this includes all
                         ;four status bytes for all ten entities.
LC22627:  DEC            ;A = 255
LC22628:  LDX #$0F
LC2262A:  STA $3ED4,X
LC2262D:  DEX
LC2262E:  BPL LC2262A    ;set $3ED4 through $3EE3 to FFh
LC22630:  LDA #$12
LC22632:  STA $3F28      ;tell Mimic last command was something other than Jump
LC22635:  STA $3F24      ;Last command (second attack w/ Gem Box, for use by
                         ;Mimic.  indicate it as nonexistent.
LC22638:  RTS


;Clear animation buffer pointers, extra strike quantity, and various backup targets

LC22639:  PHP
LC2263A:  STZ $3A72      ;clear ($76) animation buffer pointer
LC2263D:  STZ $3A70      ;clear extra strike quantity -- iow, default to just one
                         ;strike
LC22640:  REP #$20
LC22642:  STZ $3A32      ;clear ($78) animation buffer pointer
LC22645:  STZ $3A34      ;clear simultaneous damage display buffer index?
LC22648:  STZ $3A30      ;clear backup [and temporary Mimic] targets
LC2264B:  STZ $3A4E      ;clear fallback targets to beat on for multi-strike attacks
                         ;when no valid targets left
LC2264E:  PLP
LC2264F:  RTS


;Turn Death immunity into Instant Death protection by moving it into another byte; otherwise you'd
; be bloody immortal.  If the Poison elemental is nullified, make immune to Poison status.)

LC22650:  LDA $3AA1,X
LC22653:  AND #$FB       ;Clear protection from "instant death"
LC22655:  XBA
LC22656:  LDA $331C,X    ;Blocked status byte 1
LC22659:  BMI LC22661    ;Branch if not block death
LC2265B:  ORA #$80       ;Clear block death
LC2265D:  XBA
LC2265E:  ORA #$04       ;Set protection from "instant death"
LC22660:  XBA
LC22661:  XBA
LC22662:  STA $3AA1,X
LC22665:  LDA $3BCD,X    ;Nullified elements
LC22668:  BIT #$08
LC2266A:  BEQ LC22670    ;Branch if not nullify poison
LC2266C:  XBA
LC2266D:  AND #$FB       ;Set block poison status if yes
LC2266F:  XBA
LC22670:  XBA
LC22671:  STA $331C,X
LC22674:  RTS


;Make some monster or equipment statuses permanent by setting immunity to them:
;  Mute, Berserk, Muddled, Seizure, Regen, Slow, Haste, Shell, Safe, Reflect, Float *

; * If Float is only marked in Monster status byte 4, it won't be permanent
;   [not to worry; no actual monsters do this].

; Then if you're immune to one status in a "mutually exclusive" pair, make immune to
; the other.  The pairs are Slow/Haste and Seizure/Regen.)

LC22675:  LDA $3331,X
LC22678:  XBA            ;put blocked status byte 4 in top of A.
                         ;note that blocked statuses = 0, susceptible ones = 1
LC22679:  LDA $3C6D,X    ;monster/equip status byte 3
LC2267C:  LSR
LC2267D:  BCC LC22683    ;if perm-Float (aka Dance) wasn't set, branch
LC2267F:  XBA
LC22680:  AND #$7F
LC22682:  XBA            ;if it^ was, then block Float.  thus the permanence.
LC22683:  LDA $3EBB
LC22686:  BIT #$04
LC22688:  BEQ LC2268E    ;branch if we're not in Phunbaba battle #4
                         ;[iow, Terra's second Phunbaba meeting]
LC2268A:  XBA
LC2268B:  AND #$F7       ;if we are, give immunity to Morph to make it permanent
LC2268D:  XBA
LC2268E:  XBA
LC2268F:  STA $3331,X    ;update blocked status #4.
                         ;note that blocked statuses = 0, susceptible ones = 1
LC22692:  LDA $3330,X
LC22695:  XBA
LC22696:  LDA $331D,X    ;A.top=blocked status byte 3, A.btm=blocked status #2
LC22699:  REP #$20
LC2269B:  STA $EE
LC2269D:  LDA $3C6C,X    ;monster/equip status bytes 2-3
LC226A0:  AND #$EE78     ;Dance, Stop, Sleep, Condemned, Near Fatal, Image will all be 0
LC226A3:  EOR #$FFFF     ;now they'll all be 1
LC226A6:  AND $EE        ;SO Blocked Statuses = what you were blocking before, plus
                         ;whatever the enemy/equip has.  with the exception of the
                         ;above.. which will only be blocked if they were before
LC226A8:  BIT #$0200
LC226AB:  BEQ LC226B2    ;if Regen blocked, branch
LC226AD:  BIT #$0040
LC226B0:  BNE LC226B5    ;if Seizure isn't blocked, branch
LC226B2:  AND #$FDBF     ;SO if Regen or Seizure is blocked, block both.
                         ;should explain Regen failing on Ribbon.
LC226B5:  SEP #$20
LC226B7:  STA $331D,X    ;update blocked status byte #2.  we'll update byte #3 below.
LC226BA:  XBA            ;now examine #3
LC226BB:  BIT #$04
LC226BD:  BEQ LC226C3    ;if Slow blocked, branch
LC226BF:  BIT #$08
LC226C1:  BNE LC226C5    ;if Haste isn't blocked, branch
LC226C3:  AND #$F3       ;SO if Slow or Haste is blocked, block 'em both.
                         ;should explain Slow failing on RunningShoes.
LC226C5:  STA $3330,X    ;update blocked status byte #3
LC226C8:  RTS


LC226C9:  LDX #$12       ;start from 6th enemy
LC226CB:  JSR $2675
LC226CE:  DEX
LC226CF:  DEX
LC226D0:  BPL LC226CB    ;and do Function $2675 for everybody in the battle
LC226D2:  RTS


;Load command and attack/sub-command data
;When called:
;  A Low = Command  (generally from $B5 or $3A7C)
;  A High = Attack/Sub-command  (generally from $B6 or $3A7D)

LC226D3:  PHX
LC226D4:  PHY
LC226D5:  PHA            ;Put on stack
LC226D6:  STZ $BA
LC226D8:  LDX #$40
LC226DA:  STX $BB        ;default to targeting byte just being
                         ;Cursor Start on Enemy
LC226DC:  LDX #$00
LC226DE:  CMP #$1E
LC226E0:  BCS LC22701    ;branch if command >= 1Eh , using default function
                         ;pointer of 0
LC226E2:  TAX
LC226E3:  LDA $C2278A,X  ;get miscellaneous Command properties byte
LC226E7:  PHA            ;Put on stack
LC226E8:  AND #$E1       ;isolate Abort on Characters, Randomize Target, beat on
                         ;corpses if no valid targets left, and Exclude Attacker
                         ;From Targets properties
LC226EA:  STA $BA
LC226EC:  LDA $01,S
LC226EE:  AND #$18       ;now check what will become Can Target Dead/Hidden Entities
                         ;and Don't Retarget if Target Invalid
LC226F0:  LSR
LC226F1:  TSB $BA
LC226F3:  TXA
LC226F4:  ASL
LC226F5:  TAX            ;multiply command number by 2
LC226F6:  LDA $CFFE01,X
LC226FA:  STA $BB        ;get the command's targeting from a table
LC226FC:  PLA
LC226FD:  AND #$06       ;two second lowest bits from C2/278A determine
                         ;what function to call next
LC226FF:  TAX
LC22700:  XBA            ;now get spell # or miscellaneous index.. ex- it might
                         ;indicate the item Number
LC22701:  JSR ($2782,X)
LC22704:  PLA
LC22705:  PLY
LC22706:  PLX
LC22707:  RTS


;Throw, Tools.  Item calls $271A.
LC22708:  LDX #$04
LC2270A:  CMP $C22778,X  ;is the tool or skean one that uses a spell?
LC2270E:  BNE LC22716    ;if not, branch
LC22710:  SBC $C2277D,X  ;if yes, subtract constant to determine its spell number
LC22714:  BRA LC2274D    ;see, certain Tools and Skeans just load spells to do
                         ;their work

                         ;Bio Blaster will use spell 7D, Bio Blast
                         ;Flash will use spell 7E, Flash
                         ;Fire Skean will use spell 51h, Fire Skean
                         ;Water Edge will use spell 52, Water Edge
                         ;Bolt Edge will use spell 53, Bolt Edge

LC22716:  DEX
LC22717:  BPL LC2270A    ;loop 5 times, provided we didn't jump out of the loop
LC22719:  SEC            ;set Carry, for check at C2/18BD
LC2271A:  STA $3411      ;save item #
LC2271D:  JSR $2B63      ;Multiply A by 30, size of item data block
LC22720:  REP #$10       ;Set 16-bit X and Y
LC22722:  TAX
LC22723:  LDA $D8500E,X  ;Targeting byte
LC22727:  STA $BB
LC22729:  LDA $D85015,X  ;Condition 1 when Item used
LC2272D:  BIT #$C2
LC2272F:  BNE LC22735    ;Branch if Death, Zombie, or Petrify set
LC22731:  LDA #$08
LC22733:  TRB $BA        ;Clear Can Target Dead/Hidden Entities
LC22735:  LDA $D85012,X  ;equipment spell byte.
                         ; Bits 0-5: spell #
                         ; Bit 6: cast randomly after weapon strike [handled
                         ;        elsewhere, shouldn't apply here]
                         ; Bit 7: 1 = remove from inventory upon usage, 0 = nope
LC22739:  SEP #$10       ;Set 8-bit X and Y
LC2273B:  RTS


;Item
LC2273C:  CMP #$E6       ;Carry is set if item # >= 230, Sprint Shoes.  i.e. it's
                         ;Item type.  Carry won't be set for Equipment Magic.
LC2273E:  JSR $271A      ;get Targeting byte, and make slight modification to
                         ;targeting if Item affects Wound/Zombie/Petrify.  also,
                         ;A = equipment spell byte
LC22741:  BCS LC22707    ;if it's a plain ol' Item, always deduct from inventory,
                         ;and don't attempt to save the [meaningless] spell # or
                         ;load spell data
LC22743:  BMI LC2274B    ;branch if equipment gets used up when used for Item Magic.
                         ;i'm not aware of any equipment this *doesn't* happen with,
                         ;though the game supports it.
LC22745:  XBA            ;preserve equipment spell byte
LC22746:  LDA #$10
LC22748:  TSB $B1        ;set "don't deplete from Item inventory" flag
LC2274A:  XBA
LC2274B:  AND #$3F       ;isolate spell # cast by equipment
LC2274D:  STA $3410      ;Magic and numerous other commands enter here
LC22750:  BRA LC22754    ;load spell data for [equipment] magic.  note that we rely
                         ;on that code keeping/making Carry clear.


LC22752:  LDA #$EE       ;select Spell EEh - Battle
LC22754:  JSR $2966      ;go load spell data
LC22757:  LDA $BB        ;targeting byte as read from $CFFE01 table?
LC22759:  INC
LC2275A:  BNE LC22761    ;branch if it wasn't FF.. if it was, it's null, so we use
                         ;the spell byte instead
LC2275C:  LDA $11A0      ;spell aiming byte
LC2275F:  STA $BB
LC22761:  LDA $11A2
LC22764:  PHA            ;Put on stack
LC22765:  AND #$04       ;Isolate bit 2.  This spell bit is used for two properties:
                         ;Bit 2 of $11A2 will be "Hit only (dead XOR undead targets",
                         ;and Bit 3 of $BA will be "Can Target Dead/Hidden entities".
LC22767:  ASL
LC22768:  TSB $BA        ;Sets Can Target Dead/Hidden entities
LC2276A:  LDA $01,S      ;get $11A2 again
LC2276C:  AND #$10       ;Randomize target
LC2276E:  ASL
LC2276F:  ASL
LC22770:  TSB $BA        ;Sets randomize target
LC22772:  PLA            ;get $11A2 again
LC22773:  AND #$80       ;Abort on characters
LC22775:  TSB $BA        ;Sets abort on characters
LC22777:  RTS


;Data - item numbers of Tools and Skeans that use spells to do a good chunk
; of their work)

LC22778: db $A4  ;(Bio Blaster)
LC22779: db $A5  ;(Flash)
LC2277A: db $AB  ;(Fire Skean)
LC2277B: db $AC  ;(Water Edge)
LC2277C: db $AD  ;(Bolt Edge)

;Data - constants we subtract from the above item #s to get the numbers
; of the spells they rely on)

LC2277D: db $27
LC2277E: db $27
LC2277F: db $5A
LC22780: db $5A
LC22781: db $5A


;Code Pointers (indexed by bits 1 and 2 of data values below

LC22782: dw $2752  ;(Fight, Morph, Revert, Steal, Capture, Runic, Sketch, Control, Leap, Mimic,
                   ; Row, Def, Jump, GP Rain, Possess
LC22784: dw $273C  ;(Item)
LC22786: dw $274D  ;(Magic, SwdTech, Blitz, Lore, Slot, Rage, Dance, X-Magic, Summon, Health,
                   ; Shock, MagiTek
LC22788: dw $2708  ;(Throw, Tools)


;Data - indexed by command # 0 thru 1Dh

LC2278A: db $20   ;(Fight)
LC2278B: db $1A   ;(Item)
LC2278C: db $04   ;(Magic)
LC2278D: db $18   ;(Morph)
LC2278E: db $18   ;(Revert)
LC2278F: db $00   ;(Steal)
LC22790: db $20   ;(Capture)
LC22791: db $24   ;(SwdTech)
LC22792: db $06   ;(Throw)
LC22793: db $06   ;(Tools)
LC22794: db $04   ;(Blitz)
LC22795: db $18   ;(Runic)
LC22796: db $04   ;(Lore)
LC22797: db $80   ;(Sketch)
LC22798: db $80   ;(Control)
LC22799: db $04   ;(Slot)
LC2279A: db $04   ;(Rage)
LC2279B: db $80   ;(Leap)
LC2279C: db $18   ;(Mimic)
LC2279D: db $04   ;(Dance)
LC2279E: db $18   ;(Row)
LC2279F: db $18   ;(Def)
LC227A0: db $21   ;(Jump)
LC227A1: db $04   ;(X-Magic)
LC227A2: db $01   ;(GP Rain)
LC227A3: db $04   ;(Summon)
LC227A4: db $04   ;(Health)
LC227A5: db $04   ;(Shock)
LC227A6: db $81   ;(Possess)
LC227A7: db $04   ;(MagiTek)


;Copy character's out of battle stats into their battle stats, and mark out of battle
; and equipment statuses to be set)

LC227A8:  PHP
LC227A9:  REP #$30       ;Set 16-bit Accumulator & Index Registers
LC227AB:  LDY $3010,X    ;get offset to character info block
LC227AE:  LDA $1609,Y    ;get current HP
LC227B1:  STA $3BF4,X    ;HP
LC227B4:  LDA $160D,Y    ;get current MP
LC227B7:  STA $3C08,X    ;MP
LC227BA:  LDA $160B,Y    ;get maximum HP
LC227BD:  JSR $283C      ;get max HP after equipment/relic boosts
LC227C0:  CMP #$2710
LC227C3:  BCC LC227C8
LC227C5:  LDA #$270F     ;if it was >= 10000, make it 9999
LC227C8:  STA $3C1C,X    ;Max HP
LC227CB:  LDA $160F,Y    ;get maximum MP
LC227CE:  JSR $283C      ;get max MP after equipment/relic boosts
LC227D1:  CMP #$03E8
LC227D4:  BCC LC227D9
LC227D6:  LDA #$03E7     ;if it was >= 1000, make it 999
LC227D9:  STA $3C30,X    ;Max MP
LC227DC:  LDA $3018,X    ;Holds $01 for character 1, $02 for character 2,
                         ;$04 for character 3, $08 for character 4
LC227DF:  BIT $B8        ;is this character a Colosseum combatant [indicated
                         ;by C2/2F2F turning on Bit 0, as the Colosseum fighter
                         ;is always Character 1] , or was he/she installed by
                         ;a special event?
LC227E1:  BEQ LC227F8    ;branch if neither
LC227E3:  LDA $3C1C,X    ;Max HP
LC227E6:  STA $3BF4,X    ;HP
LC227E9:  LDA $3C30,X    ;Max MP
LC227EC:  STA $3C08,X    ;MP
LC227EF:  LDA $1614,Y    ;outside battle statuses 1 and 2.  from tashibana doc
                         ;^ statuses correspond to in-battle statuses 1 and 4
LC227F2:  AND #$FF2D
LC227F5:  STA $1614,Y    ;remove Clear, Petrify, Death, Zombie
LC227F8:  LDA $3C6C,X    ;monster/equip status bytes 2-3
LC227FB:  SEP #$20       ;Set 8-bit Accumulator
LC227FD:  STA $3DD5,X    ;Status to set byte 2
LC22800:  LSR
LC22801:  BCC LC2280B    ;branch if Condemned not marked to be set
LC22803:  LDA $3204,X
LC22806:  AND #$EF
LC22808:  STA $3204,X    ;^ if it is going to be set, then turn off Bit 4
LC2280B:  LDA $1614,Y
LC2280E:  STA $3DD4,X    ;Status to set byte 1
LC22811:  BIT #$08
LC22813:  BEQ LC2281F    ;If not set M-Tek
LC22815:  LDA #$1D
LC22817:  STA $3F20      ;save MagiTek as default last command for Mimic
LC2281A:  LDA #$83
LC2281C:  STA $3F21      ;save Fire Beam as default last attack for Mimic
                         ;if Gogo uses Mimic before any other character acts in a
                         ;battle, he'll normally use Fight.  all i can figure is that
                         ;this code is here to make him use Fire Beam instead should
                         ;anybody be found to be wearing MagiTek armor -- in the normal
                         ;game, we can assume that if anybody's in armor, everybody
                         ;[including Gogo] is in it.

LC2281F:  LDA $1615,Y    ;outside battle status 2.  corresponds to
                         ;in-battle status byte 4
LC22822:  AND #$C0       ;only keep Dog Block and Float
LC22824:  XBA            ;get monster/equip status byte 3
LC22825:  LSR            ;shift out the lowest bit - Dance
LC22826:  BCC LC2282C    ;branch if Dance aka Permanent Float isn't set
LC22828:  XBA
LC22829:  ORA #$80       ;turn on Float in status byte 4
LC2282B:  XBA
LC2282C:  ASL            ;shift monster/equip status byte 3 back up, zeroing the
                         ;lowest bit
LC2282D:  STA $3DE8,X    ;Status to set byte 3
LC22830:  XBA
LC22831:  STA $3DE9,X    ;Status to set byte 4
LC22834:  LDA $1608,Y
LC22837:  STA $3B18,X    ;Level
LC2283A:  PLP
LC2283B:  RTS


;Apply percentage boost to HP or MP.  Bit 14 set = 25% boost,
; Bit 15 set = 50% boost, Both of those bits set = 12.5% boost)

LC2283C:  PHX
LC2283D:  ASL
LC2283E:  ROL
LC2283F:  STA $EE
LC22841:  ROL
LC22842:  ROL           ;(Bit 15 is now in Bit 2, and Bit 14 is in Bit 1
LC22843:  AND #$0006    ;(isolate Bits 1 and 2
LC22846:  TAX           ;(and use them as function pointer
LC22847:  LDA $EE
LC22849:  LSR
LC2284A:  LSR
LC2284B:  STA $EE       ;(all that crazy shifting was equivalent to
                        ; $EE = A AND 16383.  gotta love Square. =]
LC2284D:  JMP ($2859,X)


;Boost A by some fraction, if any

LC22850:  TDC           ;(enter here for A = 0 + $EE
LC22851:  LSR           ;(enter here for A = (A * 1/8) + $EE
LC22852:  LSR           ;(enter here for A = (A * 1/4) + $EE
LC22853:  LSR           ;(enter here for A = (A * 1/2) + $EE
LC22854:  CLC
LC22855:  ADC $EE
LC22857:  PLX
LC22858:  RTS


;Code Pointers

LC22859: dw $2850  ;(A = A) (technically, A = $EE, but it's the same deal.)
LC2285B: dw $2852  ;(A = A + (A * 1/4) )
LC2285D: dw $2853  ;(A = A + (A * 1/2) )
LC2285F: dw $2851  ;(A = A + (A * 1/8) )


;A = 255 - (A * 2 + 1
; If A was >= 128 to start with, then A = 1.
; If A was 0 to start with, then A ends up as 255.)

LC22861:  ASL
LC22862:  BCC LC22866
LC22864:  LDA #$FF
LC22866:  EOR #$FF
LC22868:  INC
LC22869:  BNE LC2286C
LC2286B:  DEC
LC2286C:  RTS


;Initialize in-battle character properties from equipment properties.
; A lot of the equipment bytes in this function were explained in C2/0E77, C2/0F9A, and C2/10B2,
; so consult those functions.  Terii's Offsets List at http://www.rpglegion.com/ff6/hack/offset2.txt
; is another great resource.)

LC2286D:  PHD
LC2286E:  PEA $1100         ;(Set direct page register 11 $1100
LC22871:  PLD
LC22872:  LDA $C9           ;($11C9
LC22874:  CMP #$9F          ;(Moogle Suit in character's Armor slot?
LC22876:  BNE LC22883       ;(if not, branch
LC22878:  TXA
LC22879:  ASL
LC2287A:  ASL
LC2287B:  ASL
LC2287C:  ASL
LC2287D:  TAY               ;(Y = X * 16
LC2287E:  LDA #$0A
LC22880:  STA $2EAE,Y       ;(Use Mog's sprite
LC22883:  TXA
LC22884:  LSR
LC22885:  TAY               ;(Y = X DIV 2
LC22886:  LDA $D8           ;($11D8
LC22888:  AND #$10
LC2288A:  STA $2E6E,Y       ;(store Genji Glove effect.  this variable is used in Bank C1,
                            ; apparently to check for Genji Glove's presence when handling
                            ; mid-battle equipment changes via the Item menu.
LC2288D:  CLC
LC2288E:  LDA $A6           ;($11A6
LC22890:  ADC $A6           ;($11A6)(add Vigor to itself
LC22892:  BCC LC22896       ;(branch if it's under 256
LC22894:  LDA #$FF          ;(else make it 255
LC22896:  STA $3B2C,X       ;(store Vigor * 2
LC22899:  LDA $A4           ;($11A4)(Speed
LC2289B:  STA $3B2D,X
LC2289E:  STA $3B19,X
LC228A1:  LDA $A2           ;($11A2)(Stamina
LC228A3:  STA $3B40,X
LC228A6:  LDA $A0           ;($11A0)(Magic Power
LC228A8:  STA $3B41,X
LC228AB:  LDA $A8           ;($11A8
LC228AD:  JSR $2861
LC228B0:  STA $3B54,X       ;( 255 - (Evade * 2) + 1 , capped at low of 1 and high of 255
LC228B3:  LDA $AA           ;($11AA
LC228B5:  JSR $2861
LC228B8:  STA $3B55,X       ;( 255 - (MBlock * 2) + 1 , capped at low of 1 and high of 255
LC228BB:  LDA $CF           ;($11CF
LC228BD:  TRB $D8           ;($11D8(clear Genji Glove effect from "Battle Effects 2" if its bit
						    ; was ON in $11CF [i.e. if both hands hold a weapon].  yes, this
						    ; reeks of a bug.  likely, they instead wanted the GG effect
						    ; cleared only when one or zero hands held a weapon.
LC228BF:  LDA $BC           ;($11BC
LC228C1:  STA $3C6C,X       ;(Equipment status byte 2
LC228C4:  LDA $D4           ;($11D4
LC228C6:  STA $3C6D,X       ;(Equipment status byte 3
LC228C9:  LDA $DC           ;($11DC
LC228CB:  STA $3D71,X       ;(Amount to add to character's "Run Success" variable.  has range
                            ; of 2 thru 5.  higher means that, on average, they can run away
                            ; quicker from battle.
LC228CE:  LDA $D9           ;($11D9
LC228D0:  AND #$80          ;(undead bit from relic ring
LC228D2:  ORA #$10          ;(always set Human for party members
LC228D4:  STA $3C95,X       ;(save in "Special Byte 3"
LC228D7:  LDA $D5           ;($11D5
LC228D9:  ASL               ;(A = 0, raise attack dmg, double earring, hp+25%, hp+50,
                            ; hp+12.5, mp+25, mp+50)  (carry = mp+12.5
LC228DA:  XBA
LC228DB:  LDA $D6           ;($11D6
LC228DD:  TSB $3A6D         ;(combine with existing "Battle Effects 1" properties
LC228E0:  ASL               ;(carry = jump continously
LC228E1:  LDA $D7           ;($11D7
LC228E3:  XBA
LC228E4:  ROR               ;(Top half A [will be $3C45] = $11D7 =
                            ; boost steal, single Earring, boost sketch,
                            ; boost control, sniper sight, gold hairpin,
                            ; economizer, vigor + 50%
                            ; Bottom half [will be $3C44] = raise attack dmg,
                            ; double Earring, hp+25%, hp+50%, hp+12.5%, mp+25%,
                            ; mp+50%, jump continuously.  The HP/MP bonuses
                            ; were already read from $11D5 earlier, so they're
                            ; essentially junk in $3C44.  All that's read are
                            ; Bits 0, 1, and 7.
LC228E5:  REP #$20          ;(Set 16-bit Accumulator
LC228E7:  STA $3C44,X
LC228EA:  LDA $AC           ;($11AC
LC228EC:  STA $3B68,X       ;($3B68 = battle power for 1st hand,
                            ; $3B69 = bat pwr for 2nd hand
LC228EF:  LDA $AE           ;($11AE
LC228F1:  STA $3B7C,X       ;(hit rate
LC228F4:  LDA $B4           ;($11B4
LC228F6:  STA $3D34,X       ;(random weapon spellcast, for both hands
LC228F9:  LDA $B0           ;($11B0
LC228FB:  STA $3B90,X       ;(elemental properties of weapon
LC228FE:  LDA $D8           ;($11D8
LC22900:  BIT #$0008        ;(is Gauntlet bit set?
LC22903:  BNE LC2290A
LC22905:  LDA #$4040        ;(if it's not, turn off 2-hand effect
                            ; for both hands
LC22908:  TRB $DA           ;($11DA
LC2290A:  LDA $DA           ;($11DA
LC2290C:  STA $3BA4,X       ;(save "Weapon effects"
LC2290F:  LDA $BA           ;($11BA
LC22911:  STA $3BB8,X       ;(bottom = Defense, top = Magic Defense
LC22914:  LDA #$FFFF
LC22917:  STA $331C,X       ;(Status Immunity Bytes 1 and 2: character is vulnerable
                            ; to everything -- i.e. immune to nothing
                            ;(pointless instruction, as C2/291C immediately undoes it.
                            ; should be "STA $3330,X" instead, as that byte is
                            ; ignored, letting old immunities linger.
LC2291A:  EOR $D2           ;($11D2)(equipment immunities
LC2291C:  STA $331C,X       ;(for Immunity Bytes 1-2, character is now vulnerable to
                            ; whatever the equipment doesn't block
LC2291F:  LDA $B6           ;($11B6
LC22921:  STA $3BCC,X       ;(bottom = absorbed elements, top = nullified elements
LC22924:  LDA $B8           ;($11B8
LC22926:  STA $3BE0,X       ;(bottom = weak elements, top = 50% resist elements
LC22929:  LDA $BE           ;($11BE
LC2292B:  STA $3CBC,X       ;(bottom = special action for right hand,
                            ; top = special action for left hand
LC2292E:  LDA $C6           ;($11C6)(item # of equipment in both hands
LC22930:  STA $3CA8,X
LC22933:  LDA $CA           ;($11CA)(item # of equipment in both relic slots
LC22935:  STA $3CD0,X
LC22938:  LDA $D0           ;($11D0
LC2293A:  STA $3CE4,X       ;(deals with weapon and shield animation for blocking
                            ; magical and physical attacks
LC2293D:  LDA $D8           ;($11D8
LC2293F:  STA $3C58,X       ;(save "Battle Effects 2"
LC22942:  SEP #$20          ;(Set 8-bit Accumulator
LC22944:  ASL $3A21,X       ;(Bit X is set, where X is the actual character # of this
                            ; onscreen character.  corresponding bits are set in Items
                            ; to see if they're equippable.  shift out the top bit, as
                            ; that corresponds to "heavy" merit awardable equipment and
                            ; will be set below
LC22947:  ASL
LC22948:  ASL
LC22949:  ASL               ;(rotate "wearer can equip heavy armor" bit from
                            ; Battle Effects 2 into carry bit
LC2294A:  ROR $3A21,X       ;(now put it in "character # for purposes of equipping" byte
LC2294D:  PLD
LC2294E:  JMP $2650         ;(deal with Instant Death protection, and Poison elemental
                            ; nullification giving immunity to Poison status


;Load Magic Power / Vigor and Level

LC22951:  LDA $11A2
LC22954:  LSR
LC22955:  LDA $3B41,X    ;magic power [* 1.5]
LC22958:  BCC LC2295D    ;Branch if not physical attack
LC2295A:  LDA $3B2C,X    ;vigor [* 2]
LC2295D:  STA $11AE
LC22960:  STZ $3A89      ;turn off random weapon spellcast
LC22963:  JMP $2C21      ;Put attacker level [or Sketcher if applicable] in $11AF


;Load spell data

LC22966:  PHX
LC22967:  PHP
LC22968:  XBA
LC22969:  LDA #$0E
LC2296B:  JSR $4781      ;length of spell data * spell #
LC2296E:  REP #$31       ;Set 16-bit A, X, Y.  Clear carry flag
LC22970:  ADC #$6AC0     ;spells start at 46CC0 ROM offset, or C4/6AC0
LC22973:  TAX
LC22974:  LDY #$11A0
LC22977:  LDA #$000D
LC2297A:  MVN $C47E    ;copy 14 spell bytes into RAM
LC2297D:  SEP #$20
LC2297F:  ASL $11A9      ;multiply special effect by 2
LC22982:  BCC LC22987
LC22984:  STZ $11A9      ;if it exceeded 255, make it 0
LC22987:  PLP
LC22988:  PLX
LC22989:  RTS


;Loads command data, clears special effect, sets unblockable, sets Level to 0,
; sets Vigor/Mag. Pwr to 0)

LC2298A:  LDA $3A7C      ;get original command ID
LC2298D:  JSR $26D3      ;Load data for command [held in A.bottom] and, given
                         ;the callers to this function, data of "Battle" spell
LC22990:  LDA #$20
LC22992:  TSB $11A4      ;Set Unblockable
LC22995:  STZ $11A9      ;Clear special effects
LC22998:  STZ $11AF      ;Set Level to 0
LC2299B:  STZ $11AE      ;Set Vigor / M. Power to 0
LC2299E:  RTS


;Load weapon data into attack data.  Also handles Offering, Sniper Sight, etc.

LC2299F:  PHP
LC229A0:  LDA $3B2C,X
LC229A3:  STA $11AE      ;Vigor * 2 / Magic Power
LC229A6:  JSR $2C21      ;Put attacker level [or Sketcher if applicable] in $11AF
LC229A9:  LDA $3C45,X
LC229AC:  BIT #$10
LC229AE:  BEQ LC229B5    ;If no Sniper Sight
LC229B0:  LDA #$20
LC229B2:  TSB $11A4      ;Sets Can't be Dodged
LC229B5:  LDA $B6        ;get attack #
LC229B7:  CMP #$EF
LC229B9:  BNE LC229C7    ;Branch if not Special
LC229BB:  LDA $3EE4,X
LC229BE:  BIT #$20       ;Check for Imp status
LC229C0:  BNE LC229C7    ;if an Imp, branch
LC229C2:  LDA #$06
LC229C4:  STA $3412      ;will display a monster Special atop the screen, and
                         ;attack will load its properties at C2/32F5
LC229C7:  PLP
LC229C8:  PHX
LC229C9:  ROR $B6        ;if carry was set going into function, this is an
                         ;odd-numbered attack of sequence, related to $3A70..
                         ;top bit of $B6 will be used in animation:
                         ;Clear = right hand, Set = left hand

LC229CB:  BPL LC229CE    ;if Carry wasn't set, branch and use right hand
LC229CD:  INX            ;if it was, point to left weapon hand
LC229CE:  LDA $3B68,X
LC229D1:  STA $11A6      ;Battle Power
LC229D4:  LDA #$62
LC229D6:  TSB $B3        ;turn off Always Critical and Gauntlet.  Turn on
                         ;ignore attacker row
LC229D8:  LDA $3BA4,X
LC229DB:  AND #$60       ;isolate "Same damage from back row" and "2-hand" properties
LC229DD:  EOR #$20       ;flip "Same damage from back row" to get "Damage affected
                         ;by attacker row"
LC229DF:  TRB $B3        ;Bit 6 = 0 for Gauntlet [2-hand] and Bit 5 = 0 for
                         ;"Damage affected by attacker row"
LC229E1:  LDA $3B90,X
LC229E4:  STA $11A1      ;Element
LC229E7:  LDA $3B7C,X
LC229EA:  STA $11A8      ;Hit Rate
LC229ED:  LDA $3D34,X
LC229F0:  STA $3A89      ;random weapon spellcast
LC229F3:  LDA $3CBC,X
LC229F6:  AND #$F0
LC229F8:  LSR
LC229F9:  LSR
LC229FA:  LSR
LC229FB:  STA $11A9      ;Special effect
LC229FE:  LDA $3CA8,X    ;Get equipment in current hand
LC22A01:  INC
LC22A02:  STA $B7        ;adjust and save as graphic index
LC22A04:  PLX
LC22A05:  LDA $3C58,X    ;Check for offering
LC22A08:  LSR
LC22A09:  BCC LC22A1B    ;Branch if no Offering
LC22A0B:  LDA #$20
LC22A0D:  TSB $11A4      ;Set Can't be dodged
LC22A10:  LDA #$40
LC22A12:  TSB $BA        ;Sets randomize target
LC22A14:  LDA #$02
LC22A16:  TSB $B2        ;Set no critical and ignore True Knight
LC22A18:  STZ $3A89      ;Turn off random spellcast
LC22A1B:  LDA $11A6
LC22A1E:  BEQ LC22A36    ;Exit if 0 Battle Power
LC22A20:  CPX #$08
LC22A22:  BCC LC22A36    ;Exit if character
LC22A24:  LDA #$20
LC22A26:  BIT $3EE4,X
LC22A29:  BEQ LC22A36    ;Exit if not Imp
LC22A2B:  ASL
LC22A2C:  BIT $3C95,X    ;Check for auto critical if Imp
LC22A2F:  BNE LC22A36    ;If set then exit
LC22A31:  LDA #$01
LC22A33:  STA $11A6      ;Set Battle Power to 1
LC22A36:  RTS


;Item usage setup.  Used for non-Magic: Items, Thrown objects, and Tools
;Going in: A = Item number.
;  Carry flag = Command >= 2.  It's set for Throw or Tools, but not plain Item.)

LC22A37:  PHX
LC22A38:  PHP
LC22A39:  PHA            ;Put on stack
LC22A3A:  PHX
LC22A3B:  LDX #$0F
LC22A3D:  STZ $11A0,X    ;zero out all spell data -related bytes
LC22A40:  DEX
LC22A41:  BPL LC22A3D
LC22A43:  PLX
LC22A44:  LDA #$21
LC22A46:  STA $11A2      ;Set to ignore defense, physical attack
LC22A49:  LDA #$22
LC22A4B:  STA $11A3      ;Set attack to retarget if target invalid/dead,
                         ;not reflectable
LC22A4E:  LDA #$20
LC22A50:  STA $11A4      ;Set to unblockable
LC22A53:  BCC LC22A5E    ;branch if not Throw or Tools, i.e. plain Item
LC22A55:  LDA $3B2C,X    ;attacker Vigor [* 2]
LC22A58:  STA $11AE      ;Vigor * 2 or Magic Power
LC22A5B:  JSR $2C21      ;Put attacker level [or Sketcher if applicable] in $11AF
LC22A5E:  LDA $01,S      ;get Item ID
LC22A60:  JSR $2B63      ;Multiply A by 30, size of item data block
LC22A63:  REP #$10       ;Set 16-bit X and Y
LC22A65:  TAX
LC22A66:  LDA $D85014,X  ;Item "HP/MP affected", aka power
LC22A6A:  STA $11A6
LC22A6D:  LDA $D8500F,X  ;Item's element
LC22A71:  STA $11A1
LC22A74:  BCS LC22ADC    ;branch if Throw or Tools
LC22A76:  LDA #$01
LC22A78:  TRB $11A2      ;Sets to magical attack
LC22A7B:  LDA $D8501B,X  ;item special action
LC22A7F:  ASL
LC22A80:  BCS LC22A87    ;Branch if top bit set, i.e. no action, usually FFh
LC22A82:  ADC #$90
LC22A84:  STA $11A9      ;Else store 90h + (action*2) in special effect
LC22A87:  REP #$20       ;set 16-bit accumulator
LC22A89:  LDA $D85015,X  ;Item conditions 1+2 when used
LC22A8D:  STA $11AA
LC22A90:  LDA $D85017,X  ;Item conditions 3+4 when used
LC22A94:  STA $11AC
LC22A97:  SEP #$20       ;Set 8-bit accumulator
LC22A99:  LDA $D85013,X  ;Get Item Properties
LC22A9D:  STA $FE
LC22A9F:  ASL $FE        ;Does it manipulate 1/16th of actual values?
LC22AA1:  BCC LC22AA8    ;If not ^, branch
LC22AA3:  LDA #$80
LC22AA5:  TSB $11A4      ;Set bit to take HP at fraction of spell byte 7
LC22AA8:  ASL $FE
LC22AAA:  ASL $FE
LC22AAC:  BCC LC22AB3    ;If item doesn't remove status conditions, branch
LC22AAE:  LDA #$04
LC22AB0:  TSB $11A4      ;Set remove status spell bit
LC22AB3:  ASL $FE
LC22AB5:  BCC LC22ABE    ;Branch if "restore MP" item bit unset
LC22AB7:  LDA #$80
LC22AB9:  TSB $11A3      ;Set spell to concern MP
LC22ABC:  TSB $FE        ;And automatically set "restore HP" in item properties,
                         ;so MP-related items always try to give MP, not take it
LC22ABE:  ASL $FE
LC22AC0:  BCC LC22AC7    ;Branch if "restore HP" (or restore MP) bit unset
LC22AC2:  LDA #$01
LC22AC4:  TSB $11A4      ;Set Heal spell bit
LC22AC7:  ASL $FE
LC22AC9:  ASL $FE
LC22ACB:  BCC LC22AD2    ;Branch if Item doesn't reverse damage on undead
LC22ACD:  LDA #$08
LC22ACF:  TSB $11A2      ;Sets Invert Damage on Undead
LC22AD2:  LDA $11AA
LC22AD5:  BPL LC22ADC    ;Branch if not death attack
LC22AD7:  LDA #$0C
LC22AD9:  TSB $11A2      ;Sets Invert Damage on Undead and Hit only (dead XOR undead
                         ;targets
LC22ADC:  LDA $01,S
LC22ADE:  CMP #$AE       ;Item number 174 - Inviz Edge?
LC22AE0:  BNE LC22AE9    ;branch if not
LC22AE2:  LDA #$10
LC22AE4:  TSB $11AA      ;Set Clear effect to attack
LC22AE7:  BRA LC22AF2
LC22AE9:  CMP #$AF       ;Item number 175 - Shadow Edge?
LC22AEB:  BNE LC22AF2    ;branch if not
LC22AED:  LDA #$04
LC22AEF:  TSB $11AB      ;Set Image effect to attack

;NOTE: special Inviz and Shadow Edge checks are needed because much code
; [including that at C2/2A89 that normally loads statuses] is skipped if we're
; doing Throw [or Tools])

LC22AF2:  LDA $D85000,X  ;Item type
LC22AF6:  AND #$07
LC22AF8:  BNE LC22B16    ;If item's not a Tool, branch
LC22AFA:  LDA #$20
LC22AFC:  TRB $11A2      ;Clears ignore defense
LC22AFF:  TRB $11A4      ;Clears unblockable
LC22B02:  LDA $D85015,X
LC22B06:  STA $11A8      ;Get and store hit rate
LC22B09:  TDC
LC22B0A:  LDA $01,S      ;get item #.  number of first tool [NoiseBlaster] is A3h.
LC22B0C:  SEC
LC22B0D:  SBC #$A3
LC22B0F:  AND #$07       ;subtract 163 from item # and use bottom 3 bits to get a
                         ;"tool number" of 0-7
LC22B11:  ASL            ;multiply it by 2 to index table below
LC22B12:  TAX
LC22B13:  JSR ($2B1A,X)  ;load Tool's miscellaneous effect
LC22B16:  PLA
LC22B17:  PLP
LC22B18:  PLX
LC22B19:  RTS


;Code pointers

LC22B1A: dw $2B2A     ;(Noise Blaster)
LC22B1C: dw $2B2F     ;(Bio Blaster) (do nothing)
LC22B1E: dw $2B2F     ;(Flash) (do nothing)
LC22B20: dw $2B30     ;(Chainsaw)
LC22B22: dw $2B53     ;(Debilitator)
LC22B24: dw $2B4D     ;(Drill)
LC22B26: dw $2B57     ;(Air Anchor)
LC22B28: dw $2B5D     ;(Autocrossbow)


;Noiseblaster effect

LC22B2A:  LDA #$20
LC22B2C:  STA $11AB      ;Set Muddled in attack data
LC22B2F:  RTS


;Chainsaw effect

LC22B30:  JSR $4B5A      ;random #: 0 to 255
LC22B33:  AND #$03
LC22B35:  BNE LC22B4D    ;75% chance branch
LC22B37:  LDA #$08
LC22B39:  STA $B6        ;Animation
LC22B3B:  STZ $11A6      ;Battle power
LC22B3E:  LDA #$80
LC22B40:  TSB $11AA      ;Set death/wound status in attack data
LC22B43:  LDA #$10
LC22B45:  STA $11A4      ;Set stamina can block
LC22B48:  LDA #$02
LC22B4A:  TSB $11A2      ;Set miss if instant death protected
LC22B4D:  LDA #$20
LC22B4F:  TSB $11A2      ;Set ignore defense
LC22B52:  RTS


;Debilitator Effect

LC22B53:  LDA #$AC
LC22B55:  BRA LC22B59    ;Set Debilitator effect


;Air Anchor effect

LC22B57:  LDA #$AE       ;Add Air Anchor effect
LC22B59:  STA $11A9
LC22B5C:  RTS


;Autocrossbow effect

LC22B5D:  LDA #$40
LC22B5F:  TSB $11A2      ;Set no split damage
LC22B62:  RTS


;Multiplies A by 30

LC22B63:  XBA
LC22B64:  LDA #$1E
LC22B66:  JMP $4781


;Magic Damage Calculation:

;Results:

;$11B0 = (Spell Power * 4) + (Level * Magic Power * Spell Power / 32
;If Level of 0 is passed, $11B0 = Spell Power)

;NOTE: Unlike damage modification functions, this one does NOTHING to make sure damage
;doesn't exceed 65535.  That means with a spell like Ultima, a character at level 99
;who has reached 140+ Magic Power via Esper bonuses and equipment will do only
;triple-digit damage.

LC22B69:  LDA $11AF   ;(Level
LC22B6C:  STA $E8
LC22B6E:  CMP #$01
LC22B70:  TDC         ;(Clear 16-bit A
LC22B71:  LDA $11A6   ;(Spell Power
LC22B74:  REP #$20    ;(Set 16-bit Accumulator
LC22B76:  BCC LC22B7A ;(If Level > 0, Spell Power *= 4
LC22B78:  ASL
LC22B79:  ASL
LC22B7A:  STA $11B0   ;(Maximum Damage
LC22B7D:  SEP #$20    ;(Set 8-bit Accumulator
LC22B7F:  LDA $11AE   ;(Magic Power
LC22B82:  XBA
LC22B83:  LDA $11A6   ;(Spell Power
LC22B86:  JSR $4781   ;(Multiplication Function:
                      ; A = Magic Power * Spell Power
LC22B89:  JSR $47B7   ;(Multiplication Function 2:
                      ;              24-bit $E8 = (Mag Pwr * Spell Power) * Level
LC22B8C:  LDA #$04
LC22B8E:  REP #$20    ;(Set 16-bit Accumulator
LC22B90:  JSR $0DD1   ;(Divide 24-bit Damage by 32.  [note the
                      ; division operates on 4 bytes]
LC22B93:  CLC
LC22B94:  ADC $11B0   ;(Maximum Damage
LC22B97:  STA $11B0   ;(Maximum Damage
LC22B9A:  SEP #$20    ;(Set 8-bit Accumulator
LC22B9C:  RTS


;Physical Damage Calculation:
;X = Determines if monster or player

;Results:

;For characters:
;If Gauntlet equipped with compatible weapon, G is 7/4; else, it's 1.
;Attack = (Battle Power * G) + (Vigor * 2).  Vigor * 2 is capped at 255.
;$11B0 = Battle Power + ( (Level * Level * Attack) DIV 256 ) * 3/2

;For monsters:
;Vigor is Random number 56 to 63
;Attack = (Battle Power * 4) + Vigor
;$11B0 = (Level * Level * Attack) DIV 256

LC22B9D:  LDA $11A2      ;Check if magic attack
LC22BA0:  LSR
LC22BA1:  BCS LC22BA6
LC22BA3:  JMP $2B69      ;Magical Damage Calculation
LC22BA6:  PHP
LC22BA7:  LDA $11AF      ;attacker Level
LC22BAA:  PHA            ;save it
LC22BAB:  STA $E8
LC22BAD:  TDC
LC22BAE:  LDA $11A6      ;Battle Power
LC22BB1:  REP #$20       ;Set 16-bit Accumulator
LC22BB3:  CPX #$08       ;If monster then Battle Power *= 4
LC22BB5:  BCC LC22BB9
LC22BB7:  ASL
LC22BB8:  ASL
LC22BB9:  PHA            ;Put on stack
LC22BBA:  LDA $B2
LC22BBC:  BIT #$4000
LC22BBF:  BNE LC22BCD    ;If Gauntlet is not equipped, branch
LC22BC1:  LDA $01,S      ;Battle Power *= 7/4
LC22BC3:  LSR
LC22BC4:  CLC
LC22BC5:  ADC $01,S
LC22BC7:  LSR
LC22BC8:  CLC
LC22BC9:  ADC $01,S
LC22BCB:  STA $01,S
LC22BCD:  PLA
LC22BCE:  SEP #$20       ;Set 8-bit Accumulator
LC22BD0:  ADC $11AE      ;add Vigor * 2 if character, or Vigor if monster
LC22BD3:  XBA
LC22BD4:  ADC #$00       ;add carry from the bottom byte of Attack
                         ;into the top byte
LC22BD6:  XBA
LC22BD7:  JSR $47B7      ;get 16-bit "Attack" * 8-bit level, and put
                         ;24-bit product in Variables $E8 thru $EA
LC22BDA:  LDA $E8
LC22BDC:  STA $EA        ;use top byte of result as temporary variable,
                         ;since it's generally 0 anyway.
                         ;to see why that's a bad idea, keep reading.
LC22BDE:  PLA
LC22BDF:  STA $E8        ;get attacker level again
LC22BE1:  REP #$20       ;Set 16-bit Accumulator
LC22BE3:  LDA $E9
LC22BE5:  XBA            ;A = bottom two bytes of the first multiplication
                         ;result..  typically, we'll always have zero in the
                         ;top byte, so we can ignore it.  but with a 255
                         ;Battle Power weapon, Gauntlet, and a character at
                         ;Level 99 with 128 Vigor, that product WILL need 3
                         ;bytes.  failure to use that top byte in our next
                         ;multiplication means we'll lose a lot of damage.
                         ;BUG!

LC22BE6:  JSR $47B7      ;multiply 16-bit result of [Level * Attack] by
                         ;our 8-bit level again, and put the new 24-bit
                         ;product in Variables $E8 thru $EA.
                         ;16-bit A will hold the new product DIV 256.
LC22BE9:  STA $11B0      ;Maximum Damage
LC22BEC:  CPX #$08       ;If Player then multiply $11B0 by 3/2
LC22BEE:  BCS LC22C1F    ;And add Battle Power
LC22BF0:  LDA $11A6      ;Battle Power
LC22BF3:  AND #$00FF
LC22BF5:  ASL
LC22BF7:  ADC $11B0      ;Maximum Damage
LC22BFA:  LSR
LC22BFB:  CLC
LC22BFC:  ADC $11B0      ;Maximum Damage
LC22BFF:  STA $11B0      ;Maximum Damage
LC22C02:  LDA $3C58,X
LC22C05:  LSR
LC22C06:  BCC LC22C0B    ;Check for offering
LC22C08:  LSR $11B0      ;Halves damage
LC22C0B:  BIT #$0008
LC22C0E:  BEQ LC22C1F    ;Check for Genji Glove
LC22C10:  LDA $11B0      ;Maximum Damage
LC22C13:  LSR
LC22C14:  LSR
LC22C15:  EOR #$FFFF
LC22C18:  SEC
LC22C19:  ADC $11B0      ;Maximum Damage
LC22C1B:  STA $11B0      ;Subtract 1/4 from Maximum Damage
LC22C1F:  PLP
LC22C20:  RTS


;Put attacker level [or Sketcher if applicable] in $11AF

LC22C21:  PHX
LC22C22:  LDA $3417      ;get Sketcher
LC22C25:  BMI LC22C28    ;branch if null
LC22C27:  TAX            ;if there's a valid Sketcher, use their Level
                         ;for attack
LC22C28:  LDA $3B18,X    ;attacker Level
LC22C2B:  STA $11AF      ;save one of above as attack's level
LC22C2E:  PLX
LC22C2F:  RTS


;Load enemy name and stats
;Coming into function: A = Enemy Number.  Y = in-battle enemy index, should be between
; 8 and 18d)
;throughout this function, "main enemy" will mean the enemy referenced by the A and Y
; values that are initially passed to the function.  "loop enemy" will mean the enemy
; currently referenced by the iterator of the loop that compares the main enemy to all
; other enemies in the battle.)

LC22C30:  PHX
LC22C31:  PHP
LC22C32:  REP #$30       ;16-bit accumulator and index registers
LC22C34:  STA $1FF9,Y    ;save 16-bit enemy number
LC22C37:  STA $33A8,Y    ;make another copy.  this variable can change for
                         ;characters due to Rage, but monsters don't Rage,
                         ;so it should stay put for them.
LC22C3A:  JSR $2D71      ;read enemy command script.  function explicitly
                         ;preserves A and X, doesn't seem to touch Y.
LC22C3D:  ASL
LC22C3E:  ASL
LC22C3F:  PHA            ;Put on stack
LC22C40:  TAX            ;enemy number * 4.  there are 4 bytes for
                         ;steal+win slots
LC22C41:  LDA $CF3000,X
LC22C45:  STA $3308,Y    ;enemy steal slots
LC22C48:  PLA
LC22C49:  ASL            ;enemy number * 8
LC22C4A:  PHA            ;save it
LC22C4B:  PHX            ;push enemy number * 4
LC22C4C:  PHY            ;push 8-18 enemy index
LC22C4D:  TAX
LC22C4E:  LDA $1FF9,Y    ;get enemy number
LC22C51:  STA $3380,Y    ;Store it in the name structure.
                         ;$3380 is responsible for the listing of enemy
                         ;names in battle.  Whatever reads from that
                         ;structure ensures there's no duplicates -- e.g.
                         ;if there's 2 Leafers, "Leafer" is just displayed once.
                         ;And if the code below didn't have bugs,
                         ;2 *different* Mag Roaders would yield only one
                         ;"Mag Roader" display, as it works in FF6j.
LC22C54:  TDC
LC22C55:  TAY            ;Y = 0
LC22C56:  LDA $CFC050,X  ;enemy names
LC22C5A:  STA $00F8,Y    ;store name in temporary string
LC22C5D:  INX
LC22C5E:  INX
LC22C5F:  INY
LC22C60:  INY
LC22C61:  CPY #$0008
LC22C64:  BCC LC22C56    ;loop until 8 characters of name are read
LC22C66:  LDY #$0012     ;point to last enemy in battle
LC22C69:  LDA $1FF9,Y    ;get number of enemy
LC22C6C:  BMI LC22C96    ;if 16-bit enemy number is negative, no enemy in slot,
                         ;so skip it
LC22C6E:  PHY
LC22C6F:  ASL
LC22C70:  ASL
LC22C71:  ASL
LC22C72:  TAX            ;enemy # * 8
LC22C73:  TDC
LC22C74:  TAY            ;Y = 0
LC22C75:  LDA $00F8,Y
LC22C78:  CMP $CFC050,X  ;compare name in temporary string to name of
                         ;loop enemy
LC22C7C:  CLC
LC22C7D:  BNE LC22C88    ;if they're not equal, exit loop
LC22C7F:  INX
LC22C80:  INX
LC22C81:  INY
LC22C82:  INY
LC22C83:  CPY #$0008
LC22C86:  BCC LC22C75    ;compare all the 1st 8 characters of the names as long
                         ;as they keep matching
LC22C88:  PLY            ;Y points to in-battle index of loop enemy
LC22C89:  BCC LC22C96    ;if we exited string comparison early, the names
                         ;don't match, so branch
LC22C8B:  LDA $01,S
LC22C8D:  TAX            ;retrieve in-battle enemy index passed to function
LC22C8E:  LDA $1FF9,Y    ;number of loop enemy
LC22C91:  STA $3380,X    ;If the strings did match, store enemy # of loop
                         ;enemy in the "name structure", at the position
                         ;of the main enemy.

                         ;This way, all enemies with the same name are
                         ;represented by the same enemy # in $3380.  Whatever
                         ;mechanism displays the $3380 structure must "detect"
                         ;duplicate enemy numbers to avoid listing duplicate
                         ;enemy names.

                         ;Sadly, none of this works.  Enemy names were
                         ;8 characters in FF6j according to Lord J, but 10
                         ;characters in FF3us, and this function was unchanged.
                         ;This means differing enemies with the same name
                         ;(like Mag Roader will have duplicate listings.
                         ;Also, you can make an enemy name be wrongly OMITTED
                         ;thru clever renaming and grouping of enemies
                         ;(try giving Enemy #0 and #4 the same name --
                         ;e.g. "gangster" -- and put Enemy #0 and #5 in a
                         ;formation together or really bad luck.

                         ;A patch for this function has been released
                         ;see http://masterzed.cavesofnarshe.com/

LC22C94:  BRA LC22C9D    ;we had a match, so exit the crazy loop
LC22C96:  DEY
LC22C97:  DEY
LC22C98:  CPY #$0008
LC22C9B:  BCS LC22C69    ;loop and compare string to all enemies in battle
LC22C9D:  PLY            ;retrieve initial 8-18 enemy index
LC22C9E:  PLX            ;retrieve initial Enemy Number * 4
LC22C9F:  PLA            ;retrieve initial Enemy Number * 8
LC22CA0:  ASL
LC22CA1:  ASL
LC22CA2:  TAX            ;X = enemy # * 4 * 8.  Monster data block at $CF0000
                         ;is 32 bytes

LC22CA3:  LDA $CF0005,X  ;bottom = Defense, top = Magic Defense
LC22CA7:  STA $3BB8,Y
LC22CAA:  LDA $CF000C,X  ;Experience
LC22CAE:  STA $3D84,Y
LC22CB1:  LDA $CF000E,X  ;GP
LC22CB5:  STA $3D98,Y
LC22CB8:  LDA $3A46
LC22CBB:  BMI LC22CE4    ;test bit 7 of $3A47.  branch if there was an enemy
                         ;formation # switch, and it designates that the new
                         ;enemies retain HP and Max HP from the current formation.
LC22CBD:  LDA $CF000A,X  ;Max MP
LC22CC1:  STA $3C08,Y    ;copy to Current MP
LC22CC4:  STA $3C30,Y    ;copy to Max MP
LC22CC7:  LDA $CF0008,X  ;Max HP
LC22CCB:  STA $3BF4,Y    ;copy to Current HP
LC22CCE:  STA $3C1C,Y    ;copy to Max HP
LC22CD1:  LDA $3ED4      ;Battle formation
LC22CD4:  CMP #$01CF
LC22CD7:  BNE LC22CE4    ;Branch if not Doom Gaze's formation
LC22CD9:  STY $33FA      ;save which monster is Doom Gaze; was initially FFh
LC22CDC:  LDA $3EBE      ;Doom Gaze's HP
LC22CDF:  BEQ LC22CE4
LC22CE1:  STA $3BF4,Y    ;Set current HP to Doom Gaze's HP
LC22CE4:  SEP #$21       ;Set 8-bit Accumulator
LC22CE6:  LDA $3C1D,Y    ;High byte of max HP
LC22CE9:  LSR
LC22CEA:  CMP #$19
LC22CEC:  BCC LC22CF0
LC22CEE:  LDA #$17       ;Stamina = (Max HP / 512 + 16. If this number
                         ;is greater than 40, then the monster's stamina is
                         ;set to 40
LC22CF0:  ADC #$10
LC22CF2:  STA $3B40,Y    ;Stamina
LC22CF5:  LDA $CF0001,X
LC22CF9:  STA $3B68,Y    ;Battle Power
LC22CFC:  LDA $CF001A,X
LC22D00:  STA $3CA8,Y    ;Monster's regular weapon graphic
LC22D03:  LDA $CF0003,X  ;Evade
LC22D07:  JSR $2861
LC22D0A:  STA $3B54,Y    ;255 - Evade * 2 + 1
LC22D0D:  LDA $CF0004,X  ;MBlock
LC22D11:  JSR $2861
LC22D14:  STA $3B55,Y    ;255 - MBlock * 2 + 1
LC22D17:  LDA $CF0002,X
LC22D1B:  STA $3B7C,Y    ;Hit Rate
LC22D1E:  LDA $CF0010,X
LC22D22:  STA $3B18,Y    ;Level
LC22D25:  LDA $CF0000,X
LC22D29:  STA $3B19,Y    ;Speed
LC22D2C:  LDA $CF0007,X  ;Magic Power
LC22D30:  JSR $47D6      ;* 1.5
LC22D33:  STA $3B41,Y    ;Magic Power
LC22D36:  LDA $CF001E,X  ;monster status byte 4 and miscellaneous properties
LC22D3A:  AND #$82       ;only keep Float and Enemy Runic
LC22D3C:  ORA $3E4C,Y
LC22D3F:  STA $3E4C,Y    ;turn them on in Retort/Runic/etc byte
LC22D42:  LDA $CF0013,X
LC22D46:  STA $3C80,Y    ;Special Byte 2
LC22D49:  JSR $2DC1      ;load enemy elemental reactions, statuses and
                         ;status protection, metamorph info, special info
                         ;like human/undead/etc
LC22D4C:  LDX $33A8,Y    ;get enemy number
LC22D4F:  LDA $CF37C0,X  ;get Enemy Special Move graphic
LC22D53:  STA $3C81,Y
LC22D56:  SEP #$10
LC22D58:  JSR $2D99      ;Carry will be set if the monster is present and has
                         ;the "Attack First" attribute, clear otherwise
LC22D5B:  TDC
LC22D5C:  ROR
LC22D5D:  TSB $B1        ;if Carry is set, turn on Bit 7 of $B1
LC22D5F:  JSR $4B5A
LC22D62:  AND #$07       ;random number: 0-7
LC22D64:  CLC
LC22D65:  ADC #$38       ;add 56
LC22D67:  STA $3B2C,Y    ;save monster Vigor as a random number from 56 to 63
LC22D6A:  TYX
LC22D6B:  JSR $2650      ;deal with Instant Death protection, and Poison elemental
                         ;nullification giving immunity to Poison status
LC22D6E:  PLP
LC22D6F:  PLX
LC22D70:  RTS


;Read command script at start of combat
;A = Monster number

LC22D71:  PHX
LC22D72:  PHA            ;Put on stack
LC22D73:  PHP
LC22D74:  REP #$20
LC22D76:  ASL
LC22D77:  TAX
LC22D78:  LDA $CF8400,X  ;Monster command script pointers
LC22D7C:  STA $3254,Y    ;Offset of main command script
LC22D7F:  TAX
LC22D80:  SEP #$20
LC22D82:  JSR $1A43      ;Read command script, up through an FEh or FFh
                         ;command, advancing position in X
LC22D85:  INC
LC22D86:  BNE LC22D82    ;If FFh wasn't the last thing read, we're not at
                         ;end of main command script, so loop and read more
LC22D88:  LDA $CF8700,X  ;Monster command scripts
LC22D8C:  INC
LC22D8D:  BEQ LC22D95    ;if first byte of counterattack script is FFh, it's
                         ;empty, so skip saving the index
LC22D8F:  REP #$20       ;Set 16-bit Accumulator
LC22D91:  TXA
LC22D92:  STA $3268,Y    ;Offset of counterattack script
LC22D95:  PLP
LC22D96:  PLA
LC22D97:  PLX
LC22D98:  RTS


LC22D99:  PHX
LC22D9A:  TYX
LC22D9B:  JSR $2DA0
LC22D9E:  PLX
LC22D9F:  RTS


;Handle "Attack First" property for monster
;Also, returns Carry clear if Attack First unset, Carry set if it's set.)

LC22DA0:  CLC
LC22DA1:  LDA $3C80,X
LC22DA4:  BIT #$02       ;is "Attack First" set in Misc/Special enemy byte?
LC22DA6:  BEQ LC22DC0    ;if not, exit
LC22DA8:  LDA $3AA0,X
LC22DAB:  BIT #$01
LC22DAD:  BEQ LC22DC0    ;exit if enemy not present?
LC22DAF:  ORA #$08
LC22DB1:  STA $3AA0,X
LC22DB4:  STZ $3219,X    ;zero top byte of ATB Timer
LC22DB7:  LDA #$FF
LC22DB9:  STA $3AB5,X    ;max out top byte of enemy's Wait Timer, which
                         ;means they'll spend essentially no time in
                         ;the monster equivalent to a ready stance.
                         ;normally, monsters do this by having a 0 "Time to
                         ;Wait" in $322C, but since this function is doing
                         ;things earlier and $322C is still FFh, we instead
                         ;fill out the timer to meet the threshold.
LC22DBC:  JSR $4E66      ;put monster in the Wait to Attack queue
LC22DBF:  SEC
LC22DC0:  RTS


;Load monster's special attack, elemental properties, statuses, status immunities,
; Metamorph info, special properties like Human/Undead/Dies at MP=0 , etc)

LC22DC1:  PHP
LC22DC2:  LDA $CF001F,X  ;Special attack
LC22DC6:  STA $322D,Y
LC22DC9:  LDA $CF0019,X  ;elemental weaknesses
LC22DCD:  ORA $3BE0,Y
LC22DD0:  STA $3BE0,Y    ;add to existing weaknesses
LC22DD3:  LDA $CF0016,X  ;blocked status byte 3
LC22DD7:  EOR #$FF       ;invert it
LC22DD9:  AND $3330,Y
LC22DDC:  STA $3330,Y    ;combine with whatever was already blocked
LC22DDF:  LDA #$FF
LC22DE1:  AND $3331,Y
LC22DE4:  STA $3331,Y    ;block no additional statuses in byte 4
LC22DE7:  REP #$20       ;Set 16-bit Accumulator
LC22DE9:  LDA $CF001B,X  ;monster status bytes 1-2
LC22DED:  STA $3DD4,Y    ;copy into "status to set" bytes
LC22DF0:  LDA $CF001D,X  ;get monster status bytes 3-4
LC22DF4:  PHA            ;Put on stack
LC22DF5:  AND #$0001
LC22DF8:  LSR
LC22DF9:  ROR
LC22DFA:  ORA $01,S      ;this moves Byte 3,Bit 0 into Byte 4,Bit 7 position
                         ;it turns out "Dance" in B3,b0 is permanent float,
                         ;while B4,b7 is a dispellable float
LC22DFC:  AND #$84FE     ;filter out character stats like dog and rage
                         ;in byte 4, only Float and Life 3 are kept
LC22DFF:  STA $3DE8,Y    ;put in "status to set"
LC22E02:  PLA
LC22E03:  XBA            ;now swap enemy status bytes 3<->4 within A
LC22E04:  LSR
LC22E05:  BCC LC22E10    ;if byte4, bit 0 (aka "Rage") had not been set, branch
LC22E07:  LDA $3C58,Y
LC22E0A:  ORA #$0040     ;Set True Knight effect?
LC22E0D:  STA $3C58,Y
LC22E10:  LDA $CF001C,X  ;monster status bytes 2-3
LC22E14:  ORA $3C6C,Y    ;this makes a copy of ^, used in procs like c2/2675
LC22E17:  STA $3C6C,Y
LC22E1A:  LDA $CF0014,X  ;blocked status bytes 1-2
LC22E1E:  EOR #$FFFF     ;invert 'em
LC22E21:  AND $331C,Y
LC22E24:  STA $331C,Y    ;add to existing blockages
LC22E27:  LDA $CF0017,X  ;elements absorbed and nullified
LC22E2B:  ORA $3BCC,Y
LC22E2E:  STA $3BCC,Y    ;add to existing absorptions and nullifications
LC22E31:  LDA $CF0011,X
LC22E35:  STA $3C94,Y    ;$3C94 = Metamorph info
                         ;$3C95 = Special Byte 3: Dies at 0 MP, No name, Human,
                         ; Auto critical if Imp, Undead
LC22E38:  PLP
LC22E39:  RTS


;Determine if front, back, pincer, or side attack

LC22E3A:  LDA $3A6D
LC22E3D:  LSR
LC22E3E:  LSR            ;Put Back Guard effect into Carry
LC22E3F:  LDA $2F48      ;Get extra enemy formation data, byte 0, top half, inverted
LC22E42:  BCC LC22E50    ;Branch if no Back Guard
LC22E44:  BIT #$B0       ;Are Side, Back, or Normal attacks allowed?
LC22E46:  BEQ LC22E4A    ;If only Pincer or nothing[??] allowed, branch
LC22E48:  AND #$B0       ;Otherwise, disable Pincer
LC22E4A:  BIT #$D0       ;Are Side, Pincer, or Normal attacks allowed?
LC22E4C:  BEQ LC22E50    ;If only Back or nothing[??] allowed, branch
LC22E4E:  AND #$D0       ;Otherwise, disable Back
LC22E50:  PHA            ;Put on stack
LC22E51:  LDA $3A76      ;Number of present and living characters in party
LC22E54:  CMP #$03
LC22E56:  PLA
LC22E57:  BCS LC22E5F    ;If 3 or more in party, branch
LC22E59:  BIT #$70       ;Are any of Normal, Back, or Pincer allowed?
LC22E5B:  BEQ LC22E5F    ;If only Side or nothing[??] allowed, branch
LC22E5D:  AND #$70       ;Otherwise, disable Side attack
LC22E5F:  LDX #$10
LC22E61:  JSR $5247      ;Randomly choose attack type.  If some fictional jackass
                         ;masked them all, we enter an.. INFINITE LOOP!
LC22E64:  STX $201F      ;Save encounter type:  0 = Front, 1 = Back,
                         ;                      2 = Pincer, 3 = Side
LC22E67:  RTS


;Disable Veldt return on all but Front attack, change character rows for Pincer/Back or see
; if preemptive attack for Front/Side, copy rows to graphics data)

LC22E68:  LDX $201F      ;get encounter type:  0 = front, 1 = back,
                         ;2 = pincer, 3 = side
LC22E6B:  CPX #$00
LC22E6D:  BEQ LC22E74    ;if front attack, branch
LC22E6F:  LDA #$01
LC22E71:  TRB $11E4      ;mark Gau as not available to return from Veldt leap
LC22E74:  TXA
LC22E75:  ASL
LC22E76:  TAX            ;multiply encounter type by 2, so it acts as index
                         ;into function pointers
LC22E77:  JSR ($2E93,X)  ;Change rows for pincer and back, see if preemptive attack
                         ;for front and side
LC22E7A:  LDX #$06
LC22E7C:  PHX
LC22E7D:  LDA $3AA1,X
LC22E80:  AND #$20       ;Isolate row: 0 = Front, 1 = Back
LC22E82:  PHA            ;Put on stack
LC22E83:  TXA
LC22E84:  ASL
LC22E85:  ASL
LC22E86:  ASL
LC22E87:  ASL
LC22E88:  TAX
LC22E89:  PLA
LC22E8A:  STA $2EC5,X    ;copy row to Bit 5 of some graphics variable
LC22E8D:  PLX
LC22E8E:  DEX
LC22E8F:  DEX
LC22E90:  BPL LC22E7C    ;iterate for all 4 characters
LC22E92:  RTS


;Pointers to functions that do stuff based on battle formation

LC22E93: dw $2E9B     ;(Normal attack)
LC22E95: dw $2ECE     ;(Back attack)
LC22E97: dw $2EC1     ;(Pincer attack)
LC22E99: dw $2E9B     ;(Side attack)


;Determines if a battle is a preemptive attack
;Preemptive attack chance = 1 in 8 for normal attacks, 7 in 32 for side attacks)
;Gale Hairpin doubles chance)

LC22E9B:  LDA $B1
LC22E9D:  BMI LC22EC0    ;Exit function if bit 7 of $B1 is set.  that is,
                         ;if at least one active monster in the formation
                         ;has the "Attack First" property.
LC22E9F:  LDA $2F4B      ;load formation data, byte 3
LC22EA2:  BIT #$04       ;is "hide starting messages" set?
LC22EA4:  BNE LC22EC0    ;exit if so
LC22EA6:  TXA            ;coming in, X is 0 [Front] or 6 [Side]
LC22EA7:  ASL
LC22EA8:  ASL
LC22EA9:  ORA #$20
LC22EAB:  STA $EE        ;$EE = $201F * 8 + #$20.  so pre-emptive
                         ;rate is #$20 or #$38.
LC22EAD:  LDA $3A6D
LC22EB0:  LSR
LC22EB1:  BCC LC22EB5    ;Branch if no Gale Hairpin equipped
LC22EB3:  ASL $EE        ;Double chance of preemptive attack
LC22EB5:  JSR $4B5A      ;random number 0 to 255
LC22EB8:  CMP $EE        ;compare it against pre-emptive rate
LC22EBA:  BCS LC22EC0    ;Branch if random number >= $EE, meaning
                         ;no pre-emptive strike
LC22EBC:  LDA #$40
LC22EBE:  TSB $B0        ;Set preemptive attack
LC22EC0:  RTS


;Sets all characters to front row for pincer attacks

LC22EC1:  LDX #$06
LC22EC3:  LDA #$DF
LC22EC5:  JSR $0A43      ;Sets character X to front row, by clearing
                         ;Bit 5 of $3AA1,X
LC22EC8:  DEX
LC22EC9:  DEX
LC22ECA:  BPL LC22EC3    ;iterate for all 4 characters
LC22ECC:  BRA LC22EDC


;Switches characters' row placements for back attacks

LC22ECE:  LDX #$06
LC22ED0:  LDA $3AA1,X
LC22ED3:  EOR #$20
LC22ED5:  STA $3AA1,X    ;Toggle Row
LC22ED8:  DEX
LC22ED9:  DEX
LC22EDA:  BPL LC22ED0    ;iterate for all 4 characters
LC22EDC:  LDA #$20
LC22EDE:  TSB $B1        ;???
LC22EE0:  RTS


;Initialize some enemy presence variables, and load enemy names and stats

LC22EE1:  PHP
LC22EE2:  REP #$10       ;Set 16-bit X and Y
LC22EE4:  LDA $3F45      ;get enemy presence byte from monster formation data
LC22EE7:  LDX #$000A
LC22EEA:  ASL
LC22EEB:  ASL            ;move 6 relevant bits into top of byte, as there's
                         ;only 6 possible enemies
LC22EEC:  STZ $3AA8,X    ;mark enemy as absent to start
LC22EEF:  ASL
LC22EF0:  ROL $3AA8,X    ;$3AA8 = 1 for present enemy, 0 for absent
LC22EF3:  DEX
LC22EF4:  DEX
LC22EF5:  BPL LC22EEC    ;loop for all 6 enemies
LC22EF7:  LDA $3F52      ;get boss switches byte of monster formation data
LC22EFA:  ASL
LC22EFB:  ASL            ;move 6 relevant bits into top of byte
LC22EFC:  STA $EE
LC22EFE:  LDX #$0005
LC22F01:  LDY #$0012     ;Y = onscreen index of enemy, should be between
                         ;8 and 18d
LC22F04:  TDC
LC22F05:  ASL $3A73      ;prepare to set next bit for which monsters are in
                         ;template/formation.  this is initialized to 0
                         ;at C2/23F3.
LC22F08:  ASL $EE        ;get boss bit for current enemy
LC22F0A:  ROL
LC22F0B:  XBA            ;save boss bit in top of A
LC22F0C:  LDA $3A97      ;FFh in Colosseum, 00h elsewhere
LC22F0F:  ASL            ;Carry = whether in Colosseum
LC22F10:  LDA $3F46,X    ;get enemy number from monster formation data
LC22F13:  BCC LC22F1A    ;branch if not in Colosseum
LC22F15:  LDA $0206      ;enemy number, passed by Colosseum setup in Bank C3
LC22F18:  BRA LC22F1E    ;the Colosseum only supports enemies 0-255, so branch
                         ;immediately to check the boss bit, since we know
                         ;any enemy # > 256 is unacceptable.
LC22F1A:  CMP #$FF
LC22F1C:  BNE LC22F22    ;branch if bottom byte of enemy # isn't 255.  if it
                         ;is 255, it might be empty.
LC22F1E:  XBA
LC22F1F:  BNE LC22F28    ;if the boss bit is set, the enemy slot's empty/unused,
                         ;and we skip its stats.  otherwise, it holds Pugs [or
                         ;for Colosseum, it's the desired slot], and it's valid.
LC22F21:  XBA
LC22F22:  JSR $2C30      ;load enemy name and stats
LC22F25:  INC $3A73      ;which monsters are in template/formation: turn on
                         ;bit for the current enemy formation position
LC22F28:  DEY
LC22F29:  DEY
LC22F2A:  DEX
LC22F2B:  BPL LC22F04    ;iterate for all 6 enemies
LC22F2D:  PLP
LC22F2E:  RTS


;At battle start, load some character properties, and set up special event if indicated
; by formation or if Leapt Gau is eligible to return)

LC22F2F:  PHP
LC22F30:  REP #$10       ;Set 16-bit X & Y
LC22F32:  STZ $FC        ;start off assuming 0 characters in party
LC22F34:  STZ $B8
LC22F36:  LDA $3EE0
LC22F39:  BNE LC22F75    ;branch if not in final 4-tier multi-battle
LC22F3B:  LDX #$0000     ;start looking at first character slot
LC22F3E:  LDA #$FF
LC22F40:  STA $3ED9,X
LC22F43:  CMP $3ED8,X    ;Which character it is
LC22F46:  BNE LC22F6C    ;if character # was actually defined, don't use the
                         ;list to determine this character
LC22F48:  LDY #$0000
LC22F4B:  LDA $0205,Y    ;get 0-15 character roster position from preferred
                         ;order list set pre-battle
LC22F4E:  CMP #$FF
LC22F50:  BEQ LC22F66    ;if no character in slot, skip to next one
LC22F52:  XBA
LC22F53:  LDA #$FF
LC22F55:  STA $0205,Y    ;null out the entry from the pre-chosen list
LC22F58:  LDA #$25
LC22F5A:  JSR $4781      ;multiply by 37, size of character info block
LC22F5D:  TAY            ;Y is now index into roster info
LC22F5E:  LDA $1600,Y    ;get actual character #
                         ;can replace last 4 instructions with "JSR $30DE"
LC22F61:  STA $3ED8,X    ;save Which Character it is
LC22F64:  BRA LC22F6C    ;we've found our party member, so exit loop,
                         ;and move onto next party slot.
LC22F66:  INY            ;check next character
LC22F67:  CPY #$000C
LC22F6A:  BCC LC22F4B    ;loop for all 12 preferred character slots
LC22F6C:  INX
LC22F6D:  INX
LC22F6E:  CPX #$0008
LC22F71:  BCC LC22F3E    ;loop for all 4 party members
LC22F73:  BRA LC22FD9    ;since we're in the final battle, we know we're not
                         ;in the Colosseum or on the Veldt, so skip those
                         ;checks.  also skip the party initialization loop
                         ;at C2/2F8C.
LC22F75:  LDX $3ED4      ;Battle formation
LC22F78:  CPX #$023E     ;Shadow at Colosseum formation
LC22F7B:  BCC LC22F8C    ;if not ^ or Colosseum formation #575, branch
LC22F7D:  LDA $0208
LC22F80:  STA $3ED8      ;Set "Which Character this is" to our chosen
                         ;combatant.
LC22F83:  LDA #$01
LC22F85:  TSB $B8        ;will be checked in C2/27A8
LC22F87:  DEC $3A97      ;set $3A97 to FFh.  future checks will look at Bit 7
                         ;to determine we're in the Colosseum.
LC22F8A:  BRA LC22FD9    ;we're in the Colosseum using a single character
                         ;to fight, so skip the party initialization loop.
LC22F8C:  LDY #$000F
LC22F8F:  LDA $1850,Y    ;get character roster information
                         ;Bit 7: 1 = party leader, as set in non-overworld areas
                         ;Bit 6: main menu presence?
                         ;Bit 5: row, 0 = front, 1 = back
                         ;Bit 3-4: position in party, 0-3
                         ;Bit 0-2: which party in; 1-3, or 0 if none
LC22F92:  STA $FE
LC22F94:  AND #$07       ;isolate which party character is in.  don't know
                         ;why it takes 3 bits rather than 2.
LC22F96:  CMP $1A6D      ;compare to Which Party is Active, 1-3
LC22F99:  BNE LC22FAD    ;branch if not equal
LC22F9B:  PHY
LC22F9C:  INC $FC        ;increment count of characters in active party
LC22F9E:  TDC
LC22F9F:  LDA $FE
LC22FA1:  AND #$18       ;isolate the position of character in party
LC22FA3:  LSR
LC22FA4:  LSR
LC22FA5:  TAX            ;convert to a 0,2,4,6 index
LC22FA6:  JSR $30DC      ;get ID of character in roster slot Y
LC22FA9:  STA $3ED8,X    ;save "which character it is"
LC22FAC:  PLY
LC22FAD:  DEY
LC22FAE:  BPL LC22F8F    ;iterate for all 16 roster positions
LC22FB0:  LDA $1EDF
LC22FB3:  BIT #$08       ;is Gau enlisted and not Leapt?
LC22FB5:  BNE LC22FC3    ;branch if so
LC22FB7:  LDA $3F4B      ;get monster index of enemy #6 in formation
LC22FBA:  INC
LC22FBB:  BNE LC22FC3    ;branch if an enemy is in the slot.  thankfully, there's
                         ;no formation with Pugs [enemy #255] in Slot #6, as this
                         ;code makes no distinction between that and a nonexistent
                         ;enemy.  one problem i noticed is that if you're in
                         ;a Veldt battle where Gau's destined to return, the 6th
                         ;Pugs will often be untargetable.
LC22FBD:  LDA $FC        ;number of characters in party
LC22FBF:  CMP #$04
LC22FC1:  BCC LC22FC8    ;branch if less than 4
LC22FC3:  LDA #$01
LC22FC5:  TRB $11E4      ;clear Gau as being leapt and available to return on
                         ;Veldt
LC22FC8:  LDA #$01
LC22FCA:  BIT $11E4      ;set when fighting on Veldt, Gau is Leapt, and he's
                         ;available to return.
LC22FCD:  BEQ LC22FD9    ;branch if unset
LC22FCF:  LDA #$0A
LC22FD1:  STA $2F4A      ;extra enemy formation data, byte 2.  store special
                         ;event.
LC22FD4:  LDA #$80
LC22FD6:  TSB $2F49      ;extra enemy formation data, byte 1: activate
                         ;special event
LC22FD9:  LDA $2F49
LC22FDC:  BPL LC2304A    ;if no special event active, branch
LC22FDE:  LDA $2F4A      ;special event number
LC22FE1:  XBA
LC22FE2:  LDA #$18
LC22FE4:  JSR $4781      ;multiply by 24 bytes to access data structure
LC22FE7:  TAX
LC22FE8:  LDA $D0FD00,X  ;get first byte of formation special event data
LC22FEC:  BPL LC22FFA
LC22FEE:  LDY #$0006
LC22FF1:  LDA #$FF
LC22FF3:  STA $3ED8,Y    ;store null in Which Character it is
LC22FF6:  DEY
LC22FF7:  DEY
LC22FF8:  BPL LC22FF1    ;iterate for all 4 party members
LC22FFA:  LDY #$0004
LC22FFD:  PHY
LC22FFE:  LDA $D0FD04,X  ;character we want to install
LC23002:  CMP #$FF
LC23004:  BEQ LC23041    ;branch if undefined
LC23006:  AND #$3F       ;isolate character to install in bottom 6 bits
LC23008:  LDY #$0006
LC2300B:  CMP $3ED8,Y    ;Which character is current party member
LC2300E:  BEQ LC23023    ;if one of characters in party already matches
                         ;desired character to install, branch and exit loop
LC23010:  DEY
LC23011:  DEY
LC23012:  BPL LC2300B    ;iterate through all 4 party members
LC23014:  INY
LC23015:  INY
LC23016:  LDA $3ED8,Y    ;Which character it is
LC23019:  INC
LC2301A:  BEQ LC23023    ;if the current character is null, branch and
                         ;exit loop
LC2301C:  CPY #$0006
LC2301F:  BCC LC23014    ;loop through all 4 characters in party
LC23021:  BRA LC23041    ;we couldn't find the desired character to install
                         ;already present, nor a null slot to accomodate them,
                         ;so skip to next entry in the battle event data.
LC23023:  LDA $3018,Y
LC23026:  TSB $B8        ;will be checked in C2/27A8
LC23028:  REP #$20       ;Set 16-bit Accumulator
LC2302A:  LDA $D0FD04,X  ;character we want to install
LC2302E:  STA $3ED8,Y    ;save in Which Character it is
LC23031:  SEP #$20       ;Set 8-bit Accumulator
LC23033:  LDA #$01       ;top byte of monster # is always 1
LC23035:  XBA
LC23036:  LDA $D0FD06,X  ;get bottom byte of monster # from battle event
                         ;data
LC2303A:  CMP #$FF       ;is our monster # 511, meaning it's null?
LC2303C:  BEQ LC23041    ;branch if so
LC2303E:  JSR $2D71      ;read command script at start of combat.
                         ;A = monster num
LC23041:  PLY
LC23042:  INX
LC23043:  INX
LC23044:  INX
LC23045:  INX
LC23046:  INX
LC23047:  DEY
LC23048:  BNE LC22FFD

LC2304A:  LDX #$0006
LC2304D:  LDA $3ED8,X    ;which character it is
LC23050:  CMP #$FF
LC23052:  BEQ LC230D3    ;Branch if none (unoccupied slot)
LC23054:  ASL            ;check bit 7 of which character it is
LC23055:  BCS LC2305A    ;if set, branch
LC23057:  INC $3AA0,X    ;mark character as onscreen?
LC2305A:  ASL            ;check bit 6 of which character it is
LC2305B:  BCC LC23065    ;if unset, branch
LC2305D:  PHA            ;save shifted "Which Character" byte
LC2305E:  LDA $3018,X
LC23061:  TSB $3A40      ;mark character as acting as enemy
LC23064:  PLA
LC23065:  LSR
LC23066:  LSR            ;original Which Character byte, except top 2 bits
                         ;are zeroed
LC23067:  STA $3ED8,X
LC2306A:  LDY #$000F
LC2306D:  PHY            ;save loop variable
LC2306E:  PHA            ;save Which Character
LC2306F:  LDA $1850,Y
LC23072:  AND #$20       ;Isolate character row.  clear if Front, set if Back.
LC23074:  STA $FE
LC23076:  JSR $30DC      ;get ID of character in roster slot Y
LC23079:  CMP $01,S
LC2307B:  BNE LC230CE    ;skip character if ID of roster member doesn't match
                         ;value of Which Character byte for this party slot
LC2307D:  PHX            ;save 0,2,4,6 index of character
LC2307E:  PHA            ;save character ID
LC2307F:  LDA $FE
LC23081:  STA $3AA1,X    ;save character row in Special Properties
LC23084:  LDA $3ED9,X    ;should be FFh, unless a special event installed this
                         ;character, in which case it'll hold their sprite #
LC23087:  PHA            ;Put on stack
LC23088:  LDA $06,S      ;retrieve loop variable of 0 to 15
LC2308A:  STA $3ED9,X    ;save our roster position #
LC2308D:  TDC
LC2308E:  TXA            ;put onscreen character index in A
LC2308F:  ASL
LC23090:  ASL
LC23091:  ASL
LC23092:  ASL
LC23093:  TAX
LC23094:  PLA
LC23095:  CMP #$FF       ;was there a valid sprite supplied by special event?
LC23097:  BNE LC2309C    ;branch if so
LC23099:  LDA $1601,Y    ;get character's current sprite from roster data
LC2309C:  STA $2EAE,X    ;save battle sprite
LC2309F:  TDC
LC230A0:  PLA            ;retrieve character ID
LC230A1:  STA $2EC6,X
LC230A4:  CMP #$0E       ;is it Banon or higher?  set Carry Flag accordingly
LC230A6:  REP #$20       ;Set 16-bit Accumulator
LC230A8:  PHA            ;save character ID
LC230A9:  LDA $1602,Y    ;1st two letters of character's name
LC230AC:  STA $2EAF,X
LC230AF:  LDA $1604,Y    ;middle two letters of character's name
LC230B2:  STA $2EB1,X
LC230B5:  LDA $1606,Y    ;last two letters of character's name
LC230B8:  STA $2EB3,X
LC230BB:  PLX            ;get character ID
LC230BC:  BCS LC230C4    ;if character # is >= 0Eh [Banon], then don't bother
                         ;[properly] marking them for purposes of what can be
                         ;equipped on whom
LC230BE:  TDC            ;Clear Accumulator
LC230BF:  SEC            ;set carry flag
LC230C0:  ROL            ;move up a bit, starting with bottom
LC230C1:  DEX
LC230C2:  BPL LC230C0    ;move bit into position determined by actual # of character.
                         ;so for Character #3, only Bit #3 is on

;the following, including the next 2 instructions, is still executed for Banon and up.  seemingly,
; jibberish [the last 2 characters of the character name] is stored in that character's equippable
; items byte.  i'm not sure why this is done, but the game does have a property on these characters
; that prevents you from equipping all sorts of random crap via the Item menu in battle.)

LC230C4:  PLX            ;get onscreen 0,2,4,6 index of character
LC230C5:  STA $3A20,X    ;related to what characters item can be equipped on.
                         ;should only be our basic 14
LC230C8:  TYA
LC230C9:  STA $3010,X    ;save offset of character info block
LC230CC:  SEP #$20       ;Set 8-bit Accumulator
LC230CE:  PLA            ;retrieve Which Character byte
LC230CF:  PLY            ;retrieve loop index
LC230D0:  DEY
LC230D1:  BPL LC2306D    ;iterate for all 16 character info blocks in roster
LC230D3:  DEX
LC230D4:  DEX
LC230D5:  BMI LC230DA
LC230D7:  JMP $304D      ;iterate for all 4 party members
LC230DA:  PLP
LC230DB:  RTS


;Get ID of character in roster slot Y

LC230DC:  TYA
LC230DD:  XBA
LC230DE:  LDA #$25       ;multiple by 37 bytes, size of character block
LC230E0:  JSR $4781
LC230E3:  TAY
LC230E4:  LDA $1600,Y    ;character ID, aka "Actor"
LC230E7:  RTS


;Loads battle formation data

LC230E8:  PHP
LC230E9:  REP #$30       ;Set 16-bit A, X, & Y
LC230EB:  LDA $3EB9      ;from event bits, list of enabled formation interchanges --
                         ;that is, whether we'll be allowed to switch a formation that
                         ;matches one in the "Formations to Change From" list to the
                         ;corresponding one in the "Formations to Change To" list
LC230EE:  STA $EE
LC230F0:  LDX #$001C
LC230F3:  LDA $EE        ;is this potential interchange enabled?
LC230F5:  BPL LC23107    ;branch if not
LC230F7:  LDA $CF3780,X  ;read from list of Formations to Change From,
                         ;which consists of 1C4h (SrBehemoth living, and 7 blank
                         ;entries.
LC230FB:  CMP $11E0
LC230FE:  BNE LC23107    ;Branch if current battle formation isn't a match.
LC23100:  LDA $CF3782,X  ;get corresponding entry from list of Formations to
                         ;Change To, which consists of 1A8h (SrBehemoth undead,
                         ;and 7 blank entries.
LC23104:  STA $11E0      ;update the Battle formation
LC23107:  ASL $EE
LC23109:  DEX
LC2310A:  DEX
LC2310B:  DEX
LC2310C:  DEX
LC2310D:  BPL LC230F3    ;iterate 8 times
LC2310F:  LDA #$8000
LC23112:  TRB $11E0      ;Clear highest bit of battle formation
LC23115:  BEQ LC23127    ;Branch if not rand w/ next 3
LC23117:  SEP #$30
LC23119:  TDC
LC2311A:  JSR $4B5A      ;random: 0 to 255
LC2311D:  AND #$03       ;0 to 3
LC2311F:  REP #$31       ;set 16-bit A, X and Y.  clear Carry
LC23121:  ADC $11E0
LC23124:  STA $11E0      ;Add 0 to 3 to battle formation
LC23127:  LDA $3ED4      ;get First Battle Formation
LC2312A:  ASL
LC2312B:  LDA $11E0      ;get Current Battle formation
LC2312E:  BCC LC23133    ;branch if First Battle Formation was already defined,
                         ;which it rarely is outside of multi-part battles like
                         ;Veldt Cave SrBehemoths or Final Kefka's Tiers
LC23130:  STA $3ED4      ;if it wasn't, copy Current Formation to it
LC23133:  ASL
LC23134:  ASL
LC23135:  TAX
LC23136:  LDA $CF5902,X  ;bytes 2-3 of extra enemy formation data
LC2313A:  STA $2F4A
LC2313D:  LDA $CF5900,X  ;bytes 0-1 of extra enemy formation data
LC23141:  EOR #$00F0     ;invert the top nibble of byte 0, which contains the
                         ;attack formations masked -- Front, Back, Pincer, Side
LC23143:  STA $2F48
LC23147:  LDA $11E0
LC2314A:  ASL
LC2314B:  ASL
LC2314C:  ASL
LC2314D:  ASL
LC2314E:  SEC
LC2314F:  SBC $11E0      ;A = Monster formation * 15
LC23152:  TAX
LC23153:  TDC
LC23154:  TAY
LC23155:  LDA $CF6200,X  ;Load Battle formation data
LC23159:  STA $3F44,Y
LC2315C:  INX
LC2315D:  INX
LC2315E:  INY
LC2315F:  INY
LC23160:  CPY #$0010
LC23163:  BCC LC23155    ;copy all 16 bytes of data
LC23165:  PLP
LC23166:  RTS


;Entity executes one largely unblockable hit on self

LC23167:  LDA #$80
LC23169:  TRB $B3        ;Set Ignore Clear
LC2316B:  LDA #$0C
LC2316D:  TSB $BA        ;Sets Can target dead/hidden entities, and
                         ;Don't retarget if target invalid
LC2316F:  STZ $341B      ;enable attack to hit Jumpers
LC23172:  REP #$20
LC23174:  LDA $3018,X
LC23177:  STA $B8        ;Sets attacker as target
LC23179:  SEP #$20

;Entity Executes One Hit (Loops for Multiple-Strike Attack

LC2317B:  PHX
LC2317C:  LDA $BD
LC2317E:  STA $BC        ;copy turn-wide Damage Incrementor to current Damage
                         ;Incrementor
LC23180:  LDA #$FF
LC23182:  STA $3A82      ;Null Golem block
LC23185:  STA $3A83      ;Null Dog block
LC23188:  LDA $3400      ;Spell # for a second attack.  Used by the Magicite item,
                         ;weapons with normal addition magic [Flame Sabre,
                         ;Pearl Lance, etc], and Tempest.
                         ;Sketch also sets $3400, but the variable is swapped into
                         ;$B6 by the Sketch command (C2/151F rather than by this
                         ;routine.  Thus, $3400 will always be null at this point
                         ;for Sketch.
LC2318B:  INC
LC2318C:  BNE LC231B3    ;Branch if there is a spell [i.e. the spell # is not FFh]

LC2318E:  LDA $3413      ;If Fight or Capture command, holds command number.
                         ;[Note that Rage's Battle and Special also qualify as
                         ;"Fight".]
                         ;That way, if a spell is cast by a weapon for one strike
                         ;(which will overwrite the command # and attack data,
                         ;we'll be able to continue with the Fight/Capture command
                         ;and use the weapon as normal on the next strike.

                         ;If command isn't Fight or Capture, this holds FFh.
LC23191:  BMI LC231B3    ;branch if negative

LC23193:  STA $B5        ;Restore command #
LC23195:  JSR $26D3      ;Load data for command [held in A.bottom] and data of
                         ;"Battle" spell
LC23198:  LDA $3A70      ;# of extra attacks - set by Quadra Slam, Dragon Horn,
                         ;Offering, etc
LC2319B:  INC            ;add one.  even number will check right hand, odd number
                         ;the left.  so in a Genji Glove+Offering sequence, for
                         ;instance, we'd have: 8 = Right, 7 = Left, 6 = Right,
                         ;5 = Left, 4 = Right, 3 = Left, 2 = Right, then 1 = Left
LC2319C:  LSR            ;put bottommost bit of # attacks in carry flag
LC2319D:  JSR $299F      ;Load weapon data into attack data.
                         ;Plus Sniper Sight, Offering and more.
LC231A0:  LDA $11A6
LC231A3:  BNE LC231A8
LC231A5:  JMP $3275      ;branch if zero battle power, which can result from a hand
                         ;without a weapon, among other things.  Fight/Capture set
                         ;the strike quantity to 2 -- or 8 if you have Offering --
                         ;regardless of whether you have Genji Glove.  thus, when
                         ;there's only 1 attack hand, this branch is what skips all
                         ;the even or odd strikes corresponding to the other hand.
LC231A8:  LDA $B5
LC231AA:  CMP #$06
LC231AC:  BNE LC231B3    ;branch if command isn't Capture
LC231AE:  LDA #$A4       ;Causes attack to also steal
LC231B0:  STA $11A9      ;save special effect
LC231B3:  JSR $37EB      ;Set up weapon addition magic, Tempest's Wind Slash,
                         ;and Espers summoned by the Magicite item

LC231B6:  LDA #$20
LC231B8:  TRB $B2        ;Bit 5 is set to begin a turn
LC231BA:  BEQ LC231C1    ;branch if it was already clear -- in other words, if
                         ;we're on the second strike or later of this turn.
LC231BC:  BIT $11A3
LC231BF:  BNE LC231C5    ;Branch if Retarget if target invalid/dead
LC231C1:  LDA #$04
LC231C3:  TSB $BA        ;NOTE: in $BA, the bit now means *Don't* retarget
                         ;if target dead/invalid

;To recap the above: if we're on the 1st strike, "Don't Retarget if no valid targets" will
; depend on the attack stats.  If we're on a later strike, it always gets set.  This explains
; why Genji Glove's [sans Offering] second strike will always smack the initial target, even
; if the first one killed it.  However, most multi-strike attacks -- Offering, Dragon Horn,
; and Quadra Slam/Slice -- set "Randomize Target", which makes you retarget anyway.)

LC231C5:  LDA $B8
LC231C7:  ORA $B9
LC231C9:  BNE LC231D3    ;branch if at least one target exists
LC231CB:  LDA #$04
LC231CD:  BIT $B3        ;is it non Dead/Petrify/Zombie-affecting,
                         ;non Magic-using Item/Tool/Throw?
LC231CF:  BEQ LC231D3    ;branch if so
LC231D1:  TRB $BA        ;clear "Don't retarget if target invalid"..
                         ;iow, retarget if target invalid
LC231D3:  LDA $3415      ;will be zero for: the attack performed via Sketch,
                         ;Umaro's Blizzard, Runic, Tempest's Wind Slash, and
                         ;Espers summoned with the Magicite item
LC231D6:  BMI LC231DC    ;otherwise, it's FFh, so branch.
LC231D8:  LDA #$40
LC231DA:  TSB $BA        ;Set randomize targets
LC231DC:  LDA $B3
LC231DE:  LSR
LC231DF:  BCS LC231E9    ;branch if Bit 0 of $B3 set.  to my knowledge, it's
                         ;only UNset by a failed Blitz input.
LC231E1:  LDA #$04
LC231E3:  TSB $BA        ;set Don't retarget if target invalid
LC231E5:  STZ $B8
LC231E7:  STZ $B9        ;clear targets

LC231E9:  JSR $3666      ;Prepare attack name for display atop screen.  Also
                         ;load a few properties for Joker Dooms.
LC231EC:  LDA $3417
LC231EF:  BMI LC231F2    ;branch if Sketcher is null
LC231F1:  TAX            ;use Sketcher as attacker
LC231F2:  LDA $3A7C
LC231F5:  CMP #$1E       ;is command Enemy Roulette?
LC231F7:  BNE LC23201    ;branch if not
LC231F9:  STZ $B8
LC231FB:  STZ $B9        ;clear targets
LC231FD:  LDA #$04
LC231FF:  STA $BA        ;Don't retarget if target invalid
LC23201:  LDA $11A5
LC23204:  BEQ LC23225    ;branch if 0 MP cost
LC23206:  LDA $3EE5,X
LC23209:  BIT #$08
LC2320B:  BNE LC2321B    ;Branch if Mute
LC2320D:  LDA $3EE4,X
LC23210:  BIT #$20       ;Check for Imp status
LC23212:  BEQ LC23225    ;Branch if not ^
LC23214:  LDA $3410
LC23217:  CMP #$23
LC23219:  BEQ LC23225    ;Branch if spell is Imp
LC2321B:  TXA
LC2321C:  LSR
LC2321D:  XBA
LC2321E:  LDA #$0E
LC23220:  JSR $62BF
LC23223:  BRA LC23275
LC23225:  JSR $352B      ;Runic function
LC23228:  JSR $3838      ;Check Air Anchor action death
LC2322B:  JSR $2B9D      ;Damage Calculation
LC2322E:  JSR $0D4A      ;Atlas Armlet / Earring
LC23231:  REP #$20       ;Set 16-bit Accumulator
LC23233:  JSR $3292
LC23236:  LDA $11A2
LC23239:  LSR
LC2323A:  BCS LC23243    ;Branch if physical attack.  this rules out True Knight
                         ;bodyguarding, which sets $A6 for its own purposes.
LC2323C:  LDA $A6        ;Reflected spell or Launcher/Super Ball special effect?
LC2323E:  BEQ LC23243    ;branch if not
LC23240:  JSR $3483      ;Super Ball, Launcher, and Reflected spells function
LC23243:  LDA $3A30      ;get backup targets
LC23246:  STA $B8        ;copy to normal targets, for next strike
LC23248:  SEP #$20       ;Set 8-bit Accumulator
LC2324A:  JSR $4391      ;update statuses for everybody onscreen
LC2324D:  JSR $363E      ;handle random addition magic for weapons,
                         ;in preparation for next strike
LC23250:  LDA $3401
LC23253:  CMP #$FF       ;is there text to display for the command or attack?
LC23255:  BEQ LC23262    ;branch if not
LC23257:  XBA
LC23258:  LDA #$02
LC2325A:  JSR $62BF      ;queue display of text?
LC2325D:  LDA #$FF
LC2325F:  STA $3401      ;no more text to display
LC23262:  LDA $11A7
LC23265:  BIT #$02
LC23267:  BEQ LC23275    ;if there's no text if spell hits, branch
LC23269:  CPX #$08
LC2326B:  BCC LC23275    ;if attacker isn't monster, branch
LC2326D:  LDA $B6        ;get attack/spell #
LC2326F:  XBA
LC23270:  LDA #$02
LC23272:  JSR $62BF      ;queue display of text for spell that hit
LC23275:  LDA #$FF
LC23277:  STA $3414      ;clear Ignore Damage Modification
LC2327A:  STA $3415      ;disable forced randomization, and allow backing up
                         ;of targets
LC2327D:  STA $341C      ;disable "strike is missable weapon spellcasting"
LC23280:  LDA $3A83      ;get Dog block
LC23283:  BMI LC23288    ;if it didn't occur, branch
LC23285:  STA $3416      ;save backup of who benefitted from Dog block,
                         ;as $3A83 will be nulled on next strike should
                         ;it be a multi-strike attack.
LC23288:  PLX
LC23289:  DEC $3A70      ;# more attacks set by Offering, Quadra Slam,
                         ;Dragon Horn, etc
LC2328C:  BMI LC23291    ;if it's negative, there are no more, so exit
LC2328E:  PEA $317A      ;if there are more, repeat this $317B function
LC23291:  RTS


LC23292:  STZ $3A5A      ;Indicates no targets as missed
LC23295:  STZ $3A54      ;Indicate nobody being hit in the back
LC23298:  JSR $6400      ;Zero $A0 through $AF
LC2329B:  JSR $587E      ;targeting function
LC2329E:  PHX
LC2329F:  LDA $B8        ;load targets
LC232A1:  JSR $520E      ;X = number of bits set in A, so # of targets
LC232A4:  STX $3EC9      ;save number of targets
LC232A7:  PLX
LC232A8:  JSR $123B      ;True Knight and Love Token
LC232AB:  JSR $57C2
LC232AE:  JSR $3865      ;depending on $3415, copy targets into backup targets
                         ;and add to "already hit targets" list, or copy backup
                         ;targets into targets.
LC232B1:  LDA $3A4C      ;actual MP cost to caster
LC232B4:  BEQ LC232EC    ;if there is none, skip these affordability checks
LC232B6:  SEC            ;set Carry for upcoming subtraction
LC232B7:  LDA $3C08,X    ;attacker MP
LC232BA:  SBC $3A4C      ;MP cost to attacker
LC232BD:  STZ $3A4C      ;clear MP cost
LC232C0:  BCS LC232E0    ;branch if attacker had sufficient MP
LC232C2:  CPX #$08
LC232C4:  BCC LC232CA    ;branch if character
LC232C6:  LDY #$12
LC232C8:  STY $B5
LC232CA:  JSR $35AD      ;Write data in $B4 - $B7 to current slot in ($76
                         ;animation buffer, and point $3A71 to this slot
LC232CD:  STZ $A2
LC232CF:  STZ $A4
LC232D1:  LDA #$0002
LC232D4:  TRB $11A7      ;clear Text if Hits bit
LC232D7:  LDA #$2802
LC232DA:  JSR $629B      ;Copy A to $3A28-$3A29, and copy $3A28-$3A2B variables
                         ;into ($76) animation buffer
LC232DD:  JMP $63DB      ;Copy $An variables to ($78) buffer
LC232E0:  STA $3C08,X    ;attacker MP = attacker MP - spell MP cost
LC232E3:  LDA #$0080
LC232E6:  ORA $3204,X
LC232E9:  STA $3204,X    ;Set flag that will cause attacker's Magic, Esper,
                         ;and Lore menus to be refreshed
LC232EC:  SEP #$20       ;Set 8-bit Accumulator
LC232EE:  LDA $3412
LC232F1:  CMP #$06       ;is attack a monster Special?
LC232F3:  BNE LC2334F    ;branch if not
LC232F5:  PHX
LC232F6:  LDA #$02
LC232F8:  TSB $B2        ;Set no critical & ignore True Knight
LC232FA:  LSR
LC232FB:  TSB $A0
LC232FD:  LDA $3C81,X    ;get enemy Special move graphic
LC23300:  STA $B7        ;save graphic index
LC23302:  LDA $322D,X    ;get monster's special attack
LC23305:  PHA            ;Put on stack
LC23306:  ASL            ;is bit 6, "Do no damage," set?
LC23307:  BPL LC23311    ;if it isn't, branch
LC23309:  STZ $11A6      ;clear Battle Power
LC2330C:  LDA #$01
LC2330E:  TSB $11A7      ;set to "Miss if No Status Set or Clear"
LC23311:  BCC LC23318    ;branch if Bit 7 wasn't set
LC23313:  LDA #$20
LC23315:  TSB $11A4      ;set Can't be Dodged
LC23318:  PLA
LC23319:  AND #$3F       ;get bottom 6 bits of monster's special attack
LC2331B:  CMP #$30
LC2331D:  BCC LC23339    ;branch if value < 30h, "Absorb HP"
LC2331F:  CMP #$32
LC23321:  BCS LC23332    ;branch if value > 31h, "Absorb MP"
LC23323:  LSR            ;get bottom bit
LC23324:  LDA #$02
LC23326:  TSB $11A4      ;turn on Redirection bit of spell
LC23329:  BCC LC2334E    ;branch if bottom bit of attack byte was 0
LC2332B:  LDA #$80
LC2332D:  TSB $11A3      ;Set to Concern MP
LC23330:  BRA LC2334E
LC23332:  LDA #$04       ;s/b reached if bottom 6 bits of attack byte >= 32h.
                         ;so real examples are 32h, "Remove Reflect", and
                         ;Skull Dragon's 3Fh, which had "???" for description
LC23334:  TSB $11A4      ;turn on "Lift status" spell bit
LC23337:  LDA #$17       ;act is if just "Reflect" is in attack byte, so
                         ;there'll be no attack power
LC23339:  CMP #$20
LC2333B:  BCC LC23345    ;if value < 20h, there is no Attack Level boost, but
                         ;there is a status to alter
LC2333D:  SBC #$20
LC2333F:  ADC $BC
LC23341:  STA $BC        ;add attack level btwn 0 and Fh, plus the carry flag
                         ;[which is always 1 here], to Damage Incrementer
LC23343:  BRA LC2334E    ;don't mess with statuses
LC23345:  JSR $5217      ;transform the attack byte value 0 to 1F into
                         ;a spell status bit to set in $11AA, $11AB,
                         ;$11AC, or $11AD
LC23348:  ORA $11AA,X
LC2334B:  STA $11AA,X
LC2334E:  PLX
LC2334F:  LDA #$40
LC23351:  TSB $B2        ;Clear little Runic sword animation
LC23353:  BNE LC23364    ;If it wasn't set to begin with, branch over
                         ;this animation code.
LC23355:  LDA #$25
LC23357:  XBA
LC23358:  LDA #$06
LC2335A:  JSR $62BF
LC2335D:  JSR $63DB      ;Copy $An variables to ($78) buffer
LC23360:  LDA #$10
LC23362:  TRB $A0
LC23364:  LDA #$08
LC23366:  BIT $3EF9,X
LC23369:  BEQ LC2336F    ;Branch if attacker not morphed
LC2336B:  INC $BC
LC2336D:  INC $BC        ;Double damage if morphed
LC2336F:  LDA $11A2
LC23372:  LSR
LC23373:  BCC LC2337E    ;Branch if magic damage
LC23375:  LDA #$10
LC23377:  BIT $3EE5,X
LC2337A:  BEQ LC2337E    ;Branch if attacker not berserked
LC2337C:  INC $BC        ;Add 50% damage if berserk and physical attack
LC2337E:  LDA $11A2
LC23381:  BIT #$40
LC23383:  BNE LC23392    ;Branch if no split damage
LC23385:  LDA $3EC9
LC23388:  CMP #$02
LC2338A:  BCC LC23392    ;Branch if only one target
LC2338C:  LSR $11B1
LC2338F:  ROR $11B0      ;Cut damage in half
LC23392:  LDA #$20
LC23394:  BIT $B3
LC23396:  BNE LC233A3    ;Branch if ignore attacker row
LC23398:  BIT $3AA1,X
LC2339B:  BEQ LC233A3    ;Branch if attacker in Front Row
LC2339D:  LSR $11B1
LC233A0:  ROR $11B0      ;Cut damage in half
LC233A3:  JSR $14AD      ;Check if hitting target(s) in back
LC233A6:  JSR $3E7D      ;Special effect code from 42E1, once per strike
LC233A9:  REP #$20       ;Set 16-bit Accumulator
LC233AB:  LDY $3405      ;# of hits left from Super Ball/Launcher
LC233AE:  BMI LC233B1    ;If there aren't any, those special effects aren't being
                         ;used, so jump to the normal Combat function.
                         ;If there are, we skip the Combat function, as C2/3483
                         ;more or less takes its place.
LC233B0:  RTS


;Combat function

LC233B1:  LDY #$12
LC233B3:  LDA $3018,Y
LC233B6:  BIT $A4
LC233B8:  BEQ LC233C1    ;Skip if spell doesn't target that entity
LC233BA:  JSR $220D      ;Determine whether attack hits
LC233BD:  BCC LC233C1    ;branch if it hits
LC233BF:  TRB $A4        ;Makes attack miss target
LC233C1:  DEY
LC233C2:  DEY
LC233C3:  BPL LC233B3    ;Do for all 10 possible targets
LC233C5:  SEP #$20       ;Set 8-bit accumulator
LC233C7:  LDA $341C
LC233CA:  BMI LC233D6    ;branch if not a missable weapon spellcasting
LC233CC:  LDA $A4
LC233CE:  ORA $A5
LC233D0:  BNE LC233D6    ;Branch if at least one target hit
LC233D2:  LDA #$12
LC233D4:  STA $B5        ;use null animation for strike
LC233D6:  LDA $341D
LC233D9:  BMI LC233E5    ;branch if an insta-kill weapon hasn't activated
                         ;instant death this turn.
LC233DB:  LDA $A2
LC233DD:  ORA $A3
LC233DF:  BNE LC233E5    ;Branch if at least one entity targetted
LC233E1:  LDA #$12
LC233E3:  STA $B5        ;use null animation for strike
LC233E5:  LDA #$40
LC233E7:  BIT $3C95,X
LC233EA:  BEQ LC233F2    ;Branch if not auto critical when Imp
LC233EC:  LSR
LC233ED:  BIT $3EE4,X
LC233F0:  BNE LC2340C    ;If Attacker is imp do auto critical
LC233F2:  LDA #$02
LC233F4:  BIT $B3
LC233F6:  BEQ LC2340C    ;Automatic critical if bit 1 of $B3 not set
LC233F8:  BIT $B2
LC233FA:  BNE LC23414    ;No critical if bit 1 of $B2 set
LC233FC:  BIT $BA
LC233FE:  BEQ LC23414    ;No critical if not attacking opposition
LC23400:  JSR $4B5A      ;Random Number 0 to 255
LC23403:  CMP #$08       ;1 in 32 chance
LC23405:  BCS LC23414
LC23407:  LDA $3EC9
LC2340A:  BEQ LC23414    ;No critical if no targets
LC2340C:  INC $BC        ;Critical hit x2 damage
LC2340E:  INC $BC
LC23410:  LDA #$20
LC23412:  TSB $A0        ;Set to flash screen
LC23414:  JSR $35AD      ;Write data in $B4 - $B7 to current slot in ($76
                         ;animation buffer, and point $3A71 to this slot
LC23417:  REP #$20
LC23419:  LDA $11B0      ;Maximum Damage
LC2341C:  JSR $370B      ;Increment damage function
LC2341F:  STA $11B0      ;Maximum Damage
LC23422:  SEP #$20
LC23424:  LDA $11A3
LC23427:  ASL
LC23428:  BPL LC2342E    ;Branch if not Caster dies
LC2342A:  TXY
LC2342B:  JSR $3852      ;Kill caster
LC2342E:  LDY $32B9,X    ;who's Controlling this entity?
LC23431:  BMI LC2343C    ;branch if nobody is
LC23433:  PHX
LC23434:  TYX            ;X points to controller
LC23435:  LDY $32B8,X    ;Y = whom the controller is controlling
                         ;[in other words, the entity we previously
                         ; had in X]
LC23438:  JSR $372F      ;regenerate the Control menu.  it will
                         ;account for the MP cost of a spell cast
                         ;this turn, but unfortunately, the call is too
                         ;early to account for actual MP damage/healing/
                         ;draining done by the spell, so the menu will
                         ;lag a turn behind in that respect.
LC2343B:  PLX            ;restore X pointing to original entity
LC2343C:  REP #$20
LC2343E:  LDY #$12
LC23440:  LDA $3018,Y
LC23443:  TRB $A4        ;Make attack miss target, for now
LC23445:  BEQ LC2346C    ;Skip if not target of attack
LC23447:  BIT $3A54      ;Check if hitting back of target
LC2344A:  BEQ LC2344E
LC2344C:  INC $BC        ;Increment damage if hitting back
LC2344E:  JSR $35E3      ;initialize several variables for counterattack
                         ;purposes
LC23451:  CPY $33F8      ;Has this target used Zinger?
LC23454:  BEQ LC2346C    ;If it has, branch to next target
LC23456:  STZ $3A48      ;start off assuming attack did not miss this target
LC23459:  JSR $4406      ;determine status to be set/removed when attack hits
                         ;miss if attack doesn't change target status
LC2345C:  JSR $387E      ;Special effect code for target
LC2345F:  LDA $3A48
LC23462:  BNE LC2346C    ;Branch if attack missed this target, due to it not
                         ;changing any statuses or to checks in its special
                         ;effect
LC23464:  LDA $3018,Y
LC23467:  TSB $A4        ;Make attack hit target
LC23469:  JSR $0B83      ;Modify Damage, Heal Undead, and Elemental modification
LC2346C:  DEY
LC2346D:  DEY
LC2346E:  BPL LC23440    ;iterate for all 10 entities
LC23470:  JSR $62EF      ;subtract/add damage/healing from/to entities' HP or MP,
                         ;then queue damage and/or healing values for display
LC23473:  JSR $36D6      ;Learn lore
LC23476:  LDA $A4
LC23478:  BNE LC23480    ;Branch if 1 or more targets hit
LC2347A:  LDA #$0002
LC2347D:  TRB $11A7      ;Clear Text if Hits bit
LC23480:  JMP $63DB      ;Copy $An variables to ($78) buffer


;Super Ball / Launcher / Reflected off targets function.
; Seems to be a specialized counterpart of the "Combat Function" at C2/33B1.
; For Super Ball / Launcher, it replaces that function.  For Reflect, this is called
; shortly after that function.)

LC23483:  PHX
LC23484:  PHA            ;Put on stack
LC23485:  JSR $6400      ;Zero $A0 through $AF
LC23488:  STZ $3A5A      ;Set no targets as missed
LC2348B:  SEP #$20       ;Set 8-bit Accumulator
LC2348D:  LDA #$22
LC2348F:  TSB $11A3      ;Set attack to retarget if target invalid/dead,
                         ;not reflectable
LC23492:  LDA #$40
LC23494:  STA $BB        ;Set to cursor start on enemy.  Note we're NOT
                         ;doing any spread-aim here, as the game hits at
                         ;most one target for each target reflected off.
                         ;Likewise, each Launcher firing or Super Ball bounce
                         ;will only hit 1 target.
LC23496:  LDA #$50
LC23498:  TSB $BA        ;Sets randomize target & Reflected
LC2349A:  LDA $B6
LC2349C:  STA $3A2A      ;temporary byte 3 for ($76) animation buffer
LC2349F:  LDX $3405      ;# more times to attack, for Super Ball or Launcher
LC234A2:  BMI LC234AC    ;branch if negative, which should only happen if this
                         ;function was reached due to Reflection
LC234A4:  LDA #$10
LC234A6:  TRB $BA        ;Clear Reflected property
LC234A8:  LDA #$15
LC234AA:  BRA LC234AE
LC234AC:  LDA #$09
LC234AE:  JSR $629B      ;Copy A to $3A28, and copy $3A28-$3A2B variables into
                         ;($76) buffer
LC234B1:  LDA #$FF
LC234B3:  LDY #$09
LC234B5:  STA $00A0,Y    ;$A0 thru $A9 = #$FF
LC234B8:  DEY
LC234B9:  BPL LC234B5    ;iterate 10 times.  as this little loop suggests, you can't
                         ;go setting the Launcher/Super Ball effect to have more
                         ;than 10 "hits."  that means that $3405 can have a maximum
                         ;of 9, for those of you planning your own special effect.
LC234BB:  REP #$20       ;Set 16-bit Accumulator
LC234BD:  LSR $11B0      ;Half damage
LC234C0:  LDY #$12
LC234C2:  LDA $3018,Y
LC234C5:  AND $01,S      ;is the target among those being "reflected off" by
                         ;Reflect/Super Ball/Launcher ?
LC234C7:  BEQ LC2350F    ;if not, skip it
LC234C9:  TYX            ;save loop variable
LC234CA:  JSR $587E      ;get new targets..  since the targeting at C2/3494 was set
                         ;to "cursor start on enemy" and X holds the "reflected off"
                         ;target going into the call, we're essentially performing
                         ;a reflection here
LC234CD:  LDA $B8        ;new targets after reflection
LC234CF:  BEQ LC2350F    ;if there's none, skip our current loop target
LC234D1:  PHY
LC234D2:  JSR $51F9      ;Y = [Number of highest target after reflection] * 2
LC234D5:  PHX
LC234D6:  SEP #$20       ;Set 8-bit Accumulator
LC234D8:  TXA
LC234D9:  LSR
LC234DA:  TAX            ; [onscreen target # of reflected off target] / 2.
                         ;so characters are now 0-3, and enemies are 4-9
LC234DB:  LDA $3405      ;# more times to attack, for Super Ball or Launcher
LC234DE:  BMI LC234E4    ;branch if negative, which should only happen if this
                         ;function was reached due to Reflection
LC234E0:  DEC $3405      ;decrement it
LC234E3:  TAX            ;replace reflected off target # with our iterator
                         ;for Super Ball/Launcher?
LC234E4:  TYA
LC234E5:  LSR            ;A = bit # of highest target after reflection
LC234E6:  STA $A0,X      ;Reflect: $A0,reflected_off_target = new_target
                         ;Super Ball/Launcher: $A0,hit_iterator = new_target
LC234E8:  REP #$20       ;Set 16-bit Accumulator
LC234EA:  PLX
LC234EB:  JSR $220D      ;Determine whether attack hits
LC234EE:  BCS LC23509    ;branch if it misses
LC234F0:  STZ $3A48      ;start off assuming attack did not miss this target
LC234F3:  JSR $35E3      ;initialize several variables for counterattack
                         ;purposes
LC234F6:  JSR $4406      ;determine status to be set/removed when attack hits
                         ;miss if attack doesn't change target status
LC234F9:  JSR $387E      ;special effect code for target
LC234FC:  LDA $3A48
LC234FF:  BNE LC23509    ;Branch if attack missed this target, due to it not
                         ;changing any statuses or to checks in its special
                         ;effect
LC23501:  LDA $3018,X
LC23504:  TSB $AE        ;Set this Reflector as AN originator of the attack
                         ;graphically?  Since $AE will get overwritten later in
                         ;the case of Super Ball / Launcher, this setting only
                         ;applies to Reflection.
LC23506:  JSR $0B83      ;Modify Damage, Heal Undead, and Elemental modification
LC23509:  PLY
LC2350A:  LDX $3405      ;# more times to attack, for Super Ball or Launcher
LC2350D:  BPL LC234C2    ;If it's positive, go again.  This means that for
                         ;Super Ball/Launcher, if "reflecting off" a certain initial
                         ;target produces at least one valid final target, we'll
                         ;keep doing so until it produces the full quantity of
                         ;strikes indicated by original $3405 [+1].
                         ;Hacks-only essay:
                         ;Note that "reflecting off" multiple initial targets for
                         ;Super Ball / Launcher -- which the game never does --
                         ;would produce rather meaningless results.  $3405 would
                         ;equal FFh after the first such target, but the main loop
                         ;would still get repeated by C2/3511.  So mechanically,
                         ;each extra thrower/launcher would perform one extra
                         ;"strike".  But visually, all of the strikes would come
                         ;from our first valid thrower/launcher, and the animation
                         ;may or may not convey that there were extra strikes.

LC2350F:  DEY
LC23510:  DEY
LC23511:  BPL LC234C2    ;loop for everybody on screen

;Uh oh..!  If there were no targets found to reflect onto above, we can reach this point
; with $3405 not being FFh.  As a result, the branch at C2/33AE will keep skipping the normal
; "Combat function" at C2/33B1..  bugging up the current battle.  This will continue until
; another Launcher/Super Ball is attempted when there are actually target(s) to hit.  C2/3483
; will then loop through those targets, bringing $3405 to a "safe" FFh in the process.)

LC23513:  PLA
LC23514:  PLX
LC23515:  LDA #$0010
LC23518:  BIT $BA        ;was there Reflection?
LC2351A:  BNE LC23525    ;branch if so
LC2351C:  LDA $3018,X
LC2351F:  STA $AE        ;Set the missile launcher or the Super Ball thrower as
                         ;THE originator of attack graphically?
LC23521:  STZ $AA
LC23523:  STZ $AC
LC23525:  JSR $62EF      ;subtract/add damage/healing from/to entities' HP or MP,
                         ;then queue damage and/or healing values for display
LC23528:  JMP $63DB      ;Copy $An variables to ($78) buffer


;Runic Function

LC2352B:  LDA $11A3
LC2352E:  BIT #$08       ;can this spell be absorbed by Runic?
LC23530:  BEQ LC235AC    ;Exits function if not
LC23532:  STZ $EE
LC23534:  STZ $EF        ;start off assuming no eligible Runickers
LC23536:  LDY #$12
LC23538:  LDA $3AA0,Y
LC2353B:  LSR            ;is this a valid target?
LC2353C:  BCC LC2355E    ;branch if not
LC2353E:  LDA $3E4C,Y
LC23541:  BIT #$06
LC23543:  BEQ LC2355E    ;Branch if not runic or enemy runic
LC23545:  AND #$FB
LC23547:  STA $3E4C,Y    ;clear Runic
LC2354A:  PEA $80C0      ;Sleep, Death, Petrify
LC2354D:  PEA $2210      ;Freeze, Hide, Stop
LC23550:  JSR $5864
LC23553:  BCC LC2355E    ;Branch if entity has any of above ailments
LC23555:  REP #$20
LC23557:  LDA $3018,Y
LC2355A:  TSB $EE        ;mark this entity as an eligible Runicker
LC2355C:  SEP #$20       ;Set 8-bit Accumulator
LC2355E:  DEY
LC2355F:  DEY            ;have we run through all 10 entities yet?
LC23560:  BPL LC23538    ;loop if not
LC23562:  LDA $EE
LC23564:  ORA $EF        ;are there any eligible Runickers?
LC23566:  BEQ LC235AC    ;Exits function if not
LC23568:  PHX
LC23569:  JSR $3865      ;depending on $3415, copy targets in $B8 into backup
                         ;targets and add to "already hit targets" list, or
                         ;benignly copy backup targets into targets in $B8
                         ;[the latter can be the case if spell is invoked via
                         ;Sketch].
LC2356C:  STZ $3415      ;will stop new targets set below from being copied
                         ;into backup or Mimic targets by later C2/3865 call
                         ;won't force randomization of targets, as variable is
                         ;being zeroed too late for that
LC2356F:  REP #$20       ;Set 16-bit Accumulator
LC23571:  LDA $EE        ;get eligible Runickers
LC23573:  STA $B8        ;save as targets
LC23575:  JSR $520E      ;X = # of bits set in A, i.e. the # of targets
LC23578:  STZ $11AA
LC2357B:  STZ $11AC      ;Make attack set no statuses
LC2357E:  LDA #$2182
LC23581:  STA $11A3      ;Set just concern MP, not reflectable, Unblockable,
                         ;Heal
LC23584:  SEP #$20       ;Set 8-bit Accumulator
LC23586:  LDA #$60
LC23588:  STA $11A2      ;Set just ignore defense, no split damage
LC2358B:  TDC            ;need top half of A clear
LC2358C:  LDA $11A5      ;MP cost of spell
LC2358F:  JSR $4792      ;divide by X
LC23592:  STA $11A6      ;save as Battle Power
LC23595:  JSR $385E      ;Sets level, magic power to 0
LC23598:  STZ $3414      ;Skip damage modification
LC2359B:  LDA #$40
LC2359D:  TRB $B2        ;Flag little Runic sword animation
LC2359F:  LDA #$04
LC235A1:  STA $BA        ;Don't retarget if target invalid
LC235A3:  LDA #$03
LC235A5:  TRB $11A7      ;turn off text if hits and miss if status isn't set
                         ;or clear
LC235A8:  STZ $11A9      ;Set attack to no special effect
LC235AB:  PLX
LC235AC:  RTS


;Write data in $B4 - $B7 to current slot in ($76 animation buffer, and make
; "previous buffer pointer" in $3A71 point to this slot)

LC235AD:  PHX
LC235AE:  LDX $3A72      ;get ($76) animation buffer pointer
LC235B1:  STX $3A71      ;copy to "previous ($76) animation buffer pointer"
LC235B4:  PLX
LC235B5:  JSR $35D4      ;Copy animation data from $B4 - $B7 into $3A28 - $3A2B
                         ;variables
LC235B8:  JMP $629E      ;Copy $3A28-$3A2B variables into ($76) buffer


;Update a previous entry in ($76) animation buffer with data in $B4 - $B7
;Used to change Atma Weapon length, among other things)

LC235BB:  JSR $35D4      ;Copy animation data from $B4 - $B7 into $3A28 - $3A2B
                         ;variables
LC235BE:  PHX            ;preserve X
LC235BF:  PHP
LC235C0:  LDX $3A72
LC235C3:  PHX            ;preserve animation buffer pointer
LC235C4:  LDX $3A71      ;get "previous ($76) animation buffer pointer"
LC235C7:  STX $3A72      ;copy it into current ($76) animation buffer pointer
LC235CA:  JSR $629E      ;update animation data in the previous ($76 buffer
                         ;entry
LC235CD:  PLX
LC235CE:  STX $3A72      ;restore ($76) animation buffer pointer
LC235D1:  PLP
LC235D2:  PLX            ;restore X
LC235D3:  RTS


;Copy animation data from $B4 - $B7 into $3A28 - $3A2B variables

LC235D4:  PHP
LC235D5:  REP #$20       ;Set 16-bit Accumulator
LC235D7:  LDA $B4
LC235D9:  STA $3A28      ;temporary bytes 1 and 2 for ($76) animation buffer
LC235DC:  LDA $B6
LC235DE:  STA $3A2A      ;temporary bytes 3 and 4 for ($76) animation buffer
LC235E1:  PLP
LC235E2:  RTS


;Initialize several variables for counterattack purposes

LC235E3:  PHP
LC235E4:  SEP #$30
LC235E6:  JSR $361B      ;Mark entity X as the last attacker of entity Y, but
                         ;50% chance not if Y already has an attacker this turn
LC235E9:  TXA
LC235EA:  STA $3290,Y    ;save attacker [or reflector if reflection involved] #
LC235ED:  LDA $3A7C
LC235F0:  STA $3D48,Y    ;save command #
LC235F3:  LDA $3410
LC235F6:  CMP #$FF
LC235F8:  BEQ LC23601    ;branch if there's no Spell # [or a Skean/Tool/
                         ;piece of equipment using a spell] defined for attack.
LC235FA:  STA $3D49,Y    ;save the spell #
LC235FD:  TXA
LC235FE:  STA $3291,Y    ;save attacker [or reflector if reflection involved] #
LC23601:  LDA $3411
LC23604:  CMP #$FF
LC23606:  BEQ LC2360F    ;branch if there's no Item # [or a Skean/Tool that
                         ;doesn't use a spell] defined for attack.
LC23608:  STA $3D5C,Y    ;save item #
LC2360B:  TXA
LC2360C:  STA $32A4,Y    ;save attacker [or reflector if reflection involved] #
LC2360F:  LDA $11A1
LC23612:  STA $3D5D,Y    ;save attack's element/s
LC23615:  TXA
LC23616:  STA $32A5,Y    ;save attacker [or reflector if reflection involved] #
LC23619:  PLP
LC2361A:  RTS


;Mark entity X as the last attacker of entity Y, but 50% chance of
; not doing so if Y already has an attacker this turn)

LC2361B:  PHP
LC2361C:  SEP #$21       ;Set 8-bit Accumulator, and set Carry
LC2361E:  LDA $32E0,Y
LC23621:  BPL LC23628    ;branch if this target doesn't yet have an attacker
                         ;[which can be a reflector, if reflection is involved]
LC23623:  JSR $4B53
LC23626:  BCC LC2362D    ;50% chance this attacker overwrites current one
LC23628:  TXA
LC23629:  ROR            ; [onscreen index of attacker] / 2.
                         ;so characters are now 0-3, and enemies are 4-9
LC2362A:  STA $32E0,Y    ;save index in bottom 7 bits, and turn on top bit
LC2362D:  PLP
LC2362E:  RTS


;Mark entity X as the last attacker of entity Y, unless Y already
; has an attacker this turn.  Arbitrarily set/clear flag indicating
; whether entity Y was attacked this turn.)

LC2362F:  PHA            ;Put on stack
LC23630:  PHP
LC23631:  LDA $32E0,Y
LC23634:  BMI LC2363B    ;branch if this target already has an attacker for
                         ;this turn
LC23636:  TXA
LC23637:  ROR            ;Bits 0-6 = [onscreen index of attacker] / 2.
                         ;so characters are now 0-3, and enemies are 4-9.
                         ;Bit 7 = Carry flag passed by caller.  sadly, it's
                         ;arbitrary gibberish from three of the callers:
                         ;function C2/0C2D, function C2/384A when called
                         ;via C2/387E, and function C2/384A when called via
;                                     LC23E7D.)
LC23638:  STA $32E0,Y
LC2363B:  PLP
LC2363C:  PLA
LC2363D:  RTS


;Weapon "addition magic"

LC2363E:  LDA $B5
LC23640:  CMP #$16       ;is Command Jump?
LC23642:  BNE LC23649    ;if not, branch
LC23644:  LDA $3A70      ;are there more attacks to do from Offering /
                         ;Quadra Slam / Dragon Horn / etc?
LC23647:  BNE LC23665    ;if so, exit function
LC23649:  LDA $3A89
LC2364C:  BIT #$40       ;is "cast randomly with fight" bit set in the
                         ;weapon spellcast byte?
LC2364E:  BEQ LC23665    ;if not, Exit function
LC23650:  XBA
LC23651:  JSR $4B5A      ;random #, 0 to 255
LC23654:  CMP #$40
LC23656:  BCS LC23665    ;if that # is 64 or greater, exit function.  iow, exit
                         ;3/4 of time.
LC23658:  XBA
LC23659:  AND #$3F       ;isolate spell # of weapon in bottom 6 bits
LC2365B:  STA $3400      ;save it
LC2365E:  LDA #$10
LC23660:  TRB $B2        ;this bit distinguishes traditional "addition magic"
                         ;spellcasts from Tempest's Wind Slash in a few ways in
;                                     LC237EB.)
                         ;one is that it'll cause the targeting byte to be set to
                         ;only "Cursor start on enemy" for the followup spell.
                         ;maybe the goal is to prevent the spell from targeting
                         ;multiple enemies..?  but i'm not sure when the spellcast
                         ;would even try to target anything other than the target
                         ;whacked by the weapon, unless the spell randomizes
                         ;targets, which no normal "addition magic" does.
LC23662:  INC $3A70      ;increment # of attacks remaining.  since the calling
                         ;code will soon decrement this, the addition magic
                         ;should be cast with the same # of attacks remaining
                         ;as the weapon strike preceding it was.
LC23665:  RTS


;Prepare attack name for display atop screen.  Also load a few properties for
; Joker Dooms.)

LC23666:  LDA #$01
LC23668:  TRB $B2
LC2366A:  BEQ LC23665    ;exit if we've already called this function before on
                         ;this turn.  will stop Quadra Slam [for example] from
                         ;displaying its name on every strike.
LC2366C:  LDA $3412      ;get message ID
LC2366F:  BMI LC23665    ;exit if undefined
LC23671:  PHX
LC23672:  TXY
LC23673:  STA $3A29      ;temporary byte 2 for ($76) animation buffer
LC23676:  ASL
LC23677:  TAX
LC23678:  LDA #$01
LC2367A:  STA $3A28      ;temporary byte 1 for ($76) animation buffer
LC2367D:  JSR ($36C4,X)
LC23680:  STA $3A2A      ;temporary byte 3 for ($76) animation buffer
LC23683:  PLX
LC23684:  JMP $629E      ;Copy $3A28-$3A2B variables into ($76) buffer


;Magic, non-Summoning non-Joker Doom Slot, successful Dance, Lore, Magitek,
; enemy non-Specials, and many others)
LC23687:  LDA $B6        ;load attack ID
LC23689:  RTS


;Item
LC2368A:  LDA $3A7D
LC2368D:  RTS


;Esper Summon
LC2368E:  SEC
LC2368F:  LDA $B6
LC23691:  SBC #$36       ;convert attack ID to 0-26 Esper ID
LC23693:  RTS


;enemy GP Rain, Health, Shock
LC23694:  LDA $B5        ;load command ID
LC23696:  RTS


;Enemy Special
LC23697:  LDA #$11
LC23699:  STA $3A28      ;temporary byte 1 for ($76) animation buffer
LC2369C:  LDA $33A8,Y    ;get monster ID, bottom byte
LC2369F:  STA $3A29      ;temporary byte 2 for ($76) animation buffer
LC236A2:  LDA $33A9,Y    ;get monster ID, top byte
LC236A5:  RTS


;Joker Dooms
LC236A6:  LDA #$02
LC236A8:  TSB $3A46      ;set flag to let attack target normally untargetable
                         ;entities: Jumpers [err, scratch that, since they'd
                         ;have to be un-Hidden, which i don't think is
                         ;possible], Seized characters, and will ignore "Exclude
                         ;Attacker from targets" and "Abort on characters", etc.
LC236AB:  TRB $11A2      ;Clear miss if instant death protected
LC236AE:  LDA #$20
LC236B0:  TSB $11A4      ;Sets unblockable
LC236B3:  LDA #$00
LC236B5:  STA $3A29      ;temporary byte 2 for ($76) animation buffer
LC236B8:  LDA #$55       ;Joker Doom
LC236BA:  RTS


;Blitz
LC236BB:  LDA #$00
LC236BD:  STA $3A29      ;temporary byte 2 for ($76) animation buffer
LC236C0:  LDA $3A7D
LC236C3:  RTS


;Pointers to code

LC236C4: dw $3687   ;(Magic, non-Summoning non-Joker Doom Slot, successful Dance, Lore,
                    ; Magitek, enemy non-Specials, and many others
LC236C6: dw $368A   ;(Item [which can include a Tool or thrown weapon or skean])
LC236C8: dw $368E   ;(Esper Summon)
LC236CA: dw $3665   ;(does nothing)
LC236CC: dw $3687   ;(SwdTech)
LC236CE: dw $3694   ;(enemy GP Rain, Health, Shock)
LC236D0: dw $3697   ;(Enemy Special)
LC236D2: dw $36A6   ;(Slot - Joker Dooms)
LC236D4: dw $36BB   ;(Blitz)


;Learn lore if casted

LC236D6:  PHX
LC236D7:  PHP
LC236D8:  SEP #$20
LC236DA:  LDA $11A3
LC236DD:  BIT #$04
LC236DF:  BEQ LC23708    ;Branch if not learn when casted
LC236E1:  LDY $3007
LC236E4:  BMI LC23708    ;Exit if Strago not in party
LC236E6:  PEA $B0C3      ;Death, Petrify, Zombie, Dark, Sleep, Muddled, Berserk
LC236E9:  PEA $2310      ;Stop, Hide, Rage, Freeze
LC236EC:  JSR $5864
LC236EF:  BCC LC23708    ;Exit function if any set
LC236F1:  LDA $B6
LC236F3:  SBC #$8B       ;try to convert spell ID to 0-23 Lore ID, as
                         ;8Bh [139d] is ID of first lore, Condemned.
LC236F5:  CLC
LC236F6:  JSR $5217      ;X = A DIV 8, A = 2 ^ (A MOD 8)
LC236F9:  CPX #$03
LC236FB:  BCS LC23708    ;branch if spell ID was outside range of Lores; iow,
                         ;it's not a Lore
LC236FD:  BIT $1D29,X    ;Known lores
LC23700:  BNE LC23708    ;branch if already known
LC23702:  ORA $3A84,X    ;add to Lores to learn
LC23705:  STA $3A84,X
LC23708:  PLP
LC23709:  PLX
LC2370A:  RTS


;Damage increment function
;Damage = damage * (1 + (.5 * $BC))

LC2370B:  PHY
LC2370C:  LDY $BC
LC2370E:  BEQ LC2372D    ;Exit if Damage Incrementor in $BC = 0
LC23710:  PHA            ;Put on stack
LC23711:  LDA $B2
LC23713:  ASL
LC23714:  AND $11A1
LC23717:  ASL
LC23718:  ASL
LC23719:  ASL
LC2371A:  PLA
LC2371B:  BCS LC2372D    ;Exit function if Ignores Defense and bit 4 of $B3
                         ;[Ignore Damage Increment on Ignore Defense] is set
LC2371D:  STA $EE
LC2371F:  LSR $EE
LC23721:  CLC
LC23722:  ADC $EE        ;Add 50% damage
LC23724:  BCC LC23728
LC23726:  TDC
LC23727:  DEC            ;if overflow, set damage to 65535
LC23728:  DEY
LC23729:  BNE LC23721    ;Do this $BC times
LC2372B:  STY $BC        ;Store 0 in $BC
LC2372D:  PLY
LC2372E:  RTS


;Relm's Control menu

LC2372F:  PHX
LC23730:  PHY
LC23731:  PHP
LC23732:  REP #$31       ;set 16-bit A, X and Y.  clear Carry
LC23734:  LDA $C2544A,X  ;address of controlling character's menu
LC23738:  ADC #$0030
LC2373B:  STA $002181    ;Offset for WRAM to access
LC2373F:  TYX
LC23740:  LDA $3C08,X    ;MP of monster
LC23743:  INC
LC23744:  STA $EE        ;add 1, as it'll make future comparisons easier.
                         ;but it also means that assigning 65535 MP to
                         ;a monster won't work properly with Control.
LC23746:  LDA $1FF9,X    ;Monster Type
LC23749:  ASL
LC2374A:  ASL
LC2374B:  TAX            ;X = monster number * 4
LC2374C:  SEP #$20       ;set 8-bit accumulator
LC2374E:  TDC            ;clear A
LC2374F:  STA $002183    ;WRAM will access Bank 7Eh
LC23753:  LDY #$0004
LC23756:  TDC
LC23757:  PHA            ;Put on stack
LC23758:  LDA $CF3D00,X  ;get Relm's Control command
LC2375C:  STA $002180    ;store it in a menu
LC23760:  CMP #$FF
LC23762:  BEQ LC23780    ;branch if the command [aka the spell #] was null
LC23764:  XBA
LC23765:  LDA #$0E       ;there are 14d bytes per spell in magic data
LC23767:  JSR $4781      ;spell number * 14
LC2376A:  PHX
LC2376B:  TAX
LC2376C:  LDA $C46AC5,X  ;get MP cost
LC23770:  XBA
LC23771:  LDA $C46AC0,X  ;get targeting byte
LC23775:  PLX            ;restore X = monster num * 4
LC23776:  STA $01,S      ;replace zero value on stack from C2/3757 with
                         ;targeting byte
LC23778:  CLC            ;clear carry
LC23779:  LDA $EF        ;retrieve (MP of monster + 1) / 256
LC2377B:  BNE LC23780    ;if it's nonzero, branch.  spell MP costs are
                         ;only 1 byte, so we don't have to worry whether
                         ;it's castable
LC2377D:  XBA            ;get MP cost of spell
LC2377E:  CMP $EE        ;carry will be clear if the Cost of spell is less
                         ;than (monster MP + 1), or if the foe has >= 255 MP
                         ;IOW, if the spell is affordable.
LC23780:  ROR            ;rotate carry into top bit of A.  doubt the other bits
                         ;matter, given the XBA above is only done sometimes..
LC23781:  STA $002180    ;write it to menu
LC23785:  PLA            ;get the targeting byte, or zero if the menu entry
                         ;was null
LC23786:  STA $002180    ;write it to menu
LC2378A:  INX
LC2378B:  DEY
LC2378C:  BNE LC23756    ;iterate 4 times, once for each Control command
LC2378E:  PLP
LC2378F:  PLY
LC23790:  PLX
LC23791:  RTS


;Sketch/Control chance
;Returns Carry clear if successful, set if fails)

LC23792:  PHX
LC23793:  LDA $3B18,Y    ;Target's Level
LC23796:  BCC LC2379F    ;if sketch/control chance isn't boosted by equip, branch
LC23798:  XBA
LC23799:  LDA #$AA
LC2379B:  JSR $4781      ;Multiply target level by #$AA
LC2379E:  XBA            ;Multiply target level by 170 / 256
LC2379F:  PHA            ;save target level (or target level * 170/256)
LC237A0:  TDC
LC237A1:  LDA $3B18,X    ;Attacker's Level
LC237A4:  XBA            ;* 256
LC237A5:  PLX            ;restore target level (or target level * 170/256)
LC237A6:  JSR $4792      ;A / X
LC237A9:  PHA            ;Put on stack
LC237AA:  CLC
LC237AB:  XBA
LC237AC:  BNE LC237B3    ;Automatically hit if result of division is >= 256
LC237AE:  JSR $4B5A      ;random #: 0 to 255
LC237B1:  CMP $01,S      ;compare to result of division
LC237B3:  PLA
LC237B4:  PLX
LC237B5:  RTS


;Reduce gold for GP Rain or Enemy Steal
;Gold = Gold - A (no lower than 0)
;For GP Rain: A = Level * 30 (Gold if gold < level * 30)
;For Enemy Steal: High A = Enemy level, low A = 20 (14 hex) (Enemy level * 256 + 20)
;                 (Gold if gold < (Enemy level * 256) + 20)

LC237B6:  PHA            ;Put on stack
LC237B7:  SEC
LC237B8:  LDA $1860      ;party's gold, bottom 16 bits
LC237BB:  STA $EE
LC237BD:  SBC $01,S
LC237BF:  STA $1860      ;subtract A from gold
LC237C2:  SEP #$20       ;8-bit mem/acc
LC237C4:  LDA $1862      ;party's gold, top 8 bits
LC237C7:  SBC #$00
LC237C9:  STA $1862      ;now continue subtraction with borrow
LC237CC:  REP #$20       ;16-bit mem/acc
LC237CE:  BCS LC237DA    ;branch if party's gold was >= amount thrown or stolen
LC237D0:  LDA $EE
LC237D2:  STA $01,S      ;otherwise, lower amount thrown/stolen to what the
                         ;party's gold was
LC237D4:  STZ $1860
LC237D7:  STZ $1861      ;zero the party's gold, all 3 bytes
LC237DA:  PLA
LC237DB:  RTS


;Pick a random Esper (not Odin or Raiden

LC237DC:  LDA #$19
LC237DE:  JSR $4B65      ;random: 0 to #$18
LC237E1:  CMP #$0B
LC237E3:  BCC LC237E7    ;Branch if A < #$0B
LC237E5:  INC            ;Add 2 if over #$0B
LC237E6:  INC
LC237E7:  CLC
LC237E8:  ADC #$36
LC237EA:  RTS


;Set up weapon addition magic, Tempest's Wind Slash, and Espers summoned
; by the Magicite item)

LC237EB:  LDA $3400
LC237EE:  CMP #$FF
LC237F0:  BEQ LC23837    ;Exit if null "spell # of second attack"
LC237F2:  STA $B6        ;Set spell #
LC237F4:  JSR $1DBF      ;Get command based on attack/spell number.
                         ;A bottom = Command #, A top = Attack #
LC237F7:  STA $B5        ;Set command to that type
LC237F9:  JSR $26D3      ;Load data for command and attack/sub-command, held
                         ;in A.bottom and A.top
LC237FC:  JSR $2951      ;Load Magic Power / Vigor and Level
LC237FF:  STZ $11A5      ;Set MP cost to 0
LC23802:  LDA #$FF
LC23804:  STA $3400      ;null out the "spell # for a second attack", as
                         ;we've already processed it.
LC23807:  LDA #$02
LC23809:  TSB $B2        ;Set no critical & ignore True Knight
LC2380B:  LDA #$10
LC2380D:  BIT $B2
LC2380F:  BEQ LC23814    ;branch if it's weapon addition magic, which won't
                         ;let the followup spell hit anybody but the initial
                         ;weapon victim.  why the hell doesn't this just
                         ;branch directly to $3816?
LC23811:  STZ $3415      ;will force randomization and skip backing up of
                         ;targets
LC23814:  BNE LC2382D    ;and if one changes the above branch, this could
                         ;simply be an unconditional BRA.
                         ;i'm tempted to make a Readability patch just
                         ;combining these two trivial changes..

;To be clear: Traditional weapon "addition magic" will start its journey at C2/3816.
; As far as I know, anything else will take the C2/382D path.  That includes Espers
; summoned by the Magicite item and Tempest's Wind Slash [which is technically
; addition magic, but a special case].)

LC23816:  LDA #$0C
LC23818:  TRB $11A3      ;Clear learn if cast, clear enable Runic
LC2381B:  TSB $BA        ;Set Don't retarget if target invalid, and
                         ;Can target dead/hidden targets
LC2381D:  LDA #$40
LC2381F:  STA $BB        ;Set only to cursor start on enemy [and clear any
                         ;multi-targeting ability].
LC23821:  LDA #$10
LC23823:  BIT $11A4
LC23826:  BEQ LC2382D    ;Branch if Stamina can't block
LC23828:  STZ $341C      ;this makes a weapon spell -- like Soul Sabre's
                         ;Doom -- have its animation skipped entirely when
                         ;missing rather than show a "Miss" message
LC2382B:  BRA LC23832
LC2382D:  LDA #$20
LC2382F:  TSB $11A4      ;Set Unblockable
LC23832:  LDA #$02
LC23834:  TSB $11A3      ;Set Not Reflectable
LC23837:  RTS


;Set attacker to die if under Air Anchor effect

LC23838:  LDA $3205,X
LC2383B:  BIT #$04
LC2383D:  BNE LC23849    ;Exit function if not under Air Anchor effect
LC2383F:  ORA #$04
LC23841:  STA $3205,X    ;Clear Air Anchor effect
LC23844:  LDA #$40
LC23846:  TSB $11A3      ;Set caster dies
LC23849:  RTS


;Mark Hide and Death statuses to be set on entity X, and mark entity X
; as last attacker of entity Y if Y doesn't have one this turn.)

LC2384A:  LDA $3DE9,X
LC2384D:  ORA #$20
LC2384F:  STA $3DE9,X    ;Mark Hide status to be set
LC23852:  JSR $362F      ;Mark entity X as the last attacker of entity Y,
                         ;unless Y already has an attacker this turn.
                         ;Arbitrarily set/clear flag indicating whether
                         ;entity Y was attacked this turn.
LC23855:  LDA #$80
LC23857:  ORA $3DD4,X
LC2385A:  STA $3DD4,X    ;Mark Death status to be set
LC2385D:  RTS


;Sets level and magic power for attack to 0

LC2385E:  STZ $11AF
LC23861:  STZ $11AE
LC23864:  RTS


;If Bit 7 of $3415 is set, copy targets to backup targets [used by
; next strike on turn, as well as Mimic].  Also, add targets to list
; of "already hit targets" that multi-strike attacks [like Offering,
; Quadra Slam] will use if no living targets are found.
; If Bit 7 of $3415 is clear, copy backup targets into targets.)

LC23865:  PHP
LC23866:  REP #$20
LC23868:  LDA $3414      ;aka $3415
LC2386B:  BMI LC23874    ;branch if Bit 7 is set -- iow, variable has its
                         ;default value of FFh
LC2386D:  LDA $3A30      ;get backup targets
LC23870:  STA $B8        ;copy to current targets, for use by next strike
                         ;i think that doing this from C2/32AE is too early
                         ;to adequately preserve $B8, as some special
                         ;effects can change it [and none read from it
                         ;before doing so, afaik], and that this is
                         ;obsoleted by C2/3243.
LC23872:  BRA LC2387C
LC23874:  LDA $B8        ;get current targets
LC23876:  STA $3A30      ;save to backup targets [also used by C2/021E for
                         ;Mimic]
LC23879:  TSB $3A4E      ;add to list of already hit targets, used if we
                         ;run out of living targets later in turn
LC2387C:  PLP
LC2387D:  RTS


;Calls once-per-target special effect code

LC2387E:  PHX
LC2387F:  PHY
LC23880:  PHP
LC23881:  SEP #$30
LC23883:  LDX $11A9
LC23886:  JSR ($3DCD,X)
LC23889:  PLP
LC2388A:  PLY
LC2388B:  PLX
LC2388C:  RTS


;Kill effect

; Slice/Scimitar special effect starts here
LC2388D:  SEC
LC2388E:  LDA #$EE
LC23890:  XBA            ;Call from Kill with "X" effect enters here,
                         ;with A = #$7E
LC23891:  LDA $3AA1,Y
LC23894:  BIT #$04
LC23896:  BNE LC2388C    ;Exit function if protected from instant death
LC23898:  BCS LC2389F    ;if Slice/Scimitar, skip code to make auto hit undead
LC2389A:  LDA $3C95,Y
LC2389D:  BMI LC238AB    ;If Undead, don't skip activation for random or Stamina
                         ;reasons
LC2389F:  JSR $4B5A      ;Random number 0 to 255
LC238A2:  CMP #$40
LC238A4:  BCS LC2388C    ;Exit 75% chance
LC238A6:  JSR $23B2      ;Check if Stamina blocks
LC238A9:  BCS LC2388C    ;Exit if it does
LC238AB:  LDA $3A70      ;number of strikes remaining from Offering /
                         ;Dragon Horn / etc
LC238AE:  BEQ LC238B6    ;if this is final strike, branch
LC238B0:  LDA $B5
LC238B2:  CMP #$16
LC238B4:  BEQ LC2388C    ;Exit if Command = Jump
                         ;The last 5 instructions were added to FF3us, to avoid
                         ;a couple of bugs.
LC238B6:  LDA $3018,Y
LC238B9:  TSB $A4        ;the caller has temporarily cleared this bit in $A4,
                         ;and will set it after return.  but we need it set now,
                         ;for our animation buffer update at C2/38EF.
LC238BB:  TRB $3A4E      ;Remove this [character] target from a "backup
                         ;already-hit targets" byte, which stops Offering/
                         ;Genji Glove/etc from beating on their corpse.
LC238BE:  LDA $3019,Y
LC238C1:  TSB $A5        ;see note at C2/38B9.
LC238C3:  TRB $3A4F      ;Remove this [monster] target from a "backup already-hit
                         ;targets byte", stopping aforementioned corpse-beating.
LC238C6:  LDA #$10
LC238C8:  TSB $A0        ;i think this is being done to stop the insta-kill Magic
                         ;animations from putting a casting circle around the
                         ;attacker [and we're doing it with $A0 rather than usual
                         ;$B0 method, because C2/57C2 has already been called].
                         ;however, neither the dice-up nor the X-kill animations
                         ;seem to need this precaution.  so who knows.
LC238CA:  LDA #$80
LC238CC:  JSR $0E32      ;Set Death in Status to Set
LC238CF:  STZ $341D      ;this will make C2/33B1 null the animation for each
                         ;strike in the remainder of this turn where no targets
                         ;are found.  this is part of the "corpse beating"
                         ;prevention described above.  without this instruction,
                         ;the character will wave their hand around like an
                         ;idiot.

LC238D2:  STZ $11A6      ;set Battle Power to 0
LC238D5:  LDA #$02
LC238D7:  STA $B5        ;save Magic as command for animation purposes
LC238D9:  XBA
LC238DA:  STA $B6        ;save attack ID for animation purposes: EEh for
                         ;Slice/Scimitar, or 7Eh for Kill with 'X'
LC238DC:  CMP #$EE
LC238DE:  BNE LC238EC    ;Kill with 'X' branches
LC238E0:  CPY #$08       ;Check for monster or character
LC238E2:  BCC LC238EC    ;branch if character target
LC238E4:  LDA $3DE9,Y
LC238E7:  ORA #$20
LC238E9:  STA $3DE9,Y    ;Set Hide in Status to Set
LC238EC:  JSR $35AD      ;Write data in $B4 - $B7 to current slot in ($76
                         ;animation buffer, and point $3A71 to this slot
                         ;this matches up with the ($78 update that will be
                         ;done at C2/3480.
LC238EF:  JMP $63DB      ;Copy $An variables to ($78) buffer
                         ;this matches up with the ($76 update that was done
                         ;at C2/3414.


;Special Effect 4
;x2 Damage vs. Humans

LC238F2:  LDA $3C95,Y
LC238F5:  BIT #$10
LC238F7:  BEQ LC238FD    ;Exit if target not human
LC238F9:  INC $BC
LC238FB:  INC $BC        ;Double damage dealt
LC238FD:  RTS


;Sniper/Hawk Eye effect

LC238FE:  JSR $4B53      ;random: 0 or 1 in Carry flag
LC23901:  BCC LC238FD    ;50% chance exit
LC23903:  INC $BC        ;Add 1 to damage incrementor
LC23905:  LDA $3EF9,Y
LC23908:  BPL LC238FD    ;Exit if not target not Floating
LC2390A:  LDA $B5
LC2390C:  CMP #$00
LC2390E:  BNE LC238FD    ;Exit if command not Fight?
LC23910:  INC $BC
LC23912:  INC $BC
LC23914:  INC $BC        ;Add another 3 to damage incrementor
LC23916:  LDA #$08
LC23918:  STA $B5        ;Store Throw for *purposes of animation*
LC2391A:  LDA $B7        ;get graphic index
LC2391C:  DEC
LC2391D:  STA $B6        ;undo earlier adjustment, save as Throw parameter
LC2391F:  JMP $35BB      ;Update a previous entry in ($76 animation buffer
                         ;with data in $B4 - $B7


;Stone

LC23922:  LDA $05,S
LC23924:  TAX
LC23925:  LDA $3B18,X    ;Attacker's level
LC23928:  CMP $3B18,Y    ;Target's Level
LC2392B:  BNE LC23933    ;If not same level, exit
LC2392D:  LDA #$0D       ;Add 14 to damage incrementer, as Carry is set
LC2392F:  ADC $BC
LC23931:  STA $BC
LC23933:  RTS


;Palidor

LC23934:  LDA #$01
LC23936:  JSR $464C      ;sets bit 0 in $3204,Y .  indicates entity is
                         ;target/passenger of a Palidor summon this turn.
LC23939:  LDA $32CC,Y    ;get entry point to entity's conventional linked
                         ;list queue
LC2393C:  PHA            ;Put on stack
LC2393D:  JSR $4E54      ;Add a record [by initializing its pointer/ID field]
                         ;to a "master list" in $3184, a collection of
                         ;linked list queues
LC23940:  STA $32CC,Y    ;have entity's entry point index new addition
LC23943:  TAY            ;Y = index for 8-bit record fields
LC23944:  ASL
LC23945:  TAX            ;X will index 16-bit fields of the record
LC23946:  PLA
LC23947:  CMP #$FF       ;was there previously an entry point to this
                         ;entity's queue?
LC23949:  BEQ LC2394E    ;branch if not
LC2394B:  STA $3184,Y    ;if so, have their new record link to the one(s
                         ;that was/were previously there.
                         ;so what we've done is make it so any previously
                         ;queued command(s for this character will be
                         ;executed after landing from Palidor
LC2394E:  TDC
LC2394F:  STA $3620,X    ;new record in conventional linked list queue will
                         ;have 0 MP cost...
LC23952:  REP #$20
LC23954:  STA $3520,X    ;...and no initial targets
LC23957:  LDA #$0016
LC2395A:  STA $3420,X    ;...and Jump as command [and no sub-command, as
                         ;none is needed]
LC2395D:  RTS


;Special effect $39 - Engulf

LC2395E:  LDA $3018,Y
LC23961:  TSB $3A8A      ;Set character as engulfed
LC23964:  BRA LC2396C    ;Branch to remove from combat code


;Bababreath from 3DCD

LC23966:  LDA $3018,Y
LC23969:  TSB $3A88      ;flag to remove target from party at end of battle
LC2396C:  REP #$20       ;Special effect $27 & $38 & $4B jump here
                         ;Escape, Sneeze, Smoke Bomb
LC2396E:  LDA $3018,Y
LC23971:  TSB $2F4C      ;mark target to be removed from the battlefield
LC23974:  TSB $3A39      ;add to list of escaped characters
LC23977:  RTS


;Dischord

LC23978:  TYX
LC23979:  INC $3B18,X    ;Level
LC2397C:  LSR $3B18,X    ;Half level rounded up
LC2397F:  RTS


;R. Polarity

LC23980:  LDA $3AA1,Y    ;Target's Row
LC23983:  EOR #$20
LC23985:  STA $3AA1,Y    ;Switch
LC23988:  RTS


;Wall Change

LC23989:  TDC
LC2398A:  LDA #$FF
LC2398C:  JSR $522A      ;Pick a random bit
LC2398F:  STA $3BE0,Y    ;Set your weakness to A
LC23992:  EOR #$FF
LC23994:  STA $3BCD,Y    ;Nullify all other elements
LC23997:  JSR $522A      ;Pick a random bit, not the one picked for weakness
LC2399A:  STA $3BCC,Y    ;Absorb that element
LC2399D:  RTS


;Steal function

LC2399E:  LDA $05,S      ;Attacker
LC239A0:  TAX
LC239A1:  LDA #$01
LC239A3:  STA $3401      ;=1) (Sets message to "Doesn't have anything!"
LC239A6:  CPX #$08       ;Check if attacker is monster
LC239A8:  BCS LC23A09    ;Branch if monster
LC239AA:  REP #$20       ;Set 16-bit accumulator
LC239AC:  LDA $3308,Y    ;Target's stolen items
LC239AF:  INC
LC239B0:  SEP #$21       ;Set 8-bit Accumulator AND Carry Flag
LC239B2:  BEQ LC23A01    ;Fail to steal if no items
LC239B4:  INC $3401      ;now = 2) (Sets message to "Couldn't steal!!"
LC239B7:  LDA $3B18,X    ;Attacker's Level
LC239BA:  ADC #$32       ;adding 51, since Carry Flag was set
LC239BC:  BCS LC239D8    ;Automatically steal if level >= 205
LC239BE:  SBC $3B18,Y    ;Subtract Target's Level, along with an extra 1 because
                         ;Carry Flag is unset at this point.  Don't worry; this
                         ;cancels out with the extra 1 from C2/39BA.
                         ;StealValue = [attacker level + 51] - [target lvl + 1]
                         ;= Attacker level + 50 - Target level
LC239C1:  BCC LC23A01    ;Fail to steal if StealValue < 0
LC239C3:  BMI LC239D8    ;Automatically steal if StealValue >= 128
LC239C5:  STA $EE        ;save StealValue
LC239C7:  LDA $3C45,X
LC239CA:  LSR
LC239CB:  BCC LC239CF    ;Branch if no sneak ring
LC239CD:  ASL $EE        ;Double value
LC239CF:  LDA #$64
LC239D1:  JSR $4B65      ;Random: 0 to 99
LC239D4:  CMP $EE
LC239D6:  BCS LC23A01    ;Fail to steal if the random number >= StealValue
LC239D8:  PHY
LC239D9:  JSR $4B5A      ;Random: 0 to 255
LC239DC:  CMP #$20
LC239DE:  BCC LC239E1    ;branch 1/8 of the time, so Rare steal slot
                         ;will be checked
LC239E0:  INY            ;Check the 2nd [Common] slot 7/8 of the time
LC239E1:  LDA $3308,Y    ;Target's stolen item
LC239E4:  PLY
LC239E5:  CMP #$FF       ;If no item
LC239E7:  BEQ LC23A01    ;Fail to steal
LC239E9:  STA $2F35      ;save Item stolen for message purposes in
                         ;parameter 1, bottom byte
LC239EC:  STA $32F4,X    ;Store in "Acquired item"
LC239EF:  LDA $3018,X
LC239F2:  TSB $3A8C      ;flag character to have any applicable item in
                         ;$32F4,X added to inventory when turn is over.
LC239F5:  LDA #$FF
LC239F7:  STA $3308,Y    ;Set to no item to steal
LC239FA:  STA $3309,Y    ;in both slots
LC239FD:  INC $3401      ;now = 3) (Sets message to "Stole #whatever "
LC23A00:  RTS


;If no items to steal

LC23A01:  SEP #$20
LC23A03:  LDA #$00
LC23A05:  STA $3D48,Y    ;save Fight as command for counterattack purposes
LC23A08:  RTS


;Steal for monsters

LC23A09:  STZ $2F3A      ;clear message parameter 2, third byte
LC23A0C:  INC $3401      ;Sets message to "Couldn't steal!!"
LC23A0F:  JSR $4B5A      ;random #: 0 to 255
LC23A12:  CMP #$C0
LC23A14:  BCS LC23A01    ;fail to steal 1/4 of the time
LC23A16:  DEC $3401      ;Sets message to "Doesn't have anything!"
LC23A19:  LDA $3B18,X    ;enemy level
LC23A1C:  XBA
LC23A1D:  LDA #$14       ;enemy will swipe: level * 256 + 20 gold
LC23A1F:  REP #$20       ;set 16-bit A
LC23A21:  JSR $37B6      ;subtract swiped gold from party's inventory
LC23A24:  BEQ LC23A01    ;branch if party had zero gold before
                         ;the steal
LC23A26:  STA $2F38      ;save gold swiped for message output in
                         ;parameter 2, bottom word
LC23A29:  CLC
LC23A2A:  ADC $3D98,X    ;add amount stolen to gold possessed by enemy
LC23A2D:  BCC LC23A31    ;branch if no overflow
LC23A2F:  TDC
LC23A30:  DEC            ;if sum overflowed, set enemy's gold to 65535
LC23A31:  STA $3D98,X    ;update enemy's gold
LC23A34:  SEP #$20       ;set 8-bit A
LC23A36:  LDA #$3F
LC23A38:  STA $3401      ;Set message to "# GP was stolen!!"
LC23A3B:  RTS


;Metamorph

LC23A3C:  CPY #$08       ;Checks if target is monster
LC23A3E:  BCC LC23A8A    ;branch if not
LC23A40:  LDA $3C94,Y    ;Metamorph info: Morph chance in bits 5-7,
                         ;and Morph pack in bits 0-4
LC23A43:  PHA            ;Put on stack
LC23A44:  AND #$1F       ;isolate pack #
LC23A46:  JSR $4B53      ;Random number 0 or 1
LC23A49:  ROL
LC23A4A:  JSR $4B53      ;Random number 0 or 1
LC23A4D:  ROL
LC23A4E:  TAX            ;now we have the Metamorph pack # in bits 2-6,
                         ;and a random 0-3 index into that pack in bits 0-1
LC23A4F:  LDA $C47F40,X  ;get the item we're attempting to Metamorph
                         ;the enemy into
LC23A53:  STA $2F35      ;save it in message parameter 1, bottom byte
LC23A56:  LDA #$02
LC23A58:  STA $3A28      ;temporary byte 1 for ($76) animation buffer
LC23A5B:  LDA #$1D
LC23A5D:  STA $3A29      ;temporary byte 2 for ($76) animation buffer
LC23A60:  JSR $35BE      ;Update a previous entry in ($76 animation buffer
                         ;with data in $3A28 - $3A2B
LC23A63:  JSR $35AD      ;Write data in $B4 - $B7 to current slot in ($76
                         ;animation buffer, and point $3A71 to this slot
LC23A66:  PLA
LC23A67:  LSR
LC23A68:  LSR
LC23A69:  LSR
LC23A6A:  LSR
LC23A6B:  LSR            ;isolate 0-7 Metamorph Chance index
LC23A6C:  TAX            ;copy it to X
LC23A6D:  JSR $4B5A      ;Random number 0 to 255
LC23A70:  CMP $C23DC5,X  ;compare to actual Metamorph Chance
LC23A74:  BCS LC23A8A    ;if greater than or equal, branch and fail to
                         ;Metamorph
LC23A76:  LDA $05,S
LC23A78:  TAX
LC23A79:  LDA $2F35      ;get ID of Metamorphed item
LC23A7C:  STA $32F4,X    ;save it in this character's
                         ;"Item to add to inventory" variable
LC23A7F:  LDA $3018,X
LC23A82:  TSB $3A8C      ;flag this character to have their inventory
                         ;variable checked when the turn ends
LC23A85:  LDA #$80
LC23A87:  JMP $0E32      ;Mark death status to be set
LC23A8A:  JMP $3B1B      ;flag Miss message


;Special Efect $56
;Debilitator

LC23A8D:  TDC
LC23A8E:  LDA $3BE0,Y    ;Elements weak against
LC23A91:  ORA $3EC8      ;Elements nullified by ForceField
LC23A94:  EOR #$FF       ;Get elements in neither category
LC23A96:  BEQ LC23A8A    ;Miss if there aren't any
LC23A98:  JSR $522A      ;Randomly pick one such element
LC23A9B:  PHA            ;Put on stack
LC23A9C:  JSR $51F0      ;X = Get which bit is picked
LC23A9F:  TXA
LC23AA0:  CLC
LC23AA1:  ADC #$0B
LC23AA3:  STA $3401      ;Set to display that element as text
LC23AA6:  LDA $01,S
LC23AA8:  ORA $3BE0,Y
LC23AAB:  STA $3BE0,Y    ;Make weak vs. that element
LC23AAE:  PLA
LC23AAF:  EOR #$FF
LC23AB1:  PHA            ;Put on stack
LC23AB2:  AND $3BE1,Y
LC23AB5:  STA $3BE1,Y    ;Make not resist that element
LC23AB8:  LDA $01,S
LC23ABA:  XBA
LC23ABB:  PLA
LC23ABC:  REP #$20       ;Set 16-bit accumulator
LC23ABE:  AND $3BCC,Y
LC23AC1:  STA $3BCC,Y    ;Make not absorb or nullify that element
LC23AC4:  RTS


;Special effect $53
;Control

LC23AC5:  CPY #$08
LC23AC7:  BCC LC23B16    ;Miss with text if target is character
LC23AC9:  LDA $3C80,Y
LC23ACC:  BMI LC23B16    ;Miss with text if target has Can't Control bit set
LC23ACE:  PEA $B0D2      ;Death, Petrify, Clear, Zombie, Sleep, Muddled, Berserk
LC23AD1:  PEA $2900      ;Rage, Morph, Hide
LC23AD4:  JSR $5864
LC23AD7:  BCC LC23B16    ;Miss w/ text if any set on target
LC23AD9:  LDA $32B9,Y
LC23ADC:  BPL LC23B16    ;If already controlled, then miss w/text
LC23ADE:  LDA $05,S
LC23AE0:  TAX
LC23AE1:  LDA $3C45,X    ;Coronet "boost Control chance" in Bit 3
LC23AE4:  LSR
LC23AE5:  LSR
LC23AE6:  LSR
LC23AE7:  LSR
LC23AE8:  JSR $3792      ;Sketch/Control Chance - pass bit 3 of $3C45 as carry
LC23AEB:  BCS LC23B1B    ;Miss w/o text
LC23AED:  TYA
LC23AEE:  STA $32B8,X    ;save who attacker is Controlling
LC23AF1:  TXA
LC23AF2:  STA $32B9,Y    ;save who target is Controlled by
LC23AF5:  LDA $3019,Y
LC23AF8:  TSB $2F54      ;cause Controllee to be visually flipped
LC23AFB:  LDA $3E4D,X
LC23AFE:  ORA #$01
LC23B00:  STA $3E4D,X    ;set a custom bit on attacker.  was added on FF3us,
                         ;because Ripplering off "spell chant" status would
                         ;cause a freezing bug on FF6j.  sadly, FF6 Advance
                         ;didn't keep this addition.
LC23B03:  LDA $3EF9,X
LC23B06:  ORA #$10
LC23B08:  STA $3EF9,X    ;Set Spell Chant status to attacker
LC23B0B:  LDA $3AA1,Y
LC23B0E:  ORA #$40
LC23B10:  STA $3AA1,Y    ;flag target's ATB gauge to be reset?
LC23B13:  JMP $372F      ;generate the Control menu


LC23B16:  LDA #$04
LC23B18:  STA $3401      ;Set to display text #4
LC23B1B:  REP #$20       ;Set 16-bit Accumulator
LC23B1D:  LDA $3018,Y    ;Represents the target
LC23B20:  STA $3A48      ;Indicate a miss, due to the attack not changing any
                         ;statuses or due to checks in its special effect
LC23B23:  TSB $3A5A      ;Set target as Missed
LC23B26:  TRB $A4        ;Remove this target from hit targets
LC23B28:  RTS


;Sketch

LC23B29:  CPY #$08
LC23B2B:  BCC LC23B1B    ;Miss if aimed at party
LC23B2D:  LDA $3C80,Y
LC23B30:  BIT #$20
LC23B32:  BNE LC23B64    ;Branch if target has Can't Sketch
LC23B34:  LDA $05,S
LC23B36:  TAX
LC23B37:  LDA $3C45,X    ;Beret "boost Sketch chance" in Bit 2
LC23B3A:  LSR
LC23B3B:  LSR
LC23B3C:  LSR
LC23B3D:  JSR $3792      ;Sketch/Control chance - pass bit 2 of $3C45 as carry
LC23B40:  BCS LC23B1B    ;branch if sketch missed
LC23B42:  STY $3417      ;save Target as Sketchee
LC23B45:  TYA
LC23B46:  SBC #$07       ;subtract 8, as Carry is clear
LC23B48:  LSR
LC23B49:  STA $B7        ;save 0-5 index of our Sketched monster
LC23B4B:  JSR $35BB      ;Update a previous entry in ($76 animation buffer
                         ;with data in $B4 - $B7
LC23B4E:  JSR $4B5A      ;random: 0 to 255
LC23B51:  CMP #$40       ;75% chance for second sketch attack
LC23B53:  REP #$30       ;Set 16-bit Accumulator and Index registers
LC23B55:  LDA $1FF9,Y    ;get monster #
LC23B58:  ROL
LC23B59:  TAX
LC23B5A:  LDA $CF4300,X
LC23B5E:  SEP #$30       ;Set 8-bit A, X, & Y
LC23B60:  STA $3400      ;Set attack to sketched attack
LC23B63:  RTS


LC23B64:  LDA #$1F
LC23B66:  STA $3401      ;Store can't sketch message
LC23B69:  BRA LC23B1B    ;Make attack miss
                         ;BRA LC23B18?


;Special Effect $25 (Quake

LC23B6B:  LDA $3EF9,Y
LC23B6E:  BMI LC23B1B    ;If Float status set, miss
LC23B70:  RTS


;Leap

LC23B71:  LDA $2F49
LC23B74:  BIT #$08       ;extra enemy formation data: is "Can't Leap" set?
LC23B76:  BNE LC23B90    ;if so, miss with text
LC23B78:  LDA $3A76      ;Number of present and living characters in party
LC23B7B:  CMP #$02
LC23B7D:  BCC LC23B90    ;if less than 2, then miss w/ text
LC23B7F:  LDA $05,S
LC23B81:  TAX
LC23B82:  LDA $3DE9,X
LC23B85:  ORA #$20
LC23B87:  STA $3DE9,X    ;Mark Hide status to be set in attacker
LC23B8A:  LDA #$04
LC23B8C:  STA $3A6E      ;"End of combat" method #4, Gau leaping
LC23B8F:  RTS


LC23B90:  LDA #$05
LC23B92:  STA $3401      ;Set to display text #5
LC23B95:  JMP $3B1B      ;Miss target
                         ;JMP $3B18?


;Special Effect $50 (Possess

LC23B98:  LDA $05,S
LC23B9A:  TAX
LC23B9B:  LDA $3018,X
LC23B9E:  TSB $2F4C      ;mark Possessor to be removed from battlefield
                         ;what about the Possessee?
LC23BA1:  TSB $3A88      ;flag to remove Possessor from party at end of
                         ;battle
LC23BA4:  JSR $384A      ;Mark Hide and Death statuses to be set on attacker in
                         ;X, and mark entity X as last attacker of target in Y
                         ;if Y doesn't have one this turn.
LC23BA7:  PHX
LC23BA8:  TYX
LC23BA9:  JSR $384A      ;Mark Hide and Death statuses to be set on target in X
LC23BAC:  PLY            ;X now holds Possessee, and Y holds Possessor
LC23BAD:  JMP $361B      ;Mark entity X as the last attacker of entity Y, but
                         ;50% chance not if Y already has an attacker this turn


;Mind Blast

LC23BB0:  REP #$20       ;Set 16-bit Accumulator
LC23BB2:  JSR $44FF      ;Clear Status to Set and Status to Clear bytes
LC23BB5:  LDA $3018,Y    ;an original target, might also be in custom list
LC23BB8:  LDX #$06
LC23BBA:  BIT $3A5C,X    ;is the target in this slot of "Mind Blast victims"
                         ;list?  [this list was created previously in the
                         ;other Mind Blast special effect function.]
LC23BBD:  BEQ LC23BC6    ;branch and check next slot if not
LC23BBF:  PHA            ;Put on stack
LC23BC0:  PHX
LC23BC1:  JSR $3BD0      ;Randomly mark a status from attack data to be set
LC23BC4:  PLX
LC23BC5:  PLA
LC23BC6:  DEX
LC23BC7:  DEX
LC23BC8:  BPL LC23BBA    ;Do for all 4 list entries.  an entity who's listed
                         ;N times can get N statuses from this spell.
LC23BCA:  RTS


;Evil Toot
;Sets a random status from attack data)

LC23BCB:  REP #$20       ;Set 16-bit Accumulator
LC23BCD:  JSR $44FF      ;Clear Status to Set and Status to Clear bytes
LC23BD0:  LDA $11AA
LC23BD3:  JSR $520E      ;X = Number of statuses set by attack in bytes 1 & 2
LC23BD6:  STX $EE
LC23BD8:  LDA $11AC
LC23BDB:  JSR $520E      ;X = Number of statuses set by attack in bytes 3 & 4
LC23BDE:  SEP #$20       ;Set 8-bit Accumulator
LC23BE0:  TXA
LC23BE1:  CLC
LC23BE2:  ADC $EE        ;A = # of total statuses flagged in attack data
LC23BE4:  JSR $4B65      ;random number: 0 to A - 1
LC23BE7:  CMP $EE        ;Clear Carry if the random status we want to
                         ;set is in spell status byte 1 or 2
                         ;Set Carry if it's in byte 3 or 4.
LC23BE9:  REP #$20       ;Set 16-bit Accumulator
LC23BEB:  PHP
LC23BEC:  LDA $11AA
LC23BEF:  BCC LC23BF4    ;branch if we're attempting to set a status
                         ;from status byte 1 or 2
LC23BF1:  LDA $11AC      ;otherwise, it's from byte 3 or 4
LC23BF4:  JSR $522A      ;randomly pick a bit set in A
LC23BF7:  PLP
LC23BF8:  BCS LC23BFD
LC23BFA:  JMP $0E32      ;Set status picked bytes 1 or 2
LC23BFD:  ORA $3DE8,Y    ;Set status picked bytes 3 or 4
LC23C00:  STA $3DE8,Y
LC23C03:  RTS


;Rippler Effect

LC23C04:  LDA $05,S
LC23C06:  TAX
LC23C07:  REP #$20       ;Set 16-bit Accumulator
LC23C09:  LDA $3EE4,X    ;status bytes 1-2, caster
LC23C0C:  AND $3EE4,Y    ;status bytes 1-2, target
LC23C0F:  EOR #$FFFF
LC23C12:  STA $EE        ;save the statuses that aren't shared among caster
                         ;and target.  iow, turn on any bits that aren't
                         ;set in both.
LC23C14:  LDA $3EE4,X
LC23C17:  AND $EE        ;get statuses exclusive to caster
LC23C19:  STA $3DD4,Y    ;target status to set = statuses that were only set
                         ;in caster
LC23C1C:  STA $3DFC,X    ;caster status to clear = statuses that were only set
                         ;in caster
LC23C1F:  LDA $3EE4,Y
LC23C22:  AND $EE        ;get statuses exclusive to target
LC23C24:  STA $3DD4,X    ;caster status to set = statuses that were only set
                         ;in target
LC23C27:  STA $3DFC,Y    ;target status to clear = statuses that were only set
                         ;in target

LC23C2A:  LDA $3EF8,X    ;status bytes 3-4, caster
LC23C2D:  AND $3EF8,Y    ;status bytes 3-4, target
LC23C30:  EOR #$FFFF
LC23C33:  STA $EE        ;save the statuses that aren't shared among caster
                         ;and target.  iow, turn on any bits that aren't
                         ;set in both.
LC23C35:  LDA $3EF8,X
LC23C38:  AND $EE        ;get statuses exclusive to caster
LC23C3A:  STA $3DE8,Y    ;target status to set = statuses that were only set
                         ;in caster
LC23C3D:  STA $3E10,X    ;caster status to clear = statuses that were only set
                         ;in caster
LC23C40:  LDA $3EF8,Y
LC23C43:  AND $EE        ;get statuses exclusive to target
LC23C45:  STA $3DE8,X    ;caster status to set = statuses that were only set
                         ;in target
LC23C48:  STA $3E10,Y    ;target status to clear = statuses that were only set
                         ;in target
LC23C4B:  RTS


;Exploder effect from 3DCD

LC23C4C:  LDA $05,S
LC23C4E:  TAX            ;X = attacker
LC23C4F:  STX $EE
LC23C51:  CPY $EE        ;is this target the attacker?
LC23C53:  BNE LC23C5A    ;branch if not
LC23C55:  LDA $3018,X
LC23C58:  TRB $A4        ;if so, and it's a character, clear it from hit targets.
                         ;seemingly undoing the addition to targets by the
                         ;earlier special effect function.  but the problem is,
;                                     LC23467 sets the bit in $A4 again shortly after this
                         ;function returns.
LC23C5A:  RTS


;Scan effect

LC23C5B:  LDA $3C80,Y
LC23C5E:  BIT #$10
LC23C60:  BNE LC23C68    ;Branch if target has Can't Scan
LC23C62:  TYX
LC23C63:  LDA #$27
LC23C65:  JMP $4E91      ;queue a custom command to display all the info, in
                         ;global Special Action queue


LC23C68:  LDA #$2C
LC23C6A:  STA $3401      ;Store "Can't Scan" message
LC23C6D:  RTS


;Suplex code from $3DCD

LC23C6E:  LDA $3C80,Y
LC23C71:  BIT #$04       ;Is Can't Suplex set in Misc/Special enemy byte?
LC23C73:  BEQ LC23C5A    ;If not, exit function
LC23C75:  JMP $3B1B      ;Makes miss


;Special Effect $57 - Air Anchor

LC23C78:  LDA $3AA1,Y
LC23C7B:  BIT #$04
LC23C7D:  BNE LC23C75    ;Miss if instant death protected
LC23C7F:  LDA #$13
LC23C81:  STA $3401      ;Display text $13 - "Move, and you're dust!"
LC23C84:  LDA $3205,Y
LC23C87:  AND #$FB
LC23C89:  STA $3205,Y    ;Set Air Anchor effect
LC23C8C:  STZ $341A      ;Special Effect $23 -- X-Zone, Odin, etc -- jumps here
LC23C8F:  RTS


;L? Pearl from 3DCD

LC23C90:  RTS


;Charm

LC23C91:  LDA $05,S
LC23C93:  TAX
LC23C94:  LDA $3394,X
LC23C97:  BPL LC23C75    ;Miss if attacker already charmed a target
LC23C99:  TYA
LC23C9A:  STA $3394,X    ;Attacker data: save which target they charmed
LC23C9D:  TXA
LC23C9E:  STA $3395,Y    ;Target data: save who has charmed them
LC23CA1:  RTS


;Tapir

LC23CA2:  LDA $3EE5,Y
LC23CA5:  BPL LC23C75    ;Miss if target is not asleep
LC23CA7:  REP #$20       ;Set 16-bit Accumulator
LC23CA9:  LDA $3C1C,Y
LC23CAC:  STA $3BF4,Y    ;Set HP to max HP
LC23CAF:  REP #$20       ;Pep Up and Elixir/Megalixir branch here
LC23CB1:  LDA $3C30,Y
LC23CB4:  STA $3C08,Y    ;Set MP to max MP
LC23CB7:  RTS


;Pep Up

LC23CB8:  LDA $05,S
LC23CBA:  TAX
LC23CBB:  JSR $384A      ;Mark Hide and Death statuses to be set on attacker
                         ;in X, and mark entity X as last attacker of entity Y
                         ;if Y doesn't have one this turn.
LC23CBE:  REP #$20       ;Set 16-bit Accumulator
LC23CC0:  LDA $3018,X
LC23CC3:  TSB $2F4C      ;mark caster to be removed from the battlefield
LC23CC6:  STZ $3BF4,X    ;Set caster HP to 0
LC23CC9:  STZ $3C08,X    ;Set caster MP to 0
LC23CCC:  BRA LC23CAF    ;Set target's MP to max MP


;Special Effect $2E - Seize

LC23CCE:  LDA $05,S
LC23CD0:  TAX
LC23CD1:  LDA $3358,X    ;whom attacker is Seizing
LC23CD4:  BPL LC23C75    ;if already Seizing someone, jump to $3B1B - Miss
LC23CD6:  CPY #$08
LC23CD8:  BCS LC23C75    ;If target is not character - Miss
LC23CDA:  TYA
LC23CDB:  STA $3358,X    ;save who attacker is Seizing
LC23CDE:  TXA
LC23CDF:  STA $3359,Y    ;save who target is Seized by
LC23CE2:  LDA $3DAC,X
LC23CE5:  ORA #$80
LC23CE7:  STA $3DAC,X    ;set Seizing in monster variable visible from
                         ;script
LC23CEA:  LDA $3018,Y
LC23CED:  TRB $3403      ;add target to list of Seized characters
LC23CF0:  LDA $3AA0,Y
LC23CF3:  AND #$7F       ;Clear bit 7
LC23CF5:  STA $3AA0,Y
LC23CF8:  LDA #$40
LC23CFA:  JMP $464C


;Discard

LC23CFD:  LDA $05,S
LC23CFF:  TAX
LC23D00:  LDA $3DAC,X
LC23D03:  AND #$7F
LC23D05:  STA $3DAC,X    ;clear Seizing in monster variable visible from
                         ;script
LC23D08:  LDA #$FF
LC23D0A:  STA $3358,X    ;attacker Seizing nobody
LC23D0D:  STA $3359,Y    ;target Seized by nobody
LC23D10:  LDA $3018,Y
LC23D13:  TSB $3403      ;remove target from list of Seized characters
LC23D16:  RTS


;Special effect $4C - Elixir and Megalixir.  In Item data, this appears as
; Special effect $04.)

LC23D17:  LDA #$80
LC23D19:  JSR $464C      ;Sets bit 7 in $3204,Y
LC23D1C:  BRA LC23CAF    ;Set MP to Max MP


;Overcast

LC23D1E:  LDA $3E4D,Y
LC23D21:  ORA #$02
LC23D23:  STA $3E4D,Y    ;Turn on Overcast bit, which will be checked by
                         ;function C2/450D to give a dying target Zombie
                         ;instead
LC23D26:  RTS


;Zinger

LC23D27:  LDA $05,S
LC23D29:  TAX
LC23D2A:  STX $33F8      ;save attacker as the Zingerer
LC23D2D:  STY $33F9      ;save target as who's being Zingered
LC23D30:  LDA $3019,X
LC23D33:  TSB $2F4D      ;mark attacker to be removed from the battlefield
LC23D36:  RTS


;Love Token

LC23D37:  LDA $05,S
LC23D39:  TAX
LC23D3A:  TYA
LC23D3B:  STA $336C,X    ;Attacker data: save which target takes damage
                         ;for them
LC23D3E:  TXA
LC23D3F:  STA $336D,Y    ;Target data: save who they're taking damage for
LC23D42:  RTS


;Kill with 'X' effect
;Auto hit undead, Restores undead)

LC23D43:  CLC
LC23D44:  LDA #$7E       ;tells function it's an x-kill weapon
LC23D46:  JSR $3890      ;call x-kill/dice-up function, decide whether to
                         ;activate instant kill
LC23D49:  LDA $3C95,Y    ;Doom effect jumps here
LC23D4C:  BPL LC23D62    ;Exit function if not undead
LC23D4E:  CPY #$08
LC23D50:  BCS LC23D63    ;Branch if not character
LC23D52:  LDA $3DD4,Y
LC23D55:  AND #$7F
LC23D57:  STA $3DD4,Y    ;Remove Death from Status to Set
LC23D5A:  REP #$20
LC23D5C:  LDA $3C1C,Y
LC23D5F:  STA $3BF4,Y    ;Fully heal HP
LC23D62:  RTS


LC23D63:  TDC            ;clear 16-bit A
LC23D64:  LDA $3DE9,Y
LC23D67:  ORA #$20
LC23D69:  STA $3DE9,Y    ;Add Hide to target's Status to Set
LC23D6C:  LDA $3019,Y    ;get unique bit identifying this monster
LC23D6F:  XBA
LC23D70:  REP #$20       ;Set 16-bit Accumulator
LC23D72:  STA $B8        ;save as target in $B9.  subcommand in $B8 is 0.
LC23D74:  LDX #$0A       ;animation type
LC23D76:  LDA #$0024     ;payload command of F5 monster script command.
                         ;so we're queuing Command F5 0A 00 here.
LC23D79:  JMP $4E91      ;queue it, in global Special Action queue


;Phantasm

LC23D7C:  LDA $3E4D,Y
LC23D7F:  ORA #$40
LC23D81:  STA $3E4D,Y    ;give Seizure-like quasi status to target
                         ;unnamed, but some call it HP Leak
LC23D84:  RTS


;Stunner
;Only a Hit Rate / 256 chance it will actually try to inflict
; statuses on the target)

LC23D85:  JSR $4B5A      ;random: 0 to 255
LC23D88:  CMP $11A8
LC23D8B:  BCC LC23DA7    ;If less than hit rate then exit
LC23D8D:  REP #$20       ;Set 16-bit Accumulator
LC23D8F:  LDA $11AA      ;Spell's Status to Set bytes 1+2
LC23D92:  EOR #$FFFF
LC23D95:  AND $3DD4,Y    ;Subtract it from target's
                         ;Status to Set bytes 1+2
LC23D98:  STA $3DD4,Y
LC23D9B:  LDA $11AC      ;Spell's Status to Set bytes 3+4
LC23D9E:  EOR #$FFFF
LC23DA1:  AND $3DE8,Y    ;Subtract it from target's
                         ;Status to Set bytes 3+4
LC23DA4:  STA $3DE8,Y
LC23DA7:  RTS


;Targeting

LC23DA8:  LDA $05,S
LC23DAA:  TAX
LC23DAB:  TYA
LC23DAC:  STA $32F5,X    ;Stores target
LC23DAF:  RTS


;Fallen One

LC23DB0:  REP #$20       ;Set 16-bit Accumulator
LC23DB2:  TDC            ;Clear Accumulator
LC23DB3:  INC
LC23DB4:  STA $3BF4,Y    ;Store 1 in HP
LC23DB7:  RTS


;Special effect $4A - Super Ball

LC23DB8:  JSR $4B5A      ;Random Number 0 to 255
LC23DBB:  AND #$07       ;Random Number 0 to 7
LC23DBD:  INC            ;1 to 8
LC23DBE:  STA $11B1      ;Set damage to 256 to 2048 in steps of 256
LC23DC1:  STZ $11B0
LC23DC4:  RTS


;Metamorph Chance

LC23DC5: db $FF
LC23DC6: db $C0
LC23DC7: db $80
LC23DC8: db $40
LC23DC9: db $20
LC23DCA: db $10
LC23DCB: db $08
LC23DCC: db $00


;Table for special effects code pointers 1 (once-per-target

LC23DCD: dw $388C
LC23DCF: dw $388C
LC23DD1: dw $388C
LC23DD3: dw $3D43 ;($03)
LC23DD5: dw $38F2 ;($04)
LC23DD7: dw $388C
LC23DD9: dw $388C
LC23DDB: dw $388C
LC23DDD: dw $38FE ;($08)
LC23DDF: dw $388C
LC23DE1: dw $388C
LC23DE3: dw $388C
LC23DE5: dw $388C
LC23DE7: dw $388D ;($0D)
LC23DE9: dw $388C
LC23DEB: dw $388C
LC23DED: dw $3C5B ;($10)
LC23DEF: dw $388C
LC23DF1: dw $3A3C ;($12)
LC23DF3: dw $3934 ;($13)
LC23DF5: dw $388C
LC23DF7: dw $388C
LC23DF9: dw $388C
LC23DFB: dw $3CA2 ;($17)
LC23DFD: dw $388C
LC23DFF: dw $3C4C ;($19)
LC23E01: dw $388C
LC23E03: dw $388C
LC23E05: dw $3C90 ;($1C)
LC23E08: dw $388C
LC23E09: dw $388C
LC23E0B: dw $3978 ;($1F)
LC23E0D: dw $3CB8 ;($20)
LC23E0F: dw $3C04 ;($21)
LC23E11: dw $3922 ;($22)
LC23E13: dw $3C8C ;($23)
LC23E15: dw $388C
LC23E17: dw $3B6B ;($25)
LC23E19: dw $3989 ;($26)
LC23E1B: dw $396C ;($27)
LC23E1D: dw $3BB0 ;($28)
LC23E1F: dw $388C
LC23E21: dw $388C
LC23E23: dw $3980 ;($2B)
LC23E25: dw $388C
LC23E27: dw $3D37 ;($2D)
LC23E29: dw $3CCE ;($2E)
LC23E2B: dw $3DA8 ;($2F)
LC23E2D: dw $3C6E ;($30)
LC23E2F: dw $388C
LC23E31: dw $388C
LC23E33: dw $3966 ;($33)
LC23E35: dw $3C91 ;($34)
LC23E37: dw $3D49 ;($35)
LC23E39: dw $388C
LC23E3B: dw $3D1E ;($37)
LC23E3D: dw $396C ;($38)
LC23E3F: dw $395E ;($39)
LC23E41: dw $3D27 ;($3A)
LC23E43: dw $3BCB ;($3B)
LC23E45: dw $388C
LC23E47: dw $388C
LC23E49: dw $3D7C ;($3E)
LC23E4B: dw $3D85 ;($3F)
LC23E4D: dw $3DB0 ;($40)
LC23E4F: dw $388C
LC23E51: dw $388C
LC23E53: dw $388C
LC23E55: dw $3CFD ;($44)
LC23E57: dw $388C
LC23E59: dw $388C
LC23E5B: dw $388C
LC23E5D: dw $388C
LC23E5F: dw $388C
LC23E61: dw $3DB8 ;($4A)
LC23E63: dw $396C ;($4B)
LC23E65: dw $3D17 ;($4C)
LC23E67: dw $388C
LC23E69: dw $388C
LC23E6B: dw $388C
LC23E6D: dw $3B98 ;($50)
LC23E6F: dw $388C
LC23E71: dw $399E ;($52)
LC23E73: dw $3AC5 ;($53)
LC23E75: dw $3B71 ;($54)
LC23E77: dw $3B29 ;($55)
LC23E79: dw $3A8D ;($56)
LC23E7B: dw $3C78 ;($57)


;Calls once-per-strike special effect code

LC23E7D:  PHX
LC23E7E:  PHP
LC23E7F:  SEP #$30
LC23E81:  TXY
LC23E82:  LDX $11A9
LC23E85:  JSR ($42E1,X)
LC23E88:  PLP
LC23E89:  PLX
LC23E8A:  RTS


;Random Steal Effect (Special Effect 1 - ThiefKnife

LC23E8B:  JSR $4B53      ;50% chance to steal
LC23E8E:  BCS LC23E9F
LC23E90:  LDA #$A4       ;Add steal effect to attack
LC23E92:  STA $11A9
LC23E95:  LDA $B5
LC23E97:  CMP #$00
LC23E99:  BNE LC23E9F    ;Exit if Command is not Fight
LC23E9B:  LDA #$06
LC23E9D:  STA $B5        ;set command to Capture for animation purposes
LC23E9F:  RTS


;Step Mine - sets damage to Steps / Spell Power, capped at 65535

LC23EA0:  STZ $3414      ;Set to ignore damage modifiers
LC23EA3:  REP #$20       ;Set 16-bit Accumulator
LC23EA5:  TDC
LC23EA6:  DEC
LC23EA7:  STA $11B0      ;Store default of 65535 in maximum damage
LC23EAA:  LDA $1867      ;Steps High 2 Bytes
LC23EAD:  LDX $11A6      ;Spell Power
LC23EB0:  JSR $4792      ;Division function Steps / Spell Power
LC23EB3:  SEP #$20       ;Set 8-bit Accumulator
LC23EB5:  XBA
LC23EB6:  BNE LC23EC9    ;If the top byte of quotient is nonzero, we know the
                         ;final result will exceed 2 bytes, so leave it
                         ;at 65535 and branch
LC23EB8:  TXA            ;A = remainder of Steps / Spell Power
LC23EB9:  XBA
LC23EBA:  STA $11B1      ;Store in Maximum Damage high byte
LC23EBD:  LDA $1866      ;Steps Low Byte
LC23EC0:  LDX $11A6      ;Spell Power
LC23EC3:  JSR $4792      ;Division function
LC23EC6:  STA $11B0      ;Store in Maximum Damage low byte
LC23EC9:  RTS


;Ogre Nix - Weapon randomly breaks.  Also uses MP for criticals.

LC23ECA:  LDA $B1
LC23ECC:  LSR
LC23ECD:  BCS LC23F22    ;if not a conventional attack [i.e. in this context: it's
                         ;a counterattack], Jump to code for attack with MP
LC23ECF:  LDA $3AA0,Y
LC23ED2:  BIT #$04
LC23ED4:  BNE LC23F22    ;Jump to code for attack with MP if bit 2 of $3AA0,Y is set
LC23ED6:  LDA $3BF5,Y    ;Load high byte of HP
LC23ED9:  XBA
LC23EDA:  LDA $3BF4,Y    ;Load low byte of HP
LC23EDD:  LDX #$0A
LC23EDF:  JSR $4792      ;A = HP / 10.  X = remainder, or the ones digit.
LC23EE2:  INX
LC23EE3:  TXA
LC23EE4:  JSR $4B65      ;Random number 0 to last digit of HP
LC23EE7:  DEC
LC23EE8:  BPL LC23F22    ;If number was not 0, branch
LC23EEA:  TYA
LC23EEB:  LSR
LC23EEC:  TAX            ;X = target [0, 1, 2, 3, etc]
LC23EED:  INC $2F30,X    ;flag character's properties to be recalculated from
                         ;his/her equipment at end of turn.
LC23EF0:  XBA
LC23EF1:  LDA #$05
LC23EF3:  JSR $4781      ;Multiplication function
LC23EF6:  STA $EE        ;save target # * 5
LC23EF8:  TYX
LC23EF9:  LDA $3A70      ;# of strikes remaining in attack.  with Fight/Capture,
                         ;this value is always odd when the right hand is
                         ;striking, and even when the left is.  unfortunately,
                         ;that's not the case with Jump -- the hand used has
                         ;nothing to do with the strike # (in fact, it's random
                         ;when Genji Glove is worn -- resulting in a bug where
                         ;Ogre Nix fails to break when it should [as C2/3F0B
                         ;will check the wrong hand].
LC23EFC:  LSR            ;Carry = 1 for right hand, 0 for left
LC23EFD:  BCS LC23F06    ;branch if right hand is attacking
LC23EFF:  INX            ;point to left hand equipment slot
LC23F00:  LDA $EE
LC23F02:  ADC #$14
LC23F04:  STA $EE        ;point to the character's left hand in their
                         ;menu data
LC23F06:  STZ $3B68,X    ;zero this hand's Battle Power
LC23F09:  LDX $EE
LC23F0B:  LDA $2B86,X    ;get item in this hand
LC23F0E:  CMP #$17
LC23F10:  BNE LC23F22    ;Branch if it's not Ogre Nix
LC23F12:  LDA #$FF
LC23F14:  STA $2B86,X    ;null this hand slot in the character's menu data
LC23F17:  STA $2B87,X
LC23F1A:  STZ $2B89,X
LC23F1D:  LDA #$44
LC23F1F:  STA $3401      ;Display weapon broke text
LC23F22:  LDA #$0C       ;Special Effect 7 - Use MP for criticals - jumps here.
                         ;Featured in Rune Edge, Punisher, Ragnarok, and
                         ;Illumina.
LC23F24:  STA $EE
LC23F26:  LDA $B2
LC23F28:  BIT #$02
LC23F2A:  BNE LC23F4F    ;Exit function if "No Critical and Ignore True Knight"
                         ;is set
LC23F2C:  LDA $3EC9
LC23F2F:  BEQ LC23F4F    ;Exit function if no targets
LC23F31:  TDC            ;Clear 16-bit A
LC23F32:  JSR $4B5A      ;random #: 0 to 255
LC23F35:  AND #$07       ;now random #: 0 to 7
LC23F37:  CLC
LC23F38:  ADC $EE        ;Add to $EE [#$0C]
LC23F3A:  REP #$20       ;Set 16-bit Accumulator
LC23F3C:  STA $EE        ;Save MP consumed
LC23F3E:  LDA $3C08,Y    ;Attacker MP
LC23F41:  CMP $EE
LC23F43:  BCC LC23F4F    ;Exit function if weapon would drain more MP than the
                         ;wielder currently has
LC23F45:  SBC $EE
LC23F47:  STA $3C08,Y    ;Current MP = Current MP - MP consumed
LC23F4A:  LDA #$0200
LC23F4D:  TRB $B2        ;Set always critical
LC23F4F:  RTS


;Special Effect $0F - Use MP for criticals.  No weapons use this, afaik.

LC23F50:  LDA #$1C
LC23F52:  BRA LC23F24


;<>Pearl Wind

LC23F54:  LDA #$60
LC23F56:  TSB $11A2      ;Sets no split damage, and ignore defense
LC23F59:  STZ $3414      ;Set to not modify damage
LC23F5C:  REP #$20
LC23F5E:  LDA $3BF4,Y    ;HP
LC23F61:  STA $11B0      ;Maximum Damage = HP
LC23F64:  RTS


;Golem

LC23F65:  REP #$20
LC23F67:  LDA $3BF4,Y    ;Current HP
LC23F6A:  STA $3A36      ;HP that Golem will absorb
LC23F6D:  RTS


;Special Effect 6 - Soul Sabre

LC23F6E:  LDA #$80
LC23F70:  TSB $11A3      ;Sets attack to Concern MP
LC23F73:  LDA #$08       ;Special Effect 5 - Drainer jumps here
LC23F75:  TSB $11A2      ;Sets attack to heal undead
LC23F78:  LDA #$02
LC23F7A:  TSB $11A4      ;Sets attack to redirection
LC23F7D:  RTS


;Recover HP - Heal Rod

LC23F7E:  LDA #$20
LC23F80:  TSB $11A2      ;Sets attack to ignore defense
LC23F83:  LDA #$01
LC23F85:  TSB $11A4      ;Sets attack to heal
LC23F88:  RTS


;Valiant Knife

LC23F89:  LDA #$20
LC23F8B:  TSB $11A2      ;Sets attack to ignore defense
LC23F8E:  REP #$20
LC23F90:  SEC
LC23F91:  LDA $3C1C,Y    ;Max HP
LC23F94:  SBC $3BF4,Y    ;HP
LC23F97:  CLC
LC23F98:  ADC $11B0      ;Add Max HP - Current HP to damage
LC23F9B:  STA $11B0
LC23F9E:  RTS


;Wind Slash - Tempest

LC23F9F:  JSR $4B5A      ;Random Number Function: 0 to 255
LC23FA2:  CMP #$80
LC23FA4:  BCS LC23FB6    ;50% chance exit function
LC23FA6:  STZ $11A6      ;Clear Battle Power
LC23FA9:  LDA #$65       ;Wind Slash spell number
LC23FAB:  BRA LC23FB0


;Magicite

LC23FAD:  JSR $37DC      ;Picks random Esper, not Odin or Raiden
LC23FB0:  STA $3400      ;Save the spell number
LC23FB3:  INC $3A70      ;Increment the number of attacks remaining
LC23FB6:  RTS


;Special effect $51
;GP Rain

LC23FB7:  LDA $3B18,Y    ;Attacker's Level
LC23FBA:  XBA
LC23FBB:  LDA #$1E
LC23FBD:  JSR $4781      ;attack will cost: Attacker's Level * 30
                         ;JSR $2B63?
LC23FC0:  REP #$20       ;Set 16-bit accumulator
LC23FC2:  CPY #$08
LC23FC4:  BCS LC23FD3    ;Branch if attacker is monster
LC23FC6:  JSR $37B6      ;deduct thrown gold from party's inventory
LC23FC9:  BNE LC23FE9    ;branch if there was actually some GP to throw
LC23FCB:  STZ $A4        ;Makes attack target nothing
LC23FCD:  LDX #$08
LC23FCF:  STX $3401      ;Set to display text 8 - "No money!!"
LC23FD2:  RTS


LC23FD3:  STA $EE        ;Level * 30
LC23FD5:  LDA $3D98,Y    ;Gold monster gives
LC23FD8:  BEQ LC23FCB    ;Miss all w/text if = 0
LC23FDA:  SBC $EE
LC23FDC:  BCS LC23FE4    ;Branch if monster's gold >= Level * 30
LC23FDE:  LDA $3D98,Y
LC23FE1:  STA $EE        ;if gold to consume was more than current
                         ;gold, set $EE to current gold
LC23FE3:  TDC
LC23FE4:  STA $3D98,Y    ;Set Gold to 0 or Gold - Level * 30
LC23FE7:  LDA $EE        ;get amount of gold to consume
LC23FE9:  LDX #$02
LC23FEB:  STX $E8
LC23FED:  JSR $47B7      ;24-bit $E8 = A * 2
LC23FF0:  LDA $E8        ;A = gold to consume * 2
LC23FF2:  LDX $3EC9      ;Number of targets
LC23FF5:  JSR $4792      ;A / number of targets
LC23FF8:  STA $11B0      ;Sets maximum damage
LC23FFB:  RTS


;Exploder effect from 42E1

LC23FFC:  TYX
LC23FFD:  STZ $BC        ;clear the Damage Incrementor.  i don't think it
                         ;ever could have been set, aside from Morph
                         ;being Ripplered onto a Lore user.
LC23FFF:  LDA #$10
LC24001:  TSB $B0        ;somehow ensures caster still steps forward to do
                         ;attack, and gets blue triangle.  must be needed
                         ;because of extra C2/57C2 calls.
LC24003:  STZ $3414      ;Set to not modify damage
LC24006:  REP #$20       ;Set 16-bit A
LC24008:  LDA $A4        ;Load target hit
LC2400A:  PHA            ;Put on stack
LC2400B:  LDA $3018,X
LC2400E:  STA $B8        ;temporarily save caster as sole target
LC24010:  JSR $57C2
LC24013:  JSR $63DB      ;Copy $An variables to ($78) buffer
LC24016:  LDA $01,S      ;restore original target
LC24018:  STA $B8
LC2401A:  JSR $57C2
LC2401D:  PLA
LC2401E:  ORA $3018,X
LC24021:  STA $A4        ;add attacker to targets
LC24023:  LDA $3BF4,X
LC24026:  STA $11B0      ;Sets damage to caster's Current HP
LC24029:  JMP $35AD      ;Write data in $B4 - $B7 to current slot in ($76
                         ;animation buffer, and point $3A71 to this slot


;Special effect $4A (Super Ball

LC2402C:  LDA #$7D
LC2402E:  STA $B6        ;Set Animation
LC24030:  JSR $4B5A      ;random: 0 to 255
LC24033:  AND #$03       ;0 to 3
LC24035:  BRA LC24039
LC24037:  LDA #$07       ;Special Effect $2C, Launcher, jumps here
LC24039:  STA $3405      ;# of hits to do.  this is a zero-based counter, so
                         ;a value of 0 means 1 hit.
LC2403C:  REP #$20       ;Set 16-bit Accumulator
LC2403E:  LDA $3018,Y
LC24041:  STA $A6        ;mark attacker as "reflected off of", which will later
                         ;trigger function C2/3483 and cause him/her to be
                         ;treated as the missile launcher or ball thrower.
LC24043:  RTS


;Special Effect 2 (Atma Weapon

LC24044:  LDA #$20
LC24046:  TSB $11A2      ;Set attack to ignore defense
LC24049:  LDA #$02
LC2404B:  TSB $B2        ;Set no critical & ignore True Knight
LC2404D:  RTS


;Warp effect (Warp Stone uses same effect

LC2404E:  LDA $B1
LC24050:  BIT #$04       ;is "Can't Escape" flag set by an active enemy?
LC24052:  BNE LC2405A    ;branch if so
LC24054:  LDA #$02
LC24056:  STA $3A6E      ;"End of combat" method #2, Warping
LC24059:  RTS


LC2405A:  LDA #$0A
LC2405C:  STA $3401      ;Display can't run text
LC2405F:  BRA LC2409C    ;Set to no targets


;Bababreath from 42E1

LC24061:  STZ $EE
LC24063:  LDX #$06
LC24065:  LDA $3AA0,X
LC24068:  LSR
LC24069:  BCC LC2407C    ;branch if target not valid
LC2406B:  LDA $3EE4,X    ;Status byte 1
LC2406E:  BIT #$C2       ;Check for Dead, Zombie, or Petrify
LC24070:  BEQ LC2407C    ;Branch if none set
LC24072:  LDA $3018,X
LC24075:  BIT $3F2C
LC24078:  BNE LC2407C    ;branch if airborne from jump
LC2407A:  STA $EE        ;save as preferred target
LC2407C:  DEX
LC2407D:  DEX
LC2407E:  BPL LC24065    ;Loop through all 4 characters
LC24080:  LDA $EE
LC24082:  BNE LC2408D    ;if any character is Dead/Zombied/Petrified and not
                         ;airborne, use it as target instead.  if there're
                         ;multiple such characters, use the one who's closest
                         ;to the start of the party lineup.
LC24084:  LDA $3A76      ;Number of present and living characters in party
LC24087:  CMP #$02
LC24089:  BCS LC240BA    ;Exit function if 2+ characters alive, retaining
                         ;the initial target
LC2408B:  BRA LC2409C    ;Set to no targets, because we don't want to blow
                         ;away the only living character.

LC2408D:  STA $B8        ;save the Dead/Zombied/Petrified character as sole
                         ;target
LC2408F:  STZ $B9        ;clear any monster targets
LC24091:  TYX
LC24092:  JMP $57C2


;Special effect $50 - Possess
;106/256 chance to miss

LC24095:  JSR $4B5A      ;Random Number Function 0 to 255
LC24098:  CMP #$96
LC2409A:  BCC LC240BA    ;Exit function if A < 150
LC2409C:  STZ $A4
LC2409E:  STZ $A5        ;Make target nothing
LC240A0:  RTS


;L? Pearl from 42E1

LC240A1:  LDA $1862      ;the following code will divide our 24-bit
                         ;gold, held in $1860 - $1862, by 10.
LC240A4:  XBA
LC240A5:  LDA $1861
LC240A8:  LDX #$0A
LC240AA:  JSR $4792      ;Divides top 2 bytes of gold by 10.  put
                         ;quotient in A, and remainder in X.
LC240AD:  TXA
LC240AE:  XBA
LC240AF:  LDA $1860      ;16-bit A = (above remainder * 256
                         ;+ bottom byte of gold
LC240B2:  LDX #$0A
LC240B4:  JSR $4792      ;X = gold amount MOD 10, i.e. the ones digit
                         ;of GP
LC240B7:  STX $11A8      ;Save as Hit rate / level multiplier for
                         ;LX spells
LC240BA:  RTS


;Escape

LC240BB:  CPY #$08
LC240BD:  BCS LC240BA    ;Exit if monster
LC240BF:  LDA #$22
LC240C1:  STA $B5        ;use striding away animation instead of just
                         ;disappearing
LC240C3:  LDA #$10
LC240C5:  TSB $A0        ;would prevent the character from stepping forward
                         ;and getting a blue triangle if that animation
                         ;didn't already do so
LC240C7:  RTS


;Special effect $4B - Smoke Bomb

LC240C8:  LDA #$04
LC240CA:  BIT $B1        ;is "Can't Escape" flag set by an active enemy?
LC240CC:  BEQ LC240BA    ;Exit if not
LC240CE:  JSR $409C      ;Set to no targets
LC240D1:  STZ $11A9      ;Clear special effect
LC240D4:  LDA #$09
LC240D6:  STA $3401      ;Display text #9
LC240D9:  RTS


;Forcefield

LC240DA:  TDC            ;Clear Accumulator
LC240DB:  LDA #$FF
LC240DD:  EOR $3EC8
LC240E0:  BEQ LC2409C    ;Set to no targets if all elements nullified
LC240E2:  JSR $522A      ;Randomly pick a set bit
LC240E5:  TSB $3EC8      ;Set that bit in $3EC8
LC240E8:  JSR $51F0      ;X = Get which bit is picked
LC240EB:  TXA
LC240EC:  CLC
LC240ED:  ADC #$37
LC240EF:  BRA LC240D6


;<>Quadra Slam, Quadra Slice, etc.
;4 Random attacks

LC240F1:  LDA #$03
LC240F3:  STA $3A70      ;# of attacks
LC240F6:  LDA #$40
LC240F8:  TSB $BA        ;Sets randomize target
LC240FA:  STZ $11A9      ;Clears special effect
LC240FD:  RTS


;Blow Fish

LC240FE:  LDA #$60
LC24100:  TSB $11A2      ;Set Ignore defense, and no split damage
LC24103:  STZ $3414      ;Set to not modify damage
LC24106:  REP #$20       ;Set 16-bit Accumulator
LC24108:  LDA #$03E8
LC2410B:  STA $11B0      ;Set damage to 1000
LC2410E:  RTS


;Flare Star

LC2410F:  STZ $3414      ;Set to not modify damage
LC24112:  REP #$20       ;Set 16-bit Accumulator
LC24114:  LDA $A2        ;Bitfield of targets
LC24116:  JSR $522A      ;A = a random target present in $A2
LC24119:  JSR $51F9      ;Y = [Number of highest target set in A] * 2.
                         ;so we're obtaining a target index.
LC2411C:  LDA $A2
LC2411E:  JSR $520E      ;X = number of bits set in A, so # of targets
LC24121:  SEP #$20       ;Set 8-bit Accumulator
LC24123:  LDA $3B18,Y    ;Level
LC24126:  XBA
LC24127:  LDA $11A6      ;Spell Power
LC2412A:  JSR $4781      ;Spell Power * Level
LC2412D:  JSR $4792      ;Divide by X, the number of targets
LC24130:  REP #$20       ;Set 16-bit Accumulator
LC24132:  STA $11B0      ;Store in maximum damage
LC24135:  RTS


;Special effect $4C - Elixir and Megalixir.  In Item data, this appears as
; Special effect $04)

LC24136:  LDA #$80
LC24138:  TRB $11A3      ;Clears concern MP
LC2413B:  RTS


;Special effect $28 - Mind Blast

LC2413C:  REP #$20       ;Set 16-bit Accumulator
LC2413E:  LDY #$06
LC24140:  LDA $A4
LC24142:  JSR $522A      ;Randomly pick an entity from among the targets
LC24145:  STA $3A5C,Y    ;add them to "Mind Blast victims" list.  the
                         ;other Mind Blast special effect will later try
                         ;to give an ailment to each entry in the list.
                         ;and yes, there can be duplicates.
LC24148:  DEY
LC24149:  DEY
LC2414A:  BPL LC24140    ;Do four times
LC2414C:  RTS


;Miss random targets
; Special Effect $29 - N. Cross
; Each target will have a 50% chance of being untargeted.)

LC2414D:  JSR $4B5A      ;random #: 0 to 255
LC24150:  TRB $A4
LC24152:  JSR $4B5A      ;random #: 0 to 255
LC24155:  TRB $A5
LC24157:  RTS


;Dice Effect

LC24158:  STZ $3414      ;Set to not modify damage
LC2415B:  LDA #$20
LC2415D:  TSB $11A4      ;Makes unblockable
LC24160:  LDA #$0F
LC24162:  STA $B6        ;Third die defaults to null to start with
LC24164:  TDC
LC24165:  JSR $4B5A      ;Random Number Function 0 to 255
LC24168:  PHA            ;Put on stack
LC24169:  AND #$0F       ;0 to 15
LC2416B:  LDX #$06       ;will divide bottom nibble of random number by 6
LC2416D:  JSR $4792      ;Division A/X.  X will hold A MOD X
LC24170:  STX $B7        ;First die roll, 0 to 5 -- 3/16 chance of 0 thru 3
                         ;each, 2/16 chance of 4 thru 5 each
LC24172:  INX
LC24173:  STX $EE        ;Save first die roll, 1 to 6
LC24175:  PLA            ;Retrieve our 0-255 random number
LC24176:  LDX #$60       ;will divide top nibble of random number by 6
LC24178:  JSR $4792      ;Division A/X
LC2417B:  TXA            ;get MOD of division
LC2417C:  AND #$F0       ;0 to 5
LC2417E:  ORA $B7
LC24180:  STA $B7        ;$B7: bottom nibble = 1st die roll 0 thru 5,
                         ;top nibble = 2nd die roll 0 thru 5
LC24182:  LSR
LC24183:  LSR
LC24184:  LSR
LC24185:  LSR
LC24186:  INC            ;2nd die roll, converted to a 1 thru 6 value
LC24187:  XBA            ;put in top half of A
LC24188:  LDA $EE        ;Get first die roll, 1 to 6
LC2418A:  JSR $4781      ;Multiply them
LC2418D:  STA $EE        ;$EE = 1st roll * 2nd roll, where each roll is 1 thru 6
LC2418F:  LDA $11A8      ;# of dice
LC24192:  CMP #$03
LC24194:  BCC LC241AB    ;Branch if less than 3 dice, i.e. there's 2
LC24196:  TDC            ;Clear Accumulator
LC24197:  LDA $021E      ;our 1-60 frame counter.  because 6 divides evenly into 60,
                         ;the third die has the same odds for all sides; it is NOT
                         ;slanted against you like the first two dice.
LC2419A:  LDX #$06
LC2419C:  JSR $4792      ;Division A/X
LC2419F:  TXA            ;new random number MOD 6
LC241A0:  STA $B6        ;save third die roll
LC241A2:  INC
LC241A3:  XBA            ;3rd die roll, converted to a 1 thru 6 value
LC241A4:  LDA $EE
LC241A6:  JSR $4781      ; (1st roll * 2nd roll) * 3rd roll
LC241A9:  STA $EE        ;$EE = 1st roll * 2nd roll * 3rd roll, where each roll
                         ;is 1 thru 6
LC241AB:  LDX #$00
LC241AD:  LDA $B6        ;holds third die roll [0 to 5] if 3 dice,
                         ;or 0Fh if only 2 dice
LC241AF:  ASL
LC241B0:  ASL
LC241B1:  ASL
LC241B2:  ASL
LC241B3:  ORA $B6        ;A: if 2 dice, A = FF.  if 3 dice, A top nibble = 3rd die roll,
                         ;and A bottom nibble = 3rd die roll
LC241B5:  CMP $B7        ;does 3rd die roll match both 1st and 2nd?
                         ;obviously, it can NEVER if A = FF
LC241B7:  BNE LC241BB    ;if no match, branch
LC241B9:  LDX $B6        ;X = 0 if there's not 3 matching dice.  if there are,
                         ;we've got a bonus coming, so let X be the 0 thru 5
                         ;roll value
LC241BB:  LDA $EE        ;depending on # of dice, retrieve either:
                         ; 1st roll * 2nd roll   OR
                         ; 1st roll * 2nd roll * 3rd roll
LC241BD:  XBA
LC241BE:  LDA $11AF      ;Attacker Level
LC241C1:  ASL
LC241C2:  JSR $4781      ; (1st roll * 2nd roll * 3rd roll) * (Level * 2)
LC241C5:  REP #$20       ;set 16 bit-Accumulator
LC241C7:  STA $EE        ;overall damage =
                         ;2 Dice: 1st roll * 2nd roll * Level * 2,
                         ;3 Dice: 1st roll * 2nd roll * 3rd roll * Level * 2
LC241C9:  CLC
LC241CA:  STA $11B0      ;save damage
LC241CD:  LDA $EE
LC241CF:  ADC $11B0      ;Add [Level * 1st roll * 2nd roll * 3rd roll * 2]
                         ;or [Level * 1st roll * 2nd roll * 2] to damage
LC241D2:  BCC LC241D6    ;branch if it didn't overflow
LC241D4:  TDC
LC241D5:  DEC            ;set running damage to 65535
LC241D6:  DEX
LC241D7:  BPL LC241C9    ;Add the damage to itself X times, where X is the value
                         ;as commented at C2/41B9.  This loop serves to multiply
                         ;3 matching dice by the roll value once more, bringing
                         ;the damage to:  Roll * Roll * Roll * Level * 2 * Roll .
                         ;if X is 0 (i.e. no 3 matching dice, or 3 matching dice
                         ;with a value of 1), only the bonus-less damage is saved.
LC241D9:  SEP #$20       ;8-bit Accumulator
LC241DB:  LDA $B5
LC241DD:  CMP #$00
LC241DF:  BNE LC241E3    ;Branch if command not Fight
LC241E1:  LDA #$26
LC241E3:  STA $B5        ;Store a dice toss animation
LC241E5:  RTS


;Revenge

LC241E6:  STZ $3414      ;Set to not modify damage
LC241E9:  REP #$20       ;Set 16-bit Accumulator
LC241EB:  SEC
LC241EC:  LDA $3C1C,Y    ;Max HP
LC241EF:  SBC $3BF4,Y    ;Current HP
LC241F2:  STA $11B0      ;Damage = Max HP - Current HP
LC241F5:  RTS


;Palidor from $42E1
;Makes not jump if you have Petrify, Sleep, Stop, Hide, or Freeze status

LC241F6:  LDA #$10
LC241F8:  TSB $3A46      ;set "Palidor was summoned this turn" flag
LC241FB:  REP #$20
LC241FD:  LDX #$12
LC241FF:  LDA $3EE4,X
LC24202:  BIT #$8040     ;Check for Petrify or Sleep
LC24205:  BNE LC2420F    ;branch if any set
LC24207:  LDA $3EF8,X
LC2420A:  BIT #$2210     ;Check for Stop, Hide, or Freeze
LC2420D:  BEQ LC24216    ;branch if none set
LC2420F:  LDA $3018,X
LC24212:  TRB $A2        ;Remove from being a target
LC24214:  TRB $A4
LC24216:  DEX
LC24217:  DEX
LC24218:  BPL LC241FF    ;iterate for all 10 entities
LC2421A:  RTS


;Empowerer

LC2421B:  LDA $11A3
LC2421E:  EOR #$80       ;Toggle Concern MP
LC24220:  STA $11A3
LC24223:  BPL LC2422A    ;Branch if not Concern MP -- this means we're
                         ;currently on the first "strike", which affects HP
LC24225:  LDA #$12
LC24227:  STA $B5        ;save Nothing [Mimic] as command animation.
                         ;this means the spell animation won't be repeated
                         ;for the MP-draining phase of Empowerer.
LC24229:  RTS

LC2422A:  INC $3A70      ;make the attack, including this special effect,
                         ;get repeated
LC2422D:  LSR $11A6
LC24230:  LSR $11A6      ;Cut Spell Power to 1/4 for 2nd "strike", which
                         ;will affect MP
LC24233:  RTS


;Spiraler

LC24234:  TYX
LC24235:  LDA $3018,X
LC24238:  TRB $A2
LC2423A:  TRB $A4        ;Miss yourself
LC2423C:  TSB $2F4C      ;mark attacker to be removed from the battlefield
LC2423F:  JSR $384A      ;Mark Hide and Death statuses to be set on attacker in
                         ;X, and mark the attacker as its own last attacker.
LC24242:  REP #$20       ;Set 16-bit Accumulator
LC24244:  STZ $3BF4,X    ;Zeroes HP of attacker
LC24247:  STZ $3C08,X    ;Zeroes MP of attacker
LC2424A:  RTS


;Discard

LC2424B:  JSR $409C      ;Set to no targets
LC2424E:  LDA #$20
LC24250:  TSB $11A4      ;Set Can't be dodged
LC24253:  LDX $3358,Y    ;whom you are Seizing
LC24256:  BMI LC2424A    ;Exit if not Seizing anybody
LC24258:  LDA $3018,X
LC2425B:  STA $B8
LC2425D:  STZ $B9        ;set sole target to character whom you are Seizing
LC2425F:  TYX
LC24260:  JMP $57C2


;Mantra

LC24263:  LDA #$60
LC24265:  TSB $11A2      ;Set no split damage, & ignore defense
LC24268:  STZ $3414      ;Set to not modify damage
LC2426B:  REP #$20       ;Set 16-bit Accumulator
LC2426D:  LDA $3018,Y
LC24270:  TRB $A4        ;Make miss yourself
LC24272:  LDX $3EC9      ;Number of targets
LC24275:  DEX
LC24276:  LDA $3BF4,Y
LC24279:  JSR $4792      ;HP / (Number of targets - 1)
LC2427C:  STA $11B0      ;Set damage
LC2427F:  RTS


;Special Effect $42
;Cuts damage to 1/4

LC24280:  REP #$20       ;Set 16-bit Accumulator
LC24282:  LSR $11B0      ;Halves damage
LC24285:  REP #$20       ;Special effect $41 jumps here
LC24287:  LSR $11B0      ;Halves damage
LC2428A:  RTS


;Suplex code from 42E1
;Picks a random target)

LC2428B:  LDA #$10
LC2428D:  TSB $B0        ;???  See functions C2/13D3 and C2/57C2 for usual
                         ;purpose; dunno whether it does anything here.
LC2428F:  REP #$20       ;Set 16-bit Accumulator
LC24291:  LDA $A2
LC24293:  STA $EE        ;Copy targets to temporary variable
LC24295:  LDX #$0A
LC24297:  LDA $3C88,X    ;Monster data - Special Byte 2
LC2429A:  BIT #$0004
LC2429D:  BEQ LC242A4    ;Check next target if this one can be Suplexed
LC2429F:  LDA $3020,X
LC242A2:  TRB $EE        ;Clear this monster from potential targets
LC242A4:  DEX
LC242A5:  DEX
LC242A6:  BPL LC24297    ;Loop for all 6 monster targets
LC242A8:  LDA $EE
LC242AA:  BNE LC242AE    ;Branch if some targets left in temporary variable,
                         ;which means we'll actually be attacking something
                         ;that can be Suplexed!
LC242AC:  LDA $A2        ;original Targets
LC242AE:  JSR $522A      ;Randomly pick a bit
LC242B1:  STA $B8        ;save our one target
LC242B3:  TYX
LC242B4:  JMP $57C2


;Reflect???

LC242B7:  REP #$20
LC242B9:  LDX #$12
LC242BB:  LDA $3EF7,X
LC242BE:  BMI LC242C5    ;Branch if Reflect status
LC242C0:  LDA $3018,X
LC242C3:  TRB $A4        ;Make miss target
LC242C5:  DEX
LC242C6:  DEX
LC242C7:  BPL LC242BB    ;iterate for all targets
LC242C9:  RTS


;Quick

LC242CA:  LDA $3402
LC242CD:  BPL LC242D8    ;Branch if already under influence of Quick
LC242CF:  STY $3404      ;Set attacker as target under the influence
                         ;of Quick
LC242D2:  LDA #$02
LC242D4:  STA $3402      ;Set the number of turns due to Quick
LC242D7:  RTS


LC242D8:  REP #$20       ;Set 16-bit Accumulator
LC242DA:  LDA $3018,Y
LC242DD:  TSB $3A5A      ;Set target as missed
LC242E0:  RTS


;Table for special effects code pointers 2 (once-per-strike

LC242E1: dw $3E8A
LC242E3: dw $3E8B
LC242E5: dw $4044 ;($02)
LC242E7: dw $3E8A
LC242E9: dw $3E8A
LC242EB: dw $3F73 ;($05)
LC242ED: dw $3F6E ;($06)
LC242EF: dw $3F22 ;($07)
LC242F1: dw $3E8A
LC242F3: dw $4158 ;($09)
LC242F5: dw $3F89 ;($0A)
LC242F7: dw $3F9F ;($0B)
LC242F9: dw $3F7E ;($0C)
LC242FB: dw $3E8A
LC242FD: dw $3ECA ;($0E)
LC242FF: dw $3F50 ;($0F)
LC24301: dw $3E8A
LC24303: dw $3F65 ;($11)
LC24305: dw $3E8A
LC24307: dw $41F6 ;($13)
LC24309: dw $3E8A
LC2430B: dw $4263 ;($15)
LC2430D: dw $4234 ;($16)
LC2430F: dw $3E8A
LC24311: dw $404E ;($18)
LC24313: dw $3FFC ;($19)
LC24315: dw $40FE ;($1A)
LC24317: dw $3F54 ;($1B)
LC24319: dw $42B7 ;($1C)
LC2431B: dw $40A1 ;($1D)
LC2431D: dw $3EA0 ;($1E)
LC2431F: dw $3E8A
LC24321: dw $3E8A
LC24323: dw $3E8A
LC24325: dw $3E8A
LC24327: dw $3E8A
LC24329: dw $3E8A
LC2432B: dw $3E8A
LC2432D: dw $3E8A
LC2432F: dw $40BB ;($27)
LC24331: dw $413C ;($28)
LC24333: dw $414D ;($29)
LC24335: dw $410F ;($2A)
LC24337: dw $3E8A
LC24339: dw $4037 ;($2C)
LC2433B: dw $3E8A
LC2433D: dw $3E8A
LC2433F: dw $3E8A
LC24341: dw $428B ;($30)
LC24343: dw $40DA ;($31)
LC24345: dw $40F1 ;($32)
LC24347: dw $4061 ;($33)
LC24349: dw $3E8A
LC2434B: dw $3E8A
LC2434D: dw $421B ;($36)
LC2434F: dw $3E8A
LC24351: dw $3E8A
LC24353: dw $3E8A
LC24354: dw $3E8A
LC24357: dw $3E8A
LC24359: dw $3E8A
LC2435B: dw $41E6 ;($3D)
LC2435D: dw $3E8A
LC2435F: dw $3E8A
LC24361: dw $3E8A
LC24363: dw $4285 ;($41)
LC24365: dw $4280 ;($42)
LC24367: dw $42CA ;($43)
LC24369: dw $424B ;($44)
LC2436B: dw $3E8A
LC2436D: dw $3E8A
LC2436F: dw $3E8A
LC24371: dw $3E8A
LC24373: dw $3FAD ;($49)
LC24375: dw $402C ;($4A)
LC24377: dw $40C8 ;($4B)
LC24379: dw $4136 ;($4C)
LC2437B: dw $404E ;($4D)
LC2437D: dw $3E8A
LC2437F: dw $3E8A
LC24381: dw $4095 ;($50)
LC24383: dw $3FB7 ;($51)
LC24385: dw $3E8A
LC24387: dw $3E8A
LC24389: dw $3E8A
LC2438B: dw $3E8A
LC2438D: dw $3E8A
LC2438F: dw $3E8A


;Update statuses for every entity onscreen (at battle start, on formation switch,
; and after each strike of an attack)

LC24391:  PHX
LC24392:  PHP
LC24393:  REP #$20       ;Set 16-bit Accumulator
LC24395:  LDY #$12
LC24397:  LDA $3AA0,Y
LC2439A:  LSR
LC2439B:  BCC LC243FF    ;Skip this entity if not present in battle
LC2439D:  JSR $450D      ;Put Status to be Set / Clear into $Fn ,
                         ;Quasi New Status in $3E60 & $3E74
LC243A0:  LDA $FC        ;status to add, bytes 1-2
LC243A2:  BEQ LC243B3    ;Branch if none
LC243A4:  STA $F0
LC243A6:  LDX #$1E
LC243A8:  ASL $F0
LC243AA:  BCC LC243AF    ;Skip if current status not to be set
LC243AC:  JSR ($46B0,X)  ;perform "side effects" of setting it
LC243AF:  DEX
LC243B0:  DEX
LC243B1:  BPL LC243A8    ;Loop through all possible statuses to set in
                         ;bytes 1 & 2
LC243B3:  LDA $FE        ;status to add, bytes 3-4
LC243B5:  BEQ LC243C6    ;branch if none
LC243B7:  STA $F0
LC243B9:  LDX #$1E
LC243BB:  ASL $F0
LC243BD:  BCC LC243C2    ;Skip if current status not to be set
LC243BF:  JSR ($46D0,X)  ;perform "side effects" of setting it
LC243C2:  DEX
LC243C3:  DEX
LC243C4:  BPL LC243BB    ;Loop through all possible statuses to set in
                         ;bytes 3 & 4

;Note: the subtraction of blocked statuses from "statuses to clear" below takes place
; later than the removal of blocked statuses from "statuses to set".  i think this is
; because the special case set status functions called in $46B0 AND 46D0 can mark
; additional statuses to be cleared.  so Square performed the block checks after these
; calls to make sure we don't clear any statuses to which we're immune.)

LC243C6:  LDA $F4        ;status to clear bytes 1-2
LC243C8:  AND $331C,Y    ;blocked status bytes 1-2
LC243CB:  STA $F4        ;remove blocked from statuses to clear
LC243CD:  BEQ LC243DE    ;branch if nothing in these bytes to clear
LC243CF:  STA $F0
LC243D1:  LDX #$1E
LC243D3:  ASL $F0
LC243D5:  BCC LC243DA    ;Skip if current status not to be cleared
LC243D7:  JSR ($46F0,X)  ;Call for each status to be clear byte 1 & 2
LC243DA:  DEX
LC243DB:  DEX
LC243DC:  BPL LC243D3    ;Loop through all possible statuses to clear in
                         ;bytes 1 & 2
LC243DE:  LDA $F6        ;status to clear bytes 3-4
LC243E0:  AND $3330,Y    ;blocked status bytes 3-4
LC243E3:  STA $F6        ;don't try to clear blocked statuses
LC243E5:  BEQ LC243F6    ;branch if nothing in these bytes to clear
LC243E7:  STA $F0
LC243E9:  LDX #$1E
LC243EB:  ASL $F0
LC243ED:  BCC LC243F2    ;Skip if current status not to be cleared
LC243EF:  JSR ($4710,X)  ;Call for each status to be clear byte 3 & 4
LC243F2:  DEX
LC243F3:  DEX
LC243F4:  BPL LC243EB    ;Loop through all possible statuses to clear in
                         ;bytes 3 & 4
LC243F6:  JSR $447F      ;Get new status
LC243F9:  JSR $4585      ;Store in 3EE4 & 3EF8, and clear some statuses
                         ;if target has Zombie
LC243FC:  JSR $44FF      ;Clear status to set and status to clear bytes
LC243FF:  DEY
LC24400:  DEY
LC24401:  BPL LC24397    ;loop for all 10 targets on screen
LC24403:  PLP
LC24404:  PLX
LC24405:  RTS


;Determine statuses that will be set/removed when attack hits
; miss if attack doesn't change target's status)

LC24406:  PHP
LC24407:  REP #$20
LC24409:  LDA $3EE4,Y    ;get current status bytes 1-2
LC2440C:  STA $F8
LC2440E:  LDA $3EF8,Y    ;get current status bytes 3-4
LC24411:  STA $FA
LC24413:  JSR $4490      ;Initialize intermediate "status to set" bytes in
                         ;$F4 - $F7 and "status to clear" bytes in $FC - $FF.
                         ;Mark Clear / Freeze to be removed if necessary.
LC24416:  SEP #$20
LC24418:  LDA $B3
LC2441A:  BMI LC24420    ;Branch if not Ignore Clear
LC2441C:  LDA #$10
LC2441E:  TRB $F4        ;remove Vanish from Status to Clear
LC24420:  LDA $3C95,Y
LC24423:  BPL LC2443D    ;Branch if not undead
LC24425:  LDA #$08
LC24427:  BIT $11A2
LC2442A:  BEQ LC2443D    ;Branch if attack doesn't reverse damage on undead
LC2442C:  LSR
LC2442D:  BIT $11A4
LC24430:  BEQ LC2443D    ;Branch if not lift status
LC24432:  LDA $11AA
LC24435:  BIT #$82
LC24437:  BEQ LC2443D    ;Branch if attack doesn't involve Death or Zombie
LC24439:  LDA #$80
LC2443B:  TSB $FC        ;mark Death in Status to set
LC2443D:  REP #$20
LC2443F:  LDA $FC
LC24441:  JSR $0E32      ;update Status to set Bytes 1-2
LC24444:  LDA $FE
LC24446:  ORA $3DE8,Y
LC24449:  STA $3DE8,Y    ;update Status to set Bytes 3-4
LC2444C:  LDA $F4
LC2444E:  ORA $3DFC,Y
LC24451:  STA $3DFC,Y    ;update Status to clear Bytes 1-2
LC24454:  LDA $F6
LC24456:  ORA $3E10,Y
LC24459:  STA $3E10,Y    ;update Status to clear Bytes 3-4
LC2445C:  LDA $11A7
LC2445F:  LSR
LC24460:  BCC LC2447D    ;if "spell misses if protected from ailments" bit
                         ;is unset, exit function
LC24462:  LDA $FC
LC24464:  ORA $F4
LC24466:  AND $331C,Y    ;are there any statuses we're trying to set or clear
                         ;that aren't blocked?)  (bytes 1-2
LC24469:  BNE LC2447D    ;if there are, exit function
LC2446B:  LDA $FE
LC2446D:  ORA $F6
LC2446F:  AND $3330,Y    ;are there any statuses we're trying to set or clear
                         ;that aren't blocked?)  (bytes 3-4
LC24472:  BNE LC2447D    ;if there are, exit function
LC24474:  LDA $3018,Y
LC24477:  STA $3A48      ;Indicate a miss, due to the attack not changing any
                         ;statuses or due to checks in its special effect
LC2447A:  TSB $3A5A      ;Spell misses target if protected from ailments [or
                         ;specifically, if statuses unchanged]
LC2447D:  PLP
LC2447E:  RTS


;Get new status

LC2447F:  LDA $F8        ;status byte 1 & 2
LC24481:  TSB $FC        ;add to Status to set byte 1 & 2
LC24483:  LDA $F4        ;Status to clear byte 1 & 2
LC24485:  TRB $FC        ;subtract from Status to set byte 1 & 2
LC24487:  LDA $FA        ;Status byte 3 & 4
LC24489:  TSB $FE        ;add to Status to set byte 3 & 4
LC2448B:  LDA $F6        ;Status to clear byte 3 & 4
LC2448D:  TRB $FE        ;subtract from Status to set byte 3 & 4
LC2448F:  RTS


;Initialize intermediate "status to set" bytes in $F4 - $F7 and
; "status to clear" bytes in $FC - $FF.
; Mark Clear / Freeze to be removed if necessary.)
LC24490:  PHX
LC24491:  SEP #$20       ;Set 8-bit Accumulator
LC24493:  LDA $11A4      ;Special Byte 2
LC24496:  AND #$0C
LC24498:  LSR A
LC24499:  TAX            ;X = 0 if set status, 2 = lift status,
                         ;4 = toggle status
LC2449A:  REP #$20
LC2449C:  STZ $FC        ;Clear status to clear and set bytes
LC2449E:  STZ $FE
LC244A0:  STZ $F4
LC244A2:  STZ $F6
LC244A4:  JSR ($44D1,X)  ;prepare status set, lift, or toggle
LC244A7:  LDA $11A2
LC244AA:  LSR A
LC244AB:  BCS LC244BB  ;branch if physical attack
LC244AD:  LDA #$0010
LC244B0:  BIT $F8
LC244B2:  BEQ LC244BB  ;branch if target not vanished
LC244B4:  BIT $11AA
LC244B7:  BNE LC244BB  ;branch if attack causes Clear
LC244B9:  TSB $F4        ;mark Clear status to be cleared
LC244BB:  LDA $11A1
LC244BE:  LSR A
LC244BF:  BCC LC244CF  ;Exit if not element Fire
LC244C1:  LDA #$0200
LC244C4:  BIT $FA
LC244C6:  BEQ LC244CF  ;Exit if target not Frozen
LC244C8:  BIT $11AC
LC244CB:  BNE LC244CF  ;Exit if attack setting Freeze
LC244CD:  TSB $F6        ;mark Freeze status to be cleared
LC244CF:  PLX
LC244D0:  RTS


;Code Pointers

LC244D1: dw $44D7
LC244D3: dw $44EA
LC244D5: dw $44F9

;Spell wants to set status
LC244D7:  LDA $11AA      ;get status bytes 1-2 from spell
LC244DA:  STA $FC        ;store in status to set
LC244DC:  LDA $F8        ;get current status 1-2
LC244DE:  TRB $FC        ;don't try to set anything you already have
LC244E0:  LDA $11AC      ;get status bytes 3-4 from spell
LC244E3:  STA $FE        ;store in status to set
LC244E5:  LDA $FA        ;get current status 3-4
LC244E7:  TRB $FE        ;don't try to set anything you already have
LC244E9:  RTS

;Spell wants to clear status
LC244EA:  LDA $11AA      ;get status bytes 1-2 from spell
LC244ED:  AND $F8        ;current status 1-2
LC244EF:  STA $F4        ;only try to clear statuses you do have
LC244F1:  LDA $11AC      ;get status bytes 3-4 from spell
LC244F4:  AND $FA        ;current status 3-4
LC244F6:  STA $F6        ;only try to clear statuses you do have
LC244F8:  RTS

;Spell wants to toggle status
LC244F9:  JSR $44D7      ;mark spell statuses you don't already have
                         ;to be set
LC244FC:  JMP $44EA      ;and mark the ones you do already have to
                         ;be cleared


;Clear status to set and status to clear bytes

LC244FF:  TDC
LC24500:  STA $3DD4,Y    ;Status to Set bytes 1-2
LC24503:  STA $3DE8,Y    ;Status to Set bytes 3-4
LC24506:  STA $3DFC,Y    ;Status to Clear bytes 1-2
LC24509:  STA $3E10,Y    ;Status to Clear bytes 3-4
LC2450C:  RTS


;Put Status to be Set / Clear into $Fn
; Quasi New Status in $3E60 & $3E74)

LC2450D:  LDA $3DFC,Y
LC24510:  STA $F4        ;Status to Clear bytes 1-2
LC24512:  LDA $3E10,Y
LC24515:  STA $F6        ;Status to Clear bytes 3-4

LC24517:  LDA $3DD4,Y
LC2451A:  AND $331C,Y
LC2451D:  STA $FC        ;Status to Set bytes 1-2, excluding blocked statuses
LC2451F:  LDA $3DE8,Y
LC24522:  AND $3330,Y
LC24525:  STA $FE        ;Status to Set bytes 3-4, excluding blocked statuses

LC24527:  LDA $3EE4,Y    ;Load Status of targets, bytes 1-2
LC2452A:  STA $F8
LC2452C:  AND #$0040     ;If target already had Petrify, set it in Status to Set
LC2452F:  TSB $FC

;Note: I think the above is done in preparation for the special case functions at
; $46B0 and 46D0.  These are called when a status is inflicted, and cause side effects like
; clearing other statuses [provided you're not immune to them], and messing with
; assorted variables.  A classic example is Slow booting out Haste, and vice versa.)

; The above code means that just as Muddled/Mute/Clear/Dark/etc are cleared/prevented when
; Petrify status is first _acquired_, they will also be cleared/prevented as long as Petrify
; is POSSESSED.)

LC24531:  LDA $3EF8,Y    ;Status bytes 3 & 4
LC24534:  STA $FA

;This chunk will:
; If Current HP > 1/8 Max HP and Near Fatal status is currently set, mark Near Fatal
; status to be cleared.
; If Current HP <= 1/8 Max HP and Near Fatal status isn't currently set, mark Near Fatal
; status to be set. )
;++++++
LC24536:  LDA $3C1C,Y    ;Max HP
LC24539:  LSR
LC2453A:  LSR
LC2453B:  LSR            ;Divide by 8
LC2453C:  CMP $3BF4,Y    ;Current HP

LC2453F:  LDA #$0200
LC24542:  BIT $F8
LC24544:  BNE LC2454A    ;Branch if Near Fatal status possessed
LC24546:  BCC LC2454E    ;Branch if Current HP > Max HP / 8
LC24548:  TSB $FC        ;Mark Near Fatal in Status to Set
LC2454A:  BCS LC2454E    ;Branch if Current HP <= Max HP / 8
LC2454C:  TSB $F4        ;Mark Near Fatal in Status to Clear
;++++++

LC2454E:  LDA $FB
LC24550:  BPL LC24566    ;Branch if no Wound in Status to Set
LC24552:  LDA $3E4D,Y
LC24555:  AND #$0002     ;Bit set by Overcast
LC24558:  BEQ LC24566    ;Branch if not set
LC2455A:  ORA $FC        ;Put Zombie in Status to Set
LC2455C:  AND #$FF7F     ;Clear Wound from Status to Set
LC2455F:  STA $FC
LC24561:  LDA #$0100
LC24564:  TSB $F4        ;Set Condemned in Status to Clear

LC24566:  LDA $32DF,Y
LC24569:  BPL LC24584    ;Exit function if attack doesn't hit them.  note
                         ;that targets missed due to the attack not changing
                         ;any statuses or due to special effects checks can
                         ;still count as hit.

LC2456B:  LDA $FC        ;back up Status to Set bytes 1-2
LC2456D:  PHA            ;Put on stack
LC2456E:  LDA $FE        ;back up Status to Set bytes 3-4
LC24570:  PHA            ;Put on stack
LC24571:  JSR $447F      ;Get new status
LC24574:  LDA $FC
LC24576:  STA $3E60,Y    ;save Quasi Status bytes 1 and 2
LC24579:  LDA $FE
LC2457B:  STA $3E74,Y    ;save Quasi Status bytes 3 and 4
;         (These bytes are used for counterattack purposes.  They differ from actual
;          status bytes in that they don't factor in statuses removed as side effects.
;          Also, they don't exclude from removal statuses to which the target is
;          immune.  The result of the former difference is consistency in behavior in
;          non- FC 12 and FC 1C counterattacks.  See C2/4BF4 for more info.  The
;          latter difference means that monsters with permanent Muddled or Berserk can
;          wrongly be regarded as having the status removed.  However, there are no
;          monsters with permanent Muddle, and Brawler, the only one with permanent
;          Berserk, doesn't have a counterattack script anyway.)
LC2457E:  PLA
LC2457F:  STA $FE        ;restore Status to Set bytes 1-2
LC24581:  PLA
LC24582:  STA $FC        ;restore Status to Set bytes 3-4
LC24584:  RTS


;Store new status in character/monster status bytes.
; Clear some statuses if target has Zombie.)

LC24585:  LDA $FC
LC24587:  BIT #$0002
LC2458A:  BEQ LC2458F    ;Branch if not Zombie
LC2458C:  AND #$4DFA     ;Clear Dark and Poison
                         ;Clear Near Fatal, Berserk, Muddled, Sleep
LC2458F:  STA $3EE4,Y    ;Store new status in Bytes 1 and 2
LC24592:  LDA $FE
LC24594:  STA $3EF8,Y    ;Store new status in Bytes 3 and 4
LC24597:  RTS


;If a status in A is possessed or it's set in Status to Set, turn it on
; in Status to Clear)

LC24598:  PHA            ;Put on stack
LC24599:  LDA $F8
LC2459B:  ORA $FC
LC2459D:  AND $01,S
LC2459F:  TSB $F4
LC245A1:  PLA
LC245A2:  RTS


;Zombie - set

LC245A3:  LDA #$0080
LC245A6:  JSR $4598      ;if Death is possessed or set by the spell, mark it to
                         ;be cleared
LC245A9:  JSR $46A9      ;Mark this entity as having died since last
                         ;executing Command 1Fh, "Run Monster Script"
LC245AC:  BRA LC245C1


;Zombie - clear

LC245AE:  JSR $469C      ;If monster, add to list of remaining enemies, and
                         ;remove from list of dead-ish ones
LC245B1:  BRA LC245C1


;Muddle - set

LC245B3:  LDA $3018,Y
LC245B6:  TSB $2F53      ;cause target to be visually flipped
LC245B9:  BRA LC245C1


;Muddle - clear

LC245BB:  LDA $3018,Y
LC245BE:  TRB $2F53      ;cancel visual flipping of target
LC245C1:  PHX
LC245C2:  LDX $3018,Y
LC245C5:  TXA
LC245C6:  TSB $3A4A      ;set "Entity's Zombie or Muddled changed since last
                         ;command or ready stance entering"
LC245C9:  PLX
LC245CA:  RTS


;Clear - set

LC245CB:  PHX
LC245CC:  LDX $3019,Y
LC245CF:  TXA
LC245D0:  TSB $2F44
LC245D3:  PLX
LC245D4:  RTS


;Clear - clear
;is there an echo in here?!  who's on first?)

LC245D5:  PHX
LC245D6:  LDX $3019,Y
LC245D9:  TXA
LC245DA:  TRB $2F44
LC245DD:  PLX
LC245DE:  RTS


;Imp - set or clear

LC245DF:  LDA #$0088
LC245E2:  JSR $464C
LC245E5:  CPY #$08       ;Rage - clear   enters here
LC245E7:  BCS LC245F1    ;Exit function if monster
LC245E9:  PHX
LC245EA:  TYA
LC245EB:  LSR
LC245EC:  TAX
LC245ED:  INC $2F30,X    ;flag character's properties to be recalculated from
                         ;his/her equipment at end of turn.
LC245F0:  PLX
LC245F1:  RTS


;Petrify - clear and Death - clear

LC245F2:  JSR $469C      ;If monster, add to list of remaining enemies, and
                         ;remove from list of dead-ish ones
LC245F5:  LDA #$4000
LC245F8:  JSR $4656      ;consolidate: "JSR $4653"
LC245FB:  LDA #$0040
LC245FE:  BRA LC2464C


;Death - set
LC24600:  LDA #$0140
LC24603:  JSR $4598      ;if Petrify or Condemned are possessed or set by the spell,
                         ;mark them to be cleared
LC24606:  LDA #$0080
LC24609:  TRB $F4        ;remove Death from statuses to be cleared

;Petrify - set
LC2460B:  JSR $46A9      ;Mark this entity as having died since last
                         ;executing Command 1Fh, "Run Monster Script"
LC2460E:  LDA #$FE15
LC24611:  JSR $4598      ;if Dark, Poison, Clear, Near Fatal, Image, Mute, Berserk,
                         ;Muddled, Seizure, or Sleep are possessed by the target or
                         ;set by the spell, mark them to be cleared
LC24614:  LDA $FA
LC24616:  ORA $FE
LC24618:  AND #$9BFF     ;if Dance, Regen, Slow, Haste, Stop, Shell, Safe, Reflect,
                         ;Rage, Freeze, Morph, Spell Chant, or Float are possessed
                         ;by the target or set by the spell, mark them to be cleared
LC2461B:  TSB $F6
LC2461D:  LDA $3E4C,Y
LC24620:  AND #$BFFF
LC24623:  STA $3E4C,Y    ;clear HP Leak quasi-status that was set by Phantasm
LC24626:  LDA $3AA0,Y
LC24629:  AND #$FF7F
LC2462C:  STA $3AA0,Y
LC2462F:  LDA #$0040
LC24632:  BRA LC2464C


;Sleep - set

LC24634:  PHP
LC24635:  SEP #$20       ;Set 8-bit A
LC24637:  LDA #$12
LC24639:  STA $3CF9,Y    ;Time until Sleep wears off
LC2463C:  PLP
LC2463D:  BRA LC24626


;Condemned - set

LC2463F:  LDA #$0020
LC24642:  BRA LC2464C
LC24644:  LDA #$0010     ;Condemned - clear  enters here
LC24647:  BRA LC2464C
LC24649:  LDA #$0008     ;Mute - set or clear  enter here
LC2464C:  ORA $3204,Y
LC2464F:  STA $3204,Y
LC24652:  RTS


;Sleep - clear

LC24653:  LDA #$4000
LC24656:  ORA $3AA0,Y
LC24659:  STA $3AA0,Y    ;flag entity's ATB gauge to be reset?
LC2465C:  RTS


;Seizure - set

LC2465D:  LDA #$0002
LC24660:  TSB $F6        ;mark Regen to be cleared
LC24662:  RTS


;Regen - set

LC24663:  LDA #$4000
LC24666:  TSB $F4        ;mark Seizure to be cleared
LC24668:  RTS


;Slow - set

LC24669:  LDA #$0008
LC2466C:  BRA LC24671    ;mark Haste to be cleared


;Haste - set

LC2466E:  LDA #$0004     ;mark Slow to be cleared
LC24671:  TSB $F6
LC24673:  LDA #$0004     ;Haste - clear  and  Slow - clear  enter here
LC24676:  BRA LC2464C


;Morph - set or clear

LC24678:  LDA #$0002
LC2467B:  BRA LC2464C


;Stop - set

LC2467D:  PHP
LC2467E:  SEP #$20       ;Set 8-bit A
LC24680:  LDA #$12
LC24682:  STA $3AF1,Y    ;Time until Stop wears off
LC24685:  PLP
LC24686:  RTS


;Reflect - set

LC24687:  PHP
LC24688:  SEP #$20       ;Set 8-bit A
LC2468A:  LDA #$1A
LC2468C:  STA $3F0C,Y    ;Time until Reflect wears off, though permanency
                         ;can prevent its removal
LC2468F:  PLP
LC24690:  RTS


;Freeze - set

LC24691:  PHP
LC24692:  SEP #$20       ;Set 8-bit A
LC24694:  LDA #$22
LC24696:  STA $3F0D,Y    ;Time until Freeze wears off
LC24699:  PLP
LC2469A:  RTS


;Do nothing:
; Dark, Poison, M-Tek,
; Near Fatal, Image, Berserk,
; Dance, Shell, Safe,
; Rage [set only], Life 3, Spell, Hide, Dog Block, Float)

LC2469B:  RTS


;If monster, add to list of remaining enemies, and remove from list of dead-ish ones

LC2469C:  PHX
LC2469D:  LDX $3019,Y    ;get bit identifying monster
LC246A0:  TXA
LC246A1:  TSB $2F2F      ;add to bitfield of remaining enemies?
LC246A4:  TRB $3A3A      ;remove from bitfield of dead-ish monsters
LC246A7:  PLX
LC246A8:  RTS


LC246A9:  LDA $3018,Y
LC246AC:  TSB $3A56      ;Mark this entity as having died since last
                         ;executing Command 1Fh, "Run Monster Script",
                         ;counterattack variant
LC246AF:  RTS


;Not actual code - data (table of pointers to code, for changing status

;Set status pointers ("side effects" to perform upon setting of a status:

LC246B0: dw $469B ;(Dark)        (Jumps to RTS)
LC246B2: dw $45A3 ;(Zombie)
LC246B4: dw $469B ;(Poison)      (Jumps to RTS)
LC246B6: dw $469B ;(M-Tek)       (Jumps to RTS)
LC246B8: dw $45CB ;(Clear)
LC246BA: dw $45DF ;(Imp)
LC246BC: dw $460B ;(Petrify)
LC246BE: dw $4600 ;(Death)
LC246C0: dw $463F ;(Condemned)
LC246C2: dw $469B ;(Near Fatal)  (Jumps to RTS)
LC246C4: dw $469B ;(Image)       (Jumps to RTS)
LC246C6: dw $4649 ;(Mute)
LC246C8: dw $469B ;(Berserk)     (Jumps to RTS)
LC246CA: dw $45B3 ;(Muddle)
LC246CC: dw $465D ;(Seizure)
LC246CE: dw $4634 ;(Sleep)
LC246D0: dw $469B ;(Dance)       (Jumps to RTS)
LC246D2: dw $4663 ;(Regen)
LC246D4: dw $4669 ;(Slow)
LC246D6: dw $466E ;(Haste)
LC246D8: dw $467D ;(Stop)
LC246DA: dw $469B ;(Shell)       (Jumps to RTS)
LC246DC: dw $469B ;(Safe)        (Jumps to RTS)
LC246DE: dw $4687 ;(Reflect)
LC246E0: dw $469B ;(Rage)        (Jumps to RTS)
LC246E2: dw $4691 ;(Freeze)
LC246E4: dw $469B ;(Life 3)      (Jumps to RTS)
LC246E6: dw $4678 ;(Morph)
LC246E8: dw $469B ;(Spell)       (Jumps to RTS)
LC246EA: dw $469B ;(Hide)        (Jumps to RTS)
LC246EC: dw $469B ;(Dog Block)   (Jumps to RTS)
LC246EE: dw $469B ;(Float)       (Jumps to RTS)


;Clear status pointers ("side effects" to perform upon clearing of a status:

LC246F0: dw $469B ;(Dark)        (Jumps to RTS)
LC246F2: dw $45AE ;(Zombie)
LC246F4: dw $469B ;(Poison)      (Jumps to RTS)
LC246F6: dw $469B ;(M-Tek)       (Jumps to RTS)
LC246F8: dw $45D5 ;(Clear)
LC246FA: dw $45DF ;(Imp)
LC246FC: dw $45F2 ;(Petrify)
LC246FE: dw $45F2 ;(Death)
LC24700: dw $4644 ;(Condemned)
LC24702: dw $469B ;(Near Fatal)  (Jumps to RTS)
LC24704: dw $469B ;(Image)       (Jumps to RTS)
LC24706: dw $4649 ;(Mute)
LC24708: dw $469B ;(Berserk)     (Jumps to RTS)
LC2470A: dw $45BB ;(Muddle)
LC2470C: dw $469B ;(Seizure)     (Jumps to RTS)
LC2470E: dw $4653 ;(Sleep)
LC24710: dw $469B ;(Dance)       (Jumps to RTS)
LC24712: dw $469B ;(Regen)       (Jumps to RTS)
LC24714: dw $4673 ;(Slow)
LC24716: dw $4673 ;(Haste)
LC24718: dw $469B ;(Stop)        (Jumps to RTS)
LC2471A: dw $469B ;(Shell)       (Jumps to RTS)
LC2471C: dw $469B ;(Safe)        (Jumps to RTS)
LC2471E: dw $469B ;(Reflect)     (Jumps to RTS)
LC24720: dw $45E5 ;(Rage)
LC24722: dw $469B ;(Freeze)      (Jumps to RTS)
LC24724: dw $469B ;(Life 3)      (Jumps to RTS)
LC24726: dw $4678 ;(Morph)
LC24728: dw $469B ;(Spell)       (Jumps to RTS)
LC2472A: dw $469B ;(Hide)        (Jumps to RTS)
LC2472C: dw $469B ;(Dog Block)   (Jumps to RTS)
LC2472E: dw $469B ;(Float)       (Jumps to RTS)


;??? Function (Called from other bank

LC24730:  PHX
LC24731:  PHY
LC24732:  PHB
LC24733:  PHP
LC24734:  SEP #$30
LC24736:  PHA            ;Put on stack
LC24737:  LDA #$7E
LC24739:  PHA            ;Put on stack
LC2473A:  PLB            ;set Data Bank register to 7E
LC2473B:  PLA
LC2473C:  CLC
LC2473D:  JSR ($474B,X)
LC24740:  JSR $4490      ;Initialize intermediate "status to set" bytes in
                         ;$F4 - $F7 and "status to clear" bytes in $FC - $FF.
                         ;Mark Clear / Freeze to be removed if necessary.
LC24743:  JSR $447F      ;get new status
LC24746:  PLP
LC24747:  PLB
LC24748:  PLY
LC24749:  PLX
LC2474A:  RTL


;Pointers

LC2474B: dw $474F
LC2474D: dw $4778


LC2474F:  JSR $2966      ;load spell data
LC24752:  LDA $11A4
LC24755:  BPL LC24775    ;Branch if damage/healing not based on HP or MP
LC24757:  LDA $11A6      ;Spell Power
LC2475A:  STA $E8
LC2475C:  REP #$30
LC2475E:  LDA $11B2      ;get maximum HP or MP
LC24761:  JSR $283C      ;apply equipment/relic boosts to it
LC24764:  CMP #$2710
LC24767:  BCC LC2476C    ;branch if not 10,000 or higher
LC24769:  LDA #$270F     ;set to 9999
LC2476C:  SEP #$10       ;set 16-bit X and Y
LC2476E:  JSR $0DCB      ;A = (Spell Power * HP or MP) / 16
LC24771:  STA $11B0      ;Damage
LC24774:  RTS

LC24775:  JMP $2B69      ;Magical Damage Calculation


LC24778:  JSR $2A37      ;item usage setup
LC2477B:  LDA #$01
LC2477D:  TSB $11A2      ;Sets physical attack
LC24780:  RTS


;Multiplication Function
;Multiplies low bit of A * high bit of A.  Stores result in 16-bit A.

LC24781:  PHP
LC24782:  REP #$20
LC24784:  STA $004202
LC24788:  NOP
LC24789:  NOP
LC2478A:  NOP
LC2478B:  NOP
LC2478C:  LDA $004216
LC24790:  PLP
LC24791:  RTS


;Division Function
;Divides 16-bit A / 8-bit X
;Stores answer in 16-bit A.  Stores remainder in 8-bit X.

LC24792:  PHY
LC24793:  PHP
LC24794:  REP #$20
LC24796:  STA $004204
LC2479A:  SEP #$30
LC2479C:  TXA
LC2479D:  STA $004206
LC247A1:  NOP
LC247A2:  NOP
LC247A3:  NOP
LC247A4:  NOP
LC247A5:  NOP
LC247A6:  NOP
LC247A7:  NOP
LC247A8:  NOP
LC247A9:  LDA $004216
LC247AD:  TAX
LC247AE:  REP #$20
LC247B0:  LDA $004214
LC247B4:  PLP
LC247B5:  PLY
LC247B6:  RTS


;Multiplication Function 2
;Results:
;16-bit A = (8-bit $E8 * 16-bit A) / 256
;24-bit $E8 = 3 byte (8-bit $E8 * 16-bit A)
;16-bit $EC = 8-bit $E8 * high byte of A

LC247B7:  PHP
LC247B8:  SEP #$20
LC247BA:  STZ $EA
LC247BC:  STA $E9
LC247BE:  LDA $E8
LC247C0:  JSR $4781
LC247C3:  REP #$21
LC247C5:  STA $EC
LC247C7:  LDA $E8
LC247C9:  JSR $4781
LC247CC:  STA $E8
LC247CE:  LDA $EC
LC247D0:  ADC $E9
LC247D2:  STA $E9
LC247D4:  PLP
LC247D5:  RTS


;Multiplies A (1 byte by * 1.5

LC247D6:  PHA            ;Put on stack
LC247D7:  LSR
LC247D8:  CLC
LC247D9:  ADC $01,S
LC247DB:  BCC LC247DF
LC247DD:  LDA #$FF
LC247DF:  STA $01,S
LC247E1:  PLA
LC247E2:  RTS


;Remove character in X from all parties

LC247E3:  PHX
LC247E4:  LDA $3ED9,X    ;get 0-15 roster position of this party member
LC247E7:  TAX
LC247E8:  STZ $1850,X    ;null out their party-related roster information
                         ;[i.e. which party, which slot in party, row,
                         ;main menu presence?, and leader flag]
LC247EB:  PLX
LC247EC:  RTS


LC247ED:  LDA $3EE0
LC247F0:  BEQ LC247FB    ;branch if in 4-tier final multi-battle
LC247F2:  LDA $3A6E      ;Method used to end combat?
LC247F5:  BEQ LC247FB    ;Branch if no special end?
LC247F7:  TAX
LC247F8:  JMP ($48F5,X)


LC247FB:  LDA $1DD1      ;$1DD1 = $3EBC
LC247FE:  AND #$20
LC24800:  BEQ LC24807
LC24802:  TSB $3EBC
LC24805:  BRA LC24820
LC24807:  LDA $3A95      ;did monster script Command F5 nn 04 prohibit checking
                         ;for combat end, without being overridden since?
LC2480A:  BNE LC247EC    ;Exit if so
LC2480C:  LDA $3A74      ;list of alive and present characters
LC2480F:  BNE LC24833    ;branch if at least one
LC24811:  LDA $3A8A
LC24814:  BEQ LC24822    ;branch if no characters engulfed
LC24816:  CMP $3A8D      ;compare Engulfed characters to list of valid characters
                         ;at battle start
LC24819:  BNE LC24822    ;branch if the full list wasn't Engulfed
LC2481B:  LDA #$80
LC2481D:  TSB $3EBC      ;set event bit indicating battle ended with full party
                         ;Engulfed
LC24820:  BRA LC248A1
LC24822:  LDA $3A39
LC24825:  BNE LC24897    ;branch if 1 or more characters escaped
LC24827:  LDA $3A97      ;if we reached here, party lost the battle
LC2482A:  BNE LC2482E    ;branch if in Colosseum
LC2482C:  LDA #$29       ;tell function call below party was annihilated
LC2482E:  JSR $5FCA      ;handle battle ending in loss
LC24831:  BRA LC2488F
LC24833:  LDA $3A77      ;Number of monsters left in combat
LC24836:  BNE LC247EC    ;Exit if 1 or more monsters still alive
LC24838:  LDA $3EE0
LC2483B:  BNE LC24840    ;branch if not in final 4-tier battle
LC2483D:  JSR $4A76      ;if currently one of first 3 tiers, take certain steps for
                         ;transition, and don't return to this calling function
LC24840:  LDX $300B      ;Which character is Gau
LC24843:  BMI LC24861    ;branch if Gau not in party.  note that "in party" can
                         ;mean Gau's actively in the party, or that he's Leapt on
                         ;the Veldt, you're fighting on the Veldt, and there's a
                         ;free spot in your party for him to return.
LC24845:  LDA #$01
LC24847:  TRB $11E4      ;mark Gau as not available to return from Veldt leap
LC2484A:  BEQ LC24861    ;branch if that was already the case
LC2484C:  JSR $4B5A      ;random: 0 to 255
LC2484F:  CMP #$A0
LC24851:  BCS LC24861    ;3 in 8 chance branch
LC24853:  LDA $3EBD
LC24856:  BIT #$02       ;have you already enlisted Gau the first time?
LC24858:  BNE LC248CE    ;branch if so
LC2485A:  LDA $3A76      ;Number of present and living characters in party
LC2485D:  CMP #$02
LC2485F:  BCS LC248CE    ;Branch if 2 or more characters in party -- this ensures
                         ;that Sabin and Cyan are both *alive* to see the original
                         ;Gau hijinx
LC24861:  LDX $3003      ;Which character is Shadow
LC24864:  BMI LC2488C    ;Branch if Shadow not in party
LC24866:  JSR $4B5A      ;random #: 0 to 255
LC24869:  CMP #$10
LC2486B:  BCS LC2488C    ;15 in 16 chance branch
LC2486D:  LDA $201F      ;get encounter type:  0 = front, 1 = back,
                         ;2 = pincer, 3 = side
LC24870:  BNE LC2488C    ;if not a front attack, branch
LC24872:  LDA $3A76      ;Number of present and living characters in party
LC24875:  CMP #$02
LC24877:  BCC LC2488C    ;Branch if less than 2 characters in party
LC24879:  LDA $3EE4,X
LC2487C:  BIT #$C2       ;Check for Dead, Zombie, or Petrify
LC2487E:  BNE LC2488C    ;Branch if any set on Shadow
LC24880:  LDA #$08
LC24882:  BIT $3EBD      ;is Shadow randomly leaving disabled at this point in
                         ;game?
LC24885:  BNE LC2488C    ;branch if so
LC24887:  BIT $1EDE      ;Which characters are enlisted
LC2488A:  BNE LC248A6    ;Branch if Shadow enlisted
LC2488C:  JSR $5D57
LC2488F:  JSR $4936
LC24892:  PLA
LC24893:  PLA            ;remove caller address from stack
LC24894:  JMP $00C5      ;this lets us return somewhere other than C2/0084


;Warp, also used when escaped characters
LC24897:  LDA #$FF
LC24899:  STA $0205      ;null out Colosseum item wagered, so we're not billed
LC2489C:  LDA #$10
LC2489E:  TSB $3EBC      ;set event bit indicating battle ended due to Warp or
                         ;with at least 1 character escaped
;   FB 02-Usual monster script way to end a battle  enters here)
LC248A1:  JSR $4903
LC248A4:  BRA LC2488F


;Shadow randomly leaves after battle

LC248A6:  TRB $1EDE      ;un-enlist Shadow
LC248A9:  JSR $47E3      ;remove him from all parties
LC248AC:  REP #$10
LC248AE:  LDY $3010,X    ;get offset to character info block
LC248B1:  LDA #$FF
LC248B3:  STA $161E,Y    ;clear his equipped Esper
LC248B6:  SEP #$10
LC248B8:  LDA #$FE
LC248BA:  JSR $0792      ;clear Bit 0 of $3AA0,X , indicating absence
                         ;from battle
LC248BD:  LDA #$02
LC248BF:  TSB $2F49      ;turn on "No Winning Stand" aka
                         ;"No victory dance" in extra formation
                         ;data.  this bit is checked at C1/0124.
LC248C2:  LDX #$0B       ;Attack
LC248C4:  PLA
LC248C5:  PLA            ;remove caller address from stack
LC248C6:  LDA #$23       ;Command is Battle Event, and Attack in X indicates
                         ;it's number 11, Shadow leaving after a battle.
                         ;[or number 27 if Gau code enters at C2/48C4.]
LC248C8:  JSR $4E91      ;queue it, in global Special Action queue
LC248CB:  JMP $0019      ;return to somewhere other than C2/0084, by
                         ;branching to start of main battle loop


;Gau arrives after Veldt battle

LC248CE:  LDA $3018,X
LC248D1:  TSB $2F4E      ;mark character to enter the battlefield
LC248D4:  TSB $3A40      ;mark Gau as a "character acting as enemy" target
LC248D7:  LDA #$04
LC248D9:  TSB $3A46      ;tell main battle loop we're about to have Gau return
                         ;at the end of a Veldt battle
LC248DC:  LDX #$1B       ;Attack
LC248DE:  BRA LC248C4    ;go queue Battle Event number 27, Gau arriving after
                         ;a Veldt battle


;Gau leapt
LC248E0:  LDX $300B      ;which character is Gau
LC248E3:  JSR $47E3      ;remove him from all parties
LC248E6:  LDA #$08
LC248E8:  TRB $1EDF      ;un-enlist Gau
;   FB 09-Used by returning Gau when he joins the party , enters here)
LC248EB:  JSR $4A07      ;Add rages learned in battle
LC248EE:  BRA LC2488F


;Banon fell
LC248F0:  LDA #$36
LC248F2:  JSR $5FCA      ;handle battle ending in loss
LC248F5:  BRA LC2488F


;<>Pointers for Special Combat Endings
;Code pointers

LC248F7: dw $4897    ;(02-Warp)
LC248F9: dw $48E0    ;(04-Gau leapt)
LC248FB: dw $48F0    ;(06-Banon fell)
LC248FD: dw $48A1    ;(08-FB 02-Usual monster script way to end a battle)
LC248FF: dw $48EB    ;(0A-FB 09-Used by returning Gau when he joins the
                     ; party
LC24901: dw $4A22    ;(0C-Final battle tier transition)


LC24903:  JSR $0B36      ;Establish new value for Morph supply based on its
                         ;previous value and the current Morph timer
LC24906:  LDX #$06
LC24908:  STZ $3B04,X    ;Zero this entity's Morph gauge
LC2490B:  TXA
LC2490C:  LSR
LC2490D:  STA $10
LC2490F:  LDA #$03
LC24911:  JSR $6411
LC24914:  DEX
LC24915:  DEX
LC24916:  BPL LC24908
LC24918:  LDA #$80
LC2491A:  TSB $B1
LC2491C:  LDX #$20
LC2491E:  LDA #$01
LC24920:  JSR $6411
LC24923:  DEX
LC24924:  BNE LC2491E
LC24926:  LDA #$0F
LC24928:  TSB $3A8C      ;mark all characters to have their applicable items
                         ;added to inventory.  in particular, this will
                         ;handle an item they tried to use (the game depletes
                         ;it on issuing the command, but were killed before
                         ;before they could actually execute the command and
                         ;use it.
LC2492B:  JSR $62C7      ;add items [back] to a $602D-$6031 buffer
LC2492E:  LDA #$0A
LC24930:  JSR $6411      ;for any $602D-$6031 buffer entries that C2/62C7
                         ;filled, now actually copy them to Item menu
LC24933:  JMP $2095      ;Recalculate applicable characters' properties from
                         ;their current equipment and relics


LC24936:  LDX #$06
LC24938:  LDA $3ED8,X    ;get which character this is
LC2493B:  BMI LC2497B    ;if it's undefined, skip it
LC2493D:  CMP #$10
LC2493F:  BEQ LC24945    ;branch if it's 1st ghost
LC24941:  CMP #$11
LC24943:  BNE LC2494C    ;branch if it's not 2nd ghost
LC24945:  LDA $3EE4,X    ;Check for Dead, Zombie, or Petrify
LC24948:  BIT #$C2
LC2494A:  BNE LC24954    ;branch if one or more ^
LC2494C:  LDA $3018,X
LC2494F:  BIT $3A88      ;was this character flagged to be removed from
                         ;party? [by Possessing or getting hit by
                         ;BabaBreath]
LC24952:  BEQ LC24957    ;branch if not
LC24954:  JSR $47E3      ;remove character from all parties
LC24957:  LDA $3EF9,X    ;in-battle status byte 4
LC2495A:  AND #$C0       ;only keep Dog Block and Float after battle
LC2495C:  XBA
LC2495D:  LDA $3EE4,X    ;in-battle status byte 1
LC24960:  REP #$30       ;Set 16-bit Accumulator, 16-bit X and Y
LC24962:  LDY $3010,X    ;get offset to character info block
LC24965:  STA $1614,Y    ;save in-battle status bytes 1 and 4 to our
                         ;two out-of-battle status bytes
LC24968:  LDA $3BF4,X
LC2496B:  STA $1609,Y    ;save current HP in out-of-battle stat
LC2496E:  LDA $3C30,X
LC24971:  BEQ LC24979    ;Branch if max MP is zero
LC24973:  LDA $3C08,X
LC24976:  STA $160D,Y    ;otherwise, save current MP in out-of-battle stat
LC24979:  SEP #$30
LC2497B:  DEX
LC2497C:  DEX
LC2497D:  BPL LC24938    ;loop for all 4 party members
LC2497F:  REP #$10
LC24981:  LDX #$00FF
LC24984:  LDY #$04FB
LC24987:  LDA $2686,Y
LC2498A:  STA $1869,X    ;copy item ID from Item menu to persistent
                         ;list
LC2498D:  INC
LC2498E:  BEQ LC24993    ;if item is #255 [Null], store 0 as quantity
LC24990:  LDA $2689,Y
LC24993:  STA $1969,X    ;copy quantity from Item menu to persistent
                         ;list
LC24996:  DEY
LC24997:  DEY
LC24998:  DEY
LC24999:  DEY
LC2499A:  DEY
LC2499B:  DEX
LC2499C:  BPL LC24987    ;iterate for all 256 Item slots
LC2499E:  LDA $3A97
LC249A1:  BEQ LC249C4    ;branch if not Colosseum brawl
LC249A3:  LDA $0205      ;item wagered
LC249A6:  CMP #$FF
LC249A8:  BEQ LC249C4    ;branch if null
LC249AA:  LDX #$00FF
LC249AD:  CMP $1869,X    ;is item wagered in this slot?
LC249B0:  BNE LC249C1    ;branch if not
LC249B2:  DEC $1969,X    ;if it was, decrement the item's count as
                         ;a Colosseum fee
LC249B5:  BEQ LC249B9    ;if there's none of the item left, empty
                         ;out its slot
LC249B7:  BPL LC249C1    ;if there's a nonzero and positive quantity
                         ;of the item, don't empty out its slot
LC249B9:  LDA #$FF
LC249BB:  STA $1869,X    ;store Empty item
LC249BE:  STZ $1969,X    ;with a quantity of 0
LC249C1:  DEX            ;move to next lowest item slot
LC249C2:  BPL LC249AD    ;loop for all 256 item slots
LC249C4:  SEP #$10
LC249C6:  LDX $33FA      ;Which monster is Doom Gaze
LC249C9:  BMI LC249D5    ;Branch if Doom Gaze not in battle [FFh]
LC249CB:  REP #$20       ;Set 16-bit Accumulator
LC249CD:  LDA $3BF4,X    ;Monster's HP
LC249D0:  STA $3EBE      ;Set Doom Gaze's HP to monster's HP
LC249D3:  SEP #$20       ;Set 8-bit A
LC249D5:  LDX #$13
LC249D7:  LDA $3EB4,X    ;copy in-battle event bytes
LC249DA:  STA $1DC9,X    ; back into normal out-of-battle event bytes
LC249DD:  DEX
LC249DE:  BPL LC249D7    ;iterate 20 times
LC249E0:  LDA $2F4B
LC249E3:  BIT #$02
LC249E5:  BNE LC24A06    ;exit if this formation has "Don't appear on Veldt"
                         ;property
LC249E7:  LDX #$0A
LC249E9:  LDA $2002,X    ;Get MSB of monster #
LC249EC:  BNE LC24A02    ;If they're a boss or enemy slot is unoccupied, don't
                         ;mark formation as found, but check next monster
LC249EE:  LDA $3ED5
LC249F1:  LSR            ;Move bit 8 of formation # into Carry and out of A
LC249F2:  BNE LC24A06    ;If any of bits 9-15 were set, the formation # is
                         ;over 511.  skip it.
LC249F4:  LDA $3ED4      ;Get bits 0-7 of First Battle Formation
LC249F7:  JSR $5217      ;X = formation DIV 8, A = 2^(formation MOD 8)
LC249FA:  ORA $1DDD,X
LC249FD:  STA $1DDD,X    ;Update structure of encountered groups for Veldt
LC24A00:  BRA LC24A06    ;Once Veldt structure is updated once, we can exit
LC24A02:  DEX
LC24A03:  DEX
LC24A04:  BPL LC249E9    ;Move to next enemy and loop
LC24A06:  RTS


;Add rages learned in battle

LC24A07:  LDX #$0A
LC24A09:  LDA $2002,X
LC24A0C:  BNE LC24A1D    ;Branch if monster # >= 256 , or if enemy slot is
                         ;unoccupied
LC24A0E:  PHX
LC24A0F:  CLC
LC24A10:  LDA $2001,X    ;Low byte of monster #
LC24A13:  JSR $5217      ;X = monster # DIV 8, A = 2^(monster # MOD 8)
LC24A16:  ORA $1D2C,X
LC24A19:  STA $1D2C,X    ;Add rage to list of known ones
LC24A1C:  PLX
LC24A1D:  DEX
LC24A1E:  DEX
LC24A1F:  BPL LC24A09    ;Check for all monsters
LC24A21:  RTS


;For final battle tier transitions, do some end-battle code, and clean out
; Wounded/Petrified/Zombied and Air Anchored characters)

LC24A22:  JSR $0267
LC24A25:  JSR $4903
LC24A28:  JSR $4936
LC24A2B:  LDX #$12
LC24A2D:  CPX #$08
LC24A2F:  BCS LC24A65    ;branch if monster
LC24A31:  LDA $3AA0,X
LC24A34:  LSR
LC24A35:  BCC LC24A54    ;branch if entity not present in battle
LC24A37:  LDA $3EE4,X
LC24A3A:  BIT #$C2       ;Check for Dead, Zombie, or Petrify
LC24A3C:  BNE LC24A54    ;branch if some possessed
LC24A3E:  LDA $3205,X
LC24A41:  BIT #$04
LC24A43:  BEQ LC24A54    ;branch if under Air Anchor effect
LC24A45:  REP #$20       ;set 16-bit A
LC24A47:  LDA $3EF8,X    ;status bytes 3 and 4
LC24A4A:  AND #$EEFE
LC24A4D:  STA $3EF8,X    ;clear Dance, Rage, and Spell Chant statuses
LC24A50:  SEP #$20       ;set 8-bit A
LC24A52:  BRA LC24A68
LC24A54:  LDA #$FF
LC24A56:  STA $3ED8,X    ;indicate null for "which character this is"
LC24A59:  LDA $3018,X
LC24A5C:  TRB $3F2C      ;clear entity from jumpers
LC24A5F:  TRB $3F2E      ;make them eligible to use an Esper again
LC24A62:  TRB $3F2F      ;make them eligible to use a Desperation Attack
                         ;again
LC24A65:  JSR $4A9E      ;Clear all statuses
LC24A68:  DEX
LC24A69:  DEX
LC24A6A:  BPL LC24A2D    ;loop for all onscreen entities
LC24A6C:  LDA #$0C
LC24A6E:  JSR $6411
LC24A71:  PLA
LC24A72:  PLA            ;clear caller address from stack
LC24A73:  JMP $0016      ;do start of battle initialization function, then
                         ;proceed with main battle loop


;If one of first 3 tiers of final 4-tier multi-battle, take certain steps for
; transition, and don't return to caller)

LC24A76:  REP #$20
LC24A78:  LDX #$04
LC24A7A:  LDA $C24AAB,X
LC24A7E:  CMP $11E0      ;is Battle formation one of the first 3 tiers of
                         ;the final 4-tier multi-battle?
LC24A81:  BNE LC24A97    ;branch and check another if no match
LC24A83:  LDA $C24AAD,X
LC24A87:  STA $11E0      ;update Battle formation to the next one of the
                         ;tiers
LC24A8A:  SEP #$20
LC24A8C:  LDA $C24AB3,X  ;holds some transition animation ID, and indicates
                         ;one of last 3 tiers of final 4-tier multi-battle
                         ;by being non-FFh
LC24A90:  STA $3EE1
LC24A93:  PLA
LC24A94:  PLA            ;clear caller address from stack
LC24A95:  BRA LC24A22    ;this lets us return somewhere other than C2/4840
                         ;do some end-battle code for tier transition, and
                         ;clean out dead/etc and Air Anchored characters
LC24A97:  DEX
LC24A98:  DEX
LC24A99:  BPL LC24A7A    ;iterate 3 times
LC24A9B:  SEP #$20
LC24A9D:  RTS            ;return normally to caller


;Clears all statuses

LC24A9E:  STZ $3EE4,X    ;Clear Status Byte 1
LC24AA1:  STZ $3EE5,X    ;Clear Status Byte 2
LC24AA4:  STZ $3EF8,X    ;Clear Status Byte 3
LC24AA7:  STZ $3EF9,X    ;Clear Status Byte 4
LC24AAA:  RTS


;Data for changing formations in last battle

LC24AAB: dw $01D7     ;(Short Arm, Long Arm, Face)
LC24AAD: dw $0200     ;(Hit, Tiger, Tools)
LC24AAF: dw $0201     ;(Girl, Sleep)
LC24AB1: dw $0202     ;(Final Kefka)

LC24AB3: dw $9090
LC24AB5: dw $9090
LC24AB7: dw $8F8F


;Update lists and counts of present and/or living characters and monsters

LC24AB9:  REP #$20       ;Set 16-bit Accumulator
LC24ABB:  LDA $2F4C
LC24ABE:  EOR #$FFFF
LC24AC1:  AND $2F4E
LC24AC4:  STA $2F4E      ;entities to add to battlefield = entities to add to
                         ;battlefield - entities to remove from battlefield
LC24AC7:  STA $3A78      ;save it as initial lists of present characters and
                         ;enemies?
LC24ACA:  STZ $3A74      ;clear lists of present and living characters and
                         ;enemies
LC24ACD:  STZ $3A42      ;clear list of present and living characters acting
                         ;as enemies?
LC24AD0:  SEP #$20
LC24AD2:  LDX #$06
LC24AD4:  LDA $3AA0,X
LC24AD7:  LSR            ;Carry = is this entity present?
LC24AD8:  LDA $3018,X    ;get which target this is
LC24ADB:  BIT $2F4C
LC24ADE:  BNE LC24B02    ;branch if target is being removed from battlefield
LC24AE0:  BIT $2F4E
LC24AE3:  BNE LC24AF3    ;branch if target is being added to battlefield
LC24AE5:  BCC LC24B02    ;branch if entity not present
LC24AE7:  TSB $3A78      ;add to list of present characters?
LC24AEA:  XBA
LC24AEB:  LDA $3EE4,X
LC24AEE:  BIT #$C2       ;Zombie, Petrify or death status?
LC24AF0:  BNE LC24B02    ;if any possessed, branch
LC24AF2:  XBA
LC24AF3:  AND $3408      ;always FFh, i believe
LC24AF6:  TSB $3A74      ;add to list of present and living characters
LC24AF9:  AND $3A40      ;only keep set if character acting as an enemy
LC24AFC:  TSB $3A42      ;add to list of present and living characters acting
                         ;as enemies?
LC24AFF:  TRB $3A74      ;remove from list of present and living characters
LC24B02:  DEX
LC24B03:  DEX
LC24B04:  BPL LC24AD4    ;iterate for all 4 characters
LC24B06:  LDX #$0A
LC24B08:  LDA $3AA8,X
LC24B0B:  LSR            ;Carry = is this entity present?
LC24B0C:  LDA $3021,X    ;get which target this is.  aka $3019
LC24B0F:  BIT $2F4D
LC24B12:  BNE LC24B32    ;branch if target is being removed from battlefield
LC24B14:  BIT $2F4F
LC24B17:  BNE LC24B2C    ;branch if target is being added to battlefield
LC24B19:  BCC LC24B32    ;branch if entity not present
LC24B1B:  TSB $3A79      ;add to list of present enemies?
LC24B1E:  BIT $3A3A      ;is it in bitfield of dead-ish monsters?
LC24B21:  BNE LC24B32    ;branch if so
LC24B23:  XBA
LC24B24:  LDA $3EEC,X    ;aka $3EE4
LC24B27:  BIT #$C2       ;Zombie, Petrify or death status?
LC24B29:  BNE LC24B32    ;if any possessed, branch
LC24B2B:  XBA
LC24B2C:  AND $3409      ;starts as bits set for every monster, but can be
                         ;modified by F5 script commands
LC24B2F:  TSB $3A75      ;add to list of present and living enemies
LC24B32:  DEX
LC24B33:  DEX
LC24B34:  BPL LC24B08    ;iterate for all 6 monsters
LC24B36:  PHX
LC24B37:  PHP
LC24B38:  LDA $3A74      ;list of present and living characters
LC24B3B:  JSR $520E
LC24B3E:  STX $3A76      ;Set Number of present and living characters in
                         ;party to number of bits set in $3A74
LC24B41:  LDA $3A75      ;list of present and living enemies
LC24B44:  XBA
LC24B45:  LDA $3A42      ;list of present and living characters acting
                         ;as enemies?
LC24B48:  REP #$20       ;Set 16-bit Accumulator
LC24B4A:  JSR $520E
LC24B4D:  STX $3A77      ;Set Number of monsters left in combat to
                         ;number of bits set in $3A42 & $3A75
LC24B50:  PLP
LC24B51:  PLX
LC24B52:  RTS


;Random Number Generator 1 (0 or 1, carry clear or set

LC24B53:  PHA            ;Put on stack
LC24B54:  JSR $4B5A
LC24B57:  LSR
LC24B58:  PLA
LC24B59:  RTS


;Random Number Generator 2 (0 to 255

LC24B5A:  PHX
LC24B5B:  INC $BE        ;increment RNG index
LC24B5D:  LDX $BE
LC24B5F:  LDA $C0FD00,X  ;RNG Table
LC24B63:  PLX
LC24B64:  RTS


;Random Number Generator 3 (0 to accumulator - 1

LC24B65:  PHX
LC24B66:  PHP
LC24B67:  SEP #$30       ;Set 8-bit A, X, Y
LC24B69:  XBA
LC24B6A:  PHA            ;save top half of A
LC24B6B:  INC $BE        ;increment RNG index
LC24B6D:  LDX $BE
LC24B6F:  LDA $C0FD00,X  ;RNG Table
LC24B73:  JSR $4781      ;16-bit A = (input 8-bit A) * (Random Number Table value)
LC24B76:  PLA            ;restore top half of A
LC24B77:  XBA            ;now bottom half of A =
                         ;(input 8-bit A * Random Table value) / 256
LC24B78:  PLP
LC24B79:  PLX
LC24B7A:  RTS


;Process one or two records from entity's Counterattack [both "Run Monster Script" and the
; actual payload commands, which might be launched from a script] and Periodic Damage/Healing
; [e.g. Regen/Seizure] linked list queue)

LC24B7B:  SEC
LC24B7C:  ROR $3407      ;make $3407 negative.  this defaults to not leaving
                         ;off processing any entity.
LC24B7F:  LDA #$01
LC24B81:  TSB $B1        ;indicate it's an unconventional attack
LC24B83:  PEA $0018      ;will return to C2/0019
LC24B86:  LDA $32CD,X    ;get entry point to entity's counterattack or periodic
                         ;damage/healing linked list queue
LC24B89:  BMI LC24BF3    ;exit if null.  that can happen if:
                         ;simple 1: a monster script ran and didn't perform
                         ; anything; e.g. Command F0h chose an FEh
                         ;simple 2: a monster script ran when this linked list queue
                         ; was otherwise empty, so command it queued added records to
                         ; both this list and $3920 "who" queue.  then this list is
                         ; emptied right before executing the command, without
                         ; adjusting $3A68 to delete the $3920 queue record.
                         ;complex: second-to-last execution of this function
                         ; emptied this list, then a new record was added to that
                         ; [and thus one was added to $3920 queue as well] during
                         ; C2/13D3 call.  then the last execution was done by
                         ; use of $3407, emptying this list without adjusting
                         ; $3A68 to delete the $3920 queue record.
                         ;in any case, with this test as a safeguard and C2/0056
                         ;getting rid of the stranded $3920 record, we're good.
LC24B8B:  ASL
LC24B8C:  TAY
LC24B8D:  JSR $0276      ;Load command, attack, targets, and MP cost from queued
                         ;data.  Some commands become Fight if tried by an Imp.
LC24B90:  CMP #$1F       ;is command "Run Monster Script"?
LC24B92:  BNE LC24B9C    ;branch it not
LC24B94:  JSR $4C54      ;remove current first record from entity's counterattack
                         ;or periodic damage/healing linked list queue, and update
                         ;their entry point accordingly
LC24B97:  JSR $4BF4      ;Run Monster Script, counterattack portion
LC24B9A:  BRA LC24B86    ;go load next record in queue
LC24B9C:  LDA $32CD,X    ;get entry point to queue
LC24B9F:  TAY
LC24BA0:  LDA $3184,Y    ;read pointer/ID of current first record in queue
LC24BA3:  CMP $32CD,X    ;if that field's contents match record's position, it's
                         ;a standalone record, or the last in the linked list
LC24BA6:  BNE LC24BAA    ;branch if not, as there are more records left
LC24BA8:  LDA #$FF
LC24BAA:  STA $32CD,X    ;either make entry point index next record, or null it
LC24BAD:  LDA #$FF
LC24BAF:  STA $3184,Y    ;null current first record in queue
                         ;last 9 instructions could be replaced with "JSR $4C54",
                         ;which Square used right above them.
LC24BB2:  LDA $B5
LC24BB4:  CMP #$1E
LC24BB6:  BCS LC24BD5    ;branch and proceed if command is >= 1Eh.  in this
                         ;context, that's Enemy Roulette, periodic damage/healing,
                         ;and F2, F3, F5, F7, and F8 - FB script commands.
LC24BB8:  CPX #$08
LC24BBA:  BCS LC24BD5    ;branch and proceed if monster
LC24BBC:  LDA $3018,X
LC24BBF:  BIT $3A39      ;has character escaped?
LC24BC2:  BNE LC24BE3    ;branch and skip execution if so
LC24BC4:  BIT $3A40      ;is character acting as enemy?
LC24BC7:  BNE LC24BD5    ;branch and proceed if so
LC24BC9:  LDA $3A77      ;Number of monsters left in combat
LC24BCC:  BEQ LC24BE3    ;branch and skip execution if none
LC24BCE:  LDA $3AA0,X
LC24BD1:  BIT #$50
LC24BD3:  BNE LC24BE3
LC24BD5:  LDA $3204,X
LC24BD8:  ORA #$04
LC24BDA:  STA $3204,X
LC24BDD:  JSR $13D3      ;Character/Monster Takes One Turn
LC24BE0:  JSR $021E      ;Save this command's info in Mimic variables so Gogo
                         ;will be able to Mimic it if he/she tries.
LC24BE3:  LDA $32CD,X    ;get entry point to entity's counterattack or periodic
                         ;damage/healing linked list queue
LC24BE6:  INC
LC24BE7:  BNE LC24BF0    ;branch if it's valid -- which includes anything added
                         ;during C2/13D3 call
LC24BE9:  LDA $B0
LC24BEB:  BMI LC24BF3    ;if we were in middle of processing a conventional
                         ;linked list queue, skip C2/0267
LC24BED:  JMP $0267
LC24BF0:  STX $3407      ;leave off processing entity in X
LC24BF3:  RTS


;Run Monster Script [Command 1Fh], counterattack portion, and handle bookmarking.
; Provided we haven't already done so this batch.)

LC24BF4:  PHP
LC24BF5:  REP #$20       ;Set 16-bit accumulator
LC24BF7:  STZ $3A98      ;start off not prohibiting any script commands
LC24BFA:  LDA $3018,X
LC24BFD:  TRB $33FC      ;indicate that this entity has done Command 1Fh
                         ;this "batch"
LC24C00:  BEQ LC24C52    ;exit if that was already the case
LC24C02:  TRB $3A56      ;clear "entity died since last use of Command 1Fh,
                         ;counterattack variant"
LC24C05:  BNE LC24C28    ;branch if it had been set
LC24C07:  LDA $3403      ;Is Quick's target byte $3404 null [i.e. FFh]?
LC24C0A:  BMI LC24C11    ;branch if so
LC24C0C:  CPX $3404
LC24C0F:  BNE LC24C30    ;branch if current entity is not the one under
                         ;influence of Quick
LC24C11:  LDA $3E60,X    ;Quasi Status after attack, bytes 1-2.
                         ;see C2/450D for more info.
LC24C14:  BIT #$B000
LC24C17:  BNE LC24C30    ;if Sleep, Muddled or Berserk is set, branch
LC24C19:  LDA $3E74,X    ;Quasi Status after attack, bytes 3-4.
                         ;see C2/450D for more info.
;         (An enemy who is Muddled/Berserked/etc won't counterattack (unless their
;          script has the FC 1C command) a non-lethal strike that doesn't outright
;          remove the status.  Using these Quasi Status bytes will uphold that behavior
;          for a lethal strike -- provided the creature isn't countering with FC 12 or
;          FC 1C -- by not being swayed by Wound's side effects of removing
;          Muddled/Berserk/etc status.)
LC24C1C:  BIT #$0210
LC24C1F:  BNE LC24C30    ;if Freeze or Stop is set, branch
LC24C21:  LDA $3394,X
LC24C24:  BPL LC24C30    ;branch if you're Charmed by somebody
LC24C26:  BRA LC24C33
LC24C28:  LDA $3018,X
LC24C2B:  TSB $33FE      ;disable flag indicating that entity was targeted
                         ;in the counter-triggering attack, and by
                         ;somebody/something other than itself
LC24C2E:  BEQ LC24C11    ;if flag was enabled [read: 0], branch and do
                         ;usual status checks.
                         ;if it was already disabled, the counter was
                         ;triggered purely as a "catch-all" due to the entity
                         ;being dead, so limit the allowed script commands.
LC24C30:  DEC $3A98      ;disable most types of script commands.
                         ;the FC 12 and FC 1C commands can override this.
LC24C33:  LDA $3268,X    ;offset of monster's counterattack script
LC24C36:  STA $F0        ;upcoming $1A2F call will start at this position
LC24C38:  LDA $3D20,X    ;counterattack script position after last executed
                         ;FD command.  iow, where we left off.  applicable
                         ;when $3241,X =/= FFh.
LC24C3B:  STA $F2
LC24C3D:  LDA $3241,X    ;index of sub-block in counterattack script where
                         ;we left off if we exited script due to FD command,
                         ;null FFh otherwise.
LC24C40:  STA $F4
LC24C42:  CLC
LC24C43:  JSR $1A2F      ;Process monster's counterattack script, backing up
                         ;targets first
LC24C46:  LDA $F2
LC24C48:  STA $3D20,X    ;save counterattack script position after last
                         ;executed FD command.  iow, where we're leaving
                         ;off.
LC24C4B:  SEP #$20
LC24C4D:  LDA $F5
LC24C4F:  STA $3241,X    ;if we exited script due to FD command, save sub-block
                         ;index of counterattack script where we left off.  if
                         ;we exited due to executing FE command or executing/
                         ;reaching FF command, save null FFh.
LC24C52:  PLP
LC24C53:  RTS


;Remove current first record from entity's counterattack or periodic damage/healing
; linked list queue, and update their entry point accordingly)

LC24C54:  PHX
LC24C55:  INX
LC24C56:  JSR $0301
LC24C59:  PLX
LC24C5A:  RTS


;Prepare Counter attacks (Retort, Interceptor, Black Belt, monster script counter

LC24C5B:  LDX #$12
LC24C5D:  LDA $3AA0,X
LC24C60:  LSR
LC24C61:  BCC LC24CBE    ;skip entity if not present in battle
LC24C63:  LDA $341A      ;did attack have X-Zone/Odin/Snare special effect,
                         ;or Air Anchor special effect?
LC24C66:  BEQ LC24CBE    ;branch and skip counter if so
LC24C68:  STZ $B8
LC24C6A:  STZ $B9        ;assume no external entity hit this one to start
LC24C6C:  LDA $32E0,X    ;Top bit = 1 if hit by this attack. [note that
                         ;targets missed due to the attack not changing any
                         ;statuses or due to special effects checks can
                         ;still count as hit.]
                         ;Bottom seven bits = index of entity who last
                         ;attacked them [which includes spell reflectors].
LC24C6F:  BPL LC24C86    ;Branch if this attack does not target them
LC24C71:  ASL
LC24C72:  STA $EE        ;multiply attacker index by 2 so we can access
                         ;their data
LC24C74:  CPX $EE
LC24C76:  BEQ LC24C86    ;Branch if targeting yourself
LC24C78:  TAY            ;Y = attacker index
LC24C79:  REP #$20       ;Set 16-bit accumulator
LC24C7B:  LDA $3018,Y
LC24C7E:  STA $B8        ;Put attacker in $B8
LC24C80:  LDA $3018,X
LC24C83:  TRB $33FE      ;enable flag indicating that entity was hit by
                         ;this attack, and by somebody/something other
                         ;than itself.
LC24C86:  REP #$20
LC24C88:  LDA $3018,X
LC24C8B:  BIT $3A56      ;has entity died since last executing Command 1Fh,
                         ;"Run Monster Script", counterattack variant?
LC24C8E:  SEP #$20       ;Set 8-bit accumulator
LC24C90:  BNE LC24C9D    ;Branch if so.  this is a "catch-all" to allow
                         ;counters when not normally permitted.
LC24C92:  LDA $B1
LC24C94:  LSR
LC24C95:  BCS LC24CBE    ;Branch if it's a counterattack, periodic
                         ;damage/healing, or a special command like a
                         ;status expiring or an equipment auto-spell.
                         ;iow, No counter if not a normal attack.
LC24C97:  LDA $B8
LC24C99:  ORA $B9
LC24C9B:  BEQ LC24CBE    ;No counter if not target of attack, or if
                         ;targeting yourself
LC24C9D:  LDA $3269,X    ;top byte of offset to monster's
                         ;counterattack script
LC24CA0:  BMI LC24CB1    ;branch if it has no counterattack script
LC24CA2:  LDA $32CD,X    ;get entry point to entity's counterattack or periodic
                         ;damage/healing linked list queue
LC24CA5:  BPL LC24CB1    ;branch if they have one of the above queued
LC24CA7:  LDA #$1F
LC24CA9:  STA $3A7A      ;Set command to #$1F ("Run Monster Script")
LC24CAC:  JSR $4EB2      ;queue it, in entity's counterattack and periodic
                         ;damage/healing queue.  C2/4BF4 [using C2/1A2F] is
                         ;what walks the monster script and decides what
                         ;action(s) to actually perform.
LC24CAF:  BRA LC24CBE
LC24CB1:  CPX #$08
LC24CB3:  BCS LC24CBE    ;Branch if monster
LC24CB5:  LDA $11A2
LC24CB8:  LSR
LC24CB9:  BCC LC24CBE    ;Branch if magical attack
LC24CBB:  JSR $4CC3      ;Consider Retort counter, Dog Block counter,
                         ;or Black Belt counter
LC24CBE:  DEX
LC24CBF:  DEX
LC24CC0:  BPL LC24C5D    ;Check for each character and monster
LC24CC2:  RTS


;Retort

LC24CC3:  LDA $3E4C,X
LC24CC6:  LSR
LC24CC7:  BCC LC24CD6    ;Branch if no retort; check dog block
LC24CC9:  LDA #$07
LC24CCB:  STA $3A7A      ;Store Swdtech in command
LC24CCE:  LDA #$56
LC24CD0:  STA $3A7B      ;Store Retort in attack
LC24CD3:  JMP $4EB2      ;queue it, in entity's counterattack and periodic
                         ;damage/healing queue


;Dog Block

LC24CD6:  LDA $B9
LC24CD8:  BEQ LC24CC2    ;Exit function if attacked by party
LC24CDA:  CPX $3416      ;was this target protected by a Dog block on
                         ;this turn?  [or if it's a multi-strike attack
                         ;and Interceptor status was hacked onto multiple
                         ;characters, then was this target the most
                         ;recently protected on the turn?]
LC24CDD:  BNE LC24CF4    ;if target wasn't protected by a dog block,
                         ;branch to Black Belt
LC24CDF:  JSR $4B5A      ;random: 0 to 255
LC24CE2:  LSR
LC24CE3:  BCC LC24CF4    ;50% chance branch to Black Belt
LC24CE5:  LSR            ;Carry will determine which Interceptor
                         ;counterattack is used: 50% chance of each
LC24CE6:  TDC
LC24CE7:  ADC #$FC
LC24CE9:  STA $3A7B      ;Store Wild Fang or Take Down in attack
LC24CEC:  LDA #$02
LC24CEE:  STA $3A7A      ;Store Magic in command
LC24CF1:  JMP $4EB2      ;queue it, in entity's counterattack and periodic
                         ;damage/healing queue


;Black Belt counter

LC24CF4:  LDA $3018,X
LC24CF7:  BIT $3419      ;was this target damaged [by an attacker other
                         ;than themselves] this turn?  the target's bit
                         ;will be 0 in $3419 if they were.
LC24CFA:  BNE LC24CC2    ;Exit if they weren't
LC24CFC:  LDA $3C58,X
LC24CFF:  BIT #$02       ;Check for Black Belt
LC24D01:  BEQ LC24CC2    ;Exit if no Black Belt
LC24D03:  JSR $4B5A      ;random: 0 to 255
LC24D06:  CMP #$C0
LC24D08:  BCS LC24CC2    ;25% chance of exit
LC24D0A:  TXY
LC24D0B:  PEA $A0CA      ;Death, Petrify, M-Tek, Zombie, Sleep, Muddled
LC24D0E:  PEA $3211      ;Stop, Dance, Freeze, Spell, Hide
LC24D11:  JSR $5864
LC24D14:  BCC LC24CC2    ;Exit if any set
LC24D16:  STZ $3A7A      ;Store Fight in command
LC24D19:  STZ $3A7B
LC24D1C:  JMP $4EB2      ;queue it, in entity's counterattack and periodic
                         ;damage/healing queue


;Handle player-confirmed commands

LC24D1F:  LDY $3A6A      ;confirmed commands pointer: 0, 8, 16, or 24
LC24D22:  LDA $2BAE,Y    ;is there a valid, not-yet-processed 0-3
                         ;party member ID in this queue slot?
LC24D25:  BMI LC24D6C    ;Exit function if not
LC24D27:  ASL
LC24D28:  TAX            ;X = 0, 2, 4, 6 party member index
LC24D29:  JSR $4E66      ;put entity in wait queue
LC24D2C:  LDA #$7B
LC24D2E:  JSR $0792      ;clear Bits 2 and 7 of $3AA0,X
LC24D31:  LDA #$FF
LC24D33:  STA $2BAE,Y    ;null party member ID, as we're processing it
LC24D36:  TYA
LC24D37:  ADC #$08       ;advance confirmed commands pointer to next
                         ;position
LC24D39:  AND #$18       ;wrap to 0 if exceeds 24
LC24D3B:  STA $3A6A
LC24D3E:  JSR $4D6D      ;load targets of [first] confirmed command
LC24D41:  LDA $2BB0,Y    ;get party member's [first] confirmed attack/
                         ;subcommand ID
LC24D44:  XBA
LC24D45:  LDA $2BAF,Y    ;get party member's [first] confirmed command ID
LC24D48:  JSR $4D89      ;Perform various setup for the command.
                         ;note that command in bottom of A holds Magic [02h]
                         ;if command was X-Magic [17h].
LC24D4B:  JSR $4D77      ;Clears targets if attacker is Zombied or Muddled
LC24D4E:  JSR $4ECB      ;queue first command+attack, in entity's
                         ;conventional queue
LC24D51:  LDA $2BAF,Y
LC24D54:  CMP #$17       ;was confirmed and unadjusted command ID X-Magic?
LC24D56:  BNE LC24D1F    ;if not, repeat loop and look for other characters
LC24D58:  INY
LC24D59:  INY
LC24D5A:  INY
LC24D5B:  JSR $4D6D      ;load targets of second confirmed command
LC24D5E:  LDA $2BB0,Y    ;get party member's second confirmed attack/
                         ;subcommand ID)  (aka $2BB3,Old_Y
LC24D61:  XBA
LC24D62:  LDA #$17       ;command = X-Magic
LC24D64:  JSR $4D77      ;Clears targets if attacker is Zombied or Muddled
LC24D67:  JSR $4ECB      ;queue second, X-Magic attack, in entity's
                         ;conventional queue
LC24D6A:  BRA LC24D1F    ;repeat loop and look for other characters
LC24D6C:  RTS


;Load targets of player-confirmed command

LC24D6D:  PHP
LC24D6E:  REP #$20
LC24D70:  LDA $2BB1,Y    ;targets of party member's confirmed command
LC24D73:  STA $B8
LC24D75:  PLP
LC24D76:  RTS


;Clears targets if attacker is Zombied or Muddled

LC24D77:  PHP
LC24D78:  REP #$20       ;set 16-bit accumulator
LC24D7A:  STA $3A7A      ;save command and attack/subcommand in intermediate
                         ;variable used by C2/4ECB
LC24D7D:  LDA $3EE4,X
LC24D80:  BIT #$2002
LC24D83:  BEQ LC24D87    ;branch if not Zombie or Muddle
LC24D85:  STZ $B8        ;clear targets
LC24D87:  PLP
LC24D88:  RTS


;Perform various setup for player-confirmed command
;Entered with command in bottom of A, and attack/sub-command in top of A.
; Returns with same format, but attack/sub-command can often be changed, and
; even command can be changed in X-Magic's case.  Targets can also be changed.)

LC24D89:  PHX
LC24D8A:  PHY
LC24D8B:  TXY
LC24D8C:  CMP #$17
LC24D8E:  BNE LC24D92    ;Branch if not X-Magic
LC24D90:  LDA #$02       ;Set command to Magic
LC24D92:  CMP #$19
LC24D94:  BNE LC24DA7    ;Branch if not Summon
LC24D96:  PHA            ;Put on stack
LC24D97:  XBA
LC24D98:  CMP #$FF       ;Check if no Esper ID from input.  my guess is that's the
                         ;case in "Summon" proper as opposed to via Magic menu.
LC24D9A:  BNE LC24D9F    ;branch if there was a valid one
LC24D9C:  LDA $3344,Y    ;get equipped Esper
LC24D9F:  XBA
LC24DA0:  LDA $3018,Y
LC24DA3:  TSB $3F2E      ;make character ineligible to use Esper again this
                         ;battle
LC24DA6:  PLA
LC24DA7:  CMP #$01
LC24DA9:  BEQ LC24DAF    ;Branch if Item
LC24DAB:  CMP #$08
LC24DAD:  BNE LC24DB4    ;Branch if not Throw
LC24DAF:  XBA
LC24DB0:  STA $32F4,Y    ;store as item to add back to inventory.  this can
                         ;happen with:
                         ;1 Equipment Magic that doesn't destroy the item
                         ;   [no items have this, but the game supports it]
                         ;2 the item user's turn never happens.  perhaps the
                         ;   character who acted before them won the battle.
LC24DB3:  XBA
LC24DB4:  CMP #$0F
LC24DB6:  BNE LC24DDB    ;Branch if not Slot
LC24DB8:  PHA            ;save command #
LC24DB9:  XBA            ;get our Slot index
LC24DBA:  TAX
LC24DBB:  LDA $C24E4A,X  ;get spell # used by this Slot combo
LC24DBF:  CPX #$02
LC24DC1:  BCS LC24DD2    ;branch if it's Bahamut or higher -- i.e. neither form
                         ;of Joker Doom
LC24DC3:  PHA            ;save spell #
LC24DC4:  LDA $C24E52,X  ;get Joker Doom targeting
LC24DC8:  STA $B8,X      ;if X is 0 [7-7-Bar], mark all party members in $B8
                         ;if X is 1 [7-7-7], mark all enemies in $B9
LC24DCA:  LDA $B8
LC24DCC:  EOR $3A40
LC24DCF:  STA $B8        ;toggle whether characters acting as enemies are targeted.
                         ;e.g. Shadow in Colosseum or Gau returning from Veldt leap
LC24DD1:  PLA            ;restore spell #
LC24DD2:  CMP #$FF
LC24DD4:  BNE LC24DD9    ;branch if not Bar-Bar-Bar
LC24DD6:  JSR $37DC      ;Pick random esper
LC24DD9:  XBA
LC24DDA:  PLA            ;restore command #
LC24DDB:  CMP #$13
LC24DDD:  BNE LC24DEC    ;Branch if not Dance
LC24DDF:  PHA            ;Put on stack
LC24DE0:  XBA
LC24DE1:  STA $32E1,Y    ;save as Which dance is selected for this character
LC24DE4:  STA $3A6F      ;and save as a more global dance #, which other
                         ;characters might fall back to
LC24DE7:  JSR $059C      ;Pick dance and dance move
LC24DEA:  XBA
LC24DEB:  PLA
LC24DEC:  CMP #$10
LC24DEE:  BNE LC24DFA    ;Branch if not Rage
LC24DF0:  PHA            ;Put on stack
LC24DF1:  XBA
LC24DF2:  STA $33A8,Y    ;Which rage is being used
LC24DF5:  JSR $05D1      ;Picks a Rage [when Muddled/Berserked/etc], and picks
                         ;the Rage move
LC24DF8:  XBA
LC24DF9:  PLA
LC24DFA:  CMP #$0A
LC24DFC:  BNE LC24E13    ;Branch if not Blitz
LC24DFE:  PHA            ;Put on stack
LC24DFF:  XBA
LC24E00:  PHA            ;Put on stack
LC24E01:  BMI LC24E10    ;Branch if no blitz selected
LC24E03:  TAX
LC24E04:  JSR $1E57      ;Set Bit #X in A
LC24E07:  BIT $1D28
LC24E0A:  BNE LC24E10    ;Branch if selected blitz is known
LC24E0C:  LDA #$FF
LC24E0E:  STA $01,S      ;replace spell/attack # with null
LC24E10:  PLA
LC24E11:  XBA
LC24E12:  PLA
LC24E13:  LDX #$04
LC24E15:  CMP $C24E3C,X  ;does our command match one that needs its
                         ;spell # calculated?
LC24E19:  BNE LC24E26    ;branch if not
LC24E1B:  XBA
LC24E1C:  CLC
LC24E1D:  ADC $C24E41,X  ;add the first spell # for this command to our
                         ;current index.  ex - for Pummel, Blitz #0, we'd
                         ;end up with 55h.
LC24E21:  BCC LC24E25    ;branch if the spell # didn't overflow
LC24E23:  LDA #$EE       ;load Battle as spell #
LC24E25:  XBA            ;put spell # in top of A, and look at command # again
LC24E26:  DEX
LC24E27:  BPL LC24E15    ;loop for all 5 commands
LC24E29:  PHA            ;Put on stack
LC24E2A:  CLC            ;clear Carry
LC24E2B:  JSR $5217      ;X = A DIV 8, A = 2 ^ (A MOD 8)
LC24E2E:  AND $C24E46,X  ;compare to bitfield of commands that need to retarget
LC24E32:  BEQ LC24E38    ;Branch if command doesn't need to retarget
LC24E34:  STZ $B8
LC24E36:  STZ $B9        ;clear targets
LC24E38:  PLA
LC24E39:  PLY
LC24E3A:  PLX
LC24E3B:  RTS


;Data - commands that need their spell # calculated

LC24E3C: db $19   ;(Summon)
LC24E3D: db $0C   ;(Lore)
LC24E3E: db $1D   ;(Magitek)
LC24E3F: db $0A   ;(Blitz)
LC24E40: db $07   ;(Swdtech)


;Data - first spell # for each of above commands

LC24E41: db $36   ;(Espers)
LC24E42: db $8B   ;(Lores)
LC24E43: db $83   ;(Magitek commands)
LC24E44: db $5D   ;(Blitzes)
LC24E45: db $55   ;(Swdtech)


;Data - commands that need to retarget.  8 commands per byte.

LC24E46: db $80   ;(Swdtech)
LC24E47: db $04   ;(Blitz)
LC24E48: db $0B   ;(Rage, Leap, Dance)
LC24E49: db $00   ;(Nothing)


;Data - spell numbers for Slot attacks

LC24E4A: db $94   ;(L.5 Doom -- used by Joker Doom [7-7-Bar])
LC24E4B: db $94   ;(L.5 Doom -- used by Joker Doom [7-7-7])
LC24E4C: db $43   ;(Bahamut)
LC24E4D: db $FF   ;(Nothing -- used by Triple Bar?)
LC24E4E: db $80   ;(H-Bomb)
LC24E4F: db $7F   ;(Chocobop)
LC24E50: db $81   ;(7-Flush)
LC24E51: db $FE   ;(Lagomorph)


;Data - Joker Doom targeting

LC24E52: db $0F   ;(7-7-bar => your whole party)
LC24E53: db $3F   ;(7-7-7  => whole enemy party)


;Add a record to the "master list".  It contains standalone records, or linked
; list queues.  It won't make much sense without its entry points, held in
; $32CC,target , $32CD,target, and $340A.)
;Just the pointer/ID field is initialized by this call.  "Sister structures" are
; $3420, $3520, and $3620.  As they're 2 bytes per slot instead of 1, they're
; physically separate, but conceptually, they're just more fields of the same record.)

LC24E54:  PHX
LC24E55:  LDX #$7F
LC24E57:  LDA $3184,X
LC24E5A:  BMI LC24E60    ;branch if this slot is free
LC24E5C:  DEX
LC24E5D:  BPL LC24E57    ;iterate for all 128 slots if need be
LC24E5F:  INX            ;default to adding at Position 0 if no free
                         ;slot was found
LC24E60:  TXA
LC24E61:  STA $3184,X    ;a new record's pointer/ID value starts off
                         ;equal to its slot #
LC24E64:  PLX
LC24E65:  RTS


;Add character/monster to queue of who will wait to act.  One place this is called
; is right after a character's command is input, and before they enter their
; "ready stance".  Monsters' ready stances aren't visible [and are generally
; negligible in length], but monsters still use this queue too.)

LC24E66:  TXA
LC24E67:  PHX
LC24E68:  LDX $3A65      ;get next available Wait Queue slot
LC24E6B:  STA $3720,X    ;store current entity in that slot
LC24E6E:  PLX
LC24E6F:  INC $3A65      ;point to next queue slot after this one.  this is
                         ;circular: if we've gone past slot #255, we'll restart on
                         ;#0.  that shouldn't be a problem unless 256+ fighters
                         ;get queued up at once somehow.
LC24E72:  LDA #$FE
LC24E74:  JMP $0A43


;Add character/monster to queue of who will act next.  One place this is called is
; when someone's "wait timer" after inputting a command elapses and they can leave
; their ready stance to attack.)

LC24E77:  TXA
LC24E78:  PHX
LC24E79:  LDX $3A67      ;get next available Action Queue slot
LC24E7C:  STA $3820,X    ;store current entity in that slot
LC24E7F:  PLX
LC24E80:  INC $3A67      ;point to next queue slot after this one.  this is
                         ;circular: if we've gone past slot #255, we'll restart on
                         ;#0.  that shouldn't be a problem unless 256+ fighters
                         ;get queued up at once somehow.
LC24E83:  RTS


;Add character/monster to queue of who will next take/undergo counterattacks and
; Regen/Seizure/etc damage/healing.)

LC24E84:  TXA
LC24E85:  PHX
LC24E86:  LDX $3A69      ;get next available Counterattack or Damage/Healing slot
LC24E89:  STA $3920,X    ;store current entity in that slot
LC24E8C:  PLX
LC24E8D:  INC $3A69      ;point to next queue slot after this one.  this is
                         ;circular: if we've gone past slot #255, we'll restart on
                         ;#0.  that shouldn't be a problem unless 256+ fighters
                         ;get queued up at once somehow.
LC24E90:  RTS


;Add command, attack, targets, and [rarely-used] MP cost to global Special Action linked
; list queue)

LC24E91:  PHY
LC24E92:  PHP
LC24E93:  SEP #$20
LC24E95:  STA $3A7A      ;Set command
LC24E98:  STX $3A7B      ;Set attack.  often, X holds the acting+target entity,
                         ;or miscellaneous things instead.
LC24E9B:  JSR $4E54      ;Add a record [by initializing its pointer/ID field] to
                         ;a "master list" in $3184, a collection of linked list
                         ;queues
LC24E9E:  PHA            ;Put on stack
LC24E9F:  LDA $340A      ;get global entry point to Special Action linked list
                         ;queue.  includes actions like auto-spellcasts from
                         ;equipment, and timed statuses expiring.  note that unlike
                         ;other entry points, there isn't a separate one for each
                         ;entity.
LC24EA2:  CMP #$FF
LC24EA4:  BNE LC24EDF    ;branch if it's already defined
LC24EA6:  LDA $01,S
LC24EA8:  STA $340A      ;if it's undefined, set it to the index of the
                         ;list record we just added
LC24EAB:  BRA LC24EDF    ;if it helps to follow things, view the
                         ;last 3 instructions as: "PLA / STA $340A /
                         ;BRA LC24EF0".


;Add command, attack, targets, and MP cost [after determining it] to entity's counterattack
; and periodic damage/healing linked list queue or to its conventional one, depending on $B1.
; Usually called from monster script commands, which can run from either script section.)

LC24EAD:  LDA $B1
LC24EAF:  LSR            ;is it an unconventional turn [counterattack, in this
                         ;context]?
LC24EB0:  BCC LC24ECB    ;branch if not
LC24EB2:  PHY            ;many callers enter here, to directly use counterattack
                         ;/ periodic damage queue
LC24EB3:  PHP
LC24EB4:  SEP #$20
LC24EB6:  JSR $4E54      ;Add a record [by initializing its pointer/ID field] to
                         ;a "master list" in $3184, a collection of linked list
                         ;queues
LC24EB9:  PHA            ;Put on stack
LC24EBA:  LDA $32CD,X    ;get entry point to entity's counterattack or periodic
                         ;damage/healing linked list queue
LC24EBD:  CMP #$FF
LC24EBF:  BNE LC24EDF    ;branch if it's already defined
LC24EC1:  JSR $4E84      ;add entity to counterattack / periodic damage queue
LC24EC4:  LDA $01,S
LC24EC6:  STA $32CD,X    ;if it's undefined, set it to the index of the
                         ;list record we just added
LC24EC9:  BRA LC24EDF    ;if it helps to follow things, view the
                         ;last 3 instructions as: "PLA / STA $32CD,X /
                         ;BRA LC24EF0".


;Add command, attack, targets, and MP cost [after determining it] to entity's conventional
; linked list queue)

LC24ECB:  PHY
LC24ECC:  PHP
LC24ECD:  SEP #$20       ;Set 8-bit Accumulator
LC24ECF:  JSR $4E54      ;Add a record [by initializing its pointer/ID field] to
                         ;a "master list" in $3184, a collection of linked list
                         ;queues
LC24ED2:  PHA            ;Put on stack
LC24ED3:  LDA $32CC,X    ;get entry point to entity's conventional linked list
                         ;queue
LC24ED6:  CMP #$FF
LC24ED8:  BNE LC24EDF    ;branch if it's already defined
LC24EDA:  LDA $01,S      ;if it's undefined, set it to the index of the
                         ;list record we just added
LC24EDC:  STA $32CC,X    ;if it helps to follow things, view the
                         ;last 2 instructions as: "PLA / STA $32CC,X /
                         ;BRA LC24EF0".
LC24EDF:  TAY            ;index for 8-bit fields
LC24EE0:  CMP $3184,Y    ;does the pointer/ID value at PositionY equal
                         ;PositionY?
LC24EE3:  BEQ LC24EEC    ;if so, it's a standalone record, or the last record
                         ;in a linked list, so branch
LC24EE5:  LDA $3184,Y    ;get pointer/ID field.  [note that which queue holds
                         ;this record depends on how we reached here.]
LC24EE8:  BMI LC24EEC    ;if it's somehow a null record, branch.
                         ;if not, that leaves it being a linked list
                         ;member that points to another record.
LC24EEA:  BRA LC24EDF    ;loop and check the record that's being pointed to.
                         ;can replace last 2 instructions with "BPL LC24EDF".
LC24EEC:  PLA
LC24EED:  STA $3184,Y    ;make the record that was last point to the new record.
                         ;[or if the list had been empty, pointlessly re-save
                         ;the new record.]
LC24EF0:  ASL
LC24EF1:  TAY            ;adjust index for 16-bit fields
LC24EF2:  JSR $4F08      ;Determine MP cost of a spell/attack
LC24EF5:  STA $3620,Y    ;save MP cost in a linked list queue.  [the specific
                         ;queue varies depending on how we reached here.]
LC24EF8:  REP #$20       ;Set 16-bit Accumulator
LC24EFA:  LDA $3A7A      ;get command ID and attack/sub-command ID
LC24EFD:  STA $3420,Y    ;save command and attack in same linked list queue
LC24F00:  LDA $B8        ;get targets.  if reached from C2/4E91, might instead
                         ;be attack ID or something else.
LC24F02:  STA $3520,Y    ;save targets in same linked list queue
LC24F05:  PLP
LC24F06:  PLY
LC24F07:  RTS


;Determine MP cost of a spell/attack

LC24F08:  PHX
LC24F09:  PHP
LC24F0A:  TDC            ;16-bit A = 0.  this means the returned spell cost will
                         ;default to zero.
LC24F0B:  LDA #$40
LC24F0D:  TRB $B1        ;clear Bit 6 of $B1
LC24F0F:  BNE LC24F53    ;branch if it was set, meaning we're on second Gem Box
                         ;spell for Mimic, and return 0 as cost.  no precaution
                         ;needed for first Mimicked Gem Box spell, as we reach
                         ;this function with $3A7A as 12h [Mimic] then.
LC24F11:  LDA $3A7A      ;get command #
LC24F14:  CMP #$19
LC24F16:  BEQ LC24F24    ;branch if it's Summon
LC24F18:  CMP #$0C
LC24F1A:  BEQ LC24F24    ;branch if it's Lore
LC24F1C:  CMP #$02
LC24F1E:  BEQ LC24F24    ;branch if it's Magic
LC24F20:  CMP #$17
LC24F22:  BNE LC24F53    ;branch and use 0 cost if it's not X-Magic
LC24F24:  REP #$10       ;Set 16-bit X and Y
LC24F26:  LDA $3A7B      ;get attack #
LC24F29:  CPX #$0008
LC24F2C:  BCS LC24F47    ;branch if it's a monster attacker.  they don't have
                         ;menus containing MP data, nor relics that can
                         ;alter MP costs.
LC24F2E:  PHX
LC24F2F:  TAX
LC24F30:  LDA $3084,X    ;get this spell's position relative to Esper menu.  the
                         ;order in memory is Esper menu, Magic menu, Lore menu.
LC24F33:  PLX
LC24F34:  CMP #$FF
LC24F36:  BEQ LC24F53    ;if it's somehow not in the menu?, branch and use 0 cost
LC24F38:  REP #$20       ;Set 16-bit Accumulator
LC24F3A:  ASL
LC24F3B:  ASL            ;multiply offset by 4, as each spell menu entry has 4 bytes:
                         ; Spell index number, Unknown [related to spell availability],
                         ; Spell aiming, MP cost
LC24F3C:  ADC $302C,X    ;add starting address of character's Magic menu
LC24F3F:  TAX
LC24F40:  SEP #$20       ;Set 8-bit Accumulator
LC24F42:  LDA $0003,X    ;get MP cost from character's menu data.  it usually
                         ;matches the spell data, but Gold Hairpin, Economizer,
                         ;and Step Mine's special formula can make it vary.
LC24F45:  BRA LC24F54    ;clean up stack and exit
LC24F47:  XBA
LC24F48:  LDA #$0E
LC24F4A:  JSR $4781      ;attack # * 14
LC24F4D:  TAX
LC24F4E:  LDA $C46AC5,X  ;read MP cost from spell data
LC24F52:  XBA
LC24F53:  XBA            ;bottom of A = MP cost
LC24F54:  PLP
LC24F55:  PLX
LC24F56:  RTS


;Monster command script command #$F7

LC24F57:  LDA $B6
LC24F59:  XBA
LC24F5A:  LDA #$0F
LC24F5C:  JMP $62BF


;Command #$26 - Doom cast when Condemned countdown reaches 0; Safe, Shell, or Reflect*
;               cast when character enters Near Fatal (* no items actually do this,
;               but it's supported); or revival due to Life 3.

LC24F5F:  LDA $B8        ;get spell ID?
LC24F61:  LDX $B6        ;get target?
LC24F63:  STA $B6        ;save spell ID
LC24F65:  CMP #$0D
LC24F67:  BNE LC24F78    ;branch if we're not casting Doom
LC24F69:  LDA $3204,X
LC24F6C:  ORA #$10
LC24F6E:  STA $3204,X    ;set flag to zero and disable the Condemned counter
                         ;after turn.  this is done in case instant death is
                         ;thwarted, and thus Condemned status isn't removed
                         ;and C2/4644 never executes.
LC24F71:  LDA $3A77
LC24F74:  BEQ LC24FDF    ;Exit function if no monsters are present and alive
LC24F76:  LDA #$0D       ;Set spell to Doom again.  it's easier than PHA/PLA
LC24F78:  XBA
LC24F79:  LDA #$02
LC24F7B:  STA $B5        ;Set command to Magic
LC24F7D:  JSR $26D3      ;Load data for command and attack/sub-command, held
                         ;in A.bottom and A.top
LC24F80:  JSR $2951      ;Load Magic Power / Vigor and Level
LC24F83:  LDA #$10
LC24F85:  TRB $B0        ;Prevents characters from stepping forward and
                         ;getting circular or triangular pattern around
                         ;them when casting Magic or Lores.
LC24F87:  LDA #$02
LC24F89:  STA $11A3      ;Set attack to only not reflectable
LC24F8C:  LDA #$20
LC24F8E:  TSB $11A4      ;Set can't be dodged
LC24F91:  STZ $11A5      ;Set to 0 MP cost
LC24F94:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Monster command script command #$F5

LC24F97:  STZ $3A2A
LC24F9A:  STZ $3A2B      ;clear temporary bytes 3 and 4 for ($76 animation
                         ;buffer
LC24F9D:  LDA $3A73
LC24FA0:  EOR #$FF
LC24FA2:  TRB $B9        ;Clear monsters that aren't in formation template
                         ;from command's monster targets
LC24FA4:  LDA $B8        ;get subcommand
LC24FA6:  ASL
LC24FA7:  TAX
LC24FA8:  LDY #$12
LC24FAA:  LDA $3019,Y
LC24FAD:  BIT $B9
LC24FAF:  BEQ LC24FB4    ;branch if enemy isn't affected by the F5 command
LC24FB1:  JSR ($51E4,X)  ;execute subcommand on this enemy
LC24FB4:  DEY
LC24FB5:  DEY
LC24FB6:  CPY #$08
LC24FB8:  BCS LC24FAA    ;iterate for all 6 monsters
LC24FBA:  LDA $B6        ;get animation type
LC24FBC:  XBA
LC24FBD:  LDA #$13
LC24FBF:  JMP $62BF


;Command F5 nn 04

LC24FC2:  PHA            ;Put on stack
LC24FC3:  LDA #$FF
LC24FC5:  STA $3A95      ;prohibit C2/47FB from checking for combat end
LC24FC8:  PLA
LC24FC9:  BRA LC24FCE
LC24FCB:  TSB $2F4D      ;Command F5 nn 01 enters here
                         ;mark enemy to be removed from the battlefield
LC24FCE:  TRB $3409      ;Command F5 nn 03 enters here
LC24FD1:  TRB $2F2F      ;remove from bitfield of remaining enemies?
LC24FD4:  TSB $3A2A      ;mark in temporary byte 3 for ($76) animation buffer
LC24FD7:  LDA $3EF9,Y
LC24FDA:  ORA #$20
LC24FDC:  STA $3EF9,Y    ;Set Hide status
LC24FDF:  RTS


;Command F5 nn 00

LC24FE0:  PHA            ;Put on stack
LC24FE1:  REP #$20
LC24FE3:  LDA $3C1C,Y    ;Max HP
LC24FE6:  STA $3BF4,Y    ;Current HP
LC24FE9:  SEP #$20
LC24FEB:  PLA
LC24FEC:  TRB $3A3A      ;Command F5 nn 02 enters here
                         ;remove from bitfield of dead-ish monsters?
LC24FEF:  TSB $2F2F      ;add to bitfield of remaining enemies?
LC24FF2:  TSB $3A2B      ;mark in temporary byte 4 for ($76) animation buffer
LC24FF5:  TSB $2F4F      ;mark enemy to enter the battlefield
LC24FF8:  TSB $3409
LC24FFB:  STZ $3A95      ;allow C2/47FB to check for combat end
LC24FFE:  RTS


;Command F5 nn 05

LC24FFF:  JSR $4FCE
LC25002:  LDA $3EE4,Y
LC25005:  ORA #$80
LC25007:  STA $3EE4,Y    ;Set Death status
LC2500A:  RTS


;Regen, Poison, and Seizure/Phantasm damage or healing

LC2500B:  LDA $3A77
LC2500E:  BEQ LC24FDF    ;Exit if no monsters left in combat
LC25010:  LDA $3AA1,Y
LC25013:  AND #$EF
LC25015:  STA $3AA1,Y    ;clear bit 4 of $3AA1,Y.  because we're servicing this
                         ;damage/healing request, we can allow C2/5A83 to queue
                         ;up another one for this entity as needed.
LC25018:  LDA $3AA0,Y
LC2501B:  BIT #$10       ;is entity Wounded, Petrified, or Stopped, or is
                         ;somebody else under the influence of Quick?
LC2501D:  BNE LC24FDF    ;Exit if any are true
LC2501F:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC25022:  LDA #$90
LC25024:  TRB $B3        ;Set Ignore Clear, and allow for damage increment
                         ;even with Ignore Defense
LC25026:  LDA #$12
LC25028:  STA $B5        ;Set command for animation to Mimic
LC2502A:  LDA #$68
LC2502C:  STA $11A2      ;Sets to only ignore defense, no split damage, reverse
                         ;damage/healing on undead
LC2502F:  LSR $11A4
LC25032:  LDA $B6
LC25034:  LSR
LC25035:  LSR
LC25036:  ROL $11A4      ;Set to heal for regen; damage for poison &
                         ;seizure/phantasm
LC25039:  LSR
LC2503A:  BCC LC25051    ;Branch if not poison
LC2503C:  LDA $3E24,Y    ;Cumulative amount to increment poison damage
LC2503F:  STA $BD        ;save in turn-wide Damage Incrementor
LC25041:  INC
LC25042:  INC
LC25043:  CMP #$0F
LC25045:  BCC LC25049    ;Branch if under 15
LC25047:  LDA #$0E       ;Set to 14
LC25049:  STA $3E24,Y    ;Cumulative amount to increment poison damage for
                         ;next round
LC2504C:  LDA #$08
LC2504E:  STA $11A1      ;Set element to poison
LC25051:  LDA $3B40,Y    ;Stamina)    (Figure damage
LC25054:  STA $E8
LC25056:  REP #$20
LC25058:  LDA $3C1C,Y    ;Max HP
LC2505B:  JSR $47B7      ;Max HP * Stamina / 256
LC2505E:  LSR
LC2505F:  LSR
LC25060:  CMP #$00FE
LC25063:  SEP #$20
LC25065:  BCC LC25069    ;Branch if under 254
LC25067:  LDA #$FC       ;set to 253
LC25069:  ADC #$02
LC2506B:  STA $11A6      ;Store damage in battle power
LC2506E:  TYX
LC2506F:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Monster command script command #$F2
;$B8 and bottom 7 bits of $B9 = new formation to change to)

LC25072:  LDA $B8        ;Byte 2
LC25074:  STA $11E0      ;Monster formation, byte 1
LC25077:  ASL $3A47      ;shift out old bit 7
LC2507A:  LDA $B9        ;Byte 3.  top bit: 1 = monsters get Max HP.
                         ;0 = retain HP and Max HP from current formation.
LC2507C:  EOR #$80
LC2507E:  ASL
LC2507F:  ROR $3A47      ;put reverse of bit 7 of $B9 into bit 7 here
LC25082:  LSR
LC25083:  STA $11E1      ;Monster formation, byte 2
LC25086:  JSR $30E8      ;Loads battle formation data
LC25089:  REP #$20       ;Set 16-bit Accumulator
LC2508B:  LDX #$0A
LC2508D:  STZ $3AA8,X    ;clear enemy presence flag
LC25090:  STZ $3E54,X
LC25093:  TDC
LC25094:  DEC
LC25095:  STA $2001,X    ;save FFFFh [null] as enemy #
LC25098:  LDA #$FFBC
LC2509A:  STA $320C,X    ;aka $3204,X
LC2509E:  DEX
LC2509F:  DEX
LC250A0:  BPL LC2508D    ;loop for all 6 enemies
LC250A2:  SEP #$20       ;Set 8-bit Accumulator
LC250A4:  JSR $2EE1      ;Initialize some enemy presence variables, and load enemy
                         ;names and stats
LC250A7:  JSR $4391      ;update status effects for all applicable entities
LC250AA:  JSR $069B      ;Do various responses to three mortal statuses
LC250AD:  JSR $083F
LC250B0:  JSR $4AB9      ;Update lists and counts of present and/or living
                         ;characters and monsters
LC250B3:  JSR $26C9      ;Give immunity to permanent statuses, and handle immunity
                         ;to "mirror" statuses, for all entities.
LC250B6:  JSR $2E3A      ;Determine if front, back, pincer, or side attack
LC250B9:  LDA $3A75      ;list of present and living enemies
LC250BC:  STA $3A2B      ;temporary byte 4 for ($76) animation buffer
LC250BF:  LDA $201E
LC250C2:  STA $3A2A      ;temporary byte 3 for ($76) animation buffer
LC250C5:  LDA $B6
LC250C7:  XBA
LC250C8:  LDA #$12
LC250CA:  JMP $62BF


;Command #$25

LC250CD:  LDA #$02
LC250CF:  BRA LC250D3
LC250D1:  LDA #$10       ;Command #$21 - F3 Command script enters here
LC250D3:  XBA
LC250D4:  LDA $B6
LC250D6:  XBA
LC250D7:  STZ $3A2A      ;set temporary byte 3 for ($76 animation buffer
                         ;to 0
LC250DA:  JMP $62BF


;Command #$27 - Display Scan info

LC250DD:  LDX $B6        ;get target of original casting
LC250DF:  LDA #$FF
LC250E1:  STA $2D72      ;first byte of second entry of ($76) buffer
LC250E4:  LDA #$02
LC250E6:  STA $2D6E      ;first byte of first entry of ($76) buffer
LC250E9:  STZ $2F36
LC250EC:  STZ $2F37      ;clear message parameter 1, top two bytes
LC250EF:  STZ $2F3A      ;clear message parameter 2, top/third byte
LC250F2:  LDA $3B18,X    ;Level
LC250F5:  STA $2F35      ;save it in message parameter 1, bottom byte
LC250F8:  LDA #$34       ;ID of "Level [parameter1]" message
LC250FA:  STA $2D6F      ;second byte of first entry of ($76) buffer
LC250FD:  LDA #$04
LC250FF:  JSR $6411      ;Execute animation queue
LC25102:  REP #$20
LC25104:  LDA $3BF4,X    ;Current HP
LC25107:  STA $2F35      ;save in message parameter 1, bottom word
LC2510A:  LDA $3C1C,X    ;Max HP
LC2510D:  STA $2F38      ;save in message parameter 2, bottom word
LC25110:  SEP #$20
LC25112:  LDA #$30       ;ID of "HP [parameter1]/[parameter2]" message
LC25114:  STA $2D6F      ;second byte of first entry of ($76) buffer
LC25117:  LDA #$04
LC25119:  JSR $6411      ;Execute animation queue
LC2511C:  REP #$20
LC2511E:  LDA $3C08,X    ;Current MP
LC25121:  STA $2F35      ;save in message parameter 1, bottom word
LC25124:  LDA $3C30,X    ;Max MP
LC25127:  STA $2F38      ;save in message parameter 2, bottom word
LC2512A:  SEP #$20
LC2512C:  BEQ LC25138
LC2512E:  LDA #$31       ;ID of "MP [parameter1]/[parameter2]" message
LC25130:  STA $2D6F      ;second byte of first entry of ($76) buffer
LC25133:  LDA #$04
LC25135:  JSR $6411      ;Execute animation queue
LC25138:  LDA #$15       ;start with ID of "Weak against fire" message
LC2513A:  STA $2D6F      ;second byte of first entry of ($76) buffer
LC2513D:  LDA $3BE0,X
LC25140:  STA $EE        ;Weak elements
LC25142:  LDA $3BE1,X
LC25145:  ORA $3BCC,X
LC25148:  ORA $3BCD,X
LC2514B:  TRB $EE        ;subtract Absorbed, Nullified, and Resisted
                         ;elements, because those supercede weaknesses
LC2514D:  LDA #$01
LC2514F:  BIT $EE
LC25151:  BEQ LC2515A    ;branch if not weak to current element
LC25153:  PHA            ;Put on stack
LC25154:  LDA #$04
LC25156:  JSR $6411      ;Execute animation queue
LC25159:  PLA
LC2515A:  INC $2D6F      ;advance to "Weak against" message with next
                         ;element name
LC2515D:  ASL            ;look at next elemental bit
LC2515E:  BCC LC2514F    ;iterate for all 8 elements
LC25160:  RTS


;Remove Stop, Reflect, Freeze, or Sleep when time is up

LC25161:  LDX $3A7D      ;get entity, whom the game regards as performing
                         ;this action on oneself
LC25164:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC25167:  LDA #$12
LC25169:  STA $B5        ;Set command to Mimic
LC2516B:  LDA #$10
LC2516D:  TRB $B0        ;Prevents characters from stepping forward and
                         ;getting circular or triangular pattern around
                         ;them when casting Magic or Lores.
LC2516F:  LSR $B8
LC25171:  BCC LC25178    ;Branch if bit 0 of $B8 is 0
LC25173:  LDA #$10
LC25175:  TSB $11AC      ;Attack clears Stop
LC25178:  LSR $B8
LC2517A:  BCC LC25181    ;Branch if bit 1 of $B8 is 0
LC2517C:  LDA #$80
LC2517E:  TSB $11AC      ;Attack clears Reflect
LC25181:  LSR $B8
LC25183:  BCC LC2518A    ;Branch if bit 2 of $B8 is 0
LC25185:  LDA #$02
LC25187:  TSB $11AD      ;Attack clears Freeze
LC2518A:  LSR $B8
LC2518C:  BCC LC251A0    ;Branch if bit 3 of $B8 is 0
LC2518E:  LDA #$80
LC25190:  AND $3EE5,X
LC25193:  BEQ LC251A0    ;Branch if not sleeping
LC25195:  TSB $11AB      ;Attack clears Sleep
LC25198:  LDA #$02
LC2519A:  STA $B5        ;Set command to Magic
LC2519C:  LDA #$78
LC2519E:  STA $B6        ;Set spell to Tapir.  Note this does *not*
                         ;use the spell _data_ of the Tapir from Mog's
                         ;dance, so it won't have the same effect
LC251A0:  LDA #$04
LC251A2:  TSB $11A4      ;Set to lift statuses
LC251A5:  JMP $3167      ;Entity executes one largely unblockable hit on
                         ;self


;Command #$2C (buffer Battle Dynamics Command 0Eh, graphics related: for character
;              poses?  can't always see effect, but this lets Petrify take spellcaster
;              out of chant pose or relax a Defender, for instance.)

LC251A8:  LDA $3A7D
LC251AB:  LSR            ;convert target # to 0, 1, 2, etc
LC251AC:  XBA
LC251AD:  LDA #$0E       ;Battle Dynamics Command 0Eh
LC251AF:  JMP $62BF


;Command #$2D (Drain from being seized

LC251B2:  LDA $3AA1,Y
LC251B5:  AND #$EF
LC251B7:  STA $3AA1,Y    ;Clear bit 4 of $3AA1,Y.  because we're servicing this
                         ;damage/healing request, we can allow C2/5A83 to queue
                         ;up another one for this entity as needed.
LC251BA:  TYX
LC251BB:  JSR $298A      ;Load command data, and clear special effect,
                         ;magic power, etc.
LC251BE:  STZ $11AE      ;Set Magic Power to 0
LC251C1:  LDA #$10
LC251C3:  STA $11AF      ;Set Level to 16
LC251C6:  STA $11A6      ;Set Spell Power to 16
LC251C9:  LDA #$28
LC251CB:  STA $11A2      ;Sets to only ignore defense, heal undead
LC251CE:  LDA #$02
LC251D0:  STA $11A3      ;Sets to Not reflectable only
LC251D3:  TSB $11A4      ;Sets Redirection
LC251D6:  TSB $3A46      ;set flag to let this attack target a Seized
                         ;entity, who is normally untargetable
LC251D9:  LDA #$80
LC251DB:  TRB $B2        ;Indicate a special type of drainage.  Normal drain
                         ;is capped at the lowest of: drainee's Current HP/MP
                         ;and drainer's Max - Current HP/MP.  This one will
                         ;ignore the latter, meaning it's effectively just a
                         ;damage attack if the attacker's [or undead target's]
                         ;HP/MP is full.
LC251DD:  LDA #$12
LC251DF:  STA $B5        ;Sets command to Mimic
LC251E1:  JMP $317B      ;entity executes one hit


;Code pointers for command #$F5

LC251E4: dw $4FE0
LC251E6: dw $4FCB
LC251E8: dw $4FEC
LC251EA: dw $4FCE
LC251EC: dw $4FC2
LC251EE: dw $4FFF


;X = Highest bit in A that is 1 (bit 0 = 0, 1 = 1, etc.

LC251F0:  LDX #$00
LC251F2:  LSR
LC251F3:  BEQ LC251F8    ;Exit if all bits are 0
LC251F5:  INX
LC251F6:  BRA LC251F2
LC251F8:  RTS


;Y = (Number of highest target set in A * 2
;    (0, 2, 4, or 6 for characters.  8, 10, 12, 14, 16, or 18 for monsters.)

;    (Remember that
;     $3018 : Holds $01 for character 1, $02 for character 2, $04 for character 3,
;             $08 for character 4
;     $3019 : Holds $01 for monster 1, $02 for monster 2, etc.  )

LC251F9:  PHX
LC251FA:  PHP
LC251FB:  REP #$20       ;Set 16-bit Accumulator
LC251FD:  SEP #$10       ;Set 8-bit Index Registers
LC251FF:  LDX #$12
LC25201:  BIT $3018,X
LC25204:  BNE LC2520A    ;Exit loop if bit set
LC25206:  DEX
LC25207:  DEX
LC25208:  BPL LC25201    ;loop through all 10 targets if necessary
LC2520A:  TXY
LC2520B:  PLP
LC2520C:  PLX
LC2520D:  RTS


;Sets X to number of bits set in A

LC2520E:  LDX #$00
LC25210:  LSR
LC25211:  BCC LC25214
LC25213:  INX
LC25214:  BNE LC25210
LC25216:  RTS


;X = A / 8  (including carry, so A is effectively 9 bits
;A = 1 if (A % 8) = 0, 2 if (A % 8) = 1, 4 if (A % 8) = 2,
;    8 if (A % 8) = 3, 16 if (A % 8) = 4, etc.
;    So A = 2 ^ (A MOD 8)
;Carry flag = cleared

LC25217:  PHY
LC25218:  PHA            ;Put on stack
LC25219:  ROR
LC2521A:  LSR
LC2521B:  LSR
LC2521C:  TAX
LC2521D:  PLA
LC2521E:  AND #$07
LC25220:  TAY
LC25221:  LDA #$00
LC25223:  SEC
LC25224:  ROL
LC25225:  DEY
LC25226:  BPL LC25224
LC25228:  PLY
LC25229:  RTS


;Randomly picks a bit set in A

LC2522A:  PHY
LC2522B:  PHP
LC2522C:  REP #$20       ;Set 16-bit Accumulator
LC2522E:  STA $EE
LC25230:  JSR $520E      ;X = number of bits set in A
LC25233:  TXA
LC25234:  BEQ LC25244    ;Exit if no bits set
LC25236:  JSR $4B65      ;random: 0 to A - 1
LC25239:  TAX
LC2523A:  SEC
LC2523B:  TDC
LC2523C:  ROL
LC2523D:  BIT $EE
LC2523F:  BEQ LC2523C
LC25241:  DEX
LC25242:  BPL LC2523C
LC25244:  PLP
LC25245:  PLY
LC25246:  RTS


;Determine if front, back, pincer, or side attack
; (X = #$10 when called for choosing type of attack formation)
; (A = Which types to allow, bit 7 = side, 6 = pincer, 5 = back, 4 = normal/front)
; (Returns attack formation in X: 0 = Front/Normal, 1 = Back, 2 = Pincer, 3 = Side)
;Also used for determining which attack Umaro should use)
; (X = #$00 for no Rage Ring or Blizzard Orb, #$04 for Rage Ring, #$08 for Blizzard Orb,
;      #$0C for both)
; (A = Which attacks to allow, bit 7 = Normal attack, 6 = Charge/Tackle, 5 = Storm,
;      4 = Throw character.  Bits 6 and 7 are always set by caller.  Note that masking
;      in A is unneeded [it could very well have all bits set] because the 4 different
;      data structures at C2/5269 will exclude certain attacks by having FFh
;      [read: 00h] for them.)
; (Returns Umaro attack type in X: 0 = Throw character, 1 = Storm, 2 = Charge/Tackle,
;  3 = Normal attack)

LC25247:  PHY
LC25248:  XBA
LC25249:  LDA #$00
LC2524B:  LDY #$03
LC2524D:  XBA
LC2524E:  ASL            ;put allowability bit of current Attack or
                         ;Formation type into Carry
LC2524F:  XBA
LC25250:  BCC LC25256    ;Branch if type not allowed
LC25252:  ADC $C25269,X  ;Add chance to get that type, which includes
                         ;plus one for always-set Carry.
LC25256:  STA $00FC,Y    ;build an array that determines which ranges
                         ;of random numbers will result in which
                         ;Umaro attacks or Battle formations
LC25259:  INX
LC2525A:  DEY
LC2525B:  BPL LC2524D    ;Check for all 4 types
LC2525D:  JSR $4B65      ;random #: 0 to A - 1 , where A is
                         ;the denominator of our probabilities,
                         ;as explained in the data below.
LC25260:  LDX #$04
LC25262:  DEX
LC25263:  CMP $FC,X
LC25265:  BCS LC25262    ;Check next type if A >= $FC,X
LC25267:  PLY
LC25268:  RTS            ;Return X = Battle type / Attack to use


;NOTE: Effective values are all 1 greater than those listed in C2/5269
; through C2/527C [with FFh wrapping to 00h].)

;Each effective value is the Numerator of the probability of getting a
; certain type of Umaro attack, in the order: Normal attack, Charge/Tackle,
; Storm, Throw character)
;Denominator of the probability is the sum of the effective values.)
LC25269: dd $FFFF5F9E    ;(No Rage Ring or Blizzard Orb)
LC2526D: dd $5FFF3F5E    ;(Rage Ring)
LC25271: dd $FF5F3F5E    ;(Blizzard Orb)
LC25275: dd $3F3F3F3E    ;(Both)

;Each effective value is the Numerator of probability of getting a
; certain type of attack formation, in the order: Side, Pincer,
; Back, Normal/Front)
;Denominator of the probability is the sum of the effective values,
; excluding those of formations that were skipped at C2/5250 due
; to not being allowed.)
LC25279: dd $CF07071E    ;(For choosing type of battle)



;Gray out or enable character commands based on various criteria, such as: whether
; current equipment supports them, whether the character is inflicted with Imp or
; Mute, and whether they've accumulated enough Magic Points to Morph.
; This function also enables Offering to change the aiming of Fight and Capture.)

LC2527D:  PHX
LC2527E:  PHP
LC2527F:  REP #$30       ;Set 16-bit A, X and Y
LC25281:  TXY
LC25282:  LDA $C2544A,X  ;Get address of character's menu
LC25286:  TAX
LC25287:  SEP #$20       ;Set 8-bit Accumulator
LC25289:  LDA $3018,Y
LC2528C:  TSB $3A58      ;flag this character's main menu to be redrawn
                         ;right away
LC2528F:  LDA $3EE4,Y
LC25292:  AND #$20
LC25294:  STA $EF        ;if Imp status possessed, turn on Bit 5 of $EF.
                         ;if not, the variable is set to 0.
LC25296:  LDA $3BA4,Y    ;weapon properties, right hand
LC25299:  ORA $3BA5,Y    ;merge with weapon properties, left hand
LC2529C:  EOR #$FF       ;invert
LC2529E:  AND #$82
LC252A0:  TSB $EF        ;if neither hand supports Runic, set Bit 7.
                         ;if neither hand supports SwdTech, set Bit 1.
LC252A2:  LDA #$04
LC252A4:  STA $EE        ;counter variable.. we're going to check
                         ;4 menu slots in all
LC252A6:  PHX            ;push address of character's current menu slot
LC252A7:  SEC            ;mark menu slot to be disabled
LC252A8:  TDC            ;clear 16-bit A
LC252A9:  LDA $0000,X    ;get command # in current menu slot
LC252AC:  BMI LC252DB    ;branch if slot empty
LC252AE:  PHA            ;push command #
LC252AF:  CLC            ;mark menu slot to be enabled
LC252B0:  LDA $EF
LC252B2:  BIT #$20       ;are they an Imp?
LC252B4:  BEQ LC252C3    ;branch if not
LC252B6:  LDA $01,S
LC252B8:  ASL            ;command # * 2
LC252B9:  TAX
LC252BA:  LDA $CFFE00,X  ;table of command info
LC252BE:  BIT #$04       ;is command supported while Imped?
LC252C0:  BNE LC252C3    ;branch if so
LC252C2:  SEC            ;mark menu slot to be disabled
LC252C3:  PLA            ;fetch command #
LC252C4:  BCS LC252DB    ;if menu slot is disabled at this point,
                         ;don't bother with our next checks

;This next loop sees if our current command is one that needs special code to assess
; its menu availability -- graying it if unavailable -- or another property, such as
; its aiming.  If so, a special function is called for the command.)

LC252C6:  LDX #$0007
LC252C9:  CMP $C252E9,X  ;does our current command match one whose menu
                         ;availability or aiming can vary?
LC252CD:  BNE LC252D7    ;if not, compare it to next command in table
LC252CF:  TXA
LC252D0:  ASL
LC252D1:  TAX
LC252D2:  JSR ($52F1,X)  ;call special function for command
LC252D5:  BRA LC252DB    ;we've gotten a match, so there's no need to
                         ;compare our current command against rest of list
LC252D7:  DEX
LC252D8:  BPL LC252C9    ;there are 8 possible commands that need
                         ;special checks
LC252DA:  CLC            ;if there was no match, default to enabling the
                         ;menu slot
LC252DB:  PLX
LC252DC:  ROR $0001,X    ;2nd byte of current menu slot will have Bit 7 set
                         ;if the slot should be grayed out and unavailable.
                         ;iow, Carry = 1 -> grayed.  Carry = 0 -> enabled.
LC252DF:  INX
LC252E0:  INX
LC252E1:  INX            ;point to next slot in character's menu
LC252E2:  DEC $EE
LC252E4:  BNE LC252A6    ;repeat process for all 4 menu slots
LC252E6:  PLP
LC252E7:  PLX
LC252E8:  RTS


;Data - commands that can potentially get grayed out on the menu in battle,
; or have a property like their aiming altered.)

LC252E9: db $03    ;(Morph)
LC252EA: db $0B    ;(Runic)
LC252EB: db $07    ;(SwdTech)
LC252EC: db $0C    ;(Lore)
LC252ED: db $17    ;(X-Magic)
LC252EE: db $02    ;(Magic)
LC252EF: db $06    ;(Capture)
LC252F0: db $00    ;(Fight)


;Data - addresses of functions to check whether above command should be
; enabled, disabled, or otherwise modified on battle menu)

LC252F1: dw $5326   ;(Morph)
LC252F3: dw $5322   ;(Runic)
LC252F5: dw $531D   ;(SwdTech)
LC252F7: dw $5314   ;(Lore)
LC252F9: dw $5314   ;(X-Magic)
LC252FB: dw $5314   ;(Magic)
LC252FD: dw $5301   ;(Capture)
LC252FF: dw $5301   ;(Fight)


;For Capture and Fight menu slots

LC25301:  LDA $3C58,Y    ;Check for offering
LC25304:  LSR
LC25305:  BCC LC25313    ;Exit if no Offering
LC25307:  REP #$21       ;Set 16-bit Accumulator.  Clear Carry to enable
                         ;menu slot.
LC25309:  LDA $03,S
LC2530B:  TAX            ;get address of character's current menu slot
LC2530C:  SEP #$20       ;Set 8-bit Accumulator
LC2530E:  LDA #$4E
LC25310:  STA $0002,X    ;update aiming byte: Cursor start on enemy,
                         ;Auto select one party, Auto select both parties
                         ;[in this case, that means you'll target both enemy
                         ;clumps in a Pincer], and One side only.
LC25313:  RTS


;For Lore, X-Magic, and Magic menu slots

LC25314:  LDA $3EE5,Y
LC25317:  BIT #$08       ;is character Muted?
LC25319:  BEQ LC2531C    ;branch if not
LC2531B:  SEC            ;if they are, mark menu slot to be disabled?
LC2531C:  RTS


;For SwdTech menu slot

LC2531D:  LDA $EF
LC2531F:  LSR
LC25320:  LSR            ;Carry = Bit 1, which was set in function C2/527D
LC25321:  RTS            ;if it was set, menu slot will be disabled..
                         ;if it wasn't, slot is enabled


;For Runic menu slot

LC25322:  LDA $EF
LC25324:  ASL            ;Carry = Bit 7, which was set in function C2/527D
LC25325:  RTS            ;if it was set, menu slot will be disabled..
                         ;if it wasn't, slot is enabled

;For Morph menu slot

LC25326:  LDA #$0F
LC25328:  CMP $1CF6      ;compare to Morph supply
LC2532B:  RTS            ;if Morph supply isn't at least 16, menu slot will
                         ;be disabled..  if it's >=16, slot is enabled


;Change character commands when wearing MagiTek armor or visiting Fanatics' Tower.
; Change commands based on relics, such as Fight becoming Jump, or Steal becoming Capture.
; Blank or retain certain commands, depending on whether they should be available -- e.g.
;   no known dances means no Dance command.)
;Zero character MP if they have no Lore command, no Magic/X-Magic with at least one spell
;   learned, and no Magic/X-Magic with an Esper equipped.)

LC2532C:  PHX
LC2532D:  PHP
LC2532E:  REP #$30       ;Set 16-bit A, X, and Y
LC25330:  LDY $3010,X    ;get offset to character info block
LC25333:  LDA $C2544A,X  ;get address of character's menu
LC25337:  STA $002181    ;this means that future writes to $00218n in this function
                         ;will modify that character's menu?
LC2533B:  LDA $1616,Y    ;1st and 2nd menu slots
LC2533E:  STA $FC
LC25340:  LDA $1618,Y    ;3rd and 4th menu slots
LC25343:  STA $FE
LC25345:  LDA $1614,Y    ;out of battle Status Bytes 1 and 2; correspond
                         ;to in-battle Status Bytes 1 and 4
LC25348:  SEP #$30       ;Set 8-bit A, X, and Y
LC2534A:  BIT #$08       ;does character have MagiTek?
LC2534C:  BNE LC25354    ;branch if so
LC2534E:  LDA $3EBB      ;Fanatics' Tower?  must verify this.
LC25351:  LSR
LC25352:  BCC LC2539D    ;branch if neither MagiTek nor Fanatics' Tower
LC25354:  LDA $3ED8,X    ;get character index
LC25357:  XBA
LC25358:  LDX #$03       ;point to 4th menu slot
LC2535A:  LDA $FC,X      ;get command in menu slot
LC2535C:  CMP #$01
LC2535E:  BEQ LC2539A    ;if Item, skip to next slot
LC25360:  CMP #$12
LC25362:  BEQ LC2539A    ;if Mimic, skip to next slot
LC25364:  XBA            ;retrieve character index
LC25365:  CMP #$0B
LC25367:  BNE LC25371    ;branch if not Gau
LC25369:  XBA            ;get command again
LC2536A:  CMP #$10
LC2536C:  BNE LC25370    ;branch if not Rage
LC2536E:  LDA #$00       ;load Fight command into A so that Gau's Rage will get replaced
                         ;by MagiTek too.  why not just replace "BNE LC25370 / LDA #$00"
                         ;with "BEQ formerly_$5376" ??  you got me..
LC25370:  XBA
LC25371:  XBA            ;once more, command is in bottom of A, character index in top
LC25372:  CMP #$00       ;Fight?
LC25374:  BNE LC2537A    ;branch if not.  if it is Fight, we'll replace it with MagiTek
LC25376:  LDA #$1D
LC25378:  BRA LC25380    ;go store MagiTek command in menu slot
LC2537A:  CMP #$02
LC2537C:  BEQ LC25380    ;if Magic, branch..  which just keeps Magic as command?
                         ;rewriting it seems inefficient, unless i'm missing
                         ;something.

LC2537E:  LDA #$FF       ;empty command
LC25380:  STA $FC,X      ;update this menu slot
LC25382:  LDA $3EBB      ;Fanatics' Tower?  must verify this.
LC25385:  LSR
LC25386:  BCC LC2539A    ;branch if not in the tower
LC25388:  LDA $FC,X      ;get menu slot again
LC2538A:  CMP #$02
LC2538C:  BEQ LC25396    ;branch if Magic command, emptying slot.
LC2538E:  CMP #$1D       ;MagiTek?  actually, this is former Fight or Gau+Rage.
LC25390:  BNE LC25398    ;branch if not
LC25392:  LDA #$02
LC25394:  BRA LC25398    ;save Magic as command
LC25396:  LDA #$FF       ;empty command
LC25398:  STA $FC,X      ;update menu slot
LC2539A:  DEX
LC2539B:  BPL LC2535A    ;loop for all 4 slots

LC2539D:  TDC            ;clear 16-bit A
LC2539E:  STA $F8
LC253A0:  STA $002183    ;will write to Bank 7Eh in WRAM
LC253A4:  TAY            ;Y = 0

LC253A5:  LDA $00FC,Y    ;get command from menu slot
LC253A8:  LDX #$04
LC253AA:  PHA            ;Put on stack
LC253AB:  LDA #$04
LC253AD:  STA $EE        ;start checking Bit 2 of variable $11D6
LC253AF:  LDA $C25452,X  ;commands that can be changed FROM
LC253B3:  CMP $01,S      ;is current command one of those commands?
LC253B5:  BNE LC253C4    ;branch if not
LC253B7:  LDA $11D6      ;check Battle Effects 1 byte.
                         ;Bit 2 = Fight -> Jump, Bit 3 = Magic -> X-Magic,
                         ;Bit 4 = Sketch -> Control, Bit 5 = Slot -> GP Rain,
                         ;Bit 6 = Steal -> Capture
LC253BA:  BIT $EE
LC253BC:  BEQ LC253C4
LC253BE:  LDA $C25457,X  ;commands to change TO
LC253C2:  STA $01,S      ;replace command on stack
LC253C4:  ASL $EE        ;will check the next highest bit of $11D6
                         ;in our next iteration
LC253C6:  DEX
LC253C7:  BPL LC253AF    ;loop for all 5 possible commands that can be
                         ;converted

;This next loop sees if our current command is one that needs special code to assess
; its menu availability -- blanking it if unavailable -- or do some other tests.  If so,
; a special function is called for the command.)

LC253C9:  LDA $01,S      ;get current command
LC253CB:  LDX #$05
LC253CD:  CMP $C25468,X  ;is it one of the commands that can be blanked from menu
                         ;or have other miscellaneous crap done?
LC253D1:  BNE LC253DB    ;branch if not
LC253D3:  TXA
LC253D4:  ASL
LC253D5:  TAX            ;X = X * 2
LC253D6:  JSR ($545C,X)  ;call special function for command
LC253D9:  BRA LC253DE    ;we've gotten a match, so there's no need to
                         ;compare our current command against rest of list
LC253DB:  DEX
LC253DC:  BPL LC253CD    ;there are 6 possible commands that need
                         ;special checks
LC253DE:  PLA            ;restore command #, which may've been nulled by our
;                                     LC2545C special function)
LC253DF:  STA $002180    ;save command # in first menu byte
LC253E3:  STA $002180    ;save command # again in second menu byte..  all i know
                         ;about this byte is that the top bit will be set if the
                         ;menu option is unavailable [blank or gray]
LC253E7:  ASL
LC253E8:  TAX            ;X = command * 2, will let us index a command table
LC253E9:  TDC            ;clear 16-bit A
LC253EA:  BCS LC253F0    ;branch if command # was negative.  this will put
                         ;zero into the menu aiming
LC253EC:  LDA $CFFE01,X  ;get command's aiming
LC253F0:  STA $002180    ;store it in a third menu byte
LC253F4:  INY
LC253F5:  CPY #$04       ;loop for all 4 menu slots
LC253F7:  BNE LC253A5
LC253F9:  LSR $F8        ;Carry gets set if character has Magic/X-Magic command
                         ;and at least one spell known, Magic/X-Magic and an
                         ;Esper equipped, or if they simply have Lore.
LC253FB:  BCS LC25408
LC253FD:  LDA $02,S      ;retrieve the X value originally passed to the function.
                         ;iow, the index of the party member whose menu is being
                         ;examined
LC253FF:  TAX
LC25400:  REP #$20       ;Set 16-bit A
LC25402:  STZ $3C08,X    ;zero MP
LC25405:  STZ $3C30,X    ;zero max MP
LC25408:  PLP
LC25409:  PLX
LC2540A:  RTS


;Morph menu entry

LC2540B:  LDA #$04
LC2540D:  BIT $3EBC      ;set after retrieving Terra from Zozo -- allows
                         ;Morph command
LC25410:  BEQ LC25434    ;if not set, go null out command
LC25412:  BIT $3EBB      ;set only for Phunbaba battle #4 [i.e. Terra's second
                         ;Phunbaba encounter]
LC25415:  BEQ LC25438    ;if not Phunbaba, just keep command enabled
LC25417:  LDA $05,S      ;get the X value originally passed to function C2/532C.
                         ;iow, the index of the party member whose menu is being
                         ;examined
LC25419:  TAX
LC2541A:  LDA $3DE9,X
LC2541D:  ORA #$08
LC2541F:  STA $3DE9,X    ;Cause attack to set Morph
LC25422:  LDA #$FF
LC25424:  STA $1CF6      ;set Morph supply to maximum
LC25427:  BRA LC25434    ;by nulling Morph command in menu, we'll stop Terra from
                         ;Morphing again and from Reverting?


;Magic and X-Magic menu entry

;Blank out Magic/X-Magic menu if no spells are known and no Esper is equipped

LC25429:  LDA $F6        ;# of spells learnt
LC2542B:  BNE LC25445    ;if some are, branch and set a flag
LC2542D:  LDA $F7        ;index of Esper equipped.  this value starts with 0
                         ;for Ramuh, and the order matches the Espers' order in
                         ;the spell list.  FFh means nothing's equipped
LC2542F:  INC
LC25430:  BNE LC25445    ;branch if an Esper equipped
LC25432:  BNE LC25438    ;Dance and Leap jump here.  obviously, this branch
                         ;is never taken if we called this function for Magic
                         ;or X-Magic.
LC25434:  LDA #$FF
LC25436:  STA $03,S      ;replace current command with empty
LC25438:  RTS


;Dance menu entry

LC25439:  LDA $1D4C      ;bitfield of known Dances
LC2543C:  BRA LC25432    ;if none are, menu entry will be nulled after branch


;Leap menu entry

LC2543E:  LDA $11E4
LC25441:  BIT #$02       ;is Leap available?
LC25443:  BRA LC25432    ;if it's not, menu entry will be nulled after branch


;Lore menu entry

LC25445:  LDA #$01
LC25447:  TSB $F8        ;this will stop character's Current MP and Max MP from
                         ;getting zeroed in calling function.  Lore always does
                         ;this, whereas Magic and X-Magic have conditions..
                         ;Also note that Lore never checks whether the menu command
                         ;should be available, as Strago knows 3 Lores at startup
LC25449:  RTS


;Data - addressed by index of character onscreen -- 0, 2, 4, or 6
;Points to each of their menus, which are 4 entries, 3 bytes per entry.)
LC2544A: dw $202E
LC2544C: dw $203A
LC2544E: dw $2046
LC25450: dw $2052


;Data - commands that can be replaced with other commands thanks to Relics

LC25452: db $05   ;(Steal)
LC25453: db $0F   ;(Slot)
LC25454: db $0D   ;(Sketch)
LC25455: db $02   ;(Magic)
LC25456: db $00   ;(Fight)


;Data - commands that can replace above commands due to Relics

LC25457: db $06   ;(Capture)
LC25458: db $18   ;(GP Rain)
LC25459: db $0E   ;(Control)
LC2545A: db $17   ;(X-Magic)
LC2545B: db $16   ;(Jump)


;Pointers - functions to remove commands from in-battle menu, or to make
; miscellaneous adjustments)

LC2545C: dw $540B   ;(Morph)
LC2545E: dw $543E   ;(Leap)
LC25460: dw $5439   ;(Dance)
LC25462: dw $5429   ;(Magic)
LC25464: dw $5429   ;(X-Magic)
LC25466: dw $5445   ;(Lore)


;Data - commands that can be removed from menu in some circumstances, or otherwise
; need special functions.)

LC25468: db $03   ;(Morph)
LC25469: db $11   ;(Leap)
LC2546A: db $13   ;(Dance)
LC2546B: db $02   ;(Magic)
LC2546C: db $17   ;(X-Magic)
LC2546D: db $0C   ;(Lore)


;Construct in-battle Item menu, equipment sub-menus, and possessed Tools bitfield,
; based off of equipped and possessed items.)

LC2546E:  PHP
LC2546F:  REP #$30     ;(Set 16-bit Accumulator, 16-bit X and Y
LC25471:  LDY #$2BAD   ;(start pointing to the last byte of the 2nd
                       ; equipment menu hand slot of the 4th character.
                       ; C2/54CD uses MVN, so we'll be counting
                       ; backwards until reaching $2686, the first Item
                       ; menu slot.
LC25474:  LDA #$0001
LC25477:  STA $2E75
LC2547A:  LDX #$0006
LC2547D:  PHY
LC2547E:  LDY $3010,X  ;(get offset to character info block
LC25481:  LDA $1620,Y  ;(get 2nd Arm equipment
LC25484:  PLY
LC25485:  JSR $54CD    ;(Copy info of item held in A to a 5-byte buffer,
                       ; spanning $2E72 - $2E76.  Then copy buffer to
                       ; our current menu position.
LC25488:  DEX
LC25489:  DEX
LC2548A:  BPL LC2547D  ;(iterate for all 4 characters
LC2548C:  LDX #$0006
LC2548F:  PHY
LC25490:  LDY $3010,X  ;(get offset to character info block
LC25493:  LDA $161F,Y  ;(get 1st Arm equipment
LC25496:  PLY
LC25497:  JSR $54CD    ;(Copy info of item held in A to a 5-byte buffer,
                       ; spanning $2E72 - $2E76.  Then copy buffer to
                       ; our current menu position.
LC2549A:  DEX
LC2549B:  DEX
LC2549C:  BPL LC2548F  ;(iterate for all 4 characters
LC2549E:  LDX #$00FF
LC254A1:  LDA $1969,X  ;(get item quantity
LC254A4:  STA $2E75
LC254A7:  LDA $1869,X  ;(get item
LC254AA:  JSR $54CD    ;(Copy info of item held in A to a 5-byte buffer,
                       ; spanning $2E72 - $2E76.  Then copy buffer to
                       ; our current menu position.
LC254AD:  DEX
LC254AE:  BPL LC254A1  ;(loop for all 256 items
LC254B0:  SEP #$30     ;(Set 8-bit Accumulator, 8-bit X and Y
LC254B2:  TDC
LC254B3:  TAY
LC254B4:  LDA $1869,Y  ;(get item in first slot
LC254B7:  CMP #$A3
LC254B9:  BCC LC254C8  ;(if it's < 163 [NoiseBlaster], branch
LC254BB:  SBC #$A3     ;(get a Tool index, where NoiseBlaster = 0, etc
LC254BD:  CMP #$08
LC254BF:  BCS LC254C8  ;(if it's >= 171 [iow, not a tool], branch
LC254C1:  TAX
LC254C2:  JSR $1E57    ;(Sets bit #X in A
LC254C5:  TSB $3A9B    ;(Set bit N for Tool N
LC254C8:  INY
LC254C9:  BNE LC254B4  ;(loop for all 256 item slots
LC254CB:  PLP
LC254CC:  RTS


;Copy info of item held in A to a 5-byte buffer, spanning $2E72 - $2E76.  Then
; copy buffer to a range whose end address is indicated by Y.)

LC254CD:  PHX
LC254CE:  JSR $54DC
LC254D1:  LDX #$2E76
LC254D4:  LDA #$0004
LC254D7:  MVP $7E7E
LC254DA:  PLX
LC254DB:  RTS


;Copy info of item held in A to a 5-byte buffer, spanning $2E72 - $2E76.
; Callers set $2E75 quantity themselves.)

LC254DC:  PHX
LC254DD:  PHP
LC254DE:  REP #$10       ;Set 16-bit X and Y
LC254E0:  SEP #$20       ;set 8-bit Accumulator
LC254E2:  PHA            ;Put on stack
LC254E3:  LDA #$80
LC254E5:  STA $2E73      ;assume item is unusable/unselectable (?) in battle
LC254E8:  LDA #$FF
LC254EA:  STA $2E76      ;assume item can't be equipped by any onscreen characters
LC254ED:  PLA
LC254EE:  STA $2E72      ;save the Item #
LC254F1:  CMP #$FF       ;is it item #255, aka Empty?
LC254F3:  BEQ LC25546    ;if so, Exit function
LC254F5:  XBA
LC254F6:  LDA #$1E
LC254F8:  JSR $4781      ;Multiply by 30, size of item block
                         ;JSR $2B63?
LC254FB:  TAX
LC254FC:  LDA $D8500E,X  ;Get Item targeting
LC25500:  STA $2E74
LC25503:  LDA $D85000,X  ;Get Item type
;	 			(	            Item Type:
;				00: Tool       04: Hat    |   10: Can be thrown
;				01: Weapon     05: Relic  |   20: Usable as an item in battle
;				02: Armor      06: Item   |   40: Usable on the field (Items only)
;				03: Shield  )

LC25507:  PHA            ;Put on stack
LC25508:  PHA            ;Put on stack
LC25509:  ASL
LC2550A:  ASL            ;item type * 4
LC2550B:  AND #$80       ;isolate whether Usable as item in battle
LC2550D:  TRB $2E73      ;clear corresponding bit
LC25510:  PLA            ;get unshifted item type
LC25511:  ASL
LC25512:  AND #$20       ;isolate can be thrown
LC25514:  TSB $2E73      ;set corresponding bit
LC25517:  TDC
LC25518:  PLA            ;get unshifted item type
LC25519:  AND #$07       ;isolate classification
LC2551B:  PHX
LC2551C:  TAX
LC2551D:  LDA $C25549,X  ;get a value indexed by item type
LC25521:  PLX
LC25522:  ASL            ;multiply by 2
LC25523:  TSB $2E73      ;turn on corresponding bits
LC25526:  BCS LC25546    ;if top bit was set, branch to end of function.
                         ;only Weapon, Shield and Item classifications have
                         ;it unset.
                         ;maybe this controls whether an Item is selectable
                         ;under a given character's Item menu?

;!? why should items of Classification Item ever reach here?!

LC25528:  REP #$21       ;Set 16-bit Accumulator, clear carry
LC2552A:  STZ $EE
LC2552C:  LDA $D85001,X  ;Get Item's equippable characters
LC25530:  LDX #$0006
LC25533:  BIT $3A20,X    ;$3A20,X has bit Z set, where Z is the actual Character #
                         ;of the current onscreen character indexed by X.  don't
                         ;think $3A20 is defined for characters >= 0Eh
LC25536:  BNE LC25539    ;branch if character can equip the item
LC25538:  SEC            ;the current onscreen character can't equip the item
LC25539:  ROL $EE
LC2553B:  DEX
LC2553C:  DEX
LC2553D:  BPL LC25533    ;loop for all 4 onscreen characters
LC2553F:  SEP #$20       ;Set 8-bit Accumulator
LC25541:  LDA $EE
LC25543:  STA $2E76      ;so $2E76 should look like:
                         ;Bit 0 = 1, if onscreen character 0 can't equip item
                         ;Bit 1 = 1, if onscreen character 1 can't equip item
                         ;Bit 2 = 1, if onscreen character 2 can't equip item
                         ;Bit 3 = 1, if onscreen character 3 can't equip item
LC25546:  PLP
LC25547:  PLX
LC25548:  RTS


;Data
LC25549: db $A0 ;(Tool)
LC2554A: db $08 ;(Weapon)
LC2554B: db $80 ;(Armor)
LC2554C: db $04 ;(Shield)
LC2554D: db $80 ;(Hat)
LC2554E: db $80 ;(Relic)
LC2554F: db $00 ;(Item)
LC25550: db $00 ;(extra?)


;Generate Lore menus based on known Lores, and generate Magic menus based on spells
; known by ANY character.  C2/568D will eliminate unknown spells and modify costs as
; needed, on a per character basis.)

LC25551:  PHP
LC25552:  LDX #$1A
LC25554:  STZ $30BA,X    ;set "position of spell" for every Esper to 0,
                         ;because the 1-entry Esper menu is always at
                         ;Position 0, just before the Magic menu.
LC25557:  DEX
LC25558:  BPL LC25554    ;iterate for all 27 Espers
LC2555A:  LDA #$FF
LC2555C:  LDX #$35
LC2555E:  STA $11A0,X    ;null out a temporary list
LC25561:  DEX
LC25562:  BPL LC2555E    ;which has 54 entries
LC25564:  LDY #$17       ;there are 24 possible known Lores
LC25566:  LDX #$02
LC25568:  TDC
LC25569:  SEC
LC2556A:  ROR
LC2556B:  BCC LC2556F    ;have we looped a multiple of 8 times yet?
LC2556D:  ROR
LC2556E:  DEX            ;if we're on our 9th/17th, set Bit 7 and repeat
                         ;the process again.
LC2556F:  BIT $1D29,X    ;is current Lore known?
LC25572:  BEQ LC25584    ;branch if not
LC25574:  INC $3A87      ;increment number of known Lores
LC25577:  PHA            ;Put on stack
LC25578:  TYA            ;A = Lore ID
LC25579:  ADC #$37       ;turn it into a position relative to Esper menu,
                         ;which immediately precedes the Magic menu.
LC2557B:  STA $310F,Y    ;save to "list of positions of each lore"
LC2557E:  ADC #$54       ;so now we've converted our 0-23 Lore ID into a
                         ;raw spell ID, as Condemned [8Bh] is the first
                         ;Lore.
LC25580:  STA $306A,Y    ;save spell ID to "list of known Lores"
LC25583:  PLA
LC25584:  DEY
LC25585:  BPL LC2556A    ;iterate 24 times, going through the Lores in
                         ;reverse order
LC25587:  LDX #$06
LC25589:  LDA $3ED8,X    ;get current character
LC2558C:  CMP #$0C
LC2558E:  BCS LC255AE    ;branch if it's Gogo or Umaro or temporary
                         ;chars
LC25590:  XBA
LC25591:  LDA #$36
LC25593:  JSR $4781      ;16-bit A = 54 * character ID
LC25596:  REP #$21
LC25598:  ADC #$1A6E
LC2559B:  STA $F0        ;save address to list of spells this character
                         ;knows and doesn't know
LC2559D:  SEP #$20
LC2559F:  LDY #$35
LC255A1:  LDA ($F0),Y    ;what % of spell is known
LC255A3:  CMP #$FF       ;does this character know the current spell?
LC255A5:  BNE LC255AB    ;branch if not
LC255A7:  TYA
LC255A8:  STA $3034,Y    ;if they do, set this entry in our "spells known
                         ;by any character" list to the spell ID
LC255AB:  DEY            ;go to next spell
LC255AC:  BPL LC255A1    ;loop 54 times, through this list of character's
                         ;known/unknown spells
LC255AE:  DEX
LC255AF:  DEX
LC255B0:  BPL LC25589    ;loop for all 4 characters in party
LC255B2:  LDA $1D54      ;info from Config screen
                         ;Bit 7 = Controller: 0 = Single, 1 = Multiple
                         ;Bit 6 = ???
                         ;Bits 3-5 = Window Color adjustment cursor:
                         ;  000b = Font, 001b = 1st Window component,
                         ;  010b = 2nd Window component, 011b = 3rd ' ' ,
                         ;  100b = 4th ' ' , 101b = 5th ' ' ,
                         ;  110b = 6th ' ' , 111b = 6th ' '
                         ;Bits 0-2 = Magic Order:
                         ;  000b = Healing, Attack, Effect (HAE ,
                         ;  001b = HEA , 010b = AEH, 011b = AHE ,
                         ;  100b = EHA , 101b = EAH
LC255B5:  AND #$07       ;isolate Magic Order
LC255B7:  TAX
LC255B8:  LDY #$35
LC255BA:  LDA $3034,Y    ;get spell #
LC255BD:  CMP #$18       ;compare to 24.  if it's 0-23, it's Attack
                         ;magic [Black].
LC255BF:  BCS LC255C7    ;branch if it's 24 or higher
LC255C1:  ADC $C2574B,X  ;add spell # to amount to adjust Attack
                         ;spells positioning based on current
                         ;Magic Order
LC255C5:  BRA LC255D9
LC255C7:  CMP #$2D       ;compare to 45.  if it's 24-44, it's Effect
                         ;magic [Gray].
LC255C9:  BCS LC255D1    ;branch if it's 45 or higher
LC255CB:  ADC $C25751,X  ;add spell # to amount to adjust Effect
                         ;spells positioning based on current
                         ;Magic Order
LC255CF:  BRA LC255D9
LC255D1:  CMP #$36       ;compare to 54.  if it's 45-53, it's Healing
                         ;magic [White].
LC255D3:  BCS LC255E0    ;branch if it's 54 or higher, which apparently
                         ;means it's not a Magic spell at all.
LC255D5:  ADC $C25757,X  ;add spell # to amount to adjust Healing
                         ;spells positioning based on current
                         ;Magic Order
LC255D9:  PHX            ;preserve Magic Order value
LC255DA:  TAX            ;X = position of spell in menu
LC255DB:  TYA            ;A = spell ID
LC255DC:  STA $11A0,X    ;save to our new, reordered list of "spells
                         ;known by any character"
LC255DF:  PLX            ;get Magic Order
LC255E0:  DEY
LC255E1:  BPL LC255BA    ;loop for all 54 spell positions
LC255E3:  LDA #$FF
LC255E5:  LDX #$35
LC255E7:  STA $3034,X
LC255EA:  DEX
LC255EB:  BPL LC255E7    ;null out the Magic portion of our other temporary list
LC255ED:  TDC
LC255EE:  TAX
LC255EF:  TAY
LC255F0:  LDA $11A0,X
LC255F3:  INC
LC255F4:  BNE LC25602
LC255F6:  LDA $11A1,X
LC255F9:  INC
LC255FA:  BNE LC25602
LC255FC:  LDA $11A2,X
LC255FF:  INC
LC25600:  BEQ LC25617    ;if these three consecutive entries in spell list were
                         ;all null, skip copying all three to other list.  but
                         ;if any have a spell, then copy all three.  this was
                         ;designed to skip one row at a time in FF6j so a given
                         ;spell would always stay in the same column, but the
                         ;list was changed to 2 columns in FF3us without this
                         ;code being adjusted, so the list winds up hard to
                         ;follow.
LC25602:  LDA $11A0,X
LC25605:  STA $3034,Y    ;copy 1st spell ID from one list to another
LC25608:  LDA $11A1,X
LC2560B:  STA $3035,Y    ;copy 2nd spell ID from one list to another
LC2560E:  LDA $11A2,X
LC25611:  STA $3036,Y    ;copy 3rd spell ID from one list to another
LC25614:  INY
LC25615:  INY
LC25616:  INY
LC25617:  INX
LC25618:  INX
LC25619:  INX
LC2561A:  CPX #$36
LC2561C:  BCC LC255F0    ;iterate 18 times, or cover 54 spell entries
LC2561E:  LDX #$35
LC25620:  LDA $3034,X    ;get entry from our reordered, condensed list
                         ;of "spells known by any character"
LC25623:  CMP #$FF
LC25625:  BEQ LC2562D    ;branch if null
LC25627:  TAY            ;Y = spell ID
LC25628:  TXA            ;A = position in list
LC25629:  INC            ;now make it 1-based, because position 0 will
                         ;correspond to an equipped Esper.
LC2562A:  STA $3084,Y    ;save to "list of positions of each spell"
LC2562D:  DEX
LC2562E:  BPL LC25620    ;iterate 54 times
LC25630:  REP #$10
LC25632:  LDX #$004D     ;77.  78 = 54 Magic spells + 24 Lores.
LC25635:  TDC
LC25636:  LDA $3034,X    ;get spell ID
LC25639:  CMP #$FF
LC2563B:  BEQ LC25688    ;branch to next slot if null
LC2563D:  PHA            ;save spell ID
LC2563E:  TAY
LC2563F:  LDA $3084,Y    ;get position of spell relative to Esper menu
LC25642:  REP #$20
LC25644:  ASL
LC25645:  ASL            ;there's 4 bytes per spell entry
LC25646:  SEP #$20
LC25648:  TAY            ;offset relative to Esper menu
LC25649:  LDA $01,S      ;get spell ID
LC2564B:  CMP #$8B       ;are we at least at Condemned, the first lore?
LC2564D:  BCC LC25651    ;branch if not
LC2564F:  SBC #$8B       ;if we are, turn it into a 0-23 Lore ID, rather
                         ;than a raw spell ID
LC25651:  STA $208E,Y    ;output spell or Lore ID to 1st character's menu,
                         ;Byte 1 of 4 for this slot
LC25654:  STA $21CA,Y    ;' ' 2nd character's menu
LC25657:  STA $2306,Y    ;' ' 3rd character's menu
LC2565A:  STA $2442,Y    ;' ' 4th character's menu
LC2565D:  PLA            ;get spell ID
LC2565E:  JSR $5723      ;from spell data, put aiming byte in bottom half
                         ;of A, and MP cost in top half
LC25661:  STA $2090,Y    ;save aiming byte in 1st character's menu, Byte
                         ;3 of 4 for this slot
LC25664:  STA $21CC,Y    ;' ' 2nd character's menu
LC25667:  STA $2308,Y    ;' ' 3rd character's menu
LC2566A:  STA $2444,Y    ;' ' 4th character's menu
LC2566D:  XBA            ;get MP cost
LC2566E:  CPX #$0044     ;are we pointing at Step Mine's menu slot?
LC25671:  BNE LC2567C    ;branch if not
LC25673:  LDA $1864      ;minutes portion of time played, from when main
                         ;menu was last visited.  or seconds remaining,
                         ;if we're in a timed area.
LC25676:  CMP #$1E       ;set Carry if >=30 minutes
LC25678:  LDA $1863      ;hours portion of time played, from when main
                         ;menu was last visited.  or minutes remaining,
                         ;if we're in a timed area.
LC2567B:  ROL            ;MP Cost = [hours * 2] + [minutes DIV 30] or
                         ;unintended [minutes remaining * 2] +
                         ;[seconds remaining DIV 30]
LC2567C:  STA $2091,Y    ;save MP cost in 1st character's menu, Byte
                         ;4 of 4 for this slot
LC2567F:  STA $21CD,Y    ;' ' 2nd character's menu
LC25682:  STA $2309,Y    ;' ' 3rd character's menu
LC25685:  STA $2445,Y    ;' ' 4th character's menu
LC25688:  DEX
LC25689:  BPL LC25635    ;iterate 78 times, for all Magic and Lore menu
                         ;slots
LC2568B:  PLP
LC2568C:  RTS


;Generate a character's Esper menu, blank out unknown spells from their Magic menu,
; and adjust spell and Lore MP costs based on equipped Relics.)

LC2568D:  PHX
LC2568E:  PHP
LC2568F:  REP #$10
LC25691:  LDA $3C45,X
LC25694:  STA $F8        ;copy "Relic Effects 2" byte
LC25696:  STZ $F6        ;start off assuming known Magic spell quantity of 0
LC25698:  LDY $302C,X
LC2569B:  STY $F2        ;copy starting address of character's Magic menu
                         ;[Esper menu, to be precise]
LC2569D:  INY
LC2569E:  INY
LC2569F:  INY
LC256A0:  STY $F4        ;save address of MP cost of first spell
LC256A2:  LDY $3010,X    ;get offset to character info block
LC256A5:  LDA $161E,Y    ;get equipped Esper
LC256A8:  STA $F7        ;save it
LC256AA:  BMI LC256C7
LC256AC:  STA $3344,X    ;if it's not null, save it again
LC256AF:  LDY $F2
LC256B1:  STA $0000,Y    ;store Esper ID in Esper menu, which is the first
                         ;slot before the Magic menu and then the Lore menu
LC256B4:  CLC
LC256B5:  ADC #$36       ;convert it to a raw spell ID
LC256B7:  JSR $5723      ;put spell aiming byte in bottom half of A,
                         ;MP cost in top
LC256BA:  STA $0002,Y    ;save aiming byte in menu data
LC256BD:  STA $3345,X
LC256C0:  XBA            ;get spell MP cost
LC256C1:  JSR $5736      ;change it if Gold Hairpin or Economizer equipped
LC256C4:  STA $0003,Y    ;save updated MP cost
LC256C7:  TDC
LC256C8:  TAY            ;A = 0, Y = 0
LC256C9:  LDA $3ED8,X
LC256CC:  CMP #$0C
LC256CE:  BEQ LC256E5    ;branch if the character is Gogo
LC256D0:  INY
LC256D1:  INY            ;Y = 2
LC256D2:  BCS LC256E5    ;branch if Umaro or a temporary character
LC256D4:  INY
LC256D5:  INY            ;Y = 4
LC256D6:  XBA
LC256D7:  LDA #$36
LC256D9:  JSR $4781      ;16-bit A = character # * 54
LC256DC:  REP #$21       ;Set 16-bit A, clear Carry
LC256DE:  ADC #$1A6E     ;gives address of list of spells known/unknown by this
                         ;character
LC256E1:  STA $F0
LC256E3:  SEP #$20       ;Set 8-bit A
LC256E5:  TYX
LC256E6:  LDY #$0138     ;we can loop through 78 spell menu entries [each taking
                         ;4 bytes].  54 Magic spells + 24 Lores = 78
LC256E9:  TDC
LC256EA:  LDA ($F2),Y    ;get spell #
LC256EC:  CMP #$FF
LC256EE:  BEQ LC2570E    ;branch if no spell available in this menu slot
LC256F0:  CPY #$00DC     ;are we pointing to the first slot on the Lore menu
                         ;[our 55th slot overall]?
LC256F3:  JMP ($575D,X)  ;jump out of the loop..  but the other places can actually
                         ;jump back into it.  Square is crazy like that. :P
LC256F6:  DEY
LC256F7:  DEY
LC256F8:  DEY
LC256F9:  DEY
LC256FA:  BNE LC256E9    ;point to next menu slot, and loop
LC256FC:  PLP
LC256FD:  PLX
LC256FE:  LDA $F6
LC25700:  STA $3CF8,X    ;save number of Magic spells possessed by this character
LC25703:  RTS

LC25704:  BCS LC25716    ;branch if we're pointing to a Lore slot.  otherwise,
                         ;we're pointing to a Magic spell slot.
LC25706:  PHY
LC25707:  TAY
LC25708:  LDA ($F0),Y    ;whether this character knows this spell.  FFh = yes
LC2570A:  PLY
LC2570B:  INC
LC2570C:  BEQ LC25716    ;branch if they do

LC2570E:  TDC
LC2570F:  STA ($F4),Y    ;save 0 as MP cost
LC25711:  DEC
LC25712:  STA ($F2),Y    ;save FFh [null] as spell #
LC25714:  BRA LC256F6    ;reenter our 78-slot loop

LC25716:  BCS LC2571A    ;branch if we're pointing to a Lore slot.  otherwise,
                         ;we're pointing to a Magic spell slot.
LC25718:  INC $F6        ;increment # of known Magic spells
LC2571A:  LDA ($F4),Y    ;get spell's MP cost from menu
LC2571C:  JSR $5736      ;change it if Gold Hairpin or Economizer equipped
LC2571F:  STA ($F4),Y    ;save updated MP cost
LC25721:  BRA LC256F6    ;reenter our 78-slot loop


;From spell data, put MP cost in top of A, and aiming byte in bottom of A

LC25723:  PHX
LC25724:  XBA
LC25725:  LDA #$0E
LC25727:  JSR $4781      ;spell # * 14
LC2572A:  TAX
LC2572B:  LDA $C46AC5,X  ;read MP cost from spell data
LC2572F:  XBA
LC25730:  LDA $C46AC0,X  ;read aiming byte from spell data
LC25734:  PLX
LC25735:  RTS


;Adjust MP cost for Gold Hairpin and/or Economizer.  Obviously, the latter supercedes
; the former.)

LC25736:  XBA            ;put MP cost in top of A
LC25737:  LDA $F8        ;read our copy of "Relic Effects 2" byte
LC25739:  BIT #$20
LC2573B:  BEQ LC25741    ;branch if no Gold Hairpin
LC2573D:  XBA            ;get MP cost
LC2573E:  INC
LC2573F:  LSR            ;MP cost = [MP cost + 1] / 2
LC25740:  XBA            ;look at relics byte again
LC25741:  BIT #$40
LC25743:  BEQ LC25749    ;branch if no Economizer
LC25745:  XBA
LC25746:  LDA #$01       ;MP cost = 1
LC25748:  XBA
LC25749:  XBA            ;return MP cost in bottom of A
LC2574A:  RTS


;Data - amount to shift menu position of certain Magic spells,
; depending on the "Magic Order" chosen in Config menu.
; These values are signed, so anything 80h and above means to
; subtract, i.e. move the spell backwards.)

;For Spells 0 - 23 : Attack, Black
LC2574B: db $09  ;(Healing, Attack, Effect (HAE))
LC2574C: db $1E  ;(Healing, Effect, Attack (HEA))
LC2574D: db $00  ;(Attack, Effect, Healing (AEH))
LC2574E: db $00  ;(Attack, Healing, Effect (AHE))
LC2574F: db $1E  ;(Effect, Healing, Attack (EHA))
LC25750: db $15  ;(Effect, Attack, Healing (EAH))

;For Spells 24 - 44 : Effect, Gray
LC25751: db $09  ;(Healing, Attack, Effect (HAE))
LC25752: db $F1  ;(Healing, Effect, Attack (HEA))
LC25753: db $00  ;(Attack, Effect, Healing (AEH))
LC25754: db $09  ;(Attack, Healing, Effect (AHE))
LC25755: db $E8  ;(Effect, Healing, Attack (EHA))
LC25756: db $E8  ;(Effect, Attack, Healing (EAH))

;For Spells 45 - 53 : White, Healing
LC25757: db $D3  ;(Healing, Attack, Effect (HAE))
LC25758: db $D3  ;(Healing, Effect, Attack (HEA))
LC25759: db $00  ;(Attack, Effect, Healing (AEH))
LC2575A: db $EB  ;(Attack, Healing, Effect (AHE))
LC2575B: db $E8  ;(Effect, Healing, Attack (EHA))
LC2575C: db $00  ;(Effect, Attack, Healing (EAH))


;Pointer table

LC2575D: dw $5716   ;(Gogo)
LC2575F: dw $570E   ;(Umaro or temporary character)
LC25761: dw $5704   ;(normal character, ID 00h - 0Bh)


;Make entries on Esper, Magic, and Lore menus available and lit up or unavailable
; and grayed, depending on whether: the spell is learned [or for the Esper menu,
; an Esper is equipped], the character has enough MP to cast the spell, the
; character is an Imp trying to cast a spell other than Imp)

LC25763:  CPX #$08
LC25765:  BCS LC257A9    ;Exit function if monster
LC25767:  PHX
LC25768:  PHY
LC25769:  PHP
LC2576A:  LDA $3C09,X    ;MP, top byte
LC2576D:  BNE LC25775    ;branch if MP >= 256
LC2576F:  LDA $3C08,X    ;MP, bottom byte
LC25772:  INC
LC25773:  BNE LC25777    ;if MP < 255, branch and save MP cost
                         ;as character MP + 1
LC25775:  LDA #$FF       ;otherwise, set it to 255
LC25777:  STA $3A4C      ;save Caster MP + 1.  capped at 255
LC2577A:  LDA $3EE4,X    ;Status byte 1
LC2577D:  ASL
LC2577E:  ASL
LC2577F:  STA $EF        ;Imp is saved in Bit 7
LC25781:  REP #$10       ;16-bit X and Y registers
LC25783:  LDA $3018,X    ;Holds $01 for character 1, $02 for character 2,
                         ;$04 for character 3, $08 for character 4
LC25786:  LDY $302C,X    ;get starting address of character's Magic menu?
LC25789:  TYX
LC2578A:  SEC
LC2578B:  BIT $3F2E      ;bit is set for characters who don't have Espers
                         ;equipped, or have already used Esper this battle
LC2578E:  BNE LC25793    ;if no Esper equipped or already used, branch with
                         ;Carry Set
LC25790:  JSR $57AA      ;Set Carry if spell's unavailable due to Impage or
                         ;insufficient MP.  Clear Carry otherwise.
LC25793:  ROR $0001,X    ;put Carry into bit 7 of 2nd byte of menu data.
                         ;if set, it makes spell unavailable on menu.
LC25796:  LDY #$004D
LC25799:  INX
LC2579A:  INX
LC2579B:  INX
LC2579C:  INX            ;point to next spell in menu
LC2579D:  JSR $57AA      ;Set Carry if spell's unavailable due to absence,
                         ;Impage, or insufficient MP.  Clear Carry otherwise.
LC257A0:  ROR $0001,X    ;put Carry into bit 7 of 2nd byte of menu data.
                         ;if set, it makes spell unavailable on menu.
LC257A3:  DEY
LC257A4:  BPL LC25799    ;iterate 78 times: spells plus 24 lores
LC257A6:  PLP
LC257A7:  PLY
LC257A8:  PLX
LC257A9:  RTS


;Set Carry if spell should be disabled due to unavailability, or because
; caster is an Imp and the spell isn't Imp.  If none of these factors
; disable the spell, check the MP cost.)

LC257AA:  LDA $0000,X    ;get spell # from menu
LC257AD:  BMI LC257B9    ;branch if undefined
LC257AF:  XBA
LC257B0:  LDA $EF
LC257B2:  BPL LC257BB    ;branch if character not an Imp
LC257B4:  XBA
LC257B5:  CMP #$23
LC257B7:  BEQ LC257BB    ;branch if spell is Imp
LC257B9:  SEC            ;spell will be unavailable
LC257BA:  RTS


;Set Carry if caster lacks MP to cast spell.
; Clear it if they have sufficient MP.)

LC257BB:  LDA $0003,X    ;get spell's MP cost from menu data
LC257BE:  CMP $3A4C      ;compare to Caster MP + 1, capped at 255
LC257C1:  RTS


;Copies targets in $B8-$B9 to $A2-$A3 and $A4-$A5.
; Sets up attack animation, including making all jump but the last in a Dragon Horn
; sequence send the attacker airborne again.  Sets up "Attacking Opposition" bit.
; Randomizes targets for all jumps but the first with Dragon Horn.)

LC257C2:  PHP
LC257C3:  SEP #$30       ;set 8-bit A, X, Y
LC257C5:  STZ $A0
LC257C7:  TXA            ;get attacker index
LC257C8:  LSR            ;divide by 2.  now we have 0, 1, 2, and 3 for characters,
                         ;and 4, 5, 6, 7, 8, 9 for monsters
LC257C9:  STA $A1        ;save attacker for animation purposes
LC257CB:  CMP #$04
LC257CD:  BCC LC257D1    ;branch if character is attacker
LC257CF:  ROR $A0        ;Bit 7 is set if monster attacker
LC257D1:  LDA $B9        ;get monster targets
LC257D3:  STA $A3
LC257D5:  STA $A5
LC257D7:  LDA $B8        ;get character targets
LC257D9:  STA $A2
LC257DB:  STA $A4
LC257DD:  BNE LC257E3    ;branch if there are character targets
LC257DF:  LDA #$40
LC257E1:  TSB $A0        ;Bit 6 set if there are no character targets
LC257E3:  LDA $A0
LC257E5:  ASL
LC257E6:  BCC LC257EA    ;branch if not monster attacker
LC257E8:  EOR #$80       ;flip "no character targets" bit
                         ;last two instructions can be replaced by "EOR $A0"
LC257EA:  BPL LC257F0    ;next two lines are only executed if:
                         ;- character attacker and no character (i.e. just monster
                         ;  targets
                         ;OR  - monster attacker and character targets
LC257EC:  LDA #$02
LC257EE:  TSB $BA        ;Set "attacking opposition" bit.  Used for criticals
                         ;and reflections.
LC257F0:  LDA #$10
LC257F2:  TRB $B0        ;clear bit 4, which is set at beginning of turn.
LC257F4:  BNE LC257F8    ;branch if wasn't already clear
LC257F6:  TSB $A0        ;if it was, set Bit 4 in another variable.  it apparently
                         ;prevents characters from stepping forward and getting
                         ;circular or triangular pattern around them when casting
                         ;Magic or Lores, an action we don't want to happen more than
                         ;once per turn.
LC257F8:  LDA $3A70      ;# of strikes left for Dragon Horn / Offering / Quadra Slam
LC257FB:  BEQ LC2580A    ;if no more after the current one, exit
LC257FD:  LDA $3A8E      ;set to FFh by Dragon Horn's "jump continuously" attribute
                         ;should be zero otherwise
LC25800:  BEQ LC2580A    ;exit if zero
LC25802:  LDA #$02
LC25804:  TSB $A0        ;animation to send jumper bouncing skyward again
LC25806:  LDA #$60
LC25808:  TSB $BA        ;set Can Beat on Corpses if no Valid Targets Left and
                         ;Randomize Target.  the latter explains why all jumps
                         ;after the first one are random.  these two properties
                         ;will be applied to the *next* strike.
LC2580A:  PLP
LC2580B:  RTS


;Construct Dance and Rage menus, and get number of known Blitzes and highest known
; SwdTech index)

LC2580C:  TDC            ;16-bit A = 0
LC2580D:  LDA $1CF7      ;Known SwdTechs
LC25810:  JSR $520E      ;X = # of known SwdTechs
LC25813:  DEX
LC25814:  STX $2020      ;index of the highest SwdTech acquired.  useful
                         ;to represent it this way because SwdTechs are
                         ;on a continuum.
LC25817:  TDC
LC25818:  LDA $1D28      ;Known Blitzes
LC2581B:  JSR $520E      ;X = # of known Blitzes
LC2581E:  STX $3A80
LC25821:  LDA $1D4C      ;Known Dances
LC25824:  STA $EE
LC25826:  LDX #$07       ;start looking at 8th dance
LC25828:  ASL $EE        ;Carry will be set if current dance is known
LC2582A:  LDA #$FF       ;default to storing null in Dance menu?
LC2582C:  BCC LC2582F    ;branch if dance unknown
LC2582E:  TXA            ;if current dance is known, store its number
                         ;in the menu instead.
LC2582F:  STA $267E,X
LC25832:  DEX
LC25833:  BPL LC25828    ;loop for all 8 Dances
LC25835:  REP #$20       ;Set 16-bit Accumulator
LC25837:  LDA #$257E
LC2583A:  STA $002181    ;save Offset to write to in WRAM
LC2583E:  SEP #$20       ;Set 8-bit Accumulator
LC25840:  TDC
LC25841:  TAY
LC25842:  TAX            ;Clear A, Y, X
LC25843:  STA $002183    ;will write to Bank 7Eh in WRAM
LC25847:  BIT #$07
LC25849:  BNE LC25853    ;if none of bottom 3 bits set, we're on enemy #
                         ;0, 8, 16, etc.  in which case we need to read a new
                         ;rage byte
LC2584B:  PHA            ;Put on stack
LC2584C:  LDA $1D2C,X    ;load current rage byte - 32 bytes total, 8 rages
                         ;per byte
LC2584F:  STA $EE
LC25851:  INX            ;point to next rage byte
LC25852:  PLA
LC25853:  LSR $EE        ;get bottom bit of current rage byte
LC25855:  BCC LC2585E    ;if bit wasn't set, rage wasn't found, so don't
                         ;display it
LC25857:  INC $3A9A      ;# of rages possessed.  used to randomly pick a rage
                         ;in situations like Muddle
LC2585A:  STA $002180    ;store rage in menu
LC2585E:  INC            ;advance to next enemy #
LC2585F:  CMP #$FF
LC25861:  BNE LC25847    ;loop for all eligible enemies, 0 to 254.  we don't loop
                         ;a 256th time for Pugs, which is inaccessible regardless,
                         ;because that would overflow our $3A9A counter
LC25863:  RTS


;Checks for statuses
;Doesn't set carry if any are set
;Carry clear = one or more set
;Carry set = none set

LC25864:  REP #$21       ;Set 16-bit Accumulator, clear Carry
LC25866:  LDA $3EE4,Y    ;Target status byte 1 & 2
LC25869:  AND $05,S
LC2586B:  BNE LC25875
LC2586D:  LDA $3EF8,Y    ;Target status byte 3 & 4
LC25870:  AND $03,S
LC25872:  BNE LC25875
LC25874:  SEC
LC25875:  LDA $01,S
LC25877:  STA $05,S
LC25879:  PLA
LC2587A:  PLA
LC2587B:  SEP #$20       ;Set 8-bit Accumulator
LC2587D:  RTS


;Big ass targeting function.  It's not used to choose targets with the cursor, but
; it can choose targets randomly (for all sorts of reasons), or refine ones previously
; chosen [e.g. with the cursor].  This routine's so important, it uses several
; helper functions.)

LC2587E:  PHX
LC2587F:  PHY
LC25880:  PHP
LC25881:  SEP #$30       ;set 8-bit A, X and Y
LC25883:  LDA $BB        ;targeting byte
LC25885:  CMP #$02       ;does the aiming consist of JUST "one side only?"
                         ;if so, that means we can't do spread-aim, start the
                         ;cursor on the enemy, or move it

LC25887:  BNE LC25895    ;if not, branch
LC25889:  LDA $3018,X
LC2588C:  STA $B8
LC2588E:  LDA $3019,X
LC25891:  STA $B9        ;save attacker as lone target
LC25893:  BRA LC258F6    ;then exit function
LC25895:  JSR $58FA
LC25898:  LDA $BA
LC2589A:  BIT #$40
LC2589C:  BNE LC258B9    ;Branch if randomize targets
LC2589E:  BIT #$08
LC258A0:  BNE LC258A5    ;Branch if Can target dead/hidden entities
LC258A2:  JSR $5A4D      ;Remove dead and hidden targets
LC258A5:  LDA $B8
LC258A7:  ORA $B9
LC258A9:  BEQ LC258B3    ;Branch if no targets
LC258AB:  LDA $BB        ;targeting byte
LC258AD:  BIT #$2C       ;is "manual party select", "autoselect one party", or
                         ;"autoselect both parties" set?  in other words,
                         ;we're checking to see if the spell can be spread
LC258AF:  BEQ LC258ED    ;if not, branch
LC258B1:  BRA LC258F6    ;if so, exit function

;                          (So if there were multiple targets and the targeting byte
;                           allows that, keep our multiple targets.  If there were
;                           somehow multiple targets despite the targeting byte
;                           [I can't think of a cause for this], just choose a
;                           random one at $58ED.  If there was only a single target,
;                           the branch to either $58ED or $58F6 will retain it.)

LC258B3:  LDA $BA
LC258B5:  BIT #$04       ;Don't retarget if target dead/invalid?
LC258B7:  BNE LC258C8    ;if we don't retarget, branch
LC258B9:  JSR $5937      ;Randomize Targets jumps here
LC258BC:  JSR $58FA
LC258BF:  LDA $BA
LC258C1:  BIT #$08
LC258C3:  BNE LC258C8    ;Branch if can target dead/hidden entities
LC258C5:  JSR $5A4D      ;Remove dead and hidden targets
LC258C8:  JSR $59AC      ;refine targets for reflection [sometimes], OR based
                         ;on encounter formation
LC258CB:  LDA $BA
LC258CD:  BIT #$20
LC258CF:  BEQ LC258DE    ;branch if attack doesn't allow us to beat on corpses
LC258D1:  REP #$20       ;Set 16-bit Accumulator
LC258D3:  LDA $B8
LC258D5:  BNE LC258DC    ;branch if there are some targets set
LC258D7:  LDA $3A4E
LC258DA:  STA $B8        ;if there are no targets left, copy them from a
                         ;"backup already-hit targets" word.  this will let
                         ;Offering and Genji Glove and friends beat on corpses
                         ;once all targets have been killed during the
                         ;attacker's turn.
LC258DC:  SEP #$20       ;Set 8-bit Accumulator

;note: if we're at this point, we never did the BIT #$2C target byte check above..
; and we've most likely retargeted thanks to "Randomize targets", or to there being
; no valid targets initially selected)

LC258DE:  LDA $BB        ;targeting byte
LC258E0:  BIT #$0C       ;is "autoselect one party" or "autoselect both parties" set?
                         ;in another words, we're checking for some auto-spread aim
LC258E2:  BNE LC258F6    ;if so, exit function
LC258E4:  BIT #$20       ;is "manual party select" set?  i.e. can the spell be spread
                         ;via L/R button?
LC258E6:  BEQ LC258ED    ;if not, branch
LC258E8:  JSR $4B53      ;if so, do random coinflip
LC258EB:  BCS LC258F6    ;50% of the time, we'll pretend it was spread, so exit
                         ;50% of the time, we'll pretend it kept one target
LC258ED:  REP #$20       ;Set 16-bit Accumulator
LC258EF:  LDA $B8
LC258F1:  JSR $522A      ;Randomly picks a bit set in A
LC258F4:  STA $B8        ;so we pick one random target
LC258F6:  PLP
LC258F7:  PLY
LC258F8:  PLX
LC258F9:  RTS


LC258FA:  PHP
LC258FB:  LDA #$02
LC258FD:  TRB $3A46      ;clear flag
LC25900:  BNE LC25915    ;if it was set [as is the case with the Joker
                         ;Dooms and the Tentacles' Seize drain], branch
                         ;and don't remove any targets
LC25902:  JSR $5917
LC25905:  LDA $BA
LC25907:  BPL LC2590B    ;branch if not abort on characters
LC25909:  STZ $B8        ;clear character targets
LC2590B:  LSR
LC2590C:  BCC LC25915    ;branch if not "Exclude Attacker from targets"
LC2590E:  REP #$20       ;set 16-bit accumulator
LC25910:  LDA $3018,X
LC25913:  TRB $B8        ;clear caster from targets
LC25915:  PLP
LC25916:  RTS


LC25917:  PHP
LC25918:  LDA $2F46      ;untargetable monsters [clear], due to use of script
                         ;Command FB operation 7, or from formation special event.
LC2591B:  XBA
LC2591C:  LDA $3403      ;Seized characters: bit clear for those who are,
                         ;set for those who aren't.
LC2591F:  REP #$20
LC25921:  AND $3A78      ;only include present characters and enemies?
LC25924:  AND $3408
LC25927:  AND $B8        ;only include initial targets
LC25929:  STA $B8        ;save updated targets
LC2592B:  LDA $341A      ;check top bit of $341B
LC2592E:  BPL LC25935    ;branch if not set
LC25930:  LDA $3F2C      ;get Jumpers
LC25933:  TRB $B8        ;remove them from targets
LC25935:  PLP
LC25936:  RTS


;Randomize Targets function.  selects entire monster or character parties (or both at a time,
; returned in $B8 and $B9.  calling function will later refine the targeting.)

;calling the character side 0 and the monster side 1, it looks like this up through C2/598A:
;  side chosen = (monster caster) XOR ;character acting as enemy caster) XOR Charmed XOR
;                "Cursor start on opposition" XOR Muddled )

;values DURING function -- not coming in or leaving it:
; bit 7 of $B8 = side to target. characters = 0, monsters = 1, special/opposing characters = 1
; bit 6 of $B8 = 1: make both sides eligible to target)

LC25937:  STZ $B9        ;clear enemy targets
LC25939:  TDC            ;Accumulator = 0
LC2593A:  CPX #$08       ;set Carry if caster is monster.  note that "caster" can
                         ;also mean "reflector", in which case a good part of
                         ;this function will be skipped.
LC2593C:  ROR
LC2593D:  STA $B8        ;Bits 0-6 = 0.  Bit 7 = 1 if monster caster, 0 if character
LC2593F:  LDA $BA
LC25941:  BIT #$10       ;has Reflection occurred?
LC25943:  BNE LC25986    ;if so, branch, and do just the one flip of $B8's top
                         ;bit..  as a reflected spell always bounces at the party
                         ;opposing the reflector.
                         ;once the spell's already hit the Wall Ring, we
                         ;[generally] don't care about the reflector's status, and
                         ;they're not necessarily the caster anyway.
LC25945:  LDA $3395,X
LC25948:  BMI LC25950    ;Branch if not Charmed
LC2594A:  LDA #$80
LC2594C:  EOR $B8
LC2594E:  STA $B8        ;toggle top bit of $B8
LC25950:  LDA $3018,X
LC25953:  BIT $3A40      ;is caster a special type of character, namely one acting
                         ;as an enemy?  like Gau returning from a Veldt leap, or
                         ;Shadow in the Colosseum.
LC25956:  BEQ LC2595E    ;if not, branch
LC25958:  LDA #$80       ;if so.. here comes another toggle!
LC2595A:  EOR $B8
LC2595C:  STA $B8        ;toggle top bit of $B8
LC2595E:  LDA $BB        ;targeting byte
LC25960:  AND #$0C       ;isolate "Autoselect both parties" and "Autoselect one party"
LC25962:  CMP #$04       ;is "autoselect both parties" the only bit of these two set?
LC25964:  BNE LC2596A    ;if not, branch
LC25966:  LDA #$40
LC25968:  TSB $B8        ;make both monsters and characters targetable
LC2596A:  LDA $BB        ;targeting byte
LC2596C:  AND #$40       ;isolate "cursor start on enemy" [read: OPPOSITION, not
                         ;monster]
LC2596E:  ASL            ;put into top bit of A
LC2596F:  EOR $B8
LC25971:  STA $B8        ;toggle top bit yet again
LC25973:  LDA $3EE4,X    ;Status byte 1
LC25976:  LSR
LC25977:  LSR
LC25978:  BCC LC2597E    ;Branch if not Zombie
LC2597A:  LDA #$40
LC2597C:  TSB $B8        ;make both monsters and characters targetable
LC2597E:  LDA $3EE5,X    ;Status byte 2
LC25981:  ASL
LC25982:  ASL
LC25983:  ASL
LC25984:  BCC LC2598C    ;Branch if not Muddled
LC25986:  LDA #$80
LC25988:  EOR $B8
LC2598A:  STA $B8        ;toggle top bit
LC2598C:  LDA $B8
LC2598E:  ASL
LC2598F:  STZ $B8        ;clear character targets; monsters were cleared at start
                         ;of function
LC25991:  BMI LC25995    ;if target anybody bit is set, branch, as we don't care
                         ;whether monsters or characters were indicated by top bit
LC25993:  BCC LC259A0    ;if target monsters bit was not set, branch
LC25995:  PHP            ;save Carry and Negative flags
LC25996:  LDA #$3F
LC25998:  TSB $B9        ;target all monsters
LC2599A:  LDA $3A40
LC2599D:  TSB $B8        ;target only characters acting as enemies, like Colosseum
                         ;Shadow and Gau returning from a Veldt leap
LC2599F:  PLP            ;restore Carry and Negative flags
LC259A0:  BMI LC259A4    ;if target anybody bit is set, branch, as we don't care
                         ;whether monsters or characters were indicated by top bit
LC259A2:  BCS LC259AB    ;if target monsters bit was set, exit function
LC259A4:  LDA #$0F       ;mark all characters
LC259A6:  EOR $3A40      ;exclude characters acting as enemies from addition
LC259A9:  TSB $B8        ;turn on just normal characters' bits

;bits 7 and 6 |  Results
; -----------------------------------------------------------------------
;    0     0      normal characters
;    1     0      all monsters, special/enemy characters
;    0     1      all monsters, special/enemy characters + normal characters
;    1     1      all monsters, special/enemy characters + normal characters
;							)
LC259AB:  RTS


;If a reflection has occurred AND the initial spellcast had one party aiming at another
; AND the reflector isn't Muddled, then there's a 50% chance the initial caster will
; become the sole target, provided he/she is in the party that's about to be hit by the
; bounce.  The other 50% of the time, the final target is randomly chosen by the end of
; function C2/587E; each member of the party opposing the reflector has the same chance
; of getting hit.)

LC259AC:  LDA $BA
LC259AE:  BIT #$10
LC259B0:  BEQ LC259DA    ;branch if not Reflected
LC259B2:  BIT #$02
LC259B4:  BEQ LC259D9    ;branch if not attacking opposition..  iow,
                         ;is reflectOR an opponent?
LC259B6:  LDA $3EE5,X    ;Status byte 2
LC259B9:  BIT #$20
LC259BB:  BNE LC259D9    ;if this reflector is Muddled, exit function
LC259BD:  JSR $4B53
LC259C0:  BCS LC259D9    ;50% chance of exit function
LC259C2:  PHX
LC259C3:  LDX $3A32      ;get ($78) animation buffer pointer
LC259C6:  LDA $2C5F,X    ;get unique index of ORIGINAL spell caster
                         ;[from animation data]?
LC259C9:  ASL
LC259CA:  TAX            ;multiply by 2 to access their data block
LC259CB:  REP #$20       ;set 16-bit accumulator
LC259CD:  LDA $3018,X
LC259D0:  BIT $B8        ;is original caster a member of the party about
                         ;to be hit by the bounce?
LC259D2:  BEQ LC259D6
LC259D4:  STA $B8        ;if they are, save them as the sole target of
                         ;this bounce
LC259D6:  SEP #$20       ;set 8-bit accumulator
LC259D8:  PLX
LC259D9:  RTS


;Deal with targeting for different encounter formations

;NOTE: I reuse the "Autoselect both parties" description from FF3usME, though
; if "Autoselect one party" is also set, the former becomes "Autoselect both
; CLUSTERS".  Spread-aim spells without this bit set [Haste 2, Slow 2, X-Zone]
; will only be able to target one cluster of your party at a time when it's split
; by a Side attack or one cluster of the monster party when it's split by a Pincer.
; Whereas spells WITH it set [Meteor, Quake] can hit both/all clumps.)

LC259DA:  LDA $BB        ;targeting byte
LC259DC:  AND #$0C       ;isolate "Autoselect both parties" and "Autoselect one party"
LC259DE:  PHA            ;save these bits of targeting byte
LC259DF:  BIT #$04       ;is "Autoselect both parties" set?
LC259E1:  BNE LC25A35    ;if yes, branch
                         ;if not, we'll be unable to hit more than one cluster of
                         ;targets at a time, so take special steps for formations
                         ;like Pincer and Side, which divide targets into these clusters

LC259E3:  LDA $201F      ;get encounter type: 0 = front, 1 = back, 2 = pincer, 3 = side
LC259E6:  CMP #$02
LC259E8:  BNE LC25A0D    ;branch if not pincer
LC259EA:  LDA $2EAD      ;bitfield of enemies in right "clump".
                         ;set in function C1/1588.
LC259ED:  XBA
LC259EE:  LDA $2EAC      ;bitfield of enemies in left "clump".
                         ;set in function C1/1588.
LC259F1:  CPX #$08
LC259F3:  BCC LC259FC    ;branch if attacker is not a monster
LC259F5:  BIT $3019,X    ;is this attacker among enemies on left side
                         ;of pincer?
LC259F8:  BEQ LC25A0B    ;branch if not, and clear left side enemies from targets
LC259FA:  BRA LC25A0A    ;otherwise, branch, and clear right side enemies from
                         ;targets
LC259FC:  BIT $B9        ;are left side enemies among targets?
LC259FE:  BEQ LC25A0D    ;if they aren't, we don't have to choose a side for
                         ;attack, so branch and dont' alter anything.
LC25A00:  XBA
LC25A01:  BIT $B9
LC25A03:  BEQ LC25A0D    ;if right side enemies aren't among targets, we don't have
                         ;to choose a side, so branch and don't alter anything.
LC25A05:  JSR $4B53
LC25A08:  BCC LC25A0B    ;50% branch.  half the time, we clear left side enemies.
                         ;the other half, right side.
LC25A0A:  XBA
LC25A0B:  TRB $B9        ;clear some enemy targets
LC25A0D:  LDA $201F      ;get encounter type: 0 = front, 1 = back, 2 = pincer, 3 = side
LC25A10:  CMP #$03
LC25A12:  BNE LC25A35    ;branch if not side
LC25A14:  LDA #$0C       ;characters 2 and 3, who are on left side
LC25A16:  XBA
LC25A17:  LDA #$03       ;characters 0 and 1, who are on right side
LC25A19:  CPX #$08
LC25A1B:  BCS LC25A24    ;branch if monster attacker
LC25A1D:  BIT $3018,X
LC25A20:  BEQ LC25A33    ;branch if it's a character, and they're not on right side.
                         ;this will clear right side characters from targets.
LC25A22:  BRA LC25A32    ;otherwise, branch and clear left side characters from
                         ;targets
LC25A24:  BIT $B8
LC25A26:  BEQ LC25A35    ;if right side characters aren't among targets, we don't
                         ;have to choose a side, so branch and don't alter anything
LC25A28:  XBA
LC25A29:  BIT $B8
LC25A2B:  BEQ LC25A35    ;if left side characters aren't among targets, we don't
                         ;have to choose a side, so branch and don't alter anything
LC25A2D:  JSR $4B53
LC25A30:  BCC LC25A33    ;50% branch.  half the time, we clear right side characters.
                         ;the other half, left side.
LC25A32:  XBA
LC25A33:  TRB $B8        ;clear some character targets
LC25A35:  PLA            ;retrieve "Autoselect both parties" and "Autoselect one party"
                         ;bits of targeting byte
LC25A36:  CMP #$04       ;was only "Autoselect both parties" set?
LC25A38:  BEQ LC25A4C    ;if so, exit function
LC25A3A:  LDA $B8
LC25A3C:  BEQ LC25A4C    ;if no characters targeted, exit function
LC25A3E:  LDA $B9
LC25A40:  BEQ LC25A4C    ;or if no monsters targeted, exit function

;                         (if we reached here, both monsters and characters are targeted, even
;                          though attack's aiming byte didn't indicate that.)
LC25A42:  JSR $4B5A      ;random # [0..255]
LC25A45:  PHX
LC25A46:  AND #$01       ;reduce random number to 0 or 1
LC25A48:  TAX
LC25A49:  STZ $B8,X      ;clear $B8 [character targets] or $B9 [monster targets] .
                         ;i THINK the only case where C2/5937 would have both
                         ;characters and monsters targeted with "Autoselect both
                         ;parties" unset or "Autoselect one party" set along with it
                         ;is that of a Zombie caster.
LC25A4B:  PLX
LC25A4C:  RTS


;Removes dead (including Zombie/Petrify for monsters, hidden, and absent targets

LC25A4D:  PHX
LC25A4E:  PHP
LC25A4F:  REP #$20
LC25A51:  LDX #$12
LC25A53:  LDA $3018,X
LC25A56:  BIT $B8
LC25A58:  BEQ LC25A7C    ;Branch if not a target
LC25A5A:  LDA $3AA0,X
LC25A5D:  LSR
LC25A5E:  BCC LC25A77    ;branch if target isn't still valid?
LC25A60:  LDA #$00C2
LC25A63:  CPX #$08
LC25A65:  BCS LC25A6A    ;Branch if monster
LC25A67:  LDA #$0080
LC25A6A:  BIT $3EE4,X
LC25A6D:  BNE LC25A77    ;Branch if death status for characters/monsters, or
                         ;Zombie or Petrify for monsters
LC25A6F:  LDA $3EF8,X
LC25A72:  BIT #$2000
LC25A75:  BEQ LC25A7C    ;Branch if not hidden
LC25A77:  LDA $3018,X
LC25A7A:  TRB $B8        ;clear current target
LC25A7C:  DEX
LC25A7D:  DEX
LC25A7E:  BPL LC25A53    ;loop for all monsters and characters
LC25A80:  PLP
LC25A81:  PLX
LC25A82:  RTS


;Called whenever battle timer is incremented.
; Handles various time-based events for entities.  Advances their timers, does
; periodic damage/healing from Poison/Regen/etc., checks for running, and more.)

LC25A83:  LDA $3A91      ;Lower byte of battle time counter equivalent
LC25A86:  INC $3A91      ;increment that counter equiv.
LC25A89:  AND #$0F
LC25A8B:  CMP #$0A
LC25A8D:  BCS LC25AE1    ;Branch if lower nibble of time counter was >= #$0A
                         ;otherwise, A now corresponds to one of the 10
                         ;onscreen entities.
LC25A8F:  ASL
LC25A90:  TAX
LC25A91:  LDA $3AA0,X
LC25A94:  LSR
LC25A95:  BCC LC25AE9    ;Exit if entity not present in battle
LC25A97:  CLC
LC25A98:  LDA $3ADC,X    ;Timer that determines how often timers and time-based
                         ;events will countdown and happen for this entity.
LC25A9B:  ADC $3ADD,X    ;Add ATB multiplier (set at C2/09D2: normally,
                         ;32 if Slowed, 84 if Hasted
LC25A9E:  STA $3ADC,X
LC25AA1:  BCC LC25AE9    ;Exit if timer didn't meet or exceed 256
LC25AA3:  LDA $3AF1,X    ;Get Stop timer, originally set to #$12
                         ;at C2/467D
LC25AA6:  BEQ LC25AB1    ;Branch if it's 0, as that *should* mean the
                         ;entity is not stopped.
LC25AA8:  DEC $3AF1,X    ;Decrement Stop timer
LC25AAB:  BNE LC25AE9    ;did it JUST run down on this tick?  if not, exit
LC25AAD:  LDA #$01
LC25AAF:  BRA LC25B06    ;Set Stop to wear off
                         ;Also decrement Reflect, Freeze, and Sleep timers if
                         ;applicable, and check if any have worn off.  That
                         ;makes no sense, as these timers are stalled on
                         ;all of the Stop timer's preceding ticks; they should
                         ;be stalled during the last one as well.  In contrast,
                         ;an entity's Condemned countdown and Regen/Seizure/etc.
                         ;resume on the tick following the one where its Stop
                         ;timer hits zero -- that's much more consistent with
                         ;the simple concept of time unfreezing *after* Stop
                         ;wears off.

LC25AB1:  LDA $3AA0,X
LC25AB4:  BIT #$10       ;is entity Wounded, Petrified, or Stopped, or is
                         ;somebody else under the influence of Quick?
LC25AB6:  BNE LC25AE9    ;Exit if any are true
LC25AB8:  LDA $3B05,X    ;Condemned counter - originally set at C2/09B4.
                         ;To be clear, this counter is "one off" from the
                         ;actual numerals you'll see onscreen:
                         ;  00 value = numerals disabled
                         ;  01 value = numerals at "00", 02 = "01", 03 = "02",
                         ;  etc.
LC25ABB:  CMP #$02
LC25ABD:  BCC LC25AC9    ;Branch if counter < 2.  [i.e. numerals < "01",
                         ;meaning they're "00" or disabled.]
LC25ABF:  DEC
LC25AC0:  STA $3B05,X    ;decrement counter
LC25AC3:  DEC            ;just think of this second "DEC" as an optimized
                         ;"CMP #$01", as we're not altering the counter.
LC25AC4:  BNE LC25AC9    ;Branch if counter now != 1  [i.e. numerals != "00"]
LC25AC6:  JSR $5BC7      ;Cast Doom when countdown numerals reach 0
LC25AC9:  JSR $5C1B      ;Check if character runs from combat
LC25ACC:  JSR $5B4F      ;Trigger Poison, Seizure, Regen, Phantasm, or
                         ;Tentacle Drain damage
LC25ACF:  TDC
LC25AD0:  JSR $5B06      ;Decrement Reflect, Freeze, and Sleep timers if
                         ;applicable, and check if any have worn off
LC25AD3:  INC $3AF0,X    ;advance this entity's pointer to the next entry
                         ;in the C2/5AEA function table
LC25AD6:  LDA $3AF0,X
LC25AD9:  TXY            ;preserve X in Y
LC25ADA:  AND #$07       ;convert it to 0-7, wrapping as necessary
LC25ADC:  ASL
LC25ADD:  TAX
LC25ADE:  JMP ($5AEA,X)  ;determine which periodic/damage healing type
                         ;will be checked on this entity's next tick.
LC25AE1:  SBC #$0A       ;should only be reached if ($3A91 AND 15 was >= 10
                         ;[i.e. not corresponding to any specific entity]
                         ;at start of function.  now subtract 10.
LC25AE3:  ASL
LC25AE4:  TAX
LC25AE5:  JMP ($5AFA,X)
LC25AE8:  TYX            ;restore X from Y
LC25AE9:  RTS


;Code pointers
;Note: choosing RTS will default to the (monster) entity draining anybody
; it has Seized on its next tick.)

LC25AEA: dw $5B45     ;(Set bit 3 of $3E4C,X - check regen, seizure, phantasm)
LC25AEC: dw $5AE8     ;(RTS)
LC25AEE: dw $5B3B     ;(Set bit 4 of $3E4C,X - check poison)
LC25AF0: dw $5AE8     ;(RTS)
LC25AF2: dw $5B45     ;(Set bit 3 of $3E4C,X - check regen, seizure, phantasm)
LC25AF4: dw $5AE8     ;(RTS)
LC25AF6: dw $5AE8     ;(RTS)
LC25AF8: dw $5AE8     ;(RTS)


;Code pointers

LC25AFA: dw $5BB2     ;(Enemy Roulette completion)
LC25AFC: dw $5BFC     ;(Increment time counters)
LC25AFE: dw $5AE9     ;(RTS)
LC25B00: dw $5AE9     ;(RTS)
LC25B02: dw $5AE9     ;(RTS)
LC25B04: dw $5BD0     ;(Process "ready to run" characters, queue Flee command as needed)


;Decrement Reflect, Freeze, and Sleep timers if applicable, and if any
; have worn off, mark them to be removed.  If A was 1 (rather than 0) going
; into this function, which means Stop just ran out, mark it to be removed.)

LC25B06:  STA $B8
LC25B08:  LDA $3F0C,X    ;Time until Reflect wears off
                         ;Originally set to #$1A at C2/4687
LC25B0B:  BEQ LC25B16    ;branch if timer not active
LC25B0D:  DEC $3F0C,X    ;Decrement Reflect timer
LC25B10:  BNE LC25B16
LC25B12:  LDA #$02
LC25B14:  TSB $B8        ;If Reflect timer reached 0 on this tick,
                         ;set to remove Reflect
LC25B16:  LDA $3F0D,X    ;Time until Freeze wears off
                         ;Originally set to #$22 at C2/4691
LC25B19:  BEQ LC25B24    ;branch if timer not active
LC25B1B:  DEC $3F0D,X    ;Decrement Freeze timer
LC25B1E:  BNE LC25B24
LC25B20:  LDA #$04
LC25B22:  TSB $B8        ;If Freeze timer reached 0 on this tick,
                         ;set to remove Freeze
LC25B24:  LDA $3CF9,X    ;Time until Sleep wears off
                         ;Originally set to #$12 at C2/4633
LC25B27:  BEQ LC25B32    ;branch if timer not active
LC25B29:  DEC $3CF9,X    ;Decrement Sleep timer
LC25B2C:  BNE LC25B32
LC25B2E:  LDA #$08
LC25B30:  TSB $B8        ;If Sleep timer reached 0 on this tick,
                         ;set to remove Sleep
LC25B32:  LDA $B8
LC25B34:  BEQ LC25AE9    ;Exit if we haven't marked any of the
                         ;statuses to be auto-removed
LC25B36:  LDA #$29
LC25B38:  JMP $4E91      ;queue the status removal, in global
                         ;Special Action queue


;Set to check for Poison on this entity's next tick

LC25B3B:  TYX
LC25B3C:  LDA $3E4C,X
LC25B3F:  ORA #$10
LC25B41:  STA $3E4C,X    ;Set bit 4 of $3E4C,X
LC25B44:  RTS


;Set to check for Regen, Seizure, Phantasm on this entity's next tick

LC25B45:  TYX
LC25B46:  LDA $3E4C,X
LC25B49:  ORA #$08
LC25B4B:  STA $3E4C,X    ;Set bit 3 of $3E4C,X
LC25B4E:  RTS


;Trigger Poison, Regen, Seizure, Phantasm, or Tentacle Drain attack

LC25B4F:  LDA #$10
LC25B51:  BIT $3AA1,X
LC25B54:  BNE LC25B4E    ;Exit if bit 4 of $3AA1 is set.  we already
                         ;have some periodic damage/healing queued for
                         ;this entity, so don't queue any more yet.
LC25B56:  LDA $3E4C,X
LC25B59:  BIT #$10
LC25B5B:  BEQ LC25B6B    ;Branch if bit 4 of $3E4C,X is not set
                         ;Check Regen and Seizure and Phantasm if not set,
                         ;Poison if set
LC25B5D:  AND #$EF
LC25B5F:  STA $3E4C,X    ;Clear bit 4 of $3E4C,X
LC25B62:  LDA $3EE4,X    ;Status byte 1
LC25B65:  AND #$04
LC25B67:  BEQ LC25B4E    ;Exit if not poisoned
LC25B69:  BRA LC25B85


;<>Check Seizure, Phantasm, and Regen

LC25B6B:  BIT #$08
LC25B6D:  BEQ LC25B92    ;Branch if bit 3 of $3E4C,X is not set
                         ;Check Tentacle Drain if not set, Seizure and Phantasm
                         ;and Regen if set
LC25B6F:  AND #$F7
LC25B71:  STA $3E4C,X    ;Clear bit 3 of $3E4C,X
LC25B74:  LDA $3EE5,X
LC25B77:  ORA $3E4D,X    ;are Seizure or Phantasm set?
LC25B7A:  AND #$40
LC25B7C:  BNE LC25B85    ;if at least one is, branch
LC25B7E:  LDA $3EF8,X
LC25B81:  AND #$02       ;is Regen set?
LC25B83:  BEQ LC25B4E    ;if not, exit function
LC25B85:  STA $3A7B      ;Set spell) (02 = Regen, 04 = Poison, 40 = Seizure/Phantasm
LC25B88:  LDA #$22
LC25B8A:  STA $3A7A      ;Set command to #$22 - Poison, Regen, Seizure, Phantasm
LC25B8D:  JSR $4EB2      ;queue it, in entity's counterattack and periodic
                         ;damage/healing queue
LC25B90:  BRA LC25BA9


;<>Check Drain from being Seized

LC25B92:  LDY $3358,X
LC25B95:  BMI LC25B4E    ;Exit if monster doesn't have a character seized
LC25B97:  REP #$20       ;Set 16-bit A
LC25B99:  LDA $3018,Y
LC25B9C:  STA $B8        ;Set target to character monster has seized
LC25B9E:  LDA #$002D
LC25BA1:  STA $3A7A      ;Set command to #$2D - drain from being seized
LC25BA4:  SEP #$20       ;Set 8-bit A
LC25BA6:  JSR $4EB2      ;queue it, in entity's counterattack and periodic
                         ;damage/healing queue
LC25BA9:  LDA #$10
LC25BAB:  ORA $3AA1,X
LC25BAE:  STA $3AA1,X    ;Set bit 4 of $3AA1,X.  This bit will prevent us from
                         ;queueing up more than one instance of periodic
                         ;damage/healing (i.e. Poison, Seizure/Phantasm, Regen,
                         ;or Tentacle Drain) at a time for a given entity.
LC25BB1:  RTS


;Enemy Roulette completion

LC25BB2:  LDA $2F43      ;top byte of Enemy Roulette target bitfield, which
                         ;is set at C1/B41A when the cursor winds down.
LC25BB5:  BMI LC25B4E    ;Exit if no targets are defined
LC25BB7:  REP #$20       ;Set 16-bit A
LC25BB9:  LDA $2F42      ;get our chosen target
LC25BBC:  JSR $51F9      ;Y = bit number of highest bit set in A (0 for bit 0,
                         ;2 for bit 1, 4 for bit 2, etc.)
LC25BBF:  TDC
LC25BC0:  DEC            ;A = #$FFFF
LC25BC1:  STA $2F42      ;Set Enemy Roulette targets in $2F42 to null
LC25BC4:  SEP #$20       ;Set 8-bit A
LC25BC6:  TYX
LC25BC7:  LDA #$0D       ;Condemned expiration enters here
LC25BC9:  STA $B8        ;spell = Doom
LC25BCB:  LDA #$26
LC25BCD:  JMP $4E91      ;queue the reaper, in global Special Action queue


;Process "ready to run" characters, queue Flee command as needed

LC25BD0:  LDA $2F45      ;party trying to run: 0 = no, 1 = yes
LC25BD3:  BEQ LC25C1A    ;exit if not
LC25BD5:  LDA $B1
LC25BD7:  BIT #$02       ;is Can't Run set?
LC25BD9:  BNE LC25BF1    ;branch if so
LC25BDB:  LDA $3A91      ;get bottom byte of battle time counter equiv.,
                         ;will have value of NFh here
LC25BDE:  AND #$70
LC25BE0:  BNE LC25C1A    ;7/8 chance of exit
LC25BE2:  LDA $2F45      ;party trying to run.  yes, a duplicate
                         ;check.  it's done because C2/5C1B and C2/11BB
                         ;can branch here.
LC25BE5:  BEQ LC25C1A    ;exit if not trying to run
LC25BE7:  LDA $3A38      ;characters who are ready to run
LC25BEA:  BEQ LC25C1A    ;exit if none
LC25BEC:  LDA $3A97
LC25BEF:  BNE LC25C1A    ;exit if in Colosseum
LC25BF1:  LDA #$04
LC25BF3:  TSB $B0        ;set flag
LC25BF5:  BNE LC25C1A    ;exit if we've already executed this since the
                         ;last time C2/007D was executed, which is at least
                         ;as recent as the last time C2/5C73 was called
LC25BF7:  LDA #$2A
LC25BF9:  JMP $4E91      ;queue (attempted flee command, in global
                         ;Special Action queue


;Increment time counters

LC25BFC:  PHP
LC25BFD:  REP #$20       ;set 16-bit A
LC25BFF:  INC $3A44      ;increment Global battle time counter
LC25C02:  LDX #$12       ;point to last enemy
LC25C04:  LDA $3AA0,X
LC25C07:  LSR
LC25C08:  BCC LC25C15    ;Skip entity if not present in battle
LC25C0A:  LDA $3EE4,X    ;status byte 1
LC25C0D:  BIT #$00C0
LC25C10:  BNE LC25C15    ;branch if petrified or dead
LC25C12:  INC $3DC0,X    ;Increment monster time counter
LC25C15:  DEX
LC25C16:  DEX
LC25C17:  BPL LC25C04    ;loop for all monsters and characters
LC25C19:  PLP
LC25C1A:  RTS


;Check if character runs from combat

LC25C1B:  CPX #$08
LC25C1D:  BCS LC25C53    ;Exit if monster
LC25C1F:  LDA $2F45      ;party trying to run: 0 = no, 1 = yes
LC25C22:  BEQ LC25C53    ;Exit if not trying to run
LC25C24:  LDA $3A39      ;Load characters who've escaped
LC25C27:  ORA $3A40      ;Or with characters acting as enemies
LC25C2A:  BIT $3018,X    ;Is the current character in one or more of
                         ;these groups?
LC25C2D:  BNE LC25C53    ;Exit if so
LC25C2F:  LDA $3A3B      ;Get the Run Difficulty
LC25C32:  BNE LC25C3A    ;Branch if it's nonzero
LC25C34:  JSR $5C4D      ;mark character as "ready to run"
LC25C37:  JMP $5BE2      ;why not BRAnch to C2/5BEC?


;Figure character's "Run Success" variable and determine whether ready to run

LC25C3A:  LDA $3D71,X    ;Amount to add to "run success" variable.
                         ;varies by character; ranges from 2 through 5.
LC25C3D:  JSR $4B65      ;random: 0 to A - 1
LC25C40:  INC            ;1 to A
LC25C41:  CLC
LC25C42:  ADC $3D70,X
LC25C45:  STA $3D70,X    ;add to Run Success variable
LC25C48:  CMP $3A3B      ;compare to Run Difficulty
LC25C4B:  BCC LC25C53    ;if it's less, the character's not running yet
LC25C4D:  LDA $3018,X
LC25C50:  TSB $3A38      ;mark character as "ready to run"
LC25C53:  RTS


;Copy ATB timer, Morph gauge, and Condemned counter to displayable variables

LC25C54:  SEP #$30
LC25C56:  LDX #$06
LC25C58:  LDY #$03
LC25C5A:  LDA $3219,X    ;ATB timer, top byte
LC25C5D:  DEC
LC25C5E:  STA $2022,Y    ;visual ATB gauge?
LC25C61:  LDA $3B04,X    ;Morph gauge
LC25C64:  STA $2026,Y
LC25C67:  LDA $3B05,X    ;Condemned counter
LC25C6A:  STA $202A,Y
LC25C6D:  DEX
LC25C6E:  DEX
LC25C6F:  DEY
LC25C70:  BPL LC25C5A    ;iterate for all 4 characters
LC25C72:  RTS


;Update Can't Escape, Can't Run, Run Difficulty, and onscreen list of enemy names,
; based on currently present enemies)

LC25C73:  REP #$20       ;Set 16-bit Accumulator
LC25C75:  LDY #$08       ;the following loop nulls the list of enemy
                         ;names [and quantities, shown in FF6j but not FF3us]
                         ;that appears on the bottom left corner of the
                         ;screen in battle?
LC25C77:  TDC            ;A = 0000h
LC25C78:  STA $2013,Y    ;store to $2015 - $201B, each having a 16-bit
                         ;monster quantity
LC25C7B:  DEC            ;A = FFFFh
LC25C7C:  STA $200B,Y    ;store to $200D - $2013, each having a 16-bit
                         ;monster ID
LC25C7F:  DEY
LC25C80:  DEY
LC25C81:  BNE LC25C77    ;iterate 4 times, as there are 4 list entries
LC25C83:  SEP #$20       ;Set 8-bit Accumulator
LC25C85:  LDA #$06
LC25C87:  TRB $B1        ;clear Can't Run and Can't Escape
LC25C89:  LDA $201F      ;get encounter type.  0 = front, 1 = back,
                         ;2 = pincer, 3 = side
LC25C8C:  CMP #$02
LC25C8E:  BNE LC25CA4    ;branch if not pincer
LC25C90:  LDA $2EAC      ;bitfield of enemies in left "clump".
                         ;set in function C1/1588.
LC25C93:  AND $2F2F      ;compare to bitfield of remaining enemies?
LC25C96:  BEQ LC25CA4    ;branch if no enemy on left side remaining
LC25C98:  LDA $2EAD      ;bitfield of enemies in right "clump".
                         ;set in function C1/1588.
LC25C9B:  AND $2F2F      ;compare to bitfield of remaining enemies?
LC25C9E:  BEQ LC25CA4    ;branch if no enemy on right side remaining
LC25CA0:  LDA #$02
LC25CA2:  TSB $B1        ;set Can't Run
LC25CA4:  STZ $3A3B      ;set Run Difficulty to zero
LC25CA7:  STZ $3ECA      ;set Number of Unique enemy names who are currently
                         ;active to zero?  this variable will have a max
                         ;of 4, even though the actual number of unique
                         ;enemy names can go to 6.
LC25CAA:  LDA $3AA8,Y
LC25CAD:  LSR
LC25CAE:  BCC LC25D04    ;skip to next monster if this one not present
LC25CB0:  LDA $3021,Y
LC25CB3:  BIT $3A3A      ;is it in bitfield of dead-ish monsters?
LC25CB6:  BNE LC25D04    ;branch if so
LC25CB8:  BIT $3409
LC25CBB:  BEQ LC25D04
LC25CBD:  LDA $3EEC,Y    ;get monster's status byte 1
LC25CC0:  BIT #$C2
LC25CC2:  BNE LC25D04    ;branch if Zombie, Petrify, or Wound is set
LC25CC4:  LDA $3C88,Y    ;monster Misc/Special Byte 2.  normally accessed as
                         ;"$3C80,Y" , but we're only looking at enemies here.
LC25CC7:  LSR            ;put "Harder to Run From" bit in Carry flag
LC25CC8:  BIT #$04       ;is "Can't Escape" bit set in monster data?  [called
                         ;"Can't Run" in FF3usME]
LC25CCA:  BEQ LC25CD0
LC25CCC:  LDA #$06
LC25CCE:  TSB $B1        ;if so, set both Can't Run and Can't Escape.  the latter
                         ;will stop Warp, Warp Stones, and Smoke Bombs.  even though
                         ;a failed Smoke Bomb gives a "Can't run away!!" rather than
                         ;a "Can't escape!!" message, it just looks at the
                         ;Can't Escape bit.

LC25CD0:  TDC
LC25CD1:  ROL
LC25CD2:  SEC
LC25CD3:  ROL
LC25CD4:  ASL            ;if "Harder to Run From" was set, A = 6.  if not, A = 2.
LC25CD5:  ADC $3A3B
LC25CD8:  STA $3A3B      ;add to Run Difficulty
LC25CDB:  LDA $3C9D,Y    ;normally accessed as $3C95,Y , but we're only looking
                         ;at enemies here.
LC25CDE:  BIT #$04       ;is "Name Hidden" property set?
LC25CE0:  BNE LC25D04    ;branch if so
LC25CE2:  REP #$20
LC25CE4:  LDX #$00
LC25CE6:  LDA $200D,X    ;entry in list of enemy names you see on bottom left
                         ;of screen in battle?
LC25CE9:  BPL LC25CF4    ;branch if this entry has already been assigned an
                         ;enemy ID
LC25CEB:  LDA $3388,Y    ;get entry from Enemy Name structure, initialized
                         ;in function C2/2C30 [using $3380], for our current
                         ;monster pointed to by Y.  this structure has a list
                         ;of enemy IDs for the up to 6 enemies in a battle,
                         ;but it's normalized so enemies with matching names have
                         ;matching IDs.
LC25CEE:  STA $200D,X    ;save it in list of names?
LC25CF1:  INC $3ECA      ;increment the number of unique names of active enemies?
                         ;this counter will max out at 4, because the in-battle
                         ;list shows a maximum of 4 names, even though the actual
                         ;# of unique enemy names goes up to 6.
                         ;this variable is used by the FC 10 monster script
                         ;command.
LC25CF4:  CMP $3388,Y    ;compare enemy ID previously in this screen list entry
                         ;to one in the Name Structure entry.  they'll match for
                         ;sure if we didn't follow the branch at C2/5CE9.
LC25CF7:  BNE LC25CFE    ;if they don't match, skip to next screen list entry
LC25CF9:  INC $2015,X    ;they did match, so increase the quantity of enemies
                         ;who have this name.  FF6j displayed a quantity in
                         ;battle.  FF3us increased enemy names from 8 to 10
                         ;characters, so it never shows the quantity.
LC25CFC:  BRA LC25D04    ;exit this loop, as our enemy ID [as indexed by Y] is
                         ;already in the screen list.
LC25CFE:  INX
LC25CFF:  INX
LC25D00:  CPX #$08
LC25D02:  BCC LC25CE6    ;iterate 4 times, as the battle enemy name list has
                         ;4 entries.
LC25D04:  SEP #$20
LC25D06:  INY
LC25D07:  INY
LC25D08:  CPY #$0C
LC25D0A:  BCC LC25CAA    ;iterate for all 6 monsters
LC25D0C:  LDA $201F      ;get encounter type.  0 = front, 1 = back,
                         ;2 = pincer, 3 = side
LC25D0F:  CMP #$03
LC25D11:  BEQ LC25D19    ;branch if side attack
LC25D13:  LDA $B0
LC25D15:  BIT #$40
LC25D17:  BEQ LC25D1C    ;branch if not Preemptive attack
LC25D19:  STZ $3A3B      ;set Run Difficulty to zero
LC25D1C:  LDA $3A42      ;list of present and living characters acting
                         ;as enemies?
LC25D1F:  BEQ LC25D25    ;branch if none
LC25D21:  LDA #$02
LC25D23:  TSB $B1        ;set Can't Run
LC25D25:  RTS


;Copy Current and Max HP and MP, and statuses to displayable variables

LC25D26:  PHP
LC25D27:  REP #$20
LC25D29:  SEP #$10
LC25D2B:  LDY #$06
LC25D2D:  LDA $3BF4,Y    ;current HP
LC25D30:  STA $2E78,Y
LC25D33:  LDA $3C1C,Y    ;max HP
LC25D36:  STA $2E80,Y
LC25D39:  LDA $3C08,Y    ;current MP
LC25D3C:  STA $2E88,Y
LC25D3F:  LDA $3C30,Y    ;max MP
LC25D42:  STA $2E90,Y
LC25D45:  LDA $3EE4,Y    ;status bytes 1-2
LC25D48:  STA $2E98,Y
LC25D4B:  LDA $3EF8,Y    ;status bytes 3-4
LC25D4E:  STA $2EA0,Y
LC25D51:  DEY
LC25D52:  DEY
LC25D53:  BPL LC25D2D    ;iterate for all 4 characters
LC25D55:  PLP
LC25D56:  RTS


LC25D57:  PHP
LC25D58:  JSR $0267
LC25D5B:  LDX #$06
LC25D5D:  STZ $2E99,X
LC25D60:  DEX
LC25D61:  DEX
LC25D62:  BPL LC25D5D
LC25D64:  LDX #$0B
LC25D66:  STZ $2F35,X    ;clear message parameter bytes
LC25D69:  DEX
LC25D6A:  BPL LC25D66    ;iterate 12 times
LC25D6C:  LDA #$08
LC25D6E:  JSR $6411
LC25D71:  JSR $4903
LC25D74:  LDA $3A97
LC25D77:  BEQ LC25D91    ;branch if not in Colosseum
LC25D79:  LDA #$01
LC25D7B:  STA $2E75      ;indicate quantity of won item is 1
LC25D7E:  LDA $0207      ;item won from Colosseum
LC25D81:  STA $2F35      ;save in message parameter 1, bottom byte
LC25D84:  JSR $54DC      ;copy item's info to a 5-byte buffer, spanning
                         ;$2E72 - $2E76.  doesn't touch $2E75.
LC25D87:  JSR $6279      ;add item in buffer to Item menu [which is soon
                         ;copied to inventory]?
LC25D8A:  LDA #$20
LC25D8C:  JSR $5FD4      ;buffer and display "Got [item] x 1" message
LC25D8F:  PLP
LC25D90:  RTS


;At end of victorious combat, handle GP and Experience gained from battle,
; learned spells and abilities, won items, and displays all relevant messages.)

LC25D91:  REP #$10       ;Set 16-bit X and Y
LC25D93:  TDC            ;clear accumulator
LC25D94:  LDX $3ED4      ;get battle formation #
LC25D97:  CPX #$0200
LC25D9A:  BCS LC25DA0    ;if it's >= 512, there's no magic points, so branch
LC25D9C:  LDA $DFB400,X  ;magic points given by that enemy formation
LC25DA0:  STA $FB
LC25DA2:  STZ $F0
LC25DA4:  LDA $3EBC
LC25DA7:  AND #$08       ;set after getting any of four Magicites in Zozo --
                         ;allows Magic Point display
LC25DA9:  STA $F1        ;save that bit
LC25DAB:  REP #$20       ;Set 16-bit Accumulator
LC25DAD:  LDX #$000A
LC25DB0:  LDA $3EEC,X    ;check enemy's 1st status byte
LC25DB3:  BIT #$00C2     ;Petrify, death, or zombie?
LC25DB6:  BEQ LC25DDE    ;if not, skip this enemy
LC25DB8:  LDA $11E4
LC25DBB:  BIT #$0002     ;is Leap available [aka we're on Veldt]?
LC25DBE:  BNE LC25DCF    ;branch if so) (had been typoed "BNE LC25DD0"
LC25DC0:  CLC
LC25DC2:  LDA $3D8C,X    ;get enemy's XP -- base offset 3D84 is used earlier,
                         ;but that's because the function was indexing everybody
                         ;on screen, not just enemies
LC25DC4:  ADC $2F35      ;add it to the experience from other enemies
LC25DC7:  STA $2F35      ;save in message parameter 1, bottom word
LC25DCA:  BCC LC25DCF
LC25DCC:  INC $2F37      ;if it flowed out of bottom word, increment top word
                         ;[top byte, really, since this was 0 prior]
LC25DCF:  CLC
LC25DD0:  LDA $3DA0,X    ;get enemy's GP
LC25DD3:  ADC $2F3E      ;add it to GP from other enemies
LC25DD6:  STA $2F3E      ;save in extra [?] message parameter, bottom word
LC25DD9:  BCC LC25DDE
LC25DDB:  INC $2F40      ;if it flowed out of bottom word, increment top word
LC25DDE:  DEX
LC25DDF:  DEX
LC25DE0:  BPL LC25DB0    ;iterate for all 6 enemies

;Following code divides 24-bit XP gained from battle by 8-bit character quantity.
; Just long divide a 3-digit number by a 1-digit # to better follow the steps.)

LC25DE2:  LDA $2F35      ;bottom 2 bytes of 24-bit experience
LC25DE5:  STA $E8
LC25DE7:  LDA $2F36      ;top 2 bytes of XP
LC25DEA:  LDX $3A76      ;Number of present and living characters in party
LC25DED:  PHX
LC25DEE:  JSR $4792      ;Divides 16-bit A / 8-bit X
                         ;Stores quotient in 16-bit A. Stores remainder in 8-bit X
LC25DF1:  STA $EC        ;save quotient
LC25DF3:  STX $E9        ;save remainder
LC25DF5:  LDA $E8        ; $E8 = (remainder * 256) + bottom byte of original XP
LC25DF7:  PLX
LC25DF8:  JSR $4792      ;divide that by # of characters again
LC25DFB:  STA $2F35      ;save bottom byte of final quotient in message
                         ;parameter 1, bottom byte
LC25DFE:  LDA $EC        ;retrieve top 2 bytes of final quotient
LC25E00:  STA $2F36      ;save in message parameter 1, top 2 bytes
LC25E03:  ORA $2F35
LC25E06:  BEQ LC25E0E    ;if the XP per character is zero, branch
LC25E08:  LDA #$0027
LC25E0B:  JSR $5FD4      ;buffer and display "Got [amount] Exp. point(s)" message
LC25E0E:  SEP #$20       ;set 8-bit Accumulator
LC25E10:  LDY #$0006
LC25E13:  LDA $3018,Y
LC25E16:  BIT $3A74
LC25E19:  BEQ LC25E73    ;Branch if character dead or absent [e.g. slot is empty,
                         ;or the character escaped or got sneezed or engulfed].
LC25E1B:  LDA $3C59,Y
LC25E1E:  AND #$10
LC25E20:  BEQ LC25E2F    ;Branch if not x2 Gold [from Cat Hood]
LC25E22:  TSB $F0
LC25E24:  BNE LC25E2F    ;Branch if gold has already been doubled by another
                         ;character
LC25E26:  ASL $2F3E
LC25E29:  ROL $2F3F
LC25E2C:  ROL $2F40      ;double the GP won
LC25E2F:  LDA $3ED8,Y    ;Which character it is
LC25E32:  CMP #$00
LC25E34:  BNE LC25E49    ;Branch if not Terra
LC25E36:  LDA $F1        ;Bit 3 = 1 if have gotten any of Esper Magicites in Zozo
LC25E38:  BEQ LC25E49    ;branch if not
LC25E3A:  TSB $F0        ;this will enable Magic Point display below
LC25E3C:  LDA $FB        ;Number of Magic Points gained from battle
LC25E3E:  ASL            ;* 2
LC25E3F:  ADC $1CF6      ;Add to Morph supply
LC25E42:  BCC LC25E46    ;If it didn't overflow, branch
LC25E44:  LDA #$FF       ;Since it DID overflow, just set it to maximum
LC25E46:  STA $1CF6      ;Set Morph supply
LC25E49:  LDX $3010,Y    ;get offset to character info block
LC25E4C:  JSR $6235      ;Add experience for battle
LC25E4F:  LDA $3C59,Y
LC25E52:  BIT #$08
LC25E54:  BEQ LC25E59    ;Branch if not x2 XP [from Exp. Egg]
LC25E56:  JSR $6235      ;Add experience for battle
LC25E59:  LDA $3ED8,Y    ;Which character it is
LC25E5C:  CMP #$0C
LC25E5E:  BCS LC25E73    ;Branch if Gogo or Umaro
LC25E60:  JSR $6283      ;Stores address for spells known by character in $F4
LC25E63:  LDX $3010,Y    ;get offset to character info block
LC25E66:  PHY
LC25E67:  JSR $5FEF      ;Progress towards uncursing Cursed Shield, and learning
                         ;spells taught by equipment
LC25E6A:  LDA $161E,X    ;Esper equipped
LC25E6D:  BMI LC25E72    ;Branch if no esper equipped
LC25E6F:  JSR $602A      ;Progress towards learning spells taught by Esper
LC25E72:  PLY
LC25E73:  DEY
LC25E74:  DEY
LC25E75:  BPL LC25E13    ;Check next character
LC25E77:  LDA $F1
LC25E79:  AND $F0
LC25E7B:  BEQ LC25E8F    ;branch if we don't have both of the following:
                         ;- Esper Magicites have been retrieved at Zozo
                         ;- Terra is in party, or Magic Points went towards
                         ;  a character progressing on spell learning
LC25E7D:  LDA $FB        ;Magic points gained from battle
LC25E7F:  BEQ LC25E8F    ;branch if none
LC25E81:  STA $2F35      ;save in message parameter 1, bottom byte
LC25E84:  STZ $2F36
LC25E87:  STZ $2F37      ;zero top two bytes of parameter
LC25E8A:  LDA #$35
LC25E8C:  JSR $5FD4      ;buffer and display "Got [amount] Magic Point(s"
                         ;message
LC25E8F:  LDY #$0006
LC25E92:  LDA $3018,Y
LC25E95:  BIT $3A74      ;is character present and alive [and a non-enemy]?
LC25E98:  BEQ LC25EB9    ;branch if not
LC25E9A:  LDA $3ED8,Y    ;Which character it is
LC25E9D:  JSR $6283      ;Stores address for spells known by character in $F4
LC25EA0:  LDX $3010,Y    ;get offset to character info block
LC25EA3:  TYA
LC25EA4:  LSR
LC25EA5:  STA $2F38      ;save 0-3 character # in message parameter 2, bottom
                         ;byte
LC25EA8:  LDA #$2E
LC25EAA:  STA $F2        ;supply message ID of "[Character] gained a level",
                         ;to C2/606D, and tell it that the character has yet
                         ;to level up from this battle.
LC25EAC:  JSR $606D      ;check whether character has enough experience to
                         ;reach next level, and level up if so
LC25EAF:  LDA $3ED8,Y    ;which character this is
LC25EB2:  CMP #$0C
LC25EB4:  BCS LC25EB9    ;branch if it's Gogo or Umaro or some temporary
                         ;character
LC25EB6:  JSR $6133      ;Mark just-learned spells for a character as known,
                         ;and display messages for them
LC25EB9:  DEY
LC25EBA:  DEY
LC25EBB:  BPL LC25E92    ;iterate for all 4 party members
LC25EBD:  SEP #$10       ;set 8-bit X and Y
LC25EBF:  TDC
LC25EC0:  SEC
LC25EC1:  LDX #$02       ;start looking at last of three bytes in
                         ;Lores to Learn and Known Lores
LC25EC3:  LDY #$17       ;start looking at last Lore, Exploder
LC25EC5:  ROR
LC25EC6:  BCC LC25ECA
LC25EC8:  ROR
LC25EC9:  DEX            ;move to previous lore byte for each 8 we check
LC25ECA:  BIT $3A84,X    ;was current Lore marked in Lores to Learn?
LC25ECD:  BEQ LC25EE2    ;branch if not
LC25ECF:  PHA            ;Put on stack
LC25ED0:  ORA $1D29,X
LC25ED3:  STA $1D29,X    ;add to Known Lores
LC25ED6:  TYA
LC25ED7:  ADC #$8B       ;convert current lore # to a spell/attack #
LC25ED9:  STA $2F35      ;save in message parameter 1, bottom byte
LC25EDC:  LDA #$2D
LC25EDE:  JSR $5FD4      ;buffer and display "Learned [lore name]" message
LC25EE1:  PLA
LC25EE2:  DEY
LC25EE3:  BPL LC25EC5    ;loop for all 24 lores
LC25EE5:  LDA $300A      ;which character is Mog
LC25EE8:  BMI LC25F00    ;branch if not present in party
LC25EEA:  LDX $11E2      ;get combat background
LC25EED:  LDA $ED8E5B,X  ;get corresponding Dance #
LC25EF1:  BMI LC25F00    ;branch if it's negative - presumably FF
LC25EF3:  JSR $5217      ;X = A DIV 8, A = 2 ^ (A MOD 8)
LC25EF6:  TSB $1D4C      ;turn on dance in known dances
LC25EF9:  BNE LC25F00    ;if it was already on, don't display a message
LC25EFB:  LDA #$40
LC25EFD:  JSR $5FD4      ;buffer and display "Mastered a new dance!" message
LC25F00:  LDA $F0
LC25F02:  LSR
LC25F03:  BCC LC25F0A    ;branch if we didn't uncurse the Cursed Shield this
                         ;battle
LC25F05:  LDA #$2A
LC25F07:  JSR $5FD4      ;buffer and display "Dispelled curse on shield" message
LC25F0A:  LDX #$05       ;with up to 6 different enemies, you can win up to
                         ;6 different types of items
LC25F0C:  TDC            ;clear A
LC25F0D:  DEC            ;set A to FF
LC25F0E:  STA $F0,X      ;item type
LC25F10:  STZ $F6,X      ;quantity of that item
LC25F12:  DEX
LC25F13:  BPL LC25F0C    ;loop.  so in all 6 item slots, we'll have 0 of item #255.
LC25F15:  LDY #$0A       ;point to last enemy
LC25F17:  LDA $3EEC,Y    ;check enemy's 1st status byte
LC25F1A:  BIT #$C2       ;Petrify, Wound, or Zombied?
LC25F1C:  BEQ LC25F4E    ;if not, skip this enemy
LC25F1E:  JSR $4B5A      ;random #, 0 to 255
LC25F21:  CMP #$20       ;Carry clear if A < 20h, set otherwise.
                         ;this means we'll use the Rare dropped item slot 1/8 of
                         ;the time, and the Common 7/8 of the time
LC25F23:  REP #$30       ;Accumulator and Index regs 16-bit
LC25F25:  TDC            ;clear A
LC25F26:  ROR            ;put Carry in highest bit of A
LC25F27:  ADC $2001,Y    ;enemy number.  $2001 is filled by code handling F2 script
                         ;command, which handles enemy formation.
LC25F2A:  ASL
LC25F2B:  ROL            ;multiply enemy # by 4, as Stolen+Dropped Item block is
                         ;4 bytes
                         ;and put Carry into lowest bit.  Rare when bit is 0, Common
                         ;for 1.
LC25F2C:  TAX            ;updated index with enemy num and rare/common slot
LC25F2D:  LDA $CF3002,X  ;item dropped - CF3002 is rare, CF3003 is common
LC25F31:  SEP #$30       ;Accumulator and index regs 8-bit
LC25F33:  CMP #$FF       ;does chosen enemy slot have empty FF item?
LC25F35:  BEQ LC25F4E    ;if so, skip to next enemy
LC25F37:  LDX #$05
LC25F39:  CMP $F0,X      ;is Item # the same as any of the others won?
LC25F3B:  BEQ LC25F4C    ;if so, branch to increment its quantity
LC25F3D:  XBA
LC25F3E:  LDA $F0,X      ;if not, check if current battle slot is empty
LC25F40:  INC
LC25F41:  BNE LC25F48    ;if it wasn't empty, branch to check another battle slot
LC25F43:  XBA
LC25F44:  STA $F0,X      ;if it was, we can store our item there
LC25F46:  BRA LC25F4C
LC25F48:  XBA
LC25F49:  DEX
LC25F4A:  BPL LC25F39    ;compare item won to next slot
LC25F4C:  INC $F6,X      ;increment the quantity of the item won
LC25F4E:  DEY
LC25F4F:  DEY            ;move down to next enemy
LC25F50:  BPL LC25F17    ;loop for all the critters
LC25F52:  LDX #$05       ;start at last of 6 item slots
LC25F54:  LDA $F0,X      ;get current item ID
LC25F56:  CMP #$FF
LC25F58:  BEQ LC25F75    ;skip to next slot if it's empty
LC25F5A:  STA $2F35      ;save in message parameter 1, bottom byte
LC25F5D:  JSR $54DC      ;copy item's info to a 5-byte buffer, spanning
                         ;$2E72 - $2E76
LC25F60:  LDA $F6,X      ;get quantity of item won
LC25F62:  STA $2F38      ;save in message parameter 2, bottom byte
LC25F65:  STA $2E75      ;save quantity in that 5-byte buffer
LC25F68:  JSR $6279      ;add item in buffer to Item menu [which is soon
                         ;copied to inventory]
LC25F6B:  LDA #$20       ;"Got [item] x 1" message ID
LC25F6D:  DEC $F6,X
LC25F6F:  BEQ LC25F72
LC25F71:  INC            ;if more than one of this item ID won, A = 21h,
                         ;"Got [item] x [quantity]" message
LC25F72:  JSR $5FD4      ;buffer and display won item(s) message
LC25F75:  DEX
LC25F76:  BPL LC25F54    ;iterate for all 6 possible won item types
LC25F78:  LDA $2F3E
LC25F7B:  ORA $2F3F
LC25F7E:  ORA $2F40
LC25F81:  BEQ LC25FC5    ;branch if no gold won
LC25F83:  LDA $2F3E
LC25F86:  STA $2F38
LC25F89:  LDA $2F3F
LC25F8C:  STA $2F39
LC25F8F:  LDA $2F40
LC25F92:  STA $2F3A      ;copy 24-bit gold won from extra [?] message
                         ;parameter into 3-byte message parameter 2
LC25F95:  LDA #$26
LC25F97:  JSR $5FD4      ;buffer and display "Got [amount] GP" message
LC25F9A:  CLC
LC25F9B:  LDX #$FD
LC25F9D:  LDA $1763,X
LC25FA0:  ADC $2E41,X
LC25FA3:  STA $1763,X    ;this loop adds won gold to party's gold
LC25FA6:  INX
LC25FA7:  BNE LC25F9D

;The following loops will compare the party's GP (held in $1860 - $1862 to
; 9999999, and if it exceeds that amount, cap it at 9999999.)
LC25FA9:  LDX #$02       ;start pointing to topmost bytes of party GP
                         ;and GP limit
LC25FAB:  LDA $C25FC7,X  ;get current byte of GP limit
LC25FAF:  CMP $1860,X    ;compare to corresponding byte of party GP
LC25FB2:  BEQ LC25FC2    ;if the byte values match, we don't know how
                         ;the overall 24-bit values compare yet, so
                         ;go check the next lowest byte
LC25FB4:  BCS LC25FC5    ;if this byte of the GP limit exceeds the
                         ;corresponding byte of the party GP, we know
                         ;the overall value is also higher, so there's
                         ;no need to alter anything or compare further
LC25FB6:  LDX #$02       ;if we reached here, we know party GP must
                         ;exceed the 9999999 limit, so cap it.
LC25FB8:  LDA $C25FC7,X
LC25FBC:  STA $1860,X
LC25FBF:  DEX
LC25FC0:  BPL LC25FB8    ;update all 3 bytes of the party's GP
LC25FC2:  DEX
LC25FC3:  BPL LC25FAB
LC25FC5:  PLP
LC25FC6:  RTS


;Data

LC25FC7: dl $98967F  ;(GP cap: 9999999)



;Handle battles ending in loss - conventional, Colosseum, or Banon falling.
; Various end-battle messages also enter at C2/5FD4.)

LC25FCA:  PHA            ;Put on stack
LC25FCB:  LDA #$01
LC25FCD:  TSB $3EBC      ;set event bit indicating battle ended in loss
LC25FD0:  JSR $4903
LC25FD3:  PLA
LC25FD4:  PHP
LC25FD5:  SEP #$20
LC25FD7:  CMP #$FF
LC25FD9:  BEQ LC25FED    ;branch if in Colosseum
LC25FDB:  STA $2D6F      ;second byte of first entry of ($76) buffer
LC25FDE:  LDA #$02
LC25FE0:  STA $2D6E      ;first byte of first entry of ($76) buffer
LC25FE3:  LDA #$FF
LC25FE5:  STA $2D72      ;first byte of second entry of ($76) buffer
LC25FE8:  LDA #$04
LC25FEA:  JSR $6411      ;Execute animation queue
LC25FED:  PLP
LC25FEE:  RTS


;Progress towards uncursing Cursed Shield, and learning spells taught by equipment

LC25FEF:  PHX
LC25FF0:  LDY #$0006     ;Check all equipment and relic slots
LC25FF3:  LDA $161F,X    ;Item equipped, X determines slot to check
LC25FF6:  CMP #$FF
LC25FF8:  BEQ LC26024    ;Branch if no item equipped
LC25FFA:  CMP #$66
LC25FFC:  BNE LC2600C    ;Branch if no Cursed Shield equipped
LC25FFE:  INC $3EC0      ;Increment number of battles fought with Cursed Shield
LC26001:  BNE LC2600C    ;Branch if not 256 battles
LC26003:  LDA #$01
LC26005:  TSB $F0        ;tell caller the shield was uncursed
LC26007:  LDA #$67
LC26009:  STA $161F,X    ;Change to Paladin Shield
LC2600C:  XBA
LC2600D:  LDA #$1E
LC2600F:  JSR $4781      ;16-bit A = item ID * 30 [size of item data block]
                         ;JSR $2B63?
LC26012:  PHX
LC26013:  PHY
LC26014:  TAX
LC26015:  TDC
LC26016:  LDA $D85004,X  ;Spell item teaches
LC2601A:  TAY
LC2601B:  LDA $D85003,X  ;Rate spell is learned
LC2601F:  JSR $604B      ;Progress towards learning spell for equipped item
LC26022:  PLY
LC26023:  PLX
LC26024:  INX            ;Check next equipment slot
LC26025:  DEY
LC26026:  BNE LC25FF3    ;Branch if not last slot to check
LC26028:  PLX
LC26029:  RTS


;Progress towards learning spells taught by Esper

LC2602A:  PHX
LC2602B:  JSR $6293      ;Multiply A by #$0B and store in X
LC2602E:  LDY #$0005     ;Do for each spell taught by esper
LC26031:  TDC            ;Clear A
LC26032:  LDA $D86E01,X  ;Spell taught
LC26036:  CMP #$FF
LC26038:  BEQ LC26044    ;Branch if no spell taught
LC2603A:  PHY
LC2603B:  TAY
LC2603C:  LDA $D86E00,X  ;Spell learn rate
LC26040:  JSR $604B      ;Progress towards learning spell
LC26043:  PLY
LC26044:  INX
LC26045:  INX
LC26046:  DEY
LC26047:  BNE LC26031    ;Check next spell taught
LC26049:  PLX
LC2604A:  RTS


;Progress towards learning spell

LC2604B:  BEQ LC2606C    ;branch if no learn rate, i.e. no spell to learn
LC2604D:  XBA
LC2604E:  LDA $FB        ;Magic points gained from the battle
LC26050:  JSR $4781      ;Multiply by spell learn rate
LC26053:  STA $EE        ;Store this amount in $EE
LC26055:  LDA ($F4),Y    ;what % of spell is known
LC26057:  CMP #$FF
LC26059:  BEQ LC2606C    ;Branch if spell already known
LC2605B:  CLC
LC2605C:  ADC $EE        ;Add amount learned to % known for spell
LC2605E:  BCS LC26064
LC26060:  CMP #$64
LC26062:  BCC LC26066    ;branch if % known didn't reach 100
LC26064:  LDA #$80
LC26066:  STA ($F4),Y    ;if it did, mark spell as just learned
LC26068:  LDA $F1
LC2606A:  TSB $F0        ;tell Function C2/5D91 to enable gained Magic Point
                         ;display, provided we've already gotten an Esper
                         ;Magicite from Zozo
LC2606C:  RTS


;Check whether character has enough experience to reach next level, and level up if so

LC2606D:  STZ $F8
LC2606F:  TDC            ;Clear 16-bit A
LC26070:  LDA $1608,X    ;current level
LC26073:  CMP #$63
LC26075:  BCS LC2606C    ;exit if >= 99
LC26077:  REP #$20       ;Set 16-bit A
LC26079:  ASL
LC2607A:  PHX
LC2607B:  TAX            ;level * 2
LC2607C:  TDC            ;Clear 16-bit A
LC2607D:  CLC            ;Clear carry
LC2607E:  ADC $ED821E,X  ;add to Experience Needed for Level Up FROM this level
LC26082:  BCC LC26086    ;branch if bottom 16-bits of sum didn't overflow
LC26084:  INC $F8        ;if so, increment a counter that will determine
                         ;top 16-bits
LC26086:  DEX
LC26087:  DEX            ;point to experience needed for next lowest level
LC26088:  BNE LC2607D    ;total experience needed for level 1 thru current level.
                         ;IOW, total experience needed to reach next level.
LC2608A:  PLX

;                            (BUT, experience needed is stored divided by 8 in ROM, so we
;                             must multiply it to get true value)

LC2608B:  ASL
LC2608C:  ROL $F8        ;multiply 32-bit [only 24 bits ever used] experience
                         ;needed by 2
LC2608E:  ASL
LC2608F:  ROL $F8        ;again
LC26091:  ASL
LC26092:  ROL $F8        ;again
LC26094:  STA $F6        ;so now, $F6 thru $F8 = total 24-bit experience needed
                         ;to advance from our given level
LC26096:  LDA $1612,X    ;top 2 bytes of current Experience
LC26099:  CMP $F7        ;compare to top 2 bytes of needed experience
LC2609B:  SEP #$20       ;set 8-bit Accumulator
LC2609D:  BCC LC2606C    ;Exit if (current exp / 256) < (needed exp / 256)
LC2609F:  BNE LC260A8    ;if (current exp / 256) != (needed exp / 256), branch
                         ;since it's not less than, we know it's greater than
LC260A1:  LDA $1611,X    ;bottom byte of Experience
LC260A4:  CMP $F6        ;compare to experience needed
LC260A6:  BCC LC2606C    ;Exit if less
LC260A8:  LDA $F2        ;holds 2Eh, message ID of "[Character] gained a level",
                         ;to start with
LC260AA:  BEQ LC260B1    ;branch if current character has already levelled up
                         ;once from this function
LC260AC:  STZ $F2        ;indicate current character has levelled up
LC260AE:  JSR $5FD4      ;buffer and display "[character name] gained a level"
                         ;message
LC260B1:  JSR $60C2      ;raise level, raise normal HP and MP, and give any
                         ;Esper bonus
LC260B4:  PHX
LC260B5:  LDA $1608,X    ;load level
LC260B8:  XBA            ;put in top of A
LC260B9:  LDA $1600,X    ;character ID, aka "Actor"
LC260BC:  JSR $61B6      ;Handle spells or abilities learned at level-up for
                         ;character
LC260BF:  PLX
LC260C0:  BRA LC2606D    ;repeat to check for another possible level gain,
                         ;since it's possible a battle with wicked high
                         ;experience on a wussy character boosted multiple
                         ;levels.


;Gain level, raise HP and MP, and give any Esper bonus

LC260C2:  PHP
LC260C3:  INC $1608,X    ;increment current level
LC260C6:  STZ $FD
LC260C8:  STZ $FF
LC260CA:  PHX
LC260CB:  TDC            ;Clear 16-bit A
LC260CC:  LDA $1608,X    ;get level
LC260CF:  TAX
LC260D0:  LDA $E6F500,X  ;normal MP gain for level
LC260D4:  STA $FE
LC260D6:  LDA $E6F49E,X  ;normal HP gain for level
LC260DA:  STA $FC
LC260DC:  PLX
LC260DD:  LDA $161E,X    ;get equipped Esper
LC260E0:  BMI LC260F6    ;if it's null, don't try to calculate bonuses
LC260E2:  PHY
LC260E3:  PHX
LC260E4:  TXY            ;Y will be used to index stats that are boosted
                         ;by the $614E call.  i believe it currently points
                         ;to offset of character block from $1600
LC260E5:  JSR $6293      ;X = A * 11d
LC260E8:  TDC            ;Clear 16-bit A
LC260E9:  LDA $D86E0A,X  ;end of data block for Esper..  probably
                         ;has level-up bonus
LC260ED:  BMI LC260F4    ;if null, don't try to calculate bonus
LC260EF:  ASL
LC260F0:  TAX            ;multiply bonus index by 2
LC260F1:  JSR ($614E,X)  ;calculate bonus.  note that [Stat]+1 jumps to the
                         ;same place as [Stat]+2.  what distinguishes them?
                         ;Bit 1 of X.  if X is 20, 24, 28, 32, you'll get +1
                         ;to a stat.. if it's 18, 22, 26, 30, you get +2.

                         ;for HP/MP boosts, X of 0/2/4 means HP, and
                         ;6/8/10 means MP
LC260F4:  PLX
LC260F5:  PLY
LC260F6:  REP #$21       ;set 16-bit A, clear carry
LC260F8:  LDA $160B,X    ;maximum HP
LC260FB:  PHA            ;Put on stack
LC260FC:  AND #$C000     ;isolate top bits, which indicate (bit 7, then bit 6:
                         ;00 = no equipment % bonus, 11 = 12.5% bonus,
                         ;01 = 25% bonus, 10 = 50% bonus
LC260FF:  STA $EE        ;save equipment bonus bits
LC26101:  PLA            ;get max HP again
LC26102:  AND #$3FFF     ;isolate bottom 14 bits.. just the max HP w/o bonus
LC26105:  ADC $FC        ;add to HP gain for level
LC26107:  CMP #$2710
LC2610A:  BCC LC2610F    ;branch if less than 10000
LC2610C:  LDA #$270F     ;replace with 9999
LC2610F:  ORA $EE        ;combine with bonus bits
LC26111:  STA $160B,X    ;save updated max HP
LC26114:  CLC            ;clear carry
LC26115:  LDA $160F,X    ;now maximum MP
LC26118:  PHA            ;Put on stack
LC26119:  AND #$C000     ;isolate top bits, which indicate (bit 7, then bit 6:
                         ;00 = no equipment % bonus, 11 = 12.5% bonus,
                         ;01 = 25% bonus, 10 = 50% bonus
LC2611C:  STA $EE        ;save equipment bonus bits
LC2611E:  PLA            ;get max MP again
LC2611F:  AND #$3FFF     ;isolate bottom 14 bits.. just the max MP w/o bonus
LC26122:  ADC $FE        ;add to MP gain for level
LC26124:  CMP #$03E8
LC26127:  BCC LC2612C    ;branch if less than 1000
LC26129:  LDA #$03E7     ;replace with 999
LC2612C:  ORA $EE        ;combine with bonus bits
LC2612E:  STA $160F,X    ;save updated max MP
LC26131:  PLP
LC26132:  RTS


;Mark just-learned spells for a character as known, and display messages
; for them)

LC26133:  PHY
LC26134:  LDY #$0035
LC26137:  LDA ($F4),Y
LC26139:  CMP #$80       ;was this spell just learned?
LC2613B:  BNE LC26149    ;branch if not
LC2613D:  LDA #$FF
LC2613F:  STA ($F4),Y    ;mark it as known
LC26141:  STY $2F35      ;save spell ID in message parameter 1, bottom byte
LC26144:  LDA #$32
LC26146:  JSR $5FD4      ;buffer and display
                         ;"[Character name] learned [spell name]" message
LC26149:  DEY
LC2614A:  BPL LC26137    ;iterate for all 54 spells
LC2614C:  PLY
LC2614D:  RTS


;Code Pointers

LC2614E: dw $6170  ;(~10% HP bonus)  (HP due to X)
LC26150: dw $6174  ;(~30% HP bonus)  (HP due to X)
LC26152: dw $6178  ;(50% HP bonus)   (HP due to X)
LC26154: dw $6170  ;(~10% MP bonus)  (MP due to X)
LC26156: dw $6174  ;(~30% MP bonus)  (MP due to X)
LC26158: dw $6178  ;(50% MP bonus)   (MP due to X)
LC2615A: dw $61B0  ;(Double natural HP gain for level.  Curious...)
LC2615C: dw $6197  ;(No bonus)
LC2615E: dw $6197  ;(No bonus)
LC26160: dw $619B  ;(Vigor bonus)    (+1 due to X value in caller)
LC26162: dw $619B  ;(Vigor bonus)    (+2 due to X)
LC26164: dw $619A  ;(Speed bonus)    (+1 due to X)
LC26166: dw $619A  ;(Speed bonus)    (+2 due to X.  No Esper currently uses)
LC26168: dw $6199  ;(Stamina bonus)  (+1 due to X)
LC2616A: dw $6199  ;(Stamina bonus)  (+2 due to X)
LC2616C: dw $6198  ;(MagPwr bonus)   (+1 due to X)
LC2616E: dw $6198  ;(MagPwr bonus)   (+2 due to X)


;Esper HP or MP bonus at level-up

LC26170:  LDA #$1A       ;26 => 10.15625% bonus
LC26172:  BRA LC2617A
LC26174:  LDA #$4E       ;78 => 30.46875% bonus
LC26176:  BRA LC2617A
LC26178:  LDA #$80       ;128 ==> 50% bonus
LC2617A:  CPX #$0006     ;are we boosting MP rather than HP?
LC2617D:  LDX #$0000     ;start pointing to $FC, which holds normal HP to raise
LC26180:  BCC LC26184    ;if X was less than 6, we're just boosting HP,
                         ;so branch
LC26182:  INX
LC26183:  INX            ;point to $FE, which holds normal MP to raise
LC26184:  XBA            ;put boost numerator in top of A
LC26185:  LDA $FC,X      ;get current HP or MP to add
LC26187:  JSR $4781
LC2618A:  XBA            ;get (boost number * current HP or MP to add / 256.
                         ;after all, the boost IS a percentage..
LC2618B:  BNE LC2618E    ;if the HP/MP bonus is nonzero, branch
LC2618D:  INC            ;if it was zero, be nice and give the chump one..
LC2618E:  CLC
LC2618F:  ADC $FC,X
LC26191:  STA $FC,X      ;add boost to natural HP/MP gain
LC26193:  BCC LC26197
LC26195:  INC $FD,X      ;if bottom byte overflowed from add, boost top byte
LC26197:  RTS


;Esper stat bonus at level-up.  Vigor, Speed, Stamina, or MagPwr.
; If Bit 1 of X is set, give +1 bonus.  If not, give +2.)

LC26198:  INY            ;enter here = 3 INYs = point to MagPwr
LC26199:  INY            ;enter here = 2 INYs = point to Stamina
LC2619A:  INY            ;enter here = 1 INY  = point to Speed
LC2619B:  TXA            ;enter here = 0 INYs = point to Vigor
LC2619C:  LSR
LC2619D:  LSR            ;Carry holds bit 1 of X
LC2619E:  TYX            ;0 to 3 value.  determines which stat will be altered
LC2619F:  LDA $161A,X    ;at $161A,X we have Vigor, Speed, Stamina, and MagPwr,
                         ;in that order
LC261A2:  INC
LC261A3:  BCS LC261A6    ;If carry set, just give +1
LC261A5:  INC
LC261A6:  CMP #$81       ;is stat >= 129?
LC261A8:  BCC LC261AC
LC261AA:  LDA #$80       ;if so, make it 128
LC261AC:  STA $161A,X    ;save updated stat
LC261AF:  RTS


;Give double natural HP gain for level?  Can't say I know when this happens...

LC261B0:  TDC            ;Clear 16-bit A
LC261B1:  TAX            ;X = 0
LC261B2:  LDA $FC
LC261B4:  BRA LC2618E


;Handle spells or abilities learned at level-up for character

LC261B6:  LDX #$0000     ;point to start of Terra's magic learned at
                         ;level up block
LC261B9:  CMP #$00       ;is it character #0, Terra?
LC261BB:  BEQ LC261FC    ;if yes, branch to see if she learns any spells
LC261BD:  LDX #$0020     ;point to start of Celes' magic learned at
                         ;level up block
LC261C0:  CMP #$06       ;is it character #6, Celes?
LC261C2:  BEQ LC261FC    ;if yes, branch to see if she learns any spells
LC261C4:  LDX #$0000     ;point to start of Cyan's SwdTechs learned
                         ;at level up block
LC261C7:  CMP #$02       ;if it character #2, Cyan?
LC261C9:  BNE LC261E0    ;if not, check for Sabin


;Cyan learning SwdTechs at level up.
; His data block is just an array of 8 bytes: the level for learning each SwdTech)

LC261CB:  JSR $6222      ;are any SwdTechs learned at the current level?
LC261CE:  BEQ LC26221    ;if not, exit
LC261D0:  TSB $1CF7      ;if so, enable the newly learnt SwdTech
LC261D3:  BNE LC26221    ;if it was already enabled [e.g. Cleave learned
                         ;in nightmare], suppress celebratory messages
                         ;and such
LC261D5:  LDA #$40
LC261D7:  TSB $F0
LC261D9:  BNE LC26221    ;branch if we already learned another SwdTech
                         ;this battle; possible with multiple level-ups.
LC261DB:  LDA #$42
LC261DD:  JMP $5FD4      ;buffer and display "Mastered a new technique!"
                         ;message


;Sabin learning Blitzes at level up.
; His data block is just an array of 8 bytes: the level for learning each Blitz)

LC261E0:  LDX #$0008     ;point to start of Sabin's Blitzes learned
                         ;at level up block
LC261E3:  CMP #$05       ;is it character #5, Sabin?
LC261E5:  BNE LC26221    ;if not, exit
LC261E7:  JSR $6222      ;are any Blitzes learned at the current level?
LC261EA:  BEQ LC26221    ;if not, exit
LC261EC:  TSB $1D28      ;if so, enable the newly learnt Blitz
LC261EF:  BNE LC26221    ;if it was already enabled [e.g. Bum Rush taught
                         ;by Duncan], suppress celebratory messages
                         ;and such
LC261F1:  LDA #$80
LC261F3:  TSB $F0
LC261F5:  BNE LC26221    ;branch if we already learned another Blitz
                         ;this battle; possible with multiple level-ups.
LC261F7:  LDA #$33
LC261F9:  JMP $5FD4      ;buffer and display "Devised a new Blitz!"
                         ;message


;Terra and Celes natural magic learning at level up

LC261FC:  PHY
LC261FD:  XBA
LC261FE:  LDY #$0010     ;check a total of 32 bytes, as Terra and Celes
                         ;each have a 16-element spell list, with
                         ;2 bytes per element [spell #, then level]
LC26201:  CMP $ECE3C1,X  ;Terra/Celes level-up spell list: Level at
                         ;which spell learned
LC26205:  BNE LC2621B    ;if this level isn't one where the character
                         ;learns a spell, branch to check the next
                         ;list element
LC26207:  PHA            ;Put on stack
LC26208:  PHY
LC26209:  TDC            ;Clear 16-bit A
LC2620A:  LDA $ECE3C0,X  ;Terra/Celes level-up spell list: Spell number
LC2620E:  TAY
LC2620F:  LDA ($F4),Y    ;check spell's learning progress
LC26211:  CMP #$FF
LC26213:  BEQ LC26219    ;branch if it's already known
LC26215:  LDA #$80
LC26217:  STA ($F4),Y    ;set it as just learned
LC26219:  PLY
LC2621A:  PLA
LC2621B:  INX
LC2621C:  INX            ;check next spell and level pair
LC2621D:  DEY
LC2621E:  BNE LC26201
LC26220:  PLY
LC26221:  RTS


;Handles Sabin's Blitzes learned or Cyan's SwdTechs learned, depending on X value

LC26222:  LDA #$01
LC26224:  STA $EE        ;start by marking SwdTech/Blitz #0
LC26226:  XBA            ;get current level from top of A?
LC26227:  CMP $E6F490,X  ;does level match the one in the SwdTech/Blitz
                         ;table?
LC2622B:  BEQ LC26232    ;if so, branch
LC2622D:  INX            ;otherwise, move to check next level
LC2622E:  ASL $EE        ;mark the next SwdTech/Blitz as learned instead
LC26230:  BCC LC26227    ;loop for all 8 bits.  if Carry is set, we've
                         ;checked all 8 to no avail, and $EE will be 0,
                         ;indicating no SwdTech or Blitz is learned
LC26232:  LDA $EE        ;get the SwdTech/Blitz bitfield.. where the number
                         ;of the bit that is set represents the number of
                         ;the SwdTech/Blitz to learn
LC26234:  RTS


;Add Experience for battle to character
;If XP over 15,000,000 sets XP to 15,000,000

LC26235:  PHP
LC26236:  REP #$21
LC26238:  LDA $2F35      ;XP Gained from battle
LC2623B:  ADC $1611,X    ;Add to XP for character
LC2623E:  STA $F6
LC26240:  SEP #$20       ;Set 8-bit Accumulator
LC26242:  LDA $2F37      ;Do third byte of XP
LC26245:  ADC $1613,X
LC26248:  STA $F8
LC2624A:  PHX
LC2624B:  LDX #$0002     ;The following loops will compare the character's
                         ;new Experience (held in $F6 - $F8 to 15000000, and
                         ;if it exceeds that amount, cap it at 15000000.
LC2624E:  LDA $C26276,X
LC26252:  CMP $F6,X
LC26254:  BEQ LC26264
LC26256:  BCS LC26267
LC26258:  LDX #$0002
LC2625B:  LDA $C26276,X
LC2625F:  STA $F6,X
LC26261:  DEX
LC26262:  BPL LC2625B
LC26264:  DEX
LC26265:  BPL LC2624E
LC26267:  PLX
LC26268:  LDA $F8
LC2626A:  STA $1613,X    ;store to third persistent byte of XP
LC2626D:  REP #$20
LC2626F:  LDA $F6
LC26271:  STA $1611,X    ;store to bottom two bytes of XP
LC26274:  PLP
LC26275:  RTS


;Data (Experience cap: 15000000

LC26276: db $C0
LC26277: db $E1
LC26278: db $E4

;Add item in $2E72 - $2E76 buffer to Item menu

LC26279:  LDA #$05
LC2627B:  JSR $6411      ;(copy $2E72-$2E76 buffer to a $602D-$6031
                         ;[plus offset] buffer
LC2627E:  LDA #$0A
LC26280:  JMP $6411      ;(copy $602D-$6031 buffer to Item menu


;Stores address for spells known by character in $F4

LC26283:  PHP
LC26284:  XBA
LC26285:  LDA #$36
LC26287:  JSR $4781
LC2628A:  REP #$21
LC2628C:  ADC #$1A6E
LC2628F:  STA $F4
LC26291:  PLP
LC26292:  RTS


;Multiply A by #$0B and store in X

LC26293:  XBA
LC26294:  LDA #$0B
LC26296:  JSR $4781
LC26299:  TAX
LC2629A:  RTS


;Copy $3A28-$3A2B variables into ($76) buffer

LC2629B:  STA $3A28
LC2629E:  PHA            ;Put on stack
LC2629F:  PHX
LC262A0:  PHP
LC262A1:  REP #$20       ;Set 16-bit Accumulator
LC262A3:  SEP #$10       ;Set 8-bit Index Registers
LC262A5:  LDX $3A72      ;X = animation buffer pointer
LC262A8:  LDA $3A28      ;temporary bytes 1 and 2 for animation buffer
LC262AB:  STA $2D6E,X    ;copy to buffer
LC262AE:  LDA $3A2A      ;temporary bytes 3 and 4 for animation buffer
LC262B1:  STA $2D70,X    ;copy to buffer
LC262B4:  INX
LC262B5:  INX
LC262B6:  INX
LC262B7:  INX
LC262B8:  STX $3A72      ;increase animation buffer pointer by 4
LC262BB:  PLP
LC262BC:  PLX
LC262BD:  PLA
LC262BE:  RTS


;??? Function
;Calls 629B, setting the accumulator to 16-bit before.

LC262BF:  PHP
LC262C0:  REP #$20       ;Set 16-bit Accumulator
LC262C2:  JSR $629B
LC262C5:  PLP
LC262C6:  RTS


;Add/restore characters' items to a temporary $602D-$6031 buffer, which will later
; be added to inventory.  This function is called:
; - At the end of a character's turn when they Steal or Metamorph something.
; - At the end of battle for all characters, to account for items they tried to use
;   during the battle, but were thwarted by being killed/etc (the game depletes items
;   upon *issuing* the command, so it'll be gone from inventory even if the command
;   never executed).
; - It can also be used to restore a "bottomless" item at the end of a character's
;   turn.  [The game does support equipment that doesn't deplete when you use it as
;   an Item, though no such equipment exists.])

LC262C7:  LDX #$06
LC262C9:  LDA $3018,X
LC262CC:  TRB $3A8C      ;clear this character's "add my items to inventory"
                         ;flag
LC262CF:  BEQ LC262EA    ;if it wasn't set, then skip this character
LC262D1:  LDA $32F4,X
LC262D4:  CMP #$FF       ;does this character have a valid item to add to
                         ;inventory?
LC262D6:  BEQ LC262EA    ;branch if not
LC262D8:  JSR $54DC      ;copy item's info to a 5-byte buffer, spanning
                         ;$2E72 - $2E76
LC262DB:  LDA #$01
LC262DD:  STA $2E75      ;indicate quantity of 1 item being added/restored
LC262E0:  LDA #$05
LC262E2:  JSR $6411      ;copy $2E72-$2E76 buffer to a $602D-$6031 buffer.
                         ;latter buffer gets copied to Item menu:
                         ;- if at end of battle, by C2/492E
                         ;- if mid-battle, apparently by having triangle
                         ;  cursor switch to different character
LC262E5:  LDA #$FF
LC262E7:  STA $32F4,X    ;null the item to add to inventory
LC262EA:  DEX
LC262EB:  DEX
LC262EC:  BPL LC262C9    ;iterate for all 4 party members
LC262EE:  RTS


;Call C2/12F5 to do actual damage/healing at the end of a "strike", then queue
; damage and/or healing values for display.  Note that -1 (FFFFh) in a Damage
; Taken/Healed variable means the damage taken or healed is nonexistent and won't
; be displayed, as opposed to a displayable 0.)

LC262EF:  PHX
LC262F0:  PHY
LC262F1:  STZ $F0        ;zero number of damaged or healed entities
LC262F3:  STZ $F2        ;zero number of entities both damaged and healed
LC262F5:  LDY #$12
LC262F7:  LDA $33D0,Y    ;Damage Taken
LC262FA:  CMP $33E4,Y    ;Damage Healed
LC262FD:  BNE LC26302
LC262FF:  INC
LC26300:  BEQ LC26345    ;Branch if Damage Taken and Damage Healed are
                         ;both nonexistent
LC26302:  LDA $3018,Y
LC26305:  TRB $3A5A      ;Target is not missed
                         ;how can we have a target who's both missed
                         ;and being damaged/healed going into this
                         ;function, you ask?  it could be from Launcher
                         ;firing multiple missiles at a single target.
                         ;or it could be from spread-aiming a spell at
                         ;a Reflective group, and multiple reflections
                         ;coming back at a single target.
LC26308:  JSR $12F5      ;Do the HP or MP Damage/Healing to entity
LC2630B:  CPY $3A82      ;Check if target protected by Golem
LC2630E:  BNE LC26323    ;Branch if not ^
LC26310:  LDA $33D0,Y    ;Damage Taken
LC26313:  INC
LC26314:  BEQ LC26323    ;branch if Damage Taken is nonexistent, but
                         ;there is Damage Healed
LC26316:  SEC
LC26317:  LDA $3A36      ;HP for Golem
LC2631A:  SBC $33D0,Y    ;Subtract damage
LC2631D:  BCS LC26320    ;branch if >= 0
LC2631F:  TDC
LC26320:  STA $3A36      ;Set to 0 if < 0
LC26323:  LDA $33E4,Y    ;Damage Healed
LC26326:  INC
LC26327:  BEQ LC26345    ;Branch if Damage Healed nonexistent
LC26329:  DEC
LC2632A:  ORA #$8000
LC2632D:  STA $33E4,Y    ;Set "sign bit" in Damage Healed
LC26330:  INC $F2        ;increment count of targets with both damage done and
                         ;damage healed
LC26332:  LDA $33D0,Y
LC26335:  INC
LC26336:  BNE LC26345    ;Branch if there is Damage Taken
LC26338:  DEC $F2        ;damage was healed but not done, so undo incrementation
                         ;done for this target

LC2633A:  LDA $33E4,Y
LC2633D:  STA $33D0,Y    ;If only Damage Healed, Damage Taken = - Damage Healed
LC26340:  TDC
LC26341:  DEC
LC26342:  STA $33E4,Y    ;Store -1 in Damage Healed
LC26345:  LDA $3018,Y
LC26348:  BIT $3A5A
LC2634B:  BEQ LC26353    ;branch if target is not missed
LC2634D:  LDA #$4000
LC26350:  STA $33D0,Y    ;Store Miss bit in damage
LC26353:  LDA $33D0,Y
LC26356:  INC
LC26357:  BEQ LC2635B    ;If no damage dealt and/or damage healed
LC26359:  INC $F0        ;increment count of targets with damage dealt or healed
LC2635B:  DEY
LC2635C:  DEY
LC2635D:  BPL LC262F7
LC2635F:  LDY $F0        ;how many targets have damage dealt and/or damage
                         ;healed
LC26361:  CPY #$05
LC26363:  JSR $6398      ;set up display for < 5 targets damaged or healed
LC26366:  JSR $63B4      ;OR for >= 5 targets damaged or healed
LC26369:  LDA $F2
LC2636B:  BEQ LC26387    ;if no target had both damage healed and damage done,
                         ;branch
LC2636D:  LDX #$12
LC2636F:  LDY #$00
LC26371:  LDA $33E4,X    ;Damage Healed
LC26374:  STA $33D0,X    ;Store in Damage Taken
LC26377:  INC
LC26378:  BEQ LC2637B    ;If no damage dealt
LC2637A:  INY            ;how many targets have [2nd round of] damage dealt?
LC2637B:  DEX
LC2637C:  DEX
LC2637D:  BPL LC26371
LC2637F:  CPY #$05
LC26381:  JSR $6398      ;set up display for < 5 targets damaged or healed
LC26384:  JSR $63B4      ;OR for >= 5 targets damaged or healed
LC26387:  TDC
LC26388:  DEC
LC26389:  LDX #$12
LC2638B:  STA $33E4,X    ;Store -1 in Damage Healed
LC2638E:  STA $33D0,X    ;Store -1 in Damage Taken
LC26391:  DEX
LC26392:  DEX
LC26393:  BPL LC2638B    ;null out damage for all onscreen targets
LC26395:  PLY
LC26396:  PLX
LC26397:  RTS


;For less than 5 targets damaged or healed, use a "cascading" damage display.
; One target's damage/healing numbers will show up a split second after the other's.)

LC26398:  BCS LC263B3    ;Exit function if 5+ targets have damage dealt?
                         ;Why the hell not branch to C2/63B4, cut the BCC there,
                         ;and cut the "JSR $63B4"s out of function C2/62EF?
LC2639A:  LDX #$12
LC2639C:  LDA $33D0,X    ;Damage Taken
LC2639F:  INC
LC263A0:  BEQ LC263AF    ;branch if no damage
LC263A2:  DEC
LC263A3:  STA $3A2A      ;temporary bytes 3 and 4 for ($76) animation buffer
LC263A6:  TXA
LC263A7:  LSR            ;Acc = 0-9 target #
LC263A8:  XBA
LC263A9:  ORA #$000B     ;target # in top of A, 0x0B in bottom?
LC263AC:  JSR $629B      ;Copy A to $3A28-$3A29, and copy $3A28-$3A2B variables
                         ;into ($76) buffer
LC263AF:  DEX
LC263B0:  DEX
LC263B1:  BPL LC2639C    ;loop for all onscreen targets
LC263B3:  RTS            ;if < 5 targets have damage dealt, Carry will always
                         ;be clear here.  either we skipped the LSR above, or
                         ;it was done on an even number.


;For 5+ targets damaged or healed, have all their damage/healing numbers pop up
; simultaneously.)

LC263B4:  BCC LC263DA    ;exit function if less than 5 targets have damage
                         ;dealt?
LC263B6:  PHP
LC263B7:  SEP #$20       ;Set 8-bit Accumulator
LC263B9:  LDA #$03
LC263BB:  JSR $629B      ;Copy A to $3A28, and copy $3A28-$3A2B variables into
                         ;($76) buffer
LC263BE:  LDA $3A34      ;get simultaneous damage display buffer index?
LC263C1:  INC $3A34      ;advance for next strike
LC263C4:  XBA
LC263C5:  LDA #$14       ;A = old index * 20
LC263C7:  JSR $4781
LC263CA:  REP #$31       ;Set 16-bit Accumulator, 16-bit X and Y, clear Carry
LC263CC:  ADC #$2BCE     ;add to address of start of buffer
LC263CF:  TAY
LC263D0:  LDX #$33D0
LC263D3:  LDA #$0013
LC263D6:  MVN $7E7E    ;copy $33D0 thru $33E3, the damage variables for all
                         ;10 targets, to some other memory location
LC263D9:  PLP
LC263DA:  RTS


;Copy 8 words (16 bytes) from $A0 to ;$78) buffer, ((7E:3A32) + #$2C6E)
;C1 inspection shows $2C6E to be the area where animation
; scripts are read from. Thus, $3A32 stores the beginning
; offset for the animation script.)

LC263DB:  PHX
LC263DC:  PHY
LC263DD:  PHP
LC263DE:  SEP #$20       ;Set 8-bit A
LC263E0:  TDC
LC263E1:  LDA $3A32      ;get animation buffer pointer
LC263E4:  PHA            ;Put on stack
LC263E5:  REP #$31       ;Set 16-bit A,Y,X
LC263E7:  ADC #$2C6E
LC263EA:  TAY
LC263EB:  LDX #$00A0
LC263EE:  LDA #$000F
LC263F1:  MVN $7E7E
LC263F4:  SEP #$30       ;Set 8-bit A,Y,X
LC263F6:  PLA
LC263F7:  ADC #$10
LC263F9:  STA $3A32      ;increment animation buffer pointer by 16
LC263FC:  PLP
LC263FD:  PLY
LC263FE:  PLX
LC263FF:  RTS


;Zero $A0 through $AF

LC26400:  PHX
LC26401:  PHP
LC26402:  REP #$20       ;set 16-bit accumulator
LC26404:  LDX #$06
LC26406:  STZ $A0,X
LC26408:  STZ $A8,X      ;overall: $A0 thru $AF are zeroed out
LC2640A:  DEX
LC2640B:  DEX
LC2640C:  BPL LC26406    ;iterate 4 times
LC2640E:  PLP
LC2640F:  PLX
LC26410:  RTS


LC26411:  PHX
LC26412:  PHY
LC26413:  PHP
LC26414:  SEP #$20
LC26416:  REP #$11
LC26418:  PHA            ;Put on stack
LC26419:  TDC
LC2641A:  PLA
LC2641B:  CMP #$02
LC2641D:  BNE LC26425
LC2641F:  LDA $B1
LC26421:  BMI LC26429
LC26423:  LDA #$02
LC26425:  JSR $C10000
LC26429:  PLP
LC2642A:  PLY
LC2642B:  PLX
LC2642C:  RTS


;Monster command script command #$FA

LC2642D:  REP #$20       ;Set 16-bit accumulator
LC2642F:  LDA $B8        ;Byte 2 & 3
LC26431:  STA $3A2A      ;store in temporary bytes 3 and 4 for ($76
                         ;animation buffer
LC26434:  SEP #$20       ;Set 8-bit Accumulator
LC26436:  LDA $B6        ;Byte 0
LC26438:  XBA
LC26439:  LDA #$14
LC2643B:  JMP $62BF


;Well, well, well...  it's a shame that this function is apparently
; never called.)

LC2643E:  REP #$20       ;Set 16-bit Accumulator
LC26440:  LDA $1D55      ;get Font color from Configuration
LC26443:  CMP #$7BDE     ;are Red, Green, and Blue all equal to 30?
LC26446:  SEP #$20       ;Set 8-bit Accumulator
LC26448:  BNE LC26468    ;branch if not desired Font color
LC2644A:  LDA $004219    ;Joypad #1 status register
LC2644E:  CMP #$28       ;are Up and Select pressed, and only those?
LC26450:  BNE LC26468    ;branch if not
LC26452:  LDA #$02
LC26454:  TSB $3A96      ;set some flag
LC26457:  BNE LC26468    ;branch if it was already set
LC26459:  LDA #$FF
LC2645B:  STA $B9
LC2645D:  LDA #$05
LC2645F:  STA $B8
LC26461:  LDX #$00
LC26463:  LDA #$24
LC26465:  JSR $4E91      ;queue up something.  you tell me what.
LC26468:  RTS
print "end at: ",pc
print "wrote ",bytes," bytes"

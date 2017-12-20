
;@xkas
;xkas 0.06
hirom
;header
org $C20000


;Entry points - All battle code from outside the bank calls to here
C20000:  JMP C2000C
         JMP C2111B
         JMP C20E77     ;load equipment data for character in A
         JMP C24730

C2000C:  PHP
         SEP #$30
         LDA #$7E
         PHA            ;Put on stack
         PLB            ;set Data Bank register to 7E
         JSR C2261E
C20016:  JSR C223ED     ;Initialize many things at battle start
C20019:  INC $BE        ;increment RNG table index.  start of MAIN BATTLE LOOP.
         LDA $3402      ;Get the number of turns due to Quick
         BNE C20023     ;Branch if not zero; either we are in a regular (i.e. non-Quick
                        ;turn, or else we are in the process of executing Quick turns.
                        ;Only if the final Quick turn just passed will we do the next line.
                        ;Either way, we still need to decrement the number of Quick turns.
         DEC $3402      ;Decrement the number of turns due to Quick
C20023:  LDA #$01
         JSR C26411
         JSR C22095     ;Recalculate applicable characters' properties from their current
                        ;equipment and relics
         LDA $3A58      ;was anybody's main menu flagged to be redrawn
                        ;right away?
         BEQ C20033     ;branch if not
         JSR C200CC     ;redraw the applicable menus
C20033:  LDA $340A      ;get entry point to Special Action Queue.  high-priority stuff,
                        ;including auto-spellcasts from equipment, and timed statuses
                        ;expiring.
         CMP #$FF
         BEQ C2003D     ;branch if it's null, as queue is empty
         JMP C22163     ;Process one record from Special Action linked list queue
C2003D:  LDA #$04
         TRB $3A46      ;clear flag
         BEQ C20049     ;branch if we're not about to have Gau return at the end of
                        ;a Veldt battle
         JSR C20A91     ;for all living, present, non-Jumping characters: remove entity
                        ;from Wait Queue, remove all records from their conventional
                        ;linked list queue, and default some poses
         BRA C20019     ;branch to top of main battle loop
C20049:  LDX $3407      ;did we leave off processing an entity's Counterattack and
                        ;Periodic Damage/Healing linked list queue?
         BPL C2005F     ;if so, go resume processing it
C2004E:  LDX $3A68      ;get position of next Counterattack and Periodic Damage/Healing
                        ;[from Seizure/Regen/etc.] Queue slot to read.
         CPX $3A69      ;does it match position of the next available [unused]
                        ;queue slot?  iow, have we read through the end of queue?
         BEQ C20062     ;if so, branch
         INC $3A68      ;increment next Counterattack / Periodic Damage Queue position
         LDA $3920,X    ;see who's in line at current position
         BMI C2004E     ;if it's null entry, skip it and check next one
         TAX
C2005F:  JMP C24B7B     ;process one or two records from entity's Counterattack and
                        ;Periodic Damage/Healing linked list queue
C20062:  LDA $3A3A      ;bitfield of dead-ish monsters
         AND $2F2F      ;bitfield of remaining enemies
         BEQ C2006F
         TRB $2F2F      ;if any entity in both, rectify by clearing from latter...
         BRA C20019     ;...and go to start of main battle loop
C2006F:  LDA #$20
         TRB $B0        ;clear flag
C20073:  BEQ C2007D     ;branch if no entity has executed conventional turn since
                        ;this point was last reached
         JSR C25C73     ;Update Can't Escape, Can't Run, Run Difficulty, and
                        ;onscreen list of enemy names, based on currently present
                        ;enemies
         LDA #$06
         JSR C26411
C2007D:  LDA #$04
         TRB $B0        ;indicate that we've reached this point since C2/5BF3 last
                        ;executed [and considered queueing Flee command]
         JSR C247ED
         LDA #$FF
         LDX #$03
C20088:  STA $33FC,X    ;batch of Counterattacks and Periodic Damage/Healing is
                        ;over, so null two bitfields:
                        ;16-bit $33FC (Entity has done a "Run Monster Script"
                        ; [Command 1Fh] in this batch
                        ;16-bit $33FE (Entity was targeted in the attack that
                        ; triggered its counter, and by somebody/something other
                        ; than itself)
         DEX
         BPL C20088
         LDA #$01
         TRB $B1        ;indicate it's a conventional attack
C20092:  LDX $3A64      ;get position of next Wait Queue slot to read.
                        ;yes, we even wait in order to wait; they're very polite
                        ;over in Japan.
         CPX $3A65      ;does it match position of the next available [unused]
                        ;queue slot?  iow, have we read through the end of queue?
         BEQ C200A6     ;if so, branch
         INC $3A64      ;increment next Wait Queue position
         LDA $3720,X    ;see who's in line at current position
         BMI C20092     ;if it's null entry, skip it and check next one
         TAX
         JMP C22188     ;Do early processing of one record from entity's
                        ;conventional linked list queue, establish "time to wait",
                        ;and visually enter ready stance if character
C200A6:  LDX $3406      ;did we leave off processing an entity's conventional
                        ;linked list queue?
         BPL C200C2     ;if so, go resume processing it
C200AB:  LDX $3A66      ;get position of next Action Queue slot to read
         CPX $3A67      ;does it match position of the next available [unused]
                        ;queue slot?  iow, have we read through the end of queue?
         BNE C200B9     ;if not, branch
         STZ $3A95      ;allow C2/47FB to check for combat end
         JMP C20019     ;branch to start of main battle loop
C200B9:  INC $3A66      ;increment next Action Queue position
         LDA $3820,X    ;see who's in line at current position
         BMI C200AB     ;if it's null entry, which can happen from Palidor
                        ;and who knows what else, skip it and check next one
         TAX
C200C2:  JMP C200F9     ;Do later processing of one or more records from entity's
                        ;conventional linked list queue


C200C5:  LDA #$09
         JSR C26411
         PLP
         RTL


;Redraw main menus of characters who requested it in C2/527D
;Will keep grayed versus white commands up-to-date.)

C200CC:  LDX #$06
C200CE:  LDA $3018,X
         TRB $3A58      ;clear flag to redraw this character's menu
                        ;[note that switching between characters with
                        ;X and Y will still redraw]
         BEQ C200DF     ;branch if it hadn't been set
         STX $10
         LSR $10
         LDA #$0B
         JSR C26411     ;this must be responsible for the menu redrawing
C200DF:  DEX
         DEX
         BPL C200CE     ;loop for all 4 party members
         RTS


C200E4:  TSB $3F2C      ;set "Jumping" flag for whomever is held in A
         SEP #$20       ;Set 8-bit Accumulator
         LDA $3AA0,X
         ORA #$08
         AND #$DF
         STA $3AA0,X    ;$3AA0: turn on bit 3 and turn off bit 5
         STZ $3AB5,X    ;zero top byte of Wait Timer
         JMP C24E66     ;put entity in wait queue


;Do later processing of one or more records from entity's conventional linked list queue

C200F9:  SEC
         ROR $3406      ;make $3406 negative.  this defaults to not leaving
                        ;off processing any entity.
         PEA.w C20019-1 ;will return to C2/0019
C20100:  LDA #$12
         STA $B5
         STA $3A7C
         LDA $32CC,X    ;get entry point to entity's conventional linked list
                        ;queue
         BMI C20183     ;branch if null.  that can happen if a monster script
                        ;ran and didn't perform anything; e.g. Command F0h
                        ;chose an FEh.  alternatively, a monster script ran when
                        ;this linked list queue was otherwise empty, so command
                        ;it queued added records to both this list and the $3820
                        ;"who" queue.  then this list is emptied right before
                        ;executing the command, without adjusting $3A66 to delete
                        ;the $3820 queue record.
                        ;in any case, with this test as a safeguard and C2/00B9
                        ;getting rid of the stranded $3820 record, we're good.
         ASL
         TAY            ;adjust pointer for 16-bit fields
         LDA $3420,Y    ;get command from conventional linked list queue
         CMP #$12
         BNE C20118     ;Branch if not Mimic
         JSR C201D9     ;Copy contents of Mimic variables over [and possibly
                        ;after] queued command, attack, and targets data
C20118:  SEC
         JSR C20276     ;Load command, attack, targets, and MP cost from queued
                        ;data.  Some commands become Fight if tried by an Imp.
         CMP #$1F       ;is the command "Run Monster Script"?
         BNE C2013E     ;branch if not
         JSR C20301     ;Remove current first record from entity's conventional
                        ;linked list queue, and update their entry point
                        ;accordingly
         LDA $3A97
         BNE C20134     ;branch if in the Colosseum
         LDA $3395,X
         BPL C20134     ;branch if the monster is Charmed
         LDA $3EE5,X
         BIT #$30
         BEQ C20139     ;Branch if not Berserk or Muddled
C20134:  JSR C20634     ;Picks random command for monsters
         BRA C20100     ;go load next record in entity's conventional linked
                        ;list queue
C20139:  JSR C202DC     ;Run Monster Script, main portion
         BRA C20100     ;go load next record in said queue
C2013E:  CMP #$16       ;is the command Jump?
         BNE C2014E     ;branch if not
         REP #$20       ;Set 16-bit Accumulator
         LDA $3018,X
         TRB $3F2C      ;clear the entity's "Jumping" flag
         BEQ C200E4     ;if it hadn't been set, we're currently initiating a
                        ;jump rather than landing from one, so go set the
                        ;flag and do some other preparation.
         SEP #$20
C2014E:  LDA $32CC,X    ;get entry point to queue
         TAY
         LDA $3184,Y    ;get the pointer/ID of record stored at that entry point
         CMP $32CC,X    ;do the contents of that field match the position of
                        ;the record?  that is, it's a standalone record or the
                        ;last record in the linked list.
         BNE C2016D     ;branch if that's not the case.  the main goal seems to
                        ;be skipping code for non-final Gem Box attacks.
         LDA #$80
         TRB $B1
         LDA #$FF
         CPX $3404      ;Is this target under the influence of Quick?
         BNE C2016D     ;Branch if not
         DEC $3402      ;Decrement the number of turns due to Quick
         BNE C2016D     ;Branch if this was not the last Quick turn
         STA $3404      ;If it was, store an #$FF (empty) in Quick's target byte
C2016D:  XBA
         LDA $3AA0,X
         BIT #$50
         BEQ C2017A     ;branch if bits 4 and 6 both unset
         LDA #$80
         JMP C25BAB     ;set bit 7 of $3AA1,X
C2017A:  LDA #$FF
         STA $3184,Y    ;null current first record in entity's conventional
                        ;linked list queue
         XBA
         STA $32CC,X    ;either make entry point index next record, or null it
C20183:  LDA $3AA0,X
         AND #$D7
         ORA #$40
         STA $3AA0,X    ;turn off bits 3 and 5.  turn on bit 6.
         LSR
         BCC C201A6     ;branch if entity not present in battle
         LDA $3204,X
         ORA #$04
         STA $3204,X
         LDA $3205,X
         ORA #$80
         STA $3205,X    ;indicate entity has taken a conventional turn
                        ;[including landing one] since boarding Palidor
         JSR C213D3     ;Character/Monster Takes One Turn
         JSR C2021E     ;Save this command's info in Mimic variables so Gogo
                        ;will be able to Mimic it if he/she tries.
C201A6:  LDA #$A0
         TSB $B0        ;indicate entity has executed conventional turn since
;                                     C20073 was last reached, and indicate we're in middle
                        ;of processing a conventional linked list queue
         LDA #$10
         TRB $3A46      ;clear "Palidor was summoned this turn" flag
         BNE C201B7     ;branch if it had been set
         LDA $32CC,X    ;get entry point to entity's conventional linked list
                        ;queue
         INC
         BNE C201D5     ;branch if it's valid
C201B7:  LDA $3AA0,X
         BIT #$08
         BNE C201C6
         INC $3219,X
         BNE C201C6
         DEC $3219,X    ;increment top byte of ATB counter if not 255
C201C6:  LDA #$FF
         STA $322C,X
         STZ $3AB5,X    ;zero top byte of Wait Timer
         LDA #$80
         TRB $B0        ;we're not in middle of processing a conventional
                        ;linked list queue
         JMP C20267
C201D5:  STX $3406      ;leave off processing entity in X
C201D8:  RTS


;Replace queued command, attack, and targets with contents of Mimic variables.
; And if mimicking X-Magic, add queue entry for second spell.)

C201D9:  LDA $3F28      ;16h if last character command was Jump,
                        ;12h if it's a different command
         CMP #$16
         BNE C201F1     ;branch if not Jump
         REP #$20
         LDA $3F28      ;Last command and attack [Jump and 00h]
         STA $3420,Y    ;update command and attack in entity's conventional
                        ;linked list queue
         LDA $3F2A      ;Last targets
         STA $3520,Y    ;update targets in entity's conventional linked
                        ;list queue
         SEP #$20
         RTS

C201F1:  REP #$20
         LDA $3F20      ;Last command and attack
         STA $3420,Y    ;update command and attack in entity's conventional
                        ;linked list queue
         LDA $3F22      ;Last targets
         STA $3520,Y    ;update targets in entity's conventional linked
                        ;list queue
         SEP #$20
         LDA $3F24      ;Last command and attack (second attack w/ Gem Box)
         CMP #$12
         BEQ C201D8     ;exit if there was none
         REP #$20
         LDA $3F24      ;Last command and attack (second attack w/ Gem Box)
         STA $3A7A
         LDA $3F26      ;Last targets (second attack w/ Gem Box)
         STA $B8
         SEP #$20
         LDA #$40
         TSB $B1        ;stops Function C2/4F08 from deducting MP cost for second
                        ;Gem Box spell.  no precaution needed for first, as the
                        ;function is run with a command of 12h [Mimic] then.
         JMP C24ECB     ;queue the second X-Magic spell, in entity's
                        ;conventional queue


;Save this command's info in Mimic variables so Gogo will be able to
; Mimic it if he/she tries.)

C2021E:  PHX
         PHP
         CPX #$08
         BCS C20264     ;exit if it's a monster taking this turn
         LDA $3A7C      ;get original command of just-executed turn
         CMP #$1E
         BCS C20264     ;exit if not a normal character command.  iow,
                        ;if it was enemy Roulette, "Run Monster Script",
                        ;periodic damage/healing, etc.
         ASL
         TAX
         LDA $CFFE00,X  ;get command data
         BIT #$02
         BEQ C20264     ;exit if this command can't be Mimicked.  such
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
         LDA #$12
         STA $3F28      ;indicate to Mimic that the command is something
                        ;other than Jump?
         LDA $3A7C      ;get original command of just-executed turn
         CMP #$17
         BEQ C20256     ;branch if command was X-Magic.  it seems the first turn
                        ;of a Gem Box sequence has Magic in the command ID, and
                        ;the second turn has X-Magic.
         LDA #$12
         STA $3F24      ;Last command and attack (second attack w/ Gem Box
                        ;for use by Mimic.  in other words, default to indicating
                        ;there was no 2nd Gem Box attack.
         REP #$20
         LDA $3A7C      ;get original command of just-executed turn
         STA $3F20      ;Last command and attack (for use by Mimic)
         LDA $3A30      ;get backup targets from just-executed turn
         STA $3F22      ;Last targets (for use by Mimic)
         BRA C20264
C20256:  REP #$20
         LDA $3A7C      ;get original command of just-executed turn
         STA $3F24      ;Last command and attack (second attack w/ Gem Box
                        ;(for use by Mimic)
         LDA $3A30      ;get backup targets from just-executed turn
         STA $3F26      ;Last targets (second attack w/ Gem Box) (for use by Mimic)
C20264:  PLP
         PLX
         RTS


C20267:  LDA #$0D
         STA $2D6E      ;first byte of first entry of ($76) buffer
         LDA #$FF
         STA $2D72      ;first byte of second entry of ($76) buffer
         LDA #$04
         JMP C26411     ;Execute animation queue


;Load command, attack, targets, and MP cost from queued data.  If attacker Imped and
; command not supported while Imped, turn into Fight.)

C20276:  PHP
         REP #$20       ;Set 16-bit Accumulator
         LDA $3520,Y    ;get targets from a linked list queue [one of three
                        ;queue types, depending on caller]
         STA $B8        ;save as targets
         LDA $3420,Y    ;get command and attack from same linked list queue
         STA $3A7C      ;save as original command
         STA $B5        ;save as command
         PLP
         PHA            ;Put on stack
         BCC C2029A     ;branch if not a conventional turn
         CMP #$1D
         BCS C2029A     ;Branch if command is MagiTek or a non-character
                        ;command?
         LDA $3018,X
         TRB $3A4A      ;clear "Entity's Zombie or Muddled changed since
                        ;last command or ready stance entering"
         BEQ C2029A     ;branch if it was already clear
         STZ $B8
         STZ $B9        ;clear attack's targets
C2029A:  LDA $3620,Y    ;get MP cost from a linked list queue [one of three
                        ;queue types, depending on caller]
         STA $3A4C      ;save actual MP cost to caster
         LDA $3EE4,X
         BIT #$20       ;Check for Imp Status
         BEQ C202DA     ;Branch if not imp
         LDA $B5        ;get command
         CMP #$1E
         BCS C202DA     ;branch if not character command
         PHX
         ASL
         TAX
         LDA $CFFE00,X  ;get command data

;Bit 2 set for Fight, Item, Magic, Revert,
; Mimic, Row, Def., Jump, X-Magic,
; Health, Shock)

;0F, 07, 07, 00, 04, 0B, 0B, 03
; 03, 03, 03, 03, 03, 03, 01, 03
; 0B, 00, 05, 03, 04, 04, 05, 07
; 03, 03, 06, 06, 01, 0A, 00, 00 )

         PLX
         BIT #$04
         BNE C202DA     ;branch if command is supported while Imped
         STZ $3A4C      ;zero actual MP cost to caster
         PHX
         TDC            ;clear 16-bit A
         CPX #$08       ;set Carry if monster attacker
         ROL
         TAX            ;move Carry into X
         LDA $B8,X      ;get targets from $B8 or $B9
         AND $3A40,X    ;characters acting as enemies.  i believe $3A41
                        ;will always be zero.
         STA $B8,X      ;remove all targets who weren't members of opposition
         REP #$20
         STZ $3A7C
         STZ $B5        ;zero out command, making it Fight
         LDA $B8        ;get all targets of attack
         JSR C2522A     ;pick one at random
         STA $B8
         SEP #$20
         PLX
C202DA:  PLA
         RTS


;Run Monster Script [Command 1Fh], main portion, and handle bookmarking

C202DC:  REP #$20
         STZ $3A98      ;don't prohibit any script commands for upcoming call
         LDA $3254,X    ;offset of monster's main script
         STA $F0        ;upcoming $1A2F call will start at this position
         LDA $3D0C,X    ;main script position after last executed FD command.
                        ;iow, where we left off.  applicable when $3240,X =/=
                        ;FFh.
         STA $F2
         LDA $3240,X    ;index of sub-block in main script where we left off
                        ;if we exited script due to FD command, null FFh
                        ;otherwise.
         STA $F4
         CLC
         JSR C21A2F     ;Process monster's main script, backing up targets first
         LDA $F2
         STA $3D0C,X    ;save main script position after last executed FD
                        ;command.  iow, where we're leaving off.
         SEP #$20
         LDA $F5
         STA $3240,X    ;if we exited script due to FD command, save sub-block
                        ;index of main script where we left off.  if we exited
                        ;due to executing FE command or executing/reaching
                        ;FF command, save null FFh.
         RTS


;Remove current first record from entity's conventional linked list queue, and update
;their entry point accordingly  (operates on different list if called from C2/4C54)

C20301:  LDA $32CC,X    ;get entry point to entity's [conventional or other]
                        ;linked list queue
         BMI C2031B     ;exit if null [list is empty]
         PHY
         TAY
         LDA $3184,Y    ;read pointer/ID of current first record in entity's
                        ;[conventional or other] linked list queue
         CMP $32CC,X    ;if field's contents match record's position, it's a
                        ;standalone record, or the last in the list
         BNE C20312     ;branch if not, as there are more records left
         LDA #$FF
C20312:  STA $32CC,X    ;either make entry point index next record, or null it
         LDA #$FF
         STA $3184,Y    ;null current first record in entity's [conventional
                        ;or other] linked list queue
         PLY
C2031B:  RTS


C2031C:  STZ $B8
         STZ $B9
         INC $322C,X
         BEQ C20328
         DEC $322C,X    ;if Time to Wait is FFh, set it to 0
C20328:  JSR C20A41     ;clear Defending flag
         LDA $3E4C,X
         AND #$FA
         STA $3E4C,X    ;Clear Retort and Runic
         CPX #$08
         BCC C20344     ;branch if character
         LDA $32CC,X    ;get entry point to entity's conventional linked list
                        ;queue
         BPL C20357     ;branch if valid
         LDA #$1F
         STA $3A7A      ;set command to "Run Monster Script"
         JMP C24ECB     ;queue it, in entity's conventional queue


C20344:  LDA $3018,X
         TRB $3A4A      ;clear "Entity's Zombie or Muddled changed since
                        ;last command or ready stance entering"
         LDA $3255,X    ;top byte of offset of main script
         BMI C20352     ;branch if character has no main script
         JMP C202DC     ;Run Monster Script, main portion


C20352:  LDA $32CC,X    ;get entry point to entity's conventional linked list
                        ;queue
         BMI C2037B     ;branch if null
C20357:  PHA            ;Put on stack
         ASL
         TAY            ;adjust index for 16-bit fields
         REP #$20
         LDA $3520,Y    ;get targets from entity's conventional linked list
                        ;queue
         STA $B8        ;save as targets
         LDA $3420,Y    ;get command and attack from entity's conventional
                        ;linked list queue
         JSR C203E4     ;Determine command's "time to wait", recalculate
                        ;targets if there aren't any
         LDA $B8        ;get targets, possibly modified if there weren't any
                        ;before function call
         STA $3520,Y    ;save in entity's conventional linked list queue
         SEP #$20
         PLA
         TAY            ;adjust index for 8-bit field
         CMP $3184,Y    ;does pointer/ID of this record in conventional linked
                        ;list queue match its position?
         BEQ C2037A     ;if so, it's a standalone record or the last record
                        ;in the list, so exit
         LDA $3184,Y    ;otherwise, it should point to another record, so...
         BRA C20357     ;...loop and check that one.
C2037A:  RTS


C2037B:  LDA $3EF8,X
         LSR
         BCS C203D7     ;Branch if Dance status
         LDA $3EF9,X
         LSR
         BCS C203CE     ;Branch if Rage status
         LDA $3EE4,X
         BIT #$08
         BNE C203C6     ;Branch if M-Tek status
         JSR C20420     ;pick action to take if character Berserked,
                        ;Zombied, Muddled, Charmed, or in the Colosseum
         CMP #$17
         BNE C203B0     ;Branch if chosen command not X-Magic
         PHA            ;save command on stack
         XBA
         PHA            ;Put on stack
         PHA            ;save attack/spell on stack twice
         TXY
         JSR C2051A     ;Pick another spell
         STA $01,S      ;replace latter stack copy with that spell
         PLA
         XBA
         LDA #$02       ;ID of Magic command
         JSR C203E4     ;Determine command's "time to wait", recalculate
                        ;targets if there aren't any
         JSR C24ECB     ;queue that spell under Magic command, in entity's
                        ;conventional queue
         STZ $B8
         STZ $B9        ;clear any targets set by above C2/03E4 call, so
                        ;next one can choose its own
         PLA            ;retrieve initial attack/spell from stack
         XBA
         PLA            ;retrieve initial command from stack
C203B0:  JSR C203B9     ;Swap Roulette to Enemy Roulette
         JSR C203E4     ;Determine command's "time to wait", recalculate
                        ;targets if there aren't any
         JMP C24ECB     ;queue earlier-chosen spell under X-Magic command,
                        ;in entity's conventional queue


;Swap Roulette to Enemy Roulette

C203B9:  PHP
         REP #$20
         CMP #$8C0C     ;is the command Lore and the attack Roulette?
         BNE C203C4     ;branch if not
         LDA #$8C1E     ;set command to Enemy Roulette, keep attack as
                        ;Roulette
C203C4:  PLP
         RTS


C203C6:  JSR C20584     ;randomly pick a Magitek attack
         XBA
         LDA #$1D       ;Magitek command ID
         BRA C203DE
 

C203CE:  TXY
         JSR C205D1     ;Picks a Rage [when Muddled/Berserked/etc], and picks
                        ;the Rage move
         XBA
         LDA #$10       ;Rage command ID
         BRA C203DE
 

C203D7:  TXY
         JSR C2059C     ;picks a Dance and a dance move
         XBA
         LDA #$13       ;Dance command ID
C203DE:  JSR C203E4     ;Determine command's "time to wait", recalculate
                        ;targets if there aren't any
         JMP C24ECB     ;queue chosen Dance move, in entity's conventional
                        ;queue


;Determine command's "time to wait" [e.g. for character's ready stance], recalculate
; targets if there aren't any)

C203E4:  PHP
         SEP #$30       ;Set 8-bit A, X, & Y
         STA $3A7A      ;save command in temporary variable
         XBA
         STA $3A7B      ;save attack in temporary variable
         XBA
         CMP #$1E
         BCS C2041E     ;branch if command is 1Eh or above.. i.e. it's
                        ;enemy Roulette or "Run Monster Script"
         PHA            ;Put on stack
         PHX
         TAX
         LDA C2067B,X   ;get command's "time to wait"
         PLX
         CLC
         ADC $322C,X    ;add it to character's existing "time to wait"
         BCS C20404
         INC
         BNE C20406
C20404:  LDA #$FF
C20406:  DEC            ;if sum overflowed or equalled FFh, set it to FEh.
                        ;otherwise, keep it.
         STA $322C,X    ;update time to wait
         PLA
         JSR C226D3     ;Load data for command and attack/sub-command, held
                        ;in A.bottom and A.top
         LDA #$04
         TRB $BA        ;Clear "Don't retarget if target invalid"
         REP #$20
         LDA $B8
         BNE C2041E     ;branch if there are already targets
         STZ $3A4E      ;clear backup already-hit targets
         JSR C2587E     ;targeting function
C2041E:  PLP
         RTS


;Pick action to take if character Berserked, Zombied, Muddled, Charmed, or in the Colosseum

C20420:  TXA
         XBA
         LDA #$06
         JSR C24781     ;X * 6
         TAY
         STZ $FE        ;save Fight as Command 5
         STZ $FF
         LDA $202E,Y    ;get Command 1
         STA $F6
         LDA $2031,Y    ;get Command 2
         STA $F8
         LDA $2034,Y    ;get Command 3
         STA $FA
         LDA $2037,Y    ;get Command 4
         STA $FC
         LDA #$05       ;indicate 5 valid commands to choose from..
                        ;this number may drop.
         STA $F5

         LDA $3EE5,X    ;Status byte 2
         ASL
         ASL
         STA $F4        ;Bit 7 = Muddled, Bit 6 = Berserk, etc
         ASL
         BPL C20452     ;Branch if no Berserk status
         STZ $F4        ;Clear $F4, then skip Charm and Colosseum checks
                        ;if Berserked
         BRA C2045E
C20452:  LDA $3395,X    ;Which target Charmed you, FFh if none did
         EOR #$80       ;Bit 7 will now be set if there IS a Charmer
         TSB $F4
         LDA $3A97      ;FFh if Colosseum battle, 00h otherwise
         TSB $F4        ;so set Bit 7 [and others] if in Colosseum

;Note that Berserk status will override Muddle/Charm/Colosseum for purposes of
; determining whether we choose from the C2/04D0 or the C2/04D4 command list.
; In contrast, Zombie will not; Charm/Colosseum/Muddle override it.)

C2045E:  TXY            ;Y now points to the attacker who is taking this
                        ;turn.  will be used by the $04E2 and $04EC
                        ;functions, since X gets overwritten.

         PHX
         LDX #$06       ;start checking 4th command slot
C20462:  PHX            ;save slot position
         LDA $F6,X
         PHA            ;save command
         BMI C20482     ;branch if slot empty
         CLC            ;clear Carry
         JSR C25217     ;X = A DIV 8, A = 2 ^ (A MOD 8)
         AND C204D0,X   ;is command allowed when Muddled/Charmed/Colosseum?
         BEQ C20482     ;branch if not
         LDA $F4
         BMI C20488     ;Branch if Muddled/Charmed/Colosseum but not Berserked
         LDA $01,S      ;get command
         CLC
         JSR C25217     ;X = A DIV 8, A = 2 ^ (A MOD 8)
         AND C204D4,X   ;is command allowed when Berserked/Zombied?
         BNE C20488     ;branch if so

C20482:  LDA #$FF
         STA $01,S      ;replace command on stack with Empty entry
         DEC $F5        ;decrement number of valid commands
C20488:  TDC            ;clear 16-bit A
         LDA $01,S      ;get current command

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

         LDX #$08
C2048D:  CMP C204D8,X   ;does our current command match one from table?
         BNE C20499     ;if not, compare it to a second command in this
                        ;loop iteration
         JSR (C204E2,X) ;if it does, call the special code used by
                        ;that command
         XBA            ;put attack/spell # in top of A
         BRA C204A9     ;exit loop, as we found our command
C20499:  CMP C204D9,X   ;does our current command match one from table?
         BNE C204A5     ;if not, our current command didn't match either
                        ;compared one.  so move to new pair of commands
                        ;in table, and repeat loop
         JSR (C204EC,X) ;if it did match, call the special code used
                        ;by that command
         XBA            ;put attack/spell # in top of A
         BRA C204A9     ;exit loop, as we found our command
C204A5:  DEX
         DEX
         BPL C2048D     ;Loop to compare current command to all 10 commands
                        ;that utilize special code.
                        ;If this loop doesn't exit before X becomes negative,
                        ;that means our current command has no special function,
                        ;and the Attack # in the top half of A will be zero.
C204A9:  PLA            ;get command # from stack
         PLX            ;get command slot from stack
         STA $F6,X      ;save command # in current command slot
         XBA
         STA $F7,X      ;save attack/spell # corresponding to that attack
         DEX
         DEX
         BPL C20462     ;loop for first 4 command slots

;Fight has been put in the 5th command slot.  Any valid commands, with their
; accompanying attack/spell numbers, have been established for slots 1 thru 4.
; Now we shall randomly pick from those commands.  Each slot should have equal
; probability of being chosen.)

         LDA $F5        ;# of valid command slots
         JSR C24B65     ;RNG: 0 to A - 1 .  we're randomly picking a command
         TAY
         LDX #$08       ;start pointing to Command slot 5
C204BC:  LDA $F6,X
         BMI C204C3     ;if that command slot is Empty, move to next one
         DEY            ;only decrement when on a valid command slot
         BMI C204CA     ;If Y is negative, we've found our Nth valid command
                        ;[starting with the last valid command and counting
                        ;backward], where N is the number returned from the
                        ;RNG plus 1.
                        ;This is what we wanted, so branch.

C204C3:  DEX
         DEX
         BPL C204BC     ;loop for all 5 command slots
         TDC            ;clear 16-bit A
         BRA C204CE     ;clean up stack and exit function.  A is zero,
                        ;indicating Fight, which must be a fallback in case
                        ;all 5 Command slots somehow came up useless.  not
                        ;sure how that'd happen, as Slot #5 should always
                        ;hold Fight anyway...

C204CA:  XBA
         LDA $F7,X
         XBA            ;bottom of A = command # from $F6,X
                        ;top of A = attack/spell # from $F7,X
C204CE:  PLX
         RTS


;Data - commands allowed when Muddled/Charmed/Colosseum brawling

C204D0: db $ED  ;Fight, Magic, Morph, Steal, Capture, SwdTech
      : db $3E  ;Tools, Blitz, Runic, Lore, Sketch
      : db $DD  ;Rage, Mimic, Dance, Row, Jump, X-Magic
      : db $2D  ;GP Rain, Health, Shock, MagiTek

;in other words: Item, Revert, Throw, Control, Slot, Leap, Def., Summon, and Possess
;are excluded)

;Data - commands allowed when Berserked/Zombied

C204D4: db $41  ;Fight, Capture
      : db $00  ;none
      : db $41  ;Rage, Jump
      : db $20  ;MagiTek


;Commands that need special functions when character acts automatically

C204D8: db $02   ;Magic
C204D9: db $17   ;X-Magic
      : db $07   ;SwdTech
      : db $0A   ;Blitz
      : db $10   ;Rage
      : db $13   ;Dance
      : db $0C   ;Lore
      : db $03   ;Morph
      : db $1D   ;MagiTek
      : db $09   ;Tools


;Code pointers

C204E2: dw C2051A     ;Magic
      : dw C20560     ;SwdTech
      : dw C205D1     ;Rage
      : dw C204F6     ;Lore
      : dw C20584     ;MagiTek

C204EC: dw C2051A     ;X-Magic
      : dw C20575     ;Blitz
      : dw C2059C     ;Dance
      : dw C20557     ;Morph
      : dw C2058D     ;Tools


;Lore
C204F6:  LDA $3EE5,Y    ;Status Byte 2
         BIT #$08
         BNE C2054F     ;Branch if Mute
         LDA $3A87      ;Number of Lores possessed
         BEQ C2054F     ;if there's zero, don't use Lore command
         PHA            ;Put on stack
         REP #$21       ;Set 16-bit A, Clear Carry
         LDA $302C,Y    ;starting address of Magic menu [actually address
                        ;of Esper menu]
         ADC #$00D8     ;add 54 spells * 4 to get to next menu, which is
                        ;Lore [loop at C2/0534 won't use the 0 index, which
                        ;is why it won't wrongly select the last Magic spell]
         STA $EE
         SEP #$20       ;Set 8-bit Accumulator
         PLA
         XBA            ;put # of Lores possessed in top of A
         LDA #$60       ;there are 24 Lores, and each menu slot must occupy
                        ;4 bytes, so set loop limit to 96
         JSR C20534     ;randomly pick a valid Lore menu slot
         CLC
         ADC #$8B       ;first Lore is #139, Condemned
         RTS


;Magic and X-Magic
C2051A:  LDA $3EE5,Y    ;Status Byte 2
         BIT #$08
         BNE C2054F     ;Branch if Mute
         LDA $3CF8,Y    ;Number of spells possessed by this character
         BEQ C2054F     ;if there's zero, don't use Magic/X-Magic command
         PHA            ;Put on stack
         REP #$20       ;Set 16-bit Accumulator
         LDA $302C,Y    ;starting address of Magic menu [actually address of
                        ;Esper menu, but loop at C2/0534 won't use the 0 index]
         STA $EE
         SEP #$20       ;Set 8-bit Accumulator
         PLA
         XBA            ;put # of spells possessed in top of A
         LDA #$D8       ;there are 54 spells, and each menu slot must occupy
                        ;4 bytes, so set loop limit to 216
C20534:  PHX
         PHY
         TAY
         XBA            ;retrieve number of spells/Lores possessed
         JSR C24B65     ;RNG: 0 to A - 1 . we're randomly picking a
                        ;spell/lore
         TAX
C2053C:  LDA ($EE),Y    ;get what's in this Magic/Lore menu slot
         CMP #$FF       ;is it null?
         BEQ C20545     ;if so, skip to next slot
         DEX
         BMI C2054C     ;If X becomes negative, that means we've found the
                        ;Nth valid slot [starting with the last valid slot
                        ;and counting backward], where N is the X returned
                        ;from our RNG plus 1.
                        ;This is what we wanted, so branch.
C20545:  DEY
         DEY
         DEY
         DEY
         BNE C2053C     ;loop and check next slot
         TDC            ;if we didn't get any matches, just use Fire
                        ;[or Condemned for Lore, since 139 gets added]
C2054C:  PLY
         PLX
         RTS


;Randomly chosen command failed, for whatever reason
C2054F:  DEC $F5        ;decrement # of valid command slots
         LDA #$FF
         STA $03,S      ;store Empty in current command slot, indicating
                        ;that it cannot be chosen
         TDC            ;clear 16-bit A.  note that only the bottom 8-bits,
                        ;which indicate the attack/spell #, matter..
                        ;the command # is loaded by the stack retrieval at
;                                     C204A9, and will obviously be FFh in this case.)
         RTS


;Morph
C20557:  LDA #$0F
         CMP $1CF6      ;Morph supply
         TDC            ;clear 16-bit A
         BCS C2054F     ;if Morph supply isn't at least 16, don't allow
                        ;Morph command
         RTS


;SwdTech
C20560:  LDA $3BA4,Y    ;Special properties for right-hand weapon slot
         ORA $3BA5,Y    ;'' for left-hand
         BIT #$02       ;is Swdtech allowed by at least one hand?
         BEQ C2054F     ;if not, don't use Swdtech as command
         LDA $2020      ;index of highest known Swdtech
         INC            ;# of known Swdtechs
         JSR C24B65     ;random #: 0 to A-1.  Pick a known Swdtech.
         CLC
         ADC #$55       ;first Swdtech is #85, Dispatch
         RTS


;Blitz
C20575:  TDC
         LDA $1D28      ;Known Blitzes
         JSR C2522A     ;Pick a random bit that is set
         JSR C251F0     ;Get which bit is picked
         TXA
         CLC
         ADC #$5D       ;first Blitz is #93, Pummel
         RTS


;MagiTek
C20584:  LDA #$03
         JSR C24B65     ;0 to 2 -- only pick between first 3 MagiTek moves,
                        ;since anybody besides Terra can only use
                        ;Fire Beam + Bolt Beam + Ice Beam + Heal Force,
                        ;but there's Bio Blast in between those last two.

                        ;just picking from the first three simplifies code,
                        ;although decent planning would have had Heal Force
                        ;before Bio Blast..  or add a few instructions here
                        ;and include Heal Force anyway.
         CLC
         ADC #$83       ;first MagiTek move is #131, Fire Beam
         RTS


;Tools
C2058D:  TDC
         LDA $3A9B      ;Which tools are owned
         JSR C2522A     ;Pick a random tool that is owned
         JSR C251F0     ;Get which bit is set, thus returning a 0-7
                        ;Tool index
         TXA
         CLC
         ADC #$A3       ;item number of first tool, NoiseBlaster, is 163
         RTS


;Picks dance, and dance move

C2059C:  PHX
         LDA $32E1,Y    ;get the dance number
         CMP #$FF       ;is it null?
         BNE C205B2     ;if it's valid, a Dance has already been chosen,
                        ;so just proceed to choose a step
         TDC            ;clear 16-bit A
         LDA $1D4C      ;bitfield of known Dances
         JSR C2522A     ;Pick a random bit that is set
         JSR C251F0     ;X = Get which bit is picked
         TXA
         STA $32E1,Y    ;save our Dance #
C205B2:  ASL
         ASL            ;* 4
         STA $EE        ;Each Dance has 4 steps, and occupies 4 bytes
                        ;in the Dance Step --> Attack Number table
                        ;at $CFFE80
         JSR C24B5A     ;RNG: 0 to 255
         LDX #$02
C205BB:  CMP C205CE,X   ;see data below for chances of each step
         BCS C205C3
         INC $EE        ;move to next step for this Dance
C205C3:  DEX
         BPL C205BB     ;loop until we reach step determined by random #
         LDX $EE        ;= (Dance * 4) + step
         LDA $CFFE80,X  ;get attack # for the Dance step used
         PLX
         RTS


;Data - for chances of each dance step
;Probabilities: Dance Step 0 = 7/16, Step 1 = 6/16, Step 2 = 2/16, Step 3 = 1/16)

C205CE: db $10
      : db $30
      : db $90


;Picks a Rage [when Muddled/Berserked/etc], and picks the Rage move

C205D1:  PHX
         PHP
         TDC
         STA $33A9,Y
         LDA $33A8,Y    ;which monster it is
         CMP #$FF
         BNE C20600     ;branch if a non-null monster was passed
         INC
         STA $33A8,Y    ;store enemy #0, Guard
         LDA $3A9A      ;# of rages possessed
         JSR C24B65
         INC            ;random #: 1 to $3A9A
         STA $EE
         LDX #$00
C205ED:  LDA $257E,X    ;Rage menu.  was filled in C2/580C routine.
         CMP #$FF
         BEQ C20600     ;branch if that menu slot was null, which means
                        ;enemy #0 should be defaulted to
         DEC $EE        ;decrement our random index
         BEQ C205FD     ;if it's zero, branch, and use the menu item last read
         INX
         BNE C205ED     ;loop again to check next menu entry
         BRA C20600     ;if we've looped a full 256 times and somehow there's
                        ;been no match with the random index, branch and just
                        ;use enemy #0

;i'm not sure what the purpose of the above loop is..  it selects Enemy #0
; if any menu slots up to and including the randomly chosen one hold FFh.  maybe it's a check
; to see if the list got "broken," as a normally generated one should never have any nulls
; in the middle.)

C205FD:  STA $33A8,Y    ;store enemy number
C20600:  JSR C24B53     ;random: 0 or 1 in Carry flag
         REP #$30
         ROL
         TAX            ;X: 0 or 1
         SEP #$20       ;Set 8-bit Accumulator
         LDA $CF4600,X  ;load Rage move
         PLP
         PLX
         RTS


;Load monster Battle and Special graphics, its special attack, and
; elemental/status/special properties)

C20610:  PHP
         LDA $33A8,Y    ;Which monster it is
         TAX
         XBA
         LDA $CF37C0,X  ;get enemy Special move graphic
         STA $3C81,Y
         LDA #$20
         JSR C24781     ;get monster # * 32 to access the monster
                        ;data block
         REP #$10
         TAX
         LDA $CF001A,X  ;monster's regular weapon graphic
         STA $3CA8,Y
         STA $3CA9,Y
         JSR C22DC1     ;load monster's special attack, elemental properties,
                        ;statuses, status immunities, special properties like
                        ;Human/Undead/Dies at MP=0 , etc
         PLP
         RTS


;Picks command for Muddled/Charmed/Berserk/Colosseum monsters

C20634:  PHX
         REP #$30       ;Set 16-bit A, X, & Y
         LDA $1FF9,X    ;Which monster it is
         ASL
         ASL
         TAX            ;multiply monster # by 4 to index its
                        ;Control/Muddled/Charm/Colosseum attack table
         LDA $CF3D00,X  ;Muddled commands 1 and 2
         STA $F0
         LDA $CF3D02,X  ;Muddled commands 3 and 4
         STA $F2
         SEP #$30       ;Set 8-bit A, X, & Y
         STZ $EE
         JSR C24B5A     ;random: 0 to 255
         AND #$03       ;0 to 3 - point to a random attack slot
         TAX
C20653:  LDA $F0,X
         CMP #$FF
         BNE C20664     ;branch if valid attack in slot
         DEX
         BPL C20653     ;loop through remainder of attack slots
         INC $EE        ;if we couldn't find any valid attacks,
                        ;increment counter
         BEQ C20664     ;give up if we've incremented it 256 times?
                        ;i can't see why more than 1 time would be
                        ;necessary..  if we give up, it appears
                        ;FFh is retained as the attack #, which
                        ;should make the monster do nothing..
                        ;it would've been far faster to change C2/064B
                        ;to "LDA #$FF / STA $EE" and this BEQ to a BNE.
         LDX #$03       ;if randomly chosen attack slot and all the
                        ;ones below it were Empty, go do the loop again,
                        ;this time starting with the highest
                        ;numbered slot.  this way, we'll check EVERY
                        ;slot before throwing in the towel.
         BRA C20653
C20664:  PLX
         PHA            ;Put on stack
         LDA $3EE5,X
         BIT #$10
         BEQ C20671     ;Branch if not Berserk
         LDA #$EE
         STA $01,S      ;Set attack to Battle
C20671:  PLA
         JSR C21DBF     ;choose a command based on attack #
         JSR C203E4     ;Determine command's "time to wait", recalculate
                        ;targets if there aren't any
         JMP C24ECB     ;queue chosen command and attack, in entity's
                        ;conventional queue


;Data - Time to wait after entering a command until character actually
;performs it (iow, how long they spend in their ready stance).  This
;value * 256 is compared to their $3AB4 counter.  I'm really not sure
;how this applies to enemies.

C2067B: db $10   ;Fight
      : db $10   ;Item
      : db $20   ;Magic
      : db $00   ;Morph
      : db $00   ;Revert
      : db $10   ;Steal
      : db $10   ;Capture
      : db $10   ;SwdTech
      : db $10   ;Throw
      : db $10   ;Tools
      : db $10   ;Blitz
      : db $10   ;Runic
      : db $20   ;Lore
      : db $10   ;Sketch
      : db $10   ;Control
      : db $10   ;Slot
      : db $10   ;Rage
      : db $10   ;Leap
      : db $10   ;Mimic
      : db $10   ;Dance
      : db $10   ;Row
      : db $10   ;Def.
      : db $E0   ;Jump
      : db $20   ;X-Magic
      : db $10   ;GP Rain
      : db $10   ;Summon
      : db $20   ;Health
      : db $20   ;Shock
      : db $10   ;Possess
      : db $10   ;MagiTek
      : db $00
      : db $00


;Do various responses to three mortal statuses

C2069B:  LDX #$12
C2069D:  LDA $3AA0,X
         LSR
         BCC C20700     ;if this entity not present, branch to next one
         REP #$20
         LDA $3018,X
         BIT $2F4E      ;is this entity marked to enter battlefield?
         SEP #$20
         BNE C20700     ;branch to next one if so
         JSR C207AD     ;Mark Control links to be deactivated if entity
                        ;possesses certain statuses
         LDA $3EE4,X
         BIT #$82       ;Check for Dead or Zombie Status
         BEQ C206BF     ;branch if none set
         STZ $3BF4,X
         STZ $3BF5,X    ;Set HP to 0
C206BF:  LDA $3EE4,X
         BIT #$C2       ;Check for Dead, Zombie, or Petrify status
         BEQ C206CF     ;branch if none set
         LDA $3019,X
         TSB $3A3A      ;add to bitfield of dead-ish monsters
         JSR C207C8     ;Clear Zinger, Love Token, and Charm bonds, and
                        ;clear applicable Quick variables
C206CF:  LDA $3EE4,X
         BPL C20700     ;Branch if alive
         CPX #$08
         BCS C206E4     ;branch if monster
         LDA $3ED8,X    ;Which character
         CMP #$0E
         BNE C206E4     ;Branch if not Banon
         LDA #$06
         STA $3A6E      ;Banon fell... "End of combat" method #6
C206E4:  JSR C20710     ;If Wound status set on mid-Jump entity, replace
                        ;it with Air Anchor effect so they can land first
         LDA $3EE4,X
         BIT #$02
         BEQ C206F1     ;branch if no Zombie Status
         JSR C20728     ;clear Wound status, and some other bit
C206F1:  LDA $3EE4,X
         BPL C20700     ;Branch if alive
         LDA $3EF9,X
         BIT #$04
         BEQ C20700     ;branch if no Life 3 status
         JSR C20799     ;prepare Life 3 revival
C20700:  DEX
         DEX
         BPL C2069D     ;iterate for all 10 entities
         LDX #$12
C20706:  JSR C20739     ;clean up Control if flagged
         DEX
         DEX
         BPL C20706     ;loop for every entity onscreen
         JMP C25D26     ;Copy Current and Max HP and MP, and statuses to
                        ;displayable variables


;If Wound status set on mid-Jump entity, replace it with Air Anchor effect so
; they can land first)

C20710:  REP #$20
         LDA $3018,X
         BIT $3F2C      ;are they in the middle of a Jump?
         SEP #$20
         BEQ C20727     ;Exit function if not
         JSR C20728     ;clear Wound for now, so they don't actually croak
                        ;in mid-air
         LDA $3205,X
         AND #$FB
         STA $3205,X    ;Set Air Anchor effect
C20727:  RTS


C20728:  LDA $3EE4,X
         AND #$7F       ;Clear death status
         STA $3EE4,X
         LDA $3204,X
         AND #$BF       ;clear bit 6
         STA $3204,X
         RTS


;Remove Control's influence from this entity and its Controller/Controllee if
; Control was flagged to be deactivated due to:
;  - C2/07AD found certain statuses on entity [doesn't matter whether
;    it's the Controller or it's the Controllee])
;  - this entity is a Controllee and C2/0C2D detected them sustaining physical
;    damage [healing or 0 damage will count, but a non-damaging attack -- i.e.
;    one with no damage numerals -- will not] )

C20739:  LDA $32B9,X   ;who's Controlling this entity?
         CMP #$FF
         BEQ C20748    ;branch if nobody controls them
         BPL C20748    ;branch if somebody controls them, and Control
                        ; wasn't flagged to be deactivated
         AND #$7F
         TAY           ;put Controller in Y  [Controllee is in X]
         JSR C2075B    ;clear Control info for the Controller and
                        ; Controllee [this entity]
C20748:  LDA $32B8,X   ;now see who this entity Controls
         CMP #$FF
         BEQ C2075A    ;branch if they control nobody
         BPL C2075A    ;branch if they control somebody, and Control
                        ; wasn't flagged to be deactivated
         AND #$7F
         PHX
         TXY           ;put Controller in Y
         TAX           ;put Controllee in X
         JSR C2075B    ;clear Control info for the Controller [this
                        ; entity] and Controllee
         PLX
C2075A:  RTS


;Clear Control-related data for a Controller, addressed by Y, and
; a Controllee, addressed by X)

C2075B:  LDA $3E4D,Y
         AND #$FE
         STA $3E4D,Y
         LDA $3EF9,Y
         AND #$EF
         STA $3EF9,Y    ;clear "Chant" status from Controller
         LDA #$FF
         STA $32B9,X    ;set to nobody controlling Controllee
         STA $32B8,Y    ;set to Controller controlling nobody
         LDA $3019,X
         TRB $2F54      ;cancel visual flipping of Controllee
         PHX
         JSR C20783
         TYX
         JSR C20783
         PLX
         RTS


C20783:  LDA #$40
         JSR C25BAB     ;set bit 6 of $3AA1,X
         LDA $3204,X
         ORA #$40
         STA $3204,X    ;set bit 6
         LDA #$7F
C20792:  AND $3AA0,X
         STA $3AA0,X    ;clear bit 7
         RTS


;Prepare Life 3 revival

C20799:  AND #$FB
         STA $3EF9,X    ;clear Life 3 status
         LDA $3019,X
         TRB $2F2F      ;remove from bitfield of remaining enemies?
         LDA #$30       ;Life spell ID
         STA $B8
         LDA #$26       ;command #$26
         JMP C24E91     ;queue it, in global Special Action queue


;Mark Control links to be deactivated if entity possesses certain statuses

C207AD:  PEA $B0C2      ;Sleep, Muddled, Berserk, Death, Petrify, Zombie
         PEA $0311      ;Rage, Freeze, Dance, Stop
         TXY
         JSR C25864
         BCS C207C7     ;Exit function if none of those statuses set
         ASL $32B8,X
         SEC
         ROR $32B8,X    ;flag "Who you control" link to be deactivated
         ASL $32B9,X
         SEC
         ROR $32B9,X    ;flag "Who controls you" link to be deactivated
C207C7:  RTS


;Clear Zinger, Love Token, and Charm bonds, and clear applicable Quick variables

C207C8:  CPX $33F9
         BNE C207F5     ;branch if you're not being Zingered
         PHX
         LDX $33F8      ;who's doing the Zingering
         LDA $3019,X
         STA $B9
         LDA #$04
         STA $B8
         LDX #$00
         LDA #$24
         JSR C24E91     ;queue Command F5 04, with an animation of 00,
                        ;in global Special Action queue
         LDA #$02
         STA $B8
         LDX #$08
         LDA #$24
         JSR C24E91     ;queue Command F5 02, with an animation of 08,
                        ;in global Special Action queue
         LDA #$FF
         STA $33F8      ;nobody's Zingering
         STA $33F9      ;nobody's being Zingered
         PLX
C207F5:  LDA $336C,X
         BMI C207FE     ;branch if you have no Love Token slave
         TAY
         JSR C2082D     ;Clear Love Token links between you and slave
C207FE:  LDA $336D,X
         BMI C2080A     ;branch if you're nobody's Love Token slave
         PHX
         TXY
         TAX
         JSR C2082D     ;Clear Love Token links between you and master
         PLX
C2080A:  LDA $3394,X
         BMI C20813     ;branch if you're not Charming anybody
         TAY
         JSR C20836     ;Clear Charm links between you and your Charmee
C20813:  LDA $3395,X
         BMI C2081F     ;branch if you're not Charmed by anybody
         PHX
         TXY
         TAX
         JSR C20836     ;Clear Charm links between you and Charmer
         PLX
C2081F:  CPX $3404      ;Compare to Quick's target byte
         BNE C2082C     ;Exit If this actor does not get extra turn due to Quick
         LDA #$FF
         STA $3404      ;Store #$FF (empty) to Quick's target byte
         STA $3402      ;Store #$FF (for none) to the number of turns due to Quick
C2082C:  RTS


;Clear Love Token effects

C2082D:  LDA #$FF
         STA $336C,X    ;Love Token master now has no slave
         STA $336D,Y    ;and Love Token slave now has no master
         RTS


;Clear Charm effects

C20836:  LDA #$FF
         STA $3394,X    ;Charmer is now Charming nobody
         STA $3395,Y    ;and Charmee is now being Charmed by nobody
         RTS


;Update a variety of things when the battle starts, when the enemy formation
; is switched, and at the end of each turn [after the turn's animation plays out])

C2083F:  LDX #$12
C20841:  LDA $3AA0,X
         LSR
         BCC C208BE     ;if this entity not present, branch to next one
         ASL $32E0,X
         LSR $32E0,X    ;clear Bit 7 of $32E0.  this prevents C2/4C5B
                        ;from triggering a counterattack for a once-attacked
                        ;entity turn after turn, while still preserving the
                        ;attacker in Bits 0-6.
         LDA $3EE4,X
         BMI C20859     ;Branch if dead
         LDA $3AA1,X
         BIT #$40
         BEQ C2085C     ;Branch if bit 6 of $3AA1,X is not set
C20859:  JSR C20977
C2085C:  LDA $3204,X
         BEQ C208AB
         LSR
         BCC C20867     ;branch if bit 0 of $3204,X isn't set, meaning entity
                        ;wasn't target of a Palidor summon this turn
         JSR C20B4A     ;if it was, do some more Palidor setup
C20867:  ASL $3204,X
         BCC C2086F     ;Branch if bit 7 of $3204,X is not set.
                        ;It is set for an entity when their Imp status is
                        ;toggled, the attack/spell costs them MP to cast, or
                        ;the attack itself affects their MP because they're a
                        ;target [or the caster, if it's a draining attack]
         JSR C25763     ;Update availability of entries on Esper, Magic,
                        ;and Lore menus
C2086F:  ASL $3204,X
         BCC C2087C     ;Branch if bit 6 of $3204,X is not set
         JSR C20A0F     ;Remove entity from Wait Queue, remove all records from
                        ;their conventional linked list queue, and default some
                        ;poses if character
         LDA #$80
         JSR C25BAB     ;set bit 7 of $3AA1,X
C2087C:  ASL $3204,X
         BCC C20884     ;Branch if bit 5 of $3204,X is not set.
                        ;It is set for an entity upon Condemned status
                        ;being set.
         JSR C209B4     ;Assign a starting value to Condemned counter
C20884:  ASL $3204,X
         BCC C2088C     ;Branch if bit 4 of $3204,X is not set.
                        ;It is set for an entity when Condemned expires or
                        ;is otherwise cleared.
         JSR C209CE     ;Zero the Condemned counter
C2088C:  ASL $3204,X
         BCC C20898     ;Branch if bit 3 of $3204,X is not set.
                        ;It is set for an entity when Mute or Imp status
                        ;is toggled.
         CPX #$08
         BCS C20898     ;Branch if not a character
         JSR C2527D     ;Update availability of commands on character's
                        ;main menu
C20898:  ASL $3204,X
         BCC C208A0     ;Branch if bit 2 of $3204,X is not set.
                        ;It is set for an entity when Haste or Slow is toggled,
                        ;and a couple other cases I'm not sure of.
         JSR C209D2     ;Recalculate the amount by which to increase the ATB
                        ;gauge.  Affects various other timers, too.
C208A0:  ASL $3204,X
         BCC C208A8     ;Branch if bit 1 of $3204,X is not set.
                        ;It is set for an entity when Morph status is toggled.
         JSR C20AA8     ;switch command on main menu between Morph and Revert,
                        ;and adjust Morph-related variables like timers
C208A8:  ASL $3204,X    ;clear former Bit 0, just like we've already cleared
                        ;all the other bits with our shifting.
C208AB:  JSR C2091F
         JSR C208C6
         LDA $3AA0,X
         BIT #$50
         BEQ C208BB
         JSR C20A41     ;clear Defending flag
C208BB:  JSR C20A4A     ;Prepare equipment spell activations on low HP
C208BE:  DEX
         DEX
         BMI C208C5
         JMP C20841     ;iterate for all 10 entities
C208C5:  RTS


C208C6:  LDA #$50
         JSR C211B4     ;set Bits 4 and 6 of $3AA0,X
         LDA $3404
         BMI C208D5     ;branch if no targets under the influence of Quick
         CPX $3404      ;Is this target under the influence of Quick?
         BNE C208C5     ;branch if not
C208D5:  LDA $3EE4,X
         BIT #$C0
         BNE C208C5     ;Exit if dead or Petrify
         LDA $3EF8,X
         BIT #$10
         BNE C208C5     ;Exit if stop
         LDA #$EF
         JSR C20792     ;clear Bit 4 of $3AA0,X
         LDA $32B9,X
         BPL C208C5     ;Exit if you are controlled
         LDA $3EE5,X
         BMI C208C5     ;Exit if asleep
         LDA $3EF9,X
         BIT #$02
         BNE C208C5     ;Exit if Freeze
         LDA $3359,X
         BPL C208C5     ;Exit if seized
         LDA #$BF
         JSR C20792     ;clear Bit 6 of $3AA0,X
         LDA $3AA1,X
         BPL C208C5     ;Exit if bit 7 of $3AA1 is not set
         AND #$7F       ;Clear bit 7
         STA $3AA1,X
         LDA $32CC,X    ;get entry point to entity's conventional linked
                        ;list queue
         INC
         BEQ C208C5     ;Exit if null, as list is empty
         LDA $3AA1,X
         LSR
         BCC C2091C     ;Branch if bit 0 of $3AA1 is not set
         JMP C24E77     ;put entity in action queue
C2091C:  JMP C24E66     ;put entity in wait queue


C2091F:  CPX #$08
         BCS C208C5     ;exit if monster
         LDA $3ED8,X    ;Which character it is
         CMP #$0D
         BEQ C208C5     ;Exit if Umaro
         LDA $3255,X    ;top byte of offset of main script
         BPL C208C5     ;branch if character has a main script
         LDA $3A97
         BNE C208C5     ;exit if in the Colosseum
         LDA #$02
         STA $EE
         CPX $3404      ;Is this target under the influence of Quick?
         BNE C20941     ;branch if not
         LDA #$88
         TSB $EE
C20941:  LDA $EE
         JSR C211B4
         LDA $3018,X
         BIT $2F4C      ;is entity marked to leave battlefield?
         BNE C20986     ;branch if so
         LDA $3359,X
         AND $3395,X
         BPL C20986     ;branch if Seized or Charmed
         PEA $B0C2      ;Sleep, Muddled, Berserk, Death, Petrify, Zombie
         PEA $2101      ;Dance, Hide, Rage
         TXY
         JSR C25864
         BCC C20986     ;Branch if any set
         LDA $3AA0,X
         BPL C209CD
         LDA $32CC,X    ;get entry point to entity's conventional linked
                        ;list queue
         BPL C209CD     ;exit if non-null, i.e. list has a record
         LDA $3AA0,X
         ORA #$08
         STA $3AA0,X    ;turn on bit 3
         JMP C211EF


C20977:  REP #$20
         LDA #$BFD3
         JSR C20792
         SEP #$20
         LDA #$01
         STA $3219,X
C20986:  LDA #$F9
         XBA
         LDA $3EF9,X
         BIT #$20
         BNE C209A3     ;Branch if Hide status
         LDA $3018,X
         BIT $2F4C      ;is entity marked to leave battlefield?
         BNE C209A3     ;branch if so
         LDA $3AA0,X
         BPL C209A3     ;Branch if bit 7 of $3AA0 is not set
         LDA #$79
         XBA
         JSR C24E66     ;put entity in wait queue
C209A3:  XBA
         JSR C20792
         CPX #$08
         BCS C209CD     ;Exit function if monster
         TXA
         LSR
         STA $10
         LDA #$03
         JMP C26411


;Assign a starting value to Condemned counter
;Counter = 81 - (Attacker Level + [0..(Attacker Level - 1)]), with a minimum of 20 .
; For purposes of a starting status, Attacker Level is treated as 20.)

C209B4:  LDA $11AF      ;Attacker Level
         JSR C24B65     ;random: 0 to Level - 1
         CLC
         ADC $11AF      ;Add to level
         STA $EE
         SEC
         LDA #$3C
         SBC $EE        ;Subtract from 60
         BCS C209C8
         TDC            ;Set to 0 if less than 0
C209C8:  ADC #$14       ;Add 21.  if it was less than 0, add 20 instead,
                        ;giving it a starting value of 20.
         STA $3B05,X    ;set Condemned counter
                        ;note that this counter is "one off" from the
                        ;actual numerals you'll see onscreen:
                        ;   00 value = numerals disabled
                        ;   01 value = numerals at "00"
                        ;   02 value = numerals at "01"
                        ;   03 value = numerals at "02" , etc.
C209CD:  RTS


;Zero and Disable Condemned counter

C209CE:  STZ $3B05,X    ;Condemned counter = 0, disabled
         RTS


;Battle Time Counter function
;Recalculate the ATB multiplier, which affects: the Condemned counter, invisible
; timers for auto-expiring statuses, and the frequency of damage/healing from
; statuses like Regen and Poison.
; Also recalculate the amount by which to increase the ATB gauge, and the related
; amount for the "wait timer" [which determines how long a character is in their
; ready stance].)

C209D2:  PHP
         LDY #$20      ;ATB multiplier = 32 if slowed
         LDA $3EF8,X
         BIT #$04
         BNE C209E4    ;Branch if Slow
         LDY #$40      ;ATB multiplier = 64 normally
         BIT #$08
         BEQ C209E4    ;Branch if not Haste
         LDY #$54      ;ATB multiplier = 84 if hasted
C209E4:  TYA
         STA $3ADD,X   ;save the ATB multiplier
         TYA           ;this instruction seems frivolous
         PHA            ;Put on stack
         CLC
         LSR
         ADC $01,S
         STA $01,S     ;ATB multiplier *= 1.5
         LDA $3B19,X   ;Speed
         ADC #$14
         XBA           ;Speed + 20 in top byte of Accumulator
         CPX #$08
         BCC C20A00    ;branch if not an enemy
         LDA $3A90     ;= 255 - (Battle Speed setting * 24)
                        ;remember that what you see on the Config menu is
                        ;Battle Speed + 1
         JSR C24781    ;A = (speed + 20) * $3A90
C20A00:  PLA           ;bottom byte of A is now Slow/Normal/Haste Constant
         JSR C24781    ;Let C be the Slow/Normal/Haste constant, equal to
                        ;48, 96, or 126, respectively.
                        ;for characters:
                        ;A = (Speed + 20 * C
                        ;for enemies:
                        ;A = ( ((Speed + 20) * $3A90) DIV 256) * C
         REP #$20
         LSR
         LSR
         LSR
         LSR           ;A = A / 16
         STA $3AC8,X   ;Save as amount by which to increase ATB timer.
         PLP
         RTS


;Remove entity from Wait Queue, remove all records from their conventional linked list
; queue, do ????, and default some poses if character)

C20A0F:  JSR C20301     ;Remove current first record from entity's
                        ;conventional linked list queue, and update their
                        ;entry point accordingly
         LDA $32CC,X
         BPL C20A0F     ;repeat as long as their queue has a valid entry
                        ;point [i.e. it's not empty]
         LDY $3A64      ;get position of next Wait Queue slot to read
C20A1A:  TXA
         CMP $3720,Y    ;does queue entry match our current entity?
         BNE C20A25     ;if not, branch and move to next entry
         LDA #$FF
         STA $3720,Y    ;if there was a match, null out this Wait Queue
                        ;entry
C20A25:  INY            ;move to next entry
         CPY $3A65
         BCC C20A1A     ;keep looping until position matches next available
                        ;queue slot -- i.e., we've checked through the end of
                        ;the queue
         LDA $3219,X
         BNE C20A38     ;branch if top byte of ATB counter is not 0
         DEC $3219,X    ;make it 255
         LDA #$D3
         JSR C20792     ;clear Bits 2, 3, and 5 of $3AA0,X
C20A38:  CPX #$08
         BCS C20A49     ;exit if monster
         LDA #$2C
         JMP C24E91     ;queue command to buffer Battle Dynamics Command 0Eh,
                        ;graphics related [defaulting character poses?], in
                        ;global Special Action queue.  see Function C2/51A8
                        ;for more info.


;Clear Defending flag

C20A41:  LDA #$FD
C20A43:  AND $3AA1,X
         STA $3AA1,X    ;clear Defending flag.  or other bit(s if
                        ;entered via C2/0A43.
C20A49:  RTS


;Prepare equipment spell activations on low HP

C20A4A:  LDA $3AA0,X
         BIT #$10       ;is entity Wounded, Petrified, or Stopped, or is
                        ;somebody else under the influence of Quick?
         BNE C20A90     ;Exit function if any are true
         LDA #$02
         BIT $3EE5,X
         BEQ C20A90     ;Branch if not Near Fatal
         BIT $3205,X    ;is bit 1 set?
         BEQ C20A90     ;exit if not, meaning we've already activated
                        ;a spell on low HP this battle
         EOR $3205,X
         STA $3205,X    ;toggle off bit 1
         LDA $3C59,X
         LSR
         BCC C20A74     ;Branch if not Shell when low HP
         PHA            ;Put on stack
         LDA #$25
         STA $B8        ;Shell spell ID
         LDA #$26
         JSR C24E91     ;queue Command #$26, in global Special Action queue
         PLA
C20A74:  LSR
         BCC C20A82     ;branch if not Safe when low HP
         PHA            ;Put on stack
         LDA #$1C
         STA $B8        ;Safe spell ID
         LDA #$26
         JSR C24E91     ;queue Command #$26, in global Special Action queue
         PLA
C20A82:  LSR
         BCC C20A90     ;branch if not Reflect when low HP [no item
                        ;in game has this feature, but it's possible]
         PHA            ;Put on stack
         LDA #$24
         STA $B8        ;Rflect spell ID
         LDA #$26
         JSR C24E91     ;queue Command #$26, in global Special Action queue
         PLA
C20A90:  RTS


C20A91:  LDX #$06
C20A93:  LDA $3018,X
         BIT $3A74      ;is this character among alive and present ones?
         BEQ C20AA3     ;skip to next one if not
         BIT $3F2C      ;are they a Jumper?
         BNE C20AA3     ;skip to next one if so
         JSR C20A0F     ;Remove entity from Wait Queue, remove all records
                        ;from their conventional linked list queue, and
                        ;default some poses if character
C20AA3:  DEX
         DEX
         BPL C20A93     ;loop for all 4 characters
         RTS


;Switch command on main menu between Morph and Revert, and adjust
; Morph-related variables like timers)

C20AA8:  LDA $B1
         LSR            ;is it an unconventional turn?  in this context,
                        ;that's auto-Revert.
         BCS C20AB7     ;branch if so
         LDA $3219,X    ;Load top byte of this target's ATB counter
         BNE C20AB7     ;branch if not zero
         LDA #$88
         JSR C211B4
C20AB7:  PHX
         LDA $3EF9,X
         EOR #$08       ;get opposite of Morph status
         LSR
         LSR
         LSR
         LSR
         PHP            ;save Carry flag, which is opposite of
                        ;"currently Morphed"
         TDC
         ADC #$03
         STA $EE        ;$EE = 3 or 4, depending on carry flag
         TXA
         XBA
         LDA #$06
         JSR C24781
         TAX
         LDY #$04
C20AD1:  LDA $202E,X    ;get contents of menu slot
         CMP $EE
         BNE C20ADD     ;if Morphed and menu item isn't Morph(3, branch  -OR-
                        ;if not Morphed and menu item isn't Revert(4), branch
         EOR #$07
         STA $202E,X    ;toggle menu item between Morph(3) and Revert(4)
C20ADD:  INX
         INX
         INX
         DEY
         BNE C20AD1     ;loop for all 4 menu items
         PLP
         PLX
         BCC C20B01     ;Branch if currently Morphed
         PHP
         JSR C20B36     ;Establish new value for Morph supply based on its
                        ;previous value and the current Morph timer
         LDA #$FF
         STA $3EE2      ;Store null as Morphed character
         STZ $3B04,X    ;Set the Morph gauge for this entity to 0
         CPX #$08       ;Compare target number to 8
         BCS C20AFA     ;Branch if it's greater (not a character)
         JSR C2527D     ;Update availability of commands on character's
                        ;main menu - grey out or enable
C20AFA:  REP #$20
         STZ $3F30      ;morph timer = 0
         PLP
         RTS


;If no one is already Morphed: designate character in X as Morphed, start Morph
; timer at 65535, and establish amount to decrement morph time counter based on
; Morph supply)

C20B01:  PHX
         PHP
         LDA $3EE2      ;Which target is Morphed
         BPL C20B33     ;Exit function if someone is already Morphed
         LDA $3EBB
         LSR
         LSR
         ROR
         BCS C20B33     ;Exit function if bit 2 of $3EBB is set..
                        ;Set for just Phunbaba battle #4 [i.e. Terra's
                        ;second Phunbaba encounter]
         ASL            ;Put Bit 1 into Carry
         STX $3EE2      ;store target in X as Morphed character
         TDC
         REP #$20       ;Set 16-bit Accumulator
         DEC
         STA $3F30      ;Morph timer = 65535
         LDX $1CF6      ;Morph supply
         JSR C24792     ;65535 / Morph supply
         BCC C20B24     ;Branch if bit 1 of $3EBB not set.
                        ;This bit is set in Terra's 2nd Phunbaba battle
                        ;[i.e. Phunbaba #4], and lasts afterward.  So
                        ;Terra gains some resolve here. ^__^
         LSR
C20B24:  LSR
         LSR
         LSR            ;A = (65535 / Morph supply / 8  [pre-Phunbaba]
                        ;A = (65535 / Morph supply) / 16  [post-Phunbaba]
         CMP #$0800
         BCC C20B2F
         LDA #$07FF     ;this will cap amount to decrement morph time
                        ;counter at 2048
C20B2F:  INC
         STA $3F32      ;Amount to decrement morph time counter
C20B33:  PLP
         PLX
         RTS


;Establish new value for Morph supply based on its previous value and
; the current Morph timer)

C20B36:  LDA $3EE2      ;Which target is Morphed
         BMI C20B49     ;Exit if no one is Morphed
         LDA $1CF6
         XBA
         LDA $3F31
         JSR C24781     ;16-bit A = morph supply * (morph timer DIV 256)
         XBA
         STA $1CF6      ;morph supply =
                        ;(morph supply * (morph timer DIV 256)) DIV 256
C20B49:  RTS


;Called after turn when Palidor used

C20B4A:  REP #$20       ;Set 16-bit Accumulator
         LDA $3018,X
         TSB $3F2C      ;flag entity as Jumping
         SEP #$20       ;Set 8-bit Accumulator
         LDA $3AA0,X
         AND #$9B
         ORA #$08
         STA $3AA0,X
         LDY $3A66      ;get current action queue position
C20B61:  TXA
         CMP $3820,Y    ;does queue entry match our current entity?
         BNE C20B6C     ;if not, branch and move to next entry
         LDA #$FF
         STA $3820,Y    ;if there was a match, null out this action queue
                        ;entry
C20B6C:  INY            ;move to next entry
         CPY $3A67
         BCC C20B61     ;keep looping until position matches next available
                        ;queue slot -- i.e., we've checked through the end of
                        ;the queue
         LDA $3205,X
         AND #$7F
         STA $3205,X    ;indicate entity has not taken a conventional turn
                        ;[including landing one] since boarding Palidor
         STZ $3AB5,X    ;zero top byte of Wait Timer
         LDA #$E0
         STA $322C,X    ;save delay between inputting command and performing it.
                        ;iow, how long you spend in the "ready stance."  E0h
                        ;is the same delay as the Jump command, and its ready
                        ;stance constitutes the character being airborne.
         RTS


;Modify Damage, Heal Undead, and Elemental modification

C20B83:  PHP
         SEP #$20
         LDA $11A6      ;Battle Power
         BNE C20B8E     ;Branch if not 0
         JMP C20C2B     ;Exit function if 0
C20B8E:  LDA $11A4      ;Special Byte 2
         BMI C20B98     ;Branch if power = factor of HP
         JSR C20C9E     ;Damage modification
         BRA C20B9B
C20B98:  JSR C20D87     ;Figure HP-based or MP-based damage
C20B9B:  STZ $F2
         LDA $3EE4,Y    ;Status byte 1 of target
         ASL
         BMI C20BFA     ;Branch if target is Petrify, damage = 0

         LDA $11A4
         STA $F2        ;Store special byte 2 in $F2.  what we're looking
                        ;at is Bit 0, the Heal flag.
         LDA $11A2
         BIT #$08
         BEQ C20BD3     ;Branch if not Invert Damage on Undead
         LDA $3C95,Y
         BPL C20BBF     ;Branch if not undead
         LDA $11AA
         BIT #$82       ;Check if dead or zombie attack
         BNE C20C2B     ;Exit if ^
         STZ $F2        ;Clear heal flag
         BRA C20BC6
C20BBF:  LDA $3EE4,Y
         BIT #$02       ;Check for Zombie status
         BEQ C20BD3     ;Branch if not zombie
C20BC6:  LDA $11A4
         BIT #$02
         BEQ C20BD3     ;Branch if not redirection
         LDA $F2
         EOR #$01
         STA $F2        ;Toggle heal flag

C20BD3:  LDA $11A1
         BEQ C20C1E     ;Branch if non-elemental
         LDA $3EC8      ;Forcefield nullified elements
         EOR #$FF
         AND $11A1
         BEQ C20BFA     ;Set damage to 0 if element nullified
         LDA $3BCC,Y    ;Absorbed elements
         BIT $11A1
         BEQ C20BF2     ;branch if none are used in attack
         LDA $F2
         EOR #$01
         STA $F2        ;toggle healing flag
         BRA C20C1E
C20BF2:  LDA $3BCD,Y    ;Nullified elements
         BIT $11A1
         BEQ C20C00     ;branch if none are used in attack
C20BFA:  STZ $F0
         STZ $F1        ;Set damage to 0
         BRA C20C1E
C20C00:  LDA $3BE1,Y    ;Elements cut in half
         BIT $11A1
         BEQ C20C0E     ;branch if none are used in attack
         LSR $F1
         ROR $F0        ;Cut damage in half
         BRA C20C1E
C20C0E:  LDA $3BE0,Y    ;Weak elements
         BIT $11A1
         BEQ C20C1E     ;branch if none are used in attack
         LDA $F1
         BMI C20C1E     ;Don't double damage if over 32768
         ASL $F0
         ROL $F1        ;Double damage
C20C1E:  LDA $11A9      ;get attack special effect
         CMP #$04
         BNE C20C28     ;Branch if not Atma Weapon
         JSR C20E39     ;Atma Weapon damage modification
C20C28:  JSR C20C2D     ;see description 3 lines below
C20C2B:  PLP
         RTS


;For physical attacks, handle random Zombie-inflicted ailments, and set up removal
; of Sleep, Muddled, and Control.  Handle drainage.  Enforce 9999 damage cap.)

C20C2D:  LDA $11A2
         LSR
         BCC C20C5D     ;Branch if not physical damage
         LDA $3A82
         AND $3A83
         BPL C20C5D     ;Branch if blocked by Golem or dog
         LDA $3EE4,X
         BIT #$02       ;Check for Zombie Status on attacker
         BEQ C20C45     ;Branch if not zombie
         JSR C20E21     ;Poison / Dark status for zombies
C20C45:  LDA $11AB      ;Status set by attack 2
         EOR #$A0       ;Sleep & Muddled
         AND #$A0
         AND $3EE5,Y    ;Status byte 2
         ORA $3DFD,Y
         STA $3DFD,Y    ;mark Sleep & Muddled to be cleared from target,
                        ;provided it already has the statuses, and
                        ;the attack itself isn't trying to inflict or remove
                        ;them
         LDA $32B9,Y
         ORA #$80
         STA $32B9,Y    ;Flag target to be released from Control at end of
                        ;turn
C20C5D:  LDA $11A4
         BIT #$02
         BEQ C20C75     ;Branch if not redirection
         JSR C20DED     ;Cap damage/healing based on max HP/MP of drainer,
                        ;and remaining HP/MP of drainee
         PHX            ;save attacker index
         PHY            ;save target index
         PHY
         TXY            ;put old attacker index into target index
         PLX            ;put old target index into attacker index
         JSR C2362F     ;save target as attacker's attacker in a counterattack
                        ;variable [provided attacker doesn't yet have another
                        ;attacker].  reciprocity and all, man.
                        ;however, the Carry Flag state passed to this function
                        ;seems to be quite arbitrary, particularly if this
                        ;is a physical attack [usually being set, but sometimes
                        ;not if attacker is a Zombie].  it'll never be set for
                        ;magical attacks, which seems suspect as well.
         SEC            ;enforce 9999 cap for redirection for attacker
         JSR C20C76
         PLY            ;restore target index
         PLX            ;restore attacker index
C20C75:  CLC            ;now enforce 9999 cap for target
C20C76:  PHY
         PHP
         ROL
         EOR $F2        ;get Carry XOR attack's heal bit
         LSR
         BCC C20C82     ;branch if:
                        ; - we're checking attacker and attack "reverse" drains
                        ;   [e.g. because target is undead or absorbs element]
                        ; - we're checking target and attack damages [includes
                        ;   draining]
         TYA
         ADC #$13
         TAY            ;point to Healing instead of Damage
C20C82:  REP #$20
         LDA $33D0,Y    ;Damage Taken / Healing Done
         INC
         BEQ C20C8B     ;if no [i.e. FFFFh] damage, treat as zero
         DEC            ;otherwise, keep as-is
C20C8B:  CLC
         ADC $F0        ;add Damage/Healing so far to $F0, which is the lowest of:
                        ; - attack damage
                        ; - HP of target [or attacker if reverse drain]
                        ; - Max HP - HP of attacker [or target if reverse drain]
         BCS C20C95     ;if total Damage/Healing to this target overflowed,
                        ;branch and set it to 9999
         CMP #$2710     ;If over 9999
         BCC C20C98
C20C95:  LDA #$270F     ;Truncate Damage to 9999
C20C98:  STA $33D0,Y    ;Damage Taken / Healing Done
         PLP
         PLY
         RTS


;Damage modification (Randomness, Row, Self Damage, and more

C20C9E:  PHP
         REP #$20
         LDA $11B0      ;Maximum Damage
         STA $F0
         SEP #$20       ;Set 8-bit Accumulator
         LDA $3414
         BNE C20CB0
         JMP C20D3B     ;Exit if Skip damage modification
C20CB0:  JSR C24B5A     ;Random number 0 to 255
         ORA #$E0       ;Set bits 7,6,5; bits 0,1,2,3,4 are random
         STA $E8        ;Random number [224..255]
         JSR C20D3D     ;Damage randomness
         CLC
         LDA $11A3
         BMI C20CC4     ;Branch if Concern MP
         LDA $11A2
         LSR            ;isolate magical vs. physical property
C20CC4:  LDA $11A2
         BIT #$20
         BNE C20D22     ;Branch if ignores defense
         PHP            ;save Carry flag, which equals
                        ;(physical attack) AND NOT(Concern MP)
         LDA $3BB9,Y    ;Magic Defense
         BCC C20CD4     ;Branch if concern MP or Magical damage
         LDA $3BB8,Y    ;Defense
C20CD4:  INC
         BEQ C20CE7     ;Branch if = 255
         XBA
         LDA $3A82
         AND $3A83
         BMI C20CE3     ;If Blocked by Golem or Dog, defense = 192
         LDA #$C1
         XBA
C20CE3:  XBA
         DEC
         EOR #$FF
C20CE7:  STA $E8        ;= 255 - Defense
         JSR C20D3D     ;Multiply damage by (255 - Defense / 256 ,
                        ;then add 1
         LDA $01,S
         LSR
         LDA $3EF8,Y    ;Status byte 3
         BCS C20CF5     ;Branch if physical attack without Concerns MP
         ASL
C20CF5:  ASL
         BPL C20CFF     ;Branch if no Safe / Shell on target
         LDA #$AA
         STA $E8
         JSR C20D3D     ;Multiply damage by 170 / 256 , then add 1
C20CFF:  PLP
         BCC C20D17     ;Skip row check if magical attack or Concern MP
         LDA $3AA1,Y
         BIT #$02
         BEQ C20D0D     ;Branch if target not defending
         LSR $F1
         ROR $F0        ;Cut damage in half
C20D0D:  BIT #$20       ;Check row
         BEQ C20D22     ;Branch if target in front row
         LSR $F1
         ROR $F0        ;Cut damage in half
         BRA C20D22     ;Skip morph if physical attack
C20D17:  LDA $3EF9,Y
         BIT #$08
         BEQ C20D22     ;Branch if target not morphed
         LSR $F1
         ROR $F0        ;Cut damage in half
C20D22:  REP #$20       ;Set 16-bit Accumulator
         LDA $11A4
         LSR
         BCS C20D34     ;Branch if heal; heal skips self damage theory
         CPY #$08
         BCS C20D34     ;Branch if target is a monster
         CPX #$08
         BCS C20D34     ;Branch if attacker is monster
         LSR $F0        ;Cut damage in half if party attacks party
C20D34:  LDA $F0
         JSR C2370B     ;Increment damage using $BC
         STA $F0
C20D3B:  PLP
         RTS


;Multiplies damage by $E8 / 256 and adds 1
;Used by damage randomness, etc.)

C20D3D:  PHP
         REP #$20       ;Set 16-bit Accumulator
         LDA $F0        ;Load damage
         JSR C247B7     ;Multiply by randomness byte
         INC            ;Add 1 to damage
         STA $F0
         PLP
         RTS


;Atlas Armlet / Earring Function

C20D4A:  PHP
         LDA $11A4      ;Special Byte 2
         LSR
         BCS C20D85     ;Exits function if attack heals
         LDA $11A3
         BMI C20D5A     ;Branch if concern MP
         LDA $11A2      ;Special Byte 1
         LSR            ;Check for physical / magic
C20D5A:  REP #$20       ;Set 16-bit Accumulator
         LDA $11B0      ;Max Damage
         STA $EE        ;Stores damage at $EE
         LDA $3C44,X    ;Relic effects
         SEP #$20       ;Set 8-bit Accumulator
         BCS C20D6E     ;Branch if physical damage unless concerns mp
         BIT #$02
         BNE C20D75     ;Branch double earrings - add 50% damage
         XBA
         LSR
C20D6E:  LSR
         BCC C20D85     ;Exits function if not Atlas Armlet / Earring
         LSR $EF        ;Halves damage
         ROR $EE
C20D75:  REP #$20       ;Set 16-bit Accumulator
         LDA $EE
         LSR            ;Halves damage
         CLC
         ADC $11B0      ;Adds to damage
         BCC C20D82
         TDC
         DEC
C20D82:  STA $11B0      ;Stores result back in damage
C20D85:  PLP
         RTS


;Figure damage if based on HP or MP

C20D87:  PHX
         PHY
         PHP
         REP #$20       ;Set 16-bit Accumulator
         LDA $33D0,Y    ;Damage already Taken.  normally none [FFFFh], but
                        ;exists for Launcher and fictional reflected spells.
         INC
         BEQ C20D93     ;If damage taken is none, treat as 0
         DEC
C20D93:  STA $EE        ;save it in temp variable
         SEP #$20       ;Set 8-bit Accumulator
         JSR C20DDD     ;Use MP if concerns MP
         LDA $11A6      ;Spell Power
         STA $E8
         LDA $B5
         CMP #$01
         BEQ C20DAB     ;if command = item, then always use Max HP or MP
         LDA $11A2
         LSR
         LSR
         LSR
C20DAB:  REP #$20       ;Set 16-bit Accumulator
         BCS C20DBA     ;If hit only the (dead XOR undead, then use Max HP
                        ;or MP
         SEC            ;Else use current HP or MP
         LDA $3BF4,Y    ;Current HP or MP
         SBC $EE        ;Subtract damage already taken this strike.  relevant
                        ;for Launcher and fictional reflected spells.
         BCS C20DBD
         TDC            ;if that more than depletes HP or MP, then use 0
         BRA C20DBD
C20DBA:  LDA $3C1C,Y    ;Max HP or MP
C20DBD:  JSR C20DCB     ;A = (Spell Power * HP or MP) / 16
         PHA            ;Put on stack
         PLA            ;set Zero and Negative flags based on A
                        ;ASL/ROR would be a little faster...
         BNE C20DC5
         INC            ;if damage is 0, set to 1
C20DC5:  STA $F0
         PLP
         PLY
         PLX
         RTS


;Spell Power * HP / 16
;if entered at C2/0DD1, does a more general division of a 32-bit value
;[though most callers assume it's 24-bit] by 2^(A+1).

C20DCB:  JSR C247B7     ;24-bit $E8 = 8-bit $E8 * 16-bit A
         LDA #$0003     ;will be 4 iterations to loop
C20DD1:  PHX            ;but some callers enter here
         TAX
         LDA $E8        ;A = bottom two bytes of Spell Power * HP
C20DD5:  LSR $EA        ;Cut top two bytes in half
         ROR            ;do same for bottom two
         DEX
         BPL C20DD5     ;Do it N+1 iterations, where N is the value
                        ;of X after C2/0DD2
         PLX
         RTS


;Make damage affect MP if concerns MP

C20DDD:  LDA $11A3
         BPL C20DEC     ;Branch if not Concern MP
         TYA
         CLC
         ADC #$14
         TAY
         TXA
         CLC
         ADC #$14
         TAX
C20DEC:  RTS


;Set $F0 to lowest of ($F0, HP/MP of drainee, Max HP/MP - HP/MP of drainer
;If bit 0 of $F2 is set, switch so attacker is drainee and target is drainer
;If bit 7 of $B2 is not set, compare only $F0 and HP/MP of drainee

C20DED:  PHX
         PHY
         PHP
         JSR C20DDD     ;Set to use MP if Concern MP
         LDA $3414
         BPL C20E1D     ;Exit if Skip damage modification
         REP #$20
         LDA $F2
         LSR
         BCC C20E02     ;branch if not healing target
         PHX
         TYX
         PLY            ;Switch target and attacker
C20E02:  LDA $3BF4,Y    ;Current HP or MP of drainee
         CMP $F0
         BCS C20E0B     ;branch if HP or MP >= $F0
         STA $F0
C20E0B:  LDA $B1
         BPL C20E1D     ;Branch if top bit of $B2 is clear; it's
                        ;cleared by the Drain while Seized used by
                        ;Tentacles
         TXY            ;Put drainer in Y.  Why bother?  Just use
                        ;X below instead.
         SEC
         LDA $3C1C,Y    ;Max HP or MP of drainer
         SBC $3BF4,Y    ;Current HP or MP of drainer
         CMP $F0
         BCS C20E1D     ;branch if difference >= $F0
         STA $F0
C20E1D:  PLP
         PLY
         PLX
C20E20:  RTS


;Called if Zombie
;1 in 16 chance inflict Dark    -OR-
;1 in 16 chance inflict Poison

C20E21:  JSR C24B5A     ;Random number 0 to 255
         CMP #$10
         BCS C20E2C
         LDA #$04       ;will mark Poison status to be set
         BRA C20E32
C20E2C:  CMP #$20
         BCS C20E20     ;Exit function
         LDA #$01       ;will mark Dark status to be set
C20E32:  ORA $3DD4,Y    ;Status to set byte 1
         STA $3DD4,Y
         RTS


;Atma Weapon damage modification

C20E39:  PHP
         PHX
         PHY
         TXY            ;Y points to attacker
         LDA $3BF5,Y    ;HP / 256
         INC
         XBA
         LDA $3B18,Y    ;Level
         JSR C24781     ;Level * ((HP / 256) + 1)
         LDX $3C1D,Y    ;Max HP / 256
         INX
         JSR C24792     ;(Level * ((HP / 256) + 1)) / ((Max HP / 256) + 1)
         STA $E8        ;save modifier quotient
         REP #$20
         LDA $F0        ;load damage so far
         JSR C247B7     ;24-bit $E8 = modifier in 8-bit $E8 * 16-bit damage
         LDA #$0005
         JSR C20DD1     ;Divide 24-bit Damage in $E8 by 64. [note that
                        ;calculation operates on 4 bytes]
         INC            ;+1
         STA $F0        ;save final damage
                        ;note that we're assuming damage fit into 16 bits,
                        ;which is true outside of hacks that give Atma
                        ;Weapon 2-hand or elemental properties.
         CMP #$01F5
         BCC C20E73     ;branch if < 501
         LDX #$5B       ;put index for alternate, bigger weapon
                        ;graphic, into X
         CMP #$03E9
         BCC C20E6E     ;branch if < 1001
         INX            ;make graphic bigger yet
C20E6E:  STX $B7        ;save graphic index
         JSR C235BB     ;Update a previous entry in ($76 animation buffer
                        ;with data in $B4 - $B7)  (Changes Atma Weapon length
C20E73:  PLY
         PLX
         PLP
         RTS


;Equipment Check Function (Called from other bank)

C20E77:  PHX            ;Save X
         PHY
         PHB
         PHP
         SEP #$30       ;Set 8-bit Accumulator, X and Y
         PHA            ;Put on stack
         AND #$0F
         LDA #$7E
         PHA            ;Put on stack
         PLB            ;set Data Bank register to 7E
         PLA
         LDX #$3E
C20E87:  STZ $11A0,X
         DEX
         BPL C20E87     ;zero out $11A0 - $11DE
         INC
         XBA
         LDA #$25       ;37 bytes of info per character, see Tashibana's
                        ;ff6zst.txt for details.  this block is documented as
                        ;starting at $1600, but the INC above means X is boosted
                        ;by 37 -- perhaps to avoid a negative X later -- so the
                        ;base addy is 15DB
         JSR C24781
         REP #$10       ;Set 16-bit X and Y
         TAX
         LDA $15DB,X    ;get sprite, which doubles as character index??
         XBA
         LDA #$16       ;22 startup bytes per character
         JSR C24781
         PHX
         TAX            ;X indexes character startup block
         LDA $ED7CAA,X  ;get character Battle Power
         STA $11AC
         STA $11AD      ;store it in both hands
         REP #$20       ;Set 16-bit Accumulator
         LDA $ED7CAB,X  ;character Defense and Magic Defense
         STA $11BA
         LDA $ED7CAD,X  ;character Evade and MBlock
         SEP #$20       ;Set 8-bit Accumulator
         STA $11A8      ;save Evade here
         XBA
         STA $11AA      ;save MBlock here
         LDA $ED7CB5,X  ;character start level info
         AND #$03
         EOR #$03
         INC
         INC
         STA $11DC      ;invert and add 2.  this gives you
                        ;5 - (bottom two bits of Level byte ,
                        ;the amount to add to the character's
                        ;"Run Success" variable.
         PLX            ;X indexes into character info block again
         LDY #$0006     ;point to Vigor item in character info
C20ED3:  LDA $15F5,X
         STA $11A0,Y    ;$11A6 = Vigor, 11A4 = Speed, 11A2 = Stamina,
                        ;11A0 = Mag Pwr
         INX
         DEY
         DEY
         BPL C20ED3     ;loop 4 times
         LDA $15EB,X    ;get character Status 1
         STA $FE        ;save it; it'll be used for tests with Imp equip
         LDY #$0005     ;point to last relic slot
C20EE6:  LDA $15FB,X
         STA $11C6,Y    ;save the item #
         JSR C20F9A     ;load item data for a slot
         DEX
         DEY
         BPL C20EE6     ;loop for all 6 equipment+relic slots
         LDA $15ED,X    ;get top byte of Maximum MP
         AND #$3F       ;zero out top 2 bits, so MP can't exceed 16383
         STA $FF        ;store top byte of Max MP.
                        ;Note: X would be -2 here for Character 0 had the extra
                        ;37 not been added earlier.  i don't think indexed
                        ;addressing modes are signed or allow "wrapping", so
                        ;that was a good precaution.
         LDA #$40       ;first boost we will check is MP + 50%, then lower %
         JSR C20F7D     ;jump off to handle % MP boosts from equipment
         ORA $FF
         STA $15ED,X    ;store boost in highest 2 bits of MP
         LDA $15E9,X    ;get top byte of Maximum HP
         AND #$3F       ;zero out top 2 bits, so HP can't exceed 16383
         STA $FF        ;store top byte of Max HP
         LDA #$08
         JSR C20F7D     ;go check HP + 50% boost, then lower %
         ORA $FF
         STA $15E9,X    ;store boost in highest 2 bits of HP
         LDX #$000A
C20F18:  LDA $11A1,X    ;did MBlock/Evade/Vigor/Speed/Stamina/MagPwr
                        ;exceed 255 with equipment boosts?
         BEQ C20F26     ;if not, look at the next stat
         ASL            ;if the topmost bit of the stat is set, it's negative
                        ;thanks to horrid equipment.  so bring it up to Zero
         TDC
         BCS C20F23     ;if the topmost bit wasn't set, the stat is just big
         LDA #$FF       ;..  in which case we bring it down to 255
C20F23:  STA $11A0,X
C20F26:  DEX
         DEX
         BPL C20F18     ;loop for all aforementioned stats
         LDX $11CE      ;call a function pointer depending on what
                        ;is in each hand
         JSR (C20F47,X)
         LDA $11D7
         BPL C20F42     ;if Boost Vigor bit isn't set, exit function
         REP #$20       ;Set 16-bit Accumulator
         LDA $11A6
         LSR
         CLC
         ADC $11A6
         STA $11A6      ;if Boost Vigor was set, add 50% to Vigor
C20F42:  PLP
         PLB
         PLY
         PLX
         RTL


;Code Pointers

C20F47: dw C20F67 ;Do nothing (shouldn't be called, as i can't get shields in both hands)
      : dw C20F61 ;2nd hand is occupied by weapon, 1st hand holds nonweapon
                  ;so 2nd hand will strike.  i.e. it retains some Battle Power
      : dw C20F68 ;1st hand is occupied by weapon, 2nd hand holds nonweapon
                  ;so 1st hand will strike
      : dw C20F6F ;1st and 2nd hand are both occupied by weapon
      : dw C20F61 ;2nd hand is empty, 1st hand holds nonweapon
                  ;so 2nd hand will strike
      : dw C20F67 ;Do nothing  (filler.. shouldn't be called, contradictory 2nd hand)
      : dw C20F6B ;2nd hand is empty, 1st is occupied by weapon
                  ;(so 1st hand will strike, Gauntlet-ized if applicable)
      : dw C20F67 ;Do nothing  (filler.. shouldn't be called, contradictory 2nd hand)
      : dw C20F68 ;1st hand is empty, 2nd hand holds nonweapon
                  ;so 1st hand will strike
      : dw C20F64 ;1st hand is empty, 2nd hand occupied by weapon
                  ;so 2nd hand will strike, Gauntlet-ized if applicable
      : dw C20F67 ;Do nothing  (filler.. shouldn't be called, contradictory 1st hand)
      : dw C20F67 ;Do nothing  (filler.. shouldn't be called, contradictory 1st hand)
      : dw C20F68 ;1st and 2nd hand both empty)
                  ;so might as well strike with 1st hand

;view C2/10B2 to see how the bits for each hand were set


C20F61:  JSR C20F74
C20F64:  STZ $11AC      ;clear Battle Power for 1st hand
C20F67:  RTS

C20F68:  JSR C20F74
C20F6B:  STZ $11AD      ;clear Battle Power for 2nd hand
         RTS


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

C20F6F:  LDA #$10       ;Genji Glove Effect
         TSB $11CF      ;Sets Genji Glove effect to be cleared
C20F74:  LDA #$40
         TRB $11DA      ;turn off Gauntlet effect for 1st hand
         TRB $11DB      ;turn off Gauntlet effect for 2nd hand
         RTS


;11D5 =
;01: Raise Attack Damage         10: Raise HP by 12.5%
;02: Raise Magic Damage          20: Raise MP by 25%
;04: Raise HP by 25%             40: Raise MP by 50%
;08: Raise HP by 50%             80: Raise MP by 12.5% .  from yousei's doc)

C20F7D:  BIT $11D5
         BEQ C20F85
         LDA #$80       ;if bit is set, store 50% boost
         RTS

C20F85:  LSR
         BIT $11D5
         BEQ C20F8E
         LDA #$40       ;if bit is set, store 25% boost
         RTS

C20F8E:  ASL
         ASL
         BIT $11D5
         BEQ C20F98
         LDA #$C0       ;if bit is set, store 12.5% boost
         RTS

C20F98:  TDC            ;if none of the bits were set, store 0% boost
         RTS


;Loads item data into memory

C20F9A:  PHX
         PHY            ;Y = equip/relic slot, 0 to 5?
         XBA
         LDA #$1E
         JSR C24781     ;multiply index by size of item data block
                        ;JSR C22B63?
         TAX
         LDA $D85005,X  ;field effects
         TSB $11DF
         REP #$20       ;Set 16-bit accumulator
         LDA $D85006,X
         TSB $11D2      ;status bytes 1 and 2 protection
         LDA $D85008,X
         TSB $11D4      ;11D4 = equipment status byte 3,
                        ;11D5 = raise attack damage, raise magic damage,
                        ;and HP and MP % boosts
         LDA $D8500A,X

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

         TSB $11D6
         LDA $D8500C,X  ;battle effects 2 and 3
         TSB $11D8

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

         LDA $D85010,X  ;Vigor+ / Speed+ / Stamina+ / MagPwr+ , by ascending address
         LDY #$0006
C20FCF:  PHA            ;Put on stack
         AND #$000F     ;isolate bottom nibble
         BIT #$0008     ;if top bit of stat boost is set, adjustment will be negative
         BEQ C20FDC     ;if not, branch
         EOR #$FFF7     ;create a signed 16-bit negative value
         INC            ;A = 65536 - bottom 3 bits.  iow, negation of
                        ;3-bit value.
C20FDC:  CLC
         ADC $11A0,Y
         STA $11A0,Y    ;make adjustment to stat, ranging from -7 to +7
                        ;$11A6 = Vigor, 11A4 = Speed, 11A2 = Stamina, 11A0 = Mag Pwr
         PLA
         LSR
         LSR
         LSR
         LSR            ;get next highest nibble
         DEY
         DEY
         BPL C20FCF     ;loop for all 4 stats
         LDA $D8501A,X  ;Evade/MBlock byte in bottom of A
         PHX
         PHA            ;Put on stack
         AND #$000F     ;isolate evade
         ASL
         TAX            ;evade nibble * 2, turn into pointer
         LDA C21105,X   ;get actual evade boost/reduction of item
         CLC
         ADC $11A8
         STA $11A8      ;add it to other evade boosts
         PLA
         AND #$00F0     ;isolate mblock
         LSR
         LSR
         LSR
         TAX            ;mblock nibble * 2, turn into pointer
         LDA C21105,X   ;get actual mblock boost/reduction of item
         CLC
         ADC $11AA
         STA $11AA      ;add it to other mblock boosts
         PLX
         SEP #$20       ;Set 8-bit Accumulator
         LDA $D85014,X  ;get weapon battle power / armor defense power
         XBA
         LDA $D85002,X  ;get top byte of equippable chars
         ASL
         ASL            ;carry = Specs active when Imp?
         LDA $FE        ;Character Status Byte 1
         BCS C21029     ;branch if imp-activated
         EOR #$20       ;flip Imp status
C21029:  BIT #$20       ;character has Imp status?
         BNE C21030
         LDA #$01       ;if you're an Imp and specs aren't Imp-activated,
                        ;defense/battle power = 1.  or if you're not an Imp
                        ;and the specs are Imp-activated, battle/defense
                        ;power = 1
         XBA
C21030:  XBA            ;if imp-activation and imp status match, put the
                        ;original Battle/Defense Power back in bottom of A

;note that Item #255 has a Battle Power of 10, so bare hands will actually be
; stronger than Imp Halberd on a non-Imp)

         STA $FD
         LDA $D85000,X  ;item type
         AND #$07       ;isolate classification
         DEC
         BEQ C210B2     ;if it's a weapon, branch and load its data
         LDA $D85019,X
         TSB $11BC      ;equipment status byte 2
         LDA $D8500F,X  ;50% resist elements
         XBA
         LDA $D85018,X  ;weak to elements
         REP #$20       ;Set 16-bit Accumulator
         TSB $11B8      ;bottom = weak elements, top = 50% resist elements
         LDA $D85016,X
         TSB $11B6      ;bottom = absorbed elements, top = nullified elements
         SEP #$20       ;Set 8-bit Accumulator
         CLC
         LDA $FD        ;get equipment Defense Power
         ADC $11BA      ;add it into Defense so far
         BCC C21064
         LDA #$FF
C21064:  STA $11BA      ;if defense exceeds 255, make it 255
         CLC
         LDA $D85015,X  ;get equipment Magic Defense
         ADC $11BB      ;add it into MagDef so far
         BCC C21073
         LDA #$FF
C21073:  STA $11BB      ;if magic defense exceeds 255, make it 255
C21076:  PLY
         LDA #$02
         TRB $11D5      ;clear "raise magic damage" bit in Item Bonuses --
                        ;raise fight, raise magic, HP + %, MP + %
         BEQ C21086
         TSB $11D7      ;if Earring effect is set in current equipment slot, set
                        ;it in Item Special 2:
                        ;boost steal, single Earring, boost sketch, boost control,
                        ;sniper sight, gold hairpin, economizer, vigor + 50%
         BEQ C21086
         TSB $11D5      ;if Earring effect had also been set by other equipment
                        ;slots, set it again in item bonuses, where it will actually
                        ;represent _double_ Earring, even though the initial data
                        ;byte would have it set even for a lone Earring
                        ;if all this crazy bit swapping seems convuluted, keep in
                        ;mind that $11D5 isn't RELOADED for each equipment slot
                        ;it's ADDED to via the TSB at C2/0FB7.  thus, we must clear
                        ;the Earring bit in $11D5 for each of the 6 equip slots if
                        ;we wish to see whether the CURRENT slot gives us the
                        ;Earring effect.

C21086:  TDC
         LDA $D8501B,X  ;item byte 1B, special action
         STA $11BE,Y
         BIT #$0C       ;shield animation for blocked physical/magic attacks
                        ;or weapon parry
         BEQ C210B0     ;if none of above, branch
         PHA            ;save old Byte 1B
         AND #$03       ;isolate bottom 2 bits.  for a given item:
                        ;bit 0 = big weapon parry anim.
                        ;bit 1 = "any" shield block, all except cursed shld.
                        ;both = zephyr cape.  neither = small weapon parry.
                        ;bit 2 = physical block: shield, weapon parry, or zephyr cape
                        ;bit 3 = magical shield block.  shields only?

         TAX            ;put Acc in X.  Following loop gives us 2^X
         TDC            ;clear Acc
         SEC            ;set carry flag
C21098:  ROL            ;rotate carry into lowest bit of Acc
         DEX            ;decrement X, which was 0-3
         BPL C21098     ;loop if X >= 0
         XBA
         PLA            ;retrieve item byte 1B
         BIT #$04
         BEQ C210A7     ;branch if physical block animation not set
         XBA
         TSB $11D0      ;if one of above was set, store our 2^X value
         XBA
C210A7:  BIT #$08
         BEQ C210B0     ;if no magic attack block for shield, branch
         XBA
         TSB $11D1      ;if there was, store our 2^X value
         XBA
C210B0:  PLX
         RTS


;Load weapon properties from an arm slot

C210B2:  TDC
         INC
         TAY            ;Y = 1
         INC            ;Accumulator = 2
         STA $FF
         LDA $01,S      ;equipment/relic slot - 0 to 5
         CMP #$02
         BCS C21076     ;if it's not slot 0 or 1, one of the arms, return
                        ;to caller
         DEC
         BEQ C210C4     ;if it was slot 1, branch
         DEY            ;point to slot 0
         ASL $FF        ;$FF = 4
C210C4:  LDA $11C6,Y    ;get item # from the slot
         INC
         BNE C210CE     ;if the item is not Empty #255, branch
         ASL $FF
         ASL $FF
C210CE:  LDA $FF        ;$FF = 2 if this is 2nd hand and it's occupied by weapon,
                        ;4 if this is 1st hand and it's occupied by weapon,
                        ;8 if this is 2nd hand and it's empty,
                        ;16 if this is 1st hand and it's empty.
                        ;And $FF is never set if the hand holds a nonweapon
         TSB $11CE      ;turn on the current $FF bit in $11CE, which
                        ;will hold info about both hands
         LDA $D85016,X
         STA $11B2,Y
         LDA $D8500F,X  ;elemental properties
         STA $11B0,Y
         LDA $FD        ;get equipment Battle Power
         ADC $11AC,Y    ;add it to Battle Power so far
         BCC C210EA
         LDA #$FF
C210EA:  STA $11AC,Y    ;if the Battle Power exceeded 255, make it 255
         LDA $D85015,X  ;hit rate
         STA $11AE,Y
         LDA $D85012,X  ;random weapon spellcast
         STA $11B4,Y
         LDA $D85013,X  ;weapon properties
         STA $11DA,Y    ;11DA=

;                        01:          10: --
;                        02: SwdTech             20: Same damage from back row
;                        04: --                  40: 2-Hand
;                        08: --                  80: Runic)

         JMP C21076


;Data - Evade and Mblock Boosts/Reductions

C21105: dw 0            ;0
      : dw 10           ;+10
      : dw 20           ;+20
      : dw 30           ;+30
      : dw 40           ;+40
      : dw 50           ;+50
      : dw -10          ;-10
      : dw -20          ;-20
      : dw -30          ;-30
      : dw -40          ;-40
      : dw -50          ;-50


;Called every frame

C2111B:  PHP
         SEP #$30       ;Set 8-bit A, X, & Y
         JSR C24D1F     ;Handle player-confirmed commands
         LDA $2F41      ;are we in a menu?
         AND $3A8F      ;is Config set to wait battle?
         BNE C2118B     ;Exit function if both
         LDA $3A6C      ;get backup frame counter
         LDX #$02
C2112E:  CMP $0E        ;compare to current frame counter?
         BEQ C21190     ;Exit function if $3A6C = $000E.  Doing this check
                        ;twice serves to exit if the function was already
                        ;called the current frame [which i don't think ever
                        ;happens] or if it was called last frame.
         INC
         DEX
         BNE C2112E     ;Check and exit if $3A6C + 1 = $000E
         INC $3A3E      ;Increment battle time counter
         BNE C2113E
         INC $3A3F      ;Increment battle time counter
C2113E:  JSR C25A83     ;Handles various time-based events for entities.
                        ;Advances their timers, does periodic damage/healing
                        ;from Poison/Regen/etc., checks for running, and more.
         LDX #$12
C21143:  CPX $3EE2      ;Is this target Morphed?
         BNE C2114B     ;Branch if not
         JSR C21211     ;Do morph timer decrement
C2114B:  LDA $3AA0,X
         LSR
         BCC C21184     ;If entity not present in battle, branch to next one
         CPX $33F8      ;Has this target used Zinger?
         BEQ C21184     ;If it has, branch to next target
         BIT #$3A
         BNE C21184     ;If any of bits 6, 5, 4, or 2 are set in $3AA0,X ,
                        ;branch to next target
         BIT #$04
         BEQ C2117C     ;If bit 3 isn't set in $3AA0,X , branch to load
                        ;this target's ATB
         LDA $2F45      ;party trying to run: 0 = no, 1 = yes
         BEQ C21179     ;If no one is trying to run, branch to Advance Wait Timer
                        ;function
         LDA $3EE4,X
         BIT #$02       ;Check for Zombie Status
         BNE C21179     ;If zombie, branch to Advance Wait Timer function
         LDA $3018,X
         BEQ C21179     ;If monster, branch to Advance Wait Timer function
         BIT $3F2C
         BNE C21179     ;If jumping, branch to Advance Wait Timer function
         BIT $3A40
         BEQ C2117C     ;If not character acting as an enemy, skip Advance
                        ;Wait Timer function
C21179:  JSR C21193     ;Advance Wait Timer function
C2117C:  LDA $3219,X    ;Load top byte of this target's ATB counter
         BEQ C21184     ;If it's 0, branch to next target
         JSR C211BB
C21184:  DEX
         DEX
         BPL C21143     ;Loop if targets remaining
         JSR C25C54     ;Copy ATB timer, Morph gauge, and Condemned counter to
                        ;displayable variables
C2118B:  LDA $0E
         STA $3A6C      ;copy current frame counter to backup frame counter?
C21190:  TDC
         PLP
         RTL


;Advance Wait Timer.  This is what controls how long a character
; spends in his or her "ready stance" before executing a move.)

C21193:  REP #$20       ;16-bit accumulator
         LDA $3AC8,X    ;amount to increase ATB timer by
         LSR            ;div by 2
         CLC
         ADC $3AB4,X
         STA $3AB4,X    ;add to Wait Timer
         SEP #$20       ;8-bit accumulator
         BCS C211AA     ;if that timer overflowed, branch
         XBA            ;get top byte of the timer
         CMP $322C,X    ;compare to time to wait after inputting
                        ;a command
         BCC C211BA     ;if it's less, we're not ready yet
C211AA:  LDA #$FF
         STA $322C,X
         JSR C24E77     ;put entity in action queue
         LDA #$20
C211B4:  ORA $3AA0,X    ;many other functions can enter here to set
                        ;other bits
         STA $3AA0,X    ;set bit 5
C211BA:  RTS


C211BB:  REP #$21
         LDA $3218,X    ;current ATB timer count
         ADC $3AC8,X    ;amount to increase timer by
         STA $3218,X    ;save updated timer
         SEP #$20
         BCC C211BA     ;if timer didn't pass 0, exit
         CPX #$08
         BCS C211D1     ;branch if a monster
         JSR C25BE2
C211D1:  STZ $3219,X    ;zero top byte of ATB Timer
         STZ $3AB5,X    ;zero top byte of Wait Timer
         LDA #$FF
         STA $322C,X
         LDA #$08
         BIT $3AA0,X
         BNE C211EA
         JSR C211B4
         BIT #$02
         BEQ C2120E
C211EA:  LDA #$80
         JSR C211B4
C211EF:  CPX #$08
         BCS C2120E
         LDA $3205,X
         BPL C211BA     ;Exit function if entity has not taken a conventional
                        ;turn [including landing one] since boarding Palidor
         LDA $B1
         BMI C211BA     ;Exit function
         LDA #$04
         JSR C211B4
         LDA $3E4D,X    ;Bit 0 is set on entity who's Controlling another.
                        ;this is an addition in FF3us to prevent a bug caused
                        ;by Ripplering off the "Spell Chant" status.
         LSR
         TXA
         ROR
         STA $10
         LDA #$02
         JMP C26411

C2120E:  JMP C24E66     ;put entity in wait queue


;Decrease Morph timer.  If it's run out, zero related Morph variables,
; and queue the Revert command.)

C21211:  REP #$20       ;Set 16-bit Accumulator
         SEC
         LDA $3F30      ;Load the morph timer
         SBC $3F32      ;Subtract morph decrement amount
         STA $3F30      ;Save the new morph timer
         SEP #$20       ;Set 8-bit Accumulator
         BCS C21234     ;Branch if it's greater than zero
         STZ $3F31      ;zero top byte of Morph timer.  i assume we're
                        ;neglecting to zero $3F30 just to avoid adding a
                        ;"REP" instruction.
         JSR C20B36     ;adjust Morph supply [in this case, zero it]
                        ;to match our new Morph timer
         LDA #$FF
         STA $3EE2      ;Store #$FF to Morphed targets byte [no longer have a
                        ;Morphed target]
         LDA #$04
         STA $3A7A      ;Store Revert as command
         JSR C24EB2     ;queue it, in entity's counterattack and periodic
                        ;damage/healing queue
C21234:  LDA $3F31      ;Load the remaining amount of morph time DIV 256, if any
         STA $3B04,X    ;Store it to the character's Morph gauge
;Why do we bother zeroing all these timers and variables here when the forthcoming
; Revert can handle it?  Presumably to avoid gauge screwiness and a bunch of pointless
; calls to this function should Terra's Morph timer run down in the middle of an attack
; animation..)
         RTS


;True Knight and Love Token

C2123B:  PHX
         PHP
         LDA $B2
         BIT #$0002     ;Is "No critical and Ignore True Knight" set?
         BNE C212A5     ;Exit if so
         LDA $B8        ;intended target(s.  to my knowledge, there's only one
                        ;intended target set if we call this function..
         BEQ C212A5     ;Exit if none
         LDY #$FF
         STY $F4        ;default to no bodyguards.
         JSR C251F9     ;Y = index of our highest intended target.
                        ;0, 2, 4, or 6 for characters.  8, 10, 12, 14, 16, or 18
                        ;for monsters.
         STY $F8        ;save target index
         STZ $F2        ;Highest Bodyguard HP So Far = 0.  this makes
                        ;the first eligible bodyguard we check get accepted.
                        ;later ones may replace him/her if they have more HP.
         PHX
         LDX $336C,Y    ;Love Token - which target takes damage for you
         BMI C2125F     ;Branch if none do
         JSR C212C0     ;consider this target as a bodyguard
         JSR C212A8     ;if it was valid, make it intercept the attack
C2125F:  PLX
         LDA $3EE4,Y
         BIT #$0200
         BEQ C212A5     ;Branch if target not Near Fatal
         BIT #$0010
         BNE C212A5     ;Branch if Clear
         LDA $3358,Y    ;$3359 = who is Seizing you
         BPL C212A5     ;Branch if target is seized
         LDA #$000F     ;Load all characters as potential bodyguards
         CPY #$08
         BCC C2127C     ;Branch if target is character
         LDA #$3F00     ;Load all monsters as potential bodyguards instead
C2127C:  STA $F0        ;Save potential bodyguards
         LDA $3018,Y    ;bit representing target) (was typoed as "LDA $3018,X"
         ORA $3018,X    ;bit representing attacker
         TRB $F0        ;Clear attacker and target from potential bodyguards
         LDX #$12
C21288:  LDA $3C58,X
         BIT #$0040
         BEQ C2129A     ;Branch if no True Knight effect
         LDA $3018,X
         BIT $F0
         BEQ C2129A     ;Branch if this candidate isn't on the same
                        ;team as the target
         JSR C212C0     ;consider them as candidate bodyguard.  if they're
                        ;valid and their HP is >= past valid candidates,
                        ;they become the new frontrunner.
C2129A:  DEX
         DEX
         BPL C21288     ;Do for all characters and monsters
         LDA $F2
         BEQ C212A5     ;Exit if no bodyguard found [or if the selfless
                        ;soul has 0 HP, which shouldn't be possible outside
                        ;of bugs].
         JSR C212A8     ;make chosen bodyguard -- provided there was one --
                        ;intercept attack.  if somebody's already been slated
                        ;to intercept it [i.e. due to Love Token], the True
                        ;Knight will sensibly defer to them.
C212A5:  PLP
         PLX
         RTS


;Make chosen bodyguard intercept attack, provided one hasn't been
; marked to do so already.)

C212A8:  LDX $F4
         BMI C212BF     ;exit if no bodyguard found
         CPY $F8
         BNE C212BF     ;exit if $F8 no longer points to the original target,
                        ;which means we've already assigned a bodyguard with
                        ;this function.
         STX $F8        ;save bodyguard's index
         STY $A8        ;save intended target's index
         LSR $A8        ;.. but for the latter, use 0,1,2,etc rather
                        ;than 0,2,4,etc
         PHP
         REP #$20       ;set 16-bit A
         LDA $3018,X
         STA $B8        ;save bodyguard as the new target of attack
         PLP
C212BF:  RTS


;Consider candidate bodyguard for True Knight or Love Token

C212C0:  PHP
         REP #$20       ;Set 16-bit Accumulator
         LDA $3AA0,X
         LSR
         BCC C212F3     ;Exit function if entity not present in battle?
         LDA $32B8,X    ;$32B9 = who is Controlling you
         BPL C212F3     ;Exit if you're controlled
         LDA $3358,X    ;$3359 = who is Seizing you
         BPL C212F3     ;Exit if you're Seized
         LDA $3EE4,X
         BIT #$A0D2     ;Death, Petrify, Clear, Zombie, Sleep, Muddled
         BNE C212F3     ;Exit if any set
         LDA $3EF8,X
         BIT #$3210     ;Stop, Freeze, Spell Chant, Hide
         BNE C212F3     ;Exit if any set
         LDA $3018,X
         TSB $A6        ;make this potential guard jump in front of the
                        ;target, can accompany others
         LDA $3BF4,X    ;HP of this potential bodyguard
         CMP $F2
         BCC C212F3     ;branch if it's not >= the highest HP of the
                        ;other bodyguards considered so far for this attack.
         STA $F2        ;if it is, save this entity's HP as the highest
                        ;HP so far.
         STX $F4        ;and this entity becomes the new bodyguard.
C212F3:  PLP
         RTS


;Do HP or MP Damage/Healing to an entity

C212F5:  PHX
         PHP
         LDX #$02
         LDA $11A2
         BMI C21300     ;Branch if concerns MP
         LDX #$00
C21300:  JSR (C2131F,X) ;Deal damage and/or healing
         SEP #$20       ;Set 8-bit Accumulator
         BCC C2131C     ;Branch if no damage done to target, or
                        ;if healing done on same strike matched
                        ;or exceeded damage
         LDA $02,S      ;get attacker
         TAX            ;save in X
         STX $EE        ;and in a RAM variable, too
         JSR C2362F     ;Mark entity X as the last attacker of entity Y,
                        ;unless Y already has an attacker this turn.  Set flag
                        ;indicating that entity Y was attacked this turn, and
                        ;this might be the lone context where doing so isn't
                        ;arbitrary.
         CPY $EE        ;does target == attacker?
         BEQ C2131C     ;branch if so
         STA $327C,Y    ;save attacker [original, not any reflector] in byte
                        ;that's used by FC 05 script command
         LDA $3018,Y
         TRB $3419      ;indicate target as being damaged [by an
                        ;attacker other than themselves] this turn.
                        ;will be used by Black Belt function.
C2131C:  PLP
         PLX
         RTS


;Code pointers

C2131F: dw C21323     ;HP damage
      : dw C21350     ;MP damage


;Deal HP Damage/Healing
;Returns in Carry:
; Set if damage done to target, and damage exceeds any healing done on same strike.
; Clear if damage not done to target, or if healing done on same strike matches
; or exceeds it.)

C21323:  JSR C213A7     ;Returns Damage Healed - Damage Taken
         BEQ C2133B     ;Exit function if 0 damage [damage = healing]
         BCC C2133D     ;If Damage > Healing, deal HP damage
         CLC            ;Otherwise, deal HP healing
         ADC $3BF4,Y    ;Add to HP
         BCS C21335
         CMP $3C1C,Y
         BCC C21338
C21335:  LDA $3C1C,Y    ;If over Max HP, set to Max HP
C21338:  STA $3BF4,Y
C2133B:  CLC
C2133C:  RTS


C2133D:  EOR #$FFFF
         STA $EE        ;65535 - [Healing - Damage].  This gives us the
                        ;Net Damage minus 1, and that 1 is cancelled out
                        ;by the SBC below, which is done with Carry clear.
         LDA $3BF4,Y
         SBC $EE        ;Subtract damage from HP
         STA $3BF4,Y
         BEQ C21390     ;branch if 0 HP
         BCS C2133C     ;Exit If > 0 HP
         BRA C21390     ;If < 0 HP


;Deal MP Damage/Healing
;Returns in Carry:
; Set if damage done to target, and damage exceeds any healing done on same strike.
; Clear if damage not done to target, or if healing done on same strike matches
; or exceeds it.)

C21350:  JSR C213A7     ;Returns Damage Healed - Damage Taken
         BEQ C2133B     ;Exit function if 0 damage [damage = healing]
         BCC C2136B     ;If Damage > Healing, deal MP damage
         CLC            ;Otherwise, deal MP healing
         ADC $3C08,Y    ;Add A to MP
         BCS C21362
         CMP $3C30,Y
         BCC C21365
C21362:  LDA $3C30,Y    ;If result over Max MP, set Current MP to Max MP
C21365:  STA $3C08,Y
         CLC
         BRA C2138A
 
C2136B:  EOR #$FFFF
         STA $EE        ;65535 - [Healing - Damage].  This gives us the
                        ;Net Damage minus 1, and that 1 is cancelled out
                        ;by the SBC below, which is done with Carry clear.
         LDA $3C08,Y
         SBC $EE
         STA $3C08,Y    ;Subtract from MP
         BEQ C2137C     ;branch if MP = 0
         BCS C2138A     ;branch if MP > 0
C2137C:  TDC            ;If it's less than 0,
         STA $3C08,Y    ;Store 0 in MP
         LDA $3C95,Y
         LSR
         BCC C21389     ;Branch if not Die at 0 MP
         JSR C21390     ;Call lethal damage function if Dies at 0 MP
C21389:  SEC
C2138A:  LDA #$0080
         JMP C2464C


;If character/monster takes lethal damage

C21390:  SEC
         TDC            ;Clear accumulator
         TAX
         STX $3A89      ;turn off random weapon spellcast
         STA $3BF4,Y    ;Set HP to 0
         LDA $3EE4,Y
         BIT #$0002
         BNE C2133C     ;Exit function if Zombie
         LDA #$0080
         JMP C20E32     ;Sets $3DD4 for death status


;Returns Damage Healed - Damage Taken

C213A7:  LDA $33D0,Y    ;Damage Taken
         INC
         BEQ C213BC     ;If no damage, branch and save damage as 0
         LDA $3018,Y
         BIT $3A3C
         BEQ C213B9     ;Branch if not invincible
         TDC
         STA $33D0,Y    ;Set damage to 0
C213B9:  LDA $33D0,Y
C213BC:  STA $EE
         LDA $3A81
         AND $3A82
         BMI C213C8     ;Branch if no Golem or dog block
         STZ $EE        ;Set damage to 0
C213C8:  LDA $33E4,Y    ;Damage Healed
         INC
         BEQ C213CF     ;If no healing, branch and treat healing as 0
         DEC            ;get healing amount again
C213CF:  SEC
         SBC $EE        ;Subtract damage
         RTS


;Character/Monster Takes One Turn

C213D3:  PHX
         PHP
         JSR C22639     ;Clear animation buffer pointers, extra strike
                        ;quantity, and various backup targets
         LDA #$10
         TSB $B0        ;related to characters stepping forward and
                        ;getting circular or triangular pattern around
                        ;them when casting Magic or Lores.
         LDA #$06
         STA $B4
         STZ $BD        ;zero turn-wide Damage Incrementor
         STZ $3A89      ;disable weapon addition magic
         STZ $3EC9      ;Set # of targets to zero
         STZ $3A8E      ;disable Continuous Jump
         TXY
         LDA #$FF
         STA $B2
         STA $B3
         LDX #$0F
C213F4:  STA $3410,X    ;$3410 - $341F = FFh
         DEX
         BPL C213F4
         LDA $B5        ;Load command
         ASL
         TAX
         JSR (C219C7,X) ;Execute command
         LDA #$FF
         STA $3417      ;indicate null Sketcher/Sketchee.  not sure why
                        ;this is needed, given the C2/13F4 loop.
         JSR C2629B     ;Copy A to $3A28, and copy $3A28-$3A2B variables
                        ;into ($76) buffer
         JSR C2069B     ;Do various responses to three mortal statuses
         JSR C24C5B     ;prepare any applicable counterattacks
         JSR C21429     ;Remove dead-ish enemies from list of remaining
                        ;enemies, if Piranha or other conditions met
         LDA #$04
         JSR C26411     ;Execute animation queue
         JSR C24AB9     ;Update lists and counts of present and/or living
                        ;characters and monsters
         JSR C2147A     ;Place marked entities in $2F4E on battlefield
         JSR C2083F
         JSR C2144F     ;Remove marked entities in $2F4C from battlefield
         JSR C262C7     ;Add Stolen or Metamorphed item to a temporary
                        ;$602D-$6031 [plus offset] buffer.  Also, add back
                        ;an item used via Equipment Magic if the item isn't
                        ;destroyed upon use [no equipment in the game works
                        ;that way, but it's fully possible].
                        ;then _that_ buffer gets added to Item menu by
                        ;having the triangle cursor switch onto a new
                        ;character, or if that somehow doesn't happen, then
                        ;at end of battle.
         PLP
         PLX
         RTS


;Remove dead-ish enemies from list of remaining enemies, provided that: they have no
; counterattack or periodic damage/healing queued, they are Hidden, or they are Piranha)

C21429:  LDX #$0A
C2142B:  LDA $3021,X
         BIT $3A3A      ;is it in list of dead-ish enemies?
         BEQ C2144A     ;branch to next monster if not
         XBA
         LDA $3F01,X    ;normally accessed as $3EF9,X
         BIT #$20
         BNE C21446     ;branch if Hide status
         LDA $3E54,X    ;normally accessed as $3E4C,X
         BMI C21446     ;branch if some custom flag is set, which only
                        ;Piranha has.  the other effect of this
                        ;status byte-derived property is to give removable
                        ;Float, which i always thought pointless, given
                        ;Piranha also has permanent Float.
         LDA $32D5,X    ;normally accessed as $32CD,X.  get entry point into
                        ;this entity's counterattack or periodic
                        ;damage/healing linked list queue.
         INC
         BNE C2144A     ;branch if value wasn't a null FFh.  i.e. branch if
                        ;entity has a counterattack or periodic damage/healing
                        ;queued.
C21446:  XBA
         TRB $2F2F      ;remove from bitfield of remaining enemies?
C2144A:  DEX
         DEX
         BPL C2142B     ;iterate for all 6 monsters
         RTS


;Remove marked entities in $2F4C from battlefield

C2144F:  PHP
         REP #$20       ;Set 16-bit Accumulator
         LDX #$12
C21454:  LDA $3018,X
         TRB $2F4C      ;clear flag marking entity to be removed from
                        ;battlefield
         BEQ C21474     ;branch if it hadn't been set
         SEP #$20       ;Set 8-bit Accumulator
         XBA
         TRB $2F2F      ;if enemy, clear it from bitfield of remaining
                        ;enemies?
         LDA #$FE
         JSR C20792     ;clear Bit 0 of $3AA0,X , indicating that entity
                        ;is absent
         LDA $3EF9,X
         ORA #$20
         STA $3EF9,X    ;Set Hide status
         JSR C207C8     ;Clear Zinger, Love Token, and Charm bonds, and
                        ;clear applicable Quick variables
         REP #$20
C21474:  DEX
         DEX
         BPL C21454     ;iterate for all 10 entities
         PLP
         RTS


;Place marked entities in $2F4E on battlefield, and remove any terminal ailments
; or Imp status they may have)

C2147A:  PHP
         REP #$20       ;Set 16-bit Accumulator
         LDX #$12
C2147F:  LDA $3018,X
         TRB $2F4E      ;clear flag
         BEQ C214A7     ;branch if entity hadn't been marked to enter
                        ;battlefield
         SEP #$20       ;Set 8-bit Accumulator
         XBA
         TSB $2F2F      ;if enemy, mark it in bitfield of remaining
                        ;enemies?
         LDA #$01
         JSR C211B4     ;set Bit 0 of $3AA0,X , which indicates that
                        ;entity is present
         LDA $3EE4,X
         AND #$1D
         STA $3EE4,X    ;Clear Zombie, Imp, Petrify, Death
         LDA $3EF9,X
         AND #$DF
         STA $3EF9,X    ;Clear Hide
         JSR C22DA0     ;Handle "Attack First" property for monster.
                        ;And make Carry Flag match the property's state
                        ;[it will be clear for characters].
         REP #$20
C214A7:  DEX
         DEX
         BPL C2147F     ;iterate for all 10 entities
         PLP
         RTS


;Check if hitting target(s in back

C214AD:  LDA $11A2
         LSR
         BCC C21511     ;Exit function if magical damage
         CPX #$08
         BCS C214E5     ;Branch if monster attacker
         LDA $201F      ;get encounter type:  0 = front, 1 = back,
                        ;2 = pincer, 3 = side
         CMP #$03
         BNE C21511     ;Exit function if not Side attack
         LDA $3018,X    ;Holds $01 for character 1, $02 for character 2,
                        ;$04 for character 3, $08 for character 4
         AND $2F50      ;bitfield of which way all the characters face
         STA $EE        ;will be default of 0 if character attacker faces left,
                        ;nonzero if they face right
         LDY #$0A
C214C8:  LDA $EE
         XBA            ;save attacking character's direction variable
         LDA $3021,Y    ;Holds $01 for monster 1, $02 for monster 2,
                        ;$04 for monster 3, etc.  Note we'd normally access this
                        ;as $3019; $3021 is an adjustment for the loop iterator.
         BIT $2F51      ;bitfield of which way all the monsters face
         BEQ C214D8     ;branch if this monster faces left
         XBA
         EOR $3018,X    ;A = reverse of attacking character's direction
         XBA
C214D8:  XBA
         BNE C214DF     ;branch if the character and monster are facing
                        ;each other
         XBA            ;get $3021,Y
         TSB $3A55      ;so we'll turn on this monster's bit if the
                        ;attacking character is facing their back
C214DF:  DEY
         DEY
         BPL C214C8     ;loop for all 6 monsters
         BRA C21511     ;Exit Function


C214E5:  LDA $201F      ;get encounter type: 0 = front, 1 = back,
                        ;2 = pincer, 3 = side
         CMP #$02
         BNE C21511     ;exit function if not Pincer attack
         LDA $3019,X    ;Holds $01 for monster 1, $02 for monster 2,
                        ;$04 for monster 3, etc.
         AND $2F51      ;bitfield of which way all the monsters face
         STA $EE        ;will be 0 if monster attacker faces left,
                        ;nonzero default if they face right
         LDY #$06
C214F6:  LDA $EE
         XBA            ;save attacking monster's direction variable
         LDA $3018,Y    ;Holds $01 for character 1, $02 for character 2,
                        ;$04 for character 3, $08 for character 4
         BIT $2F50      ;bitfield of which way all the characters face
         BEQ C21506     ;branch if this character faces left
         XBA
         EOR $3019,X    ;A = reverse of attacking monster's direction
         XBA
C21506:  XBA
         BNE C2150D     ;branch if the monster and character are facing
                        ;each other
         XBA            ;get $3018,Y
         TSB $3A54      ;so we'll turn on this character's bit if the
                        ;attacking monster is facing their back
C2150D:  DEY
         DEY
         BPL C214F6     ;loop for all 4 characters
C21511:  RTS


;Increment damage if weapon is spear: Set $BD, turn-wide Damage Incrementor, to 2 if
;Item ID in A is between #$1D and #$24 (inclusive)

C21512:  CMP #$1D
         BCC C2151E     ;Exit if ID < 29d
         CMP #$25
         BCS C2151E     ;Exit if ID >= 37d
         LDA #$02
         STA $BD        ;set turn-wide Damage Incrementor to 2
C2151E:  RTS


;Sketch

C2151F:  TYX
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         LDA #$FF
         STA $B7        ;start with null graphic index, in case it misses
         LDA #$AA
         STA $11A9      ;Store Sketch in special effect
         JSR C2317B     ;entity executes one hit
         LDY $3417      ;get the Sketchee
         BMI C2151E     ;Exit if it's null
         STX $3417      ;save the attacker as the SketcheR
         LDA $3C81,Y    ;get target [enemy] Special attack graphic
         STA $3C81,X    ;copy to attacker
         LDA $322D,Y    ;get target Special attack
         STA $322D,X    ;copy to attacker
         STZ $3415      ;will force randomization and skip backing up of
                        ;targets
         LDA $3400
         STA $B6        ;copy "spell # of second attack" into normal
                        ;spell variable
         LDA #$FF
         STA $3400      ;clear "spell # of second attack"
         LDA #$01
         TSB $B2        ;will allow name of attack to be displayed atop
                        ;screen for its first strike
C21554:  LDA $B6
         JSR C21DBF     ;choose a command based on spell #
         STA $B5
         ASL
         TAX
         JMP (C219C7,X) ;execute that command


;Rage

C21560:  LDA $33A8,Y    ;get monster #
         INC
         BNE C21579     ;branch if it's already defined
         LDX $3A93      ;if it's undefined [like with Mimic], get the
                        ;index of another Rager, so we can copy their
                        ;monster #
         CPX #$14
         BCC C2156F     ;if the Rager index corresponds to a character
                        ;[0, 2, 4, 6] or an enemy [8, 10, 12, 14, 16, 18],
                        ;consider it valid and branch.
         LDX #$00       ;if not, default to looking at character #1
C2156F:  LDA $33A8,X    ;get that other Rager's monster
         STA $33A8,Y    ;save it as our current Rager's monster
         TDC
         STA $33A9,Y
C21579:  STY $3A93      ;save the index of our current Rager
         LDA $3EF9,Y
         ORA #$01
         STA $3EF9,Y    ;Set Rage status
         JSR C20610     ;Load monster Battle and Special graphics, its special
                        ;attack, elemental properties, status immunities, startup
                        ;statuses [to be set later], and special properties
         TYX
         JSR C22650     ;deal with Instant Death protection, and Poison elemental
                        ;nullification giving immunity to Poison status
         JSR C21554     ;Commands code.
                        ;note that the attack's "Update Status" function will also
                        ;be used to give the monster's statuses to the Rager.
         JMP C22675     ;make some monster statuses permanent by setting immunity
                        ;to them.  also handle immunity to "mutually exclusive"
                        ;statuses.


;Steal

C21591:  TYX
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         LDA #$A4
         STA $11A9      ;Store steal in special effect
         JMP C2317B     ;entity executes one hit


;Blitz

C2159D:  LDA $B6
         BPL C215B0     ;branch if the spell # indicates a Blitz
         LDA #$01
         TRB $B3        ;this will clear targets for a failed Blitz input
         LDA #$43
         STA $3401      ;Set to display Text $43 - "Incorrect Blitz input!"
         LDA #$5D
         STA $B6        ;store Pummel's spell number
         BRA C215B5
C215B0:  LDA #$08
         STA $3412      ;will display a Blitz name atop screen
C215B5:  LDA $B6
         PHA            ;Put on stack
         SEC
         SBC #$5D       ;subtract Pummel's spell index from our spell #
         STA $B6        ;save our 0 thru 7 "Blitz index", likely used for
                        ;animation
         PLA            ;but use our original spell # for loading spell data
         TYX
         JSR C219C1     ;Load data for command and attack/sub-command, held
                        ;in $B5 and A
         JSR C22951     ;Load Magic Power / Vigor and Level
         JMP C2317B     ;entity executes one hit


;Fight - check for Desperation attack first

C215C8:  CPY #$08
         BCS C21610     ;No DA if monster
         LDA $3A3F
         CMP #$03
         BCC C21610     ;No DA if time counter is 767 or less
         LDA $3EE5,Y
         BIT #$02
         BEQ C21610     ;No DA If not Near Fatal
         BIT #$24
         BNE C21610     ;No DA If Muddled or Image
         LDA $3EE4,Y
         BIT #$12
         BNE C21610     ;No DA If Clear or Zombie
         LDA $B9
         BEQ C21610     ;No DA if no monsters targeted
         JSR C24B5A     ;Random number 0 to 255
         AND #$0F       ;0 to 15
         BNE C21610     ;1 in 16 chance for DA
         LDA $3018,Y
         TSB $3F2F      ;mark as ineligible to use a desperation attack again
         BNE C21610     ;No DA if this character already used it this combat
         LDA $3ED8,Y    ;Which character it is
         CMP #$0C
         BEQ C21604     ;branch if Gogo
         CMP #$0B
         BCS C21610     ;branch if Character 11 or above: Gau, Umaro, or
                        ;special character.  none of these characters have DAs
         INC
C21604:  DEC            ;if it was Gogo, we decrement the DA by 1 to account
                        ;for Gau -- who's before Gogo -- not having one
         ORA #$F0
         STA $B6        ;add F0h to modified character #, then save as attack #
         LDA #$10
         TRB $B0        ;???  See functions C2/13D3 and C2/57C2 for usual
                        ;purpose; dunno whether it does anything here.
         JMP C21714

C21610:  CPY #$08       ;Capture enters here
         BCS C2161B     ;branch if monster
         LDA $3ED8,Y    ;Which character it is
         CMP #$0D
         BEQ C2163B     ;branch if Umaro
C2161B:  TYX
         LDA $3C58,X
         LSR
         LDA #$01
         BCC C21626     ;branch if no offering
         LDA #$07
C21626:  STA $3A70      ;# of attacks
         JSR C25A4D     ;Remove dead and hidden targets
         JSR C23865     ;depending on $3415, copy targets into backup targets
                        ;and add to "already hit targets" list, or copy backup
                        ;targets into targets.
         LDA #$02
         TRB $B2        ;clear no critical & ignore true knight
         LDA $B5
         STA $3413      ;save backup command [Fight or Capture].  used for
                        ;multi-strike turns where a spell is cast by a weapon,
                        ;thus overwriting the command #.
         JMP C2317B     ;entity executes one hit (loops for multiple-strike
                        ;attack)


;Determine which type of attack Umaro uses

C2163B:  STZ $FE        ;start off allowing neither Storm nor Throw attack
         LDA #$C6
         CMP $3CD0,Y
         BEQ C21649     ;Branch if Rage Ring equipped in relic slot 1
         CMP $3CD1,Y    ;Check Slot 2
         BNE C21656     ;Branch if Rage Ring not equipped
C21649:  TDC
         LDA $3018,Y
         EOR $3A74
         BEQ C21656     ;Branch if Umaro is the only present character alive
         LDA #$04
         TSB $FE        ;allow for Throw character attack
C21656:  LDA #$C5
         CMP $3CD0,Y
         BEQ C21662     ;Branch if Blizzard Orb equipped in relic slot 1
         CMP $3CD1,Y    ;Check Slot 2
         BNE C21666     ;Branch if Blizzard Orb not equipped
C21662:  LDA #$08
         TSB $FE        ;allow for Storm attack
C21666:  LDA $FE
         TAX            ;form a pointer based on availability of Storm and/or
                        ;Throw.  it will pick 1 of Umaro's 4 probability sets,
                        ;each of which holds the chances for his 4 attacks.
         ORA #$30       ;always allow Normal attack and Charge
         ASL
         ASL
         JSR C25247     ;X = Pick attack type to use.  Will return 0 for
                        ;Throw character, 1 for Storm, 2 for Charge,
                        ;3 for Normal attack.
         TXA
         ASL
         TAX
         JMP (C21676,X)


;Code pointers

C21676: dw C21692     ;Throw character
      : dw C2170D     ;Storm
      : dw C2167E     ;Charge
      : dw C2161B     ;Normal attack


;Umaro's Charge attack

C2167E:  TYX
         JSR C217C7     ;attack Battle Power = sum of battle power of
                        ;Umaro's hands.  initialize various other stuff.
         LDA #$20
         TSB $11A2      ;Set ignore defense
         LDA #$02
         TRB $B2        ;Clear no critical and ignore True Knight
         LDA #$23
         STA $B5        ;Set command for animation purposes to #$23
         JMP C2317B     ;entity executes one hit


;Umaro's Throw character attack

C21692:  TYX
         JSR C217C7     ;attack Battle Power = sum of battle power of
                        ;Umaro's hands.  initialize various other stuff.
         LDA $3018,X
         EOR $3A74      ;Remove Umaro from possible characters to throw
         LDX #$06       ;Start pointing at 4th character slot
C2169E:  BIT $3018,X    ;Check each character
         BEQ C216BF     ;Branch to check next character if this one is not
                        ;present or not alive, or if we've already decided on
                        ;a character due to them having Muddled or Sleep.
         XBA
         LDA $3EF9,X
         BIT #$20
         BEQ C216B2     ;Branch if not Hide
         XBA
         EOR $3018,X    ;Remove this character from list of characters to throw
         XBA
         BRA C216BE     ;Check next character
C216B2:  LDA $3EE5,X
         BIT #$A0
         BEQ C216BE     ;Branch if no Muddled or Sleep
         XBA
         LDA $3018,X    ;Set to automatically throw this character
         XBA
C216BE:  XBA
C216BF:  DEX
         DEX
         BPL C2169E     ;iterate for all 4 characters
         PHA            ;Put on stack
         TDC
         PLA            ;clear top half of A
         BEQ C2167E     ;Do Umaro's charge attack if no characters can be thrown
         JSR C2522A     ;Pick a random character to throw
         JSR C251F9     ;Set Y to character thrown
         TYX            ;put throwee in X, so they'll essentially be treated as
                        ;the "attacker" from here on out
         LDA $3ED8,X    ;Which character is thrown
         CMP #$0A
         BNE C216DA     ;Branch if not Mog
         LDA #$02
         TRB $B3        ;Set always critical..  too bad we don't clear
                        ;"Ignore damage increment on Ignore Defense", meaning
                        ;this does nothing. :'(  similarly, the normal 1-in-32
                        ;critical will be for nought.  i'm not sure what stops
                        ;the game from flashing the screen, though..
C216DA:  LDA $3B68,X
         ADC $3B69,X    ;add Battle power of thrown character's left hand to
                        ;their right hand
                        ;there should really be a CLC before this, as there's no
                        ;reason to give Mog, Gau, and Gogo a 1-point advantage
                        ;over other characters.  but it does reduce Mog's
                        ;snubbing somewhat. :P
         BCC C216E4
         LDA #$FE       ;if that overflowed, treat throwee's overall
                        ;Battle Power as 255 [Carry is set]
                        ;can replace last 2 instructions with "BCS C216E9"
C216E4:  ADC $11A6      ;Add to battle power of attack
         BCC C216EB
C216E9:  LDA #$FF       ;if that overflowed, set overall Battle Power
                        ;to 255
C216EB:  STA $11A6      ;Store in new battle power for attack
         LDA #$24
         STA $B5        ;Set command for animation purposes to #$24
         LDA #$20
         TSB $11A2      ;Set ignore defense
         LDA #$02
         TRB $B2        ;Clear no critical and ignore True Knight
         LDA #$01
         TSB $BA        ;Exclude Attacker [i.e. the throwee] from Targets
         LDA $3EE5,X
         AND #$A0
         ORA $3DFD,X
         STA $3DFD,X    ;Set to clear Sleep and Muddled on thrown character,
                        ;provided the character already possesses them
         JMP C2317B     ;entity executes one hit


;Storm

C2170D:  STZ $3415      ;will force to randomly retarget
         LDA #$54       ;Storm
         STA $B6        ;Set spell/animation
C21714:  LDA #$02       ;Magic
         STA $B5        ;Set command
         BRA C2175F
 

;<>Shock

C2171A:  LDA #$82       ;"Megahit" spell, which is what has Shock's data
         BRA C21720     ;go set that as spell/animation


;Health

C2171E:  LDA #$2E       ;Cure 2
C21720:  STA $B6        ;Set spell/animation
         LDA #$05
         BRA C21765
 

;<>Slot

C21726:  LDA #$10
         TRB $B0        ;???  See functions C2/13D3 and C2/57C2 for usual
                        ;purpose; dunno whether it does anything here.
         LDA $B6
         CMP #$94
         BNE C21734     ;branch if not L.5 Doom [i.e. one of the Joker Dooms]
         LDA #$07
         BRA C21765
C21734:  CMP #$51
         BCC C21763     ;branch if spell # is below Fire Skean.  iow, branch
                        ;if Slot's summoning an Esper.
         CMP #$FE
         BNE C21741     ;Branch if not Lagomorph
         LDA #$07
         STA $3401      ;Set to display text 7
C21741:  CPY #$08       ;Magic command enters here
         BCS C2175F     ;Branch if attacker is monster
         LDA $3ED8,Y
         CMP #$00
         BNE C2175F     ;Branch if not Terra
         LDA #$02
         TRB $3EBC      ;Clear bit for that classic Terra/Locke/Edgar
                        ;"M..M..Magic" skit, as it only happens once.
                        ;Keep in mind the game will also clear this when
                        ;exiting Figaro Cave to the South Figaro plains.
         BEQ C2175F     ;If it wasn't set, skip the special spellcast
                        ;and the ensuing convo
         LDX #$06       ;Attack
         LDA #$23       ;Command is Battle Event, and Attack in X indicates
                        ;it's number 6, Terra/Locke/Edgar "M..M..Magic"
         JSR C24E91     ;queue it, in global Special Action queue
         LDA #$20
         TSB $11A4      ;Set can't be dodged
C2175F:  LDA #$00       ;Lore / Enemy attack / Magitek commands enter here
         BRA C21765
C21763:  LDA #$02       ;Summon enters here
C21765:  STA $3412      ;depending on how we reached here, will display
                        ;various things atop the screen: an Esper Summon
                        ;a Magic spell, Lore, enemy attack/spell, Magitek
                        ;attack, Dance move, a Slot move [aside from
                        ;Lagomorph and Joker Doom], or "Storm"; "Health" or
                        ;"Shock"; or "Joker Doom"
         TYX
         LDA $B6
         JSR C219C1     ;Load data for command and attack/sub-command, held
                        ;in $B5 and A
         JSR C22951     ;Load Magic Power / Vigor and Level
         LDA $B5
         CMP #$0F
         BNE C2177A     ;branch if command is not Slot
         STZ $11A5      ;Set MP cost to 0
C2177A:  JMP C2317B     ;entity executes one hit


;Dance

C2177D:  LDA $3EF8,Y
         ORA #$01
         STA $3EF8,Y    ;Set Dance status
         LDA #$FF
         STA $B7        ;default animation to not affecting background
         LDA $32E1,Y    ;Which dance is selected for this character
         BPL C21794     ;branch if already defined
         LDA $3A6F      ;if not, read a "global" dance variable set
                        ;by last character to choose Dance
         STA $32E1,Y    ;and save it as this character's dance
C21794:  LDX $11E2
         CMP $ED8E5B,X  ;Check if current background is associated with
                        ;this dance
         BEQ C21741     ;Branch if it is
         JSR C24B53     ;random, 0 or 1 in Carry
         BCC C217AF     ;50% chance of branch and stumble
         TAX
         LDA $D1F9AB,X  ;get default background for this Dance
         STA $B7        ;set it in animation
         STA $11E2      ;and change current background to it
         JMP C21741     ;BRA C21741?


;Stumble when trying to dance

C217AF:  LDA $3EF8,Y
         AND #$FE
         STA $3EF8,Y    ;Clear Dance status
         TYX
         LDA #$06
         STA $3401      ;Set to display stumble message
         LDA #$20
         STA $B5        ;set command for animation purposes to Stumble?
         JSR C2298D     ;Load placeholder command data, and clear special
                        ;effect, magic power, etc.
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Attack Battle Power = sum of battle power of Umaro's hands.  initialize various
; other stuff.)

C217C7:  JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         CLC
         LDA $3B68,X    ;Battle Power for 1st hand
         ADC $3B69,X    ;add Battle Power for 2nd hand
         BCC C217D5
         LDA #$FF       ;if sum overflowed, treat combined Battle Power
                        ;as 255
C217D5:  STA $11A6      ;Battle Power or Spell Power
         LDA $3B18,X    ;attacker Level
         STA $11AF      ;attack's Level
         LDA $3B2C,X    ;attacker Vigor * 2
         STA $11AE      ;attack's Vigor * 2 or Magic Power
         RTS


;Possess

C217E5:  TYX
         JSR C219C1     ;Load data for command held in $B5, and data of
                        ;"Battle" spell
         LDA #$20
         TSB $11A4      ;Set can't be dodged
         LDA #$A0
         STA $11A9      ;Stores Possess in special effect
         JMP C2317B     ;entity executes one hit


;Jump

C217F6:  TYX
         JSR C219C1     ;Load data for command held in $B5, and data of
                        ;"Battle" spell
         LDA $3B69,X    ;Battle Power - left hand
         BEQ C21808     ;if no battle power, call subfunction with carry unset
                        ;to indicate right hand
         SEC            ;set carry to indicate left hand
         LDA $3B68,X    ;Battle Power - right hand
         BEQ C21808     ;if no bat pwr, call subfunction with carry set
         JSR C24B53     ;0 or 1 RNG - if both hands have weapon, carry flag
                        ;will select hand used
C21808:  JSR C2299F     ;Load weapon data into attack data.
                        ;Plus Sniper Sight, Offering and more.
         LDA #$20
         STA $11A4      ;Set can't be dodged only
         TSB $B3        ;Set ignore attacker row
         INC $BD        ;Increment damage.  since $BD is zeroed right before
                        ;this in function C2/13D3, it should be 1 now.
         LDA $3CA8,X    ;Weapon in right hand
         JSR C21512     ;Set $BD, turn-wide damage incrementor, to 2 if spear
         LDA $3CA9,X    ;Weapon in left hand
         JSR C21512     ;Set $BD, turn-wide damage incrementor, to 2 if spear
         LDA $3C44,X
         BPL C2183C     ;Branch if not jump continously [Dragon Horn]
         DEC $3A8E      ;make a variable FFh to indicate the attack is
                        ;a continuous jump
         JSR C24B5A     ;random: 0 to 255
         INC $3A70      ;Add 1 attack
         CMP #$40
         BCS C2183C     ;75% chance branch
         INC $3A70      ;Add 1 attack
         CMP #$10
         BCS C2183C     ;75% chance branch - so there's a 1/16 overall
                        ;chance of 4 attacks
         INC $3A70      ;Add 1 attack
C2183C:  LDA $3EF9,X
         AND #$DF
         STA $3EF9,X    ;Clear Hide status
         JMP C2317B     ;entity executes one hit (loops for multiple-strike
                        ;attack)


;Swdtech

C21847:  TYX
         LDA $B6        ;Battle animation
         PHA            ;Put on stack
         SEC
         SBC #$55
         STA $B6        ;save unique index of the SwdTech.  0 = Dispatch,
                        ;1 = Retort, etc.
         PLA
         JSR C219C1     ;Load data for command and attack/sub-command, held
                        ;in $B5 and A
         JSR C22951     ;Load Magic Power / Vigor and Level
         LDA $B6
         CMP #$01
         BNE C2187D     ;branch if not Retort
         LDA $3E4C,X
         EOR #$01
         STA $3E4C,X    ;Toggle Retort condition
         LSR
         BCC C21879     ;branch if we're doing the actual retaliation
                        ;as opposed to the preparation
         ROR $B6        ;$B6 is now 80h
         STZ $11A6      ;Sets power to 0
         LDA #$20
         TSB $11A4      ;Set can't be dodged
         LDA #$01
         TRB $11A2      ;Sets to magical damage
         BRA C21882
C21879:  LDA #$10
         TRB $B0        ;???  See functions C2/13D3 and C2/57C2 for usual
                        ;purpose; dunno whether it does anything here.
C2187D:  LDA #$04
         STA $3412      ;will display a SwdTech name atop screen
C21882:  JMP C2317B     ;entity executes one hit (loops for multiple-strike
                        ;attack)


;Tools

C21885:  LDA $B6
         SBC #$A2       ;carry was clear, so subtract 163
         STA $B6        ;save unique Tool index.  0 = NoiseBlaster,
                        ;1 = Bio Blaster, etc.
         BRA C2189E
 

;<>Throw

C2188D:  LDA #$02
         STA $BD        ;Increment damage by 100%
         LDA #$10
         TRB $B3        ;Clear Ignore Damage Increment on Ignore Defense
         BRA C2189E
 

;<>Item

C21897:  STZ $3414      ;Set ignore damage modification
         LDA #$80
         TRB $B3        ;Set Ignore Clear
C2189E:  TYX
         LDA #$01
         STA $3412      ;will display an Item name atop screen
         LDA $3A7D
         JSR C219C1     ;Load data for command and attack/sub-command, held
                        ;in $B5 and A
         LDA #$10
         TRB $B1        ;clear "don't deplete from Item inventory" flag
         BNE C218B5     ;branch if it was set
         LDA #$FF
         STA $32F4,X    ;null item index to add to inventory.  this means
                        ;the item will stay deducted from your inventory.
C218B5:  LDA $3018,X
         TSB $3A8C      ;flag character to have any applicable item in
                        ;$32F4,X added back to inventory when turn is over.
         LDA $B5        ;Command #
         BCC C218E3     ;Carry is set (by the $19C1 call for:
                        ; - Skeans/Tools that don't use a spell
                        ; - normal Item usage
                        ;which means it isn't set for:
                        ; - Equipment Magic or Skeans/Tools that do use a spell
         CMP #$02       ;Carry will now be set if Command >=2, so for Throw and
                        ;Tools, but not plain Item
         LDA $3411      ;get item #
         JSR C22A37     ;item usage setup
         LDA $11AA
         BIT #$C2       ;Check if Dead, Petrify or Zombie attack
         BNE C218E0     ;if so, branch
         REP #$20       ;Set 16-bit Accumulator
         LDA $3A74      ;alive and present characters [non-enemy] and monsters
         ORA $3A42      ;list of present and living characters acting
                        ;as enemies?
         AND $B8        ;clear targets that are in none of above categories
         STA $B8
         SEP #$20       ;Set 8-bit Accumulator
         LDA #$04
         TRB $B3        ;prevents "Retarget if target invalid" at C2/31C5
C218E0:  JMP C2317B     ;entity executes one hit


C218E3:  CMP #$01       ;is command Item?
         BNE C218EE
         INC $B5        ;if so, bump it up to Magic, as we've reached this
                        ;point thanks to Equipment Magic
         LDA $3410      ;get spell #
         STA $B6
C218EE:  STZ $BD        ;if we reached here for Throw, it's for a Skean
                        ;casting magic, so zero out the Damage Increment
                        ;given by the Throw command.
         JSR C22951     ;Load Magic Power / Vigor and Level
         LDA #$02
         TSB $11A3      ;Set Not reflectable
         LDA #$20
         TSB $11A4      ;Set unblockable
         LDA #$08
         TRB $BA        ;Clear "can target dead/hidden targets"
         STZ $11A5      ;Set MP cost to 0
         JMP C2317B     ;entity executes one hit


;GP Rain

C21907:  TYX
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         INC $11A6      ;Set spell power to 1
         LDA #$60
         TSB $11A2      ;Set ignore defense, no split damage
         STZ $3414      ;Skip damage modification
         CPX #$08
         BCC C2191F     ;branch if character
         LDA #$05
         STA $3412      ;will display "GP Rain" atop screen.
                        ;differentiated from "Health" and "Shock"
                        ;by $B5 holding command 18h in this case.
C2191F:  LDA #$A2
         STA $11A9      ;Store GP Rain in special effect
         JMP C2317B     ;entity executes one hit


;Revert

C21927:  LDA $3EF9,Y
         BIT #$08
         BNE C21937     ;Branch if Morphed
C2192E:  TYA
         LSR
         XBA
         LDA #$0E
         JMP C262BF


;Morph

C21936:  SEC            ;tell upcoming shared code it's Morph, not Revert
C21937:  PHP
         TYX
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         PLP
         LDA #$08
         STA $11AD      ;mark attack to affect Morph status
         BCC C21945     ;branch if we're running Revert
         TDC
C21945:  LSR
         TSB $11A4      ;if Carry was clear, turn on Lift Status property.
                        ;otherwise, the attack will just default to setting
                        ;the status.
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Row

C2194C:  TYX
         LDA $3AA1,X
         EOR #$20
         STA $3AA1,X    ;Toggle Row
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Runic

C2195B:  TYX
         LDA $3E4C,X
         ORA #$04
         STA $3E4C,X    ;Set runic
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Defend

C2196A:  TYX
         LDA #$02
         JSR C25BAB     ;set Defending flag
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Control

C21976:  LDA $3EF9,Y
         BIT #$10
         BEQ C21987     ;Branch if no spell/chant status
         JSR C2192E
         LDA $32B8,Y    ;Get whom this entity controls
         TAY
         JMP C21554     ;Commands code


C21987:  TYX
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         LDA #$A6
         STA $11A9      ;Store control in special effect
         LDA #$01
         TRB $11A2      ;Sets to magical damage
         LDA #$20
         TSB $11A4      ;Sets unblockable
         JMP C2317B     ;entity executes one hit


;Leap

C2199D:  TYX
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         LDA #$A8
         STA $11A9      ;Store Leap in special effect
         LDA #$01
         TRB $11A2      ;Sets to magical damage
         LDA #$40
         STA $BB        ;Sets to Cursor start on enemy only
         JMP C2317B     ;entity executes one hit


;Enemy Roulette

C219B2:  LDA #$0C
         STA $B5        ;Sets command to Lore
         JSR C2175F
         LDA #$21
         XBA
         LDA #$06
         JMP C262BF


;Load data for command and attack/sub-command, passed in $B5 and A, respectively

C219C1:  XBA
         LDA $B5
         JMP C226D3     ;Load command and attack/sub-command data,
                        ;takes parameters in A.bottom and A.top


;Code pointers for commands; special commands start at C2/1A03

C219C7: dw C215C8     ;(Fight)
      : dw C21897     ;(Item)
      : dw C21741     ;(Magic)
      : dw C21936     ;(Morph)
      : dw C21927     ;(Revert)
      : dw C21591     ;(Steal)   (05)
      : dw C21610     ;(Capture)
      : dw C21847     ;(Swdtech)
      : dw C2188D     ;(Throw)
      : dw C21885     ;(Tools)
      : dw C2159D     ;(Blitz)   (0A)
      : dw C2195B     ;(Runic)
      : dw C2175F     ;(Lore)
      : dw C2151F     ;(Sketch)
      : dw C21976     ;(Control)
      : dw C21726     ;(Slot)
      : dw C21560     ;(Rage)    (10)
      : dw C2199D     ;(Leap)
      : dw C2151E     ;(Mimic)
      : dw C2177D     ;(Dance)
      : dw C2194C     ;(Row)
      : dw C2196A     ;(Def.)    (15)
      : dw C217F6     ;(Jump)
      : dw C21741     ;(X-Magic)
      : dw C21907     ;(GP Rain)
      : dw C21763     ;(Summon)
      : dw C2171E     ;(Health)  (1A)
      : dw C2171A     ;(Shock)
      : dw C217E5     ;(Possess)
      : dw C2175F     ;(Magitek)
      : dw C219B2     ;(1E) (Enemy Roulette)
      : dw C2151E     ;(1F) (Jumps to RTS)
      : dw C25072     ;(20) (#$F2 Command script)
      : dw C250D1     ;(21) (#$F3 Command script)
      : dw C2500B     ;(22) (Poison, Regen, and Seizure/Phantasm damage or healing)
      : dw C24F57     ;(23) (#$F7 Command script)
      : dw C24F97     ;(24) (#$F5 Command script)
      : dw C250CD     ;(25)
      : dw C24F5F     ;(26) (Doom cast when Condemned countdown reaches 0; Safe, Shell, or
                      ;      Reflect* cast when character enters Near Fatal (* no items
                      ;      actually do this, but it's supported); or revival due to Life 3.
      : dw C250DD     ;(27) (Display Scan info)
      : dw C2151E     ;(28) (Jumps to RTS)
      : dw C25161     ;(29) (Remove Stop, Reflect, Freeze, or Sleep when time is up)
      : dw C220DE     ;(2A) (Run)
      : dw C2642D     ;(2B) (#$FA Command script)
      : dw C251A8     ;(2C)
      : dw C251B2     ;(2D) (Drain from being seized)
      : dw C21DFA     ;(2E) (#$F8 Command script)
      : dw C21E1A     ;(2F) (#$F9 Command script)
      : dw C21E5E     ;(30) (#$FB Command script)
      : dw C2151E     ;(31) (Jumps to RTS)
      : dw C2151E     ;(32) (Jumps to RTS)
      : dw C2151E     ;(33) (Jumps to RTS)


;Process a monster's main or counterattack script, backing up targets first

C21A2F:  PHX
         PHP
         LDA $B8        ;get targets
         STA $FC        ;save as working copy
         STA $FE        ;and as backup copy
         SEP #$20
         STZ $F5        ;start at sub-block index 0 in this
                        ;main script or counterattack script
         STX $F6        ;save target # of entity running script
         JSR C21AAF     ;go parse the script and do commands
         PLP
         PLX
C21A42:  RTS


;Read command script, up through an FEh or FFh command, advancing position in X

C21A43:  TDC
C21A44:  LDA $CF8700,X  ;read first byte of command
         INX
         CMP #$FE
         BCS C21A42     ;Exit if #$FE or #$FF - Done with commands
         SBC #$EF       ;subtract F0h
         BCC C21A44     ;Branch if not a control command
         PHX
         TAX
         LDA C21DAF,X   ;# of bytes in the control command
         PLX
         DEX
C21A59:  INX
         DEC
         BNE C21A59     ;loop through the whole command to reach
                        ;the next one
         BRA C21A44     ;go read the first byte of next command


;Read 4 bytes from command script (without advancing script position

C21A5F:  PHP
         REP #$20
         LDX $F0        ;get current script position
         LDA $CF8702,X
         STA $3A2E
         LDA $CF8700,X  ;Command scripts
         STA $3A2C
         PLP
         RTS


;Command Script #$FD

C21A74:  REP #$20       ;Set 16-bit Accumulator
         LDA $F0
         STA $F2        ;save current script address as left-off-at
                        ;address
         RTS


;Command Script #$FE and #$FF

C21A7B:  LDA #$FF
         STA $F5        ;null sub-block index, so caller of $1A2F
                        ;doesn't think we left off anywhere
         RTS


;Pick which attack of three to use; FEh will do nothing and exit caller

C21A80:  LDA #$03
         JSR C24B65     ;random #: 0 to 2
         TAX
         LDA $3A2D,X    ;Byte 1 to 3 of 4-byte command
         CMP #$FE
         BNE C21A42     ;Exit if not FEh
         PLA
         PLA            ;remove caller address from stack
         BRA C21AB4     ;resume parsing script


;Command Script #$FC
;Also handles bulk of the script-parsing logic, with additional entry points at
; C2/1AAF and C2/1AB4.)

C21A91:  LDA $3A2D      ;Byte 1 of command
         ASL
         TAX
         JSR (C21D55,X) ;Do an FC subcommand, which is an If Statement
                        ;of various conditions
         BCS C21AB4     ;branch if it passed as True
C21A9B:  REP #$30       ;Set 16-bit A, X, & Y
         LDA $FE
         STA $FC        ;copy backup targets to working targets
         SEP #$20       ;Set 8-bit A
         LDX $F0        ;get script position to start reading from
         JSR C21A43     ;Read command script, up through an FEh or FFh
                        ;command, advancing position in X
         INC
         BEQ C21A7B     ;branch if FFh command was last thing read
         STX $F0        ;save script position of next command
         INC $F5        ;increment current sub-block index
C21AAF:  LDA $3A98
         STA $F8        ;save whether caller [C2/02DC or C2/4BF4] is
                        ;preventing most types of script commands:
                        ;00h = no, FFh = yes.
                        ;a couple commands can override this.
C21AB4:  SEP #$20       ;Set 8-bit Accumulator
         REP #$10       ;Set 16-bit X & Y
         JSR C21A5F     ;Read 4 bytes from command script, w/o advance
         CMP #$FC       ;compare the first one to FCh
         BCS C21AD0     ;Branch if command is FCh or higher
         LDA $F5        ;current sub-block index, where a sub-block is a
                        ;portion of script ending with an FEh or FFh.
         CMP $F4        ;compare to the sub-block we left off at due to
                        ;an FD command.  there are separate "bookmarks"
                        ;for the main and counterattack scripts.
         BNE C21AD0     ;branch if they don't match
         LDA #$FF
         STA $F4        ;null left-off-at sub-block index, as we're
                        ;already resuming in the one we sought
         LDX $F2        ;get script position after last executed FDh
                        ;command.  there are separate "bookmarks" for the
                        ;main and counterattack scripts.
         STX $F0        ;make that our current script position
         JSR C21A5F     ;Read 4 bytes from command script, w/o advance
C21AD0:  TDC            ;A = 0
         SEC
         TXY            ;Y = script position
         LDA $3A2C      ;Command to execute
         SBC #$F0
         BCS C21ADC     ;Branch if control command
         LDA #$0F       ;if not control command, it'll be 1 byte long
C21ADC:  TAX
         LDA C21DAF,X   ;# of bytes in the command
         TAX
C21AE2:  INY
         DEX
         BNE C21AE2     ;loop, advancing Y by size of command
         STY $F0        ;save updated script position
         SEP #$10       ;Set 8-bit X, & Y
         LDA $F8
         BEQ C21AF5     ;if caller didn't disable most counter types,
                        ;or if we executed a FC 1C or a successful FC 12
                        ;in this sub-block on this script "visit",
                        ;branch
         LDA $3A2C      ;Command to execute
         CMP #$FC
         BCC C21A9B     ;branch if command is FBh or lower
C21AF5:  LDY $F6        ;get target # of entity running script
         LDA $3A2C      ;Command to execute
         CMP #$F0
         BCC C21B25     ;Branch if not control command; it's just an
                        ;attack/spell
         AND #$0F       ;get command # - F0h
         ASL
         TAX
         JMP (C21D8F,X) ;execute the command


;Command Script #$F6

C21B05:  LDA #$01
         XBA
         LDA $3A2D      ;Item or Throw
         BEQ C21B10     ;Branch if item
         LDA #$08
         XBA
C21B10:  LDA $3A2E      ;Item to use or throw
         STA $3A2D
         JSR C21A80      ;Pick which attack of three to use;¤%¤%¤% FEh will do
                        ;nothing and exit this function
         XBA
         BRA C21B28
 

;<>Command Script #$F4

C21B1C:  TDC
         JSR C21A80      ;Pick which attack of three to use;¤%¤%¤% FEh will do
                        ;nothing and exit this function
         BRA C21B28
 

;<>Command Script #$F0

C21B22:  JSR C21A80      ;Pick which attack of three to use;¤%¤%¤% FEh will do
                        ;nothing and exit this function
C21B25:  JSR C21DBF     ;choose a command based on attack #
C21B28:  TYX
         REP #$20
         PHA            ;Put on stack
         LDA $FC
         STA $B8
         LDA $3EE4,X
         BIT #$2000
         BEQ C21B3A     ;Branch if not Muddled
         STZ $B8        ;clear targets, so they can be chosen randomly
C21B3A:  PLA
         JSR C203B9     ;Swap Roulette to Enemy Roulette
         JSR C203E4     ;Determine command's "time to wait", recalculate
                        ;targets if there aren't any
         JSR C24EAD     ;queue command and attack.  script section we're
                        ;running [indicated by Bit 0 of $B1] determines
                        ;which of entity's queues used.
         JMP C21AB4     ;resume parsing script


;Command Script #$F1

C21B47:  LDA $3A2D      ;Script byte 1
         CLC
         JSR C21F25
         REP #$20
         LDA $B8
         STA $FC
         JMP C21AB4     ;resume parsing script


;Command Script #$F5

C21B57:  LDA $3A2F
         BNE C21B62     ;branch if command already has targets
         LDA $3019,Y
         STA $3A2F      ;if it doesn't, save the monster who issued command
                        ;as the target
C21B62:  LDA #$24
         BRA C21B78
 

;<>Command Script #$F3

C21B66:  LDA #$21
         BRA C21B78
 

;<>Command Script #$FB

C21B6A:  LDA #$30
         BRA C21B78
 

;<>Command Script #$F2

C21B6E:  LDA #$20
         BRA C21B78
 

;<>Command Script #$F8

C21B72:  LDA #$2E
         BRA C21B78
 

;<>Command Script #$F9

C21B76:  LDA #$2F
C21B78:  XBA
         LDA $3A2D
         XBA
         REP #$20       ;Set 16-bit Accumulator
         STA $3A7A
         LDA $3A2E
         STA $B8
         TYX
         JSR C24EAD
         JMP C21AB4     ;resume parsing script


;Command Script #$F7

C21B8E:  TYX
         LDA #$23
         STA $3A7A      ;command is Battle Event
         LDA $3A2D      ;script byte 1
         STA $3A7B      ;attack is index of Battle Event
         JSR C24EAD     ;queue it.  script section we're running [indicated
                        ;by Bit 0 of $B1] determines which of entity's
                        ;queues used.
         JMP C21AB4     ;resume parsing script


;Command Script #$FA

C21BA0:  TYX
         LDA $3A2D
         XBA
         LDA #$2B
         REP #$20
         STA $3A7A
         LDA $3A2E
         STA $B8
         JSR C24EAD
         JMP C21AB4     ;resume parsing script


;Command 06 for FC

C21BB7:  JSR C21D34     ;Set who to check for using command 17
         BCC C21BC7     ;Exit if no counter for command 17
         TDC
         LDA $3A2F
         XBA
         REP #$20
         LSR
         CMP $3BF4,Y    ;Compare HP vs. second byte * 128
C21BC7:  RTS


;Command 07 for FC

C21BC8:  JSR C21D34     ;Do command 17 for FC
         BCC C21BD6     ;Exit if no counter for command 17
         TDC
         LDA $3A2F      ;Second byte for FC
         REP #$20
         CMP $3C08,Y    ;Compare MP vs. second byte
C21BD6:  RTS


;Command 08 for FC

C21BD7:  JSR C21D34     ;Do command 17 for FC
         BCC C21C25     ;Exit if no counter for command 17
         LDA $3A2F      ;Second byte for FC
         CMP #$10
         BCC C21BEE     ;Branch if less than 10
         REP #$20
         LDA $3A74      ;list of present and living characters and enemies
         AND $FC
         STA $FC
         SEP #$20       ;Set 8-bit Accumulator
C21BEE:  LDA #$10
         TRB $3A2F      ;Second byte for FC
         REP #$20       ;Set 16-bit Accumulator
         BNE C21BFC     ;If FC over 10
         LDA #$3EE4
         BRA C21BFF
C21BFC:  LDA #$3EF8
C21BFF:  STA $FA
         LDX $3A2F      ;Second byte for FC
         JSR C21D2D     ;Set bit #X in A
         STA $EE
         LDY #$12
C21C0B:  LDA ($FA),Y
         BIT $EE
         BNE C21C16
         LDA $3018,Y
         TRB $FC
C21C16:  DEY
         DEY
         BPL C21C0B
         CLC
         LDA $FC
         BEQ C21C25
         JSR C2522A
         STA $FC
         SEC
C21C25:  RTS


;Command 09 for FC

C21C26:  JSR C21BD7     ;Do command 08 for FC
         JMP C21D26


;Command 1A for FC

C21C2C:  JSR C21D34     ;Do command 17 for FC
         BCC C21C3A
         LDA $3BE0,Y
         BIT $3A2F
         BNE C21C3A
         CLC
C21C3A:  RTS


;Command 03 for FC - Counter Item usage

C21C3B:  TYA
         ADC #$13
         TAY
C21C3F:  INY            ;Command 02 for FC - counter Spell usage - jumps here
C21C40:  TYX            ;Command 01 for FC - counter a command - jumps here
         LDY $3290,X    ;get $3290 or $3291 or $32A4, depending on where
                        ;we entered function.  this is the attacker index [or
                        ;in the case of reflection, the reflector] for the
                        ;the command/spell/item usage.
         BMI C21C53
         LDA $3D48,X    ;get $3D48 or $3D49 or $3D5C, depending on where we
                        ;entered function.  attack's Command/Spell/Item ID.
         CMP $3A2E      ;does it match first parameter in script?
         BEQ C21C55     ;branch if so
         CMP $3A2F      ;does it match second parameter in script?
         BEQ C21C55     ;branch if so
C21C53:  CLC
         RTS


C21C55:  REP #$20
         LDA $3018,Y    ;get target bit of attacker index
         STA $FC
         SEC
         RTS


;Command 04 for FC

C21C5E:  TYA
         ADC #$15
         TAX            ;could swap these 3 for "TYX" [and a needed "CLC"]
                        ;and use higher offsets below.  maybe this function
                        ;was once intended to handle more commands?
         LDY $3290,X    ;get attacker index.  [or in the case of reflection,
                        ;the reflector.]  accessed as $32A5 in C2/35E3.
         BMI C21C6F
         LDA $3D48,X    ;get attack's element(s.  accessed as $3D5D
                        ;in C2/35E3.
         BIT $3A2E      ;compare to script element(s) [1st byte for FC]
         BNE C21C55     ;branch if any matches
C21C6F:  RTS


;Command 05 for FC

C21C70:  TYX
         LDY $327C,X    ;last attacker [original, not any reflector] to do
                        ;damage to this target, not including the target
                        ;itself
         BMI C21C7E     ;branch if none
         REP #$20
         LDA $3018,Y
         STA $FC
         SEC
C21C7E:  RTS


;Command 16 for FC

C21C7F:  REP #$20
         LDA $3A44      ;get Global battle time counter
         BRA C21C8B
 

;<>Command 0B for FC

C21C86:  REP #$20
         LDA $3DC0,Y    ;get monster time counter
C21C8B:  LSR            ;divide timer by 2 before comparing to script
                        ;value
         CMP $3A2E
         RTS


;Command 0D for FC

C21C90:  LDX $3A2E      ;First byte for FC
         JSR C21E45     ;$EE = variable #X
         LDA $EE
         CMP $3A2F
         RTS


;Command 0C for FC

C21C9C:  JSR C21C90     ;Do command 0D for FC
         JMP C21D26


;Command 14 for FC

C21CA2:  LDX $3A2F      ;Second byte for FC
         JSR C21D2D     ;Set bit #X in A
         LDX $3A2E      ;First byte for FC
         JSR C21E45     ;$EE = variable #X
         BIT $EE
         BEQ C21CB3
         SEC
C21CB3:  RTS


;Command 15 for FC

C21CB4:  JSR C21CA2     ;Do command 14 for FC
         JMP C21D26


;Command 0F for FC

C21CBA:  JSR C21D34     ;Do command 17 for FC
         BCC C21CC5
         LDA $3B18,Y    ;Level
         CMP $3A2F
C21CC5:  RTS


;Command 0E for FC

C21CC6:  JSR C21CBA     ;Do command 0F for FC
         JMP C21D26


;Command 10 for FC

C21CCC:  LDA #$01
         CMP $3ECA      ;Only counter if one type of monster active
                        ;specifically, this variable is the number of
                        ;unique enemy names still active in battle.
                        ;it's capped at 4, since it's based on the
                        ;enemy list on the bottom left of the screen
                        ;in battle, but that limitation doesn't matter
                        ;since we're only comparing it to #$01 here.
         RTS


;Command 19 for FC

C21CD2:  LDA $3019,Y
         BIT $3A2E
         BEQ C21CDB
         SEC
C21CDB:  RTS


;Command 11 for FC

C21CDC:  JSR C21DEE     ;if first byte of FC command is 0,
                        ;set it to current monster
         LDA $3A75      ;list of present and living enemies
         BRA C21CEF
 

;<>Command 12 for FC

C21CE4:  STZ $F8        ;tell caller not to prohibit any script commands
                        ;will be of use if this one passes.
         JSR C21DEE     ;if first byte of FC command is 0,
                        ;set it to current monster
         LDA $3A73      ;bitfield of monsters in formation
         EOR $3A75      ;exclude present and living enemies
C21CEF:  AND $3A2E
         CMP $3A2E      ;does result include at least all targets marked
                        ;in first FC byte?
         CLC            ;default to false
         BNE C21CF9     ;exit if above answer is no
         SEC            ;return true
C21CF9:  RTS


;Command 13 for FC

C21CFA:  LDA $3A2E      ;First byte for FC
         BNE C21D06     ;branch if it indicates we're testing enemy party
         LDA $3A76      ;Number of present and living characters in party
         CMP $3A2F      ;Second byte for FC
         RTS

C21D06:  LDA $3A2F      ;Second byte for FC
         CMP $3A77      ;Number of monsters left in combat
         RTS


;Command 18 for FC

C21D0D:  LDA $1EDF
         BIT #$08       ;is Gau enlisted and not Leapt?
         BNE C21D15     ;branch if so
         SEC
C21D15:  RTS


;Command 1B for FC

C21D16:  REP #$20
         LDA $3A2E      ;First byte for FC
         CMP $11E0      ;Battle formation
         BEQ C21D21
         CLC
C21D21:  RTS


;Command 1C for FC

C21D22:  STZ $F8        ;tell caller not to prohibit any script commands
         SEC            ;always return true
         RTS


;Toggle the Carry Flag.  Will also zero Bit 7 of A for no good reason,
; but callers overwrite A afterwards anyway.)

C21D26:  SEP #$20
         ROL
         EOR #$01
         LSR            ;would change to ROR if we wanted
                        ;A unchanged
C21D2C:  RTS


;Sets bit #X in A (C2/1E57 and this are identical

C21D2D:  TDC
         SEC
C21D2F:  ROL
         DEX
         BPL C21D2F
         RTS


;Command 17 for FC

C21D34:  LDA $3A2E      ;Load first byte for FC
         PHA            ;Put on stack
         SEC
         JSR C21F25     ;Set target using first byte as parameter
         BCC C21D49     ;If invalid or no targets
         REP #$20       ;Set 16-bit Accumulator
         LDA $B8
         STA $FC
         JSR C251F9     ;Y = highest targest number * 2
         SEP #$21
C21D49:  PLA
         PHP
         CMP #$36
         BNE C21D53     ;Branch if not targeting self
         STZ $FC        ;Clear character targets
         STZ $FC        ;Clear them again.  why??
C21D53:  PLP
         RTS


;Code pointers for command #$FC

C21D55: dw C21D2C     ;(00) (No counter)
      : dw C21C40     ;(01) (Command counter)
      : dw C21C3F     ;(02) (Spell counter)
      : dw C21C3B     ;(03) (Item counter)
      : dw C21C5E     ;(04) (Elemental counter)
      : dw C21C70     ;(05) (Counter if damaged)
      : dw C21BB7     ;(06) (HP low counter)
      : dw C21BC8     ;(07) (MP low counter)
      : dw C21BD7     ;(08) (Status counter)
      : dw C21C26     ;(09) (Status counter (counter if not present))
      : dw C21D2C     ;(0A) (No counter)
      : dw C21C86     ;(0B) (Counter depending on time monster has been alive)
      : dw C21C9C     ;(0C) (Variable counter (less than))
      : dw C21C90     ;(0D) (Variable counter (greater than or equal to))
      : dw C21CC6     ;(0E) (Level counter (less than))
      : dw C21CBA     ;(0F) (Level counter (greater than or equal to))
      : dw C21CCC     ;(10) (Counter if only one type of monster alive)
      : dw C21CDC     ;(11) (Counter if target alive)
      : dw C21CE4     ;(12) (Counter if target dead (final attack))
      : dw C21CFA     ;(13) (if first byte is 0, check for # of characters, if 1, check for
                      ;       # of monsters
      : dw C21CA2     ;(14) (Variable bit check)
      : dw C21CB4     ;(15) (Variable bit check (inverse))
      : dw C21C7F     ;(16) (Counter depending on time combat has lasted)
      : dw C21D34     ;(17) (Aims like F1, Counter if valid target(s))
      : dw C21D0D     ;(18) (Counter if party hasn't gotten Gau (or Gau has leaped and is
                      ;       on Veldt)
      : dw C21CD2     ;(19) (Counter depending on monster # in formation)
      : dw C21C2C     ;(1A) (Weak vs. element counter)
      : dw C21D16     ;(1B) (Counter if specific battle formation)
      : dw C21D22     ;(1C) (Always counter (ignores Quick on other entity))


;Code pointers for control commands (monster scripts

C21D8F: dw C21B22     ;(F0)
      : dw C21B47     ;(F1)
      : dw C21B6E     ;(F2)
      : dw C21B66     ;(F3)
      : dw C21B1C     ;(F4)
      : dw C21B57     ;(F5)
      : dw C21B05     ;(F6)
      : dw C21B8E     ;(F7)
      : dw C21B72     ;(F8)
      : dw C21B76     ;(F9)
      : dw C21BA0     ;(FA)
      : dw C21B6A     ;(FB)
      : dw C21A91     ;(FC)
      : dw C21A74     ;(FD)
      : dw C21A7B     ;(FE)
      : dw C21A7B     ;(FF)


;# of bytes for control command

C21DAF: db $04   ;(F0)
      : db $02   ;(F1)
      : db $04   ;(F2)
      : db $03   ;(F3)
      : db $04   ;(F4)
      : db $04   ;(F5)
      : db $04   ;(F6)
      : db $02   ;(F7)
      : db $03   ;(F8)
      : db $04   ;(F9)
      : db $04   ;(FA)
      : db $03   ;(FB)
      : db $04   ;(FC)
      : db $01   ;(FD)
      : db $01   ;(FE)
      : db $01   ;(FF)


;Figure what type of attack it is (spell, esper, blitz, etc. , and
;return command in A

C21DBF:  PHX
         PHA            ;Put on stack
         XBA
         PLA            ;Spell # is now in bottom of A and top of A
         LDX #$0A
C21DC5:  CMP C21DD8,X   ;pick an attack category?
         BCC C21DD1     ;if attack is in a lower category, try the next one
         LDA C21DE3,X   ;choose a command
         BRA C21DD6
C21DD1:  DEX
         BPL C21DC5
         LDA #$02       ;if spell matched nothing in loop, it was between
                        ;0 and 35h, making it Magic command
C21DD6:  PLX
         RTS


;Data - used to delimit which spell #s are which command

C21DD8: db $36        ;(Esper)
      : db $51        ;(Skean)
      : db $55        ;(Swdtech)
      : db $5D        ;(Blitz)
      : db $65        ;(Dance Move)
      : db $7D        ;(Slot Move, or Tools??)
      : db $82        ;(Shock)
      : db $83        ;(Magitek)
      : db $8B        ;(Enemy Attack / Lore)
      : db $EE        ;(Battle, Special)
      : db $F0        ;(Desperation Attack, Interceptor)


;Data - the command #

C21DE3: db $19   ;(Summon)
      : db $02   ;(Magic)
      : db $07   ;(Swdtech)
      : db $0A   ;(Blitz)
      : db $02   ;(Magic)
      : db $09   ;(Tools)
      : db $1B   ;(Shock)
      : db $1D   ;(Magitek)
      : db $0C   ;(Lore)
      : db $00   ;(Fight)
      : db $02   ;(Magic)


;If first byte of FC command is 0, set it to current monster.

C21DEE:  LDA $3A2E
         BNE C21DF9
         LDA $3019,Y
         STA $3A2E
C21DF9:  RTS


;Variable Manipulation
;Operand in bottom 6 bits of $B8, Operation in top 2 bits.
; Bits 7 and 6 =
;  0 and 0, or 0 and 1: Set variable to operand
;  1 and 0: Add operand to variable
;  1 and 1: Subtract operand from variable)

C21DFA:  LDX $B6
         JSR C21E45     ;Load variable X into $EE
         LDA #$80
         TRB $B8        ;Clear bit 7 of byte 1
         BNE C21E0A     ;Branch if bit 7 of byte 1 was set
         LSR            ;A = 40h, Carry clear
         TRB $B8        ;Clear bit 6 of byte 1
         STZ $EE
C21E0A:  LDA $B8
         BIT #$40
         BEQ C21E13     ;Branch if bit 6 of byte 1 is clear
         EOR #$BF       ;Toggle all but bit 6.  that bit is on and
                        ;bit 7 was off, so this gives us:
                        ;192 + (63 - (bottom 6 bits of $B8)).  clever!
         INC            ;so A = 256 - (bottom 6 bits of $B8.
                        ;iow, the negation of the 6-bit value.
C21E13:  ADC $EE
         STA $EE
         JMP C21E38     ;Store $EE into variable X
                        ;BRA C21E38?


;Code for command #$2F (used by #$F9 monster script command

C21E1A:  LDX $B9        ;Byte 3
         JSR C21E57     ;Set only bit #X in A
         LDX $B8        ;Byte 2
         JSR C21E45     ;Load variable X into $EE
         DEC $B6        ;Byte 1: 0 for Toggle bit, 1 for Set bit,
                        ;2 for Clear bit
         BPL C21E2C
         EOR $EE
         BRA C21E38
C21E2C:  DEC $B6
         BPL C21E34
         ORA $EE
         BRA C21E38
C21E34:  EOR #$FF
         AND $EE
C21E38:  CPX #$24
         BCS C21E41
         STA $3EB0,X
         BRA C21E44
C21E41:  STA $3DAC,Y
C21E44:  RTS


;Load variable X into $EE

C21E45:  PHA            ;Put on stack
         CPX #$24
         BCS C21E4F
         LDA $3EB0,X
         BRA C21E52
C21E4F:  LDA $3DAC,Y
C21E52:  STA $EE
         PLA
         CLC
         RTS


;Sets bit #X in A (C2/1D2D and this are identical

C21E57:  TDC
         SEC
C21E59:  ROL
         DEX
         BPL C21E59
         RTS


;Monster command script command #$FB

C21E5E:  LDA $B6
         ASL
         TAX
         LDA $B8
         JMP (C21F09,X)


;Operation 0 for #$FB
;Clears monster time counter

C21E67:  TDC
         STA $3DC0,Y
         STA $3DC1,Y
         RTS


;Operation 9 for #$FB

C21E6F:  LDA #$0A
         BRA C21E75
C21E73:  LDA #$08       ;Operation 2 jumps here
C21E75:  STA $3A6E      ;"End of combat" method #8, monster script command
         RTS


;Operation 1 for #$FB

C21E79:  PHP
         SEC
         JSR C21F25
         REP #$20
         LDA $B8
         TSB $3A3C      ;mark target(s) as invincible
         PLP
         RTS


;Operation 5 for #$FB

C21E87:  PHP
         SEC
         JSR C21F25
         REP #$20
         LDA $B8
         TRB $3A3C      ;clear invincibility from target(s)
         PLP
         RTS


;Operation 6 for #$FB

C21E95:  SEC
         JSR C21F25
         LDA $B9
         TSB $2F46      ;make monster(s targetable again.  can undo
                        ;Operation 7 below, or untargetability
                        ;caused by formation data special event.
         RTS


;Operation 7 for #$FB

C21E9F:  SEC
         JSR C21F25
         LDA $B9
         TRB $2F46      ;make monster(s) untargetable
         RTS


;Operation 3 for #$FB

C21EA9:  LDA #$08
         TSB $1EDF      ;mark Gau as enlisted and not Leapt?
         LDA $3ED9,Y    ;0-15 roster position of this party member
         TAX
         LDA $1850,X    ;get character roster information
                        ;Bit 7: 1 = party leader, as set in non-overworld areas
                        ;Bit 6: main menu presence?
                        ;Bit 5: row, 0 = front, 1 = back
                        ;Bit 3-4: position in party, 0-3
                        ;Bit 0-2: which party in; 1-3, or 0 if none
         ORA #$40       ;turn on main menu presence?
         AND #$E0       ;keep party leader flag, main menu presence, and row
                        ;flag
         ORA $1A6D      ;combine with Active Party number [1-3]
         STA $EE
         TYA
         ASL
         ASL            ;convert target # into position in party
         ORA $EE
         STA $1850,X    ;save updated roster info
         RTS


;Operation 4 for #$FB

C21EC7:  STZ $3A44
         STZ $3A45      ;zero Global battle time counter
         RTS


;Operation 8 for #$FB
;Not used by any monster)

C21ECE:  SEC            ;don't exclude Dead/Hidden/etc entities
                        ;from targets
         JSR C21F25
         BCC C21ED9     ;branch if desired target(s) not found
         LDA #$FF
         STA $3AC9,Y    ;set top byte of own "Amount to increment
                        ;ATB Timer and Wait Timer" REALLY high.
                        ;iow, near-instantaneous ATB refill.
C21ED9:  RTS


;Operation C for #$FB
;Quietly lose status)

C21EDA:  JSR C21EEB     ;flag chosen status in attack data
         LDA #$04
         TSB $11A4      ;indicate Lift Status
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Operation B for #$FB
;Quietly gain status)

C21EE5:  JSR C21EEB     ;flag chosen status in attack data
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


C21EEB:  JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         CLC
         LDA $B8        ;Get status # of 0-31
         JSR C25217     ;X = A / 8, A = 2 ^ (A MOD 8)
         ORA $11AA,X
         STA $11AA,X    ;mark chosen status in attack's status
         TYX
         LDA #$12
         STA $B5        ;Store Mimic in command for animation
         RTS


;Operation D for #$FB

C21F00:  LDA $3EF9,Y
         ORA #$20
         STA $3EF9,Y    ;Set Hide status on self
C21F08:  RTS


;Code pointers for command #$FB

C21F09: dw C21E67  ;(00)
      : dw C21E79  ;(01)
      : dw C21E73  ;(02)
      : dw C21EA9  ;(03)
      : dw C21EC7  ;(04)
      : dw C21E87  ;(05)
      : dw C21E95  ;(06)
      : dw C21E9F  ;(07)
      : dw C21ECE  ;(08)
      : dw C21E6F  ;(09)
      : dw C21F08  ;(0A) (jumps to RTS)
      : dw C21EE5  ;(0B)
      : dw C21EDA  ;(0C)
      : dw C21F00  ;(0D)


C21F25:  PHX
         PHY
         PHA            ;Put on stack
         STZ $B8
         LDX #$06
C21F2C:  LDA $3ED8,X  ;Which character it is
         BMI C21F36   ;Branch if not present
         LDA $3018,X
         TSB $B8      ;Set character as target
C21F36:  DEX
         DEX
         BPL C21F2C
         STZ $B9      ;Set no monsters as target
         LDX #$0A
C21F3E:  LDA $2002,X
         BMI C21F48
         LDA $3021,X
         TSB $B9      ;Set monster as target
C21F48:  DEX
         DEX
         BPL C21F3E
         BCS C21F54
         JSR C25A4D   ;Remove dead and hidden targets
         JSR C25917
C21F54:  PLA
         CMP #$30
         BCS C21F6D
         LDX #$06
C21F5B:  CMP $3ED8,X  ;Which character it is
         BNE C21F67
         LDA $3018,X
         STA $B8
         BRA C21FA1
C21F67:  DEX
         DEX
         BPL C21F5B
         BRA C21F9F
C21F6D:  CMP #$36
         BCS C21F81
         SBC #$2F
         ASL
         TAX
         LDA $2002,X
         BMI C21F9F
         LDA $3021,X
         STA $B9
         BRA C21FA8
C21F81:  SBC #$36
         ASL
         TAX
         JMP (C22065,X)


;44

C21F88:  STZ $B9
C21F8A:  REP #$20
         LDA $B8
         JSR C2522A  ;randomly pick a bit that is set
         STA $B8
C21F93:  REP #$20    ;46 jumps here
         LDA $B8
         SEP #$21    ;set 8-bit Accumulator, and
                      ;set Carry
         BNE C21F9C
         CLC
C21F9C:  PLY
         PLX
         RTS

;47

C21F9F:  STZ $B8
C21FA1:  STZ $B9     ;43 jumps here
         BRA C21F93
 
;37

C21FA5:  JSR C2202D
C21FA8:  STZ $B8     ;38 jumps here
         BRA C21F93
 
;39

C21FAC:  JSR C2202D
C21FAF:  STZ $B8     ;3A jumps here
         BRA C21F8A
 
;3B

C21FB3:  JSR C22037
         BRA C21FA1
 
;3C

C21FB8:  JSR C22037
         BRA C21F88
 
;3D

C21FBD:  JSR C22037
         BRA C21FA8
 
;3E

C21FC2:  JSR C22037
         BRA C21FAF
 
;3F

C21FC7:  JSR C2204E
C21FCA:  BRA C21FA1
 
;40

C21FCC:  JSR C2204E
         BRA C21F88
 
;41

C21FD1:  JSR C2204E
         BRA C21FA8
 
;42

C21FD6:  JSR C2204E
         BRA C21FAF
 
;4C

C21FDB:  JSR C2202D     ;Remove self as target
         JSR C24B53     ;random: 0 or 1 in Carry
         BCC C21F8A
         BRA C21F93
 
;4D

C21FE5:  LDX $32F5,Y
         BMI C21F9F     ;No targets
         LDA #$FF
         STA $32F5,Y
         REP #$20
         LDA $3018,X
         STA $B8
         JSR C25A4D     ;Remove dead and hidden targets
         BRA C21F93
 
;45

C21FFB:  STZ $B8
         STZ $B9
         LDA $32E0,Y    ;get last entity to attack monster.
                        ;0-9 indicates a valid previous attacker.
                        ;7Fh indicates no previous attacker.
         CMP #$0A
         BCS C21F93     ;branch if no previous attacker
         ASL
         TAX            ;turn our 0-9 index into the more common
                        ;0,2,4,6,8,10,12,14,16,18 index used to
                        ;address battle entities.
         REP #$20
         LDA $3018,X
         STA $B8
         BRA C21F93
 

;48) (49) (4A) (4B

C22011:  TXA
         SEC
         SBC #$24
         TAX
         LDA $3AA0,X
         LSR
         BCC C21F9F
         LDA $3018,X
         STA $B8
         BRA C21FCA
 
;36

C22023:  REP #$20
         LDA $3018,Y
         STA $B8
         JMP C21F93


;Remove self as target

C2202D:  PHP
         REP #$20
         LDA $3018,Y
         TRB $B8
         PLP
         RTS


;Sets targets to all dead monsters and characters

C22037:  PHP            ;Set 16-bit Accumulator
         REP #$20
         STZ $B8        ;start off with no targets
         LDX #$12
C2203E:  LDA $3EE3,X
         BPL C22048     ;Branch if not dead
         LDA $3018,X
         TSB $B8        ;mark entity as target
C22048:  DEX
         DEX
         BPL C2203E     ;loop for all entities
         PLP
         RTS


;Sets all monsters and characters with Reflect status as targets

C2204E:  PHP
         REP #$20       ;Set 16-bit Accumulator
         STZ $B8        ;start off with no targets
         LDX #$12
C22055:  LDA $3EF7,X
         BPL C2205F     ;Branch if not Reflect status
         LDA $3018,X
         TSB $B8        ;mark entity as target
C2205F:  DEX
         DEX
         BPL C22055     ;loop for all entities
         PLP
         RTS


;Code pointers for command F1 targets

C22065: dw C22023     ;(36)
      : dw C21FA5     ;(37)
      : dw C21FA8     ;(38)
      : dw C21FAC     ;(39)
      : dw C21FAF     ;(3A)
      : dw C21FB3     ;(3B)
      : dw C21FB8     ;(3C)
      : dw C21FBD     ;(3D)
      : dw C21FC2     ;(3E)
      : dw C21FC7     ;(3F)
      : dw C21FCC     ;(40)
      : dw C21FD1     ;(41)
      : dw C21FD6     ;(42)
      : dw C21FA1     ;(43)
      : dw C21F88     ;(44)
      : dw C21FFB     ;(45)
      : dw C21F93     ;(46)
      : dw C21F9F     ;(47)
      : dw C22011     ;(48)
      : dw C22011     ;(49)
      : dw C22011     ;(4A)
      : dw C22011     ;(4B)
      : dw C21FDB     ;(4C)
      : dw C21FE5     ;(4D)


;Recalculate applicable characters' properties from their current equipment and relics

C22095:  LDX #$03
C22097:  LDA $2F30,X    ;was character flagged to have his/her properties be
                        ;recalculated from his/her equipment at end of turn?
         BEQ C220DA     ;skip to next character if not
         STZ $2F30,X    ;clear this character's flag
         PHX
         PHY
         TXA
         STA $EE
         ASL
         STA $EF        ;save X * 2
         ASL
         ADC $EE
         TAX            ;X = X * 5
         LDA $2B86,X    ;character's right hand in menu data
         XBA
         LDA $2B9A,X    ;character's left hand in menu data
         LDX $EF
         REP #$10       ;Set 16-bit X and Y
         LDY $3010,X    ;get offset to character info block
         STA $1620,Y    ;save contents of left hand in main character block
         XBA
         STA $161F,Y    ;save contents of right hand in main character block
         LDA $3EE4,X    ;in-battle Status Byte 1
         STA $1614,Y    ;update outside battle Status Byte 1
         SEP #$10       ;Set 8-bit X and Y
         LDA $3ED9,X    ;0-15 roster position of this party member
         JSL C20E77     ;load equipment data for character in A
         JSR C2286D     ;Initialize in-battle character properties from
                        ;equipment properties
         JSR C2527D     ;Update availability of commands on character's
                        ;main menu - gray out or enable
         JSR C22675     ;make some equipment statuses permanent by setting
                        ;immunity to them.  also handle immunity to mutually
                        ;exclusive "mirror statuses".
         PLY
         PLX
C220DA:  DEX
         BPL C22097     ;loop for all 4 onscreen characters
         RTS


;Command #$2A
;Flee, or fail to, from running)

C220DE:  LDA $2F45      ;party trying to run: 0 = no, 1 = yes
         BEQ C22162     ;exit if not trying to run
         REP #$20
         LDA #$0902
         STA $3A28      ;default some animation variable to unsuccessful
                        ;run?
                        ;temporary bytes 1 and 2 for ($76) animation buffer
         SEP #$20
         LDA $B1
         BIT #$02       ;is Can't Run set?
         BNE C2215F     ;branch if so
         LDA $3A38      ;characters who are ready to run
         BEQ C22162     ;branch if none
         STA $B8        ;save copy of ready to run characters
         STZ $3A38      ;clear original list
         JSR C26400     ;Zero $A0 through $AF
         LDX #$06
C22102:  LDA $3018,X
         TRB $B8        ;remove current party member from copy list
                        ;of ready to run characters
         BEQ C22144     ;skip to next party member if they were
                        ;never in it
         XBA
         LDA $3219,X    ;top byte of ATB timer, which is zeroed
                        ;when the gauge is full
         BNE C22144     ;it it's nonzero, the gauge isn't full,
                        ;so skip to next party member
         LDA $3AA0,X
         BIT #$50       ;???
         BNE C22144
         LSR            ;is entity even present in the battle?
         BCC C22144     ;skip to next party member if not
         LDA $3EE4,X
         BIT #$02       ;Check for Zombie status
         BNE C22144     ;branch if possessed
         LDA $3EF9,X
         BIT #$20
         BNE C22144     ;Branch if Hide status
         XBA
         TSB $B8        ;tell this function character is successfully
                        ;running
         TSB $3A39      ;add to list of escaped characters
         TSB $2F4C      ;mark runner to be removed from the battlefield
         LDA $3AA1,X
         ORA #$40
         STA $3AA1,X    ;Set bit 6 of $3AA1
         LDA $3204,X
         ORA #$40
         STA $3204,X    ;set bit 6 of $3204
         JSR C207C8     ;Clear Zinger, Love Token, and Charm bonds, and
                        ;clear applicable Quick variables
         TXY
C22144:  DEX
         DEX
         BPL C22102     ;loop for all 4 party members
         LDA $B8        ;get successfully running characters
         BEQ C22162     ;branch if none
         STZ $B9        ;no monster targets
         TYX
         JSR C257C2     ;Update $An variables with targets in $B8-$B9,
                        ;and do other stuff
         JSR C263DB     ;Copy $An variables to ($78) buffer
         REP #$20       ;set 16-bit Accumulator
         LDA #$2206
         STA $3A28      ;change some animation variable to successful run?
                        ;temporary bytes 1 and 2 for ($76) animation buffer
         SEP #$20       ;set 8-bit Accumulator
C2215F:  JSR C2629E     ;Copy $3A28-$3A2B variables into ($76) buffer
C22162:  RTS


;Process one record from Special Action linked list queue.  Note that unlike with
; other lists, all entities here are mingled together.)

C22163:  PEA.w C20019-1 ;will return to C2/0019
         PHA            ;Put on stack
         ASL
         TAY            ;adjust pointer for 16-bit fields
         CLC
         JSR C20276     ;Load command, attack, targets, and MP cost from queued
                        ;data.  Some commands become Fight if tried by an Imp.
         PLA
         TAY            ;restore pointer for 8-bit fields
         LDA $3184,Y    ;get ID/pointer of first record in Special Action linked
                        ;list queue
         CMP $340A      ;if that field's contents match record's position, it's
                        ;a standalone record, or the last in the list
         BNE C22179     ;branch if not, as there are more records left
         LDA #$FF
C22179:  STA $340A      ;either make entry point index next record, or null it
         LDA #$FF
         STA $3184,Y    ;null current first record in Special Action linked list
                        ;queue
         LDA #$01
         TSB $B1        ;indicate it's an unconventional attack
         JMP C213D3     ;Character/Monster Takes One Turn


;Do early processing of one record from entity's conventional linked list queue, establish
; "time to wait", and visually enter ready stance if character)

C22188:  LDA #$80
         JSR C25BAB
         LDA $3AA0,X
         BIT #$50
         BNE C2220A
         LDA $3AA1,X
         AND #$7F       ;Clear bit 7
         ORA #$01       ;Set bit 0
         STA $3AA1,X
         JSR C2031C
         LDA $32CC,X    ;get entry point to entity's conventional linked list
                        ;queue
         BMI C2220A     ;exit if null
         ASL
         TAY            ;adjust pointer for 16-bit fields
         LDA $3420,Y    ;get command from entity's conventional linked list
                        ;queue
         CMP #$1E
         BCS C2220A     ;exit if not a normal character command.  iow,
                        ;if it was enemy Roulette, "Run Monster Script",
                        ;periodic damage/healing, etc.
         STA $2D6F      ;second byte of first entry of ($76) buffer
         CMP #$16       ;is it Jump?
         BEQ C221BC     ;branch if so
         CPX #$08
         BCC C221E6     ;branch if character
         BRA C2220A     ;it's a monster [with no visible ready stance],
                        ;so exit
C221BC:  LDA $3205,X
         BPL C2220A     ;Exit function if entity has not taken a conventional
                        ;turn [including landing one] since boarding Palidor
         REP #$20
         CPX #$08
         BCS C221D3     ;branch if monster, so it doesn't affect Mimic
         LDA #$0016
         STA $3F28      ;tell Mimic last command was Jump
         LDA $3520,Y    ;get targets from entity's conventional linked list
                        ;queue
         STA $3F2A      ;save last targets, Jump-specific, for Mimic
C221D3:  LDA $3018,X
         TSB $3F2C      ;mark entity as a Jumper
         SEP #$20
         LDA $3EF9,X
         ORA #$20
         STA $3EF9,X    ;Set Hide Status
         JSR C25D26     ;Copy Current and Max HP and MP, and statuses to
                        ;displayable variables
C221E6:  JSR C22639     ;Clear animation buffer pointers, extra strike
                        ;quantity, and various backup targets
         JSR C26400     ;Zero $A0 through $AF
         REP #$20
         LDA $3520,Y    ;get targets from entity's conventional linked list
                        ;queue
         STA $B8        ;save as current targets
         SEP #$20
         LDA #$0C
         STA $2D6E      ;first byte of first entry of ($76) buffer
         LDA #$FF
         STA $2D72      ;first byte of second entry of ($76) buffer
         JSR C257C2
         JSR C263DB     ;Copy $An variables to ($78) buffer
         LDA #$04
         JSR C26411     ;Execute animation queue
C2220A:  JMP C20019     ;branch to start of main battle loop


;Determine whether attack hits
;Result in Carry Flag: Clear = hit [includes Golem and Dog block], Set = miss)

C2220D:  PHA            ;Put on stack
         PHX
         CLC            ;start off assuming hit
         PHP            ;preserve Carry Flag, among others
         SEP #$20       ;set 8-bit accumulator
         STZ $FE
         LDA $B3
         BPL C22235     ;Skip Clear check if bit 7 of $B3 not set
         LDA $3EE4,Y
         BIT #$10       ;Check for Clear status
         BEQ C22235     ;Branch if not vanished
         LDA $11A4
         ASL
         BMI C2222D     ;Branch if L.X spell
         LDA $11A2
         LSR
         JMP C222B3     ;If physical attack then miss, otherwise hit
C2222D:  LDA $3DFC,Y
         ORA #$10
         STA $3DFC,Y    ;mark Clear status to be cleared.  that way,
                        ;it'll still be removed even if the attack
                        ;misses and C2/4406, which is what normally
                        ;removes Clear, is skipped.
C22235:  LDA $11A3
         BIT #$02       ;Check for not reflectable
         BNE C2224B     ;Branch if ^
         LDA $3EF8,Y
         BPL C2224B     ;Branch if target does not have Reflect
         REP #$20       ;set 16-bit accumulator
         LDA $3018,Y
         TSB $A6        ;turn on target in "reflected off of" byte
         JMP C222E5     ;Always miss if reflecting off target
C2224B:  LDA $11A2
         BIT #$02       ;Check for spell miss if instant death protected
         BEQ C22259     ;Branch if not ^
         LDA $3AA1,Y
         BIT #$04
         BNE C222B5     ;Always miss if Protected from instant death
C22259:  LDA $11A2
         BIT #$04       ;Check for hit only (dead XOR undead) targets
         BEQ C22268
         LDA $3EE4,Y
         EOR $3C95,Y    ;death status XOR undead attribute
         BPL C222B5     ;If neither or both of above set, then miss
C22268:  LDA $B5
         CMP #$00
         BEQ C22272     ;Branch if command is Fight
         CMP #$06
         BNE C222A1     ;Branch if command not Capture
C22272:  LDA $11A9
         BNE C222A1     ;Branch if has special effect
         LDA $3EC9
         CMP #$01
         BNE C222A1     ;branch if # of targets isn't 1
         CPY #$08
         BCS C222A1     ;Branch if target is monster
         LDA $3EF9,Y
         ASL
         BPL C22293     ;Branch if not dog block
         JSR C24B53     ;0 or 1
         BCC C22293     ;50% chance
         LDA #$40
         STA $FE        ;set dog block animation flag
         BRA C222B5     ;Miss
C22293:  LDA $3A36
         ORA $3A37
         BEQ C222A1     ;Branch if no Golem
         LDA #$20
         STA $FE        ;set golem block animation flag
         BRA C222B5     ;Miss
C222A1:  LDA $11A4
         BIT #$20       ;Check for can't be dodged
         BNE C222E8     ;Always hit if can't be dodged
         BIT #$40
         BNE C222EC     ;Check if hit for L? Spells
         BIT #$10
         BEQ C222FB     ;Check if hit if Stamina not involved
         JSR C2239C     ;Check if hit if Stamina involved
C222B3:  BCC C222E8     ;branch if hits
C222B5:  LDA $3EE4,Y
         BIT #$1A       ;Check target for Clear, M-Tek, or Zombie
         BNE C222D1     ;Always miss if ^
         CPY #$08       ;Check if target is monster
         BCS C222D1     ;Always miss if ^
         JSR C223BF     ;Determine miss animation
         CMP #$06
         BCC C222D1     ;if it's not Golem or Dog Block, always miss
         LDX #$03
C222C9:  STZ $11AA,X    ;Clear all status modifying effects of attack
         DEX
         BPL C222C9
         BRA C222E8     ;Always hit [Carry will be cleared]
C222D1:  LDA #$02
         TSB $B2        ;Set no critical and ignore True Knight
         STZ $3A89      ;turn off random weapon spellcast
         LDA $341C      ;0 if current strike is missable weapon spellcast
         BEQ C222E5     ;if it is, skip flagging the "Miss" message,
                        ;since we'll be skipping the animation
                        ;entirely.
         REP #$20
         LDA $3018,Y
         TSB $3A5A      ;Set target as missed
C222E5:  PLP
         SEC            ;Makes attack miss
         PHP
C222E8:  PLP
         PLX
         PLA
         RTS


;Determines if attack hits for L? spells

C222EC:  LDX $11A8      ;Hit Rate
         TDC
         LDA $3B18,Y    ;Level
         JSR C24792     ;Division, X = Hit Rate MOD Level
         TXA
         BNE C222D1     ;Always miss
         BRA C222E8     ;Always Hit


;Determines if attack hits

C222FB:  PEA $8040      ;Sleep, Petrify
         PEA $0210      ;Freeze, Stop
         JSR C25864
         BCC C222E8     ;Always hit if any set
         REP #$20
         LDA $3018,Y
         BIT $3A54      ;Check if hitting in back
         SEP #$20       ;Set 8-bit A
         BNE C222E8     ;Always hit if hitting back of target
         LDA $11A8      ;Hit Rate
         CMP #$FF
         BEQ C222E8     ;Automatically hit if Hit Rate is 255
         STA $EE
         LDA $11A2
         LSR
         BCC C2233F     ;If Magic attack then skip this next code
         LDA $3E4C,Y
         LSR            ;Check for retort
         BCS C222E8     ;Always hits
         LDA $3EE5,Y    ;Check for image status
         BIT #$04

;--------------------------------------------------
;Original Code)

C2232C:  BEQ C2233F     ;Branch if not Image status on target
C2232E:  JSR C24B5A
C22331:  CMP #$40       ;1 in 4 chance clear Image status
C22333:  BCS C222D1     ;Always misses
C22335:  LDA $3DFD,Y
C22338:  ORA #$04
C2233A:  STA $3DFD,Y    ;Clear Image status
C2233D:  BRA C222D1     ;Always misses
C2233F:  LDA $3B54,Y    ;255 - Evade * 2 + 1
C22342:  BCS C22347
         LDA $3B55,Y    ;255 - MBlock * 2 + 1
C22347:  PHA            ;Put on stack
C22348:  BCC C22388
 

;Evade Patch Applied

;C2232C:  BEQ C22345     ;Branch if not Image status on target
;C2232E:  JSR C24B5A
;C22331:  CMP #$40       ;1 in 4 chance clear Image status
;C22333:  BCS C222D1     ;Always misses
;C22335:  LDA $3DFD,Y
;C22338:  ORA #$04
;C2233A:  STA $3DFD,Y    ;Clear Image status
;C2233D:  BRA C222D1     ;Always misses
;C2233F:  LDA $3B55,Y    ;255 - MBlock * 2 + 1
;C22342:  PHA            ;Put on stack
;         BRA C22388
 ;<>C22345:  LDA $3B54,Y    ;255 - Evade * 2 + 1
;C22348:  PHA            ;Put on stack
;         NOP

;-------------------------------------------------

         LDA $3EE4,X
         LSR
         BCC C22352     ;Branch if attacker not blinded [Dark status]
         LSR $EE        ;Cut hit rate in half
C22352:  LDA $3C58,Y
         BIT #$04
         BEQ C2235B     ;Branch if no Beads
         LSR $EE        ;Cut hit rate in half
C2235B:  PEA $2003      ;Muddled, Dark, Zombie
         PEA $0404      ;Life 3, Slow
         JSR C25864
         BCS C22372     ;Branch if none set on target
         LDA $EE
         LSR
         LSR
         ADC $EE        ;Adds 1/4 to hit rate
         BCC C22370
         LDA #$FF
C22370:  STA $EE        ;if hit rate overflowed, set to 255
C22372:  PEA $4204      ;Seizure, Near Fatal, Poison
         PEA $0008      ;Haste
         JSR C25864
         BCS C22388     ;Branch if none set on target
         LDA $EE
         LSR $EE
         LSR $EE
         SEC
         SBC $EE        ;Subtracts 1/4 from hit rate
         STA $EE
C22388:  PLA
         XBA
         LDA $EE        ;Hit Rate
         JSR C24781     ;Multiply Evade/Mblock * Hit Rate
         XBA
         STA $EE        ;High byte of Evade/Mblock * Hit Rate
         LDA #$64
         JSR C24B65     ;Random number 0 to 99
         CMP $EE
         JMP C222B3


;Check if hit if Stamina involved

C2239C:  LDA $3B55,Y    ;MBlock
         XBA
         LDA $11A8      ;Hit Rate
         JSR C24781     ;Multiplication Function
         XBA
         STA $EE        ;High byte of Mblock * Hit Rate
         LDA #$64
         JSR C24B65     ;Random Number 0 to 99
         CMP $EE
         BCS C223BE     ;Attack misses, so exit
C223B2:  JSR C24B5A     ;Random Number 0 to 255
         AND #$7F       ;0 to 127
         STA $EE
         LDA $3B40,Y    ;Stamina
         CMP $EE
C223BE:  RTS


;Dog/Golem/Equipment miss check

C223BF:  PHY
         LDA $11A2
         LSR
         BCS C223C7     ;Branch if physical attack
         INY            ;if it was magical, read from 3CE5,old_Y instead
C223C7:  TDC
         LDA $3CE4,Y    ;shield/weapon miss animations
         ORA $FE        ;miss due to Interceptor/Golem
         BEQ C223EB     ;Exit function if none of above
         JSR C2522A     ;Pick a random bit that is set
         BIT #$40
         BEQ C223D9     ;Branch if no dog protection
         STY $3A83      ;save character target in "Dog blocked" byte
C223D9:  BIT #$20
         BEQ C223E0     ;Branch if no Golem protection
         STY $3A82      ;save character target in "Golem blocked" byte
C223E0:  JSR C251F0     ;X = position of highest [and only] bit that is set
         TYA
         LSR
         TAY            ;Y = Y DIV 2, so it won't matter if Y was incremented
                        ;above.  it now holds a 0-3 character #.
         TXA
         INC
         STA $00AA,Y    ;save the dodge animation type for this character?
C223EB:  PLY
         RTS


;Initialize many things.  Called at battle start.

C223ED:  PHP
         REP #$30       ;Set 16-bit A, X, & Y
         LDX #$0258
C223F3:  STZ $3A20,X
         STZ $3C7A,X
         DEX
         DEX
         BPL C223F3
         TDC
         DEC
         LDX #$0A0E
C22402:  STA $2000,X
         STA $2A10,X
         DEX
         DEX
         BPL C22402
         STZ $2F44
         STZ $2F4C      ;clear list of entities to be removed from battlefield
         STZ $2F4E      ;clear list of entities to enter battlefield
         STZ $2F53      ;clear list of visually flipped entities
         STZ $B0
         STZ $B2
         LDX #C22602 ;?
         LDY #$3018
         LDA #$001B
         MVN $C27E    ;copy C2/2602 - C2/261D to 7E/3018 - 7E/3033.
                        ;unique bits identifying entities, and starting
                        ;addresses of characters' Magic menus
         LDA $11E0
         CMP #$01D7     ;Check for Short Arm, Long arm, Face formation
         SEP #$30       ;Set 8-bit A, X & Y
         BNE C22435     ;branch if it's not 1st tier of final 4-tier
                        ;multi-battle
         STZ $3EE0      ;zero byte to indicate that we're in the final
                        ;4-tier multi-battle
C22435:  LDX #$13
C22437:  LDA $1DC9,X
         STA $3EB4,X
         DEX
         BPL C22437
         LDA $021E      ;1-60 frame counter
         ASL
         ASL            ;* 4, so it's now 4, 8, 12, ... , 236, 240
         STA $BE        ;Save as RNG Table index
         JSR C230E8     ;Loads battle formation data
         JSR C22F2F     ;load some character properties, and set up special
                        ;event for formation or for possible Gau Veldt return
         LDA #$80
         TRB $3EBB
         LDA #$91
         TRB $3EBC      ;clear event bits indicating battle ended in loss,
                        ;Warp/escape, or full-party Engulfing
         LDX #$12
C22459:  JSR C24B5A     ;random: 0 to 255
         STA $3AF0,X    ;Store it.  This randomization serves to stagger when
                        ;entities get periodic damage/healing from Seizure,
                        ;Regen, Phantasm, Poison, or from being a Tentacle
                        ;who's Seize draining.
         LDA #$BC
         CPX $3EE2      ;is this target Morphed?
         BNE C22468     ;branch if not
         ORA #$02
C22468:  STA $3204,X
         DEX
         DEX
         BPL C22459     ;iterate for all 10 entities
         JSR C22544
         LDA $1D4D      ;from Configuration menu: Battle Mode, Battle Speed,
                        ;Message Speed, and Command Set
         BMI C2247A     ;branch if "Short" Command Set
         STZ $2F2E      ;otherwise, it's "Window"
C2247A:  BIT #$08       ;is "Wait" Battle Mode set?
         BEQ C22481     ;branch if not, meaning it's Active
         INC $3A8F
C22481:  AND #$07       ;Isolate Battle Speed.  Note that its actual value
                        ;ranges from 0 to 5, but the menu choices the player
                        ;sees are 1 thru 6.
         ASL
         ASL
         ASL
         STA $EE        ;Battle Speed * 8
         ASL            ;'' * 16
         ADC $EE        ;'' * 24
         EOR #$FF
         STA $3A90      ;= 255 - (Battle Speed * 24)
                        ;this variable is a multiplier which is used for
                        ;slowing down enemies in the Battle Time Counter
                        ;Function at C2/09D2.  as you can see here and
                        ;from experience, a Battle Speed of zero will leave
                        ;enemies the fastest.
         LDA $1D4E      ;from Configuration menu: Window Background #, Reequip,
                        ;Sound, Cursor, and Gauge
         BPL C22498     ;branch if the Gauge is not disabled
         STZ $2021      ;zero for gauge disabling [was set to FFh at C2/2402]
C22498:  STZ $2F41      ;clear "in a menu" flag
         JSR C2546E     ;Construct in-battle Item menu, equipment sub-menus, and
                        ;possessed Tools bitfield, based off of equipped and
                        ;possessed items.
         JSR C2580C     ;Construct Dance and Rage menus, and get number of known
                        ;Blitzes and highest known SwdTech index
         JSR C22EE1     ;Initialize some enemy presence variables, and load enemy
                        ;names and stats
         JSR C24391     ;update status effects for all applicable entities
         JSR C2069B     ;Do various responses to three mortal statuses
         LDA #$14
         STA $11AF      ;treat attacker level as 20 for purpose of
                        ;initializing Condemned counters
         JSR C2083F
         JSR C24AB9     ;Update lists and counts of present and/or living
                        ;characters and monsters
         JSR C22E3A     ;Determine if front, back, pincer, or side attack
         JSR C226C9     ;Give immunity to permanent statuses, and handle immunity
                        ;to "mirror" statuses, for all entities.
         JSR C22E68     ;Disable Veldt return on all but Front attack, change rows
                        ;or see if preemptive attack when applicable
         JSR C22575     ;Initialize ATB Timers
         LDX #$00       ;start off with no message about encounter
         LDA $2F4B      ;extra formation data, byte 3
         BIT #$04
         BNE C224EA     ;branch if "hide starting messages" set
         LDA $201F      ;get encounter type.  0 = front, 1 = back,
                        ;2 = pincer, 3 = side
         CMP #$01
         BNE C224D5     ;branch if not back attack
         LDX #$23       ;"Back attack" message ID
         BRA C224EA
C224D5:  CMP #$02
         BNE C224DD     ;branch if not pincer attack
         LDX #$25       ;"Pincer attack" message ID
         BRA C224EA
C224DD:  CMP #$03
         BNE C224E3     ;branch if not side attack
         LDX #$24       ;"Side attack" message ID
C224E3:  LDA $B0
         ASL
         BPL C224EA     ;branch if not preemptive attack
         LDX #$22       ;"Preemptive attack" message ID
C224EA:  TXY
         BEQ C224F2     ;branch if no encounter message forthcoming
         LDA #$25       ;command which prepares text display
         JSR C24E91     ;queue it, in global Special Action queue
C224F2:  JSR C25C73     ;Update Can't Escape, Can't Run, Run Difficulty, and
                        ;onscreen list of enemy names, based on currently present
                        ;enemies
         JSR C25C54     ;Copy ATB timer, Morph gauge, and Condemned counter to
                        ;displayable variables
         STZ $B8
         STZ $B9        ;clear targets, so any Jumps queued below will choose
                        ;theirs randomly?
         LDX #$06
C224FE:  LDA $3018,X
         BIT $3F2C
         BEQ C2251C     ;branch if not Jumping
         LDA $3AA0,X
         ORA #$28
         STA $3AA0,X
         STZ $3219,X    ;zero top byte of ATB Timer
         JSR C24E77     ;put character in action queue
         LDA #$16
         STA $3A7A      ;Jump command
         JSR C24ECB     ;queue it, in entity's conventional queue
C2251C:  DEX
         DEX
         BPL C224FE     ;loop for all 4 party members
         LDA $3EE1
         INC
         BEQ C2253F     ;branch if not one of last 3 tiers of final
                        ;4-tier multi-battle?
         DEC
         STA $2D6F      ;second byte of first entry of ($76) buffer
         LDA #$12
         STA $2D6E      ;first byte of first entry of ($76) buffer
         LDA $3A75      ;list of present and living enemies
         STA $2D71      ;fourth byte of first entry of ($76) buffer
         LDA #$FF
         STA $2D70      ;third byte of first entry of ($76) buffer
         STA $2D72      ;first byte of second entry of ($76) buffer
         LDA #$04
C2253F:  JSR C26411     ;Execute animation queue
         PLP
         RTS


C22544:  JSR C25551     ;Generate Lore menus based on known Lores, and generate
                        ;Magic menus based on spells known by ANY character.
                        ;upcoming C2/568D call will refine as needed.
         LDX #$06
C22549:  LDA $3ED8,X    ;Which character it is
         BMI C22570     ;Branch if slot empty?
         CMP #$10
         BCS C22557     ;branch if character # is above 10h
         TAY
         TXA
         STA $3000,Y    ;save 0, 2, 4, 6 party position of where this specific
                        ;character is found
C22557:  LDA $3018,X
         TSB $3A8D      ;save active characters in list which will be checked by
                        ;battle ending code as pertains to Engulf
         LDA $3ED9,X    ;0-15 roster position of this party member
         JSL C20E77     ;load equipment data for character in A
         JSR C2286D     ;Initialize in-battle character properties from
                        ;equipment properties
         JSR C227A8     ;copy character's out of battle stats into battle stats,
                        ;and mark out of battle and equipment statuses to be set
         JSR C2568D     ;Generate a character's Esper menu, blank out unknown
                        ;spells from their Magic menu, and adjust spell and Lore
                        ;MP costs based on equipped Relics.
         JSR C2532C     ;Change character commands when wearing MagiTek armor or
                        ;visiting Fanatics' Tower, or based on Relics.  Blank
                        ;certain commands.  Zero MP based on known
                        ;commands/spells.
C22570:  DEX
         DEX
         BPL C22549     ;iterate for all 4 party members
         RTS


;Initialize ATB Timers

C22575:  PHP
         STZ $F3        ;zero General Incrementor
         LDY #$12
C2257A:  LDA $3AA0,Y
         LSR
         BCS C22587     ;branch if entity is present in battle?
         CLC
         LDA #$10
         ADC $F3
         STA $F3        ;add 16 to $F3 [our General Incrementor] for
                        ;each entity shy of the possible 10
C22587:  DEY
         DEY
         BPL C2257A     ;loop for all 10 characters and monsters
         REP #$20       ;Set 16-bit accumulator
         LDA #$03FF     ;10 bits set, 10 possible entities in battle
         STA $F0
         LDY #$12
C22594:  LDA $F0
         JSR C2522A     ;randomly choose one of the 10 bits [targets]
         TRB $F0        ;and clear it, so it won't be used for
                        ;subsequent iterations of loop
         JSR C251F0     ;X = bit # of the chosen bit, thus a 0-9
                        ;target #
         SEP #$20       ;Set 8-bit accumulator
         TXA
         ASL
         ASL
         ASL
         STA $F2        ;save [0..9] * 8 in our Specific Incrementor
                        ;the result is that each entity is randomly
                        ;assigned a different value for $F2:
                        ;0, 8, 16, 24, 32, 40, 48, 56, 64, 72
         LDA $3219,Y    ;get top byte of ATB Timer
         INC
         BNE C225FA     ;skip to next target if it wasn't FFh
         LDA $3EE1      ;FFh in every case, except for last 3 tiers
                        ;of final 4-tier multi-battle?
         INC
         BNE C225FA     ;skip to next target if one of those 3 tiers
         LDX $201F      ;get encounter type.  0 = front, 1 = back,
                        ;2 = pincer, 3 = side
         LDA $3018,Y
         BIT $3A40      ;is target a character acting as enemy?
         BNE C225D1     ;branch if so
         CPY #$08
         BCS C225D1     ;branch if target is a monster
         LDA $B0
         ASL
         BMI C225FA     ;skip to next target if Preemptive Attack
         DEX            ;decrement encounter type
         BMI C225DE     ;branch if front attack
         DEX
         DEX
         BEQ C225FA     ;skip to next target if side attack
         LDA $F2
         BRA C225F3     ;it's a back or pincer attack
                        ;go set top byte of ATB timer to $F2 + 1
C225D1:  LDA $B0        ;we'll reach here only if target is monster
                        ;or character acting as enemy
         ASL
         BMI C225DA     ;branch if Preemptive Attack
         CPX #$03       ;checking encounter type again
         BNE C225DE     ;branch if not side attack
C225DA:  LDA #$01
         BRA C225F3     ;go set top byte of ATB timer to 2
C225DE:  LDA $3B19,Y    ;A = Speed
         JSR C24B65     ;random #: 0 to A - 1
         ADC $3B19,Y    ;A = random: Speed to ((2 * Speed) - 1)
         BCS C225F1     ;branch if exceeded 255
         ADC $F2        ;add entity's Specific Incrementor, a
                        ;0,8,16,24,32,40,48,56,64,72 random boost
         BCS C225F1     ;branch if exceeded 255
         ADC $F3        ;add our General Incrementor,
                        ;10 - number of valid entities) * 16
         BCC C225F3     ;branch if byte didn't exceed 255
C225F1:  LDA #$FF       ;if it overflowed, set it to FFh [255d]
C225F3:  INC
         BNE C225F7
         DEC            ;so A is incremented if it was < FFh
C225F7:  STA $3219,Y    ;save top byte of ATB timer
C225FA:  REP #$20
         DEY
         DEY
         BPL C22594     ;loop for all 10 possible characters and
                        ;monsters
         PLP
         RTS


;Data to load into $3018 and $3019 - unique bits identifying entities

; Characters 1-4
C22602: dw %0000000000000001 ;$0001
      : dw %0000000000000010 ;$0002
      : dw %0000000000000100 ;$0004
      : dw %0000000000001000 ;$0008

; Monsters 1-6
      : dw %0000000100000000 ;$0100
      : dw %0000001000000000 ;$0200
      : dw %0000010000000000 ;$0400
      : dw %0000100000000000 ;$0800
      : dw %0001000000000000 ;$1000
      : dw %0010000000000000 ;$2000


;Data - starting addresses of characters' Magic menus

      : dw $208E
      : dw $21CA
      : dw $2306
      : dw $2442


C2261E:  TDC            ;A = 0
         LDX #$5F
C22621:  STA $3EE4,X
         DEX
         BPL C22621     ;set $3EE4 through $3F43 to zero.  this includes all
                        ;four status bytes for all ten entities.
         DEC            ;A = 255
         LDX #$0F
C2262A:  STA $3ED4,X
         DEX
         BPL C2262A     ;set $3ED4 through $3EE3 to FFh
         LDA #$12
         STA $3F28      ;tell Mimic last command was something other than Jump
         STA $3F24      ;Last command (second attack w/ Gem Box, for use by
                        ;Mimic.  indicate it as nonexistent.
         RTS


;Clear animation buffer pointers, extra strike quantity, and various backup targets

C22639:  PHP
         STZ $3A72      ;clear ($76) animation buffer pointer
         STZ $3A70      ;clear extra strike quantity -- iow, default to just one
                        ;strike
         REP #$20
         STZ $3A32      ;clear ($78) animation buffer pointer
         STZ $3A34      ;clear simultaneous damage display buffer index?
         STZ $3A30      ;clear backup [and temporary Mimic] targets
         STZ $3A4E      ;clear fallback targets to beat on for multi-strike attacks
                        ;when no valid targets left
         PLP
         RTS


;Turn Death immunity into Instant Death protection by moving it into another byte; otherwise you'd
; be bloody immortal.  If the Poison elemental is nullified, make immune to Poison status.)

C22650:  LDA $3AA1,X
         AND #$FB       ;Clear protection from "instant death"
         XBA
         LDA $331C,X    ;Blocked status byte 1
         BMI C22661     ;Branch if not block death
         ORA #$80       ;Clear block death
         XBA
         ORA #$04       ;Set protection from "instant death"
         XBA
C22661:  XBA
         STA $3AA1,X
         LDA $3BCD,X    ;Nullified elements
         BIT #$08
         BEQ C22670     ;Branch if not nullify poison
         XBA
         AND #$FB       ;Set block poison status if yes
         XBA
C22670:  XBA
         STA $331C,X
         RTS


;Make some monster or equipment statuses permanent by setting immunity to them:
;  Mute, Berserk, Muddled, Seizure, Regen, Slow, Haste, Shell, Safe, Reflect, Float *

; * If Float is only marked in Monster status byte 4, it won't be permanent
;   [not to worry; no actual monsters do this].

; Then if you're immune to one status in a "mutually exclusive" pair, make immune to
; the other.  The pairs are Slow/Haste and Seizure/Regen.)

C22675:  LDA $3331,X
         XBA            ;put blocked status byte 4 in top of A.
                        ;note that blocked statuses = 0, susceptible ones = 1
         LDA $3C6D,X    ;monster/equip status byte 3
         LSR
         BCC C22683     ;if perm-Float (aka Dance) wasn't set, branch
         XBA
         AND #$7F
         XBA            ;if it^ was, then block Float.  thus the permanence.
C22683:  LDA $3EBB
         BIT #$04
         BEQ C2268E     ;branch if we're not in Phunbaba battle #4
                        ;[iow, Terra's second Phunbaba meeting]
         XBA
         AND #$F7       ;if we are, give immunity to Morph to make it permanent
         XBA
C2268E:  XBA
         STA $3331,X    ;update blocked status #4.
                        ;note that blocked statuses = 0, susceptible ones = 1
         LDA $3330,X
         XBA
         LDA $331D,X    ;A.top=blocked status byte 3, A.btm=blocked status #2
         REP #$20
         STA $EE
         LDA $3C6C,X    ;monster/equip status bytes 2-3
         AND #$EE78     ;Dance, Stop, Sleep, Condemned, Near Fatal, Image will all be 0
         EOR #$FFFF     ;now they'll all be 1
         AND $EE        ;SO Blocked Statuses = what you were blocking before, plus
                        ;whatever the enemy/equip has.  with the exception of the
                        ;above.. which will only be blocked if they were before
         BIT #$0200
         BEQ C226B2     ;if Regen blocked, branch
         BIT #$0040
         BNE C226B5     ;if Seizure isn't blocked, branch
C226B2:  AND #$FDBF     ;SO if Regen or Seizure is blocked, block both.
                        ;should explain Regen failing on Ribbon.
C226B5:  SEP #$20
         STA $331D,X    ;update blocked status byte #2.  we'll update byte #3 below.
         XBA            ;now examine #3
         BIT #$04
         BEQ C226C3     ;if Slow blocked, branch
         BIT #$08
         BNE C226C5     ;if Haste isn't blocked, branch
C226C3:  AND #$F3       ;SO if Slow or Haste is blocked, block 'em both.
                        ;should explain Slow failing on RunningShoes.
C226C5:  STA $3330,X    ;update blocked status byte #3
         RTS


C226C9:  LDX #$12       ;start from 6th enemy
C226CB:  JSR C22675
         DEX
         DEX
         BPL C226CB     ;and do Function $2675 for everybody in the battle
         RTS


;Load command and attack/sub-command data
;When called:
;  A Low = Command  (generally from $B5 or $3A7C)
;  A High = Attack/Sub-command  (generally from $B6 or $3A7D)

C226D3:  PHX
         PHY
         PHA            ;Put on stack
         STZ $BA
         LDX #$40
         STX $BB        ;default to targeting byte just being
                        ;Cursor Start on Enemy
         LDX #$00
         CMP #$1E
         BCS C22701     ;branch if command >= 1Eh , using default function
                        ;pointer of 0
         TAX
         LDA C2278A,X   ;get miscellaneous Command properties byte
         PHA            ;Put on stack
         AND #$E1       ;isolate Abort on Characters, Randomize Target, beat on
                        ;corpses if no valid targets left, and Exclude Attacker
                        ;From Targets properties
         STA $BA
         LDA $01,S
         AND #$18       ;now check what will become Can Target Dead/Hidden Entities
                        ;and Don't Retarget if Target Invalid
         LSR
         TSB $BA
         TXA
         ASL
         TAX            ;multiply command number by 2
         LDA $CFFE01,X
         STA $BB        ;get the command's targeting from a table
         PLA
         AND #$06       ;two second lowest bits from C2/278A determine
                        ;what function to call next
         TAX
         XBA            ;now get spell # or miscellaneous index.. ex- it might
                        ;indicate the item Number
C22701:  JSR (C22782,X)
         PLA
         PLY
         PLX
C22707:  RTS


;Throw, Tools.  Item calls $271A.
C22708:  LDX #$04
C2270A:  CMP C22778,X   ;is the tool or skean one that uses a spell?
         BNE C22716     ;if not, branch
         SBC C2277D,X   ;if yes, subtract constant to determine its spell number
         BRA C2274D     ;see, certain Tools and Skeans just load spells to do
                        ;their work

                        ;Bio Blaster will use spell 7D, Bio Blast
                        ;Flash will use spell 7E, Flash
                        ;Fire Skean will use spell 51h, Fire Skean
                        ;Water Edge will use spell 52, Water Edge
                        ;Bolt Edge will use spell 53, Bolt Edge

C22716:  DEX
         BPL C2270A     ;loop 5 times, provided we didn't jump out of the loop
         SEC            ;set Carry, for check at C2/18BD
C2271A:  STA $3411      ;save item #
         JSR C22B63     ;Multiply A by 30, size of item data block
         REP #$10       ;Set 16-bit X and Y
         TAX
         LDA $D8500E,X  ;Targeting byte
         STA $BB
         LDA $D85015,X  ;Condition 1 when Item used
         BIT #$C2
         BNE C22735     ;Branch if Death, Zombie, or Petrify set
         LDA #$08
         TRB $BA        ;Clear Can Target Dead/Hidden Entities
C22735:  LDA $D85012,X  ;equipment spell byte.
                        ; Bits 0-5: spell #
                        ; Bit 6: cast randomly after weapon strike [handled
                        ;        elsewhere, shouldn't apply here]
                        ; Bit 7: 1 = remove from inventory upon usage, 0 = nope
         SEP #$10       ;Set 8-bit X and Y
         RTS


;Item
C2273C:  CMP #$E6       ;Carry is set if item # >= 230, Sprint Shoes.  i.e. it's
                        ;Item type.  Carry won't be set for Equipment Magic.
         JSR C2271A     ;get Targeting byte, and make slight modification to
                        ;targeting if Item affects Wound/Zombie/Petrify.  also,
                        ;A = equipment spell byte
         BCS C22707     ;if it's a plain ol' Item, always deduct from inventory,
                        ;and don't attempt to save the [meaningless] spell # or
                        ;load spell data
         BMI C2274B     ;branch if equipment gets used up when used for Item Magic.
                        ;i'm not aware of any equipment this *doesn't* happen with,
                        ;though the game supports it.
         XBA            ;preserve equipment spell byte
         LDA #$10
         TSB $B1        ;set "don't deplete from Item inventory" flag
         XBA
C2274B:  AND #$3F       ;isolate spell # cast by equipment
C2274D:  STA $3410      ;Magic and numerous other commands enter here
         BRA C22754     ;load spell data for [equipment] magic.  note that we rely
                        ;on that code keeping/making Carry clear.


C22752:  LDA #$EE       ;select Spell EEh - Battle
C22754:  JSR C22966     ;go load spell data
         LDA $BB        ;targeting byte as read from $CFFE01 table?
         INC
         BNE C22761     ;branch if it wasn't FF.. if it was, it's null, so we use
                        ;the spell byte instead
         LDA $11A0      ;spell aiming byte
         STA $BB
C22761:  LDA $11A2
         PHA            ;Put on stack
         AND #$04       ;Isolate bit 2.  This spell bit is used for two properties:
                        ;Bit 2 of $11A2 will be "Hit only (dead XOR undead targets",
                        ;and Bit 3 of $BA will be "Can Target Dead/Hidden entities".
         ASL
         TSB $BA        ;Sets Can Target Dead/Hidden entities
         LDA $01,S      ;get $11A2 again
         AND #$10       ;Randomize target
         ASL
         ASL
         TSB $BA        ;Sets randomize target
         PLA            ;get $11A2 again
         AND #$80       ;Abort on characters
         TSB $BA        ;Sets abort on characters
         RTS


;Data - item numbers of Tools and Skeans that use spells to do a good chunk
; of their work)

C22778: db $A4  ;(Bio Blaster)
      : db $A5  ;(Flash)
      : db $AB  ;(Fire Skean)
      : db $AC  ;(Water Edge)
      : db $AD  ;(Bolt Edge)

;Data - constants we subtract from the above item #s to get the numbers
; of the spells they rely on)

C2277D: db $27
      : db $27
      : db $5A
      : db $5A
      : db $5A


;Code Pointers (indexed by bits 1 and 2 of data values below

C22782: dw C22752  ;Fight, Morph, Revert, Steal, Capture, Runic, Sketch, Control, Leap, Mimic,
                   ; Row, Def, Jump, GP Rain, Possess
      : dw C2273C  ;(Item)
      : dw C2274D  ;Magic, SwdTech, Blitz, Lore, Slot, Rage, Dance, X-Magic, Summon, Health,
                   ; Shock, MagiTek
      : dw C22708  ;(Throw, Tools)


;Data - indexed by command # 0 thru 1Dh

C2278A: db $20   ;(Fight)
      : db $1A   ;(Item)
      : db $04   ;(Magic)
      : db $18   ;(Morph)
      : db $18   ;(Revert)
      : db $00   ;(Steal)
      : db $20   ;(Capture)
      : db $24   ;(SwdTech)
      : db $06   ;(Throw)
      : db $06   ;(Tools)
      : db $04   ;(Blitz)
      : db $18   ;(Runic)
      : db $04   ;(Lore)
      : db $80   ;(Sketch)
      : db $80   ;(Control)
      : db $04   ;(Slot)
      : db $04   ;(Rage)
      : db $80   ;(Leap)
      : db $18   ;(Mimic)
      : db $04   ;(Dance)
      : db $18   ;(Row)
      : db $18   ;(Def)
      : db $21   ;(Jump)
      : db $04   ;(X-Magic)
      : db $01   ;(GP Rain)
      : db $04   ;(Summon)
      : db $04   ;(Health)
      : db $04   ;(Shock)
      : db $81   ;(Possess)
      : db $04   ;(MagiTek)


;Copy character's out of battle stats into their battle stats, and mark out of battle
; and equipment statuses to be set)

C227A8:  PHP
         REP #$30       ;Set 16-bit Accumulator & Index Registers
         LDY $3010,X    ;get offset to character info block
         LDA $1609,Y    ;get current HP
         STA $3BF4,X    ;HP
         LDA $160D,Y    ;get current MP
         STA $3C08,X    ;MP
         LDA $160B,Y    ;get maximum HP
         JSR C2283C     ;get max HP after equipment/relic boosts
         CMP #$2710
         BCC C227C8
         LDA #$270F     ;if it was >= 10000, make it 9999
C227C8:  STA $3C1C,X    ;Max HP
         LDA $160F,Y    ;get maximum MP
         JSR C2283C     ;get max MP after equipment/relic boosts
         CMP #$03E8
         BCC C227D9
         LDA #$03E7     ;if it was >= 1000, make it 999
C227D9:  STA $3C30,X    ;Max MP
         LDA $3018,X    ;Holds $01 for character 1, $02 for character 2,
                        ;$04 for character 3, $08 for character 4
         BIT $B8        ;is this character a Colosseum combatant [indicated
                        ;by C2/2F2F turning on Bit 0, as the Colosseum fighter
                        ;is always Character 1] , or was he/she installed by
                        ;a special event?
         BEQ C227F8     ;branch if neither
         LDA $3C1C,X    ;Max HP
         STA $3BF4,X    ;HP
         LDA $3C30,X    ;Max MP
         STA $3C08,X    ;MP
         LDA $1614,Y    ;outside battle statuses 1 and 2.  from tashibana doc
                        ;^ statuses correspond to in-battle statuses 1 and 4
         AND #$FF2D
         STA $1614,Y    ;remove Clear, Petrify, Death, Zombie
C227F8:  LDA $3C6C,X    ;monster/equip status bytes 2-3
         SEP #$20       ;Set 8-bit Accumulator
         STA $3DD5,X    ;Status to set byte 2
         LSR
         BCC C2280B     ;branch if Condemned not marked to be set
         LDA $3204,X
         AND #$EF
         STA $3204,X    ;^ if it is going to be set, then turn off Bit 4
C2280B:  LDA $1614,Y
         STA $3DD4,X    ;Status to set byte 1
         BIT #$08
         BEQ C2281F     ;If not set M-Tek
         LDA #$1D
         STA $3F20      ;save MagiTek as default last command for Mimic
         LDA #$83
         STA $3F21      ;save Fire Beam as default last attack for Mimic
                        ;if Gogo uses Mimic before any other character acts in a
                        ;battle, he'll normally use Fight.  all i can figure is that
                        ;this code is here to make him use Fire Beam instead should
                        ;anybody be found to be wearing MagiTek armor -- in the normal
                        ;game, we can assume that if anybody's in armor, everybody
                        ;[including Gogo] is in it.

C2281F:  LDA $1615,Y    ;outside battle status 2.  corresponds to
                        ;in-battle status byte 4
         AND #$C0       ;only keep Dog Block and Float
         XBA            ;get monster/equip status byte 3
         LSR            ;shift out the lowest bit - Dance
         BCC C2282C     ;branch if Dance aka Permanent Float isn't set
         XBA
         ORA #$80       ;turn on Float in status byte 4
         XBA
C2282C:  ASL            ;shift monster/equip status byte 3 back up, zeroing the
                        ;lowest bit
         STA $3DE8,X    ;Status to set byte 3
         XBA
         STA $3DE9,X    ;Status to set byte 4
         LDA $1608,Y
         STA $3B18,X    ;Level
         PLP
         RTS


;Apply percentage boost to HP or MP.  Bit 14 set = 25% boost,
; Bit 15 set = 50% boost, Both of those bits set = 12.5% boost)

C2283C:  PHX
         ASL
         ROL
         STA $EE
         ROL
         ROL           ;Bit 15 is now in Bit 2, and Bit 14 is in Bit 1
         AND #$0006    ;isolate Bits 1 and 2
         TAX           ;and use them as function pointer
         LDA $EE
         LSR
         LSR
         STA $EE       ;all that crazy shifting was equivalent to
                        ; $EE = A AND 16383.  gotta love Square. =]
         JMP (C22859,X)


;Boost A by some fraction, if any

C22850:  TDC           ;enter here for A = 0 + $EE
C22851:  LSR           ;enter here for A = (A * 1/8) + $EE
C22852:  LSR           ;enter here for A = (A * 1/4) + $EE
C22853:  LSR           ;enter here for A = (A * 1/2) + $EE
         CLC
         ADC $EE
         PLX
         RTS


;Code Pointers

C22859: dw C22850  ;(A = A) (technically, A = $EE, but it's the same deal.)
      : dw C22852  ;(A = A + (A * 1/4) )
      : dw C22853  ;(A = A + (A * 1/2) )
      : dw C22851  ;(A = A + (A * 1/8) )


;A = 255 - (A * 2 + 1
; If A was >= 128 to start with, then A = 1.
; If A was 0 to start with, then A ends up as 255.)

C22861:  ASL
         BCC C22866
         LDA #$FF
C22866:  EOR #$FF
         INC
         BNE C2286C
         DEC
C2286C:  RTS


;Initialize in-battle character properties from equipment properties.
; A lot of the equipment bytes in this function were explained in C2/0E77, C2/0F9A, and C2/10B2,
; so consult those functions.  Terii's Offsets List at http://www.rpglegion.com/ff6/hack/offset2.txt
; is another great resource.)

C2286D:  PHD
         PEA $1100         ;Set direct page register 11 $1100
         PLD
         LDA $C9           ;$11C9
         CMP #$9F          ;Moogle Suit in character's Armor slot?
         BNE C22883        ;if not, branch
         TXA
         ASL
         ASL
         ASL
         ASL
         TAY               ;Y = X * 16
         LDA #$0A
         STA $2EAE,Y       ;Use Mog's sprite
C22883:  TXA
         LSR
         TAY               ;Y = X DIV 2
         LDA $D8           ;$11D8
         AND #$10
         STA $2E6E,Y       ;store Genji Glove effect.  this variable is used in Bank C1,
                           ; apparently to check for Genji Glove's presence when handling
                           ; mid-battle equipment changes via the Item menu.
         CLC
         LDA $A6           ;$11A6
         ADC $A6           ;($11A6)(add Vigor to itself
         BCC C22896        ;branch if it's under 256
         LDA #$FF          ;else make it 255
C22896:  STA $3B2C,X       ;store Vigor * 2
         LDA $A4           ;($11A4)(Speed
         STA $3B2D,X
         STA $3B19,X
         LDA $A2           ;($11A2)(Stamina
         STA $3B40,X
         LDA $A0           ;($11A0)(Magic Power
         STA $3B41,X
         LDA $A8           ;$11A8
         JSR C22861
         STA $3B54,X       ;( 255 - (Evade * 2) + 1 , capped at low of 1 and high of 255
         LDA $AA           ;$11AA
         JSR C22861
         STA $3B55,X       ;( 255 - (MBlock * 2) + 1 , capped at low of 1 and high of 255
         LDA $CF           ;$11CF
         TRB $D8           ;$11D8(clear Genji Glove effect from "Battle Effects 2" if its bit
						    ; was ON in $11CF [i.e. if both hands hold a weapon].  yes, this
						    ; reeks of a bug.  likely, they instead wanted the GG effect
						    ; cleared only when one or zero hands held a weapon.
         LDA $BC           ;$11BC
         STA $3C6C,X       ;Equipment status byte 2
         LDA $D4           ;$11D4
         STA $3C6D,X       ;Equipment status byte 3
         LDA $DC           ;$11DC
         STA $3D71,X       ;Amount to add to character's "Run Success" variable.  has range
                           ; of 2 thru 5.  higher means that, on average, they can run away
                           ; quicker from battle.
         LDA $D9           ;$11D9
         AND #$80          ;undead bit from relic ring
         ORA #$10          ;always set Human for party members
         STA $3C95,X       ;save in "Special Byte 3"
         LDA $D5           ;$11D5
         ASL               ;A = 0, raise attack dmg, double earring, hp+25%, hp+50,
                           ; hp+12.5, mp+25, mp+50)  (carry = mp+12.5
         XBA
         LDA $D6           ;$11D6
         TSB $3A6D         ;combine with existing "Battle Effects 1" properties
         ASL               ;carry = jump continously
         LDA $D7           ;$11D7
         XBA
         ROR               ;Top half A [will be $3C45] = $11D7 =
                           ; boost steal, single Earring, boost sketch,
                           ; boost control, sniper sight, gold hairpin,
                           ; economizer, vigor + 50%
                           ; Bottom half [will be $3C44] = raise attack dmg,
                           ; double Earring, hp+25%, hp+50%, hp+12.5%, mp+25%,
                           ; mp+50%, jump continuously.  The HP/MP bonuses
                           ; were already read from $11D5 earlier, so they're
                           ; essentially junk in $3C44.  All that's read are
                           ; Bits 0, 1, and 7.
         REP #$20          ;Set 16-bit Accumulator
         STA $3C44,X
         LDA $AC           ;$11AC
         STA $3B68,X       ;$3B68 = battle power for 1st hand,
                           ; $3B69 = bat pwr for 2nd hand
         LDA $AE           ;$11AE
         STA $3B7C,X       ;hit rate
         LDA $B4           ;$11B4
         STA $3D34,X       ;random weapon spellcast, for both hands
         LDA $B0           ;$11B0
         STA $3B90,X       ;elemental properties of weapon
         LDA $D8           ;$11D8
         BIT #$0008        ;is Gauntlet bit set?
         BNE C2290A
         LDA #$4040        ;if it's not, turn off 2-hand effect
                           ; for both hands
         TRB $DA           ;$11DA
C2290A:  LDA $DA           ;$11DA
         STA $3BA4,X       ;save "Weapon effects"
         LDA $BA           ;$11BA
         STA $3BB8,X       ;bottom = Defense, top = Magic Defense
         LDA #$FFFF
         STA $331C,X       ;Status Immunity Bytes 1 and 2: character is vulnerable
                           ; to everything -- i.e. immune to nothing
                           ;pointless instruction, as C2/291C immediately undoes it.
                           ; should be "STA $3330,X" instead, as that byte is
                           ; ignored, letting old immunities linger.
         EOR $D2           ;($11D2)(equipment immunities
         STA $331C,X       ;for Immunity Bytes 1-2, character is now vulnerable to
                           ; whatever the equipment doesn't block
         LDA $B6           ;$11B6
         STA $3BCC,X       ;bottom = absorbed elements, top = nullified elements
         LDA $B8           ;$11B8
         STA $3BE0,X       ;bottom = weak elements, top = 50% resist elements
         LDA $BE           ;$11BE
         STA $3CBC,X       ;bottom = special action for right hand,
                           ; top = special action for left hand
         LDA $C6           ;($11C6)(item # of equipment in both hands
         STA $3CA8,X
         LDA $CA           ;($11CA)(item # of equipment in both relic slots
         STA $3CD0,X
         LDA $D0           ;$11D0
         STA $3CE4,X       ;deals with weapon and shield animation for blocking
                           ; magical and physical attacks
         LDA $D8           ;$11D8
         STA $3C58,X       ;save "Battle Effects 2"
         SEP #$20          ;Set 8-bit Accumulator
         ASL $3A21,X       ;Bit X is set, where X is the actual character # of this
                           ; onscreen character.  corresponding bits are set in Items
                           ; to see if they're equippable.  shift out the top bit, as
                           ; that corresponds to "heavy" merit awardable equipment and
                           ; will be set below
         ASL
         ASL
         ASL               ;rotate "wearer can equip heavy armor" bit from
                           ; Battle Effects 2 into carry bit
         ROR $3A21,X       ;now put it in "character # for purposes of equipping" byte
         PLD
         JMP C22650        ;deal with Instant Death protection, and Poison elemental
                           ; nullification giving immunity to Poison status


;Load Magic Power / Vigor and Level

C22951:  LDA $11A2
         LSR
         LDA $3B41,X    ;magic power [* 1.5]
         BCC C2295D     ;Branch if not physical attack
         LDA $3B2C,X    ;vigor [* 2]
C2295D:  STA $11AE
         STZ $3A89      ;turn off random weapon spellcast
         JMP C22C21     ;Put attacker level [or Sketcher if applicable] in $11AF


;Load spell data

C22966:  PHX
         PHP
         XBA
         LDA #$0E
         JSR C24781     ;length of spell data * spell #
         REP #$31       ;Set 16-bit A, X, Y.  Clear carry flag
         ADC #$6AC0     ;spells start at 46CC0 ROM offset, or C4/6AC0
         TAX
         LDY #$11A0
         LDA #$000D
         MVN $C47E    ;copy 14 spell bytes into RAM
         SEP #$20
         ASL $11A9      ;multiply special effect by 2
         BCC C22987
         STZ $11A9      ;if it exceeded 255, make it 0
C22987:  PLP
         PLX
         RTS


;Loads command data, clears special effect, sets unblockable, sets Level to 0,
; sets Vigor/Mag. Pwr to 0)

C2298A:  LDA $3A7C      ;get original command ID
C2298D:  JSR C226D3     ;Load data for command [held in A.bottom] and, given
                        ;the callers to this function, data of "Battle" spell
         LDA #$20
         TSB $11A4      ;Set Unblockable
         STZ $11A9      ;Clear special effects
         STZ $11AF      ;Set Level to 0
         STZ $11AE      ;Set Vigor / M. Power to 0
         RTS


;Load weapon data into attack data.  Also handles Offering, Sniper Sight, etc.

C2299F:  PHP
         LDA $3B2C,X
         STA $11AE      ;Vigor * 2 / Magic Power
         JSR C22C21     ;Put attacker level [or Sketcher if applicable] in $11AF
         LDA $3C45,X
         BIT #$10
         BEQ C229B5     ;If no Sniper Sight
         LDA #$20
         TSB $11A4      ;Sets Can't be Dodged
C229B5:  LDA $B6        ;get attack #
         CMP #$EF
         BNE C229C7     ;Branch if not Special
         LDA $3EE4,X
         BIT #$20       ;Check for Imp status
         BNE C229C7     ;if an Imp, branch
         LDA #$06
         STA $3412      ;will display a monster Special atop the screen, and
                        ;attack will load its properties at C2/32F5
C229C7:  PLP
         PHX
         ROR $B6        ;if carry was set going into function, this is an
                        ;odd-numbered attack of sequence, related to $3A70..
                        ;top bit of $B6 will be used in animation:
                        ;Clear = right hand, Set = left hand

         BPL C229CE     ;if Carry wasn't set, branch and use right hand
         INX            ;if it was, point to left weapon hand
C229CE:  LDA $3B68,X
         STA $11A6      ;Battle Power
         LDA #$62
         TSB $B3        ;turn off Always Critical and Gauntlet.  Turn on
                        ;ignore attacker row
         LDA $3BA4,X
         AND #$60       ;isolate "Same damage from back row" and "2-hand" properties
         EOR #$20       ;flip "Same damage from back row" to get "Damage affected
                        ;by attacker row"
         TRB $B3        ;Bit 6 = 0 for Gauntlet [2-hand] and Bit 5 = 0 for
                        ;"Damage affected by attacker row"
         LDA $3B90,X
         STA $11A1      ;Element
         LDA $3B7C,X
         STA $11A8      ;Hit Rate
         LDA $3D34,X
         STA $3A89      ;random weapon spellcast
         LDA $3CBC,X
         AND #$F0
         LSR
         LSR
         LSR
         STA $11A9      ;Special effect
         LDA $3CA8,X    ;Get equipment in current hand
         INC
         STA $B7        ;adjust and save as graphic index
         PLX
         LDA $3C58,X    ;Check for offering
         LSR
         BCC C22A1B     ;Branch if no Offering
         LDA #$20
         TSB $11A4      ;Set Can't be dodged
         LDA #$40
         TSB $BA        ;Sets randomize target
         LDA #$02
         TSB $B2        ;Set no critical and ignore True Knight
         STZ $3A89      ;Turn off random spellcast
C22A1B:  LDA $11A6
         BEQ C22A36     ;Exit if 0 Battle Power
         CPX #$08
         BCC C22A36     ;Exit if character
         LDA #$20
         BIT $3EE4,X
         BEQ C22A36     ;Exit if not Imp
         ASL
         BIT $3C95,X    ;Check for auto critical if Imp
         BNE C22A36     ;If set then exit
         LDA #$01
         STA $11A6      ;Set Battle Power to 1
C22A36:  RTS


;Item usage setup.  Used for non-Magic: Items, Thrown objects, and Tools
;Going in: A = Item number.
;  Carry flag = Command >= 2.  It's set for Throw or Tools, but not plain Item.)

C22A37:  PHX
         PHP
         PHA            ;Put on stack
         PHX
         LDX #$0F
C22A3D:  STZ $11A0,X    ;zero out all spell data -related bytes
         DEX
         BPL C22A3D
         PLX
         LDA #$21
         STA $11A2      ;Set to ignore defense, physical attack
         LDA #$22
         STA $11A3      ;Set attack to retarget if target invalid/dead,
                        ;not reflectable
         LDA #$20
         STA $11A4      ;Set to unblockable
         BCC C22A5E     ;branch if not Throw or Tools, i.e. plain Item
         LDA $3B2C,X    ;attacker Vigor [* 2]
         STA $11AE      ;Vigor * 2 or Magic Power
         JSR C22C21     ;Put attacker level [or Sketcher if applicable] in $11AF
C22A5E:  LDA $01,S      ;get Item ID
         JSR C22B63     ;Multiply A by 30, size of item data block
         REP #$10       ;Set 16-bit X and Y
         TAX
         LDA $D85014,X  ;Item "HP/MP affected", aka power
         STA $11A6
         LDA $D8500F,X  ;Item's element
         STA $11A1
         BCS C22ADC     ;branch if Throw or Tools
         LDA #$01
         TRB $11A2      ;Sets to magical attack
         LDA $D8501B,X  ;item special action
         ASL
         BCS C22A87     ;Branch if top bit set, i.e. no action, usually FFh
         ADC #$90
         STA $11A9      ;Else store 90h + (action*2) in special effect
C22A87:  REP #$20       ;set 16-bit accumulator
         LDA $D85015,X  ;Item conditions 1+2 when used
         STA $11AA
         LDA $D85017,X  ;Item conditions 3+4 when used
         STA $11AC
         SEP #$20       ;Set 8-bit accumulator
         LDA $D85013,X  ;Get Item Properties
         STA $FE
         ASL $FE        ;Does it manipulate 1/16th of actual values?
         BCC C22AA8     ;If not ^, branch
         LDA #$80
         TSB $11A4      ;Set bit to take HP at fraction of spell byte 7
C22AA8:  ASL $FE
         ASL $FE
         BCC C22AB3     ;If item doesn't remove status conditions, branch
         LDA #$04
         TSB $11A4      ;Set remove status spell bit
C22AB3:  ASL $FE
         BCC C22ABE     ;Branch if "restore MP" item bit unset
         LDA #$80
         TSB $11A3      ;Set spell to concern MP
         TSB $FE        ;And automatically set "restore HP" in item properties,
                        ;so MP-related items always try to give MP, not take it
C22ABE:  ASL $FE
         BCC C22AC7     ;Branch if "restore HP" (or restore MP) bit unset
         LDA #$01
         TSB $11A4      ;Set Heal spell bit
C22AC7:  ASL $FE
         ASL $FE
         BCC C22AD2     ;Branch if Item doesn't reverse damage on undead
         LDA #$08
         TSB $11A2      ;Sets Invert Damage on Undead
C22AD2:  LDA $11AA
         BPL C22ADC     ;Branch if not death attack
         LDA #$0C
         TSB $11A2      ;Sets Invert Damage on Undead and Hit only (dead XOR undead
                        ;targets
C22ADC:  LDA $01,S
         CMP #$AE       ;Item number 174 - Inviz Edge?
         BNE C22AE9     ;branch if not
         LDA #$10
         TSB $11AA      ;Set Clear effect to attack
         BRA C22AF2
C22AE9:  CMP #$AF       ;Item number 175 - Shadow Edge?
         BNE C22AF2     ;branch if not
         LDA #$04
         TSB $11AB      ;Set Image effect to attack

;NOTE: special Inviz and Shadow Edge checks are needed because much code
; [including that at C2/2A89 that normally loads statuses] is skipped if we're
; doing Throw [or Tools])

C22AF2:  LDA $D85000,X  ;Item type
         AND #$07
         BNE C22B16     ;If item's not a Tool, branch
         LDA #$20
         TRB $11A2      ;Clears ignore defense
         TRB $11A4      ;Clears unblockable
         LDA $D85015,X
         STA $11A8      ;Get and store hit rate
         TDC
         LDA $01,S      ;get item #.  number of first tool [NoiseBlaster] is A3h.
         SEC
         SBC #$A3
         AND #$07       ;subtract 163 from item # and use bottom 3 bits to get a
                        ;"tool number" of 0-7
         ASL            ;multiply it by 2 to index table below
         TAX
         JSR (C22B1A,X) ;load Tool's miscellaneous effect
C22B16:  PLA
         PLP
         PLX
         RTS


;Code pointers

C22B1A: dw C22B2A     ;(Noise Blaster)
      : dw C22B2F     ;(Bio Blaster) (do nothing)
      : dw C22B2F     ;(Flash) (do nothing)
      : dw C22B30     ;(Chainsaw)
      : dw C22B53     ;(Debilitator)
      : dw C22B4D     ;(Drill)
      : dw C22B57     ;(Air Anchor)
      : dw C22B5D     ;(Autocrossbow)


;Noiseblaster effect

C22B2A:  LDA #$20
         STA $11AB      ;Set Muddled in attack data
C22B2F:  RTS


;Chainsaw effect

C22B30:  JSR C24B5A     ;random #: 0 to 255
         AND #$03
         BNE C22B4D     ;75% chance branch
         LDA #$08
         STA $B6        ;Animation
         STZ $11A6      ;Battle power
         LDA #$80
         TSB $11AA      ;Set death/wound status in attack data
         LDA #$10
         STA $11A4      ;Set stamina can block
         LDA #$02
         TSB $11A2      ;Set miss if instant death protected
C22B4D:  LDA #$20
         TSB $11A2      ;Set ignore defense
         RTS


;Debilitator Effect

C22B53:  LDA #$AC
         BRA C22B59     ;Set Debilitator effect


;Air Anchor effect

C22B57:  LDA #$AE       ;Add Air Anchor effect
C22B59:  STA $11A9
         RTS


;Autocrossbow effect

C22B5D:  LDA #$40
         TSB $11A2      ;Set no split damage
         RTS


;Multiplies A by 30

C22B63:  XBA
         LDA #$1E
         JMP C24781


;Magic Damage Calculation:

;Results:

;$11B0 = (Spell Power * 4) + (Level * Magic Power * Spell Power / 32
;If Level of 0 is passed, $11B0 = Spell Power)

;NOTE: Unlike damage modification functions, this one does NOTHING to make sure damage
;doesn't exceed 65535.  That means with a spell like Ultima, a character at level 99
;who has reached 140+ Magic Power via Esper bonuses and equipment will do only
;triple-digit damage.

C22B69:  LDA $11AF   ;Level
         STA $E8
         CMP #$01
         TDC         ;Clear 16-bit A
         LDA $11A6   ;Spell Power
         REP #$20    ;Set 16-bit Accumulator
         BCC C22B7A ;If Level > 0, Spell Power *= 4
         ASL
         ASL
C22B7A:  STA $11B0   ;Maximum Damage
         SEP #$20    ;Set 8-bit Accumulator
         LDA $11AE   ;Magic Power
         XBA
         LDA $11A6   ;Spell Power
         JSR C24781  ;Multiplication Function:
                      ; A = Magic Power * Spell Power
         JSR C247B7  ;Multiplication Function 2:
                      ;              24-bit $E8 = (Mag Pwr * Spell Power) * Level
         LDA #$04
         REP #$20    ;Set 16-bit Accumulator
         JSR C20DD1  ;Divide 24-bit Damage by 32.  [note the
                      ; division operates on 4 bytes]
         CLC
         ADC $11B0   ;Maximum Damage
         STA $11B0   ;Maximum Damage
         SEP #$20    ;Set 8-bit Accumulator
         RTS


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

C22B9D:  LDA $11A2      ;Check if magic attack
         LSR
         BCS C22BA6
         JMP C22B69     ;Magical Damage Calculation
C22BA6:  PHP
         LDA $11AF      ;attacker Level
         PHA            ;save it
         STA $E8
         TDC
         LDA $11A6      ;Battle Power
         REP #$20       ;Set 16-bit Accumulator
         CPX #$08       ;If monster then Battle Power *= 4
         BCC C22BB9
         ASL
         ASL
C22BB9:  PHA            ;Put on stack
         LDA $B2
         BIT #$4000
         BNE C22BCD     ;If Gauntlet is not equipped, branch
         LDA $01,S      ;Battle Power *= 7/4
         LSR
         CLC
         ADC $01,S
         LSR
         CLC
         ADC $01,S
         STA $01,S
C22BCD:  PLA
         SEP #$20       ;Set 8-bit Accumulator
         ADC $11AE      ;add Vigor * 2 if character, or Vigor if monster
         XBA
         ADC #$00       ;add carry from the bottom byte of Attack
                        ;into the top byte
         XBA
         JSR C247B7     ;get 16-bit "Attack" * 8-bit level, and put
                        ;24-bit product in Variables $E8 thru $EA
         LDA $E8
         STA $EA        ;use top byte of result as temporary variable,
                        ;since it's generally 0 anyway.
                        ;to see why that's a bad idea, keep reading.
         PLA
         STA $E8        ;get attacker level again
         REP #$20       ;Set 16-bit Accumulator
         LDA $E9
         XBA            ;A = bottom two bytes of the first multiplication
                        ;result..  typically, we'll always have zero in the
                        ;top byte, so we can ignore it.  but with a 255
                        ;Battle Power weapon, Gauntlet, and a character at
                        ;Level 99 with 128 Vigor, that product WILL need 3
                        ;bytes.  failure to use that top byte in our next
                        ;multiplication means we'll lose a lot of damage.
                        ;BUG!

         JSR C247B7     ;multiply 16-bit result of [Level * Attack] by
                        ;our 8-bit level again, and put the new 24-bit
                        ;product in Variables $E8 thru $EA.
                        ;16-bit A will hold the new product DIV 256.
         STA $11B0      ;Maximum Damage
         CPX #$08       ;If Player then multiply $11B0 by 3/2
         BCS C22C1F     ;And add Battle Power
         LDA $11A6      ;Battle Power
         AND #$00FF
         ASL
         ADC $11B0      ;Maximum Damage
         LSR
         CLC
         ADC $11B0      ;Maximum Damage
         STA $11B0      ;Maximum Damage
         LDA $3C58,X
         LSR
         BCC C22C0B     ;Check for offering
         LSR $11B0      ;Halves damage
C22C0B:  BIT #$0008
         BEQ C22C1F     ;Check for Genji Glove
         LDA $11B0      ;Maximum Damage
         LSR
         LSR
         EOR #$FFFF
         SEC
         ADC $11B0      ;Maximum Damage
         STA $11B0      ;Subtract 1/4 from Maximum Damage
C22C1F:  PLP
         RTS


;Put attacker level [or Sketcher if applicable] in $11AF

C22C21:  PHX
         LDA $3417      ;get Sketcher
         BMI C22C28     ;branch if null
         TAX            ;if there's a valid Sketcher, use their Level
                        ;for attack
C22C28:  LDA $3B18,X    ;attacker Level
         STA $11AF      ;save one of above as attack's level
         PLX
         RTS


;Load enemy name and stats
;Coming into function: A = Enemy Number.  Y = in-battle enemy index, should be between
; 8 and 18d)
;throughout this function, "main enemy" will mean the enemy referenced by the A and Y
; values that are initially passed to the function.  "loop enemy" will mean the enemy
; currently referenced by the iterator of the loop that compares the main enemy to all
; other enemies in the battle.)

C22C30:  PHX
         PHP
         REP #$30       ;16-bit accumulator and index registers
         STA $1FF9,Y    ;save 16-bit enemy number
         STA $33A8,Y    ;make another copy.  this variable can change for
                        ;characters due to Rage, but monsters don't Rage,
                        ;so it should stay put for them.
         JSR C22D71     ;read enemy command script.  function explicitly
                        ;preserves A and X, doesn't seem to touch Y.
         ASL
         ASL
         PHA            ;Put on stack
         TAX            ;enemy number * 4.  there are 4 bytes for
                        ;steal+win slots
         LDA $CF3000,X
         STA $3308,Y    ;enemy steal slots
         PLA
         ASL            ;enemy number * 8
         PHA            ;save it
         PHX            ;push enemy number * 4
         PHY            ;push 8-18 enemy index
         TAX
         LDA $1FF9,Y    ;get enemy number
         STA $3380,Y    ;Store it in the name structure.
                        ;$3380 is responsible for the listing of enemy
                        ;names in battle.  Whatever reads from that
                        ;structure ensures there's no duplicates -- e.g.
                        ;if there's 2 Leafers, "Leafer" is just displayed once.
                        ;And if the code below didn't have bugs,
                        ;2 *different* Mag Roaders would yield only one
                        ;"Mag Roader" display, as it works in FF6j.
         TDC
         TAY            ;Y = 0
C22C56:  LDA $CFC050,X  ;enemy names
         STA $00F8,Y    ;store name in temporary string
         INX
         INX
         INY
         INY
         CPY #$0008
         BCC C22C56     ;loop until 8 characters of name are read
         LDY #$0012     ;point to last enemy in battle
C22C69:  LDA $1FF9,Y    ;get number of enemy
         BMI C22C96     ;if 16-bit enemy number is negative, no enemy in slot,
                        ;so skip it
         PHY
         ASL
         ASL
         ASL
         TAX            ;enemy # * 8
         TDC
         TAY            ;Y = 0
C22C75:  LDA $00F8,Y
         CMP $CFC050,X  ;compare name in temporary string to name of
                        ;loop enemy
         CLC
         BNE C22C88     ;if they're not equal, exit loop
         INX
         INX
         INY
         INY
         CPY #$0008
         BCC C22C75     ;compare all the 1st 8 characters of the names as long
                        ;as they keep matching
C22C88:  PLY            ;Y points to in-battle index of loop enemy
         BCC C22C96     ;if we exited string comparison early, the names
                        ;don't match, so branch
         LDA $01,S
         TAX            ;retrieve in-battle enemy index passed to function
         LDA $1FF9,Y    ;number of loop enemy
         STA $3380,X    ;If the strings did match, store enemy # of loop
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
                        ;like Mag Roader will have duplicate listings.
                        ;Also, you can make an enemy name be wrongly OMITTED
                        ;thru clever renaming and grouping of enemies
                        ;try giving Enemy #0 and #4 the same name --
                        ;e.g. "gangster" -- and put Enemy #0 and #5 in a
                        ;formation together or really bad luck.

                        ;A patch for this function has been released
                        ;see http://masterzed.cavesofnarshe.com/

         BRA C22C9D     ;we had a match, so exit the crazy loop
C22C96:  DEY
         DEY
         CPY #$0008
         BCS C22C69     ;loop and compare string to all enemies in battle
C22C9D:  PLY            ;retrieve initial 8-18 enemy index
         PLX            ;retrieve initial Enemy Number * 4
         PLA            ;retrieve initial Enemy Number * 8
         ASL
         ASL
         TAX            ;X = enemy # * 4 * 8.  Monster data block at $CF0000
                        ;is 32 bytes

         LDA $CF0005,X  ;bottom = Defense, top = Magic Defense
         STA $3BB8,Y
         LDA $CF000C,X  ;Experience
         STA $3D84,Y
         LDA $CF000E,X  ;GP
         STA $3D98,Y
         LDA $3A46
         BMI C22CE4     ;test bit 7 of $3A47.  branch if there was an enemy
                        ;formation # switch, and it designates that the new
                        ;enemies retain HP and Max HP from the current formation.
         LDA $CF000A,X  ;Max MP
         STA $3C08,Y    ;copy to Current MP
         STA $3C30,Y    ;copy to Max MP
         LDA $CF0008,X  ;Max HP
         STA $3BF4,Y    ;copy to Current HP
         STA $3C1C,Y    ;copy to Max HP
         LDA $3ED4      ;Battle formation
         CMP #$01CF
         BNE C22CE4     ;Branch if not Doom Gaze's formation
         STY $33FA      ;save which monster is Doom Gaze; was initially FFh
         LDA $3EBE      ;Doom Gaze's HP
         BEQ C22CE4
         STA $3BF4,Y    ;Set current HP to Doom Gaze's HP
C22CE4:  SEP #$21       ;Set 8-bit Accumulator
         LDA $3C1D,Y    ;High byte of max HP
         LSR
         CMP #$19
         BCC C22CF0
         LDA #$17       ;Stamina = (Max HP / 512 + 16. If this number
                        ;is greater than 40, then the monster's stamina is
                        ;set to 40
C22CF0:  ADC #$10
         STA $3B40,Y    ;Stamina
         LDA $CF0001,X
         STA $3B68,Y    ;Battle Power
         LDA $CF001A,X
         STA $3CA8,Y    ;Monster's regular weapon graphic
         LDA $CF0003,X  ;Evade
         JSR C22861
         STA $3B54,Y    ;255 - Evade * 2 + 1
         LDA $CF0004,X  ;MBlock
         JSR C22861
         STA $3B55,Y    ;255 - MBlock * 2 + 1
         LDA $CF0002,X
         STA $3B7C,Y    ;Hit Rate
         LDA $CF0010,X
         STA $3B18,Y    ;Level
         LDA $CF0000,X
         STA $3B19,Y    ;Speed
         LDA $CF0007,X  ;Magic Power
         JSR C247D6     ;* 1.5
         STA $3B41,Y    ;Magic Power
         LDA $CF001E,X  ;monster status byte 4 and miscellaneous properties
         AND #$82       ;only keep Float and Enemy Runic
         ORA $3E4C,Y
         STA $3E4C,Y    ;turn them on in Retort/Runic/etc byte
         LDA $CF0013,X
         STA $3C80,Y    ;Special Byte 2
         JSR C22DC1     ;load enemy elemental reactions, statuses and
                        ;status protection, metamorph info, special info
                        ;like human/undead/etc
         LDX $33A8,Y    ;get enemy number
         LDA $CF37C0,X  ;get Enemy Special Move graphic
         STA $3C81,Y
         SEP #$10
         JSR C22D99     ;Carry will be set if the monster is present and has
                        ;the "Attack First" attribute, clear otherwise
         TDC
         ROR
         TSB $B1        ;if Carry is set, turn on Bit 7 of $B1
         JSR C24B5A
         AND #$07       ;random number: 0-7
         CLC
         ADC #$38       ;add 56
         STA $3B2C,Y    ;save monster Vigor as a random number from 56 to 63
         TYX
         JSR C22650     ;deal with Instant Death protection, and Poison elemental
                        ;nullification giving immunity to Poison status
         PLP
         PLX
         RTS


;Read command script at start of combat
;A = Monster number

C22D71:  PHX
         PHA            ;Put on stack
         PHP
         REP #$20
         ASL
         TAX
         LDA $CF8400,X  ;Monster command script pointers
         STA $3254,Y    ;Offset of main command script
         TAX
         SEP #$20
C22D82:  JSR C21A43     ;Read command script, up through an FEh or FFh
                        ;command, advancing position in X
         INC
         BNE C22D82     ;If FFh wasn't the last thing read, we're not at
                        ;end of main command script, so loop and read more
         LDA $CF8700,X  ;Monster command scripts
         INC
         BEQ C22D95     ;if first byte of counterattack script is FFh, it's
                        ;empty, so skip saving the index
         REP #$20       ;Set 16-bit Accumulator
         TXA
         STA $3268,Y    ;Offset of counterattack script
C22D95:  PLP
         PLA
         PLX
         RTS


C22D99:  PHX
         TYX
         JSR C22DA0
         PLX
         RTS


;Handle "Attack First" property for monster
;Also, returns Carry clear if Attack First unset, Carry set if it's set.)

C22DA0:  CLC
         LDA $3C80,X
         BIT #$02       ;is "Attack First" set in Misc/Special enemy byte?
         BEQ C22DC0     ;if not, exit
         LDA $3AA0,X
         BIT #$01
         BEQ C22DC0     ;exit if enemy not present?
         ORA #$08
         STA $3AA0,X
         STZ $3219,X    ;zero top byte of ATB Timer
         LDA #$FF
         STA $3AB5,X    ;max out top byte of enemy's Wait Timer, which
                        ;means they'll spend essentially no time in
                        ;the monster equivalent to a ready stance.
                        ;normally, monsters do this by having a 0 "Time to
                        ;Wait" in $322C, but since this function is doing
                        ;things earlier and $322C is still FFh, we instead
                        ;fill out the timer to meet the threshold.
         JSR C24E66     ;put monster in the Wait to Attack queue
         SEC
C22DC0:  RTS


;Load monster's special attack, elemental properties, statuses, status immunities,
; Metamorph info, special properties like Human/Undead/Dies at MP=0 , etc)

C22DC1:  PHP
         LDA $CF001F,X  ;Special attack
         STA $322D,Y
         LDA $CF0019,X  ;elemental weaknesses
         ORA $3BE0,Y
         STA $3BE0,Y    ;add to existing weaknesses
         LDA $CF0016,X  ;blocked status byte 3
         EOR #$FF       ;invert it
         AND $3330,Y
         STA $3330,Y    ;combine with whatever was already blocked
         LDA #$FF
         AND $3331,Y
         STA $3331,Y    ;block no additional statuses in byte 4
         REP #$20       ;Set 16-bit Accumulator
         LDA $CF001B,X  ;monster status bytes 1-2
         STA $3DD4,Y    ;copy into "status to set" bytes
         LDA $CF001D,X  ;get monster status bytes 3-4
         PHA            ;Put on stack
         AND #$0001
         LSR
         ROR
         ORA $01,S      ;this moves Byte 3,Bit 0 into Byte 4,Bit 7 position
                        ;it turns out "Dance" in B3,b0 is permanent float,
                        ;while B4,b7 is a dispellable float
         AND #$84FE     ;filter out character stats like dog and rage
                        ;in byte 4, only Float and Life 3 are kept
         STA $3DE8,Y    ;put in "status to set"
         PLA
         XBA            ;now swap enemy status bytes 3<->4 within A
         LSR
         BCC C22E10     ;if byte4, bit 0 (aka "Rage") had not been set, branch
         LDA $3C58,Y
         ORA #$0040     ;Set True Knight effect?
         STA $3C58,Y
C22E10:  LDA $CF001C,X  ;monster status bytes 2-3
         ORA $3C6C,Y    ;this makes a copy of ^, used in procs like c2/2675
         STA $3C6C,Y
         LDA $CF0014,X  ;blocked status bytes 1-2
         EOR #$FFFF     ;invert 'em
         AND $331C,Y
         STA $331C,Y    ;add to existing blockages
         LDA $CF0017,X  ;elements absorbed and nullified
         ORA $3BCC,Y
         STA $3BCC,Y    ;add to existing absorptions and nullifications
         LDA $CF0011,X
         STA $3C94,Y    ;$3C94 = Metamorph info
                        ;$3C95 = Special Byte 3: Dies at 0 MP, No name, Human,
                        ; Auto critical if Imp, Undead
         PLP
         RTS


;Determine if front, back, pincer, or side attack

C22E3A:  LDA $3A6D
         LSR
         LSR            ;Put Back Guard effect into Carry
         LDA $2F48      ;Get extra enemy formation data, byte 0, top half, inverted
         BCC C22E50     ;Branch if no Back Guard
         BIT #$B0       ;Are Side, Back, or Normal attacks allowed?
         BEQ C22E4A     ;If only Pincer or nothing[??] allowed, branch
         AND #$B0       ;Otherwise, disable Pincer
C22E4A:  BIT #$D0       ;Are Side, Pincer, or Normal attacks allowed?
         BEQ C22E50     ;If only Back or nothing[??] allowed, branch
         AND #$D0       ;Otherwise, disable Back
C22E50:  PHA            ;Put on stack
         LDA $3A76      ;Number of present and living characters in party
         CMP #$03
         PLA
         BCS C22E5F     ;If 3 or more in party, branch
         BIT #$70       ;Are any of Normal, Back, or Pincer allowed?
         BEQ C22E5F     ;If only Side or nothing[??] allowed, branch
         AND #$70       ;Otherwise, disable Side attack
C22E5F:  LDX #$10
         JSR C25247     ;Randomly choose attack type.  If some fictional jackass
                        ;masked them all, we enter an.. INFINITE LOOP!
         STX $201F      ;Save encounter type:  0 = Front, 1 = Back,
                        ;                      2 = Pincer, 3 = Side
         RTS


;Disable Veldt return on all but Front attack, change character rows for Pincer/Back or see
; if preemptive attack for Front/Side, copy rows to graphics data)

C22E68:  LDX $201F      ;get encounter type:  0 = front, 1 = back,
                        ;2 = pincer, 3 = side
         CPX #$00
         BEQ C22E74     ;if front attack, branch
         LDA #$01
         TRB $11E4      ;mark Gau as not available to return from Veldt leap
C22E74:  TXA
         ASL
         TAX            ;multiply encounter type by 2, so it acts as index
                        ;into function pointers
         JSR (C22E93,X) ;Change rows for pincer and back, see if preemptive attack
                        ;for front and side
         LDX #$06
C22E7C:  PHX
         LDA $3AA1,X
         AND #$20       ;Isolate row: 0 = Front, 1 = Back
         PHA            ;Put on stack
         TXA
         ASL
         ASL
         ASL
         ASL
         TAX
         PLA
         STA $2EC5,X    ;copy row to Bit 5 of some graphics variable
         PLX
         DEX
         DEX
         BPL C22E7C     ;iterate for all 4 characters
         RTS


;Pointers to functions that do stuff based on battle formation

C22E93: dw C22E9B     ;(Normal attack)
      : dw C22ECE     ;(Back attack)
      : dw C22EC1     ;(Pincer attack)
      : dw C22E9B     ;(Side attack)


;Determines if a battle is a preemptive attack
;Preemptive attack chance = 1 in 8 for normal attacks, 7 in 32 for side attacks)
;Gale Hairpin doubles chance)

C22E9B:  LDA $B1
         BMI C22EC0     ;Exit function if bit 7 of $B1 is set.  that is,
                        ;if at least one active monster in the formation
                        ;has the "Attack First" property.
         LDA $2F4B      ;load formation data, byte 3
         BIT #$04       ;is "hide starting messages" set?
         BNE C22EC0     ;exit if so
         TXA            ;coming in, X is 0 [Front] or 6 [Side]
         ASL
         ASL
         ORA #$20
         STA $EE        ;$EE = $201F * 8 + #$20.  so pre-emptive
                        ;rate is #$20 or #$38.
         LDA $3A6D
         LSR
         BCC C22EB5     ;Branch if no Gale Hairpin equipped
         ASL $EE        ;Double chance of preemptive attack
C22EB5:  JSR C24B5A     ;random number 0 to 255
         CMP $EE        ;compare it against pre-emptive rate
         BCS C22EC0     ;Branch if random number >= $EE, meaning
                        ;no pre-emptive strike
         LDA #$40
         TSB $B0        ;Set preemptive attack
C22EC0:  RTS


;Sets all characters to front row for pincer attacks

C22EC1:  LDX #$06
C22EC3:  LDA #$DF
         JSR C20A43     ;Sets character X to front row, by clearing
                        ;Bit 5 of $3AA1,X
         DEX
         DEX
         BPL C22EC3     ;iterate for all 4 characters
         BRA C22EDC
 

;Switches characters' row placements for back attacks

C22ECE:  LDX #$06
C22ED0:  LDA $3AA1,X
         EOR #$20
         STA $3AA1,X    ;Toggle Row
         DEX
         DEX
         BPL C22ED0     ;iterate for all 4 characters
C22EDC:  LDA #$20
         TSB $B1        ;???
         RTS


;Initialize some enemy presence variables, and load enemy names and stats

C22EE1:  PHP
         REP #$10       ;Set 16-bit X and Y
         LDA $3F45      ;get enemy presence byte from monster formation data
         LDX #$000A
         ASL
         ASL            ;move 6 relevant bits into top of byte, as there's
                        ;only 6 possible enemies
C22EEC:  STZ $3AA8,X    ;mark enemy as absent to start
         ASL
         ROL $3AA8,X    ;$3AA8 = 1 for present enemy, 0 for absent
         DEX
         DEX
         BPL C22EEC     ;loop for all 6 enemies
         LDA $3F52      ;get boss switches byte of monster formation data
         ASL
         ASL            ;move 6 relevant bits into top of byte
         STA $EE
         LDX #$0005
         LDY #$0012     ;Y = onscreen index of enemy, should be between
                        ;8 and 18d
C22F04:  TDC
         ASL $3A73      ;prepare to set next bit for which monsters are in
                        ;template/formation.  this is initialized to 0
                        ;at C2/23F3.
         ASL $EE        ;get boss bit for current enemy
         ROL
         XBA            ;save boss bit in top of A
         LDA $3A97      ;FFh in Colosseum, 00h elsewhere
         ASL            ;Carry = whether in Colosseum
         LDA $3F46,X    ;get enemy number from monster formation data
         BCC C22F1A     ;branch if not in Colosseum
         LDA $0206      ;enemy number, passed by Colosseum setup in Bank C3
         BRA C22F1E     ;the Colosseum only supports enemies 0-255, so branch
                        ;immediately to check the boss bit, since we know
                        ;any enemy # > 256 is unacceptable.
C22F1A:  CMP #$FF
         BNE C22F22     ;branch if bottom byte of enemy # isn't 255.  if it
                        ;is 255, it might be empty.
C22F1E:  XBA
         BNE C22F28     ;if the boss bit is set, the enemy slot's empty/unused,
                        ;and we skip its stats.  otherwise, it holds Pugs [or
                        ;for Colosseum, it's the desired slot], and it's valid.
         XBA
C22F22:  JSR C22C30     ;load enemy name and stats
         INC $3A73      ;which monsters are in template/formation: turn on
                        ;bit for the current enemy formation position
C22F28:  DEY
         DEY
         DEX
         BPL C22F04     ;iterate for all 6 enemies
         PLP
         RTS


;At battle start, load some character properties, and set up special event if indicated
; by formation or if Leapt Gau is eligible to return)

C22F2F:  PHP
         REP #$10       ;Set 16-bit X & Y
         STZ $FC        ;start off assuming 0 characters in party
         STZ $B8
         LDA $3EE0
         BNE C22F75     ;branch if not in final 4-tier multi-battle
         LDX #$0000     ;start looking at first character slot
C22F3E:  LDA #$FF
         STA $3ED9,X
         CMP $3ED8,X    ;Which character it is
         BNE C22F6C     ;if character # was actually defined, don't use the
                        ;list to determine this character
         LDY #$0000
C22F4B:  LDA $0205,Y    ;get 0-15 character roster position from preferred
                        ;order list set pre-battle
         CMP #$FF
         BEQ C22F66     ;if no character in slot, skip to next one
         XBA
         LDA #$FF
         STA $0205,Y    ;null out the entry from the pre-chosen list
         LDA #$25
         JSR C24781     ;multiply by 37, size of character info block
         TAY            ;Y is now index into roster info
         LDA $1600,Y    ;get actual character #
                        ;can replace last 4 instructions with "JSR C230DE"
         STA $3ED8,X    ;save Which Character it is
         BRA C22F6C     ;we've found our party member, so exit loop,
                        ;and move onto next party slot.
C22F66:  INY            ;check next character
         CPY #$000C
         BCC C22F4B     ;loop for all 12 preferred character slots
C22F6C:  INX
         INX
         CPX #$0008
         BCC C22F3E     ;loop for all 4 party members
         BRA C22FD9     ;since we're in the final battle, we know we're not
                        ;in the Colosseum or on the Veldt, so skip those
                        ;checks.  also skip the party initialization loop
                        ;at C2/2F8C.
C22F75:  LDX $3ED4      ;Battle formation
         CPX #$023E     ;Shadow at Colosseum formation
         BCC C22F8C     ;if not ^ or Colosseum formation #575, branch
         LDA $0208
         STA $3ED8      ;Set "Which Character this is" to our chosen
                        ;combatant.
         LDA #$01
         TSB $B8        ;will be checked in C2/27A8
         DEC $3A97      ;set $3A97 to FFh.  future checks will look at Bit 7
                        ;to determine we're in the Colosseum.
         BRA C22FD9     ;we're in the Colosseum using a single character
                        ;to fight, so skip the party initialization loop.
C22F8C:  LDY #$000F
C22F8F:  LDA $1850,Y    ;get character roster information
                        ;Bit 7: 1 = party leader, as set in non-overworld areas
                        ;Bit 6: main menu presence?
                        ;Bit 5: row, 0 = front, 1 = back
                        ;Bit 3-4: position in party, 0-3
                        ;Bit 0-2: which party in; 1-3, or 0 if none
         STA $FE
         AND #$07       ;isolate which party character is in.  don't know
                        ;why it takes 3 bits rather than 2.
         CMP $1A6D      ;compare to Which Party is Active, 1-3
         BNE C22FAD     ;branch if not equal
         PHY
         INC $FC        ;increment count of characters in active party
         TDC
         LDA $FE
         AND #$18       ;isolate the position of character in party
         LSR
         LSR
         TAX            ;convert to a 0,2,4,6 index
         JSR C230DC     ;get ID of character in roster slot Y
         STA $3ED8,X    ;save "which character it is"
         PLY
C22FAD:  DEY
         BPL C22F8F     ;iterate for all 16 roster positions
         LDA $1EDF
         BIT #$08       ;is Gau enlisted and not Leapt?
         BNE C22FC3     ;branch if so
         LDA $3F4B      ;get monster index of enemy #6 in formation
         INC
         BNE C22FC3     ;branch if an enemy is in the slot.  thankfully, there's
                        ;no formation with Pugs [enemy #255] in Slot #6, as this
                        ;code makes no distinction between that and a nonexistent
                        ;enemy.  one problem i noticed is that if you're in
                        ;a Veldt battle where Gau's destined to return, the 6th
                        ;Pugs will often be untargetable.
         LDA $FC        ;number of characters in party
         CMP #$04
         BCC C22FC8     ;branch if less than 4
C22FC3:  LDA #$01
         TRB $11E4      ;clear Gau as being leapt and available to return on
                        ;Veldt
C22FC8:  LDA #$01
         BIT $11E4      ;set when fighting on Veldt, Gau is Leapt, and he's
                        ;available to return.
         BEQ C22FD9     ;branch if unset
         LDA #$0A
         STA $2F4A      ;extra enemy formation data, byte 2.  store special
                        ;event.
         LDA #$80
         TSB $2F49      ;extra enemy formation data, byte 1: activate
                        ;special event
C22FD9:  LDA $2F49
         BPL C2304A     ;if no special event active, branch
         LDA $2F4A      ;special event number
         XBA
         LDA #$18
         JSR C24781     ;multiply by 24 bytes to access data structure
         TAX
         LDA $D0FD00,X  ;get first byte of formation special event data
         BPL C22FFA
         LDY #$0006
C22FF1:  LDA #$FF
         STA $3ED8,Y    ;store null in Which Character it is
         DEY
         DEY
         BPL C22FF1     ;iterate for all 4 party members
C22FFA:  LDY #$0004
C22FFD:  PHY
         LDA $D0FD04,X  ;character we want to install
         CMP #$FF
         BEQ C23041     ;branch if undefined
         AND #$3F       ;isolate character to install in bottom 6 bits
         LDY #$0006
C2300B:  CMP $3ED8,Y    ;Which character is current party member
         BEQ C23023     ;if one of characters in party already matches
                        ;desired character to install, branch and exit loop
         DEY
         DEY
         BPL C2300B     ;iterate through all 4 party members
C23014:  INY
         INY
         LDA $3ED8,Y    ;Which character it is
         INC
         BEQ C23023     ;if the current character is null, branch and
                        ;exit loop
         CPY #$0006
         BCC C23014     ;loop through all 4 characters in party
         BRA C23041     ;we couldn't find the desired character to install
                        ;already present, nor a null slot to accomodate them,
                        ;so skip to next entry in the battle event data.
C23023:  LDA $3018,Y
         TSB $B8        ;will be checked in C2/27A8
         REP #$20       ;Set 16-bit Accumulator
         LDA $D0FD04,X  ;character we want to install
         STA $3ED8,Y    ;save in Which Character it is
         SEP #$20       ;Set 8-bit Accumulator
         LDA #$01       ;top byte of monster # is always 1
         XBA
         LDA $D0FD06,X  ;get bottom byte of monster # from battle event
                        ;data
         CMP #$FF       ;is our monster # 511, meaning it's null?
         BEQ C23041     ;branch if so
         JSR C22D71     ;read command script at start of combat.
                        ;A = monster num
C23041:  PLY
         INX
         INX
         INX
         INX
         INX
         DEY
         BNE C22FFD
 
C2304A:  LDX #$0006
C2304D:  LDA $3ED8,X    ;which character it is
         CMP #$FF
         BEQ C230D3     ;Branch if none (unoccupied slot)
         ASL            ;check bit 7 of which character it is
         BCS C2305A     ;if set, branch
         INC $3AA0,X    ;mark character as onscreen?
C2305A:  ASL            ;check bit 6 of which character it is
         BCC C23065     ;if unset, branch
         PHA            ;save shifted "Which Character" byte
         LDA $3018,X
         TSB $3A40      ;mark character as acting as enemy
         PLA
C23065:  LSR
         LSR            ;original Which Character byte, except top 2 bits
                        ;are zeroed
         STA $3ED8,X
         LDY #$000F
C2306D:  PHY            ;save loop variable
         PHA            ;save Which Character
         LDA $1850,Y
         AND #$20       ;Isolate character row.  clear if Front, set if Back.
         STA $FE
         JSR C230DC     ;get ID of character in roster slot Y
         CMP $01,S
         BNE C230CE     ;skip character if ID of roster member doesn't match
                        ;value of Which Character byte for this party slot
         PHX            ;save 0,2,4,6 index of character
         PHA            ;save character ID
         LDA $FE
         STA $3AA1,X    ;save character row in Special Properties
         LDA $3ED9,X    ;should be FFh, unless a special event installed this
                        ;character, in which case it'll hold their sprite #
         PHA            ;Put on stack
         LDA $06,S      ;retrieve loop variable of 0 to 15
         STA $3ED9,X    ;save our roster position #
         TDC
         TXA            ;put onscreen character index in A
         ASL
         ASL
         ASL
         ASL
         TAX
         PLA
         CMP #$FF       ;was there a valid sprite supplied by special event?
         BNE C2309C     ;branch if so
         LDA $1601,Y    ;get character's current sprite from roster data
C2309C:  STA $2EAE,X    ;save battle sprite
         TDC
         PLA            ;retrieve character ID
         STA $2EC6,X
         CMP #$0E       ;is it Banon or higher?  set Carry Flag accordingly
         REP #$20       ;Set 16-bit Accumulator
         PHA            ;save character ID
         LDA $1602,Y    ;1st two letters of character's name
         STA $2EAF,X
         LDA $1604,Y    ;middle two letters of character's name
         STA $2EB1,X
         LDA $1606,Y    ;last two letters of character's name
         STA $2EB3,X
         PLX            ;get character ID
         BCS C230C4     ;if character # is >= 0Eh [Banon], then don't bother
                        ;[properly] marking them for purposes of what can be
                        ;equipped on whom
         TDC            ;Clear Accumulator
         SEC            ;set carry flag
C230C0:  ROL            ;move up a bit, starting with bottom
         DEX
         BPL C230C0     ;move bit into position determined by actual # of character.
                        ;so for Character #3, only Bit #3 is on

;the following, including the next 2 instructions, is still executed for Banon and up.  seemingly,
; jibberish [the last 2 characters of the character name] is stored in that character's equippable
; items byte.  i'm not sure why this is done, but the game does have a property on these characters
; that prevents you from equipping all sorts of random crap via the Item menu in battle.)

C230C4:  PLX            ;get onscreen 0,2,4,6 index of character
         STA $3A20,X    ;related to what characters item can be equipped on.
                        ;should only be our basic 14
         TYA
         STA $3010,X    ;save offset of character info block
         SEP #$20       ;Set 8-bit Accumulator
C230CE:  PLA            ;retrieve Which Character byte
         PLY            ;retrieve loop index
         DEY
         BPL C2306D     ;iterate for all 16 character info blocks in roster
C230D3:  DEX
         DEX
         BMI C230DA
         JMP C2304D     ;iterate for all 4 party members
C230DA:  PLP
         RTS


;Get ID of character in roster slot Y

C230DC:  TYA
         XBA
C230DE:  LDA #$25       ;multiple by 37 bytes, size of character block
         JSR C24781
         TAY
         LDA $1600,Y    ;character ID, aka "Actor"
         RTS


;Loads battle formation data

C230E8:  PHP
         REP #$30       ;Set 16-bit A, X, & Y
         LDA $3EB9      ;from event bits, list of enabled formation interchanges --
                        ;that is, whether we'll be allowed to switch a formation that
                        ;matches one in the "Formations to Change From" list to the
                        ;corresponding one in the "Formations to Change To" list
         STA $EE
         LDX #$001C
C230F3:  LDA $EE        ;is this potential interchange enabled?
         BPL C23107     ;branch if not
         LDA $CF3780,X  ;read from list of Formations to Change From,
                        ;which consists of 1C4h (SrBehemoth living, and 7 blank
                        ;entries.
         CMP $11E0
         BNE C23107     ;Branch if current battle formation isn't a match.
         LDA $CF3782,X  ;get corresponding entry from list of Formations to
                        ;Change To, which consists of 1A8h (SrBehemoth undead,
                        ;and 7 blank entries.
         STA $11E0      ;update the Battle formation
C23107:  ASL $EE
         DEX
         DEX
         DEX
         DEX
         BPL C230F3     ;iterate 8 times
         LDA #$8000
         TRB $11E0      ;Clear highest bit of battle formation
         BEQ C23127     ;Branch if not rand w/ next 3
         SEP #$30
         TDC
         JSR C24B5A     ;random: 0 to 255
         AND #$03       ;0 to 3
         REP #$31       ;set 16-bit A, X and Y.  clear Carry
         ADC $11E0
         STA $11E0      ;Add 0 to 3 to battle formation
C23127:  LDA $3ED4      ;get First Battle Formation
         ASL
         LDA $11E0      ;get Current Battle formation
         BCC C23133     ;branch if First Battle Formation was already defined,
                        ;which it rarely is outside of multi-part battles like
                        ;Veldt Cave SrBehemoths or Final Kefka's Tiers
         STA $3ED4      ;if it wasn't, copy Current Formation to it
C23133:  ASL
         ASL
         TAX
         LDA $CF5902,X  ;bytes 2-3 of extra enemy formation data
         STA $2F4A
         LDA $CF5900,X  ;bytes 0-1 of extra enemy formation data
         EOR #$00F0     ;invert the top nibble of byte 0, which contains the
                        ;attack formations masked -- Front, Back, Pincer, Side
         STA $2F48
         LDA $11E0
         ASL
         ASL
         ASL
         ASL
         SEC
         SBC $11E0      ;A = Monster formation * 15
         TAX
         TDC
         TAY
C23155:  LDA $CF6200,X  ;Load Battle formation data
         STA $3F44,Y
         INX
         INX
         INY
         INY
         CPY #$0010
         BCC C23155     ;copy all 16 bytes of data
         PLP
         RTS


;Entity executes one largely unblockable hit on self

C23167:  LDA #$80
         TRB $B3        ;Set Ignore Clear
         LDA #$0C
         TSB $BA        ;Sets Can target dead/hidden entities, and
                        ;Don't retarget if target invalid
         STZ $341B      ;enable attack to hit Jumpers
         REP #$20
         LDA $3018,X
         STA $B8        ;Sets attacker as target
         SEP #$20

;Entity Executes One Hit (Loops for Multiple-Strike Attack

C2317B:  PHX
         LDA $BD
         STA $BC        ;copy turn-wide Damage Incrementor to current Damage
                        ;Incrementor
         LDA #$FF
         STA $3A82      ;Null Golem block
         STA $3A83      ;Null Dog block
         LDA $3400      ;Spell # for a second attack.  Used by the Magicite item,
                        ;weapons with normal addition magic [Flame Sabre,
                        ;Pearl Lance, etc], and Tempest.
                        ;Sketch also sets $3400, but the variable is swapped into
                        ;$B6 by the Sketch command (C2/151F rather than by this
                        ;routine.  Thus, $3400 will always be null at this point
                        ;for Sketch.
         INC
         BNE C231B3     ;Branch if there is a spell [i.e. the spell # is not FFh]

         LDA $3413      ;If Fight or Capture command, holds command number.
                        ;[Note that Rage's Battle and Special also qualify as
                        ;"Fight".]
                        ;That way, if a spell is cast by a weapon for one strike
                        ;which will overwrite the command # and attack data,
                        ;we'll be able to continue with the Fight/Capture command
                        ;and use the weapon as normal on the next strike.

                        ;If command isn't Fight or Capture, this holds FFh.
         BMI C231B3     ;branch if negative

         STA $B5        ;Restore command #
         JSR C226D3     ;Load data for command [held in A.bottom] and data of
                        ;"Battle" spell
         LDA $3A70      ;# of extra attacks - set by Quadra Slam, Dragon Horn,
                        ;Offering, etc
         INC            ;add one.  even number will check right hand, odd number
                        ;the left.  so in a Genji Glove+Offering sequence, for
                        ;instance, we'd have: 8 = Right, 7 = Left, 6 = Right,
                        ;5 = Left, 4 = Right, 3 = Left, 2 = Right, then 1 = Left
         LSR            ;put bottommost bit of # attacks in carry flag
         JSR C2299F     ;Load weapon data into attack data.
                        ;Plus Sniper Sight, Offering and more.
         LDA $11A6
         BNE C231A8
         JMP C23275     ;branch if zero battle power, which can result from a hand
                        ;without a weapon, among other things.  Fight/Capture set
                        ;the strike quantity to 2 -- or 8 if you have Offering --
                        ;regardless of whether you have Genji Glove.  thus, when
                        ;there's only 1 attack hand, this branch is what skips all
                        ;the even or odd strikes corresponding to the other hand.
C231A8:  LDA $B5
         CMP #$06
         BNE C231B3     ;branch if command isn't Capture
         LDA #$A4       ;Causes attack to also steal
         STA $11A9      ;save special effect
C231B3:  JSR C237EB     ;Set up weapon addition magic, Tempest's Wind Slash,
                        ;and Espers summoned by the Magicite item

         LDA #$20
         TRB $B2        ;Bit 5 is set to begin a turn
         BEQ C231C1     ;branch if it was already clear -- in other words, if
                        ;we're on the second strike or later of this turn.
         BIT $11A3
         BNE C231C5     ;Branch if Retarget if target invalid/dead
C231C1:  LDA #$04
         TSB $BA        ;NOTE: in $BA, the bit now means *Don't* retarget
                        ;if target dead/invalid

;To recap the above: if we're on the 1st strike, "Don't Retarget if no valid targets" will
; depend on the attack stats.  If we're on a later strike, it always gets set.  This explains
; why Genji Glove's [sans Offering] second strike will always smack the initial target, even
; if the first one killed it.  However, most multi-strike attacks -- Offering, Dragon Horn,
; and Quadra Slam/Slice -- set "Randomize Target", which makes you retarget anyway.)

C231C5:  LDA $B8
         ORA $B9
         BNE C231D3     ;branch if at least one target exists
         LDA #$04
         BIT $B3        ;is it non Dead/Petrify/Zombie-affecting,
                        ;non Magic-using Item/Tool/Throw?
         BEQ C231D3     ;branch if so
         TRB $BA        ;clear "Don't retarget if target invalid"..
                        ;iow, retarget if target invalid
C231D3:  LDA $3415      ;will be zero for: the attack performed via Sketch,
                        ;Umaro's Blizzard, Runic, Tempest's Wind Slash, and
                        ;Espers summoned with the Magicite item
         BMI C231DC     ;otherwise, it's FFh, so branch.
         LDA #$40
         TSB $BA        ;Set randomize targets
C231DC:  LDA $B3
         LSR
         BCS C231E9     ;branch if Bit 0 of $B3 set.  to my knowledge, it's
                        ;only UNset by a failed Blitz input.
         LDA #$04
         TSB $BA        ;set Don't retarget if target invalid
         STZ $B8
         STZ $B9        ;clear targets

C231E9:  JSR C23666     ;Prepare attack name for display atop screen.  Also
                        ;load a few properties for Joker Dooms.
         LDA $3417
         BMI C231F2     ;branch if Sketcher is null
         TAX            ;use Sketcher as attacker
C231F2:  LDA $3A7C
         CMP #$1E       ;is command Enemy Roulette?
         BNE C23201     ;branch if not
         STZ $B8
         STZ $B9        ;clear targets
         LDA #$04
         STA $BA        ;Don't retarget if target invalid
C23201:  LDA $11A5
         BEQ C23225     ;branch if 0 MP cost
         LDA $3EE5,X
         BIT #$08
         BNE C2321B     ;Branch if Mute
         LDA $3EE4,X
         BIT #$20       ;Check for Imp status
         BEQ C23225     ;Branch if not ^
         LDA $3410
         CMP #$23
         BEQ C23225     ;Branch if spell is Imp
C2321B:  TXA
         LSR
         XBA
         LDA #$0E
         JSR C262BF
         BRA C23275
C23225:  JSR C2352B     ;Runic function
         JSR C23838     ;Check Air Anchor action death
         JSR C22B9D     ;Damage Calculation
         JSR C20D4A     ;Atlas Armlet / Earring
         REP #$20       ;Set 16-bit Accumulator
         JSR C23292
         LDA $11A2
         LSR
         BCS C23243     ;Branch if physical attack.  this rules out True Knight
                        ;bodyguarding, which sets $A6 for its own purposes.
         LDA $A6        ;Reflected spell or Launcher/Super Ball special effect?
         BEQ C23243     ;branch if not
         JSR C23483     ;Super Ball, Launcher, and Reflected spells function
C23243:  LDA $3A30      ;get backup targets
         STA $B8        ;copy to normal targets, for next strike
         SEP #$20       ;Set 8-bit Accumulator
         JSR C24391     ;update statuses for everybody onscreen
         JSR C2363E     ;handle random addition magic for weapons,
                        ;in preparation for next strike
         LDA $3401
         CMP #$FF       ;is there text to display for the command or attack?
         BEQ C23262     ;branch if not
         XBA
         LDA #$02
         JSR C262BF     ;queue display of text?
         LDA #$FF
         STA $3401      ;no more text to display
C23262:  LDA $11A7
         BIT #$02
         BEQ C23275     ;if there's no text if spell hits, branch
         CPX #$08
         BCC C23275     ;if attacker isn't monster, branch
         LDA $B6        ;get attack/spell #
         XBA
         LDA #$02
         JSR C262BF     ;queue display of text for spell that hit
C23275:  LDA #$FF
         STA $3414      ;clear Ignore Damage Modification
         STA $3415      ;disable forced randomization, and allow backing up
                        ;of targets
         STA $341C      ;disable "strike is missable weapon spellcasting"
         LDA $3A83      ;get Dog block
         BMI C23288     ;if it didn't occur, branch
         STA $3416      ;save backup of who benefitted from Dog block,
                        ;as $3A83 will be nulled on next strike should
                        ;it be a multi-strike attack.
C23288:  PLX
         DEC $3A70      ;# more attacks set by Offering, Quadra Slam,
                        ;Dragon Horn, etc
         BMI C23291     ;if it's negative, there are no more, so exit
         PEA.w C2317B-1 ;if there are more, repeat this $317B function
C23291:  RTS


C23292:  STZ $3A5A      ;Indicates no targets as missed
         STZ $3A54      ;Indicate nobody being hit in the back
         JSR C26400     ;Zero $A0 through $AF
         JSR C2587E     ;targeting function
         PHX
         LDA $B8        ;load targets
         JSR C2520E     ;X = number of bits set in A, so # of targets
         STX $3EC9      ;save number of targets
         PLX
         JSR C2123B     ;True Knight and Love Token
         JSR C257C2
         JSR C23865     ;depending on $3415, copy targets into backup targets
                        ;and add to "already hit targets" list, or copy backup
                        ;targets into targets.
         LDA $3A4C      ;actual MP cost to caster
         BEQ C232EC     ;if there is none, skip these affordability checks
         SEC            ;set Carry for upcoming subtraction
         LDA $3C08,X    ;attacker MP
         SBC $3A4C      ;MP cost to attacker
         STZ $3A4C      ;clear MP cost
         BCS C232E0     ;branch if attacker had sufficient MP
         CPX #$08
         BCC C232CA     ;branch if character
         LDY #$12
         STY $B5
C232CA:  JSR C235AD     ;Write data in $B4 - $B7 to current slot in ($76
                        ;animation buffer, and point $3A71 to this slot
         STZ $A2
         STZ $A4
         LDA #$0002
         TRB $11A7      ;clear Text if Hits bit
         LDA #$2802
         JSR C2629B     ;Copy A to $3A28-$3A29, and copy $3A28-$3A2B variables
                        ;into ($76) animation buffer
         JMP C263DB     ;Copy $An variables to ($78) buffer
C232E0:  STA $3C08,X    ;attacker MP = attacker MP - spell MP cost
         LDA #$0080
         ORA $3204,X
         STA $3204,X    ;Set flag that will cause attacker's Magic, Esper,
                        ;and Lore menus to be refreshed
C232EC:  SEP #$20       ;Set 8-bit Accumulator
         LDA $3412
         CMP #$06       ;is attack a monster Special?
         BNE C2334F     ;branch if not
         PHX
         LDA #$02
         TSB $B2        ;Set no critical & ignore True Knight
         LSR
         TSB $A0
         LDA $3C81,X    ;get enemy Special move graphic
         STA $B7        ;save graphic index
         LDA $322D,X    ;get monster's special attack
         PHA            ;Put on stack
         ASL            ;is bit 6, "Do no damage," set?
         BPL C23311     ;if it isn't, branch
         STZ $11A6      ;clear Battle Power
         LDA #$01
         TSB $11A7      ;set to "Miss if No Status Set or Clear"
C23311:  BCC C23318     ;branch if Bit 7 wasn't set
         LDA #$20
         TSB $11A4      ;set Can't be Dodged
C23318:  PLA
         AND #$3F       ;get bottom 6 bits of monster's special attack
         CMP #$30
         BCC C23339     ;branch if value < 30h, "Absorb HP"
         CMP #$32
         BCS C23332     ;branch if value > 31h, "Absorb MP"
         LSR            ;get bottom bit
         LDA #$02
         TSB $11A4      ;turn on Redirection bit of spell
         BCC C2334E     ;branch if bottom bit of attack byte was 0
         LDA #$80
         TSB $11A3      ;Set to Concern MP
         BRA C2334E
C23332:  LDA #$04       ;s/b reached if bottom 6 bits of attack byte >= 32h.
                        ;so real examples are 32h, "Remove Reflect", and
                        ;Skull Dragon's 3Fh, which had "???" for description
         TSB $11A4      ;turn on "Lift status" spell bit
         LDA #$17       ;act is if just "Reflect" is in attack byte, so
                        ;there'll be no attack power
C23339:  CMP #$20
         BCC C23345     ;if value < 20h, there is no Attack Level boost, but
                        ;there is a status to alter
         SBC #$20
         ADC $BC
         STA $BC        ;add attack level btwn 0 and Fh, plus the carry flag
                        ;[which is always 1 here], to Damage Incrementer
         BRA C2334E     ;don't mess with statuses
C23345:  JSR C25217     ;transform the attack byte value 0 to 1F into
                        ;a spell status bit to set in $11AA, $11AB,
                        ;$11AC, or $11AD
         ORA $11AA,X
         STA $11AA,X
C2334E:  PLX
C2334F:  LDA #$40
         TSB $B2        ;Clear little Runic sword animation
         BNE C23364     ;If it wasn't set to begin with, branch over
                        ;this animation code.
         LDA #$25
         XBA
         LDA #$06
         JSR C262BF
         JSR C263DB     ;Copy $An variables to ($78) buffer
         LDA #$10
         TRB $A0
C23364:  LDA #$08
         BIT $3EF9,X
         BEQ C2336F     ;Branch if attacker not morphed
         INC $BC
         INC $BC        ;Double damage if morphed
C2336F:  LDA $11A2
         LSR
         BCC C2337E     ;Branch if magic damage
         LDA #$10
         BIT $3EE5,X
         BEQ C2337E     ;Branch if attacker not berserked
         INC $BC        ;Add 50% damage if berserk and physical attack
C2337E:  LDA $11A2
         BIT #$40
         BNE C23392     ;Branch if no split damage
         LDA $3EC9
         CMP #$02
         BCC C23392     ;Branch if only one target
         LSR $11B1
         ROR $11B0      ;Cut damage in half
C23392:  LDA #$20
         BIT $B3
         BNE C233A3     ;Branch if ignore attacker row
         BIT $3AA1,X
         BEQ C233A3     ;Branch if attacker in Front Row
         LSR $11B1
         ROR $11B0      ;Cut damage in half
C233A3:  JSR C214AD     ;Check if hitting target(s) in back
         JSR C23E7D     ;Special effect code from 42E1, once per strike
         REP #$20       ;Set 16-bit Accumulator
         LDY $3405      ;# of hits left from Super Ball/Launcher
         BMI C233B1     ;If there aren't any, those special effects aren't being
                        ;used, so jump to the normal Combat function.
                        ;If there are, we skip the Combat function, as C2/3483
                        ;more or less takes its place.
         RTS


;Combat function

C233B1:  LDY #$12
C233B3:  LDA $3018,Y
         BIT $A4
         BEQ C233C1     ;Skip if spell doesn't target that entity
         JSR C2220D     ;Determine whether attack hits
         BCC C233C1     ;branch if it hits
         TRB $A4        ;Makes attack miss target
C233C1:  DEY
         DEY
         BPL C233B3     ;Do for all 10 possible targets
         SEP #$20       ;Set 8-bit accumulator
         LDA $341C
         BMI C233D6     ;branch if not a missable weapon spellcasting
         LDA $A4
         ORA $A5
         BNE C233D6     ;Branch if at least one target hit
         LDA #$12
         STA $B5        ;use null animation for strike
C233D6:  LDA $341D
         BMI C233E5     ;branch if an insta-kill weapon hasn't activated
                        ;instant death this turn.
         LDA $A2
         ORA $A3
         BNE C233E5     ;Branch if at least one entity targetted
         LDA #$12
         STA $B5        ;use null animation for strike
C233E5:  LDA #$40
         BIT $3C95,X
         BEQ C233F2     ;Branch if not auto critical when Imp
         LSR
         BIT $3EE4,X
         BNE C2340C     ;If Attacker is imp do auto critical
C233F2:  LDA #$02
         BIT $B3
         BEQ C2340C     ;Automatic critical if bit 1 of $B3 not set
         BIT $B2
         BNE C23414     ;No critical if bit 1 of $B2 set
         BIT $BA
         BEQ C23414     ;No critical if not attacking opposition
         JSR C24B5A     ;Random Number 0 to 255
         CMP #$08       ;1 in 32 chance
         BCS C23414
         LDA $3EC9
         BEQ C23414     ;No critical if no targets
C2340C:  INC $BC        ;Critical hit x2 damage
         INC $BC
         LDA #$20
         TSB $A0        ;Set to flash screen
C23414:  JSR C235AD     ;Write data in $B4 - $B7 to current slot in ($76
                        ;animation buffer, and point $3A71 to this slot
         REP #$20
         LDA $11B0      ;Maximum Damage
         JSR C2370B     ;Increment damage function
         STA $11B0      ;Maximum Damage
         SEP #$20
         LDA $11A3
         ASL
         BPL C2342E     ;Branch if not Caster dies
         TXY
         JSR C23852     ;Kill caster
C2342E:  LDY $32B9,X    ;who's Controlling this entity?
         BMI C2343C     ;branch if nobody is
         PHX
         TYX            ;X points to controller
         LDY $32B8,X    ;Y = whom the controller is controlling
                        ;[in other words, the entity we previously
                        ; had in X]
         JSR C2372F     ;regenerate the Control menu.  it will
                        ;account for the MP cost of a spell cast
                        ;this turn, but unfortunately, the call is too
                        ;early to account for actual MP damage/healing/
                        ;draining done by the spell, so the menu will
                        ;lag a turn behind in that respect.
         PLX            ;restore X pointing to original entity
C2343C:  REP #$20
         LDY #$12
C23440:  LDA $3018,Y
         TRB $A4        ;Make attack miss target, for now
         BEQ C2346C     ;Skip if not target of attack
         BIT $3A54      ;Check if hitting back of target
         BEQ C2344E
         INC $BC        ;Increment damage if hitting back
C2344E:  JSR C235E3     ;initialize several variables for counterattack
                        ;purposes
         CPY $33F8      ;Has this target used Zinger?
         BEQ C2346C     ;If it has, branch to next target
         STZ $3A48      ;start off assuming attack did not miss this target
         JSR C24406     ;determine status to be set/removed when attack hits
                        ;miss if attack doesn't change target status
         JSR C2387E     ;Special effect code for target
         LDA $3A48
         BNE C2346C     ;Branch if attack missed this target, due to it not
                        ;changing any statuses or to checks in its special
                        ;effect
         LDA $3018,Y
C23467:  TSB $A4        ;Make attack hit target
         JSR C20B83     ;Modify Damage, Heal Undead, and Elemental modification
C2346C:  DEY
         DEY
         BPL C23440     ;iterate for all 10 entities
         JSR C262EF     ;subtract/add damage/healing from/to entities' HP or MP,
                        ;then queue damage and/or healing values for display
         JSR C236D6     ;Learn lore
         LDA $A4
         BNE C23480     ;Branch if 1 or more targets hit
         LDA #$0002
         TRB $11A7      ;Clear Text if Hits bit
C23480:  JMP C263DB     ;Copy $An variables to ($78) buffer


;Super Ball / Launcher / Reflected off targets function.
; Seems to be a specialized counterpart of the "Combat Function" at C2/33B1.
; For Super Ball / Launcher, it replaces that function.  For Reflect, this is called
; shortly after that function.)

C23483:  PHX
         PHA            ;Put on stack
         JSR C26400     ;Zero $A0 through $AF
         STZ $3A5A      ;Set no targets as missed
         SEP #$20       ;Set 8-bit Accumulator
         LDA #$22
         TSB $11A3      ;Set attack to retarget if target invalid/dead,
                        ;not reflectable
         LDA #$40
         STA $BB        ;Set to cursor start on enemy.  Note we're NOT
                        ;doing any spread-aim here, as the game hits at
                        ;most one target for each target reflected off.
                        ;Likewise, each Launcher firing or Super Ball bounce
                        ;will only hit 1 target.
         LDA #$50
         TSB $BA        ;Sets randomize target & Reflected
         LDA $B6
         STA $3A2A      ;temporary byte 3 for ($76) animation buffer
         LDX $3405      ;# more times to attack, for Super Ball or Launcher
         BMI C234AC     ;branch if negative, which should only happen if this
                        ;function was reached due to Reflection
         LDA #$10
         TRB $BA        ;Clear Reflected property
         LDA #$15
         BRA C234AE
C234AC:  LDA #$09
C234AE:  JSR C2629B     ;Copy A to $3A28, and copy $3A28-$3A2B variables into
                        ;($76) buffer
         LDA #$FF
         LDY #$09
C234B5:  STA $00A0,Y    ;$A0 thru $A9 = #$FF
         DEY
         BPL C234B5     ;iterate 10 times.  as this little loop suggests, you can't
                        ;go setting the Launcher/Super Ball effect to have more
                        ;than 10 "hits."  that means that $3405 can have a maximum
                        ;of 9, for those of you planning your own special effect.
         REP #$20       ;Set 16-bit Accumulator
         LSR $11B0      ;Half damage
         LDY #$12
C234C2:  LDA $3018,Y
         AND $01,S      ;is the target among those being "reflected off" by
                        ;Reflect/Super Ball/Launcher ?
         BEQ C2350F     ;if not, skip it
         TYX            ;save loop variable
         JSR C2587E     ;get new targets..  since the targeting at C2/3494 was set
                        ;to "cursor start on enemy" and X holds the "reflected off"
                        ;target going into the call, we're essentially performing
                        ;a reflection here
         LDA $B8        ;new targets after reflection
         BEQ C2350F     ;if there's none, skip our current loop target
         PHY
         JSR C251F9     ;Y = [Number of highest target after reflection] * 2
         PHX
         SEP #$20       ;Set 8-bit Accumulator
         TXA
         LSR
         TAX            ; [onscreen target # of reflected off target] / 2.
                        ;so characters are now 0-3, and enemies are 4-9
         LDA $3405      ;# more times to attack, for Super Ball or Launcher
         BMI C234E4     ;branch if negative, which should only happen if this
                        ;function was reached due to Reflection
         DEC $3405      ;decrement it
         TAX            ;replace reflected off target # with our iterator
                        ;for Super Ball/Launcher?
C234E4:  TYA
         LSR            ;A = bit # of highest target after reflection
         STA $A0,X      ;Reflect: $A0,reflected_off_target = new_target
                        ;Super Ball/Launcher: $A0,hit_iterator = new_target
         REP #$20       ;Set 16-bit Accumulator
         PLX
         JSR C2220D     ;Determine whether attack hits
         BCS C23509     ;branch if it misses
         STZ $3A48      ;start off assuming attack did not miss this target
         JSR C235E3     ;initialize several variables for counterattack
                        ;purposes
         JSR C24406     ;determine status to be set/removed when attack hits
                        ;miss if attack doesn't change target status
         JSR C2387E     ;special effect code for target
         LDA $3A48
         BNE C23509     ;Branch if attack missed this target, due to it not
                        ;changing any statuses or to checks in its special
                        ;effect
         LDA $3018,X
         TSB $AE        ;Set this Reflector as AN originator of the attack
                        ;graphically?  Since $AE will get overwritten later in
                        ;the case of Super Ball / Launcher, this setting only
                        ;applies to Reflection.
         JSR C20B83     ;Modify Damage, Heal Undead, and Elemental modification
C23509:  PLY
         LDX $3405      ;# more times to attack, for Super Ball or Launcher
         BPL C234C2     ;If it's positive, go again.  This means that for
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

C2350F:  DEY
         DEY
         BPL C234C2     ;loop for everybody on screen

;Uh oh..!  If there were no targets found to reflect onto above, we can reach this point
; with $3405 not being FFh.  As a result, the branch at C2/33AE will keep skipping the normal
; "Combat function" at C2/33B1..  bugging up the current battle.  This will continue until
; another Launcher/Super Ball is attempted when there are actually target(s) to hit.  C2/3483
; will then loop through those targets, bringing $3405 to a "safe" FFh in the process.)

         PLA
         PLX
         LDA #$0010
         BIT $BA        ;was there Reflection?
         BNE C23525     ;branch if so
         LDA $3018,X
         STA $AE        ;Set the missile launcher or the Super Ball thrower as
                        ;THE originator of attack graphically?
         STZ $AA
         STZ $AC
C23525:  JSR C262EF     ;subtract/add damage/healing from/to entities' HP or MP,
                        ;then queue damage and/or healing values for display
         JMP C263DB     ;Copy $An variables to ($78) buffer


;Runic Function

C2352B:  LDA $11A3
         BIT #$08       ;can this spell be absorbed by Runic?
         BEQ C235AC     ;Exits function if not
         STZ $EE
         STZ $EF        ;start off assuming no eligible Runickers
         LDY #$12
C23538:  LDA $3AA0,Y
         LSR            ;is this a valid target?
         BCC C2355E     ;branch if not
         LDA $3E4C,Y
         BIT #$06
         BEQ C2355E     ;Branch if not runic or enemy runic
         AND #$FB
         STA $3E4C,Y    ;clear Runic
         PEA $80C0      ;Sleep, Death, Petrify
         PEA $2210      ;Freeze, Hide, Stop
         JSR C25864
         BCC C2355E     ;Branch if entity has any of above ailments
         REP #$20
         LDA $3018,Y
         TSB $EE        ;mark this entity as an eligible Runicker
         SEP #$20       ;Set 8-bit Accumulator
C2355E:  DEY
         DEY            ;have we run through all 10 entities yet?
         BPL C23538     ;loop if not
         LDA $EE
         ORA $EF        ;are there any eligible Runickers?
         BEQ C235AC     ;Exits function if not
         PHX
         JSR C23865     ;depending on $3415, copy targets in $B8 into backup
                        ;targets and add to "already hit targets" list, or
                        ;benignly copy backup targets into targets in $B8
                        ;[the latter can be the case if spell is invoked via
                        ;Sketch].
         STZ $3415      ;will stop new targets set below from being copied
                        ;into backup or Mimic targets by later C2/3865 call
                        ;won't force randomization of targets, as variable is
                        ;being zeroed too late for that
         REP #$20       ;Set 16-bit Accumulator
         LDA $EE        ;get eligible Runickers
         STA $B8        ;save as targets
         JSR C2520E     ;X = # of bits set in A, i.e. the # of targets
         STZ $11AA
         STZ $11AC      ;Make attack set no statuses
         LDA #$2182
         STA $11A3      ;Set just concern MP, not reflectable, Unblockable,
                        ;Heal
         SEP #$20       ;Set 8-bit Accumulator
         LDA #$60
         STA $11A2      ;Set just ignore defense, no split damage
         TDC            ;need top half of A clear
         LDA $11A5      ;MP cost of spell
         JSR C24792     ;divide by X
         STA $11A6      ;save as Battle Power
         JSR C2385E     ;Sets level, magic power to 0
         STZ $3414      ;Skip damage modification
         LDA #$40
         TRB $B2        ;Flag little Runic sword animation
         LDA #$04
         STA $BA        ;Don't retarget if target invalid
         LDA #$03
         TRB $11A7      ;turn off text if hits and miss if status isn't set
                        ;or clear
         STZ $11A9      ;Set attack to no special effect
         PLX
C235AC:  RTS


;Write data in $B4 - $B7 to current slot in ($76 animation buffer, and make
; "previous buffer pointer" in $3A71 point to this slot)

C235AD:  PHX
         LDX $3A72      ;get ($76) animation buffer pointer
         STX $3A71      ;copy to "previous ($76) animation buffer pointer"
         PLX
         JSR C235D4     ;Copy animation data from $B4 - $B7 into $3A28 - $3A2B
                        ;variables
         JMP C2629E     ;Copy $3A28-$3A2B variables into ($76) buffer


;Update a previous entry in ($76) animation buffer with data in $B4 - $B7
;Used to change Atma Weapon length, among other things)

C235BB:  JSR C235D4     ;Copy animation data from $B4 - $B7 into $3A28 - $3A2B
                        ;variables
C235BE:  PHX            ;preserve X
         PHP
         LDX $3A72
         PHX            ;preserve animation buffer pointer
         LDX $3A71      ;get "previous ($76) animation buffer pointer"
         STX $3A72      ;copy it into current ($76) animation buffer pointer
         JSR C2629E     ;update animation data in the previous ($76 buffer
                        ;entry
         PLX
         STX $3A72      ;restore ($76) animation buffer pointer
         PLP
         PLX            ;restore X
         RTS


;Copy animation data from $B4 - $B7 into $3A28 - $3A2B variables

C235D4:  PHP
         REP #$20       ;Set 16-bit Accumulator
         LDA $B4
         STA $3A28      ;temporary bytes 1 and 2 for ($76) animation buffer
         LDA $B6
         STA $3A2A      ;temporary bytes 3 and 4 for ($76) animation buffer
         PLP
         RTS


;Initialize several variables for counterattack purposes

C235E3:  PHP
         SEP #$30
         JSR C2361B     ;Mark entity X as the last attacker of entity Y, but
                        ;50% chance not if Y already has an attacker this turn
         TXA
         STA $3290,Y    ;save attacker [or reflector if reflection involved] #
         LDA $3A7C
         STA $3D48,Y    ;save command #
         LDA $3410
         CMP #$FF
         BEQ C23601     ;branch if there's no Spell # [or a Skean/Tool/
                        ;piece of equipment using a spell] defined for attack.
         STA $3D49,Y    ;save the spell #
         TXA
         STA $3291,Y    ;save attacker [or reflector if reflection involved] #
C23601:  LDA $3411
         CMP #$FF
         BEQ C2360F     ;branch if there's no Item # [or a Skean/Tool that
                        ;doesn't use a spell] defined for attack.
         STA $3D5C,Y    ;save item #
         TXA
         STA $32A4,Y    ;save attacker [or reflector if reflection involved] #
C2360F:  LDA $11A1
         STA $3D5D,Y    ;save attack's element/s
         TXA
         STA $32A5,Y    ;save attacker [or reflector if reflection involved] #
         PLP
         RTS


;Mark entity X as the last attacker of entity Y, but 50% chance of
; not doing so if Y already has an attacker this turn)

C2361B:  PHP
         SEP #$21       ;Set 8-bit Accumulator, and set Carry
         LDA $32E0,Y
         BPL C23628     ;branch if this target doesn't yet have an attacker
                        ;[which can be a reflector, if reflection is involved]
         JSR C24B53
         BCC C2362D     ;50% chance this attacker overwrites current one
C23628:  TXA
         ROR            ; [onscreen index of attacker] / 2.
                        ;so characters are now 0-3, and enemies are 4-9
         STA $32E0,Y    ;save index in bottom 7 bits, and turn on top bit
C2362D:  PLP
         RTS


;Mark entity X as the last attacker of entity Y, unless Y already
; has an attacker this turn.  Arbitrarily set/clear flag indicating
; whether entity Y was attacked this turn.)

C2362F:  PHA            ;Put on stack
         PHP
         LDA $32E0,Y
         BMI C2363B     ;branch if this target already has an attacker for
                        ;this turn
         TXA
         ROR            ;Bits 0-6 = [onscreen index of attacker] / 2.
                        ;so characters are now 0-3, and enemies are 4-9.
                        ;Bit 7 = Carry flag passed by caller.  sadly, it's
                        ;arbitrary gibberish from three of the callers:
                        ;function C2/0C2D, function C2/384A when called
                        ;via C2/387E, and function C2/384A when called via
;                                     C23E7D.)
         STA $32E0,Y
C2363B:  PLP
         PLA
         RTS


;Weapon "addition magic"

C2363E:  LDA $B5
         CMP #$16       ;is Command Jump?
         BNE C23649     ;if not, branch
         LDA $3A70      ;are there more attacks to do from Offering /
                        ;Quadra Slam / Dragon Horn / etc?
         BNE C23665     ;if so, exit function
C23649:  LDA $3A89
         BIT #$40       ;is "cast randomly with fight" bit set in the
                        ;weapon spellcast byte?
         BEQ C23665     ;if not, Exit function
         XBA
         JSR C24B5A     ;random #, 0 to 255
         CMP #$40
         BCS C23665     ;if that # is 64 or greater, exit function.  iow, exit
                        ;3/4 of time.
         XBA
         AND #$3F       ;isolate spell # of weapon in bottom 6 bits
         STA $3400      ;save it
         LDA #$10
         TRB $B2        ;this bit distinguishes traditional "addition magic"
                        ;spellcasts from Tempest's Wind Slash in a few ways in
;                                     C237EB.)
                        ;one is that it'll cause the targeting byte to be set to
                        ;only "Cursor start on enemy" for the followup spell.
                        ;maybe the goal is to prevent the spell from targeting
                        ;multiple enemies..?  but i'm not sure when the spellcast
                        ;would even try to target anything other than the target
                        ;whacked by the weapon, unless the spell randomizes
                        ;targets, which no normal "addition magic" does.
         INC $3A70      ;increment # of attacks remaining.  since the calling
                        ;code will soon decrement this, the addition magic
                        ;should be cast with the same # of attacks remaining
                        ;as the weapon strike preceding it was.
C23665:  RTS


;Prepare attack name for display atop screen.  Also load a few properties for
; Joker Dooms.)

C23666:  LDA #$01
         TRB $B2
         BEQ C23665     ;exit if we've already called this function before on
                        ;this turn.  will stop Quadra Slam [for example] from
                        ;displaying its name on every strike.
         LDA $3412      ;get message ID
         BMI C23665     ;exit if undefined
         PHX
         TXY
         STA $3A29      ;temporary byte 2 for ($76) animation buffer
         ASL
         TAX
         LDA #$01
         STA $3A28      ;temporary byte 1 for ($76) animation buffer
         JSR (C236C4,X)
         STA $3A2A      ;temporary byte 3 for ($76) animation buffer
         PLX
         JMP C2629E     ;Copy $3A28-$3A2B variables into ($76) buffer


;Magic, non-Summoning non-Joker Doom Slot, successful Dance, Lore, Magitek,
; enemy non-Specials, and many others)
C23687:  LDA $B6        ;load attack ID
         RTS


;Item
C2368A:  LDA $3A7D
         RTS


;Esper Summon
C2368E:  SEC
         LDA $B6
         SBC #$36       ;convert attack ID to 0-26 Esper ID
         RTS


;enemy GP Rain, Health, Shock
C23694:  LDA $B5        ;load command ID
         RTS


;Enemy Special
C23697:  LDA #$11
         STA $3A28      ;temporary byte 1 for ($76) animation buffer
         LDA $33A8,Y    ;get monster ID, bottom byte
         STA $3A29      ;temporary byte 2 for ($76) animation buffer
         LDA $33A9,Y    ;get monster ID, top byte
         RTS


;Joker Dooms
C236A6:  LDA #$02
         TSB $3A46      ;set flag to let attack target normally untargetable
                        ;entities: Jumpers [err, scratch that, since they'd
                        ;have to be un-Hidden, which i don't think is
                        ;possible], Seized characters, and will ignore "Exclude
                        ;Attacker from targets" and "Abort on characters", etc.
         TRB $11A2      ;Clear miss if instant death protected
         LDA #$20
         TSB $11A4      ;Sets unblockable
         LDA #$00
         STA $3A29      ;temporary byte 2 for ($76) animation buffer
         LDA #$55       ;Joker Doom
         RTS


;Blitz
C236BB:  LDA #$00
         STA $3A29      ;temporary byte 2 for ($76) animation buffer
         LDA $3A7D
         RTS


;Pointers to code

C236C4: dw C23687   ;Magic, non-Summoning non-Joker Doom Slot, successful Dance, Lore,
                    ; Magitek, enemy non-Specials, and many others
      : dw C2368A   ;(Item [which can include a Tool or thrown weapon or skean])
      : dw C2368E   ;(Esper Summon)
      : dw C23665   ;(does nothing)
      : dw C23687   ;(SwdTech)
      : dw C23694   ;(enemy GP Rain, Health, Shock)
      : dw C23697   ;(Enemy Special)
      : dw C236A6   ;(Slot - Joker Dooms)
      : dw C236BB   ;(Blitz)


;Learn lore if casted

C236D6:  PHX
         PHP
         SEP #$20
         LDA $11A3
         BIT #$04
         BEQ C23708     ;Branch if not learn when casted
         LDY $3007
         BMI C23708     ;Exit if Strago not in party
         PEA $B0C3      ;Death, Petrify, Zombie, Dark, Sleep, Muddled, Berserk
         PEA $2310      ;Stop, Hide, Rage, Freeze
         JSR C25864
         BCC C23708     ;Exit function if any set
         LDA $B6
         SBC #$8B       ;try to convert spell ID to 0-23 Lore ID, as
                        ;8Bh [139d] is ID of first lore, Condemned.
         CLC
         JSR C25217     ;X = A DIV 8, A = 2 ^ (A MOD 8)
         CPX #$03
         BCS C23708     ;branch if spell ID was outside range of Lores; iow,
                        ;it's not a Lore
         BIT $1D29,X    ;Known lores
         BNE C23708     ;branch if already known
         ORA $3A84,X    ;add to Lores to learn
         STA $3A84,X
C23708:  PLP
         PLX
         RTS


;Damage increment function
;Damage = damage * (1 + (.5 * $BC))

C2370B:  PHY
         LDY $BC
         BEQ C2372D     ;Exit if Damage Incrementor in $BC = 0
         PHA            ;Put on stack
         LDA $B2
         ASL
         AND $11A1
         ASL
         ASL
         ASL
         PLA
         BCS C2372D     ;Exit function if Ignores Defense and bit 4 of $B3
                        ;[Ignore Damage Increment on Ignore Defense] is set
         STA $EE
         LSR $EE
C23721:  CLC
         ADC $EE        ;Add 50% damage
         BCC C23728
         TDC
         DEC            ;if overflow, set damage to 65535
C23728:  DEY
         BNE C23721     ;Do this $BC times
         STY $BC        ;Store 0 in $BC
C2372D:  PLY
         RTS


;Relm's Control menu

C2372F:  PHX
         PHY
         PHP
         REP #$31       ;set 16-bit A, X and Y.  clear Carry
         LDA C2544A,X   ;address of controlling character's menu
         ADC #$0030
         STA $002181    ;Offset for WRAM to access
         TYX
         LDA $3C08,X    ;MP of monster
         INC
         STA $EE        ;add 1, as it'll make future comparisons easier.
                        ;but it also means that assigning 65535 MP to
                        ;a monster won't work properly with Control.
         LDA $1FF9,X    ;Monster Type
         ASL
         ASL
         TAX            ;X = monster number * 4
         SEP #$20       ;set 8-bit accumulator
         TDC            ;clear A
         STA $002183    ;WRAM will access Bank 7Eh
         LDY #$0004
C23756:  TDC
         PHA            ;Put on stack
         LDA $CF3D00,X  ;get Relm's Control command
         STA $002180    ;store it in a menu
         CMP #$FF
         BEQ C23780     ;branch if the command [aka the spell #] was null
         XBA
         LDA #$0E       ;there are 14d bytes per spell in magic data
         JSR C24781     ;spell number * 14
         PHX
         TAX
         LDA $C46AC5,X  ;get MP cost
         XBA
         LDA $C46AC0,X  ;get targeting byte
         PLX            ;restore X = monster num * 4
         STA $01,S      ;replace zero value on stack from C2/3757 with
                        ;targeting byte
         CLC            ;clear carry
         LDA $EF        ;retrieve (MP of monster + 1) / 256
         BNE C23780     ;if it's nonzero, branch.  spell MP costs are
                        ;only 1 byte, so we don't have to worry whether
                        ;it's castable
         XBA            ;get MP cost of spell
         CMP $EE        ;carry will be clear if the Cost of spell is less
                        ;than (monster MP + 1), or if the foe has >= 255 MP
                        ;IOW, if the spell is affordable.
C23780:  ROR            ;rotate carry into top bit of A.  doubt the other bits
                        ;matter, given the XBA above is only done sometimes..
         STA $002180    ;write it to menu
         PLA            ;get the targeting byte, or zero if the menu entry
                        ;was null
         STA $002180    ;write it to menu
         INX
         DEY
         BNE C23756     ;iterate 4 times, once for each Control command
         PLP
         PLY
         PLX
         RTS


;Sketch/Control chance
;Returns Carry clear if successful, set if fails)

C23792:  PHX
         LDA $3B18,Y    ;Target's Level
         BCC C2379F     ;if sketch/control chance isn't boosted by equip, branch
         XBA
         LDA #$AA
         JSR C24781     ;Multiply target level by #$AA
         XBA            ;Multiply target level by 170 / 256
C2379F:  PHA            ;save target level (or target level * 170/256)
         TDC
         LDA $3B18,X    ;Attacker's Level
         XBA            ;* 256
         PLX            ;restore target level (or target level * 170/256)
         JSR C24792     ;A / X
         PHA            ;Put on stack
         CLC
         XBA
         BNE C237B3     ;Automatically hit if result of division is >= 256
         JSR C24B5A     ;random #: 0 to 255
         CMP $01,S      ;compare to result of division
C237B3:  PLA
         PLX
         RTS


;Reduce gold for GP Rain or Enemy Steal
;Gold = Gold - A (no lower than 0)
;For GP Rain: A = Level * 30 (Gold if gold < level * 30)
;For Enemy Steal: High A = Enemy level, low A = 20 (14 hex) (Enemy level * 256 + 20)
;                 (Gold if gold < (Enemy level * 256) + 20)

C237B6:  PHA            ;Put on stack
         SEC
         LDA $1860      ;party's gold, bottom 16 bits
         STA $EE
         SBC $01,S
         STA $1860      ;subtract A from gold
         SEP #$20       ;8-bit mem/acc
         LDA $1862      ;party's gold, top 8 bits
         SBC #$00
         STA $1862      ;now continue subtraction with borrow
         REP #$20       ;16-bit mem/acc
         BCS C237DA     ;branch if party's gold was >= amount thrown or stolen
         LDA $EE
         STA $01,S      ;otherwise, lower amount thrown/stolen to what the
                        ;party's gold was
         STZ $1860
         STZ $1861      ;zero the party's gold, all 3 bytes
C237DA:  PLA
         RTS


;Pick a random Esper (not Odin or Raiden

C237DC:  LDA #$19
         JSR C24B65     ;random: 0 to #$18
         CMP #$0B
         BCC C237E7     ;Branch if A < #$0B
         INC            ;Add 2 if over #$0B
         INC
C237E7:  CLC
         ADC #$36
         RTS


;Set up weapon addition magic, Tempest's Wind Slash, and Espers summoned
; by the Magicite item)

C237EB:  LDA $3400
         CMP #$FF
         BEQ C23837     ;Exit if null "spell # of second attack"
         STA $B6        ;Set spell #
         JSR C21DBF     ;Get command based on attack/spell number.
                        ;A bottom = Command #, A top = Attack #
         STA $B5        ;Set command to that type
         JSR C226D3     ;Load data for command and attack/sub-command, held
                        ;in A.bottom and A.top
         JSR C22951     ;Load Magic Power / Vigor and Level
         STZ $11A5      ;Set MP cost to 0
         LDA #$FF
         STA $3400      ;null out the "spell # for a second attack", as
                        ;we've already processed it.
         LDA #$02
         TSB $B2        ;Set no critical & ignore True Knight
         LDA #$10
         BIT $B2
         BEQ C23814     ;branch if it's weapon addition magic, which won't
                        ;let the followup spell hit anybody but the initial
                        ;weapon victim.  why the hell doesn't this just
                        ;branch directly to $3816?
         STZ $3415      ;will force randomization and skip backing up of
                        ;targets
C23814:  BNE C2382D     ;and if one changes the above branch, this could
                        ;simply be an unconditional BRA.
                        ;i'm tempted to make a Readability patch just
                        ;combining these two trivial changes..

;To be clear: Traditional weapon "addition magic" will start its journey at C2/3816.
; As far as I know, anything else will take the C2/382D path.  That includes Espers
; summoned by the Magicite item and Tempest's Wind Slash [which is technically
; addition magic, but a special case].)

         LDA #$0C
         TRB $11A3      ;Clear learn if cast, clear enable Runic
         TSB $BA        ;Set Don't retarget if target invalid, and
                        ;Can target dead/hidden targets
         LDA #$40
         STA $BB        ;Set only to cursor start on enemy [and clear any
                        ;multi-targeting ability].
         LDA #$10
         BIT $11A4
         BEQ C2382D     ;Branch if Stamina can't block
         STZ $341C      ;this makes a weapon spell -- like Soul Sabre's
                        ;Doom -- have its animation skipped entirely when
                        ;missing rather than show a "Miss" message
         BRA C23832
C2382D:  LDA #$20
         TSB $11A4      ;Set Unblockable
C23832:  LDA #$02
         TSB $11A3      ;Set Not Reflectable
C23837:  RTS


;Set attacker to die if under Air Anchor effect

C23838:  LDA $3205,X
         BIT #$04
         BNE C23849     ;Exit function if not under Air Anchor effect
         ORA #$04
         STA $3205,X    ;Clear Air Anchor effect
         LDA #$40
         TSB $11A3      ;Set caster dies
C23849:  RTS


;Mark Hide and Death statuses to be set on entity X, and mark entity X
; as last attacker of entity Y if Y doesn't have one this turn.)

C2384A:  LDA $3DE9,X
         ORA #$20
         STA $3DE9,X    ;Mark Hide status to be set
C23852:  JSR C2362F     ;Mark entity X as the last attacker of entity Y,
                        ;unless Y already has an attacker this turn.
                        ;Arbitrarily set/clear flag indicating whether
                        ;entity Y was attacked this turn.
         LDA #$80
         ORA $3DD4,X
         STA $3DD4,X    ;Mark Death status to be set
         RTS


;Sets level and magic power for attack to 0

C2385E:  STZ $11AF
         STZ $11AE
         RTS


;If Bit 7 of $3415 is set, copy targets to backup targets [used by
; next strike on turn, as well as Mimic].  Also, add targets to list
; of "already hit targets" that multi-strike attacks [like Offering,
; Quadra Slam] will use if no living targets are found.
; If Bit 7 of $3415 is clear, copy backup targets into targets.)

C23865:  PHP
         REP #$20
         LDA $3414      ;aka $3415
         BMI C23874     ;branch if Bit 7 is set -- iow, variable has its
                        ;default value of FFh
         LDA $3A30      ;get backup targets
         STA $B8        ;copy to current targets, for use by next strike
                        ;i think that doing this from C2/32AE is too early
                        ;to adequately preserve $B8, as some special
                        ;effects can change it [and none read from it
                        ;before doing so, afaik], and that this is
                        ;obsoleted by C2/3243.
         BRA C2387C
C23874:  LDA $B8        ;get current targets
         STA $3A30      ;save to backup targets [also used by C2/021E for
                        ;Mimic]
         TSB $3A4E      ;add to list of already hit targets, used if we
                        ;run out of living targets later in turn
C2387C:  PLP
         RTS


;Calls once-per-target special effect code

C2387E:  PHX
         PHY
         PHP
         SEP #$30
         LDX $11A9
         JSR (C23DCD,X)
         PLP
         PLY
         PLX
C2388C:  RTS


;Kill effect

; Slice/Scimitar special effect starts here
C2388D:  SEC
         LDA #$EE
C23890:  XBA            ;Call from Kill with "X" effect enters here,
                        ;with A = #$7E
         LDA $3AA1,Y
         BIT #$04
         BNE C2388C     ;Exit function if protected from instant death
         BCS C2389F     ;if Slice/Scimitar, skip code to make auto hit undead
         LDA $3C95,Y
         BMI C238AB     ;If Undead, don't skip activation for random or Stamina
                        ;reasons
C2389F:  JSR C24B5A     ;Random number 0 to 255
         CMP #$40
         BCS C2388C     ;Exit 75% chance
         JSR C223B2     ;Check if Stamina blocks
         BCS C2388C     ;Exit if it does
C238AB:  LDA $3A70      ;number of strikes remaining from Offering /
                        ;Dragon Horn / etc
         BEQ C238B6     ;if this is final strike, branch
         LDA $B5
         CMP #$16
         BEQ C2388C     ;Exit if Command = Jump
                        ;The last 5 instructions were added to FF3us, to avoid
                        ;a couple of bugs.
C238B6:  LDA $3018,Y
         TSB $A4        ;the caller has temporarily cleared this bit in $A4,
                        ;and will set it after return.  but we need it set now,
                        ;for our animation buffer update at C2/38EF.
         TRB $3A4E      ;Remove this [character] target from a "backup
                        ;already-hit targets" byte, which stops Offering/
                        ;Genji Glove/etc from beating on their corpse.
         LDA $3019,Y
         TSB $A5        ;see note at C2/38B9.
         TRB $3A4F      ;Remove this [monster] target from a "backup already-hit
                        ;targets byte", stopping aforementioned corpse-beating.
         LDA #$10
         TSB $A0        ;i think this is being done to stop the insta-kill Magic
                        ;animations from putting a casting circle around the
                        ;attacker [and we're doing it with $A0 rather than usual
                        ;$B0 method, because C2/57C2 has already been called].
                        ;however, neither the dice-up nor the X-kill animations
                        ;seem to need this precaution.  so who knows.
         LDA #$80
         JSR C20E32     ;Set Death in Status to Set
         STZ $341D      ;this will make C2/33B1 null the animation for each
                        ;strike in the remainder of this turn where no targets
                        ;are found.  this is part of the "corpse beating"
                        ;prevention described above.  without this instruction,
                        ;the character will wave their hand around like an
                        ;idiot.

         STZ $11A6      ;set Battle Power to 0
         LDA #$02
         STA $B5        ;save Magic as command for animation purposes
         XBA
         STA $B6        ;save attack ID for animation purposes: EEh for
                        ;Slice/Scimitar, or 7Eh for Kill with 'X'
         CMP #$EE
         BNE C238EC     ;Kill with 'X' branches
         CPY #$08       ;Check for monster or character
         BCC C238EC     ;branch if character target
         LDA $3DE9,Y
         ORA #$20
         STA $3DE9,Y    ;Set Hide in Status to Set
C238EC:  JSR C235AD     ;Write data in $B4 - $B7 to current slot in ($76
                        ;animation buffer, and point $3A71 to this slot
                        ;this matches up with the ($78 update that will be
                        ;done at C2/3480.
         JMP C263DB     ;Copy $An variables to ($78) buffer
                        ;this matches up with the ($76 update that was done
                        ;at C2/3414.


;Special Effect 4
;x2 Damage vs. Humans

C238F2:  LDA $3C95,Y
         BIT #$10
         BEQ C238FD     ;Exit if target not human
         INC $BC
         INC $BC        ;Double damage dealt
C238FD:  RTS


;Sniper/Hawk Eye effect

C238FE:  JSR C24B53     ;random: 0 or 1 in Carry flag
         BCC C238FD     ;50% chance exit
         INC $BC        ;Add 1 to damage incrementor
         LDA $3EF9,Y
         BPL C238FD     ;Exit if not target not Floating
         LDA $B5
         CMP #$00
         BNE C238FD     ;Exit if command not Fight?
         INC $BC
         INC $BC
         INC $BC        ;Add another 3 to damage incrementor
         LDA #$08
         STA $B5        ;Store Throw for *purposes of animation*
         LDA $B7        ;get graphic index
         DEC
         STA $B6        ;undo earlier adjustment, save as Throw parameter
         JMP C235BB     ;Update a previous entry in ($76 animation buffer
                        ;with data in $B4 - $B7


;Stone

C23922:  LDA $05,S
         TAX
         LDA $3B18,X    ;Attacker's level
         CMP $3B18,Y    ;Target's Level
         BNE C23933     ;If not same level, exit
         LDA #$0D       ;Add 14 to damage incrementer, as Carry is set
         ADC $BC
         STA $BC
C23933:  RTS


;Palidor

C23934:  LDA #$01
         JSR C2464C     ;sets bit 0 in $3204,Y .  indicates entity is
                        ;target/passenger of a Palidor summon this turn.
         LDA $32CC,Y    ;get entry point to entity's conventional linked
                        ;list queue
         PHA            ;Put on stack
         JSR C24E54     ;Add a record [by initializing its pointer/ID field]
                        ;to a "master list" in $3184, a collection of
                        ;linked list queues
         STA $32CC,Y    ;have entity's entry point index new addition
         TAY            ;Y = index for 8-bit record fields
         ASL
         TAX            ;X will index 16-bit fields of the record
         PLA
         CMP #$FF       ;was there previously an entry point to this
                        ;entity's queue?
         BEQ C2394E     ;branch if not
         STA $3184,Y    ;if so, have their new record link to the one(s
                        ;that was/were previously there.
                        ;so what we've done is make it so any previously
                        ;queued command(s for this character will be
                        ;executed after landing from Palidor
C2394E:  TDC
         STA $3620,X    ;new record in conventional linked list queue will
                        ;have 0 MP cost...
         REP #$20
         STA $3520,X    ;...and no initial targets
         LDA #$0016
         STA $3420,X    ;...and Jump as command [and no sub-command, as
                        ;none is needed]
         RTS


;Special effect $39 - Engulf

C2395E:  LDA $3018,Y
         TSB $3A8A      ;Set character as engulfed
         BRA C2396C     ;Branch to remove from combat code


;Bababreath from 3DCD

C23966:  LDA $3018,Y
         TSB $3A88      ;flag to remove target from party at end of battle
C2396C:  REP #$20       ;Special effect $27 & $38 & $4B jump here
                        ;Escape, Sneeze, Smoke Bomb
         LDA $3018,Y
         TSB $2F4C      ;mark target to be removed from the battlefield
         TSB $3A39      ;add to list of escaped characters
         RTS


;Dischord

C23978:  TYX
         INC $3B18,X    ;Level
         LSR $3B18,X    ;Half level rounded up
         RTS


;R. Polarity

C23980:  LDA $3AA1,Y    ;Target's Row
         EOR #$20
         STA $3AA1,Y    ;Switch
         RTS


;Wall Change

C23989:  TDC
         LDA #$FF
         JSR C2522A     ;Pick a random bit
         STA $3BE0,Y    ;Set your weakness to A
         EOR #$FF
         STA $3BCD,Y    ;Nullify all other elements
         JSR C2522A     ;Pick a random bit, not the one picked for weakness
         STA $3BCC,Y    ;Absorb that element
         RTS


;Steal function

C2399E:  LDA $05,S      ;Attacker
         TAX
         LDA #$01
         STA $3401      ;=1) (Sets message to "Doesn't have anything!"
         CPX #$08       ;Check if attacker is monster
         BCS C23A09     ;Branch if monster
         REP #$20       ;Set 16-bit accumulator
         LDA $3308,Y    ;Target's stolen items
         INC
         SEP #$21       ;Set 8-bit Accumulator AND Carry Flag
         BEQ C23A01     ;Fail to steal if no items
         INC $3401      ;now = 2) (Sets message to "Couldn't steal!!"
         LDA $3B18,X    ;Attacker's Level
         ADC #$32       ;adding 51, since Carry Flag was set
         BCS C239D8     ;Automatically steal if level >= 205
         SBC $3B18,Y    ;Subtract Target's Level, along with an extra 1 because
                        ;Carry Flag is unset at this point.  Don't worry; this
                        ;cancels out with the extra 1 from C2/39BA.
                        ;StealValue = [attacker level + 51] - [target lvl + 1]
                        ;= Attacker level + 50 - Target level
         BCC C23A01     ;Fail to steal if StealValue < 0
         BMI C239D8     ;Automatically steal if StealValue >= 128
         STA $EE        ;save StealValue
         LDA $3C45,X
         LSR
         BCC C239CF     ;Branch if no sneak ring
         ASL $EE        ;Double value
C239CF:  LDA #$64
         JSR C24B65     ;Random: 0 to 99
         CMP $EE
         BCS C23A01     ;Fail to steal if the random number >= StealValue
C239D8:  PHY
         JSR C24B5A     ;Random: 0 to 255
         CMP #$20
         BCC C239E1     ;branch 1/8 of the time, so Rare steal slot
                        ;will be checked
         INY            ;Check the 2nd [Common] slot 7/8 of the time
C239E1:  LDA $3308,Y    ;Target's stolen item
         PLY
         CMP #$FF       ;If no item
         BEQ C23A01     ;Fail to steal
         STA $2F35      ;save Item stolen for message purposes in
                        ;parameter 1, bottom byte
         STA $32F4,X    ;Store in "Acquired item"
         LDA $3018,X
         TSB $3A8C      ;flag character to have any applicable item in
                        ;$32F4,X added to inventory when turn is over.
         LDA #$FF
         STA $3308,Y    ;Set to no item to steal
         STA $3309,Y    ;in both slots
         INC $3401      ;now = 3) (Sets message to "Stole #whatever "
         RTS


;If no items to steal

C23A01:  SEP #$20
         LDA #$00
         STA $3D48,Y    ;save Fight as command for counterattack purposes
         RTS


;Steal for monsters

C23A09:  STZ $2F3A      ;clear message parameter 2, third byte
         INC $3401      ;Sets message to "Couldn't steal!!"
         JSR C24B5A     ;random #: 0 to 255
         CMP #$C0
         BCS C23A01     ;fail to steal 1/4 of the time
         DEC $3401      ;Sets message to "Doesn't have anything!"
         LDA $3B18,X    ;enemy level
         XBA
         LDA #$14       ;enemy will swipe: level * 256 + 20 gold
         REP #$20       ;set 16-bit A
         JSR C237B6     ;subtract swiped gold from party's inventory
         BEQ C23A01     ;branch if party had zero gold before
                        ;the steal
         STA $2F38      ;save gold swiped for message output in
                        ;parameter 2, bottom word
         CLC
         ADC $3D98,X    ;add amount stolen to gold possessed by enemy
         BCC C23A31     ;branch if no overflow
         TDC
         DEC            ;if sum overflowed, set enemy's gold to 65535
C23A31:  STA $3D98,X    ;update enemy's gold
         SEP #$20       ;set 8-bit A
         LDA #$3F
         STA $3401      ;Set message to "# GP was stolen!!"
         RTS


;Metamorph

C23A3C:  CPY #$08       ;Checks if target is monster
         BCC C23A8A     ;branch if not
         LDA $3C94,Y    ;Metamorph info: Morph chance in bits 5-7,
                        ;and Morph pack in bits 0-4
         PHA            ;Put on stack
         AND #$1F       ;isolate pack #
         JSR C24B53     ;Random number 0 or 1
         ROL
         JSR C24B53     ;Random number 0 or 1
         ROL
         TAX            ;now we have the Metamorph pack # in bits 2-6,
                        ;and a random 0-3 index into that pack in bits 0-1
         LDA $C47F40,X  ;get the item we're attempting to Metamorph
                        ;the enemy into
         STA $2F35      ;save it in message parameter 1, bottom byte
         LDA #$02
         STA $3A28      ;temporary byte 1 for ($76) animation buffer
         LDA #$1D
         STA $3A29      ;temporary byte 2 for ($76) animation buffer
         JSR C235BE     ;Update a previous entry in ($76 animation buffer
                        ;with data in $3A28 - $3A2B
         JSR C235AD     ;Write data in $B4 - $B7 to current slot in ($76
                        ;animation buffer, and point $3A71 to this slot
         PLA
         LSR
         LSR
         LSR
         LSR
         LSR            ;isolate 0-7 Metamorph Chance index
         TAX            ;copy it to X
         JSR C24B5A     ;Random number 0 to 255
         CMP C23DC5,X   ;compare to actual Metamorph Chance
         BCS C23A8A     ;if greater than or equal, branch and fail to
                        ;Metamorph
         LDA $05,S
         TAX
         LDA $2F35      ;get ID of Metamorphed item
         STA $32F4,X    ;save it in this character's
                        ;"Item to add to inventory" variable
         LDA $3018,X
         TSB $3A8C      ;flag this character to have their inventory
                        ;variable checked when the turn ends
         LDA #$80
         JMP C20E32     ;Mark death status to be set
C23A8A:  JMP C23B1B     ;flag Miss message


;Special Efect $56
;Debilitator

C23A8D:  TDC
         LDA $3BE0,Y    ;Elements weak against
         ORA $3EC8      ;Elements nullified by ForceField
         EOR #$FF       ;Get elements in neither category
         BEQ C23A8A     ;Miss if there aren't any
         JSR C2522A     ;Randomly pick one such element
         PHA            ;Put on stack
         JSR C251F0     ;X = Get which bit is picked
         TXA
         CLC
         ADC #$0B
         STA $3401      ;Set to display that element as text
         LDA $01,S
         ORA $3BE0,Y
         STA $3BE0,Y    ;Make weak vs. that element
         PLA
         EOR #$FF
         PHA            ;Put on stack
         AND $3BE1,Y
         STA $3BE1,Y    ;Make not resist that element
         LDA $01,S
         XBA
         PLA
         REP #$20       ;Set 16-bit accumulator
         AND $3BCC,Y
         STA $3BCC,Y    ;Make not absorb or nullify that element
         RTS


;Special effect $53
;Control

C23AC5:  CPY #$08
         BCC C23B16     ;Miss with text if target is character
         LDA $3C80,Y
         BMI C23B16     ;Miss with text if target has Can't Control bit set
         PEA $B0D2      ;Death, Petrify, Clear, Zombie, Sleep, Muddled, Berserk
         PEA $2900      ;Rage, Morph, Hide
         JSR C25864
         BCC C23B16     ;Miss w/ text if any set on target
         LDA $32B9,Y
         BPL C23B16     ;If already controlled, then miss w/text
         LDA $05,S
         TAX
         LDA $3C45,X    ;Coronet "boost Control chance" in Bit 3
         LSR
         LSR
         LSR
         LSR
         JSR C23792     ;Sketch/Control Chance - pass bit 3 of $3C45 as carry
         BCS C23B1B     ;Miss w/o text
         TYA
         STA $32B8,X    ;save who attacker is Controlling
         TXA
         STA $32B9,Y    ;save who target is Controlled by
         LDA $3019,Y
         TSB $2F54      ;cause Controllee to be visually flipped
         LDA $3E4D,X
         ORA #$01
         STA $3E4D,X    ;set a custom bit on attacker.  was added on FF3us,
                        ;because Ripplering off "spell chant" status would
                        ;cause a freezing bug on FF6j.  sadly, FF6 Advance
                        ;didn't keep this addition.
         LDA $3EF9,X
         ORA #$10
         STA $3EF9,X    ;Set Spell Chant status to attacker
         LDA $3AA1,Y
         ORA #$40
         STA $3AA1,Y    ;flag target's ATB gauge to be reset?
         JMP C2372F     ;generate the Control menu


C23B16:  LDA #$04
C23B18:  STA $3401      ;Set to display text #4
C23B1B:  REP #$20       ;Set 16-bit Accumulator
         LDA $3018,Y    ;Represents the target
         STA $3A48      ;Indicate a miss, due to the attack not changing any
                        ;statuses or due to checks in its special effect
         TSB $3A5A      ;Set target as Missed
         TRB $A4        ;Remove this target from hit targets
         RTS


;Sketch

C23B29:  CPY #$08
         BCC C23B1B     ;Miss if aimed at party
         LDA $3C80,Y
         BIT #$20
         BNE C23B64     ;Branch if target has Can't Sketch
         LDA $05,S
         TAX
         LDA $3C45,X    ;Beret "boost Sketch chance" in Bit 2
         LSR
         LSR
         LSR
         JSR C23792     ;Sketch/Control chance - pass bit 2 of $3C45 as carry
         BCS C23B1B     ;branch if sketch missed
         STY $3417      ;save Target as Sketchee
         TYA
         SBC #$07       ;subtract 8, as Carry is clear
         LSR
         STA $B7        ;save 0-5 index of our Sketched monster
         JSR C235BB     ;Update a previous entry in ($76 animation buffer
                        ;with data in $B4 - $B7
         JSR C24B5A     ;random: 0 to 255
         CMP #$40       ;75% chance for second sketch attack
         REP #$30       ;Set 16-bit Accumulator and Index registers
         LDA $1FF9,Y    ;get monster #
         ROL
         TAX
         LDA $CF4300,X
         SEP #$30       ;Set 8-bit A, X, & Y
         STA $3400      ;Set attack to sketched attack
         RTS


C23B64:  LDA #$1F
         STA $3401      ;Store can't sketch message
         BRA C23B1B     ;Make attack miss
                        ;BRA C23B18?


;Special Effect $25 (Quake

C23B6B:  LDA $3EF9,Y
         BMI C23B1B     ;If Float status set, miss
         RTS


;Leap

C23B71:  LDA $2F49
         BIT #$08       ;extra enemy formation data: is "Can't Leap" set?
         BNE C23B90     ;if so, miss with text
         LDA $3A76      ;Number of present and living characters in party
         CMP #$02
         BCC C23B90     ;if less than 2, then miss w/ text
         LDA $05,S
         TAX
         LDA $3DE9,X
         ORA #$20
         STA $3DE9,X    ;Mark Hide status to be set in attacker
         LDA #$04
         STA $3A6E      ;"End of combat" method #4, Gau leaping
         RTS


C23B90:  LDA #$05
         STA $3401      ;Set to display text #5
         JMP C23B1B     ;Miss target
                        ;JMP C23B18?


;Special Effect $50 (Possess

C23B98:  LDA $05,S
         TAX
         LDA $3018,X
         TSB $2F4C      ;mark Possessor to be removed from battlefield
                        ;what about the Possessee?
         TSB $3A88      ;flag to remove Possessor from party at end of
                        ;battle
         JSR C2384A     ;Mark Hide and Death statuses to be set on attacker in
                        ;X, and mark entity X as last attacker of target in Y
                        ;if Y doesn't have one this turn.
         PHX
         TYX
         JSR C2384A     ;Mark Hide and Death statuses to be set on target in X
         PLY            ;X now holds Possessee, and Y holds Possessor
         JMP C2361B     ;Mark entity X as the last attacker of entity Y, but
                        ;50% chance not if Y already has an attacker this turn


;Mind Blast

C23BB0:  REP #$20       ;Set 16-bit Accumulator
         JSR C244FF     ;Clear Status to Set and Status to Clear bytes
         LDA $3018,Y    ;an original target, might also be in custom list
         LDX #$06
C23BBA:  BIT $3A5C,X    ;is the target in this slot of "Mind Blast victims"
                        ;list?  [this list was created previously in the
                        ;other Mind Blast special effect function.]
         BEQ C23BC6     ;branch and check next slot if not
         PHA            ;Put on stack
         PHX
         JSR C23BD0     ;Randomly mark a status from attack data to be set
         PLX
         PLA
C23BC6:  DEX
         DEX
         BPL C23BBA     ;Do for all 4 list entries.  an entity who's listed
                        ;N times can get N statuses from this spell.
         RTS


;Evil Toot
;Sets a random status from attack data)

C23BCB:  REP #$20       ;Set 16-bit Accumulator
         JSR C244FF     ;Clear Status to Set and Status to Clear bytes
C23BD0:  LDA $11AA
         JSR C2520E     ;X = Number of statuses set by attack in bytes 1 & 2
         STX $EE
         LDA $11AC
         JSR C2520E     ;X = Number of statuses set by attack in bytes 3 & 4
         SEP #$20       ;Set 8-bit Accumulator
         TXA
         CLC
         ADC $EE        ;A = # of total statuses flagged in attack data
         JSR C24B65     ;random number: 0 to A - 1
         CMP $EE        ;Clear Carry if the random status we want to
                        ;set is in spell status byte 1 or 2
                        ;Set Carry if it's in byte 3 or 4.
         REP #$20       ;Set 16-bit Accumulator
         PHP
         LDA $11AA
         BCC C23BF4     ;branch if we're attempting to set a status
                        ;from status byte 1 or 2
         LDA $11AC      ;otherwise, it's from byte 3 or 4
C23BF4:  JSR C2522A     ;randomly pick a bit set in A
         PLP
         BCS C23BFD
         JMP C20E32     ;Set status picked bytes 1 or 2
C23BFD:  ORA $3DE8,Y    ;Set status picked bytes 3 or 4
         STA $3DE8,Y
         RTS


;Rippler Effect

C23C04:  LDA $05,S
         TAX
         REP #$20       ;Set 16-bit Accumulator
         LDA $3EE4,X    ;status bytes 1-2, caster
         AND $3EE4,Y    ;status bytes 1-2, target
         EOR #$FFFF
         STA $EE        ;save the statuses that aren't shared among caster
                        ;and target.  iow, turn on any bits that aren't
                        ;set in both.
         LDA $3EE4,X
         AND $EE        ;get statuses exclusive to caster
         STA $3DD4,Y    ;target status to set = statuses that were only set
                        ;in caster
         STA $3DFC,X    ;caster status to clear = statuses that were only set
                        ;in caster
         LDA $3EE4,Y
         AND $EE        ;get statuses exclusive to target
         STA $3DD4,X    ;caster status to set = statuses that were only set
                        ;in target
         STA $3DFC,Y    ;target status to clear = statuses that were only set
                        ;in target

         LDA $3EF8,X    ;status bytes 3-4, caster
         AND $3EF8,Y    ;status bytes 3-4, target
         EOR #$FFFF
         STA $EE        ;save the statuses that aren't shared among caster
                        ;and target.  iow, turn on any bits that aren't
                        ;set in both.
         LDA $3EF8,X
         AND $EE        ;get statuses exclusive to caster
         STA $3DE8,Y    ;target status to set = statuses that were only set
                        ;in caster
         STA $3E10,X    ;caster status to clear = statuses that were only set
                        ;in caster
         LDA $3EF8,Y
         AND $EE        ;get statuses exclusive to target
         STA $3DE8,X    ;caster status to set = statuses that were only set
                        ;in target
         STA $3E10,Y    ;target status to clear = statuses that were only set
                        ;in target
         RTS


;Exploder effect from 3DCD

C23C4C:  LDA $05,S
         TAX            ;X = attacker
         STX $EE
         CPY $EE        ;is this target the attacker?
         BNE C23C5A     ;branch if not
         LDA $3018,X
         TRB $A4        ;if so, and it's a character, clear it from hit targets.
                        ;seemingly undoing the addition to targets by the
                        ;earlier special effect function.  but the problem is,
;                                     C23467 sets the bit in $A4 again shortly after this
                        ;function returns.
C23C5A:  RTS


;Scan effect

C23C5B:  LDA $3C80,Y
         BIT #$10
         BNE C23C68     ;Branch if target has Can't Scan
         TYX
         LDA #$27
         JMP C24E91     ;queue a custom command to display all the info, in
                        ;global Special Action queue


C23C68:  LDA #$2C
         STA $3401      ;Store "Can't Scan" message
         RTS


;Suplex code from $3DCD

C23C6E:  LDA $3C80,Y
         BIT #$04       ;Is Can't Suplex set in Misc/Special enemy byte?
         BEQ C23C5A     ;If not, exit function
C23C75:  JMP C23B1B     ;Makes miss


;Special Effect $57 - Air Anchor

C23C78:  LDA $3AA1,Y
         BIT #$04
         BNE C23C75     ;Miss if instant death protected
         LDA #$13
         STA $3401      ;Display text $13 - "Move, and you're dust!"
         LDA $3205,Y
         AND #$FB
         STA $3205,Y    ;Set Air Anchor effect
C23C8C:  STZ $341A      ;Special Effect $23 -- X-Zone, Odin, etc -- jumps here
         RTS


;L? Pearl from 3DCD

C23C90:  RTS


;Charm

C23C91:  LDA $05,S
         TAX
         LDA $3394,X
         BPL C23C75     ;Miss if attacker already charmed a target
         TYA
         STA $3394,X    ;Attacker data: save which target they charmed
         TXA
         STA $3395,Y    ;Target data: save who has charmed them
         RTS


;Tapir

C23CA2:  LDA $3EE5,Y
         BPL C23C75     ;Miss if target is not asleep
         REP #$20       ;Set 16-bit Accumulator
         LDA $3C1C,Y
         STA $3BF4,Y    ;Set HP to max HP
C23CAF:  REP #$20       ;Pep Up and Elixir/Megalixir branch here
         LDA $3C30,Y
         STA $3C08,Y    ;Set MP to max MP
         RTS


;Pep Up

C23CB8:  LDA $05,S
         TAX
         JSR C2384A     ;Mark Hide and Death statuses to be set on attacker
                        ;in X, and mark entity X as last attacker of entity Y
                        ;if Y doesn't have one this turn.
         REP #$20       ;Set 16-bit Accumulator
         LDA $3018,X
         TSB $2F4C      ;mark caster to be removed from the battlefield
         STZ $3BF4,X    ;Set caster HP to 0
         STZ $3C08,X    ;Set caster MP to 0
         BRA C23CAF     ;Set target's MP to max MP


;Special Effect $2E - Seize

C23CCE:  LDA $05,S
         TAX
         LDA $3358,X    ;whom attacker is Seizing
         BPL C23C75     ;if already Seizing someone, jump to $3B1B - Miss
         CPY #$08
         BCS C23C75     ;If target is not character - Miss
         TYA
         STA $3358,X    ;save who attacker is Seizing
         TXA
         STA $3359,Y    ;save who target is Seized by
         LDA $3DAC,X
         ORA #$80
         STA $3DAC,X    ;set Seizing in monster variable visible from
                        ;script
         LDA $3018,Y
         TRB $3403      ;add target to list of Seized characters
         LDA $3AA0,Y
         AND #$7F       ;Clear bit 7
         STA $3AA0,Y
         LDA #$40
         JMP C2464C


;Discard

C23CFD:  LDA $05,S
         TAX
         LDA $3DAC,X
         AND #$7F
         STA $3DAC,X    ;clear Seizing in monster variable visible from
                        ;script
         LDA #$FF
         STA $3358,X    ;attacker Seizing nobody
         STA $3359,Y    ;target Seized by nobody
         LDA $3018,Y
         TSB $3403      ;remove target from list of Seized characters
         RTS


;Special effect $4C - Elixir and Megalixir.  In Item data, this appears as
; Special effect $04.)

C23D17:  LDA #$80
         JSR C2464C     ;Sets bit 7 in $3204,Y
         BRA C23CAF     ;Set MP to Max MP


;Overcast

C23D1E:  LDA $3E4D,Y
         ORA #$02
         STA $3E4D,Y    ;Turn on Overcast bit, which will be checked by
                        ;function C2/450D to give a dying target Zombie
                        ;instead
         RTS


;Zinger

C23D27:  LDA $05,S
         TAX
         STX $33F8      ;save attacker as the Zingerer
         STY $33F9      ;save target as who's being Zingered
         LDA $3019,X
         TSB $2F4D      ;mark attacker to be removed from the battlefield
         RTS


;Love Token

C23D37:  LDA $05,S
         TAX
         TYA
         STA $336C,X    ;Attacker data: save which target takes damage
                        ;for them
         TXA
         STA $336D,Y    ;Target data: save who they're taking damage for
         RTS


;Kill with 'X' effect
;Auto hit undead, Restores undead)

C23D43:  CLC
         LDA #$7E       ;tells function it's an x-kill weapon
         JSR C23890     ;call x-kill/dice-up function, decide whether to
                        ;activate instant kill
C23D49:  LDA $3C95,Y    ;Doom effect jumps here
         BPL C23D62     ;Exit function if not undead
         CPY #$08
         BCS C23D63     ;Branch if not character
         LDA $3DD4,Y
         AND #$7F
         STA $3DD4,Y    ;Remove Death from Status to Set
         REP #$20
         LDA $3C1C,Y
         STA $3BF4,Y    ;Fully heal HP
C23D62:  RTS


C23D63:  TDC            ;clear 16-bit A
         LDA $3DE9,Y
         ORA #$20
         STA $3DE9,Y    ;Add Hide to target's Status to Set
         LDA $3019,Y    ;get unique bit identifying this monster
         XBA
         REP #$20       ;Set 16-bit Accumulator
         STA $B8        ;save as target in $B9.  subcommand in $B8 is 0.
         LDX #$0A       ;animation type
         LDA #$0024     ;payload command of F5 monster script command.
                        ;so we're queuing Command F5 0A 00 here.
         JMP C24E91     ;queue it, in global Special Action queue


;Phantasm

C23D7C:  LDA $3E4D,Y
         ORA #$40
         STA $3E4D,Y    ;give Seizure-like quasi status to target
                        ;unnamed, but some call it HP Leak
         RTS


;Stunner
;Only a Hit Rate / 256 chance it will actually try to inflict
; statuses on the target)

C23D85:  JSR C24B5A     ;random: 0 to 255
         CMP $11A8
         BCC C23DA7     ;If less than hit rate then exit
         REP #$20       ;Set 16-bit Accumulator
         LDA $11AA      ;Spell's Status to Set bytes 1+2
         EOR #$FFFF
         AND $3DD4,Y    ;Subtract it from target's
                        ;Status to Set bytes 1+2
         STA $3DD4,Y
         LDA $11AC      ;Spell's Status to Set bytes 3+4
         EOR #$FFFF
         AND $3DE8,Y    ;Subtract it from target's
                        ;Status to Set bytes 3+4
         STA $3DE8,Y
C23DA7:  RTS


;Targeting

C23DA8:  LDA $05,S
         TAX
         TYA
         STA $32F5,X    ;Stores target
         RTS


;Fallen One

C23DB0:  REP #$20       ;Set 16-bit Accumulator
         TDC            ;Clear Accumulator
         INC
         STA $3BF4,Y    ;Store 1 in HP
         RTS


;Special effect $4A - Super Ball

C23DB8:  JSR C24B5A     ;Random Number 0 to 255
         AND #$07       ;Random Number 0 to 7
         INC            ;1 to 8
         STA $11B1      ;Set damage to 256 to 2048 in steps of 256
         STZ $11B0
         RTS


;Metamorph Chance

C23DC5: db $FF
      : db $C0
      : db $80
      : db $40
      : db $20
      : db $10
      : db $08
      : db $00


;Table for special effects code pointers 1 (once-per-target

C23DCD: dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C23D43 ;($03)
      : dw C238F2 ;($04)
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C238FE ;($08)
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C2388D ;($0D)
      : dw C2388C
      : dw C2388C
      : dw C23C5B ;($10)
      : dw C2388C
      : dw C23A3C ;($12)
      : dw C23934 ;($13)
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C23CA2 ;($17)
      : dw C2388C
      : dw C23C4C ;($19)
      : dw C2388C
      : dw C2388C
      : dw C23C90 ;($1C)
      : dw C2388C
      : dw C2388C
      : dw C23978 ;($1F)
      : dw C23CB8 ;($20)
      : dw C23C04 ;($21)
      : dw C23922 ;($22)
      : dw C23C8C ;($23)
      : dw C2388C
      : dw C23B6B ;($25)
      : dw C23989 ;($26)
      : dw C2396C ;($27)
      : dw C23BB0 ;($28)
      : dw C2388C
      : dw C2388C
      : dw C23980 ;($2B)
      : dw C2388C
      : dw C23D37 ;($2D)
      : dw C23CCE ;($2E)
      : dw C23DA8 ;($2F)
      : dw C23C6E ;($30)
      : dw C2388C
      : dw C2388C
      : dw C23966 ;($33)
      : dw C23C91 ;($34)
      : dw C23D49 ;($35)
      : dw C2388C
      : dw C23D1E ;($37)
      : dw C2396C ;($38)
      : dw C2395E ;($39)
      : dw C23D27 ;($3A)
      : dw C23BCB ;($3B)
      : dw C2388C
      : dw C2388C
      : dw C23D7C ;($3E)
      : dw C23D85 ;($3F)
      : dw C23DB0 ;($40)
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C23CFD ;($44)
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C23DB8 ;($4A)
      : dw C2396C ;($4B)
      : dw C23D17 ;($4C)
      : dw C2388C
      : dw C2388C
      : dw C2388C
      : dw C23B98 ;($50)
      : dw C2388C
      : dw C2399E ;($52)
      : dw C23AC5 ;($53)
      : dw C23B71 ;($54)
      : dw C23B29 ;($55)
      : dw C23A8D ;($56)
      : dw C23C78 ;($57)


;Calls once-per-strike special effect code

C23E7D:  PHX
         PHP
         SEP #$30
         TXY
         LDX $11A9
         JSR (C242E1,X)
         PLP
         PLX
C23E8A:  RTS


;Random Steal Effect (Special Effect 1 - ThiefKnife

C23E8B:  JSR C24B53     ;50% chance to steal
         BCS C23E9F
         LDA #$A4       ;Add steal effect to attack
         STA $11A9
         LDA $B5
         CMP #$00
         BNE C23E9F     ;Exit if Command is not Fight
         LDA #$06
         STA $B5        ;set command to Capture for animation purposes
C23E9F:  RTS


;Step Mine - sets damage to Steps / Spell Power, capped at 65535

C23EA0:  STZ $3414      ;Set to ignore damage modifiers
         REP #$20       ;Set 16-bit Accumulator
         TDC
         DEC
         STA $11B0      ;Store default of 65535 in maximum damage
         LDA $1867      ;Steps High 2 Bytes
         LDX $11A6      ;Spell Power
         JSR C24792     ;Division function Steps / Spell Power
         SEP #$20       ;Set 8-bit Accumulator
         XBA
         BNE C23EC9     ;If the top byte of quotient is nonzero, we know the
                        ;final result will exceed 2 bytes, so leave it
                        ;at 65535 and branch
         TXA            ;A = remainder of Steps / Spell Power
         XBA
         STA $11B1      ;Store in Maximum Damage high byte
         LDA $1866      ;Steps Low Byte
         LDX $11A6      ;Spell Power
         JSR C24792     ;Division function
         STA $11B0      ;Store in Maximum Damage low byte
C23EC9:  RTS


;Ogre Nix - Weapon randomly breaks.  Also uses MP for criticals.

C23ECA:  LDA $B1
         LSR
         BCS C23F22     ;if not a conventional attack [i.e. in this context: it's
                        ;a counterattack], Jump to code for attack with MP
         LDA $3AA0,Y
         BIT #$04
         BNE C23F22     ;Jump to code for attack with MP if bit 2 of $3AA0,Y is set
         LDA $3BF5,Y    ;Load high byte of HP
         XBA
         LDA $3BF4,Y    ;Load low byte of HP
         LDX #$0A
         JSR C24792     ;A = HP / 10.  X = remainder, or the ones digit.
         INX
         TXA
         JSR C24B65     ;Random number 0 to last digit of HP
         DEC
         BPL C23F22     ;If number was not 0, branch
         TYA
         LSR
         TAX            ;X = target [0, 1, 2, 3, etc]
         INC $2F30,X    ;flag character's properties to be recalculated from
                        ;his/her equipment at end of turn.
         XBA
         LDA #$05
         JSR C24781     ;Multiplication function
         STA $EE        ;save target # * 5
         TYX
         LDA $3A70      ;# of strikes remaining in attack.  with Fight/Capture,
                        ;this value is always odd when the right hand is
                        ;striking, and even when the left is.  unfortunately,
                        ;that's not the case with Jump -- the hand used has
                        ;nothing to do with the strike # (in fact, it's random
                        ;when Genji Glove is worn -- resulting in a bug where
                        ;Ogre Nix fails to break when it should [as C2/3F0B
                        ;will check the wrong hand].
         LSR            ;Carry = 1 for right hand, 0 for left
         BCS C23F06     ;branch if right hand is attacking
         INX            ;point to left hand equipment slot
         LDA $EE
         ADC #$14
         STA $EE        ;point to the character's left hand in their
                        ;menu data
C23F06:  STZ $3B68,X    ;zero this hand's Battle Power
         LDX $EE
         LDA $2B86,X    ;get item in this hand
         CMP #$17
         BNE C23F22     ;Branch if it's not Ogre Nix
         LDA #$FF
         STA $2B86,X    ;null this hand slot in the character's menu data
         STA $2B87,X
         STZ $2B89,X
         LDA #$44
         STA $3401      ;Display weapon broke text
C23F22:  LDA #$0C       ;Special Effect 7 - Use MP for criticals - jumps here.
                        ;Featured in Rune Edge, Punisher, Ragnarok, and
                        ;Illumina.
C23F24:  STA $EE
         LDA $B2
         BIT #$02
         BNE C23F4F     ;Exit function if "No Critical and Ignore True Knight"
                        ;is set
         LDA $3EC9
         BEQ C23F4F     ;Exit function if no targets
         TDC            ;Clear 16-bit A
         JSR C24B5A     ;random #: 0 to 255
         AND #$07       ;now random #: 0 to 7
         CLC
         ADC $EE        ;Add to $EE [#$0C]
         REP #$20       ;Set 16-bit Accumulator
         STA $EE        ;Save MP consumed
         LDA $3C08,Y    ;Attacker MP
         CMP $EE
         BCC C23F4F     ;Exit function if weapon would drain more MP than the
                        ;wielder currently has
         SBC $EE
         STA $3C08,Y    ;Current MP = Current MP - MP consumed
         LDA #$0200
         TRB $B2        ;Set always critical
C23F4F:  RTS


;Special Effect $0F - Use MP for criticals.  No weapons use this, afaik.

C23F50:  LDA #$1C
         BRA C23F24
 

;<>Pearl Wind

C23F54:  LDA #$60
         TSB $11A2      ;Sets no split damage, and ignore defense
         STZ $3414      ;Set to not modify damage
         REP #$20
         LDA $3BF4,Y    ;HP
         STA $11B0      ;Maximum Damage = HP
         RTS


;Golem

C23F65:  REP #$20
         LDA $3BF4,Y    ;Current HP
         STA $3A36      ;HP that Golem will absorb
         RTS


;Special Effect 6 - Soul Sabre

C23F6E:  LDA #$80
         TSB $11A3      ;Sets attack to Concern MP
C23F73:  LDA #$08       ;Special Effect 5 - Drainer jumps here
         TSB $11A2      ;Sets attack to heal undead
         LDA #$02
         TSB $11A4      ;Sets attack to redirection
         RTS


;Recover HP - Heal Rod

C23F7E:  LDA #$20
         TSB $11A2      ;Sets attack to ignore defense
         LDA #$01
         TSB $11A4      ;Sets attack to heal
         RTS


;Valiant Knife

C23F89:  LDA #$20
         TSB $11A2      ;Sets attack to ignore defense
         REP #$20
         SEC
         LDA $3C1C,Y    ;Max HP
         SBC $3BF4,Y    ;HP
         CLC
         ADC $11B0      ;Add Max HP - Current HP to damage
         STA $11B0
         RTS


;Wind Slash - Tempest

C23F9F:  JSR C24B5A     ;Random Number Function: 0 to 255
         CMP #$80
         BCS C23FB6     ;50% chance exit function
         STZ $11A6      ;Clear Battle Power
         LDA #$65       ;Wind Slash spell number
         BRA C23FB0
 

;Magicite

C23FAD:  JSR C237DC     ;Picks random Esper, not Odin or Raiden
C23FB0:  STA $3400      ;Save the spell number
         INC $3A70      ;Increment the number of attacks remaining
C23FB6:  RTS


;Special effect $51
;GP Rain

C23FB7:  LDA $3B18,Y    ;Attacker's Level
         XBA
         LDA #$1E
         JSR C24781     ;attack will cost: Attacker's Level * 30
                        ;JSR C22B63?
         REP #$20       ;Set 16-bit accumulator
         CPY #$08
         BCS C23FD3     ;Branch if attacker is monster
         JSR C237B6     ;deduct thrown gold from party's inventory
         BNE C23FE9     ;branch if there was actually some GP to throw
C23FCB:  STZ $A4        ;Makes attack target nothing
         LDX #$08
         STX $3401      ;Set to display text 8 - "No money!!"
         RTS


C23FD3:  STA $EE        ;Level * 30
         LDA $3D98,Y    ;Gold monster gives
         BEQ C23FCB     ;Miss all w/text if = 0
         SBC $EE
         BCS C23FE4     ;Branch if monster's gold >= Level * 30
         LDA $3D98,Y
         STA $EE        ;if gold to consume was more than current
                        ;gold, set $EE to current gold
         TDC
C23FE4:  STA $3D98,Y    ;Set Gold to 0 or Gold - Level * 30
         LDA $EE        ;get amount of gold to consume
C23FE9:  LDX #$02
         STX $E8
         JSR C247B7     ;24-bit $E8 = A * 2
         LDA $E8        ;A = gold to consume * 2
         LDX $3EC9      ;Number of targets
         JSR C24792     ;A / number of targets
         STA $11B0      ;Sets maximum damage
         RTS


;Exploder effect from 42E1

C23FFC:  TYX
         STZ $BC        ;clear the Damage Incrementor.  i don't think it
                        ;ever could have been set, aside from Morph
                        ;being Ripplered onto a Lore user.
         LDA #$10
         TSB $B0        ;somehow ensures caster still steps forward to do
                        ;attack, and gets blue triangle.  must be needed
                        ;because of extra C2/57C2 calls.
         STZ $3414      ;Set to not modify damage
         REP #$20       ;Set 16-bit A
         LDA $A4        ;Load target hit
         PHA            ;Put on stack
         LDA $3018,X
         STA $B8        ;temporarily save caster as sole target
         JSR C257C2
         JSR C263DB     ;Copy $An variables to ($78) buffer
         LDA $01,S      ;restore original target
         STA $B8
         JSR C257C2
         PLA
         ORA $3018,X
         STA $A4        ;add attacker to targets
         LDA $3BF4,X
         STA $11B0      ;Sets damage to caster's Current HP
         JMP C235AD     ;Write data in $B4 - $B7 to current slot in ($76
                        ;animation buffer, and point $3A71 to this slot


;Special effect $4A (Super Ball

C2402C:  LDA #$7D
         STA $B6        ;Set Animation
         JSR C24B5A     ;random: 0 to 255
         AND #$03       ;0 to 3
         BRA C24039
C24037:  LDA #$07       ;Special Effect $2C, Launcher, jumps here
C24039:  STA $3405      ;# of hits to do.  this is a zero-based counter, so
                        ;a value of 0 means 1 hit.
         REP #$20       ;Set 16-bit Accumulator
         LDA $3018,Y
         STA $A6        ;mark attacker as "reflected off of", which will later
                        ;trigger function C2/3483 and cause him/her to be
                        ;treated as the missile launcher or ball thrower.
         RTS


;Special Effect 2 (Atma Weapon

C24044:  LDA #$20
         TSB $11A2      ;Set attack to ignore defense
         LDA #$02
         TSB $B2        ;Set no critical & ignore True Knight
         RTS


;Warp effect (Warp Stone uses same effect

C2404E:  LDA $B1
         BIT #$04       ;is "Can't Escape" flag set by an active enemy?
         BNE C2405A     ;branch if so
         LDA #$02
         STA $3A6E      ;"End of combat" method #2, Warping
         RTS


C2405A:  LDA #$0A
         STA $3401      ;Display can't run text
         BRA C2409C     ;Set to no targets


;Bababreath from 42E1

C24061:  STZ $EE
         LDX #$06
C24065:  LDA $3AA0,X
         LSR
         BCC C2407C     ;branch if target not valid
         LDA $3EE4,X    ;Status byte 1
         BIT #$C2       ;Check for Dead, Zombie, or Petrify
         BEQ C2407C     ;Branch if none set
         LDA $3018,X
         BIT $3F2C
         BNE C2407C     ;branch if airborne from jump
         STA $EE        ;save as preferred target
C2407C:  DEX
         DEX
         BPL C24065     ;Loop through all 4 characters
         LDA $EE
         BNE C2408D     ;if any character is Dead/Zombied/Petrified and not
                        ;airborne, use it as target instead.  if there're
                        ;multiple such characters, use the one who's closest
                        ;to the start of the party lineup.
         LDA $3A76      ;Number of present and living characters in party
         CMP #$02
         BCS C240BA     ;Exit function if 2+ characters alive, retaining
                        ;the initial target
         BRA C2409C     ;Set to no targets, because we don't want to blow
                        ;away the only living character.

C2408D:  STA $B8        ;save the Dead/Zombied/Petrified character as sole
                        ;target
         STZ $B9        ;clear any monster targets
         TYX
         JMP C257C2


;Special effect $50 - Possess
;106/256 chance to miss

C24095:  JSR C24B5A     ;Random Number Function 0 to 255
         CMP #$96
         BCC C240BA     ;Exit function if A < 150
C2409C:  STZ $A4
         STZ $A5        ;Make target nothing
         RTS


;L? Pearl from 42E1

C240A1:  LDA $1862      ;the following code will divide our 24-bit
                        ;gold, held in $1860 - $1862, by 10.
         XBA
         LDA $1861
         LDX #$0A
         JSR C24792     ;Divides top 2 bytes of gold by 10.  put
                        ;quotient in A, and remainder in X.
         TXA
         XBA
         LDA $1860      ;16-bit A = (above remainder * 256
                        ;+ bottom byte of gold
         LDX #$0A
         JSR C24792     ;X = gold amount MOD 10, i.e. the ones digit
                        ;of GP
         STX $11A8      ;Save as Hit rate / level multiplier for
                        ;LX spells
C240BA:  RTS


;Escape

C240BB:  CPY #$08
         BCS C240BA     ;Exit if monster
         LDA #$22
         STA $B5        ;use striding away animation instead of just
                        ;disappearing
         LDA #$10
         TSB $A0        ;would prevent the character from stepping forward
                        ;and getting a blue triangle if that animation
                        ;didn't already do so
         RTS


;Special effect $4B - Smoke Bomb

C240C8:  LDA #$04
         BIT $B1        ;is "Can't Escape" flag set by an active enemy?
         BEQ C240BA     ;Exit if not
         JSR C2409C     ;Set to no targets
         STZ $11A9      ;Clear special effect
         LDA #$09
C240D6:  STA $3401      ;Display text #9
         RTS


;Forcefield

C240DA:  TDC            ;Clear Accumulator
         LDA #$FF
         EOR $3EC8
         BEQ C2409C     ;Set to no targets if all elements nullified
         JSR C2522A     ;Randomly pick a set bit
         TSB $3EC8      ;Set that bit in $3EC8
         JSR C251F0     ;X = Get which bit is picked
         TXA
         CLC
         ADC #$37
         BRA C240D6
 

;<>Quadra Slam, Quadra Slice, etc.
;4 Random attacks

C240F1:  LDA #$03
         STA $3A70      ;# of attacks
         LDA #$40
         TSB $BA        ;Sets randomize target
         STZ $11A9      ;Clears special effect
         RTS


;Blow Fish

C240FE:  LDA #$60
         TSB $11A2      ;Set Ignore defense, and no split damage
         STZ $3414      ;Set to not modify damage
         REP #$20       ;Set 16-bit Accumulator
         LDA #$03E8
         STA $11B0      ;Set damage to 1000
         RTS


;Flare Star

C2410F:  STZ $3414      ;Set to not modify damage
         REP #$20       ;Set 16-bit Accumulator
         LDA $A2        ;Bitfield of targets
         JSR C2522A     ;A = a random target present in $A2
         JSR C251F9     ;Y = [Number of highest target set in A] * 2.
                        ;so we're obtaining a target index.
         LDA $A2
         JSR C2520E     ;X = number of bits set in A, so # of targets
         SEP #$20       ;Set 8-bit Accumulator
         LDA $3B18,Y    ;Level
         XBA
         LDA $11A6      ;Spell Power
         JSR C24781     ;Spell Power * Level
         JSR C24792     ;Divide by X, the number of targets
         REP #$20       ;Set 16-bit Accumulator
         STA $11B0      ;Store in maximum damage
         RTS


;Special effect $4C - Elixir and Megalixir.  In Item data, this appears as
; Special effect $04)

C24136:  LDA #$80
         TRB $11A3      ;Clears concern MP
         RTS


;Special effect $28 - Mind Blast

C2413C:  REP #$20       ;Set 16-bit Accumulator
         LDY #$06
C24140:  LDA $A4
         JSR C2522A     ;Randomly pick an entity from among the targets
         STA $3A5C,Y    ;add them to "Mind Blast victims" list.  the
                        ;other Mind Blast special effect will later try
                        ;to give an ailment to each entry in the list.
                        ;and yes, there can be duplicates.
         DEY
         DEY
         BPL C24140     ;Do four times
         RTS


;Miss random targets
; Special Effect $29 - N. Cross
; Each target will have a 50% chance of being untargeted.)

C2414D:  JSR C24B5A     ;random #: 0 to 255
         TRB $A4
         JSR C24B5A     ;random #: 0 to 255
         TRB $A5
         RTS


;Dice Effect

C24158:  STZ $3414      ;Set to not modify damage
         LDA #$20
         TSB $11A4      ;Makes unblockable
         LDA #$0F
         STA $B6        ;Third die defaults to null to start with
         TDC
         JSR C24B5A     ;Random Number Function 0 to 255
         PHA            ;Put on stack
         AND #$0F       ;0 to 15
         LDX #$06       ;will divide bottom nibble of random number by 6
         JSR C24792     ;Division A/X.  X will hold A MOD X
         STX $B7        ;First die roll, 0 to 5 -- 3/16 chance of 0 thru 3
                        ;each, 2/16 chance of 4 thru 5 each
         INX
         STX $EE        ;Save first die roll, 1 to 6
         PLA            ;Retrieve our 0-255 random number
         LDX #$60       ;will divide top nibble of random number by 6
         JSR C24792     ;Division A/X
         TXA            ;get MOD of division
         AND #$F0       ;0 to 5
         ORA $B7
         STA $B7        ;$B7: bottom nibble = 1st die roll 0 thru 5,
                        ;top nibble = 2nd die roll 0 thru 5
         LSR
         LSR
         LSR
         LSR
         INC            ;2nd die roll, converted to a 1 thru 6 value
         XBA            ;put in top half of A
         LDA $EE        ;Get first die roll, 1 to 6
         JSR C24781     ;Multiply them
         STA $EE        ;$EE = 1st roll * 2nd roll, where each roll is 1 thru 6
         LDA $11A8      ;# of dice
         CMP #$03
         BCC C241AB     ;Branch if less than 3 dice, i.e. there's 2
         TDC            ;Clear Accumulator
         LDA $021E      ;our 1-60 frame counter.  because 6 divides evenly into 60,
                        ;the third die has the same odds for all sides; it is NOT
                        ;slanted against you like the first two dice.
         LDX #$06
         JSR C24792     ;Division A/X
         TXA            ;new random number MOD 6
         STA $B6        ;save third die roll
         INC
         XBA            ;3rd die roll, converted to a 1 thru 6 value
         LDA $EE
         JSR C24781     ; (1st roll * 2nd roll) * 3rd roll
         STA $EE        ;$EE = 1st roll * 2nd roll * 3rd roll, where each roll
                        ;is 1 thru 6
C241AB:  LDX #$00
         LDA $B6        ;holds third die roll [0 to 5] if 3 dice,
                        ;or 0Fh if only 2 dice
         ASL
         ASL
         ASL
         ASL
         ORA $B6        ;A: if 2 dice, A = FF.  if 3 dice, A top nibble = 3rd die roll,
                        ;and A bottom nibble = 3rd die roll
         CMP $B7        ;does 3rd die roll match both 1st and 2nd?
                        ;obviously, it can NEVER if A = FF
         BNE C241BB     ;if no match, branch
         LDX $B6        ;X = 0 if there's not 3 matching dice.  if there are,
                        ;we've got a bonus coming, so let X be the 0 thru 5
                        ;roll value
C241BB:  LDA $EE        ;depending on # of dice, retrieve either:
                        ; 1st roll * 2nd roll   OR
                        ; 1st roll * 2nd roll * 3rd roll
         XBA
         LDA $11AF      ;Attacker Level
         ASL
         JSR C24781     ; (1st roll * 2nd roll * 3rd roll) * (Level * 2)
         REP #$20       ;set 16 bit-Accumulator
         STA $EE        ;overall damage =
                        ;2 Dice: 1st roll * 2nd roll * Level * 2,
                        ;3 Dice: 1st roll * 2nd roll * 3rd roll * Level * 2
C241C9:  CLC
         STA $11B0      ;save damage
         LDA $EE
         ADC $11B0      ;Add [Level * 1st roll * 2nd roll * 3rd roll * 2]
                        ;or [Level * 1st roll * 2nd roll * 2] to damage
         BCC C241D6     ;branch if it didn't overflow
         TDC
         DEC            ;set running damage to 65535
C241D6:  DEX
         BPL C241C9     ;Add the damage to itself X times, where X is the value
                        ;as commented at C2/41B9.  This loop serves to multiply
                        ;3 matching dice by the roll value once more, bringing
                        ;the damage to:  Roll * Roll * Roll * Level * 2 * Roll .
                        ;if X is 0 (i.e. no 3 matching dice, or 3 matching dice
                        ;with a value of 1), only the bonus-less damage is saved.
         SEP #$20       ;8-bit Accumulator
         LDA $B5
         CMP #$00
         BNE C241E3     ;Branch if command not Fight
         LDA #$26
C241E3:  STA $B5        ;Store a dice toss animation
         RTS


;Revenge

C241E6:  STZ $3414      ;Set to not modify damage
         REP #$20       ;Set 16-bit Accumulator
         SEC
         LDA $3C1C,Y    ;Max HP
         SBC $3BF4,Y    ;Current HP
         STA $11B0      ;Damage = Max HP - Current HP
         RTS


;Palidor from $42E1
;Makes not jump if you have Petrify, Sleep, Stop, Hide, or Freeze status

C241F6:  LDA #$10
         TSB $3A46      ;set "Palidor was summoned this turn" flag
         REP #$20
         LDX #$12
C241FF:  LDA $3EE4,X
         BIT #$8040     ;Check for Petrify or Sleep
         BNE C2420F     ;branch if any set
         LDA $3EF8,X
         BIT #$2210     ;Check for Stop, Hide, or Freeze
         BEQ C24216     ;branch if none set
C2420F:  LDA $3018,X
         TRB $A2        ;Remove from being a target
         TRB $A4
C24216:  DEX
         DEX
         BPL C241FF     ;iterate for all 10 entities
         RTS


;Empowerer

C2421B:  LDA $11A3
         EOR #$80       ;Toggle Concern MP
         STA $11A3
         BPL C2422A     ;Branch if not Concern MP -- this means we're
                        ;currently on the first "strike", which affects HP
         LDA #$12
         STA $B5        ;save Nothing [Mimic] as command animation.
                        ;this means the spell animation won't be repeated
                        ;for the MP-draining phase of Empowerer.
         RTS

C2422A:  INC $3A70      ;make the attack, including this special effect,
                        ;get repeated
         LSR $11A6
         LSR $11A6      ;Cut Spell Power to 1/4 for 2nd "strike", which
                        ;will affect MP
         RTS


;Spiraler

C24234:  TYX
         LDA $3018,X
         TRB $A2
         TRB $A4        ;Miss yourself
         TSB $2F4C      ;mark attacker to be removed from the battlefield
         JSR C2384A     ;Mark Hide and Death statuses to be set on attacker in
                        ;X, and mark the attacker as its own last attacker.
         REP #$20       ;Set 16-bit Accumulator
         STZ $3BF4,X    ;Zeroes HP of attacker
         STZ $3C08,X    ;Zeroes MP of attacker
C2424A:  RTS


;Discard

C2424B:  JSR C2409C     ;Set to no targets
         LDA #$20
         TSB $11A4      ;Set Can't be dodged
         LDX $3358,Y    ;whom you are Seizing
         BMI C2424A     ;Exit if not Seizing anybody
         LDA $3018,X
         STA $B8
         STZ $B9        ;set sole target to character whom you are Seizing
         TYX
         JMP C257C2


;Mantra

C24263:  LDA #$60
         TSB $11A2      ;Set no split damage, & ignore defense
         STZ $3414      ;Set to not modify damage
         REP #$20       ;Set 16-bit Accumulator
         LDA $3018,Y
         TRB $A4        ;Make miss yourself
         LDX $3EC9      ;Number of targets
         DEX
         LDA $3BF4,Y
         JSR C24792     ;HP / (Number of targets - 1)
         STA $11B0      ;Set damage
         RTS


;Special Effect $42
;Cuts damage to 1/4

C24280:  REP #$20       ;Set 16-bit Accumulator
         LSR $11B0      ;Halves damage
C24285:  REP #$20       ;Special effect $41 jumps here
         LSR $11B0      ;Halves damage
         RTS


;Suplex code from 42E1
;Picks a random target)

C2428B:  LDA #$10
         TSB $B0        ;???  See functions C2/13D3 and C2/57C2 for usual
                        ;purpose; dunno whether it does anything here.
         REP #$20       ;Set 16-bit Accumulator
         LDA $A2
         STA $EE        ;Copy targets to temporary variable
         LDX #$0A
C24297:  LDA $3C88,X    ;Monster data - Special Byte 2
         BIT #$0004
         BEQ C242A4     ;Check next target if this one can be Suplexed
         LDA $3020,X
         TRB $EE        ;Clear this monster from potential targets
C242A4:  DEX
         DEX
         BPL C24297     ;Loop for all 6 monster targets
         LDA $EE
         BNE C242AE     ;Branch if some targets left in temporary variable,
                        ;which means we'll actually be attacking something
                        ;that can be Suplexed!
         LDA $A2        ;original Targets
C242AE:  JSR C2522A     ;Randomly pick a bit
         STA $B8        ;save our one target
         TYX
         JMP C257C2


;Reflect???

C242B7:  REP #$20
         LDX #$12
C242BB:  LDA $3EF7,X
         BMI C242C5     ;Branch if Reflect status
         LDA $3018,X
         TRB $A4        ;Make miss target
C242C5:  DEX
         DEX
         BPL C242BB     ;iterate for all targets
         RTS


;Quick

C242CA:  LDA $3402
         BPL C242D8     ;Branch if already under influence of Quick
         STY $3404      ;Set attacker as target under the influence
                        ;of Quick
         LDA #$02
         STA $3402      ;Set the number of turns due to Quick
         RTS


C242D8:  REP #$20       ;Set 16-bit Accumulator
         LDA $3018,Y
         TSB $3A5A      ;Set target as missed
         RTS


;Table for special effects code pointers 2 (once-per-strike

C242E1: dw C23E8A
      : dw C23E8B
      : dw C24044 ;($02)
      : dw C23E8A
      : dw C23E8A
      : dw C23F73 ;($05)
      : dw C23F6E ;($06)
      : dw C23F22 ;($07)
      : dw C23E8A
      : dw C24158 ;($09)
      : dw C23F89 ;($0A)
      : dw C23F9F ;($0B)
      : dw C23F7E ;($0C)
      : dw C23E8A
      : dw C23ECA ;($0E)
      : dw C23F50 ;($0F)
      : dw C23E8A
      : dw C23F65 ;($11)
      : dw C23E8A
      : dw C241F6 ;($13)
      : dw C23E8A
      : dw C24263 ;($15)
      : dw C24234 ;($16)
      : dw C23E8A
      : dw C2404E ;($18)
      : dw C23FFC ;($19)
      : dw C240FE ;($1A)
      : dw C23F54 ;($1B)
      : dw C242B7 ;($1C)
      : dw C240A1 ;($1D)
      : dw C23EA0 ;($1E)
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C240BB ;($27)
      : dw C2413C ;($28)
      : dw C2414D ;($29)
      : dw C2410F ;($2A)
      : dw C23E8A
      : dw C24037 ;($2C)
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C2428B ;($30)
      : dw C240DA ;($31)
      : dw C240F1 ;($32)
      : dw C24061 ;($33)
      : dw C23E8A
      : dw C23E8A
      : dw C2421B ;($36)
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C241E6 ;($3D)
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C24285 ;($41)
      : dw C24280 ;($42)
      : dw C242CA ;($43)
      : dw C2424B ;($44)
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23FAD ;($49)
      : dw C2402C ;($4A)
      : dw C240C8 ;($4B)
      : dw C24136 ;($4C)
      : dw C2404E ;($4D)
      : dw C23E8A
      : dw C23E8A
      : dw C24095 ;($50)
      : dw C23FB7 ;($51)
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A
      : dw C23E8A


;Update statuses for every entity onscreen (at battle start, on formation switch,
; and after each strike of an attack)

C24391:  PHX
         PHP
         REP #$20       ;Set 16-bit Accumulator
         LDY #$12
C24397:  LDA $3AA0,Y
         LSR
         BCC C243FF     ;Skip this entity if not present in battle
         JSR C2450D     ;Put Status to be Set / Clear into $Fn ,
                        ;Quasi New Status in $3E60 & $3E74
         LDA $FC        ;status to add, bytes 1-2
         BEQ C243B3     ;Branch if none
         STA $F0
         LDX #$1E
C243A8:  ASL $F0
         BCC C243AF     ;Skip if current status not to be set
         JSR (C246B0,X) ;perform "side effects" of setting it
C243AF:  DEX
         DEX
         BPL C243A8     ;Loop through all possible statuses to set in
                        ;bytes 1 & 2
C243B3:  LDA $FE        ;status to add, bytes 3-4
         BEQ C243C6     ;branch if none
         STA $F0
         LDX #$1E
C243BB:  ASL $F0
         BCC C243C2     ;Skip if current status not to be set
         JSR (C246D0,X) ;perform "side effects" of setting it
C243C2:  DEX
         DEX
         BPL C243BB     ;Loop through all possible statuses to set in
                        ;bytes 3 & 4

;Note: the subtraction of blocked statuses from "statuses to clear" below takes place
; later than the removal of blocked statuses from "statuses to set".  i think this is
; because the special case set status functions called in $46B0 AND 46D0 can mark
; additional statuses to be cleared.  so Square performed the block checks after these
; calls to make sure we don't clear any statuses to which we're immune.)

C243C6:  LDA $F4        ;status to clear bytes 1-2
         AND $331C,Y    ;blocked status bytes 1-2
         STA $F4        ;remove blocked from statuses to clear
         BEQ C243DE     ;branch if nothing in these bytes to clear
         STA $F0
         LDX #$1E
C243D3:  ASL $F0
         BCC C243DA     ;Skip if current status not to be cleared
         JSR (C246F0,X) ;Call for each status to be clear byte 1 & 2
C243DA:  DEX
         DEX
         BPL C243D3     ;Loop through all possible statuses to clear in
                        ;bytes 1 & 2
C243DE:  LDA $F6        ;status to clear bytes 3-4
         AND $3330,Y    ;blocked status bytes 3-4
         STA $F6        ;don't try to clear blocked statuses
         BEQ C243F6     ;branch if nothing in these bytes to clear
         STA $F0
         LDX #$1E
C243EB:  ASL $F0
         BCC C243F2     ;Skip if current status not to be cleared
         JSR (C24710,X) ;Call for each status to be clear byte 3 & 4
C243F2:  DEX
         DEX
         BPL C243EB     ;Loop through all possible statuses to clear in
                        ;bytes 3 & 4
C243F6:  JSR C2447F     ;Get new status
         JSR C24585     ;Store in 3EE4 & 3EF8, and clear some statuses
                        ;if target has Zombie
         JSR C244FF     ;Clear status to set and status to clear bytes
C243FF:  DEY
         DEY
         BPL C24397     ;loop for all 10 targets on screen
         PLP
         PLX
         RTS


;Determine statuses that will be set/removed when attack hits
; miss if attack doesn't change target's status)

C24406:  PHP
         REP #$20
         LDA $3EE4,Y    ;get current status bytes 1-2
         STA $F8
         LDA $3EF8,Y    ;get current status bytes 3-4
         STA $FA
         JSR C24490     ;Initialize intermediate "status to set" bytes in
                        ;$F4 - $F7 and "status to clear" bytes in $FC - $FF.
                        ;Mark Clear / Freeze to be removed if necessary.
         SEP #$20
         LDA $B3
         BMI C24420     ;Branch if not Ignore Clear
         LDA #$10
         TRB $F4        ;remove Vanish from Status to Clear
C24420:  LDA $3C95,Y
         BPL C2443D     ;Branch if not undead
         LDA #$08
         BIT $11A2
         BEQ C2443D     ;Branch if attack doesn't reverse damage on undead
         LSR
         BIT $11A4
         BEQ C2443D     ;Branch if not lift status
         LDA $11AA
         BIT #$82
         BEQ C2443D     ;Branch if attack doesn't involve Death or Zombie
         LDA #$80
         TSB $FC        ;mark Death in Status to set
C2443D:  REP #$20
         LDA $FC
         JSR C20E32     ;update Status to set Bytes 1-2
         LDA $FE
         ORA $3DE8,Y
         STA $3DE8,Y    ;update Status to set Bytes 3-4
         LDA $F4
         ORA $3DFC,Y
         STA $3DFC,Y    ;update Status to clear Bytes 1-2
         LDA $F6
         ORA $3E10,Y
         STA $3E10,Y    ;update Status to clear Bytes 3-4
         LDA $11A7
         LSR
         BCC C2447D     ;if "spell misses if protected from ailments" bit
                        ;is unset, exit function
         LDA $FC
         ORA $F4
         AND $331C,Y    ;are there any statuses we're trying to set or clear
                        ;that aren't blocked?)  (bytes 1-2
         BNE C2447D     ;if there are, exit function
         LDA $FE
         ORA $F6
         AND $3330,Y    ;are there any statuses we're trying to set or clear
                        ;that aren't blocked?)  (bytes 3-4
         BNE C2447D     ;if there are, exit function
         LDA $3018,Y
         STA $3A48      ;Indicate a miss, due to the attack not changing any
                        ;statuses or due to checks in its special effect
         TSB $3A5A      ;Spell misses target if protected from ailments [or
                        ;specifically, if statuses unchanged]
C2447D:  PLP
         RTS


;Get new status

C2447F:  LDA $F8        ;status byte 1 & 2
         TSB $FC        ;add to Status to set byte 1 & 2
         LDA $F4        ;Status to clear byte 1 & 2
         TRB $FC        ;subtract from Status to set byte 1 & 2
         LDA $FA        ;Status byte 3 & 4
         TSB $FE        ;add to Status to set byte 3 & 4
         LDA $F6        ;Status to clear byte 3 & 4
         TRB $FE        ;subtract from Status to set byte 3 & 4
         RTS


;Initialize intermediate "status to set" bytes in $F4 - $F7 and
; "status to clear" bytes in $FC - $FF.
; Mark Clear / Freeze to be removed if necessary.)
C24490:  PHX
         SEP #$20       ;Set 8-bit Accumulator
         LDA $11A4      ;Special Byte 2
         AND #$0C
         LSR A
         TAX            ;X = 0 if set status, 2 = lift status,
                        ;4 = toggle status
         REP #$20
         STZ $FC        ;Clear status to clear and set bytes
         STZ $FE
         STZ $F4
         STZ $F6
         JSR (C244D1,X) ;prepare status set, lift, or toggle
         LDA $11A2
         LSR A
         BCS C244BB   ;branch if physical attack
         LDA #$0010
         BIT $F8
         BEQ C244BB   ;branch if target not vanished
         BIT $11AA
         BNE C244BB   ;branch if attack causes Clear
         TSB $F4        ;mark Clear status to be cleared
C244BB:  LDA $11A1
         LSR A
         BCC C244CF   ;Exit if not element Fire
         LDA #$0200
         BIT $FA
         BEQ C244CF   ;Exit if target not Frozen
         BIT $11AC
         BNE C244CF   ;Exit if attack setting Freeze
         TSB $F6        ;mark Freeze status to be cleared
C244CF:  PLX
         RTS


;Code Pointers

C244D1: dw C244D7
      : dw C244EA
      : dw C244F9

;Spell wants to set status
C244D7:  LDA $11AA      ;get status bytes 1-2 from spell
         STA $FC        ;store in status to set
         LDA $F8        ;get current status 1-2
         TRB $FC        ;don't try to set anything you already have
         LDA $11AC      ;get status bytes 3-4 from spell
         STA $FE        ;store in status to set
         LDA $FA        ;get current status 3-4
         TRB $FE        ;don't try to set anything you already have
         RTS

;Spell wants to clear status
C244EA:  LDA $11AA      ;get status bytes 1-2 from spell
         AND $F8        ;current status 1-2
         STA $F4        ;only try to clear statuses you do have
         LDA $11AC      ;get status bytes 3-4 from spell
         AND $FA        ;current status 3-4
         STA $F6        ;only try to clear statuses you do have
         RTS

;Spell wants to toggle status
C244F9:  JSR C244D7     ;mark spell statuses you don't already have
                        ;to be set
         JMP C244EA     ;and mark the ones you do already have to
                        ;be cleared


;Clear status to set and status to clear bytes

C244FF:  TDC
         STA $3DD4,Y    ;Status to Set bytes 1-2
         STA $3DE8,Y    ;Status to Set bytes 3-4
         STA $3DFC,Y    ;Status to Clear bytes 1-2
         STA $3E10,Y    ;Status to Clear bytes 3-4
         RTS


;Put Status to be Set / Clear into $Fn
; Quasi New Status in $3E60 & $3E74)

C2450D:  LDA $3DFC,Y
         STA $F4        ;Status to Clear bytes 1-2
         LDA $3E10,Y
         STA $F6        ;Status to Clear bytes 3-4

         LDA $3DD4,Y
         AND $331C,Y
         STA $FC        ;Status to Set bytes 1-2, excluding blocked statuses
         LDA $3DE8,Y
         AND $3330,Y
         STA $FE        ;Status to Set bytes 3-4, excluding blocked statuses

         LDA $3EE4,Y    ;Load Status of targets, bytes 1-2
         STA $F8
         AND #$0040     ;If target already had Petrify, set it in Status to Set
         TSB $FC

;Note: I think the above is done in preparation for the special case functions at
; $46B0 and 46D0.  These are called when a status is inflicted, and cause side effects like
; clearing other statuses [provided you're not immune to them], and messing with
; assorted variables.  A classic example is Slow booting out Haste, and vice versa.)

; The above code means that just as Muddled/Mute/Clear/Dark/etc are cleared/prevented when
; Petrify status is first _acquired_, they will also be cleared/prevented as long as Petrify
; is POSSESSED.)

         LDA $3EF8,Y    ;Status bytes 3 & 4
         STA $FA

;This chunk will:
; If Current HP > 1/8 Max HP and Near Fatal status is currently set, mark Near Fatal
; status to be cleared.
; If Current HP <= 1/8 Max HP and Near Fatal status isn't currently set, mark Near Fatal
; status to be set. )
;++++++
         LDA $3C1C,Y    ;Max HP
         LSR
         LSR
         LSR            ;Divide by 8
         CMP $3BF4,Y    ;Current HP

         LDA #$0200
         BIT $F8
         BNE C2454A     ;Branch if Near Fatal status possessed
         BCC C2454E     ;Branch if Current HP > Max HP / 8
         TSB $FC        ;Mark Near Fatal in Status to Set
C2454A:  BCS C2454E     ;Branch if Current HP <= Max HP / 8
         TSB $F4        ;Mark Near Fatal in Status to Clear
;++++++

C2454E:  LDA $FB
         BPL C24566     ;Branch if no Wound in Status to Set
         LDA $3E4D,Y
         AND #$0002     ;Bit set by Overcast
         BEQ C24566     ;Branch if not set
         ORA $FC        ;Put Zombie in Status to Set
         AND #$FF7F     ;Clear Wound from Status to Set
         STA $FC
         LDA #$0100
         TSB $F4        ;Set Condemned in Status to Clear

C24566:  LDA $32DF,Y
         BPL C24584     ;Exit function if attack doesn't hit them.  note
                        ;that targets missed due to the attack not changing
                        ;any statuses or due to special effects checks can
                        ;still count as hit.

         LDA $FC        ;back up Status to Set bytes 1-2
         PHA            ;Put on stack
         LDA $FE        ;back up Status to Set bytes 3-4
         PHA            ;Put on stack
         JSR C2447F     ;Get new status
         LDA $FC
         STA $3E60,Y    ;save Quasi Status bytes 1 and 2
         LDA $FE
         STA $3E74,Y    ;save Quasi Status bytes 3 and 4
;         (These bytes are used for counterattack purposes.  They differ from actual
;          status bytes in that they don't factor in statuses removed as side effects.
;          Also, they don't exclude from removal statuses to which the target is
;          immune.  The result of the former difference is consistency in behavior in
;          non- FC 12 and FC 1C counterattacks.  See C2/4BF4 for more info.  The
;          latter difference means that monsters with permanent Muddled or Berserk can
;          wrongly be regarded as having the status removed.  However, there are no
;          monsters with permanent Muddle, and Brawler, the only one with permanent
;          Berserk, doesn't have a counterattack script anyway.)
         PLA
         STA $FE        ;restore Status to Set bytes 1-2
         PLA
         STA $FC        ;restore Status to Set bytes 3-4
C24584:  RTS


;Store new status in character/monster status bytes.
; Clear some statuses if target has Zombie.)

C24585:  LDA $FC
         BIT #$0002
         BEQ C2458F     ;Branch if not Zombie
         AND #$4DFA     ;Clear Dark and Poison
                        ;Clear Near Fatal, Berserk, Muddled, Sleep
C2458F:  STA $3EE4,Y    ;Store new status in Bytes 1 and 2
         LDA $FE
         STA $3EF8,Y    ;Store new status in Bytes 3 and 4
         RTS


;If a status in A is possessed or it's set in Status to Set, turn it on
; in Status to Clear)

C24598:  PHA            ;Put on stack
         LDA $F8
         ORA $FC
         AND $01,S
         TSB $F4
         PLA
         RTS


;Zombie - set

C245A3:  LDA #$0080
         JSR C24598     ;if Death is possessed or set by the spell, mark it to
                        ;be cleared
         JSR C246A9     ;Mark this entity as having died since last
                        ;executing Command 1Fh, "Run Monster Script"
         BRA C245C1
 

;Zombie - clear

C245AE:  JSR C2469C     ;If monster, add to list of remaining enemies, and
                        ;remove from list of dead-ish ones
         BRA C245C1
 

;Muddle - set

C245B3:  LDA $3018,Y
         TSB $2F53      ;cause target to be visually flipped
         BRA C245C1
 

;Muddle - clear

C245BB:  LDA $3018,Y
         TRB $2F53      ;cancel visual flipping of target
C245C1:  PHX
         LDX $3018,Y
         TXA
         TSB $3A4A      ;set "Entity's Zombie or Muddled changed since last
                        ;command or ready stance entering"
         PLX
         RTS


;Clear - set

C245CB:  PHX
         LDX $3019,Y
         TXA
         TSB $2F44
         PLX
         RTS


;Clear - clear
;is there an echo in here?!  who's on first?)

C245D5:  PHX
         LDX $3019,Y
         TXA
         TRB $2F44
         PLX
         RTS


;Imp - set or clear

C245DF:  LDA #$0088
         JSR C2464C
C245E5:  CPY #$08       ;Rage - clear   enters here
         BCS C245F1     ;Exit function if monster
         PHX
         TYA
         LSR
         TAX
         INC $2F30,X    ;flag character's properties to be recalculated from
                        ;his/her equipment at end of turn.
         PLX
C245F1:  RTS


;Petrify - clear and Death - clear

C245F2:  JSR C2469C     ;If monster, add to list of remaining enemies, and
                        ;remove from list of dead-ish ones
         LDA #$4000
         JSR C24656     ;consolidate: "JSR C24653"
         LDA #$0040
         BRA C2464C
 

;Death - set
C24600:  LDA #$0140
         JSR C24598     ;if Petrify or Condemned are possessed or set by the spell,
                        ;mark them to be cleared
         LDA #$0080
         TRB $F4        ;remove Death from statuses to be cleared

;Petrify - set
C2460B:  JSR C246A9     ;Mark this entity as having died since last
                        ;executing Command 1Fh, "Run Monster Script"
         LDA #$FE15
         JSR C24598     ;if Dark, Poison, Clear, Near Fatal, Image, Mute, Berserk,
                        ;Muddled, Seizure, or Sleep are possessed by the target or
                        ;set by the spell, mark them to be cleared
         LDA $FA
         ORA $FE
         AND #$9BFF     ;if Dance, Regen, Slow, Haste, Stop, Shell, Safe, Reflect,
                        ;Rage, Freeze, Morph, Spell Chant, or Float are possessed
                        ;by the target or set by the spell, mark them to be cleared
         TSB $F6
         LDA $3E4C,Y
         AND #$BFFF
         STA $3E4C,Y    ;clear HP Leak quasi-status that was set by Phantasm
C24626:  LDA $3AA0,Y
         AND #$FF7F
         STA $3AA0,Y
         LDA #$0040
         BRA C2464C
 

;Sleep - set

C24634:  PHP
         SEP #$20       ;Set 8-bit A
         LDA #$12
         STA $3CF9,Y    ;Time until Sleep wears off
         PLP
         BRA C24626
 

;Condemned - set

C2463F:  LDA #$0020
         BRA C2464C
C24644:  LDA #$0010     ;Condemned - clear  enters here
         BRA C2464C
C24649:  LDA #$0008     ;Mute - set or clear  enter here
C2464C:  ORA $3204,Y
         STA $3204,Y
         RTS


;Sleep - clear

C24653:  LDA #$4000
C24656:  ORA $3AA0,Y
         STA $3AA0,Y    ;flag entity's ATB gauge to be reset?
         RTS


;Seizure - set

C2465D:  LDA #$0002
         TSB $F6        ;mark Regen to be cleared
         RTS


;Regen - set

C24663:  LDA #$4000
         TSB $F4        ;mark Seizure to be cleared
         RTS


;Slow - set

C24669:  LDA #$0008
         BRA C24671     ;mark Haste to be cleared


;Haste - set

C2466E:  LDA #$0004     ;mark Slow to be cleared
C24671:  TSB $F6
C24673:  LDA #$0004     ;Haste - clear  and  Slow - clear  enter here
         BRA C2464C
 

;Morph - set or clear

C24678:  LDA #$0002
         BRA C2464C
 

;Stop - set

C2467D:  PHP
         SEP #$20       ;Set 8-bit A
         LDA #$12
         STA $3AF1,Y    ;Time until Stop wears off
         PLP
         RTS


;Reflect - set

C24687:  PHP
         SEP #$20       ;Set 8-bit A
         LDA #$1A
         STA $3F0C,Y    ;Time until Reflect wears off, though permanency
                        ;can prevent its removal
         PLP
         RTS


;Freeze - set

C24691:  PHP
         SEP #$20       ;Set 8-bit A
         LDA #$22
         STA $3F0D,Y    ;Time until Freeze wears off
         PLP
         RTS


;Do nothing:
; Dark, Poison, M-Tek,
; Near Fatal, Image, Berserk,
; Dance, Shell, Safe,
; Rage [set only], Life 3, Spell, Hide, Dog Block, Float)

C2469B:  RTS


;If monster, add to list of remaining enemies, and remove from list of dead-ish ones

C2469C:  PHX
         LDX $3019,Y    ;get bit identifying monster
         TXA
         TSB $2F2F      ;add to bitfield of remaining enemies?
         TRB $3A3A      ;remove from bitfield of dead-ish monsters
         PLX
         RTS


C246A9:  LDA $3018,Y
         TSB $3A56      ;Mark this entity as having died since last
                        ;executing Command 1Fh, "Run Monster Script",
                        ;counterattack variant
         RTS


;Not actual code - data (table of pointers to code, for changing status

;Set status pointers ("side effects" to perform upon setting of a status:

C246B0: dw C2469B ;(Dark)        (Jumps to RTS)
      : dw C245A3 ;(Zombie)
      : dw C2469B ;(Poison)      (Jumps to RTS)
      : dw C2469B ;(M-Tek)       (Jumps to RTS)
      : dw C245CB ;(Clear)
      : dw C245DF ;(Imp)
      : dw C2460B ;(Petrify)
      : dw C24600 ;(Death)
      : dw C2463F ;(Condemned)
      : dw C2469B ;(Near Fatal)  (Jumps to RTS)
      : dw C2469B ;(Image)       (Jumps to RTS)
      : dw C24649 ;(Mute)
      : dw C2469B ;(Berserk)     (Jumps to RTS)
      : dw C245B3 ;(Muddle)
      : dw C2465D ;(Seizure)
      : dw C24634 ;(Sleep)
C246D0: dw C2469B ;(Dance)       (Jumps to RTS)
      : dw C24663 ;(Regen)
      : dw C24669 ;(Slow)
      : dw C2466E ;(Haste)
      : dw C2467D ;(Stop)
      : dw C2469B ;(Shell)       (Jumps to RTS)
      : dw C2469B ;(Safe)        (Jumps to RTS)
      : dw C24687 ;(Reflect)
      : dw C2469B ;(Rage)        (Jumps to RTS)
      : dw C24691 ;(Freeze)
      : dw C2469B ;(Life 3)      (Jumps to RTS)
      : dw C24678 ;(Morph)
      : dw C2469B ;(Spell)       (Jumps to RTS)
      : dw C2469B ;(Hide)        (Jumps to RTS)
      : dw C2469B ;(Dog Block)   (Jumps to RTS)
      : dw C2469B ;(Float)       (Jumps to RTS)


;Clear status pointers ("side effects" to perform upon clearing of a status:

C246F0: dw C2469B ;(Dark)        (Jumps to RTS)
      : dw C245AE ;(Zombie)
      : dw C2469B ;(Poison)      (Jumps to RTS)
      : dw C2469B ;(M-Tek)       (Jumps to RTS)
      : dw C245D5 ;(Clear)
      : dw C245DF ;(Imp)
      : dw C245F2 ;(Petrify)
      : dw C245F2 ;(Death)
      : dw C24644 ;(Condemned)
      : dw C2469B ;(Near Fatal)  (Jumps to RTS)
      : dw C2469B ;(Image)       (Jumps to RTS)
      : dw C24649 ;(Mute)
      : dw C2469B ;(Berserk)     (Jumps to RTS)
      : dw C245BB ;(Muddle)
      : dw C2469B ;(Seizure)     (Jumps to RTS)
      : dw C24653 ;(Sleep)
C24710: dw C2469B ;(Dance)       (Jumps to RTS)
      : dw C2469B ;(Regen)       (Jumps to RTS)
      : dw C24673 ;(Slow)
      : dw C24673 ;(Haste)
      : dw C2469B ;(Stop)        (Jumps to RTS)
      : dw C2469B ;(Shell)       (Jumps to RTS)
      : dw C2469B ;(Safe)        (Jumps to RTS)
      : dw C2469B ;(Reflect)     (Jumps to RTS)
      : dw C245E5 ;(Rage)
      : dw C2469B ;(Freeze)      (Jumps to RTS)
      : dw C2469B ;(Life 3)      (Jumps to RTS)
      : dw C24678 ;(Morph)
      : dw C2469B ;(Spell)       (Jumps to RTS)
      : dw C2469B ;(Hide)        (Jumps to RTS)
      : dw C2469B ;(Dog Block)   (Jumps to RTS)
      : dw C2469B ;(Float)       (Jumps to RTS)


;??? Function (Called from other bank

C24730:  PHX
         PHY
         PHB
         PHP
         SEP #$30
         PHA            ;Put on stack
         LDA #$7E
         PHA            ;Put on stack
         PLB            ;set Data Bank register to 7E
         PLA
         CLC
         JSR (C2474B,X)
         JSR C24490     ;Initialize intermediate "status to set" bytes in
                        ;$F4 - $F7 and "status to clear" bytes in $FC - $FF.
                        ;Mark Clear / Freeze to be removed if necessary.
         JSR C2447F     ;get new status
         PLP
         PLB
         PLY
         PLX
         RTL


;Pointers

C2474B: dw C2474F
      : dw C24778


C2474F:  JSR C22966     ;load spell data
         LDA $11A4
         BPL C24775     ;Branch if damage/healing not based on HP or MP
         LDA $11A6      ;Spell Power
         STA $E8
         REP #$30
         LDA $11B2      ;get maximum HP or MP
         JSR C2283C     ;apply equipment/relic boosts to it
         CMP #$2710
         BCC C2476C     ;branch if not 10,000 or higher
         LDA #$270F     ;set to 9999
C2476C:  SEP #$10       ;set 16-bit X and Y
         JSR C20DCB     ;A = (Spell Power * HP or MP) / 16
         STA $11B0      ;Damage
         RTS

C24775:  JMP C22B69     ;Magical Damage Calculation


C24778:  JSR C22A37     ;item usage setup
         LDA #$01
         TSB $11A2      ;Sets physical attack
         RTS


;Multiplication Function
;Multiplies low bit of A * high bit of A.  Stores result in 16-bit A.

C24781:  PHP
         REP #$20
         STA $004202
         NOP
         NOP
         NOP
         NOP
         LDA $004216
         PLP
         RTS


;Division Function
;Divides 16-bit A / 8-bit X
;Stores answer in 16-bit A.  Stores remainder in 8-bit X.

C24792:  PHY
         PHP
         REP #$20
         STA $004204
         SEP #$30
         TXA
         STA $004206
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         NOP
         LDA $004216
         TAX
         REP #$20
         LDA $004214
         PLP
         PLY
         RTS


;Multiplication Function 2
;Results:
;16-bit A = (8-bit $E8 * 16-bit A) / 256
;24-bit $E8 = 3 byte (8-bit $E8 * 16-bit A)
;16-bit $EC = 8-bit $E8 * high byte of A

C247B7:  PHP
         SEP #$20
         STZ $EA
         STA $E9
         LDA $E8
         JSR C24781
         REP #$21
         STA $EC
         LDA $E8
         JSR C24781
         STA $E8
         LDA $EC
         ADC $E9
         STA $E9
         PLP
         RTS


;Multiplies A (1 byte by * 1.5

C247D6:  PHA            ;Put on stack
         LSR
         CLC
         ADC $01,S
         BCC C247DF
         LDA #$FF
C247DF:  STA $01,S
         PLA
         RTS


;Remove character in X from all parties

C247E3:  PHX
         LDA $3ED9,X    ;get 0-15 roster position of this party member
         TAX
         STZ $1850,X    ;null out their party-related roster information
                        ;[i.e. which party, which slot in party, row,
                        ;main menu presence?, and leader flag]
         PLX
C247EC:  RTS


C247ED:  LDA $3EE0
         BEQ C247FB     ;branch if in 4-tier final multi-battle
         LDA $3A6E      ;Method used to end combat?
         BEQ C247FB     ;Branch if no special end?
         TAX
         JMP (C248F5,X)


C247FB:  LDA $1DD1      ;$1DD1 = $3EBC
         AND #$20
         BEQ C24807
         TSB $3EBC
         BRA C24820
C24807:  LDA $3A95      ;did monster script Command F5 nn 04 prohibit checking
                        ;for combat end, without being overridden since?
         BNE C247EC     ;Exit if so
         LDA $3A74      ;list of alive and present characters
         BNE C24833     ;branch if at least one
         LDA $3A8A
         BEQ C24822     ;branch if no characters engulfed
         CMP $3A8D      ;compare Engulfed characters to list of valid characters
                        ;at battle start
         BNE C24822     ;branch if the full list wasn't Engulfed
         LDA #$80
         TSB $3EBC      ;set event bit indicating battle ended with full party
                        ;Engulfed
C24820:  BRA C248A1
C24822:  LDA $3A39
         BNE C24897     ;branch if 1 or more characters escaped
         LDA $3A97      ;if we reached here, party lost the battle
         BNE C2482E     ;branch if in Colosseum
         LDA #$29       ;tell function call below party was annihilated
C2482E:  JSR C25FCA     ;handle battle ending in loss
         BRA C2488F
C24833:  LDA $3A77      ;Number of monsters left in combat
         BNE C247EC     ;Exit if 1 or more monsters still alive
         LDA $3EE0
         BNE C24840     ;branch if not in final 4-tier battle
         JSR C24A76     ;if currently one of first 3 tiers, take certain steps for
                        ;transition, and don't return to this calling function
C24840:  LDX $300B      ;Which character is Gau
         BMI C24861     ;branch if Gau not in party.  note that "in party" can
                        ;mean Gau's actively in the party, or that he's Leapt on
                        ;the Veldt, you're fighting on the Veldt, and there's a
                        ;free spot in your party for him to return.
         LDA #$01
         TRB $11E4      ;mark Gau as not available to return from Veldt leap
         BEQ C24861     ;branch if that was already the case
         JSR C24B5A     ;random: 0 to 255
         CMP #$A0
         BCS C24861     ;3 in 8 chance branch
         LDA $3EBD
         BIT #$02       ;have you already enlisted Gau the first time?
         BNE C248CE     ;branch if so
         LDA $3A76      ;Number of present and living characters in party
         CMP #$02
         BCS C248CE     ;Branch if 2 or more characters in party -- this ensures
                        ;that Sabin and Cyan are both *alive* to see the original
                        ;Gau hijinx
C24861:  LDX $3003      ;Which character is Shadow
         BMI C2488C     ;Branch if Shadow not in party
         JSR C24B5A     ;random #: 0 to 255
         CMP #$10
         BCS C2488C     ;15 in 16 chance branch
         LDA $201F      ;get encounter type:  0 = front, 1 = back,
                        ;2 = pincer, 3 = side
         BNE C2488C     ;if not a front attack, branch
         LDA $3A76      ;Number of present and living characters in party
         CMP #$02
         BCC C2488C     ;Branch if less than 2 characters in party
         LDA $3EE4,X
         BIT #$C2       ;Check for Dead, Zombie, or Petrify
         BNE C2488C     ;Branch if any set on Shadow
         LDA #$08
         BIT $3EBD      ;is Shadow randomly leaving disabled at this point in
                        ;game?
         BNE C2488C     ;branch if so
         BIT $1EDE      ;Which characters are enlisted
         BNE C248A6     ;Branch if Shadow enlisted
C2488C:  JSR C25D57
C2488F:  JSR C24936
         PLA
         PLA            ;remove caller address from stack
         JMP C200C5     ;this lets us return somewhere other than C2/0084


;Warp, also used when escaped characters
C24897:  LDA #$FF
         STA $0205      ;null out Colosseum item wagered, so we're not billed
         LDA #$10
         TSB $3EBC      ;set event bit indicating battle ended due to Warp or
                        ;with at least 1 character escaped
;   FB 02-Usual monster script way to end a battle  enters here)
C248A1:  JSR C24903
         BRA C2488F
 

;Shadow randomly leaves after battle

C248A6:  TRB $1EDE      ;un-enlist Shadow
         JSR C247E3     ;remove him from all parties
         REP #$10
         LDY $3010,X    ;get offset to character info block
         LDA #$FF
         STA $161E,Y    ;clear his equipped Esper
         SEP #$10
         LDA #$FE
         JSR C20792     ;clear Bit 0 of $3AA0,X , indicating absence
                        ;from battle
         LDA #$02
         TSB $2F49      ;turn on "No Winning Stand" aka
                        ;"No victory dance" in extra formation
                        ;data.  this bit is checked at C1/0124.
         LDX #$0B       ;Attack
C248C4:  PLA
         PLA            ;remove caller address from stack
         LDA #$23       ;Command is Battle Event, and Attack in X indicates
                        ;it's number 11, Shadow leaving after a battle.
                        ;[or number 27 if Gau code enters at C2/48C4.]
         JSR C24E91     ;queue it, in global Special Action queue
         JMP C20019     ;return to somewhere other than C2/0084, by
                        ;branching to start of main battle loop


;Gau arrives after Veldt battle

C248CE:  LDA $3018,X
         TSB $2F4E      ;mark character to enter the battlefield
         TSB $3A40      ;mark Gau as a "character acting as enemy" target
         LDA #$04
         TSB $3A46      ;tell main battle loop we're about to have Gau return
                        ;at the end of a Veldt battle
         LDX #$1B       ;Attack
         BRA C248C4     ;go queue Battle Event number 27, Gau arriving after
                        ;a Veldt battle


;Gau leapt
C248E0:  LDX $300B      ;which character is Gau
         JSR C247E3     ;remove him from all parties
         LDA #$08
         TRB $1EDF      ;un-enlist Gau
;   FB 09-Used by returning Gau when he joins the party , enters here)
C248EB:  JSR C24A07     ;Add rages learned in battle
         BRA C2488F
 

;Banon fell
C248F0:  LDA #$36
         JSR C25FCA     ;handle battle ending in loss
C248F5:  BRA C2488F
 

;<>Pointers for Special Combat Endings
;Code pointers

      : dw C24897    ;(02-Warp)
      : dw C248E0    ;(04-Gau leapt)
      : dw C248F0    ;(06-Banon fell)
      : dw C248A1    ;(08-FB 02-Usual monster script way to end a battle)
      : dw C248EB    ;0A-FB 09-Used by returning Gau when he joins the
                     ; party
      : dw C24A22    ;(0C-Final battle tier transition)


C24903:  JSR C20B36     ;Establish new value for Morph supply based on its
                        ;previous value and the current Morph timer
         LDX #$06
C24908:  STZ $3B04,X    ;Zero this entity's Morph gauge
         TXA
         LSR
         STA $10
         LDA #$03
         JSR C26411
         DEX
         DEX
         BPL C24908
         LDA #$80
         TSB $B1
         LDX #$20
C2491E:  LDA #$01
         JSR C26411
         DEX
         BNE C2491E
         LDA #$0F
         TSB $3A8C      ;mark all characters to have their applicable items
                        ;added to inventory.  in particular, this will
                        ;handle an item they tried to use (the game depletes
                        ;it on issuing the command, but were killed before
                        ;before they could actually execute the command and
                        ;use it.
         JSR C262C7     ;add items [back] to a $602D-$6031 buffer
         LDA #$0A
         JSR C26411     ;for any $602D-$6031 buffer entries that C2/62C7
                        ;filled, now actually copy them to Item menu
         JMP C22095     ;Recalculate applicable characters' properties from
                        ;their current equipment and relics


C24936:  LDX #$06
C24938:  LDA $3ED8,X    ;get which character this is
         BMI C2497B     ;if it's undefined, skip it
         CMP #$10
         BEQ C24945     ;branch if it's 1st ghost
         CMP #$11
         BNE C2494C     ;branch if it's not 2nd ghost
C24945:  LDA $3EE4,X    ;Check for Dead, Zombie, or Petrify
         BIT #$C2
         BNE C24954     ;branch if one or more ^
C2494C:  LDA $3018,X
         BIT $3A88      ;was this character flagged to be removed from
                        ;party? [by Possessing or getting hit by
                        ;BabaBreath]
         BEQ C24957     ;branch if not
C24954:  JSR C247E3     ;remove character from all parties
C24957:  LDA $3EF9,X    ;in-battle status byte 4
         AND #$C0       ;only keep Dog Block and Float after battle
         XBA
         LDA $3EE4,X    ;in-battle status byte 1
         REP #$30       ;Set 16-bit Accumulator, 16-bit X and Y
         LDY $3010,X    ;get offset to character info block
         STA $1614,Y    ;save in-battle status bytes 1 and 4 to our
                        ;two out-of-battle status bytes
         LDA $3BF4,X
         STA $1609,Y    ;save current HP in out-of-battle stat
         LDA $3C30,X
         BEQ C24979     ;Branch if max MP is zero
         LDA $3C08,X
         STA $160D,Y    ;otherwise, save current MP in out-of-battle stat
C24979:  SEP #$30
C2497B:  DEX
         DEX
         BPL C24938     ;loop for all 4 party members
         REP #$10
         LDX #$00FF
         LDY #$04FB
C24987:  LDA $2686,Y
         STA $1869,X    ;copy item ID from Item menu to persistent
                        ;list
         INC
         BEQ C24993     ;if item is #255 [Null], store 0 as quantity
         LDA $2689,Y
C24993:  STA $1969,X    ;copy quantity from Item menu to persistent
                        ;list
         DEY
         DEY
         DEY
         DEY
         DEY
         DEX
         BPL C24987     ;iterate for all 256 Item slots
         LDA $3A97
         BEQ C249C4     ;branch if not Colosseum brawl
         LDA $0205      ;item wagered
         CMP #$FF
         BEQ C249C4     ;branch if null
         LDX #$00FF
C249AD:  CMP $1869,X    ;is item wagered in this slot?
         BNE C249C1     ;branch if not
         DEC $1969,X    ;if it was, decrement the item's count as
                        ;a Colosseum fee
         BEQ C249B9     ;if there's none of the item left, empty
                        ;out its slot
         BPL C249C1     ;if there's a nonzero and positive quantity
                        ;of the item, don't empty out its slot
C249B9:  LDA #$FF
         STA $1869,X    ;store Empty item
         STZ $1969,X    ;with a quantity of 0
C249C1:  DEX            ;move to next lowest item slot
         BPL C249AD     ;loop for all 256 item slots
C249C4:  SEP #$10
         LDX $33FA      ;Which monster is Doom Gaze
         BMI C249D5     ;Branch if Doom Gaze not in battle [FFh]
         REP #$20       ;Set 16-bit Accumulator
         LDA $3BF4,X    ;Monster's HP
         STA $3EBE      ;Set Doom Gaze's HP to monster's HP
         SEP #$20       ;Set 8-bit A
C249D5:  LDX #$13
C249D7:  LDA $3EB4,X    ;copy in-battle event bytes
         STA $1DC9,X    ; back into normal out-of-battle event bytes
         DEX
         BPL C249D7     ;iterate 20 times
         LDA $2F4B
         BIT #$02
         BNE C24A06     ;exit if this formation has "Don't appear on Veldt"
                        ;property
         LDX #$0A
C249E9:  LDA $2002,X    ;Get MSB of monster #
         BNE C24A02     ;If they're a boss or enemy slot is unoccupied, don't
                        ;mark formation as found, but check next monster
         LDA $3ED5
         LSR            ;Move bit 8 of formation # into Carry and out of A
         BNE C24A06     ;If any of bits 9-15 were set, the formation # is
                        ;over 511.  skip it.
         LDA $3ED4      ;Get bits 0-7 of First Battle Formation
         JSR C25217     ;X = formation DIV 8, A = 2^(formation MOD 8)
         ORA $1DDD,X
         STA $1DDD,X    ;Update structure of encountered groups for Veldt
         BRA C24A06     ;Once Veldt structure is updated once, we can exit
C24A02:  DEX
         DEX
         BPL C249E9     ;Move to next enemy and loop
C24A06:  RTS


;Add rages learned in battle

C24A07:  LDX #$0A
C24A09:  LDA $2002,X
         BNE C24A1D     ;Branch if monster # >= 256 , or if enemy slot is
                        ;unoccupied
         PHX
         CLC
         LDA $2001,X    ;Low byte of monster #
         JSR C25217     ;X = monster # DIV 8, A = 2^(monster # MOD 8)
         ORA $1D2C,X
         STA $1D2C,X    ;Add rage to list of known ones
         PLX
C24A1D:  DEX
         DEX
         BPL C24A09     ;Check for all monsters
         RTS


;For final battle tier transitions, do some end-battle code, and clean out
; Wounded/Petrified/Zombied and Air Anchored characters)

C24A22:  JSR C20267
         JSR C24903
         JSR C24936
         LDX #$12
C24A2D:  CPX #$08
         BCS C24A65     ;branch if monster
         LDA $3AA0,X
         LSR
         BCC C24A54     ;branch if entity not present in battle
         LDA $3EE4,X
         BIT #$C2       ;Check for Dead, Zombie, or Petrify
         BNE C24A54     ;branch if some possessed
         LDA $3205,X
         BIT #$04
         BEQ C24A54     ;branch if under Air Anchor effect
         REP #$20       ;set 16-bit A
         LDA $3EF8,X    ;status bytes 3 and 4
         AND #$EEFE
         STA $3EF8,X    ;clear Dance, Rage, and Spell Chant statuses
         SEP #$20       ;set 8-bit A
         BRA C24A68
C24A54:  LDA #$FF
         STA $3ED8,X    ;indicate null for "which character this is"
         LDA $3018,X
         TRB $3F2C      ;clear entity from jumpers
         TRB $3F2E      ;make them eligible to use an Esper again
         TRB $3F2F      ;make them eligible to use a Desperation Attack
                        ;again
C24A65:  JSR C24A9E     ;Clear all statuses
C24A68:  DEX
         DEX
         BPL C24A2D     ;loop for all onscreen entities
         LDA #$0C
         JSR C26411
         PLA
         PLA            ;clear caller address from stack
         JMP C20016     ;do start of battle initialization function, then
                        ;proceed with main battle loop


;If one of first 3 tiers of final 4-tier multi-battle, take certain steps for
; transition, and don't return to caller)

C24A76:  REP #$20
         LDX #$04
C24A7A:  LDA C24AAB,X
         CMP $11E0      ;is Battle formation one of the first 3 tiers of
                        ;the final 4-tier multi-battle?
         BNE C24A97     ;branch and check another if no match
         LDA C24AAD,X
         STA $11E0      ;update Battle formation to the next one of the
                        ;tiers
         SEP #$20
         LDA C24AB3,X   ;holds some transition animation ID, and indicates
                        ;one of last 3 tiers of final 4-tier multi-battle
                        ;by being non-FFh
         STA $3EE1
         PLA
         PLA            ;clear caller address from stack
         BRA C24A22     ;this lets us return somewhere other than C2/4840
                        ;do some end-battle code for tier transition, and
                        ;clean out dead/etc and Air Anchored characters
C24A97:  DEX
         DEX
         BPL C24A7A     ;iterate 3 times
         SEP #$20
         RTS            ;return normally to caller


;Clears all statuses

C24A9E:  STZ $3EE4,X    ;Clear Status Byte 1
         STZ $3EE5,X    ;Clear Status Byte 2
         STZ $3EF8,X    ;Clear Status Byte 3
         STZ $3EF9,X    ;Clear Status Byte 4
         RTS


;Data for changing formations in last battle

C24AAB: dw $01D7     ;(Short Arm, Long Arm, Face)
C24AAD: dw $0200     ;(Hit, Tiger, Tools)
      : dw $0201     ;(Girl, Sleep)
      : dw $0202     ;(Final Kefka)

C24AB3: dw $9090
      : dw $9090
      : dw $8F8F


;Update lists and counts of present and/or living characters and monsters

C24AB9:  REP #$20       ;Set 16-bit Accumulator
         LDA $2F4C
         EOR #$FFFF
         AND $2F4E
         STA $2F4E      ;entities to add to battlefield = entities to add to
                        ;battlefield - entities to remove from battlefield
         STA $3A78      ;save it as initial lists of present characters and
                        ;enemies?
         STZ $3A74      ;clear lists of present and living characters and
                        ;enemies
         STZ $3A42      ;clear list of present and living characters acting
                        ;as enemies?
         SEP #$20
         LDX #$06
C24AD4:  LDA $3AA0,X
         LSR            ;Carry = is this entity present?
         LDA $3018,X    ;get which target this is
         BIT $2F4C
         BNE C24B02     ;branch if target is being removed from battlefield
         BIT $2F4E
         BNE C24AF3     ;branch if target is being added to battlefield
         BCC C24B02     ;branch if entity not present
         TSB $3A78      ;add to list of present characters?
         XBA
         LDA $3EE4,X
         BIT #$C2       ;Zombie, Petrify or death status?
         BNE C24B02     ;if any possessed, branch
         XBA
C24AF3:  AND $3408      ;always FFh, i believe
         TSB $3A74      ;add to list of present and living characters
         AND $3A40      ;only keep set if character acting as an enemy
         TSB $3A42      ;add to list of present and living characters acting
                        ;as enemies?
         TRB $3A74      ;remove from list of present and living characters
C24B02:  DEX
         DEX
         BPL C24AD4     ;iterate for all 4 characters
         LDX #$0A
C24B08:  LDA $3AA8,X
         LSR            ;Carry = is this entity present?
         LDA $3021,X    ;get which target this is.  aka $3019
         BIT $2F4D
         BNE C24B32     ;branch if target is being removed from battlefield
         BIT $2F4F
         BNE C24B2C     ;branch if target is being added to battlefield
         BCC C24B32     ;branch if entity not present
         TSB $3A79      ;add to list of present enemies?
         BIT $3A3A      ;is it in bitfield of dead-ish monsters?
         BNE C24B32     ;branch if so
         XBA
         LDA $3EEC,X    ;aka $3EE4
         BIT #$C2       ;Zombie, Petrify or death status?
         BNE C24B32     ;if any possessed, branch
         XBA
C24B2C:  AND $3409      ;starts as bits set for every monster, but can be
                        ;modified by F5 script commands
         TSB $3A75      ;add to list of present and living enemies
C24B32:  DEX
         DEX
         BPL C24B08     ;iterate for all 6 monsters
         PHX
         PHP
         LDA $3A74      ;list of present and living characters
         JSR C2520E
         STX $3A76      ;Set Number of present and living characters in
                        ;party to number of bits set in $3A74
         LDA $3A75      ;list of present and living enemies
         XBA
         LDA $3A42      ;list of present and living characters acting
                        ;as enemies?
         REP #$20       ;Set 16-bit Accumulator
         JSR C2520E
         STX $3A77      ;Set Number of monsters left in combat to
                        ;number of bits set in $3A42 & $3A75
         PLP
         PLX
         RTS


;Random Number Generator 1 (0 or 1, carry clear or set

C24B53:  PHA            ;Put on stack
         JSR C24B5A
         LSR
         PLA
         RTS


;Random Number Generator 2 (0 to 255

C24B5A:  PHX
         INC $BE        ;increment RNG index
         LDX $BE
         LDA $C0FD00,X  ;RNG Table
         PLX
         RTS


;Random Number Generator 3 (0 to accumulator - 1

C24B65:  PHX
         PHP
         SEP #$30       ;Set 8-bit A, X, Y
         XBA
         PHA            ;save top half of A
         INC $BE        ;increment RNG index
         LDX $BE
         LDA $C0FD00,X  ;RNG Table
         JSR C24781     ;16-bit A = (input 8-bit A) * (Random Number Table value)
         PLA            ;restore top half of A
         XBA            ;now bottom half of A =
                        ;(input 8-bit A * Random Table value) / 256
         PLP
         PLX
         RTS


;Process one or two records from entity's Counterattack [both "Run Monster Script" and the
; actual payload commands, which might be launched from a script] and Periodic Damage/Healing
; [e.g. Regen/Seizure] linked list queue)

C24B7B:  SEC
         ROR $3407      ;make $3407 negative.  this defaults to not leaving
                        ;off processing any entity.
         LDA #$01
         TSB $B1        ;indicate it's an unconventional attack
         PEA.w C20019-1 ;will return to C2/0019
C24B86:  LDA $32CD,X    ;get entry point to entity's counterattack or periodic
                        ;damage/healing linked list queue
         BMI C24BF3     ;exit if null.  that can happen if:
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
         ASL
         TAY
         JSR C20276     ;Load command, attack, targets, and MP cost from queued
                        ;data.  Some commands become Fight if tried by an Imp.
         CMP #$1F       ;is command "Run Monster Script"?
         BNE C24B9C     ;branch it not
         JSR C24C54     ;remove current first record from entity's counterattack
                        ;or periodic damage/healing linked list queue, and update
                        ;their entry point accordingly
         JSR C24BF4     ;Run Monster Script, counterattack portion
         BRA C24B86     ;go load next record in queue
C24B9C:  LDA $32CD,X    ;get entry point to queue
         TAY
         LDA $3184,Y    ;read pointer/ID of current first record in queue
         CMP $32CD,X    ;if that field's contents match record's position, it's
                        ;a standalone record, or the last in the linked list
         BNE C24BAA     ;branch if not, as there are more records left
         LDA #$FF
C24BAA:  STA $32CD,X    ;either make entry point index next record, or null it
         LDA #$FF
         STA $3184,Y    ;null current first record in queue
                        ;last 9 instructions could be replaced with "JSR C24C54",
                        ;which Square used right above them.
         LDA $B5
         CMP #$1E
         BCS C24BD5     ;branch and proceed if command is >= 1Eh.  in this
                        ;context, that's Enemy Roulette, periodic damage/healing,
                        ;and F2, F3, F5, F7, and F8 - FB script commands.
         CPX #$08
         BCS C24BD5     ;branch and proceed if monster
         LDA $3018,X
         BIT $3A39      ;has character escaped?
         BNE C24BE3     ;branch and skip execution if so
         BIT $3A40      ;is character acting as enemy?
         BNE C24BD5     ;branch and proceed if so
         LDA $3A77      ;Number of monsters left in combat
         BEQ C24BE3     ;branch and skip execution if none
         LDA $3AA0,X
         BIT #$50
         BNE C24BE3
C24BD5:  LDA $3204,X
         ORA #$04
         STA $3204,X
         JSR C213D3     ;Character/Monster Takes One Turn
         JSR C2021E     ;Save this command's info in Mimic variables so Gogo
                        ;will be able to Mimic it if he/she tries.
C24BE3:  LDA $32CD,X    ;get entry point to entity's counterattack or periodic
                        ;damage/healing linked list queue
         INC
         BNE C24BF0     ;branch if it's valid -- which includes anything added
                        ;during C2/13D3 call
         LDA $B0
         BMI C24BF3     ;if we were in middle of processing a conventional
                        ;linked list queue, skip C2/0267
         JMP C20267
C24BF0:  STX $3407      ;leave off processing entity in X
C24BF3:  RTS


;Run Monster Script [Command 1Fh], counterattack portion, and handle bookmarking.
; Provided we haven't already done so this batch.)

C24BF4:  PHP
         REP #$20       ;Set 16-bit accumulator
         STZ $3A98      ;start off not prohibiting any script commands
         LDA $3018,X
         TRB $33FC      ;indicate that this entity has done Command 1Fh
                        ;this "batch"
         BEQ C24C52     ;exit if that was already the case
         TRB $3A56      ;clear "entity died since last use of Command 1Fh,
                        ;counterattack variant"
         BNE C24C28     ;branch if it had been set
         LDA $3403      ;Is Quick's target byte $3404 null [i.e. FFh]?
         BMI C24C11     ;branch if so
         CPX $3404
         BNE C24C30     ;branch if current entity is not the one under
                        ;influence of Quick
C24C11:  LDA $3E60,X    ;Quasi Status after attack, bytes 1-2.
                        ;see C2/450D for more info.
         BIT #$B000
         BNE C24C30     ;if Sleep, Muddled or Berserk is set, branch
         LDA $3E74,X    ;Quasi Status after attack, bytes 3-4.
                        ;see C2/450D for more info.
;         (An enemy who is Muddled/Berserked/etc won't counterattack (unless their
;          script has the FC 1C command) a non-lethal strike that doesn't outright
;          remove the status.  Using these Quasi Status bytes will uphold that behavior
;          for a lethal strike -- provided the creature isn't countering with FC 12 or
;          FC 1C -- by not being swayed by Wound's side effects of removing
;          Muddled/Berserk/etc status.)
         BIT #$0210
         BNE C24C30     ;if Freeze or Stop is set, branch
         LDA $3394,X
         BPL C24C30     ;branch if you're Charmed by somebody
         BRA C24C33
C24C28:  LDA $3018,X
         TSB $33FE      ;disable flag indicating that entity was targeted
                        ;in the counter-triggering attack, and by
                        ;somebody/something other than itself
         BEQ C24C11     ;if flag was enabled [read: 0], branch and do
                        ;usual status checks.
                        ;if it was already disabled, the counter was
                        ;triggered purely as a "catch-all" due to the entity
                        ;being dead, so limit the allowed script commands.
C24C30:  DEC $3A98      ;disable most types of script commands.
                        ;the FC 12 and FC 1C commands can override this.
C24C33:  LDA $3268,X    ;offset of monster's counterattack script
         STA $F0        ;upcoming $1A2F call will start at this position
         LDA $3D20,X    ;counterattack script position after last executed
                        ;FD command.  iow, where we left off.  applicable
                        ;when $3241,X =/= FFh.
         STA $F2
         LDA $3241,X    ;index of sub-block in counterattack script where
                        ;we left off if we exited script due to FD command,
                        ;null FFh otherwise.
         STA $F4
         CLC
         JSR C21A2F     ;Process monster's counterattack script, backing up
                        ;targets first
         LDA $F2
         STA $3D20,X    ;save counterattack script position after last
                        ;executed FD command.  iow, where we're leaving
                        ;off.
         SEP #$20
         LDA $F5
         STA $3241,X    ;if we exited script due to FD command, save sub-block
                        ;index of counterattack script where we left off.  if
                        ;we exited due to executing FE command or executing/
                        ;reaching FF command, save null FFh.
C24C52:  PLP
         RTS


;Remove current first record from entity's counterattack or periodic damage/healing
; linked list queue, and update their entry point accordingly)

C24C54:  PHX
         INX
         JSR C20301
         PLX
         RTS


;Prepare Counter attacks (Retort, Interceptor, Black Belt, monster script counter

C24C5B:  LDX #$12
C24C5D:  LDA $3AA0,X
         LSR
         BCC C24CBE     ;skip entity if not present in battle
         LDA $341A      ;did attack have X-Zone/Odin/Snare special effect,
                        ;or Air Anchor special effect?
         BEQ C24CBE     ;branch and skip counter if so
         STZ $B8
         STZ $B9        ;assume no external entity hit this one to start
         LDA $32E0,X    ;Top bit = 1 if hit by this attack. [note that
                        ;targets missed due to the attack not changing any
                        ;statuses or due to special effects checks can
                        ;still count as hit.]
                        ;Bottom seven bits = index of entity who last
                        ;attacked them [which includes spell reflectors].
         BPL C24C86     ;Branch if this attack does not target them
         ASL
         STA $EE        ;multiply attacker index by 2 so we can access
                        ;their data
         CPX $EE
         BEQ C24C86     ;Branch if targeting yourself
         TAY            ;Y = attacker index
         REP #$20       ;Set 16-bit accumulator
         LDA $3018,Y
         STA $B8        ;Put attacker in $B8
         LDA $3018,X
         TRB $33FE      ;enable flag indicating that entity was hit by
                        ;this attack, and by somebody/something other
                        ;than itself.
C24C86:  REP #$20
         LDA $3018,X
         BIT $3A56      ;has entity died since last executing Command 1Fh,
                        ;"Run Monster Script", counterattack variant?
         SEP #$20       ;Set 8-bit accumulator
         BNE C24C9D     ;Branch if so.  this is a "catch-all" to allow
                        ;counters when not normally permitted.
         LDA $B1
         LSR
         BCS C24CBE     ;Branch if it's a counterattack, periodic
                        ;damage/healing, or a special command like a
                        ;status expiring or an equipment auto-spell.
                        ;iow, No counter if not a normal attack.
         LDA $B8
         ORA $B9
         BEQ C24CBE     ;No counter if not target of attack, or if
                        ;targeting yourself
C24C9D:  LDA $3269,X    ;top byte of offset to monster's
                        ;counterattack script
         BMI C24CB1     ;branch if it has no counterattack script
         LDA $32CD,X    ;get entry point to entity's counterattack or periodic
                        ;damage/healing linked list queue
         BPL C24CB1     ;branch if they have one of the above queued
         LDA #$1F
         STA $3A7A      ;Set command to #$1F ("Run Monster Script")
         JSR C24EB2     ;queue it, in entity's counterattack and periodic
                        ;damage/healing queue.  C2/4BF4 [using C2/1A2F] is
                        ;what walks the monster script and decides what
                        ;action(s) to actually perform.
         BRA C24CBE
C24CB1:  CPX #$08
         BCS C24CBE     ;Branch if monster
         LDA $11A2
         LSR
         BCC C24CBE     ;Branch if magical attack
         JSR C24CC3     ;Consider Retort counter, Dog Block counter,
                        ;or Black Belt counter
C24CBE:  DEX
         DEX
         BPL C24C5D     ;Check for each character and monster
C24CC2:  RTS


;Retort

C24CC3:  LDA $3E4C,X
         LSR
         BCC C24CD6     ;Branch if no retort; check dog block
         LDA #$07
         STA $3A7A      ;Store Swdtech in command
         LDA #$56
         STA $3A7B      ;Store Retort in attack
         JMP C24EB2     ;queue it, in entity's counterattack and periodic
                        ;damage/healing queue


;Dog Block

C24CD6:  LDA $B9
         BEQ C24CC2     ;Exit function if attacked by party
         CPX $3416      ;was this target protected by a Dog block on
                        ;this turn?  [or if it's a multi-strike attack
                        ;and Interceptor status was hacked onto multiple
                        ;characters, then was this target the most
                        ;recently protected on the turn?]
         BNE C24CF4     ;if target wasn't protected by a dog block,
                        ;branch to Black Belt
         JSR C24B5A     ;random: 0 to 255
         LSR
         BCC C24CF4     ;50% chance branch to Black Belt
         LSR            ;Carry will determine which Interceptor
                        ;counterattack is used: 50% chance of each
         TDC
         ADC #$FC
         STA $3A7B      ;Store Wild Fang or Take Down in attack
         LDA #$02
         STA $3A7A      ;Store Magic in command
         JMP C24EB2     ;queue it, in entity's counterattack and periodic
                        ;damage/healing queue


;Black Belt counter

C24CF4:  LDA $3018,X
         BIT $3419      ;was this target damaged [by an attacker other
                        ;than themselves] this turn?  the target's bit
                        ;will be 0 in $3419 if they were.
         BNE C24CC2     ;Exit if they weren't
         LDA $3C58,X
         BIT #$02       ;Check for Black Belt
         BEQ C24CC2     ;Exit if no Black Belt
         JSR C24B5A     ;random: 0 to 255
         CMP #$C0
         BCS C24CC2     ;25% chance of exit
         TXY
         PEA $A0CA      ;Death, Petrify, M-Tek, Zombie, Sleep, Muddled
         PEA $3211      ;Stop, Dance, Freeze, Spell, Hide
         JSR C25864
         BCC C24CC2     ;Exit if any set
         STZ $3A7A      ;Store Fight in command
         STZ $3A7B
         JMP C24EB2     ;queue it, in entity's counterattack and periodic
                        ;damage/healing queue


;Handle player-confirmed commands

C24D1F:  LDY $3A6A      ;confirmed commands pointer: 0, 8, 16, or 24
         LDA $2BAE,Y    ;is there a valid, not-yet-processed 0-3
                        ;party member ID in this queue slot?
         BMI C24D6C     ;Exit function if not
         ASL
         TAX            ;X = 0, 2, 4, 6 party member index
         JSR C24E66     ;put entity in wait queue
         LDA #$7B
         JSR C20792     ;clear Bits 2 and 7 of $3AA0,X
         LDA #$FF
         STA $2BAE,Y    ;null party member ID, as we're processing it
         TYA
         ADC #$08       ;advance confirmed commands pointer to next
                        ;position
         AND #$18       ;wrap to 0 if exceeds 24
         STA $3A6A
         JSR C24D6D     ;load targets of [first] confirmed command
         LDA $2BB0,Y    ;get party member's [first] confirmed attack/
                        ;subcommand ID
         XBA
         LDA $2BAF,Y    ;get party member's [first] confirmed command ID
         JSR C24D89     ;Perform various setup for the command.
                        ;note that command in bottom of A holds Magic [02h]
                        ;if command was X-Magic [17h].
         JSR C24D77     ;Clears targets if attacker is Zombied or Muddled
         JSR C24ECB     ;queue first command+attack, in entity's
                        ;conventional queue
         LDA $2BAF,Y
         CMP #$17       ;was confirmed and unadjusted command ID X-Magic?
         BNE C24D1F     ;if not, repeat loop and look for other characters
         INY
         INY
         INY
         JSR C24D6D     ;load targets of second confirmed command
         LDA $2BB0,Y    ;get party member's second confirmed attack/
                        ;subcommand ID)  (aka $2BB3,Old_Y
         XBA
         LDA #$17       ;command = X-Magic
         JSR C24D77     ;Clears targets if attacker is Zombied or Muddled
         JSR C24ECB     ;queue second, X-Magic attack, in entity's
                        ;conventional queue
         BRA C24D1F     ;repeat loop and look for other characters
C24D6C:  RTS


;Load targets of player-confirmed command

C24D6D:  PHP
         REP #$20
         LDA $2BB1,Y    ;targets of party member's confirmed command
         STA $B8
         PLP
         RTS


;Clears targets if attacker is Zombied or Muddled

C24D77:  PHP
         REP #$20       ;set 16-bit accumulator
         STA $3A7A      ;save command and attack/subcommand in intermediate
                        ;variable used by C2/4ECB
         LDA $3EE4,X
         BIT #$2002
         BEQ C24D87     ;branch if not Zombie or Muddle
         STZ $B8        ;clear targets
C24D87:  PLP
         RTS


;Perform various setup for player-confirmed command
;Entered with command in bottom of A, and attack/sub-command in top of A.
; Returns with same format, but attack/sub-command can often be changed, and
; even command can be changed in X-Magic's case.  Targets can also be changed.)

C24D89:  PHX
         PHY
         TXY
         CMP #$17
         BNE C24D92     ;Branch if not X-Magic
         LDA #$02       ;Set command to Magic
C24D92:  CMP #$19
         BNE C24DA7     ;Branch if not Summon
         PHA            ;Put on stack
         XBA
         CMP #$FF       ;Check if no Esper ID from input.  my guess is that's the
                        ;case in "Summon" proper as opposed to via Magic menu.
         BNE C24D9F     ;branch if there was a valid one
         LDA $3344,Y    ;get equipped Esper
C24D9F:  XBA
         LDA $3018,Y
         TSB $3F2E      ;make character ineligible to use Esper again this
                        ;battle
         PLA
C24DA7:  CMP #$01
         BEQ C24DAF     ;Branch if Item
         CMP #$08
         BNE C24DB4     ;Branch if not Throw
C24DAF:  XBA
         STA $32F4,Y    ;store as item to add back to inventory.  this can
                        ;happen with:
                        ;1 Equipment Magic that doesn't destroy the item
                        ;   [no items have this, but the game supports it]
                        ;2 the item user's turn never happens.  perhaps the
                        ;   character who acted before them won the battle.
         XBA
C24DB4:  CMP #$0F
         BNE C24DDB     ;Branch if not Slot
         PHA            ;save command #
         XBA            ;get our Slot index
         TAX
         LDA C24E4A,X   ;get spell # used by this Slot combo
         CPX #$02
         BCS C24DD2     ;branch if it's Bahamut or higher -- i.e. neither form
                        ;of Joker Doom
         PHA            ;save spell #
         LDA C24E52,X   ;get Joker Doom targeting
         STA $B8,X      ;if X is 0 [7-7-Bar], mark all party members in $B8
                        ;if X is 1 [7-7-7], mark all enemies in $B9
         LDA $B8
         EOR $3A40
         STA $B8        ;toggle whether characters acting as enemies are targeted.
                        ;e.g. Shadow in Colosseum or Gau returning from Veldt leap
         PLA            ;restore spell #
C24DD2:  CMP #$FF
         BNE C24DD9     ;branch if not Bar-Bar-Bar
         JSR C237DC     ;Pick random esper
C24DD9:  XBA
         PLA            ;restore command #
C24DDB:  CMP #$13
         BNE C24DEC     ;Branch if not Dance
         PHA            ;Put on stack
         XBA
         STA $32E1,Y    ;save as Which dance is selected for this character
         STA $3A6F      ;and save as a more global dance #, which other
                        ;characters might fall back to
         JSR C2059C     ;Pick dance and dance move
         XBA
         PLA
C24DEC:  CMP #$10
         BNE C24DFA     ;Branch if not Rage
         PHA            ;Put on stack
         XBA
         STA $33A8,Y    ;Which rage is being used
         JSR C205D1     ;Picks a Rage [when Muddled/Berserked/etc], and picks
                        ;the Rage move
         XBA
         PLA
C24DFA:  CMP #$0A
         BNE C24E13     ;Branch if not Blitz
         PHA            ;Put on stack
         XBA
         PHA            ;Put on stack
         BMI C24E10     ;Branch if no blitz selected
         TAX
         JSR C21E57     ;Set Bit #X in A
         BIT $1D28
         BNE C24E10     ;Branch if selected blitz is known
         LDA #$FF
         STA $01,S      ;replace spell/attack # with null
C24E10:  PLA
         XBA
         PLA
C24E13:  LDX #$04
C24E15:  CMP C24E3C,X   ;does our command match one that needs its
                        ;spell # calculated?
         BNE C24E26     ;branch if not
         XBA
         CLC
         ADC C24E41,X   ;add the first spell # for this command to our
                        ;current index.  ex - for Pummel, Blitz #0, we'd
                        ;end up with 55h.
         BCC C24E25     ;branch if the spell # didn't overflow
         LDA #$EE       ;load Battle as spell #
C24E25:  XBA            ;put spell # in top of A, and look at command # again
C24E26:  DEX
         BPL C24E15     ;loop for all 5 commands
         PHA            ;Put on stack
         CLC            ;clear Carry
         JSR C25217     ;X = A DIV 8, A = 2 ^ (A MOD 8)
         AND C24E46,X   ;compare to bitfield of commands that need to retarget
         BEQ C24E38     ;Branch if command doesn't need to retarget
         STZ $B8
         STZ $B9        ;clear targets
C24E38:  PLA
         PLY
         PLX
         RTS


;Data - commands that need their spell # calculated

C24E3C: db $19   ;(Summon)
      : db $0C   ;(Lore)
      : db $1D   ;(Magitek)
      : db $0A   ;(Blitz)
      : db $07   ;(Swdtech)


;Data - first spell # for each of above commands

C24E41: db $36   ;(Espers)
      : db $8B   ;(Lores)
      : db $83   ;(Magitek commands)
      : db $5D   ;(Blitzes)
      : db $55   ;(Swdtech)


;Data - commands that need to retarget.  8 commands per byte.

C24E46: db $80   ;(Swdtech)
      : db $04   ;(Blitz)
      : db $0B   ;(Rage, Leap, Dance)
      : db $00   ;(Nothing)


;Data - spell numbers for Slot attacks

C24E4A: db $94   ;(L.5 Doom -- used by Joker Doom [7-7-Bar])
      : db $94   ;(L.5 Doom -- used by Joker Doom [7-7-7])
      : db $43   ;(Bahamut)
      : db $FF   ;(Nothing -- used by Triple Bar?)
      : db $80   ;(H-Bomb)
      : db $7F   ;(Chocobop)
      : db $81   ;(7-Flush)
      : db $FE   ;(Lagomorph)


;Data - Joker Doom targeting

C24E52: db $0F   ;(7-7-bar => your whole party)
      : db $3F   ;(7-7-7  => whole enemy party)


;Add a record to the "master list".  It contains standalone records, or linked
; list queues.  It won't make much sense without its entry points, held in
; $32CC,target , $32CD,target, and $340A.)
;Just the pointer/ID field is initialized by this call.  "Sister structures" are
; $3420, $3520, and $3620.  As they're 2 bytes per slot instead of 1, they're
; physically separate, but conceptually, they're just more fields of the same record.)

C24E54:  PHX
         LDX #$7F
C24E57:  LDA $3184,X
         BMI C24E60     ;branch if this slot is free
         DEX
         BPL C24E57     ;iterate for all 128 slots if need be
         INX            ;default to adding at Position 0 if no free
                        ;slot was found
C24E60:  TXA
         STA $3184,X    ;a new record's pointer/ID value starts off
                        ;equal to its slot #
         PLX
         RTS


;Add character/monster to queue of who will wait to act.  One place this is called
; is right after a character's command is input, and before they enter their
; "ready stance".  Monsters' ready stances aren't visible [and are generally
; negligible in length], but monsters still use this queue too.)

C24E66:  TXA
         PHX
         LDX $3A65      ;get next available Wait Queue slot
         STA $3720,X    ;store current entity in that slot
         PLX
         INC $3A65      ;point to next queue slot after this one.  this is
                        ;circular: if we've gone past slot #255, we'll restart on
                        ;#0.  that shouldn't be a problem unless 256+ fighters
                        ;get queued up at once somehow.
         LDA #$FE
         JMP C20A43


;Add character/monster to queue of who will act next.  One place this is called is
; when someone's "wait timer" after inputting a command elapses and they can leave
; their ready stance to attack.)

C24E77:  TXA
         PHX
         LDX $3A67      ;get next available Action Queue slot
         STA $3820,X    ;store current entity in that slot
         PLX
         INC $3A67      ;point to next queue slot after this one.  this is
                        ;circular: if we've gone past slot #255, we'll restart on
                        ;#0.  that shouldn't be a problem unless 256+ fighters
                        ;get queued up at once somehow.
         RTS


;Add character/monster to queue of who will next take/undergo counterattacks and
; Regen/Seizure/etc damage/healing.)

C24E84:  TXA
         PHX
         LDX $3A69      ;get next available Counterattack or Damage/Healing slot
         STA $3920,X    ;store current entity in that slot
         PLX
         INC $3A69      ;point to next queue slot after this one.  this is
                        ;circular: if we've gone past slot #255, we'll restart on
                        ;#0.  that shouldn't be a problem unless 256+ fighters
                        ;get queued up at once somehow.
         RTS


;Add command, attack, targets, and [rarely-used] MP cost to global Special Action linked
; list queue)

C24E91:  PHY
         PHP
         SEP #$20
         STA $3A7A      ;Set command
         STX $3A7B      ;Set attack.  often, X holds the acting+target entity,
                        ;or miscellaneous things instead.
         JSR C24E54     ;Add a record [by initializing its pointer/ID field] to
                        ;a "master list" in $3184, a collection of linked list
                        ;queues
         PHA            ;Put on stack
         LDA $340A      ;get global entry point to Special Action linked list
                        ;queue.  includes actions like auto-spellcasts from
                        ;equipment, and timed statuses expiring.  note that unlike
                        ;other entry points, there isn't a separate one for each
                        ;entity.
         CMP #$FF
         BNE C24EDF     ;branch if it's already defined
         LDA $01,S
         STA $340A      ;if it's undefined, set it to the index of the
                        ;list record we just added
         BRA C24EDF     ;if it helps to follow things, view the
                        ;last 3 instructions as: "PLA / STA $340A /
                        ;BRA C24EF0".


;Add command, attack, targets, and MP cost [after determining it] to entity's counterattack
; and periodic damage/healing linked list queue or to its conventional one, depending on $B1.
; Usually called from monster script commands, which can run from either script section.)

C24EAD:  LDA $B1
         LSR            ;is it an unconventional turn [counterattack, in this
                        ;context]?
         BCC C24ECB     ;branch if not
C24EB2:  PHY            ;many callers enter here, to directly use counterattack
                        ;/ periodic damage queue
         PHP
         SEP #$20
         JSR C24E54     ;Add a record [by initializing its pointer/ID field] to
                        ;a "master list" in $3184, a collection of linked list
                        ;queues
         PHA            ;Put on stack
         LDA $32CD,X    ;get entry point to entity's counterattack or periodic
                        ;damage/healing linked list queue
         CMP #$FF
         BNE C24EDF     ;branch if it's already defined
         JSR C24E84     ;add entity to counterattack / periodic damage queue
         LDA $01,S
         STA $32CD,X    ;if it's undefined, set it to the index of the
                        ;list record we just added
         BRA C24EDF     ;if it helps to follow things, view the
                        ;last 3 instructions as: "PLA / STA $32CD,X /
                        ;BRA C24EF0".


;Add command, attack, targets, and MP cost [after determining it] to entity's conventional
; linked list queue)

C24ECB:  PHY
         PHP
         SEP #$20       ;Set 8-bit Accumulator
         JSR C24E54     ;Add a record [by initializing its pointer/ID field] to
                        ;a "master list" in $3184, a collection of linked list
                        ;queues
         PHA            ;Put on stack
         LDA $32CC,X    ;get entry point to entity's conventional linked list
                        ;queue
         CMP #$FF
         BNE C24EDF     ;branch if it's already defined
         LDA $01,S      ;if it's undefined, set it to the index of the
                        ;list record we just added
         STA $32CC,X    ;if it helps to follow things, view the
                        ;last 2 instructions as: "PLA / STA $32CC,X /
                        ;BRA C24EF0".
C24EDF:  TAY            ;index for 8-bit fields
         CMP $3184,Y    ;does the pointer/ID value at PositionY equal
                        ;PositionY?
         BEQ C24EEC     ;if so, it's a standalone record, or the last record
                        ;in a linked list, so branch
         LDA $3184,Y    ;get pointer/ID field.  [note that which queue holds
                        ;this record depends on how we reached here.]
         BMI C24EEC     ;if it's somehow a null record, branch.
                        ;if not, that leaves it being a linked list
                        ;member that points to another record.
         BRA C24EDF     ;loop and check the record that's being pointed to.
                        ;can replace last 2 instructions with "BPL C24EDF".
C24EEC:  PLA
         STA $3184,Y    ;make the record that was last point to the new record.
                        ;[or if the list had been empty, pointlessly re-save
                        ;the new record.]
C24EF0:  ASL
         TAY            ;adjust index for 16-bit fields
         JSR C24F08     ;Determine MP cost of a spell/attack
         STA $3620,Y    ;save MP cost in a linked list queue.  [the specific
                        ;queue varies depending on how we reached here.]
         REP #$20       ;Set 16-bit Accumulator
         LDA $3A7A      ;get command ID and attack/sub-command ID
         STA $3420,Y    ;save command and attack in same linked list queue
         LDA $B8        ;get targets.  if reached from C2/4E91, might instead
                        ;be attack ID or something else.
         STA $3520,Y    ;save targets in same linked list queue
         PLP
         PLY
         RTS


;Determine MP cost of a spell/attack

C24F08:  PHX
         PHP
         TDC            ;16-bit A = 0.  this means the returned spell cost will
                        ;default to zero.
         LDA #$40
         TRB $B1        ;clear Bit 6 of $B1
         BNE C24F53     ;branch if it was set, meaning we're on second Gem Box
                        ;spell for Mimic, and return 0 as cost.  no precaution
                        ;needed for first Mimicked Gem Box spell, as we reach
                        ;this function with $3A7A as 12h [Mimic] then.
         LDA $3A7A      ;get command #
         CMP #$19
         BEQ C24F24     ;branch if it's Summon
         CMP #$0C
         BEQ C24F24     ;branch if it's Lore
         CMP #$02
         BEQ C24F24     ;branch if it's Magic
         CMP #$17
         BNE C24F53     ;branch and use 0 cost if it's not X-Magic
C24F24:  REP #$10       ;Set 16-bit X and Y
         LDA $3A7B      ;get attack #
         CPX #$0008
         BCS C24F47     ;branch if it's a monster attacker.  they don't have
                        ;menus containing MP data, nor relics that can
                        ;alter MP costs.
         PHX
         TAX
         LDA $3084,X    ;get this spell's position relative to Esper menu.  the
                        ;order in memory is Esper menu, Magic menu, Lore menu.
         PLX
         CMP #$FF
         BEQ C24F53     ;if it's somehow not in the menu?, branch and use 0 cost
         REP #$20       ;Set 16-bit Accumulator
         ASL
         ASL            ;multiply offset by 4, as each spell menu entry has 4 bytes:
                        ; Spell index number, Unknown [related to spell availability],
                        ; Spell aiming, MP cost
         ADC $302C,X    ;add starting address of character's Magic menu
         TAX
         SEP #$20       ;Set 8-bit Accumulator
         LDA $0003,X    ;get MP cost from character's menu data.  it usually
                        ;matches the spell data, but Gold Hairpin, Economizer,
                        ;and Step Mine's special formula can make it vary.
         BRA C24F54     ;clean up stack and exit
C24F47:  XBA
         LDA #$0E
         JSR C24781     ;attack # * 14
         TAX
         LDA $C46AC5,X  ;read MP cost from spell data
         XBA
C24F53:  XBA            ;bottom of A = MP cost
C24F54:  PLP
         PLX
         RTS


;Monster command script command #$F7

C24F57:  LDA $B6
         XBA
         LDA #$0F
         JMP C262BF


;Command #$26 - Doom cast when Condemned countdown reaches 0; Safe, Shell, or Reflect*
;               cast when character enters Near Fatal (* no items actually do this,
;               but it's supported); or revival due to Life 3.

C24F5F:  LDA $B8        ;get spell ID?
         LDX $B6        ;get target?
         STA $B6        ;save spell ID
         CMP #$0D
         BNE C24F78     ;branch if we're not casting Doom
         LDA $3204,X
         ORA #$10
         STA $3204,X    ;set flag to zero and disable the Condemned counter
                        ;after turn.  this is done in case instant death is
                        ;thwarted, and thus Condemned status isn't removed
                        ;and C2/4644 never executes.
         LDA $3A77
         BEQ C24FDF     ;Exit function if no monsters are present and alive
         LDA #$0D       ;Set spell to Doom again.  it's easier than PHA/PLA
C24F78:  XBA
         LDA #$02
         STA $B5        ;Set command to Magic
         JSR C226D3     ;Load data for command and attack/sub-command, held
                        ;in A.bottom and A.top
         JSR C22951     ;Load Magic Power / Vigor and Level
         LDA #$10
         TRB $B0        ;Prevents characters from stepping forward and
                        ;getting circular or triangular pattern around
                        ;them when casting Magic or Lores.
         LDA #$02
         STA $11A3      ;Set attack to only not reflectable
         LDA #$20
         TSB $11A4      ;Set can't be dodged
         STZ $11A5      ;Set to 0 MP cost
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Monster command script command #$F5

C24F97:  STZ $3A2A
         STZ $3A2B      ;clear temporary bytes 3 and 4 for ($76 animation
                        ;buffer
         LDA $3A73
         EOR #$FF
         TRB $B9        ;Clear monsters that aren't in formation template
                        ;from command's monster targets
         LDA $B8        ;get subcommand
         ASL
         TAX
         LDY #$12
C24FAA:  LDA $3019,Y
         BIT $B9
         BEQ C24FB4     ;branch if enemy isn't affected by the F5 command
         JSR (C251E4,X) ;execute subcommand on this enemy
C24FB4:  DEY
         DEY
         CPY #$08
         BCS C24FAA     ;iterate for all 6 monsters
         LDA $B6        ;get animation type
         XBA
         LDA #$13
         JMP C262BF


;Command F5 nn 04

C24FC2:  PHA            ;Put on stack
         LDA #$FF
         STA $3A95      ;prohibit C2/47FB from checking for combat end
         PLA
         BRA C24FCE
C24FCB:  TSB $2F4D      ;Command F5 nn 01 enters here
                        ;mark enemy to be removed from the battlefield
C24FCE:  TRB $3409      ;Command F5 nn 03 enters here
         TRB $2F2F      ;remove from bitfield of remaining enemies?
         TSB $3A2A      ;mark in temporary byte 3 for ($76) animation buffer
         LDA $3EF9,Y
         ORA #$20
         STA $3EF9,Y    ;Set Hide status
C24FDF:  RTS


;Command F5 nn 00

C24FE0:  PHA            ;Put on stack
         REP #$20
         LDA $3C1C,Y    ;Max HP
         STA $3BF4,Y    ;Current HP
         SEP #$20
         PLA
C24FEC:  TRB $3A3A      ;Command F5 nn 02 enters here
                        ;remove from bitfield of dead-ish monsters?
         TSB $2F2F      ;add to bitfield of remaining enemies?
         TSB $3A2B      ;mark in temporary byte 4 for ($76) animation buffer
         TSB $2F4F      ;mark enemy to enter the battlefield
         TSB $3409
         STZ $3A95      ;allow C2/47FB to check for combat end
         RTS


;Command F5 nn 05

C24FFF:  JSR C24FCE
         LDA $3EE4,Y
         ORA #$80
         STA $3EE4,Y    ;Set Death status
         RTS


;Regen, Poison, and Seizure/Phantasm damage or healing

C2500B:  LDA $3A77
         BEQ C24FDF     ;Exit if no monsters left in combat
         LDA $3AA1,Y
         AND #$EF
         STA $3AA1,Y    ;clear bit 4 of $3AA1,Y.  because we're servicing this
                        ;damage/healing request, we can allow C2/5A83 to queue
                        ;up another one for this entity as needed.
         LDA $3AA0,Y
         BIT #$10       ;is entity Wounded, Petrified, or Stopped, or is
                        ;somebody else under the influence of Quick?
         BNE C24FDF     ;Exit if any are true
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         LDA #$90
         TRB $B3        ;Set Ignore Clear, and allow for damage increment
                        ;even with Ignore Defense
         LDA #$12
         STA $B5        ;Set command for animation to Mimic
         LDA #$68
         STA $11A2      ;Sets to only ignore defense, no split damage, reverse
                        ;damage/healing on undead
         LSR $11A4
         LDA $B6
         LSR
         LSR
         ROL $11A4      ;Set to heal for regen; damage for poison &
                        ;seizure/phantasm
         LSR
         BCC C25051     ;Branch if not poison
         LDA $3E24,Y    ;Cumulative amount to increment poison damage
         STA $BD        ;save in turn-wide Damage Incrementor
         INC
         INC
         CMP #$0F
         BCC C25049     ;Branch if under 15
         LDA #$0E       ;Set to 14
C25049:  STA $3E24,Y    ;Cumulative amount to increment poison damage for
                        ;next round
         LDA #$08
         STA $11A1      ;Set element to poison
C25051:  LDA $3B40,Y    ;Stamina)    (Figure damage
         STA $E8
         REP #$20
         LDA $3C1C,Y    ;Max HP
         JSR C247B7     ;Max HP * Stamina / 256
         LSR
         LSR
         CMP #$00FE
         SEP #$20
         BCC C25069     ;Branch if under 254
         LDA #$FC       ;set to 253
C25069:  ADC #$02
         STA $11A6      ;Store damage in battle power
         TYX
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Monster command script command #$F2
;$B8 and bottom 7 bits of $B9 = new formation to change to)

C25072:  LDA $B8        ;Byte 2
         STA $11E0      ;Monster formation, byte 1
         ASL $3A47      ;shift out old bit 7
         LDA $B9        ;Byte 3.  top bit: 1 = monsters get Max HP.
                        ;0 = retain HP and Max HP from current formation.
         EOR #$80
         ASL
         ROR $3A47      ;put reverse of bit 7 of $B9 into bit 7 here
         LSR
         STA $11E1      ;Monster formation, byte 2
         JSR C230E8     ;Loads battle formation data
         REP #$20       ;Set 16-bit Accumulator
         LDX #$0A
C2508D:  STZ $3AA8,X    ;clear enemy presence flag
         STZ $3E54,X
         TDC
         DEC
         STA $2001,X    ;save FFFFh [null] as enemy #
         LDA #$FFBC
         STA $320C,X    ;aka $3204,X
         DEX
         DEX
         BPL C2508D     ;loop for all 6 enemies
         SEP #$20       ;Set 8-bit Accumulator
         JSR C22EE1     ;Initialize some enemy presence variables, and load enemy
                        ;names and stats
         JSR C24391     ;update status effects for all applicable entities
         JSR C2069B     ;Do various responses to three mortal statuses
         JSR C2083F
         JSR C24AB9     ;Update lists and counts of present and/or living
                        ;characters and monsters
         JSR C226C9     ;Give immunity to permanent statuses, and handle immunity
                        ;to "mirror" statuses, for all entities.
         JSR C22E3A     ;Determine if front, back, pincer, or side attack
         LDA $3A75      ;list of present and living enemies
         STA $3A2B      ;temporary byte 4 for ($76) animation buffer
         LDA $201E
         STA $3A2A      ;temporary byte 3 for ($76) animation buffer
         LDA $B6
         XBA
         LDA #$12
         JMP C262BF


;Command #$25

C250CD:  LDA #$02
         BRA C250D3
C250D1:  LDA #$10       ;Command #$21 - F3 Command script enters here
C250D3:  XBA
         LDA $B6
         XBA
         STZ $3A2A      ;set temporary byte 3 for ($76 animation buffer
                        ;to 0
         JMP C262BF


;Command #$27 - Display Scan info

C250DD:  LDX $B6        ;get target of original casting
         LDA #$FF
         STA $2D72      ;first byte of second entry of ($76) buffer
         LDA #$02
         STA $2D6E      ;first byte of first entry of ($76) buffer
         STZ $2F36
         STZ $2F37      ;clear message parameter 1, top two bytes
         STZ $2F3A      ;clear message parameter 2, top/third byte
         LDA $3B18,X    ;Level
         STA $2F35      ;save it in message parameter 1, bottom byte
         LDA #$34       ;ID of "Level [parameter1]" message
         STA $2D6F      ;second byte of first entry of ($76) buffer
         LDA #$04
         JSR C26411     ;Execute animation queue
         REP #$20
         LDA $3BF4,X    ;Current HP
         STA $2F35      ;save in message parameter 1, bottom word
         LDA $3C1C,X    ;Max HP
         STA $2F38      ;save in message parameter 2, bottom word
         SEP #$20
         LDA #$30       ;ID of "HP [parameter1]/[parameter2]" message
         STA $2D6F      ;second byte of first entry of ($76) buffer
         LDA #$04
         JSR C26411     ;Execute animation queue
         REP #$20
         LDA $3C08,X    ;Current MP
         STA $2F35      ;save in message parameter 1, bottom word
         LDA $3C30,X    ;Max MP
         STA $2F38      ;save in message parameter 2, bottom word
         SEP #$20
         BEQ C25138
         LDA #$31       ;ID of "MP [parameter1]/[parameter2]" message
         STA $2D6F      ;second byte of first entry of ($76) buffer
         LDA #$04
         JSR C26411     ;Execute animation queue
C25138:  LDA #$15       ;start with ID of "Weak against fire" message
         STA $2D6F      ;second byte of first entry of ($76) buffer
         LDA $3BE0,X
         STA $EE        ;Weak elements
         LDA $3BE1,X
         ORA $3BCC,X
         ORA $3BCD,X
         TRB $EE        ;subtract Absorbed, Nullified, and Resisted
                        ;elements, because those supercede weaknesses
         LDA #$01
C2514F:  BIT $EE
         BEQ C2515A     ;branch if not weak to current element
         PHA            ;Put on stack
         LDA #$04
         JSR C26411     ;Execute animation queue
         PLA
C2515A:  INC $2D6F      ;advance to "Weak against" message with next
                        ;element name
         ASL            ;look at next elemental bit
         BCC C2514F     ;iterate for all 8 elements
         RTS


;Remove Stop, Reflect, Freeze, or Sleep when time is up

C25161:  LDX $3A7D      ;get entity, whom the game regards as performing
                        ;this action on oneself
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         LDA #$12
         STA $B5        ;Set command to Mimic
         LDA #$10
         TRB $B0        ;Prevents characters from stepping forward and
                        ;getting circular or triangular pattern around
                        ;them when casting Magic or Lores.
         LSR $B8
         BCC C25178     ;Branch if bit 0 of $B8 is 0
         LDA #$10
         TSB $11AC      ;Attack clears Stop
C25178:  LSR $B8
         BCC C25181     ;Branch if bit 1 of $B8 is 0
         LDA #$80
         TSB $11AC      ;Attack clears Reflect
C25181:  LSR $B8
         BCC C2518A     ;Branch if bit 2 of $B8 is 0
         LDA #$02
         TSB $11AD      ;Attack clears Freeze
C2518A:  LSR $B8
         BCC C251A0     ;Branch if bit 3 of $B8 is 0
         LDA #$80
         AND $3EE5,X
         BEQ C251A0     ;Branch if not sleeping
         TSB $11AB      ;Attack clears Sleep
         LDA #$02
         STA $B5        ;Set command to Magic
         LDA #$78
         STA $B6        ;Set spell to Tapir.  Note this does *not*
                        ;use the spell _data_ of the Tapir from Mog's
                        ;dance, so it won't have the same effect
C251A0:  LDA #$04
         TSB $11A4      ;Set to lift statuses
         JMP C23167     ;Entity executes one largely unblockable hit on
                        ;self


;Command #$2C (buffer Battle Dynamics Command 0Eh, graphics related: for character
;              poses?  can't always see effect, but this lets Petrify take spellcaster
;              out of chant pose or relax a Defender, for instance.)

C251A8:  LDA $3A7D
         LSR            ;convert target # to 0, 1, 2, etc
         XBA
         LDA #$0E       ;Battle Dynamics Command 0Eh
         JMP C262BF


;Command #$2D (Drain from being seized

C251B2:  LDA $3AA1,Y
         AND #$EF
         STA $3AA1,Y    ;Clear bit 4 of $3AA1,Y.  because we're servicing this
                        ;damage/healing request, we can allow C2/5A83 to queue
                        ;up another one for this entity as needed.
         TYX
         JSR C2298A     ;Load command data, and clear special effect,
                        ;magic power, etc.
         STZ $11AE      ;Set Magic Power to 0
         LDA #$10
         STA $11AF      ;Set Level to 16
         STA $11A6      ;Set Spell Power to 16
         LDA #$28
         STA $11A2      ;Sets to only ignore defense, heal undead
         LDA #$02
         STA $11A3      ;Sets to Not reflectable only
         TSB $11A4      ;Sets Redirection
         TSB $3A46      ;set flag to let this attack target a Seized
                        ;entity, who is normally untargetable
         LDA #$80
         TRB $B2        ;Indicate a special type of drainage.  Normal drain
                        ;is capped at the lowest of: drainee's Current HP/MP
                        ;and drainer's Max - Current HP/MP.  This one will
                        ;ignore the latter, meaning it's effectively just a
                        ;damage attack if the attacker's [or undead target's]
                        ;HP/MP is full.
         LDA #$12
         STA $B5        ;Sets command to Mimic
         JMP C2317B     ;entity executes one hit


;Code pointers for command #$F5

C251E4: dw C24FE0
      : dw C24FCB
      : dw C24FEC
      : dw C24FCE
      : dw C24FC2
      : dw C24FFF


;X = Highest bit in A that is 1 (bit 0 = 0, 1 = 1, etc.

C251F0:  LDX #$00
C251F2:  LSR
         BEQ C251F8     ;Exit if all bits are 0
         INX
         BRA C251F2
C251F8:  RTS


;Y = (Number of highest target set in A * 2
;    (0, 2, 4, or 6 for characters.  8, 10, 12, 14, 16, or 18 for monsters.)

;    (Remember that
;     $3018 : Holds $01 for character 1, $02 for character 2, $04 for character 3,
;             $08 for character 4
;     $3019 : Holds $01 for monster 1, $02 for monster 2, etc.  )

C251F9:  PHX
         PHP
         REP #$20       ;Set 16-bit Accumulator
         SEP #$10       ;Set 8-bit Index Registers
         LDX #$12
C25201:  BIT $3018,X
         BNE C2520A     ;Exit loop if bit set
         DEX
         DEX
         BPL C25201     ;loop through all 10 targets if necessary
C2520A:  TXY
         PLP
         PLX
         RTS


;Sets X to number of bits set in A

C2520E:  LDX #$00
C25210:  LSR
         BCC C25214
         INX
C25214:  BNE C25210
         RTS


;X = A / 8  (including carry, so A is effectively 9 bits
;A = 1 if (A % 8) = 0, 2 if (A % 8) = 1, 4 if (A % 8) = 2,
;    8 if (A % 8) = 3, 16 if (A % 8) = 4, etc.
;    So A = 2 ^ (A MOD 8)
;Carry flag = cleared

C25217:  PHY
         PHA            ;Put on stack
         ROR
         LSR
         LSR
         TAX
         PLA
         AND #$07
         TAY
         LDA #$00
         SEC
C25224:  ROL
         DEY
         BPL C25224
         PLY
         RTS


;Randomly picks a bit set in A

C2522A:  PHY
         PHP
         REP #$20       ;Set 16-bit Accumulator
         STA $EE
         JSR C2520E     ;X = number of bits set in A
         TXA
         BEQ C25244     ;Exit if no bits set
         JSR C24B65     ;random: 0 to A - 1
         TAX
         SEC
         TDC
C2523C:  ROL
         BIT $EE
         BEQ C2523C
         DEX
         BPL C2523C
C25244:  PLP
         PLY
         RTS


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

C25247:  PHY
         XBA
         LDA #$00
         LDY #$03
C2524D:  XBA
         ASL            ;put allowability bit of current Attack or
                        ;Formation type into Carry
         XBA
         BCC C25256     ;Branch if type not allowed
         ADC C25269,X   ;Add chance to get that type, which includes
                        ;plus one for always-set Carry.
C25256:  STA $00FC,Y    ;build an array that determines which ranges
                        ;of random numbers will result in which
                        ;Umaro attacks or Battle formations
         INX
         DEY
         BPL C2524D     ;Check for all 4 types
         JSR C24B65     ;random #: 0 to A - 1 , where A is
                        ;the denominator of our probabilities,
                        ;as explained in the data below.
         LDX #$04
C25262:  DEX
         CMP $FC,X
         BCS C25262     ;Check next type if A >= $FC,X
         PLY
         RTS            ;Return X = Battle type / Attack to use


;NOTE: Effective values are all 1 greater than those listed in C2/5269
; through C2/527C [with FFh wrapping to 00h].)

;Each effective value is the Numerator of the probability of getting a
; certain type of Umaro attack, in the order: Normal attack, Charge/Tackle,
; Storm, Throw character)
;Denominator of the probability is the sum of the effective values.)
C25269: dd $FFFF5F9E    ;(No Rage Ring or Blizzard Orb)
      : dd $5FFF3F5E    ;(Rage Ring)
      : dd $FF5F3F5E    ;(Blizzard Orb)
      : dd $3F3F3F3E    ;(Both)

;Each effective value is the Numerator of probability of getting a
; certain type of attack formation, in the order: Side, Pincer,
; Back, Normal/Front)
;Denominator of the probability is the sum of the effective values,
; excluding those of formations that were skipped at C2/5250 due
; to not being allowed.)
      : dd $CF07071E    ;(For choosing type of battle)



;Gray out or enable character commands based on various criteria, such as: whether
; current equipment supports them, whether the character is inflicted with Imp or
; Mute, and whether they've accumulated enough Magic Points to Morph.
; This function also enables Offering to change the aiming of Fight and Capture.)

C2527D:  PHX
         PHP
         REP #$30       ;Set 16-bit A, X and Y
         TXY
         LDA C2544A,X   ;Get address of character's menu
         TAX
         SEP #$20       ;Set 8-bit Accumulator
         LDA $3018,Y
         TSB $3A58      ;flag this character's main menu to be redrawn
                        ;right away
         LDA $3EE4,Y
         AND #$20
         STA $EF        ;if Imp status possessed, turn on Bit 5 of $EF.
                        ;if not, the variable is set to 0.
         LDA $3BA4,Y    ;weapon properties, right hand
         ORA $3BA5,Y    ;merge with weapon properties, left hand
         EOR #$FF       ;invert
         AND #$82
         TSB $EF        ;if neither hand supports Runic, set Bit 7.
                        ;if neither hand supports SwdTech, set Bit 1.
         LDA #$04
         STA $EE        ;counter variable.. we're going to check
                        ;4 menu slots in all
C252A6:  PHX            ;push address of character's current menu slot
         SEC            ;mark menu slot to be disabled
         TDC            ;clear 16-bit A
         LDA $0000,X    ;get command # in current menu slot
         BMI C252DB     ;branch if slot empty
         PHA            ;push command #
         CLC            ;mark menu slot to be enabled
         LDA $EF
         BIT #$20       ;are they an Imp?
         BEQ C252C3     ;branch if not
         LDA $01,S
         ASL            ;command # * 2
         TAX
         LDA $CFFE00,X  ;table of command info
         BIT #$04       ;is command supported while Imped?
         BNE C252C3     ;branch if so
         SEC            ;mark menu slot to be disabled
C252C3:  PLA            ;fetch command #
         BCS C252DB     ;if menu slot is disabled at this point,
                        ;don't bother with our next checks

;This next loop sees if our current command is one that needs special code to assess
; its menu availability -- graying it if unavailable -- or another property, such as
; its aiming.  If so, a special function is called for the command.)

         LDX #$0007
C252C9:  CMP C252E9,X   ;does our current command match one whose menu
                        ;availability or aiming can vary?
         BNE C252D7     ;if not, compare it to next command in table
         TXA
         ASL
         TAX
         JSR (C252F1,X) ;call special function for command
         BRA C252DB     ;we've gotten a match, so there's no need to
                        ;compare our current command against rest of list
C252D7:  DEX
         BPL C252C9     ;there are 8 possible commands that need
                        ;special checks
         CLC            ;if there was no match, default to enabling the
                        ;menu slot
C252DB:  PLX
         ROR $0001,X    ;2nd byte of current menu slot will have Bit 7 set
                        ;if the slot should be grayed out and unavailable.
                        ;iow, Carry = 1 -> grayed.  Carry = 0 -> enabled.
         INX
         INX
         INX            ;point to next slot in character's menu
         DEC $EE
         BNE C252A6     ;repeat process for all 4 menu slots
         PLP
         PLX
         RTS


;Data - commands that can potentially get grayed out on the menu in battle,
; or have a property like their aiming altered.)

C252E9: db $03    ;(Morph)
      : db $0B    ;(Runic)
      : db $07    ;(SwdTech)
      : db $0C    ;(Lore)
      : db $17    ;(X-Magic)
      : db $02    ;(Magic)
      : db $06    ;(Capture)
      : db $00    ;(Fight)


;Data - addresses of functions to check whether above command should be
; enabled, disabled, or otherwise modified on battle menu)

C252F1: dw C25326   ;(Morph)
      : dw C25322   ;(Runic)
      : dw C2531D   ;(SwdTech)
      : dw C25314   ;(Lore)
      : dw C25314   ;(X-Magic)
      : dw C25314   ;(Magic)
      : dw C25301   ;(Capture)
      : dw C25301   ;(Fight)


;For Capture and Fight menu slots

C25301:  LDA $3C58,Y    ;Check for offering
         LSR
         BCC C25313     ;Exit if no Offering
         REP #$21       ;Set 16-bit Accumulator.  Clear Carry to enable
                        ;menu slot.
         LDA $03,S
         TAX            ;get address of character's current menu slot
         SEP #$20       ;Set 8-bit Accumulator
         LDA #$4E
         STA $0002,X    ;update aiming byte: Cursor start on enemy,
                        ;Auto select one party, Auto select both parties
                        ;[in this case, that means you'll target both enemy
                        ;clumps in a Pincer], and One side only.
C25313:  RTS


;For Lore, X-Magic, and Magic menu slots

C25314:  LDA $3EE5,Y
         BIT #$08       ;is character Muted?
         BEQ C2531C     ;branch if not
         SEC            ;if they are, mark menu slot to be disabled?
C2531C:  RTS


;For SwdTech menu slot

C2531D:  LDA $EF
         LSR
         LSR            ;Carry = Bit 1, which was set in function C2/527D
         RTS            ;if it was set, menu slot will be disabled..
                        ;if it wasn't, slot is enabled


;For Runic menu slot

C25322:  LDA $EF
         ASL            ;Carry = Bit 7, which was set in function C2/527D
         RTS            ;if it was set, menu slot will be disabled..
                        ;if it wasn't, slot is enabled

;For Morph menu slot

C25326:  LDA #$0F
         CMP $1CF6      ;compare to Morph supply
         RTS            ;if Morph supply isn't at least 16, menu slot will
                        ;be disabled..  if it's >=16, slot is enabled


;Change character commands when wearing MagiTek armor or visiting Fanatics' Tower.
; Change commands based on relics, such as Fight becoming Jump, or Steal becoming Capture.
; Blank or retain certain commands, depending on whether they should be available -- e.g.
;   no known dances means no Dance command.)
;Zero character MP if they have no Lore command, no Magic/X-Magic with at least one spell
;   learned, and no Magic/X-Magic with an Esper equipped.)

C2532C:  PHX
         PHP
         REP #$30       ;Set 16-bit A, X, and Y
         LDY $3010,X    ;get offset to character info block
         LDA C2544A,X   ;get address of character's menu
         STA $002181    ;this means that future writes to $00218n in this function
                        ;will modify that character's menu?
         LDA $1616,Y    ;1st and 2nd menu slots
         STA $FC
         LDA $1618,Y    ;3rd and 4th menu slots
         STA $FE
         LDA $1614,Y    ;out of battle Status Bytes 1 and 2; correspond
                        ;to in-battle Status Bytes 1 and 4
         SEP #$30       ;Set 8-bit A, X, and Y
         BIT #$08       ;does character have MagiTek?
         BNE C25354     ;branch if so
         LDA $3EBB      ;Fanatics' Tower?  must verify this.
         LSR
         BCC C2539D     ;branch if neither MagiTek nor Fanatics' Tower
C25354:  LDA $3ED8,X    ;get character index
         XBA
         LDX #$03       ;point to 4th menu slot
C2535A:  LDA $FC,X      ;get command in menu slot
         CMP #$01
         BEQ C2539A     ;if Item, skip to next slot
         CMP #$12
         BEQ C2539A     ;if Mimic, skip to next slot
         XBA            ;retrieve character index
         CMP #$0B
         BNE C25371     ;branch if not Gau
         XBA            ;get command again
         CMP #$10
         BNE C25370     ;branch if not Rage
         LDA #$00       ;load Fight command into A so that Gau's Rage will get replaced
                        ;by MagiTek too.  why not just replace "BNE C25370 / LDA #$00"
                        ;with "BEQ formerly_$5376" ??  you got me..
C25370:  XBA
C25371:  XBA            ;once more, command is in bottom of A, character index in top
         CMP #$00       ;Fight?
         BNE C2537A     ;branch if not.  if it is Fight, we'll replace it with MagiTek
         LDA #$1D
         BRA C25380     ;go store MagiTek command in menu slot
C2537A:  CMP #$02
         BEQ C25380     ;if Magic, branch..  which just keeps Magic as command?
                        ;rewriting it seems inefficient, unless i'm missing
                        ;something.

         LDA #$FF       ;empty command
C25380:  STA $FC,X      ;update this menu slot
         LDA $3EBB      ;Fanatics' Tower?  must verify this.
         LSR
         BCC C2539A     ;branch if not in the tower
         LDA $FC,X      ;get menu slot again
         CMP #$02
         BEQ C25396     ;branch if Magic command, emptying slot.
         CMP #$1D       ;MagiTek?  actually, this is former Fight or Gau+Rage.
         BNE C25398     ;branch if not
         LDA #$02
         BRA C25398     ;save Magic as command
C25396:  LDA #$FF       ;empty command
C25398:  STA $FC,X      ;update menu slot
C2539A:  DEX
         BPL C2535A     ;loop for all 4 slots

C2539D:  TDC            ;clear 16-bit A
         STA $F8
         STA $002183    ;will write to Bank 7Eh in WRAM
         TAY            ;Y = 0

C253A5:  LDA $00FC,Y    ;get command from menu slot
         LDX #$04
         PHA            ;Put on stack
         LDA #$04
         STA $EE        ;start checking Bit 2 of variable $11D6
C253AF:  LDA C25452,X   ;commands that can be changed FROM
         CMP $01,S      ;is current command one of those commands?
         BNE C253C4     ;branch if not
         LDA $11D6      ;check Battle Effects 1 byte.
                        ;Bit 2 = Fight -> Jump, Bit 3 = Magic -> X-Magic,
                        ;Bit 4 = Sketch -> Control, Bit 5 = Slot -> GP Rain,
                        ;Bit 6 = Steal -> Capture
         BIT $EE
         BEQ C253C4
         LDA C25457,X   ;commands to change TO
         STA $01,S      ;replace command on stack
C253C4:  ASL $EE        ;will check the next highest bit of $11D6
                        ;in our next iteration
         DEX
         BPL C253AF     ;loop for all 5 possible commands that can be
                        ;converted

;This next loop sees if our current command is one that needs special code to assess
; its menu availability -- blanking it if unavailable -- or do some other tests.  If so,
; a special function is called for the command.)

         LDA $01,S      ;get current command
         LDX #$05
C253CD:  CMP C25468,X   ;is it one of the commands that can be blanked from menu
                        ;or have other miscellaneous crap done?
         BNE C253DB     ;branch if not
         TXA
         ASL
         TAX            ;X = X * 2
         JSR (C2545C,X) ;call special function for command
         BRA C253DE     ;we've gotten a match, so there's no need to
                        ;compare our current command against rest of list
C253DB:  DEX
         BPL C253CD     ;there are 6 possible commands that need
                        ;special checks
C253DE:  PLA            ;restore command #, which may've been nulled by our
;                                     C2545C special function)
         STA $002180    ;save command # in first menu byte
         STA $002180    ;save command # again in second menu byte..  all i know
                        ;about this byte is that the top bit will be set if the
                        ;menu option is unavailable [blank or gray]
         ASL
         TAX            ;X = command * 2, will let us index a command table
         TDC            ;clear 16-bit A
         BCS C253F0     ;branch if command # was negative.  this will put
                        ;zero into the menu aiming
         LDA $CFFE01,X  ;get command's aiming
C253F0:  STA $002180    ;store it in a third menu byte
         INY
         CPY #$04       ;loop for all 4 menu slots
         BNE C253A5
         LSR $F8        ;Carry gets set if character has Magic/X-Magic command
                        ;and at least one spell known, Magic/X-Magic and an
                        ;Esper equipped, or if they simply have Lore.
         BCS C25408
         LDA $02,S      ;retrieve the X value originally passed to the function.
                        ;iow, the index of the party member whose menu is being
                        ;examined
         TAX
         REP #$20       ;Set 16-bit A
         STZ $3C08,X    ;zero MP
         STZ $3C30,X    ;zero max MP
C25408:  PLP
         PLX
         RTS


;Morph menu entry

C2540B:  LDA #$04
         BIT $3EBC      ;set after retrieving Terra from Zozo -- allows
                        ;Morph command
         BEQ C25434     ;if not set, go null out command
         BIT $3EBB      ;set only for Phunbaba battle #4 [i.e. Terra's second
                        ;Phunbaba encounter]
         BEQ C25438     ;if not Phunbaba, just keep command enabled
         LDA $05,S      ;get the X value originally passed to function C2/532C.
                        ;iow, the index of the party member whose menu is being
                        ;examined
         TAX
         LDA $3DE9,X
         ORA #$08
         STA $3DE9,X    ;Cause attack to set Morph
         LDA #$FF
         STA $1CF6      ;set Morph supply to maximum
         BRA C25434     ;by nulling Morph command in menu, we'll stop Terra from
                        ;Morphing again and from Reverting?


;Magic and X-Magic menu entry

;Blank out Magic/X-Magic menu if no spells are known and no Esper is equipped

C25429:  LDA $F6        ;# of spells learnt
         BNE C25445     ;if some are, branch and set a flag
         LDA $F7        ;index of Esper equipped.  this value starts with 0
                        ;for Ramuh, and the order matches the Espers' order in
                        ;the spell list.  FFh means nothing's equipped
         INC
         BNE C25445     ;branch if an Esper equipped
C25432:  BNE C25438     ;Dance and Leap jump here.  obviously, this branch
                        ;is never taken if we called this function for Magic
                        ;or X-Magic.
C25434:  LDA #$FF
         STA $03,S      ;replace current command with empty
C25438:  RTS


;Dance menu entry

C25439:  LDA $1D4C      ;bitfield of known Dances
         BRA C25432     ;if none are, menu entry will be nulled after branch


;Leap menu entry

C2543E:  LDA $11E4
         BIT #$02       ;is Leap available?
         BRA C25432     ;if it's not, menu entry will be nulled after branch


;Lore menu entry

C25445:  LDA #$01
         TSB $F8        ;this will stop character's Current MP and Max MP from
                        ;getting zeroed in calling function.  Lore always does
                        ;this, whereas Magic and X-Magic have conditions..
                        ;Also note that Lore never checks whether the menu command
                        ;should be available, as Strago knows 3 Lores at startup
         RTS


;Data - addressed by index of character onscreen -- 0, 2, 4, or 6
;Points to each of their menus, which are 4 entries, 3 bytes per entry.)
C2544A: dw $202E
      : dw $203A
      : dw $2046
      : dw $2052


;Data - commands that can be replaced with other commands thanks to Relics

C25452: db $05   ;(Steal)
      : db $0F   ;(Slot)
      : db $0D   ;(Sketch)
      : db $02   ;(Magic)
      : db $00   ;(Fight)


;Data - commands that can replace above commands due to Relics

C25457: db $06   ;(Capture)
      : db $18   ;(GP Rain)
      : db $0E   ;(Control)
      : db $17   ;(X-Magic)
      : db $16   ;(Jump)


;Pointers - functions to remove commands from in-battle menu, or to make
; miscellaneous adjustments)

C2545C: dw C2540B   ;(Morph)
      : dw C2543E   ;(Leap)
      : dw C25439   ;(Dance)
      : dw C25429   ;(Magic)
      : dw C25429   ;(X-Magic)
      : dw C25445   ;(Lore)


;Data - commands that can be removed from menu in some circumstances, or otherwise
; need special functions.)

C25468: db $03   ;(Morph)
      : db $11   ;(Leap)
      : db $13   ;(Dance)
      : db $02   ;(Magic)
      : db $17   ;(X-Magic)
      : db $0C   ;(Lore)


;Construct in-battle Item menu, equipment sub-menus, and possessed Tools bitfield,
; based off of equipped and possessed items.)

C2546E:  PHP
         REP #$30     ;Set 16-bit Accumulator, 16-bit X and Y
         LDY #$2BAD   ;start pointing to the last byte of the 2nd
                       ; equipment menu hand slot of the 4th character.
                       ; C2/54CD uses MVN, so we'll be counting
                       ; backwards until reaching $2686, the first Item
                       ; menu slot.
         LDA #$0001
         STA $2E75
         LDX #$0006
C2547D:  PHY
         LDY $3010,X  ;get offset to character info block
         LDA $1620,Y  ;get 2nd Arm equipment
         PLY
         JSR C254CD   ;Copy info of item held in A to a 5-byte buffer,
                       ; spanning $2E72 - $2E76.  Then copy buffer to
                       ; our current menu position.
         DEX
         DEX
         BPL C2547D   ;iterate for all 4 characters
         LDX #$0006
C2548F:  PHY
         LDY $3010,X  ;get offset to character info block
         LDA $161F,Y  ;get 1st Arm equipment
         PLY
         JSR C254CD   ;Copy info of item held in A to a 5-byte buffer,
                       ; spanning $2E72 - $2E76.  Then copy buffer to
                       ; our current menu position.
         DEX
         DEX
         BPL C2548F   ;iterate for all 4 characters
         LDX #$00FF
C254A1:  LDA $1969,X  ;get item quantity
         STA $2E75
         LDA $1869,X  ;get item
         JSR C254CD   ;Copy info of item held in A to a 5-byte buffer,
                       ; spanning $2E72 - $2E76.  Then copy buffer to
                       ; our current menu position.
         DEX
         BPL C254A1   ;loop for all 256 items
         SEP #$30     ;Set 8-bit Accumulator, 8-bit X and Y
         TDC
         TAY
C254B4:  LDA $1869,Y  ;get item in first slot
         CMP #$A3
         BCC C254C8   ;if it's < 163 [NoiseBlaster], branch
         SBC #$A3     ;get a Tool index, where NoiseBlaster = 0, etc
         CMP #$08
         BCS C254C8   ;if it's >= 171 [iow, not a tool], branch
         TAX
         JSR C21E57   ;Sets bit #X in A
         TSB $3A9B    ;Set bit N for Tool N
C254C8:  INY
         BNE C254B4   ;loop for all 256 item slots
         PLP
         RTS


;Copy info of item held in A to a 5-byte buffer, spanning $2E72 - $2E76.  Then
; copy buffer to a range whose end address is indicated by Y.)

C254CD:  PHX
         JSR C254DC
         LDX #$2E76
         LDA #$0004
         MVP $7E7E
         PLX
         RTS


;Copy info of item held in A to a 5-byte buffer, spanning $2E72 - $2E76.
; Callers set $2E75 quantity themselves.)

C254DC:  PHX
         PHP
         REP #$10       ;Set 16-bit X and Y
         SEP #$20       ;set 8-bit Accumulator
         PHA            ;Put on stack
         LDA #$80
         STA $2E73      ;assume item is unusable/unselectable (?) in battle
         LDA #$FF
         STA $2E76      ;assume item can't be equipped by any onscreen characters
         PLA
         STA $2E72      ;save the Item #
         CMP #$FF       ;is it item #255, aka Empty?
         BEQ C25546     ;if so, Exit function
         XBA
         LDA #$1E
         JSR C24781     ;Multiply by 30, size of item block
                        ;JSR C22B63?
         TAX
         LDA $D8500E,X  ;Get Item targeting
         STA $2E74
         LDA $D85000,X  ;Get Item type
;	 			(	            Item Type:
;				00: Tool       04: Hat    |   10: Can be thrown
;				01: Weapon     05: Relic  |   20: Usable as an item in battle
;				02: Armor      06: Item   |   40: Usable on the field (Items only)
;				03: Shield  )

         PHA            ;Put on stack
         PHA            ;Put on stack
         ASL
         ASL            ;item type * 4
         AND #$80       ;isolate whether Usable as item in battle
         TRB $2E73      ;clear corresponding bit
         PLA            ;get unshifted item type
         ASL
         AND #$20       ;isolate can be thrown
         TSB $2E73      ;set corresponding bit
         TDC
         PLA            ;get unshifted item type
         AND #$07       ;isolate classification
         PHX
         TAX
         LDA C25549,X   ;get a value indexed by item type
         PLX
         ASL            ;multiply by 2
         TSB $2E73      ;turn on corresponding bits
         BCS C25546     ;if top bit was set, branch to end of function.
                        ;only Weapon, Shield and Item classifications have
                        ;it unset.
                        ;maybe this controls whether an Item is selectable
                        ;under a given character's Item menu?

;!? why should items of Classification Item ever reach here?!

         REP #$21       ;Set 16-bit Accumulator, clear carry
         STZ $EE
         LDA $D85001,X  ;Get Item's equippable characters
         LDX #$0006
C25533:  BIT $3A20,X    ;$3A20,X has bit Z set, where Z is the actual Character #
                        ;of the current onscreen character indexed by X.  don't
                        ;think $3A20 is defined for characters >= 0Eh
         BNE C25539     ;branch if character can equip the item
         SEC            ;the current onscreen character can't equip the item
C25539:  ROL $EE
         DEX
         DEX
         BPL C25533     ;loop for all 4 onscreen characters
         SEP #$20       ;Set 8-bit Accumulator
         LDA $EE
         STA $2E76      ;so $2E76 should look like:
                        ;Bit 0 = 1, if onscreen character 0 can't equip item
                        ;Bit 1 = 1, if onscreen character 1 can't equip item
                        ;Bit 2 = 1, if onscreen character 2 can't equip item
                        ;Bit 3 = 1, if onscreen character 3 can't equip item
C25546:  PLP
         PLX
         RTS


;Data
C25549: db $A0 ;(Tool)
      : db $08 ;(Weapon)
      : db $80 ;(Armor)
      : db $04 ;(Shield)
      : db $80 ;(Hat)
      : db $80 ;(Relic)
      : db $00 ;(Item)
      : db $00 ;(extra?)


;Generate Lore menus based on known Lores, and generate Magic menus based on spells
; known by ANY character.  C2/568D will eliminate unknown spells and modify costs as
; needed, on a per character basis.)

C25551:  PHP
         LDX #$1A
C25554:  STZ $30BA,X    ;set "position of spell" for every Esper to 0,
                        ;because the 1-entry Esper menu is always at
                        ;Position 0, just before the Magic menu.
         DEX
         BPL C25554     ;iterate for all 27 Espers
         LDA #$FF
         LDX #$35
C2555E:  STA $11A0,X    ;null out a temporary list
         DEX
         BPL C2555E     ;which has 54 entries
         LDY #$17       ;there are 24 possible known Lores
         LDX #$02
         TDC
         SEC
C2556A:  ROR
         BCC C2556F     ;have we looped a multiple of 8 times yet?
         ROR
         DEX            ;if we're on our 9th/17th, set Bit 7 and repeat
                        ;the process again.
C2556F:  BIT $1D29,X    ;is current Lore known?
         BEQ C25584     ;branch if not
         INC $3A87      ;increment number of known Lores
         PHA            ;Put on stack
         TYA            ;A = Lore ID
         ADC #$37       ;turn it into a position relative to Esper menu,
                        ;which immediately precedes the Magic menu.
         STA $310F,Y    ;save to "list of positions of each lore"
         ADC #$54       ;so now we've converted our 0-23 Lore ID into a
                        ;raw spell ID, as Condemned [8Bh] is the first
                        ;Lore.
         STA $306A,Y    ;save spell ID to "list of known Lores"
         PLA
C25584:  DEY
         BPL C2556A     ;iterate 24 times, going through the Lores in
                        ;reverse order
         LDX #$06
C25589:  LDA $3ED8,X    ;get current character
         CMP #$0C
         BCS C255AE     ;branch if it's Gogo or Umaro or temporary
                        ;chars
         XBA
         LDA #$36
         JSR C24781     ;16-bit A = 54 * character ID
         REP #$21
         ADC #$1A6E
         STA $F0        ;save address to list of spells this character
                        ;knows and doesn't know
         SEP #$20
         LDY #$35
C255A1:  LDA ($F0),Y    ;what % of spell is known
         CMP #$FF       ;does this character know the current spell?
         BNE C255AB     ;branch if not
         TYA
         STA $3034,Y    ;if they do, set this entry in our "spells known
                        ;by any character" list to the spell ID
C255AB:  DEY            ;go to next spell
         BPL C255A1     ;loop 54 times, through this list of character's
                        ;known/unknown spells
C255AE:  DEX
         DEX
         BPL C25589     ;loop for all 4 characters in party
         LDA $1D54      ;info from Config screen
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
         AND #$07       ;isolate Magic Order
         TAX
         LDY #$35
C255BA:  LDA $3034,Y    ;get spell #
         CMP #$18       ;compare to 24.  if it's 0-23, it's Attack
                        ;magic [Black].
         BCS C255C7     ;branch if it's 24 or higher
         ADC C2574B,X   ;add spell # to amount to adjust Attack
                        ;spells positioning based on current
                        ;Magic Order
         BRA C255D9
C255C7:  CMP #$2D       ;compare to 45.  if it's 24-44, it's Effect
                        ;magic [Gray].
         BCS C255D1     ;branch if it's 45 or higher
         ADC C25751,X   ;add spell # to amount to adjust Effect
                        ;spells positioning based on current
                        ;Magic Order
         BRA C255D9
C255D1:  CMP #$36       ;compare to 54.  if it's 45-53, it's Healing
                        ;magic [White].
         BCS C255E0     ;branch if it's 54 or higher, which apparently
                        ;means it's not a Magic spell at all.
         ADC C25757,X   ;add spell # to amount to adjust Healing
                        ;spells positioning based on current
                        ;Magic Order
C255D9:  PHX            ;preserve Magic Order value
         TAX            ;X = position of spell in menu
         TYA            ;A = spell ID
         STA $11A0,X    ;save to our new, reordered list of "spells
                        ;known by any character"
         PLX            ;get Magic Order
C255E0:  DEY
         BPL C255BA     ;loop for all 54 spell positions
         LDA #$FF
         LDX #$35
C255E7:  STA $3034,X
         DEX
         BPL C255E7     ;null out the Magic portion of our other temporary list
         TDC
         TAX
         TAY
C255F0:  LDA $11A0,X
         INC
         BNE C25602
         LDA $11A1,X
         INC
         BNE C25602
         LDA $11A2,X
         INC
         BEQ C25617     ;if these three consecutive entries in spell list were
                        ;all null, skip copying all three to other list.  but
                        ;if any have a spell, then copy all three.  this was
                        ;designed to skip one row at a time in FF6j so a given
                        ;spell would always stay in the same column, but the
                        ;list was changed to 2 columns in FF3us without this
                        ;code being adjusted, so the list winds up hard to
                        ;follow.
C25602:  LDA $11A0,X
         STA $3034,Y    ;copy 1st spell ID from one list to another
         LDA $11A1,X
         STA $3035,Y    ;copy 2nd spell ID from one list to another
         LDA $11A2,X
         STA $3036,Y    ;copy 3rd spell ID from one list to another
         INY
         INY
         INY
C25617:  INX
         INX
         INX
         CPX #$36
         BCC C255F0     ;iterate 18 times, or cover 54 spell entries
         LDX #$35
C25620:  LDA $3034,X    ;get entry from our reordered, condensed list
                        ;of "spells known by any character"
         CMP #$FF
         BEQ C2562D     ;branch if null
         TAY            ;Y = spell ID
         TXA            ;A = position in list
         INC            ;now make it 1-based, because position 0 will
                        ;correspond to an equipped Esper.
         STA $3084,Y    ;save to "list of positions of each spell"
C2562D:  DEX
         BPL C25620     ;iterate 54 times
         REP #$10
         LDX #$004D     ;77.  78 = 54 Magic spells + 24 Lores.
C25635:  TDC
         LDA $3034,X    ;get spell ID
         CMP #$FF
         BEQ C25688     ;branch to next slot if null
         PHA            ;save spell ID
         TAY
         LDA $3084,Y    ;get position of spell relative to Esper menu
         REP #$20
         ASL
         ASL            ;there's 4 bytes per spell entry
         SEP #$20
         TAY            ;offset relative to Esper menu
         LDA $01,S      ;get spell ID
         CMP #$8B       ;are we at least at Condemned, the first lore?
         BCC C25651     ;branch if not
         SBC #$8B       ;if we are, turn it into a 0-23 Lore ID, rather
                        ;than a raw spell ID
C25651:  STA $208E,Y    ;output spell or Lore ID to 1st character's menu,
                        ;Byte 1 of 4 for this slot
         STA $21CA,Y    ;' ' 2nd character's menu
         STA $2306,Y    ;' ' 3rd character's menu
         STA $2442,Y    ;' ' 4th character's menu
         PLA            ;get spell ID
         JSR C25723     ;from spell data, put aiming byte in bottom half
                        ;of A, and MP cost in top half
         STA $2090,Y    ;save aiming byte in 1st character's menu, Byte
                        ;3 of 4 for this slot
         STA $21CC,Y    ;' ' 2nd character's menu
         STA $2308,Y    ;' ' 3rd character's menu
         STA $2444,Y    ;' ' 4th character's menu
         XBA            ;get MP cost
         CPX #$0044     ;are we pointing at Step Mine's menu slot?
         BNE C2567C     ;branch if not
         LDA $1864      ;minutes portion of time played, from when main
                        ;menu was last visited.  or seconds remaining,
                        ;if we're in a timed area.
         CMP #$1E       ;set Carry if >=30 minutes
         LDA $1863      ;hours portion of time played, from when main
                        ;menu was last visited.  or minutes remaining,
                        ;if we're in a timed area.
         ROL            ;MP Cost = [hours * 2] + [minutes DIV 30] or
                        ;unintended [minutes remaining * 2] +
                        ;[seconds remaining DIV 30]
C2567C:  STA $2091,Y    ;save MP cost in 1st character's menu, Byte
                        ;4 of 4 for this slot
         STA $21CD,Y    ;' ' 2nd character's menu
         STA $2309,Y    ;' ' 3rd character's menu
         STA $2445,Y    ;' ' 4th character's menu
C25688:  DEX
         BPL C25635     ;iterate 78 times, for all Magic and Lore menu
                        ;slots
         PLP
         RTS


;Generate a character's Esper menu, blank out unknown spells from their Magic menu,
; and adjust spell and Lore MP costs based on equipped Relics.)

C2568D:  PHX
         PHP
         REP #$10
         LDA $3C45,X
         STA $F8        ;copy "Relic Effects 2" byte
         STZ $F6        ;start off assuming known Magic spell quantity of 0
         LDY $302C,X
         STY $F2        ;copy starting address of character's Magic menu
                        ;[Esper menu, to be precise]
         INY
         INY
         INY
         STY $F4        ;save address of MP cost of first spell
         LDY $3010,X    ;get offset to character info block
         LDA $161E,Y    ;get equipped Esper
         STA $F7        ;save it
         BMI C256C7
         STA $3344,X    ;if it's not null, save it again
         LDY $F2
         STA $0000,Y    ;store Esper ID in Esper menu, which is the first
                        ;slot before the Magic menu and then the Lore menu
         CLC
         ADC #$36       ;convert it to a raw spell ID
         JSR C25723     ;put spell aiming byte in bottom half of A,
                        ;MP cost in top
         STA $0002,Y    ;save aiming byte in menu data
         STA $3345,X
         XBA            ;get spell MP cost
         JSR C25736     ;change it if Gold Hairpin or Economizer equipped
         STA $0003,Y    ;save updated MP cost
C256C7:  TDC
         TAY            ;A = 0, Y = 0
         LDA $3ED8,X
         CMP #$0C
         BEQ C256E5     ;branch if the character is Gogo
         INY
         INY            ;Y = 2
         BCS C256E5     ;branch if Umaro or a temporary character
         INY
         INY            ;Y = 4
         XBA
         LDA #$36
         JSR C24781     ;16-bit A = character # * 54
         REP #$21       ;Set 16-bit A, clear Carry
         ADC #$1A6E     ;gives address of list of spells known/unknown by this
                        ;character
         STA $F0
         SEP #$20       ;Set 8-bit A
C256E5:  TYX
         LDY #$0138     ;we can loop through 78 spell menu entries [each taking
                        ;4 bytes].  54 Magic spells + 24 Lores = 78
C256E9:  TDC
         LDA ($F2),Y    ;get spell #
         CMP #$FF
         BEQ C2570E     ;branch if no spell available in this menu slot
         CPY #$00DC     ;are we pointing to the first slot on the Lore menu
                        ;[our 55th slot overall]?
         JMP (C2575D,X) ;jump out of the loop..  but the other places can actually
                        ;jump back into it.  Square is crazy like that. :P
C256F6:  DEY
         DEY
         DEY
         DEY
         BNE C256E9     ;point to next menu slot, and loop
         PLP
         PLX
         LDA $F6
         STA $3CF8,X    ;save number of Magic spells possessed by this character
         RTS

C25704:  BCS C25716     ;branch if we're pointing to a Lore slot.  otherwise,
                        ;we're pointing to a Magic spell slot.
         PHY
         TAY
         LDA ($F0),Y    ;whether this character knows this spell.  FFh = yes
         PLY
         INC
         BEQ C25716     ;branch if they do

C2570E:  TDC
         STA ($F4),Y    ;save 0 as MP cost
         DEC
         STA ($F2),Y    ;save FFh [null] as spell #
         BRA C256F6     ;reenter our 78-slot loop

C25716:  BCS C2571A     ;branch if we're pointing to a Lore slot.  otherwise,
                        ;we're pointing to a Magic spell slot.
         INC $F6        ;increment # of known Magic spells
C2571A:  LDA ($F4),Y    ;get spell's MP cost from menu
         JSR C25736     ;change it if Gold Hairpin or Economizer equipped
         STA ($F4),Y    ;save updated MP cost
         BRA C256F6     ;reenter our 78-slot loop


;From spell data, put MP cost in top of A, and aiming byte in bottom of A

C25723:  PHX
         XBA
         LDA #$0E
         JSR C24781     ;spell # * 14
         TAX
         LDA $C46AC5,X  ;read MP cost from spell data
         XBA
         LDA $C46AC0,X  ;read aiming byte from spell data
         PLX
         RTS


;Adjust MP cost for Gold Hairpin and/or Economizer.  Obviously, the latter supercedes
; the former.)

C25736:  XBA            ;put MP cost in top of A
         LDA $F8        ;read our copy of "Relic Effects 2" byte
         BIT #$20
         BEQ C25741     ;branch if no Gold Hairpin
         XBA            ;get MP cost
         INC
         LSR            ;MP cost = [MP cost + 1] / 2
         XBA            ;look at relics byte again
C25741:  BIT #$40
         BEQ C25749     ;branch if no Economizer
         XBA
         LDA #$01       ;MP cost = 1
         XBA
C25749:  XBA            ;return MP cost in bottom of A
         RTS


;Data - amount to shift menu position of certain Magic spells,
; depending on the "Magic Order" chosen in Config menu.
; These values are signed, so anything 80h and above means to
; subtract, i.e. move the spell backwards.)

;For Spells 0 - 23 : Attack, Black
C2574B: db $09  ;(Healing, Attack, Effect (HAE))
      : db $1E  ;(Healing, Effect, Attack (HEA))
      : db $00  ;(Attack, Effect, Healing (AEH))
      : db $00  ;(Attack, Healing, Effect (AHE))
      : db $1E  ;(Effect, Healing, Attack (EHA))
      : db $15  ;(Effect, Attack, Healing (EAH))

;For Spells 24 - 44 : Effect, Gray
C25751: db $09  ;(Healing, Attack, Effect (HAE))
      : db $F1  ;(Healing, Effect, Attack (HEA))
      : db $00  ;(Attack, Effect, Healing (AEH))
      : db $09  ;(Attack, Healing, Effect (AHE))
      : db $E8  ;(Effect, Healing, Attack (EHA))
      : db $E8  ;(Effect, Attack, Healing (EAH))

;For Spells 45 - 53 : White, Healing
C25757: db $D3  ;(Healing, Attack, Effect (HAE))
      : db $D3  ;(Healing, Effect, Attack (HEA))
      : db $00  ;(Attack, Effect, Healing (AEH))
      : db $EB  ;(Attack, Healing, Effect (AHE))
      : db $E8  ;(Effect, Healing, Attack (EHA))
      : db $00  ;(Effect, Attack, Healing (EAH))


;Pointer table

C2575D: dw C25716   ;(Gogo)
      : dw C2570E   ;(Umaro or temporary character)
      : dw C25704   ;(normal character, ID 00h - 0Bh)


;Make entries on Esper, Magic, and Lore menus available and lit up or unavailable
; and grayed, depending on whether: the spell is learned [or for the Esper menu,
; an Esper is equipped], the character has enough MP to cast the spell, the
; character is an Imp trying to cast a spell other than Imp)

C25763:  CPX #$08
         BCS C257A9     ;Exit function if monster
         PHX
         PHY
         PHP
         LDA $3C09,X    ;MP, top byte
         BNE C25775     ;branch if MP >= 256
         LDA $3C08,X    ;MP, bottom byte
         INC
         BNE C25777     ;if MP < 255, branch and save MP cost
                        ;as character MP + 1
C25775:  LDA #$FF       ;otherwise, set it to 255
C25777:  STA $3A4C      ;save Caster MP + 1.  capped at 255
         LDA $3EE4,X    ;Status byte 1
         ASL
         ASL
         STA $EF        ;Imp is saved in Bit 7
         REP #$10       ;16-bit X and Y registers
         LDA $3018,X    ;Holds $01 for character 1, $02 for character 2,
                        ;$04 for character 3, $08 for character 4
         LDY $302C,X    ;get starting address of character's Magic menu?
         TYX
         SEC
         BIT $3F2E      ;bit is set for characters who don't have Espers
                        ;equipped, or have already used Esper this battle
         BNE C25793     ;if no Esper equipped or already used, branch with
                        ;Carry Set
         JSR C257AA     ;Set Carry if spell's unavailable due to Impage or
                        ;insufficient MP.  Clear Carry otherwise.
C25793:  ROR $0001,X    ;put Carry into bit 7 of 2nd byte of menu data.
                        ;if set, it makes spell unavailable on menu.
         LDY #$004D
C25799:  INX
         INX
         INX
         INX            ;point to next spell in menu
         JSR C257AA     ;Set Carry if spell's unavailable due to absence,
                        ;Impage, or insufficient MP.  Clear Carry otherwise.
         ROR $0001,X    ;put Carry into bit 7 of 2nd byte of menu data.
                        ;if set, it makes spell unavailable on menu.
         DEY
         BPL C25799     ;iterate 78 times: spells plus 24 lores
         PLP
         PLY
         PLX
C257A9:  RTS


;Set Carry if spell should be disabled due to unavailability, or because
; caster is an Imp and the spell isn't Imp.  If none of these factors
; disable the spell, check the MP cost.)

C257AA:  LDA $0000,X    ;get spell # from menu
         BMI C257B9     ;branch if undefined
         XBA
         LDA $EF
         BPL C257BB     ;branch if character not an Imp
         XBA
         CMP #$23
         BEQ C257BB     ;branch if spell is Imp
C257B9:  SEC            ;spell will be unavailable
         RTS


;Set Carry if caster lacks MP to cast spell.
; Clear it if they have sufficient MP.)

C257BB:  LDA $0003,X    ;get spell's MP cost from menu data
         CMP $3A4C      ;compare to Caster MP + 1, capped at 255
         RTS


;Copies targets in $B8-$B9 to $A2-$A3 and $A4-$A5.
; Sets up attack animation, including making all jump but the last in a Dragon Horn
; sequence send the attacker airborne again.  Sets up "Attacking Opposition" bit.
; Randomizes targets for all jumps but the first with Dragon Horn.)

C257C2:  PHP
         SEP #$30       ;set 8-bit A, X, Y
         STZ $A0
         TXA            ;get attacker index
         LSR            ;divide by 2.  now we have 0, 1, 2, and 3 for characters,
                        ;and 4, 5, 6, 7, 8, 9 for monsters
         STA $A1        ;save attacker for animation purposes
         CMP #$04
         BCC C257D1     ;branch if character is attacker
         ROR $A0        ;Bit 7 is set if monster attacker
C257D1:  LDA $B9        ;get monster targets
         STA $A3
         STA $A5
         LDA $B8        ;get character targets
         STA $A2
         STA $A4
         BNE C257E3     ;branch if there are character targets
         LDA #$40
         TSB $A0        ;Bit 6 set if there are no character targets
C257E3:  LDA $A0
         ASL
         BCC C257EA     ;branch if not monster attacker
         EOR #$80       ;flip "no character targets" bit
                        ;last two instructions can be replaced by "EOR $A0"
C257EA:  BPL C257F0     ;next two lines are only executed if:
                        ;- character attacker and no character (i.e. just monster
                        ;  targets
                        ;OR  - monster attacker and character targets
         LDA #$02
         TSB $BA        ;Set "attacking opposition" bit.  Used for criticals
                        ;and reflections.
C257F0:  LDA #$10
         TRB $B0        ;clear bit 4, which is set at beginning of turn.
         BNE C257F8     ;branch if wasn't already clear
         TSB $A0        ;if it was, set Bit 4 in another variable.  it apparently
                        ;prevents characters from stepping forward and getting
                        ;circular or triangular pattern around them when casting
                        ;Magic or Lores, an action we don't want to happen more than
                        ;once per turn.
C257F8:  LDA $3A70      ;# of strikes left for Dragon Horn / Offering / Quadra Slam
         BEQ C2580A     ;if no more after the current one, exit
         LDA $3A8E      ;set to FFh by Dragon Horn's "jump continuously" attribute
                        ;should be zero otherwise
         BEQ C2580A     ;exit if zero
         LDA #$02
         TSB $A0        ;animation to send jumper bouncing skyward again
         LDA #$60
         TSB $BA        ;set Can Beat on Corpses if no Valid Targets Left and
                        ;Randomize Target.  the latter explains why all jumps
                        ;after the first one are random.  these two properties
                        ;will be applied to the *next* strike.
C2580A:  PLP
         RTS


;Construct Dance and Rage menus, and get number of known Blitzes and highest known
; SwdTech index)

C2580C:  TDC            ;16-bit A = 0
         LDA $1CF7      ;Known SwdTechs
         JSR C2520E     ;X = # of known SwdTechs
         DEX
         STX $2020      ;index of the highest SwdTech acquired.  useful
                        ;to represent it this way because SwdTechs are
                        ;on a continuum.
         TDC
         LDA $1D28      ;Known Blitzes
         JSR C2520E     ;X = # of known Blitzes
         STX $3A80
         LDA $1D4C      ;Known Dances
         STA $EE
         LDX #$07       ;start looking at 8th dance
C25828:  ASL $EE        ;Carry will be set if current dance is known
         LDA #$FF       ;default to storing null in Dance menu?
         BCC C2582F     ;branch if dance unknown
         TXA            ;if current dance is known, store its number
                        ;in the menu instead.
C2582F:  STA $267E,X
         DEX
         BPL C25828     ;loop for all 8 Dances
         REP #$20       ;Set 16-bit Accumulator
         LDA #$257E
         STA $002181    ;save Offset to write to in WRAM
         SEP #$20       ;Set 8-bit Accumulator
         TDC
         TAY
         TAX            ;Clear A, Y, X
         STA $002183    ;will write to Bank 7Eh in WRAM
C25847:  BIT #$07
         BNE C25853     ;if none of bottom 3 bits set, we're on enemy #
                        ;0, 8, 16, etc.  in which case we need to read a new
                        ;rage byte
         PHA            ;Put on stack
         LDA $1D2C,X    ;load current rage byte - 32 bytes total, 8 rages
                        ;per byte
         STA $EE
         INX            ;point to next rage byte
         PLA
C25853:  LSR $EE        ;get bottom bit of current rage byte
         BCC C2585E     ;if bit wasn't set, rage wasn't found, so don't
                        ;display it
         INC $3A9A      ;# of rages possessed.  used to randomly pick a rage
                        ;in situations like Muddle
         STA $002180    ;store rage in menu
C2585E:  INC            ;advance to next enemy #
         CMP #$FF
         BNE C25847     ;loop for all eligible enemies, 0 to 254.  we don't loop
                        ;a 256th time for Pugs, which is inaccessible regardless,
                        ;because that would overflow our $3A9A counter
         RTS


;Checks for statuses
;Doesn't set carry if any are set
;Carry clear = one or more set
;Carry set = none set

C25864:  REP #$21       ;Set 16-bit Accumulator, clear Carry
         LDA $3EE4,Y    ;Target status byte 1 & 2
         AND $05,S
         BNE C25875
         LDA $3EF8,Y    ;Target status byte 3 & 4
         AND $03,S
         BNE C25875
         SEC
C25875:  LDA $01,S
         STA $05,S
         PLA
         PLA
         SEP #$20       ;Set 8-bit Accumulator
         RTS


;Big ass targeting function.  It's not used to choose targets with the cursor, but
; it can choose targets randomly (for all sorts of reasons), or refine ones previously
; chosen [e.g. with the cursor].  This routine's so important, it uses several
; helper functions.)

C2587E:  PHX
         PHY
         PHP
         SEP #$30       ;set 8-bit A, X and Y
         LDA $BB        ;targeting byte
         CMP #$02       ;does the aiming consist of JUST "one side only?"
                        ;if so, that means we can't do spread-aim, start the
                        ;cursor on the enemy, or move it

         BNE C25895     ;if not, branch
         LDA $3018,X
         STA $B8
         LDA $3019,X
         STA $B9        ;save attacker as lone target
         BRA C258F6     ;then exit function
C25895:  JSR C258FA
         LDA $BA
         BIT #$40
         BNE C258B9     ;Branch if randomize targets
         BIT #$08
         BNE C258A5     ;Branch if Can target dead/hidden entities
         JSR C25A4D     ;Remove dead and hidden targets
C258A5:  LDA $B8
         ORA $B9
         BEQ C258B3     ;Branch if no targets
         LDA $BB        ;targeting byte
         BIT #$2C       ;is "manual party select", "autoselect one party", or
                        ;"autoselect both parties" set?  in other words,
                        ;we're checking to see if the spell can be spread
         BEQ C258ED     ;if not, branch
         BRA C258F6     ;if so, exit function

;                          (So if there were multiple targets and the targeting byte
;                           allows that, keep our multiple targets.  If there were
;                           somehow multiple targets despite the targeting byte
;                           [I can't think of a cause for this], just choose a
;                           random one at $58ED.  If there was only a single target,
;                           the branch to either $58ED or $58F6 will retain it.)

C258B3:  LDA $BA
         BIT #$04       ;Don't retarget if target dead/invalid?
         BNE C258C8     ;if we don't retarget, branch
C258B9:  JSR C25937     ;Randomize Targets jumps here
         JSR C258FA
         LDA $BA
         BIT #$08
         BNE C258C8     ;Branch if can target dead/hidden entities
         JSR C25A4D     ;Remove dead and hidden targets
C258C8:  JSR C259AC     ;refine targets for reflection [sometimes], OR based
                        ;on encounter formation
         LDA $BA
         BIT #$20
         BEQ C258DE     ;branch if attack doesn't allow us to beat on corpses
         REP #$20       ;Set 16-bit Accumulator
         LDA $B8
         BNE C258DC     ;branch if there are some targets set
         LDA $3A4E
         STA $B8        ;if there are no targets left, copy them from a
                        ;"backup already-hit targets" word.  this will let
                        ;Offering and Genji Glove and friends beat on corpses
                        ;once all targets have been killed during the
                        ;attacker's turn.
C258DC:  SEP #$20       ;Set 8-bit Accumulator

;note: if we're at this point, we never did the BIT #$2C target byte check above..
; and we've most likely retargeted thanks to "Randomize targets", or to there being
; no valid targets initially selected)

C258DE:  LDA $BB        ;targeting byte
         BIT #$0C       ;is "autoselect one party" or "autoselect both parties" set?
                        ;in another words, we're checking for some auto-spread aim
         BNE C258F6     ;if so, exit function
         BIT #$20       ;is "manual party select" set?  i.e. can the spell be spread
                        ;via L/R button?
         BEQ C258ED     ;if not, branch
         JSR C24B53     ;if so, do random coinflip
         BCS C258F6     ;50% of the time, we'll pretend it was spread, so exit
                        ;50% of the time, we'll pretend it kept one target
C258ED:  REP #$20       ;Set 16-bit Accumulator
         LDA $B8
         JSR C2522A     ;Randomly picks a bit set in A
         STA $B8        ;so we pick one random target
C258F6:  PLP
         PLY
         PLX
         RTS


C258FA:  PHP
         LDA #$02
         TRB $3A46      ;clear flag
         BNE C25915     ;if it was set [as is the case with the Joker
                        ;Dooms and the Tentacles' Seize drain], branch
                        ;and don't remove any targets
         JSR C25917
         LDA $BA
         BPL C2590B     ;branch if not abort on characters
         STZ $B8        ;clear character targets
C2590B:  LSR
         BCC C25915     ;branch if not "Exclude Attacker from targets"
         REP #$20       ;set 16-bit accumulator
         LDA $3018,X
         TRB $B8        ;clear caster from targets
C25915:  PLP
         RTS


C25917:  PHP
         LDA $2F46      ;untargetable monsters [clear], due to use of script
                        ;Command FB operation 7, or from formation special event.
         XBA
         LDA $3403      ;Seized characters: bit clear for those who are,
                        ;set for those who aren't.
         REP #$20
         AND $3A78      ;only include present characters and enemies?
         AND $3408
         AND $B8        ;only include initial targets
         STA $B8        ;save updated targets
         LDA $341A      ;check top bit of $341B
         BPL C25935     ;branch if not set
         LDA $3F2C      ;get Jumpers
         TRB $B8        ;remove them from targets
C25935:  PLP
         RTS


;Randomize Targets function.  selects entire monster or character parties (or both at a time,
; returned in $B8 and $B9.  calling function will later refine the targeting.)

;calling the character side 0 and the monster side 1, it looks like this up through C2/598A:
;  side chosen = (monster caster) XOR ;character acting as enemy caster) XOR Charmed XOR
;                "Cursor start on opposition" XOR Muddled )

;values DURING function -- not coming in or leaving it:
; bit 7 of $B8 = side to target. characters = 0, monsters = 1, special/opposing characters = 1
; bit 6 of $B8 = 1: make both sides eligible to target)

C25937:  STZ $B9        ;clear enemy targets
         TDC            ;Accumulator = 0
         CPX #$08       ;set Carry if caster is monster.  note that "caster" can
                        ;also mean "reflector", in which case a good part of
                        ;this function will be skipped.
         ROR
         STA $B8        ;Bits 0-6 = 0.  Bit 7 = 1 if monster caster, 0 if character
         LDA $BA
         BIT #$10       ;has Reflection occurred?
         BNE C25986     ;if so, branch, and do just the one flip of $B8's top
                        ;bit..  as a reflected spell always bounces at the party
                        ;opposing the reflector.
                        ;once the spell's already hit the Wall Ring, we
                        ;[generally] don't care about the reflector's status, and
                        ;they're not necessarily the caster anyway.
         LDA $3395,X
         BMI C25950     ;Branch if not Charmed
         LDA #$80
         EOR $B8
         STA $B8        ;toggle top bit of $B8
C25950:  LDA $3018,X
         BIT $3A40      ;is caster a special type of character, namely one acting
                        ;as an enemy?  like Gau returning from a Veldt leap, or
                        ;Shadow in the Colosseum.
         BEQ C2595E     ;if not, branch
         LDA #$80       ;if so.. here comes another toggle!
         EOR $B8
         STA $B8        ;toggle top bit of $B8
C2595E:  LDA $BB        ;targeting byte
         AND #$0C       ;isolate "Autoselect both parties" and "Autoselect one party"
         CMP #$04       ;is "autoselect both parties" the only bit of these two set?
         BNE C2596A     ;if not, branch
         LDA #$40
         TSB $B8        ;make both monsters and characters targetable
C2596A:  LDA $BB        ;targeting byte
         AND #$40       ;isolate "cursor start on enemy" [read: OPPOSITION, not
                        ;monster]
         ASL            ;put into top bit of A
         EOR $B8
         STA $B8        ;toggle top bit yet again
         LDA $3EE4,X    ;Status byte 1
         LSR
         LSR
         BCC C2597E     ;Branch if not Zombie
         LDA #$40
         TSB $B8        ;make both monsters and characters targetable
C2597E:  LDA $3EE5,X    ;Status byte 2
         ASL
         ASL
         ASL
         BCC C2598C     ;Branch if not Muddled
C25986:  LDA #$80
         EOR $B8
         STA $B8        ;toggle top bit
C2598C:  LDA $B8
         ASL
         STZ $B8        ;clear character targets; monsters were cleared at start
                        ;of function
         BMI C25995     ;if target anybody bit is set, branch, as we don't care
                        ;whether monsters or characters were indicated by top bit
         BCC C259A0     ;if target monsters bit was not set, branch
C25995:  PHP            ;save Carry and Negative flags
         LDA #$3F
         TSB $B9        ;target all monsters
         LDA $3A40
         TSB $B8        ;target only characters acting as enemies, like Colosseum
                        ;Shadow and Gau returning from a Veldt leap
         PLP            ;restore Carry and Negative flags
C259A0:  BMI C259A4     ;if target anybody bit is set, branch, as we don't care
                        ;whether monsters or characters were indicated by top bit
         BCS C259AB     ;if target monsters bit was set, exit function
C259A4:  LDA #$0F       ;mark all characters
         EOR $3A40      ;exclude characters acting as enemies from addition
         TSB $B8        ;turn on just normal characters' bits

;bits 7 and 6 |  Results
; -----------------------------------------------------------------------
;    0     0      normal characters
;    1     0      all monsters, special/enemy characters
;    0     1      all monsters, special/enemy characters + normal characters
;    1     1      all monsters, special/enemy characters + normal characters
;							)
C259AB:  RTS


;If a reflection has occurred AND the initial spellcast had one party aiming at another
; AND the reflector isn't Muddled, then there's a 50% chance the initial caster will
; become the sole target, provided he/she is in the party that's about to be hit by the
; bounce.  The other 50% of the time, the final target is randomly chosen by the end of
; function C2/587E; each member of the party opposing the reflector has the same chance
; of getting hit.)

C259AC:  LDA $BA
         BIT #$10
         BEQ C259DA     ;branch if not Reflected
         BIT #$02
         BEQ C259D9     ;branch if not attacking opposition..  iow,
                        ;is reflectOR an opponent?
         LDA $3EE5,X    ;Status byte 2
         BIT #$20
         BNE C259D9     ;if this reflector is Muddled, exit function
         JSR C24B53
         BCS C259D9     ;50% chance of exit function
         PHX
         LDX $3A32      ;get ($78) animation buffer pointer
         LDA $2C5F,X    ;get unique index of ORIGINAL spell caster
                        ;[from animation data]?
         ASL
         TAX            ;multiply by 2 to access their data block
         REP #$20       ;set 16-bit accumulator
         LDA $3018,X
         BIT $B8        ;is original caster a member of the party about
                        ;to be hit by the bounce?
         BEQ C259D6
         STA $B8        ;if they are, save them as the sole target of
                        ;this bounce
C259D6:  SEP #$20       ;set 8-bit accumulator
         PLX
C259D9:  RTS


;Deal with targeting for different encounter formations

;NOTE: I reuse the "Autoselect both parties" description from FF3usME, though
; if "Autoselect one party" is also set, the former becomes "Autoselect both
; CLUSTERS".  Spread-aim spells without this bit set [Haste 2, Slow 2, X-Zone]
; will only be able to target one cluster of your party at a time when it's split
; by a Side attack or one cluster of the monster party when it's split by a Pincer.
; Whereas spells WITH it set [Meteor, Quake] can hit both/all clumps.)

C259DA:  LDA $BB        ;targeting byte
         AND #$0C       ;isolate "Autoselect both parties" and "Autoselect one party"
         PHA            ;save these bits of targeting byte
         BIT #$04       ;is "Autoselect both parties" set?
         BNE C25A35     ;if yes, branch
                        ;if not, we'll be unable to hit more than one cluster of
                        ;targets at a time, so take special steps for formations
                        ;like Pincer and Side, which divide targets into these clusters

         LDA $201F      ;get encounter type: 0 = front, 1 = back, 2 = pincer, 3 = side
         CMP #$02
         BNE C25A0D     ;branch if not pincer
         LDA $2EAD      ;bitfield of enemies in right "clump".
                        ;set in function C1/1588.
         XBA
         LDA $2EAC      ;bitfield of enemies in left "clump".
                        ;set in function C1/1588.
         CPX #$08
         BCC C259FC     ;branch if attacker is not a monster
         BIT $3019,X    ;is this attacker among enemies on left side
                        ;of pincer?
         BEQ C25A0B     ;branch if not, and clear left side enemies from targets
         BRA C25A0A     ;otherwise, branch, and clear right side enemies from
                        ;targets
C259FC:  BIT $B9        ;are left side enemies among targets?
         BEQ C25A0D     ;if they aren't, we don't have to choose a side for
                        ;attack, so branch and dont' alter anything.
         XBA
         BIT $B9
         BEQ C25A0D     ;if right side enemies aren't among targets, we don't have
                        ;to choose a side, so branch and don't alter anything.
         JSR C24B53
         BCC C25A0B     ;50% branch.  half the time, we clear left side enemies.
                        ;the other half, right side.
C25A0A:  XBA
C25A0B:  TRB $B9        ;clear some enemy targets
C25A0D:  LDA $201F      ;get encounter type: 0 = front, 1 = back, 2 = pincer, 3 = side
         CMP #$03
         BNE C25A35     ;branch if not side
         LDA #$0C       ;characters 2 and 3, who are on left side
         XBA
         LDA #$03       ;characters 0 and 1, who are on right side
         CPX #$08
         BCS C25A24     ;branch if monster attacker
         BIT $3018,X
         BEQ C25A33     ;branch if it's a character, and they're not on right side.
                        ;this will clear right side characters from targets.
         BRA C25A32     ;otherwise, branch and clear left side characters from
                        ;targets
C25A24:  BIT $B8
         BEQ C25A35     ;if right side characters aren't among targets, we don't
                        ;have to choose a side, so branch and don't alter anything
         XBA
         BIT $B8
         BEQ C25A35     ;if left side characters aren't among targets, we don't
                        ;have to choose a side, so branch and don't alter anything
         JSR C24B53
         BCC C25A33     ;50% branch.  half the time, we clear right side characters.
                        ;the other half, left side.
C25A32:  XBA
C25A33:  TRB $B8        ;clear some character targets
C25A35:  PLA            ;retrieve "Autoselect both parties" and "Autoselect one party"
                        ;bits of targeting byte
         CMP #$04       ;was only "Autoselect both parties" set?
         BEQ C25A4C     ;if so, exit function
         LDA $B8
         BEQ C25A4C     ;if no characters targeted, exit function
         LDA $B9
         BEQ C25A4C     ;or if no monsters targeted, exit function

;                         (if we reached here, both monsters and characters are targeted, even
;                          though attack's aiming byte didn't indicate that.)
         JSR C24B5A     ;random # [0..255]
         PHX
         AND #$01       ;reduce random number to 0 or 1
         TAX
         STZ $B8,X      ;clear $B8 [character targets] or $B9 [monster targets] .
                        ;i THINK the only case where C2/5937 would have both
                        ;characters and monsters targeted with "Autoselect both
                        ;parties" unset or "Autoselect one party" set along with it
                        ;is that of a Zombie caster.
         PLX
C25A4C:  RTS


;Removes dead (including Zombie/Petrify for monsters, hidden, and absent targets

C25A4D:  PHX
         PHP
         REP #$20
         LDX #$12
C25A53:  LDA $3018,X
         BIT $B8
         BEQ C25A7C     ;Branch if not a target
         LDA $3AA0,X
         LSR
         BCC C25A77     ;branch if target isn't still valid?
         LDA #$00C2
         CPX #$08
         BCS C25A6A     ;Branch if monster
         LDA #$0080
C25A6A:  BIT $3EE4,X
         BNE C25A77     ;Branch if death status for characters/monsters, or
                        ;Zombie or Petrify for monsters
         LDA $3EF8,X
         BIT #$2000
         BEQ C25A7C     ;Branch if not hidden
C25A77:  LDA $3018,X
         TRB $B8        ;clear current target
C25A7C:  DEX
         DEX
         BPL C25A53     ;loop for all monsters and characters
         PLP
         PLX
         RTS


;Called whenever battle timer is incremented.
; Handles various time-based events for entities.  Advances their timers, does
; periodic damage/healing from Poison/Regen/etc., checks for running, and more.)

C25A83:  LDA $3A91      ;Lower byte of battle time counter equivalent
         INC $3A91      ;increment that counter equiv.
         AND #$0F
         CMP #$0A
         BCS C25AE1     ;Branch if lower nibble of time counter was >= #$0A
                        ;otherwise, A now corresponds to one of the 10
                        ;onscreen entities.
         ASL
         TAX
         LDA $3AA0,X
         LSR
         BCC C25AE9     ;Exit if entity not present in battle
         CLC
         LDA $3ADC,X    ;Timer that determines how often timers and time-based
                        ;events will countdown and happen for this entity.
         ADC $3ADD,X    ;Add ATB multiplier (set at C2/09D2: normally,
                        ;32 if Slowed, 84 if Hasted
         STA $3ADC,X
         BCC C25AE9     ;Exit if timer didn't meet or exceed 256
         LDA $3AF1,X    ;Get Stop timer, originally set to #$12
                        ;at C2/467D
         BEQ C25AB1     ;Branch if it's 0, as that *should* mean the
                        ;entity is not stopped.
         DEC $3AF1,X    ;Decrement Stop timer
         BNE C25AE9     ;did it JUST run down on this tick?  if not, exit
         LDA #$01
         BRA C25B06     ;Set Stop to wear off
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

C25AB1:  LDA $3AA0,X
         BIT #$10       ;is entity Wounded, Petrified, or Stopped, or is
                        ;somebody else under the influence of Quick?
         BNE C25AE9     ;Exit if any are true
         LDA $3B05,X    ;Condemned counter - originally set at C2/09B4.
                        ;To be clear, this counter is "one off" from the
                        ;actual numerals you'll see onscreen:
                        ;  00 value = numerals disabled
                        ;  01 value = numerals at "00", 02 = "01", 03 = "02",
                        ;  etc.
         CMP #$02
         BCC C25AC9     ;Branch if counter < 2.  [i.e. numerals < "01",
                        ;meaning they're "00" or disabled.]
         DEC
         STA $3B05,X    ;decrement counter
         DEC            ;just think of this second "DEC" as an optimized
                        ;"CMP #$01", as we're not altering the counter.
         BNE C25AC9     ;Branch if counter now != 1  [i.e. numerals != "00"]
         JSR C25BC7     ;Cast Doom when countdown numerals reach 0
C25AC9:  JSR C25C1B     ;Check if character runs from combat
         JSR C25B4F     ;Trigger Poison, Seizure, Regen, Phantasm, or
                        ;Tentacle Drain damage
         TDC
         JSR C25B06     ;Decrement Reflect, Freeze, and Sleep timers if
                        ;applicable, and check if any have worn off
         INC $3AF0,X    ;advance this entity's pointer to the next entry
                        ;in the C2/5AEA function table
         LDA $3AF0,X
         TXY            ;preserve X in Y
         AND #$07       ;convert it to 0-7, wrapping as necessary
         ASL
         TAX
         JMP (C25AEA,X) ;determine which periodic/damage healing type
                        ;will be checked on this entity's next tick.
C25AE1:  SBC #$0A       ;should only be reached if ($3A91 AND 15 was >= 10
                        ;[i.e. not corresponding to any specific entity]
                        ;at start of function.  now subtract 10.
         ASL
         TAX
         JMP (C25AFA,X)
C25AE8:  TYX            ;restore X from Y
C25AE9:  RTS


;Code pointers
;Note: choosing RTS will default to the (monster) entity draining anybody
; it has Seized on its next tick.)

C25AEA: dw C25B45     ;(Set bit 3 of $3E4C,X - check regen, seizure, phantasm)
      : dw C25AE8     ;(RTS)
      : dw C25B3B     ;(Set bit 4 of $3E4C,X - check poison)
      : dw C25AE8     ;(RTS)
      : dw C25B45     ;(Set bit 3 of $3E4C,X - check regen, seizure, phantasm)
      : dw C25AE8     ;(RTS)
      : dw C25AE8     ;(RTS)
      : dw C25AE8     ;(RTS)


;Code pointers

C25AFA: dw C25BB2     ;(Enemy Roulette completion)
      : dw C25BFC     ;(Increment time counters)
      : dw C25AE9     ;(RTS)
      : dw C25AE9     ;(RTS)
      : dw C25AE9     ;(RTS)
      : dw C25BD0     ;(Process "ready to run" characters, queue Flee command as needed)


;Decrement Reflect, Freeze, and Sleep timers if applicable, and if any
; have worn off, mark them to be removed.  If A was 1 (rather than 0) going
; into this function, which means Stop just ran out, mark it to be removed.)

C25B06:  STA $B8
         LDA $3F0C,X    ;Time until Reflect wears off
                        ;Originally set to #$1A at C2/4687
         BEQ C25B16     ;branch if timer not active
         DEC $3F0C,X    ;Decrement Reflect timer
         BNE C25B16
         LDA #$02
         TSB $B8        ;If Reflect timer reached 0 on this tick,
                        ;set to remove Reflect
C25B16:  LDA $3F0D,X    ;Time until Freeze wears off
                        ;Originally set to #$22 at C2/4691
         BEQ C25B24     ;branch if timer not active
         DEC $3F0D,X    ;Decrement Freeze timer
         BNE C25B24
         LDA #$04
         TSB $B8        ;If Freeze timer reached 0 on this tick,
                        ;set to remove Freeze
C25B24:  LDA $3CF9,X    ;Time until Sleep wears off
                        ;Originally set to #$12 at C2/4633
         BEQ C25B32     ;branch if timer not active
         DEC $3CF9,X    ;Decrement Sleep timer
         BNE C25B32
         LDA #$08
         TSB $B8        ;If Sleep timer reached 0 on this tick,
                        ;set to remove Sleep
C25B32:  LDA $B8
         BEQ C25AE9     ;Exit if we haven't marked any of the
                        ;statuses to be auto-removed
         LDA #$29
         JMP C24E91     ;queue the status removal, in global
                        ;Special Action queue


;Set to check for Poison on this entity's next tick

C25B3B:  TYX
         LDA $3E4C,X
         ORA #$10
         STA $3E4C,X    ;Set bit 4 of $3E4C,X
         RTS


;Set to check for Regen, Seizure, Phantasm on this entity's next tick

C25B45:  TYX
         LDA $3E4C,X
         ORA #$08
         STA $3E4C,X    ;Set bit 3 of $3E4C,X
C25B4E:  RTS


;Trigger Poison, Regen, Seizure, Phantasm, or Tentacle Drain attack

C25B4F:  LDA #$10
         BIT $3AA1,X
         BNE C25B4E     ;Exit if bit 4 of $3AA1 is set.  we already
                        ;have some periodic damage/healing queued for
                        ;this entity, so don't queue any more yet.
         LDA $3E4C,X
         BIT #$10
         BEQ C25B6B     ;Branch if bit 4 of $3E4C,X is not set
                        ;Check Regen and Seizure and Phantasm if not set,
                        ;Poison if set
         AND #$EF
         STA $3E4C,X    ;Clear bit 4 of $3E4C,X
         LDA $3EE4,X    ;Status byte 1
         AND #$04
         BEQ C25B4E     ;Exit if not poisoned
         BRA C25B85
 

;<>Check Seizure, Phantasm, and Regen

C25B6B:  BIT #$08
         BEQ C25B92     ;Branch if bit 3 of $3E4C,X is not set
                        ;Check Tentacle Drain if not set, Seizure and Phantasm
                        ;and Regen if set
         AND #$F7
         STA $3E4C,X    ;Clear bit 3 of $3E4C,X
         LDA $3EE5,X
         ORA $3E4D,X    ;are Seizure or Phantasm set?
         AND #$40
         BNE C25B85     ;if at least one is, branch
         LDA $3EF8,X
         AND #$02       ;is Regen set?
         BEQ C25B4E     ;if not, exit function
C25B85:  STA $3A7B      ;Set spell) (02 = Regen, 04 = Poison, 40 = Seizure/Phantasm
         LDA #$22
         STA $3A7A      ;Set command to #$22 - Poison, Regen, Seizure, Phantasm
         JSR C24EB2     ;queue it, in entity's counterattack and periodic
                        ;damage/healing queue
         BRA C25BA9
 

;<>Check Drain from being Seized

C25B92:  LDY $3358,X
         BMI C25B4E     ;Exit if monster doesn't have a character seized
         REP #$20       ;Set 16-bit A
         LDA $3018,Y
         STA $B8        ;Set target to character monster has seized
         LDA #$002D
         STA $3A7A      ;Set command to #$2D - drain from being seized
         SEP #$20       ;Set 8-bit A
         JSR C24EB2     ;queue it, in entity's counterattack and periodic
                        ;damage/healing queue
C25BA9:  LDA #$10
C25BAB:  ORA $3AA1,X
         STA $3AA1,X    ;Set bit 4 of $3AA1,X.  This bit will prevent us from
                        ;queueing up more than one instance of periodic
                        ;damage/healing (i.e. Poison, Seizure/Phantasm, Regen,
                        ;or Tentacle Drain) at a time for a given entity.
         RTS


;Enemy Roulette completion

C25BB2:  LDA $2F43      ;top byte of Enemy Roulette target bitfield, which
                        ;is set at C1/B41A when the cursor winds down.
         BMI C25B4E     ;Exit if no targets are defined
         REP #$20       ;Set 16-bit A
         LDA $2F42      ;get our chosen target
         JSR C251F9     ;Y = bit number of highest bit set in A (0 for bit 0,
                        ;2 for bit 1, 4 for bit 2, etc.)
         TDC
         DEC            ;A = #$FFFF
         STA $2F42      ;Set Enemy Roulette targets in $2F42 to null
         SEP #$20       ;Set 8-bit A
         TYX
C25BC7:  LDA #$0D       ;Condemned expiration enters here
         STA $B8        ;spell = Doom
         LDA #$26
         JMP C24E91     ;queue the reaper, in global Special Action queue


;Process "ready to run" characters, queue Flee command as needed

C25BD0:  LDA $2F45      ;party trying to run: 0 = no, 1 = yes
         BEQ C25C1A     ;exit if not
         LDA $B1
         BIT #$02       ;is Can't Run set?
         BNE C25BF1     ;branch if so
         LDA $3A91      ;get bottom byte of battle time counter equiv.,
                        ;will have value of NFh here
         AND #$70
         BNE C25C1A     ;7/8 chance of exit
C25BE2:  LDA $2F45      ;party trying to run.  yes, a duplicate
                        ;check.  it's done because C2/5C1B and C2/11BB
                        ;can branch here.
         BEQ C25C1A     ;exit if not trying to run
         LDA $3A38      ;characters who are ready to run
         BEQ C25C1A     ;exit if none
         LDA $3A97
         BNE C25C1A     ;exit if in Colosseum
C25BF1:  LDA #$04
         TSB $B0        ;set flag
         BNE C25C1A     ;exit if we've already executed this since the
                        ;last time C2/007D was executed, which is at least
                        ;as recent as the last time C2/5C73 was called
         LDA #$2A
         JMP C24E91     ;queue (attempted flee command, in global
                        ;Special Action queue


;Increment time counters

C25BFC:  PHP
         REP #$20       ;set 16-bit A
         INC $3A44      ;increment Global battle time counter
         LDX #$12       ;point to last enemy
C25C04:  LDA $3AA0,X
         LSR
         BCC C25C15     ;Skip entity if not present in battle
         LDA $3EE4,X    ;status byte 1
         BIT #$00C0
         BNE C25C15     ;branch if petrified or dead
         INC $3DC0,X    ;Increment monster time counter
C25C15:  DEX
         DEX
         BPL C25C04     ;loop for all monsters and characters
         PLP
C25C1A:  RTS


;Check if character runs from combat

C25C1B:  CPX #$08
         BCS C25C53     ;Exit if monster
         LDA $2F45      ;party trying to run: 0 = no, 1 = yes
         BEQ C25C53     ;Exit if not trying to run
         LDA $3A39      ;Load characters who've escaped
         ORA $3A40      ;Or with characters acting as enemies
         BIT $3018,X    ;Is the current character in one or more of
                        ;these groups?
         BNE C25C53     ;Exit if so
         LDA $3A3B      ;Get the Run Difficulty
         BNE C25C3A     ;Branch if it's nonzero
         JSR C25C4D     ;mark character as "ready to run"
         JMP C25BE2     ;why not BRAnch to C2/5BEC?


;Figure character's "Run Success" variable and determine whether ready to run

C25C3A:  LDA $3D71,X    ;Amount to add to "run success" variable.
                        ;varies by character; ranges from 2 through 5.
         JSR C24B65     ;random: 0 to A - 1
         INC            ;1 to A
         CLC
         ADC $3D70,X
         STA $3D70,X    ;add to Run Success variable
         CMP $3A3B      ;compare to Run Difficulty
         BCC C25C53     ;if it's less, the character's not running yet
C25C4D:  LDA $3018,X
         TSB $3A38      ;mark character as "ready to run"
C25C53:  RTS


;Copy ATB timer, Morph gauge, and Condemned counter to displayable variables

C25C54:  SEP #$30
         LDX #$06
         LDY #$03
C25C5A:  LDA $3219,X    ;ATB timer, top byte
         DEC
         STA $2022,Y    ;visual ATB gauge?
         LDA $3B04,X    ;Morph gauge
         STA $2026,Y
         LDA $3B05,X    ;Condemned counter
         STA $202A,Y
         DEX
         DEX
         DEY
         BPL C25C5A     ;iterate for all 4 characters
         RTS


;Update Can't Escape, Can't Run, Run Difficulty, and onscreen list of enemy names,
; based on currently present enemies)

C25C73:  REP #$20       ;Set 16-bit Accumulator
         LDY #$08       ;the following loop nulls the list of enemy
                        ;names [and quantities, shown in FF6j but not FF3us]
                        ;that appears on the bottom left corner of the
                        ;screen in battle?
C25C77:  TDC            ;A = 0000h
         STA $2013,Y    ;store to $2015 - $201B, each having a 16-bit
                        ;monster quantity
         DEC            ;A = FFFFh
         STA $200B,Y    ;store to $200D - $2013, each having a 16-bit
                        ;monster ID
         DEY
         DEY
         BNE C25C77     ;iterate 4 times, as there are 4 list entries
         SEP #$20       ;Set 8-bit Accumulator
         LDA #$06
         TRB $B1        ;clear Can't Run and Can't Escape
         LDA $201F      ;get encounter type.  0 = front, 1 = back,
                        ;2 = pincer, 3 = side
         CMP #$02
         BNE C25CA4     ;branch if not pincer
         LDA $2EAC      ;bitfield of enemies in left "clump".
                        ;set in function C1/1588.
         AND $2F2F      ;compare to bitfield of remaining enemies?
         BEQ C25CA4     ;branch if no enemy on left side remaining
         LDA $2EAD      ;bitfield of enemies in right "clump".
                        ;set in function C1/1588.
         AND $2F2F      ;compare to bitfield of remaining enemies?
         BEQ C25CA4     ;branch if no enemy on right side remaining
         LDA #$02
         TSB $B1        ;set Can't Run
C25CA4:  STZ $3A3B      ;set Run Difficulty to zero
         STZ $3ECA      ;set Number of Unique enemy names who are currently
                        ;active to zero?  this variable will have a max
                        ;of 4, even though the actual number of unique
                        ;enemy names can go to 6.
C25CAA:  LDA $3AA8,Y
         LSR
         BCC C25D04     ;skip to next monster if this one not present
         LDA $3021,Y
         BIT $3A3A      ;is it in bitfield of dead-ish monsters?
         BNE C25D04     ;branch if so
         BIT $3409
         BEQ C25D04
         LDA $3EEC,Y    ;get monster's status byte 1
         BIT #$C2
         BNE C25D04     ;branch if Zombie, Petrify, or Wound is set
         LDA $3C88,Y    ;monster Misc/Special Byte 2.  normally accessed as
                        ;"$3C80,Y" , but we're only looking at enemies here.
         LSR            ;put "Harder to Run From" bit in Carry flag
         BIT #$04       ;is "Can't Escape" bit set in monster data?  [called
                        ;"Can't Run" in FF3usME]
         BEQ C25CD0
         LDA #$06
         TSB $B1        ;if so, set both Can't Run and Can't Escape.  the latter
                        ;will stop Warp, Warp Stones, and Smoke Bombs.  even though
                        ;a failed Smoke Bomb gives a "Can't run away!!" rather than
                        ;a "Can't escape!!" message, it just looks at the
                        ;Can't Escape bit.

C25CD0:  TDC
         ROL
         SEC
         ROL
         ASL            ;if "Harder to Run From" was set, A = 6.  if not, A = 2.
         ADC $3A3B
         STA $3A3B      ;add to Run Difficulty
         LDA $3C9D,Y    ;normally accessed as $3C95,Y , but we're only looking
                        ;at enemies here.
         BIT #$04       ;is "Name Hidden" property set?
         BNE C25D04     ;branch if so
         REP #$20
         LDX #$00
C25CE6:  LDA $200D,X    ;entry in list of enemy names you see on bottom left
                        ;of screen in battle?
         BPL C25CF4     ;branch if this entry has already been assigned an
                        ;enemy ID
         LDA $3388,Y    ;get entry from Enemy Name structure, initialized
                        ;in function C2/2C30 [using $3380], for our current
                        ;monster pointed to by Y.  this structure has a list
                        ;of enemy IDs for the up to 6 enemies in a battle,
                        ;but it's normalized so enemies with matching names have
                        ;matching IDs.
         STA $200D,X    ;save it in list of names?
         INC $3ECA      ;increment the number of unique names of active enemies?
                        ;this counter will max out at 4, because the in-battle
                        ;list shows a maximum of 4 names, even though the actual
                        ;# of unique enemy names goes up to 6.
                        ;this variable is used by the FC 10 monster script
                        ;command.
C25CF4:  CMP $3388,Y    ;compare enemy ID previously in this screen list entry
                        ;to one in the Name Structure entry.  they'll match for
                        ;sure if we didn't follow the branch at C2/5CE9.
         BNE C25CFE     ;if they don't match, skip to next screen list entry
         INC $2015,X    ;they did match, so increase the quantity of enemies
                        ;who have this name.  FF6j displayed a quantity in
                        ;battle.  FF3us increased enemy names from 8 to 10
                        ;characters, so it never shows the quantity.
         BRA C25D04     ;exit this loop, as our enemy ID [as indexed by Y] is
                        ;already in the screen list.
C25CFE:  INX
         INX
         CPX #$08
         BCC C25CE6     ;iterate 4 times, as the battle enemy name list has
                        ;4 entries.
C25D04:  SEP #$20
         INY
         INY
         CPY #$0C
         BCC C25CAA     ;iterate for all 6 monsters
         LDA $201F      ;get encounter type.  0 = front, 1 = back,
                        ;2 = pincer, 3 = side
         CMP #$03
         BEQ C25D19     ;branch if side attack
         LDA $B0
         BIT #$40
         BEQ C25D1C     ;branch if not Preemptive attack
C25D19:  STZ $3A3B      ;set Run Difficulty to zero
C25D1C:  LDA $3A42      ;list of present and living characters acting
                        ;as enemies?
         BEQ C25D25     ;branch if none
         LDA #$02
         TSB $B1        ;set Can't Run
C25D25:  RTS


;Copy Current and Max HP and MP, and statuses to displayable variables

C25D26:  PHP
         REP #$20
         SEP #$10
         LDY #$06
C25D2D:  LDA $3BF4,Y    ;current HP
         STA $2E78,Y
         LDA $3C1C,Y    ;max HP
         STA $2E80,Y
         LDA $3C08,Y    ;current MP
         STA $2E88,Y
         LDA $3C30,Y    ;max MP
         STA $2E90,Y
         LDA $3EE4,Y    ;status bytes 1-2
         STA $2E98,Y
         LDA $3EF8,Y    ;status bytes 3-4
         STA $2EA0,Y
         DEY
         DEY
         BPL C25D2D     ;iterate for all 4 characters
         PLP
         RTS


C25D57:  PHP
         JSR C20267
         LDX #$06
C25D5D:  STZ $2E99,X
         DEX
         DEX
         BPL C25D5D
         LDX #$0B
C25D66:  STZ $2F35,X    ;clear message parameter bytes
         DEX
         BPL C25D66     ;iterate 12 times
         LDA #$08
         JSR C26411
         JSR C24903
         LDA $3A97
         BEQ C25D91     ;branch if not in Colosseum
         LDA #$01
         STA $2E75      ;indicate quantity of won item is 1
         LDA $0207      ;item won from Colosseum
         STA $2F35      ;save in message parameter 1, bottom byte
         JSR C254DC     ;copy item's info to a 5-byte buffer, spanning
                        ;$2E72 - $2E76.  doesn't touch $2E75.
         JSR C26279     ;add item in buffer to Item menu [which is soon
                        ;copied to inventory]?
         LDA #$20
         JSR C25FD4     ;buffer and display "Got [item] x 1" message
         PLP
         RTS


;At end of victorious combat, handle GP and Experience gained from battle,
; learned spells and abilities, won items, and displays all relevant messages.)

C25D91:  REP #$10       ;Set 16-bit X and Y
         TDC            ;clear accumulator
         LDX $3ED4      ;get battle formation #
         CPX #$0200
         BCS C25DA0     ;if it's >= 512, there's no magic points, so branch
         LDA $DFB400,X  ;magic points given by that enemy formation
C25DA0:  STA $FB
         STZ $F0
         LDA $3EBC
         AND #$08       ;set after getting any of four Magicites in Zozo --
                        ;allows Magic Point display
         STA $F1        ;save that bit
         REP #$20       ;Set 16-bit Accumulator
         LDX #$000A
C25DB0:  LDA $3EEC,X    ;check enemy's 1st status byte
         BIT #$00C2     ;Petrify, death, or zombie?
         BEQ C25DDE     ;if not, skip this enemy
         LDA $11E4
         BIT #$0002     ;is Leap available [aka we're on Veldt]?
         BNE C25DCF     ;branch if so) (had been typoed "BNE C25DD0"
         CLC
         LDA $3D8C,X    ;get enemy's XP -- base offset 3D84 is used earlier,
                        ;but that's because the function was indexing everybody
                        ;on screen, not just enemies
         ADC $2F35      ;add it to the experience from other enemies
         STA $2F35      ;save in message parameter 1, bottom word
         BCC C25DCF
         INC $2F37      ;if it flowed out of bottom word, increment top word
                        ;[top byte, really, since this was 0 prior]
C25DCF:  CLC
C25DD0:  LDA $3DA0,X    ;get enemy's GP
         ADC $2F3E      ;add it to GP from other enemies
         STA $2F3E      ;save in extra [?] message parameter, bottom word
         BCC C25DDE
         INC $2F40      ;if it flowed out of bottom word, increment top word
C25DDE:  DEX
         DEX
         BPL C25DB0     ;iterate for all 6 enemies

;Following code divides 24-bit XP gained from battle by 8-bit character quantity.
; Just long divide a 3-digit number by a 1-digit # to better follow the steps.)

         LDA $2F35      ;bottom 2 bytes of 24-bit experience
         STA $E8
         LDA $2F36      ;top 2 bytes of XP
         LDX $3A76      ;Number of present and living characters in party
         PHX
         JSR C24792     ;Divides 16-bit A / 8-bit X
                        ;Stores quotient in 16-bit A. Stores remainder in 8-bit X
         STA $EC        ;save quotient
         STX $E9        ;save remainder
         LDA $E8        ; $E8 = (remainder * 256) + bottom byte of original XP
         PLX
         JSR C24792     ;divide that by # of characters again
         STA $2F35      ;save bottom byte of final quotient in message
                        ;parameter 1, bottom byte
         LDA $EC        ;retrieve top 2 bytes of final quotient
         STA $2F36      ;save in message parameter 1, top 2 bytes
         ORA $2F35
         BEQ C25E0E     ;if the XP per character is zero, branch
         LDA #$0027
         JSR C25FD4     ;buffer and display "Got [amount] Exp. point(s)" message
C25E0E:  SEP #$20       ;set 8-bit Accumulator
         LDY #$0006
C25E13:  LDA $3018,Y
         BIT $3A74
         BEQ C25E73     ;Branch if character dead or absent [e.g. slot is empty,
                        ;or the character escaped or got sneezed or engulfed].
         LDA $3C59,Y
         AND #$10
         BEQ C25E2F     ;Branch if not x2 Gold [from Cat Hood]
         TSB $F0
         BNE C25E2F     ;Branch if gold has already been doubled by another
                        ;character
         ASL $2F3E
         ROL $2F3F
         ROL $2F40      ;double the GP won
C25E2F:  LDA $3ED8,Y    ;Which character it is
         CMP #$00
         BNE C25E49     ;Branch if not Terra
         LDA $F1        ;Bit 3 = 1 if have gotten any of Esper Magicites in Zozo
         BEQ C25E49     ;branch if not
         TSB $F0        ;this will enable Magic Point display below
         LDA $FB        ;Number of Magic Points gained from battle
         ASL            ;* 2
         ADC $1CF6      ;Add to Morph supply
         BCC C25E46     ;If it didn't overflow, branch
         LDA #$FF       ;Since it DID overflow, just set it to maximum
C25E46:  STA $1CF6      ;Set Morph supply
C25E49:  LDX $3010,Y    ;get offset to character info block
         JSR C26235     ;Add experience for battle
         LDA $3C59,Y
         BIT #$08
         BEQ C25E59     ;Branch if not x2 XP [from Exp. Egg]
         JSR C26235     ;Add experience for battle
C25E59:  LDA $3ED8,Y    ;Which character it is
         CMP #$0C
         BCS C25E73     ;Branch if Gogo or Umaro
         JSR C26283     ;Stores address for spells known by character in $F4
         LDX $3010,Y    ;get offset to character info block
         PHY
         JSR C25FEF     ;Progress towards uncursing Cursed Shield, and learning
                        ;spells taught by equipment
         LDA $161E,X    ;Esper equipped
         BMI C25E72     ;Branch if no esper equipped
         JSR C2602A     ;Progress towards learning spells taught by Esper
C25E72:  PLY
C25E73:  DEY
         DEY
         BPL C25E13     ;Check next character
         LDA $F1
         AND $F0
         BEQ C25E8F     ;branch if we don't have both of the following:
                        ;- Esper Magicites have been retrieved at Zozo
                        ;- Terra is in party, or Magic Points went towards
                        ;  a character progressing on spell learning
         LDA $FB        ;Magic points gained from battle
         BEQ C25E8F     ;branch if none
         STA $2F35      ;save in message parameter 1, bottom byte
         STZ $2F36
         STZ $2F37      ;zero top two bytes of parameter
         LDA #$35
         JSR C25FD4     ;buffer and display "Got [amount] Magic Point(s"
                        ;message
C25E8F:  LDY #$0006
C25E92:  LDA $3018,Y
         BIT $3A74      ;is character present and alive [and a non-enemy]?
         BEQ C25EB9     ;branch if not
         LDA $3ED8,Y    ;Which character it is
         JSR C26283     ;Stores address for spells known by character in $F4
         LDX $3010,Y    ;get offset to character info block
         TYA
         LSR
         STA $2F38      ;save 0-3 character # in message parameter 2, bottom
                        ;byte
         LDA #$2E
         STA $F2        ;supply message ID of "[Character] gained a level",
                        ;to C2/606D, and tell it that the character has yet
                        ;to level up from this battle.
         JSR C2606D     ;check whether character has enough experience to
                        ;reach next level, and level up if so
         LDA $3ED8,Y    ;which character this is
         CMP #$0C
         BCS C25EB9     ;branch if it's Gogo or Umaro or some temporary
                        ;character
         JSR C26133     ;Mark just-learned spells for a character as known,
                        ;and display messages for them
C25EB9:  DEY
         DEY
         BPL C25E92     ;iterate for all 4 party members
         SEP #$10       ;set 8-bit X and Y
         TDC
         SEC
         LDX #$02       ;start looking at last of three bytes in
                        ;Lores to Learn and Known Lores
         LDY #$17       ;start looking at last Lore, Exploder
C25EC5:  ROR
         BCC C25ECA
         ROR
         DEX            ;move to previous lore byte for each 8 we check
C25ECA:  BIT $3A84,X    ;was current Lore marked in Lores to Learn?
         BEQ C25EE2     ;branch if not
         PHA            ;Put on stack
         ORA $1D29,X
         STA $1D29,X    ;add to Known Lores
         TYA
         ADC #$8B       ;convert current lore # to a spell/attack #
         STA $2F35      ;save in message parameter 1, bottom byte
         LDA #$2D
         JSR C25FD4     ;buffer and display "Learned [lore name]" message
         PLA
C25EE2:  DEY
         BPL C25EC5     ;loop for all 24 lores
         LDA $300A      ;which character is Mog
         BMI C25F00     ;branch if not present in party
         LDX $11E2      ;get combat background
         LDA $ED8E5B,X  ;get corresponding Dance #
         BMI C25F00     ;branch if it's negative - presumably FF
         JSR C25217     ;X = A DIV 8, A = 2 ^ (A MOD 8)
         TSB $1D4C      ;turn on dance in known dances
         BNE C25F00     ;if it was already on, don't display a message
         LDA #$40
         JSR C25FD4     ;buffer and display "Mastered a new dance!" message
C25F00:  LDA $F0
         LSR
         BCC C25F0A     ;branch if we didn't uncurse the Cursed Shield this
                        ;battle
         LDA #$2A
         JSR C25FD4     ;buffer and display "Dispelled curse on shield" message
C25F0A:  LDX #$05       ;with up to 6 different enemies, you can win up to
                        ;6 different types of items
C25F0C:  TDC            ;clear A
         DEC            ;set A to FF
         STA $F0,X      ;item type
         STZ $F6,X      ;quantity of that item
         DEX
         BPL C25F0C     ;loop.  so in all 6 item slots, we'll have 0 of item #255.
         LDY #$0A       ;point to last enemy
C25F17:  LDA $3EEC,Y    ;check enemy's 1st status byte
         BIT #$C2       ;Petrify, Wound, or Zombied?
         BEQ C25F4E     ;if not, skip this enemy
         JSR C24B5A     ;random #, 0 to 255
         CMP #$20       ;Carry clear if A < 20h, set otherwise.
                        ;this means we'll use the Rare dropped item slot 1/8 of
                        ;the time, and the Common 7/8 of the time
         REP #$30       ;Accumulator and Index regs 16-bit
         TDC            ;clear A
         ROR            ;put Carry in highest bit of A
         ADC $2001,Y    ;enemy number.  $2001 is filled by code handling F2 script
                        ;command, which handles enemy formation.
         ASL
         ROL            ;multiply enemy # by 4, as Stolen+Dropped Item block is
                        ;4 bytes
                        ;and put Carry into lowest bit.  Rare when bit is 0, Common
                        ;for 1.
         TAX            ;updated index with enemy num and rare/common slot
         LDA $CF3002,X  ;item dropped - CF3002 is rare, CF3003 is common
         SEP #$30       ;Accumulator and index regs 8-bit
         CMP #$FF       ;does chosen enemy slot have empty FF item?
         BEQ C25F4E     ;if so, skip to next enemy
         LDX #$05
C25F39:  CMP $F0,X      ;is Item # the same as any of the others won?
         BEQ C25F4C     ;if so, branch to increment its quantity
         XBA
         LDA $F0,X      ;if not, check if current battle slot is empty
         INC
         BNE C25F48     ;if it wasn't empty, branch to check another battle slot
         XBA
         STA $F0,X      ;if it was, we can store our item there
         BRA C25F4C
C25F48:  XBA
         DEX
         BPL C25F39     ;compare item won to next slot
C25F4C:  INC $F6,X      ;increment the quantity of the item won
C25F4E:  DEY
         DEY            ;move down to next enemy
         BPL C25F17     ;loop for all the critters
         LDX #$05       ;start at last of 6 item slots
C25F54:  LDA $F0,X      ;get current item ID
         CMP #$FF
         BEQ C25F75     ;skip to next slot if it's empty
         STA $2F35      ;save in message parameter 1, bottom byte
         JSR C254DC     ;copy item's info to a 5-byte buffer, spanning
                        ;$2E72 - $2E76
         LDA $F6,X      ;get quantity of item won
         STA $2F38      ;save in message parameter 2, bottom byte
         STA $2E75      ;save quantity in that 5-byte buffer
         JSR C26279     ;add item in buffer to Item menu [which is soon
                        ;copied to inventory]
         LDA #$20       ;"Got [item] x 1" message ID
         DEC $F6,X
         BEQ C25F72
         INC            ;if more than one of this item ID won, A = 21h,
                        ;"Got [item] x [quantity]" message
C25F72:  JSR C25FD4     ;buffer and display won item(s) message
C25F75:  DEX
         BPL C25F54     ;iterate for all 6 possible won item types
         LDA $2F3E
         ORA $2F3F
         ORA $2F40
         BEQ C25FC5     ;branch if no gold won
         LDA $2F3E
         STA $2F38
         LDA $2F3F
         STA $2F39
         LDA $2F40
         STA $2F3A      ;copy 24-bit gold won from extra [?] message
                        ;parameter into 3-byte message parameter 2
         LDA #$26
         JSR C25FD4     ;buffer and display "Got [amount] GP" message
         CLC
         LDX #$FD
C25F9D:  LDA $1763,X
         ADC $2E41,X
         STA $1763,X    ;this loop adds won gold to party's gold
         INX
         BNE C25F9D
 
;The following loops will compare the party's GP (held in $1860 - $1862 to
; 9999999, and if it exceeds that amount, cap it at 9999999.)
         LDX #$02       ;start pointing to topmost bytes of party GP
                        ;and GP limit
C25FAB:  LDA C25FC7,X   ;get current byte of GP limit
         CMP $1860,X    ;compare to corresponding byte of party GP
         BEQ C25FC2     ;if the byte values match, we don't know how
                        ;the overall 24-bit values compare yet, so
                        ;go check the next lowest byte
         BCS C25FC5     ;if this byte of the GP limit exceeds the
                        ;corresponding byte of the party GP, we know
                        ;the overall value is also higher, so there's
                        ;no need to alter anything or compare further
         LDX #$02       ;if we reached here, we know party GP must
                        ;exceed the 9999999 limit, so cap it.
C25FB8:  LDA C25FC7,X 
         STA $1860,X
         DEX
         BPL C25FB8     ;update all 3 bytes of the party's GP
C25FC2:  DEX
         BPL C25FAB
C25FC5:  PLP
         RTS


;Data

C25FC7: dl $98967F  ;(GP cap: 9999999)



;Handle battles ending in loss - conventional, Colosseum, or Banon falling.
; Various end-battle messages also enter at C2/5FD4.)

C25FCA:  PHA            ;Put on stack
         LDA #$01
         TSB $3EBC      ;set event bit indicating battle ended in loss
         JSR C24903
         PLA
C25FD4:  PHP
         SEP #$20
         CMP #$FF
         BEQ C25FED     ;branch if in Colosseum
         STA $2D6F      ;second byte of first entry of ($76) buffer
         LDA #$02
         STA $2D6E      ;first byte of first entry of ($76) buffer
         LDA #$FF
         STA $2D72      ;first byte of second entry of ($76) buffer
         LDA #$04
         JSR C26411     ;Execute animation queue
C25FED:  PLP
         RTS


;Progress towards uncursing Cursed Shield, and learning spells taught by equipment

C25FEF:  PHX
         LDY #$0006     ;Check all equipment and relic slots
C25FF3:  LDA $161F,X    ;Item equipped, X determines slot to check
         CMP #$FF
         BEQ C26024     ;Branch if no item equipped
         CMP #$66
         BNE C2600C     ;Branch if no Cursed Shield equipped
         INC $3EC0      ;Increment number of battles fought with Cursed Shield
         BNE C2600C     ;Branch if not 256 battles
         LDA #$01
         TSB $F0        ;tell caller the shield was uncursed
         LDA #$67
         STA $161F,X    ;Change to Paladin Shield
C2600C:  XBA
         LDA #$1E
         JSR C24781     ;16-bit A = item ID * 30 [size of item data block]
                        ;JSR C22B63?
         PHX
         PHY
         TAX
         TDC
         LDA $D85004,X  ;Spell item teaches
         TAY
         LDA $D85003,X  ;Rate spell is learned
         JSR C2604B     ;Progress towards learning spell for equipped item
         PLY
         PLX
C26024:  INX            ;Check next equipment slot
         DEY
         BNE C25FF3     ;Branch if not last slot to check
         PLX
         RTS


;Progress towards learning spells taught by Esper

C2602A:  PHX
         JSR C26293     ;Multiply A by #$0B and store in X
         LDY #$0005     ;Do for each spell taught by esper
C26031:  TDC            ;Clear A
         LDA $D86E01,X  ;Spell taught
         CMP #$FF
         BEQ C26044     ;Branch if no spell taught
         PHY
         TAY
         LDA $D86E00,X  ;Spell learn rate
         JSR C2604B     ;Progress towards learning spell
         PLY
C26044:  INX
         INX
         DEY
         BNE C26031     ;Check next spell taught
         PLX
         RTS


;Progress towards learning spell

C2604B:  BEQ C2606C     ;branch if no learn rate, i.e. no spell to learn
         XBA
         LDA $FB        ;Magic points gained from the battle
         JSR C24781     ;Multiply by spell learn rate
         STA $EE        ;Store this amount in $EE
         LDA ($F4),Y    ;what % of spell is known
         CMP #$FF
         BEQ C2606C     ;Branch if spell already known
         CLC
         ADC $EE        ;Add amount learned to % known for spell
         BCS C26064
         CMP #$64
         BCC C26066     ;branch if % known didn't reach 100
C26064:  LDA #$80
C26066:  STA ($F4),Y    ;if it did, mark spell as just learned
         LDA $F1
         TSB $F0        ;tell Function C2/5D91 to enable gained Magic Point
                        ;display, provided we've already gotten an Esper
                        ;Magicite from Zozo
C2606C:  RTS


;Check whether character has enough experience to reach next level, and level up if so

C2606D:  STZ $F8
         TDC            ;Clear 16-bit A
         LDA $1608,X    ;current level
         CMP #$63
         BCS C2606C     ;exit if >= 99
         REP #$20       ;Set 16-bit A
         ASL
         PHX
         TAX            ;level * 2
         TDC            ;Clear 16-bit A
C2607D:  CLC            ;Clear carry
         ADC $ED821E,X  ;add to Experience Needed for Level Up FROM this level
         BCC C26086     ;branch if bottom 16-bits of sum didn't overflow
         INC $F8        ;if so, increment a counter that will determine
                        ;top 16-bits
C26086:  DEX
         DEX            ;point to experience needed for next lowest level
         BNE C2607D     ;total experience needed for level 1 thru current level.
                        ;IOW, total experience needed to reach next level.
         PLX

;                            (BUT, experience needed is stored divided by 8 in ROM, so we
;                             must multiply it to get true value)

         ASL
         ROL $F8        ;multiply 32-bit [only 24 bits ever used] experience
                        ;needed by 2
         ASL
         ROL $F8        ;again
         ASL
         ROL $F8        ;again
         STA $F6        ;so now, $F6 thru $F8 = total 24-bit experience needed
                        ;to advance from our given level
         LDA $1612,X    ;top 2 bytes of current Experience
         CMP $F7        ;compare to top 2 bytes of needed experience
         SEP #$20       ;set 8-bit Accumulator
         BCC C2606C     ;Exit if (current exp / 256) < (needed exp / 256)
         BNE C260A8     ;if (current exp / 256) != (needed exp / 256), branch
                        ;since it's not less than, we know it's greater than
         LDA $1611,X    ;bottom byte of Experience
         CMP $F6        ;compare to experience needed
         BCC C2606C     ;Exit if less
C260A8:  LDA $F2        ;holds 2Eh, message ID of "[Character] gained a level",
                        ;to start with
         BEQ C260B1     ;branch if current character has already levelled up
                        ;once from this function
         STZ $F2        ;indicate current character has levelled up
         JSR C25FD4     ;buffer and display "[character name] gained a level"
                        ;message
C260B1:  JSR C260C2     ;raise level, raise normal HP and MP, and give any
                        ;Esper bonus
         PHX
         LDA $1608,X    ;load level
         XBA            ;put in top of A
         LDA $1600,X    ;character ID, aka "Actor"
         JSR C261B6     ;Handle spells or abilities learned at level-up for
                        ;character
         PLX
         BRA C2606D     ;repeat to check for another possible level gain,
                        ;since it's possible a battle with wicked high
                        ;experience on a wussy character boosted multiple
                        ;levels.


;Gain level, raise HP and MP, and give any Esper bonus

C260C2:  PHP
         INC $1608,X    ;increment current level
         STZ $FD
         STZ $FF
         PHX
         TDC            ;Clear 16-bit A
         LDA $1608,X    ;get level
         TAX
         LDA $E6F500,X  ;normal MP gain for level
         STA $FE
         LDA $E6F49E,X  ;normal HP gain for level
         STA $FC
         PLX
         LDA $161E,X    ;get equipped Esper
         BMI C260F6     ;if it's null, don't try to calculate bonuses
         PHY
         PHX
         TXY            ;Y will be used to index stats that are boosted
                        ;by the $614E call.  i believe it currently points
                        ;to offset of character block from $1600
         JSR C26293     ;X = A * 11d
         TDC            ;Clear 16-bit A
         LDA $D86E0A,X  ;end of data block for Esper..  probably
                        ;has level-up bonus
         BMI C260F4     ;if null, don't try to calculate bonus
         ASL
         TAX            ;multiply bonus index by 2
         JSR (C2614E,X) ;calculate bonus.  note that [Stat]+1 jumps to the
                        ;same place as [Stat]+2.  what distinguishes them?
                        ;Bit 1 of X.  if X is 20, 24, 28, 32, you'll get +1
                        ;to a stat.. if it's 18, 22, 26, 30, you get +2.

                        ;for HP/MP boosts, X of 0/2/4 means HP, and
                        ;6/8/10 means MP
C260F4:  PLX
         PLY
C260F6:  REP #$21       ;set 16-bit A, clear carry
         LDA $160B,X    ;maximum HP
         PHA            ;Put on stack
         AND #$C000     ;isolate top bits, which indicate (bit 7, then bit 6:
                        ;00 = no equipment % bonus, 11 = 12.5% bonus,
                        ;01 = 25% bonus, 10 = 50% bonus
         STA $EE        ;save equipment bonus bits
         PLA            ;get max HP again
         AND #$3FFF     ;isolate bottom 14 bits.. just the max HP w/o bonus
         ADC $FC        ;add to HP gain for level
         CMP #$2710
         BCC C2610F     ;branch if less than 10000
         LDA #$270F     ;replace with 9999
C2610F:  ORA $EE        ;combine with bonus bits
         STA $160B,X    ;save updated max HP
         CLC            ;clear carry
         LDA $160F,X    ;now maximum MP
         PHA            ;Put on stack
         AND #$C000     ;isolate top bits, which indicate (bit 7, then bit 6:
                        ;00 = no equipment % bonus, 11 = 12.5% bonus,
                        ;01 = 25% bonus, 10 = 50% bonus
         STA $EE        ;save equipment bonus bits
         PLA            ;get max MP again
         AND #$3FFF     ;isolate bottom 14 bits.. just the max MP w/o bonus
         ADC $FE        ;add to MP gain for level
         CMP #$03E8
         BCC C2612C     ;branch if less than 1000
         LDA #$03E7     ;replace with 999
C2612C:  ORA $EE        ;combine with bonus bits
         STA $160F,X    ;save updated max MP
         PLP
         RTS


;Mark just-learned spells for a character as known, and display messages
; for them)

C26133:  PHY
         LDY #$0035
C26137:  LDA ($F4),Y
         CMP #$80       ;was this spell just learned?
         BNE C26149     ;branch if not
         LDA #$FF
         STA ($F4),Y    ;mark it as known
         STY $2F35      ;save spell ID in message parameter 1, bottom byte
         LDA #$32
         JSR C25FD4     ;buffer and display
                        ;"[Character name] learned [spell name]" message
C26149:  DEY
         BPL C26137     ;iterate for all 54 spells
         PLY
         RTS


;Code Pointers

C2614E: dw C26170  ;(~10% HP bonus)  (HP due to X)
      : dw C26174  ;(~30% HP bonus)  (HP due to X)
      : dw C26178  ;(50% HP bonus)   (HP due to X)
      : dw C26170  ;(~10% MP bonus)  (MP due to X)
      : dw C26174  ;(~30% MP bonus)  (MP due to X)
      : dw C26178  ;(50% MP bonus)   (MP due to X)
      : dw C261B0  ;(Double natural HP gain for level.  Curious...)
      : dw C26197  ;(No bonus)
      : dw C26197  ;(No bonus)
      : dw C2619B  ;(Vigor bonus)    (+1 due to X value in caller)
      : dw C2619B  ;(Vigor bonus)    (+2 due to X)
      : dw C2619A  ;(Speed bonus)    (+1 due to X)
      : dw C2619A  ;(Speed bonus)    (+2 due to X.  No Esper currently uses)
      : dw C26199  ;(Stamina bonus)  (+1 due to X)
      : dw C26199  ;(Stamina bonus)  (+2 due to X)
      : dw C26198  ;(MagPwr bonus)   (+1 due to X)
      : dw C26198  ;(MagPwr bonus)   (+2 due to X)


;Esper HP or MP bonus at level-up

C26170:  LDA #$1A       ;26 => 10.15625% bonus
         BRA C2617A
C26174:  LDA #$4E       ;78 => 30.46875% bonus
         BRA C2617A
C26178:  LDA #$80       ;128 ==> 50% bonus
C2617A:  CPX #$0006     ;are we boosting MP rather than HP?
         LDX #$0000     ;start pointing to $FC, which holds normal HP to raise
         BCC C26184     ;if X was less than 6, we're just boosting HP,
                        ;so branch
         INX
         INX            ;point to $FE, which holds normal MP to raise
C26184:  XBA            ;put boost numerator in top of A
         LDA $FC,X      ;get current HP or MP to add
         JSR C24781
         XBA            ;get (boost number * current HP or MP to add / 256.
                        ;after all, the boost IS a percentage..
         BNE C2618E     ;if the HP/MP bonus is nonzero, branch
         INC            ;if it was zero, be nice and give the chump one..
C2618E:  CLC
         ADC $FC,X
         STA $FC,X      ;add boost to natural HP/MP gain
         BCC C26197
         INC $FD,X      ;if bottom byte overflowed from add, boost top byte
C26197:  RTS


;Esper stat bonus at level-up.  Vigor, Speed, Stamina, or MagPwr.
; If Bit 1 of X is set, give +1 bonus.  If not, give +2.)

C26198:  INY            ;enter here = 3 INYs = point to MagPwr
C26199:  INY            ;enter here = 2 INYs = point to Stamina
C2619A:  INY            ;enter here = 1 INY  = point to Speed
C2619B:  TXA            ;enter here = 0 INYs = point to Vigor
         LSR
         LSR            ;Carry holds bit 1 of X
         TYX            ;0 to 3 value.  determines which stat will be altered
         LDA $161A,X    ;at $161A,X we have Vigor, Speed, Stamina, and MagPwr,
                        ;in that order
         INC
         BCS C261A6     ;If carry set, just give +1
         INC
C261A6:  CMP #$81       ;is stat >= 129?
         BCC C261AC
         LDA #$80       ;if so, make it 128
C261AC:  STA $161A,X    ;save updated stat
         RTS


;Give double natural HP gain for level?  Can't say I know when this happens...

C261B0:  TDC            ;Clear 16-bit A
         TAX            ;X = 0
         LDA $FC
         BRA C2618E
 

;Handle spells or abilities learned at level-up for character

C261B6:  LDX #$0000     ;point to start of Terra's magic learned at
                        ;level up block
         CMP #$00       ;is it character #0, Terra?
         BEQ C261FC     ;if yes, branch to see if she learns any spells
         LDX #$0020     ;point to start of Celes' magic learned at
                        ;level up block
         CMP #$06       ;is it character #6, Celes?
         BEQ C261FC     ;if yes, branch to see if she learns any spells
         LDX #$0000     ;point to start of Cyan's SwdTechs learned
                        ;at level up block
         CMP #$02       ;if it character #2, Cyan?
         BNE C261E0     ;if not, check for Sabin


;Cyan learning SwdTechs at level up.
; His data block is just an array of 8 bytes: the level for learning each SwdTech)

         JSR C26222     ;are any SwdTechs learned at the current level?
         BEQ C26221     ;if not, exit
         TSB $1CF7      ;if so, enable the newly learnt SwdTech
         BNE C26221     ;if it was already enabled [e.g. Cleave learned
                        ;in nightmare], suppress celebratory messages
                        ;and such
         LDA #$40
         TSB $F0
         BNE C26221     ;branch if we already learned another SwdTech
                        ;this battle; possible with multiple level-ups.
         LDA #$42
         JMP C25FD4     ;buffer and display "Mastered a new technique!"
                        ;message


;Sabin learning Blitzes at level up.
; His data block is just an array of 8 bytes: the level for learning each Blitz)

C261E0:  LDX #$0008     ;point to start of Sabin's Blitzes learned
                        ;at level up block
         CMP #$05       ;is it character #5, Sabin?
         BNE C26221     ;if not, exit
         JSR C26222     ;are any Blitzes learned at the current level?
         BEQ C26221     ;if not, exit
         TSB $1D28      ;if so, enable the newly learnt Blitz
         BNE C26221     ;if it was already enabled [e.g. Bum Rush taught
                        ;by Duncan], suppress celebratory messages
                        ;and such
         LDA #$80
         TSB $F0
         BNE C26221     ;branch if we already learned another Blitz
                        ;this battle; possible with multiple level-ups.
         LDA #$33
         JMP C25FD4     ;buffer and display "Devised a new Blitz!"
                        ;message


;Terra and Celes natural magic learning at level up

C261FC:  PHY
         XBA
         LDY #$0010     ;check a total of 32 bytes, as Terra and Celes
                        ;each have a 16-element spell list, with
                        ;2 bytes per element [spell #, then level]
C26201:  CMP $ECE3C1,X  ;Terra/Celes level-up spell list: Level at
                        ;which spell learned
         BNE C2621B     ;if this level isn't one where the character
                        ;learns a spell, branch to check the next
                        ;list element
         PHA            ;Put on stack
         PHY
         TDC            ;Clear 16-bit A
         LDA $ECE3C0,X  ;Terra/Celes level-up spell list: Spell number
         TAY
         LDA ($F4),Y    ;check spell's learning progress
         CMP #$FF
         BEQ C26219     ;branch if it's already known
         LDA #$80
         STA ($F4),Y    ;set it as just learned
C26219:  PLY
         PLA
C2621B:  INX
         INX            ;check next spell and level pair
         DEY
         BNE C26201
         PLY
C26221:  RTS


;Handles Sabin's Blitzes learned or Cyan's SwdTechs learned, depending on X value

C26222:  LDA #$01
         STA $EE        ;start by marking SwdTech/Blitz #0
         XBA            ;get current level from top of A?
C26227:  CMP $E6F490,X  ;does level match the one in the SwdTech/Blitz
                        ;table?
         BEQ C26232     ;if so, branch
         INX            ;otherwise, move to check next level
         ASL $EE        ;mark the next SwdTech/Blitz as learned instead
         BCC C26227     ;loop for all 8 bits.  if Carry is set, we've
                        ;checked all 8 to no avail, and $EE will be 0,
                        ;indicating no SwdTech or Blitz is learned
C26232:  LDA $EE        ;get the SwdTech/Blitz bitfield.. where the number
                        ;of the bit that is set represents the number of
                        ;the SwdTech/Blitz to learn
         RTS


;Add Experience for battle to character
;If XP over 15,000,000 sets XP to 15,000,000

C26235:  PHP
         REP #$21
         LDA $2F35      ;XP Gained from battle
         ADC $1611,X    ;Add to XP for character
         STA $F6
         SEP #$20       ;Set 8-bit Accumulator
         LDA $2F37      ;Do third byte of XP
         ADC $1613,X
         STA $F8
         PHX
         LDX #$0002     ;The following loops will compare the character's
                        ;new Experience (held in $F6 - $F8 to 15000000, and
                        ;if it exceeds that amount, cap it at 15000000.
C2624E:  LDA C26276,X 
         CMP $F6,X
         BEQ C26264
         BCS C26267
         LDX #$0002
C2625B:  LDA C26276,X 
         STA $F6,X
         DEX
         BPL C2625B
C26264:  DEX
         BPL C2624E
C26267:  PLX
         LDA $F8
         STA $1613,X    ;store to third persistent byte of XP
         REP #$20
         LDA $F6
         STA $1611,X    ;store to bottom two bytes of XP
         PLP
         RTS


;Data (Experience cap: 15000000

C26276: db $C0
      : db $E1
      : db $E4

;Add item in $2E72 - $2E76 buffer to Item menu

C26279:  LDA #$05
         JSR C26411     ;copy $2E72-$2E76 buffer to a $602D-$6031
                        ;[plus offset] buffer
         LDA #$0A
         JMP C26411     ;copy $602D-$6031 buffer to Item menu


;Stores address for spells known by character in $F4

C26283:  PHP
         XBA
         LDA #$36
         JSR C24781
         REP #$21
         ADC #$1A6E
         STA $F4
         PLP
         RTS


;Multiply A by #$0B and store in X

C26293:  XBA
         LDA #$0B
         JSR C24781
         TAX
         RTS


;Copy $3A28-$3A2B variables into ($76) buffer

C2629B:  STA $3A28
C2629E:  PHA            ;Put on stack
         PHX
         PHP
         REP #$20       ;Set 16-bit Accumulator
         SEP #$10       ;Set 8-bit Index Registers
         LDX $3A72      ;X = animation buffer pointer
         LDA $3A28      ;temporary bytes 1 and 2 for animation buffer
         STA $2D6E,X    ;copy to buffer
         LDA $3A2A      ;temporary bytes 3 and 4 for animation buffer
         STA $2D70,X    ;copy to buffer
         INX
         INX
         INX
         INX
         STX $3A72      ;increase animation buffer pointer by 4
         PLP
         PLX
         PLA
         RTS


;??? Function
;Calls 629B, setting the accumulator to 16-bit before.

C262BF:  PHP
         REP #$20       ;Set 16-bit Accumulator
         JSR C2629B
         PLP
         RTS


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

C262C7:  LDX #$06
C262C9:  LDA $3018,X
         TRB $3A8C      ;clear this character's "add my items to inventory"
                        ;flag
         BEQ C262EA     ;if it wasn't set, then skip this character
         LDA $32F4,X
         CMP #$FF       ;does this character have a valid item to add to
                        ;inventory?
         BEQ C262EA     ;branch if not
         JSR C254DC     ;copy item's info to a 5-byte buffer, spanning
                        ;$2E72 - $2E76
         LDA #$01
         STA $2E75      ;indicate quantity of 1 item being added/restored
         LDA #$05
         JSR C26411     ;copy $2E72-$2E76 buffer to a $602D-$6031 buffer.
                        ;latter buffer gets copied to Item menu:
                        ;- if at end of battle, by C2/492E
                        ;- if mid-battle, apparently by having triangle
                        ;  cursor switch to different character
         LDA #$FF
         STA $32F4,X    ;null the item to add to inventory
C262EA:  DEX
         DEX
         BPL C262C9     ;iterate for all 4 party members
         RTS


;Call C2/12F5 to do actual damage/healing at the end of a "strike", then queue
; damage and/or healing values for display.  Note that -1 (FFFFh) in a Damage
; Taken/Healed variable means the damage taken or healed is nonexistent and won't
; be displayed, as opposed to a displayable 0.)

C262EF:  PHX
         PHY
         STZ $F0        ;zero number of damaged or healed entities
         STZ $F2        ;zero number of entities both damaged and healed
         LDY #$12
C262F7:  LDA $33D0,Y    ;Damage Taken
         CMP $33E4,Y    ;Damage Healed
         BNE C26302
         INC
         BEQ C26345     ;Branch if Damage Taken and Damage Healed are
                        ;both nonexistent
C26302:  LDA $3018,Y
         TRB $3A5A      ;Target is not missed
                        ;how can we have a target who's both missed
                        ;and being damaged/healed going into this
                        ;function, you ask?  it could be from Launcher
                        ;firing multiple missiles at a single target.
                        ;or it could be from spread-aiming a spell at
                        ;a Reflective group, and multiple reflections
                        ;coming back at a single target.
         JSR C212F5     ;Do the HP or MP Damage/Healing to entity
         CPY $3A82      ;Check if target protected by Golem
         BNE C26323     ;Branch if not ^
         LDA $33D0,Y    ;Damage Taken
         INC
         BEQ C26323     ;branch if Damage Taken is nonexistent, but
                        ;there is Damage Healed
         SEC
         LDA $3A36      ;HP for Golem
         SBC $33D0,Y    ;Subtract damage
         BCS C26320     ;branch if >= 0
         TDC
C26320:  STA $3A36      ;Set to 0 if < 0
C26323:  LDA $33E4,Y    ;Damage Healed
         INC
         BEQ C26345     ;Branch if Damage Healed nonexistent
         DEC
         ORA #$8000
         STA $33E4,Y    ;Set "sign bit" in Damage Healed
         INC $F2        ;increment count of targets with both damage done and
                        ;damage healed
         LDA $33D0,Y
         INC
         BNE C26345     ;Branch if there is Damage Taken
         DEC $F2        ;damage was healed but not done, so undo incrementation
                        ;done for this target

         LDA $33E4,Y
         STA $33D0,Y    ;If only Damage Healed, Damage Taken = - Damage Healed
         TDC
         DEC
         STA $33E4,Y    ;Store -1 in Damage Healed
C26345:  LDA $3018,Y
         BIT $3A5A
         BEQ C26353     ;branch if target is not missed
         LDA #$4000
         STA $33D0,Y    ;Store Miss bit in damage
C26353:  LDA $33D0,Y
         INC
         BEQ C2635B     ;If no damage dealt and/or damage healed
         INC $F0        ;increment count of targets with damage dealt or healed
C2635B:  DEY
         DEY
         BPL C262F7
         LDY $F0        ;how many targets have damage dealt and/or damage
                        ;healed
         CPY #$05
         JSR C26398     ;set up display for < 5 targets damaged or healed
         JSR C263B4     ;OR for >= 5 targets damaged or healed
         LDA $F2
         BEQ C26387     ;if no target had both damage healed and damage done,
                        ;branch
         LDX #$12
         LDY #$00
C26371:  LDA $33E4,X    ;Damage Healed
         STA $33D0,X    ;Store in Damage Taken
         INC
         BEQ C2637B     ;If no damage dealt
         INY            ;how many targets have [2nd round of] damage dealt?
C2637B:  DEX
         DEX
         BPL C26371
         CPY #$05
         JSR C26398     ;set up display for < 5 targets damaged or healed
         JSR C263B4     ;OR for >= 5 targets damaged or healed
C26387:  TDC
         DEC
         LDX #$12
C2638B:  STA $33E4,X    ;Store -1 in Damage Healed
         STA $33D0,X    ;Store -1 in Damage Taken
         DEX
         DEX
         BPL C2638B     ;null out damage for all onscreen targets
         PLY
         PLX
         RTS


;For less than 5 targets damaged or healed, use a "cascading" damage display.
; One target's damage/healing numbers will show up a split second after the other's.)

C26398:  BCS C263B3     ;Exit function if 5+ targets have damage dealt?
                        ;Why the hell not branch to C2/63B4, cut the BCC there,
                        ;and cut the "JSR C263B4"s out of function C2/62EF?
         LDX #$12
C2639C:  LDA $33D0,X    ;Damage Taken
         INC
         BEQ C263AF     ;branch if no damage
         DEC
         STA $3A2A      ;temporary bytes 3 and 4 for ($76) animation buffer
         TXA
         LSR            ;Acc = 0-9 target #
         XBA
         ORA #$000B     ;target # in top of A, 0x0B in bottom?
         JSR C2629B     ;Copy A to $3A28-$3A29, and copy $3A28-$3A2B variables
                        ;into ($76) buffer
C263AF:  DEX
         DEX
         BPL C2639C     ;loop for all onscreen targets
C263B3:  RTS            ;if < 5 targets have damage dealt, Carry will always
                        ;be clear here.  either we skipped the LSR above, or
                        ;it was done on an even number.


;For 5+ targets damaged or healed, have all their damage/healing numbers pop up
; simultaneously.)

C263B4:  BCC C263DA     ;exit function if less than 5 targets have damage
                        ;dealt?
         PHP
         SEP #$20       ;Set 8-bit Accumulator
         LDA #$03
         JSR C2629B     ;Copy A to $3A28, and copy $3A28-$3A2B variables into
                        ;($76) buffer
         LDA $3A34      ;get simultaneous damage display buffer index?
         INC $3A34      ;advance for next strike
         XBA
         LDA #$14       ;A = old index * 20
         JSR C24781
         REP #$31       ;Set 16-bit Accumulator, 16-bit X and Y, clear Carry
         ADC #$2BCE     ;add to address of start of buffer
         TAY
         LDX #$33D0
         LDA #$0013
         MVN $7E7E    ;copy $33D0 thru $33E3, the damage variables for all
                        ;10 targets, to some other memory location
         PLP
C263DA:  RTS


;Copy 8 words (16 bytes) from $A0 to ;$78) buffer, ((7E:3A32) + #$2C6E)
;C1 inspection shows $2C6E to be the area where animation
; scripts are read from. Thus, $3A32 stores the beginning
; offset for the animation script.)

C263DB:  PHX
         PHY
         PHP
         SEP #$20       ;Set 8-bit A
         TDC
         LDA $3A32      ;get animation buffer pointer
         PHA            ;Put on stack
         REP #$31       ;Set 16-bit A,Y,X
         ADC #$2C6E
         TAY
         LDX #$00A0
         LDA #$000F
         MVN $7E7E
         SEP #$30       ;Set 8-bit A,Y,X
         PLA
         ADC #$10
         STA $3A32      ;increment animation buffer pointer by 16
         PLP
         PLY
         PLX
         RTS


;Zero $A0 through $AF

C26400:  PHX
         PHP
         REP #$20       ;set 16-bit accumulator
         LDX #$06
C26406:  STZ $A0,X
         STZ $A8,X      ;overall: $A0 thru $AF are zeroed out
         DEX
         DEX
         BPL C26406     ;iterate 4 times
         PLP
         PLX
         RTS


C26411:  PHX
         PHY
         PHP
         SEP #$20
         REP #$11
         PHA            ;Put on stack
         TDC
         PLA
         CMP #$02
         BNE C26425
         LDA $B1
         BMI C26429
         LDA #$02
C26425:  JSL $C10000
C26429:  PLP
         PLY
         PLX
         RTS


;Monster command script command #$FA

C2642D:  REP #$20       ;Set 16-bit accumulator
         LDA $B8        ;Byte 2 & 3
         STA $3A2A      ;store in temporary bytes 3 and 4 for ($76
                        ;animation buffer
         SEP #$20       ;Set 8-bit Accumulator
         LDA $B6        ;Byte 0
         XBA
         LDA #$14
         JMP C262BF


;Well, well, well...  it's a shame that this function is apparently
; never called.)

         REP #$20       ;Set 16-bit Accumulator
         LDA $1D55      ;get Font color from Configuration
         CMP #$7BDE     ;are Red, Green, and Blue all equal to 30?
         SEP #$20       ;Set 8-bit Accumulator
         BNE C26468     ;branch if not desired Font color
         LDA $004219    ;Joypad #1 status register
         CMP #$28       ;are Up and Select pressed, and only those?
         BNE C26468     ;branch if not
         LDA #$02
         TSB $3A96      ;set some flag
         BNE C26468     ;branch if it was already set
         LDA #$FF
         STA $B9
         LDA #$05
         STA $B8
         LDX #$00
         LDA #$24
         JSR C24E91     ;queue up something.  you tell me what.
C26468:  RTS
print "end at: ",pc
print "wrote ",bytes," bytes"

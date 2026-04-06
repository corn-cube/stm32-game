# LINK TO TEAM VIDEO
# https://

  .syntax unified
  .cpu cortex-m4
  .fpu softvfp
  .thumb
  
  .global Main
  .global SysTick_Handler
  .global EXTI0_IRQHandler

  @ Definitions are in definitions.s to keep this file "clean"
  #include "definitions.S"

  .equ    BLINK_PERIOD, 250

  .section .text
  .type Main, %function
Main:
  PUSH  {R4-R5,LR}


  @ 
  @ Prepare GPIO Port E Pin 9 for output (LED LD3)
  @ We'll blink LED LD3 (the orange LED)
  @

  @ Enable GPIO port E by enabling its clock
  LDR     R4, =RCC_AHBENR
  LDR     R5, [R4]
  ORR     R5, R5, #(0b1 << (RCC_AHBENR_GPIOEEN_BIT))
  STR     R5, [R4]

  @ Initialise the first countdown

  LDR     R4, =blink_countdown
  LDR     R5, =BLINK_PERIOD
  STR     R5, [R4]  

  @ Configure SysTick Timer to generate an interrupt every 1ms

  LDR     R4, =SCB_ICSR               @ Clear any pre-existing interrupts
  LDR     R5, =SCB_ICSR_PENDSTCLR     @
  STR     R5, [R4]                    @

  LDR     R4, =SYSTICK_CSR            @ Stop SysTick timer
  LDR     R5, =0                      @   by writing 0 to CSR
  STR     R5, [R4]                    @   CSR is the Control and Status Register
  
  LDR     R4, =SYSTICK_LOAD           @ Set SysTick LOAD for 1ms delay
  LDR     R5, =7999                   @ Assuming 8MHz clock
  STR     R5, [R4]                    @ 

  LDR     R4, =SYSTICK_VAL            @   Reset SysTick internal counter to 0
  LDR     R5, =0x1                    @     by writing any value
  STR     R5, [R4]

  LDR     R4, =SYSTICK_CSR            @   Start SysTick timer by setting CSR to 0x7
  LDR     R5, =0x7                    @     set CLKSOURCE (bit 2) to system clock (1)
  STR     R5, [R4]                    @     set TICKINT (bit 1) to 1 to enable interrupts
                                      @     set ENABLE (bit 0) to 1


  @
  @ Prepare external interrupt Line 0 (USER pushbutton)
  @ We'll count the number of times the button is pressed
  @

  @ Initialise count to zero
  LDR   R4, =button_count             @ count = 0;
  MOV   R5, #0                        @
  STR   R5, [R4]                      @

  @ Configure USER pushbutton (GPIO Port A Pin 0 on STM32F3 Discovery
  @   kit) to use the EXTI0 external interrupt signal
  @ Determined by bits 3..0 of the External Interrrupt Control
  @   Register (EXTIICR)
  LDR     R4, =SYSCFG_EXTIICR1
  LDR     R5, [R4]
  BIC     R5, R5, #0b1111
  STR     R5, [R4]

  @ Enable (unmask) interrupts on external interrupt Line0
  LDR     R4, =EXTI_IMR
  LDR     R5, [R4]
  ORR     R5, R5, #1
  STR     R5, [R4]

  @ Set falling edge detection on Line0
  LDR     R4, =EXTI_FTSR
  LDR     R5, [R4]
  ORR     R5, R5, #1
  STR     R5, [R4]

  @ Enable NVIC interrupt #6 (external interrupt Line0)
  LDR     R4, =NVIC_ISER
  MOV     R5, #(1<<6)
  STR     R5, [R4]


  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ -------- GAME Implementation -------- @@

@@@ main game



MainGame:

.LinitializeLEDS:
  @ Initialize LD3-LD10 for output
  LDR     R4, =GPIOE_MODER
  LDR     R5, [R4]
  LDR     R6, =0xFFFF0000 
  BIC     R5, R5, R6
  LDR     R6, =0x55550000 
  ORR     R5, R5, R6
  STR     R5, [R4]


  @ BL    Menu                      @ level = int_Menu()
  
  LDR   R0, =0x20004000   

  BL    PatternsToMemory          @ PatternsToMemory(level)
  
  BL    ShowPattern               @ ShowPattern(level)

  BL    Game                      @ MainGame()



  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ --------  -----------------  -------- @@
  @@ -------- Subroutine Implementation -------- @@


@@ -- @@
@ Menu
@   All lights flash to signal start of game.
@   iterate through all LEDs clockwise to signal which level to select
@   On button input, set Level to Pin-7. 
@ Parameters:
@   - None
@ Return:
@   R0: Level  
  Menu:
  PUSH {R4-R12, LR}

  @allLightsAtOnce()


  @cicrular lights representing the menu
  MOV   R12, #0                 @ int level = 0 
.LWhileLevel:                   @ while(level == 0)
  MOV   R11, #8                 @   int i = 8
.LWhilei:                       @   while (i < 16)
  CMP   R11, #16
  BGE   .LWhileLevel
  MOV   R10, #0b1             @   mask = #0b1
  LDR   R4, =GPIOE_ODR          @     LEDi = on 
  LDR   R5, [R4]
  LSL   R10, R10, R11
  ORR   R5, R10
  STR   R5, [R4] 

  LDR   R9, =1500000            @     timer = 1000000
.LWhileTimer:                   @     while(timer != = )
  SUB   R9, R9, #1              @       timer--
  CMP   R9, #0
  BGT   .LWhileTimer
  
  BIC   R5, R10                 @     LEDi = off
  STR   R5, [R4]
  ADD   R11, R11, #1            @     i++
  B     .LWhilei
  
                                @ if(buttonPressed())
  SUB   R12, R8, #7            @ return level = i - 7
.LendWhilei:
.LendWhileLevel:  

  POP {R4-R12, LR}


@@ -- @@
@ Patterns to memory 
@   Stores an array of pin number of LEDs to be turned on in RAM 
@ Parameters:
@   R1: Level 
@ Return:
@   R0: memory address to array with stored pattern  
PatternsToMemory:

  PUSH {LR, R4-R12}

  MOV   R12, #0                  @ int index = 0;
  MOV   R4, R0                   @ pattern.address = 0x20000000
  MOV   R5, R1                   @ level = level
  
  CMP   R5, #1                   @ if(level == 1)
  BNE   .LCase2 
  @   // Pattern for Level 1
  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED3
  @   index += 4
  
  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED8
  @   index += 4
  
  MOV   R6, #15
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED9
  @   index += 4
  
  MOV   R6, #0x00
  STR   R6, [R4]                 @   word.pattern[address + i] == 0x00 //end of pattern

  B     .LBreakCase

.LCase2:  @ else if(level == 2)
  @   // Pattern for Level 2
  CMP   R5, #2                   @ if(level == 2)
  BNE   .LCase3

  MOV   R6, #9  
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED3
  @   index += 4
  
  MOV   R6, #14
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED8
  @   index += 4
  
  MOV   R6, #12
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED9
  @   index += 4
  
  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4
  
  MOV   R6, #0x00
  STR   R6, [R4]                 @   word.pattern[address + i] == 0x00 //end of pattern

  B     .LBreakCase

.LCase3:  @ else if(level == 3)
  @   // Pattern for Level 3
  CMP   R5, #2                   @ if(level == 3)
  BNE   .LCase4

  MOV   R6, #14  
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED8
  @   index += 4
  
  MOV   R6, #13
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED10
  @   index += 4
  
  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4
  
  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4
  
  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4
  
  MOV   R6, #0x00
  STR   R6, [R4]                 @   word.pattern[address + i] == 0x00 //end of pattern

  B     .LBreakCase
  
.LCase4:  @ else if(level == 4)
  @   // Pattern for Level 4

  CMP   R5, #2                   @ if(level == 4)
  BNE   .LCase5

  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4
  
  
  MOV   R6, #13
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED10
  @   index += 4
  
  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4

  MOV   R6, #14  
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED8
  @   index += 4
  
  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4
  
  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4


  MOV   R6, #0x00
  STR   R6, [R4]                 @   word.pattern[address + i] == 0x00 //end of pattern

  B     .LBreakCase

.LCase5:  @ else if(level == 5)
  @   // Pattern for Level 4

  CMP   R5, #2                   @ if(level == 5)
  BNE   .LCase6

  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4

  MOV   R6, #14  
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED8
  @   index += 4

  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4
  
  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4
  
  MOV   R6, #14
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED8
  @   index += 4

  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4

  MOV   R6, #13
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED10
  @   index += 4

  
  MOV   R6, #0x00
  STR   R6, [R4]                 @   word.pattern[address + i] == 0x00 //end of pattern

  B     .LBreakCase

.LCase6:  @ else if(level == 6)
  @   // Pattern for Level 4

  CMP   R5, #2                   @ if(level == 6)
  BNE   .LCase7

  MOV   R6, #14  
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED8
  @   index += 4
  
  MOV   R6, #13
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED10
  @   index += 4
  
  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4
  
  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4
  
  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4

  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4

  MOV   R6, #9
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED3
  @   index += 4

  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4
  
  MOV   R6, #0x00
  STR   R6, [R4]                 @   word.pattern[address + i] == 0x00 //end of pattern

  B     .LBreakCase

.LCase7:  @ else if(level == 7)
  @   // Pattern for Level 4

  CMP   R5, #2                   @ if(level == 7)
  BNE   .LCase8

  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4

  MOV   R6, #14  
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED8
  @   index += 4

  MOV   R6, #15
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED6
  @   index += 4

  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4

  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4
  
  MOV   R6, #13
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED10
  @   index += 4
  
  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4
  
  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4
  
  MOV   R6, #10
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED5
  @   index += 4
  
  MOV   R6, #0x00
  STR   R6, [R4]                 @   word.pattern[address + i] == 0x00 //end of pattern

  B     .LBreakCase

.LCase8:  @ else if(level == 8)
  @   // Pattern for Level 8 
  
  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4
  
  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4
  
  MOV   R6, #13
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED10
  @   index += 4

  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4

  MOV   R6, #13
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED10
  @   index += 4

  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4

  MOV   R6, #15
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED6
  @   index += 4

  MOV   R6, #9
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED3
  @   index += 4

  MOV   R6, #8
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED4
  @   index += 4
  
  MOV   R6, #11
  STR   R6, [R4], #4             @   word.pattern[address + i] == LED7
  @   index += 4

  MOV   R6, #0x00
  STR   R6, [R4]                 @   word.pattern[address + i] == 0x00 //end of pattern

.LBreakCase:
  POP {R4-R12, PC}
@@ -- @@
@ Show Pattern
@   Itterates through pattern array to show the player what sequence they have to remember
@ Parameters:
@   R0: pattern array
@ Return:
@   - None - 
ShowPattern:
  PUSH {R4-R12, LR}

.LWhilePattern:                @ while(pattern != 0x00)
  LDR   R6, [R0], #4              
  CMP   R6, 0x00              
  BEQ   .LendWhilePattern 

  MOV   R10, #0b1             @   mask = #0b1
  LDR   R4, =GPIOE_ODR          @     LEDi = on 
  LDR   R5, [R4]
  LSL   R10, R10, R6
  ORR   R5, R10
  STR   R5, [R4] 

  LDR   R9, =1000000            @     timer = 1000000
.LWhilePatternTimer:                   @     while(timer != = )
  SUB   R9, R9, #1              @       timer--
  CMP   R9, #0
  BGT   .LWhilePatternTimer
  
  BIC   R5, R10                 @     LEDi = off
  STR   R5, [R4]
  ADD   R11, R11, #1            @     i++
  B     .LWhilePattern
.LendWhilePattern:
  POP {R4-R12, LR}


@@ -- @@
@ Game
@   Loads array with LED pins to show pattern. Each LED is on for 2 sec.
@   If the button is pressed and when the current pattern.pin in the array == pin of the currently illuminated 
@   LED, blink the green LEDs for signalling correct input, then progress through array. 
@   Otherwise call GameOver
@ Parameters:
@   R0: pattern array
@ Return:
@   Victory and program termination 

Game:
  PUSH {R4-R12, LR}
  
  MOV   R12, R0                 

.LWhileGame:                    @ while(pattern[index] != 0x00 || !gameOver )
  MOV   R11, #8                 @   int i = 8

.LWhileLEDs:                    @   while (i < 16)

  CMP   R11, #16
  BGE   .LWhileGame

@ if ( targetLED == 0x00) break;
  LDR   R6, [R0]                @ load next target LED
  CMP   R6, #0
  BEQ   .LGameOver              @ if 0x00, pattern complete

  MOV   R10, #0b1             @     mask = #0b1
  LSL   R10, R10, R11
  LDR   R4, =GPIOE_ODR           
  LDR   R5, [R4]
  ORR   R5, R5, R10
  STR   R5, [R4]                @     LED[i] = on

  LDR   R9, =1000000            @     timer = 1000000

.LWhileGameTimer:               @     while(timer != = )
  SUB   R9, R9, #1              @       timer--

  @ check button during delay
  LDR   R7, =button_flag
  LDR   R8, [R7]
  CMP   R8, #0
  BEQ   .LNoPress

  @ if button pressed
  MOV   R8, #0
  STR   R8, [R7]                

  @ compare target pin to currently lit LED pin
  CMP   R6, R11
  BEQ   .LCorrectButtonPress    @ correct press
  BL    gameOver
  B     .LGameOver              @ wrong press

.LNoPress
  CMP   R9, #0
  BGT   .LWhileGameTimer  


@ if no button pressed, turn off current LED and move on to next
  BIC   R5, R5, R10
  STR   R5, [R4]
  ADD   R11, R11, #1
  B     .LWhileLEDs


.LCorrectButtonPress:                 @     else
                                 @     {
  ADD   R0, R0, #4               @       index += 4

  BIC   R5, R5, R10              @        
  STR   R5, [R4]                 @       LED[i] = off

@ blink LEDs green
  LDR   R8, =0x8800 
  LDR   R6, [R4]
  ORR   R6, R6, R8            
  STR   R8, [R4]                 @       blinkGreenLeds()
                                 @     }
  LDR   R9, =500000              @ delay

@ makes the green LED blink once indicate a correct press 
.LGreenBlinkDelay:
  SUBS  R9, R9, #1
  BNE  .LGreenBlinkDelay

   BIC  R6, R6, R8        @ Turn off green LEDs
   STR  R6, [R4]

  @ resets the button flag
  LDR   R6, =button_flag
  MOV   R5, #0
  STR   R5, [R6]

  B     .LWhileLEDs

.LGameOver:

  POP {R4-R12, LR}



@@ -- @@
@ gameOver:
@   Turns on all red lights blinking three times and then terminates the program
@ Parameters:
@   - None -
@ Return:
@   Program termination 
gameOver:
  PUSH {R4-R12, LR}

  LDR   R4, =GPIOE_ODR           @ GPIOE output data register
  MOV   R6, #3                   @ numberOfBlinks = 3;

.LBlinkLoop:
    MOV   R10, #0b1            @ LED mask
    LSL   R10, R10, #9           @ shift to LED3/bit 9 (red/orange LED)
    LDR   R5, [R4]               @ current GPIO state
    ORR   R5, R5, R10            @ turn LED on
    STR   R5, [R4]               @ LED on

    LDR   R7, =500000            @ delay ~1s

@ on for 1 second
.DelayOn:
    SUBS  R7, R7, #1
    BNE   .DelayOn

    BIC   R5, R10                @ turn LED off
    STR   R5, [R4]

    LDR   R7, =500000            @ delay ~1s

@ off for 1 secpnd
.DelayOff:
    SUBS  R7, R7, #1
    BNE   .DelayOff

    SUBS  R6, R6, #1             @ numberOfBlinks -= 1;
    BNE   .LBlinkLoop            @ repeat if not zero

  @ turn off all LEDs at the end
  MOV  R5, #0
  STR  R5, [R4]

  POP {R4-R12, LR}


  B     End_Main
end_maingame:
  
End_Main:
  POP   {R4-R5,PC}



@
@ SysTick interrupt handler (blink LED LD3)
@
  .type  SysTick_Handler, %function
SysTick_Handler:

  PUSH  {R4, R5, LR}

  LDR   R4, =blink_countdown        @ if (countdown != 0) {
  LDR   R5, [R4]                    @
  CMP   R5, #0                      @
  BEQ   .LendIfDelay                  @

  SUB   R5, R5, #1                  @   countdown = countdown - 1;
  STR   R5, [R4]                    @
.LendIfDelay:                       @ }

  LDR     R4, =SCB_ICSR             @ Clear (acknowledge) the interrupt
  LDR     R5, =SCB_ICSR_PENDSTCLR   @
  STR     R5, [R4]                  @

  @ Return from interrupt handler
  POP  {R4, R5, PC}



@ @
@ @ External interrupt line 0 interrupt handler
@ @   (count button presses)
@ @
  .type  EXTI0_IRQHandler, %function
EXTI0_IRQHandler:

  PUSH  {R4,R5,LR}

  LDR   R4, =button_flag
  MOV   R5, #1
  STR   R5, [R4]

  LDR   R4, =EXTI_PR                @ Clear (acknowledge) the interrupt
  MOV   R5, #(1<<0)                 @
  STR   R5, [R4]                    @

  @ Return from interrupt handler
  POP  {R4,R5,PC}


  .section .data
  
button_count:
  .space  4
  
button_flag:
  .space 4
  
blink_countdown:
  .space  4

  .end

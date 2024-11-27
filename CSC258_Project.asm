.data
dummy_var:  .space 500000   # Reserve 50000 bytes for the dummy variable (adjust size as needed)
old_display_address:    .space  262144
doubledisplayaddress:   .word   0x10008000
displayaddress:     .word       0x1008a120
Board: .half    0:128   # array of 128 half words (8 bits) used for storing the board. X,Y position 0,0 
                        # is element 0. Y incemets every 8 words (8*8 = 64 bits). The top left part of the 
                        # board is 0,0
                        
                        # Piece Reference:  (RGB order and NSEW order with Y replacing G)
                        #   0 - Empty space
                        #   1 - Red Virus
                        #   2 - Yellow Virus
                        #   3 - Blue virus
                        
                        #   4 - Red Pill No connection
                        #   5 - Red Pill Connected Up
                        #   6 - Red Pill Connected Left
                        #   7 - Red Pill Connected Down
                        #   8 - Red Pill Connected Right
                        
                        #   9 - Yellow Pill No connection
                        #   10 - Yellow Pill Connected Up
                        #   11 - Yellow Pill Connected Left
                        #   12 - Yellow Pill Connected Down
                        #   13 - Yellow Pill Connected Right
                        
                        #   14 - Blue Pill No connection
                        #   15 - Blue Pill Connected Up
                        #   16 - Blue Pill Connected Left
                        #   17 - Blue Pill Connected Down
                        #   18 - Blue Pill Connected Right
                        
                        #   Higher Values should not be expected 
                        



capsule_x:          .word       0
capsule_y:          .word       0
frame_count:        .word       0
frame_speed:        .word       0
keyboard_address:   .word       0xffff0000

Score:              .word       0
Viruses:            .word       0
Red_Viruses:        .word       0
Yellow_Viruses:     .word       0
Blue_Viruses:       .word       0

animation_frame:    .word       0   
anim_frame_r:       .word       0   
anim_frame_b:       .word       0   
anim_frame_y:       .word       0   

State: .byte 0:1        # This byte tracks whether the next check should be for generate a new piece (0),
                        # deleting pieces(1), gravity movement (2), player controled movement (3)
                        # Game Over (4)
                        
capsule_type:       .byte       0
capsule_rotation:   .byte       0
next_capsule:       .byte       0   # Number refereing to which piece will be made next. Order
                                    # Can be found in the handout
.text
main:
addi $t0 $zero 1 # Temporary testing
la $t1 Board
addi $t0, $zero, 5
la $t0, displayaddress
sll $t2, $t0, 1     # Update the offset to be correct

la $t0, old_display_address
#jal Generate_Piece

# Initialize
addi $t0, $zero, 10
sw $t0, frame_count
sw $t0, frame_speed
jal Start_Of_Game_Piece

Start_Main_Loop:

# ========= Plans For The Main Loop =======
li $v0 , 32
li $a0 , 16
syscall


# Start of Loop / Delay?
# Get Player Input

jal Movement_Determiner  # Update Piece Positions
# Check if the game is over and exit
jal Draw_Graphics # Draw the new board
jal Double_Buffer
# Play secion of Music?
# Restart Loop
# Start a new game?
jal Frame_Advance       # Increment frame number

lb $t0, State
li $t1, 3
ble $t0, $t1, Start_Main_Loop


Exit:
li $v0 , 10             # Exit
syscall

Frame_Advance:
lw $t0, frame_count

beq $t0, $zero, Reset_Frame_Count
subi $t0, $t0, 1
j Frame_Advance_Return

Reset_Frame_Count:
lw $t1, frame_speed
add $t0, $t1, $zero
Frame_Advance_Return:

sw, $t0, frame_count
jr $ra  

Check_Cleared_Rows_and_Columns:

addi $sp, $sp, -4                    # Store Return Address on the stack
sw $ra, 0($sp)

sw $zero, Viruses       # Set Viruses to 0
sw $zero, Red_Viruses
sw $zero, Yellow_Viruses
sw $zero, Blue_Viruses
la $a0, Count_Viruses
jal Access_All      # Count Viruses

j Check_Rows        # Check and clear rows
Post_Check_Rows:
#j Check_Columns     # Check and clear columns
# Normalize broken pills
# Count viruses
# Add Points
j Check_Cleared_Return

Check_Rows:
li $t0, 0   # Y Position variable

Check_Rows_Start_y_Loop:
li $t1, 1   # X position variable
# Store start point, colour, length of current sequence
la $t2, Board
sll $t3, $t0, 4
add $s0, $t2, $t3       # $s0 is the start of the current sequence
jal Get_Colour_Of_Piece
add $s1, $v0, $zero     # $s1 is the colour of the piece
li $s2, 1               # $s2 is the length of the current sequence
Check_rows_start_x_loop:

la $t2, Board
sll $t3, $t0, 4
add $t2, $t2, $t3
sll $t3, $t1, 1
add $t2, $t2, $t3   # Reference to the current piece
add $a1, $t2, $zero
jal Get_Colour_Of_Piece   # Get piece and check if colour matches

beq $v0, $s1, Row_Continues# If colour matches, increment length 
j Row_Broken
Row_Continues:  # If the colour matches, increment the length
addi $s2, $s2, 1
j Check_Rows_End_X_Loop
Row_Broken:
li $t3 4    # If colour doesnt match, check if length is at least 4. If 
            # it is clear up until the current pos. then
            # reset colour to new colour and start point to new start point'
bge $s2, $t3, Prep_Clear_Row
jal Reset_Colour_and_Length
j Check_Rows_End_X_Loop


Prep_Clear_Row:
beq $s1, $zero, Prep_Clear_Row_0
add $a1, $s0, $zero
subi $a2, $t2, 2
jal Clear_Row
jal Reset_Colour_and_Length
j Check_Rows_End_X_Loop

Prep_Clear_Row_0:
jal Reset_Colour_and_Length
j Check_Rows_End_X_Loop

Check_Rows_End_X_Loop:
addi $t1, $t1, 1
li $t3, 7
ble $t1, $t3, Check_rows_start_x_loop
# After reaching the end of a row, check to see if it is at least 4, if so, clear is
li $t3 4    # If colour doesnt match, check if length is at least 4. If 
            # it is clear up until the current pos. then
            # reset colour to new colour and start point to new start point'
bge $s2, $t3, Prep_Clear_Row_Post_loop
jal Reset_Colour_and_Length
j Check_Rows_End_Y_Loop

Prep_Clear_Row_Post_loop:
beq $s1, $zero Prep_Clear_Row_Post_loop_0
add $a1, $s0, $zero
add $a2, $t2, $zero
jal Clear_Row
jal Reset_Colour_and_Length
j Check_Rows_End_Y_Loop

Prep_Clear_Row_Post_loop_0:
jal Reset_Colour_and_Length
j Check_Rows_End_Y_Loop

Check_Rows_End_Y_Loop:
addi $t0, $t0, 1
li $t2, 15
ble $t0, $t2, Check_Rows_Start_y_Loop
j Post_Check_Rows

Clear_Row:  # a1, a2 are start and end point
# Loop over the points from start point to end point
Clear_Row_Start_loop:
sh $zero, 0($a1)    # Set values to 0
beq $a1, $a2, Clear_Row_Return
addi $a1, $a1, 2
j Clear_Row_Start_loop
Clear_Row_Return:
jr $ra

Check_Columns:
# Store start point, colour, length of current sequence
# Increment position, check if colour matches
# If colour matches, increment length 
# If colour doesnt match, check if length is at least 4. If it is clear up until the current pos. then
# reset colour to new colour and start point to new start point
# After reaching the end of a column, check to see if it is at least 4, if so, clear is
Clear_column:
# Loop over the points from start point to end point
# Set values to 0

Check_Cleared_Return:
lw $ra, 0($sp)      # Read return address from the stack
addi $sp, $sp, 4
jr $ra              # Exit function

Reset_Colour_and_Length:
add $s1, $v0, $zero
li $s2, 1
jr $ra
Get_Colour_Of_Piece:    # Given $a1  as position of piece, returns the pieces colour 
                        # Should not effect anything other than $t8, $t9 
                        # Returns in $v0
lh $t8, 0($a1)
beq $t8, $zero, Colour_Zero
li $t9, 1
beq $t8, $t9, Colour_One
li $t9, 2
beq $t8, $t9, Colour_Two
li $t9, 3
beq $t8, $t9, Colour_Three
li $t9, 8
ble $t8, $t9, Colour_One
li $t9, 13
ble $t8, $t9, Colour_Two
li $t9, 18
ble $t8, $t9, Colour_Three
j Colour_Zero
Colour_Zero:
li $v0, 0
j Colour_Return
Colour_One:
li $v0, 1
j Colour_Return
Colour_Two:
li $v0, 2
j Colour_Return
Colour_Three:
li $v0, 3
j Colour_Return
Colour_Return:
jr $ra  

Count_Viruses:  # $a1 is a position, determine if it is a virus, if it is, increment the 
                # corresponding virus counts
lh $t0, 0($a1)
li $t1, 1
beq $t0, $t1, Count_Red_Virus
li $t1, 2
beq $t0, $t1, Count_Yellow_Virus
li $t1, 3
beq $t0, $t1, Count_Blue_Virus
j Count_Return

Count_Red_Virus:
lw, $t1, Red_Viruses
add $t0, $t0, $t1
sw $t0, Red_Viruses
j Count_Viruses
Count_Yellow_Virus:
lw, $t1, Yellow_Viruses
add $t0, $t0, $t1
sw $t0, Yellow_Viruses
j Count_Viruses
Count_Blue_Virus:
lw, $t1, Blue_Viruses
add $t0, $t0, $t1
sw $t0, Blue_Viruses
j Count_Viruses
Count_Virus:
lw, $t1, Viruses
add $t0, $t0, $t1
sw $t0, Viruses

Count_Return:
jr $ra


Movement_Determiner:    # Reads the state and determines what function should be called
                        # Either calling gravity, player control, clearing rows, or 
                        # generating a new piece.
                        
addi $sp, $sp, -4                    # Store Return Address on the stack
sw $ra, 0($sp)

lb $t0, State 
addi $t1, $zero, 3   
beq $t0, $t1 Movement_Player_Movement  # If it is player control, ignore the frame count

Movement_Check_Frame_Count:
lb $t0, State 
lw $t2, frame_count

beq $t2, $zero, Movement_Update_Board
j Movement_Determiner_Return

Movement_Update_Board:
beq $t0, $zero Movement_Make_piece      # Generate Piece if It is time to generate a piece
addi $t1, $zero, 1   
beq $t0, $t1 Movement_Clear_Rows        # CLear rows if it is time to clear rows
addi $t1, $zero, 2   
beq $t0, $t1 Movement_Gravity           # Step gravity if it is time to step gravity
addi $t1, $zero, 3   
beq $t0, $t1 Movement_Player_Gravity    # Step gravity after player control, but only on the piece

j Movement_Determiner_Return        # Do nothing if game over

Movement_Make_piece:
jal Generate_Piece

j Movement_Determiner_Return
Movement_Clear_Rows:
jal Check_Cleared_Rows_and_Columns
li $t0, 2
sb $t0, State
j Movement_Determiner_Return
Movement_Gravity:           # State changing for Gravity is done beforehand, so if no pice is moved the
                            # State changes
sb $zero, State

la $a0, Gravity
                        

jal Access_All
j Movement_Determiner_Return
Movement_Player_Movement:
jal Player_Movement
j Movement_Check_Frame_Count
Movement_Player_Gravity:
j respond_to_S
j Movement_Determiner_Return
Movement_Determiner_Return:
lw $ra, 0($sp)      # Read return address from the stack
addi $sp, $sp, 4
jr $ra              # Exit function









Player_Movement:    # take in keyboard input and move the player's piece.

addi $sp, $sp, -4                    # Store Return Address on the stack
sw $ra, 0($sp)


lw $t0 , keyboard_address # $t 0 = base address for keyboard
lw $t8 , 0 ( $t0 ) # Load first word from keyboard
beq $t8 , 1 , Player_Movement_keyboardinput # If first word 1 , key is pressed
j Player_Movement_Return

Player_Movement_keyboardinput : # A key is pressed
lw $t2 , 4 ( $t0 ) # Load secondword from keyboard
beq $t2 , 0x61 , respond_to_A # Check if the key a was pressed
beq $t2 , 0x64 , respond_to_D # Check if the key d was pressed
beq $t2 , 0x73 , respond_to_S # Check if the key s was pressed
beq $t2 , 0x77 , respond_to_W # Check if the key w was pressed

j Player_Movement_Return

respond_to_A:       # ascii 0x61
la $t0, Board
lw $t1, capsule_x
lw $t2, capsule_y
                    # if the Rotation is 1 or 3, check if capsule_y is 0
jal Check_If_Rotation_Is_1_Or_3
beq $s0, $zero, Respond_A_Even
j Respond_A_Odd

Respond_A_Even:
li $t3, 0
beq $t3, $t1, Player_Movement_Return

sll $t1, $t1, 1
sll $t2, $t2, 4
add $t0, $t0, $t1
add $t0, $t0, $t2           # $t0 is the position of the current pill
jal Check_Left              # If the position to the left is open, it will return to here,
                            # If not, it wont return here
                            # move the piece left
            
li $a0, -2
add $a1, $t0, $zero
jal Move_Piece_Horizontal
j Player_Movement_Return

Respond_A_Odd:
li $t3, 0
beq $t3, $t1, Player_Movement_Return

beq, $t2, $zero, Player_Movement_Return     # If y is 0, return right away
                            # if the Rotation is 1 or 3, check if the upper position is open
sll $t1, $t1, 1
sll $t2, $t2, 4
add $t0, $t0, $t1
add $t0, $t0, $t2           # $t0 is the position of the current pill
jal Check_Left
subi $t0, $t0, 16           # $t0 is now the position up and to the left
jal Check_Left
li $a0, -2
add $a1, $t0, $zero
jal Move_Piece_Vertical



j Player_Movement_Return
                    
Check_Left:         # Check if the position to the left is open
                    # Expects the value desired to be in $t0
subi $t1, $t0, 2    # take the position one to the left
lh $t2, 0($t1)      # Value at the position to the left
bgtz $t2, Player_Movement_Return
jr $ra

respond_to_D:       # ascii 0x64
la $t0, Board
lw $t1, capsule_x
lw $t2, capsule_y
                    # if the Rotation is 1 or 3, check if capsule_y is 0
jal Check_If_Rotation_Is_1_Or_3
beq $s0, $zero, Respond_D_Even
j Respond_D_Odd

Respond_D_Even:
li $t3, 6
beq $t3, $t1, Player_Movement_Return

sll $t1, $t1, 1
sll $t2, $t2, 4
add $t0, $t0, $t1
add $t0, $t0, $t2           # $t0 is the position of the current pill
addi $t0, $t0, 2
jal Check_Right             # If the position to the right is open, it will return to here,
                            # If not, it wont return here
                            # move the piece Right
subi $t0, $t0, 2            

li $a0, 2
add $a1, $t0, $zero
jal Move_Piece_Horizontal
j Player_Movement_Return

Respond_D_Odd:
li $t3, 7
beq $t3, $t1, Player_Movement_Return

beq, $t2, $zero, Player_Movement_Return     # If y is 0, return right away
                            # if the Rotation is 1 or 3, check if the upper position is open
sll $t1, $t1, 1
sll $t2, $t2, 4
add $t0, $t0, $t1
add $t0, $t0, $t2           # $t0 is the position of the current pill
jal Check_Right
subi $t0, $t0, 16           # $t0 is now the position up and to the right
jal Check_Right
li $a0, 2
add $a1, $t0, $zero
jal Move_Piece_Vertical


j Player_Movement_Return
                    
Check_Right:         # Check if the position to the right is open
                    # Expects the value desired to be in $t0
addi $t1, $t0, 2    # take the position one to the right
lh $t2, 0($t1)      # Value at the position to the right. Offset additionall 2 to account for widepill
bgtz $t2, Player_Movement_Return
jr $ra



respond_to_S:       # ascii 0x73 ============================================================
la $t0, Board
lw $t1, capsule_x
lw $t2, capsule_y

sll $t1, $t1, 1
sll $t2, $t2, 4
add $t0, $t0, $t1
add $t0, $t0, $t2       # $t0 is the position of the current pill
                    # if the Rotation is 1 or 3, check if capsule_y is 0
jal Check_If_Rotation_Is_1_Or_3
beq $s0, $zero, Respond_S_Even
j Respond_S_Odd

Respond_S_Even:

add $a1, $t0, $zero
jal Gravity                 # Call gravity on the piece, and check if state is set. If it is, reset it 
                            # back to player controled. If state is 0, dont change it
lb $t0, State
li $t1, 2
bne, $t0, $t1, Respond_S_Failed
li $t1, 3
sb, $t1, State
lw $t0, capsule_y
addi $t0, $t0, 1
sw $t0, capsule_y
j Player_Movement_Return

Respond_S_Odd:
add $a1, $t0, $zero
jal Gravity                 # Call gravity on the piece, and check if state is set. If it is, reset it 
                            # back to player controled. If state is 0, dont change it
subi $a1, $a1, 16
jal Gravity

lb $t0, State
li $t1, 2
bne, $t0, $t1, Respond_S_Failed
li $t1, 3
sb, $t1, State
lw $t0, capsule_y
addi $t0, $t0, 1
sw $t0, capsule_y
j Player_Movement_Return

Respond_S_Failed:
li $t0, 1
sb, $t0, State
j Player_Movement_Return


respond_to_W:       # ascii 0x77 ======================================================================
                    # This should rotate the piece and increment the rotation state
la $t0, Board
lw $t1, capsule_x
lw $t2, capsule_y

jal Check_If_Rotation_Is_1_Or_3
beq $s0, $zero, Respond_W_Even
j Respond_W_Odd

Respond_W_Even:
                # Check if y = 0, if so return
beq $t2, $zero, Player_Movement_Return
sll $t2, $t2, 4     # Get position of above piece
sll $t1, $t1, 1
add $t2, $t2, $t1
add $t2, $t2, $t0
subi $t2, $t2, 16   # $t2 is now the position of the above piece
lh $t3, 0($t2)      # Check if the above position is empty, if it isnt, return
bne $t3, $zero, Player_Movement_Return 
lh, $t4, 16($t2)                # Read the current pieces
lh, $t5, 18($t2)
sh, $zero, 16($t2)                # Remove current piece
sh, $zero, 18($t2)

subi $t4, $t4, 1                # Subtract 1 from the left piece, and 1 from the right piece
subi $t5, $t5, 1
sh, $t4, 0($t2)                # Write the new information
sh, $t5, 16($t2)

j Increment_Rotation

Increment_Rotation:
lb $t0, capsule_rotation    # Increment rotation
addi $t0, $t0, 1
li $t1, 4
bne $t0, $t1, Dont_Reset # If rotation is 4, set it to 0
sb $zero, capsule_rotation
j Player_Movement_Return
Dont_Reset:
sb $t0, capsule_rotation
j Player_Movement_Return
Respond_W_Odd:
li $t3, 7
beq $t1, $t3, Player_Movement_Return # If x= 7, return return
# Check the piece to the right, if its blocked, return
sll $t2, $t2, 4     # Get position of the piece
sll $t1, $t1, 1
add $t2, $t2, $t1
add $t2, $t2, $t0   # $t2 is now the piece 
lh $t3, 2($t2)      # Check if the right position is empty, if it isnt, return
bne $t3, $zero, Player_Movement_Return 
subi $t1, $t2, 16
lh $t4, 0($t1)      # Read the current pieces
lh $t5, 0($t2)
sh $zero, 0($t1)      # Remove the current pieces
sh $zero, 0($t2)
subi $t4, $t4, 1    # Subtract 1 from the top piece
addi $t5, $t5, 3    # Add 3 to the right piece
sh $t4, 2($t2)      # The top piece becomes the right piece
sh $t5, 0($t2)      # The bottom piece becomes the left piece
j Increment_Rotation



Player_Movement_Return:
lw $ra, 0($sp)      # Read return address from the stack
addi $sp, $sp, 4
jr $ra              # Exit function

Move_Piece_Horizontal:         # Takes input #a0, the shift to be applied to the piece, either 2, -2
                    # $a1 is the current position of the piece
lh, $t1, 0($a1)     # load the left side of the piece
lh $t2, 2($a1)
sh $zero, 0($a1)
sh $zero, 2($a1)    # Set the old position of the pice to 0

add $t0, $a1, $a0
sh $t1, 0($t0)
sh $t2, 2($t0)      # find the new position and place the piece there

li $t0, 2           # Find out which position variable to increment
beq $a0, $t0, X_Plus_One
li $t0, -2
beq $a0, $t0, X_Minus_One


X_Plus_One:
lw $t0, capsule_x
addi $t0,$t0, 1
sw $t0, capsule_x
j Move_Piece_Return
X_Minus_One:
lw $t0, capsule_x
subi $t0,$t0, 1
sw $t0, capsule_x
j Move_Piece_Return

Move_Piece_Return:
jr $ra

Move_Piece_Vertical:         # Takes input #a0, the shift to be applied to the piece, either 2, -2
                    # $a1 is the current position of the piece

lh, $t1, 0($a1)     # load the top side of the piece
lh $t2, 16($a1)     #load the bottom side of the piece
sh $zero, 0($a1)
sh $zero, 16($a1)   # Set the old position of the pice to 0

add $t0, $a1, $a0
sh $t1, 0($t0)
sh $t2, 16($t0)      # find the new position and place the piece there

li $t0, 2           # Find out which position variable to increment
beq $a0, $t0, X_Plus_One_Vertical
li $t0, -2
beq $a0, $t0, X_Minus_One_Vertical    


X_Plus_One_Vertical:
lw $t0, capsule_x
addi $t0,$t0, 1
sw $t0, capsule_x
j Move_Piece_Vertical_Return
X_Minus_One_Vertical:
lw $t0, capsule_x
subi $t0,$t0, 1
sw $t0, capsule_x
j Move_Piece_Vertical_Return

Move_Piece_Vertical_Return:
jr $ra

Check_If_Rotation_Is_1_Or_3:   # If Rotation is 1 or 3, $s0 becomes 1, otherwise 0
                            # Modifies only $t6, $t7
lb $t6, capsule_rotation
li $t7, 1
beq $t6, $t7, Check_is_1_or_3
li $t7, 3
beq $t6, $t7, Check_is_1_or_3
j Check_not_1_or_3
Check_is_1_or_3:
li $s0, 1
j Check_Return
Check_not_1_or_3:
li $s0, 0
j Check_Return
Check_Return:
jr $ra

Start_Of_Game_Piece:    # Generate a piece and store it for start of game
li $v0 , 42
li $a0 , 0
li $a1 , 6
syscall

sb $a0, next_capsule
jr $ra  

Generate_Piece:
la $t1, Board
la $t3, Board           # Load positions to write the pieces to
addi $t3, $t3, 6        # Left Position
addi $t4, $t3, 2        # Right Position

lh $t5, 0($t3)
beq $t5, $zero, Generate_Piece_Possible
lh $t5, 0($t4)
beq $t5, $zero, Generate_Piece_Possible
j Generate_Piece_Impossible


Generate_Piece_Possible:


li $v0 , 42
li $a0 , 0
li $a1 , 6
syscall
la $t6, next_capsule        # 0x1008a237
lb $t0, next_capsule        # 0x1008a124
sb $a0, next_capsule

add $a0, $t0, $zero



add $t0, $zero, $zero       # Go to the space where a pice is made. The order is the same as the
beq $a0, $t0, Zero          # grapic in the assignment 
addi $t0, $zero, 1
beq $a0, $t0, One
addi $t0, $zero, 2
beq $a0, $t0, Two
addi $t0, $zero, 3
beq $a0, $t0, Three
addi $t0, $zero, 4
beq $a0, $t0, Four
addi $t0, $zero, 5
beq $a0, $t0, Five
# Piece Reference:  (RGB order and NSEW order with Y replacing G)
                        #   0 - Empty space
                        #   1 - Red Virus
                        #   2 - Yellow Virus
                        #   3 - Blue virus
                        
                        #   4 - Red Pill No connection
                        #   5 - Red Pill Connected Up
                        #   6 - Red Pill Connected Left
                        #   7 - Red Pill Connected Down
                        #   8 - Red Pill Connected Right
                        
                        #   9 - Yellow Pill No connection
                        #   10 - Yellow Pill Connected Up
                        #   11 - Yellow Pill Connected Left
                        #   12 - Yellow Pill Connected Down
                        #   13 - Yellow Pill Connected Right
                        
                        #   14 - Blue Pill No connection
                        #   15 - Blue Pill Connected Up
                        #   16 - Blue Pill Connected Left
                        #   17 - Blue Pill Connected Down
                        #   18 - Blue Pill Connected Right
                        
                        #   Higher Values should not be expected 
Zero:
addi $t0, $zero, 8
addi $t1, $zero, 6
J Set_Piece
One:
addi $t0, $zero, 18
addi $t1, $zero, 16
J Set_Piece
Two:
addi $t0, $zero, 13
addi $t1, $zero, 11
J Set_Piece
Three:
addi $t0, $zero, 8
addi $t1, $zero, 16
J Set_Piece
Four:
addi $t0, $zero, 8
addi $t1, $zero, 11
J Set_Piece
Five:
addi $t0, $zero, 18
addi $t1, $zero, 11
J Set_Piece
Set_Piece:
sh, $t0, 0($t3)
sh, $t1, 0($t4)

addi $t0, $zero, 3          # Store the new state. Should set player control
sb $t0, State                #

li $t0, 3                   
li $t1, 0
sw $t0, capsule_x           # Set the x, y position to the left piece of the pill
sw $t1, capsule_y
sb $a0, capsule_type
sb $zero, capsule_rotation
j Exit_Piece_Generation

Generate_Piece_Impossible:      # Set the state to game over if a piece can not be generated
li $t0, 4
sb $t0, State
j Exit_Piece_Generation

Exit_Piece_Generation:
jr $ra  


Access_All:         # Calls the given function on each element on the board. The function should take
                    # at most a single argument that is the location of the element it is being
                    # called on. Argument should come in $a0
                    # Elements are called from bottom to top
addi $sp, $sp, -4                    # Store Return Address on the stack
sw $ra, 0($sp)

addi $t0, $zero, 15      # Initialize the loop varable
addi $t1, $zero, -1   # Set Stop 
Access_All_Loop:
ble $t0, $t1, End_Access_All       # Begin Loop
sll $t2, $t0, 4        # Adjust position for the function
la $t3, Board

add $a1, $t2, $t3       # Set Parameter for the function     

# Store Varables
addi $sp, $sp, -4 # Store all important registers

sw $t0, 0($sp)
addi $sp, $sp, -4
sw $t1, 0($sp)
addi $sp, $sp, -4
sw $t2, 0($sp)
addi $sp, $sp, -4
sw $t3, 0($sp)

addi $sp, $sp, -4
sw $a0, 0($sp)

add $a3, $t0, $zero
jal Access_Row      # Call function
                    
                    # Load Variables
lw $a0, 0($sp) 
addi $sp, $sp, 4
lw $t3, 0($sp) 
addi $sp, $sp, 4
lw $t2, 0($sp) 
addi $sp, $sp, 4
lw $t1, 0($sp) 
addi $sp, $sp, 4
lw $t0, 0($sp) 
addi $sp, $sp, 4

addi $t0, $t0, -1           # Increment loop variable
j Access_All_Loop               # Loop
                    

End_Access_All:
lw $ra, 0($sp)      # Read return address from the stack
addi $sp, $sp, 4
jr $ra              # Exit function


Access_Row:         # Calls the function given on each elemen in the given row
                    # $a1 should be the address of the row to call a function on,
                    # and $a0 should be the addres of the function to call. The function should take 
                    # a single argument from $a0, which is the position to call the function on
addi $sp, $sp, -4                    # Store Return Address on the stack
sw $ra, 0($sp)

addi $t8, $a1, 0    # Load the board position into t8
addi $t0 $zero 0    # Set loop variable
addi $t1 $zero 8                # Set Stop Vairable
Access_Row_Loop_Start:
bge $t0, $t1, Access_Row_Exit   # Begin loop and check loop condition
sll $t2, $t0, 1     # Update the offset to be correct
add $t2, $t2, $t8   # Set position to read

addi $a1, $t2, 0

addi $sp, $sp, -4 # Store all important registers
sw $t0, 0($sp)
addi $sp, $sp, -4
sw $t1, 0($sp)
addi $sp, $sp, -4
sw $t2, 0($sp)
addi $sp, $sp, -4
sw $t3, 0($sp)
addi $sp, $sp, -4
sw $t8, 0($sp)
addi $sp, $sp, -4
sw $a0, 0($sp)
addi $sp, $sp, -4
sw $a1, 0($sp)
addi $sp, $sp, -4
sw $a3, 0($sp)


add $a2, $t0, $zero
jalr $a0
#lh $t3, 0($t2)      # Read value from memory
#addi $t3, $t3, 1    # Increment value in memory
#sh $t3, 0($t2)      # Save to memory

lw $a3, 0($sp) 
addi $sp, $sp, 4
lw $a1, 0($sp)      # Load all registers
addi $sp, $sp, 4 
lw $a0, 0($sp) 
addi $sp, $sp, 4
lw $t8, 0($sp) 
addi $sp, $sp, 4
lw $t3, 0($sp) 
addi $sp, $sp, 4
lw $t2, 0($sp) 
addi $sp, $sp, 4
lw $t1, 0($sp) 
addi $sp, $sp, 4
lw $t0, 0($sp) 
addi $sp, $sp, 4

addi $t0, $t0, 1    #Increment Loop Variable
j Access_Row_Loop_Start # Restart loop
Access_Row_Exit:
lw $ra, 0($sp)      # Read return address from the stack
addi $sp, $sp, 4
jr $ra # Exit function

Add:
# Add one to the value in the memory address in $a1

la $t0, Board
sub $t1, $a1, $t0   
addi $t2, $zero, 0xf0 # Does something different to the bottom row
bge $t1, $t2, Skip


lh $t3, 0($a1) 
addi $t3, $t3, 3
sh $t3, 0($a1) 
Skip:
jr $ra


Gravity:                # Single argument $a1. Determine if the piece at the position should move down
                        # and move it if it should be. If the piece moves, set State to 2
addi $sp, $sp, -4       # Store Return Address on the stack
sw $ra, 0($sp)

la $t0, Board
sub $t1, $a1, $t0   
addi $t2, $zero, 0xf0   # Check if we are in the bottom row, if so, return
bge $t1, $t2, Gravity_Return




lh $t0, 0($a1)              # $t0 is the value at the position we care about
addi $t1, $zero, 3

ble $t0, $t1, Gravity_Return    # Check if the value at the position is <= 3, if so, return
addi $t8, $zero, 1
sll $t8, $t8, 4
add $t8, $t8, $a1           # $t8 is the position of the piece below
lh $t9, 0($t8)              # $t9 is The value of the position below
bgtz $t9, Gravity_Return    # Check if the value at the position below it is > 0, if so, return.
# Check if the value is 6, 8, 11, 13, 16, 18
addi $t2, $zero, 6
beq $t0, $t2, Gravity_Right
addi $t2, $zero, 11
beq $t0, $t2, Gravity_Right
addi $t2, $zero, 16
beq $t0, $t2, Gravity_Right
addi $t2, $zero, 8
beq $t0, $t2, Gravity_Left
addi $t2, $zero, 13
beq $t0, $t2, Gravity_Left
addi $t2, $zero, 18
beq $t0, $t2, Gravity_Left
j Shift_Down
# If the value is 6, 11, 16, check the position to the right and down. If it is >0, return
Gravity_Left:
addi $t5, $zero, 1
sll $t5, $t5, 4
addi $t5,$t5, 2
add $t3, $t5, $a1 # $t3 is the position we care about
lh $t4, 0($t3)      # $t4 is the value we care about

bgtz $t4, Gravity_Return
j Shift_Down_Double
# If the value is 8, 13, 18, check the value at the position tot he left and down, if >0, return
Gravity_Right:

j Gravity_Return
Shift_Down_Double:
lh $t1, 2($a1)
sh $t0, 0($t8)      # Set the piece at the position below to the same as the current piece.
sh $t1, 2($t8)
sh $zero, 0($a1) 
sh $zero, 2($a1)
                    # Set the state back to 2 to continue gravity
addi $t0, $zero, 2
sb $t0, State
j Gravity_Return
Shift_Down:
sh $t0, 0($t8)      # Set the piece at the position below to the same as the current piece.
sh $zero, 0($a1)       # Set the piece at the current position to 0

                    # Set the state back to 2 to continue gravity
addi $t0, $zero, 2
sb $t0, State
# Return
Gravity_Return:
lw $ra, 0($sp)      # Read return address from the stack
addi $sp, $sp, 4
jr $ra              # Exit function

Double_Buffer:      # ----------------------$$$$$$-----------------------------------------------------
                    # Loop through every element in the display and copy it to the double buffer

lw $t0, displayaddress
lw $t1, doubledisplayaddress
addi $t5, $t0, 262144
Start_Double_Buffer_Loop:
lw $t2, 0($t0)
sw $t2, 0($t1)
addi $t0, $t0, 4
addi $t1, $t1, 4
bne $t5, $t0, Start_Double_Buffer_Loop


jr $ra
# ...
########################################
### First, I'll draw the square grid ###
########################################

Draw_Graphics:

addi $sp, $sp, -4                    # Store Return Address on the stack
sw $ra, 0($sp)
#$s1 - $s7 will store the colours
li $s1, 0x321e96 # indigo, RGB 50, 30, 150
li $s2, 0xc5d6b6 # white, RGB 197, 214, 182
li $s3, 0xde126a # magenta, RGB 222, 18, 106
li $s4, 0xe6a015 # yellow, RGB 230, 160, 21
li $s5, 0x14bab7 # cyan, 20, 186, 183
li $s6, 0xe3b19a # beige, RGB 227, 177, 154

# Set up the parameters for the rectangle drawing function
add $a0, $zero, $zero          # Set the X coordinate for the top left corner of the rectangle (in pixels)
add $a1, $zero, $zero         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
li $t9, 0                   # Increment value
add $t8, $zero, $s1         # Grid colour

repeat_row:                 # Repeats checkerboard pattern across odd numbered rows 
jal draw_grid_row

new_row:                    # Creates a new row 4 pixel below the previous
add $a0, $zero, $zero
addi $t9, $t9, 16
add $a1, $t9, $zero 
j repeat_row
repeat_end:


draw_grid_row:              # Creates a row for the checkerboard pattern background
bge $a1, 256, start_shift  # Once all the normal row are made, a similar process is started for even numbered rows with the pattern shifted 
beq $a0, 256, new_row     # Create a new row once the X position reaches 60
jal draw_rect

addi $a0, $a0, 16
add $a1, $t9, $zero 
j draw_grid_row

#########################Shifted grid#################################

start_shift:
addi $a0, $zero, 8          # Set the X coordinate diagonal to the top left square
addi $a1, $zero, 8         # Set the Y coordinate diagonal to the top left square
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
li $t9, 0

repeat_shift:
jal shift_grid_row

new_shift:
addi $a0, $zero, 8
addi $t9, $t9, 16
addi $a1, $t9, 8
j repeat_shift
shift_end:
j draw_score_board

shift_grid_row:
bge $a1, 256, shift_end
jal draw_rect

bge $a0, 248, new_shift     
addi $a0, $a0, 16
addi $a1, $t9, 8 
j shift_grid_row

#################################
### Second, I'll make the jar ###
#################################
main_jar_start:             # Creating the rectangular "Play Area" inside the jar
addi $a0, $zero, 96         # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 72         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 64          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 128          # Set the height of the rectangle (in pixels)
add $t8, $zero, $zero

jal draw_rect
# Creating the mouth of the jar
addi $a0, $zero, 120          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 56         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 16          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 64         # Set the height of the rectangle (in pixels)
add $t8, $zero, $zero

jal draw_rect
# Creating the very top of the jar 
addi $a0, $zero, 112          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 40         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 32          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 16         # Set the height of the rectangle (in pixels)
add $t8, $zero, $zero

jal draw_rect
main_jar_end:
jal jar_wall_start

############################### Actual Jar ########################################

jar_wall_start:             # Creating the walls around the "Play Area" 
addi $a0, $zero, 88         # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 72         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
add $t8, $zero, $s5
li $t7, 0

jal vertical_start
wall_end:
j b_wall_start
# Creating the various wall outside the jar
vertical_start: 
jal draw_rect
bge $a1, 200, vertical_start_end
addi $t7, $t7, 8
addi $a1, $t7, 72
j vertical_start
vertical_start_end:
addi $a0, $zero, 160
addi $a1, $zero, 72
li $t7, 0
j vertical_two

vertical_two:
jal draw_rect
beq $a1, 200, vertical_end
addi $t7, $t7, 8
addi $a1, $t7, 72
j vertical_two
vertical_end:
addi $a0, $zero, 88
addi $a1, $zero, 200
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
li $t7, 0

bottom_wall:
jal draw_rect
bge $a0, 160, bottom_end
addi $t7, $t7, 8
li $a1, 200
addi $a0, $t7, 88
j bottom_wall
bottom_end:
addi $a0, $zero, 104          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 36         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 4          # Set the height of the rectangle (in pixels)
li $t7, 0

top_start:
jal draw_rect
beq $a0, 144, top_end
addi $t7, $t7, 8
li $a1, 36
addi $a0, $t7, 104
j top_start
top_end:
addi $a0, $zero, 88          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 64         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
li $t7, 0

top_two:                    # The left shoulder (horivontal) of the bottle 
jal draw_rect
bge $a0, 108, top_two_end
addi $t7, $t7, 8
li $a1, 64
addi $a0, $t7, 88
j top_two
top_two_end:
addi $a0, $zero, 136          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 64         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
li $t7, 0

top_three:                   # The right shoulder (horivontal) of the bottle
jal draw_rect
beq $a0, 160, top_three_end
addi $t7, $t7, 8
li $a1, 64
addi $a0, $t7, 136
j top_three
top_three_end:
addi $a0, $zero, 104          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 40         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
li $t7, 0

rmouth_start:
jal draw_rect
beq $a1, 56, rmouth_end
addi $t7, $t7, 8
addi $a1, $t7, 40
j rmouth_start
rmouth_end:
addi $a0, $zero, 112          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 48         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

rrmouth_start:
jal draw_rect
beq $a1, 68, rrmouth_end
addi $t7, $t7, 2
addi $a1, $t7, 48
j rrmouth_start
rrmouth_end:
addi $a0, $zero, 144          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 40         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

lmouth_start:
jal draw_rect
beq $a1, 56, lmouth_end
addi $t7, $t7, 8
addi $a1, $t7, 40
j lmouth_start
lmouth_end:
addi $a0, $zero, 136          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 48         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

lrmouth_start:
jal draw_rect
beq $a1, 68, wall_end
addi $t7, $t7, 2
addi $a1, $t7, 48
j lrmouth_start
lrmouth_end:

#################################### Detailing Jar #######################################################

b_wall_start:             # Creating the details of walls around the "Play Area" 
addi $a0, $zero, 89         # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 71         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 6          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
add $t8, $zero, $0
li $t7, 0

jal b_vertical_start
b_wall_end:
j i_wall_start
# Creating the various wall outside the jar
b_vertical_start: 
jal draw_rect
bge $a1, 201, b_vertical_start_end
addi $t7, $t7, 3
addi $a1, $t7, 72
j b_vertical_start
b_vertical_start_end:
addi $a0, $zero, 161
addi $a1, $zero, 71
li $t7, 0
j b_vertical_two

b_vertical_two:
jal draw_rect
bge $a1, 201, b_vertical_end
addi $t7, $t7, 3
addi $a1, $t7, 72
j b_vertical_two
b_vertical_end:
addi $a0, $zero, 89
addi $a1, $zero, 201
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 6          # Set the height of the rectangle (in pixels)
li $t7, 0

b_bottom_wall:
jal draw_rect
bge $a0, 159, b_bottom_end
addi $t7, $t7, 1
li $a1, 201
addi $a0, $t7, 88
j b_bottom_wall
b_bottom_end:
addi $a0, $zero, 105          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 37         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 2          # Set the height of the rectangle (in pixels)
li $t7, 0

b_top_start:
jal draw_rect
beq $a0, 143, b_top_end
addi $t7, $t7, 1
li $a1, 37
addi $a0, $t7, 104
j b_top_start
b_top_end:
addi $a0, $zero, 89          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 65         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 6          # Set the height of the rectangle (in pixels)
li $t7, 0

b_top_two:                    # The left shoulder (horivontal) of the bottle 
jal draw_rect
bge $a0, 111, b_top_two_end
addi $t7, $t7, 1
li $a1, 65
addi $a0, $t7, 88
j b_top_two
b_top_two_end:
addi $a0, $zero, 137          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 65        # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 6          # Set the height of the rectangle (in pixels)
li $t7, 0

b_top_three:                   # The right shoulder (horivontal) of the bottle
jal draw_rect
beq $a0, 159, b_top_three_end
addi $t7, $t7, 1
li $a1, 65
addi $a0, $t7, 136
j b_top_three
b_top_three_end:
addi $a0, $zero, 105          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 39         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 6          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
li $t7, 0

b_rmouth_start:
jal draw_rect
beq $a1, 55, b_rmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 39
j b_rmouth_start
b_rmouth_end:
addi $a0, $zero, 113          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

b_rrmouth_start:
jal draw_rect
beq $a1, 67, b_rrmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 49
j b_rrmouth_start
b_rrmouth_end:
addi $a0, $zero, 145          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 39         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

b_lmouth_start:
jal draw_rect
beq $a1, 55, b_lmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 39
j b_lmouth_start
b_lmouth_end:
addi $a0, $zero, 137          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

b_lrmouth_start:
jal draw_rect
beq $a1, 67, b_fill_start
addi $t7, $t7, 1
addi $a1, $t7, 49
j b_lrmouth_start
b_lrmouth_end:

b_fill_start:
addi $a0, $zero, 107          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a3, $zero, 6
jal draw_rect

addi $a0, $zero, 141          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a3, $zero, 6
jal draw_rect
b_fill_end:

j b_wall_end

i_wall_start:             # Creating the details of walls around the "Play Area" 
addi $a0, $zero, 90         # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 70         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 4          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
add $t8, $zero, $s1
li $t7, 0

jal i_vertical_start

# Creating the various wall outside the jar
i_vertical_start: 
jal draw_rect
bge $a1, 201, i_vertical_start_end
addi $t7, $t7, 3
addi $a1, $t7, 72
j i_vertical_start
i_vertical_start_end:
addi $a0, $zero, 162
addi $a1, $zero, 70
li $t7, 0
j i_vertical_two

i_vertical_two:
jal draw_rect
bge $a1, 201, i_vertical_end
addi $t7, $t7, 3
addi $a1, $t7, 72
j i_vertical_two
i_vertical_end:
addi $a0, $zero, 89
addi $a1, $zero, 202
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 4          # Set the height of the rectangle (in pixels)
li $t7, 0

i_bottom_wall:
jal draw_rect
bge $a0, 159, i_bottom_end
addi $t7, $t7, 1
li $a1, 202
addi $a0, $t7, 88
j i_bottom_wall
i_bottom_end:
addi $a0, $zero, 105          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 37         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 2          # Set the height of the rectangle (in pixels)
li $t7, 0

i_top_start:
jal draw_rect
beq $a0, 143, i_top_end
addi $t7, $t7, 1
li $a1, 37
addi $a0, $t7, 104
j i_top_start
i_top_end:
addi $a0, $zero, 89          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 66         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 4          # Set the height of the rectangle (in pixels)
li $t7, 0

i_top_two:                    # The left shoulder (horivontal) of the bottle 
jal draw_rect
bge $a0, 110, i_top_two_end
addi $t7, $t7, 1
li $a1, 66
addi $a0, $t7, 88
j i_top_two
i_top_two_end:
addi $a0, $zero, 138          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 66        # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 4          # Set the height of the rectangle (in pixels)
li $t7, 0

i_top_three:                   # The right shoulder (horivontal) of the bottle
jal draw_rect
beq $a0, 159, i_top_three_end
addi $t7, $t7, 1
li $a1, 66
addi $a0, $t7, 138
j i_top_three
i_top_three_end:
addi $a0, $zero, 106          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 39         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 4          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 6          # Set the height of the rectangle (in pixels)
li $t7, 0

i_rmouth_start:
jal draw_rect
beq $a1, 55, i_rmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 39
j i_rmouth_start
i_rmouth_end:
addi $a0, $zero, 114          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

i_rrmouth_start:
jal draw_rect
beq $a1, 67, i_rrmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 49
j i_rrmouth_start
i_rrmouth_end:
addi $a0, $zero, 146          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 39         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

i_lmouth_start:
jal draw_rect
beq $a1, 55, i_lmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 39
j i_lmouth_start
i_lmouth_end:
addi $a0, $zero, 138          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

i_lrmouth_start:
jal draw_rect
beq $a1, 67, fill_start
addi $t7, $t7, 1
addi $a1, $t7, 49
j i_lrmouth_start
i_lrmouth_end:

fill_start:
addi $a0, $zero, 107          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 7
addi $a3, $zero, 6
jal draw_rect

addi $a0, $zero, 141          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a3, $zero, 6
jal draw_rect

addi $a0, $zero, 141          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 5
addi $a3, $zero, 1
add $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 142          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 54         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 5
addi $a3, $zero, 1
jal draw_rect

addi $a0, $zero, 142          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 53         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 4
addi $a3, $zero, 1
add $t8, $zero, 0xbfb6f2
jal draw_rect

addi $a0, $zero, 110          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 49         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 5
addi $a3, $zero, 1
add $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 110          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 54         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect

addi $a0, $zero, 110          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 53         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 4
addi $a3, $zero, 1
add $t8, $zero, 0xbfb6f2
jal draw_rect

fill_end:

############################################ Curving Corners ##################################################
i_curves:
addi $a0, $zero, 91         
addi $a1, $zero, 67 
add $t8, $zero, 0xbfb6f2
jal s_ul_curves               # Curves upper left edges (small)
addi $a0, $zero, 90         
addi $a1, $zero, 66 
add $t8, $zero, $zero
jal ul_curves               # Curves upper left edges
addi $a0, $zero, 89         
addi $a1, $zero, 65 
add $t8, $zero, $s5
jal ul_curves               # Curves upper left edges
addi $a0, $zero, 88         
addi $a1, $zero, 64         
add $t8, $zero, $zero
jal ul_curves               # Curves upper left edges

addi $a0, $zero, 163         
addi $a1, $zero, 67 
add $t8, $zero, 0xbfb6f2
jal s_ur_curves               # Curves upper right edges (small)
addi $a0, $zero, 164          
addi $a1, $zero, 66         
add $t8, $zero, $zero
jal ur_curves               # Curves upper right edges    
addi $a0, $zero, 165          
addi $a1, $zero, 65         
add $t8, $zero, $s5
jal ur_curves               # Curves upper right edges          
addi $a0, $zero, 166          
addi $a1, $zero, 64   
add $t8, $zero, $zero
jal ur_curves               # Curves upper right edges     

addi $a0, $zero, 116
addi $a1, $zero, 50        
add $t8, $zero, $zero
jal ur_curves               # Curves upper right edges   
addi $a0, $zero, 118
addi $a1, $zero, 48        
add $t8, $zero, $zero
jal ur_curves               # Curves upper right edges    
addi $a0, $zero, 117
addi $a1, $zero, 49        
add $t8, $zero, $s5
jal ur_curves               # Curves upper right edges  

addi $a0, $zero, 138
addi $a1, $zero, 50          
add $t8, $zero, $zero
jal ul_curves               # Curves upper left edges
addi $a0, $zero, 137
addi $a1, $zero, 49          
add $t8, $zero, $s5
jal ul_curves               # Curves upper left edges
addi $a0, $zero, 136
addi $a1, $zero, 48          
add $t8, $zero, $zero
jal ul_curves               # Curves upper left edges

addi $a0, $zero, 91
addi $a1, $zero, 203         
add $t8, $zero, 0xbfb6f2
jal s_bl_curves               # Curves bottom left edges (small)
addi $a0, $zero, 90
addi $a1, $zero, 204        
add $t8, $zero, $zero
jal bl_curves               # Curves bottom left corners
addi $a0, $zero, 89
addi $a1, $zero, 205        
add $t8, $zero, $s5
jal bl_curves               # Curves bottom left corners
addi $a0, $zero, 88
addi $a1, $zero, 206        
add $t8, $zero, $zero
jal bl_curves               # Curves bottom left corners

addi $a0, $zero, 107
addi $a1, $zero, 51         
add $t8, $zero, 0xbfb6f2
jal s_bl_curves               # Curves bottom left edges (small)
addi $a0, $zero, 106
addi $a1, $zero, 52        
add $t8, $zero, $zero
jal bl_curves               # Curves bottom left corners
addi $a0, $zero, 105
addi $a1, $zero, 53        
add $t8, $zero, $s5
jal bl_curves               # Curves bottom left corners
addi $a0, $zero, 104
addi $a1, $zero, 54        
add $t8, $zero, $zero
jal bl_curves               # Curves bottom left corners

addi $a0, $zero, 163
addi $a1, $zero, 203         
add $t8, $zero, 0xbfb6f2
jal s_br_curves               # Curves bottom right edges (small)
addi $a0, $zero, 164
addi $a1, $zero, 204     
add $t8, $zero, $zero
jal br_curves               # Curves bottom right corners
addi $a0, $zero, 165
addi $a1, $zero, 205     
add $t8, $zero, $s5
jal br_curves               # Curves bottom right corners
addi $a0, $zero, 166
addi $a1, $zero, 206     
add $t8, $zero, $zero
jal br_curves               # Curves bottom right corners

addi $a0, $zero, 147
addi $a1, $zero, 51         
add $t8, $zero, 0xbfb6f2
jal s_br_curves               # Curves bottom right edges (small)
addi $a0, $zero, 148
addi $a1, $zero, 52     
add $t8, $zero, $zero
jal br_curves               # Curves bottom right corners
addi $a0, $zero, 149
addi $a1, $zero, 53     
add $t8, $zero, $s5
jal br_curves               # Curves bottom right corners
addi $a0, $zero, 150
addi $a1, $zero, 54     
add $t8, $zero, $s1
jal br_curves               # Curves bottom right corners

############################################### Highlights & Shading #######################################################

addi $a0, $zero, 90         # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 71         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 1          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)
add $t8, $zero, 0xbfb6f2
li $t7, 0

# Creating the various wall outside the jar
h_vertical_start: 
jal draw_rect
bge $a1, 200, h_vertical_start_end
addi $t7, $t7, 3
addi $a1, $t7, 72
j h_vertical_start
h_vertical_start_end:
addi $a0, $zero, 165
addi $a1, $zero, 71
li $t7, 0
j h_vertical_two

h_vertical_two:
jal draw_rect
bge $a1, 200, h_vertical_end
addi $t7, $t7, 3
addi $a1, $t7, 72
j h_vertical_two
h_vertical_end:

addi $a0, $zero, 96
addi $a1, $zero, 205
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 1          # Set the height of the rectangle (in pixels)
li $t7, 0

h_bottom_wall:
jal draw_rect
bge $a0, 152, h_bottom_end
addi $t7, $t7, 1
li $a1, 205
addi $a0, $t7, 95
j h_bottom_wall
h_bottom_end:
addi $a0, $zero, 95          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 66         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 1          # Set the height of the rectangle (in pixels)
li $t7, 0

h_top_two:                    # The left shoulder (horivontal) of the bottle 
jal draw_rect
bge $a0, 106, h_top_two_end
addi $t7, $t7, 1
li $a1, 66
addi $a0, $t7, 95
j h_top_two
h_top_two_end:
addi $a0, $zero, 142          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 66        # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 1          # Set the height of the rectangle (in pixels)
li $t7, 0

h_top_three:                   # The right shoulder (horivontal) of the bottle
jal draw_rect
beq $a0, 154, h_top_three_end
addi $t7, $t7, 1
li $a1, 66
addi $a0, $t7, 142
j h_top_three
h_top_three_end:
addi $a0, $zero, 106          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 39         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 1          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 6          # Set the height of the rectangle (in pixels)
li $t7, 0

h_rmouth_start:
jal draw_rect
beq $a1, 50, h_rmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 39
j h_rmouth_start
h_rmouth_end:
addi $a0, $zero, 114          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 54         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

h_rrmouth_start:
jal draw_rect
beq $a1, 66, h_rrmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 54
j h_rrmouth_start
h_rrmouth_end:
addi $a0, $zero, 149          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 39         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

h_lmouth_start:
jal draw_rect
beq $a1, 49, h_lmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 39
j h_lmouth_start
h_lmouth_end:
addi $a0, $zero, 141          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 54         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
li $t7, 0

h_lrmouth_start:
jal draw_rect
beq $a1, 66, h_lrmouth_end
addi $t7, $t7, 1
addi $a1, $t7, 55
j h_lrmouth_start
h_lrmouth_end:

############################################## Inside Jar ##################################################################

la $a0, Draw_Inside
jal Access_All
j end_background
Draw_Inside:
            # $a1 is a reference to the pice to be converted
            # $a2 is the x
            # $a3 is the y (bottom is higher)
            
addi $sp, $sp, -4                    # Store Return Address on the stack
sw $ra, 0($sp)

add $t5, $a1, $zero
sll $t0, $a2, 3


sll $t3, $a3, 3

addi $a0, $t0, 96

addi $t1, $zero, 72
add $a1, $t1, $t3

addi $a2, $zero, 8          # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8          # Set the height of the rectangle (in pixels)

lh $t0, 0($t5)  #Read what piece is in place to t0
li $t1, 14
bge $t0, $t1, Blue
li $t1, 9
bge $t0, $t1, Yellow
li $t1, 4
bge $t0, $t1, Red
li $t1, 3
beq $t0, $t1, Blue_Virus
li $t1, 2
beq $t0, $t1, Yellow_Virus
li $t1, 1
beq $t0, $t1, Red_Virus
li $t8, 0
j Inside_Pill_Draw_Rect
Blue_Virus:
Blue:
add $t8, $zero, $s5
j Inside_Pill_Draw_Rect
Yellow_Virus:
Yellow:
add $t8, $zero, $s4
j Inside_Pill_Draw_Rect
Red_Virus:
Red:
add $t8, $zero, $s3

Inside_Pill_Draw_Rect:
jal draw_rect

lw $ra, 0($sp)      # Read return address from the stack
addi $sp, $sp, 4
jr $ra
            #Comparisons to determine wht to draw

#######################################
### Third, I'll addd the filpboards ###
#######################################

draw_score_board:
addi $a0, $zero, 8          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 32         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 72         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 72         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $zero

jal draw_rect

addi $a0, $zero, 9          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 33         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 70         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 70         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $s4

jal draw_rect

addi $a0, $zero, 12          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 35         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 64         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 65         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $zero

jal draw_rect

addi $a0, $zero, 13          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 36         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 62         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 62         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $s2

jal draw_rect

############################################### Score Board Text ################################################### 

#Top Score text position (Actual score is 8 pixels below)
# X = 16, Y = 48
add, $t8, $zero, $zero
# Letter T
addi $a0, $zero, 17
addi $a1, $zero, 48
addi $a2, $zero, 7
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 19
addi $a1, $zero, 48
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
# Letter O
addi $a0, $zero, 26
addi $a1, $zero, 48
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 26
addi $a1, $zero, 54
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 25
addi $a1, $zero, 48
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 29
addi $a1, $zero, 48
addi $a2, $zero, 1
addi $a3, $zero, 7
jal draw_rect
# Letter P
addi $a0, $zero, 34
addi $a1, $zero, 48
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 34
addi $a1, $zero, 51
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 32
addi $a1, $zero, 48
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 37
addi $a1, $zero, 48
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect

#Score text position (Actual score is 8 pixels below)
# X = 16, Y = 72
# Letter S
addi $a0, $zero, 21
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 18
addi $a1, $zero, 72
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 18
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 18
addi $a1, $zero, 75
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 21
addi $a1, $zero, 75
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 18
addi $a1, $zero, 78
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 18
addi $a1, $zero, 77
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect

# Letter C
addi $a0, $zero, 28
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 24
addi $a1, $zero, 72
addi $a2, $zero, 5
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 24
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 24
addi $a1, $zero, 75
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 28
addi $a1, $zero, 77
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 24
addi $a1, $zero, 78
addi $a2, $zero, 5
addi $a3, $zero, 1
jal draw_rect

# Letter O
addi $a0, $zero, 32
addi $a1, $zero, 72
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 32
addi $a1, $zero, 78
addi $a2, $zero, 5
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 32
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 36
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 7
jal draw_rect

# Letter R
addi $a0, $zero, 42
addi $a1, $zero, 72
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 42
addi $a1, $zero, 75
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 40
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 45
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 43
addi $a1, $zero, 76
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 44
addi $a1, $zero, 77
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
# Letter E
addi $a0, $zero, 48
addi $a1, $zero, 72
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 48
addi $a1, $zero, 78
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 48
addi $a1, $zero, 75
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 48
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect

############################################### Second Board #######################################################

addi $a0, $zero, 176         # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 128         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 64         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 88         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 177          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 129         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 62         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 86         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 180          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 132         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 56         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 81         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 181          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 133         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 54         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 78         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $s2
jal draw_rect

############################################### Second Board Text #######################################################
# Start at X = 184, Y = 144
add, $t8, $zero, $zero
# Letter L
addi $a0, $zero, 184  
addi $a1, $zero, 144     
addi $a2, $zero, 2  
addi $a3, $zero, 7    
jal draw_rect
addi $a0, $zero, 184   
addi $a1, $zero, 150     
addi $a2, $zero, 6  
addi $a3, $zero, 1   
jal draw_rect

# Letter E
addi $a0, $zero, 192
addi $a1, $zero, 144 
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 192
addi $a1, $zero, 150
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 192
addi $a1, $zero, 147
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 192
addi $a1, $zero, 144
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect

# Letter V
addi $a0, $zero, 200 
addi $a1, $zero, 144     
addi $a2, $zero, 2  
addi $a3, $zero, 3    
jal draw_rect
addi $a0, $zero, 200 
addi $a1, $zero, 147     
addi $a2, $zero, 2  
addi $a3, $zero, 2    
jal draw_rect
addi $a0, $zero, 201 
addi $a1, $zero, 149     
addi $a2, $zero, 2  
addi $a3, $zero, 1    
jal draw_rect
addi $a0, $zero, 203 
addi $a1, $zero, 150     
addi $a2, $zero, 1  
addi $a3, $zero, 1    
jal draw_rect
addi $a0, $zero, 204 
addi $a1, $zero, 149      
addi $a2, $zero, 2  
addi $a3, $zero, 1    
jal draw_rect
addi $a0, $zero, 205 
addi $a1, $zero, 147     
addi $a2, $zero, 2  
addi $a3, $zero, 2    
jal draw_rect
addi $a0, $zero, 205 
addi $a1, $zero, 144     
addi $a2, $zero, 2  
addi $a3, $zero, 3    
jal draw_rect

# Letter E
addi $a0, $zero, 209
addi $a1, $zero, 144 
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 209
addi $a1, $zero, 150
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 209
addi $a1, $zero, 147
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 209
addi $a1, $zero, 144
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect

# Letter L
addi $a0, $zero, 217 
addi $a1, $zero, 144     
addi $a2, $zero, 2  
addi $a3, $zero, 7    
jal draw_rect
addi $a0, $zero, 217    
addi $a1, $zero, 150     
addi $a2, $zero, 6  
addi $a3, $zero, 1   
jal draw_rect

# Start at X = 184, Y = 168
# Letter S
addi $a0, $zero, 188
addi $a1, $zero, 168
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 185
addi $a1, $zero, 168
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 185
addi $a1, $zero, 168
addi $a2, $zero, 2
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 185
addi $a1, $zero, 171
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 188
addi $a1, $zero, 171
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 185
addi $a1, $zero, 174
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 185
addi $a1, $zero, 173
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect

# Letter P
addi $a0, $zero, 194
addi $a1, $zero, 168
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 194
addi $a1, $zero, 171
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 192
addi $a1, $zero, 168
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 197
addi $a1, $zero, 168
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect

# Letter E
addi $a0, $zero, 200
addi $a1, $zero, 168
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 200
addi $a1, $zero, 174
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 200
addi $a1, $zero, 171
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 200
addi $a1, $zero, 168
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect

# Letter E
addi $a0, $zero, 208
addi $a1, $zero, 168
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 208
addi $a1, $zero, 174
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 208
addi $a1, $zero, 171
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 208
addi $a1, $zero, 168
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect

# Letter D
addi $a0, $zero, 217
addi $a1, $zero, 168
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 217
addi $a1, $zero, 174
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 216
addi $a1, $zero, 168
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 220
addi $a1, $zero, 169
addi $a2, $zero, 2
addi $a3, $zero, 5
jal draw_rect

# Start at X = 184, Y = 192
# Letter V
addi $a0, $zero, 184
addi $a1, $zero, 192     
addi $a2, $zero, 2  
addi $a3, $zero, 3    
jal draw_rect
addi $a0, $zero, 184
addi $a1, $zero, 195      
addi $a2, $zero, 2  
addi $a3, $zero, 2    
jal draw_rect
addi $a0, $zero, 185 
addi $a1, $zero, 197      
addi $a2, $zero, 2  
addi $a3, $zero, 1    
jal draw_rect
addi $a0, $zero, 187
addi $a1, $zero, 198    
addi $a2, $zero, 1  
addi $a3, $zero, 1    
jal draw_rect
addi $a0, $zero, 188
addi $a1, $zero, 197     
addi $a2, $zero, 2  
addi $a3, $zero, 1    
jal draw_rect
addi $a0, $zero, 189 
addi $a1, $zero, 195    
addi $a2, $zero, 2  
addi $a3, $zero, 2    
jal draw_rect
addi $a0, $zero, 189
addi $a1, $zero, 192   
addi $a2, $zero, 2  
addi $a3, $zero, 3    
jal draw_rect

# Letter I
addi $a0, $zero, 195
addi $a1, $zero, 192   
addi $a2, $zero, 2 
addi $a3, $zero, 7   
jal draw_rect

# Letter R
addi $a0, $zero, 202
addi $a1, $zero, 192
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 202
addi $a1, $zero, 195
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 200
addi $a1, $zero, 192
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 205
addi $a1, $zero, 192
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 203
addi $a1, $zero, 196
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 204
addi $a1, $zero, 197
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect

# Letter U
addi $a0, $zero, 208
addi $a1, $zero, 192
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 213
addi $a1, $zero, 192
addi $a2, $zero, 1
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 208
addi $a1, $zero, 198
addi $a2, $zero, 5
addi $a3, $zero, 1
jal draw_rect

# Letter S
addi $a0, $zero, 220
addi $a1, $zero, 192
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 217
addi $a1, $zero, 192
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 217
addi $a1, $zero, 192
addi $a2, $zero, 2
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 217
addi $a1, $zero, 195
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 220
addi $a1, $zero, 195
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 217
addi $a1, $zero, 198
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 217
addi $a1, $zero, 197
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect

#######################################
### Fourth, I'll add the petri dish ###
#######################################

addi $a0, $zero, 8         # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 152         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
add, $t8, $zero, 0x656066
add $t7, $zero, $zero

petri_start:
beq $t8, 0x625edb, change_b
beq $t8, 0x656066, change_i

change_b:
add, $t8, $zero, 0x656066
j draw_petri

change_i:
add, $t8, $zero, 0x625edb
j draw_petri

draw_petri:
addi $a2, $zero, 8         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 8         # Set the height of the rectangle (in pixels)

addi $a1, $t7, 152 
beq $a1, 224, petri_end
beq $a0, 80, new_p_row
jal draw_rect
add $a0, $a0, 8
j petri_start

new_p_row:
beq $t8, 0x625edb, row_change_b
beq $t8, 0x656066, row_change_i

row_change_b:
add, $t8, $zero, 0x656066
j continue_row

row_change_i:
add, $t8, $zero, 0x625edb
j continue_row

continue_row:
addi $t7, $t7, 8
addi $a0, $zero, 8 
j petri_start
petri_end:

addi $a0, $zero, 7       
addi $a1, $zero, 152        
add $t8, $zero, $zero
addi $a2, $zero, 1
addi $a3, $zero, 72 
jal draw_rect 
addi $a0, $zero, 80      
addi $a1, $zero, 152        
addi $a2, $zero, 1
addi $a3, $zero, 72 
jal draw_rect 
addi $a0, $zero, 8       
addi $a1, $zero, 152        
addi $a2, $zero, 72
addi $a3, $zero, 1 
jal draw_rect 
addi $a0, $zero, 8       
addi $a1, $zero, 224        
addi $a2, $zero, 72
addi $a3, $zero, 1 
jal draw_rect 

addi $a0, $zero, 8       
addi $a1, $zero, 153        
add $t8, $zero, 0xd1c3d4
addi $a2, $zero, 1
addi $a3, $zero, 70 
jal draw_rect 
addi $a0, $zero, 79      
addi $a1, $zero, 153        
addi $a2, $zero, 1
addi $a3, $zero, 70 
jal draw_rect 
addi $a0, $zero, 8       
addi $a1, $zero, 153        
addi $a2, $zero, 72
addi $a3, $zero, 1 
jal draw_rect 
addi $a0, $zero, 8       
addi $a1, $zero, 223        
addi $a2, $zero, 72
addi $a3, $zero, 1 
jal draw_rect 

addi $a0, $zero, 9       
addi $a1, $zero, 153        
add $t8, $zero, 0xd1c3d4
jal ul_curves
addi $a0, $zero, 9        
addi $a1, $zero, 221  
jal bl_curves
addi $a0, $zero, 77         
addi $a1, $zero, 153     
jal ur_curves
addi $a0, $zero, 77         
addi $a1, $zero, 221  
jal br_curves

addi $a0, $zero, 8       
addi $a1, $zero, 152        
add $t8, $zero, $zero
jal ul_curves
addi $a0, $zero, 8        
addi $a1, $zero, 222  
jal bl_curves
addi $a0, $zero, 78         
addi $a1, $zero, 152     
jal ur_curves
addi $a0, $zero, 78         
addi $a1, $zero, 222  
jal br_curves

#########################################################
### Finally, I'll add the box for Mario and the title ###
#########################################################

addi $a0, $zero, 176         # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 56         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 64         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 64         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 177          # Set the X coordinate for the top left corner of the rectangle (in pixels)
addi $a1, $zero, 57         # Set the Y coordinate for the top left corner of the rectangle (in pixels)
addi $a2, $zero, 62         # Set the width of the rectangle (in pixels)
addi $a3, $zero, 62         # Set the height of the rectangle (in pixels)
add, $t8, $zero, $zero
jal draw_rect

#########################
### Animated Features ###
#########################
Change_Pill_Colour:
lb $s2, next_capsule
# Pill is 53 pixels long, 26 pixels wide
# Two colours
#addi $a0, $zero, 195        
#addi $a1, $zero, 61         
#addi $a2, $zero, 27         
#addi $a3, $zero, 54   
#add, $t8, $zero, $zero
#jal draw_rect
beq $s2, 0, assign_zero
beq $s2, 1, assign_one
beq $s2, 2, assign_two
beq $s2, 3, assign_three
beq $s2, 4, assign_four
beq $s2, 5, assign_five

assign_zero:
add $s6, $zero, $s3
add $s7, $zero, $s3
j draw_pill

assign_one:
add $s6, $zero, $s5
add $s7, $zero, $s5
j draw_pill

assign_two:
add $s6, $zero, $s4
add $s7, $zero, $s4
j draw_pill

assign_three:
add $s6, $zero, $s3
add $s7, $zero, $s5
j draw_pill

assign_four:
add $s6, $zero, $s3
add $s7, $zero, $s4
j draw_pill

assign_five:
add $s6, $zero, $s4
add $s7, $zero, $s5
j draw_pill

draw_pill:
addi $a0, $zero, 196        
addi $a1, $zero, 62         
addi $a2, $zero, 25         
addi $a3, $zero, 26   
add, $t8, $zero, $s6
jal draw_rect

addi $a0, $zero, 196        
addi $a1, $zero, 88         
addi $a2, $zero, 25         
addi $a3, $zero, 26   
add, $t8, $zero, $s7
jal draw_rect

################################# Shading - Pill #######################################
# Top Half
beq $s6, $s3, red_shade_top
beq $s6, $s5, blue_shade_top
beq $s6, $s4, yellow_shade_top

red_shade_top:
add, $t8, $zero, 0x990030
j begin_shade

blue_shade_top:
add, $t8, $zero, 0x324ec2
j begin_shade

yellow_shade_top:
add, $t8, $zero, 0x843eb6
j begin_shade


begin_shade:
addi $a0, $zero, 210        
addi $a1, $zero, 66         
addi $a2, $zero, 7         
addi $a3, $zero, 2   
jal draw_rect

addi $a0, $zero, 208        
addi $a1, $zero, 67         
addi $a2, $zero, 11         
addi $a3, $zero, 1   
jal draw_rect

addi $a0, $zero, 206        
addi $a1, $zero, 68         
addi $a2, $zero, 14         
addi $a3, $zero, 21   
jal draw_rect

beq $s7, $s3, red_shade_bottom
beq $s7, $s5, blue_shade_bottom
beq $s7, $s4, yellow_shade_bottom
red_shade_bottom:
add, $t8, $zero, 0x990030
j begin_shade_b

blue_shade_bottom:
add, $t8, $zero, 0x324ec2
j begin_shade_b

yellow_shade_bottom:
add, $t8, $zero, 0x843eb6
j begin_shade_b

# Bottom Half
begin_shade_b:
addi $a0, $zero, 206        
addi $a1, $zero, 88         
addi $a2, $zero, 14         
addi $a3, $zero, 20   
jal draw_rect

addi $a0, $zero, 207       
addi $a1, $zero, 108         
addi $a2, $zero, 12         
addi $a3, $zero, 1   
jal draw_rect

addi $a0, $zero, 208       
addi $a1, $zero, 109         
addi $a2, $zero, 10         
addi $a3, $zero, 1   
jal draw_rect

addi $a0, $zero, 210       
addi $a1, $zero, 110         
addi $a2, $zero, 6         
addi $a3, $zero, 1   

jal draw_rect

####################### Detailing - Pill #########################
# Top 
addi $a0, $zero, 196        
addi $a1, $zero, 62         
addi $a2, $zero, 2         
addi $a3, $zero, 3   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 196        
addi $a1, $zero, 62         
addi $a2, $zero, 5         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 219       
addi $a1, $zero, 62         
addi $a2, $zero, 3         
addi $a3, $zero, 3   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 216        
addi $a1, $zero, 62         
addi $a2, $zero, 5         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

# Middle Line - Left Side
addi $a0, $zero, 196        
addi $a1, $zero, 86         
addi $a2, $zero, 2         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 197        
addi $a1, $zero, 87         
addi $a2, $zero, 4         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 198        
addi $a1, $zero, 88         
addi $a2, $zero, 21         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

# Middle Line - Right Side
addi $a0, $zero, 219        
addi $a1, $zero, 86         
addi $a2, $zero, 2         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 216        
addi $a1, $zero, 87         
addi $a2, $zero, 4         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 220        
addi $a1, $zero, 87         
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, $s7
jal draw_rect

# Bottom
addi $a0, $zero, 196        
addi $a1, $zero, 110         
addi $a2, $zero, 2         
addi $a3, $zero, 3   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 196        
addi $a1, $zero, 113         
addi $a2, $zero, 5         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 219       
addi $a1, $zero, 110         
addi $a2, $zero, 3         
addi $a3, $zero, 3   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 216        
addi $a1, $zero, 113         
addi $a2, $zero, 5         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

################################# Highlights - Pill ####################################
beq $s6, $s3, red_high
beq $s6, $s5, blue_high
beq $s6, $s4, yellow_high

red_high:
add, $t8, $zero, 0xfd3189
j begin_high

blue_high:
add, $t8, $zero, 0x33d9d6
j begin_high

yellow_high:
add, $t8, $zero, 0xe6dbbf
j begin_high

# Top Half
begin_high:
addi $a0, $zero, 196        
addi $a1, $zero, 65         
addi $a2, $zero, 1         
addi $a3, $zero, 21   
jal draw_rect

addi $a0, $zero, 197        
addi $a1, $zero, 65         
addi $a2, $zero, 3         
addi $a3, $zero, 2   
jal draw_rect

addi $a0, $zero, 198        
addi $a1, $zero, 63         
addi $a2, $zero, 4         
addi $a3, $zero, 2   
jal draw_rect

addi $a0, $zero, 201        
addi $a1, $zero, 62         
addi $a2, $zero, 5         
addi $a3, $zero, 1   
jal draw_rect

addi $a0, $zero, 207        
addi $a1, $zero, 62         
addi $a2, $zero, 1         
addi $a3, $zero, 1   
jal draw_rect

beq $s7, $s3, red_high_bottom
beq $s7, $s5, blue_high_bottom
beq $s7, $s4, yellow_high_bottom

red_high_bottom:
add, $t8, $zero, 0xfd3189
j begin_high_b

blue_high_bottom:
add, $t8, $zero, 0x33d9d6
j begin_high_b

yellow_high_bottom:
add, $t8, $zero, 0xe6dbbf
j begin_high_b

begin_high_b:
# Bottom Half 
addi $a0, $zero, 196        
addi $a1, $zero, 87         
addi $a2, $zero, 1         
addi $a3, $zero, 10   
jal draw_rect

addi $a0, $zero, 196        
addi $a1, $zero, 98         
addi $a2, $zero, 1         
addi $a3, $zero, 1   
jal draw_rect

######################################################################### Pill - "M" #######################################################################################
lw $t9, animation_frame

beq $t9, 0, Pill_Frame_1
beq $t9, 1, Pill_Frame_2
beq $t9, 2, Pill_Frame_3
beq $t9, 3, Pill_Frame_4
beq $t9, 4, Pill_Frame_5
beq $t9, 5, Pill_Frame_6

li $t9, 0
sw $t9, animation_frame
j Pill_Frame_1

Pill_Frame_1:
addi $t9, $t9, 1 
sw $t9, animation_frame

addi $a0, $zero, 208     
addi $a1, $zero, 74        
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 208   
addi $a1, $zero, 75      
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 207    
addi $a1, $zero, 73        
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 207   
addi $a1, $zero, 74      
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect
addi $a0, $zero, 209    
addi $a1, $zero, 73        
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 209   
addi $a1, $zero, 74     
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 206    
addi $a1, $zero, 72        
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 206    
addi $a1, $zero, 73      
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect
addi $a0, $zero, 210    
addi $a1, $zero, 72        
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 210    
addi $a1, $zero, 73      
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 205    
addi $a1, $zero, 71        
addi $a2, $zero, 1         
addi $a3, $zero, 10  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 205    
addi $a1, $zero, 73      
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0xffffff
jal draw_rect
addi $a0, $zero, 211    
addi $a1, $zero, 71        
addi $a2, $zero, 1         
addi $a3, $zero, 10  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 211     
addi $a1, $zero, 73      
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 204    
addi $a1, $zero, 73       
addi $a2, $zero, 1         
addi $a3, $zero, 10 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 204    
addi $a1, $zero, 76      
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0xffffff
jal draw_rect
addi $a0, $zero, 212    
addi $a1, $zero, 73      
addi $a2, $zero, 1         
addi $a3, $zero, 10  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 212    
addi $a1, $zero, 76      
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 203    
addi $a1, $zero, 76      
addi $a2, $zero, 1         
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 203    
addi $a1, $zero, 79      
addi $a2, $zero, 1         
addi $a3, $zero, 1 
add, $t8, $zero, 0xffffff
jal draw_rect
addi $a0, $zero, 213    
addi $a1, $zero, 76    
addi $a2, $zero, 1         
addi $a3, $zero, 6  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 213    
addi $a1, $zero, 79      
addi $a2, $zero, 1         
addi $a3, $zero, 1 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 202   
addi $a1, $zero, 79        
addi $a2, $zero, 1         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 214    
addi $a1, $zero, 79     
addi $a2, $zero, 1         
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect

R_Pill_Frame_1:
addi $a0, $zero, 208     
addi $a1, $zero, 97       
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 208   
addi $a1, $zero, 98     
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 207    
addi $a1, $zero, 98       
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 207   
addi $a1, $zero, 99     
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect
addi $a0, $zero, 209    
addi $a1, $zero, 98        
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 209   
addi $a1, $zero, 99     
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 206    
addi $a1, $zero, 98       
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 206    
addi $a1, $zero, 100     
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect
addi $a0, $zero, 210    
addi $a1, $zero, 98       
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 210    
addi $a1, $zero, 100     
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 205    
addi $a1, $zero, 95       
addi $a2, $zero, 1         
addi $a3, $zero, 10  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 205    
addi $a1, $zero, 98      
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0xffffff
jal draw_rect
addi $a0, $zero, 211    
addi $a1, $zero, 95        
addi $a2, $zero, 1         
addi $a3, $zero, 10  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 211     
addi $a1, $zero, 98      
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 204    
addi $a1, $zero, 93      
addi $a2, $zero, 1         
addi $a3, $zero, 10 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 204    
addi $a1, $zero, 95     
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0xffffff
jal draw_rect
addi $a0, $zero, 212    
addi $a1, $zero, 93     
addi $a2, $zero, 1         
addi $a3, $zero, 10  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 212    
addi $a1, $zero, 95     
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 203    
addi $a1, $zero, 94    
addi $a2, $zero, 1         
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 203    
addi $a1, $zero, 96      
addi $a2, $zero, 1         
addi $a3, $zero, 1 
add, $t8, $zero, 0xffffff
jal draw_rect
addi $a0, $zero, 213    
addi $a1, $zero, 94    
addi $a2, $zero, 1         
addi $a3, $zero, 6  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 213    
addi $a1, $zero, 96     
addi $a2, $zero, 1         
addi $a3, $zero, 1 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 202   
addi $a1, $zero, 95        
addi $a2, $zero, 1         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 214    
addi $a1, $zero, 95    
addi $a2, $zero, 1         
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect

j Draw_Viruses

Pill_Frame_2:
addi $t9, $t9, 1 
sw $t9, animation_frame

addi $a0, $zero, 197       
addi $a1, $zero, 78        
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 198       
addi $a1, $zero, 75        
addi $a2, $zero, 1         
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 198       
addi $a1, $zero, 78        
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 199       
addi $a1, $zero, 70       
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 199       
addi $a1, $zero, 75       
addi $a2, $zero, 1         
addi $a3, $zero, 5  
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 200       
addi $a1, $zero, 71        
addi $a2, $zero, 1         
addi $a3, $zero, 6  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 200      
addi $a1, $zero, 72       
addi $a2, $zero, 1         
addi $a3, $zero, 4  
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 201       
addi $a1, $zero, 73       
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 201     
addi $a1, $zero, 74       
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 202       
addi $a1, $zero, 72       
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 202     
addi $a1, $zero, 73       
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 203       
addi $a1, $zero, 71       
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 203     
addi $a1, $zero, 72       
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 204      
addi $a1, $zero, 70        
addi $a2, $zero, 1         
addi $a3, $zero, 10
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 204     
addi $a1, $zero, 72       
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 205     
addi $a1, $zero, 73        
addi $a2, $zero, 1         
addi $a3, $zero, 9   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 205    
addi $a1, $zero, 76       
addi $a2, $zero, 1         
addi $a3, $zero, 4
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 206     
addi $a1, $zero, 76        
addi $a2, $zero, 1         
addi $a3, $zero, 5  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 206    
addi $a1, $zero, 78      
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 207    
addi $a1, $zero, 78        
addi $a2, $zero, 1         
addi $a3, $zero, 2  
add, $t8, $zero, $zero
jal draw_rect

R_Pill_Frame_2:
addi $a0, $zero, 197       
addi $a1, $zero, 95       
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 198       
addi $a1, $zero, 93    
addi $a2, $zero, 1         
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 198       
addi $a1, $zero, 95        
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 199       
addi $a1, $zero, 92       
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 199       
addi $a1, $zero, 94       
addi $a2, $zero, 1         
addi $a3, $zero, 5  
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 200       
addi $a1, $zero, 97       
addi $a2, $zero, 1         
addi $a3, $zero, 6  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 200      
addi $a1, $zero, 98      
addi $a2, $zero, 1         
addi $a3, $zero, 4  
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 201       
addi $a1, $zero, 96    
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 201     
addi $a1, $zero, 97       
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 202       
addi $a1, $zero, 97      
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 202     
addi $a1, $zero, 98     
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 203       
addi $a1, $zero, 97      
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 203     
addi $a1, $zero, 99      
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 204      
addi $a1, $zero, 94      
addi $a2, $zero, 1         
addi $a3, $zero, 10
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 204     
addi $a1, $zero, 97       
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 205     
addi $a1, $zero, 92      
addi $a2, $zero, 1         
addi $a3, $zero, 9   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 205    
addi $a1, $zero, 94      
addi $a2, $zero, 1         
addi $a3, $zero, 4
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 206     
addi $a1, $zero, 93        
addi $a2, $zero, 1         
addi $a3, $zero, 5  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 206    
addi $a1, $zero, 95     
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 207    
addi $a1, $zero, 94    
addi $a2, $zero, 1         
addi $a3, $zero, 2  
add, $t8, $zero, $zero
jal draw_rect

j Draw_Viruses

Pill_Frame_3:
addi $t9, $t9, 1 
sw $t9, animation_frame

addi $a0, $zero, 196       
addi $a1, $zero, 69        
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $zero
jal draw_rect

R_Pill_Frame_3:
addi $a0, $zero, 196       
addi $a1, $zero, 91        
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $zero
jal draw_rect

j Draw_Viruses

Pill_Frame_4:
addi $t9, $t9, 1 
sw $t9, animation_frame

j Draw_Viruses

Pill_Frame_5:
addi $t9, $t9, 1 
sw $t9, animation_frame

addi $a0, $zero, 220     
addi $a1, $zero, 69        
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $zero
jal draw_rect

R_Pill_Frame_5:
addi $a0, $zero, 220     
addi $a1, $zero, 91        
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $zero
jal draw_rect

j Draw_Viruses

Pill_Frame_6:
addi $t9, $t9, 1 
sw $t9, animation_frame

addi $a0, $zero, 218      
addi $a1, $zero, 78        
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 217       
addi $a1, $zero, 75        
addi $a2, $zero, 1         
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 217        
addi $a1, $zero, 78        
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 216      
addi $a1, $zero, 70       
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 216      
addi $a1, $zero, 75       
addi $a2, $zero, 1         
addi $a3, $zero, 5  
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 215       
addi $a1, $zero, 71        
addi $a2, $zero, 1         
addi $a3, $zero, 6  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 215      
addi $a1, $zero, 72       
addi $a2, $zero, 1         
addi $a3, $zero, 4  
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 214       
addi $a1, $zero, 73       
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 214     
addi $a1, $zero, 74       
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 213       
addi $a1, $zero, 72       
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 213    
addi $a1, $zero, 73       
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 212       
addi $a1, $zero, 71       
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 212     
addi $a1, $zero, 72       
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 211      
addi $a1, $zero, 70        
addi $a2, $zero, 1         
addi $a3, $zero, 10
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 211     
addi $a1, $zero, 72       
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 210    
addi $a1, $zero, 73        
addi $a2, $zero, 1         
addi $a3, $zero, 9   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 210    
addi $a1, $zero, 76       
addi $a2, $zero, 1         
addi $a3, $zero, 4
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 209     
addi $a1, $zero, 76        
addi $a2, $zero, 1         
addi $a3, $zero, 5  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 209    
addi $a1, $zero, 78      
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 208   
addi $a1, $zero, 78        
addi $a2, $zero, 1         
addi $a3, $zero, 2  
add, $t8, $zero, $zero
jal draw_rect

R_Pill_Frame_6:
addi $a0, $zero, 218      
addi $a1, $zero, 95       
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 217       
addi $a1, $zero, 93     
addi $a2, $zero, 1         
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 217      
addi $a1, $zero, 95       
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 216        
addi $a1, $zero, 92      
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 216      
addi $a1, $zero, 94       
addi $a2, $zero, 1         
addi $a3, $zero, 5  
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 215       
addi $a1, $zero, 97       
addi $a2, $zero, 1         
addi $a3, $zero, 6  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 215     
addi $a1, $zero, 98       
addi $a2, $zero, 1         
addi $a3, $zero, 4  
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 214       
addi $a1, $zero, 96    
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 214    
addi $a1, $zero, 97       
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 213        
addi $a1, $zero, 97      
addi $a2, $zero, 1         
addi $a3, $zero, 5   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 213     
addi $a1, $zero, 98     
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 212       
addi $a1, $zero, 97      
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 212     
addi $a1, $zero, 99      
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 211     
addi $a1, $zero, 94      
addi $a2, $zero, 1         
addi $a3, $zero, 10
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 211     
addi $a1, $zero, 97      
addi $a2, $zero, 1         
addi $a3, $zero, 5 
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 210     
addi $a1, $zero, 92      
addi $a2, $zero, 1         
addi $a3, $zero, 9   
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 210    
addi $a1, $zero, 94       
addi $a2, $zero, 1         
addi $a3, $zero, 4
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 209     
addi $a1, $zero, 93        
addi $a2, $zero, 1         
addi $a3, $zero, 5  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 209    
addi $a1, $zero, 95     
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, 0x6f3198
jal draw_rect

addi $a0, $zero, 208    
addi $a1, $zero, 94    
addi $a2, $zero, 1         
addi $a3, $zero, 2  
add, $t8, $zero, $zero
jal draw_rect

j Draw_Viruses


######################################################################### Viruses ##########################################################################################
Draw_Viruses:
# Will just be there heads
# Red Virus - Main Body (separated by vertical layer from middle to end)
addi $a0, $zero, 43       
addi $a1, $zero, 161        
addi $a2, $zero, 6        
addi $a3, $zero, 20 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 43        
addi $a1, $zero, 162        
addi $a2, $zero, 6         
addi $a3, $zero, 18   
add, $t8, $zero, $s3
jal draw_rect

addi $a0, $zero, 41       
addi $a1, $zero, 162        
addi $a2, $zero, 2         
addi $a3, $zero, 18 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 41        
addi $a1, $zero, 163        
addi $a2, $zero, 2         
addi $a3, $zero, 16   
add, $t8, $zero, $s3
jal draw_rect
addi $a0, $zero, 49       
addi $a1, $zero, 162        
addi $a2, $zero, 2         
addi $a3, $zero, 18 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 49        
addi $a1, $zero, 163        
addi $a2, $zero, 2         
addi $a3, $zero, 16   
add, $t8, $zero, $s3
jal draw_rect

addi $a0, $zero, 40       
addi $a1, $zero, 163        
addi $a2, $zero, 1         
addi $a3, $zero, 17 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 40        
addi $a1, $zero, 164        
addi $a2, $zero, 1         
addi $a3, $zero, 15   
add, $t8, $zero, $s3
jal draw_rect
addi $a0, $zero, 51       
addi $a1, $zero, 163        
addi $a2, $zero, 1         
addi $a3, $zero, 17 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 51        
addi $a1, $zero, 164        
addi $a2, $zero, 1         
addi $a3, $zero, 15   
add, $t8, $zero, $s3
jal draw_rect

addi $a0, $zero, 39       
addi $a1, $zero, 164        
addi $a2, $zero, 1         
addi $a3, $zero, 16 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 39        
addi $a1, $zero, 165        
addi $a2, $zero, 1         
addi $a3, $zero, 14   
add, $t8, $zero, $s3
jal draw_rect
addi $a0, $zero, 52       
addi $a1, $zero, 164        
addi $a2, $zero, 1         
addi $a3, $zero, 16 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 52        
addi $a1, $zero, 165        
addi $a2, $zero, 1         
addi $a3, $zero, 14   
add, $t8, $zero, $s3
jal draw_rect

addi $a0, $zero, 38       
addi $a1, $zero, 166        
addi $a2, $zero, 1         
addi $a3, $zero, 14 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 38        
addi $a1, $zero, 167        
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $s3
jal draw_rect
addi $a0, $zero, 53       
addi $a1, $zero, 166        
addi $a2, $zero, 1         
addi $a3, $zero, 14 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 53        
addi $a1, $zero, 167        
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $s3
jal draw_rect

addi $a0, $zero, 37       
addi $a1, $zero, 167        
addi $a2, $zero, 1         
addi $a3, $zero, 12 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 54       
addi $a1, $zero, 167        
addi $a2, $zero, 1         
addi $a3, $zero, 12 
add, $t8, $zero, $zero
jal draw_rect

########################################## Red Virus - Horns #####################################
addi $a0, $zero, 41       
addi $a1, $zero, 161        
addi $a2, $zero, 2        
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 42       
addi $a1, $zero, 160        
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 42        
addi $a1, $zero, 161        
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 48       
addi $a1, $zero, 161        
addi $a2, $zero, 2        
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 48       
addi $a1, $zero, 160        
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 48        
addi $a1, $zero, 161        
addi $a2, $zero, 1         
addi $a3, $zero, 1   
add, $t8, $zero, $s4
jal draw_rect

############################################### Red Virus - Eyes #################################################
addi $a0, $zero, 42       
addi $a1, $zero, 164        
addi $a2, $zero, 8        
addi $a3, $zero, 4 
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 41       
addi $a1, $zero, 165        
addi $a2, $zero, 10         
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 40       
addi $a1, $zero, 166        
addi $a2, $zero, 5         
addi $a3, $zero, 3 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 40       
addi $a1, $zero, 166        
addi $a2, $zero, 3         
addi $a3, $zero, 5 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 47       
addi $a1, $zero, 166        
addi $a2, $zero, 5         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 49       
addi $a1, $zero, 166        
addi $a2, $zero, 3        
addi $a3, $zero, 5 
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 39       
addi $a1, $zero, 168        
addi $a2, $zero, 5         
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 48       
addi $a1, $zero, 168        
addi $a2, $zero, 5         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect

lb $t9, next_capsule
lw $t8, anim_frame_r

beq $t9, 0, move_red_1
beq $t9, 3, move_red_0
beq $t9, 4, move_red_0
j move_red_2

move_red_0:
bge $t8, 4, move_red_2
addi, $t8, $t8, 1
sw $t8, anim_frame_r

addi $a0, $zero, 44       
addi $a1, $zero, 166        
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 43       
addi $a1, $zero, 165       
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 43       
addi $a1, $zero, 167        
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 48       
addi $a1, $zero, 165       
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 47      
addi $a1, $zero, 166        
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 48       
addi $a1, $zero, 167        
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
j continue_red

move_red_1:
bge $t8, 4, move_red_2
addi, $t8, $t8, 1
sw $t8, anim_frame_r

addi $a0, $zero, 42       
addi $a1, $zero, 165        
addi $a2, $zero, 3       
addi $a3, $zero, 3 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 43       
addi $a1, $zero, 166      
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 47       
addi $a1, $zero, 165      
addi $a2, $zero, 3        
addi $a3, $zero, 3 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 48       
addi $a1, $zero, 166      
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
j continue_red

move_red_2:
li $t8, 0
sw $t8, anim_frame_r

addi $a0, $zero, 44       
addi $a1, $zero, 165        
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 47       
addi $a1, $zero, 165        
addi $a2, $zero, 1        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
j continue_red

############################################### Red Virus - Nose #################################################################
continue_red:
addi $a0, $zero, 45       
addi $a1, $zero, 169        
addi $a2, $zero, 2        
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 44       
addi $a1, $zero, 170        
addi $a2, $zero, 4        
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect

########################################### Red Virus - Mouth ####################################################
addi $a0, $zero, 39       
addi $a1, $zero, 173        
addi $a2, $zero, 14        
addi $a3, $zero, 4 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 40       
addi $a1, $zero, 172        
addi $a2, $zero, 3       
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 49       
addi $a1, $zero, 172        
addi $a2, $zero, 3       
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 40       
addi $a1, $zero, 174        
addi $a2, $zero, 12        
addi $a3, $zero, 4 
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 42       
addi $a1, $zero, 173        
addi $a2, $zero, 2        
addi $a3, $zero, 2 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 48       
addi $a1, $zero, 173        
addi $a2, $zero, 2        
addi $a3, $zero, 2 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 45       
addi $a1, $zero, 176        
addi $a2, $zero, 2        
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect

######################################### Red Virus - Ears ########################################################
addi $a0, $zero, 37       
addi $a1, $zero, 161        
addi $a2, $zero, 2        
addi $a3, $zero, 4 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 38       
addi $a1, $zero, 160        
addi $a2, $zero, 1        
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 38       
addi $a1, $zero, 161        
addi $a2, $zero, 1        
addi $a3, $zero, 4 
add, $t8, $zero, $s3
jal draw_rect
addi $a0, $zero, 38       
addi $a1, $zero, 163        
addi $a2, $zero, 1        
addi $a3, $zero, 2 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 39       
addi $a1, $zero, 161        
addi $a2, $zero, 1        
addi $a3, $zero, 5 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 39       
addi $a1, $zero, 162        
addi $a2, $zero, 1        
addi $a3, $zero, 3 
add, $t8, $zero, $s3
jal draw_rect

addi $a0, $zero, 53       
addi $a1, $zero, 161        
addi $a2, $zero, 2        
addi $a3, $zero, 4 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 53       
addi $a1, $zero, 160        
addi $a2, $zero, 1        
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 53       
addi $a1, $zero, 161        
addi $a2, $zero, 1        
addi $a3, $zero, 4 
add, $t8, $zero, $s3
jal draw_rect
addi $a0, $zero, 53       
addi $a1, $zero, 163        
addi $a2, $zero, 1        
addi $a3, $zero, 2 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 52       
addi $a1, $zero, 161        
addi $a2, $zero, 1        
addi $a3, $zero, 5 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 52       
addi $a1, $zero, 162        
addi $a2, $zero, 1        
addi $a3, $zero, 3 
add, $t8, $zero, $s3
jal draw_rect

################################# Blue Virus - Main Body #########################################
addi $a0, $zero, 60       
addi $a1, $zero, 185        
addi $a2, $zero, 4        
addi $a3, $zero, 20 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 60        
addi $a1, $zero, 186        
addi $a2, $zero, 4         
addi $a3, $zero, 18   
add, $t8, $zero, $s5
jal draw_rect

addi $a0, $zero, 59       
addi $a1, $zero, 184        
addi $a2, $zero, 1         
addi $a3, $zero, 21 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 59        
addi $a1, $zero, 185        
addi $a2, $zero, 1         
addi $a3, $zero, 19   
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 64       
addi $a1, $zero, 184       
addi $a2, $zero, 1         
addi $a3, $zero, 21 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 64        
addi $a1, $zero, 185        
addi $a2, $zero, 1         
addi $a3, $zero, 19   
add, $t8, $zero, $s5
jal draw_rect

addi $a0, $zero, 57       
addi $a1, $zero, 183        
addi $a2, $zero, 2         
addi $a3, $zero, 21 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 57        
addi $a1, $zero, 184        
addi $a2, $zero, 2         
addi $a3, $zero, 19   
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 65       
addi $a1, $zero, 183       
addi $a2, $zero, 2         
addi $a3, $zero, 21 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 65        
addi $a1, $zero, 184        
addi $a2, $zero, 2         
addi $a3, $zero, 19  
add, $t8, $zero, $s5
jal draw_rect

addi $a0, $zero, 55       
addi $a1, $zero, 184        
addi $a2, $zero, 2         
addi $a3, $zero, 19 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 55        
addi $a1, $zero, 185        
addi $a2, $zero, 2         
addi $a3, $zero, 17   
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 67       
addi $a1, $zero, 184        
addi $a2, $zero, 2         
addi $a3, $zero, 19 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 67        
addi $a1, $zero, 185        
addi $a2, $zero, 2         
addi $a3, $zero, 17   
add, $t8, $zero, $s5
jal draw_rect


addi $a0, $zero, 54       
addi $a1, $zero, 190        
addi $a2, $zero, 1         
addi $a3, $zero, 12 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 54        
addi $a1, $zero, 191        
addi $a2, $zero, 1         
addi $a3, $zero, 10   
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 69       
addi $a1, $zero, 190        
addi $a2, $zero, 1         
addi $a3, $zero, 12 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 69       
addi $a1, $zero, 191        
addi $a2, $zero, 1         
addi $a3, $zero, 10   
add, $t8, $zero, $s5
jal draw_rect

addi $a0, $zero, 53       
addi $a1, $zero, 185        
addi $a2, $zero, 2         
addi $a3, $zero, 5
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 53        
addi $a1, $zero, 186       
addi $a2, $zero, 2         
addi $a3, $zero, 3  
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 69       
addi $a1, $zero, 185        
addi $a2, $zero, 2         
addi $a3, $zero, 5 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 69        
addi $a1, $zero, 186        
addi $a2, $zero, 2         
addi $a3, $zero, 3  
add, $t8, $zero, $s5
jal draw_rect

addi $a0, $zero, 52       
addi $a1, $zero, 186        
addi $a2, $zero, 1         
addi $a3, $zero, 4
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 52        
addi $a1, $zero, 187       
addi $a2, $zero, 1         
addi $a3, $zero, 2  
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 71       
addi $a1, $zero, 186        
addi $a2, $zero, 1         
addi $a3, $zero, 4
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 71           
addi $a1, $zero, 187        
addi $a2, $zero, 1         
addi $a3, $zero, 2  
add, $t8, $zero, $s5
jal draw_rect

addi $a0, $zero, 51       
addi $a1, $zero, 187        
addi $a2, $zero, 1         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 51        
addi $a1, $zero, 188       
addi $a2, $zero, 1         
addi $a3, $zero, 1  
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 72       
addi $a1, $zero, 187        
addi $a2, $zero, 1         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 72           
addi $a1, $zero, 188        
addi $a2, $zero, 1         
addi $a3, $zero, 1  
add, $t8, $zero, $s5
jal draw_rect

addi $a0, $zero, 50       
addi $a1, $zero, 188        
addi $a2, $zero, 1         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 50        
addi $a1, $zero, 189       
addi $a2, $zero, 1         
addi $a3, $zero, 1  
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 49        
addi $a1, $zero, 189      
addi $a2, $zero, 1         
addi $a3, $zero, 1  
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 73       
addi $a1, $zero, 188        
addi $a2, $zero, 1         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 73           
addi $a1, $zero, 189        
addi $a2, $zero, 1         
addi $a3, $zero, 1  
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 74           
addi $a1, $zero, 189        
addi $a2, $zero, 1         
addi $a3, $zero, 1  
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 53       
addi $a1, $zero, 191        
addi $a2, $zero, 1         
addi $a3, $zero, 10 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 53        
addi $a1, $zero, 192        
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 70       
addi $a1, $zero, 191        
addi $a2, $zero, 1         
addi $a3, $zero, 10
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 70       
addi $a1, $zero, 192        
addi $a2, $zero, 1         
addi $a3, $zero, 6   
add, $t8, $zero, $s5
jal draw_rect

addi $a0, $zero, 52       
addi $a1, $zero, 192        
addi $a2, $zero, 1         
addi $a3, $zero, 6 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 52        
addi $a1, $zero, 193        
addi $a2, $zero, 1         
addi $a3, $zero, 4   
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 71       
addi $a1, $zero, 192        
addi $a2, $zero, 1         
addi $a3, $zero, 6
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 71       
addi $a1, $zero, 193        
addi $a2, $zero, 1         
addi $a3, $zero, 4   
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 51       
addi $a1, $zero, 193        
addi $a2, $zero, 1         
addi $a3, $zero, 4 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 72       
addi $a1, $zero, 193       
addi $a2, $zero, 1         
addi $a3, $zero, 4 
add, $t8, $zero, $zero
jal draw_rect
################################# Blue Virus - Eyes #########################################
# Left Eye
addi $a0, $zero, 55      
addi $a1, $zero, 188        
addi $a2, $zero, 5         
addi $a3, $zero, 9 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 55      
addi $a1, $zero, 187        
addi $a2, $zero, 4        
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 60     
addi $a1, $zero, 189        
addi $a2, $zero, 1        
addi $a3, $zero, 8
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 54     
addi $a1, $zero, 192        
addi $a2, $zero, 1        
addi $a3, $zero, 4
add, $t8, $zero, $zero
jal draw_rect

# Right Eye
addi $a0, $zero, 64      
addi $a1, $zero, 188        
addi $a2, $zero, 5         
addi $a3, $zero, 9 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 65      
addi $a1, $zero, 187        
addi $a2, $zero, 4        
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 63     
addi $a1, $zero, 189        
addi $a2, $zero, 1        
addi $a3, $zero, 8
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 69     
addi $a1, $zero, 192        
addi $a2, $zero, 1        
addi $a3, $zero, 4
add, $t8, $zero, $zero
jal draw_rect

# Pupils
lb $t9, next_capsule
lw $t8, anim_frame_b

beq $t9, 1, move_blue_1
beq $t9, 3, move_blue_0
beq $t9, 5, move_blue_0
j move_blue_2

move_blue_0:
bge $t8, 4, move_blue_2
addi, $t8, $t8, 1
sw $t8, anim_frame_b

addi $a0, $zero, 59     
addi $a1, $zero, 194        
addi $a2, $zero, 2        
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 61     
addi $a1, $zero, 193        
addi $a2, $zero, 2        
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 67   
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 2
add, $t8, $zero, $s4
jal draw_rect
j start_blue_mouth

move_blue_1:
bge $t8, 4, move_blue_2
addi, $t8, $t8, 1
sw $t8, anim_frame_b

addi $a0, $zero, 57     
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 58     
addi $a1, $zero, 194        
addi $a2, $zero, 2        
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 60    
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 61     
addi $a1, $zero, 193        
addi $a2, $zero, 2        
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 63     
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 64     
addi $a1, $zero, 194        
addi $a2, $zero, 2        
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 66     
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
j start_blue_mouth

move_blue_2:
li $t8, 0
sw $t8, anim_frame_b

addi $a0, $zero, 60     
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 2
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 61     
addi $a1, $zero, 193        
addi $a2, $zero, 2        
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 63     
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 2
add, $t8, $zero, $s4
jal draw_rect
j start_blue_mouth

################################# Blue Virus - Mouth #########################################
start_blue_mouth:
addi $a0, $zero, 54    
addi $a1, $zero, 199        
addi $a2, $zero, 17        
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 59    
addi $a1, $zero, 199        
addi $a2, $zero, 6        
addi $a3, $zero, 4
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 60    
addi $a1, $zero, 199        
addi $a2, $zero, 4        
addi $a3, $zero, 3
add, $t8, $zero, $s4
jal draw_rect

################################### Yellow Virus - Main Body #################################################
addi $a0, $zero, 27       
addi $a1, $zero, 193        
addi $a2, $zero, 6        
addi $a3, $zero, 20 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 27      
addi $a1, $zero, 194        
addi $a2, $zero, 6         
addi $a3, $zero, 18   
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 26       
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 19 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 26        
addi $a1, $zero, 194        
addi $a2, $zero, 1         
addi $a3, $zero, 17  
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 33       
addi $a1, $zero, 193        
addi $a2, $zero, 1         
addi $a3, $zero, 19 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 33        
addi $a1, $zero, 194       
addi $a2, $zero, 1         
addi $a3, $zero, 17  
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 25       
addi $a1, $zero, 193        
addi $a2, $zero, 1        
addi $a3, $zero, 19 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 25        
addi $a1, $zero, 194        
addi $a2, $zero, 1         
addi $a3, $zero, 17  
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 34       
addi $a1, $zero, 193        
addi $a2, $zero, 1         
addi $a3, $zero, 19 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 34        
addi $a1, $zero, 194       
addi $a2, $zero, 1         
addi $a3, $zero, 17  
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 24      
addi $a1, $zero, 195        
addi $a2, $zero, 1         
addi $a3, $zero, 16 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 24        
addi $a1, $zero, 196        
addi $a2, $zero, 1         
addi $a3, $zero, 14   
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 35       
addi $a1, $zero, 195        
addi $a2, $zero, 1         
addi $a3, $zero, 16
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 35        
addi $a1, $zero, 196       
addi $a2, $zero, 1         
addi $a3, $zero, 14   
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 23       
addi $a1, $zero, 196        
addi $a2, $zero, 1         
addi $a3, $zero, 14
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 23        
addi $a1, $zero, 197       
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 36       
addi $a1, $zero, 196        
addi $a2, $zero, 1         
addi $a3, $zero, 14 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 36        
addi $a1, $zero, 197       
addi $a2, $zero, 1         
addi $a3, $zero, 12   
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 22       
addi $a1, $zero, 198        
addi $a2, $zero, 1         
addi $a3, $zero, 11
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 22       
addi $a1, $zero, 199        
addi $a2, $zero, 1         
addi $a3, $zero, 9   
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 37       
addi $a1, $zero, 198       
addi $a2, $zero, 1         
addi $a3, $zero, 11 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 37        
addi $a1, $zero, 199        
addi $a2, $zero, 1         
addi $a3, $zero, 9  
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 21       
addi $a1, $zero, 199       
addi $a2, $zero, 1         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 38       
addi $a1, $zero, 199          
addi $a2, $zero, 1         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 22       
addi $a1, $zero, 201       
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 37       
addi $a1, $zero, 201          
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 21       
addi $a1, $zero, 203       
addi $a2, $zero, 1         
addi $a3, $zero, 5
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 38       
addi $a1, $zero, 203        
addi $a2, $zero, 1         
addi $a3, $zero, 5
add, $t8, $zero, $zero
jal draw_rect

################################### Yellow Virus - Antenna #################################################
# Left Upper Antenna 
addi $a0, $zero, 24       
addi $a1, $zero, 193        
addi $a2, $zero, 2         
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 24       
addi $a1, $zero, 194        
addi $a2, $zero, 2         
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 23       
addi $a1, $zero, 192        
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 23       
addi $a1, $zero, 193        
addi $a2, $zero, 1         
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 22       
addi $a1, $zero, 191        
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 22       
addi $a1, $zero, 192        
addi $a2, $zero, 1         
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 21      
addi $a1, $zero, 191        
addi $a2, $zero, 1         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect

# Right Upper Antenna 
addi $a0, $zero, 35       
addi $a1, $zero, 193        
addi $a2, $zero, 2         
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 35       
addi $a1, $zero, 194        
addi $a2, $zero, 2         
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 36       
addi $a1, $zero, 192        
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 36      
addi $a1, $zero, 193        
addi $a2, $zero, 1         
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 37       
addi $a1, $zero, 191        
addi $a2, $zero, 1         
addi $a3, $zero, 3 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 37       
addi $a1, $zero, 192        
addi $a2, $zero, 1         
addi $a3, $zero, 1 
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 38      
addi $a1, $zero, 191        
addi $a2, $zero, 1         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect

# Left Lower Antenna 
addi $a0, $zero, 20       
addi $a1, $zero, 201       
addi $a2, $zero, 1         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 20       
addi $a1, $zero, 202       
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 21      
addi $a1, $zero, 202       
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 19       
addi $a1, $zero, 200       
addi $a2, $zero, 1         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 19       
addi $a1, $zero, 201       
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 18       
addi $a1, $zero, 200       
addi $a2, $zero, 1         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect

# Right Lower Antenna 
addi $a0, $zero, 39       
addi $a1, $zero, 201       
addi $a2, $zero, 1         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 39       
addi $a1, $zero, 202       
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 38      
addi $a1, $zero, 202       
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 40       
addi $a1, $zero, 200       
addi $a2, $zero, 1         
addi $a3, $zero, 3
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 40       
addi $a1, $zero, 201       
addi $a2, $zero, 1         
addi $a3, $zero, 1
add, $t8, $zero, $s4
jal draw_rect
addi $a0, $zero, 41       
addi $a1, $zero, 200       
addi $a2, $zero, 1         
addi $a3, $zero, 2
add, $t8, $zero, $zero
jal draw_rect

################################### Yellow Virus - Antenna #################################################
addi $a0, $zero, 26       
addi $a1, $zero, 199        
addi $a2, $zero, 8       
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 28       
addi $a1, $zero, 198        
addi $a2, $zero, 4       
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 25       
addi $a1, $zero, 200        
addi $a2, $zero, 4       
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 26       
addi $a1, $zero, 200        
addi $a2, $zero, 1       
addi $a3, $zero, 3 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 22       
addi $a1, $zero, 201       
addi $a2, $zero, 3      
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 31       
addi $a1, $zero, 200        
addi $a2, $zero, 4       
addi $a3, $zero, 2 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 33       
addi $a1, $zero, 200        
addi $a2, $zero, 1       
addi $a3, $zero, 3 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 35      
addi $a1, $zero, 201       
addi $a2, $zero, 3      
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect

# Pupils
lb $t9, next_capsule
lw $t8, anim_frame_y

beq $t9, 2, move_yellow_1
bge $t9, 4, move_yellow_0
j move_yellow_2

move_yellow_0:
bge $t8, 4, move_yellow_2
addi, $t8, $t8, 1
sw $t8, anim_frame_y

addi $a0, $zero, 27       
addi $a1, $zero, 200       
addi $a2, $zero, 2       
addi $a3, $zero, 1 
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 31       
addi $a1, $zero, 200        
addi $a2, $zero, 2       
addi $a3, $zero, 1 
add, $t8, $zero, $s5
jal draw_rect
j continue_yellow

move_yellow_1:
bge $t8, 4, move_yellow_2
addi, $t8, $t8, 1
sw $t8, anim_frame_y

addi $a0, $zero, 26       
addi $a1, $zero, 195       
addi $a2, $zero, 8       
addi $a3, $zero, 4
add, $t8, $zero, $zero
jal draw_rect
#addi $a0, $zero, 28      
#addi $a1, $zero, 196       
#addi $a2, $zero, 4      
#addi $a3, $zero, 1
#add, $t8, $zero, $zero
#jal draw_rect

addi $a0, $zero, 28     
addi $a1, $zero, 196       
addi $a2, $zero, 1       
addi $a3, $zero, 3
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 28       
addi $a1, $zero, 200    
addi $a2, $zero, 1       
addi $a3, $zero, 1 
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 31    
addi $a1, $zero, 196        
addi $a2, $zero, 1       
addi $a3, $zero, 3 
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 31      
addi $a1, $zero, 200    
addi $a2, $zero, 1       
addi $a3, $zero, 1 
add, $t8, $zero, $s5
jal draw_rect

j continue_yellow

move_yellow_2:
li $t8, 0
sw $t8, anim_frame_y

addi $a0, $zero, 28       
addi $a1, $zero, 199        
addi $a2, $zero, 1       
addi $a3, $zero, 2 
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 31       
addi $a1, $zero, 199        
addi $a2, $zero, 1       
addi $a3, $zero, 2 
add, $t8, $zero, $s5
jal draw_rect
j continue_yellow

################################### Yellow Virus - Antenna #################################################
continue_yellow:
addi $a0, $zero, 25       
addi $a1, $zero, 207        
addi $a2, $zero, 10       
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 24       
addi $a1, $zero, 208        
addi $a2, $zero, 1       
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 35      
addi $a1, $zero, 208        
addi $a2, $zero, 1       
addi $a3, $zero, 1 
add, $t8, $zero, $zero
jal draw_rect

################################### Yellow Virus - Antenna #################################################
addi $a0, $zero, 26       
addi $a1, $zero, 192       
addi $a2, $zero, 3       
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 27       
addi $a1, $zero, 191       
addi $a2, $zero, 1       
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 27       
addi $a1, $zero, 193       
addi $a2, $zero, 2       
addi $a3, $zero, 1
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 27       
addi $a1, $zero, 192       
addi $a2, $zero, 1       
addi $a3, $zero, 1
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 27       
addi $a1, $zero, 194       
addi $a2, $zero, 2       
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 31       
addi $a1, $zero, 192       
addi $a2, $zero, 3       
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 32       
addi $a1, $zero, 191       
addi $a2, $zero, 1       
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect
addi $a0, $zero, 31      
addi $a1, $zero, 193       
addi $a2, $zero, 2       
addi $a3, $zero, 1
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 32       
addi $a1, $zero, 192       
addi $a2, $zero, 1       
addi $a3, $zero, 1
add, $t8, $zero, $s5
jal draw_rect
addi $a0, $zero, 31      
addi $a1, $zero, 194       
addi $a2, $zero, 2       
addi $a3, $zero, 1
add, $t8, $zero, $zero
jal draw_rect

j main_jar_start

#################
### Game Over ###
#################
Game_Over:
addi $a0, $zero, 80      
addi $a1, $zero, 64      
addi $a2, $zero, 96         
addi $a3, $zero, 72        
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 81  
addi $a1, $zero, 63       
addi $a2, $zero, 94        
addi $a3, $zero, 70        
add, $t8, $zero, $s4
jal draw_rect

addi $a0, $zero, 84    
addi $a1, $zero, 66       
addi $a2, $zero, 88      
addi $a3, $zero, 65       
add, $t8, $zero, 0xc5d6b6
jal draw_rect

##################################################### Text #######################################################
# X = 104, Y = 72 
add, $t8, $zero, $zero
# Letter R
addi $a0, $zero, 106
addi $a1, $zero, 72
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 106
addi $a1, $zero, 75
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 104
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 109
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 107
addi $a1, $zero, 76
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 108
addi $a1, $zero, 77
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
# Letter E
addi $a0, $zero, 112
addi $a1, $zero, 72
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 112
addi $a1, $zero, 78
addi $a2, $zero, 6
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 112
addi $a1, $zero, 75
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 112
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
# Letter T
addi $a0, $zero, 120
addi $a1, $zero, 72
addi $a2, $zero, 7
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 122
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
# Letter R
addi $a0, $zero, 130
addi $a1, $zero, 72
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 130
addi $a1, $zero, 75
addi $a2, $zero, 4
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 128
addi $a1, $zero, 72
addi $a2, $zero, 2
addi $a3, $zero, 7
jal draw_rect
addi $a0, $zero, 133
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 4
jal draw_rect
addi $a0, $zero, 131
addi $a1, $zero, 76
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 132
addi $a1, $zero, 77
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
# Letter Y
addi $a0, $zero, 136
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 137
addi $a1, $zero, 73
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 138
addi $a1, $zero, 74
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 138
addi $a1, $zero, 76
addi $a2, $zero, 2
addi $a3, $zero, 3
jal draw_rect
addi $a0, $zero, 141
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 140
addi $a1, $zero, 73
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 139
addi $a1, $zero, 74
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
# Question Mark
addi $a0, $zero, 144
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 144
addi $a1, $zero, 72
addi $a2, $zero, 5
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 149
addi $a1, $zero, 72
addi $a2, $zero, 1
addi $a3, $zero, 3
jal draw_rect
addi $a0, $zero, 147
addi $a1, $zero, 75
addi $a2, $zero, 3
addi $a3, $zero, 1
jal draw_rect
addi $a0, $zero, 146
addi $a1, $zero, 75
addi $a2, $zero, 2
addi $a3, $zero, 2
jal draw_rect
addi $a0, $zero, 146
addi $a1, $zero, 78
addi $a2, $zero, 2
addi $a3, $zero, 1
jal draw_rect

###################################################### Draw Mario #####################################################
addi $a0, $zero, 120 
addi $a1, $zero, 92     
addi $a2, $zero, 6    
addi $a3, $zero, 12    
add, $t8, $zero, 0xffffff
jal draw_rect
addi $a0, $zero, 128
addi $a1, $zero, 92     
addi $a2, $zero, 6    
addi $a3, $zero, 12    
add, $t8, $zero, 0xffffff
jal draw_rect

addi $a0, $zero, 118 
addi $a1, $zero, 94     
addi $a2, $zero, 4    
addi $a3, $zero, 2     
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 120 
addi $a1, $zero, 92     
addi $a2, $zero, 4    
addi $a3, $zero, 2     
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 122
addi $a1, $zero, 90     
addi $a2, $zero, 2    
addi $a3, $zero, 2     
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 132
addi $a1, $zero, 94     
addi $a2, $zero, 4    
addi $a3, $zero, 2     
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 130 
addi $a1, $zero, 92     
addi $a2, $zero, 4    
addi $a3, $zero, 2     
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 130
addi $a1, $zero, 90     
addi $a2, $zero, 2    
addi $a3, $zero, 2     
add, $t8, $zero, 0x637355
jal draw_rect

addi $a0, $zero, 124  
addi $a1, $zero, 98     
addi $a2, $zero, 2    
addi $a3, $zero, 4     
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 128  
addi $a1, $zero, 98     
addi $a2, $zero, 2    
addi $a3, $zero, 4     
add, $t8, $zero, 0x637355
jal draw_rect

addi $a0, $zero, 116 
addi $a1, $zero, 112     
addi $a2, $zero, 8    
addi $a3, $zero, 4    
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 118 
addi $a1, $zero, 110   
addi $a2, $zero, 4    
addi $a3, $zero, 2   
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 114
addi $a1, $zero, 112  
addi $a2, $zero, 2  
addi $a3, $zero, 2   
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 118
addi $a1, $zero, 114  
addi $a2, $zero, 16 
addi $a3, $zero, 2   
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 132
addi $a1, $zero, 110   
addi $a2, $zero, 4    
addi $a3, $zero, 2   
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 130
addi $a1, $zero, 112   
addi $a2, $zero, 8    
addi $a3, $zero, 4   
add, $t8, $zero, 0x637355
jal draw_rect
addi $a0, $zero, 138 
addi $a1, $zero, 112     
addi $a2, $zero, 2    
addi $a3, $zero, 2    
add, $t8, $zero, 0x637355
jal draw_rect

addi $a0, $zero, 126  
addi $a1, $zero, 118   
addi $a2, $zero, 2    
addi $a3, $zero, 2    
add, $t8, $zero, 0x637355
jal draw_rect

check_press:
lw $t0, keyboard_address
lw $t8, 0 ($t0) 
beq $t8, 1, check_r
j check_press

check_r:
lw $t0, keyboard_address
lw $t8, 4 ($t0) 
beq $t8, 0x72, select_speed # Difficulty is 1
j check_r

retry:
# j ...

#################
### Load Menu ###
#################

Load_Menu:
addi $a0, $zero, 80      
addi $a1, $zero, 32    
addi $a2, $zero, 96         
addi $a3, $zero, 32        
add, $t8, $zero, 0xe6a015
jal draw_rect

addi $a0, $zero, 81  
addi $a1, $zero, 33      
addi $a2, $zero, 94        
addi $a3, $zero, 30        
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 82    
addi $a1, $zero, 34      
addi $a2, $zero, 92      
addi $a3, $zero, 28      
add, $t8, $zero, 0xc5d6b6
jal draw_rect

check_key_1:
lw $t0, keyboard_address
lw $t8, 0 ($t0) 
beq $t8, 1, check_diff
j check_key_1

check_diff:
lw $t0, keyboard_address
lw $t8, 4 ($t0) 
beq $t8, 0x31, select_speed # Difficulty is 1
beq $t8, 0x32, select_speed # Difficulty is 2
beq $t8, 0x33, select_speed # Difficulty is 3
j check_diff

select_speed:
addi $a0, $zero, 80      
addi $a1, $zero, 112  
addi $a2, $zero, 96         
addi $a3, $zero, 32        
add, $t8, $zero, 0xe6a015

jal draw_rect

addi $a0, $zero, 81  
addi $a1, $zero, 113     
addi $a2, $zero, 94        
addi $a3, $zero, 30        
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 82    
addi $a1, $zero, 114     
addi $a2, $zero, 92      
addi $a3, $zero, 28      
add, $t8, $zero, 0xc5d6b6
jal draw_rect

check_key_2:
lw $t0, keyboard_address
lw $t8, 0 ($t0) 
beq $t8, 1, check_speed
j check_key_2

check_speed:
lw $t0, keyboard_address
lw $t8, 4 ($t0) 
beq $t8, 0x31, select_level # Speed is 1
beq $t8, 0x32, select_level # Speed is 2
beq $t8, 0x33, select_level # Speed is 3
j check_speed

select_level:
addi $a0, $zero, 80      
addi $a1, $zero, 192   
addi $a2, $zero, 96         
addi $a3, $zero, 32        
add, $t8, $zero, 0xe6a015

jal draw_rect

addi $a0, $zero, 81  
addi $a1, $zero, 193    
addi $a2, $zero, 94        
addi $a3, $zero, 30        
add, $t8, $zero, $zero
jal draw_rect

addi $a0, $zero, 82    
addi $a1, $zero, 194  
addi $a2, $zero, 92      
addi $a3, $zero, 28      
add, $t8, $zero, 0xc5d6b6
jal draw_rect

check_key_3:
lw $t0, keyboard_address
lw $t8, 0 ($t0) 
beq $t8, 1, check_level
j check_key_3

check_level:
lw $t0, keyboard_address
lw $t8, 4 ($t0) 
beq $t8, 0x31, start_game # Speed is 1
beq $t8, 0x32, start_game # Speed is 2
beq $t8, 0x33, start_game # Speed is 3
j check_level

start_game:
addi $a0, $zero, 0    
addi $a1, $zero, 0      
addi $a2, $zero, 256      
addi $a3, $zero, 256     
add, $t8, $zero, $zero
jal draw_rect

j Draw_Graphics

#######################
### Other Functions ###
#######################
#
#  The rectangle drawing function
#
#  $a0 = X coordinate for start of the line
#  $a1 = Y coordinate for start of the line
#  $a2 = wdith of the rectangle 
#  $a3 = height of the rectangle 
#  $t0 = the current row being drawn 
draw_rect:
add $t0, $zero, $zero       # create a loop variable with an iniital value of 0
row_start:
# Use the stack to store all registers that will be overwritten by draw_line
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $t0, 0($sp)              # store $t0 on the stack
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $a0, 0($sp)              # store $a0 on the stack
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $a1, 0($sp)              # store $a1 on the stack
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $a2, 0($sp)              # store $a2 on the stack
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

jal draw_line               # call the draw_line function

# restore all the registers that were stored on the stack
lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
lw $a2, 0($sp)              # restore $a2 from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
lw $a1, 0($sp)              # restore $a1 from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
lw $a0, 0($sp)              # restore $a0 from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
lw $t0, 0($sp)              # restore $t0 from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element

addi $a1, $a1, 1            # move to the next row to draw
addi $t0, $t0, 1            # increment the row variable by 1
beq $t0, $a3, row_end       # when the last line has been drawn, break out of the line-drawing loop
j row_start                 # jump to the start of the line-drawing section
row_end:
jr $ra                      # return to the calling program

#
#  The line drawing function
#
#  $a0 = X coordinate for start of the line
#  $a1 = Y coordinate for start of the line
#  $a2 = length of the line
#  
draw_line:
add $t1, $t8, $zero           # Set the colour of the line (to yellow)
lw $t0, displayaddress      # $t0 = base address for display
sll $a1, $a1, 10             # Calculate the Y offset to add to $t0 (multiply $a1 by 128)
sll $a0, $a0, 2             # Calculate the X offset to add to $t0 (multiply $a0 by 4)
add $t2, $t0, $a1           # Add the Y offset to $t0, store the result in $t2
add $t2, $t2, $a0           # Add the X offset to $t2 ($t2 now has the starting location of the line in bitmap memory)
# Calculate the final point in the line (start point + length x 4)
sll $a2, $a2, 2             # Multiply the length by 4
add $t3, $t2, $a2           # Calculate the address of the final point in the line, store result in $t3.
# Start the loop
line_start:
sw $t1, 0($t2)              # Draw a yellow pixel at the current location in the bitmap
# Loop until the current pixel has reached the final point in the line.
addi $t2, $t2, 4            # Move the current location to the next pixel
beq $t2, $t3, line_end      # Break out of the loop when $t2 == $t3
j line_start
# End the loop
line_end:
# Return to calling program
jr $ra

################################################### Curving Functions ####################################################################

ul_curves:        # Curves upper left edges
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

add $t5 $zero, $a0
add $t6, $zero, $a1
addi $a2, $zero, 2
addi $a3, $zero, 2
jal draw_rect

addi $a0, $t5, 2         
add $a1, $zero, $t6         
addi $a2, $zero, 3
addi $a3, $zero, 1
jal draw_rect

add $a0, $zero, $t5         
addi $a1, $t6, 2         
addi $a2, $zero, 1
addi $a3, $zero, 3
jal draw_rect

lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
jr $ra

ur_curves:          # Curves upper right edges     
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

add $t5 $zero, $a0
add $t6, $zero, $a1
addi $a2, $zero, 2
addi $a3, $zero, 2
jal draw_rect

subi $a0, $t5, 2         
add $a1, $zero, $t6         
addi $a2, $zero, 3
addi $a3, $zero, 1
jal draw_rect

addi $a0, $t5, 1          
addi $a1, $t6, 2         
addi $a2, $zero, 1
addi $a3, $zero, 3
jal draw_rect   

lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
jr $ra

bl_curves:                  # Curves bottom left corners
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

add $t5 $zero, $a0
add $t6, $zero, $a1
addi $a2, $zero, 2
addi $a3, $zero, 2
jal draw_rect

addi $a0, $t5, 2         
addi $a1, $t6, 1         
addi $a2, $zero, 3
addi $a3, $zero, 1
jal draw_rect

add $a0, $zero, $t5         
subi $a1, $t6, 2         
addi $a2, $zero, 1
addi $a3, $zero, 3
jal draw_rect

lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
jr $ra

br_curves:                   # Curves bottom right corners
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

add $t5 $zero, $a0
add $t6, $zero, $a1
addi $a2, $zero, 2
addi $a3, $zero, 2
jal draw_rect

subi $a0, $t5, 2         
addi $a1, $t6, 1         
addi $a2, $zero, 3
addi $a3, $zero, 1
jal draw_rect

addi $a0, $t5, 1         
subi $a1, $t6, 3         
addi $a2, $zero, 1
addi $a3, $zero, 3
jal draw_rect

lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
jr $ra

s_ul_curves:        # Curves upper left edges (small)
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

add $t5 $zero, $a0
add $t6, $zero, $a1
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

addi $a0, $t5, 1         
add $a1, $zero, $t6         
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

add $a0, $zero, $t5         
addi $a1, $t6, 1         
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
jr $ra

s_ur_curves:          # Curves upper right edges     
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

add $t5 $zero, $a0
add $t6, $zero, $a1
addi $a0, $t5, 1 
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

subi $a0, $t5, 0         
add $a1, $zero, $t6         
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

addi $a0, $t5, 1          
addi $a1, $t6, 1         
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect   

lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
jr $ra

s_bl_curves:                  # Curves bottom left corners
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

add $t5 $zero, $a0
add $t6, $zero, $a1
addi $a1, $t6, 1 
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

addi $a0, $t5, 1         
addi $a1, $t6, 1         
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

add $a0, $zero, $t5         
addi $a1, $t6, 0         
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
jr $ra

s_br_curves:                   # Curves bottom right corners
addi $sp, $sp, -4           # move the stack pointer to the next empty spot on the stack
sw $ra, 0($sp)              # store $ra on the stack

add $t5 $zero, $a0
add $t6, $zero, $a1
addi $a0, $t5, 1         
addi $a1, $t6, 1 
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

addi $a0, $t5, 0         
addi $a1, $t6, 1         
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

addi $a0, $t5, 1        
subi $a1, $t6, 0         
addi $a2, $zero, 1
addi $a3, $zero, 1
jal draw_rect

lw $ra, 0($sp)              # restore $ra from the stack
addi $sp, $sp, 4            # move the stack pointer to the new top element
jr $ra

end_background:
lw $ra, 0($sp)      # Read return address from the stack
addi $sp, $sp, 4
jr $ra  

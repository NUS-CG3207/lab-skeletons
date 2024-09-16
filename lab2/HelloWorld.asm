#----------------------------------------------------------------------------------
#-- (c) Rajesh Panicker
#--	License terms :
#--	You are free to use this code as long as you
#--		(i) DO NOT post it on any public repository;
#--		(ii) use it only for educational purposes;
#--		(iii) accept the responsibility to ensure that your implementation does not violate anyone's intellectual property.
#--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
#--		(v) send an email to rajesh<dot>panicker<at>ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
#--		(vi) retain this notice in this file and any files derived from this.
#----------------------------------------------------------------------------------

# This sample program prints "Welcome to CG3207" in response to "A\r" (A+Enter) received from Console. There should be sufficient time gap between the press of 'A' and '\r'
# if the processor is run at a low freq.

.eqv LSB_MASK 0xFF

# ------- <code memory (ROM mapped to Instruction Memory) begins>
.text	## IROM segment 0x00000000-0x000001FC
# Total number of instructions should not exceed 128 (127 excluding the last line 'halt B halt').

# Note : see the wiki regarding the pseudoinstructions li and la. 
# Pseudoinstructions may be implemented using more than one actual instruction. See the assembled code in the Execute tab of RARS
# You can also use the actual register numbers directly. For example, instead of s6, you can write x22

main:   
	li s6, LSB_MASK			# A mask for extracting out the LSB to check for '\0'
	la s7, LEDS			# LEDs
	la s8, CONSOLE_OUT_ready	# UART ready for output flag
	la s9, CONSOLE_IN_valid		# UART new data flag
	la s10, CONSOLE			# UART
	li s11, 0x00002418		# SEVENSEG. Used li just to test lui
	#la s11, SEVENSEG

WAIT_A:
	lw t1, (s9)		# read the new character flag
	beq t1, zero, WAIT_A	# go back and wait if there is no new character. Could have been written as pseudoinstruction beqz t1, WAIT_A
	lw t0, (s10)		# read UART (first character. 'A' - 0x41 expected)
ECHO_A:
	lw t1, (s8)		# check if the UART is ready to be written
	beqz t1, ECHO_A
	sw t0, (s10)		# echo received character to the console
	sw t0, (s11)		# show received character (ASCII) on the 7-Seg display
	sw t0, (s7)		# show received character (ASCII) on the LEDs
	li t2, 'A'
	bne t0, t2, WAIT_A	# not 'A'. Continue waiting
WAIT_CR:			# 'A' received. Need to wait for '\r' (Carriage Return - CR).
	lw t1, (s9)		# read the new character flag
	beqz t1, WAIT_CR	# go back and wait if there is no new character
	lw t0, (s10) 		# read UART (second character. '\r' expected)
ECHO_CR:
	lw t1, (s8)		# check if the UART is ready to be written
	beqz t1, ECHO_CR
	sw t0, (s10)		# echo received character to the console
	sw t0, (s11)		# show received character (ASCII) on the 7-Seg display
	sw t0, (s7)		# show received character (ASCII) on the LEDs
	beq t0, t2, WAIT_CR 	# perhaps the user is trying again before completing the pervious attempt, or 'A' was repeated. Just a '\r' needed as we already got an 'A'
	li t1, '\r'
	bne t0, t1, WAIT_A	# not the correct pattern. try all over again.
	# "A\r" received. 
	la a0, string1		# a0 stores the value to be displayed. This is the argument passed to PRINT_S
PRINT_S:			# Call PRINT_S subroutine (not implemented as a subroutine for now as jal doesn't have link and jalr is not implemented)		
	lw t0, (a0)		# load the word (4 characters) to be displayed
	# sw t0, (s11)		# write to seven segment display
	li t2, 4		# byte counter
NEXTCHAR:
	lw t1, (s8)		# check if CONSOLE is ready to send a new character
	beqz t1, NEXTCHAR	# not ready, continue waiting
	and t1, t0, s6 		# apply LSB_MASK
	beqz t1, WAIT_A 	# null terminator ('\0') detected, done. Return to top
	sw t1, (s10) 		# write to UART the Byte(4-t2) of the original word (composed of 4 characters) in (7:0) of the word to be written (remember, we can only write words, and LEDs/UART displays only (7:0) of the written word)
	srli t0, t0, 8	 	# shift so that the next character comes into LSB
	li t1, 1		# note : no subi instruction in RV
	sub t2, t2, t1		# decrement the loop counter
	bnez t2, NEXTCHAR	# check and print the next character in the word
	addi a0, a0, 4		# point to next word (4 characters)
	jal PRINT_S
halt:	
	jal halt		# infinite loop to halt computation. A program should not "terminate" without an operating system to return control to
				# keep halt: jal halt as the last line of your code, though not strictly necessary if there is an infinite loop somewhere.
				
# ------- <code memory (ROM mapped to Instruction Memory) ends>			
				
				
				
					
#------- <constant memory (ROM mapped to Data Memory) begins>									
.data	## DROM segment 0x00002000-0x000021FC
# All constants should be declared in this section. This section is read only (Only lw, no sw).
# Total number of constants should not exceed 128
# If a variable is accessed multiple times, it is better to store the address in a register and use it rather than load it repeatedly.
DROM:
string1:
.asciz "\r\nWelcome to CG3207..\r\n"

#------- <constant memory (ROM mapped to Data Memory) ends>									




# ------- <variable memory (RAM mapped to Data Memory) begins>
.align 9 ## DRAM segment. 0x00002200-0x000023FC #assuming rodata size of <= 512 bytes (128 words)
# All variables should be declared in this section, adjusting the space directive as necessary. This section is read-write.
# Total number of variables should not exceed 128. 
# No initialization possible in this region. In other words, you should write to a location before you can read from it (i.e., write to a location using sw before reading using lw).
DRAM:
.space 512

# ------- <variable memory (RAM mapped to Data Memory) ends>




# ------- <memory-mapped input-output (peripherals) begins>
.align 9 ## MMIO segment. 0x00002400-0x00002418
MMIO:
LEDS: .word 0x0			# 0x00002400	# Address of LEDs. //volatile unsigned int * LEDS = (unsigned int*)0x00000C00#  
DIPS: .word 0x0			# 0x00002404	# Address of DIP switches. //volatile unsigned int * DIPS = (unsigned int*)0x00000C04#
PBS: .word 0x0			# 0x00002408	# Address of Push Buttons. Used only in Lab 2
CONSOLE: .word 0x0		# 0x0000240C	# Address of UART. Used only in Lab 2 and later
CONSOLE_IN_valid: .word 0x0	# 0x00002410	# Address of UART. Used only in Lab 2 and later
CONSOLE_OUT_ready: .word 0x0	# 0x00002414	# Address of UART. Used only in Lab 2 and later
SEVENSEG: .word	0x0		# 0x00002418	# Address of 7-Segment LEDs. Used only in Lab 2 and later

# ------- <memory-mapped input-output (peripherals) ends>




########################### Ignore the code below #######################################
	#auipc ra,0	# If using a subroutine, store the return value manually since we do not have link
	#addi ra, 12	# just before a jump to store PC+4 in ra
	# not using the subroutine for now, as the only way to return is jalr which isn't implemented for Lab 2

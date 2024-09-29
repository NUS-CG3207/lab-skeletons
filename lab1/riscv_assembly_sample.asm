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

# This sample program for RISC-V simulation using RARS

# ------- <code memory (ROM mapped to Instruction Memory) begins>
.text	## IROM segment 0x00000000-0x000001FC
# Total number of instructions should not exceed 128 (127 excluding the last line 'halt B halt').

# Note: see the wiki regarding the pseudoinstructions li and la. 
# Pseudoinstructions may be implemented using more than one actual instruction. See the assembled code in the Execute tab of RARS
# You can also use the actual register numbers directly. For example, instead of s1 (ABI name), you can write x9, but the former is preferred

main:   
	la s1, LEDS		# LEDs
	li s2, 0x00002404	# DIPs. could have been done using > la s2, DIPS. Hardcoding to show the use of li.
loop:
	lw s3, DELAY_VAL	# reading the loop counter value
	lw s4, (s2)		# reading DIPS
	sw s4, (s1)		# writing to LEDS

wait:
	addi s3, s3, -1		# subtract 1
	beq s3, zero, loop	# exit the loop
	j wait			# continue in the loop

halt:	
	j halt			# infinite loop to halt computation. A program should not "terminate" without an operating system to return control to
				# keep halt: j halt as the last line of your code, though not strictly necessary if there is an infinite loop somewhere.
				
# ------- <code memory (ROM mapped to Instruction Memory) ends>			
				
				
				
					
#------- <constant memory (ROM mapped to Data Memory) begins>									
.data	## DROM segment 0x00002000-0x000021FC
# All constants should be declared in this section. This section is read only (Only lw, no sw).
# Total number of constants should not exceed 128
# If a variable is accessed multiple times, it is better to store the address in a register and use it rather than load it repeatedly.
DROM:
DELAY_VAL: .word 4
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
LEDS: .word 0x0			# 0x00002400	# Location simulating LEDs. //volatile unsigned int* LEDS = (unsigned int*)0x00002400#  
DIPS: .word 0x0			# 0x00002404	# Location simulating DIP switches. //volatile unsigned int* DIPS = (unsigned int*)0x00002404#
PBS: .word 0x0			# 0x00002408	# Location simulating Push Buttons. Used only in Lab 2
CONSOLE: .word 0x0		# 0x0000240C	# Location simulating UART. Used only in Lab 2 and later
CONSOLE_IN_valid: .word 0x0	# 0x00002410	# Location simulating UART input valid flag. Used only in Lab 2 and later
CONSOLE_OUT_ready: .word 0x0	# 0x00002414	# Location simulating UART ready for output flag. Used only in Lab 2 and later
SEVENSEG: .word	0x0		# 0x00002418	# Location simulating 7-Segment LEDs. Used only in Lab 2 and later

# ------- <memory-mapped input-output (peripherals) ends>

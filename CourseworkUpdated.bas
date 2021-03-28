;Program To take in temperature reading and turn on the fan or the heater based on the level of temperature

;Simulation Assumptions:
	;A.0 is the analogue reading of the room temperature
	;A.1 is the digital button input for the fan override
	;A.2 is the potentiometer analogue input for the heater
	;B.1 connects to the fan
	;B.3 connects to the heater
	;B.4 connects an LED that shows if the system is running manually (on override)
	
init:
	;Port Setup
	clrf PORTB		;Clear any potential residue left in PORTB.
	bsf STATUS,RP0	;Memory Page 1
	movlw b'00000000'	;Set PORTB pins to output
	movwf TRISB		;Write to TRIS register
	movlw b'11111111'	;Set PORTA pins to input
	movwf TRISA		;Write to TRIS register
	bcf STATUS,RP0	;Memory Page 0
	
	DEL equ B5	;The file register B.5 will be renamed to 'DEL'
	
	bcf PORTB,3	;Turn the heater OFF at startup, in case it was ON before.
	bcf PORTB,1	;Turn the fan OFF for the same reason as above.

check_override:
	;Check if the user has overridden the automatic system
	btfsc PORTA,1		;Skip if manual fan input is OFF
	goto fan_override
	btfsc PORTA,2		;Skip if manual heater input is OFF
	goto heater_override
	goto check_temp		;None of the conditions above were met, so default to the automatic temperature pivoting system.

check_temp:
	bcf PORTB,4		;Override is no longer active, because temperature pivot system is about to run in the following lines, so turn the override indicator LED OFF.
	
	btfsc PORTA,0	;Skip if the temperature reading given by the thermistor is considered by the comparator to be too cold.
	goto too_hot
	goto too_cold
	
too_hot:
	;Too hot, switch the fan ON.
	bcf PORTB,3	;Turns the heater OFF
	bsf PORTB,1	;Turns the fan ON
	goto check_override

too_cold:
	;Too cold, switch the heater ON.
	bcf PORTB,1	;Turns the fan OFF
	bsf PORTB,3	;Turns the heater ON
	goto check_override

fan_override:
	call delay_length	;The delay will begin upon override.
	bsf PORTB,1		;Turns the fan ON
	bcf PORTB,3		;Turns the heater OFF
	bsf PORTB,4		;LED to indicate override is in action.
	goto check_override
	
heater_override:
	call delay_length	;The delay will begin upon override.
	bsf PORTB,3		;Turns the heater ON
	bcf PORTB,1		;Turns the fan OFF
	bsf PORTB,4		;LED to indicate override is in action.

	goto check_override

delay_length:
	movlw d'6'	;Assign literal decimal value '6' in the working register.
	movwf DEL	;Move said decimal value to the 'DEL' file register.
	
time_delay:
	decfsz DEL,F	;Decrement by 1 in the 'DEL' file register and store the result in the same 'DEL' file register.
	goto time_delay	;loop the decrement.
	nop			;No Operation, since skipping to a return isn't handled well by the software.
	return		;Go back to call line position.
;Program To take in temperature reading and turn on the fan or the heater based on the level of temperature

;TODO:
;	Get the DAC setup and working with analogue values. (The DAC must output the correct analogue voltage to the heater, based on the analogue value of the ADC)
;	Get the switches, instead of buttons, working for the fan override system, because the override must stay on when its pressed or switched, and stay off when pressed off.
;	Develop the time delay as a seperate label that can be called to get more marks. This delay is added to avoid user spam that could lead to damaging the moving parts of the fan. /DONE

;Simulation Assumptions:
	;A.0 is the analogue reading of the room temperature
	;A.1 is the digital button input for the fan override
	;A.2 is the potentiometer analogue input for the heater
	;B.0 is the copied analogue reading of the room temperature
	;B.1 connects to the fan
	;B.2 is the copied analogue reading of the temperature dial (potentiometer)
	;B.3 connects to the heater
	;B.4 connects an LED that shows if the system is running manually (on override)
	
	;A.0 reading scale: - Numbers will be changed based on the real values that the thermistor divider produces with a limited range using fixed resistors.
	;	0 is less than or equal to 10 degrees
	;	128 is exactly 20 degrees
	;	255 is greater than or equal to 30 degrees
	;	Pivot around 128 (20 degrees)
	
	;A.2 reading scale: - Numbers will be changed based on the real values that the thermistor divider produces with a limited range using fixed resistors.
	;	0 is heater off
	;	50 is ~10 degrees
	;	100 is ~15 degrees
	;	150 is ~20 degrees
	;	200 is ~25 degrees
	;	250 is ~30 degrees
	
init:
	bsf status,RP0
	movlw b'00000000'
	movwf trisb
	movlw b'11111111'
	movwf trisa
	bcf status,RP0
	
	del equ b5	;The file register B.5 will be renamed to 'del'
	
	low B.3	;Turn the heater off at startup, in case it was on before.
	low B.1	;Turn the fan off for the same reason as above.

check_override:
	;Check if the user has overridden the automatic system
	btfsc porta,1
	goto fan_override
	call readadc2	;Read the temperature voltage value at A.2 and move that to B.2 (b2).
	if b2 < 50 then check_temp	;Potentiometer has not been moved enough to turn the heater on manually.
	if b2 >= 50 then heater_override	;Potentiometer has been moved enough to heat the room at, at least, 10 degrees.

check_temp:
	;Override is no longer active, because the temperature pivot system is going to run in the following lines, therefore set the LEDs to be off
	low B.4

	;Read the temperature voltage value at A.0 and move that reading value to B.0.
	call readadc0
	
	;The values below are based on the analogue signal range that can enter the port (0-255), therefore, 255 is logic 1 and 0 is logic 0.
	;if the B.0 port has an analogue signal below 50, it will output heat to reach the 20 degree pivot point.
	if b0 < 128 then too_cold	;Too Cold, heater on, fan off
	if b0 > 128 then too_hot	;Too Hot, heater off, fan on
	if b0 = 128 then check_temp	;If the temperature is perfectly balanced at 128 (not very common) then keep checking the temperature.
	
too_hot:
	;Too hot, switch the fan on.
	low B.3	;Turns the heater off
	high B.1	;Turns the fan on
	goto check_override
	
too_cold:
	;Too cold, switch the heater on.
	low B.1	;Turns the fan off
	high B.2	;Turns the heater on
	goto check_override

fan_override:
	call delay_length
	high B.1
	high B.4	;LED to indicate override
	;Use switches rather than buttons to turn the fan on/off on previous line (55)
	goto check_override
	
heater_override:
	call delay_length
	high B.4	;LED to indicate override
	; The following if statements check if the analogue ADC value 
	; read from the potentiometer input of the heater override, 
	; is between a certain analogue voltage bounds, so that a 
	; specific amount of analogue signal can be sent to the heater
	; to heat up a certain amount given.
	; E.g. If the potentiometer is letting in 50mA, that value will correspond
	; to a certain temperature that the heater will generate with that current, like 20 degrees.
	if b2 >= 50 and b2 < 100 then
		b3 = 50
	else if b2 >= 100 and b2 < 150 then
		b3=100
	else if b2 >= 150 and b2 < 200 then
		b3=150
	else if b2 >= 200 and b2 < 250 then 
		b3=200
	else if b2 >= 250 then 
		b3=250
	endif
	goto check_override

delay_length:
	movlw d'3'
	movwf del
	
time_delay:
	decfsz del,F
	goto time_delay
	nop
	return
	
	
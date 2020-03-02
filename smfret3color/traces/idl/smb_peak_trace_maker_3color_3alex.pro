
pro smb_peak_trace_maker_3color_3alex, run, text_ID, color_number_input

	;3color blue-green-red 3ALEX
	color_number = 3
	alex_number = 3
	; Custumizing parameters
	spot_diameter = 7				;summing region, 512 image-> 9 or 7 , 256 image-> 7 or 5


	;Program start
	
	loadct, 5
	device, decomposed=0

	COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR


	; generate gaussian peaks

	g_peaks = fltarr(7,7)

	for i = 0, 6 do begin
		for j = 0, 6 do begin
			dist = 0.3 * ((float(i)-3.0)^2 + (float(j)-3.0)^2) ;jayil trial
			;dist = 0.3 * ((float(i)-3.0)^2 + (float(j)-3.0)^2)  ;original
			g_peaks(i,j) = 2.0*exp(-dist)
		endfor
	endfor


	; input film

	if N_PARAMS() eq 0 then begin
		run = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a .pma file.', /READ, FILTER = '*.pma')
		;run = DIALOG_PICKFILE(PATH='X:\USER2\Juyeon_Lee\20150911\anal2', TITLE='Select a .pma file.', /READ, FILTER = '*.pma')
		xdisplayFile, '', TEXT=(run + " is selected."), RETURN_ID=display_ID, WTEXT=text_ID
		run = strmid(run, 0, strlen(run) - 4)
	endif

	if N_PARAMS() eq 1 then begin
		xdisplayFile, '', TEXT=(run + ".pma is selected."), RETURN_ID=display_ID, WTEXT=text_ID
	endif

	if N_PARAMS() eq 2 then begin
		WIDGET_CONTROL, text_ID, SET_VALUE=(run + ".pma is selected."), /APPEND,  /SHOW
	endif
	
	if N_PARAMS() eq 3 then begin
		WIDGET_CONTROL, text_ID, SET_VALUE=(run + ".pma is selected."), /APPEND, /SHOW
		color_number = color_number_input
	endif


	; figure out size + allocate appropriately
	close, 1														; make sure unit 1 is closed
	openr, 1, run + ".pma"

	; figure out size + allocate appropriately
	file_infomation = FSTAT(1)
	film_width = fix(1)
	film_height = fix(1)
	readu, 1, film_width
	readu, 1, film_height
	film_time_length = long(long64(file_infomation.SIZE -long64(4))/(long64(film_width)*long64(film_height)))

	WIDGET_CONTROL, text_ID, SET_VALUE=("Film width, height, time_length : " + STRING(film_width) + STRING(film_height) + STRING(film_time_length)), /APPEND, /SHOW


	; load the locations of the peaks
	;answer=gui_prompt('How many color channel on the display (2 or 3):', title='2 or 3 color')
	;color_number = total(long(answer))
	
  openr, 2, run + ".3color_3alex_pks"

	
	GoodLocations_x = intarr(4000)
	GoodLocations_y = intarr(4000)
	Background_blue = dblarr(4000)
	Background_green = dblarr(4000)
	Background_red = dblarr(4000)
	NumberofGoodLocations = fix(1)
	xx = fix(1)
	yy = fix(1)
	back_blue = double(1)
	back_green = double(1)
	back_red = double(1)
	color_change_check='n'
	readf, 2, NumberofGoodLocations
	for i = 0, NumberofGoodLocations - 1 do begin
    	readf, 2, indexdummy, xx, yy, back_blue, back_green, back_red
    	GoodLocations_x(i) = xx
    	GoodLocations_y(i) = yy
    	Background_blue(i) = back_blue
    	Background_green(i) = back_green
    	Background_red(i) = back_red
	endfor
	readf, 2, color_change_check
	close, 2
	
	WIDGET_CONTROL, text_ID, SET_VALUE=("Color change? : " + color_change_check), /APPEND, /SHOW
	
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations/color_number) + " peaks were found in file " + run + ".pma"), /APPEND, /SHOW


	; calculate which peak to use for each time trace based on
	; peak position

	; now read values at peak locations into time_tr array
	
	;answer=gui_prompt('diameter of spot (recommanded=7 pixel) :', title='Diameter')
	;spot_diameter=round(total(long(answer)))

	half_diameter = round((spot_diameter -1)/2)

	if spot_diameter eq 5 then begin
    circle = bytarr(5, 5, /NOZERO)
    circle(*,0) = [ 0,1,1,1,0]
    circle(*,1) = [ 1,1,1,1,1]
    circle(*,2) = [ 1,1,1,1,1]
    circle(*,3) = [ 1,1,1,1,1]
    circle(*,4) = [ 0,1,1,1,0]
  endif
	if spot_diameter eq 7 then begin
		circle = bytarr(7, 7, /NOZERO)
		circle(*,0) = [ 0,0,1,1,1,0,0]
		circle(*,1) = [ 0,1,1,1,1,1,0]
		circle(*,2) = [ 1,1,1,1,1,1,1]
		circle(*,3) = [ 1,1,1,1,1,1,1]
		circle(*,4) = [ 1,1,1,1,1,1,1]
		circle(*,5) = [ 0,1,1,1,1,1,0]
		circle(*,6) = [ 0,0,1,1,1,0,0]
	endif
	if spot_diameter eq 9 then begin
		circle = bytarr(9, 9, /NOZERO)
		circle(*,0) = [ 0,0,0,1,1,1,0,0,0]
		circle(*,1) = [ 0,1,1,1,1,1,1,1,0]
		circle(*,2) = [ 0,1,1,1,1,1,1,1,0]
		circle(*,3) = [ 1,1,1,1,1,1,1,1,1]
		circle(*,4) = [ 1,1,1,1,1,1,1,1,1]
		circle(*,5) = [ 1,1,1,1,1,1,1,1,1]
		circle(*,6) = [ 0,1,1,1,1,1,1,1,0]
		circle(*,7) = [ 0,1,1,1,1,1,1,1,0]
		circle(*,8) = [ 0,0,0,1,1,1,0,0,0]
	endif
	if spot_diameter eq 11 then begin
		circle = bytarr(11, 11, /NOZERO)
		circle(*,0) = [ 0,0,0,0,1,1,1,0,0,0,0]
		circle(*,1) = [ 0,0,1,1,1,1,1,1,1,0,0]
		circle(*,2) = [ 0,1,1,1,1,1,1,1,1,1,0]
		circle(*,3) = [ 0,1,1,1,1,1,1,1,1,1,0]
		circle(*,4) = [ 1,1,1,1,1,1,1,1,1,1,1]
		circle(*,5) = [ 1,1,1,1,1,1,1,1,1,1,1]
		circle(*,6) = [ 1,1,1,1,1,1,1,1,1,1,1]
		circle(*,7) = [ 0,1,1,1,1,1,1,1,1,1,0]
		circle(*,8) = [ 0,1,1,1,1,1,1,1,1,1,0]
		circle(*,9) = [ 0,0,1,1,1,1,1,1,1,0,0]
		circle(*,10) = [ 0,0,0,0,1,1,1,0,0,0,0]
	endif
	
	frame  = bytarr(film_width, film_height, /NOZERO)
	temp  = dblarr(spot_diameter, spot_diameter)    ; temp storage for analysis
	
	;if color_change_check eq 'y' then begin
	;	film_time_length = film_time_length-1
	;	readu, 1, frame
	;endif
	
	time_trace = intarr(NumberofGoodLocations, film_time_length, /NOZERO)
	
	for t = 0, film_time_length - 1 do begin
		if (t mod 100) eq 0 then begin
			WIDGET_CONTROL, text_ID, SET_VALUE=("Trace Working on : " + STRING(t) + STRING(film_time_length) + "     file : "+ run + ".pma"), /APPEND, /SHOW
		endif
		readu, 1, frame
		for j = 0, NumberofGoodLocations - 1 do begin
			if (t mod 3) eq 0 then begin
				temp = double(circle) * (double(frame((GoodLocations_x(j)-half_diameter):(GoodLocations_x(j)+half_diameter), (GoodLocations_y(j)-half_diameter):(GoodLocations_y(j)+half_diameter))) - Background_blue(j) )
			endif
			if (t mod 3) eq 1 then begin
				temp = double(circle) * (double(frame((GoodLocations_x(j)-half_diameter):(GoodLocations_x(j)+half_diameter), (GoodLocations_y(j)-half_diameter):(GoodLocations_y(j)+half_diameter))) - Background_green(j) )
			endif
			if (t mod 3) eq 2 then begin
			  temp = double(circle) * (double(frame((GoodLocations_x(j)-half_diameter):(GoodLocations_x(j)+half_diameter), (GoodLocations_y(j)-half_diameter):(GoodLocations_y(j)+half_diameter))) - Background_red(j) )
			endif
			time_trace(j, t) = round(total(temp))
		endfor
	endfor
	close, 1

	openw, 1, run + ".3color_3alex_traces"

	writeu, 1, film_time_length
	writeu, 1, NumberofGoodLocations
	writeu, 1, time_trace
	writeu, 1, spot_diameter
	close, 1

	WIDGET_CONTROL, text_ID, SET_VALUE="Trace maker for " + run + ".pma file.", /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE="Done. ", /APPEND, /SHOW

end
;
; loads film and makes a tif image from it
;
; hazen 12/98
;
;
; Heesoo 12/3/2008
;
; Filenames were maketiff.pro + calc_mapping2.pro + nxgn1_cm.pro  until this point.
;
; From this point, filename is mapping_maker_smb.pro all together.
;

pro mapping_maker_smb_3, run, text_ID

	loadct, 5
	device, decomposed=0

	COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

	if N_PARAMS() eq 0 then begin
		run = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a File to make a mapping file', /READ, FILTER = '*.pma')
		xdisplayFile, '', TEXT=(run + " is selected to make a mapping file."), RETURN_ID=display_ID, WTEXT=text_ID
		run = strmid(run, 0, strlen(run) - 4)
	endif else begin
		WIDGET_CONTROL, text_ID, SET_VALUE=(run + " is selected to make a mapping file."), /APPEND, /SHOW
	endelse

	; figure out size + allocate appropriately
	close, 1          ; make sure unit 1 is closed
	openr, 1, run + ".pma"

	file_infomation = FSTAT(1)
	film_width = fix(1)
	film_height = fix(1)
	readu, 1, film_width
	readu, 1, film_height
	film_time_length = long(long(file_infomation.SIZE-4)/(long(film_width)*long(film_height)))

	WIDGET_CONTROL, text_ID, SET_VALUE=("Film width, height, time_length : " + STRING(film_width) + STRING(film_height) + STRING(film_time_length)), /APPEND, /SHOW

	frame   = bytarr(film_width, film_height, /NOZERO)
	frame_average = fltarr(film_width, film_height, /NOZERO)

	answer= 0

	film_time_start = 0
	film_time_start = total(long(answer))
	film_time_end = film_time_start + 100

	if film_time_end gt film_time_length then film_time_end = film_time_length

	for j = 0, film_time_start - 1 do begin
		readu, 1, frame
	endfor

	for j = film_time_start, film_time_end - 1 do begin
		readu, 1, frame
		frame_average = temporary(frame_average) + frame
	endfor

	close, 1

	frame_average = temporary(frame_average)/float(film_time_end - film_time_start)
	frame = byte(frame_average)

	window, 0, xsize=film_width, ysize=film_height
	tv, frame

	WRITE_TIFF, run + "_ave.tif", frame, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression=2

	WIDGET_CONTROL, text_ID, SET_VALUE=("Intensity Median value for " + run + ".pma :" + STRING(median(frame))), /APPEND, /SHOW




	circle = bytarr(11, 11, /NOZERO)
	circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
	circle(*,1) = [ 0,0,0,0,1,1,1,0,0,0,0]
	circle(*,2) = [ 0,0,0,1,0,0,0,1,0,0,0]
	circle(*,3) = [ 0,0,1,0,0,0,0,0,1,0,0]
	circle(*,4) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,5) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,6) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,7) = [ 0,0,1,0,0,0,0,0,1,0,0]
	circle(*,8) = [ 0,0,0,1,0,0,0,1,0,0,0]
	circle(*,9) = [ 0,0,0,0,1,1,1,0,0,0,0]
	circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]

	; subtracts background
	temp = smooth(frame, 2, /EDGE_TRUNCATE)

	mininum_intensity_matrix = fltarr(film_width/16,film_height/16, /NOZERO)

	for i = 8, film_width, 16 do begin
    	for j = 8, film_height, 16 do begin
			mininum_intensity_matrix((i-8)/16,(j-8)/16) = min(temp(i-8:i+7,j-8:j+7))
		endfor
	endfor

	mininum_intensity_matrix = rebin(mininum_intensity_matrix, film_width, film_height)
	mininum_intensity_matrix = smooth(mininum_intensity_matrix, 20, /EDGE_TRUNCATE)
;	mininum_intensity_matrix = mininum_intensity_matrix -30

;	modified_frame = frame - byte(mininum_intensity_matrix)
	modified_frame = frame_average - mininum_intensity_matrix


	; thresholds the image for peak finding purposes

	medianofFrame_left = float(median(modified_frame(10:160, 10:500)))
	varianceofFrame_left = variance(modified_frame(10:160, 10:500))
	medianofFrame_middle = float(median(modified_frame(180:330, 10:500)))
	varianceofFrame_middle = variance(modified_frame(180:330, 10:500))
	medianofFrame_right = float(median(modified_frame(350:500, 10:500)))
	varianceofFrame_right = variance(modified_frame(350:500, 10:500))

	deviation_left = sqrt(varianceofFrame_left)
	deviation_middle = sqrt(varianceofFrame_middle)
	deviation_right = sqrt(varianceofFrame_right)
	;deviation = 15

	cutoff_left = byte(medianofFrame_left + deviation_left)
	cutoff_middle = byte(medianofFrame_middle + deviation_middle)
	cutoff_right = byte(medianofFrame_right + deviation_right)

	cutoff = cutoff_left < cutoff_right < cutoff_middle

	truncated_frame = (modified_frame gt cutoff)*modified_frame

	window, 1, xsize=film_width, ysize=film_height
	tv, (truncated_frame>0)
	wset, 0
	tv, modified_frame


	; find the peaks
	;circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
	;circle(*,1) = [ 0,0,0,0,1,1,1,0,0,0,0]
	;circle(*,2) = [ 0,0,0,1,0,0,0,1,0,0,0]
	;circle(*,3) = [ 0,0,1,0,0,0,0,0,1,0,0]
	;circle(*,4) = [ 0,1,0,0,0,0,0,0,0,1,0]
	;circle(*,5) = [ 0,1,0,0,0,0,0,0,0,1,0]
	;circle(*,6) = [ 0,1,0,0,0,0,0,0,0,1,0]
	;circle(*,7) = [ 0,0,1,0,0,0,0,0,1,0,0]
	;circle(*,8) = [ 0,0,0,1,0,0,0,1,0,0,0]
	;circle(*,9) = [ 0,0,0,0,1,1,1,0,0,0,0]
	;circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]

	circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
	circle(*,1) = [ 0,0,0,0,0,0,0,0,0,0,0]
	circle(*,2) = [ 0,0,0,0,1,1,1,0,0,0,0]
	circle(*,3) = [ 0,0,0,1,0,0,0,1,0,0,0]
	circle(*,4) = [ 0,0,1,0,0,0,0,0,1,0,0]
	circle(*,5) = [ 0,0,1,0,0,0,0,0,1,0,0]
	circle(*,6) = [ 0,0,1,0,0,0,0,0,1,0,0]
	circle(*,7) = [ 0,0,0,1,0,0,0,1,0,0,0]
	circle(*,8) = [ 0,0,0,0,1,1,1,0,0,0,0]
	circle(*,9) = [ 0,0,0,0,0,0,0,0,0,0,0]
	circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]

	temp = truncated_frame
	temp_emphasized = truncated_frame

	GoodLocations_x = intarr(4000,1)
	GoodLocations_y = intarr(4000,1)
	NumberofGoodLocations = 0
	NumberofBadLocations = 0
	for j = 10, film_height - 11 do begin
		for i = 10, film_width - 11 do begin
			if i eq 160 then i = 180   ; skip region where Cy3 and Cy5 channels overlap
			if i eq 330 then i = 350   ; skip region where Cy5 and Cy7 channels overlap

			if truncated_frame(i,j) gt 0 then begin

				; find the nearest maxima

				MaxIntensity_local = max(modified_frame(i-3:i+3,j-3:j+3), Max_location)
				Max_location_x_y = ARRAY_INDICES(modified_frame(i-3:i+3,j-3:j+3), Max_location)
				Max_location_x = Max_location_x_y[0] - 3
				Max_location_y = Max_location_x_y[1] - 3

				; only analyze peaks in current column,
				; and not near edge of area analyzed

				if (Max_location_x eq 0) and (Max_location_y eq 0) then begin

					Max_location_x=i
					Max_location_y=j

					; check if its a good peak
					; i.e. surrounding points below 1 stdev

					aroundMax_left = Max_location_x - 5
					aroundMax_right = Max_location_x + 5
					aroundMax_bottom = Max_location_y - 5
					aroundMax_top = Max_location_y + 5
					cutoff=byte(0.75 * float(MaxIntensity_local))
					quality=total( (modified_frame(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) gt cutoff) * (circle eq 1) )

					if quality lt 3 then begin

						; draw where peak was found on screen

						temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90

						wset, 0
						tv, temp

						GoodLocations_x(NumberofGoodLocations) = Max_location_x
						GoodLocations_y(NumberofGoodLocations) = Max_location_y
						NumberofGoodLocations++

						temp_emphasized(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = byte(float(truncated_frame(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top))/MaxIntensity_local*255)
					endif else begin
						NumberofBadLocations++
					endelse
				endif
			endif
		endfor
	endfor

	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations) + " good peaks circled."), /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofBadLocations) + " bad peaks."), /APPEND, /SHOW




	; figure out image corresondence

	circle(*,0) = [ 0,0,0,0,1,1,1,0,0,0,0]
	circle(*,1) = [ 0,0,1,1,0,0,0,1,1,0,0]
	circle(*,2) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,3) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,4) = [ 1,0,0,0,0,0,0,0,0,0,1]
	circle(*,5) = [ 1,0,0,0,0,0,0,0,0,0,1]
	circle(*,6) = [ 1,0,0,0,0,0,0,0,0,0,1]
	circle(*,7) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,8) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,9) = [ 0,0,1,1,0,0,0,1,1,0,0]
	circle(*,10)= [ 0,0,0,0,1,1,1,0,0,0,0]

	x_left = fltarr(3)
	y_left = fltarr(3)
	x_right = fltarr(3)
	y_right = fltarr(3)
	x_middle = fltarr(3)
	y_middle = fltarr(3)

	temp = temp_emphasized
	oldtemp= temp_emphasized

	wset, 0
	tv, oldtemp

	for j = 0, 2 do begin
		WIDGET_CONTROL, text_ID, SET_VALUE=("Click on spot in the image" + STRING(j+1)), /APPEND, /SHOW
		A = 'd'
		while A ne 's' do begin
		wset, 0
		CURSOR, point_x, point_y, /DOWN, /DEVICE
		case !MOUSE.BUTTON of
			1 : begin
					if point_x lt 170 then begin
						x_left(j) = point_x
						y_left(j) = point_y
						x_middle(j) = point_x + 170
						y_middle(j) = point_y
						x_right(j) = point_x + 341
						y_right(j) = point_y
					endif else begin
						if point_x lt 340 then begin
							if x_left(j) eq 0 and x_right(j) eq 0 then begin
								x_left(j) = point_x - 170
								y_left(j) = point_y
								x_middle(j) = point_x
								y_middle(j) = point_y
								x_right(j) = point_x + 170
								y_right(j) = point_y
							endif else begin
								x_middle(j) = point_x
								y_middle(j) = point_y
							endelse
						endif else begin
							if x_left(j) eq 0 and x_middle(j) eq 0 then begin
								x_left(j) = point_x - 340
								y_left(j) = point_y
								x_middle(j) = point_x - 171
								y_middle(j) = point_y
								x_right(j) = point_x
								y_right(j) = point_y
							endif else begin
								x_right(j) = point_x
								y_right(j) = point_y
							endelse
						endelse
					endelse

		;			endif else begin
		;				if x_left(j) eq 0 then begin
		;					x_left(j) = point_x - 256
		;					y_left(j) = point_y
		;					x_right(j) = point_x
		;					y_right(j) = point_y
		;				endif else begin
		;					x_right(j) = point_x
		;					y_right(j) = point_y
		;				endelse
		;			endelse

					; draw spots the user picked
					oldtemp = temp

					left_left = x_left(j) - 5
					left_right = x_left(j) + 5
					left_bottom = y_left(j) - 5
					left_top = y_left(j) + 5
					MaxIntensity_local = max(modified_frame(left_left:left_right, left_bottom:left_top), Max_location)
					Max_location_x_y = ARRAY_INDICES(modified_frame(left_left:left_right, left_bottom:left_top), Max_location)
					x_left(j) = x_left(j) + (Max_location_x_y[0] - 5)
					y_left(j) = y_left(j) + (Max_location_x_y[1] - 5)
					left_left = x_left(j) - 5
					left_right = x_left(j) + 5
					left_bottom = y_left(j) - 5
					left_top = y_left(j) + 5
					oldtemp(left_left:left_right, left_bottom:left_top) = ( (circle eq 0) * temp(left_left:left_right, left_bottom:left_top)) +( (circle gt 0) * 255)


					middle_left = x_middle(j) - 5
					middle_right = x_middle(j) + 5
					middle_bottom = y_middle(j) - 5
					middle_top = y_middle(j) + 5
					MaxIntensity_local = max(modified_frame(middle_left:middle_right, middle_bottom:middle_top), Max_location)
					Max_location_x_y = ARRAY_INDICES(modified_frame(middle_left:middle_right, middle_bottom:middle_top), Max_location)
					x_middle(j) = x_middle(j) + (Max_location_x_y[0] - 5)
					y_middle(j) = y_middle(j) + (Max_location_x_y[1] - 5)
					middle_left = x_middle(j) - 5
					middle_right = x_middle(j) + 5
					middle_bottom = y_middle(j) - 5
					middle_top = y_middle(j) + 5
					oldtemp(middle_left:middle_right, middle_bottom:middle_top) = ( (circle eq 0) * temp(middle_left:middle_right, middle_bottom:middle_top)) +( (circle gt 0) * 255)


					right_left = x_right(j) - 5
					right_right = x_right(j) + 5
					right_bottom = y_right(j) - 5
					right_top = y_right(j) + 5
					MaxIntensity_local = max(modified_frame(right_left:right_right, right_bottom:right_top), Max_location)
					Max_location_x_y = ARRAY_INDICES(modified_frame(right_left:right_right, right_bottom:right_top), Max_location)
					x_right(j) = x_right(j) + (Max_location_x_y[0] - 5)
					y_right(j) = y_right(j) + (Max_location_x_y[1] - 5)
					right_left = x_right(j) - 5
					right_right = x_right(j) + 5
					right_bottom = y_right(j) - 5
					right_top = y_right(j) + 5
					oldtemp(right_left:right_right, right_bottom:right_top) = (circle eq 0) * temp(right_left:right_right, right_bottom:right_top) + (circle gt 0) * 255

					wset, 0
					tv, oldtemp
				end
			4:	begin
					A='s'
					temp=oldtemp
				end
			endcase
		endwhile
	endfor

	; set up matrices

	transformation_matrix_1 = fltarr(3,3)
	transformation_matrix_1(0,*) = 1.0
	transformation_matrix_1(1,*) = x_left
	transformation_matrix_1(2,*) = y_left

	transformation_matrix_2 = fltarr(3,3)
	transformation_matrix_2(0,*) = 1.0
	transformation_matrix_2(1,*) = x_middle
	transformation_matrix_2(2,*) = y_middle

	inversion_matrix_1 = invert(transformation_matrix_1)
	inversion_matrix_2 = invert(transformation_matrix_2)

	; calculate coefficients and save coefficients

	trans_x_13 = fltarr(3)
	trans_y_13 = fltarr(3)
	trans_x_13 = MATRIX_MULTIPLY(inversion_matrix_1, x_right, /ATRANSPOSE)
	trans_y_13 = MATRIX_MULTIPLY(inversion_matrix_1, y_right, /ATRANSPOSE)

	trans_x_12 = fltarr(3)
	trans_y_12 = fltarr(3)
	trans_x_12 = MATRIX_MULTIPLY(inversion_matrix_1, x_middle, /ATRANSPOSE)
	trans_y_12 = MATRIX_MULTIPLY(inversion_matrix_1, y_middle, /ATRANSPOSE)

	trans_x_23 = fltarr(3)
	trans_y_23 = fltarr(3)
	trans_x_23 = MATRIX_MULTIPLY(inversion_matrix_2, x_right, /ATRANSPOSE)
	trans_y_23 = MATRIX_MULTIPLY(inversion_matrix_2, y_right, /ATRANSPOSE)

	openw, 1, run + ".coeff"
	printf, 1, transpose(trans_x_13)
	printf, 1, transpose(trans_y_13)
	printf, 1, transpose(trans_x_12)
	printf, 1, transpose(trans_y_12)
	printf, 1, transpose(trans_x_23)
	printf, 1, transpose(trans_y_23)
	close, 1


	; now sift through for the peaks that appear in both channels
	circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
	circle(*,1) = [ 0,0,0,0,1,1,1,0,0,0,0]
	circle(*,2) = [ 0,0,0,1,0,0,0,1,0,0,0]
	circle(*,3) = [ 0,0,1,0,0,0,0,0,1,0,0]
	circle(*,4) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,5) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,6) = [ 0,1,0,0,0,0,0,0,0,1,0]
	circle(*,7) = [ 0,0,1,0,0,0,0,0,1,0,0]
	circle(*,8) = [ 0,0,0,1,0,0,0,1,0,0,0]
	circle(*,9) = [ 0,0,0,0,1,1,1,0,0,0,0]
	circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]

	; find peaks that have approximately this spacing
	xx_left = intarr(1000)
	yy_left = intarr(1000)
	xx_middle = intarr(1000)
	yy_middle = intarr(1000)
	xx_right = intarr(1000)
	yy_right = intarr(1000)

	numberofPairs = 0
	for i = 0, NumberofGoodLocations - 1 do begin
		if GoodLocations_x(i) lt 160 then begin

			; calculate location of pair
			x_middle_expect = round(trans_x_12(0) + trans_x_12(1)*float(GoodLocations_x(i)) + trans_x_12(2)*float(GoodLocations_y(i)))
			y_middle_expect = round(trans_y_12(0) + trans_y_12(1)*float(GoodLocations_x(i)) + trans_y_12(2)*float(GoodLocations_y(i)))

			x_right_expect = round(trans_x_13(0) + trans_x_13(1)*float(GoodLocations_x(i)) + trans_x_13(2)*float(GoodLocations_y(i)))
			y_right_expect = round(trans_y_13(0) + trans_y_13(1)*float(GoodLocations_x(i)) + trans_y_13(2)*float(GoodLocations_y(i)))

			for j = 0, NumberofGoodLocations - 1 do begin
				if (abs(GoodLocations_x(j) - x_middle_expect) lt 3) and (abs(GoodLocations_y(j) - y_middle_expect) lt 3) then begin
					; circle the two peaks
					for k = 0, NumberofGoodLocations - 1 do begin
						if(abs(GoodLocations_x(k) - x_right_expect) lt 3) and (abs(GoodLocations_y(k) - y_right_expect) lt 3) then begin
							Location_left = GoodLocations_x(i) - 5
							Location_right = GoodLocations_x(i) + 5
							Location_bottom = GoodLocations_y(i) - 5
							Location_top = GoodLocations_y(i) + 5
							temp(Location_left:Location_right, Location_bottom:Location_top) = (circle eq 0)*temp(Location_left:Location_right, Location_bottom:Location_top) + (circle gt 0)*240

							Location_left = GoodLocations_x(j) - 5
							Location_right = GoodLocations_x(j) + 5
							Location_bottom = GoodLocations_y(j) - 5
							Location_top = GoodLocations_y(j) + 5
							temp(Location_left:Location_right, Location_bottom:Location_top) = (circle eq 0)*temp(Location_left:Location_right, Location_bottom:Location_top) + (circle gt 0)*240

							Location_left = GoodLocations_x(k) - 5
							Location_right = GoodLocations_x(k) + 5
							Location_bottom = GoodLocations_y(k) - 5
							Location_top = GoodLocations_y(k) + 5
							temp(Location_left:Location_right, Location_bottom:Location_top) = (circle eq 0)*temp(Location_left:Location_right, Location_bottom:Location_top) + (circle gt 0)*240


							wset, 0
							tv, temp

              			xx_left(numberofPairs) = GoodLocations_x(i)
							yy_left(numberofPairs) = GoodLocations_y(i)
							xx_middle(numberofPairs) = GoodLocations_x(j) - 170
							yy_middle(numberofPairs) = GoodLocations_y(j)
							xx_right(numberofPairs) = GoodLocations_x(k) - 340
							yy_right(numberofPairs) = GoodLocations_y(k)
							numberofPairs++
						endif
					endfor
				endif
			endfor
		endif
	endfor

	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(numberofPairs) + " pairs are found."), /APPEND, /SHOW

	xxx_right = xx_right(0:(numberofPairs-1))
	yyy_right = yy_right(0:(numberofPairs-1))
	xxx_middle = xx_middle(0:(numberofPairs-1))
	yyy_middle = yy_middle(0:(numberofPairs-1))
	xxx_left = xx_left(0:(numberofPairs-1))
	yyy_left = yy_left(0:(numberofPairs-1))


	;if numberofPairs gt 6 then begin
	if numberofPairs gt 16 then begin

		POLYWARP, xxx_middle, yyy_middle, xxx_left, yyy_left, 3, P12, Q12
		POLYWARP, xxx_right, yyy_right, xxx_left, yyy_left, 3, P13, Q13
		POLYWARP, xxx_right, yyy_right, xxx_middle, yyy_middle, 3, P23, Q23

		openw, 1, run + ".map"



		for i = 0, 15 do begin
			printf, 1, P12(i)
		endfor

		for i = 0, 15 do begin
			printf, 1, Q12(i)
		endfor

		for i = 0, 15 do begin
			printf, 1, P13(i)
		endfor

		for i = 0, 15 do begin
			printf, 1, Q13(i)
		endfor

		for i = 0, 15 do begin
			printf, 1, P23(i)
		endfor

		for i = 0, 15 do begin
			printf, 1, Q23(i)
		endfor

		for i = 0, 15 do begin
			printf, 1, P23(i)
		endfor

		for i = 0, 15 do begin
			printf, 1, Q23(i)
		endfor
		close, 1

		WIDGET_CONTROL, text_ID, SET_VALUE="Coefficient: ", /APPEND, /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE=STRING(P12), /APPEND, /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE=STRING(P13), /APPEND, /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE=STRING(P23), /APPEND, /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE=STRING(Q12), /APPEND, /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE=STRING(Q13), /APPEND, /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE=STRING(Q23), /APPEND, /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE="End of Mapping maker.", /APPEND, /SHOW

	endif else begin
		WIDGET_CONTROL, text_ID, SET_VALUE="Not enough matches, please try again to make a map", /APPEND, /SHOW
	endelse

end

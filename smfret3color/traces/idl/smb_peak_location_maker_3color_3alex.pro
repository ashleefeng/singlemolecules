; This program is designed for 3-color experiment with 3 laser alex
; edited by X. Feng to select spots with all three colors Nov 5, 2019 xfeng17@jhu.edu

pro smb_peak_location_maker_3color_3alex, run, mapfile, text_ID

	;3color 3ALEX
	color_number = 3
	alex_number = 3
	; Custumizing parameters
	film_time_start = 0			;usually 0, start frame to average
	average_length = 10			;usually 50~100, average frame number
	binwidth = 32						;background bin width
	low_limit = 10					;background bin range
	high_limit = 30					;background bin range
	bin_num=100							;background bin number
	margin = 10							;median, viriance edge remove, 512 image-> 10, 256 image-> 6
	spot_diameter = 7				;single spot check, 512 image-> 7 , 256 image-> 5
	width = 3								;local maximum range, 512 image-> 3, 256 image-> 2
	edge = 10								;edge pixel number to ignore, 512 image-> 10, 256 image-> 6
	cutoff_num = 0.5				;single spot check, usually 0.55
	quality_num = 3					;single spot check, 512 image-> 3, 256 image-> 3 or 7
	occupy_num = 4					;is it noise?, 512 image-> 7, 256 image-> 4 or 1
	check_ch = 1            ;which channel will be criteria for laser order check

	frame1_ratio_first = 1
	frame2_ratio_first = 0
	frame3_ratio_first = 0

	frame1_ratio_second = 0
    frame2_ratio_second = 1
    frame3_ratio_second = 0

    frame1_ratio_third = 0
    frame2_ratio_third = 0
    frame3_ratio_third = 1
	;Program start

	loadct, 5
	device, decomposed=0

	COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

	; generate gaussian peaks

	g_peaks = fltarr(3,3,7,7)   ;creates a floating-point vector or array of the specified dimensions.

	for k = 0, 2 do begin
    	for l = 0, 2 do begin
			offx = 0.5*float(k-1)
			offy = 0.5*float(l-1)
			for i = 0, 6 do begin
				for j = 0, 6 do begin
					dist = 0.4 * ((float(i)-3.0+offx)^2 + (float(j)-3.0+offy)^2)
					g_peaks(k,l,i,j) = exp(-dist)
				endfor
			endfor
		endfor
	endfor

	; input film

	if N_PARAMS() eq 0 then begin
		run = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a .pma file.', /READ, FILTER = '*.pma')
		xdisplayFile, '', TEXT=(run + " is selected."), RETURN_ID=display_ID, WTEXT=text_ID
		run = strmid(run, 0, strlen(run) - 4)
		mapfile = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a mapping file', /READ, FILTER = '*.map')
		WIDGET_CONTROL, text_ID, SET_VALUE=(mapfile + " is selected."), /APPEND,  /SHOW
	endif

	if N_PARAMS() eq 1 then begin
		mapfile = DIALOG_PICKFILE(PATH='c:\user\tir', TITLE='Select a mapping file', /READ, FILTER = '*.map')
		xdisplayFile, '', TEXT=(mapfile + " is selected."), RETURN_ID=display_ID, WTEXT=text_ID
	endif

	if N_PARAMS() eq 2 then begin
		xdisplayFile, '', TEXT=(run + ".pma is selected."), RETURN_ID=display_ID, WTEXT=text_ID
		WIDGET_CONTROL, text_ID, SET_VALUE=(mapfile + " is selected."), /APPEND,  /SHOW
	endif

	if N_PARAMS() eq 3 then begin
		WIDGET_CONTROL, text_ID, SET_VALUE=(run + ".pma is selected."), /APPEND,  /SHOW
		WIDGET_CONTROL, text_ID, SET_VALUE=(mapfile + " is selected."), /APPEND,  /SHOW
	endif



	; figure out size + allocate appropriately
	close, 1														; make sure unit 1 is closed
;	close, 2
	openr, 1, run + ".pma"
; openr, 2, run + ".spma"


	; figure out size + allocate appropriately
	file_infomation = FSTAT(1)
	film_width = fix(1)
	film_height = fix(1)
;	readu, 2, film_width
; readu, 2, film_height
	readu, 1, film_width
	readu, 1, film_height
	film_width_half = film_width/2
	film_height_half = film_height/2
	film_width_quarter = film_width/4
	film_height_quarter = film_height/4
	film_width_tri = round(film_width/3)
	film_height_tri = round(film_height/3)

	film_time_length = long(long64(file_infomation.SIZE -long64(4))/(long64(film_width)*long64(film_height)))

	WIDGET_CONTROL, text_ID, SET_VALUE=("Film width, height, time_length : " + STRING(film_width) + STRING(film_height) + STRING(film_time_length)), /APPEND, /SHOW

	frame  = bytarr(film_width, film_height, /NOZERO)
	frame_average_first = fltarr(film_width, film_height)
	frame_average_second = fltarr(film_width, film_height)
	frame_average_third = fltarr(film_width, film_height)

	;answer=gui_prompt('start frame to average (recommanded=0) :', title='Start frame')
	;film_time_start = total(long(answer))

	film_time_end = film_time_start + average_length

	;answer=gui_prompt('length of frame to average (recommanded=100) :', title='Frame average length')
	;film_time_end = film_time_start + total(long(answer))

	if film_time_end gt floor(film_time_length/alex_number) then film_time_end = floor(film_time_length/alex_number)

	print, 'current position : '
	POINT_LUN, -1, POS
	HELP, POS
	print, 'target position : ',  film_time_start
	POINT_LUN, 1, 4 + long(film_time_start)*film_width*film_height*alex_number
	POINT_LUN, -1, POS
	HELP, POS

	for j = film_time_start, film_time_end - 1 do begin
	    readu, 1, frame
	    frame_average_first = temporary(frame_average_first) + frame
		readu, 1, frame
		frame_average_second = temporary(frame_average_second) + frame
		readu, 1, frame
		frame_average_third = temporary(frame_average_third) + frame
	endfor

    frame_average_first = temporary(frame_average_first)/float(film_time_end - film_time_start)
	frame_average_second = temporary(frame_average_second)/float(film_time_end - film_time_start)
	frame_average_third = temporary(frame_average_third)/float(film_time_end - film_time_start)
	;frame_average_first = frame_average_second
	;frame_average_second = frame_average_first

	;; 현재 3-color 실험의 경우 (1번방), 1번째 frame은 blue or red excitation
	;; 따라서 첫번째 laser와 두번째 laser의 1번째 채널의 신호를 비교한다 (Blue&Green or Red&Blue)
	;; 만약 Blue&Green이라면 첫번째 laser가 더 신호가 크고, Red&Blue인 경우 두번째 laser에서의 신호가 더 클 것이다

	color_check_first = mean(frame_average_first((film_width*(check_ch-1)/3):(film_width*(check_ch)/3-1),0:(film_height-1)))
    color_check_second = mean(frame_average_second((film_width*(check_ch-1)/3):(film_width*(check_ch)/3-1),0:(film_height-1)))
;	color_check_third = mean(frame_average_third((film_width*(check_ch-1)/3):(film_width*(check_ch)/3-1),0:(film_height-1)))

;	color_check_first = mean(frame_average_first(0:(film_width/3-1),0:(film_height-1)))
;	color_check_second = mean(frame_average_second(0:(film_width/3-1),0:(film_height-1)))

;	color_check_first = mean(frame_average_first((film_width/3):(film_width*2/3-1),0:(film_height-1)))
;  color_check_second = mean(frame_average_second((film_width/3):(film_width*2/3-1),0:(film_height-1)))

;  color_check_first = mean(frame_average_first((film_width*2/3):(film_width-1),0:(film_height-1)))
;  color_check_second = mean(frame_average_second((film_width*2/3):(film_width-1),0:(film_height-1)))

	if color_check_first gt color_check_second then begin  ;; Blue & Green
	  color_change_check = 'n'
	endif else begin ;; Red & Blue
      color_change_check = 'y'
      frame = frame_average_first
      frame_average_first = frame_average_second
      frame_average_second = frame_average_third
      frame_average_third = frame
    endelse

	WIDGET_CONTROL, text_ID, SET_VALUE=("Color change? : " + color_change_check), /APPEND, /SHOW

	frame = byte(frame_average_first)
    window, 0, xsize = film_width, ysize = film_height, title = 'frame_average_first'
    tv, frame

	frame = byte(frame_average_second)
	window, 1, xsize = film_width, ysize = film_height, title = 'frame_average_second'
	tv, frame

	frame = byte(frame_average_third)
	window, 2, xsize = film_width, ysize = film_height, title = 'frame_average_third'
	tv, frame

	if FILE_TEST(run + "_ave_first.tif") eq 0 then begin       ; _ave.tif file doesn't exist.
      WRITE_TIFF, run + "_ave_first.tif", frame_average_first, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2
    endif
	if FILE_TEST(run + "_ave_second.tif") eq 0 then begin				; _ave.tif file doesn't exist.
		WRITE_TIFF, run + "_ave_second.tif", frame_average_second, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2
	endif
	if FILE_TEST(run + "_ave_third.tif") eq 0 then begin        ; _ave.tif file doesn't exist.
      WRITE_TIFF, run + "_ave_third.tif", frame_average_third, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression = 2
    endif


; subtracts background
	;film_time_end = floor(floor(film_time_length/alex_number)/alex_number)*alex_number-alex_number
	;film_time_start = film_time_end-average_length

	print, 'current position : '
	POINT_LUN, -1, POS
	HELP, POS
	print, 'target position : ',  film_time_start
	POINT_LUN, 1, 4 + long64(film_time_start)*film_width*film_height*alex_number
	POINT_LUN, -1, POS
	HELP, POS

	temp_first = fltarr(film_width, film_height)
	temp_second = fltarr(film_width, film_height)
	temp_third = fltarr(film_width, film_height)

	;; 만약 color change가 있었다면 원래 순서가 RBG이므로 한 frame을 skip해서 BGR로 바꿔준다.
	if color_change_check eq 'y' then begin
	  readu, 1, frame
	end

	for j = film_time_start, (film_time_end - 1) do begin
	  readu, 1, frame
	  temp_first = temporary(temp_first) + frame
		readu, 1, frame
		temp_second = temporary(temp_second) + frame
		readu, 1, frame
		temp_third = temporary(temp_third) + frame
	endfor

	close, 1

    temp_first = temporary(temp_first)/float(film_time_end - film_time_start)
	temp_second = temporary(temp_second)/float(film_time_end - film_time_start)
    temp_third = temporary(temp_third)/float(film_time_end - film_time_start) ;frame_average_third

    ;temp_first = temp_second
	halfbinwidth = fix(binwidth/2)
	halfbinwidth_1 = halfbinwidth - 1

	minimum_intensity_matrix_first = fltarr(film_width/binwidth, film_height/binwidth, /NOZERO)
	minimum_intensity_matrix_second = fltarr(film_width/binwidth, film_height/binwidth, /NOZERO)
	minimum_intensity_matrix_third = fltarr(film_width/binwidth, film_height/binwidth, /NOZERO)

	window, 3, TITLE = 'Histogram of first average image'
    hist = histogram(temp_first, MIN=0, MAX=80, NBINS=100)
    PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'first Average Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
    dummy=max(hist, max_index)
    max_index= double(max_index)*(80.0)/100.0
    first_minimum=max_index-low_limit
    first_maximum=max_index+high_limit

	window, 4, TITLE = 'Histogram of second average image'
	hist = histogram(temp_second, MIN=0, MAX=80, NBINS=100)
	PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'second Average Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
	dummy=max(hist, max_index)
	max_index= double(max_index)*(80.0)/100.0
	second_minimum=max_index-low_limit
	second_maximum=max_index+high_limit

	window, 5, TITLE = 'Histogram of third average image'
    hist = histogram(temp_third, MIN=0, MAX=80, NBINS=100)
    PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'third Average Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
    dummy=max(hist, max_index)
    max_index= double(max_index)*(80.0)/100.0
    third_minimum=max_index-low_limit
    third_maximum=max_index+high_limit

	window, 6, TITLE = 'Histogram of first image'
	window, 7, TITLE = 'Smoothed Histogram of first image'
	window, 8, TITLE = 'Histogram of second image'
	window, 9, TITLE = 'smoothed Histogram of second image'
	window, 10, TITLE = 'Histogram of third image'
    window, 11, TITLE = 'smoothed Histogram of third image'

	for i = halfbinwidth, film_width, binwidth do begin
		for j = halfbinwidth, film_height, binwidth do begin
			;minimum_intensity_matrix_second((i-halfbinwidth)/binwidth,(j-halfbinwidth)/binwidth) = min(temp_second(i-halfbinwidth:i+halfbinwidth_1,j-halfbinwidth:j+halfbinwidth_1))
			;minimum_intensity_matrix_red((i-halfbinwidth)/binwidth,(j-halfbinwidth)/binwidth) = min(temp_red(i-halfbinwidth:i+halfbinwidth_1,j-halfbinwidth:j+halfbinwidth_1))

			hist=histogram(temp_first(i-halfbinwidth:i+halfbinwidth_1,j-halfbinwidth:j+halfbinwidth_1), MIN=first_minimum, MAX=first_maximum, NBINS=bin_num)
			wset, 6
			PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'first Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
			hist= smooth(hist, 5, /EDGE_TRUNCATE)
			wset, 7
			PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'first Smoothed Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
			dummy=max(hist, max_index_first)
			max_index_first= first_minimum + double(max_index_first)*(first_maximum-first_minimum)/bin_num

			hist=histogram(temp_second(i-halfbinwidth:i+halfbinwidth_1,j-halfbinwidth:j+halfbinwidth_1), MIN=second_minimum, MAX=second_maximum, NBINS=bin_num)
			wset, 8
			PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'second Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
			hist= smooth(hist, 5, /EDGE_TRUNCATE)
			wset, 9
			PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'second Smoothed Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
			dummy=max(hist, max_index_second)
			max_index_second= second_minimum + double(max_index_second)*(second_maximum-second_minimum)/bin_num

            hist=histogram(temp_third(i-halfbinwidth:i+halfbinwidth_1,j-halfbinwidth:j+halfbinwidth_1), MIN=third_minimum, MAX=third_maximum, NBINS=bin_num)
            wset, 10
            PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'third Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
            hist= smooth(hist, 5, /EDGE_TRUNCATE)
            wset, 11
            PLOT, hist, /XSTYLE, /YSTYLE, TITLE = 'third Smoothed Image Histogram', XTITLE = 'Intensity Value Index', YTITLE = 'Number of Pixels of That Value'
            dummy=max(hist, max_index_third)
            max_index_third= third_minimum + double(max_index_third)*(third_maximum-third_minimum)/bin_num

			;WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(max_index_second) + STRING(max_index_red) + STRING(min(temp_second(i-halfbinwidth:i+halfbinwidth_1,j-halfbinwidth:j+halfbinwidth_1))) + STRING(min(temp_red(i-halfbinwidth:i+halfbinwidth_1,j-halfbin
			minimum_intensity_matrix_first((i-halfbinwidth)/binwidth,(j-halfbinwidth)/binwidth) = max_index_first
			minimum_intensity_matrix_second((i-halfbinwidth)/binwidth,(j-halfbinwidth)/binwidth) = max_index_second
			minimum_intensity_matrix_third((i-halfbinwidth)/binwidth,(j-halfbinwidth)/binwidth) = max_index_third
		endfor
	endfor
    minimum_intensity_matrix_first = rebin(minimum_intensity_matrix_first, film_width, film_height)
	minimum_intensity_matrix_second = rebin(minimum_intensity_matrix_second, film_width, film_height)
	minimum_intensity_matrix_third = rebin(minimum_intensity_matrix_third, film_width, film_height)
	minimum_intensity_matrix_first = smooth(minimum_intensity_matrix_first, 20, /EDGE_TRUNCATE)
	minimum_intensity_matrix_second = smooth(minimum_intensity_matrix_second, 20, /EDGE_TRUNCATE)
	minimum_intensity_matrix_third = smooth(minimum_intensity_matrix_third, 20, /EDGE_TRUNCATE)

    window, 12, xsize = film_width, ysize = film_height, title = 'background_first'
    tv, (minimum_intensity_matrix_first*255/max(minimum_intensity_matrix_first))>0
	window, 13, xsize = film_width, ysize = film_height, title = 'background_second'
	tv, (minimum_intensity_matrix_second*255/max(minimum_intensity_matrix_second))>0
	window, 14, xsize = film_width, ysize = film_height, title = 'background_third'
    tv, (minimum_intensity_matrix_third*255/max(minimum_intensity_matrix_third))>0

    modified_frame_first = frame_average_first - minimum_intensity_matrix_first
	modified_frame_second = frame_average_second - minimum_intensity_matrix_second
	modified_frame_third = frame_average_third - minimum_intensity_matrix_third

    modified_frame_first=modified_frame_first*255/max(modified_frame_first)
	modified_frame_second=modified_frame_second*255/max(modified_frame_second)
	modified_frame_third=modified_frame_third*255/max(modified_frame_third)

	window, 15, xsize = film_width, ysize = film_height, title = 'modified_frame_first'
	tv, (modified_frame_first>0)
	window, 16, xsize = film_width, ysize = film_height, title = 'modified_frame_second'
	tv, (modified_frame_second>0)
	window, 17, xsize = film_width, ysize = film_height, title = 'modified_frame_third'
    tv, (modified_frame_third>0)

	; open file that contains how the channels map onto each second

  P12 = fltarr(4,4)
  Q12 = fltarr(4,4)
  P13 = fltarr(4,4)
  Q13 = fltarr(4,4)
  P23 = fltarr(4,4)
  Q23 = fltarr(4,4)


  openr, 1, mapfile
  readf, 1, P12
  readf, 1, Q12
  readf, 1, P13
  readf, 1, Q13
  readf, 1, P23
  readf, 1, Q23
  close, 1

	; and map the right half of the screen onto the left half of the screen
  frame1_first = modified_frame_first(0:(film_width_tri-1),0:(film_height-1))
  frame2_first = modified_frame_first(film_width_tri:(film_width_tri*2-1),0:(film_height-1))
  frame3_first = modified_frame_first((film_width_tri*2):(film_width-3),0:(film_height-1))

  frame1_second = modified_frame_second(0:(film_width_tri-1),0:(film_height-1))
  frame2_second = modified_frame_second(film_width_tri:(film_width_tri*2-1),0:(film_height-1))
  frame3_second = modified_frame_second((film_width_tri*2):(film_width-3),0:(film_height-1))

  frame1_third = modified_frame_third(0:(film_width_tri-1),0:(film_height-1))
  frame2_third = modified_frame_third(film_width_tri:(film_width_tri*2-1),0:(film_height-1))
  frame3_third = modified_frame_third((film_width_tri*2):(film_width-3),0:(film_height-1))

  frame2_first = POLY_2D(frame2_first, P12, Q12, 2)
  frame3_first = POLY_2D(frame3_first, P13, Q13, 2)

  frame2_second = POLY_2D(frame2_second, P12, Q12, 2)
  frame3_second = POLY_2D(frame3_second, P13, Q13, 2)

  frame2_third = POLY_2D(frame2_third, P12, Q12, 2)
  frame3_third = POLY_2D(frame3_third, P13, Q13, 2)

  combined_frame_first = float(frame1_first)*frame1_ratio_first + float(frame2_first)*frame2_ratio_first + float(frame3_first)*frame3_ratio_first
  combined_frame_second = float(frame1_second)*frame1_ratio_second + float(frame2_second)*frame2_ratio_second + float(frame3_second)*frame3_ratio_second
  combined_frame_third = float(frame1_third)*frame1_ratio_third + float(frame2_third)*frame2_ratio_third + float(frame3_third)*frame3_ratio_third

  window, 18, xsize = film_width_tri, ysize = film_height, title = 'combined_frame_first'
  tv, combined_frame_first
  window, 19, xsize = film_width_tri, ysize = film_height, title = 'combined_frame_second'
  tv, combined_frame_second
  window, 20, xsize = film_width_tri, ysize = film_height, title = 'combined_frame_third'
  tv, combined_frame_third

  medianofFrame_first = float(median(combined_frame_first(margin:(film_width_tri-1-margin),margin:(film_height-1-margin))))
  varianceofFrame_first = variance(combined_frame_first(margin:(film_width_tri-1-margin),margin:(film_height-1-margin)))
  medianofFrame_second = float(median(combined_frame_second(margin:(film_width_tri-1-margin),margin:(film_height-1-margin))))
  varianceofFrame_second = variance(combined_frame_second(margin:(film_width_tri-1-margin),margin:(film_height-1-margin)))
  medianofFrame_third = float(median(combined_frame_third(margin:(film_width_tri-1-margin),margin:(film_height-1-margin))))
  varianceofFrame_third = variance(combined_frame_third(margin:(film_width_tri-1-margin),margin:(film_height-1-margin)))

  deviation_first = sqrt(varianceofFrame_first)
  deviation_second = sqrt(varianceofFrame_second)
  deviation_third = sqrt(varianceofFrame_third)

	;deviation = 20

  cutoff_first = byte(medianofFrame_first + deviation_first)
  truncated_frame_first = float(combined_frame_first gt cutoff_first)*combined_frame_first
  cutoff_second = byte(medianofFrame_second + deviation_second)
  truncated_frame_second = float(combined_frame_second gt cutoff_second)*combined_frame_second
  cutoff_third = byte(medianofFrame_third + deviation_third)
  truncated_frame_third = float(combined_frame_third gt cutoff_third)*combined_frame_third

  window, 21, xsize = film_width_tri, ysize = film_height, title = 'truncated_frame_first'
  tv, truncated_frame_first
  window, 22, xsize = film_width_tri, ysize = film_height, title = 'truncated_frame_second'
  tv, truncated_frame_second
  window, 23, xsize = film_width_tri, ysize = film_height, title = 'truncated_frame_third'
  tv, truncated_frame_third

;  WIDGET_CONTROL, text_ID, SET_VALUE=("median :" + STRING(medianofFrame)), /APPEND, /SHOW
;  WIDGET_CONTROL, text_ID, SET_VALUE=("deviation, cutoff :" + STRING(deviation)+ STRING(float(cutoff))), /APPEND, /SHOW

	; find the peaks

	circle = bytarr(11, 11, /NOZERO)  ;make matrix

	if spot_diameter eq 9 then begin
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
	endif
	if spot_diameter eq 7 then begin
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
	endif
	if spot_diameter eq 5 then begin
		circle(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,1) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,2) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,3) = [ 0,0,0,0,1,1,1,0,0,0,0]
		circle(*,4) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,5) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,6) = [ 0,0,0,1,0,0,0,1,0,0,0]
		circle(*,7) = [ 0,0,0,0,1,1,1,0,0,0,0]
  	circle(*,8) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,9) = [ 0,0,0,0,0,0,0,0,0,0,0]
		circle(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]
	endif

	toosmall = bytarr(11, 11, /NOZERO)
	toosmall(*,0) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,1) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,2) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,3) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,4) = [ 0,0,0,0,1,1,1,0,0,0,0]
	toosmall(*,5) = [ 0,0,0,0,1,1,1,0,0,0,0]
	toosmall(*,6) = [ 0,0,0,0,1,1,1,0,0,0,0]
	toosmall(*,7) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,8) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,9) = [ 0,0,0,0,0,0,0,0,0,0,0]
	toosmall(*,10)= [ 0,0,0,0,0,0,0,0,0,0,0]

    GoodLocations_x_first = intarr(10000)
    GoodLocations_y_first = intarr(10000)
	GoodLocations_x_second = intarr(10000)
	GoodLocations_y_second = intarr(10000)
	GoodLocations_x_third = intarr(10000)
    GoodLocations_y_third = intarr(10000)
	GoodLocations_x_all = intarr(10000)
	GoodLocations_y_all = intarr(10000)
	GoodLocations_x = intarr(10000)
	GoodLocations_y = intarr(10000)
	Background_first = dblarr(10000)
	Background_second = dblarr(10000)
	Background_third = dblarr(10000)
	Background_first_all = dblarr(10000)
	Background_second_all = dblarr(10000)
	Background_third_all = dblarr(10000)
	Background = dblarr(10000)

	NumberofGoodLocations_first = 0
    NumberofBadLocations_first = 0
	NumberofGoodLocations_second = 0
	NumberofBadLocations_second = 0
	NumberofGoodLocations_third = 0
    NumberofBadLocations_third = 0
	NumberofGoodLocations_all = 0
	NumberofBadLocations_all = 0
	NumberofGoodLocations = 0
	NumberofBadLocations = 0
	temp_all_first = modified_frame_first
    temp_all_second = modified_frame_second
    temp_all_third = modified_frame_third

	for c=0, 2 do begin
		if c eq 0 then begin
			truncated_frame = truncated_frame_first
			modified_frame = modified_frame_first
			combined_frame = combined_frame_first
			temp = modified_frame_first
			temp_emphasized = truncated_frame_first
			minimum_intensity_matrix = minimum_intensity_matrix_first
		endif
		if c eq 1 then begin
			truncated_frame = truncated_frame_second
			modified_frame = modified_frame_second
			combined_frame = combined_frame_second
			temp = modified_frame_second
			temp_emphasized = truncated_frame_second
			minimum_intensity_matrix = minimum_intensity_matrix_second
		endif
		if c eq 2 then begin
            truncated_frame = truncated_frame_third
            modified_frame = modified_frame_third
            combined_frame = combined_frame_third
            temp = modified_frame_third
            temp_emphasized = truncated_frame_third
            minimum_intensity_matrix = minimum_intensity_matrix_third
        endif

;		GoodLocations_x = intarr(4000)
;		GoodLocations_y = intarr(4000)
;		Background = dblarr(4000)

		NumberofGoodLocations = 0
		NumberofBadLocations = 0

		for j = edge, film_height - edge -1 do begin
	    	for i = edge, film_width_tri - edge -1 do begin
				if truncated_frame(i,j) gt 0 then begin

					; find the nearest maxima

					MaxIntensity_local = max(truncated_frame(i-width:i+width,j-width:j+width), Max_location)
					Max_location_x_y = ARRAY_INDICES(modified_frame(i-width:i+width,j-width:j+width), Max_location)
					Max_location_x = Max_location_x_y[0] - width
					Max_location_y = Max_location_x_y[1] - width
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

						cutoff=byte(cutoff_num * float(MaxIntensity_local))
						quality=total( (combined_frame(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) gt cutoff) * (circle eq 1) )
						occupy=total( (truncated_frame(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) gt 0) * toosmall  )

	                    if (quality lt quality_num) and (occupy gt occupy_num) then begin

							; draw where peak was found on screen

							temp_emphasized(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = float(truncated_frame(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top))/MaxIntensity_local*255
							temp_emphasized(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_emphasized(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90

							temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0

                            ; filter for spots that have all three colors - XF
							all_check = 'n'
							if c eq 2 then begin
								for g = 0, NumberofGoodLocations_second - 1 do begin
								  if (abs(GoodLocations_x_second(g)-Max_location_x) le 2)and(abs(GoodLocations_y_second(g)-Max_location_y) le 2) then begin
								    for h = 0, NumberofGoodLocations_first - 1 do begin
								      if (abs(GoodLocations_x_first(h)-Max_location_x) le 2) and (abs(GoodLocations_y_first(h)-Max_location_y) le 2) then begin
                                        all_check = 'y'
                                      endif
                                    endfor
                                  endif
                                endfor
                            endif

							if all_check eq 'y' then begin
							    temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
								temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
								temp_all_third(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_third(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
							endif

							;wset, 1
							;tv, temp_emphasized

							; compute difference between peak and gaussian peak

							best = 10000.0
							for k = 0, 2 do begin
								for l = 0, 2 do begin
									difference = total(abs(float(MaxIntensity_local) * g_peaks(k,l,*,*) - modified_frame((Max_location_x-3):(Max_location_x+3), (Max_location_y-3):(Max_location_y+3))))
									if difference lt best then begin
										best_x = k
										best_y = l
										best = difference
									endif
								endfor
							endfor

							float_x_1 = float(Max_location_x) - 0.5*float(best_x-1)
							float_y_1 = float(Max_location_y) - 0.5*float(best_y-1)

	                 		; calculate and draw location of companion peak

							float_x_2 = film_width_tri
							float_y_2 = 0.0
							for k = 0, 3 do begin
								for l = 0, 3 do begin
									float_x_2 = float_x_2 + P12(k,l) * float(float_x_1^l) * float(float_y_1^k)
									float_y_2 = float_y_2 + Q12(k,l) * float(float_x_1^l) * float(float_y_1^k)
								endfor
							endfor

							x_2 = round(float_x_2)
							y_2 = round(float_y_2)

							aroundMax_left = x_2 - 5
							aroundMax_right = x_2 + 5
							aroundMax_bottom = y_2 - 5
							aroundMax_top = y_2 + 5
							if (aroundMax_left le 1) or (aroundMax_bottom le 1) or (aroundMax_right ge (film_width-1)) or (aroundMax_top ge (film_height-1)) then begin
								NumberofBadLocations++
							endif else begin
								temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90

                if all_check eq 'y' then begin
                  temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                  temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                  temp_all_third(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_third(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                endif

								float_x_3 = film_width_tri*2
								float_y_3 = 0.0
								for k = 0, 3 do begin
                  for l = 0, 3 do begin
                    float_x_3 = float_x_3 + P13(k,l) * float(float_x_1^l) * float(float_y_1^k)
                    float_y_3 = float_y_3 + Q13(k,l) * float(float_x_1^l) * float(float_y_1^k)
                  endfor
                endfor

                x_3 = round(float_x_3)
                y_3 = round(float_y_3)
                aroundMax_left = x_3 - 5
                aroundMax_right = x_3 + 5
                aroundMax_bottom = y_3 - 5
                aroundMax_top = y_3 + 5
                if (aroundMax_left le 1) or (aroundMax_bottom le 1) or (aroundMax_right ge (film_width-1)) or (aroundMax_top ge (film_height-1)) then begin
                  NumberofBadLocations++
                endif else begin
                  temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90

                  if all_check eq 'y' then begin
                    temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                    temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                    temp_all_third(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_third(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                  endif

                ;wset, 0
								;tv, temp>0

								  GoodLocations_x(NumberofGoodLocations) = Max_location_x
                  GoodLocations_y(NumberofGoodLocations) = Max_location_y
                  Background(NumberofGoodLocations) = minimum_intensity_matrix(Max_location_x, Max_location_y)
                  NumberofGoodLocations++
                  GoodLocations_x(NumberofGoodLocations) = x_2
                  GoodLocations_y(NumberofGoodLocations) = y_2
                  Background(NumberofGoodLocations) = minimum_intensity_matrix(x_2, y_2)
                  NumberofGoodLocations++
                  GoodLocations_x(NumberofGoodLocations) = x_3
                  GoodLocations_y(NumberofGoodLocations) = y_3
                  Background(NumberofGoodLocations) = minimum_intensity_matrix(x_3, y_3)
                  NumberofGoodLocations++

                  if all_check eq 'y' then begin
                    temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_first(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                    temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_second(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0
                    temp_all_third(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) = (circle eq 0) * temp_all_third(aroundMax_left:aroundMax_right, aroundMax_bottom:aroundMax_top) + (circle ne 0) * 90.0

									  GoodLocations_x_all(NumberofGoodLocations_all) = Max_location_x
                    GoodLocations_y_all(NumberofGoodLocations_all) = Max_location_y
                    Background_first_all(NumberofGoodLocations_all) = minimum_intensity_matrix_first(Max_location_x, Max_location_y)
                    Background_second_all(NumberofGoodLocations_all) = minimum_intensity_matrix_second(Max_location_x, Max_location_y)
                    Background_third_all(NumberofGoodLocations_all) = minimum_intensity_matrix_third(Max_location_x, Max_location_y)
                    NumberofGoodLocations_all++
                    GoodLocations_x_all(NumberofGoodLocations_all) = x_2
                    GoodLocations_y_all(NumberofGoodLocations_all) = y_2
                    Background_first_all(NumberofGoodLocations_all) = minimum_intensity_matrix_first(x_2, y_2)
                    Background_second_all(NumberofGoodLocations_all) = minimum_intensity_matrix_second(x_2, y_2)
                    Background_third_all(NumberofGoodLocations_all) = minimum_intensity_matrix_third(x_2, y_2)
                    NumberofGoodLocations_all++
                    GoodLocations_x_all(NumberofGoodLocations_all) = x_3
                    GoodLocations_y_all(NumberofGoodLocations_all) = y_3
                    Background_first_all(NumberofGoodLocations_all) = minimum_intensity_matrix_first(x_3, y_3)
                    Background_second_all(NumberofGoodLocations_all) = minimum_intensity_matrix_second(x_3, y_3)
                    Background_third_all(NumberofGoodLocations_all) = minimum_intensity_matrix_third(x_3, y_3)
                    NumberofGoodLocations_all++
                  endif
                endelse
              endelse
						endif else begin
							NumberofBadLocations++
						endelse
					endif
				endif
			endfor
		endfor

		if c eq 0 then begin
			NumberofGoodLocations_first = NumberofGoodLocations
			NumberofBadLocations_first = NumberofBadLocations
			temp_first = temp
			Background_first = Background
			GoodLocations_x_first = GoodLocations_x
			GoodLocations_y_first = GoodLocations_y
		endif
		if c eq 1 then begin
			NumberofGoodLocations_second = NumberofGoodLocations
			NumberofBadLocations_second = NumberofBadLocations
			temp_second = temp
			Background_second = Background
			GoodLocations_x_second = GoodLocations_x
			GoodLocations_y_second = GoodLocations_y
		endif
		if c eq 2 then begin
      NumberofGoodLocations_third = NumberofGoodLocations
      NumberofBadLocations_third = NumberofBadLocations
      temp_third = temp
      Background_third = Background
      GoodLocations_x_third = GoodLocations_x
      GoodLocations_y_third = GoodLocations_y
    endif
	endfor

  window, 24, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_first'
  tv, temp_first>0
	window, 25, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_second'
	tv, temp_second>0
	window, 26, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_third'
  tv, temp_third>0
	window, 27, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_all_first'
  tv, temp_all_first>0
	window, 28, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_all_second'
	tv, temp_all_second>0
	window, 29, xsize = film_width, ysize = film_height, XPOS=2, YPOS=512, title = 'temp_all_third'
  tv, temp_all_third>0

  WRITE_TIFF, run + "_peaks_first.tif", temp_all_first>0, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression=2
	WRITE_TIFF, run + "_peaks_second.tif", temp_all_second>0, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression=2
	WRITE_TIFF, run + "_peaks_third.tif", temp_all_third>0, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG, compression=2

  WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations_first) + " good peaks circled for first laser."), /APPEND, /SHOW
  WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofBadLocations_first) + " bad peaks."), /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations_second) + " good peaks circled for second laser."), /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofBadLocations_second) + " bad peaks."), /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations_third) + " good peaks circled for third laser."), /APPEND, /SHOW
  WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofBadLocations_third) + " bad peaks."), /APPEND, /SHOW
	WIDGET_CONTROL, text_ID, SET_VALUE=(STRING(NumberofGoodLocations_all/color_number) + " good molecules circled for all lasers."), /APPEND, /SHOW

	openw, 1, run + ".3color_3alex_pks"
	printf, 1, NumberofGoodLocations_all
	for i = 0, NumberofGoodLocations_all - 1 do begin
    	printf, 1, i+1, GoodLocations_x_all(i), GoodLocations_y_all(i),Background_first_all(i),Background_second_all(i), Background_third_all(i)
	endfor
	if color_change_check eq 'y' then begin ;XOR ((film_time_start MOD 2) eq 0)) then begin
		printf, 1, 'y'
	endif else begin
		printf, 1, 'n'
	endelse
	close, 1

	WIDGET_CONTROL, text_ID, SET_VALUE="Done. Byebye~", /APPEND, /SHOW

end

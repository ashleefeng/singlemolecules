
pro smb_analyze_all_3alex

	; Custumizing parameters
	windows_close = 'no'
	path = 'E:\Ashlee\Lab-Data_local\SWR1\190924_iNuc_flow\7_flow_10nM_SWR1_20nM_newZB\reaction flow\'
	;path = 'W:\PFV_IN\3_10'
	mapfile = 'E:\Ashlee\Lab-Data_local\SWR1\190924_iNuc_flow\beads\rough.map'
	color_number = 3		; 2 or 3 color
	answer_need_mapping = "No"
	answer_need_movie = "No"
	;Program start

	loadct, 5
	device, decomposed=0

	COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

	;path = DIALOG_PICKFILE(TITLE='Select Working Directory', /DIRECTORY)
	cd, path

	;mapfile = DIALOG_PICKFILE(PATH='c:\NotVaildDirectory\', TITLE='Select Mapping File', /READ, FILTER = '*.map')

	filelist = FILE_SEARCH(path, '*.pma', COUNT=file_number, /EXPAND_ENVIRONMENT)

	xdisplayFile, '', TEXT=(STRING(file_number)+ " files are found."), RETURN_ID=display_ID, WTEXT=text_ID

	;answer_need_mapping = DIALOG_MESSAGE("Independent mapping file for each data?", /QUESTION, /DEFAULT_NO)
	;answer_need_movie = DIALOG_MESSAGE("Movie files for every data?", /QUESTION, /DEFAULT_NO)


	for j = 0, file_number - 1 do begin
		filelist(j) = strmid(filelist(j), 0, strlen(filelist(j)) - 4)

		if FILE_TEST(filelist(j) + ".pma") eq 1 then begin
			if FILE_TEST(filelist(j) + ".3color_3alex_pks") eq 0 and FILE_TEST(filelist(j) + ".pks") eq 0 then begin								; .pks file doesn't exist.
				WIDGET_CONTROL, text_ID, SET_VALUE=("Working on (" + STRING(j) + ") : " + filelist(j) + ".pma"), /APPEND

				if answer_need_mapping eq "Yes" then begin
					answer_mapping_ok = DIALOG_MESSAGE("Need new mapping file?", /QUESTION)
					if answer_mapping_ok eq "Yes" then begin
						smb_mapping_maker_3color, filelist(j), text_ID										; .map file generator
						answer_mapping_ok = DIALOG_MESSAGE("Use this mapping file?", /QUESTION)
					endif
					if answer_mapping_ok eq "No" then begin
						mapfile = DIALOG_PICKFILE(PATH='c:\NotVaildDirectory\', TITLE='Select Mapping File', /READ, FILTER = '*.3map')
					endif
					file_delete, filelist(j) + ".coeff", /ALLOW_NONEXISTENT
					if answer_mapping_ok eq "No" then begin
						if color_number eq 3 then begin
							smb_peak_location_maker_3color_3alex, filelist(j), mapfile, text_ID		; .pks file generator
						endif
					endif else begin
						if color_number eq 3 then begin
							smb_peak_location_maker_3color_3alex, filelist(j), filelist(j)+".3map", text_ID		; .pks file generator
						endif
					endelse
				endif else begin
					if color_number eq 3 then begin
						smb_peak_location_maker_3color_3alex, filelist(j), mapfile, text_ID					; .pks file generator
					endif
				endelse
			endif

			if FILE_TEST(filelist(j) + ".2color_2alex_traces") eq 0 and FILE_TEST(filelist(j) + ".3color_2alex_traces") eq 0 then begin							; .traces file doesn't exist.
				smb_peak_trace_maker_3color_3alex, filelist(j), text_ID, color_number										; .traces file generator
			endif

		;	if FILE_TEST(filelist(j) + ".2color_2alex_movies") eq 0 and FILE_TEST(filelist(j) + ".3color_2alex_traces") eq 0 then begin							; .movie file doesn't exist.
		;		if answer_need_movie eq 'Yes' then begin
		;			smb_peakmovie_maker_3alex, filelist(j), text_ID, color_number										; .movie file generator
		;		endif
		;	endif
		endif
	endfor

	WIDGET_CONTROL, text_ID, SET_VALUE="Done. End of ana_all. Byebye.", /APPEND

	;answer = DIALOG_MESSAGE("Do you want to close all the window?", /QUESTION, /DEFAULT_NO)
	;window_close = answer
	if windows_close eq 'Yes' then begin
		WIDGET_CONTROL, display_ID, /DESTROY
		wdelete, 0
		wdelete, 1
	endif

end

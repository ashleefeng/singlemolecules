; analyzes the time traces of the molecules
; that created the peaks that were identified
; with findpeak.
;
; hazen 1/99
;
; modified to give background subtracted value
; based on estimated background from findpeak2.
;
; hazen 3/99
;
; modified to calculate background directly using
; median of surrounding values.
;
; hazen 7/99
;
; above modification removed.
;
; hazen 7/99
;
; modified to use a gaussian weighting when calculating
; the peak intensity in hopes of an improvement in SNR.
;
; hazen 11/99
;
; modified to correct an error in how the background was subtracted
;
; hazen 2/00
;
; modified for use by TJ
;
; hazen 3/00
;

pro p_nxgn1_ap_3ch_ALEX, run

loadct, 5

; generate gaussian peaks

g_peaks = fltarr(2,2,7,7)

for k = 0, 1 do begin
	for l = 0, 1 do begin
		offx = -0.5*float(k)
		offy = -0.5*float(l)
		for i = 0, 6 do begin
			for j = 0, 6 do begin
				dist = 0.3 * ((float(i)-3.0+offx)^2 + (float(j)-3.0+offy)^2)
				g_peaks(k,l,i,j) = 2.0*exp(-dist)
			endfor
		endfor
	endfor
endfor

apeak  = fltarr(7,7)	; temp storage for analysis

; initialize variables

film_x = fix(1)
film_y = fix(1)
fr_no  = fix(1)

close, 1				; make sure unit 1 is closed
close, 2

openr, 1, run + ".pma"
openr, 2, run + ".pks"

; figure out size + allocate appropriately

result = FSTAT(1)
readu, 1, film_x
readu, 1, film_y
film_l = long(long(result.SIZE-4)/(long(film_x)*long(film_y)))

print, "film x,y,l : ", film_x,film_y,film_l

frame = bytarr(film_x,film_y)

; load the locations of the peaks

foo = fix(0)
x = float(0)
y = float(0)
b = float(0)
no_good = 0
good = fltarr(2,10000)
back = fltarr(10000)
back2 = fltarr(10000)

while EOF(2) ne 1 do begin
	readf, 2, foo, x, y, b, b2
	good(0,no_good) = x
	good(1,no_good) = y
	back(no_good) = b
	back2(no_good) = b2
	no_good = no_good + 1
endwhile

close, 2

flgd = intarr(2,10000)
flgd(0,*) = floor(good(0,*))
flgd(1,*) = floor(good(1,*))

print, no_good, " peaks were found in file"

time_tr = intarr(no_good,film_l)
time_tr_bsl = intarr(no_good,film_l)
whc_gpk = intarr(no_good,2)

; calculate which peak to use for each time trace based on
; peak position

for i = 1, no_good - 1 do begin
	whc_gpk(i,0) = round(2.0 * (good(0,i) - flgd(0,i)))
	whc_gpk(i,1) = round(2.0 * (good(1,i) - flgd(1,i)))
endfor

; now read values at peak locations into time_tr array

for i = 0, film_l - 1 do begin
	if (i mod 10) eq 0 then print, "working on : ", i, film_l
	readu, 1, frame
	for j = 0, no_good - 1 do begin
;		print, "film_x ",film_x
;		print, flgd(0,j)-3
;		print, flgd(0,j)+3
;		print, "film_y ",film_y
;		print, flgd(1,j)-3
;		print, flgd(1,j)+3
		;print, i, j
		apeak = g_peaks(whc_gpk(j,0),whc_gpk(j,1),*,*) * float(frame(flgd(0,j)-3:flgd(0,j)+3,flgd(1,j)-3:flgd(1,j)+3))
		time_tr(j,i) = round(total(apeak))
	endfor
endfor

close, 1

openr, 1, run + ".pma"

readu, 1, film_x
readu, 1, film_y

; now read values at peak locations into time_tr_bsl array

for i = 0, film_l - 1 do begin
	if (i mod 10) eq 0 then print, "working on : ", i, film_l
	readu, 1, frame
	for j = 0, no_good - 1 do begin
		if flgd(0,j)+7 eq film_x then begin
			apeak = g_peaks(whc_gpk(j,0),whc_gpk(j,1),*,*) * median(frame(flgd(0,j)-7:(film_x - 1),flgd(1,j)-7:flgd(1,j)+7))
		endif else begin
			if flgd(1,j)+7 eq film_y then begin
				apeak = g_peaks(whc_gpk(j,0),whc_gpk(j,1),*,*) * median(frame(flgd(0,j)-7:flgd(0,j)+7,flgd(1,j)-7:(film_y - 1)))
			endif else begin
				apeak = g_peaks(whc_gpk(j,0),whc_gpk(j,1),*,*) * median(frame(flgd(0,j)-7:flgd(0,j)+7,flgd(1,j)-7:flgd(1,j)+7))
			endelse
		endelse

		time_tr_bsl(j,i) = round(total(apeak))
	endfor
endfor

close, 1

;time_tr = time_tr - time_tr_bsl

no_good = no_good
openw, 1, run + "_raw.traces"
writeu, 1, film_l
writeu, 1, no_good
writeu, 1, time_tr
close, 1

openw, 1, run + "_bsl.traces"
writeu, 1, film_l
writeu, 1, no_good
writeu, 1, time_tr_bsl
close, 1

end
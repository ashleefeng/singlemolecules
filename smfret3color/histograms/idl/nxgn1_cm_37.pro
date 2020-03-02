;
; semi-automated routine figure out how the 2 channels
; map onto each other. finds the mapping that gives
; the minimum error in the least squares sense.
;
; xf = ax + bx * xi + cx * yi
; yf = ay + by * xi + cy * yi
;
; hazen 2/99
;
; modified to use a rough mapping to find possible
; corresponding peaks as we finally gave up on the
; chromatic thing and use a different lens for each
; color. This means that the 2 colors have different
; magnifications and etcetera.
;
; hazen 5/99
;
; modified to use IDLs POLYWARP routine so that we can
; later use IDLs POLY_2D routine to overlay the left
; and right channels
;
; hazen 11/99
;

loadct, 5

COMMON colors, R_ORIG, G_ORIG, B_ORIG, R_CURR, G_CURR, B_CURR

circle = bytarr(11,11)

circle(*,0) = [	0,0,0,0,0,0,0,0,0,0,0]
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

; get file to open

run = "asdf"

print, "name of file to analyze"
read, run

film_x = fix(1)
film_y = fix(1)

; input film

close, 1				; make sure unit 1 is closed

dir = "X:\folder\beads_file\"
openr, 1, dir + run + ".pma"

; figure out size + allocate appropriately

result = FSTAT(1)
readu, 1, film_x
readu, 1, film_y
film_l = long(long(result.SIZE-4)/(long(film_x)*long(film_y)))

print, "film x,y,l : ", film_x,film_y,film_l

if film_l gt 10 then film_l = 10

window, 0, xsize=film_x, ysize=film_y
frame   = bytarr(film_x,film_y)
ave_arr = fltarr(film_x,film_y)

openr, 2, dir + run + "_ave.tif", ERROR = err
if err eq 0 then begin
	close, 1
	close, 2
	frame = read_tiff(dir + run + "_ave.tif")
endif else begin
	close, 2
	for j = 0, film_l - 1 do begin
		if((j mod 5) eq 0) then print, j, film_l
		readu, 1, frame
		ave_arr = ave_arr + frame
	endfor
	close, 1
	ave_arr = ave_arr/float(film_l - 1)
	frame = byte(ave_arr)

	; frame = smooth(frame,2,/EDGE_TRUNCATE)

	WRITE_TIFF, dir + run + "_ave.tif", frame, 1, RED = R_ORIG, GREEN = G_ORIG, BLUE = B_ORIG
endelse

; subtracts background

temp1 = frame
temp1 = smooth(temp1,2,/EDGE_TRUNCATE)

aves = fltarr(film_x/16,film_y/16)
print, film_x,film_y

for i = 8, film_x, 16 do begin
	for j = 8, film_y, 16 do begin
		aves((i-8)/16,(j-8)/16) = min(temp1(i-8:i+7,j-8:j+7))
	endfor
endfor

aves = rebin(aves,film_x,film_y)
aves = smooth(aves,20,/EDGE_TRUNCATE)

temp1 = frame - (byte(aves) - 10)

; thresholds the image for peak finding purposes

temp2 = temp1
med = float(median(temp1))
stf = moment(temp1)

std = 15
for i = 0, film_x - 1 do begin
	for j = 0, film_y - 1 do begin
		if temp2(i,j) lt byte(med + std) then temp2(i,j) = 0
	endfor
endfor

wset, 0
tv, temp2

; find the peaks

temp3 = frame
temp4 = temp3
wset, 0

good = intarr(2,4000)
bogo = intarr(2,4000)
foob = bytarr(7,7)
blow = bytarr(84,84)

no_good = 0
no_bogo = 0

for i = 10, 501 do begin
	if i eq 160 then i = 352	; skip region where channels overlap
	for j = 10, film_y - 10 do begin
		if temp2(i,j) gt 0 then begin

			; find the nearest maxima

			foob = temp2(i-3:i+3,j-3:j+3)
			z = max(foob,foo)
			y = foo / 7 - 3
			x = foo mod 7 - 3

			; only analyze peaks in current column,
			; and not near edge of area analyzed

			if x gt -1 and x lt 1 then begin
				if y gt -1 and y lt 1 then begin
					y = y + j
					x = x + i
					yup = 0

					; check if we have it already

					for k = 0, no_good - 1 do begin
						if x eq good(0,k) then begin
							if y eq good(1,k) then yup = 1
						endif
					endfor
					for k = 0, no_bogo - 1 do begin
						if x eq bogo(0,k) then begin
							if y eq bogo(1,k) then yup = 1
						endif
					endfor

					; check if its a good peak
					; i.e. surrounding points below 1 stdev

					quality = 1
					for k = -5, 5 do begin
						for l = -5, 5 do begin
							if circle(k+5,l+5) gt 0 then begin
								;if temp1(x+k,y+l) gt byte(med + 0.25 * float(z)) then quality = 0
								if temp1(x+k,y+l) gt byte(med + 0.65 * float(z)) then quality = 0
							endif
						endfor
					endfor

					if quality eq 1 then begin

						; draw where peak was found on screen

						for k = -5, 5 do begin
							for l = -5, 5 do begin
								if circle(k+5,l+5) gt 0 then begin
									temp4(x+k,y+l) = 90
								endif
							endfor
						endfor
						wset, 0
						tv, temp4

						good(0,no_good) = x
						good(1,no_good) = y
						no_good = no_good + 1
						temp3 = temp4
					endif else begin
						bogo(0,no_bogo) = x
						bogo(1,no_bogo) = y
						no_bogo = no_bogo + 1
						temp4 = temp3
					endelse
				endif
			endif

		endif

	endfor
endfor

print, "there were ", no_good, "good peaks"

; now sift through for the peaks that appear in both channels

pxl = fix(1)
pyl = fix(1)
pxr = fix(1)
pyr = fix(1)

diff_x = 254
diff_y = 1

x_i = intarr(1,1000)
y_i = intarr(1,1000)
x_f = intarr(1,1000)
y_f = intarr(1,1000)

no_pairs = 0

; load coefficients for rough map

trans_x = fltarr(3)
trans_y = fltarr(3)
foo = float(1)

openr, 1, dir + run + ".coeff"
for j = 0, 2 do begin
	readf, 1, foo
	trans_x(j) = foo
endfor
for j = 0, 2 do begin
	readf, 1, foo
	trans_y(j) = foo
endfor
close, 1

; find peaks that have approximately this spacing

for i = 0, no_good - 1 do begin
	if good(0,i) lt 170 then begin

		; calculate location of pair

		xf = round(trans_x(0) + trans_x(1)*float(good(0,i)) + trans_x(2)*float(good(1,i)))
		yf = round(trans_y(0) + trans_y(1)*float(good(0,i)) + trans_y(2)*float(good(1,i)))
		for j = i + 1, no_good - 1 do begin
			if abs(good(0,j) - xf) lt 3 then begin
				if abs(good(1,j) - yf) lt 3 then begin

					; temp4 = temp3

					; circle the two peaks

					for k = -5, 5 do begin
						for l = -5, 5 do begin
							if circle(k+5,l+5) gt 0 then begin
								temp4(good(0,i)+k,good(1,i)+l) = 240
								temp4(good(0,j)+k,good(1,j)+l) = 240
							endif
						endfor
					endfor

					tv, temp4

					x_i(no_pairs) = good(0,i)
					y_i(no_pairs) = good(1,i)
					x_f(no_pairs) = good(0,j) - 342
					y_f(no_pairs) = good(1,j)
					no_pairs = no_pairs + 1

				endif
			endif
		endfor
	endif
endfor

print, no_pairs

if no_pairs gt 16 then begin

	print, "found ", no_pairs, " pairs"

	POLYWARP, x_f, y_f, x_i, y_i, 3, P, Q

	openw, 1, dir + run + ".map"

	for i = 0, 15 do begin
		printf, 1, P(i)
	endfor
	for i = 0, 15 do begin
		printf, 1, Q(i)
	endfor
	close, 1

	print, P
	print, Q

endif else begin
	print, "not enough matches"
endelse

end
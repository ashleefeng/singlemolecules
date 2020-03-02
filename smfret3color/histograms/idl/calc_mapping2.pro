;
; calculates mapping from one channel to the other
; for two color images
;
; Hazen 1/99
;

loadct, 5

circle = bytarr(11,11)

circle(*,0) = [	0,0,0,0,1,1,1,0,0,0,0]
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

; get file to open

run = "asdf"

print, "name of file to analyze"
read, run

film_x = fix(512)
film_y = fix(512)

; input film

close, 1				; make sure unit 1 is closed

; open file
dir = "X:\folder\beads_file\"
; figure out size + allocate appropriately

frame = read_tiff(dir + run + "_ave.tif")

window, 0, xsize=film_x, ysize=film_y
wset, 0
tv, frame


; first, have user figure out image corresondence

x_i = fltarr(3)
y_i = fltarr(3)
x_f = fltarr(3)
y_f = fltarr(3)
trans_mat = fltarr(3,3)

A = 'd'

for j = 0, 2 do begin
	wset, 0
	x = fix(1)
	y = fix(1)
	print, "click on spot in left image"
	cursor,x,y,3,/device
	x_i(j) = x
	y_i(j) = y
	;print, "click on spot in right image;
	;cursor,x,y,3,/device
	x_f(j) = x_i(j) + 256
	y_f(j) = y_i(j) + 0

	print, "use keyboard to tweak, <s> to stop"
	A = 'd'
	while A ne 's' do begin
		temp = frame

		; show spots the user picked

		for k = -5, 5 do begin
			for l = -5, 5 do begin
				if circle(k+5,l+5) gt 0 then begin
					temp(x_i(j)+k,y_i(j)+l) = 255
					temp(x_f(j)+k,y_f(j)+l) = 255
				endif
			endfor
		endfor
		wset, 0
		tv, temp

		A = get_kbrd(1)
		case A of
			'r' : y_i(j) = y_i(j)+1
			'f' : x_i(j) = x_i(j)+1
			'c' : y_i(j) = y_i(j)-1
			'd' : x_i(j) = x_i(j)-1
			'y' : y_f(j) = y_f(j)+1
			'h' : x_f(j) = x_f(j)+1
			'b' : y_f(j) = y_f(j)-1
			'g' : x_f(j) = x_f(j)-1
			else : A = A
		endcase
	endwhile
	frame = temp
endfor

; set up matrices

trans_mat(0,*) = 1.0
trans_mat(1,*) = x_i
trans_mat(2,*) = y_i

inv_mat = invert(trans_mat)

; calculate coefficients and save coefficients

openw, 1, dir + run + ".coeff"
printf, 1, total(inv_mat(*,0) * x_f)
printf, 1, total(inv_mat(*,1) * x_f)
printf, 1, total(inv_mat(*,2) * x_f)
printf, 1, total(inv_mat(*,0) * y_f)
printf, 1, total(inv_mat(*,1) * y_f)
printf, 1, total(inv_mat(*,2) * y_f)
close, 1

print, total(inv_mat(*,0) * x_f)
print, total(inv_mat(*,1) * x_f)
print, total(inv_mat(*,2) * x_f)
print, total(inv_mat(*,0) * y_f)
print, total(inv_mat(*,1) * y_f)
print, total(inv_mat(*,2) * y_f)

end
; Performs analysis on all the files in the sub-directories of
; a given directory. Tired of running everything by hand.
;
; Hazen 3/00
;
; get directory to analyze from user

dir = "X:\folder\super_folder\" ; data need to be in sub-folders
run = "asdf"

print, "name of directories to analyze"
read, run


path = dir + run
print, path

; find all the sub-directories in that directory

foo_dirs = findfile(path + '\*')
nfoo_dirs = size(foo_dirs)

nsub_dirs = 0							; figure number of sub-directories

for i = 2, nfoo_dirs(1) - 1 do begin
	if rstrpos(foo_dirs(i),'\') eq (strlen(foo_dirs(i)) - 1) then begin
		nsub_dirs = nsub_dirs + 1
	endif
endfor

sub_dirs = strarr(nsub_dirs)

j = 0
for i = 2, nfoo_dirs(1) - 1 do begin	; get sub-directory names
	if rstrpos(foo_dirs(i),'\') eq (strlen(foo_dirs(i)) - 1) then begin
		sub_dirs(j) = foo_dirs(i)
		j = j + 1
	endif
endfor



; now go through sub-directories finding the files to be analyzed and
; analyzing them if necessary.

for i = 0, nsub_dirs - 1 do begin

	print, "Current Directory : ", sub_dirs(i)

	; find all the *.pma files in the sub-directory
	; analyze them if there is no currently existing .pks file

	f_to_a = findfile(sub_dirs(i) + '*.pma')
	nf_to_a = size(f_to_a)
	for j = 0, nf_to_a(1) - 1 do begin
		f_to_a(j) = strmid(f_to_a(j), 0, strlen(f_to_a(j)) - 4)
		openr, 1, f_to_a(j) + ".pks", ERROR = err
		close, 1
		if err ne 0 then begin
			print, "Working on : ", f_to_a(j)
			p_nxgn1_ffp_3ch_ALEX_MattThreeColor, f_to_a(j)
			p_nxgn1_ap_3ch_ALEX, f_to_a(j)
		endif
	endfor
endfor

print, "Done."

end

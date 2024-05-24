use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)

* generate female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)


* mark western länder
merge m:1 hid syear using ${v38}regionl, keep(3) nogen

recode bula (1/10 = 1) (11/16 = 0) (nonmissing = .), gen(west)

label variable west "Residence in West Germany"

label define west 0 "[0] Does not reside in West Germany", modify
label define west 1 "[1] Resides in West Germany", modify

label values west west

drop if mi(west)


* mark eastern origin
recode loc1989 (1 = 1) (2 = 0) (nonmissing = .), gen(east_origin)

label variable east_origin "East German Origin"

label define east_origin 0 "[0] Does not have East German Origin", modify
label define east_origin 1 "[1] Has East German Origin", modify

label values east_origin east_origin

drop if mi(east_origin)


* mark stem professions
merge 1:1 pid syear using ${v38}pl, keep(3) keepusing(p_isco88) nogen

recode p_isco88 (1236 2111/2213 3111/3212 = 1) (min/0 = .) (nonmissing = 0), gen(stem)

label variable stem "STEM Profession"

label define stem 0 "[0] Does not have a STEM Profession", modify
label define stem 1 "[1] Has a STEM Profession", modify

label values stem stem

drop if mi(stem)


* get employment status
merge 1:1 pid syear using ${v38}pgen, keep(1 3) keepusing(pgemplst) nogen

recode pgemplst (2 = 1) (1 3 4 5 6 = 0), gen(part_time)
recode pgemplst (3 = 1) (1 2 4 5 6 = 0), gen(in_training)
recode pgemplst (4 = 1) (1 2 3 5 6 = 0), gen(irregular_emp)
recode pgemplst (5 6 = 1) (1 2 3 4 = 0), gen(emp_other)


* generate interactions
gen east_origin_female   = east_origin * female
gen west_female          = west * female
gen part_time_female     = part_time * female
gen irregular_emp_female = irregular_emp * female

* age
gen age = syear - gebjahr
gen age_2 = age^2


* save dataset
compress
save ${data}female_stem, replace

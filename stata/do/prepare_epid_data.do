** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* parental info
{

* info on mothers
{

use ${data}female_stem, clear
keep if female == 1

* check if mother ever worked in stem
egen stem_ever = max(stem), by(pid)
drop stem

label define stem_ever 0 "[0] Never had a STEM Profession", modify
label define stem_ever 1 "[1] Has or had a STEM Profession", modify

label values stem_ever stem_ever


duplicates drop pid, force

rename pid mnr
rename east_origin mother_east_or
rename stem_ever mother_stem_ever
keep mnr mother_east_or mother_stem_ever

label variable mother_east_or "Mother: Eastern Origin"
label variable mother_stem_ever "Mother: Ever STEM Profession"

merge 1:m mnr using ${v38}bioparen, keep(2 3) nogen
 
save ${data}parents, replace

}



* info on fathers
{

use ${data}female_stem, clear
keep if female == 0

* check if father ever worked in stem
egen stem_ever = max(stem), by(pid)
drop stem

duplicates drop pid, force

rename pid fnr
rename east_origin father_east_or
rename stem_ever father_stem_ever
keep fnr father_east_or father_stem_ever

label variable father_east_or "Father: Eastern Origin"
label variable father_stem_ever "Father: Ever STEM Profession"


merge 1:m fnr using ${data}parents, keep(2 3) nogen
 
save ${data}parents, replace

}


* drop cases with missing information
drop if fnr < 0 | /// father's id missing
		mnr < 0 | /// mother's id missing
		mi(father_east_or) | ///
		mi(mother_east_or) | ///
		mi(father_stem_ever) | ///
		mi(mother_stem_ever)


* save dataset
compress
save ${data}parents, replace

}


* children
{

* get ppathl info for children
use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)


* 6 years old or younger at the year of reunification
keep if gebjahr >= 1984


merge m:1 pid using ${data}parents, keep(3) nogen


* info about educational field
merge 1:1 pid syear using ${v38}pgen, keep(1 3) keepusing(pgfield pgbilzeit)


recode pgfield (36/44 61/69 79 89 104 118 126 128 177 200 213/226 235 277 310 370 = 1) ///
			   (min/0 = .) ///
			   (nonmissing = 0), ///
			   gen(stem_edu)

drop if mi(stem_edu)


* generate female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)


* generate age
gen age = syear - gebjahr
gen age_squared = age^2

label variable age "Age"
label variable age_squared "Age (squared)"


* number of siblings
gen num_sib = numb + nums if numb >= 0 & nums >= 0
label variable num_sib "Number of Siblings"


* migration background
recode migback (1 = 0) (2 3 = 1)
label define migback_bin 0 "No Migration Background", modify
label define migback_bin 1 "Direct/Indirect Migration Background", modify

label values migback migback_bin


* federal states
merge m:1 hid syear using ${v38}regionl, keep(3) keepusing(bula) nogen

* leave out largest federal state dummy
tab bula, gen(bula_)

egen max_cat_bula = mode(bula)
tab max_cat_bula, matrow(mat)
local max_cat = mat[1,1]
drop bula_`max_cat'
drop max_cat_bula


* save dataset
save ${data}children, replace

}



* parental income
{

use ${data}children, clear

* mothers' net monthly household income
rename pid cnr
rename hid c_hid
rename mnr pid

merge m:1 pid syear using ${v38}ppathl, keep(1 3) keepusing(hid) nogen
merge m:1 hid syear using ${v38}hl, keep(1 3) keepusing(hlc0005_h) nogen

rename hlc0005_h mother_hhincome
rename hid mother_hid
rename pid mnr


* fathers' net monthly household income
rename fnr pid

merge m:1 pid syear using ${v38}ppathl, keep(1 3) keepusing(hid) nogen
merge m:1 hid syear using ${v38}hl, keep(1 3) keepusing(hlc0005_h) nogen

rename hlc0005_h father_hhincome
rename hid father_hid
rename pid fnr


rename c_hid hid
rename cnr pid

* consistency check (if mother and father live in same hh, then
* their household income should be identical)
count if father_hhincome >= 0 & ///
		 mother_hhincome >= 0 & ///
		 father_hid == mother_hid & ///
		 father_hhincome != mother_hhincome


gen parental_hhincome = father_hhincome if father_hhincome >= 0 & ///
										   mother_hhincome >= 0 & ///
										   !mi(father_hhincome) & ///
										   !mi(mother_hhincome) & ///
										   father_hid > 0 & ///
										   mother_hid > 0 & ///
										   !mi(father_hid) & ///
										   !mi(mother_hid) & ///
										   father_hid == mother_hid


replace parental_hhincome = father_hhincome + mother_hhincome if father_hhincome >= 0 & ///
																 mother_hhincome >= 0 & ///
																 !mi(father_hhincome) & ///
																 !mi(mother_hhincome) & ///
																 father_hid > 0 & ///
																 mother_hid > 0 & ///
																 !mi(father_hid) & ///
																 !mi(mother_hid) & ///
																 father_hid != mother_hid


* save dataset
compress
save ${data}children, replace

}

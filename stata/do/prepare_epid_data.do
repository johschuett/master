** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* info on mothers
{

use ${data}female_stem, clear
keep if female == 1

* check if mother ever worked in stem
egen stem_ever = max(stem), by(pid)
drop stem


label variable stem_ever "Ever STEM Profession"

label define stem_ever 0 "[0] Never had a STEM Profession", modify
label define stem_ever 1 "[1] Has or had a STEM Profession", modify

label values stem_ever stem_ever


duplicates drop pid, force

rename pid mnr
rename east_origin mother_east_or
rename stem mother_stem_ever
keep mnr mother_east_or mother_stem_ever

merge 1:m mnr using ${v38}bioparen, keep(2 3) nogen
 
save ${data}merged, replace

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


merge 1:m fnr using ${data}merged, keep(2 3) nogen
 
save ${data}merged, replace

}



* drop cases with missing information
drop if fnr < 0 | /// father id missing
		mnr < 0 | /// mother id missing
		mi(father_east_or) | /// father's origin missing
		mi(mother_east_or) | /// mother's origin missing
		mi(father_stem) | /// father's occcupation missing
		mi(mother_stem)
		




















* only keep people who work or have worked in stem (potential parents)
use ${data}female_stem, clear
drop if stem == 0


duplicates drop pid, force
rename pid mnr
clonevar fnr = mnr


replace mnr = . if female == 0
replace fnr = . if female == 1


keep mnr fnr


save ${data}parents, replace


* get children of stem mothers
drop if mi(mnr)

merge 1:m mnr using ${v38}merged, keep(2 3)

gen stem_mother = 0
replace stem_mother = 1 if _merge == 3
drop _merge

save ${data}merged, replace


* get children of stem fathers
use ${data}parents, clear

drop if mi(fnr)

merge 1:m fnr using ${data}merged, keep(2 3)

gen stem_father = 0
replace stem_father = 1 if _merge == 3
drop _merge

save ${data}merged, replace












* get ppathl info for children
use ${v38}ppathl, clear


* 6 years old or younger at the year of reunification
keep if gebjahr >= 1984


merge m:1 pid using ${data}merged, keep(3) nogen


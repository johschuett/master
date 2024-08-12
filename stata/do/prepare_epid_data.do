** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* parental info
{

* info on mothers
{

use ${data}female_stem, clear
keep if female == 1

* check if mother ever worked in stem
egen ever_stem = max(stem), by(pid)
drop stem

label define ever_stem 0 "[0] Never had a STEM Profession", modify
label define ever_stem 1 "[1] Has or had a STEM Profession", modify

label values ever_stem ever_stem


duplicates drop pid, force

rename pid mnr
rename east_origin mother_east_or
rename ever_stem mother_ever_stem
keep mnr mother_east_or mother_ever_stem

label variable mother_east_or "Mother: Eastern Origin"
label variable mother_ever_stem "Mother: Ever STEM Profession"


save ${data}potential_mothers, replace


merge 1:m mnr using ${v38}bioparen, keep(2 3) nogen
 
save ${data}parents, replace

}



* info on fathers
{

use ${data}female_stem, clear
keep if female == 0

* check if father ever worked in stem
egen ever_stem = max(stem), by(pid)
drop stem

duplicates drop pid, force

rename pid fnr
rename east_origin father_east_or
rename ever_stem father_ever_stem
keep fnr father_east_or father_ever_stem

label variable father_east_or "Father: Eastern Origin"
label variable father_ever_stem "Father: Ever STEM Profession"


save ${data}potential_fathers, replace


merge 1:m fnr using ${data}parents, keep(2 3) nogen
 
save ${data}parents, replace

}


* drop cases with missing information
drop if fnr < 0 | /// father's id missing
		mnr < 0 | /// mother's id missing
		mi(father_east_or) | ///
		mi(mother_east_or) | ///
		mi(father_ever_stem) | ///
		mi(mother_ever_stem)


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
merge 1:1 pid syear using ${v38}pgen, keep(1 3) keepusing(pgfield pgbilzeit pgpsbil pgpbbil02 pgtraina pgtrainb pgtrainc pgtraind) nogen


* drop individuals that are still in school
drop if pgpsbil == 7


* university or vocational degree
gen university = .
replace university = 1 if pgpbbil02 > 0 // non-missing value in college degree variable
replace university = 0 if pgpbbil02 < 0 & (pgtraina > 0 | pgtrainb > 0 | pgtrainc > 0 | pgtraind > 0) // non-missing value in one of the vocational degree variables
replace university = . if pgpbbil02 == -1

label variable university "University Degree rather than Vocational Degree"

label define university 0 "[0] Vocational Degree", modify
label define university 1 "[1] University Degree", modify

label values university university


* what university degree
recode pgfield (36/44 61/69 79 89 104 118 126 128 177 200 213/226 235 277 310 370 = 1) ///
			   (min/0 = .) ///
			   (nonmissing = 0), ///
			   gen(stem_edu)

* sanity check: individuals should have no information in this variable if they have no university degree, but a vocational degree
replace stem_edu = . if university == 0


label variable stem_edu "STEM university degree"

label define stem_edu 0 "[0] Has a non-STEM university degree", modify
label define stem_edu 1 "[1] Has a STEM university degree", modify

label values stem_edu stem_edu


* generate female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)


* drop people born outside of germany
drop if germborn == 2


* generate age
gen age = syear - gebjahr
gen age_squared = age^2

label variable age "Age"
label variable age_squared "Age (squared)"


* partner
recode partner (1/4 = 1) (0 5 = 0), gen(partner_bin)
label variable partner_bin "Spouse/Life Partner"

label define partner_bin 0 "[0] Does not have a Spouse/Life Partner", modify
label define partner_bin 1 "[1] Has a Spouse/Life Partner", modify

label values partner_bin partner_bin


* household size
merge m:1 hid syear using ${v38}hbrutto, keep(3) keepusing(hhgr) nogen
label variable hhgr "Household Size"


* number of siblings
gen num_sib = numb + nums if numb >= 0 & nums >= 0
label variable num_sib "Number of Siblings"


* indirect migration background
recode migback (1 = 0) (3 = 1)

label variable migback "Indirect Migration Background"

label define migback_bin 0 "[0] No Migration Background", modify
label define migback_bin 1 "[1] Indirect Migration Background", modify

label values migback migback_bin


* federal state
merge m:1 hid syear using ${v38}regionl, keep(3) keepusing(bula) nogen


* residence west germany
recode bula (1/10 = 1) (11/16 = 0) (nonmissing = .), gen(west)

label variable west "Residence in West Germany"

label define west 0 "[0] Does not reside in West Germany", modify
label define west 1 "[1] Resides in West Germany", modify

label values west west


* save dataset
save ${data}children, replace


* interaction
gen mother_stem_east = mother_ever_stem * mother_east_or
label variable mother_stem_east "Mother: Ever STEM Profession $\times$ Mother: Eastern Origin"

gen father_stem_east = father_ever_stem * father_east_or
label variable father_stem_east "Father: Ever STEM Profession $\times$ Father: Eastern Origin"


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

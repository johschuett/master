** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* parents
{

use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)


* generate female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)


* warsaw pact / nato state of origin
recode corigin (31 51 100 112 203 233 268 348 398 417 428 440 498 616 642 643 703 762 795 804 860 = 1) ///
			   (16 56 86 124 208 250 300 380 442 528 578 620 724 826 840 = 0) ///
			   (nonmissing = .), ///
			   gen(warsaw_pact)

replace warsaw_pact = 1 if loc1989 == 1 & germborn == 1
replace warsaw_pact = 0 if loc1989 == 2 & germborn == 1

label variable warsaw_pact "Former Warsaw Pact State"

label define warsaw_pact 0 "[0] NATO State", modify
label define warsaw_pact 1 "[1] Former Warsaw Pact State", modify

label values warsaw_pact warsaw_pact

drop if mi(warsaw_pact)

			   
* stem profession
merge 1:1 pid syear using ${v38}pl, keep(1 3) keepusing(p_isco88) nogen

recode p_isco88 (1236 2111/2213 3111/3212 = 1) (min/0 = .) (nonmissing = 0), gen(stem)

label variable stem "STEM Profession"

label define stem 0 "[0] Does not have a STEM Profession", modify
label define stem 1 "[1] Has a STEM Profession", modify

label values stem stem


* info about employment status
merge 1:1 pid syear using ${v38}pgen, keep(1 3) keepusing(pgemplst) nogen


* only individuals who are either full- or part-time employed should be marked
* as success in stem variable
replace stem = 0 if !inrange(pgemplst, 1, 2)
replace stem = . if pgemplst < 0 & stem == 1

* drop individuals who still lack information on whether they work in stem or not
drop if mi(stem)


* save dataset
compress
save ${data}extension, replace

}



* parental info
{

* info on mothers
{

use ${data}extension, clear
keep if female == 1

* check if mother ever worked in stem
egen stem_ever = max(stem), by(pid)
drop stem

label define stem_ever 0 "[0] Never had a STEM Profession", modify
label define stem_ever 1 "[1] Has or had a STEM Profession", modify

label values stem_ever stem_ever


duplicates drop pid, force

rename pid mnr
rename warsaw_pact mother_warsaw_pact
rename stem_ever mother_stem_ever
rename corigin mother_corigin
keep mnr mother_warsaw_pact mother_stem_ever mother_corigin

label variable mother_warsaw_pact "Mother: Former Warsaw Pact State"
label variable mother_stem_ever "Mother: Ever STEM Profession"

merge 1:m mnr using ${v38}bioparen, keep(2 3) nogen
 
save ${data}extension_parents, replace

}



* info on fathers
{

use ${data}extension, clear
keep if female == 0

* check if father ever worked in stem
egen stem_ever = max(stem), by(pid)
drop stem

duplicates drop pid, force

rename pid fnr
rename warsaw_pact father_warsaw_pact
rename stem_ever father_stem_ever
rename corigin father_corigin
keep fnr father_warsaw_pact father_stem_ever father_corigin

label variable father_warsaw_pact "Father: Former Warsaw Pact State"
label variable father_stem_ever "Father: Ever STEM Profession"


merge 1:m fnr using ${data}extension_parents, keep(2 3) nogen
 
save ${data}extension_parents, replace

}


* drop cases with missing information
drop if fnr < 0 | /// father's id missing
		mnr < 0 | /// mother's id missing
		mi(father_warsaw_pact) | ///
		mi(mother_warsaw_pact) | ///
		mi(father_stem_ever) | ///
		mi(mother_stem_ever)


* save dataset
compress
save ${data}extension_parents, replace

}



* children
{

* get ppathl info for children
use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)


* 6 years old or younger at the year of reunification
keep if gebjahr >= 1984


merge m:1 pid using ${data}extension_parents, keep(3) nogen


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


* drop people born outside of germany
drop if germborn == 2

* generate age
gen age = syear - gebjahr
gen age_squared = age^2

label variable age "Age"
label variable age_squared "Age (squared)"


* number of siblings
gen num_sib = numb + nums if numb >= 0 & nums >= 0
label variable num_sib "Number of Siblings"


* indirect migration background
recode migback (1 = 0) (3 = 1)

label variable migback "Indirect Migration Background"

label define migback_bin 0 "[0] No Migration Background", modify
label define migback_bin 1 "[1] Indirect Migration Background", modify

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
save ${data}extension_children, replace

}


* run model (baseline--6)
{

* interaction (female x mother is from former warsaw pact state)
gen female_mother_warsaw_pact = female * mother_warsaw_pact
label variable female_mother_warsaw_pact "Female $\times$ Mother: Former Warsaw Pact State"


* restricted model (baseline--6)
{

* define independent variables
local baseline = "female mother_warsaw_pact female_mother_warsaw_pact father_warsaw_pact mother_stem_ever father_stem_ever"
local person   = "`baseline' age age_squared migback"
local state    = "`person' bula_*"

estimates clear

* run model
foreach ind in baseline person state {
	logit stem_edu ``ind'', vce(cluster hid)
	estat ic
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)

* export latex table
esttab using ${tables}extension.tex, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
	booktabs replace

}

}

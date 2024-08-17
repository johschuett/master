** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* see how not distinguishing between maternal and paternal eastern origin and
* stem background affects the results
{

use ${data}potential_mothers, clear

merge 1:m mnr using ${v38}bioparen, keep(2 3) nogen
 
save ${data}parents_robust, replace

use ${data}potential_fathers, clear

merge 1:m fnr using ${data}parents_robust, keep(2 3) nogen

* drop cases with missing information
drop if (fnr < 0 & mnr < 0) | /// both father's and mother's id missing
		(mi(father_east_or) & mi(mother_east_or)) | ///
		(mi(father_ever_stem) & mi(mother_ever_stem))

save ${data}parents_robust, replace

}



* children
{

* get ppathl info for children
use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)


* 6 years old or younger at the year of reunification
keep if gebjahr >= 1984


merge m:1 pid using ${data}parents_robust, keep(3) nogen

* "any parent" variables
gen any_parent_east_or = 0
replace any_parent_east_or = 1 if mother_east_or == 1 | father_east_or == 1

gen any_parent_ever_stem = 0
replace any_parent_ever_stem = 1 if mother_ever_stem == 1 | father_ever_stem == 1

label variable any_parent_east_or "Any Parent: Eastern Origin"
label variable any_parent_ever_stem "Any Parent: Ever STEM Profession"


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


* interaction
gen any_parent_stem_east = any_parent_ever_stem * any_parent_east_or
label variable any_parent_stem_east "Any Parent: Ever STEM Profession $\times$ Any Parent: Eastern Origin"

* save dataset
compress
save ${data}children_robust, replace

}



/*
intensive margin: do their children have a stem or non-stem university degree?
*/
{

* CHILDREN *
use ${data}children_robust, clear

drop if mi(stem_edu)


* did they attain a university degree at some point in time?
egen stem_edu_max = max(stem_edu), by(pid)
drop stem_edu
rename stem_edu_max stem_edu


* state controls
global file = "children"
do ${do}bula_17.do


* summary statistics estimation sample
foreach var in stem_edu age partner_bin hhgr west mother_east_or father_east_or mother_ever_stem father_ever_stem migback {
	di "`var'"
	ttest `var', by(female) reverse
}


forvalues female = 0(1)1 {
	estimates clear
	
	* define independent variables
	local baseline = "any_parent_ever_stem"
	local person   = "`baseline' age age_squared migback"
	local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"
	
	foreach ind in baseline person state {
		logit stem_edu ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	

	* redefine independent variables (with parents east/west)
	local baseline = "any_parent_ever_stem any_parent_east_or any_parent_stem_east"
	local person   = "`baseline' age age_squared migback"
	local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"
	
	
	foreach ind in baseline person state {
		logit stem_edu ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	
	
	* direct output in log
	di "STEM or non-STEM University Degree? Female = `female'"
	esttab, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)
	
	esttab using ${tables}intensive_fem`female'_robust.tex, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
		booktabs replace
}

}

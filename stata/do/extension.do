** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

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


* what university/vocational degree
recode pgfield (36/44 61/69 79 89 104 118 126 128 177 200 213/226 235 277 310 370 = 1) ///
			   (min/0 = .) ///
			   (nonmissing = 0), ///
			   gen(stem_edu_ext)

recode pgtraina (1410/1458 1810/2551 2591/3007 3031/3239 4401/4880 4913/5063 5400/6420 7741/7783 8570/8580 = 1) ///
				(min/0 = .) ///
				(nonmissing = 0), ///
				gen(helpa)

recode pgtrainb (1410/1421 1945/2900 3031/3239 4870 6223/6425 7742 7744 8354 8570/8580 = 1) ///
				(min/0 = .) ///
				(nonmissing = 0), ///
				gen(helpb)

recode pgtrainc (323 1410 2200/3181 6200/6274 6410/6514 7744 8571/8580 = 1) ///
				(min/0 = .) ///
				(nonmissing = 0), ///
				gen(helpc)

replace stem_edu_ext = 1 if helpa == 1 | helpb == 1 | helpc == 1
replace stem_edu_ext = 0 if mi(stem_edu_ext) & (helpa == 0 | helpb == 0 | helpc == 0)
drop help*


label variable stem_edu_ext "STEM (university or vocational) degree"

label define stem_edu_ext 0 "[0] Has a non-STEM (university or vocational) degree", modify
label define stem_edu_ext 1 "[1] Has a STEM (university or vocational) degree", modify

label values stem_edu_ext stem_edu_ext


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
save ${data}children_ext, replace


* interaction
gen mother_stem_east = mother_ever_stem * mother_east_or
label variable mother_stem_east "Mother: Ever STEM Profession $\times$ Mother: Eastern Origin"

gen father_stem_east = father_ever_stem * father_east_or
label variable father_stem_east "Father: Ever STEM Profession $\times$ Father: Eastern Origin"


* save dataset
save ${data}children_ext, replace

}



/*
intensive margin: do their children have a stem or non-stem university/vocational degree?
*/
{

* CHILDREN *
use ${data}children_ext, clear

drop if mi(stem_edu_ext)


* did they attain a university degree at some point in time?
egen stem_edu_ext_max = max(stem_edu_ext), by(pid)
drop stem_edu_ext
rename stem_edu_ext_max stem_edu_ext


* state controls
global file = "children_ext"
do ${do}bula_17.do


* summary statistics estimation sample
foreach var in stem_edu_ext age partner_bin hhgr west mother_east_or father_east_or mother_ever_stem father_ever_stem migback {
	di "`var'"
	ttest `var', by(female) reverse
}


forvalues female = 0(1)1 {
	estimates clear
	
	* define independent variables
	local baseline = "mother_ever_stem father_ever_stem"
	local person   = "`baseline' age age_squared migback"
	local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"
	
	foreach ind in baseline person state {
		logit stem_edu_ext ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	

	* redefine independent variables (with parents east/west)
	local baseline = "mother_ever_stem father_ever_stem mother_east_or father_east_or mother_stem_east father_stem_east"
	local person   = "`baseline' age age_squared migback"
	local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"
	
	
	foreach ind in baseline person state {
		logit stem_edu_ext ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	
	
	* direct output in log
	di "STEM or non-STEM University/Vocational Degree? Female = `female'"
	esttab, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)
	
	esttab using ${tables}intensive_fem`female'_ext.tex, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
		booktabs replace
}

}

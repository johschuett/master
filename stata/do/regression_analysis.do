** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

/*
extensive margin: do their children have a university or vocational degree?
*/
{

* CHILDREN *
use ${data}children, clear

drop if mi(university)


* did they attain a university degree at some point in time?
egen university_max = max(university), by(pid)
drop university
rename university_max university


* add state controls of the point in time when the individual was 17 years old
* (usually the time of deciding whether to study at uni or not)
global file = "children"
do ${do}bula_17.do


* summary statistics estimation sample
foreach var in university age partner_bin hhgr west mother_east_or father_east_or mother_ever_stem father_ever_stem migback {
	di "`var'"
	ttest `var', by(female) reverse
}

* full summary statistics for appendix
local vlist university age partner_bin hhgr west mother_east_or father_east_or mother_ever_stem father_ever_stem migback unemp gdp popdens netcommuting firstsemstud

table (var female) (result), ///
    stat(mean `vlist') ///
	stat(sd `vlist') ///
	stat(min `vlist') ///
	stat(max `vlist') ///
	stat(n `vlist') ///
	name(by) ///
	replace


* reorder the levels of 'foreign' and hide the 'Total' level
collect levelsof female
collect style autolevels female .m `s(levels)', clear
collect style header female[.m], level(hide)

* change the result labels to match the original LaTeX example
collect label levels result sd "Std. Dev." min "Min" max "Max" n "Obs.", modify

* other style changes
collect style cell result[mean sd min max], nformat(%12.2fc)
collect style header female, title(hide)

* review table look
collect preview

* export to LaTeX file
collect export ${tables}appendix_summary_ext.tex, replace


* show that higher age reduces the probability of missing information in stem_edu variable (non-random subsample in 2b.)
gen missing_stem_edu_flag = 0
replace missing_stem_edu_flag = 1 if mi(stem_edu)

logit missing_stem_edu_flag age, vce(cluster hid)
margins, dydx(age)

drop missing_stem_edu_flag


forvalues female = 0(1)1 {
	estimates clear
	
	* define independent variables
	local baseline = "mother_ever_stem father_ever_stem"
	local person   = "`baseline' age age_squared migback"
	local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"
	
	foreach ind in baseline person state {
		logit university ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	

	* redefine independent variables (with parents east/west)
	local baseline = "mother_ever_stem father_ever_stem mother_east_or father_east_or mother_stem_east father_stem_east"
	local person   = "`baseline' age age_squared migback"
	local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"
	
	
	foreach ind in baseline person state {
		logit university ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	
	
	* direct output in log
	di "University or Vocational Degree? Female = `female'"
	esttab, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)
	
	esttab using ${tables}extensive_fem`female'.tex, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
		booktabs replace
}

}



/*
intensive margin: do their children have a stem or non-stem university degree?
*/
{

* CHILDREN *
use ${data}children, clear

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

* full summary statistics for appendix
local vlist stem_edu age partner_bin hhgr west mother_east_or father_east_or mother_ever_stem father_ever_stem migback unemp gdp popdens netcommuting firstsemstud

table (var female) (result), ///
    stat(mean `vlist') ///
	stat(sd `vlist') ///
	stat(min `vlist') ///
	stat(max `vlist') ///
	stat(n `vlist') ///
	name(by) ///
	replace


* reorder the levels of 'foreign' and hide the 'Total' level
collect levelsof female
collect style autolevels female .m `s(levels)', clear
collect style header female[.m], level(hide)

* change the result labels to match the original LaTeX example
collect label levels result sd "Std. Dev." min "Min" max "Max" n "Obs.", modify

* other style changes
collect style cell result[mean sd min max], nformat(%12.2fc)
collect style header female, title(hide)

* review table look
collect preview

* export to LaTeX file
collect export ${tables}appendix_summary_int.tex, replace


forvalues female = 0(1)1 {
	estimates clear
	
	* define independent variables
	local baseline = "mother_ever_stem father_ever_stem"
	local person   = "`baseline' age age_squared migback"
	local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"
	
	foreach ind in baseline person state {
		logit stem_edu ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	

	* redefine independent variables (with parents east/west)
	local baseline = "mother_ever_stem father_ever_stem mother_east_or father_east_or mother_stem_east father_stem_east"
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
	
	esttab using ${tables}intensive_fem`female'.tex, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
		booktabs replace
}

}

** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

/*
1. is there a correlation between parents having an eastern origin and having worked in stem at some point?
*/
{

* MOTHERS *
use ${data}potential_mothers, clear

* keep only individuals who are mothers of the children in the estimation sample
merge 1:m mnr using ${data}children, keepusing(mnr)
keep if _merge == 3
drop _merge


* some are mothers of multiple children -> drop duplicates
sort mnr
duplicates drop mnr, force


* run simple logit model
logit mother_ever_stem mother_east_or
margins, dydx(mother_east_or)
*--> Female focus on STEM can be (partly) explained through the socialisation in the GDR.
**


* FATHERS *
use ${data}potential_fathers, clear

* keep only individuals who are fathers of the children in the estimation sample
merge 1:m fnr using ${data}children, keepusing(fnr)
keep if _merge == 3
drop _merge


* some are fathers of multiple children -> drop duplicates
sort fnr
duplicates drop fnr, force


* run simple logit model
logit father_ever_stem father_east_or
margins, dydx(father_east_or)
**

}


/*
2a. extensive margin: do their children have a university or vocational degree?
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
do ${do}bula_17.do


* define independent variables
local baseline = "mother_ever_stem father_ever_stem"
local person   = "`baseline' age age_squared migback"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"

forvalues female = 0(1)1 {
	estimates clear
	
	foreach ind in baseline person state {
		logit university ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	
	* direct output in log
	di "University or Vocational Degree? Female = `female'"
	esttab, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)
}


* define independent variables
local baseline = "mother_ever_stem father_ever_stem mother_east_or father_east_or mother_stem_east father_stem_east"
local person   = "`baseline' age age_squared migback"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"

forvalues female = 0(1)1 {
	estimates clear
	
	foreach ind in baseline person state {
		logit university ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	
	* direct output in log
	di "University or Vocational Degree (Mother/Father East/West)? Female = `female'"
	esttab, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)
}

}



/*
2b. intensive margin: do their children have a stem or non-stem university degree?
*/
{

* CHILDREN *
use ${data}children, clear

drop if mi(stem_edu)


* did they attain a university degree at some point in time?
egen stem_edu_max = max(stem_edu), by(pid)
drop stem_edu
rename stem_edu_max stem_edu


do ${do}bula_17.do


* define independent variables
local baseline = "mother_ever_stem father_ever_stem"
local person   = "`baseline' age age_squared migback"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"

forvalues female = 0(1)1 {
	estimates clear
	
	foreach ind in baseline person state {
		logit stem_edu ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	
	* direct output in log
	di "Female = `female'"
	esttab, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)
}


* define independent variables
local baseline = "mother_ever_stem father_ever_stem mother_east_or father_east_or mother_stem_east father_stem_east"
local person   = "`baseline' age age_squared migback"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud bula_17_flag"

forvalues female = 0(1)1 {
	estimates clear
	
	foreach ind in baseline person state {
		logit stem_edu ``ind'' if female == `female'
		eststo: margins, dydx(``ind'') post
	}
	
	* direct output in log
	di "Female = `female'"
	esttab, ///
		b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)
}

}

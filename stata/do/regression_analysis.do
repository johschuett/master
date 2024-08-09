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


* get the year of the first observation of each individual
egen syear_min = min(syear), by(pid)

gen bula_min = bula if syear == syear_min
label variable bula_min "Federal State of Residency in earliest Survey Year"
xfill bula_min, i(pid)


gsort pid -syear

duplicates drop pid, force


* survey year when they were 17 years old (usually the time of deciding whether to study at uni or not)
gen syear_17 = syear - age + 17

drop syear
rename syear_17 syear

rename bula bula_now

merge 1:1 pid syear using ${data}children, keep(1 3) keepusing(bula) nogen

rename bula bula_17
label variable bula_17 "Federal State of Residency when 17 years old"

rename bula_now bula

tab bula bula_17, mi


* fill missing information with bula of mothers when the children were 17 years old
rename pid cnr
rename mnr pid
rename bula cbula

merge m:1 pid syear using ${data}female_stem, keep(1 3) keepusing(bula) nogen

rename bula mbula_17
rename cbula bula
rename pid mnr
rename cnr pid

replace bula_17 = mbula_17 if mi(bula_17)


* fill missing information with bula of fathers when the children were 17 years old
rename pid cnr
rename fnr pid
rename bula cbula

merge m:1 pid syear using ${data}female_stem, keep(1 3) keepusing(bula) nogen

rename bula fbula_17
rename cbula bula
rename pid fnr
rename cnr pid

replace bula_17 = fbula_17 if mi(bula_17)


* see for how many children with non-missing information, bula_min = bula_17
gen bula_help = 0
replace bula_help = 1 if bula_min == bula_17
replace bula_help = . if mi(bula_17)

tab bula_help

drop bula_help


* assume for the remaining missing observations that bula_min = bula_17 and create
* imputation flag
gen bula_17_flag = 0
replace bula_17_flag = 1 if mi(bula_17)

replace bula_17 = bula_min if mi(bula_17)

label variable bula_17_flag "Imputed Value: Federal State assumed to be the same"


drop bula
rename bula_17 bula

drop unemp gdp popdens netcommuting firstsemstud

merge m:1 bula syear using ${data}state, keep(3) nogen


* define independent variables
local baseline = "mother_ever_stem father_ever_stem"
local person   = "`baseline' age age_squared migback"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud"

forvalues female = 0(1)1 {
	di "Female = `female'"
	foreach stage in baseline person state {
		logit university ``stage'' if female == `female'
		margins, dydx(``stage'')
	}
}

}

** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

/*
NOTES:
----------

results in the thesis should be presented as follows:

1. show and discuss results from baseline--6
2. first robustness: compare baseline--6 to baseline--8 and baseline--4
3. second robustness: compare baseline--6 to baseline--6 with additional controls
----------
*/

use ${data}children, clear


* interactions (female x mother is from east germany)
gen female_mother_east_or = female * mother_east_or
label variable female_mother_east_or "Female $\times$ Mother: Eastern Origin"

gen female_mother_ever_stem = female * mother_ever_stem
label variable female_mother_ever_stem "Female $\times$ Mother: Ever STEM Profession"

gen female_mother_east_stem = female * mother_east_or * mother_ever_stem
label variable female_mother_east_stem "Female $\times$ Mother: Eastern Origin $\times$ Mother: Ever STEM Profession"


* drop all matrices
mat drop _all


* save dataset
compress
save ${data}children_interactions, replace



* unrestricted model (baseline--8)
{

use ${data}children_interactions, clear

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_ever_stem father_ever_stem female_mother_ever_stem female_mother_east_stem"
local person   = "`baseline' age age_squared migback"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud"

estimates clear

* run model
local stage = 0
foreach ind in baseline person state {
	local stage = `stage' + 1
	
	logit stem_edu ``ind'', vce(cluster hid)
	
	* save information criteria
	estat ic
	
	local aic = r(S)[1,5]
	local bic = r(S)[1,6]
	
	mat input `ind'_8 = (8 `stage' `aic' `bic')
	
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)

* export latex table
esttab using ${tables}baseline--8.tex, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
	booktabs replace

}



* restricted model (baseline--6)
{

use ${data}children_interactions, clear

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_ever_stem father_ever_stem"
local person   = "`baseline' age age_squared migback"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud"

estimates clear

* run model
local stage = 0
foreach ind in baseline person state {
	local stage = `stage' + 1
	
	logit stem_edu ``ind'', vce(cluster hid)
	
	* save information criteria
	estat ic
	
	local aic = r(S)[1,5]
	local bic = r(S)[1,6]
	
	mat input `ind'_6 = (6 `stage' `aic' `bic')
	
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)

* export latex table
esttab using ${tables}baseline--6.tex, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
	booktabs replace

}



* restricted model (baseline--4)
{

use ${data}children_interactions, clear

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or"
local person   = "`baseline' age age_squared migback"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud"

estimates clear

* run model
local stage = 0
foreach ind in baseline person state {
	local stage = `stage' + 1
	
	logit stem_edu ``ind'', vce(cluster hid)
	
	* save information criteria
	estat ic
	
	local aic = r(S)[1,5]
	local bic = r(S)[1,6]
	
	mat input `ind'_4 = (4 `stage' `aic' `bic')
	
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N)

* export latex table
esttab using ${tables}baseline--4.tex, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
	booktabs replace

}



* information criteria graph
{


* create empty dataset for information criteria data on all three models
clear

gen model = .
gen stage = .
gen aic   = .
gen bic   = .

save ${data}information, replace

clear

mat dir

* retrieve aic's & bic's from matrices and save them in one dataset
foreach i in 8 6 4 {
	foreach m in baseline person state {
		svmat `m'_`i'
		
		rename `m'_`i'1 model
		rename `m'_`i'2 stage
		rename `m'_`i'3 aic
		rename `m'_`i'4 bic
		
		append using ${data}information
		save ${data}information, replace
		
		clear
	}
}

use ${data}information
gsort -model stage

label variable aic "AIC"
label variable bic "BIC"

local t1 = "Baseline"
local t2 = "Baseline + Person"
local t3 = "Baseline + Person + State"

forvalues i = 1(1)3 {
	twoway (line aic model if stage == `i', lpattern(solid)) ///
		   (line bic model if stage == `i', lpattern(dash)), ///
		   aspectratio(0.3) ///
		   xlab(4(2)8) ///
		   ylab(3080(40)3240, format(%12.0fc) nogrid) ///
		   xtitle("") ///
		   subtitle("`t`i''") ///
		   legend(order(2 1) size(small)) ///
		   name(info_`i', replace)
}

grc1leg info_1 info_2 info_3, ///
	cols(1) ///
	name(information, replace)

graph export ${figures}information.pdf, replace

}



* restricted model (baseline--6) with number of siblings and parental household income
{

use ${data}children_interactions, clear


* drop observations with missing information on additional controls
drop if mi(num_sib) | mi(parental_hhincome)

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_ever_stem father_ever_stem"
local person   = "`baseline' age age_squared migback num_sib parental_hhincome"
local state    = "`person' unemp gdp popdens netcommuting firstsemstud"

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
esttab using ${tables}baseline--6-add_control.tex, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(rank N) ///
	booktabs replace

}

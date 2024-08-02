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

gen female_mother_stem_ever = female * mother_stem_ever
label variable female_mother_stem_ever "Female $\times$ Mother: Ever STEM Profession"

gen female_mother_east_stem = female * mother_east_or * mother_stem_ever
label variable female_mother_east_stem "Female $\times$ Mother: Eastern Origin $\times$ Mother: Ever STEM Profession"


* drop all matrices
mat drop _all


* save dataset
compress
save ${data}children_interactions, replace



* unrestricted model (baseline--8)
{

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_stem_ever female_mother_stem_ever female_mother_east_stem father_stem_ever"
local person   = "`baseline' age age_squared migback"
local state    = "`person' bula_*"

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
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(aic bic rank N)

}



* restricted model (baseline--6)
{

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_stem_ever father_stem_ever"
local person   = "`baseline' age age_squared migback"
local state    = "`person' bula_*"

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
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(aic bic rank N)


}



* restricted model (baseline--4)
{

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or"
local person   = "`baseline' age age_squared migback"
local state    = "`person' bula_*"

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
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(aic bic rank N)

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

twoway (line aic model if stage == 1, lpattern(solid)) ///
	   (line bic model if stage == 1, lpattern(dash)), ///
	   aspectratio(0.3) ///
	   xlab(4(2)8) ///
	   ylab(3120(40)3240, format(%12.0fc) nogrid) ///
	   xtitle("") ///
	   subtitle("Baseline") ///
	   legend(order(2 1) size(small)) ///
	   name(info_1, replace)

twoway (line aic model if stage == 2, lpattern(solid)) ///
	   (line bic model if stage == 2, lpattern(dash)), ///
	   aspectratio(0.3) ///
	   xlab(4(2)8) ///
	   ylab(3120(40)3240, format(%12.0fc) nogrid) ///
	   xtitle("") ///
	   subtitle("Baseline + Person") ///
	   legend(order(2 1) size(small)) ///
	   name(info_2, replace)

twoway (line aic model if stage == 3, lpattern(solid)) ///
	   (line bic model if stage == 3, lpattern(dash)), ///
	   aspectratio(0.3) ///
	   xlab(4(2)8) ///
	   ylab(3040(80)3280, format(%12.0fc) nogrid) ///
	   ymtick(3040(40)3280) ///
	   xtitle("") ///
	   subtitle("Baseline + Person + State") ///
	   legend(order(2 1) size(small)) ///
	   name(info_3, replace)

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
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_stem_ever father_stem_ever"
local person   = "`baseline' age age_squared migback num_sib parental_hhincome"
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
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(aic bic rank N)


* -> residing in saarland predicts failure perfectly

}

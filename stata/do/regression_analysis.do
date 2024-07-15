** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${data}children, clear


* interaction (female x mother is from east germany)
gen female_mother_east_or = female * mother_east_or
label variable female_mother_east_or "Female $\times$ Mother: Eastern Origin"


* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_stem_ever father_stem_ever"
local controls = "`baseline' age age_squared"

estimates clear

* run model
foreach ind in baseline controls {
	logit stem_edu ``ind'', vce(cluster hid)
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle star(* 0.10 ** 0.05 *** 0.01)

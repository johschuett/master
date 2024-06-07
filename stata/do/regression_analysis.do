use ${data}female_stem, clear

* keep east germans only
keep if east_origin == 1 & inrange(syear, 1990, 1996)
drop east_origin

estimates clear

local baseline = "dist_reunification female dist_reunification_female"
local west     = "`baseline' west west_female"
local phh      = "`west'"
local states   = "`phh'"

* run model
foreach ind in baseline west phh states {
	logit stem ``ind'', vce(cluster hid)
	eststo: margins, dydx(``ind'') post
}

esttab using ${tables}margins.tex, b(4) se(4) label nomtitle star(* 0.10 ** 0.05 *** 0.01) booktabs replace

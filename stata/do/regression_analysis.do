use ${data}female_stem, clear

* keep east germans only
keep if east_origin == 1 & inrange(syear, 1990, 1996)
drop east_origin

estimates clear

local baseline = "dist_reunification female dist_reunification_female"
local west     = "`baseline' west west_female"
local hhp      = "`west' partner_bin partner_bin_female hhgr hhgr_female age age_2"
local states   = "`hhp'"

* run model
foreach ind in baseline west hhp states {
	logit stem ``ind'', vce(cluster hid)
	eststo: margins, dydx(``ind'') post
}

esttab using ${tables}margins.tex, ///
	keep(dist_reunification female dist_reunification_female west west_female ///
		 partner_bin partner_bin_female hhgr hhgr_female) ///
	b(4) se(4) label nomtitle star(* 0.10 ** 0.05 *** 0.01) booktabs replace

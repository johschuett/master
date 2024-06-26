** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${data}female_stem, clear

* keep east germans only
keep if east_origin == 1 & inrange(syear, 1990, 1999)
drop east_origin


* outcome variable is heavily skewed towards failure -> cloglog
tab stem [aw = phrf]


/* data for 1997-1999 missing
* state controls
do ${do}state_controls.do

use ${data}female_stem, clear
merge m:1 bula syear using ${data}state, keep(3) nogen

gen unemprate_female = unemprate * female
label variable unemprate_female "Unemployment Rate $\times$ Female"

gen share_female_unemp = unemp_female / (unemp_female + unemp_male)
label variable share_female_unemp "Share of Unemployed Females in all Unemployed (\emph{Bundesland})"
*/


estimates clear

local baseline = "dist_reunification female dist_reunification_female"
local west     = "`baseline' west west_female"
local hhp      = "`west' partner_bin partner_bin_female hhgr hhgr_female age age_2"
local states   = "`hhp' kr_emprate kr_popdens chemiedreieck chemiedreieck_female"

* run model
foreach ind in baseline west hhp states {
	cloglog stem ``ind'' [pw = phrf], vce(cluster hid)
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	keep(dist_reunification female dist_reunification_female west west_female ///
		 partner_bin partner_bin_female hhgr hhgr_female chemiedreieck chemiedreieck_female) ///
	b(4) se(4) label nomtitle star(* 0.10 ** 0.05 *** 0.01)


* latex export
esttab using ${tables}margins.tex, ///
	keep(dist_reunification female dist_reunification_female west west_female ///
		 partner_bin partner_bin_female hhgr hhgr_female chemiedreieck chemiedreieck_female) ///
	b(4) se(4) label nomtitle star(* 0.10 ** 0.05 *** 0.01) booktabs replace

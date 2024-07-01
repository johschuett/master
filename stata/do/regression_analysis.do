** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${data}female_stem, clear

* keep east germans only
keep if east_origin == 1 & inrange(syear, 1990, 1999)
drop east_origin


* outcome variable is heavily skewed towards failure -> cloglog
tab stem [aw = phrf]


estimates clear


* define controls
local baseline = "female d19* female_d19*"
local west     = "`baseline' west west_female"
local hhp      = "`west' age age_2 partner_bin partner_bin_female hhgr hhgr_female"
local states   = "`hhp' kr_emprate kr_popdens chemiedreieck chemiedreieck_female"


* run model
foreach ind in baseline west hhp states {
	cloglog stem ``ind'' [pw = phrf], vce(cluster hid)
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	keep(d19* female_d19* female west west_female partner_bin partner_bin_female ///
		 hhgr hhgr_female chemiedreieck chemiedreieck_female) ///
	b(4) se(4) label nomtitle star(* 0.10 ** 0.05 *** 0.01)


* latex export
esttab using ${tables}margins.tex, ///
	keep(d19* female_d19* female west west_female partner_bin partner_bin_female ///
		 hhgr hhgr_female chemiedreieck chemiedreieck_female) ///
	b(4) se(4) label nomtitle star(* 0.10 ** 0.05 *** 0.01) booktabs replace


* plot interaction dummies
coefplot (est1, label(Baseline) msymbol(Oh)) ///
		 (est2, label(Residence in West Germany) msymbol(Dh)) ///
		 (est3, label(Person and Household Controls) msymbol(O)) ///
		 (est4, label(Region Controls) msymbol(D)), ///
	yline(0, lcolor(gs6) lpattern(dash)) ///
	ylabel(, nogrid format(%03.2f)) ///
	xlabel(1 "1991" 2 "1992" 3 "1993" 4 "1994" 5 "1995" ///
		   6 "1996" 7 "1997" 8 "1998" 9 "1999") ///
	vertical ///
	legend(cols(2)) ///
	keep(female_d19*) ///
	name(coefficient_trend, replace)

graph export "${figures}coefficient_trend.pdf", replace

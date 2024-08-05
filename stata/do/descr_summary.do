** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* summary statistics for 1990's inidividuals
use ${data}female_stem, clear


* keep working-age employed population only
keep if inrange(age, 17, 65)
keep if inrange(pgemplst, 1, 2)
keep if syear == 1990


forvalues east = 0(1)1 {
	preserve
	
	di "east = `east'"
	
	keep if east_origin == `east'
	
	foreach var in stem age partner_bin hhgr west {
		di "`var'"
		ttest `var', by(female) reverse
	}
		
	restore
}

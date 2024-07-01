** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${data}female_stem, clear


* keep east german females only
keep if east_origin == 1 & inrange(syear, 1990, 1999) & female == 1
drop east_origin


* number of individuals in 1990 for notes
egen sumpid = count(pid) if syear == 1990
sum sumpid
local sumpid = r(mean)
drop sumpid

egen sumstem = count(pid) if syear == 1990 & stem == 1
sum sumstem
local sumstem = r(mean)
drop sumstem

local fmt_sumpid : di %5.0fc `sumpid'


* individuals switches from being occupied in stem to not being occupied in stem
* individuals switching the other way around get accounted as -1 to get net switches
gen stem_switch = 0
bysort pid (syear): replace stem_switch = 1 if stem == 0 & stem[_n-1] == 1
bysort pid (syear): replace stem_switch = -1 if stem == 1 & stem[_n-1] == 0


* individuals switches from being employed (either full- or part-time) to not being employed
* individuals switching the other way around get accounted as -1 to get net switches
gen unemp_switch = 0
bysort pid (syear): replace unemp_switch = 1 if inrange(pgemplst, 3, 6) & (pgemplst[_n-1] == 1 | pgemplst[_n-1] == 2)
bysort pid (syear): replace unemp_switch = -1 if (pgemplst == 1 | pgemplst == 2) & inrange(pgemplst[_n-1], 3, 6)


* individuals switches from being occupied in stem to not being employed
* individuals switching the other way around get accounted as -1 to get net switches
gen stem_unemp_switch = 0
bysort pid (syear): replace stem_unemp_switch = 1 if inrange(pgemplst, 3, 6) & (pgemplst[_n-1] == 1 | pgemplst[_n-1] == 2) & stem[_n-1] == 1
bysort pid (syear): replace stem_unemp_switch = -1 if (pgemplst == 1 | pgemplst == 2) & stem == 1 & inrange(pgemplst[_n-1], 3, 6)


collapse (sum) stem_switch unemp_switch stem_unemp_switch (count) pid [aw = phrf], by(syear)

twoway (line unemp_switch syear, lcolor(gs8) lpattern(solid)) ///
||     (connected stem_unemp_switch syear [w = pid], lcolor(gs4) mcolor(gs4) msymb(oh) lpattern(solid)) ///
||     (line stem_switch syear, lcolor(black) lpattern(solid)), ///
	xtitle("Survey Year") ///
	ytitle("Net Switches") ///
	ylab(, nogrid) ///
	xlab(, nogrid) ///
	legend(label(1 "STEM to Unemployment") ///
	       label(2 "Employment (Full- or Part-Time) to Unemployment") ///
		   label(3 "STEM to non-STEM") ///
		   order(3 2 1) ///
		   position(6)) ///
	note("N = `fmt_sumpid', thereof `sumstem' in STEM.") ///
	name(eastern_female_tracking, replace)

graph export "${figures}eastern_female_tracking.pdf", replace


* survival plot
* get eastern female stem professionals of 1990 and see how they develop
use ${data}female_stem, clear
keep if syear == 1990 & stem == 1 & east_origin == 1 & female == 1
keep pid


merge 1:m pid using ${data}female_stem, keep(3) nogen
keep if inrange(syear, 1990, 1999)

* create status variable [1] stem [2] working in non-stem [3] non-working [4] punr
gen status = .
replace status = 1 if stem == 1
replace status = 2 if stem == 0 & inlist(pgemplst, 1, 2)
replace status = 3 if stem == 0 & !inlist(pgemplst, 1, 2)


label variable status "Work Status"
label define status 1 "Working in STEM", modify
label define status 2 "Working in Non-STEM", modify
label define status 3 "Non-Working", modify
label define status 4 "Partial Unit-Nonresponse", modify

label values status status


save ${data}survival, replace


* count punr's
collapse (sum) stem (count) pid, by(syear)
gen punr = pid[1] - pid
save ${data}punr, replace

* get punr's into the status variable
forvalues year = 1(1)10 {
	
	use ${data}punr, clear
	local punr = punr[`year']
	
	
	use ${data}survival, clear
	local oldobs = _N + 1
	local newobs = _N + `punr'
	set obs `newobs'
	
	if `oldobs' < `newobs' {
		replace syear = 1989 + `year' in `oldobs'/`newobs'
		replace status = 4 in `oldobs'/`newobs'
	}
	
	save ${data}survival, replace
}

set scheme s2color

graph bar, ///
	over(status) ///
	over(syear) ///
	stack asyvars ///
	percentage ///
	ylab(, nogrid) ///
	ytitle("Percent") ///
	graphregion(color(white)) ///
	name(survival, replace)

graph export ${figures}survival.pdf, replace

* reset scheme
set scheme tufte

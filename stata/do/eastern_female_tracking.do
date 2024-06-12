** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${data}female_stem, clear


* keep east german females only
keep if east_origin == 1 & inrange(syear, 1990, 1996) & female == 1
drop east_origin


* most of the east german females had their first interview in 1990
tab erstbefr


* only look at the individuals who had their first interview in 1990
keep if erstbefr == 1990


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
gen switch = 0
bysort pid (syear): replace switch = 1 if stem == 0 & stem[_n-1] == 1
bysort pid (syear): replace switch = -1 if stem == 1 & stem[_n-1] == 0

collapse (sum) switch pid, by(syear)

graph twoway connected switch syear [w = pid], ///
	xtitle("Year") ///
	ytitle("Net Switches from STEM to non-STEM") ///
	ylab(, nogrid) ///
	text(2.5 1990.2 "N = `fmt_sumpid'" 1.1 1990.2 "thereof `sumstem' in STEM", size(vsmall) placement(ne)) ///
	name(eastern_female_tracking, replace)

graph export "${figures}eastern_female_tracking.pdf", replace

** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${data}female_stem, clear

collapse (mean) stem (count) pid [aw = phrf], by(syear east_origin female)

* infos on bin sizes for notes
sum pid
local size_mean = round(r(mean))
local size_sd   = round(r(sd))

local fmt_size_mean : di %5.0fc `size_mean'
local fmt_size_sd   : di %5.0fc `size_sd'


sum pid if female == 1 & inrange(syear, 1990, 1996)
local size_mean_female = round(r(mean))
local size_sd_female   = round(r(sd))

local fmt_size_mean_female : di %5.0fc `size_mean_female'
local fmt_size_sd_female   : di %3.0fc `size_sd_female'


* probability to be in stem cond. on population
twoway (connected stem syear if female == 0 & east_origin == 1, mcolor(gs6) lcolor(gs6) msymbol(O) lpattern(solid)) ///
||     (connected stem syear if female == 0 & east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Oh) lpattern(dash)) ///
||     (connected stem syear if female == 1 & east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Sh) lpattern(dash)) ///
||     (connected stem syear if female == 1 & east_origin == 1, mcolor(black) lcolor(black) msymbol(S) lpattern(solid)), ///
xline(1990, lcolor(gray) lpattern(dash)) ///
xtitle("Survey Year") ///
ytitle("Probability STEM Profession cond. on Population") ///
ylabel(0.05(0.05)0.2, format(%03.2f)) ///
legend(label(1 "East Origin, Male") ///
       label(2 "West Origin, Male") ///
	   label(3 "West Origin, Female") ///
	   label(4 "East Origin, Female") ///
	   order(4 3 1 2)) ///
note("Avg. Bin Size (Std. Dev.): `fmt_size_mean' (`fmt_size_sd')") ///
name(trend, replace)

graph export "${figures}trend.pdf", replace


* trend, zoomed
use ${data}female_stem, clear

keep if inrange(syear, 1990, 1999) & female == 1

statsby stem=r(mean) lb=r(lb) ub=r(ub) [aw = phrf], by(syear east_origin female) clear: ci means stem


* probability to be in stem cond. on population (females only, 1990, 1999)
twoway (connected stem syear if east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Sh) lpattern(dash)) ///
||     (connected stem syear if east_origin == 1, mcolor(black) lcolor(black) msymbol(S) lpattern(solid)) ///
||     (rcap lb ub syear if east_origin == 0, lcolor(gs6)) ///
||     (rcap lb ub syear if east_origin == 1, lcolor(black)), ///
xtitle("Survey Year") ///
ytitle("Prob. STEM Profession cond. on Population") ///
ylabel(0.05(0.05)0.2, format(%03.2f) nogrid) ///
legend(label(1 "West Origin, Female") ///
	   label(2 "East Origin, Female") ///
	   order(2 1)) ///
note("Avg. Bin Size (Std. Dev.): `fmt_size_mean_female' (`fmt_size_sd_female')") ///
name(trend_zoomed, replace)

graph export "${figures}trend_zoomed.pdf", replace

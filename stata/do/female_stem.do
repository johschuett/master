***************************************** PREAMBLE *****************************************
*-> SET LOCAL ROOT HERE
global root     = "H:/master_thesis/stata/"

version 17

clear all
set more off
set maxvar 7000

ssc install tufte
set scheme tufte

* soep v38.1
global v38      = "//hume/rdc-prod/distribution/soep-core/soep.v38.1/eu/Stata_DE/soepdata/"

global data     = "${root}data/"
global do       = "${root}do/"
global log      = "${root}log/"
global figures  = "${root}figures/"
*************************************** END PREAMBLE ***************************************




* data preparation
{

use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)

* generate female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)


merge m:1 hid syear using ${v38}regionl, keep(3) nogen

* mark western länder
gen west = 0
replace west = 1 if inrange(bula, 1, 10)

* mark eastern origin
recode loc1989 (1 = 1) (2 = 0) (nonmissing = .), gen(east_origin)
drop if mi(east_origin)


merge 1:1 pid syear using ${v38}pl, keep(3) keepusing(p_isco88) nogen

gen stem = 0
replace stem = . if p_isco88 < 0
replace stem = 1 if p_isco88 == 1236
replace stem = 1 if inrange(p_isco88, 2111, 2213)
replace stem = 1 if inrange(p_isco88, 3111, 3212)
drop if mi(stem)

label variable stem "STEM-profession"
label define stem 0 "[0] Does not have a STEM-profession", modify
label define stem 1 "[1] Has a STEM-profession", modify

label values stem stem


merge 1:1 pid syear using ${v38}pgen, keep(1 3) keepusing(pgemplst) nogen

recode pgemplst (2 = 1) (1 3 4 5 6 = 0), gen(part_time)
recode pgemplst (3 = 1) (1 2 4 5 6 = 0), gen(in_training)
recode pgemplst (4 = 1) (1 2 3 5 6 = 0), gen(irregular_emp)
recode pgemplst (5 6 = 1) (1 2 3 4 = 0), gen(emp_other)


* generate interactions
gen east_origin_female   = east_origin * female
gen west_female          = west * female
gen part_time_female     = part_time * female
gen irregular_emp_female = irregular_emp * female

gen age = syear - gebjahr
gen age_2 = age^2


save ${data}female_stem, replace
}




* graphical analysis
{

* trend
use ${data}female_stem, clear

collapse (mean) stem (count) pid, by(syear east_origin female)

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

twoway (connected stem syear if female == 0 & east_origin == 1, mcolor(gs6) lcolor(gs6) msymbol(O) lpattern(solid)) ///
||     (connected stem syear if female == 0 & east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Oh) lpattern(dash)) ///
||     (connected stem syear if female == 1 & east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Sh) lpattern(dash)) ///
||     (connected stem syear if female == 1 & east_origin == 1, mcolor(black) lcolor(black) msymbol(S) lpattern(solid)), ///
xline(1990, lcolor(gray) lpattern(dash)) ///
xtitle("Year") ///
ytitle("Avg. Prob. STEM Profession") ///
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

keep if inrange(syear, 1990, 1996)

statsby stem=r(mean) lb=r(lb) ub=r(ub), by(syear east_origin female) clear: ci means stem

twoway (connected stem syear if female == 1 & east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Sh) lpattern(dash)) ///
||     (connected stem syear if female == 1 & east_origin == 1, mcolor(black) lcolor(black) msymbol(S) lpattern(solid)) ///
||     (rcap lb ub syear if female == 1 & east_origin == 0, lcolor(gs6)) ///
||     (rcap lb ub syear if female == 1 & east_origin == 1, lcolor(black)), ///
xtitle("Year") ///
ytitle("Avg. Prob. STEM Profession") ///
ylabel(0.05(0.05)0.2, format(%03.2f) nogrid) ///
legend(label(1 "West Origin, Female") ///
	   label(2 "East Origin, Female") ///
	   order(2 1)) ///
note("Avg. Bin Size (Std. Dev.): `fmt_size_mean_female' (`fmt_size_sd_female')") ///
name(trend_zoomed, replace)

graph export "${figures}trend_zoomed.pdf", replace

}




* regression analysis
{

use ${data}female_stem, clear

gen dist_reunification = syear - 1990
gen dist_reunification_female = dist_reunification * female

local baseline = "dist_reunification female dist_reunification_female"

* baseline
foreach com in reg logit probit {
    `com' stem `baseline' if east_origin == 1 & inrange(syear, 1990, 1996), vce(cluster hid)
}

* control for living in the west
foreach com in reg logit probit {
    `com' stem `baseline' west west_female if east_origin == 1 & inrange(syear, 1990, 1996), vce(cluster hid)
}

* also control for person and household characteristica
foreach com in reg logit probit {
   `com' stem `baseline' west west_female if east_origin == 1 & inrange(syear, 1990, 1996), vce(cluster hid) 
}

* also control for länder characteristica
foreach com in reg logit probit {
   `com' stem `baseline' west west_female if east_origin == 1 & inrange(syear, 1990, 1996), vce(cluster hid) 
}

}

** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* general time trend plot cond. on working
{
use ${data}female_stem, clear


* keep employed working working age population only
keep if inrange(age, 17, 65)
keep if inrange(pgemplst, 1, 2)


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

local fmt_size_mean_female : di %3.0fc `size_mean_female'
local fmt_size_sd_female   : di %3.0fc `size_sd_female'


* share of stem professionals within demographic groups (1990-1999)
twoway (connected stem syear if female == 0 & east_origin == 1, mcolor(gs6) lcolor(gs6) msymbol(O) lpattern(solid)) ///
||     (connected stem syear if female == 0 & east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Oh) lpattern(dash)) ///
||     (connected stem syear if female == 1 & east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Sh) lpattern(dash)) ///
||     (connected stem syear if female == 1 & east_origin == 1, mcolor(black) lcolor(black) msymbol(S) lpattern(solid)), ///
	xline(1990, lcolor(gray) lpattern(dash)) ///
	xtitle("Survey Year") ///
	ytitle("Share of STEM Professionals within Bin") ///
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


* keep employed working working age population only
keep if inrange(age, 17, 65)
keep if inrange(pgemplst, 1, 2)

keep if inrange(syear, 1990, 1999) & female == 1

statsby stem=r(mean) lb=r(lb) ub=r(ub) [aw = phrf], by(syear east_origin female) clear: ci means stem


* share of stem professionals within demographic groups (females only, 1990-1999)
twoway (connected stem syear if east_origin == 0, mcolor(gs6) lcolor(gs6) msymbol(Sh) lpattern(dash)) ///
||     (connected stem syear if east_origin == 1, mcolor(black) lcolor(black) msymbol(S) lpattern(solid)) ///
||     (rcap lb ub syear if east_origin == 0, lcolor(gs6)) ///
||     (rcap lb ub syear if east_origin == 1, lcolor(black)), ///
	xtitle("Survey Year") ///
	ytitle("Share of STEM Professionals within Bin") ///
	ylabel(0.05(0.05)0.2, format(%03.2f) nogrid) ///
	legend(label(1 "West Origin, Female") ///
		   label(2 "East Origin, Female") ///
		   order(2 1)) ///
	note("Avg. Bin Size (Std. Dev.): `fmt_size_mean_female' (`fmt_size_sd_female')") ///
	name(trend_zoomed, replace)

graph export "${figures}trend_zoomed.pdf", replace

}


* survival plot
{

* get eastern female stem professionals of 1990 and see how they develop
set scheme s2color

forvalues female = 0(1)1 {
    
	use ${data}female_stem, clear
	keep if syear == 1990 & stem == 1 & east_origin == 1 & female == `female'
	keep pid


	merge 1:m pid using ${data}female_stem, keep(3) nogen
	keep if inrange(syear, 1990, 1999)

	* create status variable [1] stem [2] working in non-stem [3] irregular employment/non-working [4] punr
	gen status = .
	replace status = 1 if stem == 1
	replace status = 2 if stem == 0 & inlist(pgemplst, 1, 2)
	replace status = 3 if stem == 0 & !inlist(pgemplst, 1, 2)


	label variable status "Work Status"
	label define status 1 "Working in STEM", modify
	label define status 2 "Working in Non-STEM", modify
	label define status 3 "No Regular Employment", modify
	label define status 4 "(Partial) Unit-Nonresponse", modify

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


	if `female' == 0 {
	    graph bar, ///
			over(status) ///
			over(syear) ///
			stack asyvars ///
			percentage ///
			ylab(, nogrid) ///
			ytitle("Percent") ///
			graphregion(color(white)) ///
			name(survival_male, replace)

		graph export ${figures}survival_male.pdf, replace
	}
	else {
	    graph bar, ///
			over(status) ///
			over(syear) ///
			stack asyvars ///
			percentage ///
			ylab(, nogrid) ///
			ytitle("Percent") ///
			graphregion(color(white)) ///
			name(survival_female, replace)

		graph export ${figures}survival_female.pdf, replace
	}
}

}



* net switches plot
{

* reset scheme
set scheme tufte

* reload data
use ${data}female_stem, clear


* keep working age population only
keep if inrange(age, 17, 65)


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


* individuals switch from being occupied in stem to not being occupied in stem
* individuals switching the other way around get accounted as -1 to get net switches
gen stem_switch = 0
bysort pid (syear): replace stem_switch = 1 if stem == 0 & stem[_n-1] == 1
bysort pid (syear): replace stem_switch = -1 if stem == 1 & stem[_n-1] == 0


* individuals switch from being employed (either full- or part-time) to not being employed
* individuals switching the other way around get accounted as -1 to get net switches
gen unemp_switch = 0
bysort pid (syear): replace unemp_switch = 1 if inrange(pgemplst, 3, 6) & inrange(pgemplst[_n-1], 1, 2)
bysort pid (syear): replace unemp_switch = -1 if inrange(pgemplst, 1, 2) & inrange(pgemplst[_n-1], 3, 6)


* individuals switch from being occupied in stem to not being employed
* individuals switching the other way around get accounted as -1 to get net switches
gen stem_unemp_switch = 0
bysort pid (syear): replace stem_unemp_switch = 1 if inrange(pgemplst, 3, 6) & inrange(pgemplst[_n-1], 1, 2) & stem[_n-1] == 1
bysort pid (syear): replace stem_unemp_switch = -1 if inrange(pgemplst, 1, 2) & stem == 1 & inrange(pgemplst[_n-1], 3, 6)


collapse (sum) stem_switch unemp_switch stem_unemp_switch (count) pid [aw = phrf], by(syear)

twoway (line unemp_switch syear, lcolor(gs8) lpattern(solid)) ///
||     (connected stem_unemp_switch syear [w = pid], lcolor(gs4) mcolor(gs4) msymb(oh) lpattern(solid)) ///
||     (line stem_switch syear, lcolor(black) lpattern(solid)), ///
	yline(0, lcolor(gs12) lpattern(dash)) ///
	xtitle("Survey Year") ///
	ytitle("Net Switches") ///
	ylab(, nogrid) ///
	xlab(, nogrid) ///
	legend(label(1 "Employment (Full- or Part-Time) to No Regular Employment") ///
	       label(2 "STEM to No Regular Employment") ///
		   label(3 "STEM to Non-STEM") ///
		   order(3 2 1) ///
		   position(6)) ///
	note("`fmt_sumpid' Obs. in 1990, thereof `sumstem' in STEM.") ///
	name(net_switches, replace)

graph export "${figures}net_switches.pdf", replace

}

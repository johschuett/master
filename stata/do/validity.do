** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${data}ZA2644_LVost/ZA2644_data_v1-0-0_dta/ERWERB, clear
merge m:1 FALLNR using ${data}ZA2644_LVost/ZA2644_data_v1-0-0_dta/LMUTTER, keep(3) nogen keepusing(SEX KOHORTE)

* all variables in lower case
foreach var of varlist * {
     rename `var' `= lower("`var'")'
}

* drop if case is not part of a cohort
drop if kohorte == 9

* sort data
sort fallnr spellnr

* female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)

* drop cases with missing occupation
drop if inlist(f401i3, -1, 1004, 1009)

* start of occupation
gen startocc = bg05403 + 1900
drop if startocc == 1900 | startocc > 1990
label variable startocc "Year of Start of Occupation"

drop if mi(startocc)

* drop if occupation started before 1945
drop if startocc < 1945

* start of occupation (in decades)
recode startocc (1945/1949 = 1) (1950/1959 = 2) (1960/1969 = 3) ///
				(1970/1979 = 4) (1980/1990 = 5), gen(startocc_cat)

label variable startocc_cat "Year of Start of Occupation (categorised)"

label define startocc_cat 1 "1945--1949", modify
label define startocc_cat 2 "1950--1959", modify
label define startocc_cat 3 "1960--1969", modify
label define startocc_cat 4 "1970--1979", modify
label define startocc_cat 5 "1980--1990", modify

label values startocc_cat startocc_cat

* mark stem profession
recode f401i3 (11/54 = 1) (81/91 = 1) (nonmissing = 0), gen(stem)

label variable stem "STEM Profession"

label define stem 0 "[0] Does not have a STEM Profession", modify
label define stem 1 "[1] Has a STEM Profession", modify

label values stem stem

drop if mi(stem)

* save dataset
compress
save ${data}validity, replace

* graphical analysis
collapse (mean) stem (count) fallnr, by(startocc_cat female) 

* infos on bin sizes for notes
sum fallnr
local size_mean = round(r(mean))
local size_sd   = round(r(sd))

local fmt_size_mean : di %3.0fc `size_mean'
local fmt_size_sd   : di %3.0fc `size_sd'

use ${data}validity, clear

statsby stem=r(mean) lb=r(lb) ub=r(ub), by(startocc_cat female) clear: ci means stem

twoway (connected stem startocc_cat if female == 0, mcolor(gs6) lcolor(gs6) msymbol(O) lpattern(solid)) ///
||     (connected stem startocc_cat if female == 1, mcolor(black) lcolor(black) msymbol(S) lpattern(solid)) ///
||     (rcap lb ub startocc_cat if female == 0, lcolor(gs6)) ///
||     (rcap lb ub startocc_cat if female == 1, lcolor(black)), ///
xtitle("Year of Start of Occupation") ///
ytitle("Avg. Prob. STEM Profession") ///
xlabel(1 2 3 4 5, valuelabel) ///
ylabel(0.05(0.05)0.2, format(%03.2f) nogrid) ///
legend(label(1 "Male") ///
       label(2 "Female") ///
	   order(2 1)) ///
note("Avg. Bin Size (Std. Dev.): `fmt_size_mean' (`fmt_size_sd')") ///
name(cohorts, replace)

graph export "${figures}validity.pdf", replace

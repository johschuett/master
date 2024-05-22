***************************************** PREAMBLE *****************************************
*-> SET LOCAL ROOT HERE
global root     = "H:/master_thesis/stata/"

version 17

clear all
set more off
pause on

* soep v38.1
global v38      = "//hume/rdc-prod/distribution/soep-core/soep.v38.1/eu/Stata_DE/soepdata/"

global data     = "${root}data/"
global do       = "${root}do/"
global log      = "${root}log/"
global figures  = "${root}figures/"

* install xfill
net from https://www.sealedenvelope.com/
pause [Press "q" to continue...]
*************************************** END PREAMBLE ***************************************


use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)

merge 1:1 pid syear using ${v38}pl, keep(3) keepusing(plb0241_h plb0176_h pli0096_h plh0258_h) nogen
merge 1:1 pid syear using ${v38}pgen, keep(1 3) keepusing(pgemplst) nogen

* dependent variable DESIRED WORK HOURS - CONTRACTED WORK HOURS *

* set unemployed to zero contracted work hours
replace plb0176_h = 0 if pgemplst == 5

* drop observations with missing desired/contracted work hours
drop if plb0241_h < 0 | plb0176_h < 0

* generate work hours gap
gen work_hours_gap = plb0241_h - plb0176_h
label variable work_hours_gap "Difference between desired work hours and contraced work hours (weekly)"

**


* generate female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)


* generate catholic dummy
gen catholic = .
replace catholic = 1 if plh0258_h == 1
replace catholic = 0 if plh0258_h  > 1

label variable female "Catholic"

label define female 0 "[0] Non-Catholic", modify
label define female 1 "[1] Catholic", modify

label values catholic catholic

drop if mi(catholic)


* generate interaction dummy
gen female_catholic = female * catholic


save ${data}large_sample, replace


* get share of catholics in the federal states
import delimited using ${data}states_religion.csv, varnames(1) encoding(utf-8) clear
rename state birthregion

drop state_name

merge 1:m birthregion using ${data}large_sample, keep(3) nogen


* generate interaction instrument
gen female_perc_catholics = female * perc_catholics


ivregress 2sls voluntary_work_often female gebjahr (catholic female_catholic = perc_catholics female_perc_cath), vce(cluster hid) first

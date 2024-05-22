***************************************** PREAMBLE *****************************************
*-> SET LOCAL ROOT HERE
global root     = "H:/master_thesis/stata/"

version 17

clear all
set more off
set maxvar 7000

* soep v38.1
global v38      = "//hume/rdc-prod/distribution/soep-core/soep.v38.1/eu/Stata_DE/soepdata/"

global data     = "${root}data/"
global do       = "${root}do/"
global log      = "${root}log/"
global figures  = "${root}figures/"
*************************************** END PREAMBLE ***************************************


use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)

merge 1:1 pid syear using ${v38}pl, keep(3) keepusing(plb0241_h plb0176_h) nogen
merge 1:1 pid syear using ${v38}pgen, keep(1 3) keepusing(pgemplst) nogen
merge 1:1 pid syear using ${v38}health, keep(3) nogen

* dependent variable DESIRED WORK HOURS - CONTRACTED WORK HOURS *

* set unemployed to zero contracted work hours
replace plb0176_h = 0 if pgemplst == 5

* drop observations with missing desired/contracted work hours
drop if plb0241_h < 0 | plb0176_h < 0

* generate work hours discrepancy
gen desired_contracted = plb0241_h - plb0176_h
label variable desired_contracted "Difference between desired work hours and contraced work hours (weekly)"

**


* generate female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)


* keep only cases with valid mcs scores
keep if mcs >= 0

* generate interaction
gen desired_contracted_female = desired_contracted * female

reg mcs desired_contracted female desired_contracted_female, vce(cluster hid)

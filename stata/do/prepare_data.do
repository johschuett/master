** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${v38}ppathl, clear
keep if inrange(netto, 10, 19)


* generate female dummy
recode sex (2 = 1) (1 = 0) (nonmissing = .), gen(female)

label variable female "Female"

label define female 0 "[0] Male", modify
label define female 1 "[1] Female", modify

label values female female

drop if mi(female)


* regressors of interest: year dummies and interactions with female
forvalues year = 1991(1)1999 {
	gen d`year' = 0
	replace d`year' = 1 if syear == `year'
	
	gen female_d`year' = d`year' * female
	
	label variable d`year' "`year'"
	label variable female_d`year' "`year' $\times$ Female"
}


* residence west germany
merge m:1 hid syear using ${v38}regionl, keep(3) keepusing(bula) nogen

recode bula (1/10 = 1) (11/16 = 0) (nonmissing = .), gen(west)

label variable west "Residence in West Germany"

label define west 0 "[0] Does not reside in West Germany", modify
label define west 1 "[1] Resides in West Germany", modify

label values west west

drop if mi(west)

* interaction term
gen west_female = west * female
label variable west_female "Residence in West Germany $\times$ Female"


* eastern origin
recode loc1989 (1 = 1) (2 = 0) (nonmissing = .), gen(east_origin)

label variable east_origin "East German Origin"

label define east_origin 0 "[0] Does not have an East German Origin", modify
label define east_origin 1 "[1] Has an East German Origin", modify

label values east_origin east_origin

drop if mi(east_origin)


* stem profession
merge 1:1 pid syear using ${v38}pl, keep(1 3) keepusing(p_isco88) nogen

recode p_isco88 (1236 2111/2213 3111/3212 = 1) (min/0 = .) (nonmissing = 0), gen(stem)

label variable stem "STEM Profession"

label define stem 0 "[0] Does not have a STEM Profession", modify
label define stem 1 "[1] Has a STEM Profession", modify

label values stem stem

drop if mi(stem)


* info about employment status
merge 1:1 pid syear using ${v38}pgen, keep(1 3) keepusing(pgemplst) nogen


* only individuals who are either full- or part-time employed should be marked
* as success in stem variable
replace stem = 0 if !inrange(pgemplst, 1, 2)


* age
gen age = syear - gebjahr
gen age_2 = age^2

label variable age "Age"
label variable age_2 "Age (squared)"


* keep working age population only
keep if inrange(age, 17, 65)


* partner
recode partner (1/4 = 1) (0 5 = 0), gen(partner_bin)
label variable partner_bin "Spouse/Life Partner"

label define partner_bin 0 "[0] Does not have a Spouse/Life Partner", modify
label define partner_bin 1 "[1] Has a Spouse/Life Partner", modify

label values partner_bin partner_bin

gen partner_bin_female = partner_bin * female
label variable partner_bin_female "Spouse/Life Partner $\times$ Female"


* household size
merge m:1 hid syear using ${v38}hbrutto, keep(3) keepusing(hhgr) nogen

gen hhgr_female = hhgr * female
label variable hhgr "Household Size"
label variable hhgr_female "Household Size $\times$ Female"


** RESTRICTED AREA **
merge m:1 hid syear using ${restricted}regionl, keep(3) keepusing(regbez kr_emprate kr_popdens) nogen

label variable kr_emprate "Employment Rate in County of Residence"
label variable kr_popdens "Population Density in County of Residence"


* individual lives in the "mitteldeutsche chemiedreieck"
gen chemiedreieck = 0
replace chemiedreieck = 1 if inlist(regbez, 142, 152) // ([152] halle, [142] leipzig)

gen chemiedreieck_female = chemiedreieck * female

label variable chemiedreieck "Residence in Chemiedreieck"
label variable chemiedreieck_female "Residence in Chemiedreieck $\times$ Female"

label define chemiedreieck 0 "[0] Does not reside in the Chemiedreieck", modify
label define chemiedreieck 1 "[1] Resides in the Chemiedreieck", modify

label values chemiedreieck chemiedreieck
**


* save dataset
compress
save ${data}female_stem, replace

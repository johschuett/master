** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* population (INKAR: Bevölkerung gesamt)
import delimited "${data}destatis/state_wide.csv", encoding(utf-8) varnames(1) clear

* fill missing data in 1990 with data of 1991
replace unemprate_1990    = unemprate_1991
replace unemp_female_1990 = unemp_female_1991
replace unemp_male_1990   = unemp_male_1991

reshape long unemprate_ unemp_female_ unemp_male_, i(state) j(syear)

rename unemprate_ unemprate
rename unemp_female_ unemp_female
rename unemp_male_ unemp_male

rename state bula
drop state_name

save "${data}state.dta", replace

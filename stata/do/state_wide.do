** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* population (INKAR: Bevölkerung gesamt)
import delimited ${data}/state_wide.csv, encoding(utf-8) varnames(1) clear


* fill missing data in 2005-2007 for population density
gen popdens_2005 = 0.7 * popdens_2004 + 0.3 * popdens_2008
gen popdens_2006 = 0.5 * popdens_2004 + 0.5 * popdens_2008
gen popdens_2007 = 0.3 * popdens_2004 + 0.7 * popdens_2008

drop popdens_2004


reshape long unemp_ gdp_ popdens_ netcommuting_ firstsemstud_, i(state) j(syear)

rename unemp_ unemp
rename gdp_ gdp
rename popdens_ popdens
rename netcommuting_ netcommuting
rename firstsemstud_ firstsemstud

label variable unemp         "Unemployment Rate (Fed. State)"
label variable gdp           "GDP in Thousand of Euros (Fed. State)"
label variable popdens       "Population Density (Fed. State)"
label variable netcommuting  "Net Commuter Traffic (Fed. State)"
label variable firstsemstud  "Students in First Semester as Share of all Students (Fed. State)"

rename state bula
drop state_name


* save dataset
save ${data}state.dta, replace

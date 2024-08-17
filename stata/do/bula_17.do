** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* get the year of the first observation of each individual
egen syear_min = min(syear), by(pid)

gen bula_min = bula if syear == syear_min
label variable bula_min "Federal State of Residency in earliest Survey Year"
xfill bula_min, i(pid)


* only keep the newest observation of each individual
gsort pid -syear
duplicates drop pid, force


* calculate survey year when they were 17 years old (usually the time of deciding whether to study at uni or not)
gen syear_17 = syear - age + 17

drop syear
rename syear_17 syear

rename bula bula_now

* the local `file' is defined either in regression_analysis.do or robustness.do to make this script applicable for both!
* the value is either "children" or "children_robust"
merge 1:1 pid syear using ${data}${file}, keep(1 3) keepusing(bula) nogen

rename bula bula_17
label variable bula_17 "Federal State of Residency when 17 years old"

rename bula_now bula

tab bula bula_17, mi


* fill missing information with bula of mothers when the children were 17 years old
rename pid cnr
rename mnr pid
rename bula cbula

merge m:1 pid syear using ${data}female_stem, keep(1 3) keepusing(bula) nogen

rename bula mbula_17
rename cbula bula
rename pid mnr
rename cnr pid

replace bula_17 = mbula_17 if mi(bula_17)


* fill missing information with bula of fathers when the children were 17 years old
rename pid cnr
rename fnr pid
rename bula cbula

merge m:1 pid syear using ${data}female_stem, keep(1 3) keepusing(bula) nogen

rename bula fbula_17
rename cbula bula
rename pid fnr
rename cnr pid

replace bula_17 = fbula_17 if mi(bula_17)


* see for how many children with non-missing information, bula_min = bula_17
gen bula_help = 0
replace bula_help = 1 if bula_min == bula_17
replace bula_help = . if mi(bula_17)

tab bula_help

drop bula_help


* assume for the remaining missing observations that bula_min = bula_17 and create
* imputation flag
gen bula_17_flag = 0
replace bula_17_flag = 1 if mi(bula_17)

replace bula_17 = bula_min if mi(bula_17)

label variable bula_17_flag "Imputed Value: Federal State assumed to be the same"


drop bula
rename bula_17 bula


* merge state controls for the syear when individual was 17
merge m:1 bula syear using ${data}state, keep(3) nogen

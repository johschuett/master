** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* summary statistics estimation sample
use ${data}children, clear


foreach var in stem_edu age partner_bin hhgr west mother_east_or father_east_or mother_ever_stem father_ever_stem migback {
	di "`var'"
	ttest `var', by(female) reverse
}

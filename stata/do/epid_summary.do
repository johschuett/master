** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

* summary statistics estimation sample
use ${data}children, clear


foreach var in stem_edu age partner_bin hhgr west mother_east_or father_east_or mother_stem_ever father_stem_ever migback {
	di "`var'"
	ttest `var', by(female) reverse
}

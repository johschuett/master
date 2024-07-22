** DO NOT EXECUTE THIS DO-FILE ON ITS OWN, DO MAIN.DO !! **

use ${data}children, clear


* interactions (female x mother is from east germany)
gen female_mother_east_or = female * mother_east_or
label variable female_mother_east_or "Female $\times$ Mother: Eastern Origin"

gen female_mother_stem_ever = female * mother_stem_ever
label variable female_mother_stem_ever "Female $\times$ Mother: Ever STEM Profession"

gen female_mother_east_stem = female * mother_east_or * mother_stem_ever
label variable female_mother_east_stem "Female $\times$ Mother: Eastern Origin $\times$ Mother: Ever STEM Profession"



* unrestricted model (baseline--10)
{

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_stem_ever female_mother_stem_ever female_mother_east_stem father_stem_ever"
local person   = "`baseline' age age_squared migback"
local state    = "`person' bula_*"

estimates clear

* run model
foreach ind in baseline person state {
	logit stem_edu ``ind'', vce(cluster hid)
	estat ic
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(aic bic rank N)

}



* restricted model (basline--8)
{

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_stem_ever father_stem_ever"
local person   = "`baseline' age age_squared migback"
local state    = "`person' bula_*"

estimates clear

* run model
foreach ind in baseline person state {
	logit stem_edu ``ind'', vce(cluster hid)
	estat ic
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(aic bic rank N)


}



* restricted model (baseline--6)
{

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or"
local person   = "`baseline' age age_squared migback"
local state    = "`person' bula_*"

estimates clear

* run model
foreach ind in baseline person state {
	logit stem_edu ``ind'', vce(cluster hid)
	estat ic
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(aic bic rank N)

}



/*

unrestricted model (baseline--8)
--------------------------------------------------------------------
                              (1)             (2)             (3)   
--------------------------------------------------------------------
Female                    -0.1703***      -0.1750***      -0.1671***
                         (0.0484)        (0.0486)        (0.0475)   

Mother: Eastern Or~n       0.0663          0.0706          0.1060   
                         (0.1113)        (0.1124)        (0.1038)   

Female $\times$ Mo~       -0.0719         -0.0669         -0.1173   
                         (0.1016)        (0.1014)        (0.0977)   

Father: Eastern Or~n      -0.0079         -0.0135          0.0496   
                         (0.1054)        (0.1063)        (0.1062)   

Mother: Ever STEM ~n      -0.1164         -0.1097         -0.1192   
                         (0.1030)        (0.1028)        (0.1009)   

Female $\times$ Mo~E       0.1776          0.1842          0.1933   
                         (0.1491)        (0.1485)        (0.1466)   

Female $\times$ Mo~       -0.2227         -0.2334         -0.1866   
                         (0.1960)        (0.1947)        (0.2022)   

Father: Ever STEM ~n       0.1324***       0.1357***       0.1122***
                         (0.0424)        (0.0426)        (0.0429)   
--------------------------------------------------------------------
aic                       3329.766        3323.955        3256.326   
bic                       3382.768        3394.624        3415.331   
rank                         8              11              26   
N                          2668            2668            2668   
--------------------------------------------------------------------





restricted model (baseline--6) -> seems favourable
--------------------------------------------------------------------
                              (1)             (2)             (3)   
--------------------------------------------------------------------
Female                    -0.1557***      -0.1599***      -0.1519***
                         (0.0462)        (0.0463)        (0.0455)   

Mother: Eastern Or~n       0.0723          0.0770          0.1075   
                         (0.1113)        (0.1123)        (0.1041)   

Female $\times$ Mo~       -0.0936         -0.0899         -0.1299   
                         (0.0968)        (0.0967)        (0.0947)   

Father: Eastern Or~n      -0.0203         -0.0263          0.0367   
                         (0.1055)        (0.1063)        (0.1058)   

Mother: Ever STEM ~n      -0.0479         -0.0396         -0.0344   
                         (0.0742)        (0.0744)        (0.0740)   

Father: Ever STEM ~n       0.1305***       0.1336***       0.1103** 
                         (0.0428)        (0.0430)        (0.0433)   
--------------------------------------------------------------------
aic                       3335.168       3330.180         3261.723   
bic                       3376.391       3389.071         3408.950   
rank                         6              9               24   
N                          2668           2668             2668   
--------------------------------------------------------------------





restricted model (baseline--4)
--------------------------------------------------------------------
                              (1)             (2)             (3)   
--------------------------------------------------------------------
Female                    -0.1692***      -0.1731***      -0.1633***
                         (0.0466)        (0.0468)        (0.0457)   

Mother: Eastern Or~n       0.0894          0.0937          0.1251   
                         (0.1229)        (0.1237)        (0.1099)   

Female $\times$ Mo~       -0.0808         -0.0764         -0.1220   
                         (0.0995)        (0.0993)        (0.0951)   

Father: Eastern Or~n      -0.0317         -0.0358          0.0258   
                         (0.1164)        (0.1171)        (0.1108)   
--------------------------------------------------------------------
aic                       3376.956       3373.980         3289.891   
bic                       3406.401       3421.093         3425.340   
rank                         4              7                22   
N                          2668           2668              2668   
--------------------------------------------------------------------

*/



* restricted model (basline--8) with number of siblings and parental household income
{

* drop observations with missing information on additional controls
drop if mi(num_sib) | mi(parental_hhincome)

* define independent variables
local baseline = "female mother_east_or female_mother_east_or father_east_or mother_stem_ever father_stem_ever"
local person   = "`baseline' age age_squared migback num_sib parental_hhincome"
local state    = "`person' bula_*"

estimates clear

* run model
foreach ind in baseline person state {
	logit stem_edu ``ind'', vce(cluster hid)
	estat ic
	eststo: margins, dydx(``ind'') post
}


* direct output in log
esttab, ///
	b(4) se(4) label nomtitle keep(`baseline') star(* 0.10 ** 0.05 *** 0.01) stats(aic bic rank N)


}



/*

restricted model (baseline--6) with additional person controls
--------------------------------------------------------------------
                              (1)             (2)             (3)   
--------------------------------------------------------------------
Female                    -0.1667***      -0.1735***      -0.1619***
                         (0.0512)        (0.0506)        (0.0500)   

Mother: Eastern Or~n       0.0973          0.1116          0.1763   
                         (0.1284)        (0.1281)        (0.1151)   

Female $\times$ Mo~       -0.1141         -0.0961         -0.1745*  
                         (0.1046)        (0.1017)        (0.0980)   

Father: Eastern Or~n      -0.0177         -0.0614          0.0120   
                         (0.1224)        (0.1223)        (0.1142)   

Mother: Ever STEM ~n      -0.0723         -0.0425         -0.0513   
                         (0.0855)        (0.0835)        (0.0833)   

Father: Ever STEM ~n       0.1038**        0.1075**        0.0921** 
                         (0.0471)        (0.0464)        (0.0450)   
--------------------------------------------------------------------
aic                      2492.936         2449.301        2361.953   
bic                      2532.047         2516.349        2507.131   
rank                        6               11              25   
N                          1973            1973            1966   
--------------------------------------------------------------------

*/

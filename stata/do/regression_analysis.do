use ${data}female_stem, clear

gen dist_reunification = syear - 1990
gen dist_reunification_female = dist_reunification * female

local baseline = "dist_reunification female dist_reunification_female"

* baseline
foreach com in reg logit probit {
    `com' stem `baseline' if east_origin == 1 & inrange(syear, 1990, 1996), vce(cluster hid)
}

* control for living in the west
foreach com in reg logit probit {
    `com' stem `baseline' west west_female if east_origin == 1 & inrange(syear, 1990, 1996), vce(cluster hid)
}

* also control for person and household characteristica
foreach com in reg logit probit {
   `com' stem `baseline' west west_female if east_origin == 1 & inrange(syear, 1990, 1996), vce(cluster hid) 
}

* also control for länder characteristica
foreach com in reg logit probit {
   `com' stem `baseline' west west_female if east_origin == 1 & inrange(syear, 1990, 1996), vce(cluster hid) 
}

*-> SET LOCAL ROOT HERE
global root       = "H:/master_thesis/stata/" // VDI
global root       = "/Users/schuett/Repositories/master_thesis/stata/" // Mac

* soep v38.1
global v38        = "//hume/rdc-prod/distribution/soep-core/soep.v38.1/eu/Stata_DE/soepdata/" // VDI
global v38        = "${root}data/soep_v38.1/soepdata/" // Mac

* paths within project
global data       = "${root}data/"
global do         = "${root}do/"
global log        = "${root}log/"
global figures    = "${root}figures/"
global tables     = "${root}../latex/tables/"

ssc install coefplot
ssc install scheme_tufte

set scheme tufte

* open log
cap log close master_thesis
log using "${log}master_thesis_running.log", text replace name(master_thesis)



*** preamble
{

/*--------------------------------------------------------
MASTER THESIS
-------------

PUTTING THE GDR'S LEGACY EFFECT UNDER THE MICROSCOPE:
EASTERN FEMALE STEM PROFESSIONALS IN REUNIFIED GERMANY.

JOHANNES SCHÜTT, 5574549
FREE UNIVERSITY OF BERLIN

M.SC. PUBLIC ECONOMICS

SUPERVISOR: PROF. NATALIA DANZER, PH.D.

SUMMER TERM 2024

--------------------------------------------------------*/

version 17
clear all
set more off, permanently
set maxvar 7000

*** preamble END
}



** DESCRIPTIVE ANALYSIS **
* prepare data
do ${do}prepare_descr_data.do
* graphical analysis
do ${do}graphical_analysis.do
* validity analysis
do ${do}validity.do
**


** EPIDEMIOLOGICAL APPROACH **
* prepare data
do ${do}prepare_epid_data.do
* regression analysis
do ${do}regression_analysis.do
* robustness
do ${do}robustness.do
**


* erase tempfiles
erase ${data}female_stem.dta
erase ${data}punr.dta
erase ${data}survival.dta
erase ${data}validity.dta

erase ${data}children.dta
erase ${data}parents.dta

* close log file
log close master_thesis

exit

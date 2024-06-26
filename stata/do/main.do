*-> SET LOCAL ROOT HERE
global root       = "H:/master_thesis/stata/" // VDI
*global root       = "/Users/schuett/Repositories/master_thesis/stata/" // Mac

* soep v38.1
global v38        = "//hume/rdc-prod/distribution/soep-core/soep.v38.1/eu/Stata_DE/soepdata/" // VDI
*global v38        = "${root}data/soep_v38.1/soepdata/" // Mac

* restricted
global restricted = "\\hume\rdc-prod\restricted\soep-core\soep.v38.1\remote\Stata_DE\soepdata\"

* paths within project
global data       = "${root}data/"
global do         = "${root}do/"
global log        = "${root}log/"
global figures    = "${root}figures/"
global tables     = "${root}../latex/tables/"

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



* prepare data
do ${do}prepare_data.do
* graphical pre-analysis
do ${do}graphical_preanalysis.do
* validity analysis
do ${do}validity.do
* regression analysis
do ${do}regression_analysis.do
* eastern female tracking
do ${do}eastern_female_tracking.do


* erase tempfiles
erase ${data}female_stem.dta
erase ${data}validity.dta

* close log file
log close master_thesis

exit

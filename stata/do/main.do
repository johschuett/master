*-> SET LOCAL ROOT HERE
global root       = "/Users/schuett/Repositories/master_thesis/stata/"

* paths within project
global data       = "${root}data/"
global v38        = "${data}soep_v38.1/soepdata/"
global do         = "${root}do/"
global log        = "${root}log/"
global figures    = "${root}figures/"
global tables     = "${root}../latex/tables/"

ssc install coefplot
ssc install scheme_tufte
net install grc1leg, from(http://www.stata.com/users/vwiggins/)
net install xfill, from(http://www.sealedenvelope.com/)

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
* summary statistics
do ${do}descr_summary.do
* graphical analysis
do ${do}graphical_analysis.do
* validity analysis
do ${do}validity.do
**


** EPIDEMIOLOGICAL APPROACH **
* prepare data
do ${do}prepare_epid_data.do
* summary statistics
do ${do}epid_summary.do
* main findings / robustness
do ${do}regression_analysis.do
* extension: comparing the blocs
do ${do}extension.do
**


* erase tempfiles
erase ${data}female_stem.dta
erase ${data}punr.dta
erase ${data}survival.dta
erase ${data}validity.dta

erase ${data}children.dta
erase ${data}children_interactions.dta
erase ${data}information.dta
erase ${data}parents.dta
erase ${data}potential_fathers.dta
erase ${data}potential_mothers.dta

erase ${data}extension.dta
erase ${data}extension_children.dta
erase ${data}extension_parents.dta

erase ${data}state.dta

* close log file
log close master_thesis

exit

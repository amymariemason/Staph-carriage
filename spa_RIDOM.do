************************************************
*spa_RIDOM.DO
************************************************
*creates list of all spatypes for exporting to RIDOM
* INPUTS:   clean_data (from clean_maindata.do)
*OUTPUTS : unique_spa.csv (in outputs)
* written by Amy Mason


set li 130

cap log close
log using spa_R.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

****************************************
* RIDOM EXTRACT
****************************************
* create list of all spatypes
use "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", clear
keep patid timepoint spatype
split spatype, parse(/)
drop spatype
reshape long spatype, i(patid timepoint) j(spanum)
drop if spatype==""

**** LIST FOR EXTRACTING TO RIDOM***
keep spatype
duplicates drop
export delimited using "E:\users\amy.mason\staph_carriage\outputs\unique_spa.csv", replace
*********

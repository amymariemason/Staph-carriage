************************************************
*RIDOM_inputs.DO
************************************************
*takes data from RIDOM inputs and turns them into stata databases
* INPUTS:  CC_23_11_16.csv,  cost_noexclusions_23_11_16.txt (FROM RIDOM, see instructions at end)
*OUTPUTS : BURP, CC (in databases)
* written by Amy Mason


set li 130

cap log close
log using R_input.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"


*cc-groups 
***UPDATE: RIDOM***
noi di _n(5) _dup(80) "=" _n "Clonal colonies" _n _dup(80) "=" 
import delimited E:\users\amy.mason\staph_carriage\Inputs\CC_23_11_16.csv, delimiter(";:", collapse) varnames(1) clear 
drop v5
drop taxa
rename v4 CCname
rename spacc CC
 noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\CC", replace

* spa burp distance 
***UPDATE: RIDOM***
noi di _n(5) _dup(80) "=" _n "Burp distances" _n _dup(80) "=" 
 import delimited E:\users\amy.mason\staph_carriage\Inputs\cost_noexclusions_23_11_16.txt, clear
 drop v4
 noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\BURP", replace


cd "E:\users\amy.mason\staph_carriage\Programs"


exit
***********************************************
How to get BURP details out of ridom program.


1) Open and click on burp clustering. 
2) upload list of all spa-types from the staph carriage study. Let ridom update if there are spa-types not in it's database.
3)  cluster WITH exclusion of spatypes (default setting). 
4) extract the CC-groups data from this set (this should be a csv file). This gives you the list of which spa-types are in which Clonal cluster.
5) cluster WITHOUT excluding any spatypes
6) extract the cost matrix from this set (this should be as a mega file)
7) open the cost matrix in mega. Export the values as a csv file with export type "column". This will give you the distances between each pair of spa-types. 



Amy
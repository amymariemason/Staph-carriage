************************************************
*continue.DO
************************************************
* Answers Tim's big continuity questions; how much more info can we get from the study
* makes lots of messy carriage to date graphs, ignore these/ move to a new file.
* 
* INPUTS:   clean_data4 (from anti_types* ) 
*OUTPUTS :  makes some graphs/ outputs a log
* written by Amy Mason



set li 130

cap log close
log using continue.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"
**************************************
* HOW MANY PEOPLE HAVE ALWAYS CARRIED AND ARE STILL RETURNING SWABS



use  "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
keep patid timepoint spatype pos confirmedneg pos_so_far neg_so_far carriage_to
* keep people who still sending in past 72
bysort patid: gen last = timepoint[_N]
drop if last <74
keep if timepoint==last
noi di "how many people have always carried/ never carried who are still returning swabs post 75 months"
noi tab carriage 
noi tab timepoint carriage
list patid if carriage=="always"
keep if carriage =="always"
keep patid
cd E:\users\amy.mason\staph_carriage\Datasets\
save patlist, replace 

use  "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
merge m:1 patid using patlist, update
keep if _merge==3
keep patid timepoint spatype newspa*

* of these how many is it the same spatype
** (patid, timepoint, still carrying same spatype up to minor mutation of 2 BURP)
* 366	88	no
*420	88	no
*424	88	yes
*450	88	yes
*454	88	yes
*671	88	yes
*1212	80	yes
*1231	82	no
*1233	82	no
*1281	80	yes
*1307	82	yes
		
*	 = 	7 YES


* HOW MANY PEOPLE HAVE NEVER CARRIED AND ARE STILL RETURNING SWABS
*see previous table

* HOW MANY PEOPLE ARE STILL CARRYING THE SAME SPATYPE (aquired after start)

use "E:\users\amy.mason\staph_carriage\Datasets\record_per_spa.dta", clear
* keep only the spatypes that start after timepoint 0/2 - ie those we know aquired during study
 keep patid timepoint this_spa carriage_this_spa  this_confirmed_loss
sort patid this_spa timepoint
by patid this_spa: drop if carriage_this_spa[1]==1& carriage_this_spa[2]==1
* drop people who never carry
drop if this_spa==""
* find people who are still carrying this spatype at end of their current swabs (min 74)
by patid this_spa: gen last = timepoint[_N]
drop if last<74
gen dropped = timepoint if this_confirmed ==1
by patid this_spa: egen lastdrop = min(dropped)

drop if lastdrop!=.
keep if timepoint==last

 noi di "people still carrying spas aquired during study"
noi tab patid
noi tab patid this_spa
noi tab patid timepoint


* HOW MANY PEOPLE ARE VARYING CARRIAGE + don't have on-going spa-type

use  "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear 
keep patid timepoint spatype Result pos confirmedneg pos_so_far neg_so_far carriage_to newspa*
**** drop those not still returning swabs 
bysort patid: gen last = timepoint[_N]
drop if last <74
********* drop those without varied carriage
gen green = 1 if carriage=="varies"
bysort patid: egen greenmax = max(green)
drop if greenmax==.

****************
* eyeballing: 1218, 1219, 1359 still carrying spatypes from first two years

drop if inlist(patid, 1218, 1219, 1359)

************************
keep patid timepoint spatype Result newspa_prev carriage
noi list, sepby(patid)
noi save "E:\users\amy.mason\staph_carriage\Datasets\people_to_stop.dta", replace
export excel using "E:\users\amy.mason\staph_carriage\outputs\People to stop.xls", replace
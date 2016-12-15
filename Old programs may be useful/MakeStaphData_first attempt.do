/* This file makes the dataset used in equilibruim graph. Note that at one point 
the data is exported to R, then then back into Stata in order to add BURP distances
to the final data file. If the data is updated, that will need to be rerun halfway
through this file in order to update BURP data */

/*NOTE: this is an OLD VERSION, relying on timepoint not day_no for analysis. */
/*See MakeStaphData_second for day based dataset */


/* Creates 1) DatawithCovariates: combining swob data with baseline and antibiotic (Ruth) info, from files supplied by Sarah */
/* 2) Antibiotic marker: Using extracts from Access, made my own antibiotic marker */
/* 3) DatawithAntiCov: combo of the two above */
/* 4) DatawithNewBurp2: combining above with BURP data */




/*####################################*/
/*Creates DatawithCovariates: all swob results for nose swobs, non-hospital patients, with baseline factors added in */
/*####################################*/

/*Using raw_ruth data, which contains all swab results, postive and negative.
Combining this with crsa_combined which contains the postive results only, but with spa-typing on the swabs */

clear
use "E:\users\sarahw\small\votintseva\raw_ruth.dta", clear


/*drop people already in combind crsa*/
drop if result == "MSSA"
drop if result == "MRSA"

/*drop people who did not return swab*/
drop if result == ""





save "E:\users\amy.mason\Staph\raw_ruth_noresult.dta", replace

use "E:\users\sarahw\small\votintseva\crsa_combined.dta", clear

/*adds no result data from above to bottow of results data set */
append using "E:\users\amy.mason\Staph\raw_ruth_noresult.dta"

/*cut down to only patients in nose only swaps, remove any duplicates */

drop if cohort == 4
drop if patid > 2122
drop if patid > 1401 & patid <2000
drop if site!="Nose"&site!=""
drop if timepoint==999
drop if timepoint>48

drop if inlist(patid,1101,1102,801,1401)==1
/* drop people who have only single swob */

sort patid
by patid: drop if _N==1

/* still duplicates */
duplicates tag patid timepoint result, gen(dup_flag)
/* all duplicates are no growth, and agree on everything except return date - plan = drop duplicates, should not affect analysis*/
*drop if patid!=1385 &patid!=2094 &patid!=1374&patid!=1284&patid!=1364&patid!=2043
*order patid timepoint dup_flag
*sort patid timepoint
drop if dup_flag >0
assert dup_flag==0
drop dup_flag


/* looking for duplicate results */

duplicates tag patid timepoint, gen(dup_flag1)

/* single duplicate on patid 2080, timepoint 24. One pos, on neg? */

*assert dup_flag1==0
*ignore for now, looking into it on access database.


/* add State pos/neg growth result */
generate State=1

replace State = 0 if result =="No growth"

order patid timepoint State

save "E:\users\amy.mason\Staph\2State.dta", replace


/* open baseline factor file and relabel*/

use "E:\users\sarahw\small\miller\riskfactors_baseline.dta", clear

renpfix "" baseline_

rename baseline_patid patid

save "E:\users\amy.mason\Staph\baselinefactors.dta", replace

/*ditto timebased antibiotic use*/


use "E:\users\sarahw\small\miller\riskfactors_antibiotic.dta", clear

renpfix "" anti_

rename anti_patid patid
 
rename anti_timepoint timepoint

save "E:\users\amy.mason\Staph\riskfactors_antibiotic.dta", replace



 /*merge these into state data */


use "E:\users\amy.mason\Staph\2State.dta", clear

merge m:1 patid using "E:\users\amy.mason\Staph\baselinefactors.dta", update

/* non-matching both ways, kept only those in original file.*/
drop if _merge==1 &inlist(patid,1101,1102,801,1401)==1

/*Now want to drop records with only one result - they were patients not invited to continue study */

sort patid timepoint
by patid: drop if _N==1 &_m==1

assert _merge==3
drop _merge


/* double record for patient 2080 timepoint 24. returned two swabs? Drop no growth result */
duplicates tag patid timepoint, gen(dup_flag2)
drop if dup_flag2==1&State==0


/* add antibiotic data*/

merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\riskfactors_antibiotic.dta", update

/* extra result from using has no Stata data attached to it, just antibiotic, which is repeated on result before. 
Presumably someone returned antibiotic form without swab?  However large number of records lacking antibiotic data*/

drop if _merge==2
assert _merge==1 | _merge==3
drop _merge
/* all matched correctly */ 

save "E:\users\amy.mason\Staph\DataWithCovariates.dta", replace


/*####################################*/
/* Creates new antibiotic factors dataset  (Antimicrobials_marker)  for each time point */
/*####################################*/



/*Pull in excel extract from Access (taken 03/06/2014) */

import excel "E:\users\amy.mason\Staph\StaphCarriage_Antibiotics.xlsx", sheet("StaphCarriage_Antibiotics") firstrow clear
 /* drop empty catagories */
 drop if Antimicrobial=="" & DateStarted==. & DateEnded==.
 rename   ParticipantID patid
 rename  FollowupMonth timepoint
 
 drop  SwabID spatype  Confirmed AmountTakenPerDay
/*add number of days since antibiotics started */
gen antidays= DateTaken- DateStarted
gen antidays_receive= Received-DateStarted
gen antidays_end = DateTaken- DateEnded
/* some have negative values. Eyeballing, I suspect they misfilled in forms. replaced with "." */
replace antidays=. if antidays<0
replace antidays_end=. if antidays_end<0
replace antidays_receive=. if antidays_receive<0
replace antidays_end=. if antidays_end> antidays


/* get rid of irrelevant patients */

drop if inlist(patid,1101,1102,801,1401)==1
drop if patid > 2122
drop if patid > 1401 & patid <2000
drop if timepoint==999
drop if timepoint>48


/*work out if antibiotics taken */ 
replace Antimicrobial="Unknown" if Antimicrobial=="? - could not get in contact with patient to ask"

merge m:1 Antimicrobial using "E:\users\amy.mason\Staph\AntiStaph", update
/* spelling problem, drop */
drop if _merge==2
assert _merge==3
drop _merge

/*decide what to do with blanks */
replace antistaph=. if Antimicrobial=="Unknown" |Antimicrobial=="Unknown antibiotic" 

/* for the moment, consider only things active against staph */
keep if antistaph==1

/* check for duplicates on patid/timepoint */
duplicates tag patid timepoint, gen(dup_flag3)
/* duplicates, clearly people taking multiple meds; reshape to wide */

drop MSSA MRSA
sort patid timepoint Antimicrobial
by patid timepoint: gen marker=_n
reshape wide  Antimicrobial antistaph antidays  antidays_end antidays_receive DateStarted DateEnded, i(patid timepoint) j(marker)


merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithCovariates.dta", update
/* NOTE THIS DOES NOT GIVE _MERGE =3 */

save "E:\users\amy.mason\Staph\Antimicrobials_working", replace




/* fix AppendixFA data to right format (this is the GP records data) */
/* need patid, timepoint, info2 ( type of antimicrobial), date*/

 import excel "E:\users\amy.mason\Staph\AppendixFa2yr.xls", sheet("AppendixFa2yr") clear
 rename A patid
 gen marker2 = 4
 rename B info
  rename C date
 keep patid info date marker2
 save "E:\users\amy.mason\Staph\Antimicrobials_working2", replace
 /* include GP start data */
 import excel "E:\users\amy.mason\Staph\AppendixFa.xls", sheet("AppendixFa") clear
 rename A patid
 gen marker2 = 5
 rename B info
 rename C date
 keep patid info date marker2
 append using "E:\users\amy.mason\Staph\Antimicrobials_working2"
 duplicates drop patid date info, force
  keep patid info date marker2
  /* drop patids not in this study */
  drop if patid > 2122
drop if patid > 1401 & patid <2000
drop if inlist(patid,1101,1102,801,1401)==1

/* restrict to staph active antibiotics */
rename info Antimicrobial
merge m:1 Antimicrobial using "E:\users\amy.mason\Staph\AntiStaph_update", update
/* fix the single mismatch - spelling problem */
replace antistaph=0 if patid==1398 
drop if _merge==2
assert _merge==3| patid==1398
drop _merge

keep if antistaph==1
rename Antimicrobial info
keep patid info date marker2
  
save "E:\users\amy.mason\Staph\Antimicrobials_working3", replace
 
/* create my own # days between antibiotic started and swob received marker */

use "E:\users\amy.mason\Staph\Antimicrobials_working", clear

keep patid timepoint returndate Antimicrobial* DateStarted* DateEnded*
reshape long
drop if marker>1 & Antimicrobial==""
keep patid timepoint returndate Antimicrobial* DateStarted* DateEnded* marker

rename returndate date1
rename DateStarted date2
gen info1="swob returned"
rename Antimicrobial info2
gen temp = " ended"
egen Anti2= concat(info2 temp) if info2!=""
rename Anti2 info3
rename DateEnded date3
drop temp

sort patid timepoint
reshape long date info, i(patid timepoint marker) j(marker2)
drop if info==""
drop if date==.&marker2==3
drop if date==.&marker2==1
drop if marker>1 & marker2==1
/* finished investigation with endpoints, drop after here */
drop if marker2==3

 
append using "E:\users\amy.mason\Staph\Antimicrobials_working3"
label variable marker2 "origin of data"
label define markerv 1 "swob data"  2 "patient form" 3 "patient-endtime"  4 "Gp-2yr" 5 "GP- recruit"
label values marker2 markerv


sort patid timepoint marker2


/* remove patients for who we have no swob data */
sort patid timepoint marker2
by patid: drop if timepoint[1]==.
sort patid timepoint marker2
by patid: assert timepoint[1]!=.
 by patid:gen Start=date[1]
format Start %d
gen day_no = date-Start

/* replaceing antibiotics with missing dates with date of swob returned with */
sort patid timepoint marker2
by patid timepoint: replace day_no=day_no[_n-1] if marker2==2 & day_no==.



/* some weirdly duplicated swobs, two months apart but with same return date. drop earlier one */
format date %td
gsort patid marker2 -timepoint
duplicates drop patid day_no marker2, force






/* creates markers for when patient last had antibiotics started before this swob, when last had swob before this swob */
/* need three varients: based on GP, based on patient/recruit and based on both */

gen int GP_marker= 1 if inlist(marker2,1, 4 ,5)==1
gen int patient_marker= 1 if inlist(marker2,1, 5 ,2)==1

/* makes time-dep for all data */
gsort patid day_no -marker2
gen int last_anti_day=.
replace last_anti_day = day_no if inlist(marker2,2,4,5)==1
by patid: replace last_anti_day=last_anti_day[_n-1] if  marker2==1
by patid: gen days_since_last_anti =  day_no- last_anti_day if  last_anti_day!=.  & marker2==1
gsort patid marker2 day_no
by patid: gen days_last_swob =  day_no[_n]-day_no[_n-1] if marker2==1
replace days_last_swob=. if timepoint==0 & marker2==1
label variable days_last_swob "number of days since last swob taken by patient"
label variable days_since_last_anti "number of days since last antibiotic taken (Gp+patient report)"


/* makes time-dep vars for GP*/
gsort GP_marker patid day_no -marker2
gen int GP_last_anti_day=.
replace GP_last_anti_day = day_no if inlist(marker2,2,4,5)==1 &GP_marker==1
by GP_marker patid: replace GP_last_anti_day=GP_last_anti_day[_n-1] if  marker2==1 & GP_marker==1
by GP_marker patid: gen GP_days_last_anti =  day_no- GP_last_anti_day if  GP_last_anti_day!=.  & marker2==1& GP_marker==1
gsort GP_marker patid marker2 day_no
by GP_marker patid: gen GP_days_last_swob =  day_no[_n]-day_no[_n-1] if marker2==1& GP_marker==1
replace GP_days_last_swob=. if timepoint==0 & marker2==1 & GP_marker==1
label variable GP_days_last_swob "number of days since last swob taken by patient"
label variable GP_days_last_anti "GP DATA ONLY: number of days since last antibiotic taken"

/* now do same for patient*/
gsort patient_marker patid day_no -marker2
gen int patient_last_anti_day=.
replace patient_last_anti_day = day_no if inlist(marker2,2,4,5)==1 &patient_marker==1
by patient_marker patid: replace patient_last_anti_day=patient_last_anti_day[_n-1] if  marker2==1 & patient_marker==1
by patient_marker patid: gen patient_days_last_anti =  day_no- patient_last_anti_day if  patient_last_anti_day!=.  & marker2==1& patient_marker==1
gsort patient_marker patid marker2 day_no
by patient_marker patid: gen patient_days_last_swob =  day_no[_n]-day_no[_n-1] if marker2==1& patient_marker==1
replace patient_days_last_swob=. if timepoint==0 & marker2==1 & patient_marker==1
label variable patient_days_last_swob "number of days since last swob taken by patient"
label variable patient_days_last_anti "patient DATA ONLY: number of days since last antibiotic taken"




/* create binary marker: "antibiotics taken between this swob and previous swob", and "antibiotics taken in last 180 days" */
/*keep if marker2==1 */
gsort patid marker2 day_no
gen prev_anti_swob= 0
replace prev_anti_swob=1 if  days_since_last_anti<= days_last_swob  & marker2==1 & timepoint!=0
replace prev_anti_swob=1 if  days_since_last_anti<= 60  & marker2==1 & timepoint==0
label variable prev_anti_swob "all data: staph antibiotics taken since last swob"

gen prev_anti_6mon =0
replace prev_anti_6mon =1 if days_since_last_anti<180  & marker2==1 
label variable prev_anti_6mon "all data: staph antibiotics taken last six months"

/* and one for GP data only */

gsort patid marker2 day_no
gen GP_prev_anti_swob= 0
replace GP_prev_anti_swob=1 if  GP_days_last_anti<= days_last_swob  & marker2==1 & timepoint!=0
replace GP_prev_anti_swob=1 if  GP_days_last_anti<= 60  & marker2==1 & timepoint==0
label variable GP_prev_anti_swob "GP data: staph antibiotics taken since last swob"

gen GP_prev_anti_6mon =0
replace GP_prev_anti_6mon =1 if GP_days_last_anti<180  & marker2==1 
label variable GP_prev_anti_6mon "GP data: staph antibiotics taken last six months"

/* and one for patient data only */

gsort patid marker2 day_no
gen patient_prev_anti_swob= 0
replace patient_prev_anti_swob=1 if  patient_days_last_anti<= days_last_swob  & marker2==1 & timepoint!=0
replace patient_prev_anti_swob=1 if  patient_days_last_anti<= 60  & marker2==1 & timepoint==0
label variable patient_prev_anti_swob "patient data: staph antibiotics taken since last swob"

gen patient_prev_anti_6mon =0
replace patient_prev_anti_6mon =1 if patient_days_last_anti<180  & marker2==1 
label variable patient_prev_anti_6mon "patient data: staph antibiotics taken last six months"




/* 366 is a mess. it looks like they were taking antibiotics every month, but recording dates stupidly (ie. I started 1000s days before study. */
/*Set all markers to 1 except prev_anti_swob at timepoint=48. All others with neg values will get dealt with sensibly by program */ 
replace prev_anti_swob=1 if  patid==366 & timepoint <48 
replace prev_anti_6mon=1 if  patid==366



/* create desired output format */

keep  patid timepoint date day_no days_since_last_anti days_last_swob prev_anti_swob prev_anti_6mon
sort patid timepoint

save "E:\users\amy.mason\Staph\Antimicrobials_marker", replace

/*////////////////////////////////////////////////////////// */
/* Add antibiotic marker data to main data file: Creates DataWithAntiCov*/
/*////////////////////////////////////////////////////////// */

use "E:\users\amy.mason\Staph\DataWithCovariates.dta", clear
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\Antimicrobials_marker", update
/* some that don't match: caused by duplicate return dates, and fake swobs caused by swapping long to wide */
gsort patid -timepoint
duplicates drop patid returndate, force
drop if _merge==1
assert _merge==3

/* look at comparision with Ruth's data */

/*table  days_since_last_anti anti_antibi2swab */

/* close enough: differences due to differingI have already filtered out stuff non active to staph */
keep  patid timepoint State followupneg returndate spatypeid* n_spatypeid baseline_followupneg baseline_age baseline_male baseline_ethnic date day_no days_since_last_anti days_last_swob prev_anti_swob prev_anti_6mon


save "E:\users\amy.mason\Staph\DataWithAntiCov.dta", replace



/*#####################################################*/
/*Adding BURP data to DatawithAntiCov */
/*#####################################################*/





/* NOTE: AT THIS POINT R file "BURP_add_final" needs to be run with appropiete extract from the above*/

/* adds BURP distances to first recorded carriage (see R file) to set*/

use "E:\users\amy.mason\Staph\DataWithAntiCov.dta", clear
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\NewBurpOnly", update
/* problems = patients with only one swob, drop & rest are the ones that were dropped earlier for returning two sowbs on same date */
sort patid
by patid: gen max=_N
drop if max==1
* drop 1101 as unable to culture original sample, 801,1102 only 1/2 swabs returned, 1401 skin and soft tissue analysis dropped from main analysis
drop if inlist(patid,1101,1102,801,1401)==1
drop if _merge==2

assert _merge==3
drop _merge
/* all matched correctly */ 

rename BurpMax2time2 BurpStart
rename BurpPrev2 BurpPrev

 /* some follow_up_neg missing - fix with extra info on followupneg */
 gen byte prob=1 if (followupneg!=baseline_followupneg & followupneg!=.)
 replace baseline_followupneg = followupneg if (prob==1 & baseline_followupneg==.)
 drop prob
 gen byte prob=1 if (followupneg!=baseline_followupneg & followupneg!=.)
 assert prob==.
 
 /* still has missing: define own: agrees everywhere prev is defined. */
gen byte base2=1
sort patid timepoint
by patid: replace base2=0 if State[1]==1 

save "E:\users\amy.mason\Staph\DataWithNewBurp2", replace





/* DON'T RUN THESE AGAIN */
/* sort out antibiotic data */

import excel "E:\users\amy.mason\Staph\Staph_drugslist_nicola.xlsx", sheet("Sheet1") cellrange(A1:I132) firstrow clear
drop in 1
drop C
drop I
drop in 130
gen antistaph=0
replace antistaph=1 if  MSSA=="A" | MRSA=="A"
keep Antimicrobial MSSA MRSA antistaph

save  "E:\users\amy.mason\Staph\AntiStaph", replace


import excel "E:\users\amy.mason\Staph\Staph_drugslist_nicola_update.xlsx", sheet("Sheet1") cellrange(A1:J218) firstrow clear
drop C I J
gen antistaph=0
replace antistaph=1 if  MSSA=="A" | MRSA=="A" | MSSA=="Top A" | MRSA=="Top A"
keep Antimicrobial MSSA MRSA antistaph
save  "E:\users\amy.mason\Staph\AntiStaph_update", replace





 

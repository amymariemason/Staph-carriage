
/*####################################*/
/* Creates new antibiotic factors dataset  (Antimicrobials_marker)  for each time point */
/*####################################*/



/*Pull in excel extract from Access (taken 03/06/2014) */

import excel "E:\users\amy.mason\Staph\StaphCarriage_Antibiotics.xlsx", sheet("StaphCarriage_Antibiotics") firstrow clear
 /* drop empty catagories */
 drop if Antimicrobial=="" & DateStarted==. & DateEnded==.
 rename   ParticipantID patid
 rename  FollowupMonth timepoint
 
 drop  Confirmed 

/* get rid of irrelevant patients */

drop if inlist(patid,1101,1102,801,1401)==1
drop if patid > 2122
drop if patid > 1401 & patid <2000
drop if timepoint==999
drop if timepoint>48


/*work out if antibiotics taken */ 
replace Antimicrobial="Unknown" if Antimicrobial=="? - could not get in contact with patient to ask"

merge m:1 Antimicrobial using "E:\users\amy.mason\Staph\AntiStaph_update", update
/* spelling problem, drop */
drop if _merge==2
assert _merge==3
drop _merge

/*decide what to do with blanks */
replace antistaph=. if Antimicrobial=="Unknown" |Antimicrobial=="Unknown antibiotic" 

/* for the moment, consider only things active against staph */
*keep if antistaph==1

/* check for duplicates on patid/timepoint */
*duplicates tag patid timepoint, gen(dup_flag3)
/* duplicates, clearly people taking multiple meds; reshape to wide */

/* drop SwabID duplicated */
bysort patid timepoint: gen Whoops=1 if SwabID!=SwabID[_n-1] & _n>1
drop if Whoops==1
drop Whoops

*drop MSSA MRSA
drop antistaph
sort patid timepoint Antimicrobial
by patid timepoint: gen marker=_n
reshape wide  AmountTaken MSSA MRSA Antimicrobial DateStarted DateEnded, i(patid timepoint) j(marker)
drop Received 

duplicates tag patid timepoint, gen(dup_flag5)
assert dup_flag5==0
drop dup_flag5

merge 1:m patid timepoint using "E:\users\amy.mason\Staph\DataWithCovariates_v2.dta", update
/* NOTE THIS DOES NOT GIVE _MERGE =3 */


/* all _merge==1 (ie, extraneous from antibiotics data -> late swobs returned, no spa typed yet? */
drop if _merge==1
drop _merge

label variable DateTaken "date swob taken, indicated by patient"
label variable Sent "date swob sent from lab"
label variable Received "date swob received back by lab"
label variable followupneg "was patient negative on first swob"

drop spatype 
save "E:\users\amy.mason\Staph\Danny1", replace




/* fix AppendixFA data to right format (this is the GP records data) */
/* need patid, timepoint, info2 ( type of antimicrobial), date*/

 import excel "E:\users\amy.mason\Staph\AppendixFa2yr.xls", sheet("AppendixFa2yr") clear
 rename A patid
 gen marker2 = 4
 rename B info
  rename C date
 keep patid info date marker2
 save "E:\users\amy.mason\Staph\Danny2", replace
 /* include GP start data */
 import excel "E:\users\amy.mason\Staph\AppendixFa.xls", sheet("AppendixFa") clear
 rename A patid
 gen marker2 = 5
 rename B info
 rename C date
 keep patid info date marker2
 append using "E:\users\amy.mason\Staph\Danny2"
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

*keep if antistaph==1
rename Antimicrobial info
keep patid info date marker2
  
save "E:\users\amy.mason\Staph\Danny3", replace
 
/* create my own # days between antibiotic started and swob received marker */

use "E:\users\amy.mason\Staph\Danny1", clear

keep SwabID State spatype* patid timepoint BestDate Antimicrobial* DateStarted* DateEnded* Amount* MSSA* MRSA*
reshape long
drop if marker>1 & Antimicrobial==""
*keep patid timepoint BestDate Antimicrobial* DateStarted* DateEnded* marker

rename BestDate date1
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

 
append using "E:\users\amy.mason\Staph\Danny3"
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



/* find those Danny wants*/
*want ppl who go, pos anti pos pos
* first get rid of duplicate anti temporarily
sort patid marker2 day_no
by patid marker2:gen swobno=_n if marker2==1
sort patid day_no
gen lastswobno=swobno
sort patid day_no
by patid:replace lastswobno=lastswobno[_n-1] if lastswobno==. &_n>1 

sort patid lastswobno marker2 day_no
by patid lastswobno marker2: gen extra=1 if marker2!=1 &_n>1


sort extra patid day_no
by extra patid: gen Dannywant=1 if marker2[_n]==1 & marker2[_n-1]==1 &marker2[_n-2]!=1 & marker2[_n-3]==1 &_n>3

by extra patid: gen DannyREALLYwant=1 if State[_n]==1 & State[_n-1]==1 & State[_n-3]==1 & Dannywant==1 &_n>3

by extra patid: gen Dannyzigazig=1 if spatypeid1[_n]==spatypeid1[_n-1]& spatypeid1[_n-1]==spatypeid1[_n-3] & DannyREALLYwant==1 &_n>3

sort extra patid marker2 day_no
gen Dannyzig2=Dannyzigazig
by extra patid marker2: replace Dannyzig2=1 if (Dannyzigazig[_n+1]==1| Dannyzigazig[_n+2]==1) & marker2==1


*keep all relevant antibiotic data
sort patid lastswobno marker2
by patid lastswobno: replace Dannyzig2=1 if Dannyzig2[_n-1]==1 &_n>1

drop if Dannyzig2!=1
drop Danny*

label variable MSSA "antibiotic active against MSSA"
label variable MRSA "antibiotic active against MSRA"

drop  marker extra 

label variable info "antibiotic name if relevant"
label variable date "date antibiotics started/swab taken"
label variable day_no "number of days since first swab"
label variable swobno "chronological order of swabs taken"
label variable lastswobno "last swab taken befor antibiotic (swabs give current swabno)"
label variable State "positive for staph?" 
label variable Start "date of first swab"
label variable timepoint "order of swabs by sent out date"

label define antistaph 0 "sometimes active" 1 "always resistant" 2 "no clear activity" 3 "topical and sometimes active"	
gen MSSA2=.
replace MSSA2=0 if MSSA=="A"
replace MSSA2=1 if MSSA=="R"
replace MSSA2=2 if MSSA=="N"
replace MSSA2=3 if MSSA=="Top A"
label values MSSA2 antistaph

gen MRSA2=.
replace MRSA2=0 if MRSA=="A"
replace MRSA2=1 if MRSA=="R"
replace MRSA2=2 if MRSA=="N"
replace MRSA2=3 if MRSA=="Top A"
label values MRSA2 antistaph

drop MRSA MSSA
rename MRSA2 MRSA
rename MSSA2 MSSA


save "E:\users\amy.mason\Staph\Danny_data", replace

export delimited using "E:\users\amy.mason\Staph\Danny_data_staph", quote replace

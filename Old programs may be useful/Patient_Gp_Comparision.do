/* compare GP and patient reported medication */

/* correct spelling in patient reported */

/* sort out antibiotic data spelling errors */
import excel "E:\users\amy.mason\Staph\Staph_drugslist_nicola_update.xlsx", sheet("Sheet1") firstrow clear

 keep  Antimicrobial TrueName

save  "E:\users\amy.mason\Staph\AntiStaph_spelling", replace


import excel "E:\users\amy.mason\Staph\Staph_drugslist_nicola_update.xlsx", sheet("Sheet1") firstrow clear
gen antistaph=0
replace antistaph=1 if  MSSA=="A" | MRSA=="A" | MSSA=="Top A" | MRSA=="Top A"
 keep  TrueName antistaph
duplicates drop TrueName antistaph, force
save  "E:\users\amy.mason\Staph\AntiStaph_Truenamesonly", replace







/* import patient reported antibiotic taking */
import excel "E:\users\amy.mason\Staph\StaphCarriage_Antibiotics.xlsx", sheet("StaphCarriage_Antibiotics") firstrow clear
 /* drop empty catagories */
 drop if Antimicrobial=="" & DateStarted==. & DateEnded==.
 rename   ParticipantID patid
 rename  FollowupMonth timepoint
 
 drop  SwabID spatype  Confirmed AmountTakenPerDay

/* get rid of irrelevant patients */

drop if inlist(patid,1101,1102,801,1401)==1
drop if patid > 2122
drop if patid > 1401 & patid <2000
drop if timepoint==999
drop if timepoint>48


/*work out if antibiotics taken */ 
replace Antimicrobial="Unknown" if Antimicrobial=="? - could not get in contact with patient to ask"

merge m:1 Antimicrobial using "E:\users\amy.mason\Staph\AntiStaph_spelling", update
/* spelling problem, drop */
drop if _merge==2
assert _merge==3
drop _merge
rename DateStarted date
duplicates drop patid TrueName date, force


save "E:\users\amy.mason\Staph\Patient_Gp_Comparision1", replace


/* load up GP reported data */

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
/* spelling problem, drop */
rename info Antimicrobial
merge m:1 Antimicrobial using "E:\users\amy.mason\Staph\AntiStaph_spelling", update
drop if _merge==2
replace TrueName= "Unknown Antibiotic" if _merge==1
replace _merge=3 if _merge==1
assert _merge==3
drop _merge
duplicates drop patid TrueName date, force
keep patid TrueName date
save "E:\users\amy.mason\Staph\Patient_Gp_Comparision2", replace


/* combine GP and patient info data */
/* want to merge on patid, TrueName, date */
use "E:\users\amy.mason\Staph\Patient_Gp_Comparision2",clear
merge 1:m patid TrueName date using  "E:\users\amy.mason\Staph\Patient_Gp_Comparision1", update

/* 125 match out right*/

gen Origin="GP" if _merge==1
replace Origin="Patient" if _merge==2
replace Origin="Agree" if _merge==3
drop if _merge==3

order patid date Origin TrueName
sort patid date


sort patid timepoint 
/* by patid: assert timepoint[1]!=. */
 by patid:gen Summary="Gp data; Patient data missing" if timepoint[1]==.
 
/* investigate GP only data */ 

/*drop if Summary==""
codebook patid
drop _merge

merge m:1 TrueName using "E:\users\amy.mason\Staph\AntiStaph_Truenamesonly", update
drop if _merge==2
assert _merge==3
codebook antistaph
*/

/*  325 unique patids, with 981 observations (545 active against staph). */
 
 
/* what about those that neither agree or are wholly missing -  want to see how many are close (< 2 weeks from each other?) */
 drop if Summary!=""
replace date=Received  if date==. & Origin=="Patient"
 by patid:gen Start=date[1] if timepoint[1]!=.
format Start %d
gen day_no = date-Start 

sort patid day_no


gen round_day=round(day,20)
duplicates tag patid TrueName round_day, gen(dupflag)
codebook dupflag

/* only find ~ 160 matching pairs or more -  still 1000 not matched */

gen round_day50=round(day,50)
duplicates tag patid TrueName round_day50, gen(dupflag50)
codebook dupflag50

/* still 856 not matching*/

gen round_day100=round(day,100)
duplicates tag patid TrueName round_day100, gen(dupflag100)
codebook dupflag100

/* still 781 not matching: 456 from Gp, 325 from Patient: 409 antistaph, of which 256 come from GP*/

merge m:1 TrueName using "E:\users\amy.mason\Staph\AntiStaph_Truenamesonly", update
drop if _merge!=3
table Origin antistaph

************************************************
*inputs.DO
************************************************
* loads the data from the inputs files and creates stata data sets 

* INPUTS: Amy 29_09 Results Query.xlsx,   Amy 29_09 Antimicrobials Query.xlsx, ( from ACCESS DATABASE, will need updating)
*  Confidential Details Query
*Staph_drugslist_nicola_update_mar2016.xlsx,  ( made by Nicki Fawcett, may need to be updated if new drugs reported)
*GPRecordInformation.xlsx, GPRecordInformationAfter2Years.xlsx
* HouseholdMembers.xlsx, PersonalDetails.xlsx
* KYLE_ Underlying illnesses study numbers 18.4.13.xls, 
*OUTPUTS : raw_input , raw_druglist, raw_antibiotics, groups, GP_org, GP_2Y, Household, Personal, Illness, Skin
* all Stata datasets saved in DATASETS

* written by Amy Mason

set li 130

cap log close
log using getdata.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

*********************************************
* Input data
*********************************************

* main dataset'
***UPDATE***
noi di _n(5) _dup(80) "=" _n "Input Results extract" _n _dup(80) "=" 
import excel "E:\users\amy.mason\staph_carriage\Inputs\Amy 29_09 Results Query.xlsx", sheet("Amy_28_06_Results_extract") firstrow clear

***  keep relevent fields
		rename   Swab_SwabID SwabID
		rename   ParticipantID patid
		rename  FollowupMonth timepoint
		format  Received Sent DateTaken %td
		drop TrialS* OurSwabID Expr* AntibioticsForm* 

		
noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
noi di _n " - leaving records (swabs): " _N


compress
save "E:\users\amy.mason\staph_carriage\Datasets\raw_input.dta", replace	

****************************************************************	
noi di _n(5) _dup(80) "=" _n "Antibiotics list" _n _dup(80) "=" 

* antibiotic list created by Dr Nicola Fawcett
* may need update
import excel "E:\users\amy.mason\staph_carriage\Inputs\Staph_drugslist_nicola_update_mar2016.xlsx", sheet("Sheet1") firstrow clear
gen antistaph=0
replace antistaph=1 if  MSSA=="A" | MRSA=="A" | MSSA=="Top A" | MRSA=="Top A"
 keep  Antimicrobial TrueName antistaph
 replace Antimicrobial = lower(Antimicrobial)
noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\raw_druglist", replace


*  antibiotics taken
***UPDATE***
noi di _n(5) _dup(80) "=" _n "Antibiotics patient record" _n _dup(80) "=" 
import excel "E:\users\amy.mason\staph_carriage\Inputs\Amy 29_09 Antimicrobials Query.xlsx", sheet("Amy_28_06_Antimicrobials_Query") firstrow clear
*drop if anti form was blank
 drop if Antimicrobial=="" & DateStarted==. & DateEnded==.
 rename   ParticipantID patid
 rename  FollowupMonth timepoint
* drop irrelevant data 
 drop  spatype  Confirmed Sent  AntibioticsForm Result
 noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\raw_antibiotics", replace


* patient groups/ age/ sex
noi di _n(5) _dup(80) "=" _n "Import Patient group, age, sex" _n _dup(80) "=" 
import excel "E:\users\amy.mason\staph_carriage\Inputs\Amy 28_06 Confidential Details Query.xlsx", sheet("Amy_28_06_Confidential_Details_") firstrow clear
rename   ParticipantID patid
 noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\groups", replace

* GP info
noi di _n(5) _dup(80) "=" _n "GP record" _n _dup(80) "=" 
 import excel "E:\users\amy.mason\staph_carriage\Inputs\GPRecordInformation.xlsx", sheet("GPRecordInformation") firstrow clear
 rename   ParticipantID patid
  noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\GP_org", replace

* GP 2nd Year
noi di _n(5) _dup(80) "=" _n "GP record 2nd Year" _n _dup(80) "=" 
import excel "E:\users\amy.mason\staph_carriage\Inputs\GPRecordInformationAfter2Years.xlsx", sheet("GPRecordInformationAfter2Years") firstrow clear
 rename   ParticipantID patid
  noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\GP_2Y", replace

* Household
noi di _n(5) _dup(80) "=" _n "Household members data" _n _dup(80) "=" 
import excel "E:\users\amy.mason\staph_carriage\Inputs\HouseholdMembers.xlsx", sheet("HouseholdMembers") firstrow clear
 rename   ParticipantID patid
   noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\Household", replace

* patient details
noi di _n(5) _dup(80) "=" _n "Baseline patient details" _n _dup(80) "=" 
import excel "E:\users\amy.mason\staph_carriage\Inputs\PersonalDetails.xlsx", sheet("PersonalDetails") firstrow clear
rename   ParticipantID patid
 noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save  "E:\users\amy.mason\staph_carriage\Datasets\Personal", replace

* intake details (via data from Kyle, from Ruth's original study)
noi di _n(5) _dup(80) "=" _n "Long Term Illness" _n _dup(80) "=" 
 import excel "E:\users\amy.mason\staph_carriage\Inputs\KYLE_ Underlying illnesses study numbers 18.4.13.xls", sheet("Cleaned for analysis") firstrow clear
rename ID patid
drop if patid=="Total"
destring patid, replace
 noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save "E:\users\amy.mason\staph_carriage\Datasets\Illness", replace


* skin details (via data from Kyle)
noi di _n(5) _dup(80) "=" _n "Skin Problems" _n _dup(80) "=" 
import excel "E:\users\amy.mason\staph_carriage\Inputs\KYLE_ Underlying illnesses study numbers 18.4.13.xls", sheet("Cleaned1") firstrow clear
keep ID Skin
rename ID patid
destring patid, replace
 noi di "DROP STRAIGHT DUPLICATES" 
noi bysort *: drop if _n>1
compress
save "E:\users\amy.mason\staph_carriage\Datasets\Skin", replace



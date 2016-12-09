
* add baseline characteristics to dataset

set li 130

cap log close
log using basline.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"
cd E:\users\amy.mason\staph_carriage\Datasets\


use "E:\users\amy.mason\staph_carriage\Datasets\clean_data.dta", clear

* check count
sort patid timepoint
by patid: gen first=(_n==1)
summ first
noi di  " starting with " _N " records from " r(sum) " paticipants" 
* check everyone starts from zero
assert timepoint==0 if first==1
assert timepoint!=0 if first!=1
drop if first!=1
keep patid Sex DateOfBirth BestDate

* sex 
noi di "SEX"
assert inlist(Sex, "Female", "Male")
noi tab Sex ,m

*age
noi di "AGE"
assert DateOfBirth!=.
by patid: gen age = floor((BestDate[1]-DateOfBirth)/ 365.25) 
noi tabstat age, c(s) s(n median iqr min p25 p75 max)

save temp, replace
use temp, clear
********************************************************************************

merge m:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\Personal", update
drop if _merge==2
assert _merge==3

*ethnicity
noi di "ETHNIC"
noi assert Ethnic!=""
noi tab Ethnic 
gen Ethnic_group = "Other"
replace Ethnic_group = "White British/Irish" if inlist(EthnicB, "1a White British", "1b White Irish")
replace Ethnic_group = "Other White" if inlist(EthnicB, "1c Other white background")
noi tab Ethnic*,m

* residence (for use in deciding household)
noi di "residence"
noi tab Residence
gen residence_group = "own home/None of the above" if strpos(Residence,"9")
replace residence_group = "shared home" if strpos(Reside, "6") | strpos(Resid, "7") | strpos(Resid, "8")
replace residence_group = "No response" if residence_group==""
noi tab residence_ Reside, m
* current employment at baseline

noi di "Current Employment at recruitment"
noi assert inlist(CurrentlyEmployed, "No", "Yes")
noi tab CurrentlyEmployed ,m

* Healthcare related employment at baseline

noi di "Healthcare related employment at recruitment"
rename  HeathcareRelatedEmployed HealthcareRelatedEmployed
noi assert inlist( HealthcareRelatedEmployed, "No", "Yes")
noi tab  HealthcareRelatedEmployed ,m

* participation in contact sport 

noi di "Participation in contact sport"
noi assert inlist(SportsActivity, "Yes", "No")
noi tab SportsActivity ,m

* looks after someone with disability or old age

noi di "Looks after anyone with a disability/old age"
noi assert inlist( LookAfterDisability, "Yes", "No")
noi assert inlist( LookAfterOldAge, "Yes", "No")
noi tab LookAfter* 
gen LookAfter = LookAfterDisability
replace LookAfter = "Yes" if LookAfterOldAge=="Yes"
noi tab LookAfter,m

* ever had vasular access
noi di "Ever had vascular access"
noi assert  VascularAccess!=""
noi tab  VascularAccess,m

* ever had catheter
noi di "Ever had Catheter"
noi assert Catheter !=""
noi tab Catheter,m

* inpatient
noi di "inpatient"
noi tab IPEver, m
gen inpatient_days =  BestDate -  DateMostRecentIP
assert inpatient_days>=0
noi tabstat inpatient_days, c(s) s(n median iqr min p25 p75 max)
gen inpatient_summ = "Within 30 days" if inpatient_days<=30
replace inpatient_summ = "> 30 days ago" if inpatient_days> 30 & inpatient_days!=.
replace inpatient_summ = "No" if inpatient_days==.
noi tab inpatient_summ
gen inpatient = IPEver 
replace inpatient = "No" if IPEver=="Not known"

*outpatient
noi di "outpatient"
noi tab OPEver, m
gen outpatient_days =  BestDate -  DateMostRecentOP
assert outpatient_days>=0
noi tabstat outpatient_days, c(s) s(n median iqr min p25 p75 max)
gen outpatient_summ = "Within 30 days" if outpatient_days<=30
replace outpatient_summ = "> 30 days ago" if outpatient_days> 30 & outpatient_days!=.
replace outpatient_summ = "No" if outpatient_days==.
noi tab outpatient_summ
gen outpatient = OPEver 
replace outpatient = "No" if OPEver=="Not known"



keep outpatient_summ inpatient_summ patid residence_group LiveAlone Sex age DateOfBirth Ethnic_group CurrentlyEmployed HealthcareRelatedEmployed SportsActivity LookAfter DIED REMOVEDCONSENT FollowUpNeg VascularAccess Catheter inpatient outpatient

save temp, replace

use temp, clear


***************************************

use "E:\users\amy.mason\staph_carriage\Datasets\patid.dta", clear
merge 1:m patid using "E:\users\amy.mason\staph_carriage\Datasets\Household", update
 drop if _merge==2
 assert inlist(_merge,1,3)
 noi di "people with no household members"
 list patid if _merge==1
 drop if _merge==1 
 * people with no family members i.e. live alone?
keep patid Member
collapse (count) Member, by(patid)
rename MemberID household
label variable household "number in household"
merge 1:1 patid using temp, update
noi di "Number of household members"
noi assert inlist(_merge,2,3)
replace household = 0 if _merge==2
drop _merge
replace household = household +1 
* to account for the participant as well
 noi tab household
 gen household_group = string(household)
 replace household_group = "5+" if household>=5
* add catagory for if in shared housing
 replace household_group = "shared accomodation" if strpos(residence_group, "shared")
  noi tab household household_group, m
 noi tab residence household_group, m

* trust the household numbers set, as otherwise only have a binary variable

merge 1:1 patid using temp, update
assert _merge==3
drop _merge

 save temp, replace
use temp, clear

************************ GP data***********


use "E:\users\amy.mason\staph_carriage\Datasets\minimal.dta", clear
keep if timepoint==0
merge 1:m patid using "E:\users\amy.mason\staph_carriage\Datasets\GP_org", update
 drop if _merge==2
 assert inlist(_merge,3)
drop _merge


 merge 1:1 patid using temp, update
assert _merge==3
drop _merge
* district nurse

noi di "district nurse"
noi tab  DistrictNurseCare, m
* assume if not known -> answer is no, as it should be in records.
* Ruth said: "Missing values assumed as no, as risk factors likely to be recorded in patient records."
gen DistrictNurse_days =  BestDate - DistrictNurseCareDate 
noi tabstat DistrictNurse_days, c(s) s(n median iqr min p25 p75 max)
gen DistrictNurse_summ = "Within 30 days" if DistrictNurse_days<=30
replace DistrictNurse_summ = "> 30 days ago" if DistrictNurse_days> 30 & DistrictNurse_days!=.
replace DistrictNurse_summ = "No" if DistrictNurse_days==.
replace DistrictNurse_summ = "No" if DistrictNurse_days==. 
noi tab DistrictNurse_summ, m
gen districtnurse = DistrictNurseCare
replace districtnurse = "No" if districtnurse=="Not known"
noi tab districtnurse , m

* inpatient
noi di "inpatient - adding outside of ORH appointments"
noi tab InPatientNonORH inpatient_summ , m
gen inpatient_days2 =  BestDate - InPatientNonORHDate
assert inpatient_days2>=0
noi tabstat inpatient_days2, c(s) s(n median iqr min p25 p75 max)
noi replace inpatient_summ = "Within 30 days" if inpatient_days2<=30  
noi replace inpatient_summ = "> 30 days ago" if inpatient_days2> 30 &inpatient_days2!=. & inpatient_summ=="No" 
replace inpatient = "Yes" if inlist(inpatient_summ, "Within 30 days" , "> 30 days ago")
noi tab inpatient_summ, m
noi tab inpatient, m


* outpatient
noi di "outpatient - adding outside of ORH appointments"
noi tab OutPatientNonORH outpatient_summ , m
gen outpatient_days2 =  BestDate - OutPatientNonORHDate
assert outpatient_days2>=0
noi tabstat outpatient_days2, c(s) s(n median iqr min p25 p75 max)
replace outpatient_summ = "Within 30 days" if outpatient_days2<=30 
replace outpatient_summ = "> 30 days ago" if outpatient_days2> 30 &outpatient_days2!=. & outpatient_summ=="No" 
replace outpatient = "Yes" if inlist(outpatient_summ, "Within 30 days" , "> 30 days ago")
noi tab outpatient_summ , m
noi tab outpatient , m

*surgery
noi di "surgery"
noi tab  UndergoneSurgery , m
gen surgery_days =  BestDate - UndergoneSurgeryDate
noi tabstat surgery_days , c(s) s(n median iqr min p25 p75 max)
gen surgery_summ = "Within 30 days" if surgery_days <=30
replace surgery_summ = "> 30 days ago" if surgery_days > 30 & surgery_days!=.
replace surgery_summ = "No" if surgery_days==.
noi tab surgery_summ  , m
gen surgery = UndergoneSurgery
replace surgery = "No" if UndergoneSurgery=="Not known"
noi tab surgery  , m

* GP appointments
noi di "GP appointments"
noi tab  GPAppointment , m
gen GP_days =  BestDate - GPAppointmentDate
noi tabstat GP_days , c(s) s(n median iqr min p25 p75 max)
gen GP_summ = "Within 30 days" if GP_days <=30
noi replace GP_summ = "> 30 days ago" if GP_days > 30 & GP_days!=.
noi replace GP_summ = "No" if GP_days==.
noi tab GP_summ , m
gen GP = GPAppointment
replace GP = "No" if GPAppointment=="Not known"
noi tab GP , m

* merge back into larger set

drop InPatientNonORH InPatientNonORHDate OutPatientNonORH OutPatientNonORHDate GPAppointment GPAppointmentDate PracticeNurseAppointment PracticeNurseAppointmentDate DistrictNurseCare DistrictNurseCareDate LongTermIllness UndergoneChemotherapy UndergoneChemotherapyDate UndergoneChemotherapyApprox UndergoneRenalDialysis UndergoneRenalDialysisDate UndergoneRenalDialysisApprox UndergoneSurgery UndergoneSurgeryDate UndergoneSurgeryApprox UndergoneVascularAccess UndergoneVascularAccessDate UndergoneInsertionUrinaryCatheti Y UnderongePrescriptionOralSteroid AA ReceivedAntimicrobials ReceivedAntimicrobialsDate ReceivedAntimicrobialsHospital MRSAIsolatedPreviously MRSAIsolatedPreviouslyDate MRSAIsolatedPreviouslySampleType MSSAIsolatedPreviously MSSAIsolatedPreviouslyDate MSSAIsolatedPreviouslySampleType Comments SkinBreaks SkinBreakDetails VascAccess SourceOfInfection MainDiganosis Smoker SmokerYear SmokerMonth Numberofcigarettesperday V1Asthma V2Eczema V3Hayfever V4Surgeryinpastmonth V5Dateofsurgery V6Vaccinationinpastmonth V7Dateofvaccination V8Hospitalinpatientinpastmo V9Dateofinpatient V10Flulikeillnessinpastmon V11Dateoffluillness V12Skininfectioninpastmonth V13Dateofskininfection V14Antibioticsinpastmonth V15Dateofantibiotics V16Receivedchildhoodvaccines V17PreviousSaureusinfection V18Healthcareworkerwithcurre

save "E:\users\amy.mason\staph_carriage\Datasets\baseline_data", replace


******************************************
*skin

use "E:\users\amy.mason\staph_carriage\Datasets\baseline_data", clear
keep patid BestDate
noi di "Skin"
merge 1:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\Skin", update
drop if _merge==2
assert _merge==3
drop _merge



drop if Skin==""
summ patid
noi di r(N) " participants reported skin problems prior to start of study"

gen datestart= strpos(Skin, ".")
* deal with year only dates first
gen yearstart=strpos(Skin, " ") if datestart==0
gen year = substr(Skin, yearstart+1,.)
replace year="1982" if patid ==42
destring year, replace
gen skindate = mdy(01,01,year)
format skindate %td
drop year yearstart


* deal with combined date
gen datestart2= datestart-2 if datestart!=0
replace datestart2=1 if datestart2==0
gen sub = substr(Skin, datestart2,.) if datestart!=0
assert sub!="" if skindate==.
* remove leading spaces
gen spacecheck = strpos(sub, " ")
replace sub = substr(sub, 2, .) if spacecheck==1
drop spacecheck
gen spacecheck = strpos(sub, " ")
assert spacecheck!=1
drop spacecheck

* extract day
gen dayend = strpos(sub, ".") if skindate==.
assert !inlist(dayend, 0, 1) if skindate==. 
gen day = substr(sub, 1, dayend-1)
replace sub = substr(sub, dayend+1,.)
drop dayend
* extract month
gen monthend = strpos(sub, ".") if skindate==.
assert !inlist(monthend, 0, 1) if skindate==. 
gen month = substr(sub, 1, monthend-1)
replace sub = substr(sub, monthend+1,.)
drop monthend
* extract year
gen length = strlen(sub)
gen year = sub if length==2
replace sub = "" if length==2

* more complex versions

gen yearend1= strpos(sub, " ")
gen yearend2= strpos(sub, ",")
gen yearend=yearend1 if yearend1!=0
replace yearend = yearend2 if yearend2<yearend1 & yearend2!=0

replace year= substr(sub,1, yearend-1) if year==""
replace sub=substr(sub, yearend+1, .) 


* finish first year 
destring day month year, replace
	* fix year to 4 digits
replace year =2000+year if year<= 16
replace year = 1900+year if year< 100
gen skindate2 = mdy(month,day,year) if year!=.

drop day month year* length datestart* 

* check for second date 

replace sub = subinstr(sub, "psoriasis.", "",.)
* to manage multiple fullstops
gen datestart= strpos(sub, ".")
replace sub="" if datestart==0


gen day = substr(sub, datestart-2, 2) if sub!=""
replace sub = substr(sub, datestart+1,.)
drop datestart
gen datestart= strpos(sub, ".")
gen month = substr(sub, 1, datestart-1) if sub!=""
replace sub = substr(sub, datestart+1,.)
drop datestart
gen datestart= strpos(sub, ",")
gen year = substr(sub, 1, datestart-1)  if sub!=""
replace year = sub if datestart==0
replace sub = "" if strpos(sub, ".")==0
drop datestart

* replace skin date if later


destring day month year, replace
	* fix year to 4 digits
replace year =2000+year if year<= 16
replace year = 1900+year if year< 100
gen skindate3 = mdy(month,day,year) if year!=.

* last one
drop day month year

gen datestart= strpos(sub, ".")
replace sub="" if datestart==0
gen day = substr(sub, datestart-2, 2) if sub!=""
replace sub = substr(sub, datestart+1,.)
drop datestart
gen datestart= strpos(sub, ".")
gen month = substr(sub, 1, datestart-1) if sub!=""
replace sub = substr(sub, datestart+1,.)
drop datestart
gen datestart= strpos(sub, ",")
gen year = substr(sub, 1, datestart-1)  if sub!=""
replace year = sub if datestart==0
replace sub = "" if strpos(sub, ".")==0
drop datestart

destring day month year, replace
	* fix year to 4 digits
replace year =2000+year if year<= 16
replace year = 1900+year if year< 100
gen skindate4 = mdy(month,day,year) if year!=. 


* okay now have latest date of skin diagnosis for each patient
keep patid skindate* Best
gen skinday1 = BestDate-skindate
replace skinday1=. if skinday1<0
gen skinday2 = BestDate-skindate2
replace skinday2=. if skinday2<0
gen skinday3 = BestDate-skindate3
replace skinday3=. if skinday3<0
gen skinday4 = BestDate-skindate4
replace skinday4=. if skinday4<0

egen skinday = rowmin(skinday*)

gen skin = "No"
replace skin = "> 30 days" if skinday<.
replace skin = "within 30 days" if skinday<=30
 
noi dis "has had skin treatment within 30 days of recruitment"
noi tab skin

keep patid skin
merge 1:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\baseline_data", update
assert inlist(_merge, 2,3)
replace skin = "Did Not Report" if skin==""
noi dis "has had skin treatment within 30 days of recruitment"
noi tab skin
drop _merge

save "E:\users\amy.mason\staph_carriage\Datasets\baseline_data", replace

***************************************************
* co-morbidities for staph
use "E:\users\amy.mason\staph_carriage\Datasets\baseline_data", clear
keep patid BestDate
noi di "Long Term Illness"
merge 1:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\Illness", update
drop if _merge==2
assert _merge==3
drop _merge

*Ruth said "One hundred and sixty nine patients had one or more long term illnesses 
*that have been associated with either S.aureus carriage or community acquired 
*S. aureus infection: (n=number of patients). type 1 diabetes (5), type 2 diabetes (25), 
*asthma/COPD on inhaled steroids (36), history of cancer (24), history of dermatitis or psoriasis (43), 
*most recent BMI >=30 (102), history of drug misuse (4), dialysis (1), cirrhosis (1). 
*The effect of one of these long-term illnesses was very similar to the effect of the larger group with any long-term illness shown above."

* Type 1 diabetes
noi di "Type 1 disbetes"
noi assert Type1DiabetesYOnInsulin!=.
noi tab Type1DiabetesYOnInsulin

* Type 2 diabetes
noi di "Type 2 disbetes"
noi assert Type2diabetesYOnOralPx!=.
noi tab Type2diabetesYOnOralPx

* Asthma or COPD on inhaled steriods

noi di "Asthma or COPD on inhaled steriods"
noi assert AsthmaCOPDonINh!=.
assert  AsthmaCOPDonINh ==  AsthmaOnInhSteroid +  COPDOnINhaler
noi tab AsthmaCOPDonINh

* History Cancer
noi di "History of Cancer"
noi assert Cancer!=.
noi tab Cancer


* history of dermatitis or psoriasis 
noi di "History of dermatitis or psoriasis"
noi assert HxDermPsoriasis!=.
noi tab HxDermPsoriasis

* most recent BMI >=30 
gen BMIclean = BMIMostrecent
noi replace BMIclean=. if BMIclean==999
noi summ Dialysis if BMIclean==.
noi di r(N) " missing BMI"

noi summ BMIclean if BMIclean!=.
gen BMI30 = (BMIclean>=30 &BMIclean!=.) 
noi tab BMI30, m

* history of drug misuse
noi di "history of drug misuse"
noi assert IDUHx!=.
noi tab IDUHx, m 


* dialysis 
noi di "dialysis" 
noi assert Dialysis!=.
noi tab Dialysis

*cirrhosis

noi di "cirrhosis" 
noi assert Cirrhosis!=.
noi tab Cirrhosis


* all together
noi di "Long Term Illness"
egen LTI = rowmax( Cirrhosis Dialysis IDUHx BMI30  HxDermPsoriasis Cancer AsthmaCOPDonINh Type2diabetesYOnOralPx Type1DiabetesYOnInsulin)
noi assert LTI!=.
noi tab LTI, m

keep patid LTI
merge 1:1 patid using "E:\users\amy.mason\staph_carriage\Datasets\baseline_data",  update
assert _merge==3
drop _merge

drop BestDate timepoint

keep patid Sex age Ethnic_group residence_group CurrentlyEm HealthcareR SportsActivity LookAfter VascularAccess Catheter inpatient inpatient_summ outpatient outpatient_summ LiveAlone Follow household_group districtnurse DistrictNurse_summ skininfection surgery surgery_summ GP GP_sum skin LTI

save "E:\users\amy.mason\staph_carriage\Datasets\baseline_data", replace

cd "E:\users\amy.mason\staph_carriage\Programs"
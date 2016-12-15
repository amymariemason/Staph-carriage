******************
* extract of people who go pos anti and have another pos swab for the same spatype
******************

*************
* based on extract for Danny, start with

/* create my own # days between antibiotic started and swob received marker */

use "E:\users\amy.mason\Staph\Danny1", clear

*keep SwabID State spatype* patid timepoint BestDate Antimicrobial* DateStarted* DateEnded* Amount* MSSA* MRSA*
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



******************************************************************************************
* now I have a set with all results, including antibiotic taking
drop marker

gen antibiotic= info if marker2!=1
gen antimarker=(antibiotic!="")

* pick out the people who do pos then anti

sort patid day_no
by patid: gen Tanyawant=1 if marker2[_n]!=1 & marker2[_n-1]==1  &_n>2 & day_no >1

* now want to find the subset of people who continue to carry the same 
by patid:egen total2 = total(Tanyawant)
by patid:gen total = sum(Tanyawant)

* drop if never take antibiotics
drop if total2==0

*drop swob data if negative - we don't mind gaps

drop if marker2==1& spatypeid1==""

* drop if before first swob

drop if day_no <0

* drop if antibiotic use only at the end

by patid: gen Tanyawant2=1 if marker2[_n]==1 & marker2[_n-1]!=1  &_n>2 

by patid:egen total3 = total(Tanyawant2)

drop if total3==0

* try to pick out the keeping the same spatype people round

gen rightanti =1 if strpos(lower(antib), "cip")
by patid: egen total4 = total(rightanti)
tab patid if total4!=0

***********************


label variable MSSA "antibiotic active against MSSA"
label variable MRSA "antibiotic active against MSRA"


label variable info "antibiotic name if relevant"
label variable date "date antibiotics started/swab taken"
label variable day_no "number of days since first swab"
label variable State "positive for staph?" 
label variable Start "date of first swab"
label variable timepoint "order of swabs by sent out date"

label variable total4 "patients with swabs before/after cipro"



********** save for tanya




export delimited using "E:\users\amy.mason\Staph\Tanya", quote replace

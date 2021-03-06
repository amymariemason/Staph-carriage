************************************************
*anti_types_sept.DO
************************************************
* adds carriage so far,
* makes lots of messy carriage to date graphs, ignore these/ move to a new file.
* creates single record per spatype per patid per timepoint (for analysing loss of new spatype)
* INPUTS:   clean_data3 (from add_anti), antistaph_antibiotics_nooverlap (from antibiotics)
*OUTPUTS : clean_data4 (main set for analysis) , record_per_spa (single record per spatype dataset)
* written by Amy Mason


* creates graph of carriage so far
* creates "record per spatype" dataset

set li 130

cap log close
log using spatypes.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"

************
* data from add_anti
use "E:\users\amy.mason\staph_carriage\Datasets\clean_data3.dta", clear

* split spatypes and add counters 
noi di "split spatypes"
split spatype, parse(/)
gen n_spatype = 0
replace n_spatype= 1 if spatype1!=""
replace n_spatype= 2 if spatype2!=""
replace n_spatype= 3 if spatype3!=""
replace n_spatype= 4 if spatype4!=""
replace n_spatype= 5 if spatype5!=""

noi di "number of spatypes in each swab"
noi tab n_spatype

sort patid timepoint
by patid: gen prev_n_spa= n_spatype[_n-1]
by patid: replace prev_n_spa=n_spatype if _n==1
by patid: egen max_spa = max(n_spatype)
by patid: egen min_spa = min(n_spatype)
by patid: gen count = 1 if _n==1

noi di "max number of spatypes"
noi tab max_spa if count==1,m

noi di "min number of spatypes"
noi tab min_spa if count==1,m 

noi tab max_spa min_spa if count==1,m

* create variables assessing carriage to date
gen pos = (n_spatype>0)
gen neg = (n_spatype<1)
sort patid timepoint
by patid: gen confirmedneg = ( neg[_n]==1 & neg[_n+1]==1) & _n!=_N 
by patid: replace confirmedneg = . if _n==_N
by patid: gen pos_so_far = sum(pos)
by patid: gen neg_so_far = sum(confirmedneg)
assert !(neg_s==0 & pos_s==0 &timepoint!=0)

gen carriage_todate = "always" if neg_s == 0
replace carriage_todate = "never" if pos_s ==0 
replace carriage_todate = "unclear" if neg_s==0& pos_s==0
replace carriage_todate = "varies" if neg_s!=0& pos_s!=0

noi di "carriage to date (unclear = unconfirmed neg at timepoint 0)"
noi tab timepoint carriage_todate, m 

*save carriage to date data for continue.do to analyse

noi save "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", replace

use  "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
gen weight = 1
collapse (count) weight, by(timepoint carriage_todate)
bysort timepoint: egen total = sum(weight)
reshape wide weight, i(timepoint) j(carriage) string
* replace blanks with zeros
replace weighta = 0 if weighta==.
replace weightn = 0 if weightn==.
replace weightu = 0 if weightu==.
replace weightv = 0 if weightv==.

* plot
gen sum1 = weightalways + weightnever + weightvaries
gen sum2 = weightnever + weightvaries


#delimit ;
twoway area total timepoint || area sum1 timepoint || area sum2 timepoint ||area weightnever timepoint
,title("Count of carriage types")
legend(label (1 "Undefined") label (2 "Always Carry") label(3 "Carriage varies") label(4 "Never Carry") );
#delimit cr
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\carriage_type.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\carriage_type.tif", replace




* add missing due to not having had the chance to send swabs back yet
noi di "missing due to lack of opportunity"

use  "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
keep patid timepoint BestDate carriage_todate
* everyone's 76th timeperiod has passed, allowing for month grace period of processing. so for those who returned their 78th swab, should be updated to timepoint 86 (last point on record)
sort patid timepoint
by patid: gen last= timepoint[_N] if _n==_N

by patid: gen seventysix_Date = BestDate[1]+ 76*30.44
format seventysix %td
assert seventysix < d(28/07/2016)
drop seventysix

* no-one who hands in 76/74/72 AND has a 78 date after end of may, has not already handed in 78 
by patid: gen seventyeight_Date = BestDate[1]+ 78*30.44
format seventy %td
gen nextnotyet = 1 if seventy>= d(28/07/2016) & inlist(last, 76, 74, 72)
assert next==.
drop seventy next 

*80
by patid: gen eighty_Date = BestDate[1]+ 80*30.44
format eighty %td
gen nextnotyet = 1 if eighty_Date>= d(29/07/2016) & inlist(last, 78, 76, 74)
assert next==.
drop eighty next last

* start of missing: 40 missing
sort patid timepoint
by patid: gen last= timepoint[_N] if _n==_N
by patid: gen eightytwo_Date = BestDate[1]+ 82*30.44
format eighty %td
gen nextnotyet = 1 if eighty>= d(29/07/2016) & inlist(last, 80, 78, 76)
expand next+1, gen(copy)
replace timepoint=82 if copy==1
replace carriage_todate = "stilltocome" if copy==1
drop copy eighty next last

* repeat for 84: 41 missing
sort patid timepoint
by patid: gen last= timepoint[_N] if _n==_N
by patid: gen eightyfour_Date = BestDate[1]+ 84*30.44
format eighty %td
gen nextnotyet = 1 if eighty>= d(28/07/2016) & inlist(last, 82, 80, 78)
expand next+1, gen(copy)
replace timepoint=84 if copy==1
replace carriage_todate = "stilltocome" if copy==1
drop copy eighty next last

* repeat for 86: 47 missing

sort patid timepoint
by patid: gen last= timepoint[_N] if _n==_N
by patid: gen eightysix_Date = BestDate[1]+ 86*30.44
format eighty %td
gen nextnotyet = 1 if eighty>= d(28/07/2016) & inlist(last, 84, 82, 80)
expand next+1, gen(copy)
replace timepoint=86 if copy==1
replace carriage_todate = "stilltocome" if copy==1
drop copy eighty next last

* repeat for 88: 47 missing

sort patid timepoint
by patid: gen last= timepoint[_N] if _n==_N
by patid: gen eighty8_Date = BestDate[1]+ 88*30.44
format eighty %td
gen nextnotyet = 1 if eighty>= d(28/07/2016) & inlist(last, 84, 82, 86)
expand next+1, gen(copy)
replace timepoint=88 if copy==1
replace carriage_todate = "stilltocome" if copy==1
drop copy eighty next last


* repeat for 90: 47 missing

sort patid timepoint
by patid: gen last= timepoint[_N] if _n==_N
by patid: gen eighty90_Date = BestDate[1]+ 90*30.44
format eighty %td
gen nextnotyet = 1 if eighty>= d(28/07/2016) & inlist(last, 84, 88, 86)
expand next+1, gen(copy)
replace timepoint=90 if copy==1
replace carriage_todate = "stilltocome" if copy==1
drop copy eighty next last


* repeat graph above 
gen weight = 1
collapse (count) weight, by(timepoint carriage_todate)
bysort timepoint: egen total = sum(weight)
reshape wide weight, i(timepoint) j(carriage) string
* replace blanks with zeros
replace weighta = 0 if weighta==.
replace weightn = 0 if weightn==.
replace weights = 0 if weights==.
replace weightu = 0 if weightu==.
replace weightv = 0 if weightv==.

* plot
gen sum1 = weightalways + weightnever + weightvaries + weightunclear
gen sum2 =  weightalways + weightnever + weightvaries 
gen sum3 = weightnever + weightvaries 

#delimit ;
twoway area total timepoint || area sum1 timepoint || area sum2 timepoint || area sum3 timepoint ||area weightnever timepoint
,title("Count of carriage types")
legend(label(1 "Not yet occured") label(2 "Undefined") label(3 "Always Carry") label(4 "Carriage varies") label(5 "Never Carry") );
#delimit cr
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\carriage_type_timecensor.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\carriage_type_timecensor.tif", replace





* WEIGHT BY DROPOUTS


noi di "Weigh by starting proportion of carriage/ no carriage"
use  "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
bysort timepoint FollowUpNeg: gen currentsize = _N
bysort FollowUp: gen startsize = currentsize[1]
bysort timepoint: gen currenttotal = _N
noi tab timepoint FollowU
gen weight = startsize/currentsize
keep patid timepoint carriage_todate weight currenttotal
collapse (sum) weight (mean) currenttotal, by(timepoint carriage_todate)
bysort timepoint: egen total = sum(weight)
reshape wide weight, i(timepoint) j(carriage) string
* replace blanks with zeros
replace weighta = 0 if weighta==.
replace weightn = 0 if weightn==.
replace weightu = 0 if weightu==.
replace weightv = 0 if weightv==.

* plot
gen sum1 = weightalways + weightnever + weightvaries
gen sum2 = weightnever + weightvaries


#delimit ;
twoway area total timepoint || area sum1 timepoint || area sum2 timepoint ||area weightnever timepoint
,title("Weighted proportion of carriage types ")
legend(label (1 "Undefined") label (2 "Always Carry") label(3 "Carriage varies") label(4 "Never Carry") );
#delimit cr
graph save Graph "E:\users\amy.mason\staph_carriage\Graphs\weight_carriage_type.gph", replace
graph export "E:\users\amy.mason\staph_carriage\Graphs\weight_carriage_type.eps", as(eps) preview(off) replace






************* breakdown into carriage per spatype
* create masterlist of who carries what spatypes
use  "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear 
keep patid timepoint spatype* 
drop spatype
reshape long spatype, i(patid timepoint) j(count)
drop if spatype==""
keep patid spatype
duplicates drop
noi display "number of spatypes seen in each patid"
bysort patid: gen count = _N if _n==1
noi tab count
rename spatype this_spa
drop count
by patid: gen spacount = _n
noi save allspa, replace



* create unique carriage records for each patid-spatype combination ("record per spatype")

use  "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", clear
keep patid timepoint spatype* 
drop  spatype1 spatype2 spatype3 spatype4 spatype5
expand 9
bysort patid timepoint: gen spacount = _n
merge m:1 patid spacount using allspa, update
drop if _merge==1 & spacount>1
* this drops the extra records created in the expand 9
assert spatype=="" if _merge==1
* these are the people who never carry
drop _merge

* assess carriage, gain, confirmed loss
gen carriage_this_spa = strpos(spatype, this_spa)
gen pos = carriage >0
gen neg = carriage ==0
sort patid spacount timepoint
by patid spacount: gen this_confirmed_loss = ( neg[_n]==1 & neg[_n+1]==1 & pos[_n-1]==1 ) & _n!=_N & _n!=1 
by patid spacount: replace this_confirmed_loss = . if _n==_N | _n==1

by patid spacount: gen this_gain = ( pos[_n]==1 & neg[_n-1]==1 & neg[_n-2]==1 ) & _n>2
by patid spacount: replace this_gain = . if _n<=2

keep patid timepoint spacount this_spa carriage_this_spa this*

merge m:1 patid timepoint using "E:\users\amy.mason\staph_carriage\Datasets\clean_data4.dta", update
assert _merge==3
drop _merge
noi save "E:\users\amy.mason\staph_carriage\Datasets\record_per_spa.dta", replace


***********************************
* fix timepoint
***********************************
* divide days by 30 ~ month len

use "E:\users\amy.mason\Staph\DataWithNewBurp2_v2", clear

gen month_no=day_no/30

gen approx_timepoint=0
replace approx_timepoint=1 if month_no> 0.5 & month_no<=1.5
replace approx_timepoint=2 if month_no> 1.5 & month_no<=3
replace approx_timepoint=4 if month_no> 3 & month_no<=5
replace approx_timepoint=6 if month_no> 5 & month_no<=7
replace approx_timepoint=8 if month_no> 7 & month_no<=9
replace approx_timepoint=10 if month_no> 9 & month_no<=11
replace approx_timepoint=12 if month_no> 11 & month_no<=13
replace approx_timepoint=14 if month_no> 13 & month_no<=15
replace approx_timepoint=16 if month_no> 15 & month_no<=17
replace approx_timepoint=18 if month_no> 17 & month_no<=19
replace approx_timepoint=20 if month_no> 19 & month_no<=21
replace approx_timepoint=22 if month_no> 21 & month_no<=23
replace approx_timepoint=24 if month_no> 23 & month_no<=25
replace approx_timepoint=26 if month_no> 25 & month_no<=27
replace approx_timepoint=28 if month_no> 27 & month_no<=29
replace approx_timepoint=30 if month_no> 29 & month_no<=31
replace approx_timepoint=32 if month_no> 31 & month_no<=33
replace approx_timepoint=34 if month_no> 33 & month_no<=35
replace approx_timepoint=36 if month_no> 35 & month_no<=37
replace approx_timepoint=38 if month_no> 37 & month_no<=39
replace approx_timepoint=40 if month_no> 39 & month_no<=41
replace approx_timepoint=42 if month_no> 41 & month_no<=43
replace approx_timepoint=44 if month_no> 43 & month_no<=45
replace approx_timepoint=46 if month_no> 45 & month_no<=47
replace approx_timepoint=48 if month_no> 47 & month_no<=49
replace approx_timepoint=50 if month_no> 49 & month_no<=51
replace approx_timepoint=52 if month_no> 51 & month_no<=53

gen errors=1 if timepoint!=approx_timepoint
*~500 out of 8000 =~ 6%

* does it change where loss events are?


sort patid timepoint
gen byte lossallevent=0
by patid: replace lossallevent=1 if State[_n-2]==1&State[_n]==0&State[_n-1]==0 
gen byte gainevent=0
by patid: replace gainevent=1 if State[_n]==1&State[_n-1]==0&State[_n-2]==0
by patid: replace gainevent=1 if State[_n]==1& _n==1
by patid: replace gainevent=1 if State[_n]+State[_n+1]>0 &_n==1
gen knownaquis=0 
by patid: replace knownaquis=1 if gainevent==1 & _n>2
by patid: replace knownaquis=1 if knownaquis[_n-1]==1



sort patid approx_timepoint
gen byte lossallevent2=0
by patid: replace lossallevent2=1 if State[_n-2]==1&State[_n]==0&State[_n-1]==0 
gen byte gainevent2=0
by patid: replace gainevent2=1 if State[_n]==1&State[_n-1]==0&State[_n-2]==0
by patid: replace gainevent2=1 if State[_n]==1& _n==1
by patid: replace gainevent2=1 if State[_n]+State[_n+1]>0 &_n==1
gen knownaquis2=0 
by patid: replace knownaquis2=1 if gainevent2==1 & _n>2
by patid: replace knownaquis2=1 if knownaquis2[_n-1]==1


/* 
------------------------
lossallev |lossallevent2
ent       |     0      1
----------+-------------
        0 | 8,424     12
        1 |    14    274
------------------------

. table gain*

------------------------
          |  gainevent2 
gainevent |     0      1
----------+-------------
        0 | 8,137      2
        1 |     3    582

okay, agreement mostly correct		
		*/




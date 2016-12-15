/* START AGAIN:
EXAMINE ALL GAPS <30 days and > 90 days for input typos */

/* This file makes the dataset used in equilibruim graph. Note that at one point 
the data is exported to R, then then back into Stata in order to add BURP distances
to the final data file. If the data is updated, that will need to be rerun halfway
through this file in order to update BURP data */


/* Creates 1) DatawithCovariates: combining swob data with baseline and antibiotic (Ruth) info, from files supplied by Sarah */
/* 2) Antibiotic marker: Using extracts from Access, made my own antibiotic marker */
/* 3) DatawithAntiCov: combo of the two above */
/* 4) DatawithNewBurp2: combining above with BURP data */


/* fixez date confusion later */

/* investigate most accurate date of swob */
/* extract of relevant dates from swob database */

import excel "E:\users\amy.mason\Staph\Results_apr2016.xlsx", sheet("Amy_Results_extract") firstrow clear
* keep relevent fields
rename   Swab_SwabID SwabID
rename   ParticipantID patid
 rename  FollowupMonth timepoint
 format  Received Sent DateTaken %td
 
drop TrialS* OurSwabID Expr* AntibioticsForm* 


 /* drop patids not in this study */
  drop if patid > 2122
drop if patid > 1401 & patid <2000
drop if inlist(patid,1101,1102,801,1401)==1
 
* remove patids that only returned single swab
sort patid
by patid: drop if _N==1

* duplicate numbers

duplicates tag patid timepoint, gen (multiple)
* remove duplicated 
rename timepoint org_timepoint
gen timepoint= org_timepoint

*patid 59 has two 30s, a month apart  - dropping one makes no different to gain/ change/ loss of spa type
drop if SwabID==8610

* cluster of timepoints sent to zero that should be 50 in 2014
gen year= year(Sent)
replace timepoint=50 if year==2014 & timepoint==0

* create marker of how "accurate" to months after first swab timepoint is
sort patid time
by patid: gen days_since_first=DateTaken-DateTaken[1]
by patid: replace days_since_first=DateTaken-Sent[1] if days==.
by patid: replace days_since_first=Sent-Sent[1] if days==.
 
gen timeperiod_since_first = days/(timepoint*30.44) if timepoint!=0
replace timeper=1 if timeper==. & timepoint==0
 


* check again:
drop multiple
duplicates tag patid timepoint, gen (multiple)

* patid 366, 374, 451, 479, 671, 1000,
* 1284, 1364, 1366, 1374, 1385, 2043  
* has duplicated timepoints, < 1 month apart, with no change of spa type from previous to next.
* decision: remove these points from system, keeping one closest to ideal swab day for that timepoint
drop if inlist(SwabID, 8617, 8298, 9169, 7917, 11638, 2865)

drop if inlist(SwabID, 10210, 5261, 8611, 8762, 3329)   

*  1219: two 22 swabs, both same spa type. 
* pattern goes: 20 = no growth, 22 = A, 24=A
* keep earlier swab 
drop if inlist(SwabID, 8616)

* 2043: two 26 swabs: 24= neg, 26 = both neg, 28 = pos
*keep closer to ideal point ( < week apart)
drop if inlist(SwabID, 10883)

* patid 1367 - two swabs at timepoint 10, difference in spatypes called. (eg. pattern goes (ab) _ (a) and the duplicates are (ab) and (a) with (a) taken 1 month after (ab)
*keep one with more spatypes which is closer to midpoint of previous twoo. 
drop if inlist(SwabID, 5560)

* result says "Swab number recorded in error"
drop if inlist(SwabID, 13857)

* patid 2080 -  two different final timepoints,
* one pos one neg  - choose one with more spa types, as otherwise confirms neg when we know there is carriage in between
drop if inlist(SwabID, 9270)

* patid 2094 - 
* two timepoints 16, out of order with timepoint 18 (all no result)
* 14= jan, 16= mar/ 16=may, 18= apr, 20 = june
* all no carriage; drop the out of place 16
drop if inlist(SwabID, 7607)



* drop swabs that were sent but not returned
drop if Received==. & Result==""

* check again 
drop multiple
duplicates tag patid timepoint, gen (multiple)
assert multiple==0
drop multiple



* create BestDate = best guess at what date swab was taken by,

gen BestDate=DateTaken
replace BestDate=Received if BestDate==.
replace BestDate=Sent if BestDate==.
format BestDate %td
assert BestDate!=.

/* sanity check - are the timepoints agreeing with date order */
sort patid BestDate
by patid: gen int problem=0 if timepoint[_n-1]<=timepoint[_n] & _n>1
replace problem=0 if timepoint==0
replace problem=1 if problem==.

* okay: 45 problems, where timepoints and recieved dates conflict;
* has this created duplicates by date?

duplicates tag patid BestDate, gen (multiple)
* there are 2 patids with duplicates that look like misentered dates
replace BestDate= Received  if patid==739 & timepoint==2
replace BestDate = Received if patid==1400 & timepoint==34
* others all appear to be due to patients sending back two swabs taken simultaneous - keep lastest sent only
* 4, 384, 479, 926
gsort patid BestDate -timepoint
by patid BestDate: drop if _n>1
drop multiple


* check for ordering problem again
drop problem 
sort patid BestDate
by patid: gen int problem=0 if timepoint[_n-1]<=timepoint[_n] & _n>1
replace problem=0 if timepoint==0
replace problem=1 if problem==.

* recalculate average difference:
* create marker of how "accurate" to months after first swab timepoint is
sort patid timepo
drop days_since timeper
by patid: gen days_since_first=BestDate-BestDate[1]
gen timeperiod_since_first = days/(timepoint*30.44) if timepoint!=0
replace timeper=1 if timeper==. & timepoint==0
 
sort patid Best

* 42 remain:
* date taken not between sent and received:

*data entry problem (one date utterly implausible given other two : eg dec2012 jan 2012 jan2013 as (sent, taken, received) 

* patid 9, 97, 479, 1294, 16, 332 
replace BestDate=Sent if inlist(SwabID, 2309)
replace BestDate=Received if inlist(SwabID, 6277, 161, 11640, 3648, 11947, 8519)
*patid:  407, 620, 678, 688
replace BestDate=Received if inlist(SwabID, 9880, 1240, 768, 906)
* patid:1207, 1254, 1218, 2082
replace BestDate=Received if inlist(SwabID, 10696, 12400, 13640, 13459)
* patid 1356, 1312, 1377, 1375
replace BestDate=Received if inlist(SwabID, 4656, 12245, 12898, 13614)  
* patid 1349, 1332, 1244
replace BestDate=Received if inlist(SwabID, 12554, 13793)
replace BestDate= d(03feb2015) if SwabID==13812


* two swabs taken out of order, no difference in spa type
* returned or taken within 10 days of each other: drop swab further from ideal time
* patid: 97, 108, 965, 1359, 2033, 2055 
drop if inlist(SwabID, 2358, 368, 5930, 2702, 8372, 11834)
*patid: 2082, 2102, 1354 (x2), 97
drop if inlist(SwabID, 9810, 6722, 12009, 12835, 2358)
*patid: 420, 407, 1255, 1218
drop if inlist(SwabID, 13575, 13693, 11450, 13639 )
*patid: 1295, 1244
drop if inlist(SwabID,13945, 13666)


* one taken between two correctly timed adjacent swabs (no change)
* drop central swab
*patid: 10, 1285, 1309 
drop if inlist(SwabID, 5707, 2152, 12702) 

* swab numbers more appropietely swapping (no change)
*ie. sent back more than 10 days after the previous AND
*otherwise there is a gap greater than 2 months between swabs
* patid: 1303
replace timepoint=38 if SwabID==12772
replace timepoint=40 if SwabID==12698
*patid: 1395
replace timepoint=60 if SwabID==13729
replace timepoint=58 if SwabID==13784
* patid 2016
replace timepoint=18 if SwabID==6725
replace timepoint=16 if SwabID==7277
* patid: 420
replace timepoint=30 if SwabID==8959
replace timepoint=28 if SwabID==8519


* time much closer to another timepoint (which is missing)
*patid: 2082
replace timepoint=32 if SwabID==11163
* patid 1092
replace timepoint=4 if SwabID==1507


* two swabs within week of each other, different results
* patid 479: two swabs within 7 days of each other, growing two different spa types
* combine into single record for closest time period
replace spatype= "t012/t7154" if inlist(SwabID, 10769)
drop if inlist(SwabID, 9587)


**************
* check ordering again 
drop problem 
sort patid BestDate
by patid: gen int problem=0 if timepoint[_n-1]<=timepoint[_n] & _n>1
replace problem=0 if timepoint==0
replace problem=1 if problem==.
assert problem==0
* no ordering problems left
drop problem*


***************

* check BestDate sensible?
gen sensible=(Sent<=BestDate)
replace sensible=0 if Received < BestDate
replace sensible=0 if Sent> Received
gen sens_prob = ""
replace sens_prob= "Received" if sensible==0 & Sent< BestDate & (BestDate-Sent<30) 
replace sens_prob = "Sent" if sensible==0 & BestDate< Received &  (Received-BestDate <30) 
replace sens_prob = "BestDate" if sensible==0 & Sent<Received & (Received-Sent)<30 
replace sens_prob = "Other" if sensible==0 & sens_prob ==""

* look at those where Received is a problem (8)
* 10, 110, 424,  1259, 1291, 1307
* all of these look like data entry problems on the Received date
* CONCLUSION: leave as DateTaken
* 1244: data error on received date 
replace BestDate=Sent if SwabID==13812

* look at "Sent" (15)
*: looks like data error ( other two dates agree, and fit with timepoint
*  102, 450, 451, 454, 1215, 1303, 1309, 1311, 1312, 1315, 1316, 
* 1320, 1328, 2055, 2071
*CONCLUSION: leave as DateTaken

* look at "DateTaken" (98)
* Sent/Received dates are sensible
* patid: 51, 60, 138, 177, 302, 332, 366,  369, 412 (x4), 416, 418
* 424 (x2), 445, 450 (x2), 454 (x2), 457, 471, 631, 686, 698, 770
* 993, 1000, 1005, 1024, 1045, 1083, 1100, 1204, 1209, 1212, 1215
* 1218, 1219, 1223, 1229, 1231 (x2), 1249, 1251, 1281, 1284, 1303, 
* 1305 (x3), 1307 (x2), 1316 (x3), 1317, 1318, 1324, 1331 (x2), 1332 (x2)
* 1336, 1338, 1343, 1350, 1354, 1362, 1369, 1372 (x2), 1382 (x2), 
* 1383, 1385, 1386, 1387, 1392, 1393, 1400, 2013, 2037 (x3), 2043
* 2051, 2055, 2056, 2059, 2083, 2107
*CONCLUSION: replace with Received

* Either sent or date taken date is wrong: replace with received
*patid 407
replace BestDate=Received if sens_prob=="BestDate" 


* look at "other" (8)
* Date received appears sensible for most of them
* 1288, 1308, 1328,
*  2066: data entry error on year, keep as Date Taken.

* 354, 374, 433, 1334: data entry error on year datetaken missind, replace as Sent.
replace BestDate=Received if sens_prob=="Other" & patid!=2066
replace BestDate=Sent if sens_prob=="Other" & inlist(patid, 354, 374, 433, 1334)

*checking ordering, there is one new problem created by this:
*patid 1303, 40/38 swabs out of order, greater than 10 days apart
replace timepoint=40 if SwabID==12772
replace timepoint=38 if SwabID==12698

* look at the timepoint=50 swabs

* check ordering again 
sort patid BestDate
by patid: gen int problem=0 if timepoint[_n-1]<=timepoint[_n] & _n>1
replace problem=0 if timepoint==0
replace problem=1 if problem==.
assert problem==0
drop problem 

*************************************************
* Now claim BestDate is best possible guess at when swabs taken 
**************************************************

*Remove swabs missing records
gen MissingSpa = (Result=="" |( Result!="No growth" & spatype==""))

* 86 such samples; 1 from 2009, 1 from 2010, 3 from 2013, 
* 29 multi-pick study from 2014 
* other 18+34 -> not yet typed

*(HAVE SENT LIST TO INDRE, SHE SAYS EARLIER ONES CANNOT BE FOUND)
* drop
drop if MissingSpa==1

assert BestDate!=.
drop sensible sens_pro days_ timeper

* look at histogram of gaps

* create marker of how "accurate" to months after first swab timepoint is
sort patid BestDate
* # days since first swab taken
by patid: gen days_since_first=BestDate-BestDate[1]
* how close the swab is to the centre of ideal timepoint (1= perfect)
gen timeperiod_since_first = days/(timepoint*30.44) if timepoint!=0
replace timeper=1 if timeper==. & timepoint==0
* spacing between two swabs
by patid:gen int Spacing=BestDate[_n]-BestDate[_n-1] if _n>1
by patid: gen timediff = timepoint[_n] - timepoint[_n-1] if _n>1
gen Spacing2 = Spacing/ timediff*2


* what if we created a new timepoint based on days since first swab
gen ideal_timepoint = days/(30.44) if timepoint!=0
replace ideal= 0 if  timepoint==0

gen ideal_diff = ideal_t - timepo

gen ideal_round = round(ideal_time, 2)
replace ideal_round=1 if timepoint==1 & ideal_diff<0.5

* 464 entries where the ideal differs from the current:

*Gap and mistimed swab -> relabel swab (e.g. swab 10 missing, swab 12 present, but closer to timepoint 10)
*checked: 10, 51, 90, 152
replace timepoint=ideal_round if inlist(SwabID, 1942, 12571, 12705, 717)
* 174, 190 (x2) 
replace timepoint=ideal_round if inlist(SwabID, 12694, 788, 350)
* 310, 317, 332, 334 (x2)
replace timepoint=ideal_round if inlist(SwabID, 457, 843, 12792, 13586, 13771)
* 354, 359, 363, 375
replace timepoint=ideal_round if inlist(SwabID, 13590, 13594, 13596, 1129)
* 366 (x6), 374 (x8), 407 (x10)
replace timepoint=ideal_round if inlist(patid , 366, 374, 407)
* 418, 433, 446 (x2)
replace timepoint=ideal_round if inlist(SwabID, 6193, 13592, 4597, 5106, 7287)
* 633, 665, 732, 749, 763, 1016
replace timepoint=ideal_round if inlist(SwabID, 621, 1437, 1887, 1408, 2784, 6568)


* relabeling swab moves to 15-105 days apart (cont. carriage)
*499
replace timepoint=18 if inlist(SwabID, 5582)


* PART OF THE GIANT GAP
*-> fit closest timepoint
* 302, 359, 437, 446
replace timepoint=ideal_round if inlist(SwabID, 13571, 13794, 675 )


*NO CHANGE IN CARRIAGE
*currently labeled swabs are spaced between 15-105 days apart per two months
* -> NO CHANGE
* 25, 37, 132, 185, 412, 420, 433 (x2), 446, 451, 471, 493, 608, 614
* 638, 682, 693, 701, 907, 946, 961

* equidistant between two timepoints

* CHANGE IN SPATYPE
* -> leave as orginal timepoint so as to avoid gaps
*332


* swab< 15 days apart
*BUT NO CHANGE IN CARRIAGE from previous swab 
* -> drop furthest from ideal
* patid: 38, 102, 144, 149, 160, 334, 386, 433  
drop if inlist(SwabID, 535, 203, 268, 7343, 334, 13586, 7181, 12696)
* 446, 665, 774, 931, 984
drop if inlist(SwabID, 853, 1999, 5178, 1254, 3478)

* CHANGE IN CARRIAGE FROM PREVIOUS SWAB:
* patid 932
* only 6 days between swabs (2nd swab on time); not representation of time period before -> drop
drop if inlist(SwabID, 1255)


* swab > 105 days apart
*BUT NO CHANGE IN CARRIAGE
* and still > 15 days from any other swab
* 75, 141, 177, 189, 331, 704, 953


*swab > 1 year late and last returned
*patid =40
drop if inlist(Swab, 892) 


* two swabs close to one timepoint 
*DIFFERENT CARRIAGE



* where it is after intended swab time, but shows continual carriage and dropped in next swab
* -> keep late swab, as clearly dropping happens after it should have been taken
*705, 931

*patid 989: missing timepoint 0
* appears to have continuous carriage
* replace timepoint 0 with timepoint 1
* record is there with no spatype!!!
replace timepoint=0 if inlist(SwabID, 1305)


  	

       1024 |          1        0.24       25.78
       1078 |          1        0.24       26.01
       1092 |          2        0.48       26.49
       1095 |          3        0.72       27.21
       1207 |          1        0.24       27.45
       1208 |          1        0.24       27.68
       1209 |          1        0.24       27.92
       1211 |          2        0.48       28.40
       1212 |          1        0.24       28.64
       1214 |          1        0.24       28.88
       1216 |          1        0.24       29.12
       1217 |          2        0.48       29.59
       1220 |          2        0.48       30.07
       1223 |          3        0.72       30.79
       1226 |          5        1.19       31.98
       1227 |          1        0.24       32.22
       1229 |          1        0.24       32.46
       1231 |          7        1.67       34.13
       1232 |          2        0.48       34.61
       1233 |          3        0.72       35.32
       1236 |          8        1.91       37.23
       1239 |          1        0.24       37.47
       1244 |          1        0.24       37.71
       1245 |          2        0.48       38.19
       1246 |          1        0.24       38.42
       1247 |          2        0.48       38.90
       1251 |          1        0.24       39.14
       1261 |         10        2.39       41.53
       1262 |          4        0.95       42.48
       1265 |          3        0.72       43.20
       1266 |          1        0.24       43.44
       1267 |          1        0.24       43.68
       1271 |          1        0.24       43.91
       1274 |          1        0.24       44.15
       1277 |          7        1.67       45.82
       1281 |          3        0.72       46.54
       1284 |         10        2.39       48.93
       1288 |          2        0.48       49.40
	   
	   
	   
       1290 |          3        0.72       50.12
       1294 |          2        0.48       50.60
       1295 |         10        2.39       52.98
       1302 |          1        0.24       53.22
       1303 |          1        0.24       53.46
       1305 |          1        0.24       53.70
       1306 |          3        0.72       54.42
       1307 |          6        1.43       55.85
       1308 |          2        0.48       56.32
       1310 |          1        0.24       56.56
       1315 |          1        0.24       56.80
       1324 |          2        0.48       57.28
       1328 |         10        2.39       59.67
       1330 |          3        0.72       60.38
       1331 |          2        0.48       60.86
       1332 |          2        0.48       61.34
       1334 |          1        0.24       61.58
       1338 |          2        0.48       62.05
       1345 |          1        0.24       62.29
       1346 |          1        0.24       62.53
       1347 |          1        0.24       62.77
       1350 |          2        0.48       63.25
       1354 |          2        0.48       63.72
       1355 |          1        0.24       63.96
       1356 |          1        0.24       64.20
       1364 |          1        0.24       64.44
       1370 |          2        0.48       64.92
       1372 |          1        0.24       65.16
       1375 |          3        0.72       65.87
       1382 |          1        0.24       66.11
       1384 |          2        0.48       66.59
       1385 |          1        0.24       66.83
       1386 |          1        0.24       67.06
       1389 |          1        0.24       67.30
       1392 |          1        0.24       67.54
       1395 |          4        0.95       68.50
       1396 |          2        0.48       68.97
       1397 |          1        0.24       69.21
       1398 |          1        0.24       69.45
       1399 |          1        0.24       69.69
       1400 |          5        1.19       70.88
       2001 |          1        0.24       71.12
       2003 |          4        0.95       72.08
       2007 |          1        0.24       72.32
       2008 |          1        0.24       72.55
       2011 |          1        0.24       72.79
       2012 |          1        0.24       73.03
       2013 |          1        0.24       73.27
       2014 |          1        0.24       73.51
       2017 |          2        0.48       73.99
       2020 |          2        0.48       74.46
       2021 |          2        0.48       74.94
	   
	   
       2022 |          3        0.72       75.66
       2023 |          1        0.24       75.89
       2025 |          2        0.48       76.37
       2030 |          2        0.48       76.85
       2032 |          1        0.24       77.09
       2040 |          1        0.24       77.33
       2043 |          2        0.48       77.80
       2044 |          3        0.72       78.52
       2045 |          2        0.48       79.00
       2046 |          3        0.72       79.71
       2047 |          1        0.24       79.95
       2049 |          2        0.48       80.43
       2051 |          2        0.48       80.91
       2052 |          2        0.48       81.38
       2055 |         11        2.63       84.01
       2056 |          1        0.24       84.25
       2057 |          2        0.48       84.73
       2058 |          1        0.24       84.96
       2060 |          1        0.24       85.20
       2066 |          2        0.48       85.68
       2067 |          2        0.48       86.16
       2069 |          1        0.24       86.40
       2077 |          1        0.24       86.63
       2079 |          2        0.48       87.11
       2080 |          3        0.72       87.83
       2082 |          3        0.72       88.54
       2083 |          6        1.43       89.98
       2084 |          1        0.24       90.21
       2086 |          1        0.24       90.45
       2090 |          2        0.48       90.93
       2091 |          2        0.48       91.41
       2092 |          1        0.24       91.65
       2093 |          2        0.48       92.12
       2094 |          2        0.48       92.60
       2097 |          2        0.48       93.08
       2098 |          1        0.24       93.32
       2100 |          1        0.24       93.56
       2101 |          2        0.48       94.03
       2102 |          2        0.48       94.51
       2103 |          1        0.24       94.75
       2105 |          1        0.24       94.99
       2106 |          2        0.48       95.47
       2109 |          1        0.24       95.70
       2110 |          1        0.24       95.94
       2111 |          1        0.24       96.18
       2112 |          1        0.24       96.42
       2113 |          1        0.24       96.66
       2117 |          3        0.72       97.37
       2118 |          6        1.43       98.81
       2120 |          5        1.19      100.00





histogram Spacing2
histogram timeper
histogram ideal_diff



/* drop people who have only single swob */

sort patid
by patid: drop if _N==1



*********************
*output: 

preserve
keep patid timepoint Received BestDate 

save "E:\users\amy.mason\Staph\BestDate_mar2016", replace
restore

************************************************************
*
****************************************************************

save "E:\users\amy.mason\Staph\staph_results_mar2016", replace

/*####################################*/
/*Creates DatawithCovariates: all swob results for nose swobs, non-hospital patients, with baseline factors added in */
/*####################################*/

use "E:\users\amy.mason\Staph\staph_results_mar2016", clear
/* add State pos/neg growth result */
generate State=1
replace State = 0 if Result =="No growth"
order patid timepoint State

* sort out spatypes

split spatype, p("/")
gen n_spatype=0
replace n_spatype=1 if spatype1!=""
replace n_spatype=2 if spatype2!=""
replace n_spatype=3 if spatype3!=""
replace n_spatype=4 if spatype4!=""
replace n_spatype=5 if spatype5!=""


save "E:\users\amy.mason\Staph\2State_mar2016.dta", replace


* merge with baselines

/* open baseline factor file and relabel*/

use "E:\users\sarahw\small\miller\riskfactors_baseline.dta", clear

renpfix "" baseline_

rename baseline_patid patid

save "E:\users\amy.mason\Staph\baselinefactors.dta", replace

* merge in

use "E:\users\amy.mason\Staph\2State_mar2016.dta", clear
merge m:1 patid using "E:\users\amy.mason\Staph\baselinefactors.dta", update
* remove single sample people dropped earlier
drop if _merge==2
assert _merge==3
drop _merge
********** check multiple timepoints for everyone
bysort patid: assert _N>1

* drop irrelevant data

drop   baseline_ethnicFewCats baseline_nomemberscat baseline_nohccont baseline_sport baseline_lookdis baseline_ipever baseline_dayssinceIPall baseline_disnur baseline_dayssincedisnur baseline_surg baseline_dayssincesurg baseline_opever baseline_dayssinceOPall baseline_gpappt baseline_pracnur baseline_dayssincepracnur baseline_antibi baseline_dayssinceantibi baseline_lti baseline_chemo baseline_rendialy baseline_steroid baseline_skinbreak baseline_vasc baseline_cath baseline_prevMRSA baseline_prevMSSA baseline_dayssincegp

save "E:\users\amy.mason\Staph\DataWithCovariates_mar2016.dta", replace
export delimited using "E:\users\amy.mason\Staph\DataWithCovariates_mar2016.csv", replace


******************************************************************************

/*####################################*/
/* Creates new antibiotic factors dataset  (Antimicrobials_marker)  for each time point */
/*####################################*/

/* create Nicola reference set */

import excel "E:\users\amy.mason\Staph\Staph_drugslist_nicola_update_mar2016.xlsx", sheet("Sheet1") firstrow clear
gen antistaph=0
replace antistaph=1 if  MSSA=="A" | MRSA=="A" | MSSA=="Top A" | MRSA=="Top A"
 keep  Antimicrobial TrueName antistaph
duplicates drop
save  "E:\users\amy.mason\Staph\AntiStaph_mar2016", replace


/*Pull in excel extract from Access (taken 03/06/2014) */

 import excel "E:\users\amy.mason\Staph\Antimicrobials Query_march_2016.xlsx", sheet("Antimicrobials_Query") firstrow clear
*drop if anti form was blank
 drop if Antimicrobial=="" & DateStarted==. & DateEnded==.
 rename   ParticipantID patid
 rename  FollowupMonth timepoint
* drop irrelevant data 
 drop  SwabID spatype  Confirmed 

/* get rid of irrelevant patients */

drop if inlist(patid,1101,1102,801,1401)==1
drop if patid > 2122
drop if patid > 1401 & patid <2000
drop if timepoint==999


/*work out if antibiotics taken */ 
replace Antimicrobial="Unknown" if Antimicrobial=="? - could not get in contact with patient to ask"

merge m:1 Antimicrobial using "E:\users\amy.mason\Staph\AntiStaph_mar2016", update
/* spelling problem, drop */
drop if _merge==2
assert _merge==3
drop _merge

/* for the moment, consider only things active against staph */
keep if antistaph==1

* sort out Date Ended for people who are still taking
gen stilltaking= 1 if strpos(lower(Amount), "still")
replace DateEnded= DateTaken if still==1 & DateEnded==.
replace DateEnded= Received if still ==1 & DateEnded==.
* i.e if they are still taken replace when best guess of when swab occured

* 33 still missing end dates:
* check free text box for extra info
replace DateEnded = DateStarted +4 if patid==22 & timepoint ==12

replace DateEnded = DateStarted if patid ==348 & timepoint ==1

replace DateEnded=DateTaken if patid==482 & DateEnded==.
replace DateStarted = d(01Apr2012) if patid==482 & DateStarted==.

replace DateEnded = DateTaken-8 if patid==989 & timepoint==4
replace DateStarted = DateEnded if patid==989 & timepoint==4

replace DateStarted = d(24Oct2009) if patid==1240 & DateStarted==.
replace DateEnded= DateTaken if patid==1240 & DateEnded==.

replace DateEnded =DateStarted +7 if patid==2039 & timepoint==4

replace DateStarted = d(01Aug2008) if patid==2116 & timepoint==1
replace DateEnded = DateTaken if patid==2116 & timepoint==1


* 366 : OH GODS THIS PERSON: presume taking Ciprofloxacin just before each swab until 60
* checking first two years with GP confirms continuous perscriptions of Cipro
sort patid timepoint
by patid: drop if _n>1 & patid==366 & timepoint<60
replace antistaph=1 if _n>1 & patid==366 & timepoint==1
replace DateEnded= d(14Mar2013) if patid==366 & timepoint==1
replace DateStarted= d(29Mar2007) if patid==366 & timepoint==1


* no extra info - assume drugs ended at point started and v.v.
replace DateEnded =DateStarted if DateEnded==. 
replace DateStarted =DateEnded if DateStarted==. 

* no extra info, but both dates missing:
*Assume taken day before swab
replace DateStarted = DateTaken-1 if DateStarted==. & inlist(patid, 189, 1256, 1314)
replace DateEnded = DateTaken if DateEnded==. & inlist(patid, 189, 1256, 1314)

replace DateStarted = Sent-1 if DateStarted==. & inlist(patid, 2069)
replace DateEnded = Sent if DateEnded==. & inlist(patid, 2069)


* sense check! is Date Ended >= DateStarted

list if DateEnded <DateStarted
replace DateEnded = DateStarted if DateEnded <DateStarted & DateStarted-Received<30 & DateStarted<=Received
* last one has a typo in received (if running with new data, double check this is still sensible)
replace DateEnded = DateStarted if DateEnded <DateStarted  & patid ==1244 & timepoint ==64

assert DateEnded>=DateStarted

***** how to integrate antibiotics with swabs?

/* duplicates, clearly people taking multiple meds; meds also last over months reshape to wide */

duplicates tag patid DateStarted TrueName, gen (multiple)
gsort patid DateStarted TrueName -DateEnded
by patid DateStarted TrueName: drop if _n>1
drop multiple

* consider a day by day antibiotics?


keep patid timepoint TrueName antistaph DateStarted DateEnded

save Anti_temp, replace

* create a record with a record for every day an antibiotic active against staph taken
drop timepoint antistaph 
gen diff = DateEnded-DateStarted +1
assert diff>=0
expand diff
sort patid DateStarted True
by patid DateStarted True: gen newDate = DateStarted +_n -1

keep patid newDate 
duplicates drop

save Anti_manyrecords
* add on swab records

use Anti_manyrecords, clear

rename newDate BestDate
gen antistaph=1
append using "E:\users\amy.mason\Staph\BestDate_mar2016"
replace antistaph=0 if antistaph==.
drop Received
format BestDate %td

gsort patid -BestDate
by patid: replace timepoint = timepoint[_n-1] if timepoint==.

* set of antibiotic results with missing timepoint: these are all the dates extending to the last swab. 
* just drop, don't need results past last swab on record
drop if timepoint==.

* keep only the latest antibiotic taking before each swab
gsort patid timepoint -antistaph
by patid timepoint: drop if _n>1 & antistaph==1

* reshape to ease comparing dates
reshape wide BestDate, i(patid timepoint) j(antistaph)
rename BestDate0 BestDate
rename BestDate1 LastAntiDate

sort patid timepoint
by patid: replace LastAntiDate = Last[_n-1] if Last==.

/* add days since first swab for antibiotics/further swabs */

gsort patid timepoint 
by patid: gen day_no = BestDate-BestDate[1]


* add days since antibiotic last taken 
gen days_since_anti = BestDate - LastAntiDate
gsort patid timepoint
by patid: gen last_anti_day = LastAnti-BestDate[1]
label variable last_anti_day "last antibiotics taken by patient"

************ add markers 
* since last swab indicator
gen prev_anti_swob= (LastAntiDate>BestDate[_n-1] & LastAntiDate!=.)
label variable prev_anti_swob "staph antibiotics taken since last swob"

* 6 month indicator
gen prev_anti_6mon =0
replace prev_anti_6mon =1 if days_since<180 
label variable prev_anti_6mon "staph antibiotics taken last six months"


* tidy up working variables

drop days_since last_anti


save  "E:\users\amy.mason\Staph\AntiStaph_markers", replace


***********
* merge back into other variables 


* add back in when the swabs were taken + other data
merge 1:1 patid timepoint using "E:\users\amy.mason\Staph\DataWithCovariates_mar2016.dta", update
assert _merge==3
drop _merge

save "E:\users\amy.mason\Staph\DataWithAntiCov_v2_mar2016.dta", replace


*****************************************************************************





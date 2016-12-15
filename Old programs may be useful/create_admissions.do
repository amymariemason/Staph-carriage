************ Creates lists of number of previous admissions and time to next admission

 use "E:\users\amy.mason\SSI\28082015\PAS_all.dta", clear
merge m:m clusterid2 using "E:\users\amy.mason\SSI\Data\dates_only.dta", update


*******************************
*Clean Step 1: clean PSS data
*******************************



****************
*Step 2: merge with op dates

*******************

merge m:m clusterid2 using "E:\users\amy.mason\SSI\Data\dates_only.dta", update


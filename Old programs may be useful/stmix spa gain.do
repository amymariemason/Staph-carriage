*********************************************************************************
*Playing with spa gain survival times and stmix
*********************************************************************************
*want to create a set for first gain of new spa type.


/* use two week differences instead */
/* make survival time set for gain of first new staph carriage*/
use "E:\users\amy.mason\Staph\DataWithNewBurp2", clear
/* mark even if new infection at least two different from previous 2 weeks */
 gen byte event =(BurpPrev>=2&BurpPrev!=.)
 
 replace event =1 if (base2==1 & State==1 &timepoint>=2)
 
 /*drop to one record per patient */
 
 gsort patid-event timepoint
 by patid: drop if _n>1 & event[1]==1
 by patid: drop if _n<_N & event[1]==0
 by patid:assert _N==1
 
 /*alter records for patients who were seen only one */
 replace timepoint =0.1 if timepoint <=1 & event ==0
 
 /* create set */
 
 stset timepoint, fail(event) id(patid)
 
 assert _st==1
 
 **************************************************************
 /* tried to use stmix*/
 
 stmix, dist(ww) pmix(base2)
 ******* extract variables and graph rates ****
 


*want to create a set for every gain of new spa type.

***************************************************************
/* use two week differences instead */
/* make survival time set for gain of first new staph carriage*/
use "E:\users\amy.mason\Staph\DataWithNewBurp2", clear
/* mark even if new infection at least two different from previous 2 weeks */
 gen byte event =(BurpPrev>=2&BurpPrev!=.)
 
* add event if no initial carriage 
 replace event =1 if (base2==1 & State==1 &timepoint>=2)
 

 /*alter records for patients who were seen only one */
 replace timepoint =0.1 if timepoint <=1 & event ==0
 
 /* create set */
 
 stset timepoint, fail(event) id(patid)
 
 assert _st==1
 
 **************************************************************
 /* tried to use stmix - nope - cannot calculate numerical derivatives -- flat or discontinuous region encountered*/
 stmix, dist(ww) noinit
 
 stmix, dist(ww) pmix(base2)
 ******* extract variables and graph rates ****
 
 
 
 ****************************************************************************
 *try diff from recruitment instead?
 
 /* make survival time set for gain of first new staph carriage*/
use "E:\users\amy.mason\Staph\DataWithNewBurp2", clear
/* mark even if new infection at least two different from recruitment */
 gen byte event =(BurpStart>=2&BurpStart!=.)
 
 replace event =1 if (base2==1 & State==1 &timepoint>=2)
 
 /*drop to one record per patient */
 
* gsort patid -event timepoint
* by patid: drop if _n>1 & event[1]==1
* by patid: drop if _n<_N & event[1]==0
* by patid:assert _N==1
 
 /*alter records for patients who were seen only one */
 replace timepoint =0.1 if timepoint <=1 & event ==0
 
 /* create set */
 
 stset timepoint, fail(event) id(patid)
 
 assert _st==1
  /* LR test */

sts test base2
 
 /* tried to use stmix - cannot calculate numerical derivatives -- discontinuous region with missing values encountered error*/
 stmix, dist(ww) 
 stmix, dist(we)
  stmix, dist(ww) pmix(base2) noinit
  
  
  
  ************************************************************** 
 

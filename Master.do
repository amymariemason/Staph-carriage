* MASTER.DO

* project: staph carriage analysis
* author: Amy Mason
* start date: June 2016
* raw data files in E:\users\amy.mason\Datasets\staph_carriage\Inputs

sysdir set PERSONAL "E:\users\amy.mason\ADO"
sysdir set STBPLUS  "E:\users\amy.mason\ADO\stbplus"
sysdir set OLDPLACE "E:\users\amy.mason\ADO\oldplace"
set logtype text

*******************

cd "E:\users\amy.mason\staph_carriage\Programs"

******************************
* CREATE DATABASE
******************************

* UPDATE FROM ACCESS BEFORE RUNNING
set more off

run inputs.do '/* data input; contain instructions on updating data from Ridom and access database */
/****** fix additional spa data not in extract
****** NOTE: some of these spa-types came back as unknown by Ridom or were unresolvable at the lab level */
cd "E:\users\amy.mason\staph_carriage\Programs" 
run spa_update.do /* adding in spatypes most recently typed; should not be run once access database up to date */
cd "E:\users\amy.mason\staph_carriage\Programs" 
run Clean_maindata.do  /* cleans main dataset, creating a log report of problems and steps taken */
cd "E:\users\amy.mason\staph_carriage\Programs" 
run baseline.do /* add data from initial participant questionaire */
cd "E:\users\amy.mason\staph_carriage\Programs"
run spa_RIDOM.do /*makes list of spatypes for RIDOM ("unique_spatypes.csv") */


* RUN DOWN TO THIS POINT, THEN UPDATE RIDOM DATABASE (see instructions below)
* Then run down to analysis

cd "E:\users\amy.mason\staph_carriage\Programs"
run RIDOM_inputs.do /* updates spa information */
cd "E:\users\amy.mason\staph_carriage\Programs"
run spatypes2.do  /* runs spatypes program with new data */
run antibiotics.do /* add time since antibiotics taken to the data */


* CREATES THE FULL DATASET
cd "E:\users\amy.mason\staph_carriage\Programs"
* combine data


run add_spa.do /*** then add spatypes to clean_data and calc burp cost */
run add_anti.do /** add antibiotics to calc for anti in last 6 months, anti between spa types; also baseline data */
run anti_types_sept29_16.do /* *** create a record for each patid-spatype so can talk about loss of each spa-type */

*STOP AT THIS POINT AND LOCK THE DATABASE

/* do continue.do Answers tim's questions on whether to continue study, to some degree*/  

***********************************
* ANALYSIS SECTION
***********************************
* create stset data
** gain
run gain_analysis.do  * gain of spa different from initial spatypes
run gain_analysis2.do * gain of spa different from previous 2 swabs

run loss_analysis1.do *loss of all carriage
run loss_analysis2.do *loss of all initial carriage
run loss_analysis3.do * loss of spatype gained in the study


** loss
run loss_analysis.do

* graphs

EXIT

What needs to be done:

1. Decision on Database are as spa types as possible ie. any outstanding are not spa typeable.
2. Decision that no longer adding new swabs
3. Check all spa types found are on RIDOM database; if not flag to Dona (?)
4. Run "Amy 28/06 Antimicrobials" and "Amy 28/06 Results extract" queries on the access database
	On the j drive
	file population_structure_carriage_SA/saureus10final (true as of 15/12/2016)
5. Update input file in STATA with new file names
	Says ***UPDATE*** where new files need to go in
6. Make list of ALL spa types that occur in study (use spa_RIDOM.do). Take list to RIDOM, upload and follow Amy's instruction (see below). 
	Check all the spatypes are recognised by the database 
7. Bring back to STATA and update the file RIDOM_inputs with new filenames
    Says ***UPDATE: RIDOM*** where new files need to go in
8. Run programme to point of starting analysis, check logs then lock database
	in particular check no new antibiotics appeared that need classifying; if there are update "E:\users\amy.mason\staph_carriage\Inputs\Staph_drugslist_nicola_update_mar2016.xlsx"
9. There are some files that will aid starting an analysis: labeled gain_analysis and loss_analysis
	These will stset the data and make a Kaplan-Meier graph
	Some code fitting a non-parametric model; some fitting a Weibull model 

***********************************************************
How to get BURP details out of the RIDOM program. Requires RIDOM and Mega programs and a list of all the spatypes found in the dataset. 


1) Open and click on burp clustering. 
2) upload list of all spa-types from the staph carriage study. Let ridom update if there are spa-types not in it's database.
3)  cluster WITH exclusion of spatypes (default setting). 
4) extract the CC-groups data from this set (this should be a csv file). This gives you the list of which spa-types are in which Clonal cluster.
5) cluster WITHOUT excluding any spatypes
6) extract the cost matrix from this set (this should be as a mega file)
7) open the cost matrix in MEGA. Export the values as a csv file with export type "column". This will give you the distances between each pair of spa-types. 

****************************************
relevant variables idenified by Ruth

Ruth paper found significant:

DONE:
sex
age
ethnicity
being in current employment at recruitment
participation in contact sport at recruitment
more household members
time since district nurse
ever being an inpatient
outpatient exposure (0.001)
Days since surgery
days since last GP appointment (per year)
treatment for skin condition within last 30 day 
Ever had long term illness
	(defined as: One hundred and sixty nine patients had one or more long term illnesses that have been associated with either S.aureus carriage or community acquired S. aureus infection: (n=number of patients). type 1 diabetes (5), type 2 diabetes (25), asthma/COPD on inhaled steroids (36), history of cancer (24), history of dermatitis or psoriasis (43), most recent BMI >=30 (102), history of drug misuse (4), dialysis (1), cirrhosis (1). The effect of one of these long-term illnesses was very similar to the effect of the larger group with any long-term illness shown above.)
	
antibiotics in last 6 months
antibiotics in last interval
recruitment pos
having multiple spa-types

TO DO:
recruitment CC
positive on previous swab
carriage of CC8, CC15 or other
gaining new spatype in prev swab 


 


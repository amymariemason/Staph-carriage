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

set more off
* data input
run getdata.do
set more on


cd "E:\users\amy.mason\staph_carriage\Programs"
* clean data
set more off
cd "E:\users\amy.mason\staph_carriage\Programs"
run Clean_maindata.do
run baseline.do
cd "E:\users\amy.mason\staph_carriage\Programs"
run spatypes.do
run antibiotics.do
set more on


cd "E:\users\amy.mason\staph_carriage\Programs"
* combine data

** then add spatypes to clean_data and calc burp cost
run add_spa.do
** add antibiotics to calc for anti in last 6 months, anti between spa types; also baseline data
run add_anti.do
*** create a record for each patid-spatype so can talk about loss of each spa-type
run anti_types.do

* analyse data
** gain


** loss

* graphs
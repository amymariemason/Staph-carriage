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

* clean data
set more off
cd "E:\users\amy.mason\staph_carriage\Programs"
run Clean_maindata.do
run baseline.do
cd "E:\users\amy.mason\staph_carriage\Programs"
run spatypes.do
run antibiotics.do
set more on

* combine data

** then add spatypes to clean_data and calc burpsdifferences (see R file)
run add_spa.do
** add antibiotics to calc for anti in last 6 months, anti between spa types
run add_anti.do
** add baseline data

* analyse data
** gain
** loss

* graphs
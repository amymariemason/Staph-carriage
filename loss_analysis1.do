* project: staph carriage analysis
* author: Amy Mason
* loss analysis

set li 130

cap log close
log using gain_analysis.log, replace
noi di "Run by AMM on $S_DATE $S_TIME"


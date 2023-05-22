*Policy data
*Data manipulation
//2019-12-05
*set working directory
clear
cd "E:\Master-thesis\context_data"
*change the dataformat for numbers from sting to byte
sort policy_start State
use context-data.dta
destring childtoadultratio takeupratesinpe* share* unemployment*, replace dpcomma 

rename  bula State
gen bula=.
replace bula=1 if Bundesländer=="Schleswig-Holstein"
replace bula=2 if Bundesländer=="Hamburg"
replace bula=3 if Bundesländer=="Niedersachsen"
replace bula=4 if Bundesländer=="Bremen"
replace bula=5 if Bundesländer=="Nordrhein-Westfalen"
replace bula=6 if Bundesländer=="Hessen"
replace bula=7 if Bundesländer=="Rheinland-Pfalz"
replace bula=8 if Bundesländer=="Baden-Württemberg"
replace bula=9 if Bundesländer=="Bayern"
replace bula=10 if Bundesländer=="Saarland"
replace bula=11 if Bundesländer=="Berlin"
replace bula=12 if Bundesländer=="Brandenburg"
replace bula=13 if Bundesländer=="Mecklenburg-Vorpommern"
replace bula=14 if Bundesländer=="Sachsen"
replace bula=15 if Bundesländer=="Sachsen-Anhalt"
replace bula=16 if Bundesländer=="Thüringen"
use context-data.dta
gen wave=.
replace wave=1 if year==2009
replace wave=2 if year==2010
replace wave=3 if year==2011
replace wave=4 if year==2012
replace wave=5 if year==2013
replace wave=6 if year==2014
replace wave=7 if year==2015
replace wave=8 if year==2016
replace wave=9 if year==2017
replace wave=10 if year==2018

gen bulaid=.
replace bulaid=1 if bula==2
replace bulaid=2 if bula==3
replace bulaid=3 if bula==4
replace bulaid=4 if bula==5
replace bulaid=5 if bula==6
replace bulaid=6 if bula==7
replace bulaid=7 if bula==8
replace bulaid=8 if bula==9
replace bulaid=9 if bula==10
replace bulaid=10 if bula==11
replace bulaid=11 if bula==12
replace bulaid=12 if bula==13
replace bulaid=13 if bula==14
replace bulaid=14 if bula==15
replace bulaid=15 if bula==16
replace bulaid=16 if bula==1


gen East=0
replace East=1 if bula>=12
replace East=0 if bula<=11
gen West=0 if East==1
replace West=1 if East==0 & bula!=11
gen Berlin=1 if bula==11

sort bula wave

rename shareofpersonalwithouteducationi qualificationstaff
rename takeupratesinpercentage enrollment

*change the date:
rename year beginning_year
gen beginning_month=.
replace beginning_month==3 if beginning_year==2018
gen ending_year=.
gen ending_month=. 
replace ending_year=2019 if beginning_year==2018
replace ending_month=2 
replace beginning_month=3
replace ending_year=2018 if beginning_year==2017
replace ending_year=beginning_year+1 

*transform the date into CDC-style
replace policy_start=ym(beginning_year, beginning_month)-ym(1900, 1)
replace policy_end=ym(ending_year, ending_month)-ym(1900, 1)
*transform the qualification variable: share of educated personal=1-share of non-educated staff
replace qualificationstaff=100-qualificationstaff
************save the data
save context-data.dta, replace
************ state comparison
********** Descriptive Analysis of the childcare policies and context data
sort bula year
xtset year bula, 
xtline unemploymentrate,  i(Bundesländer) t(year)		//unemployment levels
xtline childtoadultratio,  i(Bundesländer) t(year)	//child to adult ratio
xtline enrollment,  i(Bundesländer) t(year)	//take-up rates in percent
xtline qualificationstaff,  i(Bundesländer) t(year)	//share of uneducated personal


******** East-West comparison
use context-data.dta

******** creating aggregate data

collapse (mean) unemploymentrate childtoadultratio enrollment qualificationstaff, by (East year)
xtset year
label variable East "East-West Germany, Berlin excluded"
label define East 1 "East-Germany" 0 "West-Germany"
label values East East
xtline unemploymentrate, overlay i(East) t(year)
xtline childtoadultratio, overlay i(East) t(year)
xtline enrollment, overlay i(East) t(year)
xtline qualificationstaff, overlay i(East) t(year)
save East-West.dta



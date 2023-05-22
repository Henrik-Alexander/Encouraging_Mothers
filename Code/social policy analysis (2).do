********** Analysis of the context data
clear
cd "E:\Master-thesis\Event history analysis"
use context-data
*install software
ssc install spmap
ssc install shp2dta
ssc instal mif2dta

*development of the policy indicators throughout the observation period
//availability
graph box enrollment, over(beginning_year)
graph bar enrollment if beginning_year==2006 | beginning_year==2012 | beginning_year==2018,  over(beginning_year) over(Bundesländer) over(East) nofill
tsset State beginning_year, yearly
pergram enrollment, by Bundesländer
tabstat enrollment, by(beginning_year) s(mean max min range sd var)
//child to adult ratio
graph box childtoadultratio, over(beginning_year) nofill
graph bar childtoadultratio if beginning_year==2006 | beginning_year==2012 | beginning_year==2018,  over(beginning_year) over(Bundesländer)
tabstat childtoadultratio, by(beginning_year) s(mean median max min range sd var)
//education of the staff
graph box qualificationstaff, over(beginning_year) nofill
graph bar qualificationstaff if beginning_year==2006 | beginning_year==2012 | beginning_year==2018,  over(beginning_year) over(Bundesländer)
///unemployment rate
graph box unemploymentrate, over(beginning_year) nofill
graph bar unemploymentrate if beginning_year==2006 | beginning_year==2012 | beginning_year==2018,  over(beginning_year) over(Bundesländer) over(East) nofill
tsset State beginning_year, yearly

*********spatial plotting for the year 2018
spmap enrollment if beginning_year==2018 using BRDcoord, id(bulaid)  						 ///
				clmethod(eqint) clnumber(8)  fcolor(Blues)
				

*********spatial plotting: educat
spmap  qualificationstaff if beginning_year==2018 using BRDcoord, id(bulaid)  						 ///
				clmethod(eqin)   fcolor(Blues)
*********spatial plotting: 	child to adult ratio
spmap  childtoadultratio if beginning_year==2018 using BRDcoord, id(bulaid)  						 ///
				clmethod(eqint) clnumber(6) fcolor(Blues)
*********spatial plotting: 	free ch
spmap  age_free_childcare if beginning_year==2018 using BRDcoord, id(bulaid)  fcolor(Accent)
**********spatial plotting: unemployment rate
spmap  unemploymentrate if beginning_year==2018 using BRDcoord, id(bulaid)  fcolor(Blues) clmethod(eqint)

************ state comparison
********** Descriptive Analysis of the childcare policies and context data
sort bula beginning_year
xtset beginning_year bula, 
xtline unemploymentrate,  i(Bundesländer) t(beginning_year)		//unemployment levels
xtline childtoadultratio,  i(Bundesländer) t(beginning_year)	//child to adult ratio
xtline enrollment,  i(Bundesländer) t(beginning_year)	overlay
//take-up rates in percent
xtline qualificationstaff,  i(Bundesländer) t(beginning_year) overlay	//share of uneducated personal
tsset, clear
xtset, clear
*
twoway scatter enrollment beginning_year, mlabel(East)
twoway scatter unemploymentrate beginning_year, mlabel(East)
twoway scatter childtoadultratio beginning_year, mlabel(East)
twoway scatter qualificationstaff beginning_year, mlabel(East)
******** creating aggregational data for analysing time change
use context-data.dta, clear
sort year
collapse (first) unemploymentrate childtoadultratio enrollment qualificationstaff , by (bulaid)
save policies2008, replace
use context-data.dta, clear
collapse (last) unemploymentrate childtoadultratio enrollment qualificationstaff , by (bulaid)
rename unemploymentrate unemploymentrate2018 
rename childtoadultratio quality2018 
rename enrollment enrollment2018 
rename qualificationstaff qualification2018
save policies2018, replace
merge 1:1 bulaid using policies2008
label variable bulaid "Federal state"
label define Bundesländer 16 "16 Schleswig-Holstein" 1 "1 Hamburg" 2 "2 Niedersachsen(Lower Saxony)" 3 "3 Bremen" 4 "4 Nordrhein-Westfalen (North Rhine-West)" 5 "5 Hessen (Hesse)" 6 "6 Rheinland-Pfalz(Rhineland-Palatinate)" 7"7 Baden-Württemberg" 8 "8 Bayern (Bavaria)" 9 "9 Saarland" 10 "10 Berlin"11 "11 Brandenburg" 12 "12 Mecklenburg-Vorpommern" 13 "13 Sachsen (Saxony)" 14 "14 Sachsen-Anhalt(Saxony-Anhalt)" 15 "15 Thüringen (Thuringia)", modify
label values bula Bundesländer
tab bulaid
gen unemploymentchange=unemploymentrate2018-unemploymentrate
gen qualitychange=quality2018-childtoadultratio
gen enrollmentchange=enrollment2018-enrollment
gen qualificationchange=qualification2018-qualificationstaff
graph bar qualitychange enrollmentchange qualificationchange, over (bulaid)
save policychange08-18, replace
spmap enrollmentchange using BRDcoord, id(bulaid) fcolor(Blues)


******** creating aggregate data for East-West comparison

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

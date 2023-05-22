********** Analysis of the context data
clear
cd "C:\Users\henri\OneDrive\Desktop\Journal Article\Journal Article\Data"
use context-data
*install software
//ssc install spmap
//ssc install shp2dta
//ssc instal mif2dta

*development of the policy indicators throughout the observation period
//availability
graph box enrollment, over(beginning_year) nofill title("Development of Childcare Availability in the States(2006-2018)") note("Source: Destatis/Statistisches Bundesamt 2019; Author's calculations using Stata 16.") box(1,color(black))
graph bar enrollment if beginning_year==2006 | beginning_year==2012 | beginning_year==2018,  over(beginning_year) over(Bundesländer) over(East) nofill


*Childcare Quality
//boxplot
graph box quality, over(beginning_year) nofill  title("Development of Childcare Quality in the States(2006-2018)") note("Source: Destatis/Statistisches Bundesamt 2019; Author's calculations using Stata 16.") box(1,color(black))
//barchart
graph bar quality if beginning_year==2006 | beginning_year==2012 | beginning_year==2018,  over(beginning_year) over(Bundesländer)
tabstat childtoadultratio, by(beginning_year) s(mean median max min range sd var)

*education of the staff
graph box qualificationstaff, over(beginning_year) nofill 
graph bar qualificationstaff if beginning_year==2006 | beginning_year==2012 | beginning_year==2018,  over(beginning_year) over(Bundesländer)

*unemployment rate
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



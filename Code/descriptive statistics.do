***************************************************************************
*				Encouraging Mothers: Childcare policies					  *
*					Henrik-Alexander Schubert							  *
*						Descriptive Statistics							  *
***************************************************************************

*preperations
clear
cd "U:/encouraging mothers/Encouraging Mothers"
use Analysis.dta
ssc install asdoc, replace
replace Event=.
replace Event=1 if END==DURATION+dobk1
replace Event=. if censor==1

stset END, id(id) failure(Event) origin(dobk1) ///
exit(time dobk1+36)


*education variables
drop educ
gen educ=.
replace educ=1 if education<=3
replace educ=2 if education==4 | education==5
replace educ=3 if education==6 | education==7 | education==8
label variable educ "Educational level"
label define educ_label 1 "No degree/Lower secundary education" 2"Upper secondary education" 3"Post-secondary education"
lab values educ educ_label


*replace popdens
gen city=.
replace city=1 if popdens>=5 & popdens!=.
replace city=0 if popdens<=4
label variable city "Rural area"
label define city 1"Urban area" 0"Rural area"
label values city city


*generate stratum
gen stratum=.
replace stratum=1 if hhincome<=1405
replace stratum=2 if hhincome>=1406 & hhincome<=6152
replace stratum=3 if hhincome>=6153
label variable stratum "socio-economic stratum"
label define stratum 1"Lower Class" 2"Middle class" 3"Upper class"
label values stratum stratum


*Prior working experience
gen worked=.
replace worked=1 if cumulative_work_experience>=1 & ///
 cumulative_work_experience!=.
replace worked=0 if cumulative_work_experience==0
label variable worked "Previous employment"
label define worked 0"Never employed" 1"Previous employment"
label values worked worked

*descriptive
/// work-family preferences by age of child
asdoc sum  East educ stratum wf_preferences if _t0==1, //// 
 title(Table : Work-family attitude by age of child) ///
text(Soure: Pairfam 10.0, author's calculations using Stata 16)
///summary statistics of ratio scaled variables
label variable hhincome "Net household income in €"
label variable cumulative_work_experience "Prenatal working experience in months"

///Descriptive statistics
///spell-data
asdoc tab educ city East wf_preferences  if NR==1, label //// 
label percent save(statistics) noci //// 
fhc(\b \i) fhr(\b \i) ///
title(Table : Educational level in the sample) ///
text(Soure: Pairfam 10.0, author's calculations using Stata 16) ///
fs(10)
///Person information
asdoc tab city if NR==1, label append save(statistics)///
title(Table : Educational level in the sample) ///
text(Soure: Pairfam 10.0, author's calculations using Stata 16) ///
fs(10)



///educational differences
ltable DURATION, by(educ) graph overlay
asdoc sum hhincome cumulative_work_experience, label  dec(1) ///
fhc(\b \i) fhr(\b \i) append ///
title(Table : Descriptive Statistics of continuous variables) ///
text(Source: Pairfam 10.0; author's calculations using Stata 16) fs(10)

*number of women without any working experience at childbirth
count if NR==1 & cumulative_work_experience==0
*histogram of population_density at the place of residence at childbirth
tab popdens _t if _d==1, column 
gen city=1 if 


/// East-West differences
ltable DURATION, by(East) graph overlay
sts graph, by(East)

/// statistical difference between sex East and west
sts test East


/// basic exponential model
streg, distribution(exponential) nohr
estimates store empty

/// regression with covariates
streg age i.East, distribution(exponential) nohr


* calculate the percentage change in the rate, given that only one covariate changes
display (exp(_b[age])-1) * 100 /*age*/

sts graph, by(cohort)


/// log-likelihood ratio test
lrtest empty

*************************************************************************************
*** plotting ************************************************************************
ssc install blindschemes
set scheme economist, permanently
separate DURATION, by(educ)
scatter DURATION*  hhincome  if DURATION <= 36 & hhincome <= 10000

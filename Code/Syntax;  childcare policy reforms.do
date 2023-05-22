*Event-History Analysis
//Henrik-Alexander Schubert
//Journal Article: Childcare Policy Reforms
// 2020-21
clear

*set working directory
cd "U:\encouraging mothers\Encouraging Mothers"
use ANALYSIS.dta
// installation of the required packages
*ssc install estout, replace
*ssc install coefplot, replace


*stset
stset END, failure(Event) origin(time dobk1) exit(time dobk1+36) id(id)
stvary East popdens enrollment quality stratum wf_preferences childtoadultratio second_child

*weighted analysis
svyset id [pweight=d1weight1]

/////////////////////// Analysis////////////////
*time model
svy: streg i.time , d(e)
eststo model1

*model 2
svy: streg i.time##c.enrollment c.quality i.educ i.stratum  i.East c.unemployment i.cohort i.second_child, d(e)
eststo model2

*model3
svy: streg i.time##c.enrollment c.quality i.educ i.stratum  i.East c.unemployment ib2.wf_preferences i.cohort i.second_child, d(e)
eststo model3
margins i.time, at(enrollment=(20 29 40)) at(quality=(3 5 7))predict(hazard)
marginsplot 


*model4
svy: streg i.time##c.quality c.enrollment  i.educ i.stratum  i.East c.unemployment i.wf_preferences i.cohort  i.second_child, d(e)
eststo model4

*model5
*svy: streg i.time c.quality##ib2.wf_preferences c.enrollment  i.educ i.stratum  i.East c.unemployment      i.second_child, d(e)
*eststo model5

*Creating regression table
 estout using "U:\encouraging mothers\Encouraging Mothers\resu.xls", eform ///
 cells(b(star fmt(a3))) ///
 stats(bic aic N N_sub N_fail,  	labels("Number of subjects" "Number of failures")) 	label 	varlabels( _cons "Baseline Hazard") dropped("(ref.)") ///
    title("Table: Hazard ratios of the piece-wise constant model") ///
    note("Source: Pairfam 10.0, Author's calculations using Stata 16") ///
	replace



*Sensitivity analysis
*time_dependence of quality
*streg i.time##c.childtoadultratio c.enrollment   i.East i.educ i.stratum  c.unemployment, d(e)
*eststo time_dependent
*controlling for second childbirth
*streg i.time c.enrollment c.childtoadultratio i.educ i.East i.second_birth i.stratum  c.unemployment, d(e)
*eststo second_birth
*all-in model
 *streg i.time c.enrollment c.childtoadultratio i.educ i.city i.cohort i.second_birth i.East  i.stratum  c.unemployment, d(e)
*eststo all_in


*descriptives of the weighted dataset
*weighted analysis
*svyset id [pweight=d1weight1]
*reduced model
*svy: proportion East cohort educ stratum second_child city










*Event-History Analysis
//Henrik-Alexander Schubert
//Masterthesis
//January-June 2020
clear
*set working directory
cd "U:\encouraging mothers\Encouraging Mothers"
use ANALYSIS.dta
*ssc install estout, replace
*ssc install coefplot, replace


*stset
stset END, failure(Event) origin(time dobk1) exit(time dobk1+36) id(id)
stvary East popdens enrollment  stratum wf_preferences childtoadultratio second_child

*weighted analysis
svyset id [pweight=d1weight1]

/////////////////////// Analysis////////////////
*time model
svy: streg i.time , d(e)
eststo model1
*reduced model
svy: streg i.time c.enrollment c.quality, d(e) 

*full model
svy: streg i.time##c.enrollment c.quality i.East i.educ i.stratum ib2.wf_preferences c.unemployment i.second_child, d(e)
eststo proportional_model
set scheme s1mono
coefplot proportional_model, eform drop(_cons 12.time#c.enrollment 24.time#c.enrollment 12.time 24.time 1.East enrollment quality unemploymentrate) xline(1) xtitle("hazard ratios") title("Individual Determinants") headings(2.educ="{bf:Education}" 2.stratum="{bf:Social Stratum}" 1.wf_preferences="{bf:Work-Family Preferences}")
margins i.time, at(enrollment=(20 29 40)) predict(hazard)
*third hypothesis
svy: streg i.time##c.quality c.enrollment  i.educ ib2.wf_preferences i.second_child i.East i.stratum c.unemployment, d(e)
eststo model2b




*Creating regression table
 estout using "U:\resu.xls", eform ///
 cells(b(star fmt(a3))) ///
 stats(bic aic N N_sub N_fail,  	labels("Schwar's Information Criterion" "Akaike's Information 	Criterion" "Observation Episodes" "Number of subjects" "Number of failures")) 	label 	varlabels( _cons "Baseline Hazard") dropped("(ref.)") ///
    title("Table: Hazard ratios of the piece-wise constant model") ///
    note("Source: Pairfam 10.0, Author's calculations using Stata 16") ///
    replace legend 

	
	
*Sensitivity analysis
*time_dependence of quality
streg i.time##c.childtoadultratio c.enrollment   i.East i.educ i.stratum  c.unemployment, d(e)
eststo time_dependent
*controlling for second childbirth
streg i.time c.enrollment c.childtoadultratio i.educ i.East i.second_birth i.stratum  c.unemployment, d(e)
eststo second_birth
*all-in model
 streg i.time c.enrollment c.childtoadultratio i.educ i.city i.cohort i.East  i.stratum  c.unemployment, d(e)
eststo all_in


*descriptives of the weighted dataset
*weighted analysis
svyset id [pweight=d1weight1]
*reduced model
svy: proportion East cohort educ stratum second_child city

*reduced model
svy: streg i.time c.enrollment c.childtoadultratio, d(e)
margins, at(childtoadultratio=(4 5)) predict(hazard)
eststo reduced_model
*full model
svy: streg i.time c.enrollment c.childtoadultratio i.East i.educ i.stratum  c.unemployment, d(e) time
eststo full_model
*Third model
svy: streg i.time##c.enrollment c.childtoadultratio i.East i.educ i.stratum  c.unemployment, d(e)
margins time, at(enrollment=(20 40 60)) predict(hazard) saving("predicted_hazards")
marginsplot, xdimension(time)
eststo time_dependent
*third hypothesis
streg i.time c.enrollment c.childtoadultratio##i.educ i.East i.stratum c.unemployment, d(e)
eststo third_hypothesis
*Creating regression table
 estout using "D:\Master-thesis\Event history analysis\resu.xls", eform ///
 cells(b(star fmt(a3))) ///
 stats(bic aic N N_sub N_fail,  	labels("Schwar's Information Criterion" "Akaike's Information 	Criterion" "Observation Episodes" "Number of subjects" "Number of failures")) ///
	label 	varlabels( _cons "Baseline Hazard") dropped("(ref.)") ///
    title("Table: Hazard ratios of the piece-wise constant model") ///
    note("Source: Pairfam 10.0, Author's calculations using Stata 16") ///
    replace legend 









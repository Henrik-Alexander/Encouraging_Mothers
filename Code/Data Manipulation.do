***************************************************************************
*				Encouraging Mothers: Childcare policies					  *
*					Henrik-Alexander Schubert							  *
*							Data Manipulation							  *
***************************************************************************

* install package missing
ssc install carryforward


*data investigations and manipulation
clear
cd "U:\encouraging mothers\Encouraging Mothers"

/////////////////////////////			biochild			/////////////////////////
******** 1) Data manipulation: bio child
//loading the event-histary data on childbirths
use biochild.dta

*drop variables
drop surveykid currliv_detail pid parentid smid sfid mid fid b1livkbeg b1livkend flag_parentid imp_livkbeg imp_livkend livkbeg livkend
drop if cid==.
drop id

*reshaping the dataset -> wide
reshape wide currliv intdat statusk pno index, i(cid) j(wave)
gen long id=cid-200-number

*delete all stepchildren
drop if statusk2==3 | statusk3==3 |statusk4==3 | statusk5==3 | statusk6==3 |statusk7==3 | statusk8==3 | statusk9==3 | statusk10==3
sort id cid

*calculation of age at childdeath
gen ageofchilddeath=dodk-dobk if dodk!=-3 & dobk!=-7
tab ageofchilddeath
drop dodk

*censor for childdeath of the first child before age 3
gen censorcd=1 if ageofchilddeath<=36 & number==1
label variable censorcd "1=child dies before the age of 3"

keep cid sexk censorcd dobk number cohort sex dob demodiff id

*save the long dataversion
save biochild_long.dta, replace

*reshaping dataset -> wide, one spell per parent
reshape wide sexk censorcd dobk cid, i(id) j(number)

*generating a variable for repeated childbearing
gen birthspace=dobk2-dobk1 if dobk2!=.
replace birthspace=. if birthspace<=-1
label variable birthspace "Time between births)"

*twins variable
gen twins=0
replace twins=1 if birthspace==0	
label variable twins "the first two childbirths are twins"  // 84 twin births in the data

*the competing risk outcome: instead of return to employment repeated childbearing	
gen alteroutcome=.
replace alteroutcome=1 if birthspace<=36 & twins!=1

*same procedure for twins
gen birthspace2=dobk3-dobk2 if dobk3!=. & twins==1
replace alteroutcome=1 if birthspace2<=36
label variable alteroutcome "second childbirth is given within 3 years"

*drop cases without informaiton on birth
drop if dobk1==-7
keep id cid1 cid2 cid3 dobk1 dobk2 dobk3 demodiff dob sex cohort birthspace birthspace2 twins alteroutcome
save biochild_wide.dta, replace


******  Data manipulation: bioact ************************************************
clear
use bioact

*****Data Cleaning: deleting cases
****generating indicator variables 
* an acitivity is part of education
gen educ=0
replace educ=1 if activity>=1 & activity<=9

//label indicator variable
label variable educ "educational activity"
label define educ 0 "other than educational activity" 1 "educational activity"
label values educ educ

*2) dummy variable for parental leave
gen parleave=0
replace parleave=1 if activity==17
label define parleave 0"other activity than parental leave" 1"1 parental leave"
label values parleave parleave

*3) dummy for employment
gen work=0
replace work=1 if activity>=10 & activity<=18 & activity!=17
label define work 0 "other than work" 1"1 employed"
label values work work
replace work=.  if activity==15 //irregular work doesn't count as employment
replace work=. if activity==13 //traineeship is not considered as work

*4) dummy for unemployed
gen unemployed=0
replace unemployed=1 if activity==20 | activity==19
label define unemployed 0 "not unemployed, education" 1 "1unemployed or household-work"
label values unemployed unemployed
keep id activity spell actbeg actend actcensor educ parleave work unemployed

*combine the childbirth data with activity data
append using biochild_long.dta, generate(children_cleaned)
* the online ativity spells with missings are childbirths from the biochild data
replace activity=50  if number!=.
label define activity_ba 50 "50 childbirth", add
label values activity activity_ba
replace actbeg=dobk if dobk!=.
save period_data.dta, replace

************************************************************************************
*Descriptive analysis for the event-history dataset
sort id actbeg 

*generate a first-birth variable, that is constat for all observations of the same person
by id, sort: egen firstbirtheha=min(dobk)
label variable firstbirtheha "date of the first childbirth"

***** cumulative work experience before motherhood
gen activity_duration=actend-actbeg if actbeg>=0 & actend>=0 & actend!=97

*identify employment spells before childbirth
generate wbm=1 if firstbirtheha>=actbeg & work==1 & activity!=0 & actend>=100 & actbeg>=0		//actend>=100, because the ongoing jobs are excluded

*uninterrupted work experience
gen uninterrupted_work= activity_duration if wbm==1 &  actend<=firstbirth & actcensor<=3 & actend!=97

****creating work-experience that was interrupted by motherhood
//indicator variable
gen interrupted_employment=1 if work==1 & actbeg<=firstbirth &  actend>=firstbirth  & actcensor==0 & actend!=firstbirth
replace interrupted_employment=1 if work==1 & actbeg<=firstbirth & actend==97
gen duration_interrupted_work=firstbirth-actbeg if interrupted_employment==1

**cumulative work experience
by id: egen uninterrupted_work_experience=total(uninterrupted_work) 
by id: egen interrupted_work_experience=total(duration_interrupted_work) 
gen cumulative_work_experience=(uninterrupted_work_experience+interrupted_work_experience)/12

*marker for activities before childbirth
by id: gen childlessact=1 if actbeg<=firstbirtheha & actbeg!=firstbirth


*Event-History variables
gen maternal_employment=1 if work==1 & actbeg>=firstbirth & childlessact!=1
label variable maternal_employment "work after first childbirth"
sort id actbeg 
by id: egen maternal_jobs=rank(actbeg) if maternal_employment==1, track
label variable maternal_jobs "maternal job spells"
by id: gen interruption=actbeg-firstbirtheha if maternal_jobs==1
label variable interruption "employment interruption after first birth"
by id: egen DURATION=min(interruption)
keep id DURATION actbeg actend activity spell childlessact work parleave cumulative_work_experience
drop if activity==50

*numbering of the activities
by id: gen nr=_n
reshape wide actbeg actend activity spell childlessact work parleave ,i(id) j(nr)

*save dataset
save period_data.dta, replace
merge 1:1  id  using biochild_wide.dta, generate(outsample)
drop if outsample==1
drop if sex==1
save univariate_dataset.dta, replace


**** Pace of residence ****************************************************************
use biomob_ehc.dta
clear
use biochild_long.dta
append using biomob_ehc.dta
sort id
keep id resdis index_mr resbeg resend resnumber resland dobk resbik
by id: egen firstbirth=min(dobk)
drop if resend<=firstbirth | index_mr>=2
drop if resbeg>=firstbirth+37
sort id resbeg
by id: gen residence_nr=_n
drop dobk resdis resnumber
sort id
reshape wide resbeg resend resbik index_mr resland, i(id) j(residence_nr)
save bioresidence_wide.dta, replace


*** partner data ****************************************************************
clear
use biopart.dta

keep  id demodiff partindex intdat* dob sexp relbeg relend b?beg b?end partcurrw* *flag* cohbeg cohend
drop if relbeg==-3			// drop if no relationship episode exists
sort id partindex

* Failure indicator (i.e. event): 1=Separation/Divorce
gen separ=0
replace separ=1 if relend!=-99
tab separ, m	

* Generate last interview
egen intdat_max=rowmax(intdatw*)

* Censored unions get the interview date
replace relend = intdat_max  if relend==-99 

* Drop unions with missing dates 
drop if relbeg==-7 | relend==-7

* Drop unions if partner died 
drop if relend==-66

* Drop unions with age at start of union below 10 
gen ageunion=(relbeg-dob)/12
drop if ageunion<10                //we do not believe in these unions

* Drop unions with age at end of union below 14 
gen ageendunion=(relend-dob)/12
drop if ageendunion<14

*deleting redundant variables
keep id partindex relbeg relend cohbeg cohend separ 
append using biochild_long.dta
sort id
by id: egen firstbirth=min(dobk)
drop if relend<=firstbirth-9

*generating loneparent
sort id relbeg
by id: gen loneparent=1 if relend>=firstbirth-9 & relend<=firstbirth+36
replace loneparent = 0 if loneparent == .
keep id relend loneparent
keep if loneparent==1
sort id
by id: gen nr=_n
drop if nr>=2
drop nr

*save dataset
save loneparent.dta, replace

***  anchor datasets  *************************************************************
clear all
set more off		

*reshape long
use id wave sex_gen doby dobm inty isced  intd intm nkids bik gkpol cohort inc2 hhincnet homosex pdob*_gen bula val1i* *weight pa14i* sd19k* using anchor1, clear					// load anchor data wave 1
append using  anchor1_DD, nolabel keep(id wave inty intd isced doby dobm bik gkpol intm sex_gen nkids bula *weight  cohort inc2 hhincnet homosex pdob*_gen val1* pa14i* )	// append anchor data wave 1, DemoDiff subsample 
append using anchor2 anchor3 anchor4 anchor5 anchor6 anchor7 anchor8 anchor9, ///
keep(id wave sex_gen doby dobm intd bik gkpol inty intm nkids bula isced cohort inc2 hhincnet homosex *weight  pdob*_gen crn13k1i* crn14k1* pa14i* ) force
append using anchor10 , ///
keep(id wave sex_gen doby dobm intd  inty bik gkpol intm nkids isced bula cohort inc2 hhincnet homosex *weight  pdob*_gen crn13k1i11 crn96* pa14i* ) force 
replace crn96k1=. if crn96k1<=-1
tab crn96k1


*** append data from anchor persons wave 2 to 10	*******************************
								
***** anchor's date of birth
gen dob=ym(doby, dobm) if doby>=0
lab var dob "Date of birth Anchor" 

* change baseline date from January 1960 to January 1900
replace dob		= dob		- ym(1900,1) 

*drop the old variable
drop doby dobm

*basic checks
describe, short									// describe merged dataset 

//create missing values
replace inc2=. if inc2==-3 |inc2==-2 | inc2==-1
replace hhincnet=. if hhincnet<=-1

///delete the original variables
drop crn13* crn14* crn96k6 crn96k7 crn96k8 crn96k9 crn96k10 crn96k11

*** calculating the duration between the different interview waves ***************
gen interviewdate=ym(inty, intm)-ym(1900, 1)
tab interviewdate
gen firstbirth=ym(sd19k1y, sd19k1m)-ym(1900, 1)

*wave when the child is born
sort id wave
by id: egen first_timemother=min(firstbirth)
gen secondbirth=ym(sd19k2y, sd19k2m)-ym(1900, 1)
gen thirdbirth=ym(sd19k3y, sd19k3m)-ym(1900, 1)

sort id wave

*drop the old variables 
drop sd19* pdoby intd intm pdobm  inty

*reshape
reshape wide  inc2  bik gkpol homosex isced   crn96k1 crn96k2 crn96k3  *weight  crn96k4  crn96k5  hhincnet nkids bula val* pa* interviewdate firstbirth secondbirth thirdbirth, i(id) j(wave)
save anker_demodiff, replace
merge 1:1 id using univariate_dataset.dta, gen(overlap)


*revise the alteroutcome variable
//the alternative outcome is just valid, when the second child is born before a person returns to work
replace alteroutcome=2 if alteroutcome==1 & twins!=1 & birthspace<=DURATION

*centuries of births
gen centuries_birth=.
replace centuries_birth=1 if dobk1>=1080 & dobk1<=1200
replace centuries_birth=2 if dobk1>=1200 & dobk1<=1260
replace centuries_birth=3 if dobk1>=1260 & dobk1<=1320
replace centuries_birth=4 if dobk1>=1320 & dobk1<=1440
label variable centuries_birth "century when the first child was born"
label define centuries_birth 1 "1990s" 2 "2000-2005" 3 "2005-2010" 4"2010s"
label values centuries_birth centuries_birth
tab centuries_birth

* merge lone parenthood
merge 1:1 id using loneparent.dta
drop if _merge==2
drop _merge

*merge residence data
merge 1:1 id using bioresidence_wide.dta
drop if _merge==2
drop _merge

*checking the data
replace DURATION=actbeg2-dobk1 if id==179501000		
drop if dobk1==.


*censoring
egen intdat_max=rowmax(interviewdate*)
gen censor=1 if intdat_max<=dobk1+36
replace censor=. if censor==1 & DURATION<=36
replace censor=1 if DURATION==. & intdat_max>=dobk1

*descriptive analysis
*creating a censoring variable
gen Event=.
replace Event=1 if DURATION!=.
*right-censoring
replace DURATION=intdat_max-dobk1 if censor==1

*generating a variable, that marks the observation
gen END=.
replace END=dobk1+DURATION

*filter births after 2006
keep if dobk1>=1274
*set survival data
stset END, failure(Event) origin(time dobk1) id(id)  exit(time dobk1+36)
sts graph, risktable


*maximal education level
egen education=rowmax(isced*)
label variable education "highest educational level"
label define education 1 "No degree" 2 "Lower secondary education" 3 "Lower secondary education" 4 "Upper secondary education vocational" 5 "Upper secondary education general" 6"Post-secondary not-tertiary education general" 7"First stage of tertiary education" 8"Second stage of tertiary education"
label values education education
tab education


*saving the datasets
save basic_eha.dta, replace

*splitting the data
gen policy_start1=1274
gen policy_start2=1286
gen policy_start3=1298
gen policy_start4=1310
gen policy_start5=1322
gen policy_start6=1334
gen policy_start7=1346
gen policy_start8=1358
gen policy_start9=1370
gen policy_start10=1382
gen policy_start11=1394
gen policy_start12=1406
gen policy_start13=1418
foreach var of varlist policy_start* {
replace `var'=. if `var'+12<=dobk1
}

*the first interval of policy measures
egen split_start=rowfirst(policy_start*)
stsplit policy, at(0(12)36) after(split_start)

*assigning residence to the episodes
foreach var of varlist interviewdate* {
replace `var'=. if `var'+12<=dobk1
}
*first interview
gen wave=.
replace wave=1 if END<=interviewdate1 
replace wave=2 if END<=interviewdate2+1 & END>=interviewdate1
replace wave=3 if END<=interviewdate3+1 & END>=interviewdate2
replace wave=4 if END<=interviewdate4+1 & END>=interviewdate3
replace wave=5 if END<=interviewdate5+1 & END>=interviewdate4
replace wave=6 if END<=interviewdate6+1 & END>=interviewdate5
replace wave=7 if END<=interviewdate7+1 & END>=interviewdate6
replace wave=8 if END<=interviewdate8+1 & END>=interviewdate7
replace wave=9 if END<=interviewdate10+1 & END>=interviewdate8
replace wave=10 if END>=interviewdate10
tab wave

*Residence
foreach var of varlist bula* {
replace `var'=16 if `var'==1
replace `var'=1 if `var'==2
replace `var'=2 if `var'==3		
replace `var'=3 if `var'==4		
replace `var'=4 if `var'==5		
replace `var'=5 if `var'==6
replace `var'=6 if `var'==7
replace `var'=7 if `var'==8
replace `var'=8 if `var'==9
replace `var'=9 if `var'==10	
replace `var'=10 if `var'==11 | `var'==11	
replace `var'=11 if `var'==12
replace `var'=12 if `var'==13
replace `var'=13 if `var'==14
replace `var'=14 if `var'==15
replace `var'=15 if `var'==16
}

*time-varying residence
gen State=.
replace State=bula1 if wave==1
replace State=bula2 if wave==2
replace State=bula3 if wave==3
replace State=bula4 if wave==4
replace State=bula5 if wave==5
replace State=bula6 if wave==6
replace State=bula7 if wave==7
replace State=bula8 if wave==8
replace State=bula9 if wave==9
replace State=bula10 if wave==10

*** fill missing values ********************************************************
* fill missing values using the last non-missing value
bysort id: carryforward State, gen(s)
replace State = s if State == .
drop s

* fill missing values using the first non-missing value
generate negt = -_t0
sort id negt
by id: carryforward State, gen(s)
replace State = s if State == .
drop s
sort id _t0
bro id State _t0


*time-varying area structure
gen structure=.
replace structure=bik1 if wave==1
replace structure=bik2 if wave==2
replace structure=bik3 if wave==3
replace structure=bik4 if wave==4
replace structure=bik5 if wave==5
replace structure=bik6 if wave==6
replace structure=bik7 if wave==7
replace structure=bik8 if wave==8
replace structure=bik9 if wave==9
replace structure=bik10 if wave==10
*increase by size and density
gen regstructure=10-structure

*label the new variable 
label variable regstructure "Settlement structure"
label define regstructure 1 "Region- population<2,000" 2 "Region-  population 2,0000-5,000" 3 "Region-population 5,000-20,0000" 4 "Region-population 20,000-50,000 " ///
5 "Periphery - population 50,000-100,000" 6 "City Center - Population 50,000-100,000" 7 "Periphery- popualtion 100,000-500,000" ///
8 "City Center - popualtion 100,000-500,000" 9 "Periphery - population 500,000+" 10 "City Center - population 500,000+"
label values regstructure regstructure

*gen population density
gen popdens=.
replace popdens=gkpol1 if wave==1
replace popdens=gkpol2 if wave==2
replace popdens=gkpol3 if wave==3
replace popdens=gkpol4 if wave==4
replace popdens=gkpol5 if wave==5
replace popdens=gkpol6 if wave==6
replace popdens=gkpol7 if wave==7
replace popdens=gkpol8 if wave==8
replace popdens=gkpol9 if wave==9
replace popdens=gkpol10 if wave==10


*label the new variable 
label variable popdens "Population density"
label define popdens 1 "1,000-2,000 inhabitants" 2 "2,0000-5,000 inhabitants" ///
3 "5,000-20,0000 inhabitants" 4 "Region-population 20,000-50,000 " ///
5 "50,000-100,000 inhabitants" 6 "100,000-500,000 inhabitants" 7 " 500,000+ inhabitants" 
label values popdens popdens

*generate householdincome
gen hhincome=.
replace hhincome=hhincnet1 if wave==1
replace hhincome=hhincnet2 if wave==2
replace hhincome=hhincnet3 if wave==3
replace hhincome=hhincnet4 if wave==4
replace hhincome=hhincnet5 if wave==5
replace hhincome=hhincnet6 if wave==6
replace hhincome=hhincnet7 if wave==7
replace hhincome=hhincnet8 if wave==8
replace hhincome=hhincnet9 if wave==9
replace hhincome=hhincnet10 if wave==10


*label the state variable
generate policy_start=.
replace policy_start=split_start if _t0==0
replace policy_start=_origin+_t0 if _t0!=0


*merge the policy data with the split data
sort policy_start State
merge m:m State policy_start using context-data.dta

*drop cases without residence informaton
sort id _t0
by id: gen NR=_n
by id: egen ddd=count(State)
by id: drop if NR==NR-ddd
drop ddd
replace Event=0 if DURATION>=37

*generyte time-constant income variable
gen income=.
by id, sort: egen birth_wave=min(wave)
replace income=hhincnet1 if birth_wave==1
replace birth_wave=birth_wave-1 if birth_wave!=1
replace income=hhincnet1 if birth_wave==1 & income==.
replace income=hhincnet2 if birth_wave==2 & income==.
replace income=hhincnet3 if birth_wave==3 & income==.
replace income=hhincnet4 if birth_wave==4 & income==.
replace income=hhincnet5 if birth_wave==5 & income==.
replace income=hhincnet6 if birth_wave==6 & income==.
replace income=hhincnet7 if birth_wave==7 & income==.
replace income=hhincnet8 if birth_wave==8 & income==.
replace income=hhincnet9 if birth_wave==9 & income==.
replace income=hhincnet10 if birth_wave==10 & income==.
label variable income "Time-constant householdincome"
*completed income variable
egen income2=rowmedian(hhincnet*) if income==.
replace income2=income if income2==.
label variable income2 "Time-constant projection hhincome"

*time constant preferences
gen attitude=.
replace attitude=val1i31 if birth_wave==1
replace attitude=val1i32 if birth_wave==2
replace attitude=val1i33 if birth_wave==3
replace attitude=val1i34 if birth_wave==4
replace attitude=val1i35 if birth_wave==5
replace attitude=val1i36 if birth_wave==6
replace attitude=val1i37 if birth_wave==7
replace attitude=val1i38 if birth_wave==8
replace attitude=val1i39 if birth_wave==9
replace attitude=val1i310 if birth_wave==10
gen wf_preferences=.
replace wf_preferences=1 if attitude<=2
replace wf_preferences=2 if attitude==3
replace wf_preferences=3 if attitude>=4 & attitude!=.
replace wf_preferences=1 if attitude==. & val1i31<=2
replace wf_preferences=2 if attitude==. & val1i31==3
replace wf_preferences=3 if attitude==. & val1i31>=4
label variable wf_preferences "Work-family attitude"
label define wf_preferences 1 "Work-orientation" 2 "Neutral" 3"Family-orientation"
label values wf_preferences wf_preferences

*split for time dependent variables
stsplit time, at(12 24 36)
tab time, gen(t)
edit
*manipulate East-West variable
replace East=1 if East==2
*education variables
gen educ=.
label variable educ "Educational level"
replace educ=1 if education<=3
replace educ=2 if education==4 | education==5
replace educ=3 if education==6 | education==7 | education==8
lab define educ 1 "Low" ///
2"Intermediate" 3"High"
lab values educ educ

*replace popdens
gen city=.
replace city=1 if popdens>=5 & popdens!=.
replace city=0 if popdens<=4
label variable city "Rural area"
label define city 1"Urban area" 0"Rural area"
label values city city

*stratum
gen stratum=.
replace stratum=1 if income2<=1405
replace stratum=2 if income2>=1406 & income2<=6152
replace stratum=3 if income2>=6153
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

*create a dummy for a childbirthbirth before the return to employment
///creating a variable for the timepoint of second birth
gen rep_birth=.
replace rep_birth=birthspace if twins==0 & birthspace<=36
replace rep_birth=birthspace2 if twins==1 & birthspace2<=36

*splitting episodes in before and after
stsplit second_child, at(0) after(_t=rep_birth)
replace second_child=1 if second_child==0 & rep_birth!=.
replace second_child=0 if second_child==-1

*label variable
label variable second_child "Second childbirth"
label define second_child 0 "no" 1"second childbirth"
label values second_child second_child

* generate an age variabel
gen age = .
replace age = int((dobk1 - dob)/12)
histogram age

*reduce dataset
keep id dob cumulative_work_experience DURATION dobk1 demodiff birthspace twins alteroutcome birthspace2 loneparent censor cumulative_work_experience intdat_max stratum Event  END _st _d _origin _t _t0 education wf_preferences time educ policy income income2 t1 t2 t3 t4 State regstructure popdens hhincome  policy_start Bundesländer *weight1  childtoadultratio enrollment qualificationstaff East city stratum free_childcare NR cohort unemploymentrate worked second_child quality age



*dataset for the investigations
save ANALYSIS.dta, replace


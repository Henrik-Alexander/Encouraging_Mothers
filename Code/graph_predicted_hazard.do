* save the data 
cd "U:/encouraging mothers/Encouraging Mothers"


* rename
rename hazard1 low
rename hazard2 average
rename hazard3 high


* plot
twoway(line hazard time if availability == 1,  ///
connect(stairstep) lcol(cranberry) lwidth (1.1) )   ///
 (line hazard time if availability == 2, ///
 connect(stairstep) lcol(dkgreen) lwidth (1.1) ) ///
 (line hazard time if availability == 3, ///
 connect(stairstep) lcol(dknavy)  lwidth (1.1)) 

 *
 save graph_data.dta
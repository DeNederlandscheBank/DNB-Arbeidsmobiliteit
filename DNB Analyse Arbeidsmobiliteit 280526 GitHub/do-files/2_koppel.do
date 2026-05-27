********************************************************************
*** 2_koppel.do        				    		 ***
*** Merge all seperate files into one analysis file 	 	 ***
*** Author: Cindy Biesenbeek (DNB)	 			 *** 	
*** March 2026 (edited by Maikel Volkerink & Astrid Ruland, DNB) ***
********************************************************************

************************************************************
/*
NOTES
  
*/
************************************************************

*** Settings
version 15
set more off
set dp comma
capture log close
log using "H:\logs\2_koppel.smcl", replace
local dir "H:\"

****************************************	
****************************************
*** 1. PREPARE ANALYTICAL DATA FILES ***
****************************************
****************************************

forval jaar = 2011/2024{

	*** Start with demographic data
		use "`dir'tussen\gba.dta", replace
		gen leeftijd = `jaar'+1 - year(geboortedatum) - 1
		label var leeftijd "Age"
		
	*** Select people of working age
		keep if leeftijd >=15 & leeftijd<75

	*** Add data about job one year ahead
		local nextjaar = `jaar'+1	
		merge 1:m rinpersoon using "`dir'\tussen\jobs`nextjaar'_peil.dta", keep (1 3) keepusing(beid hoofdbaan ikvid lnsv flex uren)

		keep if hoofdbaan==1|hoofdbaan==.
		drop _merge
		
	*** New job: merge firm information
		merge m:1 beid using "`dir'tussen\bedrijfsgegevens`nextjaar'", keep (1 3) keepusing(corop sbi sbi2 sbi5 grootteklasse)

	*** Rename variables to distinguish old and current job
		foreach var in beid ikvid corop sbi sbi2 sbi5 lnsv hoofdbaan flex grootteklasse uren {
			rename `var' `var'_new
			}
		drop _merge	
			
	*** Add data ab out current job
		merge 1:m rinpersoon using "`dir'\tussen\jobs`jaar'_peil.dta", keep (1 3) 
		keep if hoofdbaan==1|hoofdbaan==.
		drop _merge

	*** Current job: firm information
		merge m:1 beid using "`dir'tussen\bedrijfsgegevens`jaar'", keep (1 3)
		drop _merge	
		
	*** Distinguish temporary agency work as seperate category to SBI 1-digit industries	
		replace sbi=78 if sbi2==78
		label define sbi20081D_short 78 "78 Uitzendsector", modify
		
		replace sbi_new=78 if sbi2_new==78
		label define sbi20081D_short 78 "78 Uitzendsector", modify	
	
	*** Level of education
		merge 1:1 rinpersoon using "`dir'tussen\hoogsteopleiding`jaar'.dta", keep (1 3)
		drop _merge
		
	***********************************************************
	*** Make adjustments for non-standard jobs 				***
	*** These will not count as main jobs and will deleted	***
	***********************************************************

		replace hoofdbaan =. if !inrange(flex,1,4) /*remove dga's and other jobs such as interns*/
		replace hoofdbaan =. if inrange(sbi2,97,99) /*remove jobs at extratorrital organisations and households as employer*/
		
		replace sbi =. if inrange(sbi2,97,99) /*remove jobs at extratorrital organisations and households as employer*/
		replace sbi =. if !inrange(flex,1,4) /*remove dga's and other jobs such as interns*/
		
		replace hoofdbaan_new =. if !inrange(flex_new,1,4) /*remove dga's and other jobs such as interns*/
		replace hoofdbaan_new =. if inrange(sbi2_new,97,99) /*remove jobs at extratorrital organisations and households as employer*/
		
		replace sbi_new =. if inrange(sbi2_new,97,99) /*remove jobs at extratorrital organisations and households as employer*/
		replace sbi_new =. if !inrange(flex_new,1,4) /*remove dga's and other jobs such as interns*/

		drop if hoofdbaan==.&hoofdbaan_new==.
		
	**********************************
	*** Create additonal variables ***
	**********************************
	
	*** Age groups
		gen agegroup = .
			replace agegroup = 1 if leeftijd>=15 & leeftijd<25
			replace agegroup = 2 if leeftijd>=25 & leeftijd<35
			replace agegroup = 3 if leeftijd>=35 & leeftijd<45
			replace agegroup = 4 if leeftijd>=45 & leeftijd<55
			replace agegroup = 5 if leeftijd>=55 & leeftijd<65
			replace agegroup = 6 if leeftijd>=65 & leeftijd<75
			
		label def agegroup 1 "15 tot 25" 2 "25 tot 35" 3 "35 tot 45" 4 "45 tot 55" 5 "55 tot 65" 6 "65 tot 75"
		label val agegroup agegroup
		label var agegroup "Age in 10y categories"
		
	*** Job switch (employer - beid)
		replace beid="" if hoofdbaan==.
		replace beid_new="" if hoofdbaan_new==.
		
		gen switch_beid=.
			replace switch_beid=0 if beid==beid_new & beid!=""
			replace switch_beid=1 if beid!=beid_new & beid_new!="" & beid!=""
		label var switch_beid "Indicator for switch in main employer - beid"

	*** Job switch (employer - beid, include missing)
		gen beid_missing = beid
			replace beid_missing = "999" if hoofdbaan==.
	
		gen beid_new_missing = beid_new 
			replace beid_new_missing = "999" if hoofdbaan_new==.
	
		gen switch_beid_missing=.
			replace switch_beid_missing=0 if beid_missing==beid_new_missing
			replace switch_beid_missing=1 if beid_missing!=beid_new_missing
		label var switch_beid_missing "Indicator for switch in main employer - beid incl. missing"
* 		drop beid_missing beid_new_missing

	
	*** Additional variable that identifies entry and exit for employees as well
		gen switch_beid_stream = switch_beid 
			replace switch_beid_stream = 3 if hoofdbaan==. 			// entry
			replace switch_beid_stream = 4 if hoofdbaan_new==. 		// exit
		
	*** Job switch (main sector, include missing)
		gen sbi_missing = sbi
		replace sbi_missing = 999 if beid_missing == "999"
		
		gen sbi_new_missing = sbi_new
		replace sbi_new_missing = 999 if beid_new_missing == "999"

	*** Job switch (within and between sbi switch)
	
		gen 	within_sbi = 1 if (sbi==sbi_new) & switch_beid==1 & hoofdbaan!=. & hoofdbaan_new!=. 
		replace within_sbi = 0 if (sbi!=sbi_new) & switch_beid==1 & hoofdbaan!=. & hoofdbaan_new!=.
		
		gen 	within_sbi_missing = 1 if (sbi_missing==sbi_new_missing) & switch_beid_missing==1 
		replace within_sbi_missing = 0 if (sbi_missing!=sbi_new_missing) & switch_beid_missing==1 
		
		gen 	within_sbi2 = 1 if (sbi2==sbi2_new) & switch_beid==1 & hoofdbaan!=. & hoofdbaan_new!=.
		replace within_sbi2 = 0 if (sbi2!=sbi2_new) & switch_beid==1 & hoofdbaan!=. & hoofdbaan_new!=.

	
	************************************
	*** DEEPEN IN PARTICULAR SECTORS ***
	************************************


	*******************************************************************************
	/*
	NOTES
	Based on GPD/hour from Statline to identify high productivity sectors
	The numbers are sbi codes, not observations
	Chemical & pharma: 19-21
	Electronics & machines: 26,27,28
	Telecommunications & IT: 61-63

	Primary education: 852
	Secondary education: 853

	Health care: 86
	Social care: 87  
	Home care: 881
	Child care: 8891
	*/
	*******************************************************************************

	gen clusters = .
		replace clusters=1 if inrange(sbi2,19,21)&hoofdbaan!=.
		replace clusters=2 if inrange(sbi2,26,28)&hoofdbaan!=.
		replace clusters=3 if inrange(sbi2,61,63)&hoofdbaan!=.
		replace clusters=4 if inrange(sbi5,85200,85299)&hoofdbaan!=.
		replace clusters=5 if inrange(sbi5,85300,85399)&hoofdbaan!=.
		replace clusters=6 if sbi2==86&hoofdbaan!=.
		replace clusters=7 if sbi2==87&hoofdbaan!=.
		replace clusters=8 if inrange(sbi5,88100,88199)&hoofdbaan!=.
		replace clusters=9 if inrange(sbi5,88910,88919)&hoofdbaan!=.
		replace clusters=10 if inrange(sbi5,84220,84229)&hoofdbaan!=.

	gen clusters_new = .
		replace clusters_new=1 if inrange(sbi2_new,19,21)&hoofdbaan_new!=.
		replace clusters_new=2 if inrange(sbi2_new,26,28)&hoofdbaan_new!=.
		replace clusters_new=3 if inrange(sbi2_new,61,63)&hoofdbaan_new!=.
		replace clusters_new=4 if inrange(sbi5_new,85200,85299)&hoofdbaan_new!=.
		replace clusters_new=5 if inrange(sbi5_new,85300,85399)&hoofdbaan_new!=.
		replace clusters_new=6 if sbi2_new==86&hoofdbaan_new!=.
		replace clusters_new=7 if sbi2_new==87&hoofdbaan_new!=.
		replace clusters_new=8 if inrange(sbi5_new,88100,88199)&hoofdbaan_new!=.
		replace clusters_new=9 if inrange(sbi5_new,88910,88919)&hoofdbaan_new!=.
		replace clusters_new=10 if inrange(sbi5_new,84220,84229)&hoofdbaan_new!=.
	
	#delimit ;
		label def clusters
	
		1 	"Chemical & pharma"
		2	"Electronics & machines"
		3	"IT & telecommunications"
		4	"Primary education" 	
		5	"Secondary education" 
		6	"Health care"
		7	"Residential care"
		8	"Home care"
		9 	"Child care"
		10  "Defense activities"
		11	"Defense industry"
		;

	#delimit cr
	
	label val clusters 		clusters
	label val clusters_new 	clusters
	
	gen 	within_clusters = 1 if (clusters==clusters_new) & switch_beid==1
	replace within_clusters = 0 if (clusters!=clusters_new) & switch_beid==1

	************
	*** Save ***
	************

	//Save
	compress
	save "`dir'analysebestand\analysebestand`jaar'.dta", replace
	}


	*************************************************
	*** Append several years and save master file ***
	*********************************  **************
	
	*** Open first year dataset
		use "H:\analysebestand\analysebestand2011.dta", clear
		gen int year=2011
				
	*** Append additional years	
		forval jaar = 2012/2023{
			append using "H:\analysebestand\analysebestand`jaar'.dta"
			replace year=`jaar' if year==.
			}
		save "H:\analysebestand\analysebestand.dta", replace

log close

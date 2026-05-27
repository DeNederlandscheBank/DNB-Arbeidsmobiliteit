****************************************************************
*** 3_output.do        				    	     ***
*** create tables used in DNB Analyses May 2026 	     ***
*** Author: Maikel Volkerink				     *** 	
*** March 2026						     ***
****************************************************************

************************************************************
/*
  
*/
************************************************************

*** Settings
set more off
set dp comma
capture log close
local dir "H:\"

log using "H:\logs\3_output.smcl", replace
version 15
set dp comma

***********************************************	
***********************************************
*** 1. Read data and make final adjustments ***
***********************************************
***********************************************

	use "H:\analysebestand\analysebestand.dta", clear

*** some housekeeping
*	drop beid beid_missing beid_new beid_new_missing ikvid ikvid_new slbaanid
*	drop switch_ikvid switch_sector switch_subsector startjob geboortedatum eindbaan startjob
	aorder 
	order rinpersoon year

*** adhoc additional clusters
	replace clusters 	 = 998 if clusters==. 	  & sbi!=. 	   & hoofdbaan==1
	replace clusters_new = 998 if clusters_new==. & sbi_new!=. & hoofdbaan_new==1

	replace within_clusters = 1 if (clusters==clusters_new) & switch_beid==1 
	replace within_clusters = 0 if (clusters!=clusters_new) & switch_beid==1

	ren sbi2 sbi2d
	ren sbi5 sbi5d	


***********************************************	
***********************************************
*** 2. Create tables ***
***********************************************
***********************************************

***********************************
*** Basic descriptives
***********************************

	tab 			year, mi
	tab hoofdbaan  		year, mi
	tab hoofdbaan_new 	year, mi


***********************************
*** Macro series
***********************************

	tab switch_beid 	year, mi
	tab switch_beid 	year if hoofdbaan==1, mi
	tab switch_beid_stream  year, mi	


***********************************
*** Mobility. by characteristic
***********************************

	tab geslacht 		year if hoofdbaan==1, mi
	tab agegroup 		year if hoofdbaan==1, mi
	tab opleidingsniveau 	year if hoofdbaan==1, mi
	tab flex 		year if hoofdbaan==1, mi
	tab uren 		year if hoofdbaan==1, mi
	tab grootteklasse 	year if hoofdbaan==1, mi

	tab geslacht 		year if hoofdbaan==1 & switch_beid_stream==1, mi
	tab agegroup 		year if hoofdbaan==1 & switch_beid_stream==1, mi
	tab opleidingsniveau 	year if hoofdbaan==1 & switch_beid_stream==1, mi
	tab flex 		year if hoofdbaan==1 & switch_beid_stream==1, mi
	tab uren 		year if hoofdbaan==1 & switch_beid_stream==1, mi
	tab grootteklasse 	year if hoofdbaan==1 & switch_beid_stream==1, mi

	tab geslacht 		year if 			   switch_beid_stream==4, mi
	tab agegroup 		year if 			   switch_beid_stream==4, mi
	tab opleidingsniveau 	year if 			   switch_beid_stream==4, mi
	tab flex 		year if 			   switch_beid_stream==4, mi
	tab uren 		year if 			   switch_beid_stream==4, mi
	tab grootteklasse 	year if 			   switch_beid_stream==4, mi

	
***********************************
*** Mobility, per sector
***********************************

	label val sbi*
	label val sbi_new*

***	Characteristics	
	tab sbi geslacht 		if hoofdbaan==1 & year==2024, mi
	tab sbi agegroup 		if hoofdbaan==1 & year==2024, mi
	tab sbi opleidingsniveau 	if hoofdbaan==1 & year==2024, mi
	tab sbi flex 			if hoofdbaan==1 & year==2024, mi
	tab sbi uren 			if hoofdbaan==1 & year==2024, mi
	tab sbi grootteklasse 		if hoofdbaan==1 & year==2024, mi	

*** A: total job to job switchers, per sector (1-digit)
	table sbi year if hoofdbaan==1						  , format(%12.0f) row col nol
	table sbi year if hoofdbaan==1 & switch_beid_stream==1, format(%12.0f) row col nol
	table sbi year if 				 switch_beid_stream==4, format(%12.0f) row col nol

*** B: job-to-job mobility, within-between, per sector (1-digit)	
	table sbi year if hoofdbaan==1 & switch_beid==1 & within_sbi==1 , format(%12.0f) row col
	
	
	*********************************************
	*** adhoc adjustments for output controle ***
	*********************************************
	
		clonevar sbi2=sbi
		replace  sbi2=3  if sbi==2 // add B Mining to C Manufacturing
		replace  sbi2=4  if sbi==5 // add E Waste to D Energy
		
		clonevar sbi_new2=sbi_new
		replace  sbi_new2=3  if sbi_new==2 // add B Mining to C Manufacturing
		replace  sbi_new2=4  if sbi_new==5 // add E Waste to D Energy

		clonevar sbi_missing2=sbi_missing
		replace  sbi_missing2=3  if sbi_missing==2 // add B Mining to C Manufacturing
		replace  sbi_missing2=4  if sbi_missing==5 // add E Waste to D Energy
		
		clonevar sbi_new_missing2=sbi_new_missing
		replace  sbi_new_missing2=3  if sbi_new_missing==2 // add B Mining to C Manufacturing
		replace  sbi_new_missing2=4  if sbi_new_missing==5 // add E Waste to D Energy
		
		label val sbi*
		label val sbi_new*

*** C: job-to-job mobility, intersectoral mobility 2023, per sector (1-digit)
	table sbi2 sbi_new_missing2 	if hoofdbaan==1 & switch_beid_missing==1 & year==2023 & within_sbi!=1, row col 
	table sbi2 sbi_new_missing2 	if hoofdbaan==1 & switch_beid_missing==1 & year==2023				 , row col

	table sbi2 sbi_new_missing2 	if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1, row col 
	table sbi2 sbi_new_missing2 	if hoofdbaan==1 & switch_beid_missing==1 & year==2024				 , row col

	
	***********************************************
	***********************************************
	*** focus on type of contract and education ***
	***********************************************
	***********************************************
	
		ren sbi2 sbi2d
		ren sbi5 sbi5d	

		*** adhoc for SZW - delete in final run!!!
			clonevar sbi2=sbi
			replace  sbi2=3  if sbi==2 // add B Mining to C Manufacturing
			replace  sbi2=4  if sbi==5 // add E Waste to D Energy
			
			clonevar sbi_new2=sbi_new
			replace  sbi_new2=3  if sbi_new==2 // add B Mining to C Manufacturing
			replace  sbi_new2=4  if sbi_new==5 // add E Waste to D Energy

			clonevar sbi_missing2=sbi_missing
			replace  sbi_missing2=3  if sbi_missing==2 // add B Mining to C Manufacturing
			replace  sbi_missing2=4  if sbi_missing==5 // add E Waste to D Energy
			
			clonevar sbi_new_missing2=sbi_new_missing
			replace  sbi_new_missing2=3  if sbi_new_missing==2 // add B Mining to C Manufacturing
			replace  sbi_new_missing2=4  if sbi_new_missing==5 // add E Waste to D Energy
			
			clonevar   sbi_new_missing3 = sbi_new_missing
			replace    sbi_new_missing3 = 998 if !inlist(sbi_new_missing,7,78,999)	
			tab sbi_new_missing sbi_new_missing3, mi		
			
			label val sbi*
			label val sbi_new*	

		************************	
		*** Type of contract	
		************************
		
			table sbi2 flex if hoofdbaan==1 			 & year==2024   			  , row col // iedereen
			table sbi2 flex if hoofdbaan==1 & switch_beid_stream==1  & year==2024   			  , row col	// baanbaan 
			table sbi2 flex if hoofdbaan==1 & switch_beid_stream==4  & year==2024   			  , row col	// uitstroom 
			table sbi2 flex if hoofdbaan==1 & switch_beid_missing==1 & year==2024   			  , row col	// baanbeindigers
			
			table sbi2 flex if hoofdbaan==1 & switch_beid_stream==1  & year==2024 & within_sbi==1 , row col	// baan-baan | within 
			table sbi2 flex if hoofdbaan==1 & switch_beid_stream==1  & year==2024 & within_sbi!=1 , row col	// baan-baan | between 

			table flex sbi_new_missing2 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1, row col 				// total, per flex-type
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1, row col 				// total
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1 & flex==1, row col	// permanent contract 
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1 & flex==2, row col	// temporary contract 
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1 & flex==3, row col	// agency workers 
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1 & flex==4, row col	// on call workers 

			table flex sbi_new_missing2 if hoofdbaan==1 & switch_beid_missing==1 & year==2024, row col 				// total, per flex-type
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024, row col 				// total
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & flex==1, row col	// permanent contract 
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & flex==2, row col	// temporary contract 
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & flex==3, row col	// agency workers 
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & flex==4, row col	// on call workers 
			
		**************************
		*** Level of education	
		**************************
			table sbi2 opleidingsniveau if hoofdbaan==1 			     & year==2024   			  , row col // iedereen
			table sbi2 opleidingsniveau if hoofdbaan==1 & switch_beid_stream==1  & year==2024   			  , row col	// baanbaan 
			table sbi2 opleidingsniveau if hoofdbaan==1 & switch_beid_stream==4  & year==2024   			  , row col	// uitstroom 
			table sbi2 opleidingsniveau if hoofdbaan==1 & switch_beid_missing==1 & year==2024   			  , row col	// baanbeindigers
			
			table sbi2 opleidingsniveau if hoofdbaan==1 & switch_beid_stream==1  & year==2024 & within_sbi==1 , row col	// baan-baan | within 
			table sbi2 opleidingsniveau if hoofdbaan==1 & switch_beid_stream==1  & year==2024 & within_sbi!=1 , row col	// baan-baan | between 

			table opleidingsniveau sbi_new_missing2 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1, row col 				// total, per opleidingsniveau-type
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1, row col 							// total
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1 & opleidingsniveau==1, row col	// laag 
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1 & opleidingsniveau==2, row col	// middelbaar
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1 & opleidingsniveau==3, row col	// bachelor
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1 & opleidingsniveau==4, row col	// master

			table opleidingsniveau sbi_new_missing2 if hoofdbaan==1 & switch_beid_missing==1 & year==2024, row col 				// total, per opleidingsniveau-type
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024, row col 							// total
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & opleidingsniveau==1, row col	// laag 
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & opleidingsniveau==2, row col	// middelbaar
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & opleidingsniveau==3, row col	// bachelor
			table sbi2 sbi_new_missing3 if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & opleidingsniveau==4, row col	// master
		

	
*** D: inflow

	*** macro
		tab switch_beid year if hoofdbaan_new==1, mi
		table sbi_new   year if hoofdbaan_new==1, row col format(%12.0f)
	
	table sbi_new2 sbi_missing2 if hoofdbaan_new==1 & switch_beid_missing==1 & year==2023					, row col
	table sbi_new2 sbi_missing2 if hoofdbaan_new==1 & switch_beid_missing==1 & year==2023 & within_sbi!=1	, row col 

	table sbi_new2 sbi_missing2 if hoofdbaan_new==1 & switch_beid_missing==1 & year==2024					, row col
	table sbi_new2 sbi_missing2 if hoofdbaan_new==1 & switch_beid_missing==1 & year==2024 & within_sbi!=1	, row col 

	
***********************************
***********************************
*** CLUSTERS
***********************************
***********************************

***********************************
*** Clusters, by characteristic
***********************************

*** First overall 
	tab clusters 	 year if hoofdbaan==1	 , mi


***	Characteristics	
	tab clusters geslacht 		if hoofdbaan==1 & year==2024, mi
	tab clusters agegroup 		if hoofdbaan==1 & year==2024, mi
	tab clusters opleidingsniveau 	if hoofdbaan==1 & year==2024, mi
	tab clusters flex 		if hoofdbaan==1 & year==2024, mi
	tab clusters uren 		if hoofdbaan==1 & year==2024, mi
	tab clusters grootteklasse 	if hoofdbaan==1 & year==2024, mi

*** adhoc because of output controle

	clonevar flex2=flex
	replace  flex2=3 if flex==4
	
	tab clusters flex2 if hoofdbaan==1 & year==2024, mi
	tab clusters flex2 if hoofdbaan==1 & clusters==10, mi
	tab clusters flex  if hoofdbaan==1 & clusters==10, mi

	clonevar grootteklasse2=grootteklasse
	replace  grootteklasse2=1 if inrange(grootteklasse,1,3)
	
	tab clusters grootteklasse2 if hoofdbaan==1 & clusters==10, mi
	tab clusters grootteklasse  if hoofdbaan==1 & clusters==10, mi

	
***********************************
*** Mobility, per cluster
***********************************

	label val sbi*
	label val sbi_new*


*** A: total job to job switchers, per sector (1-digit)
	table clusters year if hoofdbaan==1			   , format(%12.0f) row col mi
	table clusters year if hoofdbaan==1 & switch_beid_stream==1, format(%12.0f) row col mi
	table clusters year if 		      switch_beid_stream==4, format(%12.0f) row col mi

*** B: job-to-job mobility, within-between, per sector (1-digit)	
	table clusters year if hoofdbaan==1 & switch_beid==1 & within_clusters==1 , format(%12.0f) row col
	
	*** adhoc for output controle
		tab clusters if hoofdbaan==1 & switch_beid==1 & within_clusters==1

*** C: job-to-job mobility, intersectoral mobility 2023, per sector (1-digit)	

	*** adhoc for output controle
		replace  sbi_missing2=11 	 if sbi_missing==12 // add L Real estate to K Financial
		replace  sbi_new_missing2=11 if sbi_new_missing==12 // add L Real estate to K Financial

	table clusters sbi_new_missing2	if hoofdbaan==1 & switch_beid_missing==1 & year==2023 & within_clusters!=1, row col 
	table clusters sbi_new_missing2 if hoofdbaan==1 & switch_beid_missing==1 & year==2023				 	  , row col
		
	table clusters sbi_new_missing2	if hoofdbaan==1 & switch_beid_missing==1 & year==2024 & within_clusters!=1, row col 
	table clusters sbi_new_missing2 if hoofdbaan==1 & switch_beid_missing==1 & year==2024				 	  , row col

	
*** D: inflow
	
	*** macro
*	tab clusters_new year if hoofdbaan_new==1, mi

	table clusters_new sbi_missing2 if hoofdbaan_new==1 & switch_beid_missing==1 & year==2023					  , row col
	table clusters_new sbi_missing2 if hoofdbaan_new==1 & switch_beid_missing==1 & year==2023 & within_clusters!=1, row col 

	table clusters_new sbi_missing2 if hoofdbaan_new==1 & switch_beid_missing==1 & year==2024					  , row col
	table clusters_new sbi_missing2 if hoofdbaan_new==1 & switch_beid_missing==1 & year==2024 & within_clusters!=1, row col 

*/

log close


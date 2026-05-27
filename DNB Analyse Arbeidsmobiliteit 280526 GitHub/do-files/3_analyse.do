
********************************************************************
*** 3_analyse.do        				    	 ***
*** Create descriptive tables and do regressions		 ***
*** Author: Cindy Biesenbeek & Astrid Ruland (DNB)		 *** 	
*** December 2025						 ***
********************************************************************

************************************************************
/*
NOTES: in this dofile, we create tables with the number of job switches and other analyses 
  
*/
************************************************************

*** Settings
set more off
set dp comma
capture log close
log using "H:\logs\3_analyse.smcl", replace
local dir "H:\resultaten\export\"

**************************
*** 1. General verview ***
**************************

*** Open dataset
	use "H:\analysebestand\analysebestand.dta", clear

*** Total number of switches per year
	tabout year using "`dir'\switches_overview.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) replace


***********************************
*** 2. Detailed characteristics ***
***********************************

*** Open dataset
	use "H:\analysebestand\analysebestand_2024.dta", clear
	keep if hoofdbaan != . 
	keep if hoofdbaan_new != .  

*** Individual characteristics
	tabout geslacht using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout agegroup using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout opleidingsniveau using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append

*** Job characterics
	tabout flex using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout uren using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout grootteklasse using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append

*** Sector of employment
	tabout sbi using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout sbi_new using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout sbi2 using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout sbi2_new using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append

*** Other not main variables of interest
	tabout herkomst using "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout corop using  "`dir'\switches_chars.xlsx", c(count switch_beid mean switch_beid count switch_sector mean switch_sector count switch_subsector mean switch_subsector) sum format(0 4 0 4 0 4) append
	tabout corop corop_new if switch_beid==1 using "`dir'\switches_chars.xlsx", c(count switch_sector) sum format(0) append

*** Wage change
	gen wagechange = (lnsv_new-lnsv)/lnsv
	tabout switch_beid using "`dir'\switches_wagechange.xlsx", c(count wagechange mean wagechange ) sum format (0 4)


*******************************************
*** 3. Detailed characteristics by year ***
*******************************************

*** Open dataset
	use "H:\analysebestand\analysebestand.dta", clear
	keep if hoofdbaan != . 
	keep if hoofdbaan_new != . 

*** Characteristics
foreach kenmerk in geslacht agegroup opleidingsniveau flex uren grootteklasse corop sbi sbi_new sbi2 sbi2_new{
	tabout `kenmerk' year using "`dir'\switches_chars_yearly.xlsx", c (count switch_beid) sum append format(0)
	tabout `kenmerk' year using "`dir'\switches_chars_yearly.xlsx", c (mean switch_beid) sum append format(4)
	}

******************* 
*** 4. Heatmaps ***
*******************

	use "H:\analysebestand\analysebestand.dta", clear

	tabout sbi_missing sbi_new_missing if switch_beid_missing==1 using "`dir'\switches_heatmap_missing.xlsx", c(count switch_beid_missing) sum format(0) append

	forval job_years = 2018(5)2023 {
		tabout sbi_missing sbi_new_missing if year==`job_years'&switch_beid_missing==1 using "`dir'\switches_heatmap_missing_yearly.xlsx", c(count switch_beid_missing) sum format(0) append
		}

*************************************************
*** 5. Zooming in on interesting SBI clusters ***
*************************************************

	local dir "H:\resultaten\export_december\"
	use "H:\analysebestand\analysebestand.dta", clear

	foreach val in 0 1 {
			tabout clusters year if switch_beid_stream==`val' using "`dir'\clusters_stream.xlsx", c (count switch_beid_stream) sum append format(0)
	}
	tabout clusters_new year if switch_beid_stream==3 using "`dir'\clusters_stream.xlsx", c (count switch_beid_stream) sum append format(0)
	tabout clusters year if switch_beid_stream==4 using "`dir'\clusters_stream.xlsx", c (count switch_beid_stream) sum append format(0)
	tabout clusters year if switch_beid==1&within_clusters==1 using "`dir'\clusters_stream.xlsx", c(count switch_beid) sum format(0) append


	foreach kenmerk in geslacht agegroup opleidingsniveau flex uren grootteklasse {
			tabout clusters `kenmerk' using "`dir'\clusters_`kenmerk'.xlsx", mi format(0) append 
			tabout clusters `kenmerk' if switch_beid==1 using "`dir'\clusters_`kenmerk'.xlsx", mi format(0) append
	}

	tabout clusters sbi_new_missing if switch_beid_missing==1 using "`dir'\clusters_sbi.xlsx", c(count switch_beid_missing) sum format(0) append
	tabout sbi_missing clusters_new if switch_beid_missing==1 using "`dir'\sbi_clusters.xlsx", c(count switch_beid_missing) sum format(0) append

	forval job_years = 2018(5)2023 {
		tabout clusters sbi_new_missing if year==`job_years'&switch_beid_missing==1 using "`dir'\clusters_sbi_years.xlsx", c(count switch_beid_missing) sum format(0) append
		tabout sbi_missing clusters_new if year==`job_years'&switch_beid_missing==1 using "`dir'\sbi_clusters_years.xlsx", c(count switch_beid_missing) sum format(0) append
		foreach kenmerk in geslacht agegroup opleidingsniveau flex uren grootteklasse {
			tabout clusters `kenmerk' if year==`job_years' using "`dir'\clusters_`kenmerk'_years.xlsx", mi format(0) append 
			tabout clusters `kenmerk' if year==`job_years'&switch_beid==1 using "`dir'\clusters_`kenmerk'_years.xlsx", mi format(0) append
		}
	}


	tabout clusters year using "`dir'\clusters_with11_years.xlsx", mi format(0) append  


****************************************************************************
*** 6. General and detailed characteristics by year with in and out flow ***
****************************************************************************

	local dir "H:\resultaten\export_december\"
	use "H:\analysebestand\analysebestand.dta", clear

	tabout switch_beid_stream year using "`dir'\switches_stream_yearly.xlsx", c (count switch_beid_stream) sum append format(0)

	*** Characteristics
	foreach val in 0 1 3 4 {
	foreach kenmerk in geslacht agegroup opleidingsniveau{
			tabout `kenmerk' year if switch_beid_stream==`val' using "`dir'\switches_stream_yearly_`kenmerk'.xlsx", c (count switch_beid_stream) sum append format(0)
		}
	}

	foreach val in 0 1 {
	foreach kenmerk in flex uren grootteklasse sbi{
			tabout `kenmerk' year if switch_beid_stream==`val' using "`dir'\switches_stream_yearly_`kenmerk'.xlsx", c (count switch_beid_stream) sum append format(0)
		}
	}
	foreach kenmerk in flex uren grootteklasse sbi{
			tabout `kenmerk'_new year if switch_beid_stream==3 using "`dir'\switches_stream_yearly_`kenmerk'.xlsx", c (count switch_beid_stream) sum append format(0)
		}
	foreach kenmerk in flex uren grootteklasse sbi{
			tabout `kenmerk' year if switch_beid_stream==4 using "`dir'\switches_stream_yearly_`kenmerk'.xlsx", c (count switch_beid_stream) sum append format(0)
	}
	tabout sbi year if switch_beid==1&within_sbi==1 using "`dir'\switches_stream_yearly_sbi.xlsx", c(count switch_beid) sum format(0) append


*********************
*** 7. Regressies ***
*********************

	local dir "H:\resultaten\export_december\"
	use "H:\analysebestand\analysebestand.dta", clear

	keep if hoofdbaan != . 
	keep if hoofdbaan_new != . 

	gen leeftijd2 = leeftijd*leeftijd

	gen tenure_cat = .
	replace tenure_cat = 1 if tenure<2
	replace tenure_cat = 2 if tenure>= 2 & tenure <5
	replace tenure_cat = 3 if tenure>= 5 & tenure <10
	replace tenure_cat = 4 if tenure >=10 & tenure<.
	label def tenure 1 "Minder dan 2 jaar" 2 "2 tot 5 jaar" 3 "5 tot 10 jaar" 4 "10 jaar of meer"
	label val tenure_cat tenure


	logit switch_beid i.tenure_cat i.agegroup i.geslacht i.herkomst i.opleidingsniveau i.sbi i.grootteklasse i.flex i.uren i.corop 
	est store logit_beid

	logit switch_beid i.tenure_cat i.agegroup i.geslacht i.herkomst i.opleidingsniveau i.sbi i.grootteklasse##i.flex i.uren i.corop 
	est store logit_beidsizeflex

	logit switch_beid i.tenure_cat i.agegroup##i.opleidingsniveau  i.geslacht i.herkomst i.sbi i.grootteklasse i.flex i.uren i.corop 
	est store logit_beidageopl

	logit switch_beid i.tenure_cat i.agegroup##i.flex i.geslacht i.herkomst i.opleidingsniveau i.sbi i.grootteklasse i.uren i.corop 
	est store logit_beidageflex

	logit switch_sector i.tenure_cat i.agegroup i.geslacht i.herkomst i.opleidingsniveau i.sbi i.grootteklasse i.flex i.uren i.corop
	est store logit_sector

	logit switch_beid i.tenure_cat i.agegroup i.geslacht i.herkomst i.opleidingsniveau i.sbi i.grootteklasse i.flex i.uren i.corop i.year 
	est store logit_beidyear

	logit switch_beid tenure leeftijd leeftijd2 i.geslacht i.herkomst i.opleidingsniveau i.sbi i.grootteklasse i.flex i.uren i.corop i.year 
	est store logit_numeriek

	local dir "H:\resultaten\"
	estout logit_* using "`dir'\regressies.xlsx",  replace cells(b(star fmt(3)) se(par)) legend label stats(r2 N, fmt(3 0))


	tabout agegroup using "`dir'\regression_help.xlsx", c(count agegroup) sum format(0) append
	tabout geslacht using "`dir'\regression_help.xlsx", c(count geslacht) sum format(0) append
	tabout opleidingsniveau using "`dir'\regression_help.xlsx", c(count opleidingsniveau) sum format(0) append
	tabout sbi using "`dir'\regression_help.xlsx", c(count sbi) sum format(0) append
	tabout grootteklasse using "`dir'\regression_help.xlsx", c(count grootteklasse) sum format(0) append
	tabout flex using "`dir'\regression_help.xlsx", c(count flex) sum format(0) append
	tabout uren using "`dir'\regression_help.xlsx", c(count uren) sum format(0) append
	tabout uren using "`dir'\regression_help.xlsx", c(count uren) sum format(0) append
	tabout year using "`dir'\regression_help.xlsx", c(count year) sum format(0) append

	tabout leeftijd using "`dir'\regression_help.xlsx", c(count leeftijd) sum format(0) append
	tabout corop using "`dir'\regression_help.xlsx", c(count corop) sum format(0) append
	tabout tenure using "`dir'\regression_help.xlsx", c(count tenure) sum format(0) append
	tabout tenure_cat using "`dir'\regression_help.xlsx", c(count tenure_cat) sum format(0) append
	tabout herkomst using "`dir'\regression_help.xlsx", c(count herkomst) sum format(0) append
	tabout grootteklasse flex using "`dir'\regression_help.xlsx", c(count grootteklasse) sum format(0) append
	tabout agegroup opleidingsniveau using "`dir'\regression_help.xlsx", c(count agegroup) sum format(0) append
	tabout agegroup flex using "`dir'\regression_help.xlsx", c(count agegroup) sum format(0) append

*************
*** Close ***
*************

log close

************************************************************
*** 1_banen.do        				    	 ***
*** Read source data about jobs	(SPOLIS) 		 ***
*** Author: Cindy Biesenbeek (DNB)	 		 *** 	
*** January 2026 (edited by Maikel Volkerink, DNB)       ***
************************************************************

************************************************************
/*
NOTES

Explanation: This do-file reads in main data about Dutch employees and includes information of firm (BEID). Source data is monthly, we only look at main job in september. October is more common, yet in 2026-01 2025Q4 was not available yet In case of multiple jobs, job with highest wage (BASISLOON) is selected.  
*/
************************************************************

*** Settings
local dir "H:\"
set more off
set dp comma
capture log close
log using "`dir'logs\1_banen.smcl", append

*** locals for source data 
	local polis2006  "G:\Polis\POLISBUS\2006\geconverteerde data\POLISBUS2006V2.DTA"
	local polis2007  "G:\Polis\POLISBUS\2007\geconverteerde data\POLISBUS2007V2.dta"
	local polis2008  "G:\Polis\POLISBUS\2008\geconverteerde data\POLISBUS2008V2.dta"
	local polis2009  "G:\Polis\POLISBUS\2009\geconverteerde data\POLISBUS2009V2.DTA"
	local polis2010  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2010V3.DTA"   
	local polis2011  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2011V3.DTA"
	local polis2012  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2012V3.DTA"
	local polis2013  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2013V3.DTA"
	local polis2014  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2014V2.DTA"
	local polis2015  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2015V4.DTA"
	local polis2016  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2016V4.DTA"	 
	local polis2017  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2017V6.DTA"
	local polis2018  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2018V6.DTA"
	local polis2019  "G:\Spolis\SPOLISBUS\Geconverteerdedata\spolisbus2019V7.dta"
	local polis2020  "G:\Spolis\SPOLISBUS\Geconverteerdedata\spolisbus2020V6.DTA"
	local polis2021  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2021V6.DTA"
	local polis2022  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2022V6.DTA"
	local polis2023  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2023V5.DTA"
	local polis2024  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2024V4.DTA"
	local polis2024  "G:\Spolis\SPOLISBUS\Geconverteerdedata\SPOLISBUS2025V3.DTA"

	
****************************************************
****************************************************
*** 0. Recast koppeltabel to merge long job ids  ***
*** Only run with new new version of longbaantab ***
****************************************************
****************************************************

	use "H:\tussen\SPOLISLONGBAANTABV20241.dta", clear
	ren *, lower
	save "`dir'tussen\koppeltabel.dta", replace
	
	
************************************************************
************************************************************
*** 1. Read job data (2010-recent) and make yearly files ***
************************************************************
************************************************************

forval jaar = 2010/2025{
	local vars "rinpersoons rinpersoon ikvid sbasisloon slnsv scontractsoort sreguliereuren sbeid ssect ssoortbaan sdatumaanvangikv sdatumaanvangiko sdatumeindeiko swekarbduurklasse"
	use `vars' using "`polis`jaar''", clear
	rename *, lower
	keep if rinpersoons=="R"
		
	*** Rename variables, so both versions are the same (except baanrugid/ikvid and slbaanid)
		local varsrename "basisloon lnsv contractsoort beid sect soortbaan wekarbduurklasse"
		foreach v of local varsrename {
			rename s`v' `v'
			}
		
	*** Check duplicates
		duplicates tag rinpersoons rinpersoon ikvid sdatumaanvangiko, gen (dubbel)
		assert dubbel==0
		drop dubbel

	*** Create start and enddate job in date format (%td)
		gen beginbaan = date(sdatumaanvangikv,"YMD")
		gen eindbaan =  date(sdatumeindeiko,"YMD")
		gen aanvbaan =  date(sdatumaanvangiko,"YMD")
		format beginbaan eindbaan aanvbaan %td
		drop sdatumaanvangikv sdatumeindeiko sdatumaanvangiko

	
	*** Select only jobs in september 
		gen month = month(aanvbaan)
		keep if month==10
		drop month

	
	********************
	*** Merge job id ***
	********************

	*** To be used later to merge jobs over the years
		rename ikvid ikvid_old
		gen str32 ikvid = ikvid_old
		drop ikvid_old
		merge m:1 rinpersoons rinpersoon ikvid using "`dir'tussen\koppeltabel.dta", keep(1 3)
		drop _merge
		gen jobmerge = slbaanid
		replace jobmerge = ikvid if slbaanid==""

		
	****************************************
	*** Translate monthly to annual data ***
	****************************************
	
	*** Translate monthly data to annual data using job id
		gsort ikvid lnsv			
		local optellen 	 = "basisloon lnsv reguliereuren"
		local laatsteobs = "rinpersoon rinpersoons contractsoort beid sect soortbaan aanvbaan beginbaan wekarbduurklasse ikvid slbaanid"
		collapse (sum) `optellen' (lastnm) `laatsteobs' (last) eindbaan, by(jobmerge) fast

	*** Check again for duplicates to make sure previous step went well
		qui gduplicates tag ikvid, gen(dubbel)
		tab dubbel 
		drop dubbel		
		
	******************
	*** Add labels ***
	******************
	
	*** Rinpersoon
		rename rinpersoon rinpersoon_string
		gen long rinpersoon =real(rinpersoon_string)
				
	*** Hours worked
		destring wekarbduurklasse, gen(uren)
		label var uren "Number of hours worked per week"
		label def uren 1 "<12" 2 "12-20"  3 "20-25" 4 "25-30"  5 "30-35"  6 ">=35"
		label val uren uren
			
	*** Job type (permanent vs. flexible)
		gen flex = 6
		replace flex = 1 if soortbaan=="9" & (contractsoort=="2" | contractsoort=="O" | contractsoort=="o")
		replace flex = 2 if soortbaan=="9" & (contractsoort=="1" | contractsoort=="B" | contractsoort=="b")
		replace flex = 3 if soortbaan=="4"
		replace flex = 4 if soortbaan=="5"
		replace flex = 5 if soortbaan=="1"
		replace flex = . if soortbaan=="" | (soortbaan=="9" & contractsoort=="3")
			
	*** Label job type
	#delimit ;
		label def flex
		1 "Onbepaalde tijd" 
		2 "Bepaalde tijd"
		3 "Uitzend"
		4 "Oproep"
		5 "Dga"
		6 "Overig";
	#delimit cr
		label val flex flex
		label var flex "Contract type"
			
	*** Define main job
		bysort rinpersoons rinpersoon (basisloon): gen volgorde=_n
		bysort rinpersoons rinpersoon (basisloon): gen banen=_N
		gen hoofdbaan = 0
		replace hoofdbaan = 1 if volgorde==banen
			
		label def nj 0 "Nee" 1 "Ja"
		label val hoofdbaan nj
		label var hoofdbaan "Dummy for main job (based on highest basisloon)"
			
	*** Other labeling
		label var basisloon "Basic salary without suplements/bonuses/paid overwork)"
		label var lnsv "Total wage applicable to social contributions and taxes"
		label var beginbaan "Startdate of the job (<2012: administrative start date, >2012 actual start date)"
		label var eindbaan "Enddate of the job"
		label var ikvid "Job identifier"
		
		
	*******************************
	*** Save intermediate files ***
	*******************************
		
		keep ikvid beginbaan eindbaan flex beid lnsv basisloon rinpersoon hoofdbaan uren reguliereuren slbaanid
		order rinpersoon ikvid beginbaan eindbaan beid hoofdbaan lnsv basisloon reguliereuren flex uren slbaanid
	
		gsort rinpersoon beginbaan
		compress
		save "`dir'tussen\banen`jaar'_peil.dta", replace
	}	

	
**************************************
**************************************
*** 2. Calculate tenure per job id ***
**************************************
**************************************

*** Merge annual datasets
	use "`dir'tussen\banen2010_peil.dta", clear
	gen year = 2010
	forval jaar = 2011/2025{
		append using "`dir'tussen\banen`jaar'_peil.dta"
		replace year = `jaar' if year==.
		}

*** Find original starting date of the job (see comments in the top of dofile for explanation)
	bysort ikvid: egen beginbaan_orig2 = min(beginbaan) if ikvid!="" 
	bysort slbaanid: egen beginbaan_orig3 = min(beginbaan) if slbaanid!="" 

	egen startjob = rowmin(beginbaan_orig2 beginbaan_orig3)
	format startjob beginbaan_orig* %td
	label var startjob  "Original start date of the job"

	sort slbaanid year

*** Save multiyear dataset
	drop beginbaan_orig2 beginbaan_orig3
	save "`dir'tussen\banenall.dta", replace

	********************************
	*** Calculate tenure by year ***
	********************************

	forval jaar =  2010/2025{
		use "`dir'tussen\banenall.dta", clear
			gen yearstart = date("3112`jaar'", "DMY")
			gen tenure = floor((yearstart - startjob)/365.25)
			label var tenure "Current tenure at 1 jan of year, in days"
			keep if year==`jaar' 
			keep if hoofdbaan==1
			tab startjob
			drop yearstart year
			
		************************
		*** Save final files ***
		************************	
			
		save "`dir'tussen\jobs`jaar'_peil.dta", replace
		
		}

********************************
*** Erase intermediate files ***	
********************************

erase "`dir'tussen\banenall.dta"

forval jaar = 2010/2022{
	erase "`dir'tussen\banen`jaar'_peil.dta"
	}
	
log close

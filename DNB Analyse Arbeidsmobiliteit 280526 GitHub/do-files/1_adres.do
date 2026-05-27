************************************************************
*** 1_adres.do        				       	 			 ***
*** Read source data about residential addresses	     ***
*** Author: Cindy Biesenbeek (DNB)			 			 *** 	
*** January 2026		                         		 ***
************************************************************

************************************************************
/*
NOTES

Explanation: This do-file reads in residential address data, including the type of ownership for each address. The dataset contains all address “spells”. These are stored in separate files by year, each containing the address at which an individual resides on the reference date aka "peildatum" (the last day of September). If "Einddatum = 31dec2050" than person still lives at address
*/
************************************************************

*** Settings
local dir "H:\"
set more off
set dp comma
capture log close
log using "`dir'logs\1_adres.smcl", replace

*** locals for source data 
	local adres "G:\Bevolking\GBAADRESOBJECTBUS\geconverteerde data\GBAADRESOBJECT2023BUSV1.dta"
	local vsl 	"G:\BouwenWonen\VSLGWBTAB\geconverteerde data\VSLGWB2023TAB03V1.dta"
	local gin	"K:\Utilities\HULPbestanden\GebiedeninNederland\GIN2023.xlsx"

*** define peildatum
	local peildatum2006 "30092006"
	local peildatum2007 "30092007"
	local peildatum2008 "30092008"
	local peildatum2009 "30092009"
	local peildatum2010 "30092010"
	local peildatum2011 "30092011"
	local peildatum2012 "30092012"
	local peildatum2013 "30092013"
	local peildatum2014 "30092014"
	local peildatum2015 "30092015"
	local peildatum2016 "30092016"
	local peildatum2017 "30092017"
	local peildatum2018 "30092018"
	local peildatum2019 "30092019"
	local peildatum2020 "30092020"
	local peildatum2021 "30092021"
	local peildatum2022 "30092022"
	local peildatum2023 "30092023 "

	
*********************************
*********************************
*** 1. Clean area information ***
*********************************
*********************************

	import excel `gin', cellrange(A2:BB343)  clear
	ren *, lower

*** Label municipality
	gen gemeente = real(substr(a,3,4))
	gen gemeente_values = trim(b)
	label var gemeente "Municipality"

*** Label COROP regional classification
	gen corop = real(substr(g,3,2))
	gen corop_string=trim(h)
	labmask corop, values(corop_string)
	label var corop "COROP-region"

*** Label provinces
	gen provincie = real(substr(y,3,2))
	gen provincie_string = trim(z)
	labmask provincie, values(provincie_string)
	label var provincie "Province"

*** Save intermediate file
	keep corop gemeente gemeente_values provincie
	save "`dir'tussen\gin.dta", replace

	
*********************************
*********************************
*** 2. Read address mutations ***
*********************************
*********************************

*** Open address file
	use "`adres'", clear
	rename *, lower
	assert rinpersoons=="R"

*** Reformat rinpersoon for merging
	recast str rinpersoon

*** Check duplicates
	duplicates tag, gen(dubbel)
	assert dubbel==0
	drop dubbel

*** Set start and enddate residential information in date format (%td)
	gen begindatum = date(gbadatumaanvangadreshouding, "YMD")
	label var begindatum "Begindatum woonachtig op adres"
	gen einddatum = date(gbadatumeindeadreshouding, "YMD")
	label var einddatum "Einddatum woonachtig op adres"
	format begindatum einddatum %td

*** Remove adminstrative relocations (2 of 3 separate spells at same address)
	sort rinpersoon begindatum
	gen hulp = 0
		replace hulp = 1 if rinpersoon == rinpersoon[_n+1] & rinobjectnummer==rinobjectnummer[_n+1] & rinobjectnummer!="" & (einddatum+1)== begindatum[_n+1]
		replace hulp = 2 if rinpersoon == rinpersoon[_n+1] & rinobjectnummer==rinobjectnummer[_n+1] & rinobjectnummer!="" & (einddatum+1)== begindatum[_n+1] & rinpersoon == rinpersoon[_n+2] & rinobjectnummer==rinobjectnummer[_n+2] & (einddatum[_n+1]+1)== begindatum[_n+2]
		replace hulp = 3 if rinpersoon == rinpersoon[_n+1] & rinobjectnummer==rinobjectnummer[_n+1] & rinobjectnummer!="" & (einddatum+1)== begindatum[_n+1] & rinpersoon == rinpersoon[_n+2] & rinobjectnummer==rinobjectnummer[_n+2] & (einddatum[_n+1]+1)== begindatum[_n+2]& rinpersoon == rinpersoon[_n+3] & rinobjectnummer==rinobjectnummer[_n+3] & (einddatum[_n+2]+1)== begindatum[_n+3]

	replace einddatum=einddatum[_n+1] if hulp==1
	replace einddatum=einddatum[_n+2] if hulp==2
	replace einddatum=einddatum[_n+3] if hulp==3
	gen drop = 1 if hulp[_n-1]>0 & rinpersoon == rinpersoon[_n-1] & rinobjectnummer==rinobjectnummer[_n-1]
	drop if drop==1
	drop hulp drop

*** Check correction of administrative relocations 
	assert rinobjectnummer!=rinobjectnummer[_n+1] if rinpersoon == rinpersoon[_n+1] & (einddatum+1)== begindatum[_n+1]
	duplicates tag rinpersoon einddatum, gen(dubbel)
	assert dubbel==0

*** Remove spells ending before 2003
	drop if year(einddatum) < 2003

*** Save intermediate file
	compress
	save "`dir'tussen\adres.dta", replace

	
********************************
********************************
*** 3. Merge postal/zip code ***
********************************
********************************

*** Read file and recast
	use "`vsl'", clear
	rename *, lower
	keep gem2021 rinobjectnummer soortobjectnummer
	recast str32 rinobjectnummer, force
	duplicates tag rinobjectnummer soortobjectnummer, gen(dubbel)
	assert dubbel==0
	save "`dir'tussen\vsl.dta", replace

*** Merge municipal codes
	use "`dir'tussen\adres.dta", replace
	merge m:1 rinobjectnummer soortobjectnummer using "`dir'tussen\vsl.dta", keep (master matched)
	replace gem2021="" if gem2021=="----"
	rename gem2021 gemcode

*** Check merge
	assert _merge==3 if gemcode!=""
	drop _merge

*** Merge other regional classifications
	merge m:1 gemeente using "`dir'tussen\gin.dta", keep (1 3)
	rename *, lower

*** Save intermediate file
	rename gemcode gemeente
	keep rinpersoon rinpersoons begindatum einddatum gemeente rinobjectnummer soortobjectnummer 
	order rinpersoon rinpersoons begindatum einddatum gemeente rinobjectnummer soortobjectnummer
	compress
	save "`dir'tussen\adres_gemeenten.dta", replace

	
**********************************************************
**********************************************************
*** 4. Splitting the address dataset into yearly files ***
**********************************************************
**********************************************************

forval jaar = 2006/2023{
	use "`dir'tussen\adres_gemeenten.dta", replace
	keep if begindatum <= date("`peildatum`jaar''","DMY") & einddatum>=date("`peildatum`jaar''","DMY")
	
	*** help variables
		rename rinpersoon rinpersoon_string
		gen long rinpersoon = real(rinpersoon_string)
		format rinpersoon %11.0g
		label var rinpersoon "Persoons-id, versleuteld"
		drop rinpersoon_string
		
	************************
	*** Save final files ***
	************************
	
		compress
		drop rinpersoons
		save "`dir'tussen\adres`jaar'.dta", replace
		}
		
log close
exit

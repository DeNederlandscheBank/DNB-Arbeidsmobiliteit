************************************************************
*** 1_bedrijfgegevens.do        			 ***
*** Read source data about firm characteristics	 (ABR)   ***
*** Author: Cindy Biesenbeek (DNB)	 		 *** 	
*** January 2026 (edited by Maikel Volkerink, DNB)       ***
************************************************************

************************************************************
/*
NOTES

Explanation: This do-file reads in basic population data about firms like sector and firmsize. Keep beid in string format, because those not in ABR contain nonnumeric characters and they cannot be merged with banen otherwise. 
*/
************************************************************

*** Settings
local dir "H:\"
set more off
set dp comma
capture log close
log using "`dir'\logs\1_bedrijfsgegevens.smcl", replace

*** locals for source data 
	local betab2006     	"G:\Arbeid\BETAB\2006\geconverteerde data\140707 BETAB 2006V1.DTA" 
	local betab2007     	"G:\Arbeid\BETAB\2007\geconverteerde data\140707 BETAB 2007V1.DTA" 
	local betab2008     	"G:\Arbeid\BETAB\2008\geconverteerde data\140707 BETAB 2008V1.DTA" 
	local betab2009     	"G:\Arbeid\BETAB\2009\geconverteerde data\140707 BETAB 2009V1.DTA" 
	local betab2010     	"G:\Arbeid\BETAB\2010\geconverteerde data\140707 BETAB 2010V1.DTA" 
	local betab2011    	"G:\Arbeid\BETAB\2011\geconverteerde data\140707 BETAB 2011V1.DTA" 
	local betab2012     	"G:\Arbeid\BETAB\2012\geconverteerde data\140707 BETAB 2012V1.DTA" 
	local betab2013 	"G:\Arbeid\BETAB\2013\geconverteerde data\141215 BETAB 2013V1.DTA" 
	local betab2012		"G:\Arbeid\BETAB\2012\geconverteerde data\140707 BETAB 2012V1.DTA"
	local betab2013		"G:\Arbeid\BETAB\2013\geconverteerde data\141215 BETAB 2013V1.DTA"
	local betab2014		"G:\Arbeid\BETAB\2014\geconverteerde data\BE2014TABV2.dta"
	local betab2015		"G:\Arbeid\BETAB\2015\geconverteerde data\BE2015TABV125.DTA"
	local betab2016  	"G:\Arbeid\BETAB\2016\geconverteerde data\BE2016TABV124.DTA" 
	local betab2017  	"G:\Arbeid\BETAB\2017\geconverteerde data\BE2017TABV124.DTA" 
	local betab2018    	"G:\Arbeid\BETAB\2018\geconverteerde data\BE2018TABV124.DTA" 
	local betab2019   	"G:\Arbeid\BETAB\2019\geconverteerde data\BE2019TABV124.DTA" 
	local betab2020   	"G:\Arbeid\BETAB\2020\geconverteerde data\BE2020TABV124.DTA" 
	local betab2021		"G:\Arbeid\BETAB\2021\geconverteerde data\BE2021TABV124.dta"
	local betab2022		"G:\Arbeid\BETAB\2022\Geconverteerde data\BE2022TABV124.dta"
	local betab2023 	"G:\Arbeid\BETAB\2023\BE2023TABV124.dta"
	local betab2024 	"H:\tussen\BE2024TABV124.dta" // this version is not available in K-directory yet, converted manually
	local betab2025		"H:\tussen\BE2025TABV091.dta" // this version is not available in K-directory yet, converted manually

	local gin			"K:\Utilities\HULPbestanden\GebiedeninNederland\GIN2025.xlsx"

	
*********************************************
*********************************************
*** 1. Create dataset with municipalities ***
*********************************************
*********************************************

*** import GIN file
	import excel `gin', cellrange(A2:BB343)  clear
	ren *, lower

*** Label municipality
	gen gemeente = real(a)
	gen gemeente_values = trim(b)
	labmask gemeente, values(gemeente_values)
	label var gemeente "Municipality"

*** Label COROP regional classification
	gen corop = real(substr(i,3,2))
	gen corop_string=trim(j)
	labmask corop, values(corop_string)
	label var corop "COROP-region"

*** Label provinces
	gen provincie = real(substr(aa,3,2))
	gen provincie_string = trim(ab)
	labmask provincie, values(provincie_string)
	label var provincie "Province"

*** Save intermediate file
	keep corop gemeente provincie
	save "`dir'tussen\gin.dta", replace


**************************************************
**************************************************
*** 2. Read BETAB dataset, create yearly files ***
**************************************************
**************************************************
	
forval jaar = 2006/2025{
	use "`betab`jaar''", clear 		
	ren *, lower

	*** Check duplicates
		duplicates tag beid, gen(dubbel)
		assert dubbel==0
		drop dubbel
	
	************************************
	*** Firm size, EU-MKB definition ***
	************************************
		
		destring gksbs, replace*
		gen grootteklasse = .
		replace grootteklasse = 1 if gksbs <=30				// 0-9 workers
		replace grootteklasse = 2 if inrange(gksbs,40,50)	// 10-49 workers
		replace grootteklasse = 3 if inrange(gksbs,60,81)	// 50-249 workers
		replace grootteklasse = 4 if gksbs >=82				// 250 or more workers
		
	*** define and add labels
		#delimit ;
		label def grootteklasse
		1 "Micro: <10 employees"
		2 "Small: 10-50 employees"
		3 "Medium: 50-250 employees"
		4 "Large: >250 employees";
		#delimit cr
	
		label val grootteklasse grootteklasse
		label var grootteklasse "Firm size"

	
	************************
	*** NACE/SBI sectors ***
	************************
	
	*** define labels
		do "`dir'\logs\label_sbi2008.do" 
	
	*** create 2-digit sector var
		destring sbi2008v, replace
		gen sbi2 = floor(sbi2008v/1000)
		
		label var sbi2 "Sector (NACE/SBI 2-digit)"
		label val sbi2 sbi20082D_short
		
		
	*** create 1-digit, main industries var
		gen sbi = .
			replace sbi = 1 if inrange(sbi2,1,3)
			replace sbi = 2 if inrange(sbi2,6,9)
			replace sbi = 3 if inrange(sbi2,10,33)
			replace sbi = 4 if sbi2==35
			replace sbi = 5 if inrange(sbi2,36,39)
			replace sbi = 6 if inrange(sbi2,41,43)
			replace sbi = 7 if inrange(sbi2,45,47)
			replace sbi = 8 if inrange(sbi2,49,53)
			replace sbi = 9 if inrange(sbi2,55,56)
			replace sbi = 10 if inrange(sbi2,58,63)
			replace sbi = 11 if inrange(sbi2,64,66)
			replace sbi = 12 if sbi2==68
			replace sbi = 13 if inrange(sbi2,69,75)
			replace sbi = 14 if inrange(sbi2,77,82)
			replace sbi = 15 if sbi2==84
			replace sbi = 16 if sbi2==85
			replace sbi = 17 if inrange(sbi2,86,88)
			replace sbi = 18 if inrange(sbi2,90,93)
			replace sbi = 19 if inrange(sbi2,94,96)
			replace sbi = 20 if inrange(sbi2,97,98)
			replace sbi = 21 if sbi2==99
			
		label var sbi "Industry (NACE/SBI 1-digit)"
		label val sbi sbi20081D_short
	
		rename sbi2008v sbi5
		label var sbi5 "Detailed sector (NACE/SBI 5-digit)
		
		
	**************
	*** Region ***
	**************
	
		destring  gemhv*, gen(gemeente)
		merge m:1 gemeente using "`dir'tussen\gin.dta", keep (1 3)

	
	************************
	*** Save final files ***
	************************
		keep 	beid grootteklasse sbi sbi2 sbi5 provincie corop gemeente
		lab var beid "Company identifier"

		compress
		save "`dir'tussen\bedrijfsgegevens`jaar'.dta", replace
	}

log close


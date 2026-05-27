************************************************************
*** 1_hoogsteopleiding.do        			 ***
*** Read source data about highest achieved education    ***
*** Author: Cindy Biesenbeek (DNB)			 *** 	
*** January 2026		                         ***
************************************************************

************************************************************
/*
NOTES

Explanation: via this do-file we obstain the highest level of education. Before 2013, the dataset itself does not contain the level of field and education, but they can be retrieved from the file OPLREF. From 2013 onwards, the variable oplnivsoi2016agg4hbmetnirwo is available in the dataset. It is preferred over the variable on level of education from OPLREF, because it contains also information about more sorts of education (see CBS documentation report). Likewise, the field of highest achieved education is available from 2016 on.
*/
************************************************************

*** Settings
local dir "H:\"
capture log close
set more off
set dp comma
log using "`dir'logs\1_hoogsteopleiding.smcl", replace

*** locals for source data 
	local opltab2006	"G:\Onderwijs\HOOGSTEOPLTAB\2006\120619 HOOGSTEOPLTAB 2006V1.dta"
	local opltab2007	"G:\Onderwijs\HOOGSTEOPLTAB\2007\120619 HOOGSTEOPLTAB 2007V1.dta"
	local opltab2008	"G:\Onderwijs\HOOGSTEOPLTAB\2008\120619 HOOGSTEOPLTAB 2008V1.dta"
	local opltab2009	"G:\Onderwijs\HOOGSTEOPLTAB\2009\120619 HOOGSTEOPLTAB 2009V1.dta"
	local opltab2010	"G:\Onderwijs\HOOGSTEOPLTAB\2010\120918 HOOGSTEOPLTAB 2010V1.dta"
	local opltab2011	"G:\Onderwijs\HOOGSTEOPLTAB\2011\130924 HOOGSTEOPLTAB 2011V1.dta"
	local opltab2012    	"G:\Onderwijs\HOOGSTEOPLTAB\2012\141020 HOOGSTEOPLTAB 2012V1.DTA" 
	local opltab2013    	"G:\Onderwijs\HOOGSTEOPLTAB\2013\HOOGSTEOPL2013TABV3.dta"  
	local opltab2014    	"G:\Onderwijs\HOOGSTEOPLTAB\2014\HOOGSTEOPL2014TABV3.dta"  
	local opltab2015    	"G:\Onderwijs\HOOGSTEOPLTAB\2015\HOOGSTEOPL2015TABV3.dta"  
	local opltab2016    	"G:\Onderwijs\HOOGSTEOPLTAB\2016\HOOGSTEOPL2016TABV2.DTA"  
	local opltab2017    	"G:\Onderwijs\HOOGSTEOPLTAB\2017\HOOGSTEOPL2017TABV3.DTA"   
	local opltab2018    	"G:\Onderwijs\HOOGSTEOPLTAB\2018\HOOGSTEOPL2018TABV3.dta"
	local opltab2019    	"G:\Onderwijs\HOOGSTEOPLTAB\2019\HOOGSTEOPL2019TABV2.DTA"   
	local opltab2020    	"G:\Onderwijs\HOOGSTEOPLTAB\2020\HOOGSTEOPL2020TABV2.DTA"
	local opltab2021    	"G:\Onderwijs\HOOGSTEOPLTAB\2021\HOOGSTEOPL2021TABV2.DTA"
	local opltab2022	"G:\Onderwijs\HOOGSTEOPLTAB\2022\HOOGSTEOPL2022TABV2.DTA"
	local opltab2023	"G:\Onderwijs\HOOGSTEOPLTAB\2023\HOOGSTEOPL2023TABV2.DTA"
	local opltab2024	"G:\Onderwijs\HOOGSTEOPLTAB\2024\HOOGSTEOPL2024TABV1.DTA"
	local oplref		"H:\tussen\OPLEIDINGSNRREFV35.DTA" // this version is not available in K-directory yet, converted manually

	
**************************************
**************************************
*** 1. Clean education data: <2016 ***
**************************************
**************************************

forval jaar = 2010/2015{
	use "`opltab`jaar''", clear 		
	ren *, lower
	ren oplnrhb oplnr
			
	*** Check duplicates
		gduplicates tag, gen (dubbel)
		assert dubbel==0
		drop dubbel
	
	*** Check correspondence with GBA
		assert rinpersoons=="R"
		drop rinpersoons
		rename rinpersoon rinpersoon_string
		gen long rinpersoon=real(rinpersoon_string)	
			
	*** Merge with education register to get level and field of education
		merge m:1 oplnr using "`oplref'", keepusing(SOI2006NIVEAU CTO2016V ISCEDF2013RICHTINGNL SOI2016NIVEAU1) keep(1 3)
		ren *, lower
		drop _merge
	
	
	**************************
	*** Level of education ***
	**************************
		
	if `jaar'<2013{	
		destring soi2016niveau1, replace
		gen opleidingsniveau = .
		replace opleidingsniveau = 1 if soi2016niveau1<=3
		replace opleidingsniveau = 2 if soi2016niveau1==4
		replace opleidingsniveau = 3 if soi2016niveau1==5
		replace opleidingsniveau = 4 if inrange(soi2016niveau1,6,7)
		}
		
	if `jaar'>=2013{
		destring oplnivsoi2016agg4hbmetnirwo, replace
		gen opleidingsniveau = .
		replace opleidingsniveau = 1 if inrange(oplnivsoi2016agg4hbmetnirwo,1111,1222)
		replace opleidingsniveau = 2 if inrange(oplnivsoi2016agg4hbmetnirwo,2111,2132)
		replace opleidingsniveau = 3 if inrange(oplnivsoi2016agg4hbmetnirwo,3111,3113)
		replace opleidingsniveau = 4 if inrange(oplnivsoi2016agg4hbmetnirwo,3211,3213)
		}

	*** label vars
		label def opleidingsniveau 1 "Lower" 2 "Medium" 3 "Bachelor" 4 "Master"
		label val opleidingsniveau opleidingsniveau
		label var opleidingsniveau "Highest level of education achieved, SOI2016"

		
	**************************
	*** Field of education ***
	**************************
	
	destring iscedf2013richtingnl, replace
	
	*** categorize fields
		gen opleidingsrichting = .
		replace opleidingsrichting = 11 if floor(iscedf2013richtingnl/100) == 0
		replace opleidingsrichting = 1 if floor(iscedf2013richtingnl/100) == 1
		replace opleidingsrichting = 2 if floor(iscedf2013richtingnl/100) == 2
		replace opleidingsrichting = 3 if floor(iscedf2013richtingnl/100) == 3
		replace opleidingsrichting = 4 if floor(iscedf2013richtingnl/100) == 4
		replace opleidingsrichting = 5 if floor(iscedf2013richtingnl/100) == 5
		replace opleidingsrichting = 6 if floor(iscedf2013richtingnl/100) == 6
		replace opleidingsrichting = 7 if floor(iscedf2013richtingnl/100) == 7
		replace opleidingsrichting = 8 if floor(iscedf2013richtingnl/100) == 8
		replace opleidingsrichting = 9 if floor(iscedf2013richtingnl/100) == 9
		replace opleidingsrichting = 10 if floor(iscedf2013richtingnl/100) == 10
		replace opleidingsrichting = . if floor(iscedf2013richtingnl/100) == 99
	
	*** label vars
		label def opleidingsrichting 1 "Education" 2 "Arts and humanities" 3 "Social sciences, journalism and information" 4 "Business, administration and law" 5 "Natural sciences, mathematics, statistics" 6 "ICTs" 7 "Engineering, manufacturing and 		construction" 8 "Agriculture, forestry, fisheries and veterinary" 9 "Health and welfare" 10 "Services" 11 "Generic programmes"
		label val opleidingsrichting opleidingsrichting
		label var opleidingsrichting "Field of education, ISCED2013"
		
	*** save final file
		keep rinpersoon opleidingsniveau opleidingsrichting
		compress
		save "`dir'tussen\hoogsteopleiding`jaar'.dta", replace
		}

		
***************************************
***************************************
*** 2. Clean education data: >=2016 ***
***************************************

forval jaar = 2016/2024{
	use "`opltab`jaar''", clear 		
	ren *, lower
	ren oplnrhb oplnr
			
	*** Check duplicates
		gduplicates tag, gen (dubbel)
		assert dubbel==0
		drop dubbel
	
	*** Check correspondence with GBA
		assert rinpersoons=="R"
		drop rinpersoons
		rename rinpersoon rinpersoon_string
		gen long rinpersoon=real(rinpersoon_string)	

		
	**************************
	*** Level of education ***
	**************************

	if `jaar'>2018{
		drop oplnivsoi2016agg4hbmetnirwo
		rename oplnivsoi2021agg4hbmetnirwo oplnivsoi2016agg4hbmetnirwo
		drop richtdetailiscedf2013hbmetnirwo
		rename richtsoi2021scedf2013hbnirwo richtdetailiscedf2013hbmetnirwo
		}
	
	destring oplnivsoi2016agg4hbmetnirwo, replace
	
	gen opleidingsniveau = .
	replace opleidingsniveau = 1 if inrange(oplnivsoi2016agg4hbmetnirwo,1111,1222)
	replace opleidingsniveau = 2 if inrange(oplnivsoi2016agg4hbmetnirwo,2111,2132)
	replace opleidingsniveau = 3 if inrange(oplnivsoi2016agg4hbmetnirwo,3111,3113)
	replace opleidingsniveau = 4 if inrange(oplnivsoi2016agg4hbmetnirwo,3211,3213)
	
	*** label vars
		label def opleidingsniveau 1 "Lower" 2 "Medium" 3 "Bachelor" 4 "Master"
		label val opleidingsniveau opleidingsniveau
		label var opleidingsniveau "Highest level of education achieved, SOI2016"
			
	**************************
	*** Field of education ***
	**************************

	destring richtdetailiscedf2013hbmetnirwo, gen(iscedf2013richtingnl)

	*** categorize fields
		gen opleidingsrichting = .
		replace opleidingsrichting = 11 if floor(iscedf2013richtingnl/100) == 0
		replace opleidingsrichting = 1 if floor(iscedf2013richtingnl/100) == 1
		replace opleidingsrichting = 2 if floor(iscedf2013richtingnl/100) == 2
		replace opleidingsrichting = 3 if floor(iscedf2013richtingnl/100) == 3
		replace opleidingsrichting = 4 if floor(iscedf2013richtingnl/100) == 4
		replace opleidingsrichting = 5 if floor(iscedf2013richtingnl/100) == 5
		replace opleidingsrichting = 6 if floor(iscedf2013richtingnl/100) == 6
		replace opleidingsrichting = 7 if floor(iscedf2013richtingnl/100) == 7
		replace opleidingsrichting = 8 if floor(iscedf2013richtingnl/100) == 8
		replace opleidingsrichting = 9 if floor(iscedf2013richtingnl/100) == 9
		replace opleidingsrichting = 10 if floor(iscedf2013richtingnl/100) == 10
		replace opleidingsrichting = . if floor(iscedf2013richtingnl/100) == 99
	
	*** label vars
		label def opleidingsrichting 1 "Education" 2 "Arts and humanities" 3 "Social sciences, journalism and information" 4 "Business, administration and law" 5 "Natural sciences, mathematics, statistics" 6 "ICTs" 7 "Engineering, manufacturing and construction" 8 "Agriculture, forestry, fisheries and veterinary" 9 "Health and welfare" 10 "Services" 11 "Generic programmes"
		label val opleidingsrichting opleidingsrichting
		label var opleidingsrichting "Field of education, ISCED2013"
	
	************************
	*** Save final files ***
	************************
	
		keep rinpersoon opleidingsniveau opleidingsrichting
		compress
		save "`dir'tussen\hoogsteopleiding`jaar'.dta", replace
		} 

log close

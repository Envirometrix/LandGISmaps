## Import soil Water Retention variables
## tom.hengl@gmail.com and Gupta Surya <surya.gupta@usys.ethz.ch>
## conversion between VWC and MWC (Landon 1991; Schoenberger et al. 2002; van Reeuwijk 2002):
## VWC (%v/v) = MWC (% by weight ) * bulk density (kg m -3 )

library(plyr)
library(rgdal)
library(dplyr)
library(raster)
library(fastSave)
library(tidyverse)
library(rgeos)
#load.pigz("soilhydro.RData") #, n.cores = parallel::detectCores())

## Target USDA_NCSS columns
## https://www.nrcs.usda.gov/Internet/FSE_DOCUMENTS/nrcs142p2_052226.pdf
site.names = c("site_key", "usiteid", "site_obsdate", "longitude_decimal_degrees", "latitude_decimal_degrees")
hor.names = c("labsampnum","site_key","layer_sequence","hzn_top","hzn_bot","hzn_desgn","db_13b", "db_od", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2")
## target structure:
col.names = c("site_key", "usiteid", "site_obsdate", "longitude_decimal_degrees", "latitude_decimal_degrees", "labsampnum", "layer_sequence", "hzn_top", "hzn_bot", "hzn_desgn", "db_13b", "db_od", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2", "source_db")

## USDA_NCSS ----
## http://ncsslabdatamart.sc.egov.usda.gov/
ncss.site <- read.csv("/data/Soil_points/INT/USDA_NCSS/NCSS_Site_Location.csv", sep = ";", dec = ",", stringsAsFactors = FALSE)
str(ncss.site)  # 63990 obs. of  20 variables
ncss.layer <- read.csv("/data/Soil_points/INT/USDA_NCSS/NCSS_Layer.csv", sep = ";", dec = ",", stringsAsFactors = FALSE)
ncss.bdm <- read.csv("/data/Soil_points/INT/USDA_NCSS/NCSS_Bulk_Density_and_Moisture.csv", sep = ";", dec = ",", stringsAsFactors = FALSE)
## multiple measurements
summary(as.factor(ncss.bdm$prep_code))
ncss.bdm.0 <- ncss.bdm[ncss.bdm$prep_code=="S",]
summary(ncss.bdm.0$db_od)
## 0 values --- error!
ncss.carb <- read.csv("/data/Soil_points/INT/USDA_NCSS/NCSS_Carbon_and_Extractions.csv", sep = ";", dec = ",", stringsAsFactors = FALSE)
ncss.organic <- read.csv("/data/Soil_points/INT/USDA_NCSS/NCSS_Organic.csv", sep = ";", dec = ",", stringsAsFactors = FALSE)
ncss.pH <- read.csv("/data/Soil_points/INT/USDA_NCSS/NCSS_pH_and_Carbonates.csv", sep = ";", dec = ",", stringsAsFactors = FALSE)
str(ncss.pH)
summary(!is.na(ncss.pH$ph_h2o))
ncss.PSDA <- read.csv("/data/Soil_points/INT/USDA_NCSS/NCSS_PSDA_and_Rock_Fragments.csv", sep = ";", dec = ",", stringsAsFactors = FALSE)
ncss.CEC <- read.csv("/data/Soil_points/INT/USDA_NCSS/NCSS_CEC_and_Bases.csv")
ncss.horizons <- plyr::join_all(list(ncss.bdm.0, ncss.layer, ncss.carb, ncss.organic, ncss.pH, ncss.PSDA, ncss.CEC), type = "left", by="labsampnum")
#head(ncss.horizons)
nrow(ncss.horizons)
## 302,151
hydrosprops.NCSS = plyr::join(ncss.site[,site.names], ncss.horizons[,hor.names], by="site_key") 
## soil organic carbon:
summary(!is.na(hydrosprops.NCSS$oc)) ## 128,957 measurements
summary(!is.na(hydrosprops.NCSS$ph_h2o)) ## only 1545 measurements
summary(!is.na(hydrosprops.NCSS$ph_kcl)) ## 22,904 measurements
hydrosprops.NCSS$source_db = "USDA_NCSS"
str(hydrosprops.NCSS)
hist(hydrosprops.NCSS$w3cld[hydrosprops.NCSS$w3cld<150], breaks=45, col="gray")
## ERROR: MANY VALUES >100%
## fills in missing BD values using formula from Köchy, Hiederer, and Freibauer (2015)
db.f = ifelse(is.na(hydrosprops.NCSS$db_13b), -0.31*log(hydrosprops.NCSS$oc)+1.38, hydrosprops.NCSS$db_13b)
db.f[db.f<0.02 | db.f>2.87] = NA
## Convert to volumetric % to match most of world data sets:
hydrosprops.NCSS$w3cld = hydrosprops.NCSS$w3cld * db.f
hydrosprops.NCSS$w15l2 = hydrosprops.NCSS$w15l2 * db.f
hydrosprops.NCSS$w10cld = hydrosprops.NCSS$w10cld * db.f
summary(as.factor(hydrosprops.NCSS$tex_psda))
## texture classes need to be cleaned up!
## check WRC values for sandy soils
hydrosprops.NCSS[which(!is.na(hydrosprops.NCSS$w3cld) & hydrosprops.NCSS$sand_tot_psa>95)[1:10],]
## check WRC values for ORGANIC soils
hydrosprops.NCSS[which(!is.na(hydrosprops.NCSS$w3cld) & hydrosprops.NCSS$oc>12)[1:10],]
## w3cld > 100?
## save
#ncss.csv = paste0("/data/Soil_points/INT/USDA_NCSS/", c("NCSS_Site_Location.csv", "NCSS_Layer.csv", "NCSS_Bulk_Density_and_Moisture.csv", "NCSS_CEC_and_Bases.csv", "NCSS_PSDA_and_Rock_Fragments.csv", "NCSS_Organic.csv", "NCSS_pH_and_Carbonates.csv"))
#file.copy(ncss.csv, to = gsub("/data/", "/data/git/SoilWaterModeling/", ncss.csv), overwrite = TRUE)

## ISIS ----
## https://wur.on.worldcat.org/search?queryString=isric+soil+brief
isis.xy <- read.csv("/data/Soil_points/INT/ISRIC_ISIS/Sites.csv", stringsAsFactors = FALSE)
str(isis.xy)
isis.des <- read.csv("/data/Soil_points/INT/ISRIC_ISIS/SitedescriptionResults.csv", stringsAsFactors = FALSE)
isis.site <- data.frame(site_key=isis.xy$Id, usiteid=paste(isis.xy$CountryISO, isis.xy$SiteNumber, sep=""))
id0.lst = c(236,235,224)
nm0.lst = c("longitude_decimal_degrees", "latitude_decimal_degrees", "site_obsdate")
isis.site.l = plyr::join_all(lapply(1:length(id0.lst), function(i){plyr::rename(subset(isis.des, ValueId==id0.lst[i])[,c("SampleId","Value")], replace=c("SampleId"="site_key", "Value"=paste(nm0.lst[i])))}), type = "full")
isis.site.df = join(isis.site, isis.site.l)
for(j in nm0.lst){ isis.site.df[,j] <- as.numeric(isis.site.df[,j]) }
isis.site.df[isis.site.df$usiteid=="CI2","latitude_decimal_degrees"] = 5.883333
str(isis.site.df)
## 906 points
isis.smp <- read.csv("/data/Soil_points/INT/ISRIC_ISIS/AnalyticalSamples.csv", stringsAsFactors = FALSE)
isis.ana <- read.csv("/data/Soil_points/INT/ISRIC_ISIS/AnalyticalResults.csv", stringsAsFactors = FALSE)
str(isis.ana)
isis.class <- read.csv("/data/Soil_points/INT/ISRIC_ISIS/ClassificationResults.csv", stringsAsFactors = FALSE)
isis.hor <- data.frame(labsampnum=isis.smp$Id, hzn_top=isis.smp$Top, hzn_bot=isis.smp$Bottom, site_key=isis.smp$SiteId)
isis.hor$hzn_bot <- as.numeric(gsub(">", "", isis.hor$hzn_bot))
str(isis.hor)
id.lst = c(1,2,22,4,28,31,32,14,34,38,39,42)
nm.lst = c("ph_h2o","ph_kcl","wpg2","oc","sand_tot_psa","silt_tot_psa","clay_tot_psa","cec_sum","db_od","w10cld","w3cld", "w15l2")
str(as.numeric(isis.ana$Value[isis.ana$ValueId==38]))
isis.hor.l = plyr::join_all(lapply(1:length(id.lst), function(i){plyr::rename(subset(isis.ana, ValueId==id.lst[i])[,c("SampleId","Value")], replace=c("SampleId"="labsampnum", "Value"=paste(nm.lst[i])))}), type = "full")
summary(as.numeric(isis.hor.l$w3cld))
isis.hor.df = join(isis.hor, isis.hor.l)
isis.hor.df = isis.hor.df[!duplicated(isis.hor.df$labsampnum),]
#View(isis.hor.df)
#summary(as.numeric(isis.hor.df$w3cld))
for(j in nm.lst){ isis.hor.df[,j] <- as.numeric(isis.hor.df[,j]) }
#str(isis.hor.df)
## add missing columns
for(j in c("layer_sequence", "hzn_desgn", "tex_psda", "COLEws", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "cec_nh4", "db_13b", "w6clod")){  isis.hor.df[,j] = NA }
which(!hor.names %in% names(isis.hor.df))
hydrosprops.ISIS <- join(isis.site.df[,site.names], isis.hor.df[,hor.names], type="left")
hydrosprops.ISIS$source_db = "ISRIC_ISIS"
#plot(hydrosprops.ISIS[,c("longitude_decimal_degrees", "latitude_decimal_degrees")])
#isis.csv = paste0("/data/Soil_points/INT/ISRIC_ISIS/", c("Sites.csv", "AnalyticalResults.csv","AnalyticalSamples.csv","ClassificationResults.csv","ClassificationSamples.csv","SitedescriptionResults.csv","SitedescriptionSamples.csv"))
#file.copy(isis.csv, to = gsub("/data/", "/data/git/SoilWaterModeling/", isis.csv), overwrite = TRUE)

## AFSIS SPDB ----
## https://www.isric.org/projects/africa-soil-profiles-database-afsp
afspdb.profiles <- read.csv("/data/Soil_points/AF/AfSIS_SPDB/AfSP01301Qry_Profiles.csv", stringsAsFactors=FALSE, fileEncoding="latin1", na.strings=c("", "NA", "-9999", "-9999.000", "-9999.0", "-99990", "100000", "<Null>", "<NA>"))
afspdb.layers <- read.csv("/data/Soil_points/AF/AfSIS_SPDB/AfSP01301Qry_Layers.csv", stringsAsFactors=FALSE, fileEncoding="latin1", na.strings=c("", "NA", "-9999", "-9999.000", "-9999.0", "-9999.00", "-99990", "100000", "<Null>", "<NA>"))
## select columns of interest:
#site.names = c("site_key", "usiteid", "site_obsdate", "longitude_decimal_degrees", "latitude_decimal_degrees")
afspdb.s.lst <- c("ProfileID", "usiteid", "T_Year", "X_LonDD", "Y_LatDD")
#hor.names = c("labsampnum","site_key","layer_sequence","hzn_top","hzn_bot","hzn_desgn","db_13b", "db_od", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2")
## Convert to weight content
summary(afspdb.layers$BlkDens)
## select layers
afspdb.h.lst <- c("LayerID", "ProfileID", "LayerNr", "UpDpth", "LowDpth", "HorDes", "db_13b", "BlkDens", "COLEws", "VMCpF18", "VMCpF20", "VMCpF25", "VMCpF42", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "LabTxtr", "Clay", "Silt", "Sand", "OrgC", "PHKCl", "PHH2O", "CecSoil", "cec_nh4", "CfPc")
## add missing columns
for(j in c("usiteid")){  afspdb.profiles[,j] = NA }
for(j in c("db_13b", "COLEws", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "cec_nh4")){  afspdb.layers[,j] = NA }
hydrosprops.AfSPDB = plyr::join(afspdb.profiles[,afspdb.s.lst], afspdb.layers[,afspdb.h.lst])
for(j in 1:ncol(hydrosprops.AfSPDB)){ 
  if(is.numeric(hydrosprops.AfSPDB[,j])) { hydrosprops.AfSPDB[,j] <- ifelse(hydrosprops.AfSPDB[,j] < -200, NA, hydrosprops.AfSPDB[,j]) }
}
hydrosprops.AfSPDB$source_db = "AfSPDB"
hydrosprops.AfSPDB$OrgC = hydrosprops.AfSPDB$OrgC/10
summary(hydrosprops.AfSPDB$OrgC)
head(hydrosprops.AfSPDB)
#hist(hydrosprops.AfSPDB$VMCpF25, breaks=45, col="gray")
#afspdb.csv = paste0("/data/Soil_points/AF/AfSIS_SPDB/", c("AfSP01301Qry_Profiles.csv", "AfSP01301Qry_Layers.csv"))
#file.copy(afspdb.csv, to = gsub("/data/", "/data/git/SoilWaterModeling/", afspdb.csv), overwrite = TRUE)

## ISRIC WISE ----
## https://www.isric.org/sites/default/files/isric_report_2008_02.pdf
cols2dms <- function(x,y,z,e){ifelse(is.na(e)|is.na(x), NA, as(sp::char2dms(paste(x, "d", y, "'", z, "\"", e, sep="")), "numeric"))}
wise.SITE <- read.csv("/data/Soil_points/INT/ISRIC_WISE/WISE3_SITE.csv", stringsAsFactors=FALSE)
wise.HORIZON <- read.csv("/data/Soil_points/INT/ISRIC_WISE/WISE3_HORIZON.csv")
for(j in c("LATSEC","LONSEC","LATMIN","LONMIN")){
  wise.SITE[,j] = ifelse(is.na(wise.SITE[,j]), 0, wise.SITE[,j])
}
wise.SITE = wise.SITE[!(is.na(wise.SITE$LONDEG)|is.na(wise.SITE$LATDEG)),]
# get WGS84 coordinates:
wise.SITE$LONIT = wise.SITE$LONGI
for(j in c("LAT","LON")){
  wise.SITE[,paste0(j,"WGS84")] = cols2dms(wise.SITE[,paste0(j,"DEG")], wise.SITE[,paste0(j,"MIN")], wise.SITE[,paste0(j,"SEC")], wise.SITE[,paste0(j,"IT")])
}
#plot(wise.SITE[,c("LONWGS84","LATWGS84")], pch="+")
#site.names = c("site_key", "usiteid", "site_obsdate", "longitude_decimal_degrees", "latitude_decimal_degrees")
wise.s.lst <- c("WISE3_id", "SOURCE_ID", "DATEYR", "LONWGS84", "LATWGS84")
#hor.names = c("labsampnum","site_key","layer_sequence","hzn_top","hzn_bot","hzn_desgn","db_13b", "db_od", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2")
## Convert volumetric values to weight %
summary(wise.HORIZON$BULKDENS)
summary(wise.HORIZON$VMC1)
wise.HORIZON$WISE3_id = wise.HORIZON$WISE3_ID
wise.h.lst <- c("labsampnum", "WISE3_id", "HONU", "TOPDEP", "BOTDEP", "DESIG", "db_13b", "BULKDENS", "COLEws", "w6clod", "VMC1", "VMC2", "VMC3", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "CLAY", "SILT", "SAND", "ORGC", "PHKCL", "PHH2O", "CECSOIL", "cec_nh4", "GRAVEL")
## add missing columns
for(j in c("labsampnum", "db_13b", "COLEws", "w15bfm", "w6clod", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "cec_nh4")){  wise.HORIZON[,j] = NA }
hydrosprops.WISE = plyr::join(wise.SITE[,wise.s.lst], wise.HORIZON[,wise.h.lst])
for(j in 1:ncol(hydrosprops.WISE)){ 
  if(is.numeric(hydrosprops.WISE[,j])) { hydrosprops.WISE[,j] <- ifelse(hydrosprops.WISE[,j] < -200, NA, hydrosprops.WISE[,j]) }
}
hydrosprops.WISE$ORGC = hydrosprops.WISE$ORGC/10
hydrosprops.WISE$source_db = "ISRIC_WISE"
summary(hydrosprops.WISE$VMC3.f)
#hist(hydrosprops.WISE$VMC2.f, breaks=45, col="gray")
#summary(!is.na(hydrosprops.WISE$VMC3.f))
## 5677
head(hydrosprops.WISE)
## save
#wise.csv = paste0("/data/Soil_points/INT/ISRIC_WISE/", c("WISE3_SITE.csv", "WISE3_HORIZON.csv"))
#file.copy(wise.csv, to = gsub("/data/", "/data/git/SoilWaterModeling/", wise.csv), overwrite = TRUE)

## Russian SPDB ----
russ.HOR = read.csv("/data/Soil_points/Russia/EGRPR/Russia_EGRPR_soil_pedons.csv")
russ.HOR$SOURCEID = paste(russ.HOR$CardID, russ.HOR$SOIL_ID, sep="_")
russ.HOR$SNDPPT <- russ.HOR$TEXTSAF + russ.HOR$TEXSCM
russ.HOR$SLTPPT <- russ.HOR$TEXTSIC + russ.HOR$TEXTSIM + 0.8 * russ.HOR$TEXTSIF
russ.HOR$CLYPPT <- russ.HOR$TEXTCL + 0.2 * russ.HOR$TEXTSIF
## Correct texture fractions:
sumTex <- rowSums(russ.HOR[,c("SLTPPT","CLYPPT","SNDPPT")])
russ.HOR$SNDPPT <- russ.HOR$SNDPPT / ((sumTex - russ.HOR$CLYPPT) /(100 - russ.HOR$CLYPPT))
russ.HOR$SLTPPT <- russ.HOR$SLTPPT / ((sumTex - russ.HOR$CLYPPT) /(100 - russ.HOR$CLYPPT))
russ.HOR$oc <- russ.HOR$ORGMAT/1.724
#col.names = c("site_key", "usiteid", "site_obsdate", "longitude_decimal_degrees", "latitude_decimal_degrees", "labsampnum", "layer_sequence", "hzn_top", "hzn_bot", "hzn_desgn", "db_13b", "db_od", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2", "source_db")
## add missing columns
for(j in c("site_obsdate", "labsampnum", "db_13b", "COLEws", "w15bfm", "w6clod", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "cec_nh4", "wpg2")){  russ.HOR[,j] = NA }
russ.sel.h = c("SOURCEID", "SOIL_ID", "site_obsdate", "LONG", "LAT", "labsampnum", "HORNMB", "HORTOP", "HORBOT", "HISMMN", "db_13b", "DVOL", "COLEws", "w6clod", "WR10", "WR33", "WR1500", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "CLYPPT", "SLTPPT", "SNDPPT", "oc", "PHSLT", "PHH2O", "CECST", "cec_nh4", "wpg2")
hydrosprops.EGRPR = russ.HOR[,russ.sel.h]
hydrosprops.EGRPR$source_db = "Russia_EGRPR"
summary(hydrosprops.EGRPR$WR1500)
#hist(hydrosprops.EGRPR$WR33, breaks=45, col="gray")
#file.copy("/data/Soil_points/Russia/EGRPR/Russia_EGRPR_soil_pedons.csv", to = "/data/git/SoilWaterModeling/Soil_points/Russia/EGRPR/Russia_EGRPR_soil_pedons.csv", overwrite = TRUE)

## SPADE 2 ----
## https://esdac.jrc.ec.europa.eu/content/soil-profile-analytical-database-2
spade.PLOT <- read.csv("/data/Soil_points/EU/SPADE/DAT_PLOT.csv")
str(spade.PLOT)
spade.PLOT = spade.PLOT[!spade.PLOT$LON_COOR_V>180 & spade.PLOT$LAT_COOR_V>20,]
plot(spade.PLOT[,c("LON_COOR_V","LAT_COOR_V")])
spade.HOR <- read.csv("/data/Soil_points/EU/SPADE/DAT_HOR.csv")
names(spade.HOR)
#site.names = c("site_key", "usiteid", "site_obsdate", "longitude_decimal_degrees", "latitude_decimal_degrees")
spade.PLOT$ProfileID = paste(spade.PLOT$CNTY_C, spade.PLOT$PLOT_ID, sep="_")
spade.PLOT$T_Year = 2009
spade.s.lst <- c("PLOT_ID", "ProfileID", "T_Year", "LON_COOR_V", "LAT_COOR_V")
## standardize:
spade.HOR$SLTPPT <- spade.HOR$SILT1_V + spade.HOR$SILT2_V
spade.HOR$SNDPPT <- spade.HOR$SAND1_V + spade.HOR$SAND2_V + spade.HOR$SAND3_V
spade.HOR$PHIKCL <- NA
spade.HOR$PHIKCL[which(spade.HOR$PH_M %in% "A14")] <- spade.HOR$PH_V[which(spade.HOR$PH_M %in% "A14")]
spade.HOR$PHIHO5 <- NA
spade.HOR$PHIHO5[which(spade.HOR$PH_M %in% "A12")] <- spade.HOR$PH_V[which(spade.HOR$PH_M %in% "A12")]
summary(spade.HOR$BD_V)
#hor.names = c("labsampnum","site_key","layer_sequence","hzn_top","hzn_bot","hzn_desgn","db_13b", "db_od", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2")
for(j in c("site_obsdate", "layer_sequence", "db_13b", "COLEws", "w15bfm", "w6clod", "w10cld", "adod", "wrd_ws13", "w15bfm", "cec7_cly", "w15cly", "tex_psda", "cec_nh4")){  spade.HOR[,j] = NA }
spade.h.lst = c("HOR_ID","PLOT_ID","layer_sequence","HOR_BEG_V","HOR_END_V","HOR_NAME","db_13b", "BD_V", "COLEws", "w6clod", "w10cld", "WCFC_V", "WC4_V", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "CLAY_V", "SLTPPT", "SNDPPT", "OC_V", "PHIKCL", "PHIHO5", "CEC_V", "cec_nh4", "GRAV_C")
hydrosprops.SPADE2 = plyr::join(spade.PLOT[,spade.s.lst], spade.HOR[,spade.h.lst])
hydrosprops.SPADE2$source_db = "SPADE2"
summary(hydrosprops.SPADE2$WC4_V)
summary(is.na(hydrosprops.SPADE2$WC4_V))
hist(hydrosprops.SPADE2$WC4_V, breaks=45, col="gray")
str(hydrosprops.SPADE2)
## save
#spade.csv = paste0("/data/Soil_points/EU/SPADE/", c("DAT_PLOT.csv", "DAT_HOR.csv"))
#file.copy(spade.csv, to = gsub("/data/", "/data/git/SoilWaterModeling/", spade.csv), overwrite = TRUE)

## Canada NPDB ----
## https://open.canada.ca/data/en/dataset/6457fad6-b6f5-47a3-9bd1-ad14aea4b9e0
NPDB.nm = c("NPDB_V2_sum_source_info.csv","NPDB_V2_sum_chemical.csv", "NPDB_V2_sum_horizons_raw.csv", "NPDB_V2_sum_physical.csv")
NPDB.HOR = plyr::join_all(lapply(paste0("/data/Soil_points/Canada/NPDB/", NPDB.nm), read.csv), type = "full")
str(NPDB.HOR)
summary(NPDB.HOR$BULK_DEN)
## 0 values -> ERROR!
#col.names = c("site_key", "usiteid", "site_obsdate", "longitude_decimal_degrees", "latitude_decimal_degrees", "labsampnum", "layer_sequence", "hzn_top", "hzn_bot", "hzn_desgn", "db_13b", "db_od", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2", "source_db")
## add missing columns
NPDB.HOR$HISMMN = paste0(NPDB.HOR$HZN_MAS, NPDB.HOR$HZN_SUF, NPDB.HOR$HZN_MOD)
for(j in c("usiteid", "layer_sequence", "labsampnum", "db_13b", "COLEws", "w15bfm", "w6clod", "w10cld", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "cec_nh4", "ph_kcl")){  NPDB.HOR[,j] = NA }
npdb.sel.h = c("PEDON_ID", "usiteid", "CAL_YEAR", "DD_LONG", "DD_LAT", "labsampnum", "layer_sequence", "U_DEPTH", "L_DEPTH", "HISMMN", "db_13b", "BULK_DEN", "COLEws", "w6clod", "w10cld", "RETN_33KP", "RETN_1500K", "RETN_HYGR", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "T_CLAY", "T_SILT", "T_SAND", "CARB_ORG", "ph_kcl", "PH_H2O", "CEC", "cec_nh4", "VC_SAND")
hydrosprops.NPDB = NPDB.HOR[,npdb.sel.h]
hydrosprops.NPDB$source_db = "Canada_NPDB"
summary(hydrosprops.NPDB$RETN_33KP)
hist(hydrosprops.NPDB$RETN_33KP, breaks=45, col="gray")
## save
#npdb.csv = paste0("/data/Soil_points/Canada/NPDB/", NPDB.nm)
#file.copy(npdb.csv, to = gsub("/data/", "/data/git/SoilWaterModeling/", npdb.csv), overwrite = TRUE)

## HYBRAS ----
## http://www.cprm.gov.br/en/Hydrology/Research-and-Innovation/HYBRAS-4208.html
hybras.HOR = read.csv("/data/Soil_points/Brasil/HYBRAS/HYBRAS.V1_integrated_tables_RAW.csv", sep = ";")
str(hybras.HOR)
summary(hybras.HOR$bulk_den)
#col.names = c("site_key", "usiteid", "site_obsdate", "longitude_decimal_degrees", "latitude_decimal_degrees", "labsampnum", "layer_sequence", "hzn_top", "hzn_bot", "hzn_desgn", "db_13b", "db_od", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2", "source_db")
## add missing columns
for(j in c("usiteid", "layer_sequence", "labsampnum", "db_13b", "COLEws", "w15bfm", "w6clod", "w10cld", "adod", "wrd_ws13", "cec7_cly", "w15cly", "cec_sum", "cec_nh4", "ph_kcl", "ph_h2o")){  hybras.HOR[,j] = NA }
hybras.HOR$w3cld = rowMeans(hybras.HOR[,c("theta20","theta50")], na.rm = TRUE)
hybras.sel.h = c("Profile.id", "usiteid", "year", "LongitudeOR", "LatitudeOR", "labsampnum", "layer_sequence", "top_depth", "bot_depth", "horizon", "db_13b", "bulk_den", "COLEws", "w6clod", "theta10", "w3cld", "theta15000", "satwat", "adod", "wrd_ws13", "cec7_cly", "w15cly", "texture", "clay", "silt", "sand", "org_carb", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "vc_sand")
hydrosprops.HYBRAS = hybras.HOR[,hybras.sel.h]
hydrosprops.HYBRAS$source_db = "HYBRAS"
for(i in c("theta10", "w3cld", "theta15000", "satwat")){ hydrosprops.HYBRAS[,i] = hydrosprops.HYBRAS[,i]*100 }
summary(hydrosprops.HYBRAS$theta50)
summary(hydrosprops.HYBRAS$satwat)
hist(hydrosprops.HYBRAS$theta10, breaks=45, col="gray")
#plot(hydrosprops.HYBRAS[,c(4:5)])
#file.copy("/data/Soil_points/Brasil/HYBRAS/HYBRAS.V1_integrated_tables_RAW.csv", to = "/data/git/SoilWaterModeling/Soil_points/Brasil/HYBRAS/HYBRAS.V1_integrated_tables_RAW.csv", overwrite = TRUE)

## UNSODA ----
## https://data.nal.usda.gov/dataset/unsoda-20-unsaturated-soil-hydraulic-database-database-and-program-indirect-methods-estimating-unsaturated-hydraulic-properties
unsoda.LOC = read.csv("/data/Soil_points/INT/UNSODA/general_c.csv")
#unsoda.LOC = unsoda.LOC[!unsoda.LOC$Lat==0,]
plot(unsoda.LOC[,c("Long","Lat")])
unsoda.SOIL = read.csv("/data/Soil_points/INT/UNSODA/soil_properties.csv")
str(tmp.hyd)
## Soil water retention in lab:
tmp.hyd = read.csv("/data/Soil_points/INT/UNSODA/lab_drying_h-t.csv")
tmp.hyd = tmp.hyd[!is.na(tmp.hyd$preshead),]
tmp.hyd$theta = tmp.hyd$theta*100
head(tmp.hyd)
pr.lst = c(6,10,33,15000)
cl.lst = c("w6clod", "w10cld", "w3cld", "w15l2")
tmp.hyd.tbl = data.frame(code=unique(tmp.hyd$code), w6clod=NA, w10cld=NA, w3cld=NA, w15l2=NA)
for(i in 1:length(pr.lst)){
  tmp.hyd.tbl[,cl.lst[i]] = plyr::join(tmp.hyd.tbl, tmp.hyd[which(tmp.hyd$preshead==pr.lst[i]),c("code","theta")], match="first")$theta
}
head(tmp.hyd.tbl)
unsoda.col = join_all(list(unsoda.LOC, unsoda.SOIL, tmp.hyd.tbl))
#head(unsoda.col)
summary(unsoda.col$OM_content)
unsoda.col$oc = unsoda.col$OM_content/1.724
for(j in c("usiteid", "layer_sequence", "labsampnum", "db_13b", "COLEws", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "cec_nh4", "ph_kcl", "wpg2")){  unsoda.col[,j] = NA }
unsoda.sel.h = c("code", "usiteid", "date", "Long", "Lat", "labsampnum", "layer_sequence", "depth_upper", "depth_lower", "horizon", "db_13b", "bulk_density", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "Texture", "Clay", "Silt", "Sand", "oc", "ph_kcl", "pH", "CEC", "cec_nh4", "wpg2")
hydrosprops.UNSODA = unsoda.col[,unsoda.sel.h]
hydrosprops.UNSODA$source_db = "UNSODA"
hist(hydrosprops.UNSODA$w15l2, breaks=45, col="gray")
## save
#unsoda.csv = paste0("/data/Soil_points/INT/UNSODA/", c("general_c.csv","soil_properties.csv","lab_drying_h-t.csv"))
#file.copy(unsoda.csv, to = gsub("/data/", "/data/git/SoilWaterModeling/", unsoda.csv), overwrite = TRUE)

## HydroS ----
hydros.tbl = read.csv("/data/Soil_points/INT/HydroS/int_rawret.csv", sep="\t", stringsAsFactors = FALSE, dec = ",")
hydros.tbl = hydros.tbl[!is.na(hydros.tbl$TENSION),]
summary(hydros.tbl$TENSION)
hydros.tbl$TENSIONc = cut(hydros.tbl$TENSION, breaks=c(1,5,8,15,30,40,1000,15001))
summary(hydros.tbl$TENSIONc)
hydros.tbl$WATER_CONTENT = hydros.tbl$WATER_CONTENT
summary(hydros.tbl$WATER_CONTENT)
head(hydros.tbl)
pr2.lst = c("(5,8]", "(8,15]","(30,40]","(1e+03,1.5e+04]")
cl.lst = c("w6clod", "w10cld", "w3cld", "w15l2")
hydros.tbl.df = data.frame(SITE_ID=unique(hydros.tbl$SITE_ID), w6clod=NA, w10cld=NA, w3cld=NA, w15l2=NA)
for(i in 1:length(pr2.lst)){
  hydros.tbl.df[,cl.lst[i]] = plyr::join(hydros.tbl.df, hydros.tbl[which(hydros.tbl$TENSIONc==pr2.lst[i]),c("SITE_ID","WATER_CONTENT")], match="first")$WATER_CONTENT
}
head(hydros.tbl.df)
## properties:
hydros.soil = read.csv("/data/Soil_points/INT/HydroS/int_basicdata.csv", sep="\t", stringsAsFactors = FALSE, dec = ",")
head(hydros.soil)
plot(hydros.soil[,c("H","R")])
hydros.col = plyr::join(hydros.soil, hydros.tbl.df)
summary(hydros.col$OMC)
hydros.col$oc = hydros.col$OMC/1.724
for(j in c("layer_sequence", "db_13b", "COLEws", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2")){  hydros.col[,j] = NA }
hydros.sel.h = c("SITE_ID", "SITE", "SAMP_DATE", "H", "R", "SAMP_NO", "layer_sequence", "TOP_DEPTH", "BOT_DEPTH", "HORIZON", "db_13b", "BULK_DENSITY", "COLEws", "w6clod", "w10cld", "w3cld", "w15l2", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "tex_psda", "clay_tot_psa", "silt_tot_psa", "sand_tot_psa", "oc", "ph_kcl", "ph_h2o", "cec_sum", "cec_nh4", "wpg2")
hydros.sel.h[which(!hydros.sel.h %in% names(hydros.col))]
hydrosprops.HYDROS = hydros.col[,hydros.sel.h]
hydrosprops.HYDROS$source_db = "HydroS"
hist(hydrosprops.HYDROS$w15l2, breaks=45, col="gray")
## save
#hydros.csv = paste0("/data/Soil_points/INT/HydroS/", c("int_rawret.csv","int_basicdata.csv"))
#file.copy(hydros.csv, to = gsub("/data/", "/data/git/SoilWaterModeling/", hydros.csv), overwrite = TRUE)

## Pseudo-observations ----
## 0 soil organic carbon + 98% sand content (deserts)
sprops.SIM = readRDS("/data/LandGIS/training_points/soil/sprops.SIM.rds")
sprops.SIM$w10cld = 3.1
sprops.SIM$w3cld = 1.2
sprops.SIM$w15l2 = 0.8
sprops.SIM$tex_psda = "sand"
sprops.SIM$usiteid = sprops.SIM$lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0
sprops.SIM$longitude_decimal_degrees = sprops.SIM$x
sprops.SIM$latitude_decimal_degrees = sprops.SIM$y
for(j in c("db_13b", "COLEws", "w6clod", "w15bfm", "adod", "wrd_ws13", "cec7_cly", "w15cly", "ph_kcl", "cec_sum", "cec_nh4")){  sprops.SIM[,j] = NA }
col.names[which(!col.names %in% names(sprops.SIM))]
hydrosprops.SIM = sprops.SIM[,col.names]
#file.copy("/data/LandGIS/training_points/soil/sprops.SIM.rds", "/data/git/SoilWaterModeling/Soil_points/SIM/sprops.SIM.rds")
str(hydrosprops.SIM)

## Bind ALL ----
ls(pattern=glob2rx("hydrosprops.*"))
## 11
tot_sprops = dplyr::bind_rows(lapply(ls(pattern=glob2rx("hydrosprops.*")), function(i){ mutate_all(setNames(get(i), col.names), as.character) }))
## convert to numeric:
for(j in c("longitude_decimal_degrees","latitude_decimal_degrees","layer_sequence","hzn_top","hzn_bot","oc","ph_h2o","ph_kcl","db_od","clay_tot_psa","sand_tot_psa","silt_tot_psa","wpg2","db_13b","COLEws","w15cly","w6clod","w10cld","w3cld","w15l2","w15bfm","adod","wrd_ws13","cec7_cly","cec_sum","cec_nh4")){
  tot_sprops[,j] = as.numeric(tot_sprops[,j])
}
#head(tot_sprops)
tot_sprops.pnts = tot_sprops[!duplicated(tot_sprops$site_key),c("site_key","source_db","longitude_decimal_degrees","latitude_decimal_degrees")]
nrow(tot_sprops.pnts)
## 96,605 points
summary(as.factor(tot_sprops$source_db))
# AfSPDB  Canada_NPDB       HYBRAS       HydroS   ISRIC_ISIS   ISRIC_WISE Russia_EGRPR    SIMULATED 
# 80319        21993         8793          173         6546        38679         4961         8133 
# SPADE2       UNSODA    USDA_NCSS 
# 2356          790       196267
library("ggplot2")
mp <- NULL
mapWorld <- borders("world", colour="gray50", fill="gray50") 
mp <- ggplot() + mapWorld + geom_point(aes(x=tot_sprops.pnts$longitude_decimal_degrees, y=tot_sprops.pnts$latitude_decimal_degrees), color="black", pch="+", size=2) 
mp
## Removed 12038 rows containing missing values (geom_point).

## Typos and physically impossible values
#hist(tot_sprops$clay_tot_psa)
for(j in c("clay_tot_psa","sand_tot_psa","silt_tot_psa","wpg2","w6clod", "w10cld", "w3cld", "w15l2")){
  tot_sprops[,j] = ifelse(tot_sprops[,j]>100|tot_sprops[,j]<0, NA, tot_sprops[,j])
}
for(j in c("ph_h2o","ph_kcl")){
  tot_sprops[,j] = ifelse(tot_sprops[,j]>12|tot_sprops[,j]<2, NA, tot_sprops[,j])
}
#hist(tot_sprops$db_od)
for(j in c("db_od")){
  tot_sprops[,j] = ifelse(tot_sprops[,j]>2.4|tot_sprops[,j]<0.05, NA, tot_sprops[,j])
}
#hist(tot_sprops$oc)
for(j in c("oc")){
  tot_sprops[,j] = ifelse(tot_sprops[,j]>90|tot_sprops[,j]<0, NA, tot_sprops[,j])
}
tot_sprops$hzn_depth = tot_sprops$hzn_top + (tot_sprops$hzn_bot-tot_sprops$hzn_top)/2
tot_sprops = tot_sprops[!is.na(tot_sprops$hzn_depth),]

## check distributions ----
library(ggplot2)
ggplot(tot_sprops[tot_sprops$w15l2<100,], aes(x=source_db, y=w15l2)) + geom_boxplot() + theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggplot(tot_sprops[tot_sprops$w3cld<100,], aes(x=source_db, y=w3cld)) + geom_boxplot() + theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggplot(tot_sprops, aes(x=source_db, y=db_od)) + geom_boxplot() + theme(axis.text.x = element_text(angle = 90, hjust = 1))
ggplot(tot_sprops, aes(x=source_db, y=ph_kcl)) + geom_boxplot() + theme(axis.text.x = element_text(angle = 90, hjust = 1))
summary(!is.na(tot_sprops$ph_h2o[tot_sprops$source_db=="USDA_NCSS"]))
## Final objects ----
saveRDS(tot_sprops, "/data/LandGIS/training_points/soil/soil_hydroprops_horizons.rds")
## complete points only:
sel.compl = !is.na(tot_sprops$longitude_decimal_degrees) & !is.na(tot_sprops$w15l2) & !is.na(tot_sprops$w3cld) & !is.na(tot_sprops$ph_h2o) & !is.na(tot_sprops$clay_tot_psa) & !is.na(tot_sprops$oc)
summary(sel.compl)
## 20,446
saveRDS(tot_sprops[sel.compl,], "/data/LandGIS/training_points/soil/soil_hydroprops_horizons_COMPLETE.rds")
## points COMPLETE ----
#tot_sprops.pnts.C = tot_sprops.pnts[which(tot_sprops.pnts$site_key %in% tot_sprops$site_key[sel.compl] & !tot_sprops.pnts$source_db == "SIMULATED"),]
#str(tot_sprops.pnts.C)
## 3516
#mp2 <- NULL
#mp2 <- ggplot() + mapWorld + geom_point(aes(x=tot_sprops.pnts.C$longitude_decimal_degrees, y=tot_sprops.pnts.C$latitude_decimal_degrees), color="black", pch="+", size=2) 
#mp2

tot_sprops.pnts$location_id = as.factor(paste("ID", round(tot_sprops.pnts$longitude_decimal_degrees,5), round(tot_sprops.pnts$latitude_decimal_degrees,5), sep="_"))
tot_sprops.pnts = tot_sprops.pnts[complete.cases(tot_sprops.pnts[,c("longitude_decimal_degrees","latitude_decimal_degrees")]),]
coordinates(tot_sprops.pnts) <- ~ longitude_decimal_degrees+latitude_decimal_degrees
proj4string(tot_sprops.pnts) = "+proj=longlat +datum=WGS84"
saveRDS(tot_sprops.pnts, "/data/LandGIS/training_points/soil/soil_hydroprops.pnts.rds")
unlink("/data/LandGIS/training_points/soil/hydroprops_locations.pnts.shp")
writeOGR(tot_sprops.pnts, "/data/LandGIS/training_points/soil/hydroprops_locations.pnts.shp", "hydroprops_locations", "ESRI Shapefile")

## save everything in one image
save.image.pigz(file="soilhydro.RData", n.cores = parallel::detectCores())
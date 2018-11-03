## Fit spatial prediction models and make global soil maps
## tom.hengl@gmail.com

library(rgdal)
library(raster)
library(fastSave)
#detach("package:fastSave", unload=TRUE)
library(ranger)
library(caret)
#library(caretEnsemble)
#library(SuperLearner)

source("/data/LandGIS/R/saveRDS_functions.R")
source("/data/LandGIS/R/LandGIS_functions.R")
tile.tbl = readRDS("/data/LandGIS/models/stacked250m_tiles.rds")
pr.dirs = readRDS("/data/LandGIS/models/prediction_dirs.rds")
tile.pol = readOGR("/data/LandGIS/models/tiles_ll_100km.shp")
tile.pol = tile.pol[paste0("T", tile.pol$ID) %in% pr.dirs,]
#str(tile.pol@data)
#plot(tile.pol)
#writeOGR(tile.pol, "/data/LandGIS/models/tiles_ll_100km_mask.shp", "tiles_ll_100km_mask", "ESRI Shapefile")

## USDA great groups
tax_grtgroup.pnts = readRDS.gz("/data/LandGIS/training_points/soil/tax_grtgroup.pnts.rds")
nrow(tax_grtgroup.pnts)
## 340,820
## overlay (takes 120 mins):
ov.tax <- extract.tiled(obj=tax_grtgroup.pnts, tile.pol=tile.pol, path="/data/tt/LandGIS/grid250m", ID="ID", cpus=64)
#head(ov.tax)
## Check overlay match:
#l.nm = names(ov.tax)[54]
#ov.tax[55050,l.nm]
#raster::extract(raster(paste0("/data/LandGIS/downscaled250m/", l.nm)), data.frame(x=ov.tax$X[55050], y=ov.tax$Y[55050]))
save.image.pigz()

## add tile ID:
id.t = over(spTransform(tax_grtgroup.pnts, CRS(proj4string(tile.pol))), tile.pol)
#str(id.t)
ov.tax$ID = paste0("T", id.t$ID)
saveRDS.gz(ov.tax, "/data/LandGIS/training_points/soil/ov_tax_grtgroup.pnts.rds")
#ov.tax = readRDS.gz("/data/LandGIS/training_points/soil/ov_tax_grtgroup.pnts.rds")

## layers statistics:
stat.ov = lapply(ov.tax[,grep("PC", names(ov.tax))], function(i){data.frame(t(as.vector(summary(i))))})
stat.ov = dplyr::bind_rows(stat.ov)
names(stat.ov) = c("min", "q1st", "median", "mean", "q3rd", "max", "na.count")
stat.ov$layer_name = names(ov.tax)[grep("PC", names(ov.tax))]
write.csv(stat.ov, "/data/LandGIS/soil/tax_grtgroup/covs_stats.csv")
str(stat.ov)
#View(stat.ov)

## Subset data ----
rm.tax = ov.tax[complete.cases(ov.tax[,c(grep("tax_grtgroup.f", names(ov.tax)),grep("PC", names(ov.tax)))]),]
dim(rm.tax)
## 338,677    254
pr.vars = paste0("PC", 1:nrow(stat.ov))
formulaString.USDA = as.formula(paste('tax_grtgroup.f ~ ', paste(pr.vars, collapse="+")))
rm.tax$tax_grtgroup.f = droplevels(rm.tax$tax_grtgroup.f)
str(rm.tax$tax_grtgroup.f)
## 340 levels
## legend ----
## drop? 'aquiturbels', 'glacistels', 'haploturbels', 'hemistels', 'historthels', 'histoturbels'
col.legend = read.csv("/data/Soil_points/generic/TAXOUSDA_GreatGroups_complete.csv")
col.legend$Group = tolower(col.legend$Great_Group)
col.legend$Number = 1:nrow(col.legend)

save.image.pigz(n.cores = 64)
saveRDS.gz(rm.tax, "/data/LandGIS/training_points/soil/regression.matrix_tax_grtgroup.pnts.rds")

## Testing / RFE ----
## Geographically distributed sample:
prof.s <- GSIF::sample.grid(tax_grtgroup.pnts, cell.size=c(1,1), n=4)
length(prof.s$subset)
## 8770
## determine Mtry / optimal subset of covs:
df = rm.tax[rm.tax$pedon_id %in% prof.s$subset$pedon_id,]
## Remove smaller classes as they leads to errors in the train function
xg = summary(df$tax_grtgroup.f, maxsum=length(levels(df$tax_grtgroup.f)))
selg.levs = attr(xg, "names")[xg > 10]
df$tax_grtgroup.f[which(!df$tax_grtgroup.f %in% selg.levs)] <- NA
df$tax_grtgroup.f <- droplevels(df$tax_grtgroup.f)
df <- df[complete.cases(df[,all.vars(formulaString)]),all.vars(formulaString)]
## get optimal parameters
#t.mrfX <- test_classifier(formulaString.USDA, df, sizes=seq(5,75,by=5), nfold=3, mtry.seq=c(15,40,80,110,150))
#t.mrfX$train
#t.mrfX$rfe
#str(predictors(t.mrfX$rfe))
## test run:
t.mrfX0 <- caret::train(formulaString, data=df, method="ranger", 
                   trControl = trainControl(method="repeatedcv", classProbs=TRUE, number=3, repeats=1),
                   na.action = na.omit, num.trees=85, importance="impurity",
                   tuneGrid=expand.grid(mtry = c(15,40,80,110,130,150), splitrule="gini", min.node.size=10))
t.mrfX0
# Resampling: Cross-Validated (3 fold, repeated 1 times) 
# Summary of sample sizes: 6284, 6295, 6297 
# Resampling results across tuning parameters:
#   
#   mtry  Accuracy   Kappa    
# 15   0.3059947  0.2923254
# 40   0.3144664  0.3010161
# 80   0.3117112  0.2983198
# 110   0.3108605  0.2974274
# 130   0.3117190  0.2984146
# 150   0.3108632  0.2975854
xl <- as.list(ranger::importance(t.mrfX0$finalModel))
print(t(data.frame(xl[order(unlist(xl), decreasing=TRUE)[1:55]])))

cl <- parallel::makeCluster(64)
doParallel::registerDoParallel(cl)
t.kknX <- caret::train(formulaString.USDA, data=df, method="kknn", 
            trControl = trainControl(method="repeatedcv", classProbs=TRUE, number=3, repeats=1),
            na.action=na.omit)
t.kknX
parallel::stopCluster(cl) ## closeAllConnections()
# kmax  Accuracy   Kappa    
# 5     0.2673252  0.2560729
# 7     0.2673252  0.2560729
# 9     0.2673252  0.2560729
save.image.pigz(n.cores = 64)

## Ranger model ----
mtry = t.mrfX0$bestTune$mtry
## if mtry is < 50 takes only 15 mins to fit the model
#mtry = 124
mrfX_grtgroup <- ranger::ranger(formulaString.USDA, rm.tax, importance="impurity", mtry=mtry, probability=TRUE, num.trees=85, case.weights=rm.tax$pedon_completeness_index+1) 
## TAKES ca 15mins to fit
mrfX_grtgroup
# Type:                             Probability estimation 
# Number of trees:                  85 
# Sample size:                      338677 
# Number of independent variables:  242 
# Mtry:                             40 
# Target node size:                 10 
# Variable importance mode:         impurity 
# Splitrule:                        gini 
# OOB prediction error (Brier s.):  0.4609344 
saveRDS.gz(mrfX_grtgroup, "/data/LandGIS/soil/tax_grtgroup/mrfX_grtgroup.rds")
#mrfX_grtgroup = readRDS.gz("/data/LandGIS/soil/tax_grtgroup/mrfX_grtgroup.rds")

r.file = "/data/LandGIS/soil/tax_grtgroup/grtgroup_resultsFit.txt"
cat("Results of model fitting 'randomForest':\n", file=r.file)
cat("\n", file=r.file, append=TRUE)
cat(paste("Variable:", all.vars(formulaString.USDA)[1]), file=r.file, append=TRUE)
cat("\n", file=r.file, append=TRUE)
sink(file=r.file, append=TRUE, type="output")
cat("\n Random forest model:", file=r.file, append=TRUE)
print(mrfX_grtgroup)
cat("\n Variable importance:\n", file=r.file, append=TRUE)
xl <- as.list(ranger::importance(mrfX_grtgroup))
print(t(data.frame(xl[order(unlist(xl), decreasing=TRUE)[1:25]])))
sink()

## check legend file:
mrfX_grtgroup$forest$levels[which(!mrfX_grtgroup$forest$levels %in% col.legend$Group)]
#character(0)

## predict ----
## test:
#pred_probs(i="T38715", gm=mrfX_grtgroup, tile.tbl, col.legend, varn="grtgroup", out.dir="/data/tt/LandGIS/grid250m")
#pred_probs(i="T38716", gm=mrfX_grtgroup, tile.tbl, col.legend, varn="grtgroup", out.dir="/data/tt/LandGIS/grid250m")
#pred_probs(i="T35016", gm=mrfX_grtgroup, tile.tbl, col.legend, varn="grtgroup", out.dir="/data/tt/LandGIS/grid250m")

## TH: 10GB prediction model - difficult to export
## TAKES >12hrs
detach("package:snowfall", unload=TRUE)
cpus = unclass(round((400-25)/(3*(object.size(mrfX_grtgroup)/1e9))))
library(parallel)
library(plyr)
library(ranger)
library(rgdal)
library(stats)
cl <- parallel::makeCluster(cpus, type="FORK") ## 
x = parallel::clusterApplyLB(cl, pr.dirs, function(i){ try( pred_probs(i, gm=mrfX_grtgroup, tile.tbl=tile.tbl, col.legend=col.legend, varn="grtgroup") ) })
parallel::stopCluster(cl)

#library(snowfall)
#sfInit(parallel=TRUE, cpus=cpus)
#sfLibrary(rgdal)
#sfLibrary(ranger)
#sfLibrary(stats)
#sfLibrary(plyr)
#sfExport("pred_probs", "tile.tbl", "mrfX_grtgroup", "pr.dirs", "col.legend")
#out <- snowfall::sfClusterApplyLB(pr.dirs, function(i){ try( pred_probs(i, gm=mrfX_grtgroup, tile.tbl=tile.tbl, col.legend=col.legend, varn="grtgroup") ) })
#sfStop()

r = raster("/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
cellsize = res(r)[1]
d.lst = mrfX_grtgroup$forest$levels
filename = paste0("/data/LandGIS/predicted250m/sol_grtgroup_usda.soiltax.", d.lst, "_p_250m_s0..0cm_1950..2017_v0.1.tif")
rm(mrfX_grtgroup)
gc()
save.image.pigz(n.cores = 64)

library(snowfall)
sfInit(parallel=TRUE, cpus=25) ## length(filename)
sfExport("d.lst", "mosaick_ll", "filename", "te", "cellsize")
out <- sfClusterApplyLB(1:length(d.lst), function(x){ try( mosaick_ll(varn="grtgroup_M", i=d.lst[x], out.tif=filename[x], in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot="Byte", dstnodata=255, aggregate=FALSE) )})
sfStop()

mosaick_ll(varn="grtgroup", i="C", out.tif="/data/LandGIS/predicted250m/sol_grtgroup_usda.soiltax_c_250m_s0..0cm_1950..2017_v0.1.tif", dominant = TRUE, in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot="Int16", dstnodata=-32768, aggregate=FALSE)
write.csv(col.legend[,c("Number","Group","Great_Group_2015_match","Suborder","Order")], "/data/LandGIS/predicted250m/sol_grtgroup_usda.soiltax_c_250m_s0..0cm_1950..2017_v0.1.tif.csv")

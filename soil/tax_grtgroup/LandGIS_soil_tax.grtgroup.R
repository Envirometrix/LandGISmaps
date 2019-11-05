## Fit spatial prediction models and make global soil maps
## tom.hengl@opengeohub.org

library(rgdal)
library(raster)
library(fastSave)
library(ranger)
library(caret)
library(mlr)
load(".RData")

source("/data/LandGIS/R/saveRDS_functions.R")
source("/data/LandGIS/R/LandGIS_functions.R")
tile.tbl = readRDS("/data/LandGIS/models/stacked250m_tiles.rds")
pr.dirs = readRDS("/data/LandGIS/models/prediction_dirs.rds")
tile.pol = readOGR("/data/LandGIS/models/tiles_ll_100km.shp")
tile.pol = tile.pol[paste0("T", tile.pol$ID) %in% pr.dirs,]
#str(tile.pol@data)
#plot(tile.pol)
#writeOGR(tile.pol, "/data/LandGIS/models/tiles_ll_100km_mask.shp", "tiles_ll_100km_mask", "ESRI Shapefile")

## USDA great groups ----
tax_grtgroup.pnts = readRDS.gz("/data/LandGIS/training_points/soil_tax/tax_grtgroup.pnts.rds")
nrow(tax_grtgroup.pnts)
## 340,931
## overlay (takes 120 mins):
ov.tax <- extract.tiled(obj=tax_grtgroup.pnts, tile.pol=tile.pol, path="/data/tt/LandGIS/grid250m", ID="ID", cpus=64)
#head(ov.tax)
#summary(ov.tax$clm_bioclim.var_chelsa.1_m_1km_s0..0cm_1979..2013_v1.0.tif)
## Check overlay match:
#l.nm = names(ov.tax)[54]
#ov.tax[55050,l.nm]
#raster::extract(raster(paste0("/data/LandGIS/downscaled250m/", l.nm)), data.frame(x=ov.tax$X[55050], y=ov.tax$Y[55050]))
save.image.pigz(n.cores = 64)

## add tile ID:
id.t = over(spTransform(tax_grtgroup.pnts, CRS(proj4string(tile.pol))), tile.pol)
#str(id.t)
ov.tax$ID = paste0("T", id.t$ID)
saveRDS.gz(ov.tax, "/data/LandGIS/training_points/soil_tax/ov_tax_grtgroup.pnts.rds")
#ov.tax = readRDS.gz("/data/LandGIS/training_points/soil_tax/ov_tax_grtgroup.pnts.rds")

## Predictors ----
pr.vars = make.names(unique(unlist(sapply(c("sm2rain", "mod11a2", "mod09a1","mangroves", "fapar", "landsat", "f02dar", "probav.lc100_p", "bioclim.var_chelsa", "irradiation_solar.atlas", "usgs.ecotapestry", "floodmap.500y", "water.table.depth_deltares", "snow.prob_esacci", "water.", "wind.speed_terraclimate", "dtm_", "cloud.fraction_earthenv", "wetlands.cw_upmc"), function(i){names(ov.tax)[grep(i, names(ov.tax))]}))))
## many missing values in FAPAR images
#pr.vars = pr.vars[-grep("proba.v.dec", pr.vars)]
#pr.vars = pr.vars[-grep("proba.v.jan", pr.vars)]
pr.vars = pr.vars[-grep("land.copernicus.annual_d", pr.vars)]
str(pr.vars)
## 323

## layers statistics:
stat.ov = lapply(ov.tax[,pr.vars], function(i){data.frame(t(as.vector(summary(i))))})
stat.ov = dplyr::bind_rows(stat.ov)
names(stat.ov) = c("min", "q1st", "median", "mean", "q3rd", "max", "na.count")
stat.ov$layer_name = pr.vars
write.csv(stat.ov, "/data/LandGIS/soil/tax_grtgroup/covs_stats.csv")
#str(stat.ov)
#View(stat.ov)

## Subset data ----
rm.tax = ov.tax[complete.cases(ov.tax[,c("tax_grtgroup.f", pr.vars)]),]
dim(rm.tax)
## 338,585    379
formulaString.USDA = as.formula(paste('tax_grtgroup.f ~ ', paste(pr.vars, collapse="+")))
rm.tax$tax_grtgroup.f = droplevels(rm.tax$tax_grtgroup.f)
str(rm.tax$tax_grtgroup.f)
## 340 levels
## legend ----
## drop? 'aquiturbels', 'glacistels', 'haploturbels', 'hemistels', 'historthels', 'histoturbels'
col.legend = read.csv("/data/Soil_points/generic/TAXOUSDA_GreatGroups_complete.csv")
col.legend$Group = tolower(col.legend$Great_Group)
col.legend$Number = 1:nrow(col.legend)
## TH: Note the typo "endoaquert" and "endoaquerts" are the same class!
save.image.pigz(n.cores = 64)
saveRDS.gz(rm.tax, "/data/LandGIS/training_points/soil_tax/regression.matrix_tax_grtgroup.pnts.rds")

## Testing / RFE ----
## Geographically distributed sample:
prof.s <- GSIF::sample.grid(tax_grtgroup.pnts, cell.size=c(1,1), n=10)
length(prof.s$subset)
## 12407
## determine Mtry / optimal subset of covs:
df = rm.tax[rm.tax$pedon_id %in% prof.s$subset$pedon_id,]
## Remove smaller classes as they leads to errors in the train function
xg = summary(df$tax_grtgroup.f, maxsum=length(levels(df$tax_grtgroup.f)))
selg.levs = attr(xg, "names")[xg > 10]
df$tax_grtgroup.f[which(!df$tax_grtgroup.f %in% selg.levs)] <- NA
df$tax_grtgroup.f <- droplevels(df$tax_grtgroup.f)
df <- df[complete.cases(df[,all.vars(formulaString.USDA)]),all.vars(formulaString.USDA)]
dim(df)

## mtry tuned ----
library(mlr)
tsk.C <- mlr::makeClassifTask(data = df[,all.vars(formulaString.USDA)], target = all.vars(formulaString.USDA)[1])
discrete_ps = makeParamSet( makeDiscreteParam("mtry", values = seq(10,120,by=10)) )
ctrl = makeTuneControlGrid()
rdesc = makeResampleDesc("CV", iters = 3L)
parallelMap::parallelStartSocket(parallel::detectCores())
resC = tuneParams(mlr::makeLearner("classif.ranger", num.threads = parallel::detectCores(), num.trees=85), task = tsk.C, resampling = rdesc, par.set = discrete_ps, control = ctrl)
parallelMap::parallelStop()
resC
#Tune result:
#  Op. pars: mtry=60
# mmce.test.mean=0.6368333

## Feature selection ----
outer = makeResampleDesc("CV", iters = 3L)
inner = makeResampleDesc("Holdout")
ctrl = makeFeatSelControlRandom(maxit = 20)
lrn.rf = mlr::makeLearner("classif.ranger", num.threads = parallel::detectCores(), mtry=resC$x$mtry, num.trees=85)
lrn1 = makeFeatSelWrapper(lrn.rf, resampling = inner, control = ctrl, show.info=TRUE)
parallelMap::parallelStartSocket(parallel::detectCores())
glc.mod1 = train(lrn1, task = tsk.C)
glc.sfeats1 = getFeatSelResult(glc.mod1)
str(glc.sfeats1$x)
## 164
lrn.xg = mlr::makeLearner("classif.xgboost")
lrn2 = makeFeatSelWrapper(lrn.xg, resampling = inner, control = ctrl, show.info=TRUE)
glc.mod2 = train(lrn2, task = tsk.C)
parallelMap::parallelStop()
glc.sfeats2 = getFeatSelResult(glc.mod2)
str(glc.sfeats2$x)
## new shorter formula
formulaString.USDA0 = as.formula(paste('tax_grtgroup.f ~ ', paste(unique(c(glc.sfeats1$x, glc.sfeats2$x)), collapse="+")))
length(all.vars(formulaString.USDA0))
## 256

## Ranger complete data ----
mrfX_grtgroup <- ranger::ranger(formulaString.USDA0, rm.tax, importance="impurity", mtry=resC$x$mtry, probability=TRUE, num.trees=85, case.weights=rm.tax$pedon_completeness_index+1) 
## TAKES >1hr to fit
mrfX_grtgroup
# Type:                             Probability estimation 
# Number of trees:                  85 
# Sample size:                      338585 
# Number of independent variables:  248 
# Mtry:                             60 
# Target node size:                 10 
# Variable importance mode:         impurity 
# Splitrule:                        gini 
# OOB prediction error (Brier s.):  0.4237284
saveRDS.gz(mrfX_grtgroup, "/data/LandGIS/soil/tax_grtgroup/mrfX_grtgroup.rds")
#mrfX_grtgroup = readRDS.gz("/data/LandGIS/soil/tax_grtgroup/mrfX_grtgroup.rds")
save.image.pigz(n.cores = 64)

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

## Ensemble ML ----
# library(mlr)
# ## no need to map classes with <10 observations
# xg0 = summary(rm.tax$tax_grtgroup.f, maxsum=length(levels(rm.tax$tax_grtgroup.f)))
# selg.levs0 = attr(xg0, "names")[xg0 > 9]
# rm.tax.f = rm.tax[,all.vars(formulaString.USDA0)]
# rm.tax.f$tax_grtgroup.f[which(!rm.tax.f$tax_grtgroup.f %in% selg.levs0)] <- NA
# rm.tax.f$tax_grtgroup.f <- droplevels(rm.tax.f$tax_grtgroup.f)
# rm.tax.f <- rm.tax.f[complete.cases(rm.tax.f),]
# dim(rm.tax.f)
# #[1] 338349    256
# tsk.C0 <- mlr::makeClassifTask(data = rm.tax.f[,all.vars(formulaString.USDA0)], target = all.vars(formulaString.USDA0)[1])
# tsk.C0
# ## Classes: 302
# ## >8hrs of computing
# SL.library <- c("classif.ranger", "classif.xgboost", "classif.nnTrain")
# parallelMap::parallelStartSocket(parallel::detectCores())
# lrns <- list(mlr::makeLearner(SL.library[1], num.threads = parallel::detectCores(), mtry = resC$x$mtry, num.trees=85), mlr::makeLearner(SL.library[2], verbose=1), mlr::makeLearner(SL.library[3]))
# lrns <- lapply(lrns, setPredictType, "prob")
# init.m <- mlr::makeStackedLearner(base.learners = lrns, predict.type = "prob", method = "stack.cv", super.learner = "classif.glmnet")
# system.time( m.grtgroup <- mlr::train(init.m, tsk.C0) )
# #user  system elapsed 
# # 96074.180   725.901 29893.731 
# parallelMap::parallelStop()
# saveRDS.gz(m.grtgroup, "/data/LandGIS/soil/tax_grtgroup/eml_grtgroup.rds")
# save.image.pigz(n.cores = 64)
#col.legend$response = make.names(col.legend$Group)
#system.time( pred_probs.mlr(i="T38715", m.grtgroup, tile.tbl, col.legend, varn="grtgroup", out.dir="/data/tt/LandGIS/grid250m") )
#19000*1033/60/60/20
## 5-6 days of computing

## Predict ----
# x = list.files(path="/data/tt/LandGIS/grid250m", pattern=glob2rx("^grtgroup_C_*.tif$"), recursive=TRUE, full.names = TRUE)
x = list.files(path="/data/tt/LandGIS/grid250m", pattern=glob2rx("^grtgroup_*.tif$"), recursive=TRUE, full.names = TRUE)
unlink(x)

## RF model only
#mrfX_grtgroup = readRDS.gz("/data/LandGIS/soil/tax_grtgroup/mrfX_grtgroup.rds")
system.time( pred_probs(i="T38715", gm=mrfX_grtgroup, tile.tbl, col.legend, varn="grtgroup", out.dir="/data/tt/LandGIS/grid250m") )
#pred_probs(i="T38716", gm=mrfX_grtgroup, tile.tbl, col.legend, varn="grtgroup", out.dir="/data/tt/LandGIS/grid250m")
#pred_probs(i="T52349", gm=mrfX_grtgroup, tile.tbl, col.legend, varn="grtgroup", out.dir="/data/tt/LandGIS/grid250m")
pred_probs(i="T23592", gm=mrfX_grtgroup, tile.tbl, col.legend, varn="grtgroup", out.dir="/data/tt/LandGIS/grid250m")
## TAKES >12hrs
detach("package:snowfall", unload=TRUE)
cpus = unclass(round((400-25)/(3*(object.size(mrfX_grtgroup)/1e9)))) ## 12
gc(); gc(); gc()
library(parallel)
library(plyr)
library(ranger)
library(rgdal)
library(stats)
cl <- parallel::makeCluster(cpus, type="FORK") ## 
x = parallel::clusterApplyLB(cl, pr.dirs, function(i){ try( pred_probs(i, gm=mrfX_grtgroup, tile.tbl=tile.tbl, col.legend=col.legend, varn="grtgroup") ) })
parallel::stopCluster(cl)
# 1338 nodes produced errors; first error: Error in data.frame(..., check.names = FALSE) : 
#  arguments imply differing number of rows: 1, 0

## Final mosaics ----
r = raster("/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
cellsize = res(r)[1]
d.lst = mrfX_grtgroup$forest$levels
filename = paste0("/data/LandGIS/predicted250m/sol_grtgroup_usda.soiltax.", d.lst, "_p_250m_s0..0cm_1950..2017_v0.2.tif")
rm(mrfX_grtgroup)
gc()
save.image.pigz(n.cores = 64)

library(snowfall)
sfInit(parallel=TRUE, cpus=20) ## length(filename)
sfExport("d.lst", "mosaick_ll", "filename", "te", "cellsize")
out <- sfClusterApplyLB(1:length(d.lst), function(x){ try( mosaick_ll(varn="grtgroup_M", i=d.lst[x], out.tif=filename[x], in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot="Byte", dstnodata=255, aggregate=FALSE) )})
sfStop()

mosaick_ll(varn="grtgroup", i="C", out.tif="/data/LandGIS/predicted250m/sol_grtgroup_usda.soiltax_c_250m_s0..0cm_1950..2017_v0.2.tif", dominant=TRUE, in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot="Int16", dstnodata=-32768, aggregate=FALSE)
write.csv(col.legend[,c("Number","Group","Great_Group_2015_match","Suborder","Order")], "/data/LandGIS/predicted250m/sol_grtgroup_usda.soiltax_c_250m_s0..0cm_1950..2017_v0.2.tif.csv")

## Orders, suborders ----
## Create maps with higher level classification
input.tif = list.files("/data/LandGIS/predicted250m", pattern=glob2rx("sol_grtgroup_usda.soiltax.*_p_250m_b0..0cm_1950..2017_v0.2.tif$"), full.names = TRUE)
## 340
#grtgroup_generalize(i="T38715", input.tif = input.tif, tile.tbl=tile.tbl, col.legend=col.legend)

## takes ca 10hrs!
library(snowfall)
sfInit(parallel=TRUE, cpus=64)
sfExport("input.tif", "grtgroup_generalize", "tile.tbl", "col.legend")
sfLibrary(rgdal)
out <- sfClusterApplyLB(pr.dirs, function(x){ try( grtgroup_generalize(x, input.tif = input.tif, tile.tbl=tile.tbl, col.legend=col.legend) )})
sfStop()

so.lst = tolower(levels(col.legend$Suborder))
filename2 = paste0("/data/LandGIS/predicted250m/sol_suborder_usda.soiltax.", so.lst, "_p_250m_s0..0cm_1950..2017_v0.2.tif")
save.image.pigz(n.cores = 64)

library(snowfall)
sfInit(parallel=TRUE, cpus=15) 
sfExport("so.lst", "mosaick_ll", "filename2", "te", "cellsize")
out <- sfClusterApplyLB(1:length(so.lst), function(x){ try( mosaick_ll(out.tif=filename2[x], in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot="Byte", dstnodata=255, aggregate=FALSE, pattern=paste0("T*_", so.lst[x], ".tif$")) )})
sfStop()

inputO.tif = list.files("/data/LandGIS/predicted250m", pattern=glob2rx("sol_suborder_usda.soiltax.*_p_250m_s0..0cm_1950..2017_v0.2.tif$"), full.names = TRUE)
## 73
#grtgroup_generalize(i="T38715", input.tif = inputO.tif, tile.tbl=tile.tbl, col.legend=col.legend, type="orders")
library(snowfall)
sfInit(parallel=TRUE, cpus=64)
sfExport("inputO.tif", "grtgroup_generalize", "tile.tbl", "col.legend")
sfLibrary(rgdal)
out <- sfClusterApplyLB(pr.dirs, function(x){ try( grtgroup_generalize(x, input.tif = inputO.tif, tile.tbl=tile.tbl, col.legend=col.legend, type="orders") )})
sfStop()

so2.lst = tolower(levels(col.legend$Order))
filename3 = paste0("/data/LandGIS/predicted250m/sol_order_usda.soiltax.", so2.lst, "_p_250m_s0..0cm_1950..2017_v0.2.tif")

library(snowfall)
sfInit(parallel=TRUE, cpus=12) 
sfExport("so2.lst", "mosaick_ll", "filename3", "te", "cellsize")
out <- sfClusterApplyLB(1:length(so2.lst), function(x){ try( mosaick_ll(out.tif=filename3[x], in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot="Byte", dstnodata=255, aggregate=FALSE, pattern=paste0("T*_", so2.lst[x], ".tif$")) )})
sfStop()
save.image.pigz(n.cores = 64)

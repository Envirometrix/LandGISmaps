## Fit spatial prediction models and make global maps of soil available water
## tom.hengl@gmail.com & surya.gupta@usys.ethz.ch

library(rgdal)
library(raster)
library(fastSave)
library(ranger)
library(xgboost)
library(caret)
library(plyr)
library(SuperLearner)
library(matrixStats)
load(".RData")

source("/data/LandGIS/R/saveRDS_functions.R")
source("/data/LandGIS/R/LandGIS_functions.R")
## tiling system
tile.tbl = readRDS("/data/LandGIS/models/stacked250m_tiles.rds")
pr.dirs = readRDS("/data/LandGIS/models/prediction_dirs.rds")
tile.pol = readOGR("/data/LandGIS/models/tiles_ll_100km.shp")
tile.pol = tile.pol[paste0("T", tile.pol$ID) %in% pr.dirs,]
## Grid def ----
r = raster("/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
cellsize = res(r)[1]

## Load point data ----
## Global compilation of soil properties:
soil_hydroprops.pnts = readRDS.gz("/data/LandGIS/training_points/soil_phys/soil_hydroprops.pnts.rds")
tot_hydroprops = readRDS.gz("/data/LandGIS/training_points/soil_phys/soil_hydroprops_horizons.rds")
soil_hydroprops.pnts = soil_hydroprops.pnts[which(soil_hydroprops.pnts$location_id %in% tot_hydroprops$location_id),]
str(soil_hydroprops.pnts)
## 25,269 points
#summary(as.factor(soil_hydroprops.pnts$source_db))

## Spatial overlay -----
#(takes 15 mins):
ov.hydroprops <- extract.tiled(obj=soil_hydroprops.pnts, tile.pol=tile.pol, path="/data/tt/LandGIS/grid250m", ID="ID", cpus=parallel::detectCores())
## add tile ID:
id.t = over(spTransform(soil_hydroprops.pnts, CRS(proj4string(tile.pol))), tile.pol)
#str(id.t)
ov.hydroprops$ID = paste0("T", id.t$ID)
ov.hydroprops$location_id = soil_hydroprops.pnts$location_id
saveRDS.gz(ov.hydroprops, "/data/LandGIS/training_points/soil_phys/ov_soil_hydro.properties.pnts.rds")
#ov.hydroprops = readRDS.gz("/data/LandGIS/training_points/soil_phys/ov_soil_properties.pnts.rds")
rm.hydroprops = plyr::join(tot_hydroprops, ov.hydroprops, type="left", by="location_id")
## filter non-sensical data:
rm.hydroprops$w3cld = ifelse(rm.hydroprops$w3cld>99, NA, rm.hydroprops$w3cld)
rm.hydroprops$w15l2 = ifelse(rm.hydroprops$w15l2>99, NA, rm.hydroprops$w15l2)
summary(rm.hydroprops$w15l2)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#  0.000   8.236  14.761  16.115  22.422  98.312   10930
summary(rm.hydroprops$w3cld)
summary(rm.hydroprops$w3cld/rm.hydroprops$w15l2)
#Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
#   0.00    1.50    1.86     Inf    2.57     Inf   71523 
rm.hydroprops$dataset_confidence = 1/as.numeric(rm.hydroprops$confidence_degree)
rm.hydroprops$dataset_confidence = ifelse(is.na(rm.hydroprops$dataset_confidence)|rm.hydroprops$dataset_confidence==Inf, 0.1, rm.hydroprops$dataset_confidence)
summary(rm.hydroprops$dataset_confidence)
saveRDS.gz(rm.hydroprops, "/data/LandGIS/soil/soil_water/rm_soil_properties.rds")
#rm.hydroprops = readRDS.gz("/data/LandGIS/soil/soil_water/rm_soil_properties.rds")
save.image.pigz(n.cores = parallel::detectCores())

## Predictors ----
pr.vars = make.names(unique(unlist(sapply(c("sm2rain", "mod11a2", "mod09a1","mangroves", "fapar", "landsat", "f02dar", "bioclim.var_chelsa", "irradiation_solar.atlas", "usgs.ecotapestry", "floodmap.500y", "water.table.depth_deltares", "snow.prob_esacci", "water.", "wind.speed_terraclimate", "dtm_", "cloud.fraction_earthenv", "wetlands.cw_upmc"), function(i){names(rm.hydroprops)[grep(i, names(rm.hydroprops))]}))))
## many missing values in FAPAR images
#pr.vars = pr.vars[-grep("proba.v.dec", pr.vars)]
#pr.vars = pr.vars[-grep("proba.v.jan", pr.vars)]
pr.vars = pr.vars[-grep("land.copernicus.annual_d", pr.vars)]
str(pr.vars)
## 315

## target variables
rm.hydroprops$log.ksat = signif(log10( rowMeans(rm.hydroprops[,c("ksat_lab","ksat_field")], na.rm=TRUE) + 1), 4)
t.vars = c("w3cld", "w15l2", "log.ksat")
out.vars = c("watercontent.33kPa", "watercontent.1500kPa", "saturated.hyd.conductivity")
meth.vars = c("usda.4b1c", "usda.3c2a1a", "log.ksat")
summary(as.factor(rm.hydroprops$source_db[!is.na(rm.hydroprops$log.ksat)]))
#hist(rm.hydroprops$log.ksat, col="grey", breaks=30)

## Model fine-tuning ----

## Caret training settings (reduce number of combinations to speed up):
ctrl <- trainControl(method="repeatedcv", number=3, repeats=1)
gb.tuneGrid <- expand.grid(eta = c(0.3,0.4,0.5), nrounds = c(50,100,150), 
                           max_depth = 2:4, gamma = 0, colsample_bytree = 0.8, 
                           min_child_weight = 1, subsample=1)
rf.tuneGrid <- expand.grid(mtry = seq(5,120,by=10), splitrule="variance", min.node.size=5)
## Geo-distributed sub-sample
prof.s <- GSIF::sample.grid(soil_hydroprops.pnts, cell.size=c(1,1), n=3) ## 5%
plot(prof.s$subset, pch="+")
length(prof.s$subset)
## 7987

library(caret)
library(parallel)
library(ranger)
library(xgboost)
library(doParallel)
nc = parallel::detectCores()
## takes >1hr to fit all models
for(j in 1:length(t.vars)){
  out.file = paste0(t.vars[j],"_resultsFit.txt")
  if(!file.exists(out.file)){
    cat("Results of model fitting 'randomForest and XGBoost':\n\n", file=out.file)
    cat("\n", file=out.file, append=TRUE)
    cat(paste("Variable:", out.vars[j]), file=out.file, append=TRUE)
    cat("\n", file=out.file, append=TRUE)
    out.rf <- paste0("mrf.",t.vars[j],".rds")
    sel.n <- c(t.vars[j],"DEPTH",pr.vars)
    fm.t <- as.formula(paste(t.vars[j], " ~ DEPTH +", paste0(pr.vars, collapse = "+")))
    df <- hor2xyd(rm.hydroprops[rm.hydroprops$site_key %in% prof.s$subset$site_key,], U="hzn_top", L="hzn_bot")
    sel.r <- complete.cases(df[,sel.n])
    df <- df[sel.r,sel.n]
    case.weights = df$dataset_confidence
    if(!file.exists(gsub("mrf", "t.mrf", out.rf))){
      ## optimize mtry parameter:
      cl <- makePSOCKcluster(nc-2)
      doParallel::registerDoParallel(cl)
      t.mrfX <- caret::train(x=df[,c("DEPTH", pr.vars)], 
                             y=df[,t.vars[j]], method="ranger", trControl=ctrl,
                             case.weights=case.weights,
                             tuneGrid=rf.tuneGrid)
      stopCluster(cl)
      unregister()
      saveRDS.gz(t.mrfX, file=gsub("mrf", "t.mrf", out.rf))
    } else {
      t.mrfX <- readRDS.gz(gsub("mrf", "t.mrf", out.rf))
    }
    gc()
    if(!file.exists(paste0("mrf.",t.vars[j],".rds"))){
      mrfX <- ranger(formula=fm.t, 
                     data=df, importance="impurity", 
                     write.forest=TRUE, mtry=t.mrfX$bestTune$mtry, num.trees=85,
                     ## reduce number of trees so the output objects do not become TOO LARGE i.e. >5GB
                     case.weights=case.weights)
      saveRDS.gz(mrfX, file=paste0("mrf.",t.vars[j],".rds"))
    } else {
      mrfX <- readRDS.gz(paste0("mrf.",t.vars[j],".rds"))
    }
    ## Top 15 covariates:
    sink(file=out.file, append=TRUE, type="output")
    print(mrfX)
    cat("\n Variable importance:\n", file=out.file, append=TRUE)
    xl <- as.list(ranger::importance(mrfX))
    print(t(data.frame(xl[order(unlist(xl), decreasing=TRUE)[1:35]])))
    rm(t.mrfX); rm(mrfX)
    gc(); gc()
    if(!file.exists(paste0("mgb.",t.vars[j],".rds"))){
      ## fit XGBoost model using all points:
      cl <- makePSOCKcluster(nrow(gb.tuneGrid))
      doParallel::registerDoParallel(cl)
      mgbX <- caret::train(x=df[,c("DEPTH", pr.vars)], 
                           y=df[,t.vars[j]], method="xgbTree", trControl=ctrl, 
                           tuneGrid=gb.tuneGrid, case.weights=case.weights) 
      stopCluster(cl)
      unregister()
      saveRDS.gz(mgbX, file=paste0("mgb.",t.vars[j],".rds"))
      ## save also binary model for prediction purposes:
      #xgb.save(mgbX$finalModel, paste0("Xgb.",t.vars[j]))
    } else {
      mgbX <- readRDS.gz(paste0("mgb.",t.vars[j],".rds"))
    }
    importance_matrix <- xgb.importance(mgbX$coefnames, model = mgbX$finalModel)
    cat("\n", file=out.file, append=TRUE)
    print(mgbX)
    cat("\n XGBoost variable importance:\n", file=out.file, append=TRUE)
    print(importance_matrix[1:25,])
    cat("\n", file=out.file, append=TRUE)
    sink()
    rm(mgbX)
    unregister()
    closeAllConnections()
    gc(); gc()
  }
}
save.image.pigz(n.cores = parallel::detectCores())

## Final models ----
## complete data
library(mlr)
SL.library <- c("regr.ranger", "regr.xgboost", "regr.nnet")
dfs <- hor2xyd(rm.hydroprops, U="hzn_top", L="hzn_bot")
## reduce simulated points to 5%
which.sim = which(dfs$source_db=="SIMULATED")
size.sim = round(.95*length(which.sim))
sim.rm = sample(which.sim, size=size.sim)
dfs <- dfs[-sim.rm,]
for(j in 1:length(t.vars)){
  out.m.rds = paste0("/data/LandGIS/soil/soil_water/eml.m_", out.vars[j],".rds")
  if(!file.exists(out.m.rds)){
    sel.n <- c(t.vars[j], "DEPTH", pr.vars)
    sel.r <- complete.cases(dfs[,sel.n])
    #summary(as.factor(dfs$source_db[sel.r]))
    df.s <- dfs[sel.r,sel.n]
    ## by accident some covariates can have all constant values
    sd.s = sapply(df.s[,pr.vars], sd)
    rm.pr = attr(which(sd.s==0), "name")
    if(length(rm.pr)>0){
      df.s = df.s[,-which(names(df.s) %in% rm.pr)]
    }
    #dim(df.s)
    case.weights = dfs[sel.r,"dataset_confidence"]
    id.col <- as.factor(dfs[sel.r,"ID"])
    t.mrfX <- readRDS.gz(paste0("t.mrf.",t.vars[j],".rds"))
    mgbX <- readRDS.gz(paste0("mgb.",t.vars[j],".rds"))
    #hist(df.s$log.ksat, breaks=25, col="grey")
    parallelMap::parallelStartSocket(parallel::detectCores())
    tsk <- mlr::makeRegrTask(data = df.s, target = t.vars[j], weights = case.weights, blocking = id.col)
    lrns <- list(mlr::makeLearner(SL.library[1], num.threads = parallel::detectCores(), mtry = t.mrfX$bestTune$mtry, num.trees=85), mlr::makeLearner(SL.library[2], verbose=1, eta=mgbX$bestTune$eta, nrounds=mgbX$bestTune$nrounds, max_depth=mgbX$bestTune$max_depth), mlr::makeLearner(SL.library[3]))
    init.m <- mlr::makeStackedLearner(base.learners = lrns, predict.type = "response", method = "stack.cv", super.learner = "regr.glm")
    t.m <- mlr::train(init.m, tsk)
    t.m$learner.model$super.model$learner.model
    parallelMap::parallelStop()
    saveRDS.gz(t.m, out.m.rds)
    saveRDS.gz(df.s, paste0("/data/LandGIS/soil/soil_water/rm_", out.vars[j],".rds"))
  }
}
## models

save.image.pigz(n.cores = parallel::detectCores())

## Predictions ----
z.min <- as.list(c(0,0,0))
names(z.min) = t.vars
z.max <- as.list(c(100,100,5.2))
names(z.max) = t.vars
multi.lst = as.list(c(1,1,10))

## test predictions
j=3
t.m = readRDS.gz(paste0("/data/LandGIS/soil/soil_water/eml.m_", out.vars[j],".rds"))
## Rijeka
pred_response.mlr(i="T38715", m=t.m, tile.tbl, varn=t.vars[j], zmin = z.min[[j]], zmax = z.max[[j]], multiplier=multi.lst[[j]])
pred_response.mlr(i="T38716", m=t.m, tile.tbl, varn=t.vars[j], zmin = z.min[[j]], zmax = z.max[[j]], multiplier=multi.lst[[j]])
pred_response.mlr(i="T47192", m=t.m, tile.tbl, varn=t.vars[j], zmin = z.min[[j]], zmax = z.max[[j]], multiplier=multi.lst[[j]])
## Tunisia
pred_response.mlr(i="T33672", m=t.m, tile.tbl, varn=t.vars[j], zmin = z.min[[j]], zmax = z.max[[j]], multiplier=multi.lst[[j]])
## Zurich
pred_response.mlr(i="T39429", m=t.m, tile.tbl, varn=t.vars[j], zmin = z.min[[j]], zmax = z.max[[j]], multiplier=multi.lst[[j]])
## cleanup:
#x = unlist(sapply(c("awc_","w3cld_","w15l2_","log.ksat_"), function(i){list.files("/data/tt/LandGIS/grid250m", i, full.names=TRUE, recursive=TRUE)}))
#unlink(x)

## Run per property ----
#load(".RData")
for(j in 1:length(out.vars)){
  t.m = readRDS.gz(paste0("/data/LandGIS/soil/soil_water/eml.m_", out.vars[j],".rds"))
  library(snowfall)
  sfInit(parallel=TRUE, cpus=60)
  sfExport("t.m", "pred_response.mlr", "tile.tbl", "t.vars", "z.min", "z.max", "multi.lst", "pr.dirs", "j", "fill_NA_globe")
  sfLibrary(ranger)
  sfLibrary(xgboost)
  sfLibrary(deepnet)
  sfLibrary(mlr)
  sfLibrary(rgdal)
  sfLibrary(stats)
  out <- sfClusterApplyLB(pr.dirs, function(i){ try( pred_response.mlr(i, m=t.m, tile.tbl, varn=t.vars[j], zmin = z.min[[j]], zmax = z.max[[j]], multiplier=multi.lst[[j]]) ) })
  sfStop()
  gc()
}

## Available Water capacity ----
x = awc_tile(i="T38715")
sfInit(parallel=TRUE, cpus=parallel::detectCores())
sfExport("awc_tile", "pr.dirs")
sfLibrary(raster)
sfLibrary(rgdal)
out <- sfClusterApplyLB(pr.dirs, function(i){try( awc_tile(i) )})
sfStop()

## Final mosaics ----
filename.lst = c(
  as.vector(sapply(paste0("b", c(0, 10, 30, 60, 100, 200), "..", c(0, 10, 30, 60, 100, 200)), function(i){ paste0("/data/LandGIS/predicted250m/sol_",out.vars,"_", meth.vars, "_m_250m_", i, "cm_1950..2017_v0.1.tif") })), paste0("/data/LandGIS/predicted250m/sol_available.water.capacity_usda.mm_m_250m_", c(0, 10, 30, 60, 100),"..", c(10, 30, 60, 100, 200), "cm_1950..2017_v0.1.tif"),
  paste0("/data/LandGIS/predicted250m/sol_available.water.capacity_usda.mm_m_250m_0..200cm_1950..2017_v0.1.tif")
)
filename.lst = c(filename.lst, gsub("_m_", "_md_", filename.lst))
## 30 maps in total
varn.lst = rep(c(rep(t.vars, 6), rep("awc", 6)), 2)
d.lst = c(as.vector(sapply(paste0("M_sl", 1:6), function(i){rep(i, 3)})),
          paste0("M_sh", 1:5), paste0("M_tot"),
          as.vector(sapply(paste0("sd_sl", 1:6), function(i){rep(i, 3)})),
          paste0("sd_sh", 1:5), paste0("sd_tot") )
View(data.frame(filename.lst, varn.lst, d.lst))
write.csv(data.frame(filename.lst, varn.lst, d.lst), "/data/LandGIS/soil/soil_water/filename_list.csv")
#x = list.files("/data/LandGIS/predicted250m", glob2rx("sol_*water*_v0.1.tif$"), full.names = TRUE)
#file.rename(x, gsub("v0.1", "v0.2", x))

library(snowfall)
sfInit(parallel=TRUE, cpus=25)
sfExport("varn.lst", "d.lst", "mosaick_ll", "filename.lst", "te", "cellsize")
out <- sfClusterApplyLB(1:length(filename.lst), function(x){ try( mosaick_ll(varn=varn.lst[x], i=d.lst[x], out.tif=filename.lst[x], in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot=ifelse(varn.lst[x]=="awc", "Int16", "Byte"), dstnodata=ifelse(varn.lst[x]=="awc", "-32768", "255"), aggregate=FALSE) )})
sfStop()

save.image.pigz(n.cores = parallel::detectCores())
rm.aux = list.files("/mnt/DATA/LandGIS/", pattern=glob2rx("*.tif.aux.xml"), full.names = TRUE, recursive = TRUE)
unlink(rm.aux)
## copy to massive storage ----
#x = list.files("/mnt/DATA/LandGIS/predicted250m", glob2rx("sol_*_*_m_250m_*_*_v0.*.tif$"), full.names = TRUE)
#unlink(x)

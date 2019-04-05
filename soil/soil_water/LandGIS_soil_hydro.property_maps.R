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
soil_hydroprops.pnts = readRDS.gz("/data/LandGIS/training_points/soil/soil_hydroprops.pnts.rds")
tot_hydroprops = readRDS.gz("/data/LandGIS/training_points/soil/soil_hydroprops_horizons.rds")
sel.na = (!is.na(tot_hydroprops$w3cld) | !is.na(tot_hydroprops$w15l2))
summary(sel.na)
## 170,456
tot_hydroprops = tot_hydroprops[sel.na,]
soil_hydroprops.pnts = soil_hydroprops.pnts[which(soil_hydroprops.pnts$site_key %in% tot_hydroprops$site_key),]
str(soil_hydroprops.pnts)
## 25,404 points
#summary(as.factor(soil_hydroprops.pnts$source_db))
#AfSPDB       HYBRAS       HydroS   ISRIC_ISIS   ISRIC_WISE Russia_EGRPR    SIMULATED    USDA_NCSS 
#3016          346           73          350         1483          247         2711        17178

## overlay (takes 15 mins):
ov.hydroprops <- extract.tiled(obj=soil_hydroprops.pnts, tile.pol=tile.pol, path="/data/tt/LandGIS/grid250m", ID="ID", cpus=parallel::detectCores())
## add tile ID:
id.t = over(spTransform(soil_hydroprops.pnts, CRS(proj4string(tile.pol))), tile.pol)
#str(id.t)
ov.hydroprops$ID = paste0("T", id.t$ID)
ov.hydroprops$location_id = soil_hydroprops.pnts$location_id
saveRDS.gz(ov.hydroprops, "/data/LandGIS/training_points/soil/ov_soil_hydro.properties.pnts.rds")
#ov.hydroprops = readRDS.gz("/data/LandGIS/training_points/soil/ov_soil_properties.pnts.rds")
rm.hydroprops = plyr::join(tot_hydroprops, ov.hydroprops, type="left", by="site_key")
## filter non-sensical data:
summary(rm.hydroprops$w15l2)
summary(rm.hydroprops$w3cld/rm.hydroprops$w15l2)
#rm.hydroprops$w3cld = ifelse(rm.hydroprops$w3cld>98, NA, rm.hydroprops$w3cld)
#rm.hydroprops$w15l2 = ifelse(rm.hydroprops$w15l2>98, NA, rm.hydroprops$w15l2)
rm.hydroprops$dataset_confidence = ifelse(rm.hydroprops$source_db=="USDA_NCSS", 9, ifelse(rm.hydroprops$source_db=="ISRIC_WISE" | rm.hydroprops$source_db=="ISRIC_ISIS", 5, 3))
saveRDS.gz(rm.hydroprops, "/data/LandGIS/soil/soil_water/rm_soil_properties.rds")
#rm.hydroprops = readRDS.gz("/data/LandGIS/soil/soil_water/rm_soil_properties.rds")
save.image.pigz(n.cores = parallel::detectCores())

## Geo-distributed sub-sample ----
prof.s <- GSIF::sample.grid(soil_hydroprops.pnts, cell.size=c(1,1), n=2) ## 5%
plot(prof.s$subset, pch="+")
length(prof.s$subset)
## use subset so the results are generated faster
rm.df <- hor2xyd(rm.hydroprops[rm.hydroprops$site_key %in% prof.s$subset$site_key,], U="hzn_top", L="hzn_bot")
## target variables
t.vars = c("w3cld","w15l2")
out.vars = c("watercontent.33kPa","watercontent.1500kPa")
meth.vars = c("usda.4b1c", "usda.3c2a1a")

## Test ensemble model ----
fit_t.m = function(j, X, t.vars, out.vars){
  out.m.rds = paste0("/data/LandGIS/soil/soil_water/t.m_", out.vars[j],".rds")
  if(!file.exists(out.m.rds)){
    sel.n <- c(t.vars[j],"DEPTH",paste0("PC", 1:242))
    sel.r <- complete.cases(X[,sel.n])
    df.s <- X[sel.r,sel.n]
    case.weights = X[sel.r,"dataset_confidence"]
    id.col <- X[sel.r,"ID"]
    rownames(df.s) <- NULL
    t.m <- SuperLearner(Y=df.s[,t.vars[j]], 
                   X=df.s[,c("DEPTH", paste0("PC",1:242))], 
                   SL.library = c("SL.xgboost", "SL.ranger"),
                   id=id.col, verbose=TRUE,
                   obsWeights=case.weights/max(case.weights, na.rm=TRUE),
                   cvControl=list(V=3))
    saveRDS.gz(t.m, out.m.rds)
  }
}
## test it:
#fit_t.m(j=1, X=rm.df, t.vars, out.vars)

## run per property
## TAKES 4-5 hrs
library(snowfall)
sfInit(parallel=TRUE, cpus=length(t.vars))
sfLibrary(SuperLearner)
sfLibrary(parallel)
sfExport("rm.df", "out.vars", "t.vars", "fit_t.m", "saveRDS.gz")
out <- snowfall::sfClusterApplyLB(1:length(t.vars), function(j){ fit_t.m(j, X=rm.df, t.vars, out.vars)  })
sfStop()
#Non-Negative least squares convergence: TRUE

## extract weights ----
weights.lst = data.frame(var=t.vars, m.ranger=NA, m.Xgboost=NA, rmse.ranger=NA, rmse.Xgboost=NA)
r.file = "/data/LandGIS/soil/soil_water/t.hydroprops_resultsFit.txt"
cat("Results of model fitting 'SuperLearner':\n", file=r.file, append=TRUE)
for(j in 1:length(t.vars)){
  x = readRDS.gz(paste0("/data/LandGIS/soil/soil_water/t.m_", out.vars[j],".rds"))
  cat("\n", file=r.file, append=TRUE)
  cat(paste("Variable:", out.vars[j]), file=r.file, append=TRUE)
  cat("\n", file=r.file, append=TRUE)
  sink(file=r.file, append=TRUE, type="output")
  print(x)
  cat("\n", file=r.file, append=TRUE)
  cat("Processing time:\n", file=r.file, append=TRUE)
  print(x$times$everything)
  cat("\n", file=r.file, append=TRUE)
  cat("--------------------------------------\n", file=r.file, append=TRUE)
  sink()
  weights.lst$m.ranger[j] = x$coef[which(attr(x$coef, "names")=="SL.ranger_All")]
  weights.lst$m.Xgboost[j] = x$coef[which(attr(x$coef, "names")=="SL.xgboost_All")]
  weights.lst$rmse.ranger[j] = sqrt(x$cvRisk[which(attr(x$cvRisk, "names")=="SL.ranger_All")])
  weights.lst$rmse.Xgboost[j] = sqrt(x$cvRisk[which(attr(x$cvRisk, "names")=="SL.xgboost_All")])
  rm(x)
}
weights.lst[,c("m.ranger","m.Xgboost")]
#    m.ranger m.Xgboost
# 1 0.7521728 0.2478272
# 2 0.6272902 0.3727098
write.csv(weights.lst, "/data/LandGIS/soil/soil_water/t.hydroprops_weights.csv")

## Final models ----
## Caret training settings (reduce number of combinations to speed up):
ctrl <- trainControl(method="repeatedcv", number=3, repeats=1)
gb.tuneGrid <- expand.grid(eta = c(0.3,0.4,0.5), nrounds = c(50,100,150), 
                           max_depth = 2:4, gamma = 0, colsample_bytree = 0.8, 
                           min_child_weight = 1, subsample=1)
rf.tuneGrid <- expand.grid(mtry = seq(5,120,by=10), splitrule="variance", min.node.size=5)

library(caret); library(parallel); library(ranger); library(xgboost); library(doParallel)
nc = parallel::detectCores()
## takes >2hrs to fit all models
## Problems with using parallel -- zombie processes server freezes and needs to be rebooted
for(j in 1:length(t.vars)){
  out.file = paste0(t.vars[j],"_resultsFit.txt")
  if(!file.exists(out.file)){
    cat("Results of model fitting 'randomForest and XGBoost':\n\n", file=out.file)
    cat("\n", file=out.file, append=TRUE)
    cat(paste("Variable:", out.vars[j]), file=out.file, append=TRUE)
    cat("\n", file=out.file, append=TRUE)
    out.rf <- paste0("mrf.",t.vars[j],".rds")
    sel.n <- c(t.vars[j],"DEPTH",paste0("PC", 1:242))
    fm.t <- as.formula(paste(t.vars[j], " ~ DEPTH +", paste0("PC",1:242, collapse = "+")))
    if(!file.exists(gsub("mrf", "t.mrf", out.rf))){
      df <- hor2xyd(rm.hydroprops[rm.hydroprops$site_key %in% prof.s$subset$site_key,], U="hzn_top", L="hzn_bot")
      sel.r <- complete.cases(df[,sel.n])
      df <- df[sel.r,sel.n]
      case.weights = df$dataset_confidence
      ## optimize mtry parameter:
      #doParallel::registerDoParallel(parallel::detectCores()-2)
      cl <- makePSOCKcluster(nc-2)
      doParallel::registerDoParallel(cl)
      t.mrfX <- caret::train(x=df[,c("DEPTH", paste0("PC",1:242))], 
                             y=df[,t.vars[j]], method="ranger", trControl=ctrl,
                             case.weights=case.weights,
                             tuneGrid=rf.tuneGrid)
      stopCluster(cl)
      unregister()
      #stopImplicitCluster()
      saveRDS.gz(t.mrfX, file=gsub("mrf", "t.mrf", out.rf))
    } else {
      t.mrfX <- readRDS.gz(gsub("mrf", "t.mrf", out.rf))
    }
    gc()
    ## use complete reg matrix
    dfs <- hor2xyd(rm.hydroprops, U="hzn_top", L="hzn_bot")
    ## 1.5-2.2GB object
    sel.rs <- complete.cases(dfs[,sel.n])
    dfs <- dfs[sel.rs,sel.n]
    case.weights.s = dfs$dataset_confidence
    if(!file.exists(paste0("mrf.",t.vars[j],".rds"))){
      mrfX <- ranger(formula=fm.t, 
                     data=dfs, importance="impurity", 
                     write.forest=TRUE, mtry=t.mrfX$bestTune$mtry, num.trees=105,
                     ## reduce number of trees so the output objects do not become TOO LARGE i.e. >5GB
                     case.weights=case.weights.s)
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
      mgbX <- caret::train(x=dfs[,c("DEPTH", paste0("PC",1:242))], 
                           y=dfs[,t.vars[j]], method="xgbTree", trControl=ctrl, 
                           tuneGrid=gb.tuneGrid, case.weights=case.weights.s) 
      stopCluster(cl)
      unregister()
      #stopImplicitCluster()
      saveRDS.gz(mgbX, file=paste0("mgb.",t.vars[j],".rds"))
      ## save also binary model for prediction purposes:
      xgb.save(mgbX$finalModel, paste0("Xgb.",t.vars[j]))
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
    rm(mgbX); rm(dfs)
    unregister()
    closeAllConnections()
    gc(); gc()
  }
}
save.image.pigz(n.cores = parallel::detectCores())

## Predictions ----

z.min <- as.list(c(0,0))
names(z.min) = t.vars
z.max <- as.list(c(100,100))
names(z.max) = t.vars

## test predictions
j=1; i="T38715"
gm = readRDS.gz(paste0("mrf.", t.vars[j],".rds"))
gm1.w = weights.lst$m.ranger[which(weights.lst$var == t.vars[j])]
system.time(split_predict_n(i, gm, varn=t.vars[j], method="ranger", multiplier=1))
## 95 secs
gm = readRDS.gz(paste0("mgb.", t.vars[j],".rds"))
gm2.w = weights.lst$m.Xgboost[which(weights.lst$var == t.vars[j])]
system.time(split_predict_n(i, gm, varn=t.vars[j], method="xgboost", multiplier=1))
## 9 secs
sum_predict_ensemble(i, varn=t.vars[j], zmin=z.min[[j]], zmax=z.max[[j]], gm1.w=gm1.w, gm2.w=gm2.w)
rm(gm)
gc(); gc()

## cleanup:
#x = list.files("/data/tt/LandGIS/grid250m", "_rf", full.names=TRUE, recursive=TRUE)
#unlink(x)
#x = list.files("/data/tt/LandGIS/grid250m", "_xgb", full.names=TRUE, recursive=TRUE)
#unlink(x)
#x = list.files("/data/tt/LandGIS/grid250m", "tif.aux.xml", full.names=TRUE, recursive=TRUE)
#unlink(x)
#x = unlist(sapply(c("awc_","w3cld_","w15l2_"), function(i){list.files("/data/tt/LandGIS/grid250m", i, full.names=TRUE, recursive=TRUE)}))
#unlink(x)

## Run per property ----
load(".RData")
library(ranger)
library(xgboost)
library(tools)
library(parallel)
library(doParallel)
library(rgdal)
library(plyr)
library(matrixStats)

## BUG: need to close and restart RStudio 2 times manually otherwise "makeCluster" hangs

## 18555 tiles
for(j in 1:length(t.vars)){
  gc()
  try( detach("package:snowfall", unload=TRUE), silent=TRUE)
  try( detach("package:snow", unload=TRUE), silent=TRUE)
  multiplier = 1
  ## Random forest predictions:
  gm = readRDS.gz(paste0("mrf.", t.vars[j],".rds"))
  gm1.w = weights.lst$m.ranger[which(weights.lst$var == t.vars[j])]
  ## Estimate amount of RAM needed per core
  cpus = unclass(round((400-50)/(3.5*(object.size(gm)/1e9))))
  cl <- parallel::makeCluster(ifelse(cpus>parallel::detectCores(), parallel::detectCores()-4, cpus), type="FORK")
  doParallel::registerDoParallel(cl)
  x = parallel::parLapply(cl, pr.dirs, fun=function(x){ if(any(!file.exists(paste0("/data/tt/LandGIS/grid250m/", x, "/", t.vars[j], "_M_sl", 1:6, "_", x, ".tif")))){ try( split_predict_n(x, gm, varn=t.vars[j], method="ranger", multiplier=multiplier) ) } } )
  parallel::stopCluster(cl)
  unregister()
  rm(cl)
  gc()
  ## XGBoost:
  gm = readRDS.gz(paste0("mgb.", t.vars[j],".rds"))
  gm2.w = weights.lst$m.Xgboost[which(weights.lst$var == t.vars[j])]
  cpus = unclass(round((400-50)/(3.5*(object.size(gm)/1e9))))
  cl <- parallel::makeCluster(ifelse(cpus>parallel::detectCores(), parallel::detectCores()-4, cpus), type="FORK", verbose = TRUE)
  doParallel::registerDoParallel(cl)
  x = parallel::parLapply(cl, pr.dirs, fun=function(x){ if(any(!file.exists(paste0("/data/tt/LandGIS/grid250m/", x, "/", t.vars[j], "_M_sl", 1:6, "_", x, ".tif")))){ try( split_predict_n(x, gm, varn=t.vars[j], method="xgboost", multiplier=multiplier) ) } } )
  parallel::stopCluster(cl)
  rm(cl)
  unregister()
  gc()
  ## sum up predictions:
  library(snowfall)
  sfInit(parallel=TRUE, cpus=parallel::detectCores()-2)
  #sfExport("pr.dirs", "sum_predict_ensemble", "t.vars", "j", "z.min", "z.max", "gm1.w", "gm2.w", "gm3.w")
  sfExport("pr.dirs", "sum_predict_ensemble", "t.vars", "j", "z.min", "z.max", "gm1.w", "gm2.w")
  sfLibrary(rgdal)
  sfLibrary(plyr)
  x <- snowfall::sfClusterApplyLB(pr.dirs, fun=function(x){ try( sum_predict_ensemble(x, varn=t.vars[j], zmin=z.min[[j]], zmax=z.max[[j]], gm1.w=gm1.w, gm2.w=gm2.w) ) } )
  snowfall::sfStop()
  unregister()
  gc()
}
rm(gm)
gc()
save.image.pigz(n.cores = parallel::detectCores())

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
d.lst = c(as.vector(sapply(paste0("M_sl", 1:6), function(i){rep(i, 2)})),
          paste0("M_sh", 1:5), paste0("M_tot"),
          as.vector(sapply(paste0("sd_sl", 1:6), function(i){rep(i, 2)})),
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

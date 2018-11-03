## Fit spatial prediction models and make global soil maps soil properties
## tom.hengl@gmail.com

library(rgdal)
library(raster)
library(fastSave)
#detach("package:fastSave", unload=TRUE)
library(ranger)
library(xgboost)
library(caret)
library(plyr)
#library(caretEnsemble)
library(SuperLearner)
library(matrixStats)
load(".RData")

source("/data/LandGIS/R/saveRDS_functions.R")
source("/data/LandGIS/R/LandGIS_functions.R")
tile.tbl = readRDS("/data/LandGIS/models/stacked250m_tiles.rds")
pr.dirs = readRDS("/data/LandGIS/models/prediction_dirs.rds")
tile.pol = readOGR("/data/LandGIS/models/tiles_ll_100km.shp")
tile.pol = tile.pol[paste0("T", tile.pol$ID) %in% pr.dirs,]

## Load point data ----
## Global compilation of soil properties:
soil_props.pnts = readRDS.gz("/data/LandGIS/training_points/soil/soil_props.pnts.rds")
tot_sprops = readRDS.gz("/data/LandGIS/training_points/soil/soil_props_horizons.rds")
## overlay (takes 25 mins):
ov.sprops <- extract.tiled(obj=soil_props.pnts, tile.pol=tile.pol, path="/data/tt/LandGIS/grid250m", ID="ID", cpus=parallel::detectCores())
## add tile ID:
id.t = over(spTransform(soil_props.pnts, CRS(proj4string(tile.pol))), tile.pol)
#str(id.t)
ov.sprops$ID = paste0("T", id.t$ID)
ov.sprops$location_id = soil_props.pnts$location_id
saveRDS.gz(ov.sprops, "/data/LandGIS/training_points/soil/ov_soil_properties.pnts.rds")
#ov.sprops = readRDS.gz("/data/LandGIS/training_points/soil/ov_soil_properties.pnts.rds")
rm.sprops <- plyr::join(tot_sprops, ov.sprops, type="left", by="location_id")
## 1.4GB object
saveRDS.gz(rm.sprops, "/data/LandGIS/soil/soil_properties/rm_soil_properties.rds")
#rm.sprops = readRDS.gz("/data/LandGIS/soil/soil_properties/rm_soil_properties.rds")
save.image.pigz(n.cores = parallel::detectCores())

## Geo-distributed sub-sample ----
prof.s <- GSIF::sample.grid(soil_props.pnts, cell.size=c(1,1), n=2)
length(prof.s$subset)
## 13,357
## 10% of the total data

t.vars = c("oc.f", "db_od", "ph_h2o", "clay_tot_psa", "sand_tot_psa", "silt_tot_psa", "wpg2")
out.vars = c("organic.carbon", "bulkdens.fineearth", "ph.h2o", "clay.wfraction", "sand.wfraction", "silt.wfraction", "coarsefrag.vfraction")
## Test ensemble model ----
## use subset so the results are generated faster
cl <- parallel::makeCluster(parallel::detectCores())
x <- parallel::clusterEvalQ(cl, expr={library(SuperLearner); library(ranger); library(xgboost); library(bartMachine)})
r.file = "/data/LandGIS/soil/soil_properties/t.sprops_resultsFit.txt"
cat("Results of model fitting 'SuperLearner':\n", file=r.file)
for(j in 1:length(t.vars)){
  cat("\n", file=r.file, append=TRUE)
  cat(paste("Variable:", out.vars[j]), file=r.file, append=TRUE)
  cat("\n", file=r.file, append=TRUE)
  out.m.rds = paste0("/data/LandGIS/soil/soil_properties/t.m_", out.vars[j],".rds")
  if(!file.exists(out.m.rds)){
    df <- hor2xyd(rm.sprops[rm.sprops$location_id %in% prof.s$subset$location_id,], U="hzn_top", L="hzn_bot")
    sel.n <- c(t.vars[j],"DEPTH",paste0("PC", 1:242))
    sel.r <- complete.cases(df[,sel.n])
    df <- df[sel.r,sel.n]
    case.weights = df[sel.r,"dataset_confidence"]
    id.col <- df[sel.r,"ID"]
    t.m <- SuperLearner::snowSuperLearner(X=df[,c("DEPTH", paste0("PC",1:242))], 
                   Y=df[,1], cluster = cl, 
                   #SL.library = c("SL.xgboost", "SL.bartMachine", "SL.ranger", "glmnet"),
                   SL.library = c("SL.xgboost", "SL.ranger"),
                   id=id.col, verbose=TRUE,
                   obsWeights=case.weights,
                   cvControl=list(V=3))
    ## This does not uses all cores (only 3?)
    sink(file=r.file, append=TRUE, type="output")
    print(t.m)
    cat("\n", file=r.file, append=TRUE)
    cat("Processing time:\n", file=r.file)
    print(t.m$times$everything)
    saveRDS.gz(t.m, out.m.rds)
    cat("\n", file=r.file, append=TRUE)
    cat("--------------------------------------\n", file=r.file, append=TRUE)
    sink()
  }
}
stopCluster(cl)
closeAllConnections()
## Unfortunately this does not seem to run in parallel

weights.lst = data.frame(var=t.vars, m.ranger=NA, m.Xgboost=NA, m.glmnet=NA, rmse.ranger=NA, rmse.Xgboost=NA, rmse.glmnet=NA)
for(j in 1:length(t.vars)){
  x = readRDS.gz(paste0("/data/LandGIS/soil/soil_properties/t.m_", out.vars[j],".rds"))
  weights.lst$m.ranger[j] = x$coef[which(attr(x$coef, "names")=="SL.ranger_All")]
  weights.lst$m.Xgboost[j] = x$coef[which(attr(x$coef, "names")=="SL.xgboost_All")]
  weights.lst$m.glmnet[j] = x$coef[which(attr(x$coef, "names")=="SL.glmnet_All")]
  weights.lst$rmse.ranger[j] = x$cvRisk[which(attr(x$cvRisk, "names")=="SL.ranger_All")]
  weights.lst$rmse.Xgboost[j] = x$cvRisk[which(attr(x$cvRisk, "names")=="SL.xgboost_All")]
  weights.lst$rmse.glmnet[j] = x$cvRisk[which(attr(x$cvRisk, "names")=="SL.glmnet_All")]
  rm(x)
}
weights.lst
# var  m.ranger    m.Xgboost m.glmnet
# 1         oc.f 0.3990900 0.6009100260        0
# 2        db_od 0.2053056 0.7946944247        0
# 3       ph_h2o 0.8701325 0.1298675481        0
# 4 clay_tot_psa 0.9994045 0.0005954565        0
# 5 sand_tot_psa 0.9901732 0.0098268265        0
# 6 silt_tot_psa 0.9720472 0.0279527510        0
# 7         wpg2 0.5426220 0.4573779519        0
write.csv(weights.lst, "/data/LandGIS/soil/soil_properties/t.sprops_weights.csv")

## Final models ----
## Caret training settings (reduce number of combinations to speed up):
ctrl <- trainControl(method="repeatedcv", number=3, repeats=1)
gb.tuneGrid <- expand.grid(eta = c(0.3,0.4,0.5), nrounds = c(50,100,150), 
                           max_depth = 2:4, gamma = 0, colsample_bytree = 0.8, 
                           min_child_weight = 1, subsample=1)
rf.tuneGrid <- expand.grid(mtry = seq(5,120,by=10), splitrule="variance", min.node.size=5)

## takes 8hrs to fit all models
for(j in 1:length(t.vars)){
  out.file = paste0(t.vars[j],"_resultsFit.txt")
  if(!file.exists(out.file)){
    cat("Results of model fitting 'randomForest, XGBoost, bartMachine':\n\n", file=out.file)
    cat("\n", file=out.file, append=TRUE)
    cat(paste("Variable:", out.vars[j]), file=out.file, append=TRUE)
    cat("\n", file=out.file, append=TRUE)
    out.rf <- paste0("mrf.",t.vars[j],".rds")
    if(!file.exists(gsub("mrf", "t.mrf", out.rf))){
      df <- hor2xyd(rm.sprops[rm.sprops$location_id %in% prof.s$subset$location_id,], U="hzn_top", L="hzn_bot")
      sel.n <- c(t.vars[j],"DEPTH",paste0("PC", 1:242))
      sel.r <- complete.cases(df[,sel.n])
      df <- df[sel.r,sel.n]
      case.weights = df[sel.r,"dataset_confidence"]
      ## optimize mtry parameter:
      cl <- parallel::makeCluster(parallel::detectCores())
      doParallel::registerDoParallel(cl)
      t.mrfX <- caret::train(x=df[,c("DEPTH", paste0("PC",1:242))], 
                             y=df[,1], method="ranger", trControl=ctrl,
                             case.weights=case.weights,
                             tuneGrid=rf.tuneGrid)
      saveRDS.gz(t.mrfX, file=gsub("mrf", "t.mrf", out.rf))
      parallel::stopCluster(cl)
    } else {
      t.mrfX <- readRDS.gz(gsub("mrf", "t.mrf", out.rf))
    }
    gc()
    ## use complete reg matrix
    dfs <- hor2xyd(rm.sprops, U="hzn_top", L="hzn_bot")
    ## 1.5-2.2GB object
    sel.rs <- complete.cases(dfs[,sel.n])
    dfs <- dfs[sel.rs,sel.n]
    case.weights.s = dfs[sel.rs,"dataset_confidence"]
    if(!file.exists(paste0("mrf.",t.vars[j],".rds"))){
      mrfX <- ranger(formula=as.formula(paste(t.vars[j], "~ DEPTH +", paste0("PC",1:242, collapse = "+"))), 
                     data=dfs, importance="impurity", 
                     write.forest=TRUE, mtry=t.mrfX$bestTune$mtry, num.trees=85,
                     ## reduce number of trees so the output objects do not get TOO LARGE i.e. >5GB
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
    gc()
    if(!file.exists(paste0("mgb.",t.vars[j],".rds"))){
      ## fit XGBoost model using all points:
      cl <- parallel::makeCluster(parallel::detectCores())
      doParallel::registerDoParallel(cl)
      mgbX <- caret::train(x=dfs[,c("DEPTH", paste0("PC",1:242))], 
                           y=dfs[,1], method="xgbTree", trControl=ctrl, 
                           tuneGrid=gb.tuneGrid, case.weights=case.weights.s) 
      saveRDS.gz(mgbX, file=paste0("mgb.",t.vars[j],".rds"))
      ## save also binary model for prediction purposes:
      xgb.save(mgbX$finalModel, paste0("Xgb.",t.vars[j]))
      parallel::stopCluster(cl)
    } else {
      mgbX <- readRDS.gz(paste0("mgb.",t.vars[j],".rds"))
    }
    importance_matrix <- xgb.importance(mgbX$coefnames, model = mgbX$finalModel)
    cat("\n", file=out.file, append=TRUE)
    print(mgbX)
    cat("\n XGBoost variable importance:\n", file=out.file, append=TRUE)
    print(importance_matrix[1:25,])
    cat("\n", file=out.file, append=TRUE)
    cat("--------------------------------------\n", file=out.file, append=TRUE)
    sink()
    rm(mgbX); rm(dfs)
    gc()
  }
}
save.image.pigz(n.cores = parallel::detectCores())

## Predictions ----
## Run per property
library(ranger)
library(xgboost)
library(tools)
library(parallel)
library(rgdal)
library(plyr)
library(matrixStats)

#range.oc = quantile(rm.sprops$oc.f, c(0.001,0.999), na.rm=TRUE)*2
#range.oc
#range.bd = quantile(rm.sprops$db_od, c(0.001,0.999), na.rm=TRUE)*100
#range.bd
#range.ph_h2o = quantile(rm.sprops$ph_h2o, c(0.001,0.999), na.rm=TRUE)*10
#range.ph_h2o
z.min <- as.list(c(0,2,30,0,0,0,0))
names(z.min) = t.vars
z.max <- as.list(c(120,225,105,100,100,100,100))
names(z.max) = t.vars
## test predictions
j=1; i="T38716"
gm = readRDS.gz(paste0("mrf.", t.vars[j],".rds"))
gm1.w = weights.lst$m.ranger[which(weights.lst$var == t.vars[j])]
split_predict_n(i, gm, varn=t.vars[j], method="ranger", multiplier=2)
gm = readRDS.gz(paste0("mgb.", t.vars[j],".rds"))
gm2.w = weights.lst$m.Xgboost[which(weights.lst$var == t.vars[j])]
split_predict_n(i, gm, varn=t.vars[j], method="xgboost", multiplier=2)
sum_predict_ensemble(i, varn=t.vars[j], zmin=z.min[[j]], zmax=z.max[[j]], gm1.w=gm1.w, gm2.w=gm2.w)
rm(gm)
gc()

for(j in 1:length(t.vars)){
  try( detach("package:snowfall", unload=TRUE), silent=TRUE)
  if(t.vars[j] %in% c("oc.f")){ multiplier = 2 }
  if(t.vars[j] %in% c("db_od")){ multiplier = 100 }
  if(t.vars[j] %in% c("ph_h2o")){ multiplier = 10 }
  if(t.vars[j] %in% c("clay_tot_psa", "sand_tot_psa", "silt_tot_psa", "wpg2")){ multiplier = 1 }
  ## Random forest predictions:
  gm = readRDS.gz(paste0("mrf.", t.vars[j],".rds"))
  gm1.w = weights.lst$m.ranger[which(weights.lst$var == t.vars[j])]
  ## Estimate amount of RAM needed per core
  cpus = unclass(round((400-30)/(3.5*(object.size(gm)/1e9))))
  cl <- parallel::makeCluster(ifelse(cpus>parallel::detectCores(), parallel::detectCores(), cpus), type="FORK")
  x = parallel::parLapply(cl, pr.dirs, fun=function(x){ if(any(!file.exists(paste0("/data/tt/LandGIS/grid250m", x, "/", j, "_M_sl", 1:6, "_", x, ".tif")))){ try( split_predict_n(x, gm, varn=j, method="ranger", multiplier=multiplier) ) } } )
  parallel::stopCluster(cl)
  gc(); gc()
  ## XGBoost:
  gm = readRDS.gz(paste0("mgb.", t.vars[j],".rds"))
  gm2.w = weights.lst$m.Xgboost[which(weights.lst$var == t.vars[j])]
  cpus = unclass(round((400-50)/(3.5*(object.size(gm)/1e9))))
  cl <- parallel::makeCluster(ifelse(cpus>parallel::detectCores(), parallel::detectCores(), cpus), type="FORK")
  x = parallel::parLapply(cl, pr.dirs, fun=function(x){ if(any(!file.exists(paste0("/data/tt/LandGIS/grid250m", x, "/", j, "_M_sl", 1:6, "_", x, ".tif")))){ try( split_predict_n(x, gm, varn=t.vars[j], method="xgboost", multiplier=multiplier) ) } } )
  parallel::stopCluster(cl)
  gc(); gc()
  ## sum up predictions:
  if(is.nan(gm1.w)|is.nan(gm2.w)){ gm1.w = 0.5; gm2.w = 0.5 } 
  ## TH: it can happen that ranger results in error = NaN
  library(snowfall)
  sfInit(parallel=TRUE, cpus=parallel::detectCores())
  sfExport("pr.dirs", "sum_predict_ensemble", "j", "z.min", "z.max", "gm1.w", "gm2.w", "type.lst", "mvFlag.lst")
  sfLibrary(rgdal)
  sfLibrary(plyr)
  x <- snowfall::sfClusterApplyLB(pr.dirs, fun=function(x){ try( sum_predict_ensemble(x, varn=t.vars[j], zmin=z.min[[j]], zmax=z.max[[j]], gm1.w=gm1.w, gm2.w=gm2.w) ) } )
  snowfall::sfStop()
  gc(); gc()
}
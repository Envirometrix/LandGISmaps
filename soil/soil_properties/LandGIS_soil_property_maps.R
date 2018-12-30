## Fit spatial prediction models and make global soil maps soil properties
## tom.hengl@gmail.com

library(rgdal)
library(raster)
library(fastSave)
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
## Grid def ----
r = raster("/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif")
te = as.vector(extent(r))[c(1,3,2,4)]
cellsize = res(r)[1]

## Load point data ----
## Global compilation of soil properties:
soil_props.pnts = readRDS.gz("/data/LandGIS/training_points/soil/soil_props.pnts.rds")
tot_sprops = readRDS.gz("/data/LandGIS/training_points/soil/soil_props_horizons.rds")
## overlay (takes 45 mins):
ov.sprops <- extract.tiled(obj=soil_props.pnts, tile.pol=tile.pol, path="/data/tt/LandGIS/grid250m", ID="ID", cpus=parallel::detectCores())
## add tile ID:
id.t = over(spTransform(soil_props.pnts, CRS(proj4string(tile.pol))), tile.pol)
#str(id.t)
ov.sprops$ID = paste0("T", id.t$ID)
ov.sprops$location_id = soil_props.pnts$location_id
saveRDS.gz(ov.sprops, "/data/LandGIS/training_points/soil/ov_soil_properties.pnts.rds")
#ov.sprops = readRDS.gz("/data/LandGIS/training_points/soil/ov_soil_properties.pnts.rds")
rm.sprops = plyr::join(tot_sprops, ov.sprops, type="left", by="location_id")
# 774,132    278
## 1.4GB object
saveRDS.gz(rm.sprops, "/data/LandGIS/soil/soil_properties/rm_soil_properties.rds")
#rm.sprops = readRDS.gz("/data/LandGIS/soil/soil_properties/rm_soil_properties.rds")
save.image.pigz(n.cores = parallel::detectCores())

## Geo-distributed sub-sample ----
#prof.s <- GSIF::sample.grid(soil_props.pnts, cell.size=c(3,3), n=1) ## 0.5%
#prof.s <- GSIF::sample.grid(soil_props.pnts, cell.size=c(2,2), n=2) ## 1.5%
prof.s <- GSIF::sample.grid(soil_props.pnts, cell.size=c(1,1), n=1) ## 5%
plot(prof.s$subset, pch="+")
length(prof.s$subset)
## 8316 (5% of the total data)
## use subset so the results are generated faster
rm.df <- hor2xyd(rm.sprops[rm.sprops$location_id %in% prof.s$subset$location_id,], U="hzn_top.f", L="hzn_bot.f")

t.vars = c("oc.f", "db_od", "ph_h2o", "clay_tot_psa", "sand_tot_psa", "silt_tot_psa", "wpg2")
out.vars = c("organic.carbon", "bulkdens.fineearth", "ph.h2o", "clay.wfraction", "sand.wfraction", "silt.wfraction", "coarsefrag.vfraction")
meth.vars = c("usda.6a1c", "usda.4a1h", "usda.4c1a2a", "usda.3a1a1a", "usda.3a1a1a", "usda.3a1a1a", "usda.3b1")

## Test ensemble model ----
fit_t.m = function(j, X, t.vars, out.vars){
  out.m.rds = paste0("/data/LandGIS/soil/soil_properties/t.m_", out.vars[j],".rds")
  if(!file.exists(out.m.rds)){
    sel.n <- c(t.vars[j],"DEPTH",paste0("PC", 1:242))
    sel.r <- complete.cases(X[,sel.n])
    df.s <- X[sel.r,sel.n]
    case.weights = X[sel.r,"dataset_confidence"]
    id.col <- X[sel.r,"ID"]
    rownames(df.s) <- NULL
    #cl <- parallel::makeCluster(4)
    #x <- parallel::clusterEvalQ(cl, expr={library(SuperLearner); library(ranger); library(xgboost); library(caret); library(gam); library(splines)})
    t.m <- SuperLearner(Y=df.s[,t.vars[j]], 
    #t.m <- SuperLearner::snowSuperLearner(Y=df.s[,t.vars[j]], 
                   X=df.s[,c("DEPTH", paste0("PC",1:242))], 
                   #cluster = cl,
                   #family = gaussian(), method="method.NNLS2",
                   #SL.library = c("SL.xgboost", "SL.ranger"),
                   SL.library = c("SL.xgboost", "SL.ranger", "SL.ksvm", "SL.gam"),
                   id=id.col, verbose=TRUE,
                   obsWeights=case.weights/max(case.weights, na.rm=TRUE),
                   cvControl=list(V=3))
    #print(t.m)
    #stopCluster(cl)
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
weights.lst = data.frame(var=t.vars, m.ranger=NA, m.Xgboost=NA, m.gam=NA, m.ksvm=NA, rmse.ranger=NA, rmse.Xgboost=NA, rmse.gam=NA, rmse.ksvm=NA)
r.file = "/data/LandGIS/soil/soil_properties/t.sprops_resultsFit.txt"
cat("Results of model fitting 'SuperLearner':\n", file=r.file, append=TRUE)
for(j in 1:length(t.vars)){
  x = readRDS.gz(paste0("/data/LandGIS/soil/soil_properties/t.m_", out.vars[j],".rds"))
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
  weights.lst$m.ksvm[j] = x$coef[which(attr(x$coef, "names")=="SL.ksvm_All")]
  weights.lst$m.gam[j] = x$coef[which(attr(x$coef, "names")=="SL.gam_All")]
  weights.lst$rmse.ranger[j] = sqrt(x$cvRisk[which(attr(x$cvRisk, "names")=="SL.ranger_All")])
  weights.lst$rmse.Xgboost[j] = sqrt(x$cvRisk[which(attr(x$cvRisk, "names")=="SL.xgboost_All")])
  weights.lst$rmse.ksvm[j] = sqrt(x$cvRisk[which(attr(x$cvRisk, "names")=="SL.ksvm_All")])
  weights.lst$rmse.gam[j] = sqrt(x$cvRisk[which(attr(x$cvRisk, "names")=="SL.gam_All")])
  rm(x)
}
weights.lst[,c("m.ranger","m.Xgboost","m.ksvm","m.gam")]
# m.ranger  m.Xgboost     m.ksvm       m.gam
# 1 0.2098697 0.17212143 0.32782136 0.241082008
# 2 0.4504769 0.34471954 0.05790617 0.146897398
# 3 0.2268570 0.26896654 0.26859956 0.235576884
# 4 0.5052088 0.12494409 0.36058738 0.009259772
# 5 0.4453805 0.19330438 0.26056375 0.100751398
# 6 0.4927687 0.07878987 0.31269766 0.115743801
# 7 0.1660685 0.15845651 0.49096012 0.18451483
write.csv(weights.lst, "/data/LandGIS/soil/soil_properties/t.sprops_weights.csv")

## Final models ----
## Caret training settings (reduce number of combinations to speed up):
ctrl <- trainControl(method="repeatedcv", number=3, repeats=1)
gb.tuneGrid <- expand.grid(eta = c(0.3,0.4,0.5), nrounds = c(50,100,150), 
                           max_depth = 2:4, gamma = 0, colsample_bytree = 0.8, 
                           min_child_weight = 1, subsample=1)
rf.tuneGrid <- expand.grid(mtry = seq(5,120,by=10), splitrule="variance", min.node.size=5)

library(caret); library(parallel); library(ranger); library(xgboost); library(liquidSVM) 
library(doParallel)
nc = parallel::detectCores()
## takes >12hrs to fit all models
## Problems with using parallel -- zombie processes server freezes and needs to be rebooted
for(j in 1:length(t.vars)){
  out.file = paste0(t.vars[j],"_resultsFit.txt")
  if(!file.exists(out.file) | !file.exists(paste0("mSVM.",t.vars[j],".fsol"))){
    cat("Results of model fitting 'randomForest and XGBoost':\n\n", file=out.file)
    cat("\n", file=out.file, append=TRUE)
    cat(paste("Variable:", out.vars[j]), file=out.file, append=TRUE)
    cat("\n", file=out.file, append=TRUE)
    out.rf <- paste0("mrf.",t.vars[j],".rds")
    sel.n <- c(t.vars[j],"DEPTH",paste0("PC", 1:242))
    fm.t <- as.formula(paste(t.vars[j], " ~ DEPTH +", paste0("PC",1:242, collapse = "+")))
    if(!file.exists(gsub("mrf", "t.mrf", out.rf))){
      df <- hor2xyd(rm.sprops[rm.sprops$location_id %in% prof.s$subset$location_id,], U="hzn_top", L="hzn_bot")
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
    dfs <- hor2xyd(rm.sprops, U="hzn_top", L="hzn_bot")
    ## 1.5-2.2GB object
    sel.rs <- complete.cases(dfs[,sel.n])
    dfs <- dfs[sel.rs,sel.n]
    case.weights.s = dfs$dataset_confidence
    if(!file.exists(paste0("mrf.",t.vars[j],".rds"))){
      mrfX <- ranger(formula=fm.t, 
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
    ## SVM:
    if(!file.exists(paste0("mSVM.",t.vars[j],".fsol"))){
      gc(); gc()
      #mSVM <- kernlab::ksvm(fm.t, dfs)
      mSVM <- liquidSVM::lsSVM(fm.t, dfs, threads=nc-2)
      ## https://github.com/liquidSVM/liquidSVM/issues/1
      write.liquidSVM(mSVM, paste0("mSVM.",t.vars[j],".fsol"))
    } else {
      mSVM <- read.liquidSVM(paste0("mSVM.",t.vars[j],".fsol"))
    }
    cat("\n Support Vector Machine model:\n", file=out.file, append=TRUE)
    print(mSVM)
    cat("\n", file=out.file, append=TRUE)
    cat("--------------------------------------\n", file=out.file, append=TRUE)
    sink()
    rm(mgbX); rm(dfs); rm(mSVM)
    unregister()
    closeAllConnections()
    gc(); gc()
  }
}
save.image.pigz(n.cores = parallel::detectCores())

## Predictions ----

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
j=1; i="T38715"
gm = readRDS.gz(paste0("mrf.", t.vars[j],".rds"))
gm1.w = weights.lst$m.ranger[which(weights.lst$var == t.vars[j])]
system.time(split_predict_n(i, gm, varn=t.vars[j], method="ranger", multiplier=2))
## 95 secs
gm = readRDS.gz(paste0("mgb.", t.vars[j],".rds"))
gm2.w = weights.lst$m.Xgboost[which(weights.lst$var == t.vars[j])]
system.time(split_predict_n(i, gm, varn=t.vars[j], method="xgboost", multiplier=2))
## 9 secs
## slow read ...
#gm = liquidSVM::read.liquidSVM(paste0("mSVM.", t.vars[j],".fsol"))
#gm = readRDS.gz(paste0("t.m_", out.vars[j],".rds"))
#gm3.w = weights.lst$m.ksvm[which(weights.lst$var == t.vars[j])]
#system.time(split_predict_n(i, gm, varn=t.vars[j], method="liquidSVM", multiplier=2))
## 123 secs with all cores
## TAKES TOO MUCH TIME UNFORTUNATELY
#sum_predict_ensemble(i, varn=t.vars[j], zmin=z.min[[j]], zmax=z.max[[j]], gm1.w=gm1.w, gm2.w=gm2.w, gm3.w=gm3.w)
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

## Run per property ----
load(".RData")
library(ranger)
library(xgboost)
#library(liquidSVM)
library(tools)
#try( detach("package:fastSave", unload=TRUE), silent=TRUE)
library(parallel)
library(doParallel)
library(rgdal)
library(plyr)
library(matrixStats)

## BUG: need to close and restart RStudio 2 times manually otherwise "makeCluster" hangs

## 18555 tiles
for(j in 1:length(t.vars)){
  try( detach("package:snowfall", unload=TRUE), silent=TRUE)
  try( detach("package:snow", unload=TRUE), silent=TRUE)
  if(t.vars[j] %in% c("oc.f")){ multiplier = 2 }
  if(t.vars[j] %in% c("db_od")){ multiplier = 100 }
  if(t.vars[j] %in% c("ph_h2o")){ multiplier = 10 }
  if(t.vars[j] %in% c("clay_tot_psa", "sand_tot_psa", "silt_tot_psa", "wpg2")){ multiplier = 1 }
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
  gc(); gc()
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
  gc(); gc()
  #gm = liquidSVM::read.liquidSVM(paste0("mSVM.", t.vars[j],".fsol"))
  #gm3.w = weights.lst$m.ksvm[which(weights.lst$var == t.vars[j])]
  #cpus = unclass(round((400-50)/(3.5*(object.size(gm)/1e9))))
  #cl <- parallel::makeCluster(ifelse(cpus>parallel::detectCores(), parallel::detectCores(), cpus), type="FORK", verbose = TRUE)
  #doParallel::registerDoParallel(cl)
  #x = parallel::parLapply(cl, pr.dirs[1:20], fun=function(x){ if(any(!file.exists(paste0("/data/tt/LandGIS/grid250m/", x, "/", t.vars[j], "_M_sl", 1:6, "_", x, ".tif")))){ try( split_predict_n(x, gm, varn=t.vars[j], method="liquidSVM", multiplier=multiplier) ) } } )
  #parallel::stopCluster(cl)
  #unregister()
  #rm(cl)
  #gc(); gc()
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
  gc(); gc()
}
rm(gm)
gc()
save.image.pigz(n.cores = parallel::detectCores())

## Fix textures ----
SND.lst <- list.files(path="/data/tt/LandGIS/grid250m", pattern=glob2rx("sand_tot_psa_M_*_*.tif"), recursive = TRUE, full.names = TRUE)
str(SND.lst)
length(SND.lst)/6
#SLT.lst <- list.files(path="/data/tt/LandGIS/grid250m", pattern=glob2rx("silt_tot_psa_M_*_*.tif"), recursive = TRUE, full.names = TRUE)
#CF.lst <- list.files(path="/data/tt/LandGIS/grid250m", pattern=glob2rx("wpg2_M_*_*.tif"), recursive = TRUE, full.names = TRUE)
#length(SLT.lst)/6

sfInit(parallel=TRUE, cpus=parallel::detectCores())
sfLibrary(rgdal)
sfLibrary(sp)
sfExport("SND.lst", "normalize_texture")
x <- sfClusterApplyLB(1:length(SND.lst), function(i){normalize_texture(in.lst=SND.lst[i])})
sfStop()
gc()
rm(x)

## Fix SOC ----
## first, create complete mosaics
out.soc.tifs = paste0("/data/LandGIS/predicted250m/sol_organic.carbon_usda.6a1c_m_250m_b", c(0,10,30,60,100,200), "..", c(0,10,30,60,100,200), "cm_1950..2017_v0.1.tif")
varn0.lst = rep(c("oc.f"), 6)
d0.lst = paste0("M_sl", 1:6)

library(snowfall)
sfInit(parallel=TRUE, cpus=6)
sfExport("out.soc.tifs", "d0.lst", "mosaick_ll", "varn0.lst", "te", "cellsize")
out <- sfClusterApplyLB(1:length(out.soc.tifs), function(x){ try( mosaick_ll(varn=varn0.lst[x], i=d0.lst[x], out.tif=out.soc.tifs[x], in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot="Byte", dstnodata=255, aggregate=FALSE) )})
sfStop()

#all(file.exists(out.soc.tifs))
## test it:
#normalize_carbon(i="T14873", in.tif=out.soc.tifs, tile.tbl=tile.tbl)
#normalize_carbon(i="T44418", in.tif=out.soc.tifs, tile.tbl=tile.tbl)
#normalize_carbon(i="T23964", in.tif=out.soc.tifs, tile.tbl=tile.tbl)

sfInit(parallel=TRUE, cpus=parallel::detectCores())
sfLibrary(rgdal)
sfExport("pr.dirs", "normalize_carbon", "tile.tbl", "out.soc.tifs")
x <- sfClusterApplyLB(pr.dirs, function(i){normalize_carbon(i, in.tif=out.soc.tifs, tile.tbl=tile.tbl)})
sfStop()
gc()

## carbon stock ----
#carbon_stock(i="T38715")
sfInit(parallel=TRUE, cpus=parallel::detectCores())
sfExport("carbon_stock", "pr.dirs")
sfLibrary(raster)
sfLibrary(rgdal)
sfLibrary(GSIF)
out <- sfClusterApplyLB(pr.dirs, function(i){try( carbon_stock(i) )})
sfStop()

## clean up ----
#out.tex.tif = sapply(c("clay.wfraction", "silt.wfraction", "sand.wfraction"), function(i){paste0("/data/LandGIS/predicted250m/sol_", i,"_usda.3a1a1a_m_250m_s", c(0,10,30,60,100,200), "..", c(0,10,30,60,100,200), "cm_1950..2017_v0.1.tif")})
#unlink(out.tex.tif)
unlink(out.soc.tifs)

## texture class ----
#x = list.files("/data/tt/LandGIS/grid250m", glob2rx("texture.class_M_sl*_*.tif"), full.names=TRUE, recursive=TRUE)
#unlink(x)
library(soiltexture)
library(plyr)
library(raster)

tex.c <- data.frame(class.n=TT.classes.tbl(class.sys="USDA.TT", collapse=", ")[,"abbr"], class.i=1:12)
trim <- function (x){ gsub("^\\s+|\\s+$", "", x) }
library(snowfall)
library(raster)
library(rgdal)
library(soiltexture)
library(plyr)
sfInit(parallel=TRUE, cpus=parallel::detectCores())
sfExport("predictTEXclass", "frac2TEX", "trim", "pr.dirs", "tex.c")
sfLibrary(raster)
sfLibrary(rgdal)
sfLibrary(soiltexture)
sfLibrary(plyr)
out <- sfClusterApplyLB(pr.dirs, function(i){try( predictTEXclass(i, in.path="/data/tt/LandGIS/grid250m", tex.c=tex.c) )})
sfStop()

## Final mosaics ----
filename.lst = c(
  as.vector(sapply(paste0("b", c(0, 10, 30, 60, 100, 200), "..", c(0, 10, 30, 60, 100, 200)), function(i){ paste0("/data/LandGIS/predicted250m/sol_",c(out.vars,"texture.class"),"_", c(meth.vars,"usda.tt"), "_m_250m_", i, "cm_1950..2017_v0.2.tif") })), 
  as.vector(sapply(paste0("b", c(0, 10, 30, 60, 100), "..", c(10, 30, 60, 100, 200)), function(i){ paste0("/data/LandGIS/predicted250m/sol_organic.carbon.stock_msa.kgm2_m_250m_", i, "cm_1950..2017_v0.2.tif") }))
)
filename.lst = c(filename.lst, gsub("_m_", "_md_", filename.lst))
## 106 maps in total
varn.lst = rep(c(rep(c(t.vars,"texture.class"), 6), rep("ocs", 5)), 2)
d.lst = c(as.vector(sapply(paste0("M_sl", 1:6), function(i){rep(i, 8)})),
          paste0("M_sh", 1:5),
          as.vector(sapply(paste0("sd_sl", 1:6), function(i){rep(i, 8)})),
          paste0("sd_sh", 1:5) )
View(data.frame(filename.lst, varn.lst, d.lst))
write.csv(data.frame(filename.lst, varn.lst, d.lst), "/data/LandGIS/soil/soil_properties/filename_list.csv")
x = list.files("/data/LandGIS/predicted250m", glob2rx("sol_*_v0.1.tif$"), full.names = TRUE)
file.rename(x, gsub("v0.1", "v0.2", x))

library(snowfall)
sfInit(parallel=TRUE, cpus=25)
sfExport("varn.lst", "d.lst", "mosaick_ll", "filename.lst", "te", "cellsize")
out <- sfClusterApplyLB(1:length(filename.lst), function(x){ try( mosaick_ll(varn=varn.lst[x], i=d.lst[x], out.tif=filename.lst[x], in.path="/data/tt/LandGIS/grid250m", out.path="/data/LandGIS/predicted250m", tr=cellsize, te=paste(te, collapse = " "), ot=ifelse(varn.lst[x]=="ocs", "Int16", "Byte"), dstnodata=ifelse(varn.lst[x]=="ocs", "-32768", "255"), aggregate=FALSE) )})
sfStop()

save.image.pigz(n.cores = parallel::detectCores())
rm.aux = list.files("/mnt/DATA/LandGIS/", pattern=glob2rx("*.tif.aux.xml"), full.names = TRUE, recursive = TRUE)
unlink(rm.aux)
## copy to massive storage ----
x = list.files("/mnt/DATA/LandGIS/predicted250m", glob2rx("sol_*_*_m_250m_*_*_v0.1.tif$"), full.names = TRUE)
unlink(x)

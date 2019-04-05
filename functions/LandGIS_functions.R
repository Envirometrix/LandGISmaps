## Functions for LandGIS (https://github.com/Envirometrix/LandGIS_data)
## tom.hengl@gmail.com

unregister <- function() {
  env <- foreach:::.foreachGlobals
  rm(list=ls(name=env), pos=env)
}

test_classifier <- function(formulaString, df, sizes, nfold=3, mtry.seq, cpus=parallel::detectCores()){
  require(caret)
  ## test model accuracy:
  message("Running caret::train...")
  out.train <- caret::train(formulaString, data=df, method="ranger", 
                    trControl = trainControl(method="repeatedcv", classProbs=TRUE, number=nfold, repeats=1),
                    na.action = na.omit, num.trees=85, tuneGrid=expand.grid(mtry = mtry.seq, splitrule="gini", min.node.size=10))
  message("DONE")
  # run the RFE algorithm to select optimal subset of covariates:
  message("Running RFE...")
  require(parallel)
  cl <- parallel::makeCluster(cpus)
  doParallel::registerDoParallel(cl)
  out.rfe <- caret::rfe(x=df[,all.vars(formulaString)[-1]], y=df[,all.vars(formulaString)[1]], 
                    sizes=sizes, 
                    rfeControl=caret::rfeControl(functions=rfFuncs, method="cv", number=nfold))
  message("DONE")
  parallel::stopCluster(cl)
  return(list(train=out.train, rfe=out.rfe))
}

over_rds = function(x, y, out.dir="/data/LandGIS/overlay"){
  out.rds = paste0(out.dir, "/", basename(x), ".rds")
  if(!file.exists(out.rds)){
    z = raster::extract(raster(x), y, na.rm=FALSE)
    saveRDS.gz(z, out.rds)
    gc(); gc()
  }
}

dominant_class = function(i, tile.tbl, input.tif, tvar, out.dir="/data/tt/LandGIS/calc250m"){ # col.legend
  i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.tif <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/T", tile.tbl[i.n,"ID"], "_", tvar, ".tif")
  if(any(!file.exists(out.tif))){
    ## read all tifs:
    m = readGDAL(fname=input.tif[1], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    m = as(m, "SpatialPixelsDataFrame")
    sel.p = !is.na(m$band1)
    if(sum(sel.p)>0){
      for(j in 2:length(input.tif)){
        m@data[,j] = readGDAL(fname=input.tif[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent=TRUE)$band1[m@grid.index]
      }
      #tax = basename(input.tif)
      ## most probable class:
      #col.tbl <- plyr::join(data.frame(Group=tax, int=1:length(tax)), col.legend, type="left")
      ## match most probable class
      #m$cl <- col.tbl[match(apply(m@data,1,which.max), col.tbl$int),"Number"]
      m$cl <- apply(m@data,1,which.max)
      writeGDAL(m["cl"], out.tif, type="Byte", mvFlag=255, options="COMPRESS=DEFLATE")
    }
  }
}

pred_probs = function(i, gm, tile.tbl, col.legend, varn, out.dir="/data/tt/LandGIS/grid250m"){
  i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.rds <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/T", tile.tbl[i.n,"ID"], ".rds")
  out.c <- paste0(out.dir, "/", i, "/", varn, "_C_", i, ".tif")
  if(file.exists(out.rds) & !file.exists(out.c)){
    m = readRDS(out.rds)
    m = m[complete.cases(m@data[,gm$forest$independent.variable.names]),]
    pred = predict(gm, m@data)
    tax = attr(pred$predictions, "dimnames")[[2]]
    rs <- rowSums(pred$predictions, na.rm=TRUE)
    ## Write GeoTiffs:
    if(sum(rs,na.rm=TRUE)>0&length(rs)>0){
      ## predictions
      m@data <- data.frame(pred$predictions)
      x = m[1]
      for(j in 1:ncol(m)){
        out <- paste0(out.dir, "/", i, "/", varn, "_M_", tax[j], "_", i, ".tif")
        x@data[,1] <- round(m@data[,j]*100)
        writeGDAL(x[1], out, type="Byte", mvFlag=255, options="COMPRESS=DEFLATE")
      }
      ## most probable class:
      col.tbl <- plyr::join(data.frame(Group=tax, int=1:length(tax)), col.legend, type="left")
      ## match most probable class
      m$cl <- col.tbl[match(apply(m@data,1,which.max), col.tbl$int),"Number"]  
      writeGDAL(m["cl"], out.c, type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")
    }
    gc()
    gc()
  }
}

hor2xyd = function(x, U="UHDICM", L="LHDICM", treshold.T=15){
  x$DEPTH <- x[,U] + (x[,L] - x[,U])/2
  x$THICK <- x[,L] - x[,U]
  sel = x$THICK < treshold.T
  ## begin and end of the horizon:
  x1 = x[!sel,]; x1$DEPTH = x1[,L]
  x2 = x[!sel,]; x2$DEPTH = x1[,U]
  y = do.call(rbind, list(x, x1, x2))
  return(y)
}

saga_grid_stats = function(in.tif.lst, out.tif.lst, cleanup=TRUE, r.lst, d.lst, tr, te, out.ot="Byte", a_nodata=255, pca=FALSE, NFIRST, tif.convert=TRUE, p4s, tmp.dir="/data/tmp/"){
  if(all(file.exists(in.tif.lst)) & any(!file.exists(out.tif.lst))){
    require(parallel)
    sgrd.lst = paste0(tmp.dir, gsub(".tif", ".sgrd", basename(in.tif.lst)))
    message("Stacking rasters to the same grid...")
    if(missing(r.lst)){ r.lst = rep("near", length(in.tif.lst)) }
    if(missing(d.lst)){ d.lst = rep(a_nodata, length(in.tif.lst)) }
    if(missing(tr)){ tr = res(raster::raster(in.tif.lst[1]))[1] }
    if(missing(te)){ te = extent(raster::raster(in.tif.lst[1]))[c(1,3,2,4)] }
    if(missing(p4s)){ p4s = proj4string(raster::raster(in.tif.lst[1])) }
    x = parallel::mclapply(1:length(in.tif.lst), function(i) { system(paste0('gdalwarp ', in.tif.lst[i], ' ', tmp.dir, gsub(".tif", ".sdat", basename(in.tif.lst[i])),' -of \"SAGA" -ot \"Int16\" -dstnodata \"', d.lst[i], '\" -t_srs \"', p4s, '\" -co \"BIGTIFF=YES\" -wm 2000 -overwrite -r \"', r.lst[i], '\" -tr ', tr, ' ', tr, ' -te ', paste(te, collapse = " "))) }, mc.cores=length(in.tif.lst))
    if(pca==TRUE){
      message("Generating principal components...")
      if(missing(NFIRST)){ NFIRST = length(out.tif.lst) }
      system(paste0('saga_cmd statistics_grid 8 -GRIDS \"', paste(sgrd.lst, collapse=";"), '\" -PCA \"', paste(gsub(".tif", ".sgrd", out.tif.lst), collapse=";"), '\" -METHOD 2 -NFIRST ', NFIRST))
    } else {
      message("Deriving mean and stdev...")
      system(paste0('saga_cmd statistics_grid 4 -GRIDS \"', paste(c(sgrd.lst, sgrd.lst[length(sgrd.lst)]), collapse=";"), '\" -MEAN \"', gsub(".tif", ".sgrd", out.tif.lst[1]), '\" -STDDEV \"', gsub(".tif", ".sgrd", out.tif.lst[2]), '\"'))
    }
    if(tif.convert==TRUE){
      message("Generaring GeoTiffs...")
      x = parallel::mclapply(out.tif.lst, function(i) { system(paste0('gdal_translate ', gsub(".tif", ".sdat", i),' ', i, ' -co \"BIGTIFF=YES\" -co \"COMPRESS=DEFLATE\" -ot \"', out.ot,'\" -a_nodata \"', a_nodata,'\"')) }, mc.cores=length(out.tif.lst))
    }
    if(cleanup==TRUE){
      unlink(gsub(".tif", ".sdat", out.tif.lst)); unlink(gsub(".tif", ".prj", out.tif.lst)); unlink(gsub(".tif", ".sgrd", out.tif.lst)); unlink(gsub(".tif", ".sdat.aux.xml", out.tif.lst)); unlink(gsub(".tif", ".mgrd", out.tif.lst))
      unlink(paste0(tmp.dir, gsub(".tif", ".sdat", basename(in.tif.lst)))); unlink(paste0(tmp.dir, gsub(".tif", ".prj", basename(in.tif.lst)))); unlink(paste0(tmp.dir, gsub(".tif", ".sgrd", basename(in.tif.lst)))); unlink(paste0(tmp.dir, gsub(".tif", ".sdat.aux.xml", basename(in.tif.lst)))) 
    }
  }
}

stack_stats_inram <- function(tif.sel, out=c("min","med","max"), probs =c(.025,.5,.975), out.tifs, type="Int16", mvFlag=-32767, na.min.value=0, na.max.value=1e4, scale.v=1, mean.map=TRUE){
  require(data.table)
  require(rgdal)
  if(any(!file.exists(out.tifs))){
    m = readGDAL(fname=tif.sel[1], silent = TRUE)
    m@data[,1] = ifelse(m@data[,1] > na.max.value, NA, ifelse(m@data[,1] < na.min.value, NA, m@data[,1]))*scale.v
    for(j in 2:length(tif.sel)){
      x = readGDAL(fname=tif.sel[j], silent = TRUE)$band1
      m@data[,j] = ifelse(x > na.max.value, NA, ifelse(x < na.min.value, NA, x))*scale.v
    }
    v = data.table(m@data)
    if(mean.map==TRUE){
      ## mean value (can be quite differnt from the median!):
      m$mean = rowMeans(m@data, na.rm=TRUE)
      writeGDAL(m["mean"], gsub("_min_", "_mean_", out.tifs[1]), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    }
    m@data[,out] = t(v[, apply(v, 1, quantile, probs = probs, na.rm=TRUE)])
    for(k in 1:length(out)){
      writeGDAL(m[out[k]], out.tifs[k], type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    }
  }
}

missing_tile = function(i, var1, var2, var3, out=c("min","med","max"), out.dir="/data/tt/OpenLandData/covs250m", type="Int16", mvFlag=-32767){
  for(j in 1:length(out)){
    out.tif = paste0(out.dir, "/", i,"/", var2, "_",  out[j], "_", i, ".tif")
    if(!file.exists(out.tif)){
      t1 = paste0(out.dir, "/", i,"/", var1, "_",  out[j], "_", i, ".tif")
      t3 = paste0(out.dir, "/", i,"/", var3, "_",  out[j], "_", i, ".tif")
      m = stack(c(t1, t3))
      m = as(m, "SpatialGridDataFrame")
      m$fix = rowMeans(m@data, na.rm=TRUE)
      writeGDAL(m["fix"], out.tif, type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    }
  }
}

stack_stats <- function(i, tile.tbl, tif.sel, var, out=c("min","med","max"), probs =c(.025,.5,.975), out.dir="/data/tt/OpenLandData/covs250m", type="Int16", mvFlag=-32767){
  out.tif = paste0(out.dir, "/", i,"/", var, "_",  out, "_", i, ".tif")
  require(data.table)
  require(rgdal)
  if(any(!file.exists(out.tif))){
    i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
    m = readGDAL(fname=tif.sel[1], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    for(j in 2:length(tif.sel)){
      m@data[,j] = readGDAL(fname=tif.sel[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    }
    ## Fastest way to derive stats is via the data.table package
    v = data.table(m@data)
    m@data[,out] = t(v[, apply(v, 1, quantile, probs = probs, na.rm=TRUE)])
    for(k in 1:length(out)){
      writeGDAL(m[out[k]], paste0(out.dir, "/", i,"/", var, "_",  out[k], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    }
  }
}

stack_mean_sd <- function(i, tile.tbl, tif.sel, var, out=c("mean","sd"), out.dir="/data/tt/OpenLandData/covs250m", type="Byte", mvFlag=255){
  out.tif = paste0(out.dir, "/", i,"/", var, "_",  out, "_", i, ".tif")
  require(data.table)
  require(rgdal)
  if(any(!file.exists(out.tif))){
    i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
    m = readGDAL(fname=tif.sel[1], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    for(j in 2:length(tif.sel)){
      m@data[,j] = readGDAL(fname=tif.sel[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    }
    ## Fastest way to derive stats is via the data.table package
    v = data.table(m@data)
    m@data[,out[1]] = round(apply(v, 1, mean, na.rm=TRUE))
    m@data[,out[2]] = round(apply(v, 1, sd, na.rm=TRUE))
    for(k in 1:length(out)){
      writeGDAL(m[out[k]], paste0(out.dir, "/", i,"/", var, "_",  out[k], "_", i, ".tif"), type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
    }
  }
}

mosaick_ll <- function(varn=NULL, i, out.tif, in.path="/data/tt/OpenLandData/covs250m", out.path="/data/GEOG", ot="Int16", dstnodata=-32768, dominant=FALSE, resample="near", metadata=NULL, aggregate=FALSE, te, tr, only.metadata=TRUE, pattern=NULL){
  if(missing(out.tif)){
    out.tif <- paste0(out.path, "/", varn, "_", i, "_250m_ll.tif")
  }
  if(!file.exists(out.tif)){
    if(missing(i)){
      if(is.null(pattern)){ 
        pattern <- paste0(varn, "_T*.tif$") 
      }
      tmp.lst <- list.files(path=in.path, pattern=glob2rx(pattern), full.names=TRUE, recursive=TRUE)
    } else {
      tmp.lst <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_", i, "_T*.tif$")), full.names=TRUE, recursive=TRUE)
    }
    if(length(tmp.lst)>1){
      out.tmp <- tempfile(fileext = ".txt")
      vrt.tmp <- tempfile(fileext = ".vrt")
      cat(tmp.lst, sep="\n", file=out.tmp)
      system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
      system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -ot \"', paste(ot), '\" -dstnodata \"',  paste(dstnodata), '\" -r \"near\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -multi -wo \"NUM_THREADS=2\" -wm 2000 -tr ', tr, ' ', tr, ' -te ', te))
      system(paste0('gdaladdo ', out.tif, ' 2 4 8 16 32 64 128'))
      if(!is.null(metadata)){ 
        m = paste('-mo ', '\"', names(metadata), "=", as.vector(metadata), '\"', sep="", collapse = " ")
        command = paste0('gdal_edit.py ', m,' ', out.tif)
        system (command, intern=TRUE)
      }
      ## 1 km resolution:
      if(aggregate==TRUE){
        if(dominant==TRUE){
          system(paste0('gdal_translate -of GTiff -r \"near\" -tr ', 1/120, ' ', 1/120, ' ', vrt.tmp, ' ', gsub("250m", "1km", gsub("_250m_ll.tif", "_1km_ll.tif", out.tif)), ' -ot \"', paste(ot), '\" -a_nodata \"', paste(dstnodata), '\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\"'))
        } else {
          system(paste0('gdal_translate -of GTiff -r \"average\" -tr ', 1/120, ' ', 1/120, ' ', vrt.tmp, ' ', gsub("250m", "1km", gsub("_250m_ll.tif", "_1km_ll.tif", out.tif)), ' -ot \"', paste(ot), '\" -a_nodata \"', paste(dstnodata), '\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\"'))
        }
      }
      unlink(vrt.tmp)
      unlink(out.tmp)
    }
  }
  if(!is.null(metadata)&only.metadata==TRUE){ 
    m = paste('-mo ', '\"', names(metadata), "=", as.vector(metadata), '\"', sep="", collapse = " ")
    command = paste0('gdal_edit.py ', m,' ', out.tif)
    system (command, intern=TRUE)
  }
}

rasterize_pol <- function(INPUT, FIELD, OUTPUT, cellsize, xllcorner, yllcorner, xurcorner, yurcorner, cpus=24){
  if(!pkgmaker::file_extension(INPUT)=="shp") {stop("Shapefile required")}
  if(missing(OUTPUT)){ OUTPUT = gsub(".shp", ".tif", basename(INPUT)) }
  if(!file.exists(OUTPUT)){
    system(paste0('saga_cmd -c=', cpus, ' grid_gridding 0 -INPUT \"', INPUT, '\" -FIELD \"', FIELD, '\" -GRID \"', gsub(".tif", ".sgrd", OUTPUT), '\" -GRID_TYPE 0 -TARGET_DEFINITION 0 -TARGET_USER_SIZE ', cellsize, ' -TARGET_USER_XMIN ', xllcorner+cellsize/2,' -TARGET_USER_XMAX ', xurcorner-cellsize/2, ' -TARGET_USER_YMIN ', yllcorner+cellsize/2,' -TARGET_USER_YMAX ', yurcorner-cellsize/2))
    system(paste0('gdalwarp ', gsub(".tif", ".sdat", OUTPUT), ' ', OUTPUT, ' -co \"COMPRESS=DEFLATE\" -r \"near\" -tr ', cellsize, ' ', cellsize, ' -te ', xllcorner,' ', yllcorner, ' ', xurcorner, ' ', yurcorner))
    unlink(gsub(".tif", ".sdat", OUTPUT))
  }
}

## Convert to sinusoidal projection ----
latlon2sin = function(input.file, output.file, mod.grid, tmp.dir="/data/tmp/", proj, pixsize, cleanup.files=TRUE, te, resample="near"){
  ## reproject grid in tiles:
  out.files = paste0(tmp.dir, "T", mod.grid$ID, "_", set.file.extension(basename(input.file), ".tif"))
  te.lst = apply(mod.grid@data[,1:4], 1, function(x){paste(x, collapse=" ")})
  if(missing(proj)){ proj = "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs" }
  sfInit(parallel=TRUE, cpus=48)
  sfExport("mod.grid", "te.lst", "proj", "out.files")
  #sfLibrary(rgdal)
  x <- sfClusterApplyLB(1:length(out.files), function(i){ invisible( system(paste0('gdalwarp ', input.file, ' ', out.files[i], ' -r \"', resample, '\" -t_srs \"', proj, '\" -tr ', pixsize, ' ', pixsize, ' -te ', te.lst[i]), show.output.on.console = FALSE, intern = TRUE) ) }) ## -co \"COMPRESS=DEFLATE\"
  sfStop()
  ## mosaic:
  tmp.lst = list.files(path=tmp.dir, pattern=basename(input.file), full.names=TRUE)
  out.tmp <- tempfile(fileext = ".txt")
  vrt.tmp <- tempfile(fileext = ".vrt")
  cat(tmp.lst, sep="\n", file=out.tmp)
  system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
  if(missing(te)){
    system(paste0('gdalwarp ', vrt.tmp, ' ', output.file, ' -ot \"Int16\" -dstnodata \"-32767\" -co \"BIGTIFF=YES\" -multi -wm 2000 -co \"COMPRESS=DEFLATE\" -r \"near\"'))
  } else {
    system(paste0('gdalwarp ', vrt.tmp, ' ', output.file, ' -ot \"Int16\" -dstnodata \"-32767\" -co \"BIGTIFF=YES\" -multi -wm 2000 -co \"COMPRESS=DEFLATE\" -r \"near\" -te ', te))
  }
  if(cleanup.files==TRUE){ unlink(out.files) }
}

## resample maps to coarser resolution ----
aggr_SG <- function(i, r, tr=1/120, tr.metric=1000, out.dir="/data/aggregated/1km/", ti="250m", tn="1km"){
  if(missing(r)){
    if(any(basename(i) %in% c("TAXOUSDA_250m_ll.tif", "TAXNWRB_250m_ll.tif", "TAXNWRB_300m_sin.tif", "TAXOUSDA_300m_sin.tif", "GAUL_ADMIN1_landmask_300m_sin.tif", paste0("TEXMHT_M_sl",1:7,"_250m_ll.tif")))){
      r = 'near'
    } else {
      r = 'average'
    }
  }
  if(any(basename(i) %in% c("OCSTHA_M_30cm_300m_sin.tif", "OCSTHA_M_100cm_300m_sin.tif", "OCSTHA_M_200cm_300m_sin.tif", "TAXNWRB_300m_sin.tif", "TAXOUSDA_300m_sin.tif", "GAUL_ADMIN1_landmask_300m_sin.tif"))){
    tr = tr.metric
    ti = "300m"
  }
  out.tif = paste0(out.dir, set.file.extension(gsub(paste0("_", ti), paste0("_", tn), basename(i)), ".tif"))
  if(!file.exists(out.tif)){
    system(paste0('gdalwarp ', i, ' ', out.tif, ' -r \"', r, '\" -tr ', tr, ' ', tr, ' -co \"COMPRESS=DEFLATE\"'))
  }
}

## Overlay and extract values using a tiling system:
extract.tiled <- function(obj, tile.pol, path="/data/tt/LandGIS/grid250m", ID="ID", cpus=parallel::detectCores()){
  obj$row.index <- 1:nrow(obj)
  ov.c <- over(spTransform(obj, CRS(proj4string(tile.pol))), tile.pol)
  message("Done overlaying points and tiles.")
  ov.t <- which(!is.na(ov.c[,ID]))
  ## for each point get the tile name:
  ov.c <- data.frame(ID=ov.c[ov.t,ID], row.index=ov.t)
  tiles.lst <- basename(dirname(list.files(path=path, pattern=glob2rx("*.rds$"), recursive=TRUE)))
  ov.c <- ov.c[ov.c[,ID] %in% sapply(tiles.lst, function(i){strsplit(i, "T")[[1]][2]}),]
  tiles <- levels(as.factor(paste(ov.c[,ID]))) 
  cov.c <- as.list(tiles)
  names(cov.c) <- tiles
  ## extract using snowfall
  require(snowfall)
  sfInit(parallel=TRUE, cpus=cpus)
  sfExport(list=c("obj", "path", "ov.c", "ID", "cov.c", ".extract.tile", "tile.pol"))
  sfLibrary(raster)
  sfLibrary(rgdal)
  ov.lst <- sfClusterApplyLB(1:length(cov.c), function(i){try(.extract.tile(i, x=obj, ID=ID, path=path, ov.c=ov.c, cov.c=cov.c, tile.pol=tile.pol), silent = TRUE)}) 
  snowfall::sfStop()
  #cl <- parallel::makeCluster(cpus, type="FORK") 
  #parallel::clusterExport(cl, list("obj", "path", "ov.c", "ID", "cov.c", ".extract.tile", "tile.pol"), envir=environment())
  #ov.lst = parallel::clusterApplyLB(cl, 1:length(cov.c), function(i){try(.extract.tile(i, x=obj, ID=ID, path=path, ov.c=ov.c, cov.c=cov.c, tile.pol=tile.pol), silent = FALSE)}) 
  #parallel::stopCluster(cl)
  ## bind together:
  message("Done running overlay in parallel.")
  out <- dplyr::bind_rows(ov.lst)
  out <- plyr::join(obj@data, as.data.frame(out), type="left", by="row.index")
  return(out)
}

.extract.tile <- function(i, x, ID, path, ov.c, cov.c, tile.pol){
  row.index <- ov.c$row.index[ov.c[,ID]==names(cov.c)[i]]
  pnts <- x[row.index,]
  pnts <- spTransform(pnts, CRS(proj4string(tile.pol)))
  m <- readRDS(paste0(path, "/T", names(cov.c)[i], "/T", names(cov.c)[i], ".rds"))
  out <- sp::over(y=m, x=pnts)
  out$band1 <- NULL
  out$row.index <- row.index
  xy <- data.frame(pnts@coords)
  names(xy) <- c("X","Y")
  out <- cbind(out, xy)
  return(out)
}

## prediction error for predicting probs:
cv_factor <- function(formulaString, rmatrix, nfold, idcol, cpus=nfold){ 
  require("ROCR"); require("plyr"); require("ranger"); require("mda"); require("psych")
  varn <- all.vars(formulaString)[1]
  sel <- dismo::kfold(rmatrix, k=nfold, by=rmatrix[,varn])
  message(paste("Running ", nfold, "-fold cross validation with model re-fitting...", sep=""))
  ## run in parallel:
  if(missing(cpus)){ 
    require("parallel")
    cpus <- parallel::detectCores(all.tests = FALSE, logical = FALSE) 
  }
  if(cpus>1){
    require("snowfall")
    snowfall::sfInit(parallel=TRUE, cpus=cpus)
    snowfall::sfExport("idcol","formulaString","rmatrix","sel","varn","predict_ranger_probs")
    snowfall::sfLibrary(package="ROCR", character.only=TRUE)
    snowfall::sfLibrary(package="nnet", character.only=TRUE)
    snowfall::sfLibrary(package="plyr", character.only=TRUE)
    snowfall::sfLibrary(package="ranger", character.only=TRUE)
    snowfall::sfLibrary(package="caret", character.only=TRUE)
    out <- snowfall::sfLapply(1:nfold, function(j){predict_ranger_probs(j, sel=sel, varn=varn, formulaString=formulaString, rmatrix=rmatrix, idcol=idcol)})
    snowfall::sfStop()
  } else {
    out <- lapply(1:nfold, function(j){predict_ranger_probs(j, sel=sel, varn=varn, formulaString=formulaString, rmatrix=rmatrix, idcol=idcol)})
  }
  ## calculate totals per class
  N.tot <- plyr::rbind.fill(lapply(out, function(x){x[["n.l"]]}))
  N.tot <- colSums(N.tot)
  ## mean error per class:
  mean.error <- plyr::rbind.fill(lapply(out, function(x){x[["error.l"]]}))
  mean.error <- colSums(mean.error)/N.tot
  error <- plyr::rbind.fill(lapply(out, function(x){x[["error"]]}))
  obs <- plyr::rbind.fill(lapply(out, function(x){ as.data.frame(x[["obs.pred"]][[1]])}))
  pred <- plyr::rbind.fill(lapply(out, function(x){ as.data.frame(x[["obs.pred"]][[2]])}))
  ## Get the most probable class:
  cl <- parallel::makeCluster(getOption("cl.cores", cpus))
  ranks.pred <- parallel::parApply(cl, pred, MARGIN=1, which.max)
  ranks.obs <- parallel::parApply(cl, obs, MARGIN=1, which.max)
  parallel::stopCluster(cl)
  ## derive confusion matrix:
  cf <- mda::confusion(names(obs)[ranks.obs], names(pred)[ranks.pred])
  c.kappa <- psych::cohen.kappa(cbind(names(obs)[ranks.obs], names(pred)[ranks.pred]))
  purity <- sum(diag(cf))/sum(cf)*100  
  ## Accuracy for Binomial var [http://www.r-bloggers.com/evaluating-logistic-regression-models/]: 
  TPR <- sapply(1:ncol(obs), function(c){mean(performance( prediction(pred[,c], obs[,c]), measure="tpr")@y.values[[1]])})
  AUC <- sapply(1:ncol(obs), function(c){performance( prediction(pred[,c], obs[,c]), measure="auc")@y.values[[1]]})
  cv.r <- list(obs, pred, error, data.frame(ME=mean.error, TPR=TPR, AUC=AUC, N=N.tot), cf, c.kappa, purity)
  names(cv.r) <- c("Observed", "Predicted", "CV_residuals", "Classes", "Confusion.matrix", "Cohen.Kappa", "Purity")
  message("Done")
  return(cv.r)
}

predict_ranger_probs <- function(j, sel, varn, formulaString, rmatrix, idcol){
  require("plyr"); require("ranger")
  message(paste("Fitting fold ", j, " and deriving mapping accuracy", sep=""))
  s.train <- rmatrix[!sel==j,]
  s.test <- rmatrix[sel==j,]
  n.l <- plyr::count(s.test[,varn])
  n.l <- data.frame(matrix(n.l$freq, nrow=1, dimnames = list(1, paste(n.l$x))))
  gm = ranger(formulaString, data=s.train, write.forest=TRUE, probability=TRUE)
  probs <- predict(gm, s.test, probability=TRUE, na.action = na.pass)$predictions
  names <- colnames(probs)
  obs <- data.frame(lapply(names, FUN=function(i){ifelse(s.test[, varn]==i, 1, 0)}))
  names(obs) = names
  obs.pred <- list(as.matrix(obs[,names]), probs[,names])
  error <- Reduce("-", obs.pred)
  error.l <- as.data.frame(t(signif(colSums(error), 3)))
  ## copy ID of the point
  error <- as.data.frame(error)
  error[,idcol] <- paste(s.test[,idcol])
  ## Accuracy for Binomial var [http://www.r-bloggers.com/evaluating-logistic-regression-models/]:
  pred.l <- lapply(1:nrow(obs.pred[[2]]), function(i){prediction(obs.pred[[2]][i,], obs.pred[[1]][i,])})
  out <- list(n.l, obs.pred, error, error.l)
  names(out) <- c("n.l", "obs.pred", "error", "error.l")
  return(out)
}


## Cross-validation numeric variables:
cv_ranger <- function(fm, rmatrix, nfold=5, idcol, Nsub=1e4, Log=FALSE, LLO=TRUE, pars.ranger=NULL){
  rmatrix = rmatrix[!is.na(rmatrix[,all.vars(fm)[1]]),]
  if(missing(idcol)) { 
    rmatrix$ID = row.names(rmatrix)
    idcol = "ID"
  }
  message(paste("Running ", nfold, "-fold cross validation with model re-fitting.", sep=""))
  if(nfold > nrow(rmatrix)){ 
    stop("'nfold' argument must not exceed total number of points") 
  }
  if(sum(duplicated(rmatrix[,idcol]))>0.5*nrow(rmatrix)){
    if(LLO==TRUE){
      ## TH: Leave whole locations out
      ul <- paste(unique(rmatrix[,idcol]))
      sel.ul <- dismo::kfold(ul, k=nfold)
      sel <- lapply(1:nfold, function(o){ data.frame(row.names=which(rmatrix[,idcol] %in% ul[sel.ul==o]), x=rep(o, length(which(rmatrix[,idcol] %in% ul[sel.ul==o])))) })
      sel <- do.call(rbind, sel)
      sel <- sel[order(as.numeric(row.names(sel))),]
      message(paste0("Subsetting observations by unique location"))
    } else {
      sel <- dismo::kfold(rmatrix, k=nfold, by=rmatrix[,idcol])
      message(paste0("Subsetting observations by '", idcol, "'"))
    }
  } else {
    sel <- dismo::kfold(rmatrix, k=nfold)
    message(paste0("Simple subsetting of observations using kfolds"))
  }
  out <- lapply(1:nfold, function(j){ cv_predict_ranger(j, sel=sel, idcol=idcol, fm=fm, rmatrix=rmatrix, Nsub=Nsub, pars.ranger=pars.ranger)})
  ## calculate mean accuracy:
  out <- plyr::rbind.fill(out)
  out$z_score = (out$Observed - out$Predicted)/out$sdPE
  out$z_score = ifelse(is.infinite(out$z_score), NA, out$z_score)
  ME = mean(out$Observed - out$Predicted, na.rm=TRUE)
  MAE = mean(abs(out$Observed - out$Predicted), na.rm=TRUE)
  RMSE = sqrt(mean((out$Observed - out$Predicted)^2, na.rm=TRUE))
  MZS = mean(out$z_score, na.rm=TRUE)
  ZSV = sd(out$z_score, na.rm=TRUE)
  ## Errors of errors:
  MAE.SE = mean(abs(out$Observed - out$Predicted) - out$sdPE, na.rm=TRUE)
  ## https://en.wikipedia.org/wiki/Coefficient_of_determination
  R.squared = 1-var(out$Observed - out$Predicted, na.rm=TRUE)/var(out$Observed, na.rm=TRUE)
  if(Log==TRUE){
    logRMSE = sqrt(mean((log1p(out$Observed) - log1p(out$Predicted))^2, na.rm=TRUE))
    logR.squared = 1-var(log1p(out$Observed) - log1p(out$Predicted), na.rm=TRUE)/var(log1p(out$Observed), na.rm=TRUE)
    cv.r <- list(out, data.frame(ME=ME, MAE=MAE, RMSE=RMSE, MAE.SE=MAE.SE, MZS=MZS, ZSV=ZSV, R.squared=R.squared, logRMSE=logRMSE, logR.squared=logR.squared)) 
  } else {
    cv.r <- list(out, data.frame(ME=ME, MAE=MAE, RMSE=RMSE, MAE.SE=MAE.SE, MZS=MZS, ZSV=ZSV, R.squared=R.squared))
  }
  message("DONE")
  names(cv.r) <- c("CV_residuals", "Summary")
  return(cv.r)
}

## Predict ranger RF using CV
cv_predict_ranger <- function(j, sel, idcol, fm, rmatrix, Nsub, pars.ranger){ 
  varn = all.vars(fm)[1]
  # For method == "geoR" spcT has no meaning, the same for method == "ranger" & OK = T
  s.train <- rmatrix[!sel==j,]
  s.train <- s.train[complete.cases(s.train[,all.vars(fm)]),]
  message(paste0("Running ", j, " fold with: ", nrow(s.train), " training points"))
  s.test <- rmatrix[sel==j,]
  if(!Nsub>nrow(s.train)){ 
    s.train = s.train[sample.int(nrow(s.train), Nsub),]
  }
  require(ranger)
  if(missing(pars.ranger)|is.null(pars.ranger)){
    gm <- ranger(fm, s.train, quantreg = TRUE)
  } else {
    pars.ranger$mtry = ifelse(pars.ranger$mtry >= length(all.vars(fm)), length(all.vars(fm))-1, pars.ranger$mtry)
    ##  mtry can not be larger than number of variables in data
    gm <- ranger(fm, s.train, mtry=pars.ranger$mtry, min.node.size=pars.ranger$min.node.size, num.trees = pars.ranger$num.trees, sample.fraction=pars.ranger$sample.fraction, seed=pars.ranger$seed, quantreg = TRUE)
  }
  sel.t = complete.cases(s.test)
  x.pred <- predict(gm, s.test[sel.t,], type="quantiles", quantiles = c((1-.682)/2, 0.5, 1-(1-.682)/2))$predictions
  pred <- data.frame(predictions=x.pred[,2], se=(x.pred[,3]-x.pred[,1])/2)
  names(pred)[1] = "predictions"
  obs.pred <- as.data.frame(list(s.test[sel.t,varn], pred$predictions, pred$se), col.names=c("Observed", "Predicted", "sdPE"))
  obs.pred[,idcol] <- s.test[sel.t,idcol]
  obs.pred$fold = j
  return(obs.pred)
}

pfun.loess <- function(x,y, ...){ 
  panel.xyplot(x,y, ...)
  panel.abline(0,1,lty=2,lw=1,col="grey60")
  panel.loess(x,y,span=0.5, col = "grey30", lwd = 1.7)
}

pfun <- function(x,y, ...){
  panel.hexbinplot(x,y, ...)  
  panel.abline(0,1,lty=1,lw=2,col="black")
}

overlay.raster = function(r, p, ps4){
  if(file.exists(r)){
    r = raster::raster(r)
    if(missing(ps4)){
      ps4 = proj4string(r)
    } else {
      proj4string(r) = ps4
    }
    if(!proj4string(r)==proj4string(p)){ 
      p = spTransform(p, CRS(ps4))
    }
    out = raster::extract(r, p)
    return(out)
  }
}

## derive Scaled Shannon Entropy (100 is a maximum error; 0 is perfect prediction)
entropy_tile <- function(i, in.path, varn, levs){
  out.p <- paste0(in.path, "/", i, "/SSI_", varn, "_", i, ".tif")
  if(!file.exists(out.p)){
    tif.lst <- paste0(in.path, "/", i, "/", varn, "_", levs, "_", i, ".tif")
    s <- raster::stack(tif.lst)
    s <- as(as(s, "SpatialGridDataFrame"), "SpatialPixelsDataFrame")
    gc()
    v <- unlist(alply(s@data, 1, .fun=function(x){entropy.empirical(unlist(x))})) 
    s$SSI <- round(v/entropy.empirical(rep(1/length(levs),length(levs)))*100)
    writeGDAL(s["SSI"], out.p, type="Byte", mvFlag=255, options="COMPRESS=DEFLATE")
  }
}

## Filter landform / lithology maps using land mask:
filter_landmask = function(i, tile.tbl, inf.tif, tif.land="/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif", tif.admin="/data/LandGIS/layers250m/lcv_admin0_fao.gaul_c_250m_s0..0cm_2015_v1.0.tif", out.dir="/data/tt/grid250m"){
  i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.tif <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/T", tile.tbl[i.n,"ID"], "_", basename(inf.tif))
  if(any(!file.exists(out.tif))){
    ## land mask:
    m = readGDAL(fname=tif.land, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    m$band2 = readGDAL(fname=tif.admin, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    m = as(m, "SpatialPixelsDataFrame")
    sel.p = (m$band1==1|m$band1==3)
    if(sum(sel.p)>0){
      m = m[sel.p,]
      for(j in 1:length(inf.tif)){
        m@data[,j+2] = readGDAL(fname=inf.tif[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent=TRUE)$band1[m@grid.index]
      }
      names(m) = c("landcover", "admin", basename(inf.tif))
      ## Systematic fixes (snow prob):
      sn.sel = grep(pattern="ESA4", names(m))
      for(p in sn.sel){ m@data[,p] = ifelse(m@data[,p]>100, NA, m@data[,p]) }
      ## Missing values in latitudes >61
      if(any(m@coords[,2]>61.4)){
        m$S01ESA4.tif = ifelse(m@coords[,2]>61.4 & is.na(m$S01ESA4.tif), 100, m$S01ESA4.tif)
        m$S12ESA4.tif = ifelse(m@coords[,2]>61.4 & is.na(m$S12ESA4.tif), 100, m$S12ESA4.tif)
        m$S11ESA4.tif = ifelse(m@coords[,2]>61.4 & is.na(m$S11ESA4.tif), 100, m$S11ESA4.tif)
      }
      ## Filter northern latitudes MODFC:
      m$C11MCF5.tif = ifelse(is.na(m$C11MCF5.tif), rowMeans(m@data[,c("C09MCF5.tif", "C10MCF5.tif", "C12MCF5.tif", "C01MCF5.tif")], na.rm=TRUE), m$C11MCF5.tif)
      m$C12MCF5.tif = ifelse(is.na(m$C12MCF5.tif), rowMeans(m@data[,c("C10MCF5.tif", "C11MCF5.tif", "C01MCF5.tif", "C02MCF5.tif")], na.rm=TRUE), m$C12MCF5.tif)
      m$C01MCF5.tif = ifelse(is.na(m$C01MCF5.tif), rowMeans(m@data[,c("C11MCF5.tif", "C12MCF5.tif", "C02MCF5.tif", "C03MCF5.tif")], na.rm=TRUE), m$C01MCF5.tif)
      ## Filter Greenland
      m$L07USG5.tif = ifelse(is.na(m$L07USG5.tif) & m$admin==99, 100, m$L07USG5.tif)
      ## Filter Global Surface Water
      m$OCCGSW7.tif = ifelse(m$OCCGSW7.tif>100 | is.na(m$OCCGSW7.tif), 0, m$OCCGSW7.tif)
      ## Filter GIEMS
      m$GIEMSD3.tif = ifelse(is.na(m$GIEMSD3.tif), 0, m$GIEMSD3.tif)
      ## Filter indicators
      us.sel = grep(pattern="USG5", names(m))
      for(q in us.sel){ m@data[,q] = ifelse(is.na(m@data[,q]), 0, m@data[,q]) }
      ## Fill-in the remaining missing values (can be tricky)
      sel.mis = sapply(m@data[,-unlist(sapply(c("USG5", "admin", "landcover"), function(i){grep(i,names(m))}))], function(x){sum(is.na(x))>0})
      if(sum(sel.mis)>0){
        x = which(sel.mis)
        for(k in 1:length(x)){
          if(!is.factor(m@data[,attr(x, "names")[k]])){
            if(length(grep(pattern="OCCGSW7", attr(x, "names")[k]))>0 | length(grep(pattern="ESA4", attr(x, "names")[k]))>0 | length(grep(pattern="USG5", attr(x, "names")[k]))>0 ){ 
              repn = rep(0, nrow(m)) 
            } else {
              r = raster::raster(m[attr(x, "names")[k]])
              ## first using proximity filter:
              rf = raster::focal(r, w=matrix(1,15,15), fun=mean, na.rm=TRUE, NAonly=TRUE)
              repn = as(rf, "SpatialGridDataFrame")@data[m@grid.index,1]
              ## second using dominant value:
              repn = ifelse(is.na(repn), quantile(repn, probs=.5, na.rm=TRUE), repn)
            }
            m@data[,attr(x, "names")[k]] = ifelse(is.na(m@data[,attr(x, "names")[k]]), repn, m@data[,attr(x, "names")[k]])
          }
        }
      }
      ## write back filtered Geotiff:
      for(j in 1:length(out.tif)){
        type <- ifelse(length(grep("MCF5", out.tif[j]))>0, "Int16", "Byte")
        mvFlag <- ifelse(length(grep("MCF5", out.tif[j]))>0, "-32768", "255")
        writeGDAL(m[j+2], out.tif[j], type=type, mvFlag=mvFlag, options=c("COMPRESS=DEFLATE"))
      }
    }
  }
}

writeRDS.tile <- function(i, tif.sel, tile.tbl, tif.mask="/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif", out.dir="/data/tt/LandGIS/grid250m"){
  i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.rds <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/T", tile.tbl[i.n,"ID"], ".rds")
  if(!file.exists(out.rds)){
    m = readGDAL(fname=tif.mask, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    m = as(m, "SpatialPixelsDataFrame")
    sel.p = (m$band1==1|m$band1==3)
    if(sum(sel.p)>0){
      m = m[sel.p,]
      for(j in 1:length(tif.sel)){
        m@data[,j+1] = readGDAL(fname=tif.sel[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent=TRUE)$band1[m@grid.index]
      }
      names(m) = c("mask", basename(tif.sel))
      ## Fill-in the remaining missing values (can be very tricky)
      sel.mis = sapply(m@data[,-unlist(sapply(c("usgs.ecotapestry", "mask"), function(i){grep(i,names(m))}))], function(x){sum(is.na(x))>0})
      if(sum(sel.mis)>0){
        x = which(sel.mis)
        for(k in 1:length(x)){
          if(!is.factor(m@data[,attr(x, "names")[k]])){
            if(length(grep(pattern="_p_", attr(x, "names")[k]))>0 ){ 
              repn = rep(0, nrow(m)) 
            } else {
              r = raster::raster(m[attr(x, "names")[k]])
              ## 1 using proximity filter:
              rf = raster::focal(r, w=matrix(1,15,15), fun=mean, pad=TRUE, na.rm=TRUE, NAonly=TRUE)
              repn = as(rf, "SpatialGridDataFrame")@data[m@grid.index,1]
              ## 2 using dominant value:
              repn = ifelse(is.na(repn), quantile(repn, probs=.5, na.rm=TRUE), repn)
            }
            m@data[,attr(x, "names")[k]] = ifelse(is.na(m@data[,attr(x, "names")[k]]), repn, m@data[,attr(x, "names")[k]])
          }
        }
      }
      saveRDS(m, out.rds)
    }
  }  
}

writeRDS.pc.tile <- function(i, tif.sel.pc, covs_prcomp, scaling.c, scaling.s, tile.tbl, tif.mask="/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif", out.dir="/data/tt/LandGIS/grid250m"){
  i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.rds <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/T", tile.tbl[i.n,"ID"], ".rds")
  if(!file.exists(out.rds)){
    m = readGDAL(fname=tif.mask, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    m = as(m, "SpatialPixelsDataFrame")
    sel.p = (m$band1==1|m$band1==3)
    if(sum(sel.p)>0){
      m = m[sel.p,]
      for(j in 1:length(tif.sel.pc)){
        m@data[,j+1] = readGDAL(fname=tif.sel.pc[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent=TRUE)$band1[m@grid.index]
      }
      names(m) = c("mask", basename(tif.sel.pc))
      sel.mis = sapply(m@data, function(x){sum(is.na(x))>0})
      if(sum(sel.mis)>0){
        x = which(sel.mis)
        for(k in 1:length(x)){
          if(!is.factor(m@data[,attr(x, "names")[k]])){
            if(length(grep(pattern="_p_", attr(x, "names")[k]))>0 ){ 
              repn = rep(0, nrow(m)) 
            } else {
              r = raster::raster(m[attr(x, "names")[k]])
              ## 1 using proximity filter:
              rf = raster::focal(r, w=matrix(1,15,15), fun=mean, pad=TRUE, na.rm=TRUE, NAonly=TRUE)
              repn = as(rf, "SpatialGridDataFrame")@data[m@grid.index,1]
              ## 2 using dominant value:
              repn = ifelse(is.na(repn), quantile(repn, probs=.5, na.rm=TRUE), repn)
            }
            m@data[,attr(x, "names")[k]] = ifelse(is.na(m@data[,attr(x, "names")[k]]), repn, m@data[,attr(x, "names")[k]])
          }
        }
      }
      ## Convert to PCs
      v = base::scale(m@data[,basename(tif.sel.pc)], center = scaling.c, scale = scaling.s)
      v[is.na(v)] <- 0
      v <- as.data.frame(v)
      v = predict(covs_prcomp, v[,basename(tif.sel.pc)])
      m@data = cbind(m@data["mask"], round(as.data.frame(v), 1))
      saveRDS(m, out.rds)
      gc()
    }
  }  
}

decrease_RDS_size = function(i, tile.tbl, round.number=1, out.dir="/data/tt/LandGIS/grid250m"){
  i.n <- which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.rds <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/T", tile.tbl[i.n,"ID"], ".rds")
  if(file.exists(out.rds)){
    m <- readRDS(out.rds)
    m@data <- cbind(m@data["mask"], round(m@data[,-1], round.number))
    saveRDS(m, out.rds)
    gc()
  }
}

extract_bands = function(i, tile.tbl, band.numbers=1:3, out.dir="/data/tt/LandGIS/grid250m"){
  i.n <- which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.tif <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/covs_PC", band.numbers, "_T", tile.tbl[i.n,"ID"], ".tif")
  out.rds <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/T", tile.tbl[i.n,"ID"], ".rds")
  if(any(!file.exists(out.tif))){
    m <- readRDS(out.rds)
    for(j in 1:length(band.numbers)){
      m@data[,"xx"] = m@data[band.numbers[j]+1] * 10
      writeGDAL(m["xx"], out.tif[j], type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")
    }
  }
}

check_RDS = function(i, tile.tbl, out.dir="/data/tt/LandGIS/grid250m"){
  i.n <- which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.rds <- paste0(out.dir, "/T", tile.tbl[i.n,"ID"], "/T", tile.tbl[i.n,"ID"], ".rds")
  res <- try( m <- readRDS(out.rds) )
  if(class(res) == "try-error"){
   unlink(out.rds) 
  } else {
    if(!class(m)=="SpatialPixelsDataFrame"){
      unlink(out.rds) 
    }
    stat.ov = lapply(m@data, function(i){data.frame(t(as.vector(summary(i))))})
    stat.ov = dplyr::bind_rows(stat.ov)
    names(stat.ov)[1:6] = c("min", "q1st", "median", "mean", "q3rd", "max")
    stat.ov$layer_name = names(m)
    write.csv(stat.ov, gsub(".rds",".csv",out.rds))
  }
}

## predict 6 standard dephts ----
split_predict_n <- function(i, gm, in.path="/data/tt/LandGIS/grid250m", out.path="/data/tt/LandGIS/grid250m", varn, sd=c(0, 10, 30, 60, 100, 200), method, multiplier=1, depths=TRUE, DEPTH.col="DEPTH", rds.file){
  if(method=="ranger"){
    rds.out = paste0(out.path, "/", i, "/", varn,"_", i, "_rf.rds")
  }
  if(method=="xgboost"){
    rds.out = paste0(out.path, "/", i, "/", varn,"_", i, "_xgb.rds")
  }
  if(method=="liquidSVM"){
    rds.out = paste0(out.path, "/", i, "/", varn,"_", i, "_svm.rds")
  }
  if(any(c(!file.exists(rds.out),file.size(rds.out)==0))){
    if(missing(rds.file)){ rds.file = paste0(in.path, "/", i, "/", i, ".rds") }
    if(file.exists(rds.file)&file.size(rds.file)>1e3){ 
      #gc(); gc()
      m <- readRDS(rds.file)
      if(depths==FALSE){
        x <- matrix(data=NA, nrow=nrow(m), ncol=1)
        if(method=="ranger"){
          x[,1] <- round(predict(gm, m@data, na.action=na.pass)$predictions * multiplier)
        } else {
          x[,1] <- round(predict(gm, m@data, na.action=na.pass) * multiplier)
        }
      } else {
        x <- matrix(data=NA, nrow=nrow(m), ncol=length(sd))
        for(l in 1:length(sd)){
          m@data[,DEPTH.col] = sd[l]
          if(method=="ranger"){
            require(ranger)
            v = predict(gm, m@data, na.action=na.pass)$predictions * multiplier
          }
          if(method=="xgboost"){
            require(xgboost)
            v = predict(gm, m@data[,gm$finalModel$feature_names], na.action=na.pass) * multiplier
          }
          if(method=="liquidSVM"){
            require(liquidSVM)
            v = predict(gm, m@data, T=1) * multiplier
          }
          x[,l] <- round(v)
        }
      }
      saveRDS(x, file=rds.out)
    }
  }
}

## Sum up predictions
sum_predict_ensemble <- function(i, in.path="/data/tt/LandGIS/grid250m", out.path="/data/tt/LandGIS/grid250m", varn, zmin, zmax, gm1.w, gm2.w, type="Byte", mvFlag=255, depths=TRUE, rds.file){
  if(depths==FALSE){
    out.tif = paste0(out.path, "/", i, "/", varn, "_M_", i, ".tif")
    test = !file.exists(out.tif)
  } else {
    test = !length(list.files(path = paste0(out.path, "/", i, "/"), glob2rx(paste0("^", varn, "_M_sl*_*.tif$"))))==6
  }
  if(test){
    if(missing(rds.file)){ rds.file = paste0(in.path, "/", i, "/", i, ".rds") }
    if(file.exists(rds.file)){
      m <- readRDS(rds.file)
      if(nrow(m@data)>1){
        gb = paste0(out.path, "/", i, "/", varn,"_", i, "_xgb.rds")
        rf.ls = paste0(out.path, "/", i, "/", varn,"_", i, "_rf.rds")
        #svm = paste0(out.path, "/", i, "/", varn,"_", i, "_svm.rds")
        #if(all(file.exists(c(rf.ls,gb,svm)))){
        if(all(file.exists(c(rf.ls,gb)))){
          ## import all predictions:
          v1 <- readRDS(rf.ls)
          v2 <- readRDS(gb)
          #v3 <- readRDS(svm)
          ## weighted average:
          #m@data <- data.frame(Reduce("+", list(v1*gm1.w, v2*gm2.w, v3*gm3.w)) / (gm1.w+gm2.w+gm3.w))
          m@data <- data.frame(Reduce("+", list(v1*gm1.w, v2*gm2.w)) / (gm1.w+gm2.w))
          if(depths==FALSE){
            ## Write GeoTiffs (2D case):
            m@data[,1] <- ifelse(m@data[,1] < zmin, zmin, ifelse(m@data[,1] > zmax, zmax, m@data[,1]))
            writeGDAL(m[1], out.tif, type=type, mvFlag=mvFlag, options="COMPRESS=DEFLATE")
          } else {
            ## Write GeoTiffs (per depth):
            for(l in 1:ncol(m)){
              out.tif = paste0(out.path, "/", i, "/", varn, "_M_sl", l, "_", i, ".tif")
              m@data[,l] <- ifelse(m@data[,l] < zmin, zmin, ifelse(m@data[,l] > zmax, zmax, m@data[,l]))
              writeGDAL(m[l], out.tif, type=type, mvFlag=mvFlag, options="COMPRESS=DEFLATE")
              #m@data[,"sd"] <- matrixStats::rowSds(cbind(v1[,l], v2[,l], v3[,l]), na.rm=TRUE) ## use weighted sd?
              m@data[,"sd"] <- matrixStats::rowSds(cbind(v1[,l], v2[,l]), na.rm=TRUE)
              writeGDAL(m["sd"], gsub("_M_", "_sd_", out.tif), type=type, mvFlag=mvFlag, options="COMPRESS=DEFLATE")
            }
          }
          ## cleanup:
          unlink(rf.ls) 
          unlink(gb)
          #unlink(svm)
          #gc(); gc()
        }
      }
    }
  }
}

## textures ----
normalize_texture <- function(in.lst, n.lst=c("sand_tot_psa","silt_tot_psa","clay_tot_psa")){
  tex.lst <- sapply(n.lst, function(x){gsub(pattern="sand_tot_psa", replacement=x, in.lst)})
  if(file.exists(tex.lst[1])){
    x = readGDAL(tex.lst[1])
    x@data[,2] <- readGDAL(tex.lst[2])$band1
    x@data[,3] <- readGDAL(tex.lst[3])$band1
    names(x) <- n.lst
    sums <- rowSums(x@data)
    xr = range(sums, na.rm=TRUE)
    if(xr[1]<99|xr[2]>101){
      x$silt_tot_psa <- round(x$silt_tot_psa / sums * 100, 0)
      x$sand_tot_psa <- round(x$sand_tot_psa / sums * 100, 0)
      x$clay_tot_psa <- round(x$clay_tot_psa / sums * 100, 0)
      unlink(tex.lst[1]); unlink(tex.lst[2]); unlink(tex.lst[3])
      writeGDAL(x[n.lst[1]], tex.lst[1], "GTiFF", mvFlag=255, type="Byte", options="COMPRESS=DEFLATE")
      writeGDAL(x[n.lst[2]], tex.lst[2], "GTiFF", mvFlag=255, type="Byte", options="COMPRESS=DEFLATE")
      writeGDAL(x[n.lst[3]], tex.lst[3], "GTiFF", mvFlag=255, type="Byte", options="COMPRESS=DEFLATE")
      gc()
    }
  }
}

## soil carbon ----
## machine learning misses training points in deserts hence artifacts
## function to remove artifacts based on land cover / FAPAR map
normalize_carbon = function(i, tile.tbl, in.tif, tif.mask="/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif", lcv.tif="/data/LandGIS/layers250m/lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_2000_v1.0.tif", fap.tif="/data/LandGIS/layers250m/veg_fapar_proba.v.annual_d_250m_s0..0cm_2014..2017_v1.0.tif", out.path="/data/tt/LandGIS/grid250m"){
  i.n = which(tile.tbl$ID == strsplit(i, "T")[[1]][2])
  out.tif = paste0(out.path, "/", i, "/oc.f_M_sl", 1:6, "_", i,".tif")
  m = readGDAL(fname=tif.mask, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
  m$band2 = readGDAL(fname=fap.tif, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
  m$band3 = readGDAL(fname=lcv.tif, offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
  sel.p <- m$band1==1|m$band1==3
  ## land cover class bare land or FAPAR close to 0
  sel.rm <- (m$band3 == 200 | m$band3 == 220 | (m$band2 < 3 & !is.na(m$band2))) & sel.p
  if(sum(sel.rm)>0){
    for(j in 1:length(out.tif)){
      m@data[,paste0("mask",j)] = readGDAL(fname=in.tif[j], offset=unlist(tile.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
      m@data[which(sel.rm),paste0("mask",j)] <- 0 
      m@data[which(!sel.p),paste0("mask",j)] <- NA
      writeGDAL(m[paste0("mask",j)], out.tif[j], type="Byte", mvFlag=255, options="COMPRESS=DEFLATE")
    }
    gc()
  }
}

## texture class ----
frac2TEX <- function(x){
  require(soiltexture)
  TT <- soiltexture::TT.points.in.classes(tri.data=x, class.sys="USDA.TT", PiC.type="t", tri.sum.tst=FALSE)
  ## filter transitional classes:
  no.TT <- sapply(TT, function(x){length(strsplit(x, ",")[[1]])})
  sel.TT <- which(no.TT > 1)
  TEX <- TT
  ## replace transitional classes with a random class:
  for(i in sel.TT){
    TEX[[i]] <- trim(strsplit(TT[i], ",")[[1]][ceiling(runif(1)*no.TT[i])])
  }
  return(TEX)
}

predictTEXclass <- function(i, in.path, depths=1:6, tex.c){
  for(d in depths){
    outn <- paste0(in.path, "/", i, "/texture.class_M_sl", d, "_", i, ".tif")
    if(!file.exists(outn)){
      tex.tif.lst <- paste0(in.path, "/", i, "/", c("sand_tot_psa","silt_tot_psa","clay_tot_psa"), "_M_sl", d, "_", i, ".tif")
      if(all(file.exists(tex.tif.lst))){
        try( x <- rgdal::readGDAL(tex.tif.lst[1]) )
        if(!class(.Last.value)[1]=="try-error"){
          if(sum(!is.na(x$band1))>4){
            x$band2 <- rgdal::readGDAL(tex.tif.lst[2])$band1
            x$band3 <- rgdal::readGDAL(tex.tif.lst[3])$band1
            try( x0 <- as(x, "SpatialPixelsDataFrame"), silent=TRUE )
            if(!class(.Last.value)[1]=="try-error"&exists("x0")){
              names(x0@data) <- c("SAND", "SILT","CLAY")
              sel <- complete.cases(x0@data)
              if(length(sel)>2){
                x0 <- x0[sel,]
                tex.i <- frac2TEX(x0@data)  
                tex.i <- as.vector(unlist(tex.i))
                ## convert to integers:
                x0$TEX_M <- plyr::join(data.frame(class.n=tex.i), tex.c, type="left", match="first")$class.i
                rgdal::writeGDAL(x0["TEX_M"], outn, mvFlag=255, type="Byte", options="COMPRESS=DEFLATE")
              }
            } else {
              return(i)
            }
          }
        } else {
          return(i)
        }
      }
    }
  }
}

## organic carbon stock ----
## (six standard layers) corrected for depth to bedrock:
carbon_stock <- function(i, n.lst=c("oc.f","db_od","wpg2"), ORCDRC.sd=20, BLD.sd=100, CRFVOL.sd=5, sdepth = c(0, 10, 30, 60, 100, 200), out.path="/data/tt/LandGIS/grid250m"){
  ## five standard layers 0-10, 10-30, 30-60, 60-100, 100-200:
  out.all <- paste0(out.path, "/", i, "/ocs_M_sh", 1:5, "_", i,".tif")
  if(any(!file.exists(out.all))){
    for(d in 1:5){
      Utif.lst <- paste0(out.path, "/", i, "/", n.lst, "_M_sl", d, "_", i, ".tif")
      Ltif.lst <- paste0(out.path, "/", i, "/", n.lst, "_M_sl", d+1, "_", i, ".tif")
      s <- raster::stack(c(Utif.lst,Ltif.lst))
      s <- as(as(s, "SpatialGridDataFrame"), "SpatialPixelsDataFrame")
      s$ORCDRC <- rowMeans(s@data[,grep("oc.f", names(s))], na.rm = TRUE)/2
      ## division by 2 to get percent because values are in 5 g / kg:
      s$BLD <- rowMeans(s@data[,grep("db_od", names(s))], na.rm = TRUE)
      s$CRFVOL <- rowMeans(s@data[,grep("wpg2", names(s))], na.rm = TRUE)
      ## Predict organic carbon stock (in kg / m2):
      s$v <- round(as.vector(GSIF::OCSKGM(ORCDRC=s$ORCDRC*10, BLD=s$BLD*10, CRFVOL=s$CRFVOL, HSIZE=(sdepth[d+1]-sdepth[d]), ORCDRC.sd=ORCDRC.sd, BLD.sd=BLD.sd, CRFVOL.sd=CRFVOL.sd)))
      writeGDAL(s["v"], out.all[d], type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")
      gc()
    }
  }
}

## Available water capacity ----
## p.197 in https://www.nrcs.usda.gov/wps/portal/nrcs/detail/soils/ref/?cid=nrcs142p2_054247
awc_tile = function(i, n.lst=c("w3cld","w15l2","db_od","wpg2"), db.h2o=1, out.path="/data/tt/LandGIS/grid250m", volume.pct=TRUE, d.s=c(100, 200, 300, 400, 1000)){
  ## five standard layers 0-10, 10-30, 30-60, 60-100, 100-200:
  out.all <- paste0(out.path, "/", i, "/awc_M_sh", 1:5, "_", i,".tif")
  out.tv <- paste0(out.path, "/", i, "/awc_M_tot_", i,".tif")
  if(any(!file.exists(out.all))){
    v = list(NULL)
    for(d in 1:5){
      Utif.lst <- paste0(out.path, "/", i, "/", n.lst, "_M_sl", d, "_", i, ".tif")
      Ltif.lst <- paste0(out.path, "/", i, "/", n.lst, "_M_sl", d+1, "_", i, ".tif")
      s <- raster::stack(c(Utif.lst,Ltif.lst))
      s <- as(as(s, "SpatialGridDataFrame"), "SpatialPixelsDataFrame")
      s$AW1 <- rowMeans(s@data[,grep("w3cld", names(s))], na.rm = TRUE)
      s$AW2 <- rowMeans(s@data[,grep("w15l2", names(s))], na.rm = TRUE)
      s$BLD <- rowMeans(s@data[,grep("db_od", names(s))], na.rm = TRUE)
      s$CRFVOL <- rowMeans(s@data[,grep("wpg2", names(s))], na.rm = TRUE)
      ## Water Retention Difference in %:
      if(volume.pct==TRUE){
        xx <- (s$AW1-s$AW2) * (100-s$CRFVOL)/100 * db.h2o * d.s[d]/100
      } else {
        xx <- (s$AW1-s$AW2) * s$BLD/100 * (100-s$CRFVOL)/100 * db.h2o * d.s[d]/100
      }
      v[[d]] <- round(ifelse(xx<0, 0, xx))
      s$v <- v[[d]]
      writeGDAL(s["v"], out.all[d], type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")
      gc()
    }
    ## Total available water capacity in mm:
    #s$tv = rowSums( data.frame(mapply(`*`, as.data.frame(v)/100, )), na.rm = TRUE )
    s$tv = rowSums( as.data.frame(v), na.rm = TRUE )
    writeGDAL(s["tv"], out.tv, type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")
  }
}

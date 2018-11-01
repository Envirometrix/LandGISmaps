## DEM processing functions
## tom.hengl@gmail.com

sdat2geotif <- function(x, imin, imax, omin, omax, ot="Int16", mv=-32768){
  if(!file.exists(gsub(".sdat", ".tif", x))){
    if(length(grep(pattern = "cprof", x))>0){
      imin = -0.01; imax = 0.01; omin = -1000; omax = 1000
    }
    if(length(grep(pattern = "devmean", x))>0){
      imin = -15; imax = 15; omin = -1500; omax = 1500
    }
    if(length(grep(pattern = "down", x))>0){
      imin = -50; imax = 50; omin = -5000; omax = 5000
    }
    if(length(grep(pattern = "uplocal", x))>0){
      imin = -50; imax = 50; omin = -5000; omax = 5000
    }
    if(length(grep(pattern = "vbf", x))>0){
      imin = 0; imax = 10; omin = 0; omax = 1000
    }
    if(length(grep(pattern = "mrn", x))>0){
      imin = 0; imax = 50; omin = 0; omax = 500
    }
    if(length(grep(pattern = "open", x))>0){
      imin = 0; imax = 10; omin = 0; omax = 1000
    }
    if(length(grep(pattern = "slope", x))>0){
      imin = 0; imax = 1; omin = 0; omax = 100
    }
    if(length(grep(pattern = "tpi", x))>0){
      imin = -100; imax = 100; omin = -1000; omax = 1000
    }
    if(length(grep(pattern = "twi", x))>0){
      imin = 0; imax = 500; omin = 0; omax = 5000
    }
    if(length(grep(pattern = "catchm", x))>0){
      ot = "Int32"
    }
    if(missing(omin)){
      system(paste0('gdal_translate ', x, ' ', gsub(".sdat", ".tif", x), ' -co \"COMPRESS=DEFLATE\" -ot \"', ot, '\"'))
    } else {
      system(paste0('gdal_translate ', x, ' ', gsub(".sdat", ".tif", x), ' -co \"COMPRESS=DEFLATE\" -scale ', imin, ' ', imax, ' ', omin, ' ', omax, ' -ot \"', ot, '\" -a_nodata \"', mv, '\"'))
    }
  }
}

tile.tif <- function(x, t, out.dir="/data/MDEM/stiled100m/", tr=100, resample="bilinear"){
  t_srs = proj4string(t)
  library(snowfall)  
  sfInit(parallel=TRUE, cpus=24)
  sfLibrary(sp)
  sfExport("x", "t", "out.dir", "tr", "resample", "t_srs")
  x <- sfLapply(1:nrow(t), function(j){ if(!file.exists(paste0(out.dir, "DEM_", strsplit(paste(t@data[j,"SHORTNAME"]), " ")[[1]][2], "_", t@data[j,"TILE"], ".tif"))) { system(paste0('gdalwarp ', x, ' ', paste0(out.dir, "DEM_", strsplit(paste(t@data[j,"SHORTNAME"]), " ")[[1]][2], "_", t@data[j,"TILE"], ".tif"), ' -t_srs \"', t_srs, '\" -tr ', tr, ' ', tr, ' -r \"', resample, '\" -te ', paste(as.vector(bbox(t[j,])), collapse=" "), ' -ot \"Int16\" -co \"COMPRESS=DEFLATE\"')) } })
  sfStop()
}

## Derive some standard DEM variables of interest for soil mapping:
saga_DEM_derivatives <- function(INPUT, MASK=NULL, sel=c("SLP","CPR","TWI","CRV","VBF","VDP","OPN","DVM","MRN","TPI"), RADIUS=c(9,13), cpus=24){
  if(pkgmaker::file_extension(INPUT)=="tif"){ 
    system(paste0('gdal_translate ', INPUT, ' ', gsub(".tif", ".sdat", INPUT), ' -of \"SAGA\" -ot \"Int16\"'))
    INPUT = gsub(".tif", ".sgrd", INPUT)
  }
  if(!is.null(MASK)){
    ## Fill in missing DEM pixels:
    suppressWarnings( system(paste0('saga_cmd -c=', cpus,' grid_tools 25 -GRID=\"', INPUT, '\" -MASK=\"', MASK, '\" -CLOSED=\"', INPUT, '\"')) )
  }
  ## Uplslope curvature:
  if(any(sel %in% "CRV")){
    if(!file.exists(gsub(".sgrd", "_downlocal.sgrd", INPUT))){
      try( suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_morphometry 26 -DEM=\"', INPUT, '\" -C_DOWN_LOCAL=\"', gsub(".sgrd", "_downlocal.sgrd", INPUT), '\" -C_UP_LOCAL=\"', gsub(".sgrd", "_uplocal.sgrd", INPUT), '\" -C_UP=\"tmp.sgrd\" -C_LOCAL=\"tmp.sgrd\" -C_DOWN=\"', gsub(".sgrd", "_down.sgrd", INPUT), '\"') ) ) )
    }
  }
  ## Slope:
  if(any(sel %in% "SLP")){
    if(!file.exists(gsub(".sgrd", "_slope.sgrd", INPUT))){
      try( suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_morphometry 0 -ELEVATION=\"', INPUT, '\" -SLOPE=\"', gsub(".sgrd", "_slope.sgrd", INPUT), '\"') ) ) )
    }
  }
  ## CProf:
  if(any(sel %in% "CPR")){
    if(!file.exists(gsub(".sgrd", "_cprof.sgrd", INPUT))){
      try( suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_morphometry 0 -ELEVATION=\"', INPUT, '\" -C_PROF=\"', gsub(".sgrd", "_cprof.sgrd", INPUT), '\"') ) ) )
    }
  }
  ## MrVBF:
  if(any(sel %in% "VBF")){
    if(!file.exists(gsub(".sgrd", "_vbf.sgrd", INPUT))){
      try( suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_morphometry 8 -DEM=\"', INPUT, '\" -MRVBF=\"', gsub(".sgrd", "_vbf.sgrd", INPUT), '\" -T_SLOPE=10 -P_SLOPE=3') ) ) )
    }
  }
  ## Valley depth:
  if(any(sel %in% "VDP")){
    if(!file.exists(gsub(".sgrd", "_vdepth.sgrd", INPUT))){
      try( suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_channels 7 -ELEVATION=\"', INPUT, '\" -VALLEY_DEPTH=\"', gsub(".sgrd", "_vdepth.sgrd", INPUT), '\"') ) ) )
    }
  }
  ## Openess:
  if(any(sel %in% "OPN")){
    if(!file.exists(gsub(".sgrd", "_openp.sgrd", INPUT))){
      try( suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_lighting 5 -DEM=\"', INPUT, '\" -POS=\"', gsub(".sgrd", "_openp.sgrd", INPUT), '\" -NEG=\"', gsub(".sgrd", "_openn.sgrd", INPUT), '\" -METHOD=0' ) ) ) )
    }
  }
  ## Deviation from Mean Value:
  if(any(sel %in% "DVM")){
    if(!file.exists(gsub(".sgrd", "_devmean.sgrd", INPUT))){
      suppressWarnings( system(paste0('saga_cmd -c=', cpus,' statistics_grid 1 -GRID=\"', INPUT, '\" -DEVMEAN=\"', gsub(".sgrd", "_devmean.sgrd", INPUT), '\" -RADIUS=', RADIUS[1] ) ) )
    }
    if(!file.exists(gsub(".sgrd", "_devmean2.sgrd", INPUT))){
      suppressWarnings( system(paste0('saga_cmd -c=', cpus,' statistics_grid 1 -GRID=\"', INPUT, '\" -DEVMEAN=\"', gsub(".sgrd", "_devmean2.sgrd", INPUT), '\" -RADIUS=', RADIUS[2] ) ) )
    }
  }
  ## TWI:
  if(any(sel %in% "TWI")){
    if(!file.exists(gsub(".sgrd", "_twi.sgrd", INPUT))){
      try( suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_hydrology 15 -DEM=\"', INPUT, '\" -SLOPE_MIN=0.04 -SLOPE_OFF=0.3 -AREA_MOD=\"', gsub(".sgrd", "_catchm.sgrd", INPUT), '\" -SLOPE_TYPE=0 -TWI=\"', gsub(".sgrd", "_twi.sgrd", INPUT), '\"') ) ) )
    }
  }
  ## Melton Ruggedness Number:
  if(any(sel %in% "MRN")){
    if(!file.exists(gsub(".sgrd", "_mrn.sgrd", INPUT))){
      suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_hydrology 23 -DEM=\"', INPUT, '\" -AREA=\"tmp.sgrd\" -MRN=\"', gsub(".sgrd", "_mrn.sgrd", INPUT), '\" -ZMAX=\"tmp.sgrd\"' ) ) )
    }
  }
  ## TPI:
  if(any(sel %in% "TPI")){
    if(!file.exists(gsub(".sgrd", "_tpi.sgrd", INPUT))){
      suppressWarnings( system(paste0('saga_cmd -c=', cpus,' ta_morphometry 18 -DEM=\"', INPUT, '\" -STANDARD=1 -TPI=\"', gsub(".sgrd", "_tpi.sgrd", INPUT), '\" -RADIUS_MIN=0 -RADIUS_MAX=2000 -DW_WEIGHTING=3 -DW_BANDWIDTH=75' ) ) )
    }
  }
}

## Functions for mosaicking EQUI7 grid system (https://github.com/TUW-GEO/Equi7Grid) to longlat system
tiles_equi7t3 <- function(i, j, varn, in.path, r, te, tr, ot, dstnodata, out.path, compress, vrt.tmp){
  if(i=="dominant"){
    out.tif <- paste0(out.path, "/", j, '/', varn, '_', j, '_250m_r.tif')
  } else {
    out.tif <- paste0(out.path, "/", j, '/', varn, '_', i, '_', j, '_250m_r.tif')
  }
  if(!file.exists(out.tif)){
    if(is.null(vrt.tmp)){
      if(i=="dominant"){
        tmp.lst <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_", j, "_*_*.tif$")), full.names=TRUE, recursive=TRUE)
      } else {
        tmp.lst <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_", i, "_", j, "_*_*.tif$")), full.names=TRUE, recursive=TRUE)
      }
      if(length(tmp.lst)>0){
        out.tmp <- tempfile(fileext = ".txt")
        vrt.tmp <- tempfile(fileext = ".vrt")
        cat(tmp.lst, sep="\n", file=out.tmp)
        system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
      } else {
        stop("Empty list")
      }
    }
    ## Two extra tiles for >180 degrees:
    if(j=="AS"){
      system(paste0('gdalwarp ', vrt.tmp, ' ', gsub("/AS/", "/chukotka/", out.tif), ' -t_srs \"+proj=longlat +datum=WGS84\" -overwrite -r \"', r,'\" -ot \"', ot, '\" -dstnodata \"',  dstnodata, '\" -te -180 54 -168.3 83.3 -tr ', tr, ' ', tr, ' -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -wm 2000')) ## chukotka
    }
    if(j=="OC"){
      system(paste0('gdalwarp ', vrt.tmp, ' ', gsub("/OC/", "/pacific/", out.tif), ' -t_srs \"+proj=longlat +datum=WGS84\" -overwrite -r \"', r,'\" -ot \"', ot, '\" -dstnodata \"',  dstnodata, '\" -te -180 -62 -120 15 -tr ', tr, ' ', tr, ' -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -wm 2000')) ## Pacific islands
    }
    if(compress==TRUE){
      system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -t_srs \"+proj=longlat +datum=WGS84\" -overwrite -r \"', r,'\" -ot \"', ot, '\" -dstnodata \"',  dstnodata, '\" -te ', paste(te, collapse=" "),' -tr ', tr, ' ', tr, ' -co \"BIGTIFF=YES\" -wm 2000 -co \"COMPRESS=DEFLATE\"')) ## <-- compression takes MORE time. Maybe not necessary to generate temp files?
    } else {
      system(paste0('gdalwarp ', vrt.tmp, ' ', out.tif, ' -t_srs \"+proj=longlat +datum=WGS84\" -overwrite -r \"', r,'\" -ot \"', ot, '\" -dstnodata \"',  dstnodata, '\" -te ', paste(te, collapse=" "),' -tr ', tr, ' ', tr, ' -co \"BIGTIFF=YES\" -wm 2000'))
    }
  }
}

## Merge everything into a single mosaick
mosaick_equi7 <- function(i, varn, ext.lst, resample1="bilinear", resample2="average", r250m=TRUE, tr=0.002083333, in.path="./", ot="Byte", dstnodata=255, tile.names, out.path, compress=TRUE, build.pyramids=TRUE, vrt.tmp=NULL, cleanup=TRUE, te){
  if(i=="dominant"){
    out.tif <- paste0(in.path, "/", varn, "_250m_ll.tif")
    r = "near"
  } else {
    out.tif <- paste0(in.path, "/", varn, "_", i, "_250m_ll.tif")
  }
  if(!file.exists(out.tif)){
    ## build mosaics per continent:
    if(is.null(vrt.tmp)){ 
      x <- sapply(1:length(ext.lst), function(x){ tiles_equi7t3(j=tile.names[x], i=i, varn=varn, te=ext.lst[[x]], tr=tr, r=resample1, in.path=in.path, ot=ot, dstnodata=dstnodata, compress=compress, out.path=out.path) })
    } else {
      x <- sapply(1:length(ext.lst), function(x){ tiles_equi7t3(j=tile.names[x], i=i, varn=varn, te=ext.lst[[x]], tr=tr, r=resample1, ot=ot, dstnodata=dstnodata, compress=compress, out.path=out.path, vrt.tmp=vrt.tmp[x]) })
    }
    if(i=="dominant"){
      in.tif <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_*_250m_r.tif$")), full.names=TRUE, recursive=TRUE)
    } else {
      in.tif <- list.files(path=in.path, pattern=glob2rx(paste0(varn, "_", i, "_*_250m_r.tif$")), full.names=TRUE, recursive=TRUE)
    }
    if(length(in.tif)>0){
      outG.tmp <- tempfile(fileext = ".txt")
      vrtG.tmp <- tempfile(fileext = ".vrt")
      ## sort based on priority? 
      sort.lst = lapply(c("AN","chukotka","pacific","AS","OC","SA","AF","EU","NA"), function(x){grep(x, in.tif)})
      sort.lst = unlist(sort.lst[sapply(sort.lst, function(x){length(x)>0})])
      cat(unique(in.tif[sort.lst]), sep="\n", file=outG.tmp)
      system(paste0('gdalbuildvrt -input_file_list ', outG.tmp, ' ', vrtG.tmp, ' -srcnodata ', dstnodata))
      if(r250m == TRUE){
        if(build.pyramids==TRUE){
          system(paste0('gdalwarp ', vrtG.tmp, ' ', out.tif, ' -ot \"', ot, '\" -dstnodata \"', dstnodata, '\" -overwrite -r \"', resample1, '\" -co \"COMPRESS=DEFLATE\" -co \"TILED=YES\" -co \"BLOCKXSIZE=512\" -co \"BLOCKYSIZE=512\" -wm 2000 -co \"BIGTIFF=YES\" -te ', te))
          system(paste0('gdaladdo ', out.tif, ' 2 4 8 16 32 64 128'))
        } else {
          system(paste0('gdalwarp ', vrtG.tmp, ' ', out.tif, ' -ot \"', ot, '\" -dstnodata \"', dstnodata, '\" -overwrite -r \"', resample1, '\" -co \"COMPRESS=DEFLATE\" -wm 2000 -co \"BIGTIFF=YES\" -te ', te))
        }
      }
      ## gdal_translate relatively faster?
      system(paste0('gdalwarp -r \"', resample2,'\" -tr 0.008333333 0.008333333 ', vrtG.tmp, ' ', gsub("250m_ll.tif", "1km_ll.tif", out.tif), ' -ot \"', ot, '\" -dstnodata \"', dstnodata, '\" -co \"COMPRESS=DEFLATE\" -co \"BIGTIFF=YES\" -te ', te))
      if(cleanup==TRUE){
        unlink(outG.tmp)
        unlink(vrtG.tmp)
        unlink(in.tif)
      }
    }
  }
}

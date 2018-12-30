## Functions to prepare global SOC time series data
## ichsani@envirometrix.net / Tom.Hengl@envirometrix.net

summary_LC_CLIM_tiles <- function(i, tileS.tbl, cl.leg, lc="ESACCI-LC-L4-LCCS-Map-300m-P1Y-2000-v2.0.7_sin.tif", ocs="OCSTHA_M_30cm_300m_sin.tif", cl="EF_Bio_Des_300m_sin.tif"){
  m = readGDAL(fname=lc, offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
  m@data[,2] = readGDAL(fname=ocs, offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
  m@data[,3] = plyr::join(data.frame(number=readGDAL(fname=cl, offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1), cl.leg)$number_agg
  names(m) = c("LCCOwnLabel","OCS","number_agg")
  if(sum(!is.na(m$OCS))>0){
    ## Aggregate per class combination
    SOC_agg.LCCL <- plyr::ddply(m@data, .(LCCOwnLabel,number_agg), summarize, Mean_OCS=mean(OCS, na.rm=TRUE), SD_OCS=sd(OCS, na.rm=TRUE), N_OCS_2010=sum(!is.na(OCS)))
    SOC_agg.LCCL <- SOC_agg.LCCL[!is.na(SOC_agg.LCCL$SD_OCS)&!is.nan(SOC_agg.LCCL$SD_OCS),]
    return(SOC_agg.LCCL)
  }
}

make_LC_tiles <- function(i, tile.tbl, in.path="/data/LDN", out.path="/data/tt/LDN/tiled", lc1="/data/ESA_global/ESACCI-LC-L4-LCCS-Map-300m-P5Y-2000-v1.6.1.tif", lc2="/data/ESA_global/ESACCI-LC-L4-LCCS-Map-300m-P5Y-2010-v1.6.1.tif", cl="EF_Bio_Des_300m.tif", cl.leg, comb.leg){
  out.tif = paste0(out.path, "/T", tile.tbl[i,"ID"], "/LandCover_CL_T", tile.tbl[i,"ID"], ".tif")
  if(!file.exists(out.tif)){
    m = readGDAL(fname=lc1, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
    m@data[,2] = readGDAL(fname=lc2, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    m@data[,3] = readGDAL(fname=cl, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    names(m) = c("LC2000","LC2010","BIOCL")
    m = as(m, "SpatialPixelsDataFrame")
    ## Focus only on pixels that show land cover change
    sel = !m$LC2000==m$LC2010
    if(sum(sel)>0){
      m = m[sel,]
      m$BIOCL_f = plyr::join(data.frame(number=m$BIOCL), cl.leg, type="left")$number_agg
      m$v = paste(m$LC2000, m$LC2010, m$BIOCL_f, sep="_")
      m$i = plyr::join(data.frame(NAME=m$v), comb.leg, type="left")$Value
      writeGDAL(m["i"], out.tif, type="Int16", options="COMPRESS=DEFLATE", mvFlag = -32768)
    }
  }
}

summary_GAUL_tiles <- function(i, tile.tbl, out.path="/data/tt/LDN/tiled", cnt="/data/LDN/GAUL_COUNTRIES_300m_ll.tif", countries){
  out.file = paste0(out.path, "/T", tile.tbl[i,"ID"], "/GAUL_T", tile.tbl[i,"ID"], ".tif")
  m = readGDAL(fname=cnt, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
  m$band1 = ifelse(m$band1<0, NA, m$band1)
  if(sum(is.na(m$band1))<nrow(m)){
    m$GAUL_COUNTRY = factor(m$band1, levels=as.character(sort(unique(countries$Value))), labels=countries$NAMES[order(countries$Value)])
    out = summary(m$GAUL_COUNTRY[!is.na(m$GAUL_COUNTRY)], maxsum = nrow(countries))
    out = data.frame(Value=attr(out, "names"), Count=as.numeric(out))
    out = out[out$Count>0,]
    out$ID = i
    if(!file.exists(out.file)){
      writeGDAL(m[1], out.file, type="Int16", options="COMPRESS=DEFLATE", mvFlag = -32768)
    }
    return(out)
  }
}

summary_LC_tiles <- function(i, tile.tbl, out.path="/data/tt/LDN/tiled", comb.leg){
  in.file = paste0(out.path, "/T", tile.tbl[i,"ID"], "/LandCover_CL_T", tile.tbl[i,"ID"], ".tif")
  if(file.exists(in.file)){
    m = factor(readGDAL(in.file)$band1, levels=as.character(comb.leg$Value))
    flevs = levels(m)
    out = summary(m, maxsum = length(flevs))
    out = data.frame(Value=attr(out, "names"), Count=unclass(out))
    out = out[out$Count>0,]
    if(nrow(out)>0){
      return(out)
    }
  }
}

join_LC_factor <- function(i, tile.tbl, out.path="/data/tt/LDN/tiled", summary_LC.df_f, column.name=c("OCS_CF_FactorLandUse_2010","OCS_CF_FactorInput_2010")){
  in.file = paste0(out.path, "/T", tile.tbl[i,"ID"], "/LandCover_CL_T", tile.tbl[i,"ID"], ".tif")
  out.file = paste0(out.path, "/T", tile.tbl[i,"ID"], "/", column.name, "_T", tile.tbl[i,"ID"], ".tif")
  if(any(!file.exists(out.file))&file.exists(in.file)){
    m = readGDAL(in.file)
    m$i = plyr::join(data.frame(Value=m$band1), summary_LC.df_f[,c("Value", column.name[1])], type="left")[,column.name[1]]*100
    m$b = plyr::join(data.frame(Value=m$band1), summary_LC.df_f[,c("Value", column.name[2])], type="left")[,column.name[2]]*100
    writeGDAL(m["i"], out.file[1], type="Int16", options="COMPRESS=DEFLATE", mvFlag = -32768)
    writeGDAL(m["b"], out.file[2], type="Int16", options="COMPRESS=DEFLATE", mvFlag = -32768)
  }
}

## Derive OCS loss based on the SoilGrids and LC factor of change:
OCS_loss_LC_factor <- function(i, tile.tbl, out.path="/data/tt/LDN/tiled", OCS.tif="OCSTHA_0_30cm_300m_ll.tif", t1=2000, t2=2010, dt=20){
  in.file = paste0(out.path, "/T", tile.tbl[i,"ID"], "/OCS_CF_FactorLandUse_2010_T", tile.tbl[i,"ID"], ".tif")
  in.file2 = paste0(out.path, "/T", tile.tbl[i,"ID"], "/OCS_CF_FactorInput_2010_T", tile.tbl[i,"ID"], ".tif")
  out.file = paste0(out.path, "/T", tile.tbl[i,"ID"], "/OCS_change_FactorLandUse_2010_T", tile.tbl[i,"ID"], ".tif")
  if(!file.exists(out.file)&file.exists(in.file)){
    m = readGDAL(in.file, silent = TRUE)
    names(m) = "CFL"
    m$CFI = readGDAL(in.file2, silent = TRUE)$band1
    m$OCS = readGDAL(fname=OCS.tif, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    m$dOCS = m$OCS*((m$CFL-100)*(t2-t1)/dt)/100 + m$OCS*((m$CFI-100)*(t2-t1)/dt)/100
    #plot(raster(m["dOCS"]), col=SAGA_pal[[1]])
    writeGDAL(m["dOCS"], out.file, type="Int16", options="COMPRESS=DEFLATE", mvFlag = -32768)
  }
}

## Reclassify Land cover maps to 6 classes:
reclassify_LC_tiles <- function(i, tile.tbl, in.path="/data/LDN", out.path="/data/tt/LDN/tiled", lc1="/home/tom/data/LDN/300m_ll/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2015-v2.0.7_ll.tif", lc2="/home/tom/data/LDN/300m_ll/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2000-v2.0.7_ll.tif", lcA.leg){
  out.tif = paste0(out.path, "/T", tile.tbl[i,"ID"], "/ESACCI_LC_", c(2000,2015), "_T", tile.tbl[i,"ID"], ".tif")
  if(any(!file.exists(out.tif))){
    m = readGDAL(fname=lc1, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
    m@data[,2] = readGDAL(fname=lc2, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    names(m) = c("LC2000","LC2010")
    m = as(m, "SpatialPixelsDataFrame")
    m$LC2000_AGG = plyr::join(data.frame(Value=m$LC2000), lcA.leg, type="left")$Value_AGG_w
    m$LC2010_AGG = plyr::join(data.frame(Value=m$LC2010), lcA.leg, type="left")$Value_AGG_w
    writeGDAL(m["LC2000_AGG"], out.tif[1], type="Byte", mvFlag=0, options="COMPRESS=DEFLATE")
    writeGDAL(m["LC2010_AGG"], out.tif[2], type="Byte", mvFlag=0, options="COMPRESS=DEFLATE")
  }
}

## Reclassify Land cover maps to 6 classes:
reclassify_OCS_tiles <- function(i, tile.tbl, in.path="/data/LDN", out.path="/data/tt/LDN/tiled", lc="/data/LDN/300m_ll/ESACCI-LC-L4-LCCS-Map-300m-P1Y-2015-v2.0.7_ll.tif", lcA.leg, OCS.tif="/data/LDN/300m_ll/OCS2015_300m_ll.tif", ocs.breaks=c(0.0001,50,110,200,1000), LC_OCS.leg){
  out.tif = paste0(out.path, "/T", tile.tbl[i,"ID"], "/LC_OCS_2015_T", tile.tbl[i,"ID"], ".tif")
  if(any(!file.exists(out.tif))){
    m = readGDAL(fname=lc, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
    names(m) = "LC2015"
    m = as(m, "SpatialPixelsDataFrame")
    m = m[!m$LC2015 == 210 & !m$LC2015 == 0,]
    m$OCS = readGDAL(fname=OCS.tif, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1[m@grid.index]
    m$LC2015_AGG = plyr::join(data.frame(Value=m$LC2015), lcA.leg, type="left")$AGG_NAME
    m$LC_OCS = factor(paste(m$LC2015_AGG, as.character(cut(m$OCS, ocs.breaks, labels=c("low", "moderate", "high", "organic"))), sep=" / "), levels=LC_OCS.leg)
    m$LC_OCS.int = as.integer(m$LC_OCS) 
    writeGDAL(m["LC_OCS.int"], out.tif, type="Byte", mvFlag=0, options="COMPRESS=DEFLATE")
  }
}

summary_OCS_change_tiles <- function(i, tileS.tbl, out.path="/data/tt/LDN/Stiled", lcs1="ESACCI_LC_2000_300m_sin.tif", lcs2="ESACCI_LC_2010_300m_sin.tif", sg1="OCSTHA_0_30cm_300m_sin.tif", cf="OCS_change_FactorLandUse_2010_300m_sin.tif", wsd="hydrobasins_FAO_300m_sin.tif", lpd="LPD_1999_2013_300m_sin.tif", cnt="GAUL_COUNTRIES_300m_sin.tif", lc.leg, lpd.leg, hb.leg, countries, AREA = (300*300)/1e4){
  out.csv = paste0(out.path, "/T", tileS.tbl[i,"ID"], "/OCS_agg_LC",c(2000,2010,"Cross"),"_T", tileS.tbl[i,"ID"], ".csv")
  out.tif = paste0(out.path, "/T", tileS.tbl[i,"ID"], "/OCS_0_30_cm_",c(2000,2010),"_T", tileS.tbl[i,"ID"], ".tif")
  if(any(!file.exists(out.csv))){
    m = readGDAL(fname=lcs1, offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
    lst = list(lcs2,sg1,cf,cnt,wsd,lpd)
    for(j in 1:length(lst)){
      m@data[,j+1] = readGDAL(fname=lst[[j]], offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    }
    names(m) = c("LC2000","LC2010","SG2000","LC_CF","GAUL_COUNTRY","HYBASIN","LPD")
    m = as(m, "SpatialPixelsDataFrame")
    sel.pix = !is.na(m$GAUL_COUNTRY) & !m$LC2000 == 7 & !is.na(m$LC2000)
    if(length(sel.pix)>2){
      m = m[sel.pix,]
      m$LC2000 = factor(m$LC2000, levels=as.character(1:7), labels=levels(lc.leg$AGG_NAME)[c(4,6,3,8,1,2,7)])
      m$LC2010 = factor(m$LC2010, levels=as.character(1:7), labels=levels(lc.leg$AGG_NAME)[c(4,6,3,8,1,2,7)])
      m$Cross_LC_AGG = as.factor(paste(m$LC2000, m$LC2010, sep="_"))
      m$GAUL_COUNTRY = factor(m$GAUL_COUNTRY, levels=as.character(sort(unique(countries$Value))), labels=countries$NAMES[order(countries$Value)])
      m$HYBASIN = factor(m$HYBASIN, levels=as.character(1:nrow(hb.leg)), labels=hb.leg$NAME)
      m$LPD = factor(m$LPD, levels=as.character(1:nrow(lpd.leg)), labels=lpd.leg$NAME)
      #m$SG2010 = ifelse(is.na(m$LC_CF), m$SG2000, m$SG2000*(1 + ((m$LC_CF-100)/2)/100) )
      m$SG2010 = ifelse(is.na(m$LC_CF), m$SG2000, m$SG2000 + m$LC_CF)
      m$SG2010 = ifelse(m$SG2010<0, 0, m$SG2010)
      saveRDS(m, paste0(out.path, "/T", tileS.tbl[i,"ID"], "/stacked_T", tileS.tbl[i,"ID"], ".rds"))
      writeGDAL(m["SG2000"], out.tif[1], type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")
      writeGDAL(m["SG2010"], out.tif[2], type="Int16", mvFlag=-32768, options="COMPRESS=DEFLATE")
      ## Aggregate per country
      SOC_agg.LC2000 <- plyr::ddply(m@data, .(GAUL_COUNTRY,LC2000,HYBASIN,LPD), summarize, Total_OCS_2000_t=round(sum(SG2000*AREA, na.rm = TRUE)/1e6,2), Sum_OCS_2000=sum(SG2000, na.rm=TRUE), N_OCS_2000=sum(!is.na(SG2000)))
      write.csv(SOC_agg.LC2000, out.csv[1])
      SOC_agg.LC2010 <- plyr::ddply(m@data, .(GAUL_COUNTRY,LC2010,HYBASIN,LPD), summarize, Total_OCS_2010_t=round(sum(SG2010*AREA, na.rm = TRUE)/1e6,2), Sum_OCS_2010=sum(SG2010, na.rm=TRUE), N_OCS_2010=sum(!is.na(SG2010)))
      write.csv(SOC_agg.LC2010, out.csv[2])
      ## Aggregate per class combination
      SOC_agg2.LC2010 <- plyr::ddply(m@data, .(GAUL_COUNTRY,Cross_LC_AGG,HYBASIN,LPD), summarize, Total_OCS_2000_t=round(sum(SG2000*AREA, na.rm = TRUE)/1e6,2), Sum_OCS_2000=sum(SG2000, na.rm=TRUE), Total_OCS_2010_t=round(sum(SG2010*AREA, na.rm = TRUE)/1e6,2), Sum_OCS_2010=sum(SG2010, na.rm=TRUE), N_OCS_2010=sum(!is.na(SG2010))) ## dOCS_2010=sum(SG2010-SG2000, na.rm=TRUE)
      write.csv(SOC_agg2.LC2010, out.csv[3])
    }
  }
}

## Fill in interger numbers using dominant value (suitable for filling in gaps in factor-type tif)
## http://gis.stackexchange.com/questions/181011/fill-the-gaps-using-nearest-neighbors
fill.na <- function(x, min.count=2) {
  if(sum(!is.na(x))>min.count){
    wm = as.integer(names(which.max(table(as.factor(x)))[1]))
    return(wm)
  }
}

fill.gaps <- function(i, tileS.tbl, out.path="/data/tt/LDN/Stiled", in.grid="bas_15s_beta_300m_sin.tif", in.mask="GAUL_COUNTRIES_300m_sin.tif"){
  out.tif = paste0(out.path, "/T", tileS.tbl[i,"ID"], "/bas_15s_betaF_T", tileS.tbl[i,"ID"], ".tif")
  if(!file.exists(out.tif)){
    m = readGDAL(fname=in.grid, offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
    m$mask = readGDAL(fname=in.mask, offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    if(sum(!is.na(m$mask)&is.na(m$band1))>0){
      r = raster(m["band1"])
      rf = focal(r, w=matrix(1,9,9), fun=fill.na, pad=TRUE, na.rm=FALSE, NAonly=TRUE)
      m$out = as(rf, "SpatialGridDataFrame")@data[,1]
      m$out = ifelse(m$out<=0, NA, m$out)
      ## second round
      r = raster(m["out"])
      rf = focal(r, w=matrix(1,9,9), fun=fill.na, pad=TRUE, na.rm=FALSE, NAonly=TRUE)
      m$out = as(rf, "SpatialGridDataFrame")@data[,1]
      m$out = ifelse(is.na(m$mask), NA, m$out)
      writeGDAL(m["out"], out.tif, type="Int16", mvFlag=0, options=c("COMPRESS=DEFLATE"))
    }
  }
}

latlon2sin = function(input.file, output.file, mod.grid, tmp.dir="/data/LDN/tmp/", proj, pixsize, cleanup.files=TRUE, te, resample="near"){
  if(!file.exists(output.file)){
    ## reproject grid in tiles:
    out.files = paste0(tmp.dir, "T", mod.grid$ID, "_", set.file.extension(basename(input.file), ".tif"))
    te.lst = apply(mod.grid@data[,1:4], 1, function(x){paste(x, collapse=" ")})
    if(missing(proj)){ proj = "+proj=sinu +lon_0=0 +x_0=0 +y_0=0 +a=6371007.181 +b=6371007.181 +units=m +no_defs" }
    require(snowfall)
    sfInit(parallel=TRUE, cpus=parallel::detectCores())
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
}

## function to extract values per country:
sp_bind = function(tif=NULL, cnt=NULL, sel, rds=NULL, varname=NULL, as.table=FALSE){
  if(is.null(rds)){
    s = readGDAL(tif,silent=TRUE)
    s$cnt = readGDAL(cnt,silent=TRUE)$band1
    s = as(s, "SpatialPixelsDataFrame")
    s <- s[which(s$cnt %in% sel),1]
  } else {
    s = readRDS(rds)
    s <- s[which(s$GAUL_COUNTRY %in% gsub("_","'",paste(sel))),varname]
  }
  if(length(s)>0){ 
    if(as.table==TRUE){
      s = as.data.frame(s)
    }
    return(s) 
  }
}

bind_country_tif = function(b, country, varname, in.path="/data/tt/LDN/Stiled", out.path, from.rds=FALSE, gaul.df){
  out.file = paste0(out.path, plotKML::normalizeFilename(gsub("-", "_", gsub(")", ".", gsub("(", ".", country, fixed=TRUE), fixed=TRUE), fixed=TRUE)), "_", varname, "_300m.tif")
  if(!file.exists(out.file)){
    x = b$ID[b$Value==country]
    if(from.rds==FALSE){
      tif.lst = sapply(x, function(i){paste0(in.path, "/T", i, "/", varname, "_T", i, ".tif")})
      cnt.lst = sapply(x, function(i){paste0(in.path, "/T", i, "/GAUL_T", i, ".tif")})
      ta = sapply(tif.lst, file.exists)
      tif.lst = tif.lst[ta]
      cnt.lst = cnt.lst[ta]
      prj = proj4string(raster(tif.lst[1]))
      sel = gaul.df[which(gaul.df$NAMES==country),"Value"]
      s = list(NULL)
      sfInit(parallel=TRUE, cpus=ifelse(length(tif.lst)>parallel::detectCores(),parallel::detectCores(),length(tif.lst)))
      sfExport("tif.lst", "cnt.lst", "sel", "sp_bind")
      sfLibrary(rgdal)
      sfLibrary(raster)
      s <- sfClusterApplyLB(1:length(tif.lst), function(i){ sp_bind(tif.lst[i],cnt.lst[i],sel)})
      sfStop()
    } else {
      rds.lst = sapply(x, function(i){paste0(in.path, "/T", i, "/stacked_T", i, ".rds")})
      if(any(sapply(rds.lst, function(i)!file.exists(i)))){ stop("Missing *.rds files") }
      sfInit(parallel=TRUE, cpus=ifelse(length(rds.lst)>parallel::detectCores(),parallel::detectCores(),length(rds.lst)))
      sfExport("rds.lst", "country", "varname", "sp_bind")
      sfLibrary(rgdal)
      sfLibrary(raster)
      s <- sfClusterApplyLB(rds.lst, function(i){ sp_bind(sel=country, rds=i, varname=varname) })
      sfStop()
    }
    if(!all(sapply(s, is.null))){
      tmp.lst = paste0("/data/tmp/T", 1:length(s), ".tif")
      if(from.rds==FALSE){  
        x = parallel::mclapply(1:length(s), FUN=function(i){writeGDAL(s[[i]], tmp.lst[i], type="Int16", options="COMPRESS=DEFLATE", mvFlag=-32768)}, mc.cores=parallel::detectCores())
      } else {
        x = parallel::mclapply(1:length(s), FUN=function(i){raster::writeRaster(raster(s[[i]]), filename = tmp.lst[i], datatype="INT2S", options=c("COMPRESS=DEFLATE"))}, mc.cores=parallel::detectCores())
      }
      out.tmp <- tempfile(fileext = ".txt")
      vrt.tmp <- tempfile(fileext = ".vrt")
      cat(tmp.lst, sep="\n", file=out.tmp)
      system(paste0('gdalbuildvrt -input_file_list ', out.tmp, ' ', vrt.tmp))
      system(paste0(gdalwarp, ' ', vrt.tmp, ' ', out.file, ' -ot \"Int16\" -dstnodata \"-32767\" -co \"BIGTIFF=YES\" -multi -wm 2000 -co \"COMPRESS=DEFLATE\" -r \"near\"'))
      unlink(tmp.lst)
      gc(); gc()
    }
  }
}


plot_raster = function(r, out.file, res=600, legend, breaks, country_lines){
  if(!file.exists(out.file)){
    if(is.character(r)){ r = readGDAL(r) }
    if(missing(legend)){ 
      legend = c("#0000ff", "#0050af", "#00a15e", "#00f20d", "#43ff00", "#94ff00", "#e5ff00",  "#ffca00", "#ff7900", "#ff2800", "#ff0000")  
      #legend = c("#d7191c", "#e85b3a", "#f99e59", "#fec981", "#ffedab", "#ecf7ad", "#c4e687", "#97d265", "#58b453", "#1a9641")
    }
    if(missing(breaks)){
      breaks = c(0,15,30,45,60,75,90,105,120,135,1000)
    }
    r$cut = cut(r@data[,1], breaks=breaks)
    ## adjust dimensions for smaller countries
    width = r@grid@cells.dim[1]
    height = r@grid@cells.dim[2]
    width = ifelse(width<1000|height<1000, width*3, width)
    height = ifelse(width<1000|height<1000, height*3, height)
    png(file = out.file, res=res, width=width, height=height)
    ## mar: numerical vector indicating margin size c(bottom, left, top, right) in lines. default = c(5, 4, 4, 2) + 0.1
    ## mai: numerical vector indicating margin size c(bottom, left, top, right) in inches
    par(mar=c(0,0,0,0), oma=c(0,0,0,0))
    ## http://stackoverflow.com/questions/31745894/get-aspect-ratio-for-lat-long-plots
    x.dist = ggplot2:::dist_central_angle(mean(r@bbox[1,]) + c(-0.5, 0.5), rep(mean(r@bbox[2,]), 2))
    y.dist = ggplot2:::dist_central_angle(rep(mean(r@bbox[1,]), 2), mean(r@bbox[2,]) + c(-0.5, 0.5))
    image(raster(r["cut"]), col=legend, asp=y.dist/x.dist)
    lines(country_lines, col="black") #lwd=2
    #legend("bottomright", legend=rev(levels(r$cut)), fill=rev(legend), horiz=FALSE, pt.cex=2)
    #maps::map.scale(relwidth=0.1, ratio=FALSE) 
    dev.off()
  }
}

## propagated change in SOC due to land cover change
prop_FC <- function(x, CF.tbl){
  x0 <- strsplit(paste(x[1]), " ")[[1]]
  soc0 <- as.numeric(paste(x[2]))
  x.cf <- CF.tbl[match(x0, CF.tbl$NAME),"OCS_CF_FactorLandUse"]
  x.cf[is.na(x.cf)] = 1
  t <- x.cf==1
  ds <- rep(soc0, length(x.cf))
  if(!all(t)){
    s <- which(!t)
    for(j in 1:length(s)){
      if(j==length(s)) {
        s0 <- length(x.cf)
      } else {
        s0 <- (s[j+1]-1)
      }
      if(j==1){
        ds[s[j]:s0] <- soc0 * (1 + (1:length(s[j]:s0) * (x.cf[s[j]]-1)/20)) 
      } else {
        ds[s[j]:s0] <- ds[s[j]-1] * (1 + (1:length(s[j]:s0) * (x.cf[s[j]]-1)/20))
      }
    }
  }
  ds <- ifelse(ds<0, 0, ds)
  return(ds)
}
myFuncCmp <- compiler::cmpfun(prop_FC)

## Derive SOC change using multitemporal land cover ----
SOC_change_ts = function(i, tile.tbl, CF.tbl, cl.leg, out.path="/data/tt/LDN/tiled", ts.grid="./ESA_landcover/ESACCI-LC-L4-LCCS-Map-300m-P1Y-1992_2015-v2.0.7.tif", clim="EF_Bio_Des_300m.tif", soc="OCSTHA_M_30cm_300m_ll.tif", years=2000:2015, tot.years=1992:2015){
  outD.tif = paste0(out.path, "/T", tile.tbl[i,"ID"], "/dOCS_", tile.tbl[i,"ID"], ".tif")
  if(!file.exists(outD.tif)){
    m = readGDAL(fname=ts.grid, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
    sel.nc = match(years, tot.years)
    m@data = m@data[,sel.nc]
    nc = ncol(m)
    m$clim = plyr::join(data.frame(number=readGDAL(fname=clim, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1), cl.leg, match="first")$number_agg
    m$soc = readGDAL(fname=soc, offset=unlist(tile.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tile.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
    sel.p = which(!apply(m@data[,1:nc], 1, FUN = function(x){all(x==210)}))
    if(sum(!is.na(m$soc))>0){
      mx = as.data.frame(lapply(sel.nc[-length(sel.nc)], function(x){ paste0(m@data[sel.p,paste0("band", x)], "_", m@data[sel.p, paste0("band", x+1)], "_", m$clim[sel.p]) }), stringsAsFactors = FALSE, col.names=paste0("LCC_",sel.nc[-length(sel.nc)]))
      mx = data.table(data.frame(x=do.call(paste, mx), soc=m$soc[sel.p], stringsAsFactors = FALSE))
      ## MOST TIME CONSUMING STEP:
      socN = apply(mx, 1, FUN=myFuncCmp, CF.tbl=CF.tbl)
      ## generates also missing values
      ## Export SOC maps:
      for(j in 1:(nc-1)){
        m@data[sel.p,"socN"] = socN[j,]
        out.tif = paste0(out.path, "/T", tile.tbl[i,"ID"], "/OCS", years[j+1], "_", tile.tbl[i,"ID"], ".tif")
        writeGDAL(m["socN"], out.tif, type="Int16", mvFlag=-32767, options=c("COMPRESS=DEFLATE"))
      }
      ## Cumulative change:
      socC = apply(socN, 2, diff)
      m@data[sel.p,"socC"] = rowSums(t(socC), na.rm = TRUE)
      #plot(raster(m["socC"]), col=SAGA_pal[[1]])
      writeGDAL(m["socC"], outD.tif, type="Int16", mvFlag=-32767, options=c("COMPRESS=DEFLATE"))
    } else {
      m@data[sel.p,"socC"] = 0
      writeGDAL(m["socC"], outD.tif, type="Int16", mvFlag=-32767, options=c("COMPRESS=DEFLATE"))
    }
  }
}

make_mosaic <- function(x, filename, path="/data/tt/LDN/tiled", tr, te, ot="Int16", dstnodata=-32768){
  if(missing(filename)){
    filename <- paste0("./300m_ll/", x, "_300m_ll.tif")
  }
  if(!file.exists(filename)){
    lst.s <- list.files(path, pattern=glob2rx(paste0(x, "*.tif$")), recursive = TRUE, full.names = TRUE)
    vrt <- tempfile(fileext = ".vrt")
    txt <- tempfile(fileext = ".txt")
    cat(lst.s, sep="\n", file=txt)
    system(paste0('gdalbuildvrt -input_file_list ', txt,' ', vrt))
    system(paste0('gdalwarp ', vrt, ' ', filename, ' -co \"BIGTIFF=YES\" -tr ', tr, ' ', tr, ' -multi -wo \"NUM_THREADS=2\" -wm 2000 -co \"COMPRESS=DEFLATE\" -ot \"', ot,'\" -dstnodata \"', dstnodata, '\" -te ', te))
    system(paste0('gdaladdo ', filename, ' 2 4 8 16 32 64 128'))
  }
}

## Total soil organic carbon stock per GAUL ----
summary_OCS_tiles <- function(i, tileS.tbl, admin="./300m_sin/GAUL_ADMIN1_landmask_300m_sin.tif", ocs="./300m_sin/dOCS_300m_sin.tif"){
  m = readGDAL(fname=admin, offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)
  m@data[,2] = readGDAL(fname=ocs, offset=unlist(tileS.tbl[i,c("offset.y","offset.x")]), region.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileS.tbl[i,c("region.dim.y","region.dim.x")]), silent = TRUE)$band1
  names(m) = c("Value","OCS")
  if(sum(!is.na(m$OCS))>0){
    ## Aggregate per class combination
    SOC_agg.admin <- plyr::ddply(m@data, .(Value), summarize, Sum_dOCS=sum(OCS, na.rm=TRUE), Area_km2=sum(!is.na(OCS))*0.09)
    return(SOC_agg.admin)
  }
}

## historic forest ----
historic_forest = function(i, tileL.tbl, ifl.tifs=paste0("./250m_ll/", c("ifl_2000.sdat", "ifl_2013.sdat", "ifl_2016.sdat")), lcv.tifs=paste0("/data/LandGIS/layers250m/", paste0("lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_", c(1995, 2000, 2005, 2010, 2013, 2015), "_v1.0.tif")), ofc.tif="/data/LDN/250m_ll/ofc_gen.sdat", tif.land="/data/LandGIS/layers250m/lcv_landmask_esacci.lc.l4_c_250m_s0..0cm_2000..2015_v1.0.tif", out.dir="/data/tt/LandGIS/calc250m", tree.sel=c(50, 60, 61, 62, 70, 71, 72, 80, 81, 82, 90, 100, 160)){
  i.n = which(tileL.tbl$ID == strsplit(i, "T")[[1]][2])
  out.file = paste0(out.dir, "/T", tileL.tbl[i.n,"ID"], "/", paste0("FC", c(0,1995,2000,2005,2010,2013,2016)),"_T", tileL.tbl[i.n,"ID"], ".tif")
  if(!all(file.exists(out.file))){
    m = readGDAL(fname=tif.land, offset=unlist(tileL.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tileL.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileL.tbl[i.n,c("region.dim.y","region.dim.x")]), silent = TRUE)
    m = as(m, "SpatialPixelsDataFrame")
    sel.p = (m$band1==1|m$band1==3)
    if(sum(sel.p)>0){
      m = m[sel.p,]
      tot.tif = c(ofc.tif, ifl.tifs, lcv.tifs)
      for(j in 1:length(tot.tif)){
        m@data[,j+1] = readGDAL(fname=tot.tif[j], offset=unlist(tileL.tbl[i.n,c("offset.y","offset.x")]), region.dim=unlist(tileL.tbl[i.n,c("region.dim.y","region.dim.x")]), output.dim=unlist(tileL.tbl[i.n,c("region.dim.y","region.dim.x")]), silent=TRUE)$band1[m@grid.index]
      }
      names(m) = c("mask", basename(tot.tif))
      ## forest cover 2 classes (1) intact areas, (2) other forests
      m$FC0 = ifelse(is.na(m$ofc_gen.sdat), NA, 1)
      r = raster::raster(m["FC0"])
      ## filter out the blocky structure:
      rf = raster::focal(r, w=matrix(1,25,25), fun=modal, na.rm=TRUE, NAonly=TRUE)
      repn = as(rf, "SpatialGridDataFrame")@data[m@grid.index,1]
      m$FC1995 = ifelse(!is.na(m$ifl_2000.sdat), 1, ifelse(m$lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_1995_v1.0.tif %in% tree.sel, 2, NA))
      m$FC2000 = ifelse(!is.na(m$ifl_2000.sdat), 1, ifelse(m$lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_2000_v1.0.tif %in% tree.sel, 2, NA))
      m$FC2005 = ifelse(!is.na(m$ifl_2000.sdat), 1, ifelse(m$lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_2005_v1.0.tif %in% tree.sel, 2, NA))
      m$FC2010 = ifelse(!is.na(m$ifl_2000.sdat), 1, ifelse(m$lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_2010_v1.0.tif %in% tree.sel, 2, NA))
      m$FC2013 = ifelse(!is.na(m$ifl_2013.sdat), 1, ifelse(m$lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_2013_v1.0.tif %in% tree.sel, 2, NA))
      m$FC2016 = ifelse(!is.na(m$ifl_2016.sdat), 1, ifelse(m$lcv_land.cover_esacci.lc.l4_c_250m_s0..0cm_2015_v1.0.tif %in% tree.sel, 2, NA))
      m$FC0 = ifelse(!is.na(m$FC1995), 1, ifelse(is.na(m$FC0), repn, m$FC0))
      ## export
      ps = paste0("FC", c(0,1995,2000,2005,2010,2013,2016))
      for(x in 1:length(ps)){
        writeGDAL(m[ps[x]], out.file[x], type="Byte", options="COMPRESS=DEFLATE", mvFlag = 255)
      }
    }
  }
}

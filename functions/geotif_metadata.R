## Attach metadata to LandGIS layers:
## tom.hengl@envirometrix.net

md = read.csv("landgis_layers.csv", stringsAsFactors = FALSE)
tif.lst = c(list.files("/mnt/nas/LandGIS/predicted1km", pattern=glob2rx("*.tif$"), full.names = TRUE), list.files("/mnt/nas/PNV/predicted1km", pattern=glob2rx("*.tif$"), full.names = TRUE))

add_md = function(x, metadata){
  if(!is.null(metadata)){ 
    m = paste('-mo ', '\"', names(metadata), "=", paste(as.vector(metadata)), '\"', sep="", collapse = " ")
    command = paste0('gdal_edit.py ', m,' ', x)
    system (command, intern=TRUE)
  }
}

for(i in 1:nrow(md)){
  n.md = grep(md$layer_filename_pattern[i], basename(tif.lst))
  sel.tif = tif.lst[n.md]
  if(length(sel.tif)>0){
    metadata = md[i,-(1:3)]
    for(j in 1:length(sel.tif)){
      add_md(x=sel.tif[j], metadata)
    }
  }
}

system(paste0('gdalinfo ', tif.lst[5]))
system(paste0('gdalinfo ', tif.lst[15]))

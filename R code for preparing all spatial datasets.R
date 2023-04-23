# R Script was used to prepare all presence points ans raster.
# This script is only to give uses an idea of how the raw datasets where cleaned and prepared in RStudio
# This script does not reproduce the analysis, it only generates the datasets used for the paper which were shared in the repository
# NOTE: The original datasets are not shared here as they are heavy with file size exceeding 150MB

# activate packages
library("raster")
library("tmap")
library("sf")

rm(list = ls())
gc()

# clean the aedes aegypti points
setwd("/Users/anwarmusah/Desktop/Research/Datasets/Aedes Mosquito")
# filter to only data for Brazil 2013
aedes.data <- read.csv("Aedes_occurrences.csv")
aedes.data <- aedes.data[aedes.data$county == "Brazil",]
aedes.data <- aedes.data[aedes.data$year == 2013,]
aedes.data <- aedes.data[!is.na(aedes.data$year),]
colnames(aedes.data)[4] <- "country"
colnames(aedes.data)[5] <- "latitude"
colnames(aedes.data)[6] <- "longitude"
# delete point that falls in the sea
aedes.data <- aedes.data[!aedes.data$gbifID == 1264876090,]
write.csv(aedes.data, file = "Aedes Occurrences in 2013.csv", row.names = FALSE)

# Check overall distribution of points by year and those that are missing
aedes.data <- read.csv("Aedes_occurrences.csv")
aedes.data$counts <- 1
aedes.data$year[is.na(aedes.data$year)] <- 9999
aedes.brazil.aggregated <- aggregate(list(aedes.data$counts), FUN=sum, by=list(aedes.data$year))
names(aedes.brazil.aggregated) <- c("Years", "Points")
aedes.brazil.aggregated$Contribution <- aedes.brazil.aggregated$Points/nrow(aedes.data) * 100
write.csv(aedes.data, file = "All known Aedes Occurrences since 1958 to 2014.csv", row.names = FALSE)

# raster manipulation

# 1 arc-second ~ 30.87 meters
# 2.5 minutes ~ 4630.5 meters (21.44153 sq.kilometers)

# raster lists
# :::night-time light
# :::elevation
# :::population density
# :::urban settlement
# :::ndvi
# :::averaged temperature
# :::averaged precipitation

# WorldClim
# starting with maximum temperature
setwd("/Users/anwarmusah/Desktop/Research/Datasets/WorldClim/Maximum temperature 2010-2018")
maxtempfiles <- list.files(pattern=".tif$")
# keep 2013-01 to 2013-12
maxtempfiles <- maxtempfiles[37:48]
list_maxtempfiles <- list()
for (i in 1:length(maxtempfiles)) {
	list_maxtempfiles[[i]] <- raster(maxtempfiles[i])
}

# average temperature
average_temperature <- calc(stack(list_maxtempfiles[[1]], list_maxtempfiles[[2]], list_maxtempfiles[[3]], list_maxtempfiles[[4]], list_maxtempfiles[[5]], list_maxtempfiles[[6]], 
	list_maxtempfiles[[7]], list_maxtempfiles[[8]], list_maxtempfiles[[9]], list_maxtempfiles[[10]], list_maxtempfiles[[11]], list_maxtempfiles[[12]]), fun = mean, na.rm = T)
	names(average_temperature) <- "temperature"

setwd("/Users/anwarmusah/Desktop/Research/Datasets/Aedes Mosquito/Rasters")
writeRaster(average_temperature, filename = "Global Averaged Temperature 2000-14.tif", overwrite = TRUE)

# precipitation
setwd("/Users/anwarmusah/Desktop/Research/Datasets/WorldClim/Precipitation 2010-2018")
pretempfiles <- list.files(pattern=".tif$")
# keep 2013-01 to 2013-12
pretempfiles <- pretempfiles[37:48]
list_pretempfiles <- list()
for (i in 1:length(pretempfiles)) {
	list_pretempfiles[[i]] <- raster(pretempfiles[i])
}

# average precipitation
average_precipitation <- calc(stack(list_pretempfiles[[1]], list_pretempfiles[[2]], list_pretempfiles[[3]], list_pretempfiles[[4]], list_pretempfiles[[5]], list_pretempfiles[[6]], 
	list_pretempfiles[[7]], list_pretempfiles[[8]], list_pretempfiles[[9]], list_pretempfiles[[10]], list_pretempfiles[[11]], list_pretempfiles[[12]]), fun = mean, na.rm = T)
	names(average_precipitation) <- "precipitation"

setwd("/Users/anwarmusah/Desktop/Research/Datasets/Aedes Mosquito/Rasters")
writeRaster(average_precipitation, filename = "Global Averaged Precipitation 2000-14.tif", overwrite = TRUE)

# load shapefile of Brazil
setwd("/Users/anwarmusah/Desktop/Research/Datasets/Aedes Mosquito/Shapefile")

brazil_outine <- read_sf("gadm41_BRA_0.shp")
	brazil_extent <- extent(brazil_outine)
	pcs <- CRS("+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs+ towgs84=0,0,0")

# clipping and masking grids to boundaries of Brazil
average_temperature_clipped <- crop(average_temperature, brazil_extent)
average_temperature_masked <- mask(average_temperature_clipped, brazil_outine)
average_temperature_masked <- projectRaster(average_temperature_masked, crs=pcs)

average_precipitation_clipped <- crop(average_precipitation, brazil_extent)
average_precipitation_masked <- mask(average_precipitation_clipped, brazil_outine)
average_precipitation_masked <- projectRaster(average_precipitation_masked, crs=pcs)

# standardize all raster to dimension of approx. 4.5 km (area = 21 sq.km)
RasterTemplate <- raster(nrow=dim(average_temperature)[1], ncol=dim(average_temperature)[2], crs=crs(average_temperature), extent(average_temperature))

# load in the following
#:::night-time light
#:::elevation
#:::population density
#:::urban settlement

setwd("/Users/anwarmusah/Desktop/Research/Datasets/Aedes Mosquito/Masterfile")
elevation <- raster("global_srtm_v4.tif")
population <- raster("ppp_2014_1km_Aggregated.tif")
lighting <- raster("bra_viirs_100m_2013.tif")
urbanarea <- raster("bra_bsgmi_v0a_100m_2013.tif")

elevation_resampled <- resample(elevation, RasterTemplate, method = "bilinear")
lighting_resampled <- resample(lighting, RasterTemplate, method = "bilinear")
population_resampled <- resample(population, RasterTemplate, method = "bilinear")
urbanarea_resampled <- resample(urbanarea, RasterTemplate, method = "ngb")

names(average_precipitation_masked) <- "precipitation"
names(average_temperature_masked) <- "temperature"
names(elevation_resampled) <- "elevation"
names(lighting_resampled) <- "lighting"
names(population_resampled) <- "population"
names(urbanarea_resampled) <- "urbanarea"

setwd("/Users/anwarmusah/Desktop/Research/Datasets/Aedes Mosquito/Rasters")

writeRaster(average_precipitation_masked, filename = "Brazil Annual Precipitation 2013.tif", overwrite = TRUE)
writeRaster(average_temperature_masked, filename = "Brazil Annual Temperature 2013.tif", overwrite = TRUE)
writeRaster(population_resampled, filename = "Global Population Density AveragedEst.tif", overwrite = TRUE)
writeRaster(urbanarea_resampled, filename = "Brazil Urbanisation 2013.tif", overwrite = TRUE)
writeRaster(elevation_resampled, filename = "Global Land Surface Elevation.tif", overwrite = TRUE)
writeRaster(lighting_resampled, filename = "Brazil Natural Lighting.tif", overwrite = TRUE)

# deal with vegetation data
# use any of the save rasters create on code lines 133-138
raster_data <- raster("Brazil Annual Temperature 2013.tif")
# create template based on the dimensions of any of the save rasters in lines 133-138
RasterTemplate <- raster(nrow=dim(raster_data)[1], ncol=dim(raster_data)[2], crs=crs(raster_data), extent(raster_data))
# load the stitched raster for NDVI
# NOTE: this was created externally from RStudio after tiled-extractions from GEE and assembled in QGIS
ndvi <- raster("bra_NDVI_modis_061_mod13a1.tif")
# clip and mask the NDVI to borders using the Brazil shapefile
ndvi_clipped <- crop(ndvi, brazil_extent)
ndvi_masked <- mask(ndvi_clipped, brazil_outine)
ndvi_masked <- projectRaster(ndvi_masked, crs=pcs)
# now resample and standardize the NDVI raster from 500m to a dimension approx. 4.5 km (area = 21 sq.km)
ndvi_resampled <- resample(ndvi_masked, RasterTemplate, method = "bilinear")
setwd("/Users/anwarmusah/Desktop/Research/Datasets/Aedes Mosquito/Rasters")
writeRaster(ndvi_resampled, filename = "Brazil NDVI 2013.tif", overwrite = TRUE)
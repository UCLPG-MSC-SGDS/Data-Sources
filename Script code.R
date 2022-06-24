
# refresh memory and plot panel of RStudio IDE
rm(list = ls())
gc()
dev.off()

# install the following packages need to perform the analysis in article
install.packages("raster")
install.packages("tmap")
install.packages("sp")
install.packages("sf")
install.packages("classInt")
install.packages("spatialEco")
install.packages("BAMMtools")

# active the following packages needed to perform the analysis in article
library("raster")
library("tmap")
library("sp")
library("sf")
library("classInt")
library("spatialEco")
library("BAMMtools")

# set the directory to location of datasets
setwd("~Data")

# load the shapefiles
border <- st_read("Extents.shp")
states <- st_read("Study_areas.shp")

# load the raster data
temp <- raster("AnnualTempMin_cel.tif")
nvdi <- raster("NDVI_averaged.tif")
prec <- raster("AnnualPrec_mm.tif")
popl <- raster("PopulationDensity.tif")
elev <- raster("Elevation_m.tif")
arid <- raster("AridityIndex_value.tif")

# standardize the extents using the border shape file by creating a rastertemplate
RasterTemplate <- raster(nrow = dim(elev)[1], ncol = dim(temp)[2], crs=crs(elev), extent(elev))

# next, standardize the raster to the same dimension by sampling the pixels accordingly and re-estimating them to 100m
temp_100m <- resample(temp, RasterTemplate, method = "bilinear")
prec_100m <- resample(prec, RasterTemplate, method = "bilinear")
arid_100m <- resample(arid, RasterTemplate, method = "bilinear")
nvdi_100m <- resample(nvdi, RasterTemplate, method = "bilinear")
popl_100m <- resample(popl, RasterTemplate, method = "bilinear")
elev_100m <- resample(elev, RasterTemplate, method = "bilinear")

# clip nvdi - this is already at a 100m resolution
nvdi_100m <- mask(nvdi_100m, border)

# Overlay analysis for suitability -- results in figure 2
# temp
temp_cl <- c(temp_100m@data@min-1, 18, 0, 18, temp_100m@data@max+1, 1)
temp_cl_mat <- matrix(temp_cl, ncol = 3, byrow = TRUE); temp_cl_mat
temp_recl <- reclassify(temp_100m, temp_cl_mat)

tm_shape(temp_recl) + tm_raster(style = "cat", title = "", palette=c("white", "red"), labels=c("Zone: Not Suitable", "Zone: Highly Suitable")) +
	tm_shape(border) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE)

# nvdi
nvdi_cl <- c(nvdi_100m@data@min-1, 0.2, 0, 0.2, nvdi_100m@data@max+1, 1)
nvdi_cl_mat <- matrix(nvdi_cl, ncol = 3, byrow = TRUE); nvdi_cl_mat
nvdi_recl <- reclassify(nvdi_100m, nvdi_cl_mat)

tm_shape(nvdi_recl) + tm_raster(style = "cat", title = "", palette=c("white", "red"), labels=c("Zone: Not Suitable", "Zone: Highly Suitable")) +
	tm_shape(border) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE)

# prec
prec_cl <- c(prec_100m@data@min-1, 80, 0, 80, prec_100m@data@max+1, 1)
prec_cl_mat <- matrix(prec_cl, ncol = 3, byrow = TRUE); prec_cl_mat
prec_recl <- reclassify(prec_100m, prec_cl_mat)

tm_shape(prec_recl) + tm_raster(style = "cat", title = "", palette=c("white", "red"), labels=c("Zone: Not Suitable", "Zone: Highly Suitable")) +
	tm_shape(border) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE)

# popl
popl_cl <- c(popl_100m@data@min-1, 2, 0, 1, popl_100m@data@max+1, 1)
popl_cl_mat <- matrix(popl_cl, ncol = 3, byrow = TRUE); popl_cl_mat
popl_recl <- reclassify(popl_100m, popl_cl_mat)

tm_shape(popl_recl) + tm_raster(style = "cat", title = "", palette=c("white", "red"), labels=c("Zone: Not Suitable", "Zone: Highly Suitable")) +
	tm_shape(border) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE)

# elev
elev_cl <- c(elev_100m@data@min-1, 600, 1, 600, elev_100m@data@max+1, 0)
elev_cl_mat <- matrix(elev_cl, ncol = 3, byrow = TRUE); elev_cl_mat
elev_recl <- reclassify(elev_100m, elev_cl_mat)

tm_shape(elev_recl) + tm_raster(style = "cat", title = "", palette=c("white", "red"), labels=c("Zone: Not Suitable", "Zone: Highly Suitable")) +
	tm_shape(border) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE)

# arid
arid_cl <- c(arid_100m@data@min-1, 0.30, 0, 0.30, arid_100m@data@max+1, 1)
arid_cl_mat <- matrix(arid_cl, ncol = 3, byrow = TRUE); arid_cl_mat
arid_recl <- reclassify(arid_100m, arid_cl_mat)

tm_shape(arid_recl) + tm_raster(style = "cat", title = "", palette=c("white", "red"), labels=c("Zone: Not Suitable", "Zone: Highly Suitable")) +
	tm_shape(border) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE)

# Combined
RasterStack <- stack(temp_recl, nvdi_recl, prec_recl, popl_recl, arid_recl, elev_recl)
SummedCriteria <- calc(RasterStack, sum)

tm_shape(SummedCriteria) + 
	tm_raster(style = "cat", title = "Suitability Rating", palette=c("#FEF0D9", "#FDD49E", "#FDBB84", "#FC8D59", "#E34A33", "#B30000"), labels=c("Little/None (1)" ,"Very low (2)", "Low (3)", "Medium (4)", "High (5)", "High Very (6)")) +
	tm_shape(states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE, legend.text.size = 0.5, legend.title.size = 0.8) + tm_text("NAME_1", size = "AREA") +
  tm_compass(position = c("left", "top"))

# AHP
# cleaning for temp
# Extract values from Raster
tempValues <- values(temp_100m) 
# Change the values from vector object to data.frame object
tempDF <- as.data.frame(tempValues)
# Remove missing values and reapply column name
tempDF <- as.data.frame(tempDF[!is.na(tempDF$tempValues),])
colnames(tempDF) <- "tempValues"
# Use the getJenksBreaks() function. Sample 0.10 (10%) of the pixels at random and base the categorisation on this. 
# NOTE: Doing this on the full data will take forever - so use the subset argument. 
tempJenks <- getJenksBreaks(tempDF$tempValues, 10, subset = nrow(tempDF)*0.10)
# See value in vector
tempJenks
# so on and so further...
# Create categorisation by using the Jenks values in the vector
temp_jenks_cl <- c(temp_100m@data@min-1, tempJenks[1], 1,
									 tempJenks[1], tempJenks[2], 2,
									 tempJenks[2], tempJenks[3], 3,
									 tempJenks[3], tempJenks[4], 4,
									 tempJenks[4], tempJenks[5], 5,
									 tempJenks[5], tempJenks[6], 6,
									 tempJenks[6], tempJenks[7], 7,
									 tempJenks[7], tempJenks[8], 8,
									 tempJenks[8], tempJenks[9], 9,
									 tempJenks[9], temp_100m@data@max+1, 10) 
# create matrix
temp_jenks_cl_mat <- matrix(temp_jenks_cl, ncol = 3, byrow = TRUE)
# view categorisation in matrix
temp_jenks_cl_mat
# reclassify original raster using the jenks classifications
temp_jenks_recl <- reclassify(temp_100m, temp_jenks_cl_mat)

tm_shape(temp_jenks_recl) + tm_raster(style = "cont", title = "Temp (on Jenks scale)", palette= "-Spectral") +
	tm_shape(states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE)

# 2 prec
# Extract values from Raster
precValues <- values(prec_100m) 
# Change the values from vector object to data.frame object
precDF <- as.data.frame(precValues)
# Remove missing values and reapply column name
precDF <- as.data.frame(precDF[!is.na(precDF$precValues),])
colnames(precDF) <- "precValues"
# Use the getJenksBreaks() function. Sample 0.10 (10%) of the pixels at random and base the categorisation on this. 
# NOTE: Doing this on the full data will take forever - so use the subset argument. 
precJenks <- getJenksBreaks(precDF$precValues, 10, subset = nrow(precDF)*0.10)
# See value in vector
precJenks
# so on and so further...
# Create categorisation by using the Jenks values in the vector
prec_jenks_cl <- c(prec_100m@data@min-1, precJenks[1], 1,
									 precJenks[1], precJenks[2], 2,
									 precJenks[2], precJenks[3], 3,
									 precJenks[3], precJenks[4], 4,
									 precJenks[4], precJenks[5], 5,
									 precJenks[5], precJenks[6], 6,
									 precJenks[6], precJenks[7], 7,
									 precJenks[7], precJenks[8], 8,
									 precJenks[8], precJenks[9], 9,
									 precJenks[9], prec_100m@data@max+1, 10) 
# create matrix
prec_jenks_cl_mat <- matrix(prec_jenks_cl, ncol = 3, byrow = TRUE)
# view categorisation in matrix
prec_jenks_cl_mat
# reclassify original raster using the jenks classifications
prec_jenks_recl <- reclassify(prec_100m, prec_jenks_cl_mat)

# 3. popl
# Extract values from Raster
poplValues <- values(popl_100m)
# Change the values from vector object to data.frame object
poplDF <- as.data.frame(poplValues)
# Remove missing values and reapply column name
poplDF <- as.data.frame(poplDF[!is.na(poplDF$poplValues),])
colnames(poplDF) <- "poplValues"
# Use the getJenksBreaks() function. Sample 0.10 (10%) of the pixels at random and base the categorisation on this. 
# NOTE: Doing this on the full data will take forever - so use the subset argument. 
poplJenks <- getJenksBreaks(poplDF$poplValues, 10, subset = nrow(poplDF)*0.10)
# See value in vector
poplJenks

# so on and so further...
# Create categorisation by using the Jenks values in the vector
popl_jenks_cl <- c(popl_100m@data@min-1, poplJenks[1], 1,
									 poplJenks[1], poplJenks[2], 2,
									 poplJenks[2], poplJenks[3], 3,
									 poplJenks[3], poplJenks[4], 4,
									 poplJenks[4], poplJenks[5], 5,
									 poplJenks[5], poplJenks[6], 6,
									 poplJenks[6], poplJenks[7], 7,
									 poplJenks[7], poplJenks[8], 8,
									 poplJenks[8], poplJenks[9], 9,
									 poplJenks[9], popl_100m@data@max+1, 10) 
# create matrix
popl_jenks_cl_mat <- matrix(popl_jenks_cl, ncol = 3, byrow = TRUE)
# view categorisation in matrix
popl_jenks_cl_mat
# reclassify original raster using the jenks classifications
popl_jenks_recl <- reclassify(popl_100m, popl_jenks_cl_mat)

# 4 nvdi
# Extract values from Raster
nvdiValues <- values(nvdi_100m) 
# Change the values from vector object to data.frame object
nvdiDF <- as.data.frame(nvdiValues)
# Remove missing values and reapply column name
nvdiDF <- as.data.frame(nvdiDF[!is.na(nvdiDF$nvdiValues),])
colnames(nvdiDF) <- "nvdiValues"
# Use the getJenksBreaks() function. Sample 0.10 (10%) of the pixels at random and base the categorisation on this. 
# NOTE: Doing this on the full data will take forever - so use the subset argument. 
# EXTRA NOTE: The values for nvdi are very close to each other and so the algorithm splits it to just two cateogries
nvdiJenks <- getJenksBreaks(nvdiDF$nvdiValues, 10, subset = nrow(nvdiDF)*0.10)
# See value in vector
nvdiJenks

# so on and so further...
# Create categorisation by using the Jenks values in the vector
nvdi_jenks_cl <- c(nvdi_100m@data@min-1, nvdiJenks[1], 1,
									 nvdiJenks[1], nvdiJenks[2], 2,
									 nvdiJenks[2], nvdiJenks[3], 3,
									 nvdiJenks[3], nvdiJenks[4], 4,
									 nvdiJenks[4], nvdiJenks[5], 5,
									 nvdiJenks[5], nvdiJenks[6], 6,
									 nvdiJenks[6], nvdiJenks[7], 7,
									 nvdiJenks[7], nvdiJenks[8], 8,
									 nvdiJenks[8], nvdiJenks[9], 9,
									 nvdiJenks[9], nvdi_100m@data@max+1, 10)
# create matrix
nvdi_jenks_cl_mat <- matrix(nvdi_jenks_cl, ncol = 3, byrow = TRUE)
# view categorisation in matrix
nvdi_jenks_cl_mat
# reclassify original raster using the jenks classifications
nvdi_jenks_recl <- reclassify(nvdi_100m, nvdi_jenks_cl_mat)

# 5. arid
# Extract values from Raster
aridValues <- values(arid_100m) 
# Change the values from vector object to data.frame object
aridDF <- as.data.frame(aridValues)
# Remove missing values and reapply column name
aridDF <- as.data.frame(aridDF[!is.na(aridDF$aridValues),])
colnames(aridDF) <- "aridValues"
# Use the getJenksBreaks() function. Sample 0.10 (10%) of the pixels at random and base the categorisation on this. 
# NOTE: Doing this on the full data will take forever - so use the subset argument.
# EXTRA NOTE: The values for aridity are very close to each other and so the algorithm splits it to just two cateogries
aridJenks <- getJenksBreaks(aridDF$aridValues, 2, subset = nrow(aridDF)*0.10)
# See value in vector
aridJenks
# so on and so further...
# Create categorisation by using the Jenks values in the vector
arid_jenks_cl <- c(arid_100m@data@min-1, aridJenks[1], 1,
									 nvdiJenks[1], nvdiJenks[2], 2,
									 nvdiJenks[2], nvdiJenks[3], 3,
									 nvdiJenks[3], nvdiJenks[4], 4,
									 nvdiJenks[4], nvdiJenks[5], 5,
									 nvdiJenks[5], nvdiJenks[6], 6,
									 nvdiJenks[6], nvdiJenks[7], 7,
									 nvdiJenks[7], nvdiJenks[8], 8,
									 nvdiJenks[8], nvdiJenks[9], 9,
									 aridJenks[9], arid_100m@data@max+1, 10) 
# create matrix
arid_jenks_cl_mat <- matrix(arid_jenks_cl, ncol = 3, byrow = TRUE)
# view categorisation in matrix
arid_jenks_cl_mat
# reclassify original raster using the jenks classifications
arid_jenks_recl <- reclassify(arid_100m, arid_jenks_cl_mat)

# 6. elev

# Extract values from Raster
elevValues <- values(elev_100m) 
# Change the values from vector object to data.frame object
elevDF <- as.data.frame(elevValues)
# Remove missing values and reapply column name
elevDF <- as.data.frame(elevDF[!is.na(elevDF$elevValues),])
colnames(elevDF) <- "elevValues"
# Use the getJenksBreaks() function. Sample 0.10 (10%) of the pixels at random and base the categorisation on this. 
# NOTE: Doing this on the full data will take forever - so use the subset argument. 
elevJenks <- getJenksBreaks(elevDF$elevValues, 10, subset = nrow(elevDF)*0.10)
# See value in vector
elevJenks
# so on and so further...
# Create categorisation by using the Jenks values in the vector
elev_jenks_cl <- c(elev_100m@data@min-1, elevJenks[1], 1,
									 elevJenks[1], elevJenks[2], 2,
									 elevJenks[2], elevJenks[3], 3,
									 elevJenks[3], elevJenks[4], 4,
									 elevJenks[4], elevJenks[5], 5,
									 elevJenks[5], elevJenks[6], 6,
									 elevJenks[6], elevJenks[7], 7,
									 elevJenks[7], elevJenks[8], 8,
									 elevJenks[8], elevJenks[9], 9,
									 elevJenks[9], elev_100m@data@max+1, 10) 
# create matrix
elev_jenks_cl_mat <- matrix(elev_jenks_cl, ncol = 3, byrow = TRUE)
# view categorisation in matrix
elev_jenks_cl_mat
# reclassify original raster using the jenks classifications
elev_jenks_recl <- reclassify(elev_100m, elev_jenks_cl_mat)
# Now flip the values using raster.invert() function
rev_elev_jenks_recl <- raster.invert(elev_jenks_recl)

tm_shape(rev_elev_jenks_recl) + tm_raster(style = "cont", title = "Inverted Elev (on Jenks scale)", palette= "-Spectral") +
	tm_shape(states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.outside = TRUE)


# >>> go to spreadsheet to estimate the weights to create weighted model >>>

# use the re-scaled raster in the formula
suitablemap_WLC <- 0.3324*prec_jenks_recl + 0.2775*temp_jenks_recl + 0.1571*popl_jenks_recl + 0.0901*nvdi_jenks_recl + 0.0767*arid_jenks_recl + 0.0659*rev_elev_jenks_recl
suitablemap_WLC

tm_shape(suitablemap_WLC) + tm_raster(style = "cont", title = "Aedes Suitability (AHP [Out of 10])", palette= "-Spectral") +
	tm_shape(states) + tm_polygons(alpha = 0, border.col = "black") + tm_text("NAME_1", size = "AREA") +
	tm_layout(frame = FALSE, legend.outside = TRUE, legend.title.size = 0.8, legend.text.size = 0.5) + tm_compass(position = c("left", "top"))
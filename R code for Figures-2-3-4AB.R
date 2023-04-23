#######
rm(list = ls())
gc()

# MAXENT modelling
## load following packages
library("raster")
library("dismo")
library("tmap")
library("sf")
library("rJava")
library("sp")

## set working directory to location of datasets
setwd("/Users/anwarmusah/Desktop/Research/Datasets/Aedes Mosquito/MAXENT analysis")

# load survey points of Aedes occurrences in 2013
aedes.data <- read.csv("Aedes Occurrences in 2013.csv")

# load raster files
prec <- raster("Brazil Annual Precipitation 2013.tif")
temp <- raster("Brazil Annual Temperature 2013.tif")
ligh <- raster("Brazil Natural Lighting.tif")
urbr <- raster("Brazil Urbanisation 2013.tif")
ndvi <- raster("Brazil NDVI 2013.tif")
popl <- raster("Brazil Population Density 2013.tif")
elev <- raster("Brazil Land Surface Elevation.tif")

# load the outline shapefile for Brazil
brazil_outline <- read_sf("gadm41_BRA_0.shp")

# load the state shapefile for Brazil
brazil_outline_states <- read_sf("gadm41_BRA_1.shp")

# step 1: We need to prepare for data for maxent analysis
## first, we must create a multi-band raster using stack() function on the environmental variables
env_covariates <- stack(temp, prec, ligh, urbr, ndvi, popl, elev)
names(env_covariates) <- c("Temperature", "Precipitation", "Lighting", "Urban", "NDVI", "Population", "Elevation")

# step 2: we need to convert points of occurrence from a data frame object to that of a spatial points object
## here, declare the column longitude and latitude as coordinates
aedes_points <- aedes.data[, c(5,6)]
coordinates(aedes_points) = ~longitude+latitude
# make sure the CRS is defined: WGS84 4326 | using crs() from sp
crs(aedes_points) <- "+proj=longlat +datum=WGS84 +no_defs"

# step 3: create background points within the Brazilian region
## here, we will general a set of random pseudo-absence points to act as controls where there's no aedes occurrences
## here, we double the number of controls based on the presence points
set.seed(20000430)
brazil_outline_sp <- as(brazil_outline, Class = "Spatial")
background_points <- spsample(brazil_outline_sp, n=2*length(aedes_points), "random")

# step 4: perform raster extraction from the environmental covariates on to all points
aedes_points_env <- extract(env_covariates, aedes_points)
background_points_env <- extract(env_covariates, background_points)
## convert the large matrix objects to separate data frame objects and then add binary outcome `present`
aedes_points_env <-data.frame(aedes_points_env, present=1)
background_points_env <-data.frame(background_points_env, present=0)

# step 5:
## using thesame set.seed() as before
set.seed(20000430)
## we will need to prepare the train and test dataset from the aedes and background points separately
## here, we use k-fold function to split data into 4 equal parts
select <- kfold(aedes_points_env, 4)
# 25% of the aedes data use for testing the model
aedes_points_env_test <- aedes_points_env[select==1,]
# 75% of the aedes data use for training the model
aedes_points_env_train <- aedes_points_env[select!=1,]

# repeat the process for the background points
# set same set.seed() as before
set.seed(20000430)
# repeat the process for the background points
select <- kfold(background_points_env, 4)
# 25% of the control data use for testing the model
background_points_env_test <- background_points_env[select==1,]
# 75% of the control data use for testing the model
background_points_env_train <- background_points_env[select!=1,]

training_data <- rbind(aedes_points_env_train, background_points_env_train)
testing_data <- rbind(aedes_points_env_test, background_points_env_test)

# step 6: train the model
model_training <- maxent(x=training_data[,c(1:7)], p=training_data[,8], args=c("responsecurves"))

# step 7: obtain results
# 1.) check variable contribution
plot(model_training, pch=19, xlab = "Percentage [%]", cex=1.2)
response(model_training)

# 2.) validation with ROC curve
cross_validation <- evaluate(p=testing_data[testing_data$present==1,], a=testing_data[testing_data$present==0,], model = model_training)
plot(cross_validation, 'ROC', cex=1.2)

# 3.) mapping predicted probabilities of aedes occurrence
prob_aedes <- predict(model_training, env_covariates)

# prepare threshold total map 
create_classes_prob <- c(0, 0.2, 1, 0.2, 0.4, 2, 0.4, 0.6, 3, 0.6, 0.8, 4, 0.8, 1.00, 5)
create_pred_matrix <- matrix(create_classes_prob, ncol = 3, byrow = TRUE)
create_pred_matrix

predicted_prob_aedes <- reclassify(prob_aedes, create_pred_matrix)

# generate a publication-worthy figure
# map of probability 
tm_shape(predicted_prob_aedes) +
	tm_raster(title = "Aedes Occupancy [Probability (%)]", 
		palette = c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c"), 
		style ='cat', labels = c("Low (0.0-0.2)", "Moderate (>0.2-0.4)", "Medium (>0.4-0.6)", "High (>0.6-0.8)", "Very high (>0.8-1.0)")) +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.alpha = 0.5, border.col = "#252525") +
	tm_layout(legend.text.size = 0.9, legend.outside = TRUE, legend.title.size = 1.1, frame='#252525') +
	tm_scale_bar(position=c('left', 'bottom'), text.size = 0.8, breaks = c(0, 500, 1000, 1500)) +
	tm_compass(north = 0,type = 'arrow', position = c('right', 'top'), text.size = 0.9)

# calculate thresholds of models
threshold_value <- threshold(cross_validation, "spec_sens")
# report value
threshold_value

# prepare threshold total map 
create_classes_vector <- c(0, threshold_value, 0, threshold_value, 1, 1)
create_clasess_matrix <- matrix(create_classes_vector, ncol = 3, byrow = TRUE)
create_clasess_matrix

suitability_aedes <- reclassify(prob_aedes, create_clasess_matrix)

tm_shape(suitability_aedes) + tm_raster(style = "cat", title = "Aedes Aegypti Occupancy", palette= c("#f0f0f0", "#fc9272"), labels = c("None occupied areas", "Occupied Areas")) +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.alpha = 0.5, border.col = "#252525", legend.text.size = 1.1) +
	tm_layout(frame = "#252525", legend.outside = TRUE, legend.title.size = 1.1, legend.text.size = 0.9) +
	tm_scale_bar(position=c('left', 'bottom'), text.size = 0.8, breaks = c(0, 500, 1000, 1500)) +
	tm_compass(north = 0,type = 'arrow', position = c('right', 'top'), text.size = 0.9)

####
# split plot panel into 4 segments for 4 AUC plots
par(mfrow=c(2,2))
# create a list() object to dump results inside `eMAX`
eMAX<-list()

# use california_fires_env
# use background_points_env
folds <- 4

kfold_pres <- kfold(aedes_points_env, folds)
kfold_back <- kfold(background_points_env, folds)

set.seed(20000430)
# adapting loop code from https://rpubs.com/mlibxmda/GEOG70922_Week5
# takes a long time to run 4-fold
for (i in 1:folds) {
	train <- aedes_points_env[kfold_pres!= i,]
	test <- aedes_points_env[kfold_pres == i,]
	backTrain<-background_points_env[kfold_back!=i,]
	backTest<-background_points_env[kfold_back==i,]
	dataTrain<-rbind(train,backTrain)
	dataTest<-rbind(test,backTest)
	maxnet_eval <- maxent(x=dataTrain[,c(1:7)], p=dataTrain[,8], args=c("responsecurves"))
	eMAX[[i]] <- evaluate(p=dataTest[dataTest$present==1,],a=dataTest[dataTest$present==0,], maxnet_eval)
	plot(eMAX[[i]],'ROC')
}

aucMAX <- sapply( eMAX, function(x){slot(x, 'auc')} )
# report 4 of the AUC
aucMAX
# find the mean of AUC (and it must be > 0.50)
mean(aucMAX)

#Get maxTPR+TNR for the maxnet model
Opt_MAX<-sapply( eMAX, function(x){ x@t[which.max(x@TPR + x@TNR)] } )
Opt_MAX

Mean_OptMAX<-mean(Opt_MAX)
Mean_OptMAX
# use Mean_OptMAX as threshold for mapping suitability

# contribution
#Elevation.contribution                                                                0.4219
#Lighting.contribution                                                                10.2924
#NDVI.contribution                                                                     4.1810
#Population.contribution                                                              75.7557
#Precipitation.contribution                                                            6.7929
#Temperature.contribution                                                              2.5560
#Urban.contribution                                                                    0.0000

# cross_validation
#class          : ModelEvaluation 
#n presences    : 1101 
#n absences     : 2200 
#AUC            : 0.8350334 
#cor            : 0.5483086 
#max TPR+TNR at : 0.4953688

# k-fold validation
# report 4 of the AUC::: aucMAX == 0.8435279 0.8403742 0.8333678 0.8331750
# mean of AUC (and it must be > 0.50) == 0.8376112

# Mean_OptMAX
# use Mean_OptMAX as threshold for mapping suitability

## this code generates the image shown in figure 2
a <- background_points_env
b <- raster::geom(background_points)

a$long <- b[,2]
a$lat <- b[,3]
a <- a[,9:10]

write.csv(a, file="background points.csv", row.names = FALSE)

# map object of temperature stored in m1
m1 <- tm_shape(temp) + tm_raster(style = "cont", title = "Celsius", palette= "-Spectral") +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.position = c("right", "top"), title.position = c("left", "bottom"), title = "A: Temperature")

# map object of precipitation stored in m2
m2 <- tm_shape(prec) + tm_raster(style = "cont", title = "mm", palette= "Blues") +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.position = c("right", "top"), title.position = c("left", "bottom"), title = "B: Precipitation")

# map object of population stored in m3
m3 <- tm_shape(popl) + tm_raster(style = "cont", title = "Counts", palette= "Greys") +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.position = c("right", "top"), title.position = c("left", "bottom"), title = "C:Population density")

# map object of ndvi stored in m4
m4 <- tm_shape(ndvi) + tm_raster(style = "cont", title = "Index", palette= "Greens") +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.position = c("right", "top"), title.position = c("left", "bottom"), title = "D:NDVI")

# map object of elevation stored in m5
m5 <- tm_shape(elev) + tm_raster(style = "cont", title = "m", midpoint = 1500, palette= "-Spectral") +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.position = c("right", "top"), title.position = c("left", "bottom"), title = "E:Elevation")

# map object of natural ligth stored in m6
m6 <- tm_shape(ligh) + tm_raster(style = "cont", title = "%", palette= "Greys") +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.position = c("right", "top"), title.position = c("left", "bottom"), title = "F:Natural lighting")

# map object of natural ligth stored in m6
m7 <- tm_shape(urbr) + tm_raster(style = "cat", title = "Type", palette= c("white", "black"), labels = c("Rural", "Urban")) +
	tm_shape(brazil_outline_states) + tm_polygons(alpha = 0, border.col = "black") +
	tm_layout(frame = FALSE, legend.position = c("right", "top"), title.position = c("left", "bottom"), title = "G: Urban/Rural")

# stitch the maps together using tmap_arrange() function
tmap_arrange(m1, m2, m3, m4, m5, m6, m7, nrow = 2, ncol = 4)
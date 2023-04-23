# Coalescing disparate data sources for the geospatial prediction of mosquito abundance, using Brazil as a motivating case study

<br/>This repository contains the datasets used to produce the results for the above titled research article. These were provided as supplementary materials and were made freely available through our GitHub repository. Please note that all datasets used for this analysis are open source. All links and references to the datasets used for this analysis were explicitly mentioned in our research article. Nevertheless, we provide the location(s) of where they can be accessed and downloaded:

## Shapefiles
1.) Level 0: Country's border for Brazil (gadm36_BRA_0.shp) <br/>
2.) Level 1: Boundaries for the 27 states in Brazil (gadm36_BRA_1.shp)

The shapefiles can be downloaded from [Global Administrative Areas Database (GADM)][gadm]

[gadm]: https://gadm.org/download_country.html

## Rasters
All gridded datasets have been prepared, resampled and standardised to a uniform resolution (i.e., 2.5 mins (equivalent to 4.5 kms)) 

1.) Brazilian population density in 2013 (Brazil Population Density 2013.tif) <br/>
2.) Brazilian urbanisation in 2013 (Brazil Urbanisation 2013.tif) <br/>
3.) Levels of natural lighting in Brazil (Brazil Natural Lighting.tif)

These three datasets can be downloaded from [WorldPop database][worldpop]

[worldpop]: https://www.worldpop.org

4.) Averaged annual precipitation in Brazil in 2013 (Brazil Annual Precipitation 2013.tif) <br/>
5.) Averaged annual temperature in Brazil in 2013 (Brazil Annual Temperature 2013.tif)

These two datasets can be downloaded from historical monthly data from the [WorldClim database][worldclim]

[worldclim]: https://www.worldclim.org/data/monthlywth.html

6.) Land surface elevation in Brazil (Brazil Natural Lighting.tif)

This dataset was downloaded from the [STRM 90.0m DEM Digital Elevation Database][strm]

[strm]: https://srtm.csi.cgiar.org

7.) Averaged normalised differenced vegetation index (NDVI) for Brazil in 2013 (Brazil NDVI 2013.tif)

We used the MOD13A1.061 Terra Vegetation Indices 16-Day Global 500m for this analysis. Please note that extracting the NDVI data was a highly involved process especially for a large region. It is highly recommended to perform the extraction through [Google Earth Engine][gee] using bespoke Python code. In addition, for large regions, it is best to extract the NDVI data on a tile-by-tile basis in a recursive loop. Please refer to the Python script for extracting NDVI via [Google Earth Engine][gee] and use the "Tiled_Region_Brazil.shp" shapefile. Note that you will need to create a Google Account to implement the code in an code editor hosted on [Google Earth Engine][gee]. The downloads will send the tiles as .tif files to your Google Drive which you can download locally to your computer. Finally, you will need to stitch the tiles accordingly to form the country in GIS software (e.g., R, QGIS, ArcGIS etc.,).

[gee]: https://earthengine.google.com

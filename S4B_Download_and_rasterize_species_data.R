
###to download and make a raster from species data
###documentation on ridigbio https://cran.r-project.org/web/packages/ridigbio/ridigbio.pdf

#load package 
#(we're not loading them all at once, because sometimes they mask each other)
library(ridigbio)

#search and download data from iDigBio. 
#replace 'genus' and 'specificEpithet' with the species you want. You can get rid of 'specificEpithet' if you just want to use
#genus- you can also use higher taxa if you want to; use 'data.dwc:family' or 'data.dwc:order'. Don't be tempted to use
#'data.dwc:scientifiName'- that category seems to be full of errors. If you do use a higher order, you might want to add
#'genus' and 'specificEpithet' to the 'fields' to check for errors.

#I chose Myzus persicae (pea aphid) because I know it's a common pest and so would have good collection data
speciesdata <- idig_search_records(rq = list(geopoint=list(type="exists"), genus = "myzus", "data.dwc:specificEpithet" = "persicae"),
                                   fields = c("geopoint"))
#check your data
head(speciesdata)

###convert your data into a raster map

#load these packages
library(raster)
library(rgdal)

#download map files to use as raster masks
#I'm only including data from one country, because some of the niche data, like landuse, or soil type,
#only seem available on a national level, but there might be ways around this
US <- getData('GADM', country = 'USA', level=1)

#creating shapefile from speciesdata. Lat and lon are switched. CRS of US map is applied to species data
speciesdataSP <- SpatialPointsDataFrame(speciesdata[,1:2], speciesdata, proj4string = crs(US))

#plot species data against US map
plot(speciesdataSP)
plot(US, add = TRUE)

#crops species data to only include data collected in the US
cropspeciesdataSP <- speciesdataSP[US, ]

#plot cropped data against US map
plot(cropspeciesdataSP, pch = '.')
plot(US, add = TRUE)

#measures max and min lat and lon of species data shapefile
extent(cropspeciesdataSP)

#saves only the data portion of the shapefile as a dataframe. Basically, the cropped portion of the 
#original datafile
USspeciesdata <- cropspeciesdataSP@data

#making raster file
#create empty raster based on cropspeciesdataSP
#create values to plug into raster files
#arbitarily chosen cell size- 0.25 is 1/4 of a minute, I think
cell_size <- 0.25

#use extent from cropspeciesdataSP
extent(cropspeciesdataSP)

#I'm doing this manually, but there's probably an easy way to code it (x = lon, y = lat)
lon_min <- -159.77; lon_max <- -68.01; lat_min <- 21.30; lat_max <- 48.43

#This is calculating how the cells are going to be laid out in the raster
ncols <- ((lon_max - lon_min)/cell_size)+1; nrows <- ((lat_max - lat_min)/cell_size)+1

#create an empty raster
speciesraster <- raster(nrows=nrows, ncols=ncols, xmn=lon_min, xmx=lon_max, ymn=lat_min, ymx=lat_max, 
                     res=0.25, crs="+proj=longlat +datum=WGS84")

#rasterize species data
speciesraster <- rasterize(USspeciesdata, speciesraster, fun = "count")

 
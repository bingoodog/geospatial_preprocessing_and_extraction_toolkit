
This vignette describes... 

# Landsat Time Series
Below is a simple, step-by-step guide to processing Landsat satellite imagery using Google Earth Engine (GEE) and the landsat_time_series.js script found in [https://code.earthengine.google.com/?accept_repo=users/bgcasey/science_centre](https://code.earthengine.google.com/?accept_repo=users/bgcasey/science_centre). The following code snippets are meant to be copied into the GEE code editor.

# Landsat Time Series
## 1. Setup

### Load Helper Functions

Load helper functions to simplify various tasks like date generation, image processing, and exporting results.

- `functions/utils`: Provides utility functions for satellite imagery and various geospatial analyses:

    - **`createDateList`**: Generates a list of dates for time series analysis based on a specified start date, end date, interval, and unit.
    - **`exportImageCollection`**: Exports an image collection to Google Drive, supporting custom file naming and export parameters.
    - **`focalStats`**: Computes focal statistics (e.g., mean) over a specified kernel size, helping to smooth or aggregate spatial data.

- `functions/landsatTimeSeries`: Processes Landsat imagery by harmonizing spectral reflectance values, calculating vegetation indices, and merging results. The script processes Landsat satellite imagery (Landsat 5, 7, 8, and 9), harmonizes spectral reflectance values from different sensors, calculates selected vegetation indices, and merges the results into a single image collection. The process prioritizes using Landsat 5, 8, and 9 over Landsat 7 due to the latter's Scan Line Corrector (SLC) failure.
    
    **Steps performed by the script:**
    
    1. Retrieves and harmonizes Landsat Surface Reflectance (SR) collections for the specified time period and area of interest (AOI).
    2. Combines harmonized Landsat 5, 7, 8, and 9 collections, prioritizing Landsat 5, 8, and 9 over 7.
    3. Processes the combined collection and calculates composites of selected vegetation indices and merges them into a single image collection.
    
    
- `functions/landsatIndicesAndMasks`: This script defines functions to calculate various spectral indices and apply masks to a time-series of Landsat images. The indices include vegetation, moisture, and stress-related indices. Masks are used for cloud, snow, and QA filtering to ensure accurate data analysis. The functions included in this script are automatically called by `functions/landsatTimeSeries.js`
    

```javascript
var utils = require("users/bgcasey/science_centre:functions/utils");
var landsatTimeSeries = require("users/bgcasey/science_centre:functions/landsat_time_series");
var landsatIndicesAndMasks = require("users/bgcasey/science_centre:functions/landsat_indices_and_masks");
```

### Define Area of Interest (AOI)

This section sets the geographic area for analysis. The time series of Landsat images will be extracted for this region. The following code defines and area of interest around Calling Lake, Alberta, Canada.

```javascript
var aoi = ee.Geometry.Polygon([
  [-113.5, 55.5],  // Top-left corner
  [-113.5, 55.0],  // Bottom-left corner
  [-112.8, 55.0],  // Bottom-right corner
  [-112.8, 55.5]   // Top-right corner
]);
```

### Create Date List for Time Series

Use the `utils.createDateList` function create a list of starting points for time intervals used to extract a time series of satelite images. The `createDateList` function generates a list of dates at a specified interval, beginning on the provided start date and ending on the end date. 

**Function Arguments:**

- `Date_Start`: The start date of the time series (e.g., `ee.Date('2023-06-01')`).
    
- `Date_End`: The end date of the time series (e.g., `ee.Date('2024-06-01')`).
    
- `interval`: The step size to advance between dates (e.g., 1).
    
- `intervalType`: The unit for the interval (e.g., `'years'`, `'months'`, `'weeks'`).
    

``` js
var dateList = utils.createDateList(
  ee.Date('2020-06-01'), ee.Date('2024-06-01'), 1, 'years'
);
print("Start Dates", dateList);
```
### Define Reducer Statistic

Specifies how to summarize pixel values over time. Options include 'mean', 'median', 'max', etc.

```javascript
var statistic = 'mean'; // Options: 'mean', 'median', 'max', etc.
```

## 2. Landsat Time Series Processing

### Calculate Spectral Indices

The `landsatTimeSeries.ls_fn` function processes Landsat images and calculates various spectral indices over the dates defined in `var dateList`.

**Function Arguments:**

- `dates`: The list of start dates for each interval in the time series.
    
- `interval`: The number of units to advance for the end date of each interval (e.g., 121 days).
    
- `intervalType`: The type of interval ('days', 'weeks', 'months', 'years').
    
- `aoi`: The area of interest for clipping the processed images.
    
- `selectedIndices`: An array of indices to calculate (e.g., ['NDVI', 'BSI']).
    
- `statistic`: The statistical method to apply for summarizing data ('mean', 'median', 'max').
    

The function harmonizes Landsat 5, 7, 8, and 9 imagery, applies cloud and snow masks, calculates selected indices, and outputs a combined image collection summarized by the specified statistic for each time interval.

**Available Spectral Indices:**

- `BSI`: Bare Soil Index

- `DRS`: Distance Red & SWIR
- `DSWI`: Disease Stress Water Index
- `EVI`: Enhanced Vegetation Index
- `GNDVI`: Green Normalized Difference Vegetation Index
- `LAI`: Leaf Area Index
- `NBR`: Normalized Burn Ratio
- `NDMI`: Normalized Difference Moisture Index
- `NDSI`: Normalized Difference Snow Index
- `NDVI`: Normalized Difference Vegetation Index
- `NDWI`: Normalized Difference Water Index
- `SAVI`: Soil Adjusted Vegetation Index
- `SI`: Shadow Index
  
```javascript
var ls = landsatTimeSeries.ls_fn(
  dateList, 121, 'days', aoi,
  ['BSI', 'DRS', 'DSWI', 'EVI', 'GNDVI', 'LAI', 'NBR', 'NDMI', 'NDSI', 'NDVI', 'NDWI', 'SAVI', 'SI'],
  statistic
)
  .map(function(image) {
    var filteredBandNames = image.bandNames().filter(ee.Filter.neq('item', 'QA_PIXEL')); // remove QA pixels from output
    return image.select(filteredBandNames).toFloat(); // Ensures consistent data type
  });

//print("Landsat Time Series:", ls);  
```

## 3. Check Calculated Bands

Here users can view summary statistics calculated incices and view them in the map viewer window.
### 3.1 Check Band Summary Statistics

For each band in the image collection, calculate summary statistics (minimum, maximum, and standard deviation) to ensure values fall within expected ranges.

```js
var reducer = ee.Reducer.min()
  .combine(ee.Reducer.max(), '', true).
  .combine(ee.Reducer.stdDev(), '', true);

var collectionStats = utils.calculateImageCollectionStats(ls, aoi, 1000, 1e13, reducer);
print(collectionStats, "Image Statistics");

// Export statistics to CSV for further review
utils.exportStatsToCSV(collectionStats, 'image_stats');
```

### 3.2 Check Band Data Types

Ensure all bands have consistent data types. All bands need to be the same data type  to be exported as multiband rasters.

```js
var image_first = ls.first();
print("Band Names", image_first.bandNames());
print("Band Types", image_first.bandTypes());
```

### 3.3 Visualize NDVI

Visualize the NDVI for the first image in the collection.

```js
var ndviVisParams = {
  min: -0.5,
  max: 1.0,
  palette: ['blue', 'white', 'green']
};

var ndvi_first = image_first.select('NDVI');

// Reduce resolution for easier visualization
var ndvi_firstLowRes = ndvi_first.reproject({
  crs: ndvi_first.projection(),
  scale: 2000
});

// Center map on AOI and add NDVI layer
Map.centerObject(aoi, 7);
Map.addLayer(ndvi_first, ndviVisParams, 'NDVI (Low Res)');

// Visualize missing pixels
var missingPixelsMask = ndvi_first.mask().not();
Map.addLayer(missingPixelsMask, {min: 0, max: 1, palette: ['white', 'black']}, 'Missing Pixels');
```


## 4. Export Time Series to Google Drive

This section demonstrates how to export each image in the processed collection as multiband GeoTIFFs to Google Drive by using the function `utils.exportImageCollection`.

**Function Arguments:**

- `collection`: The image collection to export.
    
- `aoi`: The area of interest to which images will be clipped.
    
- `folder`: The name of the folder in Google Drive where images will be saved.
    
- `scale`: The spatial resolution of the exported images, in meters.
    
- `crs`: The coordinate reference system for the exported images.
    
- `fileNameFn`: A custom function to generate file names based on image metadata (e.g., year).
    

The function processes each image by:

1. Clipping it to the specified AOI.
    
2. Applying the custom naming convention.
    
3. Exporting it to Google Drive as a multiband GeoTIFF with the specified scale and CRS.

```js
/* Export parameters */
var folder = 'gee_exports';
var scale = 30; // 30-meter resolution
var crs = 'EPSG:4326'; // WGS 84 CRS

/* Define file naming function */
var fileNameFn = function(img) {
  var year = img.get('year').getInfo() || 'unknown';
  return 'landsat_multiband_' + year;
};

/* Export images to Google Drive */
utils.exportImageCollection(ls, aoi, folder, scale, crs, fileNameFn);
```

---


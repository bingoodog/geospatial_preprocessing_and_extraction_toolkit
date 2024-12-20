
#' Mosaic Rasters
#'
#' This function creates a mosaic from all raster files (`.tif`) located 
#' in a specified directory. It saves the resulting mosaic to a file.
#'
#' @param path_name Character. Path to the directory containing raster files.
#' @param export_filename Character. Full path where the resulting mosaic 
#' raster will be saved.
#' @param fun Character. Function to use for aggregating overlapping 
#' raster values in the mosaic (e.g., "mean", "sum"). Defaults to 
#' "mean".
#'
#' @return A `SpatRaster` object representing the created mosaic.
#'
#' @details This function requires the following R packages:
#'          - terra
#'          
#' # Example usage of the function
#' 
#' source("scripts/preprocessing/r/create_mosaic_function.R")
#' 
#' mosaic <- mosaic_rasters(
#'   path_name = "X:/samba/abmisc/spatial_data/temp/",
#'   export_filename = "X:/samba/abmisc/spatial_data/landsat/"
#'     "all_landsat.tif",
#'   fun = "mean"
#' )
#' print(mosaic)
#' 
mosaic_rasters <- function(path_name, export_filename, fun = "mean") {
  # Ensure the path ends with a slash
  if (!endsWith(path_name, "/")) {
    path_name <- paste0(path_name, "/")
  }
  
  # Step 1: List all .tif files in the specified directory
  fl <- list.files(path = path_name, pattern = '\\.tif$', 
                   recursive = TRUE, full.names = TRUE)
  
  # Step 2: Check if any .tif files are found
  if (length(fl) == 0) {
    stop("No .tif files found in the specified directory.")
  }
  
  # Step 3: Create a SpatRasterCollection from the .tif files
  rsrc <- terra::sprc(fl)
  
  # Step 4: Create a mosaic using the specified aggregation function
  m <- terra::mosaic(rsrc, fun = fun)
  
  # Step 5: Clear rasters from memory
  rm(rsrc)
  gc() # Run garbage collection to ensure memory is freed
  
  # Step 6: Write the mosaic to the specified export filename
  terra::writeRaster(m, filename = export_filename, 
                     overwrite = TRUE)
  
  # Step 7: Return the created mosaic
  return(m)
}




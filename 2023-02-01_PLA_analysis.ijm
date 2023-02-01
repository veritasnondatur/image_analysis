// Codebase for automated analysis of PLA assay with ImageJ/Fiji
// Applied to fluorescent images in channels: green-GFP (transduciton efficiency), red-PLA speckles (PLA signal), blue-DAPI (nuclei)
// Author: Vera Laub
// Latest update: 2023-02-01

input = "~/input/"     // set input directory to load images, relative to where script is stored
output = "~/output/"   // assign output folder
suffix = ".nd2"

processFolder(input);
// function to scan folders/subfolders/files to find files with correct suffix
// 2023-01-09, VL: not included yet (want to get code to run on individual images first)
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator + list[i]);
		if(endsWith(list[i], suffix))
			processFile(input, output, list[i]);
	}
}
function processFile(input, output, file) {
run("Bio-Formats Windowless Importer", "open=" + input + file + " autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT"); // import image (merged channels, not slpit!)

// Manual image import (for trial)
image_number = "_001"
rename("nikon_image"); // rename original file in neutral way 

// Define nuclei with DAPI channel
selectWindow("nikon_image");
run("Duplicate...", "title=DAPI duplicate channels=3"); //duplicate DAPI-channel
setOption("ScaleConversions", true); //convert to 8-bit image
run("8-bit");
run("Duplicate...", "title=DAPI_nuclei"); //duplicate
run("Auto Local Threshold", "method=Bernsen radius=50 parameter_1=0 parameter_2=0 white"); //apply threshold. Note: Method is variable and can be optimized for each condition; 
run("Options...", "iterations=2 count=1 black do=Erode"); //Smoothing and Watersheding of Intersection
run("Options...", "iterations=2 count=1 black do=Dilate");
run("Watershed Irregular Features", "erosion=15 convexity_threshold=0 separator_size=0-Infinity");
run("Analyze Particles...", "size=200-5000 show=[Count Masks] display clear summarize add");
//selectWindow("Count Masks of DAPI_nuclei");
//rename("separated_nuclei_count");

// Define transduction (GFP+) of cells
selectWindow("nikon_image");
run("Duplicate...", "title=GFP duplicate channels=2"); //duplicate GFP-channel
setOption("ScaleConversions", true); //convert to 8-bit image
run("8-bit");
run("Duplicate...", "title=GFP_filter"); //duplicate
run("Auto Threshold", "method=RenyiEntropy white"); //apply threshold. Note: Method is variable and can be optimized for each condition

// Combine info on presence of nucleus (DAPI) and transduction (GFP)
imageCalculator("AND create", "GFP_filter","DAPI_nuclei"); //Create intersection of GFP- and DAPI channel using Boolean Operation (AND)
selectWindow("Result of GFP_filter");
rename("intersection_DAPI+GFP");
run("Duplicate...", "title=intersection_smoothed"); //duplicate
run("Options...", "iterations=2 count=1 black do=Erode"); //Smoothing and Watersheding of Intersection
run("Options...", "iterations=2 count=1 black do=Dilate");
run("Watershed Irregular Features", "erosion=15 convexity_threshold=0 separator_size=0-Infinity");
run("Duplicate...", "title=DAPI+GFP_nuclei"); //duplicate
run("Analyze Particles...", "size=200-5000 show=[Count Masks] display clear include summarize add"); //counting amount of GFP+ nuclei, define as ROIs
selectWindow("Count Masks of DAPI+GFP_nuclei");
run("Duplicate...", "title=ROI"); //duplicate

// Filter PLA signal
selectWindow("nikon_image");
run("Duplicate...", "title=PLA duplicate channels=1"); //duplicate PLA-channel
setOption("ScaleConversions", true); //convert to 8-bit image
run("8-bit");
run("Duplicate...", "title=PLA_filter"); //duplicate
run("Auto Local Threshold", "method=Bernsen radius=1 parameter_1=20 parameter_2=0 white"); //apply threshold. Note: Method is variable and can be optimized for each condition

// Count PLA signal in ROI (GFP+ nuclei [DAPI])
imageCalculator("AND create", "ROI","PLA_filter")
selectWindow("Result of ROI"); 
rename("intersection_DAPI+GFP+PLA");
run("Duplicate...", "title=DAPI+GFP+PLA_signal"); //duplicate
run("8-bit");
run("Auto Local Threshold", "method=Contrast radius=15 parameter_1=0 parameter_2=0 white");
run("Analyze Particles...", "size=5-100 pixel show=[Count Masks] display clear summarize add"); //counting amount of PLA signal in GFP+nuclei (only speckles that are 5-100 pixel size)

// Save results
selectWindow("Summary"); //save Summary window as csv-file  
saveAs("Results" + image_number + ".csv");  // saveAs("Results", output + file + ".csv"); 
run("Close");
run("Close All");
if (isOpen("Results")){
	selectWindow("Results");
	run("Close");
}
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + output);	
}




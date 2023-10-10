/*
# Analysis of fluorescent yeast cells from microscope 
- August 2023
# Luca Torello Pianale (Chalmers University, lucat@chalmers.se) 

__Macro Developped under ImageJ 1.53t.__

------------------

This macro is used to _analyse fluorescent yeast cells from microscopy images_ 

__General info__:
* Run the macro in FIJI (www.fiji.sc) either dragging the .ijm in FIJI or selecting the file from `Plugins / Macros / Run...`.
* The language can be both IJM Macro or IJM Macro Markdown, if a final HTML file is desired.
* __Plugins Needed__: Bio-Formats, Template matching, ResultsToExcel, IJMMD (if final HTML of the macro is required). If not installed already, install them from `Help / Update... / Manage update sites`. 
* For plugin Template_matching: use the built-in update manager (ImageJ's Menu>Help>Update...), and add the following URL via "Manage update sites">"Add update site" -> http://sites.imagej.net/Template_Matching/ 

The __input folder__ should contain subfolders for each timepoint to be analyised with inside .tif files for each sample and channel analysed. 
The file name should look like "CG_t0_RAW_ch01", where "CG_t0" is the identifier for the sample and "_ch01" is the channel.

The __output folder__ should contain subfolders named:
* _"ROIs"_ (to save the ROIs for each photo as .zip files). 
* * _"Hyperstacks"_ (to save the hyperstacks for each timepoint with brightfield and fluorescent channels with background correction (if selected) as .tif files). 
* _"Hyperstacks_Fluo"_ (to save the hyperstacks for each timepoint with brightfield and fluorescent channel ratios (here, YFP/RFP and CFP/RPF) as .tif files). 
* _"Figures"_ (empty folder, needed for saving data analysis later on from R). 
* _"Scripts_Data_analysis"_ (folder with R scripts fordata analysis). 

If these are not the input/output formats (either in the files or analysis), changes should be applied in the macro. 

*/
/*
--------------------
# FRESH START FOR FIJI.

*/

close("*");
roiManager("reset");
run("Clear Results");
print("\\Clear");
roiManager("Show None");
roiManager("Associate", "true");
roiManager("Centered", "false");
roiManager("UseNames", "false");

/*
------------------
# SET FOLDER PATHS.

*/

input = getDirectory("Load files from directory...");
output = getDirectory("Save processed files to directory...");

YesNo = newArray("Choose!", "Yes", "No");
Dialog.create("Experimental presets");
	Dialog.addChoice("Make Hyperstacks?", YesNo);
	Dialog.addChoice("Backgroud Correction?", YesNo);
	Dialog.addChoice("ROI selection required?", YesNo);
Dialog.show();

makehyperstacks = Dialog.getChoice();
fluocorr = Dialog.getChoice();
ROIselect = Dialog.getChoice();

/*
------------------
# MAKE STACKS.

*/

if (makehyperstacks == "Yes") {
	
folders = getFileList(input);

for (i = 0; i < folders.length; i++){
	for (k = 1; k <= 4; k++){
		File.openSequence(input + folders[i] + "Project/", " start=" + k + " step=4");
		rename("C" + k);
	}
	
	//Make one big hyperstack with all the images in that timepoint
	run("Merge Channels...", "c1=[C1] c2=[C2] c3=[C3] c4=[C4] create");
	
	//Get the names of the samples	
	names = getFileList(input + folders[i] + "Project/");
	names = Array.slice(names,1);
	
	for (l = 0; l < names.length; l++){
		names[l] = substring(names[l], 8, indexOf(names[l], "_RAW"));
	}
	
	//Save each sample individually 
	num = nSlices/4;
	for (z = 1; z <= num; z++){
		selectWindow("Composite");
		run("Make Subset...", "channels=1-4 slices=" + z);
		saveAs("Tiff", output + "Hyperstacks/" + names[(z-1)*4] + ".tif");
		close();
	}
		
	close("*");
}}

/*
------------------
# BACKGROUND CORRECTION.

*/

if (fluocorr == "Yes") {
list_stacks = getFileList(output + "Hyperstacks/");
Array.sort(list_stacks);

for (i = 0; i < list_stacks.length; i++){
	
	//Open Hyperstack.
	filename = output + "Hyperstacks/" + list_stacks[i];
	open(filename);
	rename(replace(getTitle(), ".tif", ""));
	name = getTitle();

	run("Duplicate...", "duplicate");
	rename("C");
	selectWindow(name);
	close();
	selectWindow("C");
	
	//Fluorescence correction
	run("Split Channels");
	for (k = 2; k <= 4; k++){
		selectWindow("C" + k + "-C");
		run("Subtract Background...", "rolling=200 stack"); 
		run("32-bit");
		setAutoThreshold("Default dark");
		run("NaN Background");	
	}
	
	//Convert bright field in 32-bit
	selectWindow("C1-C");
	run("32-bit");
	
	//Make one big hyperstack with all the images in that timepoint
	run("Merge Channels...", "c1=[C1-C] c2=[C2-C] c3=[C3-C] c4=[C4-C] create");
	
	//Adjust LUTs
	color = newArray("Grays", "Red", "Yellow", "Cyan");
	for (k = 1; k <=4; k++) {
		Stack.setChannel(k);
		run(color[k-1]);
	}
	
	//Save
	saveAs("Tiff", output + "Hyperstacks/" + name + ".tif");
	close("*");
}}

/*
------------------
# ROI SELECTION.

*/

if (ROIselect == "Yes") {
	
roiManager("Show All");
list_stacks = getFileList(output + "Hyperstacks/");
Array.sort(list_stacks);

	for (i = 0; i < list_stacks.length; i++){
	
		print("Analysing stack " + i + 1 + " of " + list_stacks.length);
		print("Currently: " + list_stacks[i] + "");
		if (i == list_stacks.length-1) { print("Finished"); } 
		else { print("Up next: " + list_stacks[(i+1)] + "");
		}
		
		//Open Hyperstack.
		filename = output + "Hyperstacks/" + list_stacks[i];
		open(filename);
		rename(replace(getTitle(), ".tif", ""));
		name = getTitle();
	
		run("Duplicate...", "duplicate");
		rename("temporary");
		selectWindow(name);
		close();
		selectWindow("temporary");
		
		//Select ROIs
		setTool("ellipse");
		if (i == 0) {
			Dialog.create("Ratio Calculation");
			Dialog.addMessage("Select the cells you want with the elliptical selection.\nAdd the selection to the ROI Manager wit Ctrl+T.\nOnce Done, press OK in the next window.");
			Dialog.show();
		}
		waitForUser("Done?");
		
		//Create an array to select all the ROIs and save them.
		ROIarray = newArray(roiManager("count"));
		for (k = 0; k < roiManager("count"); k += 1) { ROIarray[k] = k; }
		roiManager("select", ROIarray);	
		roiManager("Save", output + "ROIs/RoiSet_" + name + ".zip");
		
		//Prepare "Fresh Start" for next loop.
		roiManager("reset");
		print("\\Clear");
		close("*");
		
}}

/*
------------------
# ANALYSE STACKS.

*/

//Preparation
Ratio_Names = newArray("Ratio_YR", "Ratio_CR");
roiManager("Show All");
list_stacks = getFileList(output + "Hyperstacks/");

for (i = 0; i < list_stacks.length; i++){
	
	//Open Hyperstack
	filename = output + "Hyperstacks/" + list_stacks[i];
	open(filename);
	rename(replace(getTitle(), ".tif", ""));
	name = getTitle();

	run("Duplicate...", "duplicate");
	rename("C");
	selectWindow(name);
	close();
	selectWindow("C");
	
	//Open ROIs
	roiManager("Open", output + "ROIs/RoiSet_" + name + ".zip");
	
	//Create an array to select all the ROIs
	ROIarray = newArray(roiManager("count"));
	for (k = 0; k < roiManager("count"); k += 1) { ROIarray[k] = k; }
	roiManager("select", ROIarray);	
	
	//Create the YR ratio stack
	run("Split Channels");
	imageCalculator("Divide create", "C3-C", "C2-C");
	rename(Ratio_Names[0]);
	run("Yellow");
	selectWindow("C3-C");
	close();
		
	//Create the CR ratio stack
	imageCalculator("Divide create", "C4-C", "C2-C");
	rename(Ratio_Names[1]);
	run("Cyan");
	selectWindow("C4-C");
	close();
	selectWindow("C2-C");
	close();
	
	//Measure fluorescence ratio stacks and save results
	for (k = 0; k < Ratio_Names.length; k++){
		run("Set Measurements...", "mean standard display redirect=" + Ratio_Names[k] + " decimal=3");
		roiManager("select", ROIarray);
		roiManager("Measure");
	}
	
	run("Read and Write Excel", "dataset_label=[" + name + "] no_count_column file=[" + output + "Results.xlsx] sheet=[" + name + "]");

	//Save Stacks with Ratios.
	selectWindow("C1-C");
	rename("BrightField");
	run("Grays");
	run("Images to Stack", "use");
	run("Properties...", "channels=3 slices=1 frames=1");
	run("Scale Bar...", "width=10 height=10 font=28 color=White background=Black location=[Upper Right] bold overlay label");
	saveAs("Tiff", output + "Hyperstacks_Fluo/" + name + "_ratios.tif");
	   
	//Prepare "Fresh Start" for next loop.
	roiManager("reset");
	run("Clear Results");
	print("\\Clear");
	close("*");
}

beep();
print("DONE! :D");

/*
-------------------------------------------------
__Done, good job!__ You can continue the analysis in R now!

*/
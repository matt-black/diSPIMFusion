macro "dispimfusion"{
// This macro is to create a User Interface within ImageJ, and 
// launch the spimFusionBatch.exe console and pass arguments to the console
// Min Guo, May 2019

//=================================================================
//=========You can customize your default parameters here!!!=======
//=================================================================
//*** Default setup****
//Objective type:40x,0.8NA; or 10x,0.3NA; or 50x adiSPIM
OBJx = 40; // 40: 40x,0.8NA; 10: 10x,0.3NA; 50: adiSPIM, 50x, 1.1NA and 28.6x, 0.71NA
// Default folders/files for CUDA app
appPath = "./diSPIMFusion/cudaLib/";
cudaExe = appPath + "bin/win/spimFusionBatch.exe";
filePSFA = appPath + "data/PSFA.tif";
filePSFB = appPath + "data/PSFB.tif";
filePSFA_bp = appPath + "data/PSFA_BP.tif";
filePSFB_bp = appPath + "data/PSFB_BP.tif";

// Default parameters
colorChoice="Single color";

nameA = "SPIMA-";
nameB = "SPIMB-";
//pixel size of tiff images
pixelSizeAx = 0.1625;
pixelSizeAy = 0.1625;
pixelSizeAz = 1;
pixelSizeBx = 0.1625;
pixelSizeBy = 0.1625;
pixelSizeBz = 1;

regChoice = "All images dependently"; // registration mode: 
									// "All images dependently", "All images independently",  "One image only", "No registration"
rotChoice = "90 deg by Y-axis"; // rotation angle for SPIMB: "No rotation", "90 deg by Y-axis",  "-90 deg by Y-axis"
tmxChoice= "Default"; //flagInitialTmx = 0;
FTOL = 0.0001;
itLimit= 3000;
saveRegA = true; // save registerred image A or not
saveRegB = true; // save registerred image B or not

iteration = 10; //iteration number for deconvolution
flagUnmatch = false; // use customized unmatched backprojector or not
saveXProj = false; //
saveYProj = false; //
saveZProj = true; //
saveXaxisProj = false; //
saveYaxisProj = true; //

outputBit = "16 bit"; // output data bit: 16 or 32
dQuery = false; // show GPU information or not
deviceNum = 0; // GPU device #

if(OBJx == 10){
	// if 10x objecttive
	filePSFA = appPath + "data/PSFA_10x.tif"; // directory to PSFA: 10x,0.3NA
	filePSFB = appPath + "data/PSFB_10x.tif"; // directory to PSFB: 10x,0.3NA
	pixelSizeAx = 0.65; // um
	pixelSizeAy = 0.65;
	pixelSizeAz = 3;
	pixelSizeBx = 0.65; // um
	pixelSizeBy = 0.65;
	pixelSizeBz = 3;
}

if(OBJx == 50){
	// if 50x objecttive, asymmetrical diSPIM
	filePSFA = appPath + "data/PSFA_1p1NA.tif"; // directory to PSFA: 50x,1.1NA
	filePSFB = appPath + "data/PSFB_0p71NA.tif"; // directory to PSFB: 28.6x,0.71NA
	pixelSizeAx = 0.13; // um
	pixelSizeAy = 0.13;
	pixelSizeAz = 0.7686;
	pixelSizeBx = 0.227; // um
	pixelSizeBy = 0.227;
	pixelSizeBz = 1.1701;
	rotChoice = "-90 deg by Y-axis";//"No rotation"; // rotation angle for SPIMB: "No rotation", "90 deg by Y-axis",  "-90 deg by Y-axis"
}

//=================================================================
//===================Customization End!!!!=========================
//=================================================================

// Color options
Dialog.create("diSPIM Fusion Color Selection");
items = newArray("Single color", "Multiple colors");
Dialog.addRadioButtonGroup("Color Options", items, 2, 1, colorChoice);
Dialog.show();
colorChoice = Dialog.getRadioButton();
if(colorChoice=="Single color"){
	pathSPIMA = getDirectory("Select SPIMA (base images) folder");
	pathSPIMB = getDirectory("Select SPIMB folder");
	pathOutput = getDirectory("Select output folder");
	multiColor = false;
}
else{
	pathSPIMA = 1; // to trigger multiple color processing
	pathSPIMB = getDirectory("Select main folder for multi-color input");
	pathOutput = getDirectory("Select output folder");
	multiColor = true;
}



SPIMAList = getFileList(pathSPIMA);
totalImageNum = lengthOf(SPIMAList);
imageNumStart = 0;
imageNumEnd = totalImageNum - 1;
imageNumInterval = 1;

print("Set input parameters...\n...\n");

Dialog.create("diSPIM Fusion");
	//input images parameters
Dialog.addMessage("Directories and File Names");
if(!multiColor){
	Dialog.addString("SPIMA Directory",pathSPIMA,50);
	Dialog.addString("SPIMB Directory",pathSPIMB,50);
}
else {
	Dialog.addString("Multi-color main Directory",pathSPIMB,50);
}
Dialog.addString("ImageA Name",nameA,20);
Dialog.addString("ImageB Name",nameB,20);
Dialog.addString("Output Directory",pathOutput,50);

Dialog.addNumber("Range:  Start #", imageNumStart,0,4,"   End #");
Dialog.setInsets(-28, 100, 0);
Dialog.addNumber("", imageNumEnd,0,4,"  Interval");
Dialog.setInsets(-28, 200, 0);
Dialog.addNumber("", imageNumInterval,0,4,"  Test #");
Dialog.setInsets(-28, 300, 0);
Dialog.addNumber("", imageNumStart,0,4," ");
Dialog.addMessage("Input Pixel Size");
Dialog.addNumber("ImageA x, y, z", pixelSizeAx,4,6,"um");
Dialog.setInsets(-28, 100, 0);
Dialog.addNumber(" ", pixelSizeAy,4,6,"um");
Dialog.setInsets(-28, 200, 0);
Dialog.addNumber(" ", pixelSizeAz,4,6,"um");
Dialog.addNumber("ImageB x, y, z", pixelSizeBx,4,6,"um");
Dialog.setInsets(-28, 100, 0);
Dialog.addNumber(" ", pixelSizeBy,4,6,"um");
Dialog.setInsets(-28, 200, 0);
Dialog.addNumber(" ", pixelSizeBz,4,6,"um");

// registration parameters
//Dialog.addMessage("\n");
Dialog.addMessage("Set Registration Options");
items = newArray( "No registration", "One image only", "All images dependently", "All images independently");
Dialog.setInsets(0, 40, 0);
Dialog.addRadioButtonGroup("Registration Mode", items, 2, 2, regChoice);
items = newArray("No rotation", "90 deg by Y-axis",  "-90 deg by Y-axis");
Dialog.setInsets(0, 40, 0);
Dialog.addRadioButtonGroup("ImageB Rotation", items, 1, 3, rotChoice);
items = newArray("Default", "Customized",  "2D registration");
Dialog.setInsets(0, 40, 0);
Dialog.addRadioButtonGroup("Initial matrix", items, 1, 3, tmxChoice);
Dialog.setInsets(0, 40, 0);
Dialog.addCheckbox("Save Reg SPIMA", saveRegA);
Dialog.setInsets(-22, 200, 0);
Dialog.addCheckbox("Save Reg SPIMB", saveRegB);
//Dialog.addMessage("\n");

// Joint Deconvolution parameters
//Dialog.addMessage("\n");
Dialog.addMessage("Set Deconvolution Options");
Dialog.addNumber("Iterations", iteration);
Dialog.setInsets(-28, 40, 0);
Dialog.addCheckbox("Unmatched BP", false);
Dialog.setInsets(0, 40, 0);
Dialog.addCheckbox("XProj", saveXProj);
Dialog.setInsets(-22, 120, 0);
Dialog.addCheckbox("YProj", saveYProj);
Dialog.setInsets(-22, 200, 0);
Dialog.addCheckbox("ZProj", saveZProj);
Dialog.setInsets(-22, 300, 0);
Dialog.addCheckbox("3D Proj: X axis", saveXaxisProj);
Dialog.setInsets(-22, 450, 0);
Dialog.addCheckbox("3D Proj: Y axis", saveYaxisProj);
Dialog.setInsets(0, 40, 0);
items = newArray("16 bit", "32 bit");
Dialog.addRadioButtonGroup("Output Image Bit", items, 1, 2, outputBit);

//GPU device settings
//Dialog.addMessage("\n");
//Dialog.addMessage("Set GPU Options");
Dialog.setInsets(0, 40, 0);
Dialog.addCheckbox("Show GUP Device Information", dQuery);
Dialog.addNumber("GPU Device #", deviceNum);

//default for cuda app
Dialog.addMessage("\n");
//Dialog.addMessage("Default for CUDA app");
//Dialog.addString("App location", appPath, 80);
Dialog.addMessage("Point spread functions");
Dialog.addString("PSFA", filePSFA, 50);
Dialog.addString("PSFB", filePSFB, 50);
//Dialog.setLocation(10,10);
Dialog.show();

//Get parameters from dialog
if(multiColor){
	pathSPIMA = 1; // to trigger multiple color processing
}
else {
	pathSPIMA = Dialog.getString();
}
pathSPIMB = Dialog.getString();
nameA = Dialog.getString();
nameB = Dialog.getString();
pathOutput = Dialog.getString();

imageNumStart = Dialog.getNumber();
imageNumEnd = Dialog.getNumber();
imageNumInterval = Dialog.getNumber();
imageNumTest = Dialog.getNumber();

pixelSizeAx = Dialog.getNumber();
pixelSizeAy = Dialog.getNumber();
pixelSizeAz = Dialog.getNumber();
pixelSizeBx = Dialog.getNumber();
pixelSizeBy = Dialog.getNumber();
pixelSizeBz = Dialog.getNumber();

// registration
regChoice = Dialog.getRadioButton();// 0, 1, 2, 3;
if(regChoice=="No registration"){
	regMode = 0;
}
else if(regChoice=="One image only"){
	regMode = 1;
}
else if(regChoice=="All images dependently"){
	regMode = 2;
}
else if(regChoice=="All images independently"){
	regMode = 3;
}

rotChoice = Dialog.getRadioButton();// 0, 1, -1;
if(rotChoice=="No rotation"){
	imRotation = 0;
}
else if(rotChoice=="90 deg by Y-axis"){
	imRotation = 1; // please add this choice to the cuda exe
}
else if(rotChoice=="-90 deg by Y-axis"){
	imRotation = -1;
}

tmxChoice = Dialog.getRadioButton();// 0, 1, 2;
if(tmxChoice=="Default"){
	flagInitialTmx = 0;
	fileTmx = "none";
}
else if(tmxChoice=="Customized"){
	flagInitialTmx = 1; // 
	fileTmx =  File.openDialog("Select transform matrix file");
}
else if(tmxChoice=="2D registration"){
	flagInitialTmx = 3;
	fileTmx = "none";
}
saveRegA = Dialog.getCheckbox(); //true: 1, false: 0
saveRegB = Dialog.getCheckbox(); //true: 1, false: 0

// deconvolution
iteration = Dialog.getNumber();
flagUnmatch = Dialog.getCheckbox(); //true: 1, false: 0
saveXProj = Dialog.getCheckbox(); //true: 1, false: 0
saveYProj = Dialog.getCheckbox(); //true: 1, false: 0
saveZProj = Dialog.getCheckbox(); //true: 1, false: 0
saveXaxisProj = Dialog.getCheckbox(); //true: 1, false: 0
saveYaxisProj = Dialog.getCheckbox(); //true: 1, false: 0
outputBit = Dialog.getRadioButton();// 0, 1, 2;
if(outputBit == "16 bit"){
	bitPerSample = 16;
}	
else{
	bitPerSample = 32;
}

//Set GPU Options
dQuery = Dialog.getCheckbox();
deviceNum = Dialog.getNumber();

//CUDA app
//appPath = Dialog.getString();
filePSFA = Dialog.getString();
filePSFB = Dialog.getString();

print("Parameters configuration done!!!\n\n");
if(multiColor)
	print("Processing multi-color images!!!\n\n");
else
	print("Processing single-color images!!!\n\n");
print("Lauching cuda program...\n...\n");
print("cuda program running...\n...\n");

// call CUDA app

if(flagUnmatch){ // use unmatched back projectors
	result = exec(cudaExe,pathOutput,pathSPIMA,pathSPIMB,nameA,nameB,imageNumStart,imageNumEnd,
		imageNumInterval,imageNumTest,pixelSizeAx,pixelSizeAy, pixelSizeAz,pixelSizeBx,pixelSizeBy,pixelSizeBz,
		regMode, imRotation,flagInitialTmx,fileTmx,FTOL,itLimit,saveRegA, saveRegB,filePSFA,filePSFB,iteration,saveXProj, 
		saveYProj, saveZProj, saveXaxisProj, saveYaxisProj, bitPerSample,dQuery,deviceNum, filePSFA_bp, filePSFB_bp);
}
else{// use traditional back projectors
	result = exec(cudaExe,pathOutput,pathSPIMA,pathSPIMB,nameA,nameB,imageNumStart,imageNumEnd,
		imageNumInterval,imageNumTest,pixelSizeAx,pixelSizeAy, pixelSizeAz,pixelSizeBx,pixelSizeBy,pixelSizeBz,
		regMode, imRotation,flagInitialTmx,fileTmx,FTOL,itLimit,saveRegA, saveRegB,filePSFA,filePSFB,iteration,saveXProj, 
		saveYProj, saveZProj, saveXaxisProj, saveYaxisProj, bitPerSample,dQuery,deviceNum);
}

print("caculation result:"+result);
}
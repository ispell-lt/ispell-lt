// This file was generated.  Do not modify by hand.

// this function verifies disk space in kilobytes
function verifyDiskSpace(dirPath, spaceRequired)
{
  var spaceAvailable;

  // Get the available disk space on the given path
  spaceAvailable = fileGetDiskSpaceAvailable(dirPath);

  // Convert the available disk space into kilobytes
  spaceAvailable = parseInt(spaceAvailable / 1024);

  // do the verification
  if(spaceAvailable < spaceRequired)
  {
    logComment("Insufficient disk space: " + dirPath);
    logComment("  required : " + spaceRequired + " K");
    logComment("  available: " + spaceAvailable + " K");
    return(false);
  }

  return(true);
}

// main
var srDest;
var err;
var fProgram;

// --- NOTE: FOR EACH DICTIONARY, MODIFY ONLY THESE ---
var dictName = "Lithuanian";
var regName = "lt.dic";
var dateString = "20021229";
srDest = 1032;
// --- END OF DICTIONARY SPECIFIC LINES  ---

err    = initInstall(dictName + " Mozilla Spelling Dictionary",
                     regName + " Spelling Dictionary",
                     "1.2." + dateString);

if (err)
  cancelInstall(err);

logComment("initInstall: " + err);

fProgram = getFolder("Program");
logComment("fProgram: " + fProgram);

if(verifyDiskSpace(fProgram, srDest))
{
  setPackageFolder(fProgram);
  err = addDirectory("",
                     "1.2." + dateString,
                     "bin",              // dir name in jar to extract 
                     fProgram, // Where to put this file (Returned from getFolder) 
                     "",                 // subdir name to create relative to fProgram
                     true );             // Force Flag 

  logComment("addDirectory() returned: " + err);

  // check return value
  if(!err)
  {
    err = performInstall(); 
    logComment("performInstall() returned: " + err);
  }
  else
    cancelInstall(err);
}
else
  cancelInstall(INSUFFICIENT_DISK_SPACE);

// end main

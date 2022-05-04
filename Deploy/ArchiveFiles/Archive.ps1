param
(
	[Parameter(Mandatory=$true,HelpMessage="Path to the directory to archive.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $directoryToArchive,
		
	[Parameter(Mandatory=$true,HelpMessage="Path to the directory where to store archives.")]
	[ValidateScript({If ($_) { $True } else { $False } })]
	[string] $archiveTargetDirectory,
    
	[Parameter(HelpMessage="Name of the archive file.")]
	[string] $archiveName,

	[Parameter(HelpMessage="Specify whether to delete files in the archived directory.")]
	[bool] $cleanDirectoryAfterArchiving = $true
)

function GetFullPath (
	[string] $filePath
)
{ 
    if([System.IO.Path]::IsPathFullyQualified($directoryToArchive)) {
        $processedFullPath = $filePath
    } else {
        $processedFullPath = [System.IO.Path]::Combine($PSScriptRoot, $filePath)
        $processedFullPath = [System.IO.Path]::GetFullPath($processedFullPath)
    }

    return $processedFullPath
}

function BuildArchiveFileName (
    [string] $archiveName
)
{
    $currentDateAndTime = [System.DateTime]::UtcNow.ToString("yyyyMMdd-HHmmss-fff")
    if([System.String]::IsNullOrEmpty($archiveName)) {
        $archiveName = "Archive"
    }
    
    return "$archiveName-$currentDateAndTime.7z"
}

function BuildArchiveTempDirectoryPath (
    [string] $directoryToArchivePath,
    [string] $archiveFilePath
)
{
    return [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($directoryToArchivePath), [System.IO.Path]::GetFileNameWithoutExtension($archiveFilePath))
}

function PrepareArchive (
    [string] $directoryToArchivePath,
    [string] $archiveFileTempDirectoryPath
)
{
    Write-Host "Test if the directory '$archiveFileTempDirectoryPath' exists"
    
    if(Test-Path -Path $archiveFileTempDirectoryPath -PathType Container) {
        $errorMessage = "The temporary directory '$archiveFileTempDirectoryPath' already exists."
        throw $errorMessage
    }

    if(-not (Test-Path -Path $directoryToArchivePath -PathType Container)) {
        $errorMessage = "The directory to archive '$directoryToArchivePath' does not exist."
        throw $errorMessage
    }

    Write-Host "Create the directory '$archiveFileTempDirectoryPath'"
    $newDirectoryName = $archiveFileTempDirectoryPath
    Rename-Item -Path $directoryToArchivePath -NewName $newDirectoryName
    
    Write-Host "Recreate the directory '$directoryToArchivePath'"
    New-Item -Path $directoryToArchivePath -ItemType Directory

    return $archiveFileTempDirectoryPath
}

function FinalizeArchive (
    [string] $archiveFileTempDirectoryPath
)
{
    Write-Host "Delete the temporary directory ('$archiveFileTempDirectoryPath')"
    Remove-Item $archiveFileTempDirectoryPath -Force -Recurse
}

Write-Host "Archive files script" -Foreground Cyan

$directoryToArchivePath = GetFullPath $directoryToArchive
$archiveTargetDirectoryPath = GetFullPath $archiveTargetDirectory
$archiveFileName = BuildArchiveFileName $archiveName
$archiveFilePath = [System.IO.Path]::Combine($archiveTargetDirectoryPath, $archiveFileName)

Write-Host "The files from the directory '$directoryToArchivePath' will be archived in the directory '$archiveTargetDirectoryPath' (file name: $archiveFileName)"

$sevenZipScriptPath = "C:\Program Files\7-Zip\7z.exe"
if(-not $cleanDirectoryAfterArchiving) {
    & $sevenZipScriptPath a $archiveFilePath $directoryToArchivePath -mx9 -bb0
} else {
    $archiveFileTempDirectoryPath = BuildArchiveTempDirectoryPath $directoryToArchivePath $archiveFilePath
    
    PrepareArchive $directoryToArchivePath $archiveFileTempDirectoryPath

    Write-Host "Archive files" -Foreground Gray
    & $sevenZipScriptPath a $archiveFilePath $archiveFileTempDirectoryPath -mx9 -bb0

    FinalizeArchive $archiveFileTempDirectoryPath
}

Write-Host "Files from the directory '$directoryToArchivePath' are archived into the file '$archiveFilePath'" -Foreground Green

<#
PS C:\Projets\Temp\Arcado\PrevisionsVentes\Processed\Previsions> & $sevenZipScriptPath 

7-Zip 21.07 (x64) : Copyright (c) 1999-2021 Igor Pavlov : 2021-12-26

Usage: 7z <command> [<switches>...] <archive_name> [<file_names>...] [@listfile]

<Commands>
  a : Add files to archive
  b : Benchmark
  d : Delete files from archive
  e : Extract files from archive (without using directory names)
  h : Calculate hash values for files
  i : Show information about supported formats
  l : List contents of archive
  rn : Rename files in archive
  t : Test integrity of archive
  u : Update files to archive
  x : eXtract files with full paths

<Switches>
  -- : Stop switches and @listfile parsing
  -ai[r[-|0]]{@listfile|!wildcard} : Include archives
  -ax[r[-|0]]{@listfile|!wildcard} : eXclude archives
  -ao{a|s|t|u} : set Overwrite mode
  -an : disable archive_name field
  -bb[0-3] : set output log level
  -bd : disable progress indicator
  -bs{o|e|p}{0|1|2} : set output stream for output/error/progress line
  -bt : show execution time statistics
  -i[r[-|0]]{@listfile|!wildcard} : Include filenames
  -m{Parameters} : set compression Method
    -mmt[N] : set number of CPU threads
    -mx[N] : set compression level: -mx1 (fastest) ... -mx9 (ultra)
  -o{Directory} : set Output directory
  -p{Password} : set Password
  -r[-|0] : Recurse subdirectories for name search
  -sa{a|e|s} : set Archive name mode
  -scc{UTF-8|WIN|DOS} : set charset for for console input/output
  -scs{UTF-8|UTF-16LE|UTF-16BE|WIN|DOS|{id}} : set charset for list files
  -scrc[CRC32|CRC64|SHA1|SHA256|*] : set hash function for x, e, h commands
  -sdel : delete files after compression
  -seml[.] : send archive by email
  -sfx[{name}] : Create SFX archive
  -si[{name}] : read data from stdin
  -slp : set Large Pages mode
  -slt : show technical information for l (List) command
  -snh : store hard links as links
  -snl : store symbolic links as links
  -sni : store NT security information
  -sns[-] : store NTFS alternate streams
  -so : write data to stdout
  -spd : disable wildcard matching for file names
  -spe : eliminate duplication of root folder for extract command
  -spf : use fully qualified file paths
  -ssc[-] : set sensitive case mode
  -sse : stop archive creating, if it can't open some input file
  -ssp : do not change Last Access Time of source files while archiving
  -ssw : compress shared files
  -stl : set archive timestamp from the most recently modified file
  -stm{HexMask} : set CPU thread affinity mask (hexadecimal number)
  -stx{Type} : exclude archive type
  -t{Type} : Set type of archive
  -u[-][p#][q#][r#][x#][y#][z#][!newArchiveName] : Update options
  -v{Size}[b|k|m|g] : Create volumes
  -w[{path}] : assign Work directory. Empty path means a temporary directory
  -x[r[-|0]]{@listfile|!wildcard} : eXclude filenames
  -y : assume Yes on all queries
#>
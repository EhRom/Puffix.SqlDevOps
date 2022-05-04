# Archive files

The [Archive.ps1](https://github.com/EhRom/Puffix.SqlDevOps/blob/master/Deploy/ArchiveFiles/Archive.ps1) is a simple script used to archive files using the [7-7ip tool](https://www.7-zip.org/).

The script has 4 parameters:
- `$directoryToArchive` (mandatory): the path to the directory to archive,
- `$archiveTargetDirectory` (mandatory): the path to the directory where to store the archives,
- `$archiveName`: the archive name (if not specified, the *Archive* is used)
- `$cleanDirectoryAfterArchiving`: specify whether to delete archived files.

Sample usage:
```powershell

$directoriesToArchive = @{
    "Directory1"="C:\SamplePath1\Directory1\";
    "Directory2"="C:\SamplePath2\Directory2\"
}

$baseArchiveDirectory = "C:\ArchiveDirectory\Archives"

foreach ($element in $directoriesToArchive.Keys) {
    Write-Host "Archive $($element) from $($directoriesToArchive[$element]) to $baseArchiveDirectory"

    & .\Archive.ps1 $directoriesToArchive[$element] $baseArchiveDirectory $element $true
}
```

[Back to Deploy section](https://github.com/EhRom/Puffix.SqlDevOps/tree/master/Deploy)

[Back to root](https://github.com/EhRom/Puffix.SqlDevOps)
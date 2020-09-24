<#
.SYNOPSIS
   JSON-CLI helper
.AUTHOR
   Christophe AVONTURE
.DESCRIPTION
    This script will compare two JSON files with each other and for each value
    defined in the "original" file a check will be made in the second file to
    detect if the value would have been modified. If it is the case, the modified
    value will be displayed on the screen.

    The goal is to highlight only the modified values of the second file and
    not to make a complete "diff" between the two files.

    Rely on https://github.com/swaggest/json-cli
.EXAMPLE
    Display the help screen
    powershell .\json-diff.ps1 -help

    Run the script
    powershell .\json-diff.ps1 original.json updated.json
#>
param (
    # Show the help screen
    [switch] $help = $false,
    # First file, the original one
    [parameter(Position=0, Mandatory=$false)][String]$originalPath="",
    # Second file, the one that will be compared with the original
    [parameter(Position=1, Mandatory=$false)][String]$newPath=""
)
begin {
    # Force variable declaration
    Set-StrictMode -Version 2.0

    # Name of the tool to run
    Set-Variable TOOL -option Constant -value "JSON CLI tool - Compare json files"

    # Repository from where to download the tool
    Set-Variable REPOSITORY -option Constant -value "https://github.com/swaggest/json-cli"

    # Binary of the tool that should be retrieved on the system
    Set-Variable BINARY -option Constant -value "vendor\bin\json-cli.bat"

    # Name of the temporary result file
    Set-Variable OUTPUT -option Constant -value "tmp\result.json"

    # Path to the script that we'll use (f.i. vendor\bin\json-cli)
    $global:bin = ""

    # Full name of the resulting file (f.i. c:\...\tmp\result.json)
    $global:output = ""

    <#
    .SYNOPSIS
        Display the help screen
    .OUTPUTS
        void
    #>
    function showHelp() {

        Write-Host " $TOOL" -ForegroundColor Green

        $me = [io.path]::GetFileNameWithoutExtension($global:me)

        Write-Host $(
            "`n Usage: $me [-help] <original.json> <compared.json>`n"
        ) -ForegroundColor Cyan

        Write-Host $(
            " -help           Show this screen`n"
        )

        Write-Host $(
            " <original.json> Name of the original JSON file, the one used as the template`n"
        )
        Write-Host $(
            " <compared.json> Name of the 'Compared with' file, the one in which changes will be inspected`n"
        )

        Write-Host $(" Some examples`n -------------`n")
        Write-Host $(" $me original.json updated.json ") -ForegroundColor Cyan -NoNewline
        Write-Host $(" Show the list of keys from updated.json that have been modified i.e. whose " +
            "value is different in the original file.`n")

        Write-Host $(" Run $me samples\original.json samples\updated.json for a real example") -ForegroundColor Yello

        return
    }

    <#
    .SYNOPSIS
        Retrieve the executable; die if not present
    .OUTPUTS
        void
    #>
    function getBinary() {

        # Binary to use
        $currentDir = "$PSScriptRoot"

        if (Test-Path -Path "$currentDir\$BINARY" -PathType Leaf) {
            # Installed as a local dependency of the project
            $global:bin = "$currentDir\$BINARY"
        }

        if ([string]::IsNullOrEmpty($global:bin)) {
            Write-Host "Sorry $TOOL is missing on your system`n" -ForegroundColor Red
            Write-Host $("Please install it:")
            Write-Host $("   1. Change the current working folder to $currentDir")
            Write-Host $("   2. Run 'composer require swaggest/json-cli'`n")
            Write-Host $("Get more informations from $REPOSITORY")
            exit 99
        }

    }

    <#
    .SYNOPSIS
        Display the result of the job to the console
    .OUTPUTS
        void
    #>
    function showResults() {

        if (-not (Test-Path $global:output -pathType "Leaf")) {
            Write-Host " Oups, the resulting $global:output file is missing" -ForegroundColor Red
            exit 999
        }

        # Get the list of modified values in the "compared-with" file
        $modifiedNew = $(
            Get-Content $global:output |
            ConvertFrom-Json |
            Select-Object -ExpandProperty "modifiedNew" |
            ConvertTo-Json
        )

        if ([string]::IsNullOrEmpty($modifiedNew)) {
            Write-Host $(" There are no modified values in $newPath i.e. all keys defined in " +
                "$originalPath have the same values in $newPath`n")

            Write-Host $(" Note: this doesn't means here that the two files are strictly indentical " +
                "but that every keys defined in $originalPath are still defined in $newPath " +
                "with the exact same value") -ForegroundColor Yellow
        } else {
            Write-Host $(" Somes keys in $originalPath have been modified in $newPath")
            Write-Host $(" The list below show the new values saved in $newPath`n")

            Write-Host $modifiedNew -ForegroundColor DarkGray

            Write-Host $("`n Analyze the output here above carefully and take actions if needed. " +
                "Does these changes are still relevant f.i.?") -ForegroundColor Green
        }

    }

    <#
    .SYNOPSIS
        Make sure the two files i.e. the original one and the updated one exists,
        exit otherwise
    .OUTPUTS
        void
    #>
    function checkFilesExists() {

        $me = [io.path]::GetFileNameWithoutExtension($global:me)

        if ([string]::IsNullOrEmpty($originalPath)) {
            Write-Host "`n Please specify the path to your 'Original JSON' file, abort`n" -ForegroundColor Red
            Write-Host " For instance: $me %GIT_HOOKS%\config\hooks.json .config\hooks.json`n" -ForegroundColor Yellow
            Write-Host " Run $me -help to get more detailled informations"
            exit 1
        }

        if ([string]::IsNullOrEmpty($newPath)) {
            Write-Host "`n Please specify the path to your 'Compared with' file, abort`n" -ForegroundColor Red
            Write-Host " For instance: $me %GIT_HOOKS%\config\hooks.json .config\hooks.json" -ForegroundColor Yellow
            Write-Host " Run $me -help to get more detailled informations"
            exit 2
        }


        if (-not(Test-Path $originalPath -PathType "Leaf")) {
            Write-Host "`n $originalPath doesn't exists, abort" -ForegroundColor Red
            exit 3
        }

        if (-not(Test-Path $newPath -PathType "Leaf")) {
            Write-Host "`n $newPath doesn't exists, abort" -ForegroundColor Red
            exit 4
        }

        if ($originalPath -eq $newPath) {
            Write-Host "`n The mentioned Original and Compared with files are one and the same file, abort" -ForegroundColor Red
            exit 5

        }
    }

    <#
    .SYNOPSIS
        Run the json-cli tool and get results
    .OUTPUTS
        void
    #>
    function doJob() {

        $title = "= Run $TOOL ="
        $len = $title.Length
        $line = "=" * $len      # Same than str_repeat("=", $len) in PHP

        Write-Host "`n $line`n $title`n $line`n"

        getBinary




        Write-Host " Running $global:me`n" -ForegroundColor Cyan

        Write-Host $(
            " Binary:        $global:bin `n" +
            " Original JSON: $originalPath`n" +
            " Compared with: $newPath") -ForegroundColor DarkGray

        checkFilesExists

        $argumentList = "diff-info $originalPath $newPath --pretty --with-paths " +
            "--with-contents --output $global:output"

        Write-Host $("`n Start: $global:bin $argumentList`n") -ForegroundColor Yellow

        if (Test-Path $global:output -pathType "Leaf") {
            Remove-Item -Path $global:output
        }

        Start-Process "$global:bin" -ArgumentList "$argumentList" -NoNewWindow -Wait

        showResults
    }

    #region Entry point
    $global:me = "$($PSScriptRoot)\$($MyInvocation.MyCommand.Name)"
    $global:output = "$($PSScriptRoot)\$OUTPUT"

    if ($help) {
        showHelp
        exit
    }

    #region samples
    #Just for the sample; make sure to use the correct path i.e. the one of the script
    if ((-not(Test-Path $originalPath -PathType "Leaf")) -and ($originalPath -eq "samples\original.json")) {
        $originalPath = "$PSScriptRoot\$originalPath"
    }

    if ((-not(Test-Path $newPath -PathType "Leaf")) -and ($newPath -eq "samples\updated.json")) {
        $newPath = "$PSScriptRoot\$newPath"
    }
    #endregion samples

    doJob
    #endregion Entry point
}

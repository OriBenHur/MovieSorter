<#param($Work)

# restart PowerShell with -noexit, the same script, and 1
if (!$Work) {
    powershell -noexit -file $MyInvocation.MyCommand.Path 1
    return
}#>

##################################### Setting Initial Variables #####################################
$RootFolder = Split-Path -Parent ($MyInvocation.MyCommand.Path) 
$ErrorActionPreference = "SilentlyContinue"
$API = "http://www.omdbapi.com/"
$MatchFiles = @()
$IgnoreList = @()
$Rips  = "CAMRip","CAM","TS","TELESYNC","PDVD","WP","WORKPRINT","TC","TELECINE","PPV","PPVRip","SCR","SCREENER","DVDSCR",`
"DVDSCREENER","BDSCR","DDC","R5","R5.LINE","R5.AC3.5.1.HQ","DVDRip","DVDR","DVD-Full","Full-Rip","ISO rip","DVD-5","DVD-9",`
"DSR","DSRip","SATRip","DTHRip","DVBRip","HDTV","PDTV","TVRip","VODRip","VODR","WEBDL","WEB DL","WEB-DL","WEB","HDRip","WEB-Rip",`
"WEBRIP","WEB Rip","HDRip","WEB-Cap","WEBCAP","WEB Cap","BDRip","BRRip","Blu-Ray","BluRay","BLURAY","BDR","BD5","BD9","BD25","BD50",`
"420p","480i","720p","1080p","1080i"
#####################################################################################################



################################### Create Folder Browser Dialog ####################################

Add-Type -AssemblyName System.Windows.Forms
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
    SelectedPath = $RootFolder
    ShowNewFolderButton = $false
    Description ="Choose Root Folder To Process"
}
#####################################################################################################


#################################### Declaring TestWord Function ####################################
function TestWord($arg , $Filter)
{
    $bool = $true
    foreach ($item in $filter)
    {
        if($arg -eq $item)
        {
            $bool = $false
            break
        }
    }
    return $bool
}
#####################################################################################################



############################### Declaring TVShow Year Check  Function ###############################
function TVShowCheckYear($Show)
{
    $bool = $false
    foreach($Episode in $Show.Episodes)
    {
        if($Show.Episodes -ne $null)
        {
            if($Episode.Released -match "2016")
            {
                $bool = $true
                break
            }
        }
    }
    return $bool
}
#####################################################################################################



############################################### Work ################################################
if($FolderBrowser.ShowDialog() -eq "OK")
{
    $Dir = $FolderBrowser.SelectedPath
    $FileList = Get-ChildItem -Path "$Dir" -Recurse | ForEach-Object{ $_.FullName }
    foreach ($file in $FileList)
    {
        $baseDir = Split-Path $file -Parent
        $Matches = @()

        if((-not $MatchFiles.Contains($baseDir)) -and -not ($IgnoreList.Contains($baseDir))-and -not ((Get-Item $file) -is [System.IO.DirectoryInfo]))
        { 
            $ext = [IO.Path]::GetExtension($file)
            if(($ext -eq ".mp4") -or ($ext -eq ".avi") -or ($ext -eq ".mkv"))
            { 
                #$count++  
                $Name = Split-Path -Path "$file" -Leaf -Resolve
                $Name = [System.IO.Path]::GetFileNameWithoutExtension($Name)
                $SP =  "[sS][0-9]{2}[eE][0-9]{2}"
                if($Name -match $SP)
                {
                    $Matches = @()
                    $Name -match "[sS][0-9]{2}" >$null
                    $S = $matches[0]
                    $S = $S.trim("S"," ")
                    $Name = $Name -split $SP
                    $Name = $Name[0]
                    $Name = $Name.Substring(0,$Name.length-1)
                    #cmd.exe /c pause
                    $Movie = Invoke-WebRequest $API"?t=$Name&Season=$S&r=json"
                    #write-host $API"?t=$Name&Season=$S&r=json"
                    $Movie = $Movie.Content
                    #$Movie = $Movie.Substring($Movie.indexof("["),$Movie.indexof("]")-73)
                    $Movie = $Movie | ConvertFrom-Json
                    if(TVShowCheckYear $Movie ){ $MatchFiles += $baseDir }
                    else{ $IgnoreList += $baseDir }
                }
                
                else
                {        
                    $MP = '[0-9]{4}'
                    $Name -match $MP>$null
                    [int]$Year = $Matches[0]
                    if(($Year -ne $null) -and ($Year -ge "1900"))
                    {  
                        if($Year -eq "2016") { $MatchFiles+=$baseDir }
                        else {$IgnoreList += $baseDir}
                    }
                    else
                    {
                        $TMP =  $Name -split "\."
                        $Name = ""
                        foreach($word in $TMP)
                        {
                            if(TestWord $word $Rips){ $Name += $word+'.'}
                            else { Break }
                        }
                        $Name = $Name.Substring(0,$Name.length-1)
                        $Movie = Invoke-WebRequest $API"?s=$Name&type=movie&$Data=json"
                        #write-host "$API$FileTitle=$Name&type=movie&$Data=json"
                        $Movie = $Movie.Content
                        $Movie = $Movie.Substring($Movie.indexof("["),$Movie.indexof("]")-9)
                        $Movie = $Movie | ConvertFrom-Json
                        $Name = $Name -replace "\." , " "
                        foreach($item in $Movie)
                        {
                            if(($item.Title -eq $Name) -and ($item.Type -eq "movie"))
                            {
                                if($item.Year -eq "2016") { $MatchFiles += $baseDir }
                                else {$IgnoreList += $baseDir}
                            } 
                        }
                    }
                }
            }
        }
    }
}
$count
$MatchFiles
#####################################################################################################

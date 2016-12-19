<#param($Work)

# restart PowerShell with -noexit, the same script, and 1
if (!$Work) {
    powershell -noexit -file $MyInvocation.MyCommand.Path 1
    return
}
#>
##################################### Setting Initial Variables #####################################
$RootFolder = Split-Path -Parent ($MyInvocation.MyCommand.Path) 
$ErrorActionPreference = "SilentlyContinue"
$API = "http://www.omdbapi.com/?"
$FileTitle = "s"
$Data = "r"
$MatchFiles= @()
$Rips  = "CAMRip","CAM","TS","TELESYNC","PDVD","WP","WORKPRINT","TC","TELECINE","PPV","PPVRip","SCR","SCREENER","DVDSCR",`
"DVDSCREENER","BDSCR","DDC","R5","R5.LINE","R5.AC3.5.1.HQ","DVDRip","DVDR","DVD-Full","Full-Rip","ISO rip","DVD-5","DVD-9",`
"DSR","DSRip","SATRip","DTHRip","DVBRip","HDTV","PDTV","TVRip","VODRip","VODR","WEBDL","WEB DL","WEB-DL","WEB","HDRip","WEB-Rip",`
"WEBRIP","WEB Rip","HDRip","WEB-Cap","WEBCAP","WEB Cap","BDRip","BRRip","Blu-Ray","BluRay","BLURAY","BDR","BD5","BD9","BD25","BD50"
#####################################################################################################



################################### Create Folder Browser Dialog ####################################

Add-Type -AssemblyName System.Windows.Forms
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog -Property @{
    SelectedPath = $RootFolder
}
$FolderBrowser.Description = "Choose Root Folder To Process"
[void]$FolderBrowser.ShowDialog()
$Dir = $FolderBrowser.SelectedPath
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



############################################### Work ################################################
$FileList = Get-ChildItem -Path "$Dir" -Recurse | ForEach-Object{ $_.FullName }
foreach ($file in $FileList)
{
    $baseDir = Split-Path $file -Parent
    if(-not($MatchFiles.Contains($baseDir)))
    {
        
        $ext = [IO.Path]::GetExtension($file)
        if(($ext -eq ".mp4") -or ($ext -eq ".avi") -or ($ext -eq ".mkv"))
        { 
            $count++  
            $Name = Split-Path -Path "$file" -Leaf -Resolve
            $Name = [System.IO.Path]::GetFileNameWithoutExtension($Name)
            $SP =  "[sS][0-9]{2}[eE][0-9]{2}"
            if($Name -match $SP)
            {
                $Name -match "[sS][0-9]{2}" >$null
                $S = $matches[0]
                $S = $S.trim("S"," ")
                $Name -match "[eE][0-9]{2}" >$null
                $E = $matches[0]
                $E = $E.trim("E"," ")
                $FileTitle ="t"
                $Name = $Name -split $sp
                $Name = $Name[0]
                #cmd.exe /c pause
                $Movie = Invoke-WebRequest "$API$FileTitle=$Name&Season=$S&Episode=$E&r=json"
                #write-host "$API$FileTitle=$Name&Season=$S&Episode=$E&r=json"
                $Movie = $Movie.Content
                $Movie = $Movie | ConvertFrom-Json
                foreach ($item in $Movie) 
                {
                    if($item.Type -eq "episode")
                    {
                        if($item.Year -eq "2016")
                        {
                            $MatchFiles+=$baseDir
                        }
                    }
                }
            }
            
            else
            {         
                $MP = '[0-9]{4}'
                $Name -match $MP>$null
                [int]$Year = $Matches[0]
                if(($Year -ne $null) -and ($Year -ge "1900"))
                {  
                    if($Year -eq 2016)
                    {
                        $MatchFiles+=$baseDir
                    }  
                }
                else
                {
                    $FileTitle = "s"
                    $TMP =  $Name -split "\."
                    $Name = ""
                    foreach($word in $TMP)
                    {
                        if(TestWord $word $Rips){ $Name += $word+'.'}
                        else { Break }
                    }
                    $Name = $Name.Substring(0,$Name.length-1)
                    $Movie = Invoke-WebRequest "$API$FileTitle=$Name&type=movie&$Data=json"
                    #write-host "$API$FileTitle=$Name&type=movie&$Data=json"
                    $Movie = $Movie.Content
                    $Movie = $Movie.Substring($Movie.indexof("["),$Movie.indexof("]")-9)
                    $Movie = $Movie | ConvertFrom-Json
                    $Name = $Name -replace "\." , " "
                    foreach($item in $Movie)
                    {
                        if(($item.Title -eq $Name) -and ($item.Type -eq "movie"))
                        {
                            if($item.Year -eq "2016")
                            {
                                $MatchFiles+=$baseDir
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
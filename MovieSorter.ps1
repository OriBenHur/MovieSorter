<#param($Work)

# restart PowerShell with -noexit, the same script, and 1
if (!$Work) {
    powershell -executionpolicy remotesigned -noexit -file $MyInvocation.MyCommand.Path 1
    return
}
#>
##################################### Setting Initial Variables #####################################
$RootFolder = Split-Path -Parent ($MyInvocation.MyCommand.Path) 
$ErrorActionPreference = "SilentlyContinue"
$API = "http://www.omdbapi.com/"
$MatchFiles = @()
#$IgnoreList = @()
$Filters = "CAMRip|CAM|TS|TELESYNC|PDVD|PTVD|PPVRip|SCR|SCREENER|DVDSCR|DVDSCREENER|BDSCR|R4|R5|R5LINE|R5.LINE|DVD|DVD5|DVD9|DVDRip|DVDR|TVRip|DSR|PDTV|SDTV|HDTV|HDTVRip|DVB|DVBRip|DTHRip|VODRip|VODR|BDRip|BRRip|BR.Rip|BluRay|Blu.Ray|BD|BDR|BD25|BD50|3D.BluRay|3DBluRay|3DBD|Remux|BDRemux|BR.Scr|BR.Screener|HDDVD|HDRip|WorkPrint|VHS|VCD|TELECINE|WEBRip|WEB.Rip|WEBDL|WEB.DL|WEBCap|WEB.Cap|ithd|iTunesHD|Laserdisc|AmazonHD|NetflixHD|NetflixUHD|VHSRip|LaserRip|URip|UnknownRip|MicroHD|WP|TC|PPV|DDC|R5.AC3.5.1.HQ|DVD-Full|DVDFull|Full-Rip|FullRip|DSRip|SATRip|BD5|BD9|Extended|Uncensored|Remastered|Unrated|Uncut|IMAX|(Ultimate.)?(Director.?s|Theatrical|Ultimate|Final|Rogue|Collectors|Special|Despecialized).(Cut|Edition|Version)|((H|HALF|F|FULL)[^\\p{Alnum}]{0,2})?(SBS|TAB|OU)|DivX|Xvid|AVC|(x|h)[.]?(264|265)|HEVC|3ivx|PGS|MP[E]?G[45]?|MP[34]|(FLAC|AAC|AC3|DD|MA).?[2457][.]?[01]|[26]ch|(Multi.)?DTS(.HD)?(.MA)?|FLAC|AAC|AC3|TrueHD|Atmos|[M0]?(420|480|720|1080|1440|2160)[pi]|(?<=[-.])(420|480|720|1080|2D|3D)|10.?bit|(24|30|60)FPS|Hi10[P]?|[a-z]{2,3}.(2[.]0|5[.]1)|(19|20)[0-9]+(.)S[0-9]+(?!(.)?E[0-9]+)|(?<=\\d+)v[0-4]|CD\\d+|3D|2D"
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
    if($arg -match $Filter)
    {
        $bool = $false
        break
    }
    return $bool
}
#####################################################################################################



############################### Declaring TVShow Year Check  Function ###############################
function TVShowCheckYear($Show)
{
    foreach($Episode in $Show.Episodes)
    {
        if($Show.Episodes -ne $null)
        {
            if($Episode.Released -match "2016")
            {
                return $true
            }
        }
    }
    return $false
}
#####################################################################################################



############################################### Work ################################################
if($FolderBrowser.ShowDialog() -eq "OK")
{
    $Dir = $FolderBrowser.SelectedPath
    $FileList = Get-ChildItem -Path "$Dir" -Recurse | ForEach-Object{ $_.FullName }
    foreach ($file in $FileList)
    {  
        #$baseDir = Split-Path $file -Parent
        $Matches = @()

        if((-not $MatchFiles.Contains($file)) -and -not ((Get-Item $file) -is [System.IO.DirectoryInfo]))
        { 
            $ext = [IO.Path]::GetExtension($file)
            if(($ext -eq ".mp4") -or ($ext -eq ".avi") -or ($ext -eq ".mkv"))
            { 
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
                    $URI = $API+"?t=$Name&Season=$S&r=json"
                    $Movie = Invoke-WebRequest $URI
                    #Write-Host $URI
                    $Movie = $Movie.Content
                    $Movie = $Movie | ConvertFrom-Json
                    if(TVShowCheckYear $Movie ){ $MatchFiles += $file }
                    #else{ $IgnoreList += $baseDir }
                }
                
                else
                {
                    $MP = '[0-9]{4}'
                    $Name -match $MP>$null
                    [int]$Year = $Matches[0]
                    if(($Year -ne $null) -and ($Year -ge 1900)-and ($Year -lt 2100))
                    {  
                        if($Year -eq "2016") { $MatchFiles += $file }
                        #else {$IgnoreList += $baseDir}
                    }
                    
                    else
                    {
                        $TMP =  $Name -split "\."
                        $Name = ""
                        foreach($word in $TMP)
                        {
                            if(TestWord $word $Filters){ $Name += $word+'.'}
                            else { Break }
                        }
                        $Name = $Name.Substring(0,$Name.length-1)
                        $URI = $API+"?s=$Name&type=movie&$Data=json"
                        $Movie = Invoke-WebRequest $URI
                        #Write-Host $URI
                        $Movie = $Movie.Content
                        $Movie = $Movie.Substring($Movie.indexof("["),$Movie.indexof("]")-9)
                        $Movie = $Movie | ConvertFrom-Json
                        $Name = $Name -replace "\." , " "
                        foreach($item in $Movie)
                        {
                            if(($item.Title -eq $Name) -and ($item.Type -eq "movie"))
                            {
                                if($item.Year -eq "2016") { $MatchFiles += $file }
                                #else {$IgnoreList += $baseDir}
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

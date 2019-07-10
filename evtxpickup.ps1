<#
VERSION      DATE          AUTHOR
0.3A      10/07/2019       op7ic
0.2A      08/05/2019       op7ic
0.1A      05/05/2019       op7ic
#> # Revision History


<#
  .SYNOPSIS
    This script collects all evtx files from systems across windows domain. Each file is then renamed to hostname-evtxname.evtx for ease of digestion
  .EXAMPLE
    evtxpickup.ps1 -output E:\evidence\
#>
param (
    [Parameter(Mandatory=$true)][string]$output
 )



function help(){
Write-Host @"
Usage: powershell -nop -exec bypass .\evtxpickup.ps1 -output E:\evidence\ [options]

Options:
  -output   Location where to store evtx files (full path)
"@
}

function fancyPickup($serverListArray, $folder){

foreach ($remoteServer in $serverListArray){
	# control running jobs, max 8 
	$running = @(Get-Job | Where-Object { $_.State -eq 'Running' })
	if ($running.Count -ge 8) {
	    $running | Wait-Job -Any | Out-Null
    }
	Write-Host "[+] Starting pickup for $remoteServer"
	Start-Job {
	param($foldername)#
	#EVTX files are stored in
	#%SystemRoot%\System32\Winevt\Logs\
	#Avoid 64kb logs
	#We only pick up from available systems (-ErrorAction SilentlyContinue)
	$LogArray = Get-ChildItem "FileSystem::\\$using:remoteServer\`C$\Windows\System32\Winevt\Logs\" -Recurse -ErrorAction SilentlyContinue | Where-Object{ $_.Length -ne 69632}  | Select-Object | 
	copy-item -Destination {"$foldername\$using:remoteServer-" + $_.Name }

	} -Arg $folder | Out-Null

}#EOF foreach

# Wait for all jobs to complete and results ready to be received
Wait-Job * | Out-Null

# Process the results
foreach($job in Get-Job)
{
    $result = Receive-Job $job
}
Remove-Job -State Completed

}


function enumerate($folder){

# Check if output folder exists
if (Test-Path $folder) {
}else{
Write-Host "[!] Specified output folder doesn't exist"
Exit 
}
# Enumerate systems connected to domain
$strFilter = "computer";
$objDomain = New-Object System.DirectoryServices.DirectoryEntry
$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.SearchScope = "Subtree"
$objSearcher.PageSize = 9999999
$objSearcher.Filter = "(objectCategory=$strFilter)";
$colResults = $objSearcher.FindAll()

$serverListArray = [System.Collections.ArrayList]@()
foreach ($i in $colResults)
{
        $objComputer = $i.GetDirectoryEntry()
        $remoteBOX = $objComputer.Name
		#Step 1 - enumerate the domain and save host list to array
		$serverListArray.Add($remoteBOX) | out-null
}

fancyPickup $serverListArray $folder
}

Write-Host "[+] Output directory: $output"

enumerate($output)
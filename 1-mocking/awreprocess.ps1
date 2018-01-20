<# Execute-AWRestAPI Powershell Script Help

    .SYNOPSIS
        This powershell script makes a REST API call to an AirWatch Server.
        This particular script will retrieve the device list infromation.

    .USAGE
        Ensure awupdaterc.ps1 is in the same directory. This file contains:
        1. User to authenticate with.
        2. Password for the user.
        3. The endpoint URL.

        Call this script to actually retreive the information. Options below:

    .PARAMETER outputFile (optional)
        This is not a required file, this just helps with printing out useful
        information.

    .PARAMETER configFile (optional)
        This is not a required file, this allows you to use a different
        awupdaterc.ps1 file if need be.

    .PARAMETER product (mandatory)
        Number of the product to reprocess in AirWatch console.
#>
[CmdletBinding()]
Param(
    [Parameter()]
    [string]$outputFile,

    [Parameter()]
    [string]$configFile,

    [Parameter(Mandatory = $True)]
    [string]$product
)
    
# Set up default if configFile is not already set.
If (!$configFile) {
    $configFile = ".\awupdaterc.ps1"
}

# Set up default if outputFile is not already set.
if (!$outputFile) {
    $outputFile = ".\device_list.csv"
}
# Source in the config file and its settings.
. $configFile

# Set our base call for the api.
$baseURL = $endpointURL + "/API/"

# Source build headers function.
. ".\buildheaders.ps1"

# Source Basic auth function.
. ".\basicauth.ps1"

# We know we're using json so set accept/content type as such.
$contentType = "application/json"

# Concatenate User information for processing.
$userInfo = $userName + ":" + $password
$restUser = Get-BasicUserForAuth $userInfo

# Get our headers.
$headers = Build-Headers $restUser $tenantAPIKey $contentType $contentType

# Setup our caller string to get the devices.
$changeURL = $baseURL + "mdm/products/$product/assigned"

# Write out information for us to know what's going on.
Write-Verbose ""
Write-Verbose "---------- Caller URL ----------"
Write-Verbose ("URL: " + $changeURL)
Write-Verbose "--------------------------------"
Write-Verbose ""
If ($Proxy) {
    If ($UserAgent) {
        $request = Invoke-RestMethod -Uri $changeURL -Headers $headers -OutFile ".\temp.json" -Proxy $Proxy -UserAgent $UserAgent
    }
    Else {
        $request = Invoke-RestMethod -Uri $changeURL -Headers $headers -OutFile ".\temp.json" -Proxy $Proxy
    }
}
Else {
    If ($UserAgent) {
        $request = Invoke-RestMethod -Uri $changeURL -Headers $headers -OutFile ".\temp.json" -UserAgent $UserAgent
    }
    Else {
        # Perform request
        $request = Invoke-RestMethod -Uri $changeURL -Headers $headers -OutFile ".\temp.json"
    }
}

# As we stored all the data into a file we need to read it in.
$data = Get-Content ".\temp.json" -Raw -Verbose | ConvertFrom-Json

# Initialize array of data to store.
$dataSet = @()

Write-Host $data

# Loop our devices found.
foreach ($device in $data | Select-Object DeviceId) {
    $details = @{}
    $id = $device.DeviceId
    $details = [ordered]@{
        ID = $id
    }
    $dataSet += New-Object PSObject -Property $details   
}
# Create the CSV to process from.
$dataSet | Export-CSV -Path $outputFile -NoTypeInformation


$deviceIDs = @{}
$deviceIDs.ForceFlag = "True"
$deviceIDs.DeviceIds = $dataset
$deviceIDs.ProductID = $product

$deviceIDs = $deviceIDs | ConvertTo-Json

$changeURL = $baseURL + "mdm/products/reprocessProduct"

# Write out information for us to know what's going on.
Write-Verbose ""
Write-Verbose "---------- Caller URL ----------"
Write-Verbose ("URL: " + $changeURL)
Write-Verbose "--------------------------------"
Write-Verbose ""

# Perform the action.
If ($Proxy) {
    If ($UserAgent) {
        $ret = Invoke-RestMethod -Method Post -Uri $changeURL -Headers $headers -ContentType $contentType -Body $deviceIDs -Proxy $Proxy -UserAgent $UserAgent
    }
    Else {
        $ret = Invoke-RestMethod -Method Post -Uri $changeURL -Headers $headers -ContentType $contentType -Body $deviceIDs -Proxy $Proxy
    }
}
Else {
    If ($UserAgent) {
        $ret = Invoke-RestMethod -Method Post -Uri $changeURL -Headers $headers -ContentType $contentType -Body $deviceIDs -UserAgent $UserAgent
    }
    Else {
        $ret = Invoke-RestMethod -Method Post -Uri $changeURL -Headers $headers -ContentType $contentType -Body $deviceIDs
    }
}
Write-Verbose $ret
# Sleep a little bit so AW doesn't think we need to be blocked.
Start-Sleep -m 500
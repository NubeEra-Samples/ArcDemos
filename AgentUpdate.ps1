<#
.SYNOPSIS
    This sample script is designed to ease the Arc Agent update at scale.

.DESCRIPTION
    This sample script is designed to ease the Arc Agent update at scale. It require the proxy URL in the form of http://proxyFQDN:port. If no proxy is necessary, enter NONE. The script will behave accordingly.
    It will download the latest agent version from the Microsoft Download web site and will run the installation silently (unattended mode).

.PARAMETER proxy
    Required. The proxy server and the port (i.e. http://myproxy:8080). Enter NONE to not use any proxy.

.EXAMPLE
    .\Update-ArcAgent_Windows.ps1 -proxy none

.NOTES
    AUTHOR:   Bruno Gabrielli
    VERSION:  1.0
    LASTEDIT: May 26th, 2021
#>

param(
        [Parameter(Mandatory=$True,
                ValueFromPipelineByPropertyName=$false,
                HelpMessage='Insert the proxy server and the port (i.e. http://myproxy:8080). Enter NONE to not use any proxy.',
                Position=0)]
                [string]$proxy
        )
                
# Setting variables
$setupFilePath = "C:\Temp"

# Setting variables specific for ARC Agent
$setupFileName = "AzureConnectedMachineAgent.msi"

$argumentListArc = @('/i', "$setupFilePath\AzureConnectedMachineAgent.msi", "/qn", "/l*v", "$setupFilePath\AzcmAgentUpgradeSetup.log")

$URI_ARC = "https://aka.ms/AzureConnectedMachineAgent"

#region Functions

#endregion

# Checking if temporary path exists otherwise create it
if(!(Test-Path $setupFilePath))
{
    Write-Output "Creating folder $setupFilePath since it does not exist ... "
    New-Item -path $setupFilePath -ItemType Directory
    Write-Output "Folder $setupFilePath created successfully."
}

#Check if the file was already downloaded hence overwrite it, otherwise download it from scratch
if (Test-Path $($setupFilePath+"\"+$setupFileName))
{
    Write-Output "The file $setupFileName already exists, overwriting with a new copy ... "
}
else
{
    Write-Output "The file $setupFileName does not exist, downloading ... "
}

# Downloading the file
try
{
    if($proxy -eq "NONE")
    {
        $Response = Invoke-WebRequest -Uri $URI_ARC -OutFile $($setupFilePath+"\"+$setupFileName) -ErrorAction Stop
    }
    else
    {
        $Response = Invoke-WebRequest -Proxy "$proxy" -ProxyUseDefaultCredentials -Uri $URI_ARC -OutFile $($setupFilePath+"\"+$setupFileName) -ErrorAction Stop
    }

    # This will only execute if the Invoke-WebRequest is successful.
    if (Test-Path $($setupFilePath+"\"+$setupFileName))
    {
        Write-Output "Download of $setupFileName, done!"
        Write-Output "Starting the upgrade process ... "
        
        #cd $setupFilePath
        start-process "msiexec.exe" -ArgumentList $argumentListArc -Wait
        
        Write-Output "Agent Upgrade process completed."
    }
    else
    {
        Write-Output "Download of $setupFileName, failed! The upgrade process cannot be completed."
    }
}
catch
{
    $StatusCode = $_.Exception.Response.StatusCode.value__
    Write-Output "An error occurred during file download. The error code is ==$StatusCode==."
}

Write-Output "Runbook execution completed."
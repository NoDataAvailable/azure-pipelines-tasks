function Extract-Dacpac {
    param (
        [string] $serverName,
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlpackageAdditionalArguments
    )

    $targetDacpacFilePath = "$ENV:SYSTEM_DEFAULTWORKINGDIRECTORY\$databaseName.dacpac"

    # Increase Timeout to 120 seconds in case its not provided by User
    if (-not ($sqlpackageAdditionalArguments.ToLower().Contains("/targettimeout:") -or $sqlpackageAdditionalArguments.ToLower().Contains("/tt:")))
    {
        # Add Timeout of 120 Seconds
        $sqlpackageAdditionalArguments = $sqlpackageAdditionalArguments + " /TargetTimeout:$defaultTimeout"
    }

    # append additionalArguments to scriptArguments
    # getting script arguments to execute sqlpackage.exe
    $sqlpackageArguments =  "/Action:Extract /TargetFile:`"$targetDacpacFilePath`" /SourceServerName:`"$serverName`" /SourceDatabaseName:`"$databaseName`" /SourceUser:`"$sqlUsername`" /SourcePassword:`"$sqlPassword`""
    $sqlpackageArgumentsToBeLogged = "/Action:Extract /TargetFile:`"$targetDacpacFilePath`" /SourceServerName:`"$serverName`" /SourceDatabaseName:`"$databaseName`" /SourceUser:`"$sqlUsername`" /SourcePassword:********"

    $sqlPackagePath = Get-SqlPackageOnTargetMachine
    Write-Verbose "Executing : `"$sqlpackagePath`" $sqlpackageArgumentsToBeLogged"

    Execute-Command -FileName $sqlPackagePath -Arguments $sqlpackageArguments

    Write-Host "Generated dacpac file: $targetDacpacFilePath. Uploading the dacpac file to the logs."
    Write-Host "##vso[task.uploadfile]$targetDacpacFilePath"
}

function Execute-PublishAction {
    param(
        [string] $serverName,
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $taskNameSelector,
        [string] $dacpacFile,
        [string] $publishProfile,
        [string] $sqlFile,
        [string] $sqlInline,
        [string] $sqlpackageAdditionalArguments,
        [string] $sqlcmdAdditionalArguments,
        [string] $sqlcmdInlineAdditionalArguments
    )

    switch ($taskNameSelector) {
        "DacpacTask" {
            Publish-Dacpac -serverName $serverName -databaseName $databaseName -sqlUsername $sqlUsername -sqlPassword $sqlPassword -dacpacFile $dacpacFile -publishProfile $publishProfile -sqlpackageAdditionalArguments $sqlpackageAdditionalArguments
        }
        "SqlTask" {
            Run-SqlFiles -serverName $serverName -databaseName $databaseName -sqlUsername $sqlUsername -sqlPassword $sqlPassword -sqlFile $sqlFile -sqlcmdAdditionalArguments $sqlcmdAdditionalArguments
        }
        "InlineSqlTask" {
            Run-InlineSql -serverName $serverName -databaseName $databaseName -sqlUsername $sqlUsername -sqlPassword $sqlPassword -sqlInline $sqlInline -sqlcmdAdditionalArguments $sqlcmdInlineAdditionalArguments
        }
        default {
            throw "Invalid option selected for publish action: $taskNameSelector"
        }
    }
}

function Export-Bacpac {
    param (
        [string] $serverName,
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlpackageAdditionalArguments
    )

    $targetBacpacFilePath = "$ENV:SYSTEM_DEFAULTWORKINGDIRECTORY\$databaseName.bacpac"

    # Increase Timeout to 120 seconds in case its not provided by User
    if (-not ($sqlpackageAdditionalArguments.ToLower().Contains("/targettimeout:") -or $sqlpackageAdditionalArguments.ToLower().Contains("/tt:")))
    {
        # Add Timeout of 120 Seconds
        $sqlpackageAdditionalArguments = $sqlpackageAdditionalArguments + " /TargetTimeout:$defaultTimeout"
    }

    # append additionalArguments to scriptArguments
    # getting script arguments to execute sqlpackage.exe
    $sqlpackageArguments =  "/Action:Export /TargetFile:`"$targetBacpacFilePath`" /SourceServerName:`"$serverName`" /SourceDatabaseName:`"$databaseName`" /SourceUser:`"$sqlUsername`" /SourcePassword:`"$sqlPassword`""
    $sqlpackageArgumentsToBeLogged = "/Action:Export /TargetFile:`"$targetBacpacFilePath`" /SourceServerName:`"$serverName`" /SourceDatabaseName:`"$databaseName`" /SourceUser:`"$sqlUsername`" /SourcePassword:********"

    $sqlPackagePath = Get-SqlPackageOnTargetMachine
    Write-Verbose "Executing : `"$sqlpackagePath`" $sqlpackageArgumentsToBeLogged"

    Execute-Command -FileName $sqlPackagePath -Arguments $sqlpackageArguments

    Write-Host "Generated bacpac file: $targetBacpacFilePath. Uploading the bacpac file to the logs."
    Write-Host "##vso[task.uploadfile]$targetBacpacFilePath"
}

function Import-Bacpac {
    param (
        [string] $bacpacFile,   
        [string] $serverName,
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlpackageAdditionalArguments
    )

    $bacpacFilePath = Find-SqlFiles -filePathPattern $bacpacFile -verboseMessage "Bacpac file:" -throwIfMultipleFilesOrNoFilePresent

    # Increase Timeout to 120 seconds in case its not provided by User
    if (-not ($sqlpackageAdditionalArguments.ToLower().Contains("/targettimeout:") -or $sqlpackageAdditionalArguments.ToLower().Contains("/tt:")))
    {
        # Add Timeout of 120 Seconds
        $sqlpackageAdditionalArguments = $sqlpackageAdditionalArguments + " /TargetTimeout:$defaultTimeout"
    }

    # append additionalArguments to scriptArguments
    # getting script arguments to execute sqlpackage.exe
    $sqlpackageArguments =  "/Action:Import /SourceFile:`"$bacpacFilePath`" /TargetServerName:`"$serverName`" /TargetDatabaseName:`"$databaseName`" /TargetUser:`"$sqlUsername`" /TargetPassword:`"$sqlPassword`""
    $sqlpackageArgumentsToBeLogged = "/Action:Import /SourceFile:`"$bacpacFilePath`" /TargetServerName:`"$serverName`" /TargetDatabaseName:`"$databaseName`" /TargetUser:`"$sqlUsername`" /TargetPassword:********"

    $sqlPackagePath = Get-SqlPackageOnTargetMachine
    Write-Verbose "Executing : `"$sqlpackagePath`" $sqlpackageArgumentsToBeLogged"

    Execute-Command -FileName $sqlPackagePath -Arguments $sqlpackageArguments
}

function Deploy-Report {
    param (
        [string] $dacpacFile,   
        [string] $serverName,
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlpackageAdditionalArguments
    )

    $dacpacFilePath = Find-SqlFiles -filePathPattern $dacpacFile -verboseMessage "Dacpac file:" -throwIfMultipleFilesOrNoFilePresent
    $outputXmlPath = "$ENV:SYSTEM_DEFAULTWORKINGDIRECTORY\${databaseName}_DeployReport.xml"
    
    # Increase Timeout to 120 seconds in case its not provided by User
    if (-not ($sqlpackageAdditionalArguments.ToLower().Contains("/targettimeout:") -or $sqlpackageAdditionalArguments.ToLower().Contains("/tt:")))
    {
        # Add Timeout of 120 Seconds
        $sqlpackageAdditionalArguments = $sqlpackageAdditionalArguments + " /TargetTimeout:$defaultTimeout"
    }

    # append additionalArguments to scriptArguments
    # getting script arguments to execute sqlpackage.exe
    $sqlpackageArguments =  "/Action:DeployReport /SourceFile:`"$dacpacFilePath`" /TargetServerName:`"$serverName`" /TargetDatabaseName:`"$databaseName`" /TargetUser:`"$sqlUsername`" /TargetPassword:`"$sqlPassword`" /OutputPath:`"$outputXmlPath`" /p:AllowIncompatiblePlatform=true"
    $sqlpackageArgumentsToBeLogged = "/Action:DeployReport /SourceFile:`"$dacpacFilePath`" /TargetServerName:`"$serverName`" /TargetDatabaseName:`"$databaseName`" /TargetUser:`"$sqlUsername`" /TargetPassword:******** /OutputPath:`"$outputXmlPath`""

    $sqlPackagePath = Get-SqlPackageOnTargetMachine
    Write-Verbose "Executing : `"$sqlpackagePath`" $sqlpackageArgumentsToBeLogged"

    Execute-Command -FileName $sqlPackagePath -Arguments $sqlpackageArguments

    Write-Host "Generated deploy report: $outputXmlPath. Uploading the deploy report file to the logs."
    Write-Host "##vso[task.uploadfile]$outputXmlPath"
}

function Drift-Report {
    param (
        [string] $serverName,
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlpackageAdditionalArguments
    )

    $outputXmlPath = "$ENV:SYSTEM_DEFAULTWORKINGDIRECTORY\${databaseName}_DriftReport.xml"
    
    # Increase Timeout to 120 seconds in case its not provided by User
    if (-not ($sqlpackageAdditionalArguments.ToLower().Contains("/targettimeout:") -or $sqlpackageAdditionalArguments.ToLower().Contains("/tt:")))
    {
        # Add Timeout of 120 Seconds
        $sqlpackageAdditionalArguments = $sqlpackageAdditionalArguments + " /TargetTimeout:$defaultTimeout"
    }

    # append additionalArguments to scriptArguments
    # getting script arguments to execute sqlpackage.exe
    $sqlpackageArguments =  "/Action:DriftReport /TargetServerName:`"$serverName`" /TargetDatabaseName:`"$databaseName`" /TargetUser:`"$sqlUsername`" /TargetPassword:`"$sqlPassword`" /OutputPath:`"$outputXmlPath`""
    $sqlpackageArgumentsToBeLogged = "/Action:DriftReport /TargetServerName:`"$serverName`" /TargetDatabaseName:`"$databaseName`" /TargetUser:`"$sqlUsername`" /TargetPassword:******** /OutputPath:`"$outputXmlPath`""

    $sqlPackagePath = Get-SqlPackageOnTargetMachine
    Write-Verbose "Executing : `"$sqlpackagePath`" $sqlpackageArgumentsToBeLogged"

    Execute-Command -FileName $sqlPackagePath -Arguments $sqlpackageArguments

    Write-Host "Generated drift report: $outputXmlPath. Uploading the drift report file to the logs."
    Write-Host "##vso[task.uploadfile]$outputXmlPath"
}

function Script-Action {
    param (
        [string] $dacpacFile,   
        [string] $serverName,
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlpackageAdditionalArguments
    )

    $dacpacFilePath = Find-SqlFiles -filePathPattern $dacpacFile -verboseMessage "Dacpac file:" -throwIfMultipleFilesOrNoFilePresent
    $outputSqlPath = "$ENV:SYSTEM_DEFAULTWORKINGDIRECTORY\${databaseName}_Script.sql"
    
    # Increase Timeout to 120 seconds in case its not provided by User
    if (-not ($sqlpackageAdditionalArguments.ToLower().Contains("/targettimeout:") -or $sqlpackageAdditionalArguments.ToLower().Contains("/tt:")))
    {
        # Add Timeout of 120 Seconds
        $sqlpackageAdditionalArguments = $sqlpackageAdditionalArguments + " /TargetTimeout:$defaultTimeout"
    }

    # append additionalArguments to scriptArguments
    # getting script arguments to execute sqlpackage.exe
    $sqlpackageArguments =  "/Action:Script /SourceFile:`"$dacpacFilePath`" /TargetServerName:`"$serverName`" /TargetDatabaseName:`"$databaseName`" /TargetUser:`"$sqlUsername`" /TargetPassword:`"$sqlPassword`" /OutputPath:`"$outputSqlPath`" /p:AllowIncompatiblePlatform=true"
    $sqlpackageArgumentsToBeLogged = "/Action:Script /SourceFile:`"$dacpacFilePath`" /TargetServerName:`"$serverName`" /TargetDatabaseName:`"$databaseName`" /TargetUser:`"$sqlUsername`" /TargetPassword:******** /OutputPath:`"$outputSqlPath`""

    $sqlPackagePath = Get-SqlPackageOnTargetMachine
    Write-Verbose "Executing : `"$sqlpackagePath`" $sqlpackageArgumentsToBeLogged"

    Execute-Command -FileName $sqlPackagePath -Arguments $sqlpackageArguments

    Write-Host "Generated script: $outputSqlPath. Uploading the script file to the logs."
    Write-Host "##vso[task.uploadfile]$outputSqlPath"
}

function Publish-Dacpac {
    param (
        [string] $serverName,
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $dacpacFile,
        [string] $publishProfile,
        [string] $sqlpackageAdditionalArguments
    )
    
    #Ensure that a single package (.dacpac) file is found
    $dacpacFilePath = Find-SqlFiles -filePathPattern $dacpacFile -verboseMessage "Dacpac package file:" -throwIfMultipleFilesOrNoFilePresent

    # Publish profile path validations - Ensure that only one publish profile file is found
    $publishProfilePath = "" 
    if ([string]::IsNullOrWhitespace($publishProfile) -eq $false -and $publishProfile -ne $env:SYSTEM_DEFAULTWORKINGDIRECTORY -and $publishProfile -ne [String]::Concat($env:SYSTEM_DEFAULTWORKINGDIRECTORY, "\")) {
        $publishProfilePath = Find-SqlFiles -filePathPattern $publishProfile -verboseMessage "Publish profile path:" -throwIfMultipleFilesOrNoFilePresent
    }

    # Increase Timeout to 120 seconds in case its not provided by User
    if (-not ($sqlpackageAdditionalArguments.ToLower().Contains("/targettimeout:") -or $sqlpackageAdditionalArguments.ToLower().Contains("/tt:")))
    {
        # Add Timeout of 120 Seconds
        $sqlpackageAdditionalArguments = $sqlpackageAdditionalArguments + " /TargetTimeout:$defaultTimeout"
    }

    # getting script arguments to execute sqlpackage.exe
    $scriptArgument = Get-SqlPackageCommandArguments -dacpacFile $dacpacFilePath -targetMethod "server" -serverName $serverName -databaseName $databaseName `
                                                    -sqlUsername $sqlUsername -sqlPassword $sqlPassword -publishProfile $publishProfilePath -additionalArguments $sqlpackageAdditionalArguments

    $scriptArgumentToBeLogged = Get-SqlPackageCommandArguments -dacpacFile $dacpacFilePath -targetMethod "server" -serverName $serverName -databaseName $databaseName `
                                                    -sqlUsername $sqlUsername -sqlPassword $sqlPassword -publishProfile $publishProfilePath -additionalArguments $sqlpackageAdditionalArguments -isOutputSecure

    Write-Verbose "sqlPackageArguments = $scriptArgumentToBeLogged"

    $sqlPackagePath = Get-SqlPackageOnTargetMachine

    Write-Verbose "Executing SQLPackage.exe"

    $commandToBeLogged = "`"$SqlPackagePath`" $scriptArgumentToBeLogged"

    Write-Verbose "Executing : $commandToBeLogged"

    Execute-Command -FileName $SqlPackagePath -Arguments $scriptArgument
}

function Run-SqlFiles {
    param (
        [string] $serverName,    
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlFile,
        [string] $sqlcmdAdditionalArguments
    )

    #Ensure that a single .sql file is found
    $sqlFilePath = Find-SqlFiles -filePathPattern $sqlFile -verboseMessage "Sql file:" -throwIfMultipleFilesOrNoFilePresent
    
    if ([System.IO.Path]::GetExtension($sqlFilePath) -ne ".sql") {
        Write-Error (Get-VstsLocString -Key "SAD_InvalidSqlFile" -ArgumentList $FilePath)
    }

    Run-SqlCmd -serverName $serverName -databaseName $databaseName -sqlUsername $sqlUsername -sqlPassword $sqlPassword -sqlFilePath $sqlFilePath -sqlcmdAdditionalArguments $sqlcmdAdditionalArguments
}

function Run-InlineSql {
    param (
        [string] $serverName,    
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlInline,
        [string] $sqlcmdAdditionalArguments
    )

    $sqlInlineFilePath = [System.IO.Path]::GetTempFileName()
    $sqlInline | Out-File $sqlInlineFilePath

    Write-Host "Temporary inline sql file: $sqlInlineFilePath"

    Run-SqlCmd -serverName $serverName -databaseName $databaseName -sqlUsername $sqlUsername -sqlPassword $sqlPassword -sqlFilePath $sqlInlineFilePath -sqlcmdAdditionalArguments $sqlcmdAdditionalArguments
}

function Run-SqlCmd {
    param (
        [string] $serverName,    
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $sqlFilePath,
        [string] $sqlcmdAdditionalArguments
    )

    if ($sqlUsername) {
        $sqlUsername = Get-FormattedSqlUsername -sqlUserName $sqlUsername -serverName $serverName
    }

    $scriptArgument = "Invoke-Sqlcmd -ServerInstance `"$serverName`" -Database `"$databaseName`" -Username `"$sqlUsername`" "

    $commandToRun = $scriptArgument + " -Password `"$sqlPassword`" "
    $commandToLog = $scriptArgument + " -Password ****** "

    # Increase Timeout to 120 seconds in case its not provided by User
    if (-not ($sqlcmdAdditionalArguments.ToLower().Contains("-connectiontimeout")))
    {
        # Add Timeout of 120 Seconds
        $sqlcmdAdditionalArguments = $sqlcmdAdditionalArguments + " -ConnectionTimeout $defaultTimeout"
    }

    $commandToRun += " -Inputfile `"$sqlFilePath`" " + $sqlcmdAdditionalArguments
    $commandToLog += " -Inputfile `"$sqlFilePath`" " + $sqlcmdAdditionalArguments

    Write-Host $commandToLog
    Invoke-Expression $commandToRun
}

function Add-FirewallRule {
    param (
        [object] $endpoint,
        [string] $serverName,    
        [string] $databaseName,
        [string] $sqlUsername,
        [string] $sqlPassword,
        [string] $ipDetectionMethod,
        [string] $startIPAddress,
        [string] $endIPAddress
    )
    
    # Test and get IPRange for autoDetect IpDetectionMethod
    $ipAddressRange = @{}
    if($ipDetectionMethod -eq "AutoDetect")
    {
        $ipAddressRange = Get-AgentIPRange -serverName $serverName -sqlUsername $sqlUsername -sqlPassword $sqlPassword
    }
    else 
    {
        $ipAddressRange.StartIPAddress = $startIPAddress
        $ipAddressRange.EndIPAddress = $endIPAddress
    }

    Write-Verbose ($ipAddressRange | Format-List | Out-String)

    # creating firewall rule for agent on sql server, if it is not able to connect or iprange is selected
    if($ipAddressRange.Count -ne 0)
    {
        $serverFriendlyName = $serverName.split(".")[0]
    
        $firewallSettings = Create-AzureSqlDatabaseServerFirewallRule -startIP $ipAddressRange.StartIPAddress -endIP $ipAddressRange.EndIPAddress -serverName $serverFriendlyName -endpoint $endpoint
        Write-Verbose ($firewallSettings | Format-List | Out-String)

        $firewallRuleName = $firewallSettings.RuleName
        $isFirewallConfigured = $firewallSettings.IsConfigured
    }

    return $firewallRuleName, $isFirewallConfigured
}

function Find-SqlFiles {
    param (
        [string] $filePathPattern,
        [string] $verboseMessage,
        [switch] $throwIfMultipleFilesOrNoFilePresent
    )

    Write-Verbose "filePath = Find-VstsFiles LegacyPattern $filePathPattern"
    $filePath = Find-VstsFiles LegacyPattern $filePathPattern

    if ($throwIfMultipleFilesOrNoFilePresent) {
        ThrowIfMultipleFilesOrNoFilePresent -files $filePath -pattern $filePathPattern
    }

    Write-Host "$verboseMessage $filePath"

    return $filePath
}

function ThrowIfMultipleFilesOrNoFilePresent($files, $pattern)
{
    if ($files -is [system.array]) {
        throw (Get-VstsLocString -Key "SAD_FoundMoreFiles" -ArgumentList $pattern)
    }
    else {
        if (!$files) {
            throw (Get-VstsLocString -Key "SAD_NoFilesMatch" -ArgumentList $pattern)
        }
    }
}


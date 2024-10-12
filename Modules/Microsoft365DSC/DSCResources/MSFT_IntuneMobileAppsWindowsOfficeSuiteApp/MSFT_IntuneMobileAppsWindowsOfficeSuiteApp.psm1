function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        #region Intune resource parameters

        [Parameter()]
        [System.String]
        $Id,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $Publisher,

        [Parameter()]
        [System.Boolean]
        $IsFeatured,

        [Parameter()]
        [System.String]
        $PrivacyInformationUrl,

        [Parameter()]
        [System.String]
        $InformationUrl,

        [Parameter()]
        [System.String]
        $Owner,

        [Parameter()]
        [System.String]
        $Developer,

        [Parameter()]
        [System.String]
        $Notes,

        [Parameter()]
        [System.String]
        [ValidateSet('notPublished', 'processing','published')]
        $PublishingState,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.Boolean]
        $AutoAcceptEula,

        [Parameter()]
        [System.String[]]
        [ValidateSet('O365ProPlusRetail', 'O365BusinessRetail', 'VisioProRetail', 'ProjectProRetail')]
        $ProductIds,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ExcludedApps,

        [Parameter()]
        [System.Boolean]
        $UseSharedComputerActivation,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'Current', 'Deferred', 'FirstReleaseCurrent', 'FirstReleaseDeferred', 'MonthlyEnterprise')]
        $UpdateChannel,

        [Parameter()]
        [System.String]
        [ValidateSet('NotConfigured', 'OfficeOpenXMLFormat', 'OfficeOpenDocumentFormat', 'UnknownFutureValue')]
        $OfficeSuiteAppDefaultFileFormat,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'X86', 'X64', 'Arm', 'Neutral', 'Arm64')]
        $OfficePlatformArchitecture,

        [Parameter()]
        [System.String[]]
        $LocalesToInstall,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'Full')]
        $InstallProgressDisplayLevel,

        [Parameter()]
        [System.Boolean]
        $ShouldUninstallOlderVersionsOfOffice,

        [Parameter()]
        [System.String]
        $TargetVersion,

        [Parameter()]
        [System.String]
        $UpdateVersion,

        [Parameter()]
        [System.Byte[]]
        $OfficeConfigurationXml,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Categories,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $LargeIcon,

        #endregion

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters | Out-Null

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $nullResult = $PSBoundParameters
    $nullResult.Ensure = 'Absent'
    try
    {
        $instance = Get-MgBetaDeviceAppManagementMobileApp `
            -Filter "(isof('microsoft.graph.officeSuiteApp') and displayName eq '$DisplayName')" `
            -ExpandProperty "categories,assignments" `
            -ErrorAction SilentlyContinue | Where-Object `
            -FilterScript { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.officeSuiteApp' }

        if ($null -eq $instance)
        {
            Write-Verbose -Message "No Mobile app with DisplayName {$DisplayName} was found. Search with DisplayName."
            $instance = Get-MgBetaDeviceAppManagementMobileApp `
                -MobileAppId $Id `
                -ExpandProperty "categories,assignments" `
                -ErrorAction Stop | Where-Object `
                -FilterScript { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.officeSuiteApp' }
        }

        if ($null -eq $instance)
        {
            Write-Verbose -Message "No Mobile app with {$Id} was found."
            return $nullResult
        }

        $results = @{
            Id                    = $instance.Id
            DisplayName           = $instance.DisplayName
            Description           = $instance.Description
            Publisher             = $instance.Publisher
            IsFeatured            = $instance.IsFeatured
            PrivacyInformationUrl = $instance.PrivacyInformationUrl
            InformationUrl        = $instance.InformationUrl
            Owner                 = $instance.Owner
            Developer             = $instance.Developer
            Notes                 = $instance.Notes
            PublishingState       = $instance.PublishingState.ToString()
            RoleScopeTagIds       = $instance.RoleScopeTagIds
            ProductIds            = $instance.ProductIds
            UseSharedComputerActivation = $instance.UseSharedComputerActivation
            UpdateChannel         = $instance.UpdateChannel
            OfficeSuiteAppDefaultFileFormat = $instance.OfficeSuiteAppDefaultFileFormat
            OfficePlatformArchitecture = $instance.OfficePlatformArchitecture
            LocalesToInstall      = $instance.LocalesToInstall
            InstallProgressDisplayLevel = $instance.InstallProgressDisplayLevel
            ShouldUninstallOlderVersionsOfOffice = $instance.ShouldUninstallOlderVersionsOfOffice
            TargetVersion         = $instance.TargetVersion
            UpdateVersion         = $instance.UpdateVersion
            OfficeConfigurationXml = $instance.OfficeConfigurationXml
            AutoAcceptEula        = $instance.AdditionalProperties.AutoAcceptEula

            Ensure                = 'Present'
            Credential            = $Credential
            ApplicationId         = $ApplicationId
            TenantId              = $TenantId
            CertificateThumbprint = $CertificateThumbprint
            ApplicationSecret     = $ApplicationSecret
            ManagedIdentity       = $ManagedIdentity.IsPresent
            AccessTokens          = $AccessTokens
        }

        #region complex types

        #Categories
        if($null -ne $instance.Categories)
        {
            $results.Add('Categories', $instance.Categories)
        }
        else {
            $results.Add('Categories', "")
        }

        # ExcludedApps
        if ($null -ne $instance.AdditionalProperties -and $null -ne $instance.AdditionalProperties.excludedApps)
        {
            # Convert to Hashtable if it is an array
            if ($instance.AdditionalProperties.excludedApps -is [System.Object[]]) {
                $formattedExcludedApps = @{}
                foreach ($app in $instance.AdditionalProperties.excludedApps) {
                    foreach ($key in $app.Keys) {
                        $formattedExcludedApps[$key] = $app[$key]
                    }
                }
            }
            else {
                $formattedExcludedApps = $instance.AdditionalProperties.excludedApps
            }

            # Ensure ExcludedApps is returned as a Hashtable
            $results['ExcludedApps'] = @{}
            foreach ($key in $formattedExcludedApps.Keys) {
                $results['ExcludedApps'].Add($key, $formattedExcludedApps[$key])
            }
        }
        else {
            $results.Add('ExcludedApps', $null)
        }

        #Assignments
        $resultAssignments = @()
        $appAssignments = Get-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $instance.Id
        if ($null -ne $appAssignments -and $appAssignments.count -gt 0)
        {
            $resultAssignments += ConvertFrom-IntuneMobileAppAssignment `
                                -IncludeDeviceFilter:$true `
                                -Assignments ($appAssignments)

            $results.Add('Assignments', $resultAssignments)
        }

        #LargeIcon
        # The large is returned only when Get cmdlet is called with Id parameter. The large icon is a base64 encoded string, so we need to convert it to a byte array.
        $instanceWithLargeIcon = Get-MgBetaDeviceAppManagementMobileApp -MobileAppId $instance.Id
        if (-not $results.ContainsKey('LargeIcon')) {
            $results.Add('LargeIcon', $instanceWithLargeIcon.LargeIcon)
        } else {
            $results['LargeIcon'] = $instanceWithLargeIcon.LargeIcon  # Update the existing key
        }

        #end region complex types

        return [System.Collections.Hashtable] $results
    }
    catch
    {
        Write-Verbose -Message $_
        New-M365DSCLogEntry -Message 'Error retrieving data:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        return $nullResult
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        #region Intune resource parameters

        [Parameter()]
        [System.String]
        $Id,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $Publisher,

        [Parameter()]
        [System.Boolean]
        $IsFeatured,

        [Parameter()]
        [System.String]
        $PrivacyInformationUrl,

        [Parameter()]
        [System.String]
        $InformationUrl,

        [Parameter()]
        [System.String]
        $Owner,

        [Parameter()]
        [System.String]
        $Developer,

        [Parameter()]
        [System.String]
        $Notes,

        [Parameter()]
        [System.String]
        [ValidateSet('notPublished', 'processing','published')]
        $PublishingState,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.Boolean]
        $AutoAcceptEula,

        [Parameter()]
        [System.String[]]
        [ValidateSet('O365ProPlusRetail', 'O365BusinessRetail', 'VisioProRetail', 'ProjectProRetail')]
        $ProductIds,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ExcludedApps,

        [Parameter()]
        [System.Boolean]
        $UseSharedComputerActivation,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'Current', 'Deferred', 'FirstReleaseCurrent', 'FirstReleaseDeferred', 'MonthlyEnterprise')]
        $UpdateChannel,

        [Parameter()]
        [System.String]
        [ValidateSet('NotConfigured', 'OfficeOpenXMLFormat', 'OfficeOpenDocumentFormat', 'UnknownFutureValue')]
        $OfficeSuiteAppDefaultFileFormat,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'X86', 'X64', 'Arm', 'Neutral', 'Arm64')]
        $OfficePlatformArchitecture,

        [Parameter()]
        [System.String[]]
        $LocalesToInstall,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'Full')]
        $InstallProgressDisplayLevel,

        [Parameter()]
        [System.Boolean]
        $ShouldUninstallOlderVersionsOfOffice,

        [Parameter()]
        [System.String]
        $TargetVersion,

        [Parameter()]
        [System.String]
        $UpdateVersion,

        [Parameter()]
        [System.Byte[]]
        $OfficeConfigurationXml,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Categories,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $LargeIcon,

        #endregion

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentInstance = Get-TargetResource @PSBoundParameters
    $PSBoundParameters.Remove('Ensure') | Out-Null
    $PSBoundParameters.Remove('Credential') | Out-Null
    $PSBoundParameters.Remove('ApplicationId') | Out-Null
    $PSBoundParameters.Remove('ApplicationSecret') | Out-Null
    $PSBoundParameters.Remove('TenantId') | Out-Null
    $PSBoundParameters.Remove('CertificateThumbprint') | Out-Null
    $PSBoundParameters.Remove('ManagedIdentity') | Out-Null
    $PSBoundParameters.Remove('AccessTokens') | Out-Null

    $CreateParameters = Remove-M365DSCAuthenticationParameter -BoundParameters $PSBoundParameters

    # CREATE
    if ($Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Absent')
    {
        Write-Host "Create office suite app: $DisplayName"

        $CreateParameters = ([Hashtable]$PSBoundParameters).clone()
        $CreateParameters = Rename-M365DSCCimInstanceParameter -Properties $CreateParameters
        Write-Output "Before AdditionalProperties creation: $($CreateParameters | Out-String)"
        $AdditionalProperties = Get-M365DSCIntuneMobileWindowsOfficeSuiteAppAdditionalProperties -Properties ($CreateParameters)
        Write-Output "AdditionalProperties: $($AdditionalProperties | Out-String)"
        foreach ($key in $AdditionalProperties.keys)
        {
            if ($key -ne '@odata.type')
            {
                $keyName = $key.substring(0, 1).ToUpper() + $key.substring(1, $key.length - 1)
                $CreateParameters.remove($keyName)
            }
        }

        $CreateParameters.remove('Id') | Out-Null
        $CreateParameters.remove('Ensure') | Out-Null
        $CreateParameters.remove('Categories') | Out-Null
        $CreateParameters.remove('Assignments') | Out-Null
        $CreateParameters.remove('excludedApps') | Out-Null
        $CreateParameters.Remove('Verbose') | Out-Null
        $CreateParameters.Remove('PublishingState') | Out-Null #Not allowed to update as it's a computed property
        $CreateParameters.Remove('LargeIcon') | Out-Null

        foreach ($key in ($CreateParameters.clone()).Keys)
        {
            if ($CreateParameters[$key].getType().Fullname -like '*CimInstance*')
            {
                $CreateParameters[$key] = Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $CreateParameters[$key]
            }
        }

        if ($AdditionalProperties)
        {
            $CreateParameters.add('AdditionalProperties', $AdditionalProperties)
        }

        #LargeIcon
        if($LargeIcon)
        {
            [System.Object]$LargeIconValue = ConvertTo-M365DSCIntuneAppLargeIcon -LargeIcon $LargeIcon
            if (-not $CreateParameters.ContainsKey('LargeIcon')) {
                $CreateParameters.Add('LargeIcon', $LargeIconValue)
            } else {
                $CreateParameters['LargeIcon'] = $LargeIconValue
            }
        }
        Write-Output "CreateParameters before API call: $($CreateParameters | Out-String)"
        $app = New-MgBetaDeviceAppManagementMobileApp @CreateParameters

        #Assignments
        $assignmentsHash = ConvertTo-IntuneMobileAppAssignment -IncludeDeviceFilter:$true -Assignments $Assignments
        if ($app.id)
        {
            Write-Output "UpdateParameters before API call: $($UpdateParameters | Out-String)"
            Update-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $app.id `
                -Target $assignmentsHash `
                -Repository 'deviceAppManagement/mobileAppAssignments'
        }
    }
    # UPDATE
    elseif ($Ensure -eq 'Present' -and $currentInstance.Ensure -eq 'Present')
    {
        Write-Host "Update office suite app: $DisplayName"

        $PSBoundParameters.Remove('Assignments') | Out-Null
        $UpdateParameters = ([Hashtable]$PSBoundParameters).clone()
        $UpdateParameters = Rename-M365DSCCimInstanceParameter -Properties $UpdateParameters

        $AdditionalProperties = Get-M365DSCIntuneMobileWindowsOfficeSuiteAppAdditionalProperties -Properties ($UpdateParameters)
        foreach ($key in $AdditionalProperties.keys)
        {
            if ($key -ne '@odata.type')
            {
                $keyName = $key.substring(0, 1).ToUpper() + $key.substring(1, $key.length - 1)
                #Remove additional keys, so that later they can be added as 'AdditionalProperties'
                $UpdateParameters.Remove($keyName)
            }
        }

        $UpdateParameters.Remove('Id') | Out-Null
        $UpdateParameters.Remove('Verbose') | Out-Null
        $UpdateParameters.Remove('Categories') | Out-Null
        $UpdateParameters.Remove('PublishingState') | Out-Null #Not allowed to update as it's a computed property

        foreach ($key in ($UpdateParameters.clone()).Keys)
        {
            if ($UpdateParameters[$key].getType().Fullname -like '*CimInstance*')
            {
                $value = Convert-M365DSCDRGComplexTypeToHashtable -ComplexObject $UpdateParameters[$key]
                $UpdateParameters[$key] = $value
            }
        }

        if ($AdditionalProperties)
        {
            $UpdateParameters.Add('AdditionalProperties', $AdditionalProperties)
        }

         #LargeIcon
         if($LargeIcon)
         {
            [System.Object]$LargeIconValue = ConvertTo-M365DSCIntuneAppLargeIcon -LargeIcon $LargeIcon
            if (-not $CreateParameters.ContainsKey('LargeIcon')) {
                $UpdateParameters.Add('LargeIcon', $LargeIconValue)
            } else {
                $UpdateParameters['LargeIcon'] = $LargeIconValue
            }
         }

        Update-MgBetaDeviceAppManagementMobileApp -MobileAppId $currentInstance.Id @UpdateParameters
        Write-Host "Updated office suite App: $DisplayName."

        #Assignments
        $assignmentsHash = ConvertTo-IntuneMobileAppAssignment -IncludeDeviceFilter:$true -Assignments $Assignments
        Update-MgBetaDeviceAppManagementMobileAppAssignment -MobileAppId $currentInstance.id `
            -Target $assignmentsHash `
            -Repository 'deviceAppManagement/mobileAppAssignments'
    }
    # REMOVE
    elseif ($Ensure -eq 'Absent' -and $currentInstance.Ensure -eq 'Present')
    {
        Write-Host "Remove office suite app: $DisplayName"
        Remove-MgBetaDeviceAppManagementMobileApp -MobileAppId $currentInstance.Id -Confirm:$false
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        #region Intune resource parameters

        [Parameter()]
        [System.String]
        $Id,

        [Parameter(Mandatory = $true)]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $Description,

        [Parameter()]
        [System.String]
        $Publisher,

        [Parameter()]
        [System.Boolean]
        $IsFeatured,

        [Parameter()]
        [System.String]
        $PrivacyInformationUrl,

        [Parameter()]
        [System.String]
        $InformationUrl,

        [Parameter()]
        [System.String]
        $Owner,

        [Parameter()]
        [System.String]
        $Developer,

        [Parameter()]
        [System.String]
        $Notes,

        [Parameter()]
        [System.String]
        [ValidateSet('notPublished', 'processing','published')]
        $PublishingState,

        [Parameter()]
        [System.String[]]
        $RoleScopeTagIds,

        [Parameter()]
        [System.Boolean]
        $AutoAcceptEula,

        [Parameter()]
        [System.String[]]
        [ValidateSet('O365ProPlusRetail', 'O365BusinessRetail', 'VisioProRetail', 'ProjectProRetail')]
        $ProductIds,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $ExcludedApps,

        [Parameter()]
        [System.Boolean]
        $UseSharedComputerActivation,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'Current', 'Deferred', 'FirstReleaseCurrent', 'FirstReleaseDeferred', 'MonthlyEnterprise')]
        $UpdateChannel,

        [Parameter()]
        [System.String]
        [ValidateSet('NotConfigured', 'OfficeOpenXMLFormat', 'OfficeOpenDocumentFormat', 'UnknownFutureValue')]
        $OfficeSuiteAppDefaultFileFormat,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'X86', 'X64', 'Arm', 'Neutral', 'Arm64')]
        $OfficePlatformArchitecture,

        [Parameter()]
        [System.String[]]
        $LocalesToInstall,

        [Parameter()]
        [System.String]
        [ValidateSet('None', 'Full')]
        $InstallProgressDisplayLevel,

        [Parameter()]
        [System.Boolean]
        $ShouldUninstallOlderVersionsOfOffice,

        [Parameter()]
        [System.String]
        $TargetVersion,

        [Parameter()]
        [System.String]
        $UpdateVersion,

        [Parameter()]
        [System.Byte[]]
        $OfficeConfigurationXml,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Categories,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]
        $Assignments,

        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance]
        $LargeIcon,

        #endregion

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    Write-Verbose -Message "Testing configuration of Intune Mobile office suite App: {$DisplayName}"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    if (-not (Test-M365DSCAuthenticationParameter -BoundParameters $CurrentValues))
    {
        Write-Verbose "An error occured in Get-TargetResource, the app {$displayName} will not be processed"
        throw "An error occured in Get-TargetResource, the app {$displayName} will not be processed. Refer to the event viewer logs for more information."
    }
    $ValuesToCheck = ([Hashtable]$PSBoundParameters).clone()
    $ValuesToCheck = Remove-M365DSCAuthenticationParameter -BoundParameters $ValuesToCheck
    $ValuesToCheck.Remove('Id') | Out-Null

    Write-Verbose -Message "Current Values: $(Convert-M365DscHashtableToString -Hashtable $CurrentValues)"
    Write-Verbose -Message "Target Values: $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    if ($CurrentValues.Ensure -ne $Ensure)
    {
        Write-Verbose -Message "Test-TargetResource returned $false"
        return $false
    }
    $testResult = $true

    #Compare Cim instances
    foreach ($key in $PSBoundParameters.Keys)
    {
        $source = $PSBoundParameters.$key
        $target = $CurrentValues.$key
        if ($source.getType().Name -like '*CimInstance*')
        {
            $testResult = Compare-M365DSCComplexObject `
                -Source ($source) `
                -Target ($target)

            if (-Not $testResult)
            {
                $testResult = $false
                break
            }

            $ValuesToCheck.Remove($key) | Out-Null
        }
    }

    if ($testResult)
    {
        $TestResult = Test-M365DSCParameterState -CurrentValues $CurrentValues `
            -Source $($MyInvocation.MyCommand.Source) `
            -DesiredValues $PSBoundParameters `
            -ValuesToCheck $ValuesToCheck.Keys
    }

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Credential,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificateThumbprint,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $ApplicationSecret,

        [Parameter()]
        [Switch]
        $ManagedIdentity,

        [Parameter()]
        [System.String[]]
        $AccessTokens
    )

    $ConnectionMode = New-M365DSCConnection -Workload 'MicrosoftGraph' `
        -InboundParameters $PSBoundParameters

    #Ensure the proper dependencies are installed in the current environment.
    Confirm-M365DSCDependencies

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace('MSFT_', '')
    $CommandName = $MyInvocation.MyCommand
    $data = Format-M365DSCTelemetryParameters -ResourceName $ResourceName `
        -CommandName $CommandName `
        -Parameters $PSBoundParameters
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    try
    {
        $Script:ExportMode = $true
        [array] $Script:getInstances = Get-MgBetaDeviceAppManagementMobileApp `
            -Filter "isof('microsoft.graph.officeSuiteApp')" `
            -ExpandProperty "categories,assignments" `
            -ErrorAction Stop | Where-Object `
            -FilterScript { $_.AdditionalProperties.'@odata.type' -eq '#microsoft.graph.officeSuiteApp' }

        $i = 1
        $dscContent = ''
        if ($Script:getInstances.Length -eq 0)
        {
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }
        else
        {
            Write-Host "`r`n" -NoNewline
        }

        foreach ($config in $Script:getInstances)
        {
            if ($null -ne $Global:M365DSCExportResourceInstancesCount)
            {
                $Global:M365DSCExportResourceInstancesCount++
            }

            $displayedKey = $config.Id
            Write-Host "    |---[$i/$($Script:getInstances.Count)] $displayedKey" -NoNewline

            $params = @{
                Id                    = $config.Id
                DisplayName           = $config.DisplayName
                Ensure                = 'Present'
                Credential            = $Credential
                ApplicationId         = $ApplicationId
                TenantId              = $TenantId
                CertificateThumbprint = $CertificateThumbprint
                ApplicationSecret     = $ApplicationSecret
                ManagedIdentity       = $ManagedIdentity.IsPresent
                AccessTokens          = $AccessTokens
            }

            $Results = Get-TargetResource @params
            $Results = Update-M365DSCExportAuthenticationResults -ConnectionMode $ConnectionMode `
                -Results $Results

            if (-not (Test-M365DSCAuthenticationParameter -BoundParameters $Results))
            {
                Write-Verbose "An error occured in Get-TargetResource, the app {$($params.displayName)} will not be processed."
                throw "An error occured in Get-TargetResource, the app {$($params.displayName)} will not be processed. Refer to the event viewer logs for more information."
            }

            #region complex types

            #Categories
            if($null -ne $Results.Categories)
            {
                $Results.Categories = Get-M365DSCIntuneAppCategoriesAsString -Categories $Results.Categories
            }
            else {
                $Results.Remove('Categories') | Out-Null
            }

            # ExcludedApps
            if ($null -ne $Results.ExcludedApps)
            {
                # Convert to a Hashtable if still an array
                if ($Results.ExcludedApps -is [System.Object[]]) {
                    $Results.ExcludedApps = Convert-ObjectArrayToHashtable -InputArray $Results.ExcludedApps
                }
                $Results.ExcludedApps = Get-M365DSCIntuneAppExcludedAppsAsString -ExcludedApps $Results.ExcludedApps
            }
            else {
                $Results.Remove('ExcludedApps') | Out-Null
            }

            #Assignments
            if ($null -ne $Results.Assignments)
            {
                $complexTypeStringResult = Get-M365DSCDRGComplexTypeToString -ComplexObject ([Array]$Results.Assignments) -CIMInstanceName DeviceManagementMobileAppAssignment

                if ($complexTypeStringResult)
                {
                    $Results.Assignments = $complexTypeStringResult
                }
                else
                {
                    $Results.Remove('Assignments') | Out-Null
                }
            }

            #LargeIcon
            if($null -ne $Results.LargeIcon)
            {
                $Results.LargeIcon = Get-M365DSCIntuneAppLargeIconAsString -LargeIcon $Results.LargeIcon
            }
            else
            {
                $Results.Remove('LargeIcon') | Out-Null
            }

            #endregion complex types

            $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
                -ConnectionMode $ConnectionMode `
                -ModulePath $PSScriptRoot `
                -Results $Results `
                -Credential $Credential

            #region complex types

            #Categories
            if ($null -ne $Results.Categories)
            {
                $isCIMArray = $false
                if ($Results.Categories.getType().Fullname -like '*[[\]]')
                {
                    $isCIMArray = $true
                }

                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'Categories' -IsCIMArray:$isCIMArray
            }

            #ExcludedApps
            if ($null -ne $Results.excludedApps)
            {
                $isCIMArray = $false
                if ($Results.excludedApps.getType().Fullname -like '*[[\]]')
                {
                    $isCIMArray = $true
                }

                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'ExcludedApps' -IsCIMArray:$isCIMArray
            }

            #Assignments
            if ($null -ne $Results.Assignments)
            {
                $isCIMArray = $false
                if ($Results.Assignments.getType().Fullname -like '*[[\]]')
                {
                    $isCIMArray = $true
                }

                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'Assignments' -IsCIMArray:$isCIMArray
            }

            #LargeIcon
            if ($null -ne $Results.LargeIcon)
            {
                $currentDSCBlock = Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName 'LargeIcon' -IsCIMArray:$false
            }

            #endregion complex types

            $dscContent += $currentDSCBlock
            Save-M365DSCPartialExport -Content $currentDSCBlock `
                -FileName $Global:PartialExportFileName
            $i++
            Write-Host $Global:M365DSCEmojiGreenCheckMark
        }

        return $dscContent
    }
    catch
    {
        Write-Host $Global:M365DSCEmojiRedX

        New-M365DSCLogEntry -Message 'Error during Export:' `
            -Exception $_ `
            -Source $($MyInvocation.MyCommand.Source) `
            -TenantId $TenantId `
            -Credential $Credential

        return ''
    }
}

#region Helper functions

function Convert-ObjectArrayToHashtable {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $InputArray
    )
    $outputHashTable = @{}
    foreach ($element in $InputArray) {
        if ($element -is [System.Collections.Hashtable]) {
            $outputHashTable += $element
        }
    }
    return $outputHashTable
}

function Get-M365DSCIntuneAppCategoriesAsString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object[]]
        $Categories
    )

    $StringContent = '@('
    $space = '                '
    $indent = '    '

    $i = 1
    foreach ($category in $Categories)
    {
        if ($Categories.Count -gt 1)
        {
            $StringContent += "`r`n"
            $StringContent += "$space"
        }

        #Only export the displayName, not Id
        $StringContent += "MSFT_DeviceManagementMobileAppCategory { `r`n"
        $StringContent += "$($space)$($indent)displayName = '" + $category.displayName + "'`r`n"
        $StringContent += "$space}"

        $i++
    }

    $StringContent += ')'

    return $StringContent
}

function Get-M365DSCIntuneAppExcludedAppsAsString
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $ExcludedApps
    )

    # Create the embedded instance for ExcludedApps
    $StringContent = "MSFT_DeviceManagementMobileAppExcludedApp {"
    foreach ($key in $ExcludedApps.Keys) {
        $value = if ($ExcludedApps[$key]) { '$true' } else { '$false' }
        $StringContent += "`n    $key = $value;"
    }
    $StringContent += "`n}"

    return $StringContent
}

function Get-M365DSCIntuneMobileWindowsOfficeSuiteAppAdditionalProperties
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $Properties
    )

    # Define the list of additional properties to include in the final payload
    $additionalProperties = @('AutoAcceptEula', 'ExcludedApps')

    # Initialize a hashtable to store the additional properties
    $results = @{'@odata.type' = '#microsoft.graph.officeSuiteApp'}

    # Clone the original properties to manipulate
    $cloneProperties = $Properties.clone()

    # Loop through the clone and process each property based on its type
    foreach ($property in $cloneProperties.Keys)
    {
        if ($property -in $additionalProperties)
        {
            # Convert property name to expected format
            $propertyName = $property[0].ToString().ToLower() + $property.Substring(1, $property.Length - 1)
            $propertyValue = $Properties.$property

            # Handle ExcludedApps: Convert to a hashtable with camelCase properties
            if ($propertyName -eq 'excludedApps' -and $propertyValue -is [System.Collections.Hashtable])
            {
                $formattedExcludedApps = @{}

                # Convert each key in ExcludedApps to camelCase and add to formattedExcludedApps
                foreach ($key in $propertyValue.Keys)
                {
                    $camelCaseKey = $key.Substring(0, 1).ToLower() + $key.Substring(1)
                    $formattedExcludedApps[$camelCaseKey] = $propertyValue[$key]
                }

                # Convert to PSCustomObject to match the expected format
                $results.Add($propertyName, [PSCustomObject]$formattedExcludedApps)
            }
            else
            {
                # For simple types like Boolean (AutoAcceptEula), add directly
                $results.Add($propertyName, $propertyValue)
            }
        }
    }

    return $results
}

# function Get-M365DSCIntuneMobileWindowsOfficeSuiteAppAdditionalProperties
# {
#     [CmdletBinding()]
#     [OutputType([System.Collections.Hashtable])]
#     param
#     (
#         [Parameter(Mandatory = $true)]
#         [System.Collections.Hashtable]
#         $Properties
#     )

#     # Define the list of additional properties to include in the final payload
#     $additionalProperties = @('AutoAcceptEula', 'ExcludedApps')

#     # Initialize a hashtable to store the additional properties
#     $results = @{'@odata.type' = '#microsoft.graph.officeSuiteApp'}

#     # Loop through the clone and process each property based on its type
#     foreach ($property in $Properties.Keys)
#     {
#         if ($property -in $additionalProperties)
#         {
#             $propertyName = $property.Substring(0, 1).ToLower() + $property.Substring(1)
#             $propertyValue = $Properties.$property

#             # Handle ExcludedApps as a hashtable with camelCase properties
#             if ($propertyName -eq 'excludedApps' -and $propertyValue -is [System.Collections.Hashtable])
#             {
#                 $formattedExcludedApps = @{}

#                 # Ensure the keys are camelCase
#                 foreach ($key in $propertyValue.Keys)
#                 {
#                     $camelCaseKey = $key.Substring(0, 1).ToLower() + $key.Substring(1)
#                     $formattedExcludedApps[$camelCaseKey] = $propertyValue[$key]
#                 }

#                 # Convert it to PSCustomObject
#                 $results[$propertyName] = [PSCustomObject]$formattedExcludedApps
#             }
#             else
#             {
#                 # For simple types, just add the value directly
#                 $results[$propertyName] = $propertyValue
#             }
#         }
#     }

#     return $results
# }

function Get-M365DSCIntuneAppLargeIconAsString #Get and Export
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $LargeIcon
    )

     $space = '                '
     $indent = '    '

    if ($null -ne $LargeIcon.Value)
    {
        $StringContent += "`r`n"
        $StringContent += "$space"

        $base64String = [System.Convert]::ToBase64String($LargeIcon.Value) # This exports the base64 string (blob) of the byte array, same as we see in Graph API response

        $StringContent += "MSFT_DeviceManagementMimeContent { `r`n"
        $StringContent += "$($space)$($indent)type  = '" + $LargeIcon.Type + "'`r`n"
        $StringContent += "$($space)$($indent)value = '" + $base64String + "'`r`n"
        $StringContent += "$space}"
    }

    return $StringContent
 }

function ConvertTo-M365DSCIntuneAppLargeIcon #set
{
    [OutputType([System.Object])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Object]
        $LargeIcon
    )

    $result = @{
        type  = $LargeIcon.Type
        value = $iconValue
    }

    return $result
}

#endregion Helper functions

Export-ModuleMember -Function *-TargetResource

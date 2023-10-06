# Install Domain Controller 1
Write-Host "Installing the first Domain Controller"
Invoke-Command -ComputerName $ADController -ScriptBlock -Verbose {
    Param(
        [String]
        $DomainShortName,

        [String]
        $DomainExtension,

        [SecureString]
        $SafeModeAdministratorPassword,

        [String]
        $DomainAdminUser,

        [SecureString]
        $DomainAdminPass
    )
    Import-Module ADDSDeployment
    Import-Module ActiveDirectory

    Write-Verbose"Installing Domain Services"
    Install-WindowsFeature AD-Domain-Services
    Write-Verbose "Installing $DomainShortName.$DomainExtension Forest"

    $ADForestParams = @{ # Hashtable for parameters
        CreateDnsDelegation           = $false
        DatabasePath                  = "C:\Windows\NTDS"
        DomainMode                    = "Win2012R2"
        DomainName                    = "$DomainShortName.$DomainExtension"
        DomainNetbiosName             = $DomainShortName
        ForestMode                    = "Win2012R2"
        InstallDns                    = $true
        LogPath                       = "C:\Windows\NTDS"
        NoRebootOnCompletion          = $true
        SysvolPath                    = "C:\Windows\SYSVOL"
        SafeModeAdministratorPassword = $SafeModeAdministratorPassword
        Force                         = $true
    }
    Install-ADDSForest @ADForestParams # splatting hashtable

    Write-Verbose "Adding $DomainAdminUser"
    $ADUserParams = @{
        Name              = $DomainAdminUser
        GivenName         = $DomainAdminUser
        SamAccountName    = $DomainAdminUser
        UserPrincipalName = "$DomainAdminUser@$DomainShortName.$DomainExtension"
        AccountPassword   = $DomainAdminPass
        PassThru          = $true
    }
    New-ADUser @ADUserParams | Enable-ADAccount

    Write-Verbose "Adding $DomainAdminUser to Domain Admins"
    Add-ADGroupMember "Domain Admins" $DomainAdminUser
} -ArgumentList @( 
    $DomainShortName 
    $DomainExtension
    $SafeModeAdministratorPassword
    $DomainAdminUser
    $DomainAdminPass
)
function Set-MFAMethodDefault {
    <#
        .SYNOPSIS
        Changes the default MFA Method for the target user account within MS Online.

        .DESCRIPTION
        Connects to MS Online, gets the MFA methods on the target account, and changes the default method if the target method is already configured.
        Requires MSOnline module. 
        Information for installing can be found here: 
        https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-msonlinev1?view=azureadps-1.0

        .PARAMETER UserPrincipalName
        The UserPrincipalName of the target account within MS Online.

        .PARAMETER MFAType
        The type of MFA that is to be the new default for the account.
        Options are: "PhoneAppNotification", "OneWaySMS", "TwoWayVoiceMobile", "PhoneAppOTP".
        Case sensitive.

        .INPUTS
        UserPrincipalName accepts input from pipeline.

        .OUTPUTS
        None

        .EXAMPLE
        Set-MFAMethodDefault -UserPrincipalName 'test@contoso.com' -MFAType 'PhoneAppNotification' -Credential (Get-Credential)

        .EXAMPLE
        Connect-MsolService -Credential (Get-Credential)
        $allUsers = Get-ADUser -Filter 'enabled -eq $true'
        ForEach ($user in $allUsers) {
            Set-MFAMethodDefault -UserPrincipalName $user.UserPrincipalName -MFAType 'PhoneAppNotification'
        }

        .LINK
        Github source: https://github.com/SnoozingPinata/MFAManager

        .LINK
        Author's website: www.samuelmelton.com
    #>
    
    [Cmdletbinding()]

    Param (
        [Parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [String] $UserPrincipalName,

        [Parameter(
            Mandatory=$true,
            Position=1)]
        [ValidateSet("PhoneAppNotification", "OneWaySMS", "TwoWayVoiceMobile", "PhoneAppOTP", IgnoreCase = $false)]
        $MFAType,

        [Parameter(
            Position=2,
            Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        $Credential
    )

    Connect-MsolService -Credential $Credential
    $msolUserObject = Get-MsolUser -UserPrincipalName $UserPrincipalName

    $MFATypeIsSetupOnAccount = $msolUserObject.StrongAuthenticationMethods.MethodType.Contains($MFAType)

    if ($MFATypeIsSetupOnAccount) {
        $newMFAMethodsArray = @()
        foreach ($StrongAuthMethod in $msolUserObject.StrongAuthenticationMethods) {
            if ($StrongAuthMethod.MethodType -eq $MFAType) {
                $StrongAuthMethod.IsDefault = $True
            } else {
                $StrongAuthMethod.IsDefault = $False
            }
            $newMFAMethodsArray += $StrongAuthMethod
        }
        
        Set-MsolUser -UserPrincipalName $UserPrincipalName -StrongAuthenticationMethods $newMFAMethodsArray
        
    } else {
        Write-Error -Message "The MFA Type $MFAType has not been configured on the target account $UserPrincipalName"
    }
}
$cxt = Get-AzureRmContext | Select-Object -Expand Tenant 
if( $cxt -eq $null ) {
    Login-AzureRmAccount
}

$keyVault = "BjdCoreKeyVault"
$secretName = "AzureAutomationKey01"
$automationAccount = "Automation"
$automationResourceGroup = "Core_Infra_Automation_RG"

function Get-NewSecret
{
    $length = 25

    [void][Reflection.Assembly]::LoadWithPartialName("System.Web")
    $message = [System.Web.Security.Membership]::GeneratePassword($length,1)

    $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha.key = [Text.Encoding]::ASCII.GetBytes($secret)
    $signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($message))
    $signature = [Convert]::ToBase64String($signature)

    return $signature
}

$secret = Get-NewSecret
$secureSecure = ConvertTo-SecureString -String $secret -AsPlainText -Force
Set-AzureKeyVaultSecret -VaultName $keyVault -Name $secretName -SecretValue $secureSecure

Set-AzureRmAutomationVariable -Name $secretName -Encrypted $true -Value $secret -ResourceGroupName $automationResourceGroup -AutomationAccountName $automationAccount -ErrorAction SilentlyContinue
if( $? -eq $false ) {
    New-AzureRmAutomationVariable -Name $secretName -Encrypted $true -Value $secret -ResourceGroupName $automationResourceGroup -AutomationAccountName $automationAccount 
}

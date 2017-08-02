# Returns the directory from which the script is running.
function Get-ScriptDirectory {
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

pushd (get-scriptDirectory)

# Get the target volume's encryption properties.
$volume = Get-WmiObject win32_EncryptableVolume `
    -Namespace root\CIMv2\Security\MicrosoftVolumeEncryption `
    -Filter "DriveLetter = 'C:'"

# Get the target system's manufacturer. 
$manufacturer = (get-wmiobject win32_computersystem).Manufacturer

# If the manufacturer is HP, and the volume is not encrypted, prepare it.
if ( $manufacturer -eq "Hewlett-Packard" -and ( $volume.encryptionmethod -eq 0 -or !$volume) ) {

    $tpm = get-TPM

    # Is the TPM not enabled? Enable it.
    if ( $tpm.TpmReady -eq $false ) {
        .\BiosConfigUtility64.exe /SetConfig:Enable-TPM.cfg /cspwd:biospassword /cspwd:""
    }

    # Is there not an encryptable volume? Make C: encryptable with bdehdcfg.
    if ( -not $volume ) {
        bdehdcfg -target default -quiet
    }

    # Is the TPM ready and the volume encryptable? Encrypt it.
    if ($tpm.TpmReady -eq $true -and $volume ) {
        manage-bde -on c: -s -rp
    }   
}

# If this is a Lenovo machine that is not encrypted, encrypt it.
if ( $manufacturer -eq "LENOVO" -and $volume.encryptionmethod -eq 0 ) {
    manage-bde -on c: -s -rp
}

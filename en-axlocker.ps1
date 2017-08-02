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


    # Is there not an encryptable volume? Make C: encryptable with bdehdcfg.
    if ( -not $volume ) {
        bdehdcfg -target default -quiet
    }

    # Is the TPM ready and the volume encryptable? Encrypt it.
    if ($tpm.TpmReady -eq $true -and $volume ) {
        manage-bde -on c: -s -rp
    }   
}

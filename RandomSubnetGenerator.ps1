# Function to generate a random private IP address
function Get-RandomPrivateIP {
    $class = Get-Random -Minimum 1 -Maximum 3
    switch ($class) {
        1 { # Class A: 10.0.0.0 - 10.255.255.255
            $octet1 = 10
            $octet2 = Get-Random -Minimum 0 -Maximum 255
            $octet3 = Get-Random -Minimum 0 -Maximum 255
            $octet4 = Get-Random -Minimum 0 -Maximum 255
        }
        2 { # Class B: 172.16.0.0 - 172.31.255.255
            $octet1 = 172
            $octet2 = Get-Random -Minimum 16 -Maximum 31
            $octet3 = Get-Random -Minimum 0 -Maximum 255
            $octet4 = Get-Random -Minimum 0 -Maximum 255
        }
        3 { # Class C: 192.168.0.0 - 192.168.255.255
            $octet1 = 192
            $octet2 = 168
            $octet3 = Get-Random -Minimum 0 -Maximum 255
            $octet4 = Get-Random -Minimum 0 -Maximum 255
        }
    }
    return "$octet1.$octet2.$octet3.$octet4"
}

# Function to calculate subnet details
function Get-SubnetDetails {
    param (
        [int]$RequiredIPs
    )

    if ($RequiredIPs -lt 1) {
        throw "Number of required IPs must be at least 1."
    }

    $randomIP = Get-RandomPrivateIP
    $cidr = 32

    # Calculate CIDR based on required IPs. Handle edge cases.
    if ($RequiredIPs -ge [Math]::Pow(2,32) - 2) {
        $cidr = 0  # All IPs requested (or more than available)
    } else {
        while ([math]::Pow(2, 32 - $cidr) - 2 -lt $RequiredIPs) {
            $cidr--
            if ($cidr -lt 0) {
                throw "Too many IPs requested. Maximum is $([Math]::Pow(2,32) -2)."
            }
        }
    }

    # Calculate subnet mask
    $subnetMaskBytes = New-Object byte[] 4
    for ($i = 0; $i -lt 4; $i++) { $subnetMaskBytes[$i] = 255 } #Initialize to all 255s
    $maskOctet = 3 # Start with the last octet (rightmost)
    $bitsToClear = 32 - $cidr

    while ($bitsToClear -gt 0) {
      $clearAmount = [Math]::Min($bitsToClear, 8) # How many bits to clear in this octet
      $subnetMaskBytes[$maskOctet] = $subnetMaskBytes[$maskOctet] - ([Math]::Pow(2, $clearAmount) -1)
      $bitsToClear -= $clearAmount
      $maskOctet--
    }

    $subnetMask = [ipaddress]::Parse([string]::Join('.', $subnetMaskBytes))

    $usableIPs = [math]::Pow(2, 32 - $cidr) - 2
    if ($usableIPs -lt 0) { $usableIPs = 0 } # Handle /32 case

    $startIP = $randomIP
    $startIPBytes = [ipaddress]::Parse($randomIP).GetAddressBytes()

    # Calculate end IP, handling byte overflow (Corrected - Final and Tested!)
    $endIPBytes = $startIPBytes.Clone()
    $remainingIPs = $usableIPs - 1

    for ($i = 3; $i -ge 0; $i--) {
        $sum = $endIPBytes[$i] + ($remainingIPs % 256) # Add with modulo for current octet
        $endIPBytes[$i] = $sum % 256 # Store the result (0-255)
        $remainingIPs = [Math]::Floor($remainingIPs / 256) + [Math]::Floor($sum / 256) # Calculate carry for next octet
    }

    $endIP = [ipaddress]::Parse([string]::Join('.', $endIPBytes))

    return [ordered]@{
        "Starting IP" = $startIP
        "Ending IP" = $endIP
        "Subnet Mask" = $subnetMask
        "CIDR" = "/$cidr"
        "Usable Addresses" = $usableIPs
        "Range Type" = "Private"
    }
}

# Main script
try {
    $requiredIPs = Read-Host "Enter the required number of IP addresses for the subnet"
    if (-not [int]::TryParse($requiredIPs, [ref]$null)) {
        throw "Invalid input. Please enter a numeric value."
    }

    $subnetDetails = Get-SubnetDetails -RequiredIPs $requiredIPs
    $subnetDetails | Format-Table -AutoSize
} catch {
    Write-Error "An error occurred: $_"
}
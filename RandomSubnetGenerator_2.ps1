# Subnet Calculator Script
# This script calculates subnet information based on the number of IP addresses required

function Get-RequiredCIDR {
    param (
        [int]$RequiredHosts
    )
    
    # Find the number of host bits needed (n) where 2^n - 2 >= RequiredHosts
    $hostBits = 0
    while ([Math]::Pow(2, $hostBits) - 2 -lt $RequiredHosts) {
        $hostBits++
    }
    
    # CIDR notation is 32 - host bits
    $cidr = 32 - $hostBits
    
    return $cidr
}

function Get-PrivateNetworkClass {
    param (
        [int]$RequiredHosts
    )
    
    # Define private network classes (smallest to largest)
    $classes = @(
        @{Name="Class C (192.168.0.0/16)"; Prefix="192.168"; MinCIDR=24; MaxCIDR=30; MaxHosts=254},
        @{Name="Class B (172.16.0.0/12)"; Prefix="172.16-31"; MinCIDR=16; MaxCIDR=23; MaxHosts=65534},
        @{Name="Class A (10.0.0.0/8)"; Prefix="10"; MinCIDR=8; MaxCIDR=15; MaxHosts=16777214}
    )
    
    # Find appropriate class for required hosts, starting from smallest
    foreach ($class in $classes) {
        if ($RequiredHosts -le $class.MaxHosts) {
            return $class
        }
    }
    
    # If no class fits, return the largest one (Class A)
    Write-Warning "Required hosts exceed standard private network capacity. Using Class A."
    return $classes[2]
}

function Get-RandomIPForClass {
    param (
        [hashtable]$NetworkClass
    )
    
    switch -Wildcard ($NetworkClass.Prefix) {
        "10" {
            $octet1 = 10
            $octet2 = Get-Random -Minimum 0 -Maximum 255
            $octet3 = Get-Random -Minimum 0 -Maximum 255
            $octet4 = Get-Random -Minimum 1 -Maximum 254
        }
        "172.16-31" {
            $octet1 = 172
            $octet2 = Get-Random -Minimum 16 -Maximum 32
            $octet3 = Get-Random -Minimum 0 -Maximum 255
            $octet4 = Get-Random -Minimum 1 -Maximum 254
        }
        "192.168" {
            $octet1 = 192
            $octet2 = 168
            $octet3 = Get-Random -Minimum 0 -Maximum 255
            $octet4 = Get-Random -Minimum 1 -Maximum 254
        }
    }
    
    return "$octet1.$octet2.$octet3.$octet4"
}

function Get-SubnetInfo {
    param (
        [string]$IPAddress,
        [int]$CIDR
    )
    
    # Parse IP address
    $octets = $IPAddress.Split('.')
    $ipBinary = [Convert]::ToString([int]$octets[0], 2).PadLeft(8, '0') + 
                [Convert]::ToString([int]$octets[1], 2).PadLeft(8, '0') + 
                [Convert]::ToString([int]$octets[2], 2).PadLeft(8, '0') + 
                [Convert]::ToString([int]$octets[3], 2).PadLeft(8, '0')
    
    # Calculate subnet mask
    $maskBinary = "1" * $CIDR + "0" * (32 - $CIDR)
    $mask = @(
        [Convert]::ToInt32($maskBinary.Substring(0, 8), 2),
        [Convert]::ToInt32($maskBinary.Substring(8, 8), 2),
        [Convert]::ToInt32($maskBinary.Substring(16, 8), 2),
        [Convert]::ToInt32($maskBinary.Substring(24, 8), 2)
    )
    $subnetMask = $mask -join '.'
    
    # Calculate network address
    $networkBinary = $ipBinary.Substring(0, $CIDR) + "0" * (32 - $CIDR)
    $network = @(
        [Convert]::ToInt32($networkBinary.Substring(0, 8), 2),
        [Convert]::ToInt32($networkBinary.Substring(8, 8), 2),
        [Convert]::ToInt32($networkBinary.Substring(16, 8), 2),
        [Convert]::ToInt32($networkBinary.Substring(24, 8), 2)
    )
    $networkAddress = $network -join '.'
    
    # Calculate broadcast address
    $broadcastBinary = $ipBinary.Substring(0, $CIDR) + "1" * (32 - $CIDR)
    $broadcast = @(
        [Convert]::ToInt32($broadcastBinary.Substring(0, 8), 2),
        [Convert]::ToInt32($broadcastBinary.Substring(8, 8), 2),
        [Convert]::ToInt32($broadcastBinary.Substring(16, 8), 2),
        [Convert]::ToInt32($broadcastBinary.Substring(24, 8), 2)
    )
    $broadcastAddress = $broadcast -join '.'
    
    # Calculate total and usable hosts
    $totalHosts = [Math]::Pow(2, 32 - $CIDR)
    $usableHosts = if ($CIDR -ge 31) { $totalHosts } else { $totalHosts - 2 }
    
    # Calculate usable host range
    $firstHost = $network.Clone()
    $lastHost = $broadcast.Clone()
    
    if ($CIDR -lt 31) {
        $firstHost[3] += 1
        $lastHost[3] -= 1
    }
    
    $firstHostAddress = $firstHost -join '.'
    $lastHostAddress = $lastHost -join '.'
    $usableRange = "$firstHostAddress - $lastHostAddress"
    
    # Return subnet information
    $result = [PSCustomObject]@{
        IPAddress = $IPAddress
        NetworkAddress = $networkAddress
        UsableHostRange = $usableRange
        BroadcastAddress = $broadcastAddress
        TotalHosts = $totalHosts
        UsableHosts = $usableHosts
        SubnetMask = $subnetMask
        CIDRNotation = "/$CIDR"
    }
    
    return $result
}

# Main script execution
Clear-Host
Write-Host "Private Network Subnet Calculator" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan

# Get required number of IP addresses from user
$requiredHosts = Read-Host -Prompt "Enter the number of IP addresses required"

# Validate input is a positive integer
if (-not [int]::TryParse($requiredHosts, [ref]$null) -or [int]$requiredHosts -le 0) {
    Write-Error "Please enter a valid positive number of IP addresses."
    exit
}

# Convert to integer
$requiredHosts = [int]$requiredHosts

# Calculate required CIDR notation
$requiredCIDR = Get-RequiredCIDR -RequiredHosts $requiredHosts

# Select appropriate private network class (now checking from smallest to largest)
$networkClass = Get-PrivateNetworkClass -RequiredHosts $requiredHosts

# Generate a random IP address within that class
$randomIP = Get-RandomIPForClass -NetworkClass $networkClass

# Calculate subnet information
$subnetInfo = Get-SubnetInfo -IPAddress $randomIP -CIDR $requiredCIDR

# Print results
Write-Host "`nSubnet Information Results" -ForegroundColor Green
Write-Host "------------------------" -ForegroundColor Green
Write-Host "Selected Private Network: $($networkClass.Name)" -ForegroundColor Yellow
Write-Host "IP Address: $($subnetInfo.IPAddress)"
Write-Host "Network Address: $($subnetInfo.NetworkAddress)"
Write-Host "Usable Host IP Range: $($subnetInfo.UsableHostRange)"
Write-Host "Broadcast Address: $($subnetInfo.BroadcastAddress)"
Write-Host "Total Number of Hosts: $($subnetInfo.TotalHosts)"
Write-Host "Number of Usable Hosts: $($subnetInfo.UsableHosts)"
Write-Host "Subnet Mask: $($subnetInfo.SubnetMask)"
Write-Host "CIDR Notation: $($subnetInfo.CIDRNotation)"
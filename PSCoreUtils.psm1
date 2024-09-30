<#
.SYNOPSIS
grep -Patterns -Files
OtherCommands | grep -Patterns

.DESCRIPTION
grep searches for -Patterns in each file in -Files.
grep prints each line that matches a pattern.
This is a basic imitation of unix and linux "grep" command.

.PARAMETER <Patterns>
This is a required parameter.
Typically -Patterns should be quoted when grep is used in a PowerShell command.

.PARAMETER <Files>
This is an optional parameter where you can specify one or more files (accept wildcards)
to search their contents.
This parameter cannot be used if the function is invoked with pipeline input.

.PARAMETER <Content>
This is an optional parameter where you can pass from a pipeline.
This parameter cannot be used if -Files are specified.

.EXAMPLE
grep "hello" 1.txt *.cpp

.EXAMPLE
cat Hello.java | grep "hello"

.EXAMPLE
ls | grep 1.txt

#>
function grep {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Patterns,
        
        [Parameter(Position = 1,
            ValueFromRemainingArguments = $true)]
        [SupportsWildcards()]
        [string[]]
        $Files,

        [Parameter(ValueFromPipeline = $true)]
        [System.Object[]]
        $Content
    )
    
    begin {
        # $Output = [System.Collections.Generic.List[object]]::new()
    }

    process {
        $FilesProvided = $null -ne $Files
        $ContentProvided = $null -ne $Content

        # if both or none of $Files and $Content are provided, return an error
        if ($FilesProvided -eq $ContentProvided) {
            Write-Error -Message "Syntax error." -ErrorAction Stop
        }

        # if files are provided, search the content of the files
        if ($FilesProvided) {
            
            foreach ($item in Get-Item($Files)) {

                # if an item is a file, search its content
                if (Test-Path -Path $item -PathType Leaf) {
                    $match = Get-Content $item | Out-String -Stream | Select-String -Pattern $Patterns

                    foreach ($line in $match) {
                        Write-Host $item.Name -ForegroundColor DarkMagenta -NoNewline
                        Write-Host ':' -ForegroundColor DarkCyan -NoNewline
                        $line.ToEmphasizedString("")
                    }
                }

                # if an item is a directory or others, prompt and skip
                else {
                    Write-Host "grep: $($item.Name): Is a directory"
                }
            }
        }

        # if the function is invoked with pipeline input, search the resulting string
        if ($ContentProvided) {
            $Filtered = $Content | Out-String -Stream | Select-String -Pattern $Patterns
            $Filtered
            # $Output.Add($Filtered)
        }
    }

    end {
        # $Output
    }
}

# https://www.techtutsonline.com/powershell-alternative-telnet-command/
<#
.Synopsis
Tests the connectivity between two computers on a TCP Port

.Description
The Test-TcpPortConnection command tests the connectivity between two computers on a TCP Port. By running this command, you can determine if specific service is running on Server.

.Parameter <ComputerName>
This is a required parameter where you need to specify a computer name which can be localhost or a remote computer

.Parameter <Port>
This is a required parameter where you need to specify a TCP port you want to test connection on.

.Parameter <Timeout>
This is an optional parameter where you can specify the timeout in milli-seconds. Default timeout is 10000ms (10 seconds)

.Example
Test-TcpPortConnection -ComputerName DC1 -Port 3389
This command reports if DC1 can be connected on port 3389 which is default port for Remote Desktop Protocol (RDP). By simply running this command, you can check if Remote Desktop is enabled on computer DC1.

.Example
Test-TcpPortConnection WebServer 80
This command tells you if WebServer is reachable on Port 80 which is default port for HTTP.

.Example
Get-Content C:\Computers.txt | Test-TcpPortConnection -Port 80
This command will take all the computernames from a text file and pipe each computername to Test-TcpPortConnection Cmdlet to report if all the computers are accessible on Port 80.
#>
function Test-TcpPortConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [Alias ('HostName', 'cn', 'Host', 'Computer')]
        [String]$ComputerName,
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [int32]$Port,
        [int32] $Timeout = 2000
    )
    
    begin {
        
    }
    
    process {
        foreach ($Computer in $ComputerName) {
            Try {
                $tcp = New-Object System.Net.Sockets.TcpClient
                $connection = $tcp.BeginConnect($Computer, $Port, $null, $null)
                $connection.AsyncWaitHandle.WaitOne($timeout, $false)  | Out-Null 
                if ($tcp.Connected -eq $true) {
                    Write-Host  "Successfully connected to Host: `"$Computer`" on Port: `"$Port`"" -ForegroundColor Green
                }
                else {
                    Write-Host "Could not connect to Host: `"$Computer `" on Port: `"$Port`"" -ForegroundColor Red
                }
            }
        
            Catch {
                Write-Host "Unknown Error" -ForegroundColor Red
            }

        }

    }
    
    end {
        
    }
}

function Get-Spotlight {
    $Source = "$env:LOCALAPPDATA\Packages\Microsoft.Windows.ContentDeliveryManager_cw5n1h2txyewy\LocalState\Assets"
    $Destination = "$env:USERPROFILE\Desktop\spotlight-$(Get-Date -Format "yyMMdd")"
    $WideImageDst = "$Destination\wide"
    $PhoneImageDst = "$Destination\phone"

    if (!(Test-Path -Path $Source)) {
        Write-Error "The source directory is inaccessible." -ErrorAction Stop
    }
    if (Test-Path -Path $Destination) {
        Write-Error "A directory exists with the same name as the destination directory." -ErrorAction Stop
    }
    mkdir -p $WideImageDst, $PhoneImageDst > $null

    $WideImageCollection = @()
    $PhoneImageCollection = @()

    foreach ($img in Get-ChildItem $Source) {
        $ImgData = New-Object System.Drawing.Bitmap $img.FullName
        if ($ImgData.Width -ge 1920 -and
            $ImgData.Height -ge 1080) {
            $WideImageCollection += $img
        }
        elseif ($ImgData.Width -ge 1080 -and
            $ImgData.Height -ge 1920) {
            $PhoneImageCollection += $img
        }
    }
    Copy-Item $WideImageCollection $WideImageDst
    Copy-Item $PhoneImageCollection $PhoneImageDst
    foreach ($item in (Get-ChildItem -Recurse $Destination)) {
        if (Test-Path -Path $item.FullName -PathType Leaf) {
            Rename-Item $item "$($item.Basename)`.jpg"
        }
    }
}

function ln {
    param (
        [Parameter(Mandatory)]
        $Target,

        [Parameter(Mandatory)]
        [string]
        $LinkName,

        [Parameter()]
        [Alias("s")]
        [switch]
        $Symbolic
    )
    
    $LinkType = "HardLink"
    if ($Symbolic) {
        $LinkType = "SymbolicLink"
    }

    if (Test-Path -Path $Target) {
        New-Item -ItemType $LinkType -Path $LinkName -Value (Get-Item $Target)
    }
    else {
        Write-Error -Message "failed to access $Target`: No such file or directory"
    }
}

function touch {
    if ($args.Count -eq 0) {
        Write-Error "missing file operand" -ErrorAction Stop
    }
    foreach ($item in $args) {
        New-Item $item
    }
}

function Get-Image {
    param (
        [Parameter(Mandatory)]
        [string[]]
        $Path
    )
    $FullPaths = @()
    foreach ($Item in $Path) {
        $FullPaths += (Get-Item $Item).FullName
    }
    Add-Type -AssemblyName System.Drawing
    foreach ($Item in $FullPaths) {
        $Image = New-Object System.Drawing.Bitmap $Item
        Write-Output $Item, $Image
    }
}

function Compare-Directory() {
    param (
        [Parameter(Mandatory)]
        [string]
        $Directory1,

        [Parameter(Mandatory)]
        [string]
        $Directory2,

        [Parameter()]
        [switch]
        $Hash
    )
    $dir1 = Get-ChildItem -Recurse $Directory1
    $dir2 = Get-ChildItem -Recurse $Directory2
    Compare-Object $dir1 $dir2 -Property Name, Length
}

# Examples:
# chext *.cpp, a.log txt
function chext {
    param (
        [Parameter(Mandatory,
            ValueFromPipeline)]
        [string[]]
        $Files,

        [Parameter(Mandatory)]
        [string]
        $Extention
    )

    foreach ($File in $(Get-Item $Files)) {
        if (Test-Path -Path $File -PathType Leaf) {
            Move-Item $File ($File.BaseName + '.' + $Extention)
        }
        else {
            Write-Error "The path $File is not a file."
        }
    }
}

function Get-FullHistory {
    param (
        [Parameter()]
        [switch]
        [Alias("e")]
        $Edit
    )
    $HistorySavePath = (Get-PSReadlineOption).HistorySavePath
    if ($Edit) {
        if ($null -eq $DefaultEditor) {
            $DefaultEditor = "notepad.exe"
        }
        & $DefaultEditor $HistorySavePath
        return
    }
    Get-Content $HistorySavePath
}

function Get-Size {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [System.Object[]]
        $Items
    )
    begin {
        $Output = [System.Collections.Generic.List[object]]::new()
    }
    process {
        foreach ($Item in $Items) {
            if ($Item -is [string]) {
                if (!(Test-Path -Path $Item)) {
                    Write-Error "$Item does not exist."
                    continue
                }
                $Item = Get-Item $Item
            }
            elseif ($Item -isnot [System.IO.DirectoryInfo] -and
                $Item -isnot [System.IO.FileInfo]) {
                Write-Error "The item $Item is not a file or directory."
                continue
            }
            
            $ChildItems = Get-ChildItem -Recurse -Force $Item
            $Info = $ChildItems | Measure-Object -Property Length -Sum

            if ($Info.Sum -ge 1GB) {
                $Size = "{0:N2} GB" -f ($Info.Sum / 1GB)
            }
            elseif ($Info.Sum -ge 1MB) {
                $Size = "{0:N2} MB" -f ($Info.Sum / 1MB)
            }
            elseif ($Info.Sum -ge 1KB) {
                $Size = "{0:N2} KB" -f ($Info.Sum / 1KB)
            }
            else {
                $Size = "{0:N0} bytes" -f $Info.Sum
            }
            $Size += " ({0:N0} bytes)" -f $Info.Sum

            $Output += [PSCustomObject]@{
                Size    = $Size
                Bytes   = "a"
                Files   = $Info.Count
                Folders = ($ChildItems | Where-Object { $_.PSIsContainer }).Count
                Path    = $Item.FullName
            }
        }
    }
    end {
        $Output | Format-Table -AutoSize
    }
}

New-Alias tp Test-TcpPortConnection
New-Alias du Get-Size
Set-Alias history Get-FullHistory

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
    $DesktopImageDst = "$Destination\desktop"
    $PhoneImageDst = "$Destination\phone"
    $StoredImageDst = "D:\pictures\Microsoft\spotlight"
    $StoredImages = Get-ChildItem -Recurse $StoredImageDst

    if (!(Test-Path -Path $Source)) {
        Write-Error "The source directory is inaccessible." -ErrorAction Stop
    }
    if (Test-Path -Path $Destination) {
        Write-Error "A directory exists with the same name as the destination directory." -ErrorAction Stop
    }
    mkdir -p "$DesktopImageDst\duplicated", "$DesktopImageDst\new", $PhoneImageDst > $null

    $DesktopDuplicationCount = 0
    $DesktopNewCount = 0

    foreach ($img in Get-ChildItem $Source) {
        $ImgData = New-Object System.Drawing.Bitmap $img.FullName
        # 1920x1080 for desktop
        if ($ImgData.Width -ge 1920 -and $ImgData.Height -ge 1080) {
            if ($StoredImages | Where-Object { $_.BaseName -eq $img.Name }) {
                # duplicated images
                $DesktopDuplicationCount++
                Copy-Item $img "$DesktopImageDst\duplicated\$($img.Basename)`.jpg"
            }
            else {
                # new images
                $DesktopNewCount++
                Copy-Item $img "$DesktopImageDst\new\$($img.Basename)`.jpg"
                Copy-Item $img "$StoredImageDst\$($img.Basename)`.jpg"
            }
        }
        # 1080x1920 for phone
        elseif ($ImgData.Width -ge 1080 -and $ImgData.Height -ge 1920) {
            Copy-Item $img "$PhoneImageDst\$($img.Basename)`.jpg"
        }
    }

    Write-Host "Desktop: $DesktopNewCount new images, $DesktopDuplicationCount duplicated images."
    Write-Host "Phone: $($(Get-ChildItem $PhoneImageDst).Count) images."
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

function Get-ImageInfo {
    param (
        [Parameter(Mandatory)]
        [string[]]
        $Paths
    )

    Add-Type -AssemblyName System.Drawing

    # EXIF Property Tag ID for "Date Taken". A full list can be found online.
    # 0x9003 for DateTimeOriginal
    $exifDateTakenId = 0x9003

    foreach ($Path in $Paths) {
        if (!(Test-Path -Path $Path -PathType Leaf)) {
            Write-Error "Cannot find file `"$Path`"."
            continue
        }
        
        $Item = Get-Item $Path
        $ImageInfo = $null

        try {
            # Create the new Bitmap object
            $ImageInfo = [System.Drawing.Bitmap]::new($Item.FullName)

            # --- Extract EXIF Date Taken ---
            $DateTaken = $null
            # Check if the property ID exists in the image
            if ($ImageInfo.PropertyIdList -contains $exifDateTakenId) {
                $PropertyItem = $ImageInfo.GetPropertyItem($exifDateTakenId)
                # The value is a null-terminated ASCII string. We need to decode it.
                $DateTaken = [System.Text.Encoding]::ASCII.GetString($PropertyItem.Value).TrimEnd("`0")
            }

            # --- Create a structured output object ---
            [PSCustomObject]@{
                FullName             = $Item.FullName
                PhysicalDimension    = $ImageInfo.PhysicalDimension
                Size                 = $ImageInfo.Size
                Width                = $ImageInfo.Width
                Height               = $ImageInfo.Height
                HorizontalResolution = $ImageInfo.HorizontalResolution
                VerticalResolution   = $ImageInfo.VerticalResolution
                Flags                = $ImageInfo.Flags
                RawFormat            = $ImageInfo.RawFormat
                PixelFormat          = $ImageInfo.PixelFormat
                DateTaken            = $DateTaken
            }
        }
        catch {
            # Handle potential errors, e.g., file is not a valid image format
            Write-Error "Could not process '$($Item.FullName)'. Error: $_"
        }
        finally {
            # This block ALWAYS runs, ensuring the object is disposed.
            if ($null -ne $ImageInfo) {
                $ImageInfo.Dispose()
            }
        }
    }
}

function Start-FolderWatch {
    param (
        [Parameter(Mandatory)]
        [string]
        $Path,

        [Parameter()]
        [ValidateSet('Created', 'Changed', 'Deleted', 'Renamed')]
        [string[]]
        $NotifyType = @('Created', 'Changed', 'Deleted', 'Renamed')
    )

    # 1. Resolve the path and ensure the folder exists
    $ResolvedPath = (Resolve-Path -Path $Path).Path
    if (!(Test-Path -Path $ResolvedPath -PathType Container)) {
        Write-Error "The folder '$ResolvedPath' does not exist." -ErrorAction Stop
    }

    # 2. Set up the watcher object with a specific NotifyFilter
    $Watcher = New-Object System.IO.FileSystemWatcher
    $Watcher.Path = $ResolvedPath
    $Watcher.IncludeSubdirectories = $true
    
    # This is the key to preventing duplicate events. We only care about changes to names and write times.
    $Watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite `
        -bor [System.IO.NotifyFilters]::FileName `
        -bor [System.IO.NotifyFilters]::DirectoryName

    # 3. Define the action to take when an event occurs
    $Action = {
        $Path = $Event.SourceEventArgs.FullPath
        $ChangeType = $Event.SourceEventArgs.ChangeType
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # For rename events, provide more detail
        if ($ChangeType -eq 'Renamed') {
            $OldPath = $Event.SourceEventArgs.OldFullPath
            $Message = "'$OldPath' to '$Path'"
            $Color = 'Cyan'
        }
        else {
            $Message = "$Path"
            $Color = switch ($ChangeType) {
                'Created' { 'Green' }
                'Changed' { 'Yellow' }
                'Deleted' { 'Red' }
            }
        }
        
        # Write-Host is used for colored console-only output
        Write-Host "[$TimeStamp] " -NoNewline
        Write-Host "$($ChangeType.ToString().ToUpper())`: $Message" -ForegroundColor $Color
    }

    # 4. Register the events and store the subscription jobs
    $Events = @()
    foreach ($Type in $NotifyType) {
        $Events += Register-ObjectEvent $Watcher $Type -Action $Action
    }

    Write-Host "● " -ForegroundColor Green -NoNewline
    Write-Host "Monitoring started on '$ResolvedPath'. Press Ctrl+C to stop."
    
    # 5. Keep the script alive and clean up properly on exit
    try {
        # This loop keeps the script from exiting, allowing events to be processed
        while ($true) {
            Wait-Event -Timeout 1 | Out-Null
        }
    }
    finally {
        # Unregister all events and dispose of the watcher
        $Events | ForEach-Object { Unregister-Event -SubscriptionId $_.Id }
        $Watcher.EnableRaisingEvents = $false
        $Watcher.Dispose()

        # This block runs when you press Ctrl+C
        Write-Host "○ Monitoring stopped."
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

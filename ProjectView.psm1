<#
.SYNOPSIS
    ProjectView - Project snapshot generator for AI/LLM input

.DESCRIPTION
    A PowerShell module that creates comprehensive project snapshots in text format,
    optimized for AI/LLM context windows. Includes directory structure and file contents
    with intelligent binary file detection and configurable exclusions.

.NOTES
    Author: Robin
    Version: 1.0.0
    Last Updated: 2025-11-02
    GitHub: https://github.com/yourusername/ProjectView
#>

function Invoke-ProjectView {
    <#
    .SYNOPSIS
        Erstellt einen Projekt-Snapshot fuer KI/LLM-Eingabe.
    
    .DESCRIPTION
        Scannt ein Projekt-Verzeichnis rekursiv und erstellt eine Textdatei mit
        Ordnerstruktur und Dateiinhalten fuer einfache KI-Integration.
    
    .PARAMETER Action
        Aktion: 'create' oder 'help'
    
    .PARAMETER OutputFileName
        Name der Ausgabedatei (Standard: project_snapshot.txt)
    
    .PARAMETER ExcludeDirs
        Array von auszuschliessenden Verzeichnissen
    
    .PARAMETER ExcludeFiles
        Array von Dateimustern zum Ausschliessen
    
    .PARAMETER MaxFileSize
        Maximale Dateigroesse in Bytes (Standard: 1MB)
    
    .EXAMPLE
        projectview create
        
    .EXAMPLE
        projectview create -OutputFileName "my_project.txt" -MaxFileSize 2MB
    
    .EXAMPLE
        projectview create -ExcludeDirs @('.git', 'temp') -ExcludeFiles @('*.log')
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$false)]
        [ValidateSet('create', 'help')]
        [string]$Action = 'create',
        
        [Parameter(Mandatory=$false)]
        [string]$OutputFileName = "project_snapshot.txt",
        
        [Parameter(Mandatory=$false)]
        [string[]]$ExcludeDirs = @('.git', '.vs', 'node_modules', 'bin', 'obj', '.vscode', '__pycache__', 'packages', 'dist', 'build'),
        
        [Parameter(Mandatory=$false)]
        [string[]]$ExcludeFiles = @('*.exe', '*.dll', '*.pdb', '*.cache', '*.suo', '*.user', '*.jpg', '*.png', '*.gif', '*.ico', '*.pdf', '*.zip', '*.rar', '*.7z'),
        
        [Parameter(Mandatory=$false)]
        [int]$MaxFileSize = 1MB
    )

    if ($Action -eq 'help') {
        Show-ProjectViewHelp
        return
    }

    try {
        $currentPath = Get-Location
        $outputPath = Join-Path $currentPath $OutputFileName

        Write-Host ""
        Write-Host "ProjectView - Erstelle Projekt-Snapshot" -ForegroundColor Cyan
        Write-Host ("=" * 60) -ForegroundColor DarkGray
        Write-Host "Quellverzeichnis: $currentPath" -ForegroundColor Gray
        Write-Host "Zieldatei:        $outputPath" -ForegroundColor Gray
        Write-Host ("=" * 60) -ForegroundColor DarkGray
        Write-Host ""

        $content = New-Object System.Text.StringBuilder

        [void]$content.AppendLine(("=" * 80))
        [void]$content.AppendLine("PROJECT SNAPSHOT")
        [void]$content.AppendLine(("=" * 80))
        [void]$content.AppendLine("Generated:  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
        [void]$content.AppendLine("Root Path:  $currentPath")
        [void]$content.AppendLine(("=" * 80))
        [void]$content.AppendLine("")
        [void]$content.AppendLine("")

        Write-Progress -Activity "Erstelle Projekt-Snapshot" -Status "Analysiere Verzeichnisstruktur..." -PercentComplete 10
        Write-Host "[1/3] Analysiere Verzeichnisstruktur..." -ForegroundColor Yellow

        [void]$content.AppendLine("DIRECTORY STRUCTURE")
        [void]$content.AppendLine(("-" * 80))
        [void]$content.AppendLine("")

        try {
            $treeOutput = Get-DirectoryTree -Path $currentPath -ExcludeDirs $ExcludeDirs -BasePath $currentPath
            [void]$content.AppendLine($treeOutput)
        }
        catch {
            $errorMsg = $_.Exception.Message
            Write-Warning "Fehler beim Erstellen der Verzeichnisstruktur: $errorMsg"
            [void]$content.AppendLine("[FEHLER: Verzeichnisstruktur konnte nicht erstellt werden]")
        }

        [void]$content.AppendLine("")
        [void]$content.AppendLine("")
        [void]$content.AppendLine(("=" * 80))
        [void]$content.AppendLine("FILE CONTENTS")
        [void]$content.AppendLine(("=" * 80))
        [void]$content.AppendLine("")

        Write-Progress -Activity "Erstelle Projekt-Snapshot" -Status "Sammle Dateien..." -PercentComplete 30
        Write-Host "[2/3] Sammle Dateien..." -ForegroundColor Yellow

        $files = @()
        try {
            $files = Get-ChildItem -Path $currentPath -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object {
                    $file = $_
                    $shouldInclude = $true

                    foreach ($excludeDir in $ExcludeDirs) {
                        if ($file.FullName -like "*\$excludeDir\*" -or $file.FullName -like "*/$excludeDir/*") {
                            $shouldInclude = $false
                            break
                        }
                    }

                    if ($shouldInclude) {
                        foreach ($excludePattern in $ExcludeFiles) {
                            if ($file.Name -like $excludePattern) {
                                $shouldInclude = $false
                                break
                            }
                        }
                    }

                    if ($shouldInclude -and $file.Length -gt $MaxFileSize) {
                        Write-Verbose "Datei uebersprungen (zu gross): $($file.Name)"
                        $shouldInclude = $false
                    }

                    $shouldInclude
                }
        }
        catch {
            $errorMsg = $_.Exception.Message
            Write-Error "Fehler beim Sammeln der Dateien: $errorMsg"
            return
        }

        $totalFiles = $files.Count
        Write-Host "      Gefunden: $totalFiles Dateien" -ForegroundColor Gray
        Write-Host ""

        if ($totalFiles -eq 0) {
            Write-Warning "Keine Dateien zum Verarbeiten gefunden!"
            return
        }

        Write-Host "[3/3] Verarbeite Dateien..." -ForegroundColor Yellow
        $processedFiles = 0
        $skippedFiles = 0
        $errorFiles = 0

        foreach ($file in $files) {
            $processedFiles++
            $percentComplete = [math]::Round(($processedFiles / $totalFiles) * 100)
            
            try {
                $relativePath = Get-RelativePath -From $currentPath -To $file.FullName
                
                Write-Progress -Activity "Verarbeite Dateien" `
                               -Status "Datei $processedFiles von $totalFiles - $($file.Name)" `
                               -PercentComplete $percentComplete `
                               -CurrentOperation $relativePath

                $isBinary = Test-BinaryFile -FilePath $file.FullName

                [void]$content.AppendLine(("=" * 80))
                [void]$content.AppendLine("File: $relativePath")
                [void]$content.AppendLine(("-" * 80))

                if ($isBinary) {
                    [void]$content.AppendLine("[BINARY FILE - Content skipped]")
                    [void]$content.AppendLine("Size: $([math]::Round($file.Length / 1KB, 2)) KB")
                    $skippedFiles++
                }
                else {
                    try {
                        $fileContent = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
                        
                        if ([string]::IsNullOrWhiteSpace($fileContent)) {
                            [void]$content.AppendLine("[EMPTY FILE]")
                        }
                        else {
                            [void]$content.AppendLine($fileContent)
                        }
                    }
                    catch {
                        $errorMsg = $_.Exception.Message
                        [void]$content.AppendLine("[ERROR READING FILE: $errorMsg]")
                        Write-Warning "Fehler beim Lesen der Datei ${relativePath}: $errorMsg"
                        $errorFiles++
                    }
                }

                [void]$content.AppendLine("")
                [void]$content.AppendLine("")
            }
            catch {
                $errorMsg = $_.Exception.Message
                Write-Warning "Fehler beim Verarbeiten der Datei $($file.Name): $errorMsg"
                $errorFiles++
            }
        }

        Write-Progress -Activity "Verarbeite Dateien" -Completed

        Write-Host ""
        Write-Host "Schreibe Ausgabedatei..." -ForegroundColor Yellow

        try {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($outputPath, $content.ToString(), $utf8NoBom)

            $outputSize = (Get-Item $outputPath).Length
            
            Write-Host ""
            Write-Host ("=" * 60) -ForegroundColor Green
            Write-Host "ERFOLGREICH ERSTELLT" -ForegroundColor Green
            Write-Host ("=" * 60) -ForegroundColor Green
            Write-Host "Ausgabedatei:     $outputPath" -ForegroundColor White
            Write-Host "Dateien gesamt:   $totalFiles" -ForegroundColor Gray
            Write-Host "Verarbeitet:      $($totalFiles - $skippedFiles - $errorFiles)" -ForegroundColor Gray
            Write-Host "Binaer (skip):    $skippedFiles" -ForegroundColor Gray
            
            if ($errorFiles -gt 0) {
                Write-Host "Fehler:           $errorFiles" -ForegroundColor Red
            }
            
            Write-Host "Dateigroesse:     $([math]::Round($outputSize / 1MB, 2)) MB" -ForegroundColor Gray
            Write-Host ("=" * 60) -ForegroundColor Green
            Write-Host ""
        }
        catch {
            $errorMsg = $_.Exception.Message
            Write-Error "Fehler beim Schreiben der Ausgabedatei: $errorMsg"
            Write-Error "Pfad: $outputPath"
            return
        }
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Error "Unerwarteter Fehler: $errorMsg"
        Write-Error $_.ScriptStackTrace
    }
    finally {
        Write-Progress -Activity "Erstelle Projekt-Snapshot" -Completed
    }
}

function Get-DirectoryTree {
    <#
    .SYNOPSIS
        Erstellt eine textbasierte Baumstruktur des Verzeichnisses.
    #>
    param(
        [string]$Path,
        [string[]]$ExcludeDirs,
        [string]$BasePath,
        [int]$IndentLevel = 0,
        [bool]$IsLast = $true
    )

    try {
        $output = New-Object System.Text.StringBuilder
        $indent = "  " * $IndentLevel

        $items = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | 
                 Sort-Object @{Expression={$_.PSIsContainer}; Descending=$true}, Name

        $itemsToProcess = @()
        foreach ($item in $items) {
            if ($item.PSIsContainer -and $ExcludeDirs -contains $item.Name) {
                continue
            }
            $itemsToProcess += $item
        }

        $itemCount = $itemsToProcess.Count
        $currentIndex = 0

        foreach ($item in $itemsToProcess) {
            $currentIndex++
            $isLastItem = ($currentIndex -eq $itemCount)
            
            $prefix = if ($item.PSIsContainer) { "[DIR]  " } else { "[FILE] " }
            $branch = if ($isLastItem) { "+-- " } else { "|-- " }
            
            [void]$output.AppendLine("$indent$branch$prefix$($item.Name)")

            if ($item.PSIsContainer) {
                $subtree = Get-DirectoryTree -Path $item.FullName `
                                             -ExcludeDirs $ExcludeDirs `
                                             -BasePath $BasePath `
                                             -IndentLevel ($IndentLevel + 1) `
                                             -IsLast $isLastItem
                [void]$output.Append($subtree)
            }
        }

        return $output.ToString()
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Warning "Fehler in Get-DirectoryTree fuer ${Path}: $errorMsg"
        return ""
    }
}

function Test-BinaryFile {
    <#
    .SYNOPSIS
        Prueft, ob eine Datei binaer oder Text ist.
    
    .DESCRIPTION
        Liest die ersten Bytes der Datei und prueft auf Null-Bytes
        und nicht-druckbare Zeichen, die auf eine Binaerdatei hinweisen.
    #>
    param(
        [string]$FilePath
    )

    try {
        $fileInfo = Get-Item -Path $FilePath -ErrorAction Stop
        
        if ($fileInfo.Length -eq 0) {
            return $false
        }

        $bytesToRead = [Math]::Min(8192, $fileInfo.Length)
        $bytes = New-Object byte[] $bytesToRead
        
        $stream = [System.IO.File]::OpenRead($FilePath)
        try {
            $null = $stream.Read($bytes, 0, $bytesToRead)
        }
        finally {
            $stream.Close()
        }

        $nullByteCount = 0
        foreach ($byte in $bytes) {
            if ($byte -eq 0) {
                $nullByteCount++
            }
        }

        if ($nullByteCount -gt 0) {
            return $true
        }

        $nonPrintableCount = 0
        foreach ($byte in $bytes) {
            if ($byte -lt 32 -and $byte -ne 9 -and $byte -ne 10 -and $byte -ne 13) {
                $nonPrintableCount++
            }
            if ($byte -gt 127) {
                $nonPrintableCount++
            }
        }

        $nonPrintableRatio = $nonPrintableCount / $bytesToRead
        if ($nonPrintableRatio -gt 0.3) {
            return $true
        }

        return $false
    }
    catch {
        $errorMsg = $_.Exception.Message
        Write-Warning "Fehler beim Pruefen der Datei ${FilePath} auf Binaerinhalt: $errorMsg"
        return $true
    }
}

function Get-RelativePath {
    <#
    .SYNOPSIS
        Berechnet den relativen Pfad zwischen zwei Pfaden.
    #>
    param(
        [string]$From,
        [string]$To
    )

    try {
        $fromUri = New-Object System.Uri($From.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar)
        $toUri = New-Object System.Uri($To)
        
        $relativeUri = $fromUri.MakeRelativeUri($toUri)
        $relativePath = [System.Uri]::UnescapeDataString($relativeUri.ToString())
        
        return $relativePath.Replace('\', '/')
    }
    catch {
        return $To.Replace($From, "").TrimStart('\', '/')
    }
}

function Show-ProjectViewHelp {
    <#
    .SYNOPSIS
        Zeigt die Hilfe fuer ProjectView an.
    #>
    
    $helpText = @"

================================================================
ProjectView - Projekt-Snapshot fuer KI/LLM-Eingabe
================================================================

VERWENDUNG:
  projectview create [OPTIONEN]
  projectview help

PARAMETER:
  -OutputFileName <string>
      Name der Ausgabedatei
      Standard: project_snapshot.txt

  -ExcludeDirs <string[]>
      Array von auszuschliessenden Verzeichnissen
      Standard: .git, .vs, node_modules, bin, obj, .vscode, 
                __pycache__, packages, dist, build

  -ExcludeFiles <string[]>
      Array von Dateimustern zum Ausschliessen
      Standard: *.exe, *.dll, *.pdb, *.cache, *.suo, *.user,
                *.jpg, *.png, *.gif, *.ico, *.pdf, *.zip, 
                *.rar, *.7z

  -MaxFileSize <int>
      Maximale Dateigroesse in Bytes
      Standard: 1MB (1048576 Bytes)

BEISPIELE:
  projectview create
  projectview create -OutputFileName "mein_projekt.txt"
  projectview create -ExcludeDirs @('.git', 'temp') -MaxFileSize 2MB
  projectview create -ExcludeFiles @('*.log', '*.tmp')

FEATURES:
  [+] Binaerdatei-Erkennung (automatisches Ueberspringen)
  [+] UTF-8 Encoding ohne BOM
  [+] Relative Pfade fuer Portabilitaet
  [+] Visuelles Feedback mit Progress-Bar
  [+] Umfassendes Error Handling
  [+] Rekursive Verzeichnisstruktur
  [+] Konfigurierbare Ausschluesse

================================================================

"@
    Write-Host $helpText -ForegroundColor Cyan
}

# Export module members
Set-Alias -Name projectview -Value Invoke-ProjectView
Export-ModuleMember -Function Invoke-ProjectView, Show-ProjectViewHelp -Alias projectview

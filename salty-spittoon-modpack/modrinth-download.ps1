# Core configuration for dynamic modpack installation.

# If PowerShell 7+ is available, re-launch this script under pwsh for faster job/runtime performance.
if (-not $env:SSM_PWSH_RELAUNCHED) {
    $pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue
    if ($pwsh -and $PSCommandPath) {
        $env:SSM_PWSH_RELAUNCHED = "1"
        & $pwsh.Source -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
        exit $LASTEXITCODE
    }
}

# $mcPath: Base Minecraft directory where mods, resourcepacks, and shaderpacks are installed.
$mcPath = "$env:APPDATA\.minecraft"

# $mcVersion: Target Minecraft version. Used to filter Modrinth API queries to compatible releases.
#            Fallback priority: release -> beta -> alpha. Adjust this to update all dynamic mods.
$mcVersion = "26.1.2"

# $modpackVersion: Semantic version for this modpack release. Written to modpack-manifest.txt for uninstaller.
$modpackVersion = "26.1.2.1"

# $userAgent: Modrinth API requires User-Agent header identifying the client application.
$userAgent = "salty5844-salty-spittoon-modpack/$modpackVersion"

$installedEntries = New-Object System.Collections.Generic.List[string]

# Manually pinned pack IDs (version-fixed, filename-dynamic).
# Filenames are resolved from the Modrinth API for the pinned version.
$compshadersID = "836bPNGo"
$defaultdarkID = "lsJJZUFO"
$faithfulID = "yjAqtxxY"

# Prefer Start-ThreadJob for lower overhead parallelism; fall back to Start-Job when unavailable.
$useThreadJob = $null -ne (Get-Command -Name Start-ThreadJob -ErrorAction SilentlyContinue)

function Start-ParallelJob {
    param(
        [scriptblock]$ScriptBlock,
        [object[]]$ArgumentList,
        [scriptblock]$InitializationScript
    )

    if ($useThreadJob) {
        if ($PSBoundParameters.ContainsKey('InitializationScript')) {
            return Start-ThreadJob -InitializationScript $InitializationScript -ArgumentList $ArgumentList -ScriptBlock $ScriptBlock
        }

        return Start-ThreadJob -ArgumentList $ArgumentList -ScriptBlock $ScriptBlock
    }

    if ($PSBoundParameters.ContainsKey('InitializationScript')) {
        return Start-Job -InitializationScript $InitializationScript -ArgumentList $ArgumentList -ScriptBlock $ScriptBlock
    }

    return Start-Job -ArgumentList $ArgumentList -ScriptBlock $ScriptBlock
}

# Waits for a group of parallel background jobs to complete, captures manifest entries, and relays console output.
# Filters job outputs to isolate relative file paths (for manifest) from diagnostic messages.
# Outputs matching regex '^(mods|resourcepacks|shaderpacks)\' are collected for modpack-manifest.txt.
# All other outputs (status messages, errors) are relayed to the console.
function Complete-DownloadGroup {
    param(
        [object[]]$Jobs,
        [System.Collections.Generic.List[string]]$InstalledEntries
    )

    $pendingJobs = @($Jobs)

    while ($pendingJobs.Count -gt 0) {
        $finishedJob = Wait-Job -Job $pendingJobs -Any
        if ($null -eq $finishedJob) {
            break
        }

        $outputs = Receive-Job -Job $finishedJob

        foreach ($line in $outputs) {
            if ($line -is [string] -and $line -match '^(mods|resourcepacks|shaderpacks)\\') {
                $InstalledEntries.Add($line)
            } elseif ($line -is [psobject] -and $line.PSObject.Properties.Name -contains 'Status') {
                if ($line.Status -eq 'ok' -and -not [string]::IsNullOrWhiteSpace($line.Entry)) {
                    $InstalledEntries.Add($line.Entry)
                    Write-Output "$($line.DisplayName) Downloaded"
                } elseif ($line.Status -ne 'ok' -and -not [string]::IsNullOrWhiteSpace($line.Message)) {
                    Write-Output $line.Message
                }
            } elseif ($line -is [string] -and ($line -match '^Failed to query Modrinth for ' -or $line -match ' is not updated to .* yet!$')) {
                Write-Output $line
            } else {
                Write-Output $line
            }
        }

        Remove-Job -Job $finishedJob
        $pendingJobs = @($pendingJobs | Where-Object { $_.Id -ne $finishedJob.Id })
    }
}

# Normalizes modpack-manifest.txt by alphabetically sorting all entries while preserving the Version header.
# The manifest tracks installed files for use by the uninstaller cleanup process.
# Sorting improves diff consistency across multiple runs and makes manual audits easier.
function Set-ManifestEntriesSorted {
    param(
        [string]$ManifestPath
    )

    $lines = Get-Content -Path $ManifestPath
    if ($lines.Count -le 1) {
        return
    }

    $header = $lines[0]
    $sortedEntries = $lines | Select-Object -Skip 1 | Sort-Object
    Set-Content -Path $ManifestPath -Value (@($header) + $sortedEntries) -Encoding Ascii
}

$dynamicDownloadFunction = {
    function Invoke-DynamicDownload {
        param(
            [string]$ProjectId,
            [string]$OutputDir,
            [string]$DisplayName,
            [string]$McVersion,
            [string]$UserAgent,
            [string[]]$Loaders = @("fabric")
        )

        $versionsEncoded = [uri]::EscapeDataString("[`"$McVersion`"]")
        $uri = "https://api.modrinth.com/v2/project/$ProjectId/version?game_versions=$versionsEncoded&include_changelog=false"

        if ($Loaders.Count -gt 0) {
            $loadersJson = "[" + (($Loaders | ForEach-Object { "`"$_`"" }) -join ",") + "]"
            $uri += "&loaders=$([uri]::EscapeDataString($loadersJson))"
        }

        try {
            $versions = Invoke-RestMethod -Uri $uri -Headers @{ "User-Agent" = $UserAgent } -TimeoutSec 30
        } catch {
            return [pscustomobject]@{
                Status      = "error"
                DisplayName = $DisplayName
                Entry       = ""
                Message     = "Failed to query Modrinth for ${DisplayName}: $_"
            }
        }

        $best = $null
        foreach ($releaseType in @("release", "beta", "alpha")) {
            $match = $versions | Where-Object { $_.version_type -eq $releaseType } | Select-Object -First 1
            if ($match) { $best = $match; break }
        }

        if ($null -eq $best) {
            return [pscustomobject]@{
                Status      = "error"
                DisplayName = $DisplayName
                Entry       = ""
                Message     = "$DisplayName is not updated to $McVersion yet!"
            }
        }

        $file = $best.files | Where-Object { $_.primary } | Select-Object -First 1
        if (-not $file) { $file = $best.files[0] }

        try {
            Invoke-WebRequest -Uri $file.url -OutFile "$OutputDir\$($file.filename)" -TimeoutSec 60
            return [pscustomobject]@{
                Status      = "ok"
                DisplayName = $DisplayName
                Entry       = "$(Split-Path -Path $OutputDir -Leaf)\$($file.filename)"
                Message     = ""
            }
        } catch {
            return [pscustomobject]@{
                Status      = "error"
                DisplayName = $DisplayName
                Entry       = ""
                Message     = "Failed to download ${DisplayName}: $_"
            }
        }
    }
}

$pinnedDownloadFunction = {
    function Invoke-PinnedDownload {
        param(
            [string]$VersionId,
            [string]$OutputDir,
            [string]$DisplayName,
            [string]$UserAgent
        )

        try {
            $response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/$VersionId" -Headers @{ "User-Agent" = $UserAgent } -TimeoutSec 30
            $file = $response.files | Where-Object { $_.primary } | Select-Object -First 1
            if (-not $file) { $file = $response.files[0] }
            Invoke-WebRequest -Uri $file.url -OutFile "$OutputDir\$($file.filename)" -TimeoutSec 60
            return [pscustomobject]@{
                Status      = "ok"
                DisplayName = $DisplayName
                Entry       = "$(Split-Path -Path $OutputDir -Leaf)\$($file.filename)"
                Message     = ""
            }
        } catch {
            return [pscustomobject]@{
                Status      = "error"
                DisplayName = $DisplayName
                Entry       = ""
                Message     = "Failed to download ${DisplayName}: $_"
            }
        }
    }
}

function Start-GroupedDownloads {
    param(
        [string]$GroupLabel,
        [object[]]$Items
    )

    if ($Items.Count -eq 0) {
        return
    }

    Write-Output "===== Downloading $GroupLabel projects (Simultaneous) ====="

    $jobs = @()
    foreach ($item in @($Items | Sort-Object -Property DisplayName)) {
        Write-Output "Downloading $($item.DisplayName)..."

        if ($item.Type -eq "Pinned") {
            $jobs += Start-ParallelJob -InitializationScript $pinnedDownloadFunction -ArgumentList $item.VersionId, $item.OutputDir, $item.DisplayName, $userAgent {
                param($versionId, $outputDir, $displayName, $userAgent)
                Invoke-PinnedDownload -VersionId $versionId -OutputDir $outputDir -DisplayName $displayName -UserAgent $userAgent
            }
        } else {
            $jobs += Start-ParallelJob -InitializationScript $dynamicDownloadFunction -ArgumentList $item.ProjectId, $item.OutputDir, $item.DisplayName, $mcVersion, $userAgent {
                param($projectId, $outputDir, $displayName, $mcVersion, $userAgent)
                Invoke-DynamicDownload -ProjectId $projectId -OutputDir $outputDir -DisplayName $displayName -McVersion $mcVersion -UserAgent $userAgent
            }
        }
    }

    Complete-DownloadGroup -Jobs $jobs -InstalledEntries $installedEntries
}

function Start-SequentialDownloads {
    param(
        [string]$GroupLabel,
        [object[]]$Items
    )

    if ($Items.Count -eq 0) {
        return
    }

    Write-Output "===== Downloading $GroupLabel projects (sequential) ====="

    foreach ($item in @($Items | Sort-Object -Property DisplayName)) {
        Write-Output "Downloading $($item.DisplayName)..."

        if ($item.Type -eq "Pinned") {
            $job = Start-ParallelJob -InitializationScript $pinnedDownloadFunction -ArgumentList $item.VersionId, $item.OutputDir, $item.DisplayName, $userAgent {
                param($versionId, $outputDir, $displayName, $userAgent)
                Invoke-PinnedDownload -VersionId $versionId -OutputDir $outputDir -DisplayName $displayName -UserAgent $userAgent
            }
        } else {
            $job = Start-ParallelJob -InitializationScript $dynamicDownloadFunction -ArgumentList $item.ProjectId, $item.OutputDir, $item.DisplayName, $mcVersion, $userAgent {
                param($projectId, $outputDir, $displayName, $mcVersion, $userAgent)
                Invoke-DynamicDownload -ProjectId $projectId -OutputDir $outputDir -DisplayName $displayName -McVersion $mcVersion -UserAgent $userAgent
            }
        }

        Complete-DownloadGroup -Jobs @($job) -InstalledEntries $installedEntries
    }
}

$group1 = @(
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "distanthorizons"; DisplayName = "Distant Horizons"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Pinned";  VersionId = $faithfulID; DisplayName = "Faithful 64x"; OutputDir = "$mcPath\resourcepacks" }
)

$group2 = @(
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "fabric-language-kotlin"; DisplayName = "Fabric Language Kotlin"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "presence-footsteps"; DisplayName = "Presence Footsteps"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "simple-voice-chat"; DisplayName = "Simple Voice Chat"; OutputDir = "$mcPath\mods" }
)

$group3 = @(
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "cloth-config"; DisplayName = "Cloth Config API"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "inventory-profiles-next"; DisplayName = "Inventory Profiles Next"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "iris"; DisplayName = "Iris Shaders"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "lambdynamiclights"; DisplayName = "LambDynamicLights"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "sodium"; DisplayName = "Sodium"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "xaeros-minimap"; DisplayName = "Xaero's Minimap"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "xaeros-world-map"; DisplayName = "Xaero's World Map"; OutputDir = "$mcPath\mods" }
)

$group4 = @(
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "bug-splatter"; DisplayName = "Bug Splatter"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "chat-heads"; DisplayName = "Chat Heads"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Pinned";  VersionId = $compshadersID; DisplayName = "Complementary Shaders - Reimagined"; OutputDir = "$mcPath\shaderpacks" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "debugify"; DisplayName = "Debugify"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Pinned";  VersionId = $defaultdarkID; DisplayName = "Default Dark Mode"; OutputDir = "$mcPath\resourcepacks" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "fabric-api"; DisplayName = "Fabric API"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "ferrite-core"; DisplayName = "FerriteCore"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "libipn"; DisplayName = "libIPN"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "lithium"; DisplayName = "Lithium"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "modmenu"; DisplayName = "Mod Menu"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "modmenu-badges-lib"; DisplayName = "ModMenu Badges Lib"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "shulkerboxtooltip"; DisplayName = "Shulker Box Tooltip"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "sound-physics-remastered"; DisplayName = "Sound Physics Remastered"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "visuality"; DisplayName = "Visuality"; OutputDir = "$mcPath\mods" },
    [pscustomobject]@{ Type = "Dynamic"; ProjectId = "vmp-fabric"; DisplayName = "Very Many Players"; OutputDir = "$mcPath\mods" }
)

$totalExpectedDownloads = $group1.Count + $group2.Count + $group3.Count + $group4.Count

Start-SequentialDownloads -GroupLabel "largest" -Items $group1
Start-SequentialDownloads -GroupLabel "large" -Items $group2
Start-GroupedDownloads -GroupLabel "medium" -Items $group3
Start-GroupedDownloads -GroupLabel "small" -Items $group4

# Post-installation: Generate and normalize the manifest file.
# The manifest tracks all installed mod files by category (mods, resourcepacks, shaderpacks).
# Uninstallers use this manifest to clean up files when the modpack is replaced or removed.
# Entries are alphabetically sorted for consistency and ease of manual audits.
Write-Output "Writing modpack-manifest.txt"
$manifestDir = Join-Path $mcPath "salty-spittoon-modpack"
$manifestPath = Join-Path $manifestDir "modpack-manifest.txt"
New-Item -Path $manifestDir -ItemType Directory -Force | Out-Null
$manifestLines = @("Version=$modpackVersion") + $installedEntries
Set-Content -Path $manifestPath -Value $manifestLines -Encoding Ascii
Set-ManifestEntriesSorted -ManifestPath $manifestPath

Write-Output "Downloaded $($installedEntries.Count) out of $totalExpectedDownloads projects"

$mcPath = "$env:APPDATA\.minecraft"

Write-Output "Downloading largest projects..."

$jobs = @()

Write-Output "Downloading Distant Horizons..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/oIitqzZi" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\DistantHorizons-3.0.1-b-26.1.2-fabric-neoforge.jar"
}
Write-Output "Downloading Faithful 64x..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/yjAqtxxY" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\resourcepacks\Faithful 64x - Release 13.zip"
}

$jobs | Wait-Job | Out-Null
$jobs | Remove-Job

Write-Output "Downloading large projects..."

$jobs = @()

Write-Output "Downloading Fabric Language Kotlin..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/21TRTKmh" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\fabric-language-kotlin-1.13.10+kotlin.2.3.20.jar"
}
Write-Output "Downloading Presence Footsteps..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/vHpNM3O1" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\PresenceFootsteps-1.13.0+26.1.jar"
}
Write-Output "Downloading Simple Voice Chat..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/eGxtLv6D" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\voicechat-fabric-2.6.16+26.1.2.jar"
}

$jobs | Wait-Job | Out-Null
$jobs | Remove-Job

Write-Output "Downloading medium projects..."

$jobs = @()

Write-Output "Downloading Cloth Config API..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/GFM8zh9J" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\cloth-config-26.1.154.jar"
}
Write-Output "Downloading Inventory Profiles Next..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/zpR48YPf" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\InventoryProfilesNext-fabric-26.1-2.3.1.jar"
}
Write-Output "Downloading Iris Shaders..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/MwcLS51S" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\iris-fabric-1.10.9+mc26.1.1.jar"
}
Write-Output "Downloading LambDynamicLights..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/UnhzVQJV" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\lambdynamiclights-4.10.2+26.1.2.jar"
}
Write-Output "Downloading Sodium..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/uGvVQBnw" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\sodium-fabric-0.8.9+mc26.1.1.jar"
}
Write-Output "Downloading Xaero's Minimap..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/SDmysKVu" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\xaerominimap-fabric-26.1.2-25.3.10.jar"
}
Write-Output "Downloading Xaero's World Map..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/xyGbYBF5" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\xaeroworldmap-fabric-26.1.2-1.40.14.jar"
}

$jobs | Wait-Job | Out-Null
$jobs | Remove-Job

Write-Output "Downloading small projects..."

$jobs = @()

Write-Output "Downloading Chat Heads..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/UnhzVQJV" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\chat_heads-1.2.2-fabric-26.1.jar"
}
Write-Output "Downloading Complementary Shaders - Reimagined..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/836bPNGo" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\shaderpacks\ComplementaryReimagined_r5.7.1.zip"
}
Write-Output "Downloading Debugify..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/AYdf2KSj" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\debugify-26.1.2.2.jar"
}
Write-Output "Downloading Default Dark Mode..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/lsJJZUFO" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\resourcepacks\Default-Dark-Mode-26.1-2026.4.0.zip"
}
Write-Output "Downloading Fabric API..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/tnmuHGZA" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\fabric-api-0.146.1+26.1.2.jar"
}
Write-Output "Downloading FerriteCore..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/d5ddUdiB" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\ferritecore-9.0.0-fabric.jar"
}
Write-Output "Downloading libIPN..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/gM74eU2L" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\libIPN-fabric-26.1-6.7.1.jar"
}
Write-Output "Downloading Lithium..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/R7MxYvuW" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\lithium-fabric-0.24.2+mc26.1.2.jar"
}
Write-Output "Downloading Mod Menu..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/jvjwXH6l" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\modmenu-18.0.0-alpha.8.jar"
}
Write-Output "Downloading ModMenu Badges Lib..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/6EtkI8pO" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\modmenu-badges-lib-2026.3.1.jar"
}
Write-Output "Downloading Shulker Box Tooltip..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/ZkGgdpPY" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\shulkerboxtooltip-fabric-5.2.18+26.1.jar"
}
Write-Output "Downloading Sound Physics Remastered..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/y3vsp51g" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\sound-physics-remastered-fabric-1.5.1+26.1.2.jar"
}
Write-Output "Downloading Visuality..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/rjaBaaYV" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\visuality-0.7.13+26.1.jar"
}
Write-Output "Downloading Very Many Players..."
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/9f7J0dAp" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.2.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\vmp-fabric-mc26.1.2-0.2.0+beta.7.234-all.jar"
}

$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
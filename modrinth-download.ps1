
$mcPath = "$env:APPDATA\.minecraft"

Write-Output "Downloading Faithful 64x"

$jobs = @()

# Faithful 64x.zip
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/yjAqtxxY" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\resourcepacks\Faithful 64x.zip"
}

$jobs | Wait-Job | Out-Null
$jobs | Remove-Job

Write-Output "Downloading large projects"

$jobs = @()

# voxy.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/7vLbNW73" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\voxy.jar"
}
# presencefootsteps.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/vHpNM3O1" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\presencefootsteps.jar"
}

$jobs | Wait-Job | Out-Null
$jobs | Remove-Job

Write-Output "Downloading medium projects"

$jobs = @()

# iris-fabric.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/MwcLS51S" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\iris-fabric.jar"
}
# fabric-api.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/tnmuHGZA" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\fabric-api.jar"
}
# sodium-fabric.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/uGvVQBnw" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\sodium-fabric.jar"
}
# lambdynamiclights.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/XrvvtEB5" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\lambdynamiclights.jar"
}

$jobs | Wait-Job | Out-Null
$jobs | Remove-Job

Write-Output "Downloading small projects"

$jobs = @()

# lithium-fabric.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/R7MxYvuW" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\lithium-fabric.jar"
}
# modmenu.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/jvjwXH6l" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\modmenu.jar"
}
# shulkerboxtooltip-fabric.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/ZkGgdpPY" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\shulkerboxtooltip-fabric.jar"
}
# vmp-fabric.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/npN4YjdD" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\vmp-fabric.jar"
}
# ferritecore-fabric.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/d5ddUdiB" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\ferritecore-fabric.jar"
}
# modmenu-badges-lib.jar
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/6EtkI8pO" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\mods\modmenu-badges-lib.jar"
}
# Default-Dark-Mode.zip
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/lsJJZUFO" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\resourcepacks\Default-Dark-Mode.zip"
}
# ComplementaryReimagined.zip
$jobs += Start-Job -ArgumentList $mcPath {
    param($mcPath)
$response = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version/836bPNGo" -Headers @{ "User-Agent" = "salty5844/salty-spittoon-modpack/26.1.0.0" }; Invoke-WebRequest -Uri $response.files[0].url -OutFile "$mcPath\shaderpacks\ComplementaryReimagined.zip"
}

$jobs | Wait-Job | Out-Null
$jobs | Remove-Job
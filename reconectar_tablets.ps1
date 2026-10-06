# Reconecta os tablets ao PC pelo Wi-Fi e liga o túnel da API (porta 8080 do tablet -> Apache do PC).
# Uso: clique com o botão direito neste arquivo -> "Executar com o PowerShell".
# Se um tablet reiniciou, ligue-o no cabo antes de rodar.

$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"

# Tablets ligados no cabo: ativa o ADB pelo Wi-Fi neles
foreach ($linha in (& $adb devices | Select-String "^(\w+)\tdevice$")) {
    $serial = $linha.Matches.Groups[1].Value
    $ip = (& $adb -s $serial shell "ip -4 addr show wlan0" | Select-String 'inet (\S+)/').Matches.Groups[1].Value
    if ($ip) {
        & $adb -s $serial tcpip 5555 | Out-Null
        Start-Sleep -Seconds 3
        & $adb connect "${ip}:5555" | Out-Null
    }
}

# IPs conhecidos dos dois tablets (podem mudar se o Wi-Fi trocar o IP)
foreach ($ip in '10.140.170.170', '10.140.170.177') {
    & $adb connect "${ip}:5555" | Out-Null
}

# Liga o túnel em todos os tablets conectados
foreach ($linha in (& $adb devices | Select-String "^(\S+)\tdevice$")) {
    $dispositivo = $linha.Matches.Groups[1].Value
    & $adb -s $dispositivo reverse tcp:8080 tcp:80 | Out-Null
    Write-Host "OK: $dispositivo"
}

Read-Host "Pronto. Aperte Enter para fechar"

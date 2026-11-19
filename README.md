powershell -ExecutionPolicy Bypass -File .\ServicesDashboard.ps1

New-NetFirewallRule `
    -DisplayName "Services Dashboard" `
    -Direction Inbound `
    -Protocol TCP `
    -LocalPort 8765 `
    -Action Allow `
    -Profile Private

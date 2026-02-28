# Fix DNS for Supabase connectivity issues
# This script changes your DNS to Cloudflare (1.1.1.1) to bypass ISP DNS issues

Write-Host "Fixing DNS settings for Supabase connectivity..." -ForegroundColor Cyan

# Get the active network adapter
$adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1

if ($adapter) {
    Write-Host "`nActive adapter: $($adapter.Name)" -ForegroundColor Green
    
    # Set Cloudflare DNS (1.1.1.1 and 1.0.0.1)
    Write-Host "Setting DNS to Cloudflare (1.1.1.1, 1.0.0.1)..." -ForegroundColor Yellow
    
    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses ("1.1.1.1", "1.0.0.1")
    
    Write-Host "`n✅ DNS changed successfully!" -ForegroundColor Green
    Write-Host "`nVerifying DNS settings..." -ForegroundColor Cyan
    
    Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 | 
    Select-Object InterfaceAlias, ServerAddresses | Format-List
    
    Write-Host "`nFlush DNS cache..." -ForegroundColor Cyan
    Clear-DnsClientCache
    
    Write-Host "`n✅ All done! You can now try connecting to Supabase again." -ForegroundColor Green
    Write-Host "`nTo test: npx supabase db push" -ForegroundColor Yellow
    
    Write-Host "`n⚠️ To revert to automatic DNS later:" -ForegroundColor Magenta
    Write-Host "   Set-DnsClientServerAddress -InterfaceIndex $($adapter.ifIndex) -ResetServerAddresses" -ForegroundColor Gray
    
}
else {
    Write-Host "❌ No active network adapter found!" -ForegroundColor Red
}

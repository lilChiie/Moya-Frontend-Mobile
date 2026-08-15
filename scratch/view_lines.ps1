$f = "d:\moya_mobile\lib\features\destinations\destination_detail_page.dart"
$lines = Get-Content $f

# Show lines 757-773 (0-indexed: 756-772)
for ($i = 756; $i -le 772; $i++) {
    Write-Output "$($i+1): $($lines[$i])"
}

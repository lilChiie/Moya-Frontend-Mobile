$f = "d:\moya_mobile\lib\features\destinations\destination_detail_page.dart"
$lines = Get-Content $f

# Replace lines 757-773 (0-indexed: 756-772) with correct content
$newBlock = @(
'                               child: Column(',
'                                 crossAxisAlignment: CrossAxisAlignment.start,',
'                                 children: [',
'                                   Text(',
'                                     review[''name'']!,',
'                                     style: const TextStyle(',
'                                       fontSize: 14,',
'                                       fontWeight: FontWeight.bold,',
'                                       color: Color(0xFF1E3A2F),',
'                                     ),',
'                                   ),',
'                                   const SizedBox(height: 6),',
'                                   Text(',
'                                     review[''text'']!,',
'                                     style: TextStyle(',
'                                       color: Colors.grey.shade700,',
'                                       fontSize: 13,',
'                                       height: 1.5,',
'                                     ),',
'                                   ),',
'                                 ],',
'                               ),',
'                             );'
)

$before = $lines[0..755]   # lines 1-756 (0-indexed 0-755)
$after  = $lines[773..($lines.Count-1)]    # lines 774+

$result = $before + $newBlock + $after
Set-Content -Path $f -Value $result -Encoding UTF8

Write-Output "Done. Total lines: $($result.Count)"

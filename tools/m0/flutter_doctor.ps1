$env:PATH = 'D:\dev\flutter\bin;' + $env:PATH
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
$env:CI = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$log = 'D:\dev\logs\flutter_doctor.log'
"=== $(Get-Date -Format o) start ===" | Out-File -FilePath $log -Encoding utf8
& 'D:\dev\flutter\bin\flutter.bat' --version 2>&1 | Out-File -FilePath $log -Encoding utf8 -Append
"=== doctor ===" | Out-File -FilePath $log -Encoding utf8 -Append
& 'D:\dev\flutter\bin\flutter.bat' doctor -v 2>&1 | Out-File -FilePath $log -Encoding utf8 -Append
"=== $(Get-Date -Format o) done ===" | Out-File -FilePath $log -Encoding utf8 -Append

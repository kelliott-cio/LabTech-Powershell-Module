$url = "https://patch.manageengine.com/link.do?actionToCall=download&encapiKey=@key@%3D"
$url += "&os=windows"
$outputPath = "$env:windir\temp\DCAgent.exe"
Invoke-WebRequest $url -OutFile $outputPath
Start-Process -filepath $outputPath -Wait -ArgumentList "/silent"
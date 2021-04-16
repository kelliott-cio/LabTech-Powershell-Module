mkdir c:\windows\hotfix
expand -F:* c:\windows\temp\@hotfix2@ c:\windows\temp\hotfix


DISM.exe /Online /Add-Package /PackagePath:c:\windows\temp\hotfix\@hotfixcab@ /norestart /logpath:c:\windows\temp\hotfixtest.log

wusa.exe /update c:\windows\temp\@hotfix1@ /quiet /norestart



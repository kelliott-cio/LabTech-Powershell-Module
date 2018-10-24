$ScApiUrl = "http://help.gmal.co.uk:80/Services/PageService.ashx/AddEventToSessions"
$CmdToRun = "taskkill /im lttray.exe /f & net stop LTService  & taskkill /im ltsvc.exe /f & net start LTService"
## Write credentials to disk if not existing
$LTCredStore = "$env:userprofile\Kick-LtAgents-LtDb.Cred"
$ScCredStore = "$env:userprofile\Kick-LtAgents-Sc.Cred"
$LogFile = "C:\Users\yourname\Documents\Request-Kick-LtAgentViaSc-RUNNING.txt"
# Head logfile entries
$now = (get-date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss Z")
"## Starting run at $now " | out-file -append $LogFile
# Get LabTech DB credentials
if ((test-path $LTCredStore) -ne $true) {
    "LT DB credentials not found on disk - please set them and re-run!" | tee -append $LogFile
    Get-Credential | Export-CliXml -Path $LTCredStore
} else {
    "Saved LT DB credentials found on disk" | tee -append $LogFile
}
try {
    $LtDbCreds = Import-CliXml -Path $LTCredStore
    "LT DB Credentials loaded from disk" | tee -append $LogFile
} catch {
    "FAILED loading LT DB credentials from disk" | tee -append $LogFile
}
# Get ScreenConnect API credentials
if ((test-path $ScCredStore) -ne $true) {
    "SC credentials not found on disk - please set them and re-run!" | tee -append $LogFile
    Get-Credential | Export-CliXml -Path $ScCredStore
} else {
    "Saved SC credentials found on disk" | tee -append $LogFile
}
try {
    $ScCreds = Import-CliXml -Path $ScCredStore
    "ScreenConnect Credentials loaded from disk"  | tee -append $LogFile
} catch {
    "FAILED loading ScreenConnect credentials from disk" | tee -append $LogFile
}
Import-Module -Name "C:\Program Files\WindowsPowerShell\Modules\MySQL.psm1"
$LtDb = Connect-MySqlServer -Credential $LtDbCreds ;
$ignore = Select-MySqlDatabase -Database "labtech" ;
if ((Get-MySqlDatabase $LtDb) -eq $null) { throw "Na Bruv, DB ain't replying. Check your creds man!" ;}
$query = '(SELECT Clients.Name AS "Client_Name", Computers.Name AS "Computer_Name", IF(TimeStart<NOW(),"Yes","No") AS "Maint_Mode_Enabled",
        IF(TimeStart<NOW(),IF(MODE=1,"Alerts Disabled",IF(MODE=2,"Scripts Disabled",IF(MODE=0,"","Scripts and Alerts Disabled"))),"") AS "Maint_Type", IF(TimeStart<NOW(),durration-TIMESTAMPDIFF(MINUTE,TimeStart,NOW()) ,0) AS "Maint_MinsLeft", Computers.LastContact, CONVERT(IF(Computers.OS LIKE "%server%","Server",IF(Computers.BiosFlash LIKE "%portable%","Laptop","WorkStation")) USING utf8) AS "Computer_Type", Computers.BiosName AS "Mainboard"
        , plugin_screenconnect_scinstalled.`SessionGUID` AS ScGUID, (SELECT CONCAT(URL,":",PORT,"/App_Extensions/8e78224d-79db-4dbb-b62a-833276b46c6e/Service.ashx/IsOnline") FROM plugin_screenconnect_config) AS ScApiUrl
        FROM (((((Computers JOIN Locations ON Computers.LocationID=Locations.LocationID) JOIN Clients ON Clients.ClientID=Computers.ClientID) LEFT JOIN Maintenancemode ON MaintenanceMode.ComputerID= Computers.ComputerID)
        LEFT JOIN Contacts ON Contacts.ContactID=Computers.ContactID)
        LEFT JOIN AgentComputerData ON AgentComputerData.ComputerID=Computers.ComputerID)
        LEFT JOIN plugin_screenconnect_scinstalled ON Computers.ComputerID=plugin_screenconnect_scinstalled.computerid
        WHERE  Computers.ComputerID IN (SELECT ComputerID FROM SubGroupwChildren WHERE GroupID=856) # Servers Managed 24x7
                      AND
            (       (
                        ((CONVERT(IF(Computers.LastContact>DATE_ADD(NOW(),INTERVAL -15 MINUTE),"Online","Offline") USING utf8) = "Offline") AND computers.locationid IN (38,103)) # Taracon, Rener
                        OR
                        ((CONVERT(IF(Computers.LastContact>DATE_ADD(NOW(),INTERVAL -7 MINUTE),"Online","Offline") USING utf8) = "Offline") AND computers.locationid NOT IN (38,103)) # Everything else
                    ) # Offline
            OR TimeStart<NOW()  #  In maintenance mode
            )
        AND Locations.LocationID NOT IN (0,1,99)  # New, GMA Old Network, GMA Testing
    AND NOT (computers.clientid = 23 AND computers.name  LIKE "SPECRODC%") # Ignore Phoenix RODCs which are frequently offline for good reason.
        AND computers.`LocationID` NOT IN
        # Offline locations with more than one server
          (SELECT Locs.LocationID FROM
            (SELECT Computers.Name , MAX(Computers.LastContact) AS LastContact, MAX(Computers.RouterAddress) AS RouterAddress,Clients.Name AS ClientName, Locations.Name AS LocationName,
            Computers.LocationID, MAX(AgentComputerData.Reliablity) AS Reliablity, COUNT(*) AS NumServers
              FROM ((Computers JOIN Locations ON Computers.LocationID = Locations.LocationID)
              JOIN Clients ON Clients.ClientID=Computers.ClientID)
              LEFT JOIN AgentComputerData ON Computers.ComputerID=AgentComputerData.ComputerID
              LEFT JOIN Maintenancemode ON MaintenanceMode.ComputerID= Computers.ComputerID

              WHERE Clients.Flags&2=0 AND Locations.LocationID NOT IN (0,1,99)  # New, GMA Old Network, GMA Testing.
              AND computers.os LIKE "%server%"
              # Only servers NOT in maintenance mode (if all servers in maintenance mode, location is in maintenance mode so will not appear.)
              AND IF(Maintenancemode.TimeStart<NOW(),"Yes","No") = "No"
            GROUP BY LocationID HAVING COUNT(*)>0 ORDER BY Computers.LastContact
            ) AS Locs
          WHERE LastContact < DATE_SUB(NOW(), INTERVAL 2 MINUTE)
          AND NumServers > 1
          )
        )    '
write-host ""
write-host ""
$ServersDown = Invoke-MySqlQuery -Connection $LtDb -Query $query
"Found " + $ServersDown.Rows.Count + " computers where LabTech agent needs a kick" | tee -Append $LogFile
foreach ($Server In $ServersDown) {
    If ($Server.ScGUID -ne "" -and $server.ScApiUrl -ne "" -and $server.Maint_Mode_Enabled -eq "No") {
### Add your API key to next line.  Require RMM+ extn for SC.
        $SCdata = @("YOUR_API_KEY_HERE", $Server.ScGUID) | ConvertTo-Json ;
        $SecsOnline = Invoke-RestMethod -Uri $Server.ScApiUrl -Method Post -Body $SCdata -ContentType 'application/json' -Credential $ScCreds
        If ($SecsOnline -gt 600) {
            # Machine online more than ten mins
            Write-Output ($Server.Computer_Name).ToString() "online in SC for $SecsOnline seconds"  | tee -Append $LogFile
            $JSON = '["All Machines",["' + $Server.ScGUID + '"],44,"' + $CmdToRun + '"]'
            $JSON | out-file -Append $LogFile
            try {
                $req = Invoke-RestMethod -Uri $ScApiUrl -Method Post -Body $JSON -ContentType 'application/json' -Credential $ScCreds
                write-output "Restarted LT agent on" ($Server.Computer_Name).ToString()  | tee -Append $LogFile
            } catch {
                Write-Output "Exception restarting LT agent on" ($Server.Computer_Name).ToString()  | tee -Append $LogFile
            }
        }
        ""  | tee -Append $LogFile
    }
}
"### END RUN ###"  | out-file -append $LogFile
""  | out-file  -Append $LogFile
""  | out-file  -Append $LogFile

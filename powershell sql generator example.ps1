#This should be 1 higher than the current SELECT MAX(GroupID) from mastergroups;
$GroupID = 2956 #Change these as needed for setting up your group names, they are referenced in the 3rd query.
$Day = 'Weekly Friday'
$pm = ('-','+')#Adjust your loops as needed as well. I happened to have a need for a +/- in my group names here
$pm | Foreach-Object {
For ($hour = 0; $hour -lt 24; $hour++) {
#First statement uses the direct parent of whatever group you are creating, second statement has all parents in the chain for the FIND_IN_SET
@"
INSERT INTO MasterGroups (ParentID,Parents,NAME,Depth,fullname,Children,GroupType,`GUID`) 
  (SELECT GroupID,CONVERT(CONCAT(Parents,GroupID,',') USING latin1),
  'New Group',
  (SELECT `Depth` + 1 FROM `MasterGroups` WHERE `GroupId`=2552),
  CONVERT(CONCAT(Fullname,'.New Group') USING latin1),',',GroupType,UUID() FROM MasterGroups WHERE GroupID=2552);UPDATE MasterGroups 
SET Children=CONCAT(Children,'$($GroupID),')  
WHERE FIND_IN_SET(GroupID,'2382,1179,2384,2552');UPDATE MasterGroups 
SET NAME='$($Day) $($hour) Day$($_)',
Permissions=0,Notes='',Template=0,GroupType=0,MaintenanceID=0,AutoJoinScript=0,MASTER=0,NetworkJoin=0,NetworkJoinOptions=0,ContactJoin=0,ContactJoinOptions=0,Priority=5,Control=0,ControlID=0,MaintWindowApplied=NOW(),LimitToParent=0 
WHERE GroupID=$($GroupID);UPDATE mastergroups mg SET mg.fullname=f_GroupFullName(mg.GroupID) 
WHERE FIND_IN_SET(mg.groupid,'$($GroupID)');
"@ | out-file -append -filepath ".\GeneratedSQL.txt";
$GroupID++;
}
}







#This should be 1 higher than the current SELECT MAX(GroupID) from mastergroups;
$GroupID = 3642 #Change these as needed for setting up your group names, they are referenced in the 3rd query.
$Parent_Group = 3304 #This is the direct parent group you want to create the groups in
$Week = "Create ticket - Weekly - SQL"
#$Day = 'End of Quarter'
#$pm = ('Every', 'First', 'Second', 'Third', 'Fourth', 'Last')#Adjust your loops as needed as well. I happened to have a need for a +/- in my group names here
$Day = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')#Adjust your loops as needed as well. I happened to have a need for a +/- in my group names here
$Day | Foreach-Object {
For ($hour = 0; $hour -lt 24; $hour+=2) {
    $hour2 = $hour+6
    if ($hour2 -gt 23){
        $hour2-=24
    }     
#First statement uses the direct parent of whatever group you are creating, second statement has all parents in the chain for the FIND_IN_SET
# i.e. this line WHERE FIND_IN_SET(GroupID,'1684,1681');UPDATE MasterGroups
@"
INSERT INTO MasterGroups (ParentID,Parents,NAME,Depth,fullname,Children,GroupType,`GUID`) 
  (SELECT GroupID,CONVERT(CONCAT(Parents,GroupID,',') USING latin1),
  'New Group',
  (SELECT `Depth` + 1 FROM `MasterGroups` WHERE `GroupId`=$($Parent_Group)),
  CONVERT(CONCAT(Fullname,'.New Group') USING latin1),',',GroupType,UUID() FROM MasterGroups WHERE GroupID=$($Parent_Group));UPDATE MasterGroups 
SET Children=CONCAT(Children,'$($GroupID),')  
WHERE FIND_IN_SET(GroupID,'3304,2466');UPDATE MasterGroups
SET NAME='$($Week) $($_) $($hour)-$($hour2)',
Permissions=0,Notes='',Template=0,GroupType=0,MaintenanceID=0,AutoJoinScript=0,MASTER=2,NetworkJoin=0,NetworkJoinOptions=0,ContactJoin=0,ContactJoinOptions=0,Priority=5,Control=0,ControlID=0,MaintWindowApplied=NOW(),LimitToParent=0 
WHERE GroupID=$($GroupID);UPDATE mastergroups mg SET mg.fullname=f_GroupFullName(mg.GroupID) 
WHERE FIND_IN_SET(mg.groupid,'$($GroupID)');
"@ | out-file -append -filepath ".\GeneratedSQLweeklyticket.txt"
$GroupID++}
}















INSERT INTO installsoftwarepolicies
SELECT NULL AS Id, `Name`, 5 AS UpdateMode, 7 AS `Day`, TRIM(RIGHT(SUBSTRING_INDEX(`Name`,' ',4),2)) AS StartTime, 
14 AS Duration, 1 AS CustomAction, 1 AS Dates, 1170 AS MonthlyOccurrence, 0 AS LastDay, 16 AS Occurrence, 1 AS CustomDays, 
IF(`Name` LIKE '%+',68,64) AS `Options`, 0 AS Uptime, 0 AS CVSS, 0 AS PromptInterval, 0 AS RebootDeadline, '' AS SoftwareUpdateMessage, 
0 AS IsThirdParty, '' AS BeforeScript, '' AS AfterScript, 0 AS DaysAfter, 0 AS ServiceBranch, -1 AS FeatureUpdatesDelay, -1 AS QualityUpdatesDelay
FROM mastergroups WHERE parentid = 2552;



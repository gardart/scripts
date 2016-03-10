$NewHomeDirectoryRoot = "C:\userdir"
$RoboCopy_Template = ".\RoboCopy_Template.txt"
$row=""
$Encoding = "ascii" 

$users_csv_file = ".\users.csv"
$users_csv_headers = "samaccountname"

$users_generated_csv_file = ".\users.generated.csv"
$users_generated_csv_headers = "employeeid,samaccountname,homepath_current,homepath_new"

# Generate csv file

$users_generated_csv_headers | out-file $users_generated_csv_file
import-csv $users_csv_file | 
foreach{$username=$_.samaccountname;
$User = get-aduser $username -properties *
$HomePath_New = $NewHomeDirectoryRoot + $User.SamAccountName
$row = $User.EmployeeID + "," + $User.SamAccountName + "," + $User.HomeDirectory + "," + $HomePath_New
write-host $row
$row | out-file -filepath $users_generated_csv_file -append
}

# Generate Robocopy script
$users_robocopy_script_file = ".\01-users_robocopy_script.bat.tmp"
Get-Content -Path $RoboCopy_Template -Encoding $Encoding |  Set-Content $users_robocopy_script_file -Encoding $Encoding
import-csv $users_csv_file | 
foreach{$username=$_.samaccountname;
$User = get-aduser $username -properties *
$HomePath_New = $NewHomeDirectoryRoot + $User.SamAccountName
$Robocopy_Command = "robocopy " + $User.HomeDirectory + " " + $HomePath_New + " %WHAT_TO_COPY% %OPTIONS% %EXCLUDE_DIRS% %EXCLUDE_FILES% %FAST_COPY%"
write-host $Robocopy_Command
$Robocopy_Command | out-file -Encoding $Encoding -filepath $users_robocopy_script_file -append
}

# Generate Disconnection script for users
$users_disconnect_script_file = ".\02-users_disconnect_script.bat.tmp"

import-csv $users_generated_csv_file | 
foreach{$employeeid=$_.employeeid;$username=$_.samaccountname;$homepath_current=$_.homepath_current;
$Command = "openfiles /disconnect /a " + $username
$Command | out-file -filepath $users_disconnect_script_file -append
}

# Generate User update new homepath script
$users_update_script_file = ".\03-users_update_script.ps1.tmp"
import-csv $users_generated_csv_file | 
foreach{$employeeid=$_.employeeid;$username=$_.samaccountname;$homepath_current=$_.homepath_current;$homepath_new=$_.homepath_new;
$UserUpdate_Command = "set-aduser " + $username + " -HomeDirectory " + $homepath_new
#write-host $UserUpdate_Command
$UserUpdate_Command | out-file -filepath $users_update_script_file -append
}

# Generate Reset Permissions script
$users_permission_reset_script_file = ".\04-users_permission_reset_script.bat.tmp"
import-csv $users_generated_csv_file | 
foreach{$employeeid=$_.employeeid;$username=$_.samaccountname;$homepath_current=$_.homepath_current;
$Permission_Reset_Command = "takeown /f " + $homepath_current + " /r /a /d y"
$Permission_Reset_Command | out-file -filepath $users_permission_reset_script_file -append
$Permission_Reset_Command = "icacls " + $homepath_current + " /reset /T"
$Permission_Reset_Command | out-file -filepath $users_permission_reset_script_file -append
}

# Generate Rename old homedirectory script
$users_rename_script_file = ".\05-users_rename_script.bat.tmp"
import-csv $users_generated_csv_file | 
foreach{$employeeid=$_.employeeid;$username=$_.samaccountname;$homepath_current=$_.homepath_current;
$Command = "ren " + $homepath_current + " " + $username + ".old"
$Command | out-file -filepath $users_rename_script_file -append
}

# Generate Remove Old Homedirectory script
$users_remove_script_file = ".\06-users_remove_script.bat.tmp"
write ":: Generated script to remove old homedirectories" | out-file -filepath $users_remove_script_file
import-csv $users_generated_csv_file | 
foreach{$employeeid=$_.employeeid;$username=$_.samaccountname;$homepath_current=$_.homepath_current;
$Remove_Command = "rmdir /S /Q " + $homepath_current + ".old"
$Remove_Command | out-file -filepath $users_remove_script_file -append
}

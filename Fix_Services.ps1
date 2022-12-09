<#

.SYNOPSIS
    Updates Services file with given list of ports and protocols.

.DESCRIPTION
    For use as rmediation script via "Proactive Remediation" in Microsoft Intune.
    Script to update Services file using Proactive Remediation.
    Will verify all port numbers and protocol combination in Services file, 
       if there is a match it will update it with information on the entries list,
       if not it will add it.


.NOTES
    SUGGESTION: Do not modify Servides file.
    Services file located in c:\windows\system32\drivers\etc is used to tell services written by Microsoft what port to use, 
    as well as files that wish to use Windows APIs and/or that file to turn a service name into a port.
    These service names are defined by the IETF(Internet Engineering task force).
  

#>

#region Initialize

$Error.Clear()
$t = Get-Date
#New lines, easier to read Agentexecutor Log file.
Write-Host "`n`n"
#Log start time.
Write-Output "Services file update start time: $t"

#endregion

#region Functions
function Set-ServicesEntries([hashtable] $entries) {
    $ServicesFile = "$env:windir\System32\drivers\etc\services"   #Path to services file
    $portprotocol = ""    #port number, protocol combination that we'll add or change in the host file
    $servicename = ""  #Service name that we'll associate to port protocol combination
    $newLines = @()

    $c = Get-Content -Path $ServicesFile
    foreach ($line in $c) {
        $bits = [regex]::Split($line, "\s+")
        
        #If the line is not a comment and has more 2 or more words check the port, protocol combination. 
        #   If it's a port from the entries list replace it / update it. 
        if (($bits[0] -ne "#") -and ($bits.Count -ge 2)) {
            $match = $null
            foreach ($entry in $entries.GetEnumerator()) {          
                #If Port/Protocol is in the entries list, update it.
                if ($bits[1] -eq $entry.Key) {
                    
                    #Found a Port/Protocol match in current line, updating it to match Port/Protocol and Service name from entries list.
                    Write-Host "Updating entry for Port/Protocol combintaion $($entry.Key)."
                    $portprotocol = $entry.Key
                    $servicename = $entry.Value + "`t"
                    
                    $newLines += $servicename + $portprotocol
                    $match = $entry.Key

                    break
                    
                }
            }
            if ($null -eq $match) {
                #Line didn't match one of the Port, Protocol combination in our entries list, so line stays as is, no changes
                $newLines += $line
            }
            else {
                #We did find a match and updated the entry, let's remove that Port, Protocol combintaion from the entries list.
                $entries.Remove($match)
            }

        }
        else {
            #Line stays the same. Don't write the blank lines.
            if ($line -ne "") {
                $newLines += $line
            }

        }

    }

    #Add all remaing Port, Protocol and corresponding Service Name from the entries list to Services file.
    foreach($entry in $entries.GetEnumerator()) {
        $portprotocol = $entry.Key
        $servicename = ""
        Write-Host "Adding entry for Port, Protocol: $portprotocol"
        foreach ($value in $entry.Value) {
            if ($value -ne "") {
                $servicename += $value + "`t"
            }

        } 
    
        $newLines += ($servicename + $portprotocol)

    }

    if ($newLines[$newLines.Count - 1] -ne "") {

        #Making sure the last line is a blank line
        $newLines += "`n"

    }


    #Write Services file with changes made.
    Write-Host "Saving $ServicesFile file."
    Clear-Content $ServicesFile
    foreach ($line in $newLines) {
        $line | Out-File -encoding ASCII -append $ServicesFile
    }

}

#endregion

#region Main

#Entries in the format "Port/Protocol" = "Service Name". Not compatible for other columns such as Alias and comments.
$entries = @{
    '0001/tcp' = "service01"
    '0002/tcp' = "service02"
};

Set-ServicesEntries($entries)

#Log finish time.
$t = Get-Date
Write-Output "Services file update finished at: $t"
#New lines, easier to read Agentexecutor Log file.
Write-Host "`n`n"

#endregion
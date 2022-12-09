<#

.SYNOPSIS
    Looks for a list of ports and protocols in Services file.

.DESCRIPTION
    For use as Detection script via "Proactive Remediation" in Microsoft Intune.
    Script to detect if all Port, Protocol in entry list already exist in Services file.
    
    
.NOTES
    SUGGESTION: Do not modify Servides file.
    Services file located in c:\windows\system32\drivers\etc is used to tell services written by Microsoft what port to use, 
    as well as files that wish to use Windows APIs and/or that file to turn a service name into a port.
    These service names are defined by the IETF(Internet Engineering task force).
    
#>

#region Initialize

$Error.Clear()
#New lines, easier to read Agentexecutor Log file.
Write-Host "`n`n"


#endregion

#region Functions
function Search-PortProtocolEntries([hashtable] $entries) {
    $servicesFile = "$env:windir\System32\drivers\etc\services"   #Path to hosts file

    $c = Get-Content -Path $servicesFile
    foreach ($line in $c) {
        $bits = [regex]::Split($line, "\s+")
        
        #   If it's an Port, Protocol combination from our entries list then you can erease that entry. 
        #   Empty entries list at end of lines in services file = Exit 0, no issues
        
        #If the line is not a comment and has more 2 or more words check the Port, Protocol combintaion. 
        if (($bits[0] -ne "#") -and ($bits.Count -ge 2)) {
            $match = $null
            foreach ($entry in $entries.GetEnumerator()) {          
                if ($bits[1] -eq $entry.Key) {
                    
                    #Found a Protocol match in current line, then mark match. We'll remove it from entries list later.
                    Write-Host "Found match for Port/Protocol: $($entry.Key)."
                    $match = $entry.Key
                    break
                    
                }
            }
            if ($null -eq $match) {
                #Line didn't match one of the Port, Protocol combination in our entries list, nothing to do, this is the detection script.
            }
            else {
                #If we found a match, then this Port, Protocol combintaion can be removed from the entries list.
                $entries.Remove($match)
            }
        }
    }


    #Is there any Port/Protocol from the entries list missing in the hosts file? 
    #   If there is then fail, Exit 1.
    #   If not, then success, no issues found here, move on.
    if ($entries.Count -ge 1) {

        Write-Warning "1 or more Port/Protocol from entries list is missing. `n`n"
        Exit 1

    }

}

#endregion

#region Main

$entries = @{
    '0001/tcp' = "service01"
    '0002/tcp' = "service02"
};

Search-PortProtocolEntries($entries)

#If we've made it till here, then we're clear, no errors.
Write-Host "All Port/Protocol from entries list were found. `n`n"

Exit 0

#endregion
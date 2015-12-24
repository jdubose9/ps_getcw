$Global:CWInfo = New-Object PSObject -Property @{
Company = 'Company'
User = 'user'
Password = 'password'
}
[String]$CWServerRoot = "https://your.connectwiseurl.com/"
function Get-CWKeys
{

    [string]$BaseUri     = "$CWServerRoot" + "v4_6_release/apis/3.0/system/members/jdubose/tokens"
    [string]$Accept      = "application/vnd.connectwise.com+json; version=v2015_3"
    [string]$ContentType = "application/json"
    [string]$Authstring  = $CWInfo.company + '+' + $CWInfo.user + ':' + $CWInfo.password

    #Convert the user and pass (aka public and private key) to base64 encoding
    $encodedAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));

    #Create Header
    $header = [Hashtable] @{
        Authorization = ("Basic {0}" -f $encodedAuth)
        Accept        = $Accept
        Type          = "application/json"
        'x-cw-usertype' = "integrator" 
    };

    $body   = "{`"memberIdentifier`":`"jdubose`"}"
    
    #execute the the request
    $response = Invoke-RestMethod -Uri $Baseuri -Method Post -Headers $header -Body $body -ContentType $contentType;
    
    #return the results
    return $response;
}
Function Get-CWBoardStats
{
		$CWCredentials = Get-CWKeys
        [string]$BaseUri     = "$CWServerRoot" + "v4_6_Release/apis/3.0/service/tickets/count"
        [string]$Accept      = "application/vnd.connectwise.com+json; version=v2015_3"
        [string]$ContentType = "application/json"
        [string]$Authstring  = $CWInfo.company + '+' + $CWInfo.user + ':' + $CWInfo.password
        $encodedAuth         = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));

        $Headers=@{
        'X-cw-overridessl' = "True"
        "Authorization"="Basic $encodedAuth"
        }

             
        $JSONResponse = Invoke-RestMethod -URI $BaseURI -Headers $Headers -ContentType $ContentType -Body $Body -Method Get
		$json = "{
			""username"": ""CWBoardStats"",
            ""text"": ""test text""
          }" 
       
        If($JSONResponse)
        {
			#Write-host $Authstring
			#ConvertTo-Json $JSONResponse
			#Invoke-RestMethod -URI 'https://alert.victorops.com/integrations/generic/20131114/alert/c3f770bc-034d-48f7-b709-0448e2c8580d/$routing_key' -Method Post -ContentType 'application/json' -Body "{ ""message_type"": ""CRITICAL""}"
			#Write-host $JSONResponse
            Return $JSONResponse
        }

        Else
        {
            Return $False
        }
}
Function Get-CWNewTicket
{
		$CWCredentials = Get-CWKeys
		$CWTicketCount = Get-CWBoardStats
		$CWTicketCountClean = $CWTicketCount -replace '\D+(\d+)\D+','$1'
		$CWTickets = 6067 + $CWTicketCountClean
        [string]$BaseUri     = "$CWServerRoot" + "v4_6_Release/apis/3.0/service/tickets/$CWTickets"
        [string]$Accept      = "application/vnd.connectwise.com+json; version=v2015_3"
        [string]$ContentType = "application/json"
        [string]$Authstring  = $CWInfo.company + '+' + $CWInfo.user + ':' + $CWInfo.password
        $encodedAuth         = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($Authstring)));

        $Headers=@{
        'X-cw-overridessl' = "True"
        "Authorization"="Basic $encodedAuth"
        }

             
        $JSONResponse = Invoke-RestMethod -URI $BaseURI -Headers $Headers -ContentType $ContentType -Body $Body -Method Get

       
        If($JSONResponse)
        {
			#This section takes the values from JSONResponse and writes them/converts them to clean variables. 
            $TicketNumber = $JSONResponse.id
			$TicketSummary = $JSONResponse.summary
			$TicketContact = $JSONResponse.contactEmailAddress
			$TicketStatusDirty = $JSONResponse.status -replace '\D+(\d+)\D+','$1'
			If (Get-Content C:\users\glch\Documents\cwtickets.txt | Select-String -Pattern $TicketNumber)
			{
				Return $False
			}
			Else
			{
				If($TicketStatusDirty -eq 216 -Or $TicketStatusDirty -eq 16)
				{
					$TicketStatus = "New"
					Invoke-RestMethod -URI 'https://victoropsURL.com/randomstuff' -Method Post -ContentType 'application/json' -Body "{ ""message_type"": ""CRITICAL"", ""entity_id"": ""$TicketStatus"", ""state_message"": ""$TicketSummary"", ""entity_display_name"": ""$TicketContact""}"
				}
				Else
				{
					Return $False
				}
				$TicketNumber | out-file -filepath C:\users\user\cwtickets.txt -append
			}

        }

        Else
        {
            Return $False
        }
}


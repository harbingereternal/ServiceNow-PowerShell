# TODO: Create Parameters
Param(
    [Parameter(Mandatory=$true)]
    [Alias("URI")]
    #[ValidateScript({ Test-Connection $_ -Quiet })]
    [string] $ServiceNowURI,

    [Parameter(Mandatory=$true)]
    [ValidateSet("incident","sys_user","sys_user_group")]
    [string] $ServiceNowTable,

    [Parameter(Mandatory=$false)]
    [Alias("Filter")]
    [hashtable] $SearchFilter = @{}
)

function WriteXmlToScreen ([xml]$xml)
{
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    Write-Output $StringWriter.ToString();
}

# TODO: Create function that returns a user's name from the sys_user table based on the sys_id


# CUSTOM XML CREATION =============================================================
#
#    - We need to pipe .AppendChild() to Out-Null to prevent 
#         extra output in the host window.
#
#    - I have not been able to make this code work in a function.
#         the object it returns does not cast back to XML correctly.
#
# =================================================================================

# Create XML object
[xml]$xmlDoc = New-Object System.Xml.XmlDocument

# Add XML declaration and add it to the XML document
$declaration = $xmlDoc.CreateXmlDeclaration("1.0","ISO-8859-1",$null)
$xmlDoc.AppendChild($declaration) | Out-Null

# Create ROOT node and add attributes
$root = $xmlDoc.CreateNode("element","soapenv:Envelope",$null)
$root.SetAttribute("xmlns:soapenv","`"http://schemas.xmlsoap.org/soap/envelope/`"")

If ($ServiceNowTable -eq "incident") {
    $root.SetAttribute("xmlns:inc","`"http://www.service-now.com/incident`"")
}
ElseIf ($ServiceNowTable -eq "sys_user") {
    $root.SetAttribute("xmlns:usr","`"http://www.service-now.com/sys_user`"")
}
ElseIf ($ServiceNowTable -eq "sys_user_group") {
    $root.SetAttribute("xmlns:grp","`"http://www.service-now.com/sys_user_group`"")
}

# Create Header node, add it to the root
$headerNode = $xmlDoc.CreateNode("element","soapenv:Header",$null)
$root.AppendChild($headerNode) | Out-Null

# Create Body Node
$bodyNode = $xmlDoc.CreateNode("element","soapenv:Body",$null)

# Create the "action" node, what we're doing
If ($ServiceNowTable -eq "incident") {
    $actionNode = $xmlDoc.CreateNode("element","inc:getRecords",$null)
}
ElseIf ($ServiceNowTable -eq "sys_user") {
    $actionNode = $xmlDoc.CreateNode("element","usr:getRecords",$null)
}
ElseIf ($ServiceNowTable -eq "sys_user_group") {
    $actionNode = $xmlDoc.CreateNode("element","grp:getRecords",$null)
}

# Create elements, assign them a value, and add them to the parent
Foreach ($key in $SearchFilter.Keys) {
           
    $element = '{0}' -f $key
    $elemValue = '{0}' -f $SearchFilter[$key]
            
    $numElement = $xmlDoc.CreateElement($element)
    $numElement.InnerText = $elemValue

    $actionNode.AppendChild($numElement) | Out-Null
}

# Add action node to the body node
$bodyNode.AppendChild($actionNode) | Out-Null

# Add the body node to ROOT
$root.AppendChild($bodyNode) | Out-Null

# Add the ROOT node to the XML document
$xmlDoc.AppendChild($root) | Out-Null

####### DEBUG ONLY #######
#WriteXmlToScreen $xmlDoc
#Write-Host ""
##########################

# END CUSTOM XML ==================================================================

# Build full URI
$URI = "https://" + $ServiceNowURI + "/" + $ServiceNowTable + ".do?SOAP"

# Open credential prompt
$cred = Get-Credential

# Send request to ServiceNow and store the response
$post = Invoke-WebRequest -Uri $URI -Credential $cred -Method Post -Body $xmlDoc -ContentType "text/xml"

# Convert the response to XML
$xmlPOST = [xml]$post.Content

# Parse the response for the data we want and put each result in a custom object
$collReturn = @()

If ($ServiceNowTable -eq "incident") {

    For ($i=0; $i -lt $xmlPOST.Envelope.Body.getRecordsResponse.ChildNodes.Count;$i++) {
        $objReturn = [pscustomobject] @{
            number = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].number
            category = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].category
            active = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].active
            opened_at = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].opened_at
            resolved_by = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].resolved_by
            state = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].state
        }

        $collReturn += $objReturn
    }
}
ElseIf ($ServiceNowTable -eq "sys_user") {
    For ($i=0; $i -lt $xmlPOST.Envelope.Body.getRecordsResponse.ChildNodes.Count;$i++) {
        $objReturn = [pscustomobject] @{
            user_name = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].user_name
            last_name = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].last_name
            first_name = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].first_name
            email = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].email
            active = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].active            
        }

        $collReturn += $objReturn
    }
}
ElseIf ($ServiceNowTable -eq "sys_user_group") {
    For ($i=0; $i -lt $xmlPOST.Envelope.Body.getRecordsResponse.ChildNodes.Count;$i++) {
        $objReturn = [pscustomobject] @{
            name = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].name
            type = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].type
            sys_id = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].sys_id          
        }

        $collReturn += $objReturn
    }
}


$collReturn | Format-Table

$collReturn = @()
$xmlDoc = $null
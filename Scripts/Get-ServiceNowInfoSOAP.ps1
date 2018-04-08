# TODO: Create function that returns a user's name from the sys_user table based on the sys_id

Param(
    [Parameter(Mandatory=$true)]
    [Alias("URI")]
    #[ValidateScript({ Test-Connection $_ -Quiet })]
    [string] $ServiceNowURI,

    # Limit the choices to known existing and tested tables
    [Parameter(Mandatory=$true)]
    [ValidateSet("incident","sys_user","sys_user_group")]
    [string] $ServiceNowTable,

    [Parameter(Mandatory=$false)]
    [Alias("Filter")]
    [hashtable] $SearchFilter = @{}
)

function Write-XmlToScreen ([xml]$xml)
{
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    Write-Output $StringWriter.ToString();
}

# CUSTOM XML CREATION =============================================================
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
Write-XmlToScreen $xmlDoc
Write-Host ""
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

####### DEBUG ONLY #######
#Write-XmlToScreen $xmlPOST
#Write-Host ""
##########################

# Parse the response for the data we want and put each result in a custom object
$collReturn = @()

# Iterate through all 
For ($i=0; $i -lt $xmlPOST.Envelope.Body.getRecordsResponse.ChildNodes.Count;$i++) {
    # Create an empty hashtable
    $htOutput = [ordered]@{}
    
    ####### DEBUG ONLY #######    
    #$debugText = $xmlPOST.Envelope.Body.getRecordsResponse.ChildNodes.Count.ToString() + " nodes in getRecordsResult"
    #Write-Host $debugText
    #
    #$debugText = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].ChildNodes.Count.ToString() + " nodes in getRecordsResult"
    #Write-Host $debugText
    ##########################

    # Add all key/value combinations to the hashtable
    For ($j=0; $j -lt $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].ChildNodes.Count;$j++) {
        
        #$output = $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].ChildNodes[$j].Name + " - " + $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].ChildNodes[$j].InnerText
        #Write-Host $output -ForegroundColor Yellow
                
        $htOutput.Add(("`"" + $xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].ChildNodes[$j].Name + "`"") ,$xmlPOST.Envelope.Body.getRecordsResponse.getRecordsResult[$i].ChildNodes[$j].InnerText)
    }

    # Cast the hashtable to a pscustomobject
    $objReturn = [pscustomobject]$htOutput

    # Add to the object collection
    $collReturn += $objReturn

    # Clear the variables
    $htOutput = $null
    $objReturn = $null
}

# Display as a GridView for TESTING ONLY
$collReturn | Out-GridView

$collReturn = @()
$xmlDoc = $null
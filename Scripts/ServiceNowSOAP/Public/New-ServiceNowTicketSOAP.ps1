﻿<#
.Synopsis
Creates a ServiceNow ticket with the given information. Currently only supports incidents

.Description

.Parameter ServiceNowURI
The URL for the ServiceNow instance to pull data from. Does not accept protocol identifiers (http://, https://)

.Parameter ServiceNowTable
The table in which the data required resides.

.Parameter TicketInfo
A hashtable that acts as a filter for the data requested.

.Example
  # Create a ticket
  New-ServiceNowTicketSOAP -ServiceNowURI "test.service-now.com" -ServiceNowTable incident -TicketInfo @{impact='4';urgency='3';assignment_group='Incident Management';short_description='Some text';description='Some more text'}

#>

Function New-ServiceNowTicketSOAP {
    Param(
        [Parameter(Mandatory=$true)]
        [Alias("URI")]
        #[ValidateScript({ Test-Connection $_ -Quiet })]
        [string] $ServiceNowURI,

        [Parameter(Mandatory=$true)]
        [ValidateSet("incident","sc_task")]
        [string] $ServiceNowTable,

        [Parameter(Mandatory=$false)]
        [Alias("Filter")]
        [hashtable] $TicketInfo = @{}
    )

    # Displays the completed XML file. *DEBUG USE ONLY*
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
    $root = $xmlDoc.CreateNode("element","SOAP-ENV:Envelope",$null)

    # Build the action attribute
    $root.SetAttribute("xmlns:act","`"http://www.service-now.com/$ServiceNowTable`"")

    $root.SetAttribute("xmlns:SOAP-ENV","`"http://schemas.xmlsoap.org/soap/envelope/`"")
    $root.SetAttribute("xmlns:SOAP-ENC","`"http://schemas.xmlsoap.org/soap/encoding/`"")
    $root.SetAttribute("xmlns:m","`"http://www.service-now.com`"")
    $root.SetAttribute("xmlns:xsi","`"http://www.w3.org/2001/XMLSchema-instance`"")
    $root.SetAttribute("xmlns:xsd","`"http://www.w3.org/2001/XMLSchema`"")
    $root.SetAttribute("SOAP-ENV:encodingStyle","`"http://schemas.xmlsoap.org/soap/encoding/`"")

    # Create Body Node
    $bodyNode = $xmlDoc.CreateNode("element","SOAP-ENV:Body",$null)

    # Create the "action" node, what we're doing
    $actionNode = $xmlDoc.CreateNode("element","insert",$null)
    $actionNode.SetAttribute("xmlns","`"http://www.service-now.com`"")

    # Iterate through hashtable to create elements, assign them a value, and add them to the parent
    Foreach ($key in $TicketInfo.Keys) {
           
        $element = '{0}' -f $key
        $elemValue = '{0}' -f $TicketInfo[$key]
            
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

    # Parse the post for the data we want and put each result in a custom object
    $objReturn = [pscustomobject] @{
        sys_id = $xmlPOST.Envelope.Body.insertResponse.sys_id
        number = $xmlPOST.Envelope.Body.insertResponse.number
    }

    # Display success or failure based on response
    If (($objReturn.number -ne $null) -and ($objReturn.number -ne $null)) {
        $output = "Successfully created " + $objReturn.number + "!"
        Write-Host $output -ForegroundColor Green
    }
    Else {
        $output = "Failed to create ticket!"
        Write-Host $output -ForegroundColor Red
    }

    $objReturn = $null
    $xmlDoc = $null
}
# ServiceNow-PowerShell
Powershell scripts to leverage ServiceNow's SOAP web service. 

Developed for the Kingston release.

[ServiceNow Kingston SOAP Web Service Documentation](https://docs.servicenow.com/bundle/kingston-application-development/page/integrate/inbound-soap/concept/c_SOAPWebService.html)

**IMPORTANT:** Neither this module nor its creator are in any way affiliated with ServiceNow.

## Current goals

### Get-ServiceNowInfoSOAP
* DONE! ~~Find a way to access the full list of values in 'getResponse' for each table dynamically to ease build of final "response objects" and eliminate need to make If\Else statements for each table that data is pulled from.~~
* Implement Encoded Queries [ServiceNow Kingston Filter Operator Documentation](https://docs.servicenow.com/bundle/kingston-platform-user-interface/page/use/common-ui-elements/reference/r_OpAvailableFiltersQueries.html)

### New-ServiceNowTicketSOAP (formerly Create-ServiceNowTicket)
* Expand from Incident to cover more types of "tickets"

### All scripts
* Get Custom XML builder into a function to allow more flexibility

## Usage

### Get-ServiceNowInfoSOAP

#### Example: Get all records in the 'incident' table
```PowerShell
Import-Module ServiceNowSOAP
Get-ServiceNowInfoSOAP -ServiceNowURI "testinstance.service-now.com" -ServiceNowTable incident
```

#### Example: Get all records in the 'incident' table that are active
```PowerShell
Import-Module ServiceNowSOAP
Get-ServiceNowInfoSOAP -ServiceNowURI "testinstance.service-now.com" -ServiceNowTable incident -SearchFilter @{active="1"}
```

#### Example: Get all records in the 'incident' table that are active and the impact is set to 3
```PowerShell
Import-Module ServiceNowSOAP
Get-ServiceNowInfoSOAP -ServiceNowURI "testinstance.service-now.com" -ServiceNowTable incident -SearchFilter @{active="1";impact="3"}
```

### New-ServiceNowTicketSOAP (formerly Create-ServiceNowTicketSOAP)

#### Example: Create a new incident with some data
```PowerShell
Import-Module ServiceNowSOAP
New-ServiceNowTicketSOAP -ServiceNowURI "test.service-now.com" -ServiceNowTable incident -TicketInfo @{impact='4';urgency='3';assignment_group='Incident Management';short_description='Some text';description='Some more text'}
```
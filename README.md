# ServiceNow-PowerShell
Powershell scripts to leverage ServiceNow's SOAP web service. 

Developed for the Kingston release.

* [ServiceNow Kingston SOAP Web Service Documentation](https://docs.servicenow.com/bundle/kingston-application-development/page/integrate/inbound-soap/concept/c_SOAPWebService.html)
* [ServiceNow Kingston Filter Operator Documentation](https://docs.servicenow.com/bundle/kingston-platform-user-interface/page/use/common-ui-elements/reference/r_OpAvailableFiltersQueries.html)

**IMPORTANT:** Neither this module nor its creator are in any way affiliated with ServiceNow.
## Tables Currently Supported

### Get-ServiceNowInfoSOAP
* incident
* sc_task
* sys_user
* sys_user_group

### New-ServiceNowTicketSOAP (formerly Create-ServiceNowTicket)
* incident
* sc_task

## Current Goals

### Get-ServiceNowInfoSOAP
* Fix issue with FOR loop that seems to be preventing display of data from tables that have a single record.

### New-ServiceNowTicketSOAP (formerly Create-ServiceNowTicket)
* Expand from INCIDENT and SCTASK to cover more types of "tickets".

### All scripts
* Get Custom XML builder into a function or independent script(s) to allow more flexibility.
* Create script to return the sys_id or user_id of a user by lastname and firstname, or employeenumber.
* Create script to update tickets.

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
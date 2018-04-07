# ServiceNow-PowerShell
Powershell scripts to leverage ServiceNow's SOAP web service. Developed for the Kingston release.
[ServiceNow Kingston SOAP Web Service Documentation](https://docs.servicenow.com/bundle/kingston-application-development/page/integrate/inbound-soap/concept/c_SOAPWebService.html)

## Current goals:

### Get-ServiceNowInfo
* Find a way to access the full list of values in 'getResponse' for each table dynamically to ease build of final "response objects" and eliminate need to make If\Else statements for each table that data is pulled from.

### Create-ServiceNowTicket
* Expand from Incident to cover more types of "tickets"

### All scripts
* Get Custom XML builder into a function to allow more flexibility

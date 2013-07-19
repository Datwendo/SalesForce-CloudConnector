SalesForces-Connector
=====================

Apex Class to call Datwendo Cloud Connector.
Datwendo 7/2013. CS.

This code is running if implemented as explained in this document, it is provided under the same Open Source license 
as all Datwendo code concerning client interfaces, feel free to adapt it to your needs.

This Apex class is built to be used from an 'after Create trigger'.
You simply provide the name of the field containing the unique Index and it will be automatically filled after each new create of an entity.

Suppose you want to fill the accountNumber with values shared with your ERP.
All you have to do is include the Connector class and create a trigger as this one


trigger SetAccountNumber on Account (after insert) {
Account[] accs= Trigger.new;
System.Debug('Begin SetAccountNumber');
Connector.ReadNextIndex(accs[0].ID,'AccountNumber',Publisher_Id,Coonector_Id,Secret_Key, isFast,200);
System.Debug('End SetAccountNumber');
}

Replace:

Publisher_Id : by zero or the publisher Id for your salesforce CRM if you have the publish/sunscribe option,

Connector_Id : by the Counter number which has been provided by Datwendo for a Test or Production Connector,

Secret_Key :  by the string you have chosen to secure your connector (or automatically set if in test mode)n

IsFast:  by 'true' if you select a FAst Connector or 'false' for secure connector


Don't forget to adapt the fieldname to the field you want to use for the new value.

Beware that due to Salesforces constraints in triggers, the call out are not running in Test mode.

Last but not least, the class is targeting http://datwendosvc.cloudapp.net which is our demo site, for 
production ennvironnements you will have to replace this url by the url produced by Datwendo.

IMPORTANT: Go in the security settings of your Salesforces organisation and install the Datwendo Service Url as an authorised url.


CS
7/2013

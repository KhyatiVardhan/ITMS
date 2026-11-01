
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Jira_Named_Credential/rest/api/3/project/ITS');
req.setMethod('GET');
req.setHeader('Accept', 'application/json');

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('HTTP Status: ' + res.getStatusCode());
System.debug('Response: ' + res.getBody());

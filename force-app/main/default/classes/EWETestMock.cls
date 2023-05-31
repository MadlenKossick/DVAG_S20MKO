/**
* @author Cloud Consulting Group
* @date 2022
*
* @group Mock
*
* @description EWE Service Mock for testing purposes
*/

@isTest
public class EWETestMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(201);
        return res;
    }
}
@isTest
global class AnimalLocatorMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        
        // Create mock HTTP response
        HttpResponse response = new HttpResponse();
        
        // Set response headers
        response.setHeader('Content-Type', 'application/json');
        
        // Set successful status code
        response.setStatusCode(200);
        
        // Set response body - JSON matching API format
        response.setBody(
            '{"animal":{"id":1,"name":"chicken","eats":"chicken feed","says":"cluck cluck"}}'
        );
        
        return response;
    }
}
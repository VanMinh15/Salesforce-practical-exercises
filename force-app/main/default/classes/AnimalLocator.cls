public with sharing class AnimalLocator {
    public static String getAnimalNameById(Integer AnimalId){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://th-apex-http-callout.herokuapp.com/animals/ ' + AnimalId);
        request.setMethod('GET');

        HttpResponse response = http.send(request);
        
        String animalName = null;
        
        if(response.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> animal = (Map<String, Object>) result.get('animal'); 
            animalName = (String) animal.get('name');
        }
        return animalName;
    }
}
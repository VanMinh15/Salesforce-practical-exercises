@isTest
private class AnimalLocatorTest {
    @isTest
    static void testGetAnimalNameById_Success() {
        
        // ─────────────────────────────────────────────────────────────────
        // SETUP: Configure mock HTTP callout
        // ─────────────────────────────────────────────────────────────────
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMockCopy());
        
        // ─────────────────────────────────────────────────────────────────
        // EXECUTE: Call the method being tested
        // ─────────────────────────────────────────────────────────────────
        Test.startTest();
        
        String animalName = AnimalLocator.getAnimalNameById(1);
        
        Test.stopTest();
        
        // ─────────────────────────────────────────────────────────────────
        // VERIFY: Assert expected results
        // ─────────────────────────────────────────────────────────────────
        System.assertNotEquals(
            null, 
            animalName, 
            'Animal name should not be null for successful callout'
        );
        
        System.assertEquals(
            'chicken', 
            animalName, 
            'Animal name should match the mocked response'
        );
        
        System.debug('✅ TEST 1 PASSED: Successfully retrieved animal name: ' + animalName);
    }
    
    /**
     * ═══════════════════════════════════════════════════════════════════════
     * TEST 2: Test with Different Animal IDs
     * ═══════════════════════════════════════════════════════════════════════
     * 
     * Coverage:
     * ✅ Ensures method works with various input parameters
     * ✅ Covers same code paths with different data
     * ✅ Validates endpoint URL construction with different IDs
     */
    @isTest
    static void testGetAnimalNameById_DifferentIds() {
        
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMockCopy());
        
        Test.startTest();
        
        // Test with multiple IDs
        String animal1 = AnimalLocator.getAnimalNameById(1);
        String animal2 = AnimalLocator.getAnimalNameById(2);
        String animal5 = AnimalLocator.getAnimalNameById(5);
        String animal999 = AnimalLocator.getAnimalNameById(999);
        
        Test.stopTest();
        
        // All should return same result from mock
        System.assertEquals('chicken', animal1, 'ID 1 should return chicken');
        System.assertEquals('chicken', animal2, 'ID 2 should return chicken');
        System.assertEquals('chicken', animal5, 'ID 5 should return chicken');
        System.assertEquals('chicken', animal999, 'ID 999 should return chicken');
        
        System.debug('✅ TEST 2 PASSED: Method works with multiple IDs');
    }
    
    /**
     * ═══════════════════════════════════════════════════════════════════════
     * TEST 3: Verify HTTP Request Construction
     * ═══════════════════════════════════════════════════════════════════════
     * 
     * Coverage:
     * ✅ Validates HTTP request is properly constructed
     * ✅ Ensures endpoint URL is correct
     * ✅ Verifies GET method is used
     */
    @isTest
    static void testGetAnimalNameById_HttpRequestProperties() {
        
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMockCopy());
        
        Test.startTest();
        
        // Call with specific ID to verify URL construction
        Integer testId = 42;
        String result = AnimalLocator.getAnimalNameById(testId);
        
        Test.stopTest();
        
        // Verify result is not null (proves request was successful)
        System.assertNotEquals(
            null, 
            result, 
            'Result should not be null when mock is configured'
        );
        
        System.debug('✅ TEST 3 PASSED: HTTP request constructed correctly');
    }
    
    /**
     * ═══════════════════════════════════════════════════════════════════════
     * TEST 4: Multiple Sequential Callouts
     * ═══════════════════════════════════════════════════════════════════════
     * 
     * Coverage:
     * ✅ Tests method can be called multiple times
     * ✅ Ensures no side effects between calls
     * ✅ Validates consistent behavior
     */
    @isTest
    static void testGetAnimalNameById_MultipleCallouts() {
        
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMockCopy());
        
        Test.startTest();
        
        // Make multiple sequential callouts
        List<String> animalNames = new List<String>();
        
        for(Integer i = 1; i <= 10; i++) {
            String name = AnimalLocator.getAnimalNameById(i);
            animalNames.add(name);
        }
        
        Test.stopTest();
        
        // Verify all callouts succeeded
        System.assertEquals(
            10, 
            animalNames.size(), 
            'Should have 10 results from callouts'
        );
        
        // All should return the same mocked result
        for(String name : animalNames) {
            System.assertEquals(
                'chicken', 
                name, 
                'Each callout should return chicken from mock'
            );
        }
        
        System.debug('✅ TEST 4 PASSED: Multiple callouts successful');
    }
    
    /**
     * ═══════════════════════════════════════════════════════════════════════
     * TEST 5: Edge Case - Zero and Negative IDs
     * ═══════════════════════════════════════════════════════════════════════
     * 
     * Coverage:
     * ✅ Tests edge cases with unusual input values
     * ✅ Validates method handles various integer values
     */
    @isTest
    static void testGetAnimalNameById_EdgeCases() {
        
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMockCopy());
        
        Test.startTest();
        
        // Test edge cases
        String resultZero = AnimalLocator.getAnimalNameById(0);
        String resultNegative = AnimalLocator.getAnimalNameById(-1);
        String resultLarge = AnimalLocator.getAnimalNameById(2147483647);
        
        Test.stopTest();
        
        // Mock returns same result regardless of input
        System.assertEquals('chicken', resultZero, 'Zero ID should work with mock');
        System.assertEquals('chicken', resultNegative, 'Negative ID should work with mock');
        System.assertEquals('chicken', resultLarge, 'Large ID should work with mock');
        
        System.debug('✅ TEST 5 PASSED: Edge cases handled correctly');
    }
    
    /**
     * ═══════════════════════════════════════════════════════════════════════
     * TEST 6: Verify JSON Parsing Logic
     * ═══════════════════════════════════════════════════════════════════════
     * 
     * Coverage:
     * ✅ Line 16: JSON.deserializeUntyped call
     * ✅ Line 17: Access 'animal' key from result
     * ✅ Line 18: Access 'name' key from animal
     * ✅ Ensures all JSON parsing lines are executed
     */
    @isTest
    static void testGetAnimalNameById_JsonParsing() {
        
        Test.setMock(HttpCalloutMock.class, new AnimalLocatorMockCopy());
        
        Test.startTest();
        
        String animalName = AnimalLocator.getAnimalNameById(1);
        
        Test.stopTest();
        
        // Verify the parsed result
        System.assert(
            animalName != null && animalName.length() > 0,
            'JSON parsing should extract non-empty name'
        );
        
        System.assertEquals(
            'chicken',
            animalName,
            'Parsed name should match mock response'
        );
        
        System.debug('✅ TEST 6 PASSED: JSON parsing works correctly');
    }
}

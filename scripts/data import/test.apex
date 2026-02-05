/**
 * ═══════════════════════════════════════════════════════════════════════════
 * INTERACTIVE TEST: getAccountSubscriptions() - WITH AUTO RELATIONSHIP DISCOVERY
 * ═══════════════════════════════════════════════════════════════════════════
 */

System.debug('════════════════════════════════════════════════════════');
System.debug('🎮 INTERACTIVE TEST: getAccountSubscriptions()');
System.debug('════════════════════════════════════════════════════════\n');

// ═══════════════════════════════════════════════════════════════════════════
// STEP 1: DISCOVER THE CORRECT RELATIONSHIP NAME
// ═══════════════════════════════════════════════════════════════════════════

System.debug('🔍 Step 1: Discovering relationship name...\n');

String relationshipName = null;

Schema.DescribeSObjectResult accountDescribe = Schema.SObjectType.Account;
Schema.ChildRelationship[] childRelationships = accountDescribe.getChildRelationships();

for(Schema.ChildRelationship rel : childRelationships) {
    if(rel.getChildSObject() == Subscription__c.SObjectType) {
        relationshipName = rel.getRelationshipName();
        System.debug('✅ Found Subscription relationship!');
        System.debug('   Relationship Name: ' + relationshipName);
        System.debug('   Field: ' + rel.getField());
        System.debug('   Child Object: ' + rel.getChildSObject());
        break;
    }
}

if(relationshipName == null) {
    System.debug('❌ ERROR: Could not find Subscription relationship on Account!');
    return;
}

System.debug('\n');

// ═══════════════════════════════════════════════════════════════════════════
// STEP 2: GET TEST ACCOUNTS
// ═══════════════════════════════════════════════════════════════════════════

System.debug('📊 Step 2: Querying test accounts...\n');

// Build dynamic SOQL query - NOW INCLUDES Account__c field!
String soqlQuery = 
    'SELECT Id, Name, ' +
    '       (SELECT Id, Name, Account__c, Status__c, End_Date__c, Start_Date__c, External_Sub_ID__c ' +
    '        FROM ' + relationshipName + ' ' +
    '        ORDER BY End_Date__c DESC) ' +
    'FROM Account ' +
    'WHERE Tax_Code__c LIKE \'TEST-%\' ' +
    'ORDER BY Name ' +
    'LIMIT 10';

System.debug('📝 Query: ' + soqlQuery + '\n');

List<Account> testAccounts = Database.query(soqlQuery);

System.debug('Found ' + testAccounts.size() + ' test account(s)\n');

if(testAccounts.isEmpty()) {
    System.debug('❌ No test accounts found!');
    System.debug('   Run: scripts/data import/test.apex');
    return;
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 3: TEST EACH ACCOUNT
// ═══════════════════════════════════════════════════════════════════════════

System.debug('🧪 Step 3: Testing getAccountSubscriptions() method...\n');

Integer totalTests = 0;
Integer passedTests = 0;
Integer failedTests = 0;

for(Account acc : testAccounts) {
    totalTests++;
    
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('Test #' + totalTests + ': ' + acc.Name);
    System.debug('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    System.debug('Account ID: ' + acc.Id);
    
    // Get subscriptions via relationship query
    List<Subscription__c> relatedSubs = (List<Subscription__c>)acc.getSObjects(relationshipName);
    if(relatedSubs == null) {
        relatedSubs = new List<Subscription__c>();
    }
    
    System.debug('Direct query count: ' + relatedSubs.size());
    
    // Call the method being tested
    List<Subscription__c> methodResults;
    Boolean testPassed = true;
    
    try {
        methodResults = SubscriptionController.getAccountSubscriptions(acc.Id);
        System.debug('Method returned count: ' + methodResults.size());
        
        // Verify counts match
        if(methodResults.size() == relatedSubs.size()) {
            System.debug('✅ PASS: Counts match!');
            passedTests++;
        } else {
            System.debug('❌ FAIL: Count mismatch!');
            System.debug('   Expected: ' + relatedSubs.size());
            System.debug('   Got: ' + methodResults.size());
            failedTests++;
            testPassed = false;
        }
        
        // Display results if any subscriptions exist
        if(!methodResults.isEmpty()) {
            System.debug('\n📄 Subscriptions returned by method:');
            
            Integer index = 1;
            for(Subscription__c sub : methodResults) {
                System.debug('  ' + index + '. ' + sub.Name);
                System.debug('     Status: ' + sub.Status__c);
                System.debug('     Start: ' + sub.Start_Date__c);
                System.debug('     End: ' + sub.End_Date__c);
                
                // Calculate days remaining
                if(sub.End_Date__c != null) {
                    Integer daysRemaining = Date.today().daysBetween(sub.End_Date__c);
                    String daysStatus = daysRemaining > 0 ? 
                        daysRemaining + ' days remaining' : 
                        Math.abs(daysRemaining) + ' days overdue';
                    System.debug('     ' + daysStatus);
                }
                
                if(sub.External_Sub_ID__c != null) {
                    System.debug('     External ID: ' + sub.External_Sub_ID__c);
                }
                
                index++;
            }
            
            // Verify ordering (End_Date DESC)
            if(methodResults.size() > 1) {
                Boolean correctOrder = true;
                for(Integer i = 0; i < methodResults.size() - 1; i++) {
                    Date currentEndDate = methodResults[i].End_Date__c;
                    Date nextEndDate = methodResults[i + 1].End_Date__c;
                    
                    if(currentEndDate < nextEndDate) {
                        correctOrder = false;
                        break;
                    }
                }
                
                if(correctOrder) {
                    System.debug('\n✅ Results are properly ordered by End_Date__c DESC');
                } else {
                    System.debug('\n❌ Results are NOT properly ordered!');
                    testPassed = false;
                    if(testPassed) failedTests++;
                }
            }
        } else {
            System.debug('\n  (No subscriptions for this account)');
        }
        
        // Additional assertions
        System.debug('\n🔍 Additional Checks:');
        
        // Check 1: Method returns a list (not null)
        if(methodResults != null) {
            System.debug('  ✓ Method returns a list (not null)');
        } else {
            System.debug('  ✗ Method returned null!');
            testPassed = false;
        }
        
        // Check 2: All subscriptions belong to correct account
        // NOW SAFE because methodResults includes Account__c field!
        Boolean allCorrectAccount = true;
        for(Subscription__c sub : methodResults) {
            if(sub.Account__c != acc.Id) {
                allCorrectAccount = false;
                break;
            }
        }
        
        if(allCorrectAccount) {
            System.debug('  ✓ All subscriptions belong to correct account');
        } else {
            System.debug('  ✗ Some subscriptions belong to wrong account!');
            testPassed = false;
        }
        
    } catch(Exception e) {
        System.debug('❌ ERROR calling method:');
        System.debug('   ' + e.getMessage());
        System.debug('   ' + e.getStackTraceString());
        failedTests++;
        testPassed = false;
    }
    
    System.debug('\n');
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 4: SUMMARY REPORT
// ═══════════════════════════════════════════════════════════════════════════

System.debug('════════════════════════════════════════════════════════');
System.debug('📊 TEST SUMMARY');
System.debug('════════════════════════════════════════════════════════');
System.debug('');
System.debug('Relationship Name Used: ' + relationshipName);
System.debug('');
System.debug('Total Tests: ' + totalTests);
System.debug('Passed: ' + passedTests + ' ✅');
System.debug('Failed: ' + failedTests + ' ❌');
System.debug('');

if(failedTests == 0) {
    System.debug('🎉 ALL TESTS PASSED!');
    System.debug('');
    System.debug('✅ The getAccountSubscriptions() method is working correctly!');
    System.debug('✅ You can now use it in your LWC component.');
} else {
    System.debug('⚠️  SOME TESTS FAILED');
    System.debug('');
    System.debug('Please review the failures above and fix the issues.');
}

System.debug('');
System.debug('════════════════════════════════════════════════════════');
System.debug('Next Steps:');
System.debug('1. If all tests passed, deploy your LWC component');
System.debug('2. Add the Subscription Console to an Account page');
System.debug('3. Test the "Quick Extend" functionality');
System.debug('════════════════════════════════════════════════════════');
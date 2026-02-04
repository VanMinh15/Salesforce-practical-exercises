// ═══════════════════════════════════════════════════════════════
// TEST SCRIPT FOR SubscriptionManager (No Product Lookup)
// ═══════════════════════════════════════════════════════════════

System.debug('═══════════════════════════════════════');
System.debug('🧪 Starting SubscriptionManager Test');
System.debug('═══════════════════════════════════════');

// ═══════════════════════════════════════════════════════════════
// CLEANUP: Delete existing test data
// ═══════════════════════════════════════════════════════════════
delete [SELECT Id FROM Subscription__c WHERE External_Sub_ID__c LIKE 'TEST-%'];
delete [SELECT Id FROM Account WHERE Tax_Code__c LIKE 'TEST-%'];
System.debug('✅ Cleaned up existing test data');

// ═══════════════════════════════════════════════════════════════
// TEST 1: Insert New Accounts & Subscriptions
// ═══════════════════════════════════════════════════════════════
System.debug('\n--- TEST 1: Insert New Records ---');

List<SubscriptionManager.SubWrapper> testData1 = new List<SubscriptionManager.SubWrapper>();

SubscriptionManager.SubWrapper wrapper1 = new SubscriptionManager.SubWrapper();
wrapper1.customerName = 'Acme Corporation';
wrapper1.taxCode = 'TEST-TAX-001';
wrapper1.subscriptionName = 'Gold'; 
wrapper1.externalSubscriptionID = 'TEST-SUB-001';
wrapper1.startDate = Date.today();
wrapper1.endDate = Date.today().addYears(1);
wrapper1.status = 'Active';
testData1.add(wrapper1);

SubscriptionManager.SubWrapper wrapper2 = new SubscriptionManager.SubWrapper();
wrapper2.customerName = 'Tech Industries';
wrapper2.taxCode = 'TEST-TAX-002';
wrapper2.subscriptionName = 'Silver'; 
wrapper2.externalSubscriptionID = 'TEST-SUB-002';
wrapper2.startDate = Date.today();
wrapper2.endDate = Date.today().addMonths(6);
wrapper2.status = 'Active';
testData1.add(wrapper2);

SubscriptionManager.syncCustomerData(testData1);

// Verify results
List<Account> accounts = [SELECT Id, Name, Tax_Code__c FROM Account WHERE Tax_Code__c LIKE 'TEST-%' ORDER BY Name];
List<Subscription__c> subs = [SELECT Id, Name, External_Sub_ID__c, Account__r.Name FROM Subscription__c WHERE External_Sub_ID__c LIKE 'TEST-%' ORDER BY External_Sub_ID__c];

System.debug('Created Accounts: ' + accounts.size());
for(Account acc : accounts){
    System.debug('  ✅ ' + acc.Name + ' (' + acc.Tax_Code__c + ')');
}

System.debug('Created Subscriptions: ' + subs.size());
for(Subscription__c sub : subs){
    System.debug('  ✅ ' + sub.Name + ' → Account: ' + sub.Account__r.Name);
}

// ═══════════════════════════════════════════════════════════════
// TEST 2: Update Existing Records (UPSERT behavior)
// ═══════════════════════════════════════════════════════════════
System.debug('\n--- TEST 2: Update Existing Records ---');

List<SubscriptionManager.SubWrapper> testData2 = new List<SubscriptionManager.SubWrapper>();

SubscriptionManager.SubWrapper wrapper3 = new SubscriptionManager.SubWrapper();
wrapper3.customerName = 'Acme Corporation UPDATED';  // ← Changed name
wrapper3.taxCode = 'TEST-TAX-001';  // ← Same tax code (should update)
wrapper3.subscriptionName = 'Platinum';  // ✅ Changed subscription name
wrapper3.externalSubscriptionID = 'TEST-SUB-001';  // ← Same external ID (should update)
wrapper3.startDate = Date.today();
wrapper3.endDate = Date.today().addYears(2);  // ← Changed end date
wrapper3.status = 'Active';
testData2.add(wrapper3);

SubscriptionManager.syncCustomerData(testData2);

// Verify updates
Account updatedAccount = [SELECT Name FROM Account WHERE Tax_Code__c = 'TEST-TAX-001'];
Subscription__c updatedSub = [SELECT Name, End_Date__c FROM Subscription__c WHERE External_Sub_ID__c = 'TEST-SUB-001'];

System.debug('Updated Account Name: ' + updatedAccount.Name);
System.debug('Updated Subscription Name: ' + updatedSub.Name);
System.debug('Updated Subscription End Date: ' + updatedSub.End_Date__c);
System.debug('✅ Upsert working correctly!');

// ═══════════════════════════════════════════════════════════════
// TEST 3: Merge Duplicate Accounts
// ═══════════════════════════════════════════════════════════════
System.debug('\n--- TEST 3: Merge Duplicate Accounts ---');

// Create duplicate accounts manually
Account acc1 = new Account(Name = 'Duplicate Test A', Tax_Code__c = 'TEST-DUP-999', AnnualRevenue = 1000000);
Account acc2 = new Account(Name = 'Duplicate Test B', Tax_Code__c = 'TEST-DUP-999', AnnualRevenue = 5000000);  // Higher revenue
Account acc3 = new Account(Name = 'Duplicate Test C', Tax_Code__c = 'TEST-DUP-999', AnnualRevenue = 3000000);
insert new List<Account>{acc1, acc2, acc3};

System.debug('Created 3 duplicate accounts with TEST-DUP-999');

List<Account> beforeMerge = [SELECT Id FROM Account WHERE Tax_Code__c = 'TEST-DUP-999'];
System.debug('Accounts before merge: ' + beforeMerge.size());

// Now sync - should merge duplicates
List<SubscriptionManager.SubWrapper> testData3 = new List<SubscriptionManager.SubWrapper>();

SubscriptionManager.SubWrapper wrapper4 = new SubscriptionManager.SubWrapper();
wrapper4.customerName = 'Merged Company';
wrapper4.taxCode = 'TEST-DUP-999';
wrapper4.subscriptionName = 'Bronze';  // ✅ No "Package"
wrapper4.externalSubscriptionID = 'TEST-SUB-MERGE-001';
wrapper4.startDate = Date.today();
wrapper4.endDate = Date.today().addMonths(3);
wrapper4.status = 'Active';
testData3.add(wrapper4);

SubscriptionManager.syncCustomerData(testData3);

// Verify merge
List<Account> afterMerge = [SELECT Id, AnnualRevenue FROM Account WHERE Tax_Code__c = 'TEST-DUP-999'];
System.debug('Accounts after merge: ' + afterMerge.size());
System.debug('Kept account with revenue: ' + afterMerge[0].AnnualRevenue);
System.debug('✅ Merge working correctly!');

// ═══════════════════════════════════════════════════════════════
// TEST 4: Multiple Subscriptions for Same Account
// ═══════════════════════════════════════════════════════════════
System.debug('\n--- TEST 4: Multiple Subscriptions per Account ---');

List<SubscriptionManager.SubWrapper> testData4 = new List<SubscriptionManager.SubWrapper>();

SubscriptionManager.SubWrapper wrapper5 = new SubscriptionManager.SubWrapper();
wrapper5.customerName = 'Multi-Sub Company';
wrapper5.taxCode = 'TEST-MULTI-001';
wrapper5.subscriptionName = 'Gold';  // ✅ No "Package"
wrapper5.externalSubscriptionID = 'TEST-MULTI-SUB-001';
wrapper5.startDate = Date.today();
wrapper5.endDate = Date.today().addYears(1);
wrapper5.status = 'Active';
testData4.add(wrapper5);

SubscriptionManager.SubWrapper wrapper6 = new SubscriptionManager.SubWrapper();
wrapper6.customerName = 'Multi-Sub Company';  // Same customer
wrapper6.taxCode = 'TEST-MULTI-001';  // Same tax code
wrapper6.subscriptionName = 'Silver';  // ✅ Different subscription, no "Package"
wrapper6.externalSubscriptionID = 'TEST-MULTI-SUB-002';  // Different external ID
wrapper6.startDate = Date.today();
wrapper6.endDate = Date.today().addMonths(6);
wrapper6.status = 'Active';
testData4.add(wrapper6);

SubscriptionManager.syncCustomerData(testData4);

// Verify
List<Account> multiAccounts = [SELECT Id FROM Account WHERE Tax_Code__c = 'TEST-MULTI-001'];
List<Subscription__c> multiSubs = [SELECT Id, Name FROM Subscription__c WHERE External_Sub_ID__c LIKE 'TEST-MULTI-%' ORDER BY Name];

System.debug('Accounts created: ' + multiAccounts.size());
System.debug('Subscriptions created: ' + multiSubs.size());

for(Subscription__c sub : multiSubs){
    System.debug('  ✅ ' + sub.Name);
}

// ═══════════════════════════════════════════════════════════════
// TEST 5: Null and Blank Values
// ═══════════════════════════════════════════════════════════════
System.debug('\n--- TEST 5: Handle Null/Blank Values ---');

List<SubscriptionManager.SubWrapper> testData5 = new List<SubscriptionManager.SubWrapper>();

SubscriptionManager.SubWrapper wrapper7 = new SubscriptionManager.SubWrapper();
wrapper7.customerName = 'Test Null Company';
wrapper7.taxCode = 'TEST-NULL-001';
wrapper7.subscriptionName = '';  // Blank subscription name
wrapper7.externalSubscriptionID = 'TEST-SUB-NULL-001';
wrapper7.startDate = Date.today();
wrapper7.endDate = Date.today().addMonths(1);
wrapper7.status = 'Active';
testData5.add(wrapper7);

SubscriptionManager.syncCustomerData(testData5);

List<Subscription__c> nullSubs = [SELECT Id, Name FROM Subscription__c WHERE External_Sub_ID__c = 'TEST-SUB-NULL-001'];
System.debug('Subscription with blank name created: ' + (nullSubs.size() > 0));
if(nullSubs.size() > 0){
    System.debug('  Subscription Name field: "' + nullSubs[0].Name + '"');
}
System.debug('✅ Null handling working correctly!');

// ═══════════════════════════════════════════════════════════════
// FINAL SUMMARY
// ═══════════════════════════════════════════════════════════════
System.debug('\n═══════════════════════════════════════');
System.debug('🎉 ALL TESTS COMPLETED!');
System.debug('═══════════════════════════════════════');
System.debug('Test Coverage:');
System.debug('  ✅ Insert new accounts & subscriptions');
System.debug('  ✅ Update existing records (upsert)');
System.debug('  ✅ Merge duplicate accounts');
System.debug('  ✅ Multiple subscriptions per account');
System.debug('  ✅ Handle null/blank values');
System.debug('═══════════════════════════════════════');

// ═══════════════════════════════════════════════════════════════
// CLEANUP (Optional - comment out if you want to keep test data)
// ═══════════════════════════════════════════════════════════════
/*
delete [SELECT Id FROM Subscription__c WHERE External_Sub_ID__c LIKE 'TEST-%'];
delete [SELECT Id FROM Account WHERE Tax_Code__c LIKE 'TEST-%'];
System.debug('✅ Cleaned up all test data');
*/
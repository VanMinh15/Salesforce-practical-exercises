/**
 * ═══════════════════════════════════════════════════════════════
 * TEST SCRIPT FOR SubscriptionManager
 * ═══════════════════════════════════════════════════════════════
 */

System.debug('════════════════════════════════════════════════════════');
System.debug('🧪 STARTING SubscriptionManager TEST');
System.debug('════════════════════════════════════════════════════════');

// ═══════════════════════════════════════════════════════════════
// SETUP: Create Products (Required for subscriptions)
// ═══════════════════════════════════════════════════════════════
System.debug('\n📦 SETUP: Creating Products...');

List<Product2> products = new List<Product2>{
    new Product2(Name = 'Silver', ProductCode = 'SILVER', IsActive = true),
    new Product2(Name = 'Gold', ProductCode = 'GOLD', IsActive = true),
    new Product2(Name = 'Platinum', ProductCode = 'PLATINUM', IsActive = true)
};
insert products;
System.debug('✅ Created ' + products.size() + ' products');


// ═══════════════════════════════════════════════════════════════
// TEST 1: Insert New Accounts & Subscriptions
// ═══════════════════════════════════════════════════════════════
System.debug('\n════════════════════════════════════════════════════════');
System.debug('TEST 1: Insert New Records');
System.debug('════════════════════════════════════════════════════════');

List<SubscriptionManager.SubWrapper> testData1 = new List<SubscriptionManager.SubWrapper>();

SubscriptionManager.SubWrapper wrapper1 = new SubscriptionManager.SubWrapper();
wrapper1.customerName = 'Acme Corporation';
wrapper1.taxCode = 'TEST-TAX-001';
wrapper1.subscriptionName = 'Gold';
wrapper1.externalSubscriptionID = 'TEST-SUB-001';
wrapper1.startDate = Date.today();
wrapper1.endDate = Date.today().addDays(365);
wrapper1.status = 'Active';
testData1.add(wrapper1);

SubscriptionManager.SubWrapper wrapper2 = new SubscriptionManager.SubWrapper();
wrapper2.customerName = 'Tech Innovations Inc';
wrapper2.taxCode = 'TEST-TAX-002';
wrapper2.subscriptionName = 'Platinum';
wrapper2.externalSubscriptionID = 'TEST-SUB-002';
wrapper2.startDate = Date.today();
wrapper2.endDate = Date.today().addDays(365);
wrapper2.status = 'Active';
testData1.add(wrapper2);

System.debug('📤 Syncing ' + testData1.size() + ' new records...');
SubscriptionManager.syncCustomerData(testData1);

// Verify Test 1
List<Account> accountsTest1 = [
    SELECT Id, Name, Tax_Code__c 
    FROM Account 
    WHERE Tax_Code__c IN ('TEST-TAX-001', 'TEST-TAX-002')
];
System.debug('✅ Accounts created: ' + accountsTest1.size());
for(Account acc : accountsTest1){
    System.debug('  • ' + acc.Name + ' (' + acc.Tax_Code__c + ')');
}

List<Subscription__c> subsTest1 = [
    SELECT Id, Account__r.Name, External_Sub_ID__c, Status__c
    FROM Subscription__c
    WHERE External_Sub_ID__c IN ('TEST-SUB-001', 'TEST-SUB-002')
];
System.debug('✅ Subscriptions created: ' + subsTest1.size());
for(Subscription__c sub : subsTest1){
    System.debug('  • ' + sub.External_Sub_ID__c + ' → ' + sub.Account__r.Name);
}


// ═══════════════════════════════════════════════════════════════
// TEST 2: Update Existing Accounts & Subscriptions
// ═══════════════════════════════════════════════════════════════
System.debug('\n════════════════════════════════════════════════════════');
System.debug('TEST 2: Update Existing Records');
System.debug('════════════════════════════════════════════════════════');

List<SubscriptionManager.SubWrapper> testData2 = new List<SubscriptionManager.SubWrapper>();

SubscriptionManager.SubWrapper updateWrapper1 = new SubscriptionManager.SubWrapper();
updateWrapper1.customerName = 'Acme Corporation - UPDATED';
updateWrapper1.taxCode = 'TEST-TAX-001';  // Same tax code
updateWrapper1.subscriptionName = 'Silver';
updateWrapper1.externalSubscriptionID = 'TEST-SUB-001';  // Same external ID
updateWrapper1.startDate = Date.today();
updateWrapper1.endDate = Date.today().addDays(730);  // Extended
updateWrapper1.status = 'Active';
testData2.add(updateWrapper1);

System.debug('📤 Updating existing records...');
SubscriptionManager.syncCustomerData(testData2);

// Verify Test 2
Account updatedAccount = [
    SELECT Id, Name, Tax_Code__c 
    FROM Account 
    WHERE Tax_Code__c = 'TEST-TAX-001'
    LIMIT 1
];
System.debug('✅ Account updated: ' + updatedAccount.Name);

Subscription__c updatedSub = [
    SELECT Id, End_Date__c, Status__c
    FROM Subscription__c
    WHERE External_Sub_ID__c = 'TEST-SUB-001'
    LIMIT 1
];
System.debug('✅ Subscription updated: End Date = ' + updatedSub.End_Date__c);


// ═══════════════════════════════════════════════════════════════
// TEST 3: Merge Duplicate Accounts
// ═══════════════════════════════════════════════════════════════
System.debug('\n════════════════════════════════════════════════════════');
System.debug('TEST 3: Merge Duplicate Accounts');
System.debug('════════════════════════════════════════════════════════');

// Create duplicate accounts manually (same tax code)
Account dup1 = new Account(
    Name = 'Duplicate Test A', 
    Tax_Code__c = 'TEST-DUP-999', 
    AnnualRevenue = 1000000
);
Account dup2 = new Account(
    Name = 'Duplicate Test B', 
    Tax_Code__c = 'TEST-DUP-999', 
    AnnualRevenue = 5000000  // Highest revenue - should be master
);
Account dup3 = new Account(
    Name = 'Duplicate Test C', 
    Tax_Code__c = 'TEST-DUP-999', 
    AnnualRevenue = 3000000
);

// We need to insert them separately to bypass unique constraint
insert dup1;
System.debug('Created account 1: ' + dup1.Id);

// Temporarily remove unique constraint or use update to create duplicates
// For testing purposes, we'll update existing to have same tax code
dup2.Tax_Code__c = 'TEST-DUP-998';
dup3.Tax_Code__c = 'TEST-DUP-997';
insert new List<Account>{dup2, dup3};

// Now update to create duplicates
dup2.Tax_Code__c = 'TEST-DUP-999';
dup3.Tax_Code__c = 'TEST-DUP-999';
update new List<Account>{dup2, dup3};

System.debug('✅ Created 3 duplicate accounts with TEST-DUP-999');

// Check before merge
List<Account> beforeMerge = [
    SELECT Id, Name, Tax_Code__c, AnnualRevenue 
    FROM Account 
    WHERE Tax_Code__c = 'TEST-DUP-999'
];
System.debug('📊 Accounts before merge: ' + beforeMerge.size());
for(Account acc : beforeMerge){
    System.debug('  • ' + acc.Name + ' - Revenue: $' + acc.AnnualRevenue);
}

// Sync with duplicate tax code - should merge them
List<SubscriptionManager.SubWrapper> testData3 = new List<SubscriptionManager.SubWrapper>();

SubscriptionManager.SubWrapper mergeWrapper = new SubscriptionManager.SubWrapper();
mergeWrapper.customerName = 'Duplicate Test - Merged';
mergeWrapper.taxCode = 'TEST-DUP-999';
mergeWrapper.subscriptionName = 'Gold';
mergeWrapper.externalSubscriptionID = 'TEST-SUB-999';
mergeWrapper.startDate = Date.today();
mergeWrapper.endDate = Date.today().addDays(365);
mergeWrapper.status = 'Active';
testData3.add(mergeWrapper);

System.debug('\n📤 Syncing data - should trigger merge...');
SubscriptionManager.syncCustomerData(testData3);

// Check after merge
List<Account> afterMerge = [
    SELECT Id, Name, Tax_Code__c, AnnualRevenue 
    FROM Account 
    WHERE Tax_Code__c = 'TEST-DUP-999'
];
System.debug('\n📊 Accounts after merge: ' + afterMerge.size());
if(afterMerge.size() == 1){
    System.debug('✅ Merge successful! Kept account:');
    System.debug('  • ' + afterMerge[0].Name + ' - Revenue: $' + afterMerge[0].AnnualRevenue);
    if(afterMerge[0].AnnualRevenue == 5000000){
        System.debug('✅ Correct master selected (highest revenue)');
    }
} else {
    System.debug('⚠️ Merge did not complete. Still ' + afterMerge.size() + ' accounts');
}


// ═══════════════════════════════════════════════════════════════
// TEST 4: Mixed Operations (Insert + Update)
// ═══════════════════════════════════════════════════════════════
System.debug('\n════════════════════════════════════════════════════════');
System.debug('TEST 4: Mixed Insert and Update');
System.debug('════════════════════════════════════════════════════════');

List<SubscriptionManager.SubWrapper> testData4 = new List<SubscriptionManager.SubWrapper>();

// This one exists - should update
SubscriptionManager.SubWrapper mixed1 = new SubscriptionManager.SubWrapper();
mixed1.customerName = 'Tech Innovations Inc - Updated Again';
mixed1.taxCode = 'TEST-TAX-002';  // Existing
mixed1.subscriptionName = 'Silver';
mixed1.externalSubscriptionID = 'TEST-SUB-003';  // New subscription
mixed1.startDate = Date.today();
mixed1.endDate = Date.today().addDays(180);
mixed1.status = 'Active';
testData4.add(mixed1);

// This one is new - should insert
SubscriptionManager.SubWrapper mixed2 = new SubscriptionManager.SubWrapper();
mixed2.customerName = 'Global Solutions LLC';
mixed2.taxCode = 'TEST-TAX-003';  // New
mixed2.subscriptionName = 'Platinum';
mixed2.externalSubscriptionID = 'TEST-SUB-004';
mixed2.startDate = Date.today();
mixed2.endDate = Date.today().addDays(365);
mixed2.status = 'Active';
testData4.add(mixed2);

System.debug('📤 Syncing mixed operations...');
SubscriptionManager.syncCustomerData(testData4);

List<Account> accountsTest4 = [
    SELECT Id, Name, Tax_Code__c 
    FROM Account 
    WHERE Tax_Code__c IN ('TEST-TAX-002', 'TEST-TAX-003')
];
System.debug('✅ Accounts: ' + accountsTest4.size());
for(Account acc : accountsTest4){
    System.debug('  • ' + acc.Name + ' (' + acc.Tax_Code__c + ')');
}

List<Subscription__c> subsTest4 = [
    SELECT Id, External_Sub_ID__c, Account__r.Tax_Code__c
    FROM Subscription__c
    WHERE External_Sub_ID__c IN ('TEST-SUB-003', 'TEST-SUB-004')
];
System.debug('✅ New subscriptions: ' + subsTest4.size());
for(Subscription__c sub : subsTest4){
    System.debug('  • ' + sub.External_Sub_ID__c + ' → Account: ' + sub.Account__r.Tax_Code__c);
}


// ═══════════════════════════════════════════════════════════════
// FINAL SUMMARY
// ═══════════════════════════════════════════════════════════════
System.debug('\n════════════════════════════════════════════════════════');
System.debug('📊 FINAL SUMMARY');
System.debug('════════════════════════════════════════════════════════');

List<Account> allTestAccounts = [
    SELECT Id, Name, Tax_Code__c, AnnualRevenue
    FROM Account 
    WHERE Tax_Code__c LIKE 'TEST-%'
    ORDER BY Tax_Code__c
];
System.debug('Total Accounts: ' + allTestAccounts.size());
for(Account acc : allTestAccounts){
    System.debug('  • ' + acc.Tax_Code__c + ' → ' + acc.Name);
}

List<Subscription__c> allTestSubs = [
    SELECT Id, External_Sub_ID__c, Account__r.Tax_Code__c, Status__c
    FROM Subscription__c
    WHERE External_Sub_ID__c LIKE 'TEST-SUB-%'
    ORDER BY External_Sub_ID__c
];
System.debug('\nTotal Subscriptions: ' + allTestSubs.size());
for(Subscription__c sub : allTestSubs){
    System.debug('  • ' + sub.External_Sub_ID__c + ' → ' + sub.Account__r.Tax_Code__c + ' (' + sub.Status__c + ')');
}

System.debug('\n════════════════════════════════════════════════════════');
System.debug('✅ ALL TESTS COMPLETE!');
System.debug('════════════════════════════════════════════════════════');
/**
 * Opportunity Trigger
 * @description Trigger on Opportunity object to handle various requirements:
 * 1. Validate amount is greater than 5000 (Update only)
 * 2. Prevent deletion of closed won opportunities for banking accounts (Delete only)
 * 3. Set primary contact to CEO contact on the account (Update only)
 */
trigger OpportunityTrigger on Opportunity (before update, before delete) {
    
    // Handle before update operations
    if (Trigger.isBefore && Trigger.isUpdate) {
        // Requirement 1: Validate amount is greater than 5000
        for (Opportunity opp : Trigger.new) {
            if (opp.Amount != null && opp.Amount <= 5000) {
                opp.addError('Opportunity amount must be greater than 5000');
            }
        }
        
        // Requirement 3: Set primary contact to CEO contact on the account
        // Collect all account IDs for opportunities being updated
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : Trigger.new) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        
        // Query for CEO contacts for these accounts
        Map<Id, Id> accountToCEOContactMap = new Map<Id, Id>();
        if (!accountIds.isEmpty()) {
            for (Contact con : [SELECT Id, AccountId FROM Contact WHERE AccountId IN :accountIds AND Title = 'CEO']) {
                accountToCEOContactMap.put(con.AccountId, con.Id);
            }
        }
        
        // Set the primary contact directly on the records being updated
        for (Opportunity opp : Trigger.new) {
            if (opp.AccountId != null && accountToCEOContactMap.containsKey(opp.AccountId)) {
                opp.Primary_Contact__c = accountToCEOContactMap.get(opp.AccountId);
            }
        }
    }
    
    // Handle before delete operations
    if (Trigger.isBefore && Trigger.isDelete) {
        // Requirement 2: Prevent deletion of closed won opportunities for banking accounts
        // First, collect all account IDs for opportunities being deleted
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : Trigger.old) {
            if (opp.StageName == 'Closed Won' && opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        
        // Query accounts with Banking industry
        Map<Id, Account> bankingAccounts = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            for (Account acc : [SELECT Id, Industry FROM Account WHERE Id IN :accountIds AND Industry = 'Banking']) {
                bankingAccounts.put(acc.Id, acc);
            }
        }
        
        // Check each opportunity and prevent deletion if conditions are met
        for (Opportunity opp : Trigger.old) {
            if (opp.StageName == 'Closed Won' && bankingAccounts.containsKey(opp.AccountId)) {
                opp.addError('Cannot delete closed opportunity for a banking account that is won');
            }
        }
    }
}
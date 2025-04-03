/**
 * Account Trigger
 * @description Trigger on Account object to handle various requirements:
 * 1. Set account type to 'Prospect' when none is provided (Insert only)
 * 2. Copy shipping address to billing address (Insert only)
 * 3. Set account rating to 'Hot' when Phone, Website, and Fax are all populated (Insert only)
 * 4. Create a default contact for each new account (Insert only)
 */
trigger AccountTrigger on Account (before insert, after insert) {
    
    // Handle before insert operations
    if (Trigger.isBefore && Trigger.isInsert) {
        // Loop through all accounts being inserted to categorize them
        for (Account acc : Trigger.new) {
            // Requirement 1: Set account type to 'Prospect' if null
            if (acc.Type == null) {
                acc.Type = 'Prospect';
            }
            
            // Requirement 2: Copy shipping address to billing address if shipping is populated
            if (acc.ShippingStreet != null || acc.ShippingCity != null || 
                acc.ShippingState != null || acc.ShippingPostalCode != null || 
                acc.ShippingCountry != null) {
                acc.BillingStreet = acc.ShippingStreet;
                acc.BillingCity = acc.ShippingCity;
                acc.BillingState = acc.ShippingState;
                acc.BillingPostalCode = acc.ShippingPostalCode;
                acc.BillingCountry = acc.ShippingCountry;
            }
            
            // Requirement 3: Set account rating to 'Hot' if Phone, Website, and Fax are all populated
            if (acc.Phone != null && acc.Website != null && acc.Fax != null) {
                acc.Rating = 'Hot';
            }
        }
    }
    
    // Handle after insert operations
    if (Trigger.isAfter && Trigger.isInsert) {
        // Requirement 4: Create a default contact for each new account
        List<Contact> contactsToInsert = new List<Contact>();
        
        for (Account acc : Trigger.new) {
            Contact newContact = new Contact(
                LastName = 'DefaultContact',
                Email = 'default@email.com',
                AccountId = acc.Id
            );
            contactsToInsert.add(newContact);
        }
        
        // Insert all contacts in one DML operation to respect governor limits
        if (!contactsToInsert.isEmpty()) {
            insert contactsToInsert;
        }
    }
}
-- =====================================================
-- ADDITIONAL CONSTRAINTS AND VALIDATIONS
-- =====================================================

-- Accounting: Ensure journal entry is balanced
ALTER TABLE accounting.journal_entry
ADD CONSTRAINT CHK_journal_balanced
CHECK (total_debit = total_credit);

-- Create function to validate journal entry lines
GO
CREATE OR ALTER FUNCTION accounting.fn_validate_journal_balance(@journal_entry_id INT)
RETURNS BIT
AS
BEGIN
    DECLARE @is_balanced BIT = 0;
    
    IF EXISTS (
        SELECT 1 
        FROM accounting.journal_entry je
        WHERE je.journal_entry_id = @journal_entry_id
        AND je.total_debit = je.total_credit
    )
    SET @is_balanced = 1;
    
    RETURN @is_balanced;
END;
GO

-- Add constraint using function (SQL Server doesn't allow functions in CHECK constraints directly)
-- We'll handle this via triggers instead

-- Inventory: Ensure transfer movements have both locations
ALTER TABLE inventory.inventory_movement
ADD CONSTRAINT CHK_transfer_locations CHECK (
    (movement_type_id IN (SELECT movement_type_id FROM inventory.inventory_movement_type WHERE movement_direction = 'Transfer') 
     AND from_location_id IS NOT NULL AND to_location_id IS NOT NULL) OR
    (movement_type_id NOT IN (SELECT movement_type_id FROM inventory.inventory_movement_type WHERE movement_direction = 'Transfer')
     AND (from_location_id IS NOT NULL XOR to_location_id IS NOT NULL))
);

-- Document: Ensure amounts are consistent
ALTER TABLE document.document
ADD CONSTRAINT CHK_document_amounts CHECK (
    total_amount = (subtotal + tax_amount - discount_amount)
);

-- Cash: Shift closing validation
ALTER TABLE cash.shift
ADD CONSTRAINT CHK_shift_status CHECK (
    (status = 'Open' AND closing_time IS NULL) OR
    (status = 'Closed' AND closing_time IS NOT NULL AND closing_balance IS NOT NULL)
);

-- Party: Ensure email format (basic validation)
ALTER TABLE party.party
ADD CONSTRAINT CHK_party_email CHECK (
    email IS NULL OR email LIKE '%_@__%.__%'
);

-- Product: Ensure SKU format
ALTER TABLE catalog.product_variant
ADD CONSTRAINT CHK_sku_format CHECK (
    sku LIKE '[A-Z0-9]%'
);

-- Prevent self-reference in categories
ALTER TABLE catalog.category
ADD CONSTRAINT CHK_no_self_parent CHECK (
    parent_category_id <> category_id
);

-- Prevent self-reference in accounts
ALTER TABLE accounting.account
ADD CONSTRAINT CHK_no_self_parent_account CHECK (
    parent_account_id <> account_id
);
-- =====================================================
-- TRIGGERS FOR BUSINESS RULES
-- =====================================================

-- Auto-calculate journal entry totals
GO
CREATE OR ALTER TRIGGER accounting.trg_journal_entry_line_totals
ON accounting.journal_entry_line
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE je
    SET 
        total_debit = (
            SELECT SUM(debit_amount) 
            FROM accounting.journal_entry_line 
            WHERE journal_entry_id = je.journal_entry_id
        ),
        total_credit = (
            SELECT SUM(credit_amount) 
            FROM accounting.journal_entry_line 
            WHERE journal_entry_id = je.journal_entry_id
        ),
        modified_at = GETUTCDATE()
    FROM accounting.journal_entry je
    WHERE je.journal_entry_id IN (
        SELECT journal_entry_id FROM inserted
        UNION
        SELECT journal_entry_id FROM deleted
    );
END;
GO

-- Log all changes for audit
GO
CREATE OR ALTER TRIGGER security.trg_audit_log
ON ALL SERVER
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    -- This would log schema changes
    -- Implementation depends on specific requirements
END;
GO

-- Update current stock on inventory movement
GO
CREATE OR ALTER TRIGGER inventory.trg_update_stock_on_movement
ON inventory.inventory_movement
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- This is handled in the stored procedure, but added as an additional safety
    -- Update average cost for incoming items
    UPDATE cs
    SET average_cost = (
        SELECT AVG(unit_cost)
        FROM inventory.inventory_movement
        WHERE product_id = cs.product_id
        AND movement_type_id IN (1, 2) -- Receipt types
    )
    FROM inventory.current_stock cs
    INNER JOIN inserted i ON cs.product_id = i.product_id;
END;
GO

-- Auto-generate document numbers
GO
CREATE OR ALTER TRIGGER document.trg_generate_document_number
ON document.document
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO document.document (
        document_type_id, document_number, document_date, posting_date,
        due_date, party_id, branch_id, currency_id, exchange_rate,
        subtotal, tax_amount, discount_amount, total_amount,
        status, reference_document_id, description, created_by, created_at
    )
    SELECT 
        i.document_type_id,
        CASE 
            WHEN i.document_number IS NULL THEN 
                dt.number_prefix + CAST(dt.next_number AS NVARCHAR(20))
            ELSE i.document_number
        END,
        i.document_date, i.posting_date, i.due_date,
        i.party_id, i.branch_id, i.currency_id, i.exchange_rate,
        i.subtotal, i.tax_amount, i.discount_amount, i.total_amount,
        i.status, i.reference_document_id, i.description,
        i.created_by, i.created_at
    FROM inserted i
    INNER JOIN document.document_type dt ON i.document_type_id = dt.document_type_id;
    
    -- Update next number
    UPDATE dt
    SET next_number = dt.next_number + 1
    FROM document.document_type dt
    INNER JOIN inserted i ON dt.document_type_id = i.document_type_id
    WHERE i.document_number IS NULL;
END;
GO

-- Prevent deletion of posted transactions
GO
CREATE OR ALTER TRIGGER accounting.trg_prevent_posted_deletion
ON accounting.journal_entry
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM deleted WHERE status = 'Posted')
    BEGIN
        RAISERROR('Cannot delete posted journal entries. Create a reversal entry instead.', 16, 1);
        ROLLBACK;
        RETURN;
    END
    
    DELETE FROM accounting.journal_entry
    WHERE journal_entry_id IN (SELECT journal_entry_id FROM deleted);
END;
GO
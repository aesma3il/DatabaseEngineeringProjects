-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- Create Journal Entry with double-entry validation
GO
CREATE OR ALTER PROCEDURE accounting.sp_create_journal_entry
    @entry_number NVARCHAR(50),
    @entry_date DATE,
    @description NVARCHAR(500),
    @lines AS accounting.JournalEntryLineType READONLY, -- Custom table type
    @created_by INT,
    @journal_entry_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @total_debit DECIMAL(19,4) = 0;
        DECLARE @total_credit DECIMAL(19,4) = 0;
        
        SELECT @total_debit = SUM(debit_amount), @total_credit = SUM(credit_amount)
        FROM @lines;
        
        IF @total_debit != @total_credit
        BEGIN
            RAISERROR('Journal entry must have equal debit and credit totals', 16, 1);
            ROLLBACK;
            RETURN;
        END
        
        INSERT INTO accounting.journal_entry (
            entry_number, entry_date, description, status, 
            total_debit, total_credit, created_by, created_at
        )
        VALUES (
            @entry_number, @entry_date, @description, 'Draft',
            @total_debit, @total_credit, @created_by, GETUTCDATE()
        );
        
        SET @journal_entry_id = SCOPE_IDENTITY();
        
        INSERT INTO accounting.journal_entry_line (
            journal_entry_id, account_id, debit_amount, credit_amount, description, line_number
        )
        SELECT 
            @journal_entry_id, account_id, debit_amount, credit_amount, description, line_number
        FROM @lines;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Post Journal Entry (maker-checker)
GO
CREATE OR ALTER PROCEDURE accounting.sp_post_journal_entry
    @journal_entry_id INT,
    @approved_by INT,
    @posted_by INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE accounting.journal_entry
    SET 
        status = 'Posted',
        approved_by = @approved_by,
        posted_by = @posted_by,
        posted_at = GETUTCDATE(),
        modified_at = GETUTCDATE()
    WHERE journal_entry_id = @journal_entry_id
    AND status = 'Approved';
    
    IF @@ROWCOUNT = 0
        RAISERROR('Journal entry not found or not in approved status', 16, 1);
END;
GO

-- Record inventory movement
GO
CREATE OR ALTER PROCEDURE inventory.sp_record_movement
    @movement_number NVARCHAR(50),
    @movement_type_code NVARCHAR(20),
    @product_id INT,
    @quantity DECIMAL(18,4),
    @from_location_code NVARCHAR(50),
    @to_location_code NVARCHAR(50),
    @document_id INT,
    @created_by INT,
    @inventory_movement_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @movement_type_id INT;
        DECLARE @from_location_id INT, @to_location_id INT;
        DECLARE @unit_cost DECIMAL(19,4);
        
        SELECT @movement_type_id = movement_type_id, @movement_direction = movement_direction
        FROM inventory.inventory_movement_type
        WHERE type_code = @movement_type_code;
        
        -- Get current average cost for incoming movements
        IF @movement_type_code IN ('PURCHASE', 'RECEIPT')
        BEGIN
            SELECT @unit_cost = average_cost 
            FROM inventory.current_stock 
            WHERE product_id = @product_id;
            
            IF @unit_cost IS NULL SET @unit_cost = 0;
        END
        
        -- Get location IDs
        SELECT @from_location_id = location_id FROM inventory.location WHERE location_code = @from_location_code;
        SELECT @to_location_id = location_id FROM inventory.location WHERE location_code = @to_location_code;
        
        INSERT INTO inventory.inventory_movement (
            movement_number, movement_type_id, product_id, quantity, unit_cost,
            from_location_id, to_location_id, document_id, created_by
        )
        VALUES (
            @movement_number, @movement_type_id, @product_id, @quantity, @unit_cost,
            @from_location_id, @to_location_id, @document_id, @created_by
        );
        
        SET @inventory_movement_id = SCOPE_IDENTITY();
        
        -- Update current stock
        IF @movement_type_code = 'RECEIPT' -- Incoming
        BEGIN
            MERGE inventory.current_stock AS target
            USING (SELECT @product_id AS product_id, @to_location_id AS location_id) AS source
            ON target.product_id = source.product_id AND target.location_id = source.location_id
            WHEN MATCHED THEN
                UPDATE SET 
                    quantity_on_hand = target.quantity_on_hand + @quantity,
                    last_movement_date = GETUTCDATE()
            WHEN NOT MATCHED THEN
                INSERT (product_id, location_id, quantity_on_hand, last_movement_date)
                VALUES (@product_id, @to_location_id, @quantity, GETUTCDATE());
        END
        ELSE IF @movement_type_code = 'ISSUE' -- Outgoing
        BEGIN
            UPDATE inventory.current_stock
            SET quantity_on_hand = quantity_on_hand - @quantity,
                last_movement_date = GETUTCDATE()
            WHERE product_id = @product_id AND location_id = @from_location_id;
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Calculate price using pricing rules
GO
CREATE OR ALTER PROCEDURE pricing.sp_calculate_price
    @product_id INT,
    @party_id INT,
    @quantity DECIMAL(18,4),
    @calculated_price DECIMAL(19,4) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @base_price DECIMAL(19,4);
    DECLARE @discount DECIMAL(5,2) = 0;
    DECLARE @party_role_id INT;
    
    -- Get base price (from product or default)
    SELECT @base_price = COALESCE(MAX(fixed_price), 0)
    FROM pricing.price_rule
    WHERE product_id = @product_id
    AND is_active = 1
    AND (start_date IS NULL OR start_date <= GETDATE())
    AND (end_date IS NULL OR end_date >= GETDATE())
    AND fixed_price IS NOT NULL;
    
    -- Get party role
    SELECT TOP 1 @party_role_id = party_role_id
    FROM party.party_role_assignment
    WHERE party_id = @party_id;
    
    -- Apply discount rules
    SELECT TOP 1 @discount = discount_percent
    FROM pricing.price_rule
    WHERE (product_id = @product_id OR category_id IN (
        SELECT category_id FROM catalog.product WHERE product_id = @product_id
    ))
    AND (party_role_id IS NULL OR party_role_id = @party_role_id)
    AND (min_quantity IS NULL OR min_quantity <= @quantity)
    AND (max_quantity IS NULL OR max_quantity >= @quantity)
    AND is_active = 1
    AND (start_date IS NULL OR start_date <= GETDATE())
    AND (end_date IS NULL OR end_date >= GETDATE())
    ORDER BY priority DESC, discount_percent DESC;
    
    SET @calculated_price = @base_price * (1 - (@discount / 100));
    
    IF @calculated_price IS NULL
        SET @calculated_price = 0;
END;
GO

-- Create document with full workflow
GO
CREATE OR ALTER PROCEDURE document.sp_create_sales_document
    @document_type_code NVARCHAR(20),
    @party_code NVARCHAR(50),
    @items AS document.DocumentLineItemType READONLY,
    @created_by INT,
    @document_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @document_type_id INT;
        DECLARE @party_id INT;
        DECLARE @document_number NVARCHAR(50);
        DECLARE @subtotal DECIMAL(19,4) = 0;
        DECLARE @tax_amount DECIMAL(19,4) = 0;
        DECLARE @total_amount DECIMAL(19,4) = 0;
        
        -- Get document type
        SELECT @document_type_id = document_type_id, @document_number = 
            number_prefix + CAST(next_number AS NVARCHAR(20))
        FROM document.document_type
        WHERE type_code = @document_type_code;
        
        -- Get party
        SELECT @party_id = party_id FROM party.party WHERE party_code = @party_code;
        
        -- Calculate totals
        SELECT 
            @subtotal = SUM(quantity * unit_price),
            @tax_amount = SUM(quantity * unit_price * (tax_rate / 100)),
            @total_amount = SUM(quantity * unit_price * (1 + tax_rate / 100))
        FROM @items;
        
        -- Create document
        INSERT INTO document.document (
            document_type_id, document_number, document_date, party_id,
            subtotal, tax_amount, total_amount, status, created_by
        )
        VALUES (
            @document_type_id, @document_number, GETDATE(), @party_id,
            @subtotal, @tax_amount, @total_amount, 'Draft', @created_by
        );
        
        SET @document_id = SCOPE_IDENTITY();
        
        -- Create document lines
        INSERT INTO document.document_line (
            document_id, line_number, product_id, description, quantity, 
            unit_price, tax_rate, line_total
        )
        SELECT 
            @document_id, line_number, product_id, description, quantity,
            unit_price, tax_rate, quantity * unit_price * (1 + tax_rate / 100)
        FROM @items;
        
        -- Create transaction record
        INSERT INTO transaction_log.transaction (
            transaction_number, transaction_type_id, document_id, party_id, amount, created_by
        )
        SELECT 
            'TRX-' + CAST(@document_id AS NVARCHAR(20)),
            transaction_type_id,
            @document_id,
            @party_id,
            @total_amount,
            @created_by
        FROM transaction_log.transaction_type
        WHERE type_code = 'SALES';
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Get trial balance
GO
CREATE OR ALTER PROCEDURE accounting.sp_trial_balance
    @as_of_date DATE,
    @company_id INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        a.account_code,
        a.account_name,
        a.account_type,
        SUM(CASE WHEN jel.debit_amount > 0 THEN jel.debit_amount ELSE 0 END) AS total_debit,
        SUM(CASE WHEN jel.credit_amount > 0 THEN jel.credit_amount ELSE 0 END) AS total_credit,
        SUM(CASE 
            WHEN a.normal_balance = 'Debit' THEN jel.debit_amount - jel.credit_amount
            ELSE jel.credit_amount - jel.debit_amount
        END) AS balance
    FROM accounting.account a
    LEFT JOIN accounting.journal_entry_line jel ON a.account_id = jel.account_id
    LEFT JOIN accounting.journal_entry je ON jel.journal_entry_id = je.journal_entry_id
    WHERE je.entry_date <= @as_of_date
    AND je.status = 'Posted'
    GROUP BY a.account_code, a.account_name, a.account_type
    ORDER BY a.account_code;
END;
GO

-- Close fiscal period
GO
CREATE OR ALTER PROCEDURE master.sp_close_fiscal_period
    @company_id INT,
    @fiscal_year INT,
    @period_number INT,
    @closed_by INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        UPDATE master.fiscal_period
        SET is_closed = 1,
            closed_at = GETUTCDATE(),
            closed_by = @closed_by
        WHERE company_id = @company_id
        AND fiscal_year = @fiscal_year
        AND period_number = @period_number;
        
        -- Create closing entries (retained earnings)
        DECLARE @closing_entry_id INT;
        
        -- This would transfer net income to retained earnings
        -- Simplified version
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO
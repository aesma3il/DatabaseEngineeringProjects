-- =====================================================
-- USER-DEFINED TABLE TYPES FOR STORED PROCEDURES
-- =====================================================

-- For journal entry lines
CREATE TYPE accounting.JournalEntryLineType AS TABLE (
    line_number INT,
    account_id INT,
    debit_amount DECIMAL(19,4),
    credit_amount DECIMAL(19,4),
    description NVARCHAR(500)
);
GO

-- For document line items
CREATE TYPE document.DocumentLineItemType AS TABLE (
    line_number INT,
    product_id INT,
    description NVARCHAR(500),
    quantity DECIMAL(18,4),
    unit_price DECIMAL(19,4),
    tax_rate DECIMAL(5,2)
);
GO

-- For bulk inventory updates
CREATE TYPE inventory.InventoryMovementType AS TABLE (
    product_id INT,
    quantity DECIMAL(18,4),
    location_code NVARCHAR(50),
    movement_type NVARCHAR(20)
);
GO

-- For bulk price updates
CREATE TYPE pricing.PriceUpdateType AS TABLE (
    product_id INT,
    new_price DECIMAL(19,4),
    effective_date DATE
);
GO
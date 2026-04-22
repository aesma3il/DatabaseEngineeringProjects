-- =====================================================
-- INITIAL DATA SETUP FOR THE SYSTEM
-- =====================================================

-- Insert default company
INSERT INTO master.company (company_code, company_name, legal_name, tax_id, fiscal_year_start, is_active)
VALUES ('COMP001', 'Main Company', 'Main Company LLC', 'TAX123456789', '2024-01-01', 1);
GO

-- Insert default branches
INSERT INTO master.branch (company_id, branch_code, branch_name, city, is_head_office, is_active)
VALUES 
    (1, 'HQ', 'Headquarters', 'New York', 1, 1),
    (1, 'BR001', 'Downtown Branch', 'New York', 0, 1),
    (1, 'BR002', 'Westside Branch', 'Los Angeles', 0, 1);
GO

-- Insert currencies
INSERT INTO master.currency (currency_code, currency_name, currency_symbol, decimal_places, is_base_currency, exchange_rate_to_base, is_active)
VALUES 
    ('USD', 'US Dollar', '$', 2, 1, 1.000000, 1),
    ('EUR', 'Euro', '€', 2, 0, 0.850000, 1),
    ('GBP', 'British Pound', '£', 2, 0, 0.730000, 1);
GO

-- Insert chart of accounts (simplified)
INSERT INTO accounting.account (account_code, account_name, account_type, normal_balance, parent_account_id, is_active)
VALUES
    -- Assets
    ('1000', 'Assets', 'Asset', 'Debit', NULL, 1),
    ('1100', 'Current Assets', 'Asset', 'Debit', 1, 1),
    ('1110', 'Cash', 'Asset', 'Debit', 2, 1),
    ('1120', 'Accounts Receivable', 'Asset', 'Debit', 2, 1),
    ('1130', 'Inventory', 'Asset', 'Debit', 2, 1),
    ('1200', 'Fixed Assets', 'Asset', 'Debit', 1, 1),
    ('1210', 'Equipment', 'Asset', 'Debit', 6, 1),
    
    -- Liabilities
    ('2000', 'Liabilities', 'Liability', 'Credit', NULL, 1),
    ('2100', 'Current Liabilities', 'Liability', 'Credit', 8, 1),
    ('2110', 'Accounts Payable', 'Liability', 'Credit', 9, 1),
    ('2120', 'Tax Payable', 'Liability', 'Credit', 9, 1),
    
    -- Equity
    ('3000', 'Equity', 'Equity', 'Credit', NULL, 1),
    ('3100', 'Owner''s Equity', 'Equity', 'Credit', 12, 1),
    ('3200', 'Retained Earnings', 'Equity', 'Credit', 12, 1),
    
    -- Revenue
    ('4000', 'Revenue', 'Revenue', 'Credit', NULL, 1),
    ('4100', 'Sales Revenue', 'Revenue', 'Credit', 15, 1),
    ('4200', 'Service Revenue', 'Revenue', 'Credit', 15, 1),
    
    -- Expenses
    ('5000', 'Expenses', 'Expense', 'Debit', NULL, 1),
    ('5100', 'Cost of Goods Sold', 'Expense', 'Debit', 18, 1),
    ('5200', 'Operating Expenses', 'Expense', 'Debit', 18, 1),
    ('5210', 'Rent Expense', 'Expense', 'Debit', 20, 1),
    ('5220', 'Utilities Expense', 'Expense', 'Debit', 20, 1),
    ('5230', 'Salaries Expense', 'Expense', 'Debit', 20, 1);
GO

-- Insert document types
INSERT INTO document.document_type (type_code, type_name, has_inventory_impact, has_accounting_impact, number_prefix, next_number)
VALUES
    ('INV', 'Sales Invoice', 1, 1, 'INV-', 1000),
    ('PO', 'Purchase Order', 1, 1, 'PO-', 1000),
    ('RCT', 'Receipt', 0, 1, 'RCT-', 1000),
    ('CN', 'Credit Note', 1, 1, 'CN-', 1000);
GO

-- Insert transaction types
INSERT INTO transaction_log.transaction_type (type_code, type_name, has_accounting_impact, has_inventory_impact)
VALUES
    ('SALES', 'Sales Transaction', 1, 1),
    ('PURCHASE', 'Purchase Transaction', 1, 1),
    ('PAYMENT', 'Payment Transaction', 1, 0),
    ('RECEIPT', 'Receipt Transaction', 1, 0),
    ('ADJUSTMENT', 'Inventory Adjustment', 1, 1);
GO

-- Insert inventory movement types
INSERT INTO inventory.inventory_movement_type (type_code, type_name, movement_direction)
VALUES
    ('RECEIPT', 'Goods Receipt', 'In'),
    ('ISSUE', 'Goods Issue', 'Out'),
    ('TRANSFER', 'Stock Transfer', 'Transfer'),
    ('ADJUST_IN', 'Stock Adjustment In', 'In'),
    ('ADJUST_OUT', 'Stock Adjustment Out', 'Out');
GO

-- Insert categories
INSERT INTO catalog.category (category_code, category_name, parent_category_id, is_active)
VALUES
    ('ELEC', 'Electronics', NULL, 1),
    ('COMP', 'Computers', 1, 1),
    ('PHONE', 'Phones', 1, 1),
    ('CLOTH', 'Clothing', NULL, 1),
    ('MENS', 'Men''s Clothing', 4, 1),
    ('WOMENS', 'Women''s Clothing', 4, 1);
GO

-- Insert units of measure
INSERT INTO catalog.unit_of_measure (uom_code, uom_name, uom_type)
VALUES
    ('PCS', 'Pieces', 'Quantity'),
    ('KG', 'Kilogram', 'Weight'),
    ('M', 'Meter', 'Length'),
    ('L', 'Liter', 'Volume');
GO

-- Insert security roles
INSERT INTO security.role (role_code, role_name, description)
VALUES
    ('SYS_ADMIN', 'System Administrator', 'Full system access'),
    ('ACC_MGR', 'Accounting Manager', 'Manage accounting operations'),
    ('ACC_CLERK', 'Accounting Clerk', 'Create journal entries'),
    ('INV_MGR', 'Inventory Manager', 'Manage inventory'),
    ('INV_CLERK', 'Inventory Clerk', 'Record inventory movements'),
    ('SALES_REP', 'Sales Representative', 'Create sales documents'),
    ('CASHIER', 'Cashier', 'Handle cash transactions'),
    ('AUDITOR', 'Auditor', 'View-only access for auditing');
GO

-- Insert permissions
INSERT INTO security.permission (permission_code, resource, action)
VALUES
    ('CREATE_JOURNAL', 'journal_entry', 'create'),
    ('POST_JOURNAL', 'journal_entry', 'post'),
    ('APPROVE_JOURNAL', 'journal_entry', 'approve'),
    ('CREATE_INVOICE', 'document', 'create_invoice'),
    ('POST_INVOICE', 'document', 'post'),
    ('RECEIVE_PAYMENT', 'cash', 'receive'),
    ('MAKE_PAYMENT', 'cash', 'make'),
    ('ADJUST_STOCK', 'inventory', 'adjust'),
    ('VIEW_REPORTS', 'report', 'view'),
    ('MANAGE_USERS', 'security', 'manage');
GO

-- Assign permissions to roles
INSERT INTO security.role_permission (role_id, permission_id)
SELECT r.role_id, p.permission_id
FROM security.role r
CROSS JOIN security.permission p
WHERE 
    (r.role_code = 'SYS_ADMIN') OR
    (r.role_code = 'ACC_MGR' AND p.permission_code IN ('CREATE_JOURNAL', 'POST_JOURNAL', 'APPROVE_JOURNAL', 'VIEW_REPORTS')) OR
    (r.role_code = 'ACC_CLERK' AND p.permission_code IN ('CREATE_JOURNAL', 'VIEW_REPORTS')) OR
    (r.role_code = 'INV_MGR' AND p.permission_code IN ('ADJUST_STOCK', 'VIEW_REPORTS')) OR
    (r.role_code = 'SALES_REP' AND p.permission_code IN ('CREATE_INVOICE', 'VIEW_REPORTS')) OR
    (r.role_code = 'CASHIER' AND p.permission_code IN ('RECEIVE_PAYMENT', 'MAKE_PAYMENT')) OR
    (r.role_code = 'AUDITOR' AND p.permission_code IN ('VIEW_REPORTS'));
GO

-- Insert sample parties (customers/suppliers)
INSERT INTO party.party (party_code, party_name, legal_name, tax_id, email, phone, city, is_active)
VALUES
    ('CUST001', 'ABC Corporation', 'ABC Corp Ltd', 'TAX001', 'contact@abccorp.com', '123-456-7890', 'New York', 1),
    ('CUST002', 'XYZ Industries', 'XYZ Industries Inc', 'TAX002', 'info@xyz.com', '098-765-4321', 'Los Angeles', 1),
    ('SUPP001', 'Tech Supplies Co', 'Tech Supplies Ltd', 'TAX003', 'sales@techsupplies.com', '555-123-4567', 'Chicago', 1),
    ('SUPP002', 'Fashion Wholesale', 'Fashion Wholesale LLC', 'TAX004', 'orders@fashionwholesale.com', '555-987-6543', 'Miami', 1);
GO

-- Assign roles to parties
INSERT INTO party.party_role_assignment (party_id, party_role_id, assigned_from, is_primary)
SELECT p.party_id, pr.party_role_id, GETDATE(), 1
FROM party.party p
CROSS JOIN party.party_role pr
WHERE 
    (p.party_code LIKE 'CUST%' AND pr.role_name = 'Customer') OR
    (p.party_code LIKE 'SUPP%' AND pr.role_name = 'Supplier');
GO

-- Insert sample products
INSERT INTO catalog.product (product_code, product_name, description, category_id, base_uom_id, is_active, is_stockable)
VALUES
    ('LAPTOP001', 'Business Laptop', 'High-performance laptop for business', 
     (SELECT category_id FROM catalog.category WHERE category_code = 'COMP'), 
     (SELECT uom_id FROM catalog.unit_of_measure WHERE uom_code = 'PCS'), 1, 1),
    ('PHONE001', 'Smartphone Pro', 'Latest model smartphone', 
     (SELECT category_id FROM catalog.category WHERE category_code = 'PHONE'), 
     (SELECT uom_id FROM catalog.unit_of_measure WHERE uom_code = 'PCS'), 1, 1),
    ('SHIRT001', 'Cotton Dress Shirt', 'Premium cotton dress shirt', 
     (SELECT category_id FROM catalog.category WHERE category_code = 'MENS'), 
     (SELECT uom_id FROM catalog.unit_of_measure WHERE uom_code = 'PCS'), 1, 1);
GO

-- Insert product variants
INSERT INTO catalog.product_variant (product_id, variant_code, variant_name, sku, attributes)
VALUES
    (1, '8GB256', '8GB RAM, 256GB SSD', 'LAP-8-256', '{"ram": "8GB", "storage": "256GB"}'),
    (1, '16GB512', '16GB RAM, 512GB SSD', 'LAP-16-512', '{"ram": "16GB", "storage": "512GB"}'),
    (2, 'BLK128', 'Black, 128GB', 'PHN-BLK-128', '{"color": "Black", "storage": "128GB"}'),
    (2, 'SLV256', 'Silver, 256GB', 'PHN-SLV-256', '{"color": "Silver", "storage": "256GB"}');
GO

-- Insert inventory locations
INSERT INTO inventory.location (branch_id, location_code, location_name, is_active)
SELECT branch_id, 'MAIN', 'Main Warehouse', 1
FROM master.branch;
GO

-- Insert price rules
INSERT INTO pricing.price_rule (rule_code, rule_name, product_id, discount_percent, priority, start_date, is_active)
VALUES
    ('DISC10', '10% Discount on Laptops', 1, 10.00, 1, GETDATE(), 1),
    ('DISC5', '5% Discount on Phones', 2, 5.00, 2, GETDATE(), 1);
GO

-- Insert system users (passwords would be hashed in production)
INSERT INTO security.[user] (party_id, username, email, password_hash, is_active)
SELECT party_id, LOWER(party_code), email, 'hash_placeholder', 1
FROM party.party
WHERE party_code IN ('CUST001', 'CUST002');
GO

-- Assign roles to users
INSERT INTO security.user_role (user_id, role_id)
SELECT u.user_id, r.role_id
FROM security.[user] u
CROSS JOIN security.role r
WHERE 
    (u.username = 'cust001' AND r.role_code = 'SALES_REP') OR
    (u.username = 'cust002' AND r.role_code = 'SALES_REP');
GO

-- Insert sample fiscal periods
DECLARE @year INT = 2024;
DECLARE @month INT = 1;

WHILE @month <= 12
BEGIN
    INSERT INTO master.fiscal_period (company_id, fiscal_year, period_number, period_name, start_date, end_date, is_closed)
    VALUES (
        1, @year, @month, 
        DATENAME(MONTH, DATEFROMPARTS(@year, @month, 1)),
        DATEFROMPARTS(@year, @month, 1),
        EOMONTH(DATEFROMPARTS(@year, @month, 1)),
        0
    );
    SET @month = @month + 1;
END;
GO

-- Insert default settings
INSERT INTO master.settings (setting_key, setting_value, setting_group, data_type, description)
VALUES
    ('SYSTEM_NAME', 'Complete Accounting System', 'General', 'String', 'Name of the system'),
    ('SYSTEM_VERSION', '1.0.0', 'General', 'String', 'System version'),
    ('DEFAULT_LOCALE', 'en-US', 'General', 'String', 'Default locale'),
    ('INVOICE_DUE_DAYS', '30', 'Document', 'Integer', 'Default invoice due days'),
    ('TAX_ROUNDING', 'HALF_UP', 'Tax', 'String', 'Tax rounding method');
GO

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Verify all schemas exist
SELECT name FROM sys.schemas ORDER BY name;
GO

-- Verify table counts per schema
SELECT 
    SCHEMA_NAME(schema_id) AS schema_name,
    COUNT(*) AS table_count
FROM sys.tables
GROUP BY SCHEMA_NAME(schema_id)
ORDER BY schema_name;
GO

-- Verify all permissions are applied
SELECT 
    class_desc,
    permission_name,
    state_desc,
    OBJECT_NAME(major_id) AS object_name,
    USER_NAME(grantee_principal_id) AS grantee
FROM sys.database_permissions
WHERE state_desc IN ('GRANT', 'GRANT_WITH_GRANT')
ORDER BY grantee, permission_name;
GO
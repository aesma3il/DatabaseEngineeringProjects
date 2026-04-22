-- =====================================================
-- BUSINESS VIEWS
-- =====================================================

-- Account Balance View
GO
CREATE OR ALTER VIEW accounting.vw_account_balance AS
WITH AccountBalance AS (
    SELECT 
        a.account_id,
        a.account_code,
        a.account_name,
        a.account_type,
        a.parent_account_id,
        SUM(CASE 
            WHEN je.status = 'Posted' AND jel.debit_amount > 0 THEN jel.debit_amount
            ELSE 0 
        END) AS total_debits,
        SUM(CASE 
            WHEN je.status = 'Posted' AND jel.credit_amount > 0 THEN jel.credit_amount
            ELSE 0 
        END) AS total_credits
    FROM accounting.account a
    LEFT JOIN accounting.journal_entry_line jel ON a.account_id = jel.account_id
    LEFT JOIN accounting.journal_entry je ON jel.journal_entry_id = je.journal_entry_id
    GROUP BY a.account_id, a.account_code, a.account_name, a.account_type, a.parent_account_id
)
SELECT 
    account_id,
    account_code,
    account_name,
    account_type,
    total_debits,
    total_credits,
    CASE 
        WHEN account_type IN ('Asset', 'Expense') THEN total_debits - total_credits
        ELSE total_credits - total_debits
    END AS current_balance
FROM AccountBalance;
GO

-- Stock Level View
GO
CREATE OR ALTER VIEW inventory.vw_current_stock AS
SELECT 
    p.product_code,
    p.product_name,
    l.location_code,
    l.location_name,
    cs.quantity_on_hand,
    cs.average_cost,
    cs.quantity_on_hand * cs.average_cost AS stock_value
FROM inventory.current_stock cs
INNER JOIN catalog.product p ON cs.product_id = p.product_id
INNER JOIN inventory.location l ON cs.location_id = l.location_id;
GO

-- Customer Statement View
GO
CREATE OR ALTER VIEW party.vw_customer_statement AS
SELECT 
    p.party_code,
    p.party_name,
    d.document_number,
    d.document_date,
    d.total_amount,
    CASE WHEN d.document_type_id IN (1, 2) THEN d.total_amount ELSE 0 END AS debit,
    CASE WHEN d.document_type_id IN (3, 4) THEN d.total_amount ELSE 0 END AS credit,
    SUM(CASE WHEN d.document_type_id IN (1, 2) THEN d.total_amount ELSE -d.total_amount END) 
        OVER (PARTITION BY p.party_id ORDER BY d.document_date) AS running_balance
FROM party.party p
INNER JOIN document.document d ON p.party_id = d.party_id
WHERE p.party_id IN (SELECT party_id FROM party.party_role_assignment WHERE party_role_id = 1) -- Customer role
AND d.status = 'Posted';
GO

-- Document Summary View
GO
CREATE OR ALTER VIEW document.vw_document_summary AS
SELECT 
    dt.type_code,
    dt.type_name,
    COUNT(DISTINCT d.document_id) AS document_count,
    SUM(d.subtotal) AS total_subtotal,
    SUM(d.tax_amount) AS total_tax,
    SUM(d.discount_amount) AS total_discount,
    SUM(d.total_amount) AS total_amount,
    COUNT(DISTINCT d.party_id) AS unique_customers
FROM document.document d
INNER JOIN document.document_type dt ON d.document_type_id = dt.document_type_id
WHERE d.status = 'Posted'
GROUP BY dt.type_code, dt.type_name;
GO

-- Daily Sales View
GO
CREATE OR ALTER VIEW cash.vw_daily_sales AS
SELECT 
    CAST(transaction_time AS DATE) AS sale_date,
    branch_id,
    COUNT(*) AS transaction_count,
    SUM(amount) AS total_sales,
    AVG(amount) AS average_transaction
FROM cash.cash_transaction ct
INNER JOIN cash.shift s ON ct.shift_id = s.shift_id
WHERE transaction_type = 'Sale'
GROUP BY CAST(transaction_time AS DATE), branch_id;
GO

-- Aging Receivables View
GO
CREATE OR ALTER VIEW accounting.vw_aging_receivables AS
WITH AgedData AS (
    SELECT 
        p.party_id,
        p.party_name,
        d.document_number,
        d.document_date,
        d.total_amount,
        DATEDIFF(DAY, d.document_date, GETDATE()) AS days_outstanding
    FROM document.document d
    INNER JOIN party.party p ON d.party_id = p.party_id
    WHERE d.document_type_id = 1 -- Invoice type
    AND d.status = 'Posted'
    AND d.total_amount > 0
)
SELECT 
    party_id,
    party_name,
    SUM(CASE WHEN days_outstanding <= 30 THEN total_amount ELSE 0 END) AS current_30,
    SUM(CASE WHEN days_outstanding BETWEEN 31 AND 60 THEN total_amount ELSE 0 END) AS days_31_60,
    SUM(CASE WHEN days_outstanding BETWEEN 61 AND 90 THEN total_amount ELSE 0 END) AS days_61_90,
    SUM(CASE WHEN days_outstanding > 90 THEN total_amount ELSE 0 END) AS overdue_90_plus,
    SUM(total_amount) AS total_receivable
FROM AgedData
GROUP BY party_id, party_name;
GO

-- Product Performance View
GO
CREATE OR ALTER VIEW catalog.vw_product_performance AS
SELECT 
    p.product_code,
    p.product_name,
    c.category_name,
    b.brand_name,
    COUNT(DISTINCT dl.document_line_id) AS times_sold,
    SUM(dl.quantity) AS total_quantity_sold,
    SUM(dl.line_total) AS total_revenue,
    AVG(dl.unit_price) AS average_selling_price,
    ISNULL(SUM(cs.quantity_on_hand), 0) AS current_stock
FROM catalog.product p
LEFT JOIN catalog.category c ON p.category_id = c.category_id
LEFT JOIN catalog.brand b ON p.brand_id = b.brand_id
LEFT JOIN document.document_line dl ON p.product_id = dl.product_id
LEFT JOIN document.document d ON dl.document_id = d.document_id AND d.status = 'Posted'
LEFT JOIN inventory.current_stock cs ON p.product_id = cs.product_id
GROUP BY p.product_code, p.product_name, c.category_name, b.brand_name;
GO

-- Audit Trail View
GO
CREATE OR ALTER VIEW security.vw_audit_trail AS
SELECT 
    al.activity_log_id,
    u.username,
    al.action,
    al.entity_type,
    al.entity_id,
    al.created_at,
    al.ip_address,
    ROW_NUMBER() OVER (PARTITION BY al.entity_type, al.entity_id ORDER BY al.created_at DESC) AS revision_number
FROM security.activity_log al
LEFT JOIN security.[user] u ON al.user_id = u.user_id;
GO

-- Comprehensive Financial Report
GO
CREATE OR ALTER VIEW accounting.vw_financial_summary AS
SELECT 
    'Balance Sheet' AS report_type,
    'Assets' AS section,
    account_code,
    account_name,
    current_balance
FROM accounting.vw_account_balance
WHERE account_type = 'Asset'
UNION ALL
SELECT 
    'Balance Sheet',
    'Liabilities',
    account_code,
    account_name,
    current_balance
FROM accounting.vw_account_balance
WHERE account_type = 'Liability'
UNION ALL
SELECT 
    'Balance Sheet',
    'Equity',
    account_code,
    account_name,
    current_balance
FROM accounting.vw_account_balance
WHERE account_type = 'Equity'
UNION ALL
SELECT 
    'Income Statement',
    'Revenue',
    account_code,
    account_name,
    current_balance
FROM accounting.vw_account_balance
WHERE account_type = 'Revenue'
UNION ALL
SELECT 
    'Income Statement',
    'Expenses',
    account_code,
    account_name,
    current_balance
FROM accounting.vw_account_balance
WHERE account_type = 'Expense';
GO
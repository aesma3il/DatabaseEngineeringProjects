-- =====================================================
-- DATABASE USERS, LOGINS, AND PERMISSIONS
-- =====================================================

-- =====================================================
-- PART 1: CREATE SERVER LOGINS (Run in master database)
-- =====================================================

/*
-- These statements should be executed in master database
-- Uncomment and modify as needed for your environment

-- Create server logins
CREATE LOGIN accounting_admin WITH PASSWORD = 'StrongP@ssw0rd!', CHECK_POLICY = ON;
CREATE LOGIN accounting_manager WITH PASSWORD = 'ManagerP@ss123!', CHECK_POLICY = ON;
CREATE LOGIN accounting_clerk WITH PASSWORD = 'ClerkP@ss456!', CHECK_POLICY = ON;
CREATE LOGIN inventory_manager WITH PASSWORD = 'InventoryP@ss789!', CHECK_POLICY = ON;
CREATE LOGIN inventory_clerk WITH PASSWORD = 'InventoryClerk123!', CHECK_POLICY = ON;
CREATE LOGIN sales_rep WITH PASSWORD = 'SalesRep456!', CHECK_POLICY = ON;
CREATE LOGIN cashier WITH PASSWORD = 'Cashier789!', CHECK_POLICY = ON;
CREATE LOGIN auditor WITH PASSWORD = 'Auditor123!', CHECK_POLICY = ON;
CREATE LOGIN readonly_user WITH PASSWORD = 'Readonly456!', CHECK_POLICY = ON;
CREATE LOGIN api_user WITH PASSWORD = 'ApiUser789!', CHECK_POLICY = ON;

-- Create Windows Authentication logins (if using Active Directory)
-- CREATE LOGIN [DOMAIN\AccountingGroup] FROM WINDOWS;
-- CREATE LOGIN [DOMAIN\JohnSmith] FROM WINDOWS;
*/

-- =====================================================
-- PART 2: CREATE DATABASE USERS (Run in your database)
-- =====================================================

-- Use the accounting database
USE AccountingDB; -- Replace with your actual database name
GO

-- Create database users mapped to server logins
CREATE USER accounting_admin FOR LOGIN accounting_admin;
CREATE USER accounting_manager FOR LOGIN accounting_manager;
CREATE USER accounting_clerk FOR LOGIN accounting_clerk;
CREATE USER inventory_manager FOR LOGIN inventory_manager;
CREATE USER inventory_clerk FOR LOGIN inventory_clerk;
CREATE USER sales_rep FOR LOGIN sales_rep;
CREATE USER cashier FOR LOGIN cashier;
CREATE USER auditor FOR LOGIN auditor;
CREATE USER readonly_user FOR LOGIN readonly_user;
CREATE USER api_user FOR LOGIN api_user;
GO

-- Create database roles (if using contained database authentication)
-- CREATE USER accounting_admin WITH PASSWORD = 'StrongP@ssw0rd!';
-- CREATE USER accounting_manager WITH PASSWORD = 'ManagerP@ss123!';

-- =====================================================
-- PART 3: CREATE DATABASE ROLES FOR PERMISSION MANAGEMENT
-- =====================================================

-- Application roles (database-level)
CREATE ROLE app_accounting_admin;
CREATE ROLE app_accounting_manager;
CREATE ROLE app_accounting_clerk;
CREATE ROLE app_inventory_manager;
CREATE ROLE app_inventory_clerk;
CREATE ROLE app_sales_rep;
CREATE ROLE app_cashier;
CREATE ROLE app_auditor;
CREATE ROLE app_readonly;
CREATE ROLE app_api;
GO

-- Add users to roles
ALTER ROLE app_accounting_admin ADD MEMBER accounting_admin;
ALTER ROLE app_accounting_manager ADD MEMBER accounting_manager;
ALTER ROLE app_accounting_clerk ADD MEMBER accounting_clerk;
ALTER ROLE app_inventory_manager ADD MEMBER inventory_manager;
ALTER ROLE app_inventory_clerk ADD MEMBER inventory_clerk;
ALTER ROLE app_sales_rep ADD MEMBER sales_rep;
ALTER ROLE app_cashier ADD MEMBER cashier;
ALTER ROLE app_auditor ADD MEMBER auditor;
ALTER ROLE app_readonly ADD MEMBER readonly_user;
ALTER ROLE app_api ADD MEMBER api_user;
GO

-- =====================================================
-- PART 4: SCHEMA-LEVEL PERMISSIONS
-- =====================================================

-- Grant schema permissions to roles
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::accounting TO app_accounting_admin;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::accounting TO app_accounting_manager;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::accounting TO app_accounting_clerk;
GRANT SELECT ON SCHEMA::accounting TO app_auditor;
GRANT SELECT ON SCHEMA::accounting TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::inventory TO app_inventory_manager;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::inventory TO app_inventory_clerk;
GRANT SELECT ON SCHEMA::inventory TO app_auditor;
GRANT SELECT ON SCHEMA::inventory TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::document TO app_accounting_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::document TO app_accounting_manager;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::document TO app_accounting_clerk;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::document TO app_sales_rep;
GRANT SELECT ON SCHEMA::document TO app_auditor;
GRANT SELECT ON SCHEMA::document TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::party TO app_accounting_admin;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::party TO app_accounting_manager;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::party TO app_sales_rep;
GRANT SELECT ON SCHEMA::party TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::catalog TO app_inventory_manager;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::catalog TO app_inventory_clerk;
GRANT SELECT ON SCHEMA::catalog TO app_sales_rep;
GRANT SELECT ON SCHEMA::catalog TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::cash TO app_cashier;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::cash TO app_accounting_manager;
GRANT SELECT ON SCHEMA::cash TO app_auditor;
GRANT SELECT ON SCHEMA::cash TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::pricing TO app_accounting_manager;
GRANT SELECT ON SCHEMA::pricing TO app_sales_rep;
GRANT SELECT ON SCHEMA::pricing TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::security TO app_accounting_admin;
GRANT SELECT ON SCHEMA::security TO app_auditor;
GRANT SELECT ON SCHEMA::security TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::transaction_log TO app_accounting_admin;
GRANT SELECT ON SCHEMA::transaction_log TO app_auditor;
GRANT SELECT ON SCHEMA::transaction_log TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::attachment TO app_accounting_admin;
GRANT SELECT, INSERT, UPDATE ON SCHEMA::attachment TO app_accounting_manager;
GRANT SELECT ON SCHEMA::attachment TO app_readonly;

GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::master TO app_accounting_admin;
GRANT SELECT ON SCHEMA::master TO app_readonly;
GRANT SELECT ON SCHEMA::master TO app_accounting_manager;

-- =====================================================
-- PART 5: TABLE-LEVEL SPECIFIC PERMISSIONS (Fine-grained)
-- =====================================================

-- Accounting: Only managers and admins can post journal entries
GRANT UPDATE ON accounting.journal_entry TO app_accounting_manager;
DENY UPDATE ON accounting.journal_entry TO app_accounting_clerk;

-- Allow clerks to insert but not update status
GRANT INSERT ON accounting.journal_entry TO app_accounting_clerk;
GRANT INSERT ON accounting.journal_entry_line TO app_accounting_clerk;

-- Inventory: Stock adjustments require manager approval
GRANT UPDATE ON inventory.current_stock TO app_inventory_manager;
DENY UPDATE ON inventory.current_stock TO app_inventory_clerk;

-- Documents: Sales reps can create drafts but not post
GRANT INSERT, UPDATE ON document.document TO app_sales_rep;
DENY UPDATE ON document.document(document_status) TO app_sales_rep;

-- Cash: Cashiers can only insert, not update or delete
GRANT INSERT ON cash.cash_transaction TO app_cashier;
DENY UPDATE, DELETE ON cash.cash_transaction TO app_cashier;

-- Security: Only admins can modify user permissions
GRANT SELECT ON security.user TO app_accounting_manager;
DENY INSERT, UPDATE, DELETE ON security.user TO app_accounting_manager;
GRANT ALL ON security.user TO app_accounting_admin;

-- =====================================================
-- PART 6: COLUMN-LEVEL PERMISSIONS (Sensitive data)
-- =====================================================

-- Hide salary information from regular employees
DENY SELECT ON security.[user](password_hash) TO app_readonly;
DENY SELECT ON security.[user](password_hash) TO app_accounting_clerk;
GRANT SELECT ON security.[user](password_hash) TO app_accounting_admin;

-- Hide cost information from sales reps
DENY SELECT ON catalog.product(cost_price) TO app_sales_rep;
GRANT SELECT ON catalog.product(product_code, product_name, selling_price) TO app_sales_rep;

-- Hide sensitive party information
DENY SELECT ON party.party(tax_id, bank_account) TO app_sales_rep;
DENY SELECT ON party.party(tax_id, bank_account) TO app_readonly;

-- =====================================================
-- PART 7: PROCEDURE EXECUTION PERMISSIONS
-- =====================================================

-- Grant execute permissions on stored procedures
GRANT EXECUTE ON accounting.sp_create_journal_entry TO app_accounting_clerk;
GRANT EXECUTE ON accounting.sp_post_journal_entry TO app_accounting_manager;
GRANT EXECUTE ON accounting.sp_trial_balance TO app_accounting_clerk, app_auditor, app_readonly;

GRANT EXECUTE ON inventory.sp_record_movement TO app_inventory_clerk;
GRANT EXECUTE ON inventory.sp_adjust_stock TO app_inventory_manager;

GRANT EXECUTE ON document.sp_create_sales_document TO app_sales_rep;
GRANT EXECUTE ON document.sp_approve_document TO app_accounting_manager;

GRANT EXECUTE ON pricing.sp_calculate_price TO app_sales_rep, app_cashier;

GRANT EXECUTE ON cash.sp_open_shift TO app_cashier;
GRANT EXECUTE ON cash.sp_close_shift TO app_cashier, app_accounting_manager;

-- =====================================================
-- PART 8: VIEW PERMISSIONS
-- =====================================================

-- Grant access to views
GRANT SELECT ON accounting.vw_account_balance TO app_accounting_clerk, app_auditor, app_readonly;
GRANT SELECT ON accounting.vw_financial_summary TO app_accounting_manager, app_auditor;
GRANT SELECT ON accounting.vw_aging_receivables TO app_accounting_clerk, app_auditor;

GRANT SELECT ON inventory.vw_current_stock TO app_inventory_clerk, app_sales_rep, app_readonly;

GRANT SELECT ON document.vw_document_summary TO app_accounting_clerk, app_auditor;

GRANT SELECT ON party.vw_customer_statement TO app_sales_rep, app_accounting_clerk;

GRANT SELECT ON catalog.vw_product_performance TO app_inventory_manager, app_auditor;

GRANT SELECT ON cash.vw_daily_sales TO app_accounting_manager, app_auditor;

-- =====================================================
-- PART 9: APPLICATION ROLES FOR SPECIFIC FUNCTIONS
-- =====================================================

-- Create application-specific roles
CREATE ROLE app_payroll_processor;
CREATE ROLE app_tax_accountant;
CREATE ROLE app_bank_reconciler;
CREATE ROLE app_procurement_officer;
GO

-- Grant permissions for specific functions
GRANT SELECT, INSERT, UPDATE ON accounting.journal_entry TO app_payroll_processor;
GRANT SELECT ON party.party(employee_records) TO app_payroll_processor;

GRANT SELECT ON accounting.account TO app_tax_accountant;
GRANT SELECT ON document.document(tax_details) TO app_tax_accountant;

GRANT SELECT, UPDATE ON cash.cash_transaction TO app_bank_reconciler;
GRANT SELECT ON master.bank_account TO app_bank_reconciler;

GRANT SELECT, INSERT, UPDATE ON document.document TO app_procurement_officer;
GRANT SELECT ON inventory.current_stock TO app_procurement_officer;

-- =====================================================
-- PART 10: DYNAMIC DATA MASKING (Sensitive data protection)
-- =====================================================

-- Apply dynamic data masking to sensitive columns (SQL Server 2016+)
ALTER TABLE party.party
ALTER COLUMN email ADD MASKED WITH (FUNCTION = 'email()');
GO

ALTER TABLE party.party
ALTER COLUMN phone ADD MASKED WITH (FUNCTION = 'partial(0, "XXX-XXX-", 4)');
GO

ALTER TABLE security.[user]
ALTER COLUMN password_hash ADD MASKED WITH (FUNCTION = 'default()');
GO

-- Grant UNMASK permission to admins and auditors
GRANT UNMASK TO app_accounting_admin;
GRANT UNMASK TO app_auditor;
GO

-- =====================================================
-- PART 11: ROW-LEVEL SECURITY (RLS) - SQL Server 2016+
-- =====================================================

-- Create security policy for branch-level access
GO
CREATE OR ALTER FUNCTION security.fn_branch_access(@branch_id INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
SELECT 1 AS access_result
WHERE 
    -- Admins can see all
    IS_ROLEMEMBER('app_accounting_admin') = 1
    OR
    -- Users can only see their branch
    @branch_id IN (
        SELECT assigned_branch_id 
        FROM security.user_branch_access 
        WHERE user_id = CAST(SESSION_CONTEXT(N'user_id') AS INT)
    );
GO

-- Create security policy on document table
CREATE SECURITY POLICY security.branch_access_policy
ADD FILTER PREDicate security.fn_branch_access(branch_id) ON document.document
WITH (STATE = ON);
GO

-- =====================================================
-- PART 12: REVOKE EXCESSIVE PERMISSIONS (Principle of least privilege)
-- =====================================================

-- Revoke public schema permissions
REVOKE CREATE TABLE FROM PUBLIC;
REVOKE CREATE VIEW FROM PUBLIC;
REVOKE CREATE PROCEDURE FROM PUBLIC;
REVOKE CREATE FUNCTION FROM PUBLIC;

-- Remove unnecessary permissions from roles
REVOKE DELETE ON accounting.journal_entry FROM app_accounting_clerk;
REVOKE DELETE ON accounting.journal_entry_line FROM app_accounting_clerk;
REVOKE DELETE ON inventory.inventory_movement FROM app_inventory_clerk;
REVOKE DELETE ON cash.cash_transaction FROM app_cashier;

-- Deny direct table access, force view usage where possible
DENY SELECT ON accounting.journal_entry TO app_readonly;
GRANT SELECT ON accounting.vw_account_balance TO app_readonly;

-- =====================================================
-- PART 13: AUDIT AND MONITORING PERMISSIONS
-- =====================================================

-- Create role for compliance auditors
CREATE ROLE app_compliance_auditor;
GO

-- Grant audit-specific permissions
GRANT SELECT ON security.activity_log TO app_compliance_auditor;
GRANT SELECT ON sys.sql_logins TO app_compliance_auditor;
GRANT VIEW SERVER STATE TO app_compliance_auditor;
GRANT VIEW DEFINITION TO app_compliance_auditor;
GRANT SELECT ON sys.dm_exec_sessions TO app_compliance_auditor;
GRANT SELECT ON sys.dm_exec_connections TO app_compliance_auditor;

-- =====================================================
-- PART 14: BACKUP AND MAINTENANCE PERMISSIONS
-- =====================================================

-- Create role for database maintenance
CREATE ROLE app_db_maintenance;
GO

-- Grant maintenance permissions
GRANT BACKUP DATABASE TO app_db_maintenance;
GRANT BACKUP LOG TO app_db_maintenance;
GRANT CREATE DATABASE TO app_db_maintenance;
GRANT ALTER ANY DATABASE TO app_db_maintenance;
GRANT VIEW DATABASE STATE TO app_db_maintenance;

-- =====================================================
-- PART 15: API AND INTEGRATION PERMISSIONS
-- =====================================================

-- API user specific permissions (minimal)
GRANT EXECUTE ON accounting.sp_create_journal_entry TO app_api;
GRANT EXECUTE ON inventory.sp_record_movement TO app_api;
GRANT EXECUTE ON document.sp_create_sales_document TO app_api;
GRANT SELECT ON catalog.vw_product_performance TO app_api;
GRANT SELECT ON inventory.vw_current_stock TO app_api;

-- API user cannot modify configuration
DENY INSERT, UPDATE, DELETE ON master.settings TO app_api;
DENY INSERT, UPDATE, DELETE ON security.[user] TO app_api;

-- =====================================================
-- PART 16: TEMPORARY PERMISSIONS (For specific tasks)
-- =====================================================

-- Example: Grant temporary permission for year-end closing
-- GRANT UPDATE ON master.fiscal_period TO app_accounting_clerk;
-- REVOKE UPDATE ON master.fiscal_period FROM app_accounting_clerk;

-- =====================================================
-- PART 17: PERMISSION REPORTING VIEWS
-- =====================================================

-- View to show all user permissions
GO
CREATE OR ALTER VIEW security.vw_user_permissions
AS
SELECT 
    dp.class_desc,
    dp.permission_name,
    dp.state_desc,
    OBJECT_NAME(dp.major_id) AS object_name,
    USER_NAME(grantee_principal_id) AS grantee_name,
    USER_NAME(grantor_principal_id) AS grantor_name
FROM sys.database_permissions dp
WHERE grantee_principal_id > 0;
GO

-- Grant access to permission view
GRANT SELECT ON security.vw_user_permissions TO app_accounting_admin, app_auditor;
GO

-- =====================================================
-- PART 18: PERIODIC PERMISSION REVIEW
-- =====================================================

-- Create stored procedure to review permissions
GO
CREATE OR ALTER PROCEDURE security.sp_review_user_permissions
    @username NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        u.name AS user_name,
        r.name AS role_name,
        p.permission_name,
        p.state_desc,
        o.name AS object_name,
        s.name AS schema_name
    FROM sys.database_principals u
    LEFT JOIN sys.database_role_members rm ON u.principal_id = rm.member_principal_id
    LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    LEFT JOIN sys.database_permissions p ON 
        (p.grantee_principal_id = u.principal_id OR p.grantee_principal_id = r.principal_id)
    LEFT JOIN sys.objects o ON p.major_id = o.object_id
    LEFT JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE u.type IN ('S', 'U') -- SQL and Windows users
    AND (@username IS NULL OR u.name = @username)
    ORDER BY u.name, r.name, p.permission_name;
END;
GO

GRANT EXECUTE ON security.sp_review_user_permissions TO app_accounting_admin, app_auditor;
GO

-- =====================================================
-- PART 19: CLEANUP AND RESET SCRIPTS
-- =====================================================

-- Script to revoke all permissions for a user (for offboarding)
GO
CREATE OR ALTER PROCEDURE security.sp_revoke_all_permissions
    @username NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @sql NVARCHAR(MAX) = '';
    
    -- Revoke database permissions
    SELECT @sql = @sql + 'REVOKE ' + permission_name + ' TO ' + @username + ';'
    FROM sys.database_permissions
    WHERE grantee_principal_id = DATABASE_PRINCIPAL_ID(@username);
    
    -- Revoke schema permissions
    SELECT @sql = @sql + 'REVOKE ' + permission_name + ' ON SCHEMA::' + s.name + ' TO ' + @username + ';'
    FROM sys.database_permissions dp
    INNER JOIN sys.schemas s ON dp.major_id = s.schema_id
    WHERE grantee_principal_id = DATABASE_PRINCIPAL_ID(@username);
    
    -- Drop user from all roles
    SELECT @sql = @sql + 'ALTER ROLE ' + r.name + ' DROP MEMBER ' + @username + ';'
    FROM sys.database_role_members rm
    INNER JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
    WHERE rm.member_principal_id = DATABASE_PRINCIPAL_ID(@username);
    
    EXEC sp_executesql @sql;
END;
GO

GRANT EXECUTE ON security.sp_revoke_all_permissions TO app_accounting_admin;
GO

-- =====================================================
-- PART 20: VERIFICATION QUERIES
-- =====================================================

-- Check effective permissions for current user
SELECT * FROM fn_my_permissions(NULL, 'DATABASE');
GO

-- Check if user has specific permission
SELECT HAS_PERMS_BY_NAME('accounting.journal_entry', 'OBJECT', 'SELECT') AS can_select_journal;
SELECT HAS_PERMS_BY_NAME('accounting.sp_post_journal_entry', 'OBJECT', 'EXECUTE') AS can_execute_post;
GO

-- List all users and their roles
SELECT 
    u.name AS user_name,
    u.type_desc,
    r.name AS role_name
FROM sys.database_principals u
LEFT JOIN sys.database_role_members rm ON u.principal_id = rm.member_principal_id
LEFT JOIN sys.database_principals r ON rm.role_principal_id = r.principal_id
WHERE u.type IN ('S', 'U')
ORDER BY u.name, r.name;
GO
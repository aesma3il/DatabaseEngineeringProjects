 -- =========================================
-- 01_create_database.sql
-- Create Database
-- =========================================
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'AccountingERP')
BEGIN
    CREATE DATABASE AccountingERP;
END
GO

-- =========================================
-- Use Database
-- =========================================
USE AccountingERP;
GO


-- =========================================
-- 00_schemas.sql
-- Create schemas for logical organization
-- =========================================

-- Accounting
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'accounting')
    EXEC('CREATE SCHEMA accounting');
GO

-- Inventory
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'inventory')
    EXEC('CREATE SCHEMA inventory');
GO

-- Master Data
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'master')
    EXEC('CREATE SCHEMA master');
GO

-- Party
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'party')
    EXEC('CREATE SCHEMA party');
GO

-- Attachments
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'attachment')
    EXEC('CREATE SCHEMA attachment');
GO

-- Documents
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'document')
    EXEC('CREATE SCHEMA document');
GO

-- Transactions Log
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'transaction_log')
    EXEC('CREATE SCHEMA transaction_log');
GO

-- Security
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'security')
    EXEC('CREATE SCHEMA security');
GO

-- Catalog
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'catalog')
    EXEC('CREATE SCHEMA catalog');
GO

-- Pricing
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'pricing')
    EXEC('CREATE SCHEMA pricing');
GO

-- Cash Management
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'cash')
    EXEC('CREATE SCHEMA cash');
GO
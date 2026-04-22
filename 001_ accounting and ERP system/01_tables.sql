-- =====================================================
-- MASTER DATA SCHEMA
-- =====================================================

-- Company information
CREATE TABLE master.company (
    company_id INT IDENTITY(1,1) PRIMARY KEY,
    company_code NVARCHAR(20) NOT NULL UNIQUE,
    company_name NVARCHAR(200) NOT NULL,
    legal_name NVARCHAR(200),
    tax_id NVARCHAR(50),
    registration_number NVARCHAR(50),
    address_line1 NVARCHAR(200),
    address_line2 NVARCHAR(200),
    city NVARCHAR(100),
    state_province NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100),
    phone NVARCHAR(50),
    email NVARCHAR(100),
    website NVARCHAR(200),
    fiscal_year_start DATE,
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    modified_at DATETIME2 DEFAULT GETUTCDATE(),
    created_by INT,
    modified_by INT
);

-- Branches
CREATE TABLE master.branch (
    branch_id INT IDENTITY(1,1) PRIMARY KEY,
    company_id INT NOT NULL REFERENCES master.company(company_id),
    branch_code NVARCHAR(20) NOT NULL,
    branch_name NVARCHAR(200) NOT NULL,
    address_line1 NVARCHAR(200),
    address_line2 NVARCHAR(200),
    city NVARCHAR(100),
    state_province NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100),
    phone NVARCHAR(50),
    email NVARCHAR(100),
    is_head_office BIT DEFAULT 0,
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    modified_at DATETIME2 DEFAULT GETUTCDATE(),
    CONSTRAINT UQ_branch_company_code UNIQUE (company_id, branch_code)
);

-- Currencies
CREATE TABLE master.currency (
    currency_id INT IDENTITY(1,1) PRIMARY KEY,
    currency_code NVARCHAR(3) NOT NULL UNIQUE,
    currency_name NVARCHAR(50) NOT NULL,
    currency_symbol NVARCHAR(5),
    decimal_places INT DEFAULT 2,
    is_base_currency BIT DEFAULT 0,
    exchange_rate_to_base DECIMAL(18,6),
    is_active BIT DEFAULT 1
);

-- Fiscal Periods
CREATE TABLE master.fiscal_period (
    fiscal_period_id INT IDENTITY(1,1) PRIMARY KEY,
    company_id INT NOT NULL REFERENCES master.company(company_id),
    fiscal_year INT NOT NULL,
    period_number INT NOT NULL,
    period_name NVARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_closed BIT DEFAULT 0,
    closed_at DATETIME2,
    closed_by INT,
    CONSTRAINT UQ_fiscal_period UNIQUE (company_id, fiscal_year, period_number)
);

-- =====================================================
-- PARTY SCHEMA (Unified Party Model)
-- =====================================================

CREATE TABLE party.party (
    party_id INT IDENTITY(1,1) PRIMARY KEY,
    party_code NVARCHAR(50) NOT NULL UNIQUE,
    party_name NVARCHAR(200) NOT NULL,
    legal_name NVARCHAR(200),
    tax_id NVARCHAR(50),
    email NVARCHAR(100),
    phone NVARCHAR(50),
    mobile NVARCHAR(50),
    website NVARCHAR(200),
    address_line1 NVARCHAR(200),
    address_line2 NVARCHAR(200),
    city NVARCHAR(100),
    state_province NVARCHAR(100),
    postal_code NVARCHAR(20),
    country NVARCHAR(100),
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    modified_at DATETIME2 DEFAULT GETUTCDATE()
);

-- Party Roles
CREATE TABLE party.party_role (
    party_role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name NVARCHAR(50) NOT NULL UNIQUE,
    role_description NVARCHAR(500)
);

-- Party Role Assignment
CREATE TABLE party.party_role_assignment (
    party_id INT NOT NULL REFERENCES party.party(party_id),
    party_role_id INT NOT NULL REFERENCES party.party_role(party_role_id),
    assigned_from DATE,
    assigned_to DATE,
    is_primary BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    CONSTRAINT PK_party_role_assignment PRIMARY KEY (party_id, party_role_id)
);

-- Insert basic roles
INSERT INTO party.party_role (role_name, role_description) VALUES
('Customer', 'Party that purchases goods or services'),
('Supplier', 'Party that provides goods or services'),
('Employee', 'Person employed by the company'),
('Lead', 'Potential customer'),
('Partner', 'Business partner');

-- =====================================================
-- ACCOUNTING SCHEMA
-- =====================================================

-- Chart of Accounts (Hierarchical)
CREATE TABLE accounting.account (
    account_id INT IDENTITY(1,1) PRIMARY KEY,
    parent_account_id INT REFERENCES accounting.account(account_id),
    account_code NVARCHAR(50) NOT NULL,
    account_name NVARCHAR(200) NOT NULL,
    account_type NVARCHAR(20) NOT NULL CHECK (account_type IN ('Asset', 'Liability', 'Equity', 'Revenue', 'Expense')),
    normal_balance NVARCHAR(4) NOT NULL CHECK (normal_balance IN ('Debit', 'Credit')),
    is_active BIT DEFAULT 1,
    is_heading BIT DEFAULT 0,
    opening_balance DECIMAL(19,4) DEFAULT 0,
    opening_balance_date DATE,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    modified_at DATETIME2 DEFAULT GETUTCDATE(),
    CONSTRAINT UQ_account_code UNIQUE (account_code)
);

-- Journal Entry Header
CREATE TABLE accounting.journal_entry (
    journal_entry_id INT IDENTITY(1,1) PRIMARY KEY,
    entry_number NVARCHAR(50) NOT NULL UNIQUE,
    entry_date DATE NOT NULL,
    reference_number NVARCHAR(100),
    description NVARCHAR(500),
    status NVARCHAR(20) DEFAULT 'Draft' CHECK (status IN ('Draft', 'Pending', 'Approved', 'Posted', 'Cancelled')),
    total_debit DECIMAL(19,4) DEFAULT 0,
    total_credit DECIMAL(19,4) DEFAULT 0,
    is_reversed BIT DEFAULT 0,
    reversed_entry_id INT,
    created_by INT,
    approved_by INT,
    posted_by INT,
    posted_at DATETIME2,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    modified_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (reversed_entry_id) REFERENCES accounting.journal_entry(journal_entry_id)
);

-- Journal Entry Lines (Double Entry)
CREATE TABLE accounting.journal_entry_line (
    journal_entry_line_id INT IDENTITY(1,1) PRIMARY KEY,
    journal_entry_id INT NOT NULL REFERENCES accounting.journal_entry(journal_entry_id),
    account_id INT NOT NULL REFERENCES accounting.account(account_id),
    debit_amount DECIMAL(19,4) DEFAULT 0,
    credit_amount DECIMAL(19,4) DEFAULT 0,
    description NVARCHAR(500),
    line_number INT,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    CONSTRAINT CHK_amount CHECK (debit_amount >= 0 AND credit_amount >= 0),
    CONSTRAINT CHK_debit_credit CHECK (
        (debit_amount > 0 AND credit_amount = 0) OR 
        (credit_amount > 0 AND debit_amount = 0)
    )
);

-- =====================================================
-- DOCUMENT SCHEMA (Unified Document Model)
-- =====================================================

CREATE TABLE document.document_type (
    document_type_id INT IDENTITY(1,1) PRIMARY KEY,
    type_code NVARCHAR(20) NOT NULL UNIQUE,
    type_name NVARCHAR(100) NOT NULL,
    has_inventory_impact BIT DEFAULT 0,
    has_accounting_impact BIT DEFAULT 0,
    number_prefix NVARCHAR(10),
    next_number INT DEFAULT 1
);

CREATE TABLE document.document (
    document_id INT IDENTITY(1,1) PRIMARY KEY,
    document_type_id INT NOT NULL REFERENCES document.document_type(document_type_id),
    document_number NVARCHAR(50) NOT NULL UNIQUE,
    document_date DATE NOT NULL,
    posting_date DATE,
    due_date DATE,
    party_id INT REFERENCES party.party(party_id),
    branch_id INT REFERENCES master.branch(branch_id),
    currency_id INT REFERENCES master.currency(currency_id),
    exchange_rate DECIMAL(18,6) DEFAULT 1,
    subtotal DECIMAL(19,4) DEFAULT 0,
    tax_amount DECIMAL(19,4) DEFAULT 0,
    discount_amount DECIMAL(19,4) DEFAULT 0,
    total_amount DECIMAL(19,4) DEFAULT 0,
    status NVARCHAR(20) DEFAULT 'Draft',
    reference_document_id INT,
    description NVARCHAR(500),
    created_by INT,
    approved_by INT,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    modified_at DATETIME2 DEFAULT GETUTCDATE(),
    FOREIGN KEY (reference_document_id) REFERENCES document.document(document_id)
);

CREATE TABLE document.document_line (
    document_line_id INT IDENTITY(1,1) PRIMARY KEY,
    document_id INT NOT NULL REFERENCES document.document(document_id),
    line_number INT NOT NULL,
    product_id INT,  -- References catalog.product
    description NVARCHAR(500),
    quantity DECIMAL(18,4) DEFAULT 0,
    unit_price DECIMAL(19,4) DEFAULT 0,
    discount_percent DECIMAL(5,2) DEFAULT 0,
    tax_rate DECIMAL(5,2) DEFAULT 0,
    line_total DECIMAL(19,4) DEFAULT 0,
    created_at DATETIME2 DEFAULT GETUTCDATE()
);

-- =====================================================
-- INVENTORY SCHEMA
-- =====================================================

CREATE TABLE inventory.location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    branch_id INT NOT NULL REFERENCES master.branch(branch_id),
    location_code NVARCHAR(50) NOT NULL,
    location_name NVARCHAR(200) NOT NULL,
    is_active BIT DEFAULT 1,
    CONSTRAINT UQ_location_branch_code UNIQUE (branch_id, location_code)
);

CREATE TABLE inventory.inventory_movement_type (
    movement_type_id INT IDENTITY(1,1) PRIMARY KEY,
    type_code NVARCHAR(20) NOT NULL UNIQUE,
    type_name NVARCHAR(100) NOT NULL,
    movement_direction NVARCHAR(10) CHECK (movement_direction IN ('In', 'Out', 'Transfer'))
);

CREATE TABLE inventory.inventory_movement (
    inventory_movement_id INT IDENTITY(1,1) PRIMARY KEY,
    movement_number NVARCHAR(50) NOT NULL UNIQUE,
    movement_type_id INT NOT NULL REFERENCES inventory.inventory_movement_type(movement_type_id),
    product_id INT,  -- References catalog.product
    quantity DECIMAL(18,4) NOT NULL,
    unit_cost DECIMAL(19,4),
    from_location_id INT REFERENCES inventory.location(location_id),
    to_location_id INT REFERENCES inventory.location(location_id),
    document_id INT REFERENCES document.document(document_id),
    movement_date DATETIME2 DEFAULT GETUTCDATE(),
    reference_number NVARCHAR(100),
    created_by INT,
    created_at DATETIME2 DEFAULT GETUTCDATE()
);

-- Current Stock Snapshot (Derived, but stored for performance)
CREATE TABLE inventory.current_stock (
    product_id INT NOT NULL,
    location_id INT NOT NULL,
    quantity_on_hand DECIMAL(18,4) DEFAULT 0,
    average_cost DECIMAL(19,4) DEFAULT 0,
    last_movement_date DATETIME2,
    CONSTRAINT PK_current_stock PRIMARY KEY (product_id, location_id)
);

-- =====================================================
-- TRANSACTION SCHEMA (Generic Transaction Pattern)
-- =====================================================

CREATE TABLE transaction_log.transaction_type (
    transaction_type_id INT IDENTITY(1,1) PRIMARY KEY,
    type_code NVARCHAR(50) NOT NULL UNIQUE,
    type_name NVARCHAR(200) NOT NULL,
    has_accounting_impact BIT DEFAULT 1,
    has_inventory_impact BIT DEFAULT 0
);

CREATE TABLE transaction_log.transaction (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_number NVARCHAR(50) NOT NULL UNIQUE,
    transaction_type_id INT NOT NULL REFERENCES transaction_log.transaction_type(transaction_type_id),
    transaction_date DATETIME2 DEFAULT GETUTCDATE(),
    document_id INT REFERENCES document.document(document_id),
    journal_entry_id INT REFERENCES accounting.journal_entry(journal_entry_id),
    party_id INT REFERENCES party.party(party_id),
    branch_id INT REFERENCES master.branch(branch_id),
    description NVARCHAR(500),
    amount DECIMAL(19,4),
    status NVARCHAR(20) DEFAULT 'Pending',
    created_by INT,
    approved_by INT,
    created_at DATETIME2 DEFAULT GETUTCDATE()
);

-- =====================================================
-- CASH AND SHIFTS SCHEMA
-- =====================================================

CREATE TABLE cash.shift (
    shift_id INT IDENTITY(1,1) PRIMARY KEY,
    shift_number NVARCHAR(50) NOT NULL UNIQUE,
    cashier_id INT NOT NULL REFERENCES party.party(party_id),
    branch_id INT NOT NULL REFERENCES master.branch(branch_id),
    opening_time DATETIME2 NOT NULL,
    closing_time DATETIME2,
    opening_balance DECIMAL(19,4) NOT NULL,
    closing_balance DECIMAL(19,4),
    expected_balance DECIMAL(19,4),
    discrepancy DECIMAL(19,4),
    status NVARCHAR(20) DEFAULT 'Open',
    notes NVARCHAR(500),
    created_at DATETIME2 DEFAULT GETUTCDATE()
);

CREATE TABLE cash.cash_transaction (
    cash_transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    shift_id INT NOT NULL REFERENCES cash.shift(shift_id),
    transaction_type NVARCHAR(20) CHECK (transaction_type IN ('Sale', 'Refund', 'Expense', 'Deposit', 'Withdrawal')),
    amount DECIMAL(19,4) NOT NULL,
    reference_number NVARCHAR(100),
    document_id INT REFERENCES document.document(document_id),
    transaction_time DATETIME2 DEFAULT GETUTCDATE(),
    created_by INT
);

-- =====================================================
-- ATTACHMENT SCHEMA (Generic Attachment Pattern)
-- =====================================================

CREATE TABLE attachment.attachment (
    attachment_id INT IDENTITY(1,1) PRIMARY KEY,
    file_name NVARCHAR(500) NOT NULL,
    file_path NVARCHAR(1000),
    file_size BIGINT,
    mime_type NVARCHAR(100),
    file_hash NVARCHAR(200),
    uploaded_by INT,
    uploaded_at DATETIME2 DEFAULT GETUTCDATE()
);

CREATE TABLE attachment.entity_attachment (
    entity_attachment_id INT IDENTITY(1,1) PRIMARY KEY,
    attachment_id INT NOT NULL REFERENCES attachment.attachment(attachment_id),
    entity_type NVARCHAR(100) NOT NULL,  -- Table name like 'document', 'product', 'party'
    entity_id INT NOT NULL,
    attachment_type NVARCHAR(50),  -- 'Invoice', 'Contract', 'Image', etc.
    is_primary BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETUTCDATE()
);

-- =====================================================
-- PRODUCT CATALOG SCHEMA
-- =====================================================

CREATE TABLE catalog.category (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    parent_category_id INT REFERENCES catalog.category(category_id),
    category_code NVARCHAR(50) NOT NULL UNIQUE,
    category_name NVARCHAR(200) NOT NULL,
    description NVARCHAR(500),
    is_active BIT DEFAULT 1
);

CREATE TABLE catalog.brand (
    brand_id INT IDENTITY(1,1) PRIMARY KEY,
    brand_code NVARCHAR(50) NOT NULL UNIQUE,
    brand_name NVARCHAR(200) NOT NULL,
    description NVARCHAR(500),
    is_active BIT DEFAULT 1
);

CREATE TABLE catalog.unit_of_measure (
    uom_id INT IDENTITY(1,1) PRIMARY KEY,
    uom_code NVARCHAR(10) NOT NULL UNIQUE,
    uom_name NVARCHAR(50) NOT NULL,
    uom_type NVARCHAR(20) CHECK (uom_type IN ('Quantity', 'Weight', 'Length', 'Volume'))
);

CREATE TABLE catalog.product (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    product_code NVARCHAR(50) NOT NULL UNIQUE,
    product_name NVARCHAR(200) NOT NULL,
    description NVARCHAR(MAX),
    category_id INT REFERENCES catalog.category(category_id),
    brand_id INT REFERENCES catalog.brand(brand_id),
    base_uom_id INT REFERENCES catalog.unit_of_measure(uom_id),
    is_active BIT DEFAULT 1,
    is_stockable BIT DEFAULT 1,
    weight DECIMAL(18,4),
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    modified_at DATETIME2 DEFAULT GETUTCDATE()
);

CREATE TABLE catalog.product_variant (
    variant_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL REFERENCES catalog.product(product_id),
    variant_code NVARCHAR(50) NOT NULL,
    variant_name NVARCHAR(200),
    sku NVARCHAR(50) NOT NULL UNIQUE,
    attributes NVARCHAR(MAX),  -- JSON for flexible attributes
    additional_cost DECIMAL(19,4) DEFAULT 0,
    CONSTRAINT UQ_variant_product_code UNIQUE (product_id, variant_code)
);

-- =====================================================
-- PRICING SCHEMA (Pricing Rule Engine)
-- =====================================================

CREATE TABLE pricing.price_rule_type (
    price_rule_type_id INT IDENTITY(1,1) PRIMARY KEY,
    type_code NVARCHAR(50) NOT NULL UNIQUE,
    type_name NVARCHAR(200) NOT NULL
);

CREATE TABLE pricing.price_rule (
    price_rule_id INT IDENTITY(1,1) PRIMARY KEY,
    rule_code NVARCHAR(50) NOT NULL UNIQUE,
    rule_name NVARCHAR(200) NOT NULL,
    price_rule_type_id INT REFERENCES pricing.price_rule_type(price_rule_type_id),
    product_id INT REFERENCES catalog.product(product_id),
    category_id INT REFERENCES catalog.category(category_id),
    party_role_id INT REFERENCES party.party_role(party_role_id),
    priority INT DEFAULT 0,
    min_quantity DECIMAL(18,4),
    max_quantity DECIMAL(18,4),
    discount_percent DECIMAL(5,2),
    fixed_price DECIMAL(19,4),
    start_date DATE,
    end_date DATE,
    is_active BIT DEFAULT 1,
    created_at DATETIME2 DEFAULT GETUTCDATE()
);

-- =====================================================
-- SECURITY SCHEMA
-- =====================================================

CREATE TABLE security.role (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_code NVARCHAR(50) NOT NULL UNIQUE,
    role_name NVARCHAR(200) NOT NULL,
    description NVARCHAR(500)
);

CREATE TABLE security.permission (
    permission_id INT IDENTITY(1,1) PRIMARY KEY,
    permission_code NVARCHAR(100) NOT NULL UNIQUE,
    resource NVARCHAR(100),
    action NVARCHAR(50)
);

CREATE TABLE security.role_permission (
    role_id INT NOT NULL REFERENCES security.role(role_id),
    permission_id INT NOT NULL REFERENCES security.permission(permission_id),
    CONSTRAINT PK_role_permission PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE security.[user] (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    party_id INT NOT NULL REFERENCES party.party(party_id),
    username NVARCHAR(50) NOT NULL UNIQUE,
    email NVARCHAR(100) NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    is_active BIT DEFAULT 1,
    last_login DATETIME2,
    password_changed_at DATETIME2,
    created_at DATETIME2 DEFAULT GETUTCDATE()
);

CREATE TABLE security.user_role (
    user_id INT NOT NULL REFERENCES security.[user](user_id),
    role_id INT NOT NULL REFERENCES security.role(role_id),
    CONSTRAINT PK_user_role PRIMARY KEY (user_id, role_id)
);

CREATE TABLE security.user_session (
    session_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT NOT NULL REFERENCES security.[user](user_id),
    session_token NVARCHAR(500) NOT NULL UNIQUE,
    login_time DATETIME2 DEFAULT GETUTCDATE(),
    logout_time DATETIME2,
    ip_address NVARCHAR(45),
    user_agent NVARCHAR(500)
);

CREATE TABLE security.activity_log (
    activity_log_id INT IDENTITY(1,1) PRIMARY KEY,
    user_id INT REFERENCES security.[user](user_id),
    action NVARCHAR(200) NOT NULL,
    entity_type NVARCHAR(100),
    entity_id INT,
    old_value NVARCHAR(MAX),
    new_value NVARCHAR(MAX),
    ip_address NVARCHAR(45),
    created_at DATETIME2 DEFAULT GETUTCDATE()
);

-- =====================================================
-- SETTINGS SYSTEM
-- =====================================================

CREATE TABLE master.settings (
    setting_id INT IDENTITY(1,1) PRIMARY KEY,
    setting_key NVARCHAR(200) NOT NULL UNIQUE,
    setting_value NVARCHAR(MAX),
    setting_group NVARCHAR(100),
    data_type NVARCHAR(20) DEFAULT 'String',
    description NVARCHAR(500),
    is_encrypted BIT DEFAULT 0,
    created_at DATETIME2 DEFAULT GETUTCDATE(),
    modified_at DATETIME2 DEFAULT GETUTCDATE()
);

-- Insert default settings
INSERT INTO master.settings (setting_key, setting_value, setting_group, data_type, description) VALUES
('DEFAULT_CURRENCY', 'USD', 'General', 'String', 'Default currency for the system'),
('DEFAULT_TAX_RATE', '0.00', 'Tax', 'Decimal', 'Default tax rate percentage'),
('INVENTORY_VALUATION_METHOD', 'FIFO', 'Inventory', 'String', 'FIFO, LIFO, or Weighted Average'),
('ACCOUNTING_FISCAL_YEAR_START', '01-01', 'Accounting', 'String', 'Fiscal year start date (MM-DD)'),
('CASH_DISCREPANCY_THRESHOLD', '5.00', 'Cash', 'Decimal', 'Maximum allowed cash discrepancy');
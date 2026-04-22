-- =====================================================
-- PERFORMANCE INDEXES
-- =====================================================

-- Accounting indexes
CREATE INDEX IX_journal_entry_date ON accounting.journal_entry(entry_date);
CREATE INDEX IX_journal_entry_status ON accounting.journal_entry(status);
CREATE INDEX IX_journal_entry_created ON accounting.journal_entry(created_at);
CREATE INDEX IX_journal_entry_line_account ON accounting.journal_entry_line(account_id);
CREATE INDEX IX_journal_entry_line_entry ON accounting.journal_entry_line(journal_entry_id);
CREATE INDEX IX_account_parent ON accounting.account(parent_account_id);
CREATE INDEX IX_account_code ON accounting.account(account_code);

-- Document indexes
CREATE INDEX IX_document_date ON document.document(document_date);
CREATE INDEX IX_document_party ON document.document(party_id);
CREATE INDEX IX_document_type ON document.document(document_type_id);
CREATE INDEX IX_document_status ON document.document(status);
CREATE INDEX IX_document_number ON document.document(document_number);
CREATE INDEX IX_document_line_document ON document.document_line(document_id);
CREATE INDEX IX_document_line_product ON document.document_line(product_id);

-- Inventory indexes
CREATE INDEX IX_inventory_movement_date ON inventory.inventory_movement(movement_date);
CREATE INDEX IX_inventory_movement_product ON inventory.inventory_movement(product_id);
CREATE INDEX IX_inventory_movement_document ON inventory.inventory_movement(document_id);
CREATE INDEX IX_current_stock_product ON inventory.current_stock(product_id);
CREATE INDEX IX_current_stock_location ON inventory.current_stock(location_id);

-- Party indexes
CREATE INDEX IX_party_name ON party.party(party_name);
CREATE INDEX IX_party_code ON party.party(party_code);
CREATE INDEX IX_party_role_party ON party.party_role_assignment(party_id);
CREATE INDEX IX_party_role_role ON party.party_role_assignment(party_role_id);

-- Transaction indexes
CREATE INDEX IX_transaction_date ON transaction_log.transaction(transaction_date);
CREATE INDEX IX_transaction_document ON transaction_log.transaction(document_id);
CREATE INDEX IX_transaction_journal ON transaction_log.transaction(journal_entry_id);
CREATE INDEX IX_transaction_party ON transaction_log.transaction(party_id);

-- Catalog indexes
CREATE INDEX IX_product_code ON catalog.product(product_code);
CREATE INDEX IX_product_name ON catalog.product(product_name);
CREATE INDEX IX_product_category ON catalog.product(category_id);
CREATE INDEX IX_product_brand ON catalog.product(brand_id);
CREATE INDEX IX_variant_product ON catalog.product_variant(product_id);
CREATE INDEX IX_variant_sku ON catalog.product_variant(sku);

-- Pricing indexes
CREATE INDEX IX_price_rule_product ON pricing.price_rule(product_id);
CREATE INDEX IX_price_rule_category ON pricing.price_rule(category_id);
CREATE INDEX IX_price_rule_dates ON pricing.price_rule(start_date, end_date);
CREATE INDEX IX_price_rule_active ON pricing.price_rule(is_active);

-- Security indexes
CREATE INDEX IX_user_username ON security.[user](username);
CREATE INDEX IX_user_party ON security.[user](party_id);
CREATE INDEX IX_session_token ON security.user_session(session_token);
CREATE INDEX IX_session_user ON security.user_session(user_id);
CREATE INDEX IX_activity_log_user ON security.activity_log(user_id);
CREATE INDEX IX_activity_log_date ON security.activity_log(created_at);
CREATE INDEX IX_activity_log_entity ON security.activity_log(entity_type, entity_id);

-- Attachment indexes
CREATE INDEX IX_entity_attachment ON attachment.entity_attachment(entity_type, entity_id);
CREATE INDEX IX_attachment_uploaded ON attachment.attachment(uploaded_at);

-- Cash indexes
CREATE INDEX IX_shift_cashier ON cash.shift(cashier_id);
CREATE INDEX IX_shift_branch ON cash.shift(branch_id);
CREATE INDEX IX_shift_status ON cash.shift(status);
CREATE INDEX IX_cash_transaction_shift ON cash.cash_transaction(shift_id);

-- Master data indexes
CREATE INDEX IX_branch_company ON master.branch(company_id);
CREATE INDEX IX_fiscal_period_company ON master.fiscal_period(company_id);
CREATE INDEX IX_fiscal_period_dates ON master.fiscal_period(start_date, end_date);

-- Composite indexes for common queries
CREATE INDEX IX_document_party_date ON document.document(party_id, document_date);
CREATE INDEX IX_inventory_movement_product_date ON inventory.inventory_movement(product_id, movement_date);
CREATE INDEX IX_journal_entry_date_status ON accounting.journal_entry(entry_date, status);

-- Full-text indexes (if needed)
-- CREATE FULLTEXT CATALOG ft_catalog AS DEFAULT;
-- CREATE FULLTEXT INDEX ON catalog.product(product_name, description) KEY INDEX PK_product;
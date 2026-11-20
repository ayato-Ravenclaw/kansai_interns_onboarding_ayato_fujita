-- ENUM 型定義
CREATE TYPE account_category_enum AS ENUM ('DEBIT', 'CREDIT');

-- 勘定科目マスタテーブル
CREATE TABLE accounts (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(20) NOT NULL,
    account_category account_category_enum NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 仕訳テーブル
CREATE TABLE journal_entries (
    id BIGSERIAL PRIMARY KEY,
    transaction_date DATE NOT NULL,
    memo VARCHAR(200),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (memo IS NULL OR LENGTH(memo) <= 200)
);

-- 仕訳行テーブル
CREATE TABLE journal_entry_lines (
    id BIGSERIAL PRIMARY KEY,
    journal_entry_id BIGINT NOT NULL,
    description VARCHAR(100),
    debit_account_id BIGINT,
    debit_amount INT,
    credit_account_id BIGINT,
    credit_amount INT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_journal_entry FOREIGN KEY (journal_entry_id) REFERENCES journal_entries(id) ON DELETE CASCADE,
    CONSTRAINT fk_debit_account FOREIGN KEY (debit_account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
    CONSTRAINT fk_credit_account FOREIGN KEY (credit_account_id) REFERENCES accounts(id) ON DELETE RESTRICT,
    CHECK (description IS NULL OR LENGTH(description) <= 100),
    CHECK (debit_amount IS NULL OR debit_amount > 0),
    CHECK (credit_amount IS NULL OR credit_amount > 0),
    CHECK ((debit_account_id IS NOT NULL) = (debit_amount IS NOT NULL)),
    CHECK ((credit_account_id IS NOT NULL) = (credit_amount IS NOT NULL))
);

-- 更新時刻自動更新関数
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: accounts テーブル
CREATE TRIGGER trigger_accounts_update_timestamp
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- Trigger: journal_entries テーブル
CREATE TRIGGER trigger_journal_entries_update_timestamp
    BEFORE UPDATE ON journal_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- Trigger: journal_entry_lines テーブル
CREATE TRIGGER trigger_journal_entry_lines_update_timestamp
    BEFORE UPDATE ON journal_entry_lines
    FOR EACH ROW
    EXECUTE FUNCTION update_timestamp();

-- インデックス
CREATE INDEX idx_accounts_code ON accounts(code);
CREATE INDEX idx_journal_entries_transaction_date_id ON journal_entries(transaction_date DESC, id DESC);
CREATE INDEX idx_journal_entry_lines_journal_entry_id ON journal_entry_lines(journal_entry_id);
CREATE INDEX idx_journal_entry_lines_debit_account_id ON journal_entry_lines(debit_account_id);
CREATE INDEX idx_journal_entry_lines_credit_account_id ON journal_entry_lines(credit_account_id);

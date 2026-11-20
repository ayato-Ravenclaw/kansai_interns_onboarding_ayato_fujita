# API設計書

作成日：2026-11-13  
参照：`01-datamodel.md`

## 概要

会計システムの REST API 設計。以下 7 機能で計 8 エンドポイント。

| 機能 | メソッド | URI | 説明 |
|------|---------|-----|------|
| **仕訳登録** | POST | `/api/journal-entries` | 新規仕訳を作成 |
| **仕訳一覧** | GET | `/api/journal-entries` | 仕訳を一覧取得（仕訳行・勘定科目を含む） |
| **仕訳詳細** | GET | `/api/journal-entries/{id}` | 単一仕訳を取得（仕訳行・勘定科目を含む） |
| **仕訳編集** | PUT | `/api/journal-entries/{id}` | 仕訳を編集（仕訳行は全置換） |
| **仕訳削除** | DELETE | `/api/journal-entries/{id}` | 仕訳を削除 |
| **勘定科目登録** | POST | `/api/accounts` | 新規勘定科目を登録 |
| **勘定科目一覧** | GET | `/api/accounts` | 勘定科目を一覧取得 |
| **勘定科目削除** | DELETE | `/api/accounts/{id}` | 勘定科目を削除 |

---

## 共通仕様

### レスポンスフォーマット

**成功時（200, 201）:**
```json
{
  "data": { /* レスポンスボディ */ }
}
```

**バリデーションエラー（400）:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値に誤りがあります",
    "fields": {
      "transactionDate": "取引日は必須です",
      "lines": "仕訳行は1件以上必要です",
      "lines[0].debitAmount": "借方金額は正の整数である必要があります"
    }
  }
}
```

**ビジネスロジックエラー（409）:**
```json
{
  "error": {
    "code": "CONFLICT",
    "message": "この勘定科目は使用中のため削除できません"
  }
}
```

**予期しないエラー（500）:**
```json
{
  "error": {
    "code": "INTERNAL_SERVER_ERROR",
    "message": "予期しないエラーが発生しました"
  }
}
```

### ステータスコード一覧

| ステータス | 意味 | 備考 |
|-----------|------|------|
| 200 OK | 成功 | GET, PUT, DELETE 時 |
| 201 Created | 作成成功 | POST 時 |
| 400 Bad Request | バリデーションエラー | フィールド単位で返す |
| 404 Not Found | リソースが見つからない | 削除済み、存在しない ID など |
| 409 Conflict | ビジネスロジック違反 | 使用中の勘定科目削除など |
| 500 Internal Server Error | サーバー側エラー | 予期しないバグなど |

---

## エンドポイント詳細

### 1. 仕訳登録

**エンドポイント:** `POST /api/journal-entries`

**リクエスト:**
```json
{
  "transactionDate": "2026-11-13",
  "memo": "給料支払い",
  "lines": [
    {
      "description": "現金から支払い",
      "debitAccountId": 1,
      "debitAmount": 100,
      "creditAccountId": 2,
      "creditAmount": 100
    },
    {
      "description": null,
      "debitAccountId": null,
      "debitAmount": null,
      "creditAccountId": 3,
      "creditAmount": 50
    }
  ]
}
```

**バリデーション:**
- `transactionDate`: 必須、日付形式（YYYY-MM-DD）
- `memo`: 最大200文字（null 可）
- `lines`: 必須、1件以上、配列
  - `description`: 最大100文字（null 可）
  - `debitAccountId`: 勘定科目が存在する必要がある
  - `debitAmount`: 勘定科目がある場合は必須、正の整数、0不可
  - `creditAccountId`: 勘定科目が存在する必要がある
  - `creditAmount`: 勘定科目がある場合は必須、正の整数、0不可
  - **貸借一致チェック:** 仕訳全体で「借方合計 = 貸方合計」であること

**バリデーションエラーの例:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値に誤りがあります",
    "fields": {
      "transactionDate": "取引日は必須です",
      "memo": "メモは200文字以内である必要があります",
      "lines[0].debitAmount": "借方金額は正の整数である必要があります",
      "lines[0].creditAccountId": "勘定科目が見つかりません",
      "journalEntry": "借方合計と貸方合計が一致していません（借方:100円、貸方:150円）"
    }
  }
}
```

**レスポンス（201 Created）:**
```json
{
  "data": {
    "id": 1,
    "transactionDate": "2026-11-13",
    "memo": "給料支払い",
    "lines": [
      {
        "id": 1,
        "description": "現金から支払い",
        "debitAccountId": 1,
        "debitAccountCode": "110",
        "debitAccountName": "現金",
        "debitAmount": 100,
        "creditAccountId": 2,
        "creditAccountCode": "120",
        "creditAccountName": "普通預金",
        "creditAmount": 100
      },
      {
        "id": 2,
        "description": null,
        "debitAccountId": null,
        "debitAccountCode": null,
        "debitAccountName": null,
        "debitAmount": null,
        "creditAccountId": 3,
        "creditAccountCode": "130",
        "creditAccountName": "定期預金",
        "creditAmount": 50
      }
    ],
    "createdAt": "2026-11-13T10:00:00+09:00"
  }
}
```

---

### 2. 仕訳一覧

**エンドポイント:** `GET /api/journal-entries`

**クエリパラメータ:**
- なし（ページング不要、全件取得）

**パフォーマンス考慮:**
- LEFT JOIN で仕訳行・勘定科目を1クエリで取得（N+1 回避）
- 複合インデックス `(transaction_date DESC, id DESC)` で ORDER BY を効率化

**レスポンス（200 OK）:**
```json
{
  "data": [
    {
      "id": 2,
      "transactionDate": "2026-11-13",
      "memo": "給料支払い",
      "lines": [
        {
          "id": 3,
          "description": "現金から支払い",
          "debitAccountId": 1,
          "debitAccountCode": "110",
          "debitAccountName": "現金",
          "debitAmount": 100,
          "creditAccountId": 2,
          "creditAccountCode": "120",
          "creditAccountName": "普通預金",
          "creditAmount": 100
        }
      ],
      "createdAt": "2026-11-13T10:00:00+09:00"
    },
    {
      "id": 1,
      "transactionDate": "2026-11-12",
      "memo": "入金",
      "lines": [
        {
          "id": 1,
          "description": null,
          "debitAccountId": 1,
          "debitAccountCode": "110",
          "debitAccountName": "現金",
          "debitAmount": 50,
          "creditAccountId": 2,
          "creditAccountCode": "120",
          "creditAccountName": "普通預金",
          "creditAmount": 50
        }
      ],
      "createdAt": "2026-11-12T09:00:00+09:00"
    }
  ]
}
```

**表示順:** 取引日の降順（新しい順）、同じ日付なら ID の降順

---

### 3. 仕訳詳細

**エンドポイント:** `GET /api/journal-entries/{id}`

**パスパラメータ:**
- `id`: 仕訳ID（必須）

**エラー:**
```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "仕訳が見つかりません"
  }
}
```

**レスポンス（200 OK）:**
仕訳一覧と同じ形式の1件分。

---

### 4. 仕訳編集

**エンドポイント:** `PUT /api/journal-entries/{id}`

**リクエスト:**
仕訳登録と同じ。

**編集方式:**
- 既存の仕訳行をすべて削除し、送られた行を新規作成（全置換）
- 仕訳行 ID は編集のたびに変わる（外部から参照不可前提）

**バリデーション:**
仕訳登録と同じ。

**レスポンス（200 OK）:**
仕訳登録と同じ形式。

---

### 5. 仕訳削除

**エンドポイント:** `DELETE /api/journal-entries/{id}`

**パスパラメータ:**
- `id`: 仕訳ID（必須）

**動作:**
- 仕訳とその仕訳行をすべて削除（ON DELETE CASCADE）

**レスポンス（200 OK）:**
```json
{
  "data": {
    "id": 1,
    "message": "仕訳を削除しました"
  }
}
```

**エラー:**
```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "仕訳が見つかりません"
  }
}
```

---

### 6. 勘定科目登録

**エンドポイント:** `POST /api/accounts`

**リクエスト:**
```json
{
  "code": "110",
  "name": "現金",
  "accountCategory": "DEBIT"
}
```

**バリデーション:**
- `code`: 必須、最大20文字、ユニーク（重複時は 409 Conflict）
- `name`: 必須、最大20文字
- `debitCredit`: 必須、"DEBIT" または "CREDIT"

**バリデーションエラーの例:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "入力値に誤りがあります",
    "fields": {
      "code": "コードは必須です",
      "name": "名前は20文字以内である必要があります",
      "debitCredit": "貸借区分は必須です"
    }
  }
}
```

**コード重複エラー:**
```json
{
  "error": {
    "code": "CONFLICT",
    "message": "このコードは既に使用されています"
  }
}
```

**レスポンス（201 Created）:**
```json
{
  "data": {
    "id": 1,
    "code": "110",
    "name": "現金",
    "accountCategory": "DEBIT",
    "createdAt": "2026-11-13T10:00:00+09:00"
  }
}
```

---

### 7. 勘定科目一覧

**エンドポイント:** `GET /api/accounts`

**クエリパラメータ:**
- なし

**レスポンス（200 OK）:**
```json
{
  "data": [
    {
      "id": 1,
      "code": "110",
      "name": "現金",
      "accountCategory": "DEBIT",
      "createdAt": "2026-11-13T10:00:00+09:00"
    },
    {
      "id": 2,
      "code": "120",
      "name": "普通預金",
      "debitCredit": "CREDIT",
      "createdAt": "2026-11-13T09:00:00+09:00"
    }
  ]
}
```

---

### 8. 勘定科目削除

**エンドポイント:** `DELETE /api/accounts/{id}`

**パスパラメータ:**
- `id`: 勘定科目ID（必須）

**削除ポリシー:**
- その勘定科目が仕訳行で使用中の場合は削除不可（409 Conflict）
- 外部キー ON DELETE RESTRICT で強制される

**エラー（使用中）:**
```json
{
  "error": {
    "code": "CONFLICT",
    "message": "この勘定科目は使用中のため削除できません"
  }
}
```

**エラー（見つからない）:**
```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "勘定科目が見つかりません"
  }
}
```

**レスポンス（200 OK）:**
```json
{
  "data": {
    "id": 1,
    "message": "勘定科目を削除しました"
  }
}
```

---

## エラーハンドリング方針

### フロント側で処理すべきエラー

| コード | 対象 | 処理 |
|--------|------|------|
| VALIDATION_ERROR | 400 | フィールド単位のエラーメッセージを表示 |
| CONFLICT | 409 | ユーザーが理解できるメッセージを表示（「使用中のため削除できません」など） |
| NOT_FOUND | 404 | 「データが見つかりません」と表示、一覧へ戻す |

### サーバー側で記録すべきエラー

| コード | 対象 | 対応 |
|--------|------|------|
| INTERNAL_SERVER_ERROR | 500 | スタックトレースをサーバーログに記録、ユーザーには汎用メッセージのみ |
| その他の予期しないエラー | 5xx | 同上 |

### ログ戦略

**記録するレベル:**
- **INFO:** API エンドポイント呼び出し（リクエストID、ユーザー情報（将来用））
- **WARN:** バリデーション失敗、ビジネスロジック違反（409等）
- **ERROR:** 予期しないエラー（500等）、スタックトレース含む

**記録しない情報:**
- ユーザーパスワード、認証トークン（将来実装時）
- 個人情報（現状は対象外）

---

## 性能要件と実装ポイント

### N+1回避

**仕訳一覧・詳細取得時:**
```sql
SELECT j.*, l.*, da.code, da.name, ca.code, ca.name
FROM journal_entries j
LEFT JOIN journal_entry_lines l ON j.id = l.journal_entry_id
LEFT JOIN accounts da ON l.debit_account_id = da.id
LEFT JOIN accounts ca ON l.credit_account_id = ca.id
ORDER BY j.transaction_date DESC, j.id DESC;
```

- 仕訳 + 仕訳行 + 勘定科目を **1クエリで取得**
- アプリケーション側でグルーピング

### インデックス活用

- `journal_entries(transaction_date DESC, id DESC)` — 一覧取得のソート効率化
- 外部キー列 `journal_entry_lines(journal_entry_id)` — 親取得時の効率化
- `accounts(code)` — コード検索・重複チェック

---

## 将来の拡張に向けた設計

- **ユーザー認証（未実装）:** リクエストに Authorization ヘッダを追加すればOK
- **ページング（未実装）:** クエリパラメータ `?limit=20&offset=0` などを追加
- **フィルター（未実装）:** 取引日範囲、勘定科目でのフィルター

現在は不要だが、API 構造は拡張性を考慮した設計にしておく。


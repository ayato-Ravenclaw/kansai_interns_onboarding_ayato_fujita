# メソッド仕様書

作成日：2026-11-17  
参照：`06-code-structure.md`, `04-architecture.md`

---

# Backend: Kotlin メソッド仕様

## Domain層

### Entity: JournalEntry

#### メソッド：create()

**目的：** 仕訳 Entity の作成と初期バリデーション

**パラメータ**
- `transactionDate: LocalDate` — 取引日（必須）
- `memo: String?` — メモ（optional、null 可、200 文字以内）

**バリデーション**
- [ ] `memo != null && memo.length > 200` → throw IllegalArgumentException("メモは200文字以内です")

**戻り値**
- `JournalEntry` — 新規インスタンス
  - `id: null`（DB採番まで未設定）
  - `createdAt: null`（DB設定まで未設定）
  - `updatedAt: null`（DB設定まで未設定）

**処理フロー**
1. memo が指定されていればバリデーション
2. 新規 JournalEntry インスタンス生成
3. インスタンス返却

---

#### メソッド：getters

**目的：** フィールド値の取得

**メソッド一覧**
- [ ] `getId(): Long?`
- [ ] `getTransactionDate(): LocalDate`
- [ ] `getMemo(): String?`
- [ ] `getCreatedAt(): LocalDateTime?`
- [ ] `getUpdatedAt(): LocalDateTime?`

**処理フロー**
- 各フィールドを単純に返却

---

### Entity: JournalEntryLine

#### メソッド：create()

**目的：** 仕訳行 Entity の作成と初期バリデーション

**パラメータ**
- `journalEntryId: Long` — 親仕訳 ID（必須）
- `description: String?` — 摘要（optional、100 文字以内）
- `debitAccountId: Long?` — 借方勘定科目 ID（optional）
- `debitAmount: Int?` — 借方金額（optional、0 不可）
- `creditAccountId: Long?` — 貸方勘定科目 ID（optional）
- `creditAmount: Int?` — 貸方金額（optional、0 不可）

**バリデーション**
- [ ] `journalEntryId == null` → throw IllegalArgumentException
- [ ] `description != null && description.length > 100` → throw IllegalArgumentException
- [ ] `debitAmount != null && debitAmount <= 0` → throw IllegalArgumentException
- [ ] `creditAmount != null && creditAmount <= 0` → throw IllegalArgumentException
- [ ] `(debitAccountId != null && debitAmount == null)` → throw IllegalArgumentException（勘定科目があれば金額も必須）
- [ ] `(debitAccountId == null && debitAmount != null)` → throw IllegalArgumentException（金額があれば勘定科目も必須）
- [ ] `(creditAccountId != null && creditAmount == null)` → throw IllegalArgumentException
- [ ] `(creditAccountId == null && creditAmount != null)` → throw IllegalArgumentException

**戻り値**
- `JournalEntryLine` — 新規インスタンス
  - `id: null`
  - `debitAmount, creditAmount: Amount?` （Integer を Amount ValueObject に変換）
  - `createdAt: null`
  - `updatedAt: null`

**処理フロー**
1. 各パラメータをバリデーション
2. debitAmount/creditAmount を Amount ValueObject に変換
3. インスタンス生成して返却

---

### Entity: Account

#### メソッド：create()

**目的：** 勘定科目 Entity の作成と初期バリデーション

**パラメータ**
- `code: String` — 勘定科目コード（必須、20 文字以内）
- `name: String` — 勘定科目名（必須、20 文字以内）
- `accountCategory: AccountCategory` — 貸借区分（必須、DEBIT or CREDIT）

**バリデーション**
- [ ] `code.isBlank() || code.length > 20` → throw IllegalArgumentException
- [ ] `name.isBlank() || name.length > 20` → throw IllegalArgumentException
- [ ] `accountCategory == null` → throw IllegalArgumentException

**戻り値**
- `Account` — 新規インスタンス（`id: null`）

**処理フロー**
1. code, name, accountCategory をバリデーション
2. インスタンス生成
3. 返却

---

### ValueObject: Amount

#### メソッド：of()

**目的：** 金額の ValueObject 生成

**パラメータ**
- `value: Int` — 金額（必須、0より大きい整数）

**バリデーション**
- [ ] `value <= 0` → throw IllegalArgumentException("金額は正の整数である必要があります")

**戻り値**
- `Amount` — ValueObject インスタンス

---

#### メソッド：plus()

**目的：** 2つの金額を加算

**パラメータ**
- `other: Amount` — 加算する金額

**戻り値**
- `Amount` — 合算結果（新規インスタンス）

**処理フロー**
1. this.value + other.value を計算
2. 新規 Amount インスタンス生成
3. 返却

---

#### メソッド：equals()、hashCode()

**目的：** ValueObject の同一性判定

**処理フロー**
- value の値のみで比較（ValueObject のセマンティック等価性）

---

### ValueObject: AccountCategory

**目的：** 勘定科目カテゴリ

**値**
- [ ] `DEBIT` — 借方
- [ ] `CREDIT` — 貸方

---

### DomainService: JournalEntryDomainService

#### メソッド：validateBalance()

**目的：** 仕訳の借貸一致をチェック

**パラメータ**
- `lines: List<JournalEntryLine>` — 仕訳行一覧（必須）

**バリデーション**
- [ ] `lines.isEmpty()` → throw ValidationException("仕訳行は1件以上必要です")

**例外**
- `ValidationException` — 借方合計と貸方合計が不一致
  - メッセージ：「借方合計と貸方合計が一致していません（借方:XXX円、貸方:YYY円）」

**処理フロー**
1. lines が空か確認
2. 借方合計を計算（debitAmount がある行のみ）
3. 貸方合計を計算（creditAmount がある行のみ）
4. 借方合計 == 貸方合計 か確認
5. 不一致の場合、ValidationException を throw（メッセージに金額を含める）

---

### Repository インターフェース: JournalEntryRepository

#### メソッド：insert()

**目的：** 仕訳を DB に保存

**パラメータ**
- `entry: JournalEntry` — 保存する仕訳（必須）

**戻り値**
- `Long` — 自動採番された仕訳 ID

**処理**
- Domain Entity を jOOQ Record に変換
- INSERT 文を実行
- 返された ID を返却

---

#### メソッド：insertLines()

**目的：** 仕訳行を DB に一括保存

**パラメータ**
- `journalEntryId: Long` — 親仕訳 ID（必須）
- `lines: List<JournalEntryLine>` — 仕訳行一覧（必須、空リストも OK）

**処理**
- lines の各要素を jOOQ Record に変換
- 複数 INSERT 文を実行
- 外部キー制約によりエラーの可能性あり

---

#### メソッド：findById()

**目的：** ID で仕訳を取得（仕訳行・勘定科目情報を含む）

**パラメータ**
- `id: Long` — 仕訳 ID（必須）

**戻り値**
- `JournalEntryWithLines?` — 仕訳と行のセット、見つからない場合は null

**パフォーマンス**
- [ ] LEFT JOIN で仕訳・仕訳行・勘定科目を **1 クエリで取得**（N+1 なし）

**処理**
- SQL：journal_entries と journal_entry_lines を LEFT JOIN
- さらに debit_account_id, credit_account_id で accounts を LEFT JOIN
- 結果をアプリケーション側でグルーピング
- Domain Entity に変換

---

#### メソッド：findAll()

**目的：** すべての仕訳を取得（仕訳行・勘定科目情報を含む）

**戻り値**
- `List<JournalEntryWithLines>` — 仕訳リスト（取引日降順）

**ソート順**
- [ ] 取引日の降順（新しい順）
- [ ] 同一日付の場合は ID の降順

**パフォーマンス**
- [ ] LEFT JOIN で 1 クエリ
- [ ] 複合インデックス `(transaction_date DESC, id DESC)` を活用

---

#### メソッド：update()

**目的：** 仕訳を更新（取引日、メモ）

**パラメータ**
- `id: Long` — 仕訳 ID（必須）
- `entry: JournalEntry` — 更新内容（必須）

**例外**
- `NotFoundException` — 仕訳が見つからない場合

**処理**
- UPDATE 文を実行
- 更新件数が 0 の場合、NotFoundException を throw

---

#### メソッド：delete()

**目的：** 仕訳を削除（仕訳行も自動削除）

**パラメータ**
- `id: Long` — 仕訳 ID（必須）

**例外**
- `NotFoundException` — 仕訳が見つからない場合

**処理**
- DELETE FROM journal_entries WHERE id = ?
- ON DELETE CASCADE で journal_entry_lines も自動削除

---

#### メソッド：deleteLines()

**目的：** 特定仕訳の仕訳行を全削除

**パラメータ**
- `journalEntryId: Long` — 仕訳 ID（必須）

**処理**
- DELETE FROM journal_entry_lines WHERE journal_entry_id = ?

---

### Repository インターフェース: AccountRepository

#### メソッド：insert()

**パラメータ**
- `account: Account` — 保存する勘定科目（必須）

**戻り値**
- `Long` — 自動採番された勘定科目 ID

**例外**
- `ConflictException` — code が重複している場合（UNIQUE 制約違反）

---

#### メソッド：findById()

**パラメータ**
- `id: Long` — 勘定科目 ID（必須）

**戻り値**
- `Account?` — 勘定科目、見つからない場合は null

---

#### メソッド：findByCode()

**パラメータ**
- `code: String` — 勘定科目コード（必須）

**戻り値**
- `Account?` — 勘定科目、見つからない場合は null

---

#### メソッド：findAll()

**戻り値**
- `List<Account>` — すべての勘定科目

---

#### メソッド：delete()

**パラメータ**
- `id: Long` — 勘定科目 ID（必須）

**例外**
- `NotFoundException` — 見つからない場合
- `ConflictException` → `DataIntegrityViolationException` を変換（ON DELETE RESTRICT で削除不可）

---

#### メソッド：checkIfUsed()

**目的：** 勘定科目が仕訳行で使用中か確認

**パラメータ**
- `accountId: Long` — 勘定科目 ID（必須）

**戻り値**
- `Boolean` — 使用中なら true、未使用なら false

**処理**
- SELECT COUNT(*) FROM journal_entry_lines WHERE debit_account_id = ? OR credit_account_id = ?
- COUNT > 0 なら true

---

## Application層

### Usecase: CreateJournalEntryUsecase

#### メソッド：execute()

**目的：** 仕訳作成ビジネスフロー全体を実行

**パラメータ**
- `command: CreateJournalEntryCommand`
  - `transactionDate: LocalDate`
  - `memo: String?`
  - `lines: List<CreateJournalEntryLineCommand>`

**戻り値**
- `JournalEntryDTO` — 作成された仕訳

**例外**
- `ValidationException` — ビジネスロジックバリデーション失敗
  - メモ 200 文字超
  - 金額 0 以下
  - 勘定科目と金額の不一致
  - 貸借不一致
- `NotFoundException` — 指定された勘定科目が存在しない

**トランザクション**
- [ ] `@Transactional` で 1 トランザクション内で実行
- [ ] エラー時は自動ロールバック

**処理フロー**
1. command → Domain Entity に変換（JournalEntry, JournalEntryLine を create）
2. 各勘定科目 ID が存在するか確認
3. DomainService で貸借一致をチェック
4. Repository で insert
   - journalEntryRepository.insert(entry) → id を取得
   - journalEntryRepository.insertLines(id, lines)
5. 作成後、findById で取得
6. DTO に変換して返却

---

### Usecase: UpdateJournalEntryUsecase

#### メソッド：execute()

**目的：** 仕訳編集ビジネスフロー全体を実行

**パラメータ**
- `id: Long` — 仕訳 ID（必須）
- `command: UpdateJournalEntryCommand` — 更新内容

**戻り値**
- `JournalEntryDTO` — 更新された仕訳

**例外**
- `NotFoundException` — 仕訳が見つからない場合
- `ValidationException` — CreateJournalEntryUsecase と同じ

**処理フロー**
1. id で既存仕訳を確認
2. CreateJournalEntryUsecase と同じバリデーション
3. 既存の仕訳行をすべて削除（deleteLines）
4. 新しい仕訳行を追加（insertLines）
5. 仕訳のメタデータ（取引日、メモ）を更新（update）
6. 更新後、findById で取得
7. DTO に変換して返却

---

### Usecase: DeleteJournalEntryUsecase

#### メソッド：execute()

**目的：** 仕訳削除ビジネスフロー

**パラメータ**
- `id: Long` — 仕訳 ID（必須）

**戻り値**
- `Unit`（void）

**例外**
- `NotFoundException` — 仕訳が見つからない場合

**処理フロー**
1. id で仕訳が存在するか確認
2. Repository で delete

---

### Usecase: CreateAccountUsecase

#### メソッド：execute()

**目的：** 勘定科目作成ビジネスフロー

**パラメータ**
- `command: CreateAccountCommand`
  - `code: String`
  - `name: String`
  - `accountCategory: AccountCategory`

**戻り値**
- `AccountDTO` — 作成された勘定科目

**例外**
- `ValidationException` — code/name の長さ超過
- `ConflictException` — 重複する code

**処理フロー**
1. command → Domain Entity を create
2. 同一 code が存在しないか確認（findByCode）
3. Repository で insert
4. 取得して DTO に変換

---

### Usecase: DeleteAccountUsecase

#### メソッド：execute()

**目的：** 勘定科目削除ビジネスフロー

**パラメータ**
- `id: Long` — 勘定科目 ID（必須）

**戻り値**
- `Unit`（void）

**例外**
- `NotFoundException` — 勘定科目が見つからない場合
- `ConflictException` — 使用中の場合

**処理フロー**
1. id で勘定科目が存在するか確認
2. checkIfUsed で使用中か確認
3. Repository で delete

---

## Adapter層

### Controller: JournalEntryController

#### メソッド：create()

**目的：** 仕訳作成 HTTP エンドポイント

**HTTP**
- `POST /api/journal-entries`

**パラメータ**
- `request: CreateJournalEntryRequest` — リクエストボディ（@Valid で自動バリデーション）

**戻り値**
- `ResponseEntity<ApiResponse<JournalEntryDTO>>` — 201 Created + レスポンスボディ

**処理フロー**
1. request → CreateJournalEntryCommand に変換
2. createUsecase.execute(command)
3. 戻り値を ApiResponse でラップ
4. ResponseEntity.status(CREATED) で返却

**エラーハンドリング**
- ValidationException → 400 Bad Request
- NotFoundException → 400 Bad Request
- 予期しないエラー → 500 Internal Server Error

---

#### メソッド：findAll()

**HTTP**
- `GET /api/journal-entries`

**戻り値**
- `ResponseEntity<ApiResponse<List<JournalEntryDTO>>>` — 200 OK + リスト

**処理フロー**
1. repository.findAll()
2. 結果を DTO に変換
3. ApiResponse でラップして返却

---

#### メソッド：findById()

**HTTP**
- `GET /api/journal-entries/{id}`

**パラメータ**
- `id: Long` — パスパラメータ

**戻り値**
- `ResponseEntity<ApiResponse<JournalEntryDTO>>` — 200 OK または 404 Not Found

**処理フロー**
1. repository.findById(id)
2. 存在しない場合、404 Not Found を返却
3. 存在する場合、DTO に変換して返却

---

#### メソッド：update()

**HTTP**
- `PUT /api/journal-entries/{id}`

**パラメータ**
- `id: Long` — パスパラメータ
- `request: UpdateJournalEntryRequest` — リクエストボディ

**処理フロー**
1. request → UpdateJournalEntryCommand に変換
2. updateUsecase.execute(id, command)
3. 戻り値を ApiResponse でラップして返却

---

#### メソッド：delete()

**HTTP**
- `DELETE /api/journal-entries/{id}`

**パラメータ**
- `id: Long` — パスパラメータ

**戻り値**
- `ResponseEntity<ApiResponse<Map<String, Any>>>` — 200 OK + { "id": 1, "message": "削除しました" }

**処理フロー**
1. deleteUsecase.execute(id)
2. 削除結果メッセージを返却

---

### Controller: AccountController

#### メソッド：create()

**HTTP**
- `POST /api/accounts`

**パラメータ**
- `request: CreateAccountRequest` — リクエストボディ

**戻り値**
- `ResponseEntity<ApiResponse<AccountDTO>>` — 201 Created

---

#### メソッド：findAll()

**HTTP**
- `GET /api/accounts`

**戻り値**
- `ResponseEntity<ApiResponse<List<AccountDTO>>>` — 200 OK

---

#### メソッド：delete()

**HTTP**
- `DELETE /api/accounts/{id}`

**パラメータ**
- `id: Long` — パスパラメータ

**戻り値**
- `ResponseEntity<ApiResponse<Map<String, Any>>>` — 200 OK または 409 Conflict

---

### Exception Handler

**目的：** ビジネス例外をキャッチして HTTP レスポンスに変換

#### ValidationException

**ステータスコード**
- 400 Bad Request

**レスポンス形式**
- `{ "code": "VALIDATION_ERROR", "message": "...", "fields": {...} }`

---

#### ConflictException

**ステータスコード**
- 409 Conflict

**レスポンス形式**
- `{ "code": "CONFLICT", "message": "..." }`

---

#### NotFoundException

**ステータスコード**
- 404 Not Found

**レスポンス形式**
- `{ "code": "NOT_FOUND", "message": "..." }`

---

#### Generic Exception

**ステータスコード**
- 500 Internal Server Error

**処理**
- [ ] スタックトレースをサーバーログに記録
- [ ] ユーザーには汎用メッセージのみ返却

---

---

# Frontend: React/TypeScript コンポーネント仕様

## Pages

### JournalListPage.tsx

**目的：** 仕訳一覧画面全体の制御

**Props**
- なし

**State 管理**
- `entries: JournalEntryDTO[]` — 仕訳リスト
- `loading: boolean` — ローディング状態
- `error: string?` — エラーメッセージ
- `deleteConfirm: Long?` — 削除対象の仕訳 ID

**処理フロー**
1. マウント時に journalEntryService.listJournalEntries() を呼び出し
2. 結果を entries に設定
3. エラー時は error に設定
4. 仕訳一覧を表示
5. 編集ボタン → 編集画面に遷移
6. 削除ボタン → 削除確認ダイアログ表示
7. 削除確定 → journalEntryService.deleteJournalEntry() を呼び出し
8. refetch()

---

### JournalFormPage.tsx

**目的：** 仕訳作成・編集画面

**Props**
- `id?: Long` — 編集時は仕訳 ID が存在

**State 管理**
- `formData: CreateJournalEntryRequest` — フォームデータ
- `errors: { general?: string, fields?: Record<string, string> }` — バリデーションエラー
- `loading: boolean` — 送信中フラグ

**処理フロー**
1. id がある場合、マウント時に getJournalEntry(id) を呼び出し
2. 結果をフォームデータに展開
3. ユーザー入力をリアルタイムに state 更新
4. 保存ボタン → submit()
5. 成功 → 一覧画面に遷移
6. エラー → errors に設定して表示
7. キャンセル → 一覧画面に戻る

---

### AccountListPage.tsx

**目的：** 勘定科目一覧画面

**Props**
- なし

**State 管理**
- `accounts: AccountDTO[]` — 勘定科目リスト
- `loading: boolean` — ローディング状態
- `error: string?` — エラーメッセージ
- `deleteConfirm: Long?` — 削除対象の勘定科目 ID

**処理フロー**
1. マウント時に accountService.listAccounts() を呼び出し
2. 一覧を表示
3. 削除ボタン → 削除確認ダイアログ
4. 削除確定 → deleteAccount()
5. 成功 → refetch()
6. エラー → 409 Conflict メッセージを表示（使用中）

---

### AccountFormPage.tsx

**目的：** 勘定科目作成画面

**Props**
- なし

**State 管理**
- `formData: CreateAccountRequest` — フォームデータ
- `errors: Record<string, string>` — バリデーションエラー
- `loading: boolean` — 送信中フラグ

**処理フロー**
1. ユーザー入力をリアルタイムに state 更新
2. 保存ボタン → createAccount()
3. 成功 → 一覧画面に遷移
4. エラー → errors 表示
5. キャンセル → 一覧画面に戻る

---

## Components

### JournalEntryList.tsx

**目的：** 仕訳一覧テーブル表示

**Props**
- `entries: JournalEntryDTO[]` — 仕訳リスト（必須）
- `onEdit: (id: Long) => void` — 編集ボタンのコールバック
- `onDelete: (id: Long) => void` — 削除ボタンのコールバック

**処理**
- [ ] entries が空の場合、「仕訳がありません」と表示
- [ ] テーブルで仕訳を一覧表示
- [ ] 各行に編集・削除ボタン
- [ ] 仕訳行は借方・貸方の対が見やすいように表示

---

### JournalEntryForm.tsx

**目的：** 仕訳フォーム（登録・編集共用）

**Props**
- `initialData?: JournalEntryDTO` — 編集時の初期値
- `onSave: (data) => Promise<void>` — 保存ボタンのコールバック
- `onCancel: () => void` — キャンセルボタンのコールバック

**State 管理**
- `formData: CreateJournalEntryRequest` — フォームデータ
- `errors: Record<string, string>` — フィールドごとのバリデーションエラー
- `loading: boolean` — 送信中フラグ

**処理**
- [ ] 取引日フィールド（日付入力）
- [ ] メモフィールド（テキスト、200 文字制限）
- [ ] 仕訳行テーブルを子コンポーネントで表示
- [ ] 保存中は「保存中...」と表示、ボタン disabled
- [ ] エラーがあれば ErrorAlert で表示

---

### JournalEntryLineTable.tsx

**目的：** 仕訳行のテーブル（追加・削除・編集）

**Props**
- `lines: JournalEntryLineDTO[]` — 仕訳行一覧（必須）
- `accounts: AccountDTO[]` — 勘定科目マスタ（必須）
- `onAdd: () => void` — 行追加ボタンのコールバック
- `onRemove: (index: number) => void` — 行削除ボタンのコールバック
- `onChange: (index: number, line: JournalEntryLineDTO) => void` — フィールド変更のコールバック

**処理**
- [ ] lines の各行を JournalEntryLineRow で表示
- [ ] 「行を追加」ボタンで新規行を追加
- [ ] 各行に「削除」ボタン

---

### JournalEntryLineRow.tsx

**目的：** 仕訳行 1 行分の編集

**Props**
- `line: JournalEntryLineDTO` — 仕訳行データ（必須）
- `accounts: AccountDTO[]` — 勘定科目マスタ（必須）
- `onChange: (line: JournalEntryLineDTO) => void` — 変更通知
- `onRemove: () => void` — 削除通知

**処理**
- [ ] 摘要フィールド（テキスト、100 文字制限）
- [ ] 借方勘定科目セレクタ
- [ ] 借方金額フィールド（数値、0 不可）
- [ ] 貸方勘定科目セレクタ
- [ ] 貸方金額フィールド（数値、0 不可）
- [ ] 削除ボタン
- [ ] フィールド変更時に onChange を呼び出し

---

### AccountSelector.tsx

**目的：** 勘定科目ドロップダウン

**Props**
- `accounts: AccountDTO[]` — 勘定科目リスト（必須）
- `value: Long?` — 選択中の勘定科目 ID
- `onChange: (id: Long?) => void` — 選択変更コールバック

**処理**
- [ ] ドロップダウンを表示
- [ ] 「未選択」オプション
- [ ] accounts を code, name で表示
- [ ] 選択時に onChange を呼び出し

---

### AccountList.tsx

**目的：** 勘定科目一覧テーブル表示

**Props**
- `accounts: AccountDTO[]` — 勘定科目リスト（必須）
- `onDelete: (id: Long) => void` — 削除ボタンのコールバック

**処理**
- [ ] テーブルで勘定科目を一覧表示
- [ ] code, name, accountCategory（借方/貸方）を表示
- [ ] 各行に削除ボタン

---

### AccountForm.tsx

**目的：** 勘定科目フォーム（作成のみ）

**Props**
- `onSave: (data) => Promise<void>` — 保存ボタンのコールバック
- `onCancel: () => void` — キャンセルボタンのコールバック

**State 管理**
- `formData: CreateAccountRequest` — フォームデータ
- `errors: Record<string, string>` — バリデーションエラー
- `loading: boolean` — 送信中フラグ

**処理**
- [ ] コードフィールド（テキスト、20 文字制限）
- [ ] 名前フィールド（テキスト、20 文字制限）
- [ ] 貸借区分ラジオボタン（借方 / 貸方）
- [ ] 保存・キャンセルボタン
- [ ] エラー表示

---

## Common Components

### ErrorAlert.tsx

**目的：** エラーメッセージ表示

**Props**
- `error?: string` — 一般エラーメッセージ
- `fields?: Record<string, string>` — フィールド別エラー

**処理**
- [ ] error と fields がない場合は何も表示しない
- [ ] error があれば表示
- [ ] fields があればリスト表示

---

### LoadingSpinner.tsx

**目的：** ローディング表示

**Props**
- `loading: boolean` — ローディング状態

**処理**
- [ ] loading が false の場合は何も表示しない
- [ ] loading が true の場合、「読み込み中...」を表示

---

### ConfirmDialog.tsx

**目的：** 削除確認ダイアログ

**Props**
- `open: boolean` — ダイアログ表示状態
- `title: string` — タイトル
- `message: string` — メッセージ
- `onConfirm: () => void` — 確定ボタンのコールバック
- `onCancel: () => void` — キャンセルボタンのコールバック

**処理**
- [ ] open が false の場合は何も表示しない
- [ ] open が true の場合、ダイアログを表示
- [ ] 警告文「この操作は取り消せません」を赤色で表示
- [ ] 確定・キャンセルボタン

---

### FormField.tsx

**目的：** ラベル + 入力フィールドの組み合わせ

**Props**
- `label: string` — ラベルテキスト
- `value: string` — フィールド値
- `onChange: (value: string) => void` — 変更コールバック
- `error?: string` — エラーメッセージ

**処理**
- [ ] label を表示
- [ ] input フィールドを表示
- [ ] error があれば赤色で表示

---

## Services

### journalEntryService.ts

**目的：** 仕訳 API 呼び出し

**メソッド一覧**
- [ ] `createJournalEntry(request)` → `Promise<JournalEntryDTO>`
- [ ] `updateJournalEntry(id, request)` → `Promise<JournalEntryDTO>`
- [ ] `deleteJournalEntry(id)` → `Promise<void>`
- [ ] `getJournalEntry(id)` → `Promise<JournalEntryDTO>`
- [ ] `listJournalEntries()` → `Promise<JournalEntryDTO[]>`

**エラーハンドリング**
- [ ] ApiResponse.error がある場合、ApiError を throw
- [ ] ネットワークエラーは catch で処理

---

### accountService.ts

**目的：** 勘定科目 API 呼び出し

**メソッド一覧**
- [ ] `createAccount(request)` → `Promise<AccountDTO>`
- [ ] `deleteAccount(id)` → `Promise<void>`
- [ ] `listAccounts()` → `Promise<AccountDTO[]>`

---

### apiClient.ts

**目的：** HTTP クライアント設定

**処理**
- [ ] axios インスタンスを作成
- [ ] baseURL を設定（環境変数 REACT_APP_API_URL）
- [ ] timeout を設定（5000ms）
- [ ] Content-Type: application/json をデフォルトヘッダーに設定
- [ ] レスポンスインターセプター：401 時はログインページへリダイレクト
- [ ] エラーインターセプター：エラーを Promise.reject で投げる

---

## Hooks

### useJournalEntry.ts

**目的：** 仕訳のロジック管理

**useJournalList()**
- **戻り値**
  - `entries: JournalEntryDTO[]` — 仕訳リスト
  - `loading: boolean` — ローディング状態
  - `error: string?` — エラーメッセージ
  - `refetch: () => Promise<void>` — 再取得関数
- **処理**
  - [ ] マウント時に listJournalEntries() を呼び出し
  - [ ] entries に設定
  - [ ] エラー時は error に設定

**useJournalForm(id?)**
- **パラメータ**
  - `id?: Long` — 編集時の仕訳 ID
- **戻り値**
  - `formData: CreateJournalEntryRequest` — フォームデータ
  - `errors: { general?: string, fields?: Record<string, string> }` — エラー
  - `setFormData: (data) => void` — フォーム更新
  - `submit: () => Promise<boolean>` — 保存処理
  - `loading: boolean` — 送信中フラグ
- **処理**
  - [ ] 初期値は getDefaultFormData()
  - [ ] id がある場合、マウント時に getJournalEntry(id) を呼び出し
  - [ ] submit() は create または update を呼び分け
  - [ ] 成功時は true、失敗時は false を返却

---

### useAccount.ts

**目的：** 勘定科目のロジック管理

**useAccountList()**
- **戻り値**
  - `accounts: AccountDTO[]` — 勘定科目リスト
  - `loading: boolean` — ローディング状態
  - `error: string?` — エラーメッセージ
  - `refetch: () => Promise<void>` — 再取得関数

**useAccountForm()**
- **戻り値**
  - `formData: CreateAccountRequest` — フォームデータ
  - `errors: Record<string, string>` — エラー
  - `setFormData: (data) => void` — フォーム更新
  - `submit: () => Promise<boolean>` — 保存処理
  - `loading: boolean` — 送信中フラグ

---

### useApi.ts

**目的：** API 通信の共通ロジック

**useApi<T>(fn: () => Promise<T>)**
- **パラメータ**
  - `fn: () => Promise<T>` — API 呼び出し関数
- **戻り値**
  - `data: T?` — レスポンスデータ
  - `loading: boolean` — ローディング状態
  - `error: string?` — エラーメッセージ
  - `refetch: () => Promise<void>` — 再実行関数
- **処理**
  - [ ] fn() を呼び出し
  - [ ] データを data に設定
  - [ ] エラー時は error に設定
  - [ ] loading フラグで送信状態を管理

---

## Types

### journal.ts

**型定義**
- [ ] `JournalEntryDTO` — 仕訳データ型
- [ ] `JournalEntryLineDTO` — 仕訳行データ型
- [ ] `CreateJournalEntryRequest` — 仕訳作成リクエスト型
- [ ] `UpdateJournalEntryRequest` — 仕訳更新リクエスト型

---

### account.ts

**型定義**
- [ ] `AccountDTO` — 勘定科目データ型
- [ ] `CreateAccountRequest` — 勘定科目作成リクエスト型

---

### api.ts

**型定義**
- [ ] `ApiResponse<T>` — API レスポンス型（data, error を含む）
- [ ] `ApiError` — API エラー型

**ApiResponse 構造**
```
{
  data: T
  error?: {
    code: string
    message: string
    fields?: Record<string, string>
  }
}
```

---

## 実装チェックリスト

**Backend Kotlin:**
- [ ] メソッドシグネチャが仕様通りか
- [ ] すべてのバリデーションが実装されているか
- [ ] 例外型が仕様通りか
- [ ] 戻り値の型が正確か
- [ ] トランザクション境界が正しいか（@Transactional）
- [ ] SQL が N+1 を回避しているか（LEFT JOIN）
- [ ] Domain Entity は pure（DB 依存なし）か
- [ ] Repository インターフェースを使用しているか

**Frontend React/TypeScript:**
- [ ] TypeScript の型定義が完全か（any を避ける）
- [ ] Props インターフェースが定義されているか
- [ ] State の初期値が適切か
- [ ] API エラーハンドリングが実装されているか
- [ ] 非同期処理に loading フラグがあるか
- [ ] コンポーネント間の責務分割が適切か
- [ ] フォームバリデーションがあるか（フロントとバック両方）
- [ ] useEffect で無限ループが発生していないか


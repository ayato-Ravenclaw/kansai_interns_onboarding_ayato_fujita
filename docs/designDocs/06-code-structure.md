# コード構造設計書

作成日：2026-11-17  
参照：`04-architecture.md`, `01-datamodel.md`

## 概要

会計システムのコード構成。Backend（Kotlin + Spring Boot）と Frontend（React.js + TypeScript）で構成。DDD/クリーンアーキテクチャに基づき、層別にパッケージを分割。

---

## 全体構成

```
accounting-system/
├── backend/                         （Kotlin + Spring Boot）
│   ├── src/main/kotlin/...          （ソース）
│   ├── src/test/kotlin/...          （テスト）
│   ├── build.gradle.kts
│   └── README.md
│
├── frontend/                        （React.js + TypeScript）
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/
│   │   ├── types/
│   │   ├── hooks/
│   │   ├── App.tsx
│   │   └── index.tsx
│   ├── package.json
│   ├── tsconfig.json
│   └── README.md
│
└── docs/
    └── design/                      （設計書）
        ├── 01-datamodel.md
        ├── 02-api-design.md
        ├── ...
        └── 07-method-specifications.md
```

---

## Backend ディレクトリ構造（Kotlin + Spring Boot）

```
backend/
├── src/
│   ├── main/
│   │   ├── kotlin/com/example/accounting/
│   │   │   ├── adapter/
│   │   │   │   ├── inbound/          （入力Adapter）
│   │   │   │   │   ├── controller/
│   │   │   │   │   │   ├── JournalEntryController.kt
│   │   │   │   │   │   └── AccountController.kt
│   │   │   │   │   └── request/      （リクエストDTO）
│   │   │   │   │       ├── CreateJournalEntryRequest.kt
│   │   │   │   │       ├── UpdateJournalEntryRequest.kt
│   │   │   │   │       └── CreateAccountRequest.kt
│   │   │   │   └── outbound/         （出力Adapter）
│   │   │   │       ├── repository/
│   │   │   │       │   ├── JooqJournalEntryRepository.kt
│   │   │   │       │   └── JooqAccountRepository.kt
│   │   │   │       └── mapper/       （Domain ↔ DB 変換）
│   │   │   │           ├── JournalEntryMapper.kt
│   │   │   │           └── AccountMapper.kt
│   │   │   │
│   │   │   ├── application/          （Application層）
│   │   │   │   ├── service/
│   │   │   │   │   ├── CreateJournalEntryUsecase.kt
│   │   │   │   │   ├── UpdateJournalEntryUsecase.kt
│   │   │   │   │   ├── DeleteJournalEntryUsecase.kt
│   │   │   │   │   ├── CreateAccountUsecase.kt
│   │   │   │   │   └── DeleteAccountUsecase.kt
│   │   │   │   └── dto/              （レスポンスDTO）
│   │   │   │       ├── JournalEntryDTO.kt
│   │   │   │       ├── JournalEntryLineDTO.kt
│   │   │   │       └── AccountDTO.kt
│   │   │   │
│   │   │   ├── domain/               （Domain層）
│   │   │   │   ├── entity/
│   │   │   │   │   ├── JournalEntry.kt
│   │   │   │   │   ├── JournalEntryLine.kt
│   │   │   │   │   └── Account.kt
│   │   │   │   ├── value/            （ValueObject）
│   │   │   │   │   ├── Amount.kt
│   │   │   │   │   ├── TransactionDate.kt
│   │   │   │   │   └── AccountCategory.kt
│   │   │   │   ├── service/          （DomainService）
│   │   │   │   │   └── JournalEntryDomainService.kt
│   │   │   │   └── repository/       （Repository インターフェース）
│   │   │   │       ├── JournalEntryRepository.kt
│   │   │   │       └── AccountRepository.kt
│   │   │   │
│   │   │   ├── exception/            （ビジネス例外）
│   │   │   │   ├── ValidationException.kt
│   │   │   │   ├── ConflictException.kt
│   │   │   │   └── NotFoundException.kt
│   │   │   │
│   │   │   └── config/               （設定）
│   │   │       ├── JooqConfig.kt
│   │   │       └── AppConfig.kt
│   │   │
│   │   └── resources/
│   │       ├── db/migration/         （Flyway マイグレーション）
│   │       │   └── V1__init_schema.sql
│   │       └── application.yml
│   │
│   └── test/
│       ├── kotlin/com/example/accounting/
│       │   ├── domain/               （Domain テスト）
│       │   │   ├── entity/
│       │   │   │   ├── JournalEntryTest.kt
│       │   │   │   ├── JournalEntryLineTest.kt
│       │   │   │   └── AccountTest.kt
│       │   │   ├── value/
│       │   │   │   └── AmountTest.kt
│       │   │   └── service/
│       │   │       └── JournalEntryDomainServiceTest.kt
│       │   │
│       │   ├── adapter/              （Repository テスト）
│       │   │   └── outbound/
│       │   │       ├── JournalEntryRepositoryTest.kt
│       │   │       └── AccountRepositoryTest.kt
│       │   │
│       │   ├── application/          （Usecase テスト）
│       │   │   ├── CreateJournalEntryUsecaseTest.kt
│       │   │   ├── UpdateJournalEntryUsecaseTest.kt
│       │   │   ├── DeleteJournalEntryUsecaseTest.kt
│       │   │   ├── CreateAccountUsecaseTest.kt
│       │   │   └── DeleteAccountUsecaseTest.kt
│       │   │
│       │   ├── adapter/              （Controller テスト）
│       │   │   └── inbound/
│       │   │       ├── JournalEntryControllerTest.kt
│       │   │       └── AccountControllerTest.kt
│       │   │
│       │   └── e2e/                  （E2E テスト）
│       │       └── JournalEntryE2ETest.kt
│       │
│       └── resources/
│           └── application-test.yml
│
├── build.gradle.kts                 （Gradle + Kotlin）
└── README.md
```

---

## Backend: パッケージ構成と責務

### 入力Adapter層（`adapter.inbound`）

**パッケージ:** `com.example.accounting.adapter.inbound`

#### controller/

**JournalEntryController.kt**
- 責務：仕訳の HTTP リクエスト/レスポンス処理
- 主要メソッド：
  - `POST /api/journal-entries` → `create(request)`
  - `GET /api/journal-entries` → `findAll()`
  - `GET /api/journal-entries/{id}` → `findById(id)`
  - `PUT /api/journal-entries/{id}` → `update(id, request)`
  - `DELETE /api/journal-entries/{id}` → `delete(id)`

**AccountController.kt**
- 責務：勘定科目の HTTP リクエスト/レスポンス処理
- 主要メソッド：
  - `POST /api/accounts` → `create(request)`
  - `GET /api/accounts` → `findAll()`
  - `DELETE /api/accounts/{id}` → `delete(id)`

#### request/

**CreateJournalEntryRequest.kt**
- プロパティ：`transactionDate`, `memo`, `lines`
- lines はネストされたオブジェクトの配列
- バリデーション：アノテーション（@NotNull, @Size 等）

**UpdateJournalEntryRequest.kt**
- CreateJournalEntryRequest と同じ構造

**CreateAccountRequest.kt**
- プロパティ：`code`, `name`, `accountCategory`
- バリデーション：アノテーション

---

### Application層（`application`）

**パッケージ:** `com.example.accounting.application`

#### service/

**CreateJournalEntryUsecase.kt**
- 責務：仕訳作成のビジネスフロー
- アノテーション：`@Service`, `@Transactional`
- 主要メソッド：
  - `execute(CreateJournalEntryCommand command)` → `JournalEntryDTO`

**UpdateJournalEntryUsecase.kt**
- 責務：仕訳編集のビジネスフロー
- 主要メソッド：
  - `execute(Long id, UpdateJournalEntryCommand command)` → `JournalEntryDTO`

**DeleteJournalEntryUsecase.kt**
- 責務：仕訳削除のビジネスフロー
- 主要メソッド：
  - `execute(Long id)` → `Unit`

**CreateAccountUsecase.kt**
- 責務：勘定科目作成のビジネスフロー
- 主要メソッド：
  - `execute(CreateAccountCommand command)` → `AccountDTO`

**DeleteAccountUsecase.kt**
- 責務：勘定科目削除のビジネスフロー
- 主要メソッド：
  - `execute(Long id)` → `Unit`

#### dto/

**JournalEntryDTO.kt**
- プロパティ：`id`, `transactionDate`, `memo`, `lines`, `createdAt`
- lines は `JournalEntryLineDTO` の配列

**JournalEntryLineDTO.kt**
- プロパティ：`id`, `description`, `debitAccountId`, `debitAccountCode`, `debitAccountName`, `debitAmount`, `creditAccountId`, `creditAccountCode`, `creditAccountName`, `creditAmount`

**AccountDTO.kt**
- プロパティ：`id`, `code`, `name`, `accountCategory`, `createdAt`

---

### Domain層（`domain`）

**パッケージ:** `com.example.accounting.domain`

#### entity/

**JournalEntry.kt**
- 責務：仕訳のドメイン Entity
- プロパティ：`id`, `transactionDate`, `memo`, `createdAt`, `updatedAt`
- 主要メソッド：
  - `companion object { fun create(transactionDate, memo) }` — バリデーション付き create
  - getters

**JournalEntryLine.kt**
- 責務：仕訳行のドメイン Entity
- プロパティ：`id`, `journalEntryId`, `description`, `debitAccountId`, `debitAmount`, `creditAccountId`, `creditAmount`, `createdAt`, `updatedAt`
- 主要メソッド：
  - `companion object { fun create(...) }` — バリデーション付き create
  - 金額は `Amount` ValueObject として扱う

**Account.kt**
- 責務：勘定科目のドメイン Entity
- プロパティ：`id`, `code`, `name`, `accountCategory`, `createdAt`, `updatedAt`
- 主要メソッド：
  - `companion object { fun create(...) }`

#### value/

**Amount.kt**
- 責務：金額の ValueObject
- プロパティ：`value: Int`
- バリデーション：0 より大きい整数のみ
- メソッド：
  - `companion object { fun of(value: Int) }`
  - `plus(other: Amount)` → `Amount`
  - `equals()`, `hashCode()`

**TransactionDate.kt**
- 責務：取引日の ValueObject
- プロパティ：`value: LocalDate`

**AccountCategory.kt**
- 責務：勘定科目カテゴリの Enum
- 値：`DEBIT`, `CREDIT`

#### service/

**JournalEntryDomainService.kt**
- 責務：複数 Entity にまたがるビジネスロジック
- アノテーション：`@Service`（optional、pure logic ならアノテーション不要）
- 主要メソッド：
  - `validateBalance(lines: List<JournalEntryLine>)` → `Unit` (例外で通知)

#### repository/

**JournalEntryRepository.kt（インターフェース）**
- 責務：仕訳の永続化契約
- メソッド：
  - `insert(entry: JournalEntry)` → `Long`
  - `insertLines(entryId: Long, lines: List<JournalEntryLine>)` → `Unit`
  - `findById(id: Long)` → `Optional<JournalEntryWithLines>`
  - `findAll()` → `List<JournalEntryWithLines>`
  - `update(id: Long, entry: JournalEntry)` → `Unit`
  - `delete(id: Long)` → `Unit`
  - `deleteLines(entryId: Long)` → `Unit`

**AccountRepository.kt（インターフェース）**
- 責務：勘定科目の永続化契約
- メソッド：
  - `insert(account: Account)` → `Long`
  - `findById(id: Long)` → `Optional<Account>`
  - `findByCode(code: String)` → `Optional<Account>`
  - `findAll()` → `List<Account>`
  - `delete(id: Long)` → `Unit`
  - `checkIfUsed(id: Long)` → `Boolean`

---

### 出力Adapter層（`adapter.outbound`）

**パッケージ:** `com.example.accounting.adapter.outbound`

#### repository/

**JooqJournalEntryRepository.kt**
- 実装：`JournalEntryRepository` インターフェース
- 責務：jOOQ を使った仕訳の DB 操作
- アノテーション：`@Repository`

**JooqAccountRepository.kt**
- 実装：`AccountRepository` インターフェース
- 責務：jOOQ を使った勘定科目の DB 操作

#### mapper/

**JournalEntryMapper.kt**
- 責務：Domain `JournalEntry` ↔ DB `jOOQ Record` 変換
- 主要メソッド：
  - `toDomain(record: Record)` → `JournalEntry`
  - `toRecord(entry: JournalEntry)` → `Record`

**AccountMapper.kt**
- 責務：Domain `Account` ↔ DB `jOOQ Record` 変換

---

### Exception層（`exception`）

**パッケージ:** `com.example.accounting.exception`

**ValidationException.kt**
- extends `RuntimeException`
- プロパティ：`fieldErrors: Map<String, String>`
- 用途：ビジネスロジックバリデーション失敗時

**ConflictException.kt**
- extends `RuntimeException`
- プロパティ：`message: String`
- 用途：ビジネス規則違反時

**NotFoundException.kt**
- extends `RuntimeException`
- プロパティ：`message: String`
- 用途：リソースが見つからない

---

### Configuration層（`config`）

**パッケージ:** `com.example.accounting.config`

**JooqConfig.kt**
- 責務：jOOQ の DSLContext Bean 定義
- アノテーション：`@Configuration`
- メソッド：`@Bean dslContext()`

**AppConfig.kt**
- 責務：アプリケーション全体の設定
- メソッド：その他必要な Bean 定義

---

## Frontend ディレクトリ構造（React.js + TypeScript）

```
frontend/
├── src/
│   ├── components/
│   │   ├── common/                  （共通コンポーネント）
│   │   │   ├── ErrorAlert.tsx
│   │   │   ├── LoadingSpinner.tsx
│   │   │   ├── ConfirmDialog.tsx
│   │   │   └── FormField.tsx
│   │   │
│   │   ├── journal/                 （仕訳関連）
│   │   │   ├── JournalEntryList.tsx
│   │   │   ├── JournalEntryForm.tsx
│   │   │   ├── JournalEntryLineTable.tsx
│   │   │   ├── JournalEntryLineRow.tsx
│   │   │   └── AccountSelector.tsx
│   │   │
│   │   └── account/                 （勘定科目関連）
│   │       ├── AccountList.tsx
│   │       └── AccountForm.tsx
│   │
│   ├── pages/
│   │   ├── JournalListPage.tsx       （仕訳一覧）
│   │   ├── JournalFormPage.tsx       （仕訳登録・編集）
│   │   ├── AccountListPage.tsx       （勘定科目一覧）
│   │   └── AccountFormPage.tsx       （勘定科目登録）
│   │
│   ├── services/
│   │   ├── journalEntryService.ts    （API 呼び出し）
│   │   ├── accountService.ts
│   │   └── apiClient.ts              （HTTP クライアント設定）
│   │
│   ├── types/
│   │   ├── journal.ts                （仕訳型定義）
│   │   ├── account.ts                （勘定科目型定義）
│   │   └── api.ts                    （API レスポンス型）
│   │
│   ├── hooks/
│   │   ├── useJournalEntry.ts        （仕訳ロジック）
│   │   ├── useAccount.ts             （勘定科目ロジック）
│   │   └── useApi.ts                 （API 通信ロジック）
│   │
│   ├── App.tsx                       （ルート）
│   ├── index.tsx
│   └── styles/
│       └── App.css
│
├── public/
│   ├── index.html
│   └── favicon.ico
│
├── package.json
├── tsconfig.json
└── README.md
```

---

## Frontend: コンポーネント構成と責務

### pages/

**JournalListPage.tsx**
- 責務：仕訳一覧画面全体
- 主要機能：
  - 仕訳一覧を表示
  - 編集・削除ボタン
  - 新規作成ボタン

**JournalFormPage.tsx**
- 責務：仕訳作成・編集画面
- 主要機能：
  - 仕訳フォーム
  - 仕訳行テーブル
  - 保存・キャンセルボタン

**AccountListPage.tsx**
- 責務：勘定科目一覧画面
- 主要機能：
  - 勘定科目一覧表示
  - 削除ボタン
  - 新規作成ボタン

**AccountFormPage.tsx**
- 責務：勘定科目作成画面
- 主要機能：
  - 勘定科目フォーム
  - 保存・キャンセルボタン

---

### components/

#### common/

**ErrorAlert.tsx**
- Props：`error?: string`, `fields?: Record<string, string>`
- 責務：エラーメッセージ表示

**LoadingSpinner.tsx**
- Props：`loading: boolean`
- 責務：ローディング表示

**ConfirmDialog.tsx**
- Props：`open: boolean`, `title: string`, `message: string`, `onConfirm: () => void`, `onCancel: () => void`
- 責務：削除確認ダイアログ

**FormField.tsx**
- Props：`label: string`, `value: string`, `onChange: (value: string) => void`, `error?: string`
- 責務：ラベル + 入力フィールド

#### journal/

**JournalEntryList.tsx**
- Props：`entries: JournalEntryDTO[]`, `onEdit: (id: Long) => void`, `onDelete: (id: Long) => void`
- 責務：仕訳一覧表示

**JournalEntryForm.tsx**
- Props：`initialData?: JournalEntryDTO`, `onSave: (data) => void`, `onCancel: () => void`
- State：フォームデータ、バリデーションエラー
- 責務：仕訳のフォーム入力

**JournalEntryLineTable.tsx**
- Props：`lines: JournalEntryLineDTO[]`, `onAdd: () => void`, `onRemove: (index: number) => void`
- 責務：仕訳行の追加・削除テーブル

**JournalEntryLineRow.tsx**
- Props：`line: JournalEntryLineDTO`, `accounts: AccountDTO[]`, `onChange: (line) => void`
- 責務：仕訳行1行分の編集

**AccountSelector.tsx**
- Props：`accounts: AccountDTO[]`, `value: Long?`, `onChange: (id: Long?) => void`
- 責務：勘定科目セレクタ（ドロップダウン）

#### account/

**AccountList.tsx**
- Props：`accounts: AccountDTO[]`, `onDelete: (id: Long) => void`
- 責務：勘定科目一覧表示

**AccountForm.tsx**
- Props：`onSave: (data) => void`, `onCancel: () => void`
- State：フォームデータ、バリデーションエラー
- 責務：勘定科目のフォーム入力

---

### services/

**journalEntryService.ts**
```typescript
// 仕訳操作
export async function createJournalEntry(data) → JournalEntryDTO
export async function updateJournalEntry(id, data) → JournalEntryDTO
export async function deleteJournalEntry(id) → void
export async function getJournalEntry(id) → JournalEntryDTO
export async function listJournalEntries() → JournalEntryDTO[]
```

**accountService.ts**
```typescript
// 勘定科目操作
export async function createAccount(data) → AccountDTO
export async function deleteAccount(id) → void
export async function listAccounts() → AccountDTO[]
```

**apiClient.ts**
```typescript
// HTTP クライアント設定
export const apiClient = axios.create({
  baseURL: 'http://localhost:8080/api',
  timeout: 5000,
})

// レスポンス・エラーインターセプター設定
```

---

### types/

**journal.ts**
```typescript
interface JournalEntryDTO {
  id: number
  transactionDate: string
  memo?: string
  lines: JournalEntryLineDTO[]
  createdAt: string
}

interface JournalEntryLineDTO {
  id: number
  description?: string
  debitAccountId?: number
  debitAccountCode?: string
  debitAccountName?: string
  debitAmount?: number
  creditAccountId?: number
  creditAccountCode?: string
  creditAccountName?: string
  creditAmount?: number
}
```

**account.ts**
```typescript
interface AccountDTO {
  id: number
  code: string
  name: string
  accountCategory: 'DEBIT' | 'CREDIT'
  createdAt: string
}
```

**api.ts**
```typescript
interface ApiResponse<T> {
  data: T
  error?: {
    code: string
    message: string
    fields?: Record<string, string>
  }
}
```

---

### hooks/

**useJournalEntry.ts**
- 責務：仕訳のロジック管理
- 主要関数：
  - `useJournalList()` → `{ entries, loading, error, refetch }`
  - `useJournalForm(id?)` → `{ formData, errors, setFormData, submit, loading }`

**useAccount.ts**
- 責務：勘定科目のロジック管理
- 主要関数：
  - `useAccountList()` → `{ accounts, loading, error, refetch }`
  - `useAccountForm()` → `{ formData, errors, setFormData, submit, loading }`

**useApi.ts**
- 責務：API 通信の共通ロジック
- 主要関数：
  - `useApi<T>(fn: () => Promise<T>)` → `{ data, loading, error, refetch }`

---

## Backend: パッケージ命名規則

| 層 | パッケージパス | 説明 |
|----|--------------|------|
| 入力Adapter | `adapter.inbound.controller` | HTTP コントローラ |
| 入力Adapter | `adapter.inbound.request` | リクエスト DTO |
| Application | `application.service` | Usecase |
| Application | `application.dto` | レスポンス DTO |
| Domain | `domain.entity` | Entity |
| Domain | `domain.value` | ValueObject |
| Domain | `domain.service` | DomainService |
| Domain | `domain.repository` | Repository インターフェース |
| 出力Adapter | `adapter.outbound.repository` | Repository 実装 |
| 出力Adapter | `adapter.outbound.mapper` | Domain ↔ DB 変換 |
| Exception | `exception` | ビジネス例外 |
| Config | `config` | Bean 定義 |

---

## Backend: ファイル命名規則

| 要素 | パターン | 例 |
|------|---------|-----|
| Entity | `{名前}.kt` | `JournalEntry.kt` |
| ValueObject | `{名前}.kt` | `Amount.kt` |
| Controller | `{機能名}Controller.kt` | `JournalEntryController.kt` |
| Usecase | `{機能名}Usecase.kt` | `CreateJournalEntryUsecase.kt` |
| Repository インターフェース | `{Entity名}Repository.kt` | `JournalEntryRepository.kt` |
| Repository 実装 | `Jooq{Entity名}Repository.kt` | `JooqJournalEntryRepository.kt` |
| DTO | `{Entity名}DTO.kt` | `JournalEntryDTO.kt` |
| Request | `{機能名}Request.kt` | `CreateJournalEntryRequest.kt` |
| Exception | `{名前}Exception.kt` | `ValidationException.kt` |
| Test | `{対象クラス}Test.kt` | `JournalEntryTest.kt` |

---

## Frontend: ファイル命名規則

| 要素 | パターン | 例 |
|------|---------|-----|
| Page | `{Page名}Page.tsx` | `JournalListPage.tsx` |
| Component | `{名前}.tsx` | `JournalEntryForm.tsx` |
| Service | `{機能名}Service.ts` | `journalEntryService.ts` |
| Hook | `use{名前}.ts` | `useJournalEntry.ts` |
| Type | `{機能名}.ts` | `journal.ts` |
| Test | `{対象ファイル}.test.tsx` | `JournalEntryForm.test.tsx` |

---

## 相互参照の方向性（Backend 依存関係）

```
Controller
  ↓
Usecase（@Autowired Repository インターフェース）
  ↓
Domain Entity + DomainService
  ↓
Repository インターフェース（Domain が定義）
  ↓
Repository 実装（Adapter が実装）
  ↓
jOOQ + DB
```

**ルール：**
- 上位層から下位層への参照のみ OK
- 下位層から上位層への参照は NG（依存性逆転）
- Repository は Domain パッケージに定義、Adapter で実装

---

## 相互参照の方向性（Frontend）

```
Page (JournalListPage)
  ↓
Component (JournalEntryList, ErrorAlert)
  ↓
Hook (useJournalEntry)
  ↓
Service (journalEntryService)
  ↓
API Client (apiClient)
  ↓
Backend API
```

**ルール：**
- Page は Component と Hook を使用
- Component は他の Component と Hook を使用
- Hook は Service を使用
- Service は apiClient を使用
- 循環参照なし

---

## 注意点

**Backend:**
1. Domain パッケージの純粋性：DB フレームワーク（jOOQ）の import は Domain パッケージに含めない
2. Repository インターフェースの場所：Domain パッケージに定義（Adapter ではなく）
3. Usecase のトランザクション：`@Transactional` は Application Service に付与
4. Exception クラス：ビジネス例外は `exception` パッケージで一元管理
5. Mapper の使用：Repository 実装内でのみ使用

**Frontend:**
1. TypeScript の型定義を厳密に（any は避ける）
2. Component の Props は interface で定義
3. API エラーハンドリングは useApi hook で一元管理
4. 共通コンポーネントは components/common に集約
5. ページ遷移は React Router で管理


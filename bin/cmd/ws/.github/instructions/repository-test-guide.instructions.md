---
applyTo: '**/app/repositories/*.go'
---

description: |
This guide provides instructions for testing repository code in the Persia project.
It includes steps for setting up the test environment, running tests, and verifying results.

# Repository 層テスト実装ガイド

## 🎯 実装方針

あなたは Go 言語の Repository 層の単体テストを実装する専門家です。以下の原則に従って、**完全で保守性の高いテストコード**を生成してください。

### 基本要件

- **完全性**: 対象メソッドのすべてのパスを網羅
- **保守性**: 一貫した命名規則とパターンに従う
- **実用性**: プロダクション品質のテストコード

---

## 🔍 実装前の準備（必須）

### ⚠️ 重要: 既存テスト関数の保護

**テスト関数の生成を依頼された場合、すでに実装されているテスト関数については絶対に変更を加えず、依頼されたテスト関数の生成のみを行ってください。**

- ✅ 新しいテスト関数のみを追加
- ❌ 既存のテスト関数の修正・削除は禁止
- ❌ 既存のテストケースの変更は禁止

### 1. 対象メソッドの実装理解

テスト実装前に、対象メソッドの実際の動作を必ず確認してください。

```go
// 例：実装を確認してからテストケースを設計
func (r repository) FindByID(ctx context.Context, id ID) (Entity, error) {
    // 実際の実装を確認し、成功・失敗パターンを特定
}
```

### 2. テストデータの探索

```bash
find ./repositories/testhelper/ -name "test_data_*.go"
```

### 3. メソッドシグネチャの確認

実際のメソッドシグネチャを正確に取得し、パラメータ名をテストで使用してください。

### 4. テストデータの準備

必要に応じて新しいテストデータを生成してください：

```go
// testhelper/test_data_{entity}.go の形式で作成
type {Entity}TestData struct {
    Query  queries.{Entity}    // DB層の構造体
}

var {Entity}1 = {Entity}TestData{
    Query: queries.{Entity}{
        ID:       "a1b2c3d4-e5f6-7890-abcd-ef1234567890",  // UUIDV4形式
        Name:      "test_name_1",
        CreatedAt: time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC),
        UpdatedAt: time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC),
    },
}

// Edit機能（動的データ変更用）
func (t {Entity}TestData) Edit(f func(t *{Entity}TestData)) {Entity}TestData {
    copied := t
    f(&copied)
    return copied
}
```

---

## 🏗️ テストケース設計パターン

### CRUD 操作の基本パターン

**テストケースの分類:**

- ✅ **成功パターン**: 正常に動作する期待されるケース
- ❌ **失敗パターン**: エラーが発生する異常系ケース

#### Create 系メソッド

- ✅ 成功パターン
- ❌ 制約違反（Unique 制約等）
- ❌ 外部キー制約違反
- ❌ 不正な値（空文字、NULL 等）

#### Find/Get 系メソッド

- ✅ 成功パターン（データあり）
- ✅ 成功パターン（データなし）
- ✅ フィルタ条件の組み合わせ
- ✅ 空の引数の場合
- ✅ WHERE 句の各条件の個別テスト（下記参照）

#### Update 系メソッド

- ✅ 成功パターン
- ❌ 対象データが存在しない
- ❌ 制約違反

#### Delete 系メソッド

- ✅ 成功パターン
- ✅ 対象データが存在しない（通常はエラーなし）
- ❌ 外部キー制約違反

---

## WHERE 句条件の個別テストパターン

Repository メソッドで WHERE 句による条件絞り込みがある場合、**各条件を個別にテストする**ことで、SQL クエリの条件漏れやロジックエラーを確実に検出できます。

### 基本方針

**各 WHERE 条件パラメータについて、その条件だけを変更したテストケースを作成する**

```sql
-- 例：以下のようなクエリがある場合
SELECT * FROM table
WHERE company_id = ?
  AND procedure_id = ?
  AND member_id = ?
  AND egov_procedure_id = ?
```

### テストケースパターン

#### 1. 正常ケース

```go
{
    name: "success: get records",
    companyID: testhelper.CompanyTestData1.CompanyID,
    args: args{
        procedureID:     testhelper.ProcedureTestData1.Query.ID,
        memberID:        testhelper.MemberTestData1.ID,
        egovProcedureID: testhelper.EgovProcedureTestID1,
    },
    inserter: sharedInserter.Add(
        queries.TargetTable.TableName,
        testhelper.TestData1,
    ),
    expected: expectedResults,
    errAssertion: assert.NoError,
},
```

#### 2. 各 WHERE 条件の個別フィルタテスト

```go
{
    name: "success: 1 initial record, get 0 record (filtered by companyID)",
    companyID: 0, // 異なるcompanyIDを設定
    args: args{
        procedureID:     testhelper.ProcedureTestData1.Query.ID,     // 正常値
        memberID:        testhelper.MemberTestData1.ID,              // 正常値
        egovProcedureID: testhelper.EgovProcedureTestID1,            // 正常値
    },
    inserter: sharedInserter.Add(
        queries.TargetTable.TableName,
        testhelper.TestData1, // 正常なテストデータを投入
    ),
    expected: []queries.TargetTable{}, // 結果は空になる
    errAssertion: assert.NoError,
},
{
    name: "success: 1 initial record, get 0 record (filtered by procedureID)",
    companyID: testhelper.CompanyTestData1.CompanyID,               // 正常値
    args: args{
        procedureID:     uuid.Nil,                                  // 異なるprocedureIDを設定
        memberID:        testhelper.MemberTestData1.ID,              // 正常値
        egovProcedureID: testhelper.EgovProcedureTestID1,            // 正常値
    },
    inserter: sharedInserter.Add(
        queries.TargetTable.TableName,
        testhelper.TestData1, // 正常なテストデータを投入
    ),
    expected: []queries.TargetTable{}, // 結果は空になる
    errAssertion: assert.NoError,
},
{
    name: "success: 1 initial record, get 0 record (filtered by memberID)",
    companyID: testhelper.CompanyTestData1.CompanyID,               // 正常値
    args: args{
        procedureID:     testhelper.ProcedureTestData1.Query.ID,     // 正常値
        memberID:        uuid.Nil,                                   // 異なるmemberIDを設定
        egovProcedureID: testhelper.EgovProcedureTestID1,            // 正常値
    },
    inserter: sharedInserter.Add(
        queries.TargetTable.TableName,
        testhelper.TestData1, // 正常なテストデータを投入
    ),
    expected: []queries.TargetTable{}, // 結果は空になる
    errAssertion: assert.NoError,
},
{
    name: "success: 1 initial record, get 0 record (filtered by egovProcedureID)",
    companyID: testhelper.CompanyTestData1.CompanyID,               // 正常値
    args: args{
        procedureID:     testhelper.ProcedureTestData1.Query.ID,     // 正常値
        memberID:        testhelper.MemberTestData1.ID,              // 正常値
        egovProcedureID: uuid.Nil,                                   // 異なるegovProcedureIDを設定
    },
    inserter: sharedInserter.Add(
        queries.TargetTable.TableName,
        testhelper.TestData1, // 正常なテストデータを投入
    ),
    expected: []queries.TargetTable{}, // 結果は空になる
    errAssertion: assert.NoError,
},
```

### 実装時の注意点

#### 1. テストデータは正常値を使用

```go
// ❌ 悪い例：テストデータも条件に合わせて変更
inserter: sharedInserter.Add(
    queries.TargetTable.TableName,
    testhelper.TestDataWithWrongCompanyID, // 間違ったcompanyIDのテストデータ
),

// ✅ 良い例：テストデータは正常値、条件のみ変更
inserter: sharedInserter.Add(
    queries.TargetTable.TableName,
    testhelper.TestData1, // 正常なテストデータ
),
```

#### 2. 1 条件ずつテスト

```go
// ❌ 悪い例：複数条件を同時に変更
companyID: 0,
args: args{
    procedureID: uuid.Nil,  // 複数条件を同時に変更
    memberID:    uuid.Nil,
},

// ✅ 良い例：1条件のみ変更
companyID: 0,              // companyIDのみ変更
args: args{
    procedureID: testhelper.ProcedureTestData1.Query.ID,  // 正常値
    memberID:    testhelper.MemberTestData1.ID,           // 正常値
},
```

#### 3. 期待結果は空配列（Select のクエリの場合）

```go
expected: []queries.TargetTable{}, // フィルタされて結果なし
errAssertion: assert.NoError,      // エラーなし
```

### 適用対象メソッド

以下のメソッドタイプに適用：

- **Get/Find 系**: 条件検索するメソッド
- **Update 系**: WHERE 句で対象を絞り込むメソッド
- **Delete 系**: WHERE 句で対象を絞り込むメソッド

### 効果

- **SQL クエリの検証**: WHERE 句の条件が正しく動作するか確認
- **ロジックエラーの検出**: 条件分岐の漏れやミスを発見
- **リグレッション防止**: 条件変更時の影響を早期発見
- **仕様の明確化**: メソッドがどの条件で絞り込むかを明示

---

## テストコード実装パターン

### 基本テンプレート

```go
func Test_{repositoryName}_{methodName}(t *testing.T) {
    // モック時刻設定
    now := time.Date(2025, 1, 1, 0, 0, 0, 0, time.UTC)

    tests := []struct {
        name         string
        // 入力パラメータ（実際のメソッドシグネチャに合わせる）
        entityParam  domain.Entity          // Create系の場合
        entityID     domain.ID              // Find/Update/Delete系の場合
        filter       domain.Filter          // Filter系の場合
        // テストデータ
        inserter     testhelper.Inserter
        // 期待値
        expected     []queries.{Table}      // 期待される結果
        errAssertion assert.ErrorAssertionFunc // テスト対象の関数を実行した際のエラーの期待値
    }{
        {
            name: "success",
            entityParam: domain.Entity{
                ID:   domain.ID("a1b2c3d4-e5f6-7890-abcd-ef1234567890"),  // UUIDV4形式
                Name: "test_name",
            },
            inserter: testhelper.NewInserter(),
            errAssertion: assert.NoError,
            expected: []queries.{Table}{
                {
                    ID:        "a1b2c3d4-e5f6-7890-abcd-ef1234567890",  // UUIDV4形式
                    Name:      "test_name",
                    CreatedAt: now,
                    UpdatedAt: now,
                },
            },
        },
        {
            name: "failure: constraint violation",
            entityParam: domain.Entity{
                ID:   domain.ID(testhelper.Entity1.Query.ID),
                Name: "duplicate_name",
            },
            inserter: testhelper.NewInserter().
                Add(queries.{Table}Table.TableName, testhelper.Entity1.Query),
            errAssertion: testutils.AssertErrorCode(codes.Internal),
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            testDB().Run(t, func(ctx context.Context, db db.DB) {
                // コンテキスト設定（必要に応じて）
                ctx = ctxlib.SetContextWithCompanyID(ctx, tt.companyID)
                ctx = ctxfunc.WithFixedTime(ctx, now)

                // リポジトリとクエリの初期化
                repo := New{Repository}(db, dependencies...)
                queries := db.Queries(ctx)

                // テストデータ挿入（前提条件なのでrequire）
                conn, err := db.Conn(ctx)
				require.NoError(t, err)
				require.NoError(t, tt.inserter.InsertAll(ctx, conn))

                // テスト実行
                result, err := repo.{MethodName}(ctx, tt.entityParam)

                // エラーアサーション
                tt.errAssertion(t, err)

                // 結果検証のために再度クエリを発行する必要がある場合のみ、以下のif文を追加
                if err != nil {
                    return
                    // テストケースごとにトランザクションを貼っているため、ここでエラーが発生した場合は後続のDB操作ができない。そのためスキップ
                }

                // 結果検証
                got, err := queries.Get{Table}sForTest(ctx) // sqlcで生成されたテスト用の取得クエリを使用
                require.NoError(t, err)
                assert.Equal(t, tt.expected, got) // assertを使用する
            })
        })
    }
}
```

---

## 🔧 実装パターン詳細

### 1. 命名規則

```go
// テスト関数
func Test_{repositoryName}_{methodName}(t *testing.T) {}

// テストケース構造体
tests := []struct {
    name         string                        // テストケース名
    entityParam  domain.Entity                 // 実際のパラメータ名を使用
    inserter     testhelper.Inserter           // 初期データの投入
    errAssertion assert.ErrorAssertionFunc     // テスト対象の関数を実行した際のエラーの期待値
    expected     []queries.{Table}             // 期待される結果
}{}
```

### 2. testDB().Run パターン

```go
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        testDB().Run(t, func(ctx context.Context, db db.DB) {
            ctx = ctxlib.SetContextWithCompanyID(ctx, tt.companyID)
            ctx = ctxfunc.WithFixedTime(ctx, now)

            // Repository初期化時の依存関係設定
            repo := New{Repository}(db, dependencies...)
            queries := db.Queries(ctx)

            // コネクション取得とテストデータ投入
            conn, err := db.Conn(ctx)
            require.NoError(t, err)
            require.NoError(t, tt.inserter.InsertAll(ctx, conn))

            // テスト実行と結果検証
        })
    })
}
```

### Repository 初期化時の依存関係設定

Repository 初期化時に外部サービスへの依存がある場合は、テスト用の Fake 実装を使用します。

#### storage.FileService の場合

ファイルストレージサービスを使用する Repository では、`storage.NewFakeStorageClient()`を使用します。

**使用例：**

```go
// repositories/egov_attached_file_test.go より
repo := repositories.NewEgovAttachedFileRepository(db, storage.NewFakeStorageClient())
```

**適用場面：**

- ファイルのアップロード・ダウンロード・削除機能を持つ Repository
- 外部ストレージ（GCS 等）との連携が必要な Repository

#### drivers.BengalConn の場合

Bengal（外部 API）への接続が必要な Repository では、`testdb.FakeBengalConn()`を使用します。

**使用例：**

```go
// repositories/custom_document_group_member_test.go より
repo := NewCustomDocumentGroupMemberRepository(db, testdb.FakeBengalConn())
```

**適用場面：**

- 外部プロダクト（Bengal）との通信が必要な Repository
- マイクロサービス間の連携機能を持つ Repository

#### testhelpergen ツールを使ったモック構造体の場合

repository が DB 以外に依存しており、モックの機能が必要な場合は、`testhelpergen`ツールを使用して自動生成されたモックを依存性の注入に使用します。

**手順：**

1. 使いたい Repository のコンストラクタを`tools/testhelpergen/cmd/main.go`の`configs`の`Functions`に追加
2. app 配下で`make gen-mock`を実行してモックを自動生成
3. 生成されたモック構造体をテストで使用

**例：**

```go
// tools/testhelpergen/cmd/main.go のconfigsに追加
{
    OutputDir:   "repositories/testhelper",
    Filename:    "mock_helpers.gen.go",
    PackageName: "testhelper",
    Functions: []any{
        repositories.NewTargetRepository,  // 追加
        // 他の既存のコンストラクタ...
    },
    // MockPackageMapの設定...
}
```

**テストでの使用：**

```go
func Test_egovECertificateRepository_DownloadEgovECertificateFile(t *testing.T) {
    tests := []struct {
        name               string
        envelopeEncryption egov.Encryption
        filePath           string
        keyPath            string
        mock               func(ctx context.Context, mockHelper *testhelper.EgovECertificateRepositoryMockHelper)
        want               []byte
        errAssertion       assert.ErrorAssertionFunc
    }{
        {
            name:               "success",
            envelopeEncryption: testhelper.EGovEnvelopeEncryption,
            filePath:           "test/file/path",
            keyPath:            "test/key/path",
            mock: func(ctx context.Context, mockHelper *testhelper.EgovECertificateRepositoryMockHelper) {
                // FileServiceのモックを設定
                mockHelper.GetMockFileService().EXPECT().Download(ctx, "test/key/path").Return("", []byte(testhelper.EgovEncryption1_EncryptedKeyB64), nil)
                mockHelper.GetMockFileService().EXPECT().Download(ctx, "test/file/path").Return("", []byte(testutils.Must(testhelper.EGovEncryption1.EncryptToString([]byte("test data")))), nil)
            },
            want:         []byte("test data"),
            errAssertion: assert.NoError,
        },
        // 他のテストケース...
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            ctx := t.Context()

            // MockHelperを作成し、モック設定を実行
            mockHelper := testhelper.NewEgovECertificateRepositoryMockHelper(t)
            tt.mock(ctx, mockHelper)

            // MockHelperを使ってRepositoryを初期化
            r := mockHelper.NewEgovECertificateRepository(testdb.FakeDBConn(t), tt.envelopeEncryption)

            // テスト実行
            got, err := r.DownloadEgovECertificateFile(ctx, tt.filePath, tt.keyPath)
            tt.errAssertion(t, err)
            assert.Equal(t, tt.want, got)
        })
    }
}
```

**使用パターンの説明：**

1. **MockHelper の作成**: `testhelper.New{Repository}MockHelper(t)`でモックヘルパーを作成
2. **モック設定**: `mockHelper.GetMock{Service}().EXPECT()`でモックの期待値を設定
3. **Repository 初期化**: `mockHelper.New{Repository}()`でモック付きの Repository を作成
4. **テスト実行**: 通常通り Repository のメソッドを呼び出し

**利点：**

- gomock を使った高度なモック機能が利用可能
- 自動生成により保守性が向上

**注意点：**

- 実際の Repository コンストラクタの引数順序と型を正確に確認する
- テスト用の Fake 実装は実際の API と同じインターフェースを実装している

### 3. テスト用の取得クエリの実装

テスト後のデータ検証のため、`repositories/db/sql` 配下の関連する SQL ファイルにテスト用の取得クエリを追加する必要があります。

**手順:**

1. 対象テーブルに対応する SQL ファイル（例：`repositories/db/sql/{table_name}.sql`）を開く
2. ファイル末尾に以下のクエリを追加：

```sql
-- name: Get{Table}sForTest :many
SELECT * FROM {table_name};
```

**例:**

```sql
-- name: GetPayslipsForTest :many
SELECT * FROM payslips;

-- name: GetEgovApplicationsForTest :many
SELECT * FROM egov_applications;
```

3. クエリ追加後、`app` ディレクトリで以下のコマンドを実行してコード生成：

```bash
make gen-sql
```

**注意点:**

- クエリ名は `Get{Table}sForTest` の形式で統一する（複数形）
- `SELECT *` を使用してすべてのカラムを取得する
- **生成ファイルの編集禁止**: `make gen-sql`で生成されるファイル（例：`egov_applications.sql.go`）は絶対に編集しない
- **追加機能の実装**: queries パッケージに追加の関数が必要な場合は、別ファイルを作成する（例：`egov_applications.go`）

### 4. プライベートメソッドのテスト

Repository 内のプライベートメソッドをテストする場合は、export 用のファイルを作成してメソッドを公開します。

**手順:**

1. `repositories/{repository_name}_export_test.go` ファイルを作成
2. テスト対象のプライベートメソッドを公開するインターフェースと struct を定義

**例:** `repositories/egov_attached_file_export_test.go`

```go
package repositories

import (
	"context"
	"github.com/hrbrain/hrbrain/apps/persia/app/domain"
	"github.com/hrbrain/hrbrain/apps/persia/app/repositories/db"
)

// テスト用に公開するインターフェース
type ExportedEgovAttachedFileRepository interface {
	EgovAttachedFileRepository  // 元のインターフェースを埋め込み
	// プライベートメソッドを公開
	DeleteDraftAttachedFile(ctx context.Context, id domain.ID) error
}

// テスト用のコンストラクタ
func NewExportEgovAttachedFileRepository(db db.DB) ExportedEgovAttachedFileRepository {
	return &exportedEgovAttachedFileRepository{
		egovAttachedFileRepository: egovAttachedFileRepository{
			db: db,
		},
	}
}

// テスト用のstruct
type exportedEgovAttachedFileRepository struct {
	egovAttachedFileRepository  // 元のstructを埋め込み
}

// プライベートメソッドを公開
func (e exportedEgovAttachedFileRepository) DeleteDraftAttachedFile(ctx context.Context, id domain.ID) error {
	return e.egovAttachedFileRepository.deleteDraftAttachedFile(ctx, id)
}
```

**テストでの使用:**

```go
// テスト内で使用
repo := NewExportEgovAttachedFileRepository(db)
err := repo.DeleteDraftAttachedFile(ctx, testID)  // プライベートメソッドをテスト
```

**注意点:**

- ファイル名は必ず `{repository_name}_export_test.go` の形式にする
- テストビルド時のみコンパイルされるよう `_test.go` サフィックスを使用
- 元の struct を埋め込み（embedded）して機能を継承する

### 5. testhelper.Inserter パターン

testhelper.Inserter を使用してテストデータを挿入する際は、外部キー制約に注意してデータの投入順序を正しく設定する必要があります。

**基本的な Inserter:**

```go
inserter: testhelper.NewInserter().
    Add(queries.{Table}Table.TableName, testhelper.Entity1.Query),
```

**複数テーブルの Inserter:**

```go
inserter: testhelper.NewInserter().
    Add(queries.{Table1}Table.TableName,
        testhelper.Entity1.Query,
        testhelper.Entity2.Query).
    Add(queries.{Table2}Table.TableName, testhelper.RelatedEntity1.Query),
```

**外部キー制約を考慮したデータ投入順序:**

データベーススキーマは `./repositories/db/schema.sql` で定義されています。外部キー制約により、親テーブルのデータを先に投入する必要があります。

**投入順序の例:**

```go
inserter: testhelper.NewInserter().
    // 1. 親テーブル（外部キー参照されるテーブル）を先に投入
    Add(queries.CompaniesTable.TableName, testhelper.Company1.Query).
    Add(queries.OfficesTable.TableName, testhelper.Office1.Query).
    // 2. 子テーブル（外部キーを持つテーブル）を後に投入
    Add(queries.OfficeMembersTable.TableName, testhelper.OfficeMember1.Query).
    Add(queries.PayslipsTable.TableName, testhelper.Payslip1.Query),
```

**よくある外部キー関係:**

- `companies` → `offices` → `office_members`
- `companies` → `payslip_templates` → `payslips`
- `companies` → `procedures` → `member_procedures`

**注意点:**

- スキーマファイルで CONSTRAINT 定義を確認してから投入順序を決める
- 外部キー制約違反によるテスト失敗を避けるため、依存関係を正しく把握する

### 6. sharedInserter パターン

すべてのテストケースに共通で投入したい初期データがある場合は、`sharedInserter`を使用します。これにより、テストケース間でのデータ重複を避け、保守性を向上させることができます。

**基本的な sharedInserter の定義:**

```go
func Test_repositoryName_methodName(t *testing.T) {
    // 全テストケースに共通で必要なデータ
    sharedInserter := testhelper.NewInserter().
        Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query)

    tests := []struct {
        // ...テストケース定義
        inserter testhelper.Inserter
    }{
        {
            name: "basic case",
            // sharedInserterをベースに追加データを投入
            inserter: sharedInserter.
                Add(queries.MemberProceduresTable.TableName, testhelper.MemberProcedureTestData1.Query),
            // ...
        },
        {
            name: "multiple records case",
            // sharedInserterをベースに複数の追加データを投入
            inserter: sharedInserter.
                Add(queries.MemberProceduresTable.TableName,
                    testhelper.MemberProcedureTestData1.Query,
                    testhelper.MemberProcedureTestData2.Query).
                Add(queries.EgovApplicationDraftAttachedFilesTable.TableName,
                    testhelper.EgovApplicationDraftAttachedFile1,
                    testhelper.EgovApplicationDraftAttachedFile2),
            // ...
        },
        {
            name: "no additional data case",
            // sharedInserterのみを使用（追加データなし）
            inserter: sharedInserter,
            // ...
        },
    }
    // ...テスト実行
}
```

**使用例（repositories/egov_attached_file_test.go より）:**

```go
func Test_egovAttachedFileRepository_GetDraftAttachedFilesByMemberIDsAndEgovProcedureIDs(t *testing.T) {
    // 全テストケースで必要な基本データ
    sharedInserter := testhelper.NewInserter().
        Add(queries.ProceduresTable.TableName, testhelper.ProcedureTestData1.Query)

    tests := []struct {
        name             string
        // ...他のフィールド
        inserter         testhelper.Inserter
    }{
        {
            name: "no initial record, get no record",
            // sharedInserterのみ（追加データなし）
            inserter: sharedInserter,
        },
        {
            name: "1 initial record, get no record (wrong procedureID)",
            // sharedInserterに追加データを投入
            inserter: sharedInserter.
                Add(queries.MemberProceduresTable.TableName, testhelper.MemberProcedureTestData1.Query).
                Add(queries.EgovApplicationDraftAttachedFilesTable.TableName, testhelper.EgovApplicationDraftAttachedFile_mpid1_epid1_1),
        },
        {
            name: "3 initial record, get 1 record",
            // sharedInserterに複数の追加データを投入
            inserter: sharedInserter.
                Add(queries.MemberProceduresTable.TableName,
                    testhelper.MemberProcedureTestData1.Query,
                    testhelper.MemberProcedureTestData2.Query).
                Add(queries.EgovApplicationDraftAttachedFilesTable.TableName,
                    testhelper.EgovApplicationDraftAttachedFile_mpid1_epid1_1,
                    testhelper.EgovApplicationDraftAttachedFile_mpid2_epid1_1,
                    testhelper.EgovApplicationDraftAttachedFile_mpid1_epid2_1),
        },
    }
}
```

**sharedInserter の利点:**

- **コード重複の削減**: 共通のテストデータを一箇所で定義
- **保守性の向上**: 共通データの変更時は 1 箇所の修正で済む
- **テストの可読性向上**: 各テストケースは差分データのみに集中できる
- **外部キー制約の一元管理**: 基本的な依存関係を一箇所で解決

**注意点:**

- 外部キー制約を考慮して、sharedInserter には最も基本的な親テーブルのデータを配置する
- sharedInserter のデータは全テストケースで使用されるため、特定のテストケースに依存しないデータを選ぶ

### ６. モック設定パターン

```go
// 時刻をモックする場合（以下のような場面で使用します）
// - INSERT処理において、created_atカラムを固定された時刻にしたい場合
// - UPDATE処理において、updated_atカラムを固定された時刻にしたい場合
// - SELECT処理のフィルタリング条件において、現在時刻を固定された値にしたい場合
// - Repository関数内で呼び出されている ctxfunc.GetNow(ctx) の戻り値を固定された時刻にしたい場合
ctx = ctxfunc.WithFixedTime(ctx, now)

// CompanyIDをモックする場合（Repository処理内で ctxlib.GetCompanyIDFromContext(ctx) を呼び出している場合は必ず使用してください）
ctx = ctxlib.SetContextWithCompanyID(ctx, tt.companyID)
```

### ７. エラーアサーションパターン

```go
errAssertion: assert.NoError,                    // 成功ケース
errAssertion: testutils.AssertErrorCode(codes.NotFound),    // 404
errAssertion: testutils.AssertErrorCode(codes.Internal),    // 500

```

### ８. require vs assert の使い分け

```go
// require: テストの継続が不可能な前提条件
require.NoError(t, tt.inserter.InsertAll(ctx, conn))  // データ挿入失敗時は継続不可

// assert: テストの継続が可能な検証
assert.Equal(t, expected, got)   // 値の比較（他のフィールドも確認したい）
assert.Len(t, result, 3)         // 長さの確認（要素の中身も確認したい）

// パターン例
require.NoError(t, tt.inserter.InsertAll(ctx, conn))  // 前提条件
result, err := repo.GetByFilter(ctx, tt.filter)
tt.assertion(t, err) // エラーアサーション
assert.Equal(t, tt.expected, result) // 追加の検証
```

---

## 📋 実装チェックリスト

### 必須項目

- [ ] 対象メソッドの実装を理解した
- [ ] 利用可能な testhelper データを調査した
- [ ] 必要に応じて新しいテストデータを作成した
- [ ] メソッドシグネチャを正確に確認した
- [ ] 成功・失敗の全パターンを網羅した
- [ ] WHERE 句の各条件を個別にテストした（該当する場合）
- [ ] 適切なモック設定を行った
- [ ] require/assert を適切に使い分けた
- [ ] 命名規則を遵守した

### 品質確認

- [ ] テストケース名から期待動作が理解できる
- [ ] エラーハンドリングが適切
- [ ] 最小限のテストデータを使用
- [ ] 他のテストとの一貫性を保っている

---

## 🔧 カスタマイズポイント

### ドメイン固有の置換項目

```go
// テンプレート内で以下を実際の値に置換
{repositoryName}     → procedureRepository, payslipRepository 等
{methodName}         → Create, FindByID, GetByFilter 等
{Repository}         → ProcedureRepository, PayslipRepository 等
{Table}              → Procedures, Payslip 等
{Entity}             → Procedure, Payslip 等（型名）
```

## テストケース名の命名規則

テストケース名は内容が明確に分かるような英語で簡潔に記述します。以下の命名規則に従ってください：

**基本ルール:**

- ✅ **成功パターン**: `"success: {具体的な条件}"`で始める
- ❌ **失敗パターン**: `"failure: {エラーの原因}"`で始める

**成功パターンの例:**

```go
{
    name: "success",                           // 基本的な成功ケース
},
{
    name: "success: multiple records found",   // 複数件取得成功
},
{
    name: "success: no records found",         // データなしでも成功
},
{
    name: "success: 1 initial record, get 0 record (filtered by companyID)"  // フィルタ条件付き成功
},
```

**失敗パターンの例:**

```go
{
    name: "failure: constraint violation",     // 制約違反
},
{
    name: "failure: record not found",         // データが存在しない
},
{
    name: "failure: invalid input",            // 不正な入力値
},
```

**注意点:**

- 英語で記述し、内容を一目で理解できるようにする
- 条件や期待結果を明確に表現する
- 簡潔さを保ちつつ、具体性を重視する

---

## 🚨 重要な制約

### 必須制約

1. **実装理解**: テスト前に必ず対象メソッドの実装を理解する
2. **DB 選択**: テストの要件に応じて適切な DB を選択
   - `testDB()`: `repositories/db/unit_test_data.sql`の初期データが入った DB を使用（多くの場合）
   - `freshDB()`: 何もレコードが入っていない DB を使用（初期データが不要な場合）
3. **エラー後のスキップ**: エラー発生時は`return`で後続処理をスキップ
4. **モック設定**: 時刻とコンテキストは適切に設定
5. **パラメータ名**: 実際のメソッドシグネチャと完全に一致
6. **UUIDV4 形式**: テストデータの UUID は必ず UUIDV4 形式を使用
7. **自動生成ファイルの編集禁止**:
   以下のファイルは自動生成されるため、絶対に手動で編集しないでください：
   - `*.sql.go` - SQL クエリから自動生成されるファイル（`make gen-sql`コマンドで生成）
   - `*.gen.go` - その他の自動生成ファイル

### パフォーマンス制約

- 最小限のテストデータを使用
- 不要なテーブルへのデータ挿入は避ける
- 共通の Inserter を活用

### 保守性制約

- 一貫した命名規則の遵守
- テストデータの適切な管理
- コード重複の最小化

---

このガイドに従って、プロジェクトの特性に合わせて置換項目を調整し、完全で保守性の高い Repository 層テストを実装してください。

- [ ] 実際のコードベースパターンに従っている
- [ ] プライベートメソッドの場合は export 用のファイルを作成している
- [ ] testhelper.Inserter を適切に使用している
- [ ] sharedInserter を使用している場合は、全テストケースで共通のデータを投入している
- [ ] WHERE 句の各条件を個別にテストしている（該当する場合）
- [ ] モック設定が適切に行われている
- [ ] エラーアサーションが適切に行われている
- [ ] テストケース名が明確で一貫性がある
- [ ] テストケースの命名規則に従っている
- [ ] テストケースの内容が明確で、期待される動作が理解できる
- [ ] テストデータの投入順序が外部キー制約を考慮して正しく設定されている
- [ ] テストコードが一貫したスタイルで書かれている
- [ ] UUID は UUIDV4 形式を使用している
- [ ] 自動生成ファイルは編集せず、必要に応じて別ファイルを作成している

**これらすべてをクリアした完全なテストコードを生成してください。**
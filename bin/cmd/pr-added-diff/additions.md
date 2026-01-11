# Added lines by file

## apps/persia/app/handlers/http/oapi/api.gen.go
```diff
+ // ProcedureFormAutoFillMissingFormNames 自動入力処理の実行時に必須項目が未登録だった場合に返す、「不足している項目を登録するフォーム名」のリスト。
+ type ProcedureFormAutoFillMissingFormNames = []string
+ 
```

## apps/persia/schema/persia-api.yaml
```diff
+           description: 自動入力に必要な情報が不足している場合、または手続きが終了している場合
+           content:
+             application/json:
+               schema:
+                 $ref: '#/components/schemas/ProcedureFormAutoFillMissingFormNames'
+     ProcedureFormAutoFillMissingFormNames:
+       title: ProcedureFormAutoFillMissingFormNames
+       type: array
+       description: |
+         自動入力処理の実行時に必須項目が未登録だった場合に返す、「不足している項目を登録するフォーム名」のリスト。
+       items:
+         type: string
```


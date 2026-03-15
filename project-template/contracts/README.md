# contracts/ — Feature 資料契約目錄

> **重要**：全域 ENUM 和欄位模板已移至 `10_Standards/DB/`
>
> | 檔案 | 新位置 |
> |------|--------|
> | `enum_registry.yaml`（全域 ENUM SSOT）| `10_Standards/DB/enum_registry.yaml` |
> | `field_registry_template.yaml`（欄位模板）| `10_Standards/DB/field_registry_template.yaml` |

此目錄存放**各功能模組**的 Feature 級資料契約，確保前端、後端、DB 三端一致性。

---

## 目錄結構

```
contracts/
├── README.md                    ← 本文件
├── field_registry_F01.yaml      ← F01 欄位 Registry（從模板複製產出）
├── field_registry_F02.yaml      ← F02 欄位 Registry
└── ...
```

> ENUM 集中管理於 `10_Standards/DB/enum_registry.yaml`（跨 Feature 共用）
> Field Registry 按 Feature 分檔，命名：`field_registry_F##.yaml`

---

## 建立新 Feature 的 Field Registry

```bash
# 複製模板
cp 10_Standards/DB/field_registry_template.yaml contracts/field_registry_F##.yaml
# 填入 Feature 欄位定義
```

---

## 使用規則

| 規則 | 說明 |
|------|------|
| **DC-01** | 每個功能模組必須有 `field_registry_F##.yaml`，欄位數須與 Entity 一致 |
| **DC-02** | ENUM 值從 `10_Standards/DB/enum_registry.yaml` 取，禁止各層 hardcode |
| **DC-06** | Gate 3 前 Review Agent 驗證 ENUM 三端一致性 |

**維護者**：dba-agent（Schema 設計）、backend-agent（API 欄位對齊）
**驗證時機**：Gate 2（欄位數一致性）、Gate 3（ENUM 三端一致性）
**驗證指令**：`/validate-contract`

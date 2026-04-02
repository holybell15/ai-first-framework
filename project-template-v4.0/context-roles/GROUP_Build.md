# GROUP: Build

> P04 實作開發階段的 specialist 群組

## 通用行為（所有 Build specialist 共享）
- **TDD 強制**: RED→GREEN→REFACTOR 每次提交前完成
- **Worktree 隔離**: 每個 Feature 用 `git worktree` 獨立分支，無跨任務污染
- **Code Review**: 任何 production code 必須過 Review Agent 才能 merge
- **Bug fix = Regression Test**: 修 bug 必須同步寫 test case 防止再發
- **交接格式**: 完成後寫 Handoff 到 `memory/handoffs/[feature-id]/`
- **無 Drift**: 發現 Spec/Design 衝突 → 記錄 findings.md → 不主動修改、送信號

---

## §Backend

**職責**
- API 端點實作與業務邏輯編寫
- 資料模型與業務規則實現
- 錯誤處理與日誌記錄
- 與 DBA/Frontend 的契約履行

**必載 Skill**
- test-driven-development
- using-git-worktrees
- systematic-debugging
- verification-before-completion

**禁止事項**
- 不碰 UI/CSS（留給 §Frontend）
- 不修改 DB schema 未經 DBA review
- 不改 API contract 未通知 Frontend
- 不跳過 test

**完成標準**
- 單元測試覆蓋率 ≥ 80%
- API contract 符合 SPEC
- 所有 AC 已實作並測試通過
- Code review 已通過、無待修評論

---

## §Frontend

**職責**
- UI 元件實作（遵循 DESIGN.md token）
- 用戶互動邏輯與狀態管理
- API 整合與數據綁定
- 可訪問性與性能最佳化

**必載 Skill**
- test-driven-development
- using-git-worktrees
- frontend-design
- verification-before-completion

**禁止事項**
- 不碰 DB（留給 DBA）
- 不修改 API contract 未通知 Backend
- 不使用 DESIGN.md 未定義的 token
- 不跳過 test

**完成標準**
- 視覺與 Prototype 像素級一致
- 所有 AC 已實現並測試通過
- 互動流程符合 DESIGN.md
- Code review 已通過

---

## §DBA

**職責**
- 資料庫 schema 設計與實現
- Migration script 撰寫與驗證
- 索引與性能最佳化
- Schema 版本控制與回滾計畫

**必載 Skill**
- test-driven-development
- using-git-worktrees
- verification-before-completion

**禁止事項**
- 不寫 application code（只 schema/migration）
- 不修改 API contract
- 不碰業務邏輯

**完成標準**
- ERD（實體關係圖）完整且符合 Business Model
- Migration 可向前向後回滾
- Index 已優化、查詢性能測試通過
- Schema 變更文檔已更新至 DESIGN.md Database 區段

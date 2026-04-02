# Start Here

> 如果你第一次接觸 AI-First Framework，不需要先讀完整 repo。先從你現在的情境進入。

---

## 1. 我想建立一個新專案

```bash
./scripts/new-project.sh 我的產品名稱
```

接著：

```text
讀取 CLAUDE.md，使用 Lite Mode 啟動 F01
```

相關文件：
- `README.md`
- `docs/LITE_MODE.md`

---

## 2. 我想把框架接到現有專案

```bash
./scripts/adopt-project.sh /path/to/project
```

接著：

```text
讀取 CLAUDE.md 和 memory/STATE.md，使用 Lite Mode 接手目前最優先功能
```

相關文件：
- `README.md`
- `docs/LITE_MODE.md`
- `docs/PIPELINES.md`

---

## 3. 我只想知道現在該做什麼

```text
/info-task-master
```

Task-Master 會讀 `TASKS.md` + `memory/STATE.md`，告訴你下一步、目前阻塞與應啟動的 Agent。

---

## 4. 我想直接理解文件各自做什麼

先讀：

- `docs/INFORMATION_ARCHITECTURE.md`
- `project-template/CLAUDE.md`

---

## 5. 我想驗證框架有沒有壞掉

```bash
./scripts/validate-framework.sh
```

這會做：

- 核心文件存在性檢查
- Lite Mode 與資訊架構入口檢查
- `workflow-test` 報告產生

---

## 6. 我想看一個最小示範

先看：

- `examples/lite-task-demo/README.md`

這個示範專案展示 Lite Mode 第一個 feature 的最小閉環長什麼樣子。

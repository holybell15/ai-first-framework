# F01-MINI-DESIGN

## Scope

- 單頁表單建立任務
- 單一欄位：title
- 建立成功後回到同頁並刷新列表

## Affected Modules

- `TaskForm`
- `TaskList`
- `POST /tasks`

## Risks

- 若未處理空字串驗證，會產生無效資料
- 若 API 未回傳新任務，前端列表同步會失敗

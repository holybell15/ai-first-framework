#!/usr/bin/env node
/**
 * generate-rs-confirmation.js
 *
 * 產出「需求規格確認書」Word 文件
 * 合約導向結構 + 完整功能規格（定義/操作流程/業務規則/邊界情境）+ 三方簽核
 *
 * Usage:
 *   node scripts/generate-rs-confirmation.js [options]
 *
 * Options (all optional — defaults produce a template):
 *   --project    "產品名稱"
 *   --feature    "F01"
 *   --title      "功能名稱"
 *   --version    "v0.1.0"
 *   --date       "2026-03-18"
 *   --output     "output.docx"
 *
 * Example:
 *   node scripts/generate-rs-confirmation.js \
 *     --project "NEW360" --feature "F02" --title "來電彈屏" \
 *     --version "v1.0.0" --date "2026-03-18" \
 *     --output "02_Specifications/RS_Confirm_F02_來電彈屏.docx"
 */

const fs = require("fs");
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell,
  Header, Footer, AlignmentType, HeadingLevel, BorderStyle, WidthType,
  ShadingType, PageNumber, PageBreak, LevelFormat,
} = require("docx");

// ── Parse args ──────────────────────────────────────────────
const args = {};
process.argv.slice(2).forEach((arg, i, arr) => {
  if (arg.startsWith("--") && arr[i + 1]) args[arg.slice(2)] = arr[i + 1];
});

const PROJECT  = args.project  || "[產品名稱]";
const FEATURE  = args.feature  || "[F##]";
const TITLE    = args.title    || "[功能名稱]";
const VERSION  = args.version  || "v0.1.0";
const DOC_DATE = args.date     || new Date().toISOString().slice(0, 10);
const OUTPUT   = args.output   || `RS_Confirm_${FEATURE}_${TITLE}.docx`;

// ── Colors & Constants ──────────────────────────────────────
const C = {
  primary: "1F4E79", secondary: "2E75B6", accent: "4472C4",
  lightBg: "D6E4F0", lighterBg: "EDF2F9", featureBg: "F0F5FA",
  gray: "595959", mutedGray: "808080",
  warnBg: "FFF8E1", warnBorder: "F59E0B", warnText: "92400E",
  dangerText: "C00000", successText: "065F46",
  ruleBg: "F9FAFB", edgeBg: "FFF7ED",
};
const PAGE_W = 9360;
const cellBorder = { style: BorderStyle.SINGLE, size: 1, color: "BFBFBF" };
const borders = { top: cellBorder, bottom: cellBorder, left: cellBorder, right: cellBorder };
const cellPad = { top: 60, bottom: 60, left: 100, right: 100 };

// ── Reusable Builders ───────────────────────────────────────
const FONT = "Microsoft JhengHei";

function txt(text, opts = {}) {
  return new TextRun({ text, font: FONT, size: opts.size || 20, color: opts.color || C.gray, bold: opts.bold, italics: opts.italics });
}

function heading(level, text, num) {
  const sizes = { 1: 32, 2: 26, 3: 22 };
  const prefix = num ? `${num}  ` : "";
  return new Paragraph({
    heading: level,
    spacing: { before: level === HeadingLevel.HEADING_1 ? 360 : 280, after: 160 },
    children: [txt(prefix + text, { size: sizes[level === HeadingLevel.HEADING_1 ? 1 : level === HeadingLevel.HEADING_2 ? 2 : 3], color: C.primary, bold: true })],
  });
}
const h1 = (text, num) => heading(HeadingLevel.HEADING_1, text, num);
const h2 = (text, num) => heading(HeadingLevel.HEADING_2, text, num);
const h3 = (text, num) => heading(HeadingLevel.HEADING_3, text, num);

function body(text, opts = {}) {
  return new Paragraph({
    spacing: { after: opts.after || 120 },
    indent: opts.indent ? { left: opts.indent } : undefined,
    children: Array.isArray(text)
      ? text
      : [txt(text, opts)],
  });
}

function bullet(text, opts = {}) {
  return new Paragraph({
    numbering: { reference: "bullets", level: 0 },
    spacing: { after: 60 },
    children: [txt(text, opts)],
  });
}

function spacer(h = 200) { return new Paragraph({ spacing: { after: h }, children: [] }); }
function pageBreak() { return new Paragraph({ children: [new PageBreak()] }); }

function hdrCell(text, width, opts = {}) {
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading: { fill: opts.fill || C.primary, type: ShadingType.CLEAR },
    margins: cellPad, verticalAlign: "center", columnSpan: opts.colSpan,
    children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [txt(text, { bold: true, color: "FFFFFF", size: 20 })] })],
  });
}

function lblCell(text, width, opts = {}) {
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading: { fill: opts.fill || C.lightBg, type: ShadingType.CLEAR },
    margins: cellPad, columnSpan: opts.colSpan,
    children: [new Paragraph({ children: [txt(text, { bold: true, color: C.primary })] })],
  });
}

function valCell(text, width, opts = {}) {
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading: opts.fill ? { fill: opts.fill, type: ShadingType.CLEAR } : undefined,
    margins: cellPad, columnSpan: opts.colSpan,
    children: Array.isArray(opts.children)
      ? opts.children
      : [new Paragraph({
          alignment: opts.align,
          children: [txt(text, { color: opts.color, bold: opts.bold, italics: opts.italics })],
        })],
  });
}

/** Multi-line cell: accepts an array of strings, each becomes a paragraph */
function multiLineCell(lines, width, opts = {}) {
  return new TableCell({
    borders, width: { size: width, type: WidthType.DXA },
    shading: opts.fill ? { fill: opts.fill, type: ShadingType.CLEAR } : undefined,
    margins: cellPad, columnSpan: opts.colSpan,
    children: lines.map((line, i) => new Paragraph({
      spacing: { after: i < lines.length - 1 ? 40 : 0 },
      children: [txt(line, { color: opts.color, bold: opts.bold, italics: opts.italics })],
    })),
  });
}

function table(colWidths, rows) {
  return new Table({
    width: { size: PAGE_W, type: WidthType.DXA },
    columnWidths: colWidths,
    rows,
  });
}

function kvTable(pairs) {
  const LW = 2200, VW = PAGE_W - LW;
  return table([LW, VW], pairs.map(([k, v]) =>
    new TableRow({ children: [lblCell(k, LW), valCell(v, VW)] })
  ));
}

// ── Feature Spec Block Builder ──────────────────────────────
// This is the core enhancement: each feature gets a full specification block
// with definition, operation flow, business rules, edge cases, and AC.

function featureSectionHeader(fNum, title) {
  return new TableRow({ children: [
    new TableCell({
      borders, columnSpan: 6, width: { size: PAGE_W, type: WidthType.DXA },
      shading: { fill: C.secondary, type: ShadingType.CLEAR }, margins: cellPad,
      children: [new Paragraph({ children: [
        txt(`${fNum}`, { bold: true, color: "FFFFFF", size: 24 }),
        txt(`  ${title}`, { bold: true, color: "FFFFFF", size: 24 }),
      ]})],
    }),
  ]});
}

/**
 * Build a complete feature specification block.
 *
 * @param {string} fNum      - Feature number, e.g. "FN-01"
 * @param {string} fTitle    - Feature title
 * @param {number} stepCount - Number of operation steps (placeholder)
 * @param {number} ruleCount - Number of business rules (placeholder)
 * @param {number} edgeCount - Number of edge cases (placeholder)
 * @param {number} acCount   - Number of acceptance criteria (placeholder)
 */
function featureBlock(fNum, fTitle, stepCount, ruleCount, edgeCount, acCount) {
  const elements = [];

  // ── A. Feature Definition (功能定義) ──────────────────────
  elements.push(
    new Paragraph({
      spacing: { before: 240, after: 80 },
      shading: { fill: C.featureBg, type: ShadingType.CLEAR },
      children: [
        txt(`${fNum}  `, { bold: true, color: C.primary, size: 24 }),
        txt(fTitle, { bold: true, color: C.primary, size: 24 }),
      ],
    }),
  );

  // Sub-section: 功能定義
  elements.push(h3("功能定義"));
  elements.push(
    table([2200, 7160], [
      new TableRow({ children: [
        lblCell("功能目的", 2200), valCell("[用 2-3 句話說明：這個功能解決什麼問題？使用者在什麼情境下需要它？]", 7160),
      ]}),
      new TableRow({ children: [
        lblCell("適用角色", 2200), valCell("[哪些角色會使用此功能？主要使用者 vs. 次要使用者]", 7160),
      ]}),
      new TableRow({ children: [
        lblCell("觸發條件", 2200), valCell("[什麼事件或動作會啟動這個功能？例如：來電時自動觸發 / 使用者點擊按鈕]", 7160),
      ]}),
      new TableRow({ children: [
        lblCell("預期結果", 2200), valCell("[功能成功執行後，使用者看到什麼？系統狀態如何改變？]", 7160),
      ]}),
      new TableRow({ children: [
        lblCell("前置條件", 2200), valCell("[使用此功能前必須滿足的條件，例如：已登入、已有客戶資料、CTI 已連線]", 7160),
      ]}),
    ]),
  );

  // ── B. User Story ────────────────────────────────────────
  elements.push(spacer(100));
  elements.push(h3("User Story"));
  elements.push(
    new Paragraph({
      spacing: { after: 60 },
      indent: { left: 360 },
      border: { left: { style: BorderStyle.SINGLE, size: 8, color: C.accent, space: 8 } },
      shading: { fill: C.lighterBg, type: ShadingType.CLEAR },
      children: [
        txt("As a ", { italics: true, size: 22 }),
        txt("[角色]", { bold: true, italics: true, size: 22, color: C.primary }),
        txt(", I want to ", { italics: true, size: 22 }),
        txt("[行為]", { bold: true, italics: true, size: 22, color: C.primary }),
        txt(", so that ", { italics: true, size: 22 }),
        txt("[目的/價值]", { bold: true, italics: true, size: 22, color: C.primary }),
      ],
    }),
  );
  elements.push(body("[將上面的 User Story 用白話文展開：詳細描述使用者想做什麼、期待的體驗是什麼。至少 3 行說明。]"));

  // ── C. Complete Operation Flow (完整操作流程) ─────────────
  elements.push(spacer(100));
  elements.push(h3("完整操作流程"));
  elements.push(body("以下為使用者從「啟動功能」到「完成目標」的完整步驟。每一步標明使用者動作與系統回應。"));
  elements.push(spacer(40));

  const stepW = [800, 1200, 3380, 3980];
  const stepRows = [
    new TableRow({ children: [
      hdrCell("步驟", stepW[0]),
      hdrCell("動作者", stepW[1]),
      hdrCell("使用者操作 / 系統事件", stepW[2]),
      hdrCell("系統回應 / 畫面變化", stepW[3]),
    ]}),
  ];
  for (let i = 1; i <= stepCount; i++) {
    stepRows.push(new TableRow({ children: [
      valCell(`${i}`, stepW[0], { align: AlignmentType.CENTER, bold: true }),
      valCell("[使用者/系統]", stepW[1], { align: AlignmentType.CENTER }),
      valCell("[描述操作動作或系統事件觸發]", stepW[2]),
      valCell("[系統如何回應？畫面顯示什麼？資料如何變化？]", stepW[3]),
    ]}));
  }
  elements.push(table(stepW, stepRows));

  // Flow notes
  elements.push(spacer(60));
  elements.push(body("[補充說明：操作流程中的分支點、可選步驟、可以跳過的步驟、或需要特別留意的時序要求。]", { italics: true, color: C.mutedGray }));

  // ── D. Business Rules (業務規則) ──────────────────────────
  elements.push(spacer(100));
  elements.push(h3("業務規則"));
  elements.push(body("以下為此功能涉及的所有業務邏輯與判斷規則。每條規則需明確「條件→行為」。"));
  elements.push(spacer(40));

  const ruleW = [900, 2860, 3400, 2200];
  const ruleRows = [
    new TableRow({ children: [
      hdrCell("規則編號", ruleW[0], { fill: "2E75B6" }),
      hdrCell("條件（When）", ruleW[1], { fill: "2E75B6" }),
      hdrCell("行為（Then）", ruleW[2], { fill: "2E75B6" }),
      hdrCell("範例 / 補充", ruleW[3], { fill: "2E75B6" }),
    ]}),
  ];
  for (let i = 1; i <= ruleCount; i++) {
    ruleRows.push(new TableRow({ children: [
      valCell(`BR-${String(i).padStart(2, "0")}`, ruleW[0], { bold: true, align: AlignmentType.CENTER, fill: C.ruleBg }),
      valCell("[當什麼條件成立時...]", ruleW[1], { fill: C.ruleBg }),
      valCell("[系統執行什麼行為 / 顯示什麼 / 限制什麼]", ruleW[2], { fill: C.ruleBg }),
      valCell("[舉出具體數值或情境範例]", ruleW[3], { fill: C.ruleBg }),
    ]}));
  }
  elements.push(table(ruleW, ruleRows));

  // ── E. Edge Cases & Exception Handling (邊界情境與例外處理) ─
  elements.push(spacer(100));
  elements.push(h3("邊界情境與例外處理"));
  elements.push(body("以下列出此功能可能遭遇的例外狀況，以及系統應如何處理。確認每個情境都有明確處理方式。"));
  elements.push(spacer(40));

  const edgeW = [900, 2460, 2800, 1600, 1600];
  const edgeRows = [
    new TableRow({ children: [
      hdrCell("編號", edgeW[0], { fill: "C05621" }),
      hdrCell("例外情境", edgeW[1], { fill: "C05621" }),
      hdrCell("系統處理方式", edgeW[2], { fill: "C05621" }),
      hdrCell("使用者看到什麼", edgeW[3], { fill: "C05621" }),
      hdrCell("嚴重度", edgeW[4], { fill: "C05621" }),
    ]}),
  ];
  for (let i = 1; i <= edgeCount; i++) {
    edgeRows.push(new TableRow({ children: [
      valCell(`EX-${String(i).padStart(2, "0")}`, edgeW[0], { bold: true, align: AlignmentType.CENTER, fill: C.edgeBg }),
      valCell("[描述例外發生的情境]", edgeW[1], { fill: C.edgeBg }),
      valCell("[系統如何處理？重試？降級？中斷？]", edgeW[2], { fill: C.edgeBg }),
      valCell("[錯誤提示文字 / Toast / 畫面變化]", edgeW[3], { fill: C.edgeBg }),
      valCell("[高/中/低]", edgeW[4], { align: AlignmentType.CENTER, fill: C.edgeBg }),
    ]}));
  }
  elements.push(table(edgeW, edgeRows));

  // ── F. Acceptance Criteria (驗收條件) ─────────────────────
  elements.push(spacer(100));
  elements.push(h3("驗收條件 (AC)"));
  elements.push(body("以下為此功能的正式驗收條件。每條 AC 必須可測試、可驗證。優先級標示哪些為 MVP 必備。"));
  elements.push(spacer(40));

  const acW = [900, 4260, 1200, 1200, 1800];
  const acRows = [
    new TableRow({ children: [
      hdrCell("AC 編號", acW[0]),
      hdrCell("驗收條件描述", acW[1]),
      hdrCell("優先級", acW[2]),
      hdrCell("驗證方式", acW[3]),
      hdrCell("對應業務規則", acW[4]),
    ]}),
  ];
  for (let i = 1; i <= acCount; i++) {
    acRows.push(new TableRow({ children: [
      valCell(`AC-${String(i).padStart(2, "0")}`, acW[0], { bold: true, align: AlignmentType.CENTER }),
      valCell("[Given... When... Then... 格式描述驗收條件]", acW[1]),
      valCell("[P0/P1/P2]", acW[2], { align: AlignmentType.CENTER }),
      valCell("[自動/手動]", acW[3], { align: AlignmentType.CENTER }),
      valCell("[BR-##, EX-##]", acW[4]),
    ]}));
  }
  elements.push(table(acW, acRows));

  // ── G. Screen Reference (畫面參照) ────────────────────────
  elements.push(spacer(100));
  elements.push(h3("畫面參照"));
  elements.push(
    table([2200, 7160], [
      new TableRow({ children: [
        lblCell("Prototype 檔案", 2200), valCell("[01_Product_Prototype/xxx_prototype.html]", 7160),
      ]}),
      new TableRow({ children: [
        lblCell("主要畫面", 2200), valCell("[列出此功能涉及的主要畫面名稱，例如：彈屏主畫面、客戶詳情頁、歷史記錄面板]", 7160),
      ]}),
      new TableRow({ children: [
        lblCell("畫面跳轉說明", 2200), valCell("[描述畫面間的導航路徑，例如：彈屏→點擊客戶名稱→客戶詳情頁]", 7160),
      ]}),
    ]),
  );

  // Divider after each feature
  elements.push(spacer(200));
  elements.push(new Paragraph({
    border: { bottom: { style: BorderStyle.SINGLE, size: 4, color: C.lightBg, space: 8 } },
    children: [],
  }));

  return elements;
}

// ── BUILD DOCUMENT ──────────────────────────────────────────
const doc = new Document({
  styles: {
    default: { document: { run: { font: FONT, size: 20 } } },
    paragraphStyles: [
      { id: "Heading1", name: "Heading 1", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 32, bold: true, font: FONT, color: C.primary },
        paragraph: { spacing: { before: 360, after: 200 }, outlineLevel: 0 } },
      { id: "Heading2", name: "Heading 2", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 26, bold: true, font: FONT, color: C.primary },
        paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 1 } },
      { id: "Heading3", name: "Heading 3", basedOn: "Normal", next: "Normal", quickFormat: true,
        run: { size: 22, bold: true, font: FONT, color: C.secondary },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 2 } },
    ],
  },
  numbering: {
    config: [
      { reference: "bullets", levels: [{ level: 0, format: LevelFormat.BULLET, text: "\u2022", alignment: AlignmentType.LEFT,
        style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
    ],
  },
  sections: [{
    properties: {
      page: {
        size: { width: 12240, height: 15840 },
        margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 },
      },
    },
    headers: {
      default: new Header({ children: [new Paragraph({
        border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: C.secondary, space: 4 } },
        children: [
          txt(`${PROJECT}`, { size: 16, color: C.secondary }),
          txt(` | 需求規格確認書 ${FEATURE} | ${VERSION}`, { size: 16, color: C.secondary, bold: true }),
        ],
      })] }),
    },
    footers: {
      default: new Footer({ children: [new Paragraph({
        border: { top: { style: BorderStyle.SINGLE, size: 4, color: "BFBFBF", space: 4 } },
        alignment: AlignmentType.CENTER,
        children: [
          txt(`RS-CONFIRM-${FEATURE}`, { size: 16, color: "999999" }),
          txt("  |  Page ", { size: 16, color: "999999" }),
          new TextRun({ children: [PageNumber.CURRENT], font: FONT, size: 16, color: "999999" }),
        ],
      })] }),
    },
    children: [
      // ════════════════════════════════════════════
      // COVER PAGE
      // ════════════════════════════════════════════
      spacer(800),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 80 }, children: [txt(PROJECT, { size: 28, color: C.secondary })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 40 }, children: [txt("需求規格確認書", { size: 48, bold: true, color: C.primary })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 20 }, children: [txt("Requirement Specification Confirmation", { size: 22, color: C.secondary, italics: true })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 400 }, children: [txt(`${FEATURE} — ${TITLE}`, { size: 32, bold: true, color: C.accent })] }),

      kvTable([
        ["文件編號", `RS-CONFIRM-${FEATURE}`],
        ["版本", VERSION],
        ["日期", DOC_DATE],
        ["狀態", "待簽核"],
      ]),

      spacer(300),
      new Paragraph({
        alignment: AlignmentType.CENTER,
        border: { top: { style: BorderStyle.SINGLE, size: 2, color: C.secondary, space: 8 },
                  bottom: { style: BorderStyle.SINGLE, size: 2, color: C.secondary, space: 8 } },
        spacing: { before: 200, after: 200 },
        children: [txt("本文件為需求規格的正式確認紀錄。經三方簽核後，方可進入技術設計與開發階段。", { italics: true })],
      }),

      spacer(200),

      // ── Reading Guide ──
      h2("閱讀指南"),
      body("本確認書的每個功能包含以下六個區塊，方便您逐項確認："),
      spacer(40),
      table([600, 2200, 6560], [
        new TableRow({ children: [hdrCell("#", 600), hdrCell("區塊", 2200), hdrCell("內容說明", 6560)] }),
        new TableRow({ children: [valCell("1", 600, { align: AlignmentType.CENTER, bold: true }), valCell("功能定義", 2200, { bold: true }), valCell("這個功能是什麼？解決什麼問題？誰會用？", 6560)] }),
        new TableRow({ children: [valCell("2", 600, { align: AlignmentType.CENTER, bold: true }), valCell("完整操作流程", 2200, { bold: true }), valCell("使用者從頭到尾的操作步驟，每一步系統會如何回應", 6560)] }),
        new TableRow({ children: [valCell("3", 600, { align: AlignmentType.CENTER, bold: true }), valCell("業務規則", 2200, { bold: true }), valCell("系統內建的判斷邏輯：什麼條件下做什麼事", 6560)] }),
        new TableRow({ children: [valCell("4", 600, { align: AlignmentType.CENTER, bold: true }), valCell("邊界情境", 2200, { bold: true }), valCell("例外狀況怎麼處理（網路斷線、資料不存在、權限不足等）", 6560)] }),
        new TableRow({ children: [valCell("5", 600, { align: AlignmentType.CENTER, bold: true }), valCell("驗收條件", 2200, { bold: true }), valCell("交付時用什麼標準判斷「做完了」", 6560)] }),
        new TableRow({ children: [valCell("6", 600, { align: AlignmentType.CENTER, bold: true }), valCell("畫面參照", 2200, { bold: true }), valCell("對應的 Prototype 畫面和導航路徑", 6560)] }),
      ]),
      spacer(60),
      body("請特別留意標記為 P0（必做）的驗收條件，以及標記為「高」嚴重度的邊界情境。", { bold: true }),

      pageBreak(),

      // ════════════════════════════════════════════
      // 第一部分 — 專案概覽
      // ════════════════════════════════════════════
      h1("第一部分 — 專案概覽"),

      // 1.1
      h2("1.1 專案基本資訊"),
      kvTable([
        ["專案名稱", PROJECT],
        ["功能代碼", FEATURE],
        ["功能名稱", TITLE],
        ["規模分類", "[S / M / L / XL]"],
        ["RFP 入口模式", "[A: 匯入文件 / B: 訪談產生]"],
      ]),

      // 1.2
      h2("1.2 商業背景與動機"),
      body("[來自 RFP Brief — 為什麼要做這件事？目前有什麼痛點？如果不做會怎樣？]"),
      spacer(60),
      body("預期商業價值：", { bold: true }),
      bullet("[價值 1：例如「客服平均處理時間從 5 分鐘降至 2 分鐘」]"),
      bullet("[價值 2：例如「新進客服培訓時間從 2 週縮短至 3 天」]"),
      bullet("[價值 3]"),

      // 1.3
      h2("1.3 使用者角色"),
      body("以下為使用此功能的所有角色，以及他們各自的使用情境："),
      spacer(60),
      table([1200, 2160, 1800, 2000, 2200], [
        new TableRow({ children: [
          hdrCell("角色 ID", 1200), hdrCell("角色名稱", 2160), hdrCell("使用頻率", 1800),
          hdrCell("主要使用情境", 2000), hdrCell("關鍵痛點", 2200),
        ]}),
        new TableRow({ children: [
          valCell("P01", 1200, { bold: true }), valCell("[角色名稱與簡述]", 2160),
          valCell("[每日 N 次]", 1800), valCell("[什麼時候會用到]", 2000), valCell("[目前最大的困擾]", 2200),
        ]}),
        new TableRow({ children: [
          valCell("P02", 1200, { bold: true }), valCell("[角色名稱與簡述]", 2160),
          valCell("[每日 N 次]", 1800), valCell("[什麼時候會用到]", 2000), valCell("[目前最大的困擾]", 2200),
        ]}),
      ]),

      // 1.4 — Scope Summary
      h2("1.4 範圍摘要"),
      body("本次交付包含以下功能，不含範圍外項目："),
      spacer(60),
      table([600, 2400, 4160, 2200], [
        new TableRow({ children: [hdrCell("#", 600), hdrCell("功能名稱", 2400), hdrCell("一句話描述", 4160), hdrCell("優先級", 2200)] }),
        new TableRow({ children: [
          valCell("1", 600, { align: AlignmentType.CENTER, bold: true }),
          valCell("[功能名稱]", 2400, { bold: true }),
          valCell("[這個功能做什麼？使用者完成什麼目標？]", 4160),
          valCell("P0 必做", 2200, { color: C.dangerText, bold: true }),
        ]}),
        new TableRow({ children: [
          valCell("2", 600, { align: AlignmentType.CENTER, bold: true }),
          valCell("[功能名稱]", 2400, { bold: true }),
          valCell("[這個功能做什麼？]", 4160),
          valCell("P0 必做", 2200, { color: C.dangerText, bold: true }),
        ]}),
        new TableRow({ children: [
          valCell("3", 600, { align: AlignmentType.CENTER, bold: true }),
          valCell("[功能名稱]", 2400, { bold: true }),
          valCell("[這個功能做什麼？]", 4160),
          valCell("P1 重要", 2200, { color: "ED7D31", bold: true }),
        ]}),
      ]),

      spacer(100),
      body("明確不含範圍（Out of Scope）：", { bold: true, color: C.primary }),
      spacer(40),
      table([600, 4760, 4000], [
        new TableRow({ children: [hdrCell("#", 600), hdrCell("排除項目", 4760), hdrCell("說明 / 預計時程", 4000)] }),
        new TableRow({ children: [valCell("1", 600, { align: AlignmentType.CENTER }), valCell("[排除項目]", 4760), valCell("[Phase 2 再議 / 不在本專案範圍]", 4000)] }),
        new TableRow({ children: [valCell("2", 600, { align: AlignmentType.CENTER }), valCell("[排除項目]", 4760), valCell("[說明]", 4000)] }),
      ]),

      pageBreak(),

      // ════════════════════════════════════════════
      // 第二部分 — 功能規格明細
      // ════════════════════════════════════════════
      h1("第二部分 — 功能規格明細"),
      body("以下為每個功能的完整規格，包含功能定義、操作流程、業務規則、邊界情境與驗收條件。"),
      body("請逐項確認每個功能是否符合您的需求。如有任何不符，請在對應區塊旁標註意見。", { bold: true }),

      // ── Feature 1 ──
      spacer(200),
      ...featureBlock("FN-01", "[功能名稱 1]", 6, 4, 3, 4),

      pageBreak(),

      // ── Feature 2 ──
      ...featureBlock("FN-02", "[功能名稱 2]", 5, 3, 3, 3),

      pageBreak(),

      // ── Feature 3 (placeholder) ──
      ...featureBlock("FN-03", "[功能名稱 3]", 4, 3, 2, 3),

      pageBreak(),

      // ════════════════════════════════════════════
      // 第三部分 — 合約條件
      // ════════════════════════════════════════════
      h1("第三部分 — 合約條件"),

      // 3.1
      h2("3.1 里程碑與交付時程"),
      table([600, 2400, 2160, 2000, 2200], [
        new TableRow({ children: [
          hdrCell("#", 600), hdrCell("里程碑", 2400), hdrCell("預計日期", 2160),
          hdrCell("交付物", 2000), hdrCell("驗收方式", 2200),
        ]}),
        new TableRow({ children: [
          valCell("M1", 600, { align: AlignmentType.CENTER, bold: true }),
          valCell("需求確認完成", 2400), valCell("[日期]", 2160),
          valCell("本文件 + 簽核", 2000), valCell("三方簽核", 2200),
        ]}),
        new TableRow({ children: [
          valCell("M2", 600, { align: AlignmentType.CENTER, bold: true }),
          valCell("技術設計完成（Gate 2）", 2400), valCell("[日期]", 2160),
          valCell("架構文件 + DB Schema", 2000), valCell("Gate 2 Review", 2200),
        ]}),
        new TableRow({ children: [
          valCell("M3", 600, { align: AlignmentType.CENTER, bold: true }),
          valCell("開發完成（Gate 3）", 2400), valCell("[日期]", 2160),
          valCell("程式碼 + 測試報告", 2000), valCell("Gate 3 Review", 2200),
        ]}),
        new TableRow({ children: [
          valCell("M4", 600, { align: AlignmentType.CENTER, bold: true }),
          valCell("上線部署", 2400), valCell("[日期]", 2160),
          valCell("部署紀錄 + 冒煙測試", 2000), valCell("部署驗收", 2200),
        ]}),
      ]),

      // 3.2
      h2("3.2 驗收標準總覽"),
      body("以下彙整所有功能的驗收條件，依優先級分類："),
      spacer(60),
      table([1400, 2000, 5960], [
        new TableRow({ children: [hdrCell("優先級", 1400), hdrCell("定義", 2000), hdrCell("涵蓋項目", 5960)] }),
        new TableRow({ children: [
          valCell("P0", 1400, { bold: true, color: C.dangerText }),
          valCell("MVP 核心 — 必須上線", 2000),
          valCell("[列出所有 P0 的 AC 編號和摘要]", 5960),
        ]}),
        new TableRow({ children: [
          valCell("P1", 1400, { bold: true, color: "ED7D31" }),
          valCell("重要 — 可後續迭代", 2000),
          valCell("[列出 P1 項目]", 5960),
        ]}),
        new TableRow({ children: [
          valCell("P2", 1400, { bold: true, color: C.accent }),
          valCell("Nice to have", 2000),
          valCell("[列出 P2 項目]", 5960),
        ]}),
      ]),

      // 3.3
      h2("3.3 客戶方需提供（前提條件）"),
      body("以下為開發啟動前，客戶方需提供或確認的前提條件："),
      spacer(60),
      table([600, 4360, 2200, 2200], [
        new TableRow({ children: [hdrCell("#", 600), hdrCell("前提條件", 4360), hdrCell("負責方", 2200), hdrCell("預計完成日", 2200)] }),
        new TableRow({ children: [valCell("1", 600, { align: AlignmentType.CENTER }), valCell("[例：提供 CRM API 文件與測試環境]", 4360), valCell("[客戶方 IT]", 2200), valCell("[日期]", 2200)] }),
        new TableRow({ children: [valCell("2", 600, { align: AlignmentType.CENTER }), valCell("[例：確認 PII 欄位遮罩規則]", 4360), valCell("[客戶方法務]", 2200), valCell("[日期]", 2200)] }),
      ]),

      pageBreak(),

      // ════════════════════════════════════════════
      // 第四部分 — 開放問題與風險
      // ════════════════════════════════════════════
      h1("第四部分 — 開放問題與風險"),

      // 4.1
      h2("4.1 開放問題"),
      body("以下為尚待確認的問題。標記為「高」的問題必須在技術設計前解決。"),
      spacer(60),
      table([600, 3560, 1200, 1800, 2200], [
        new TableRow({ children: [
          hdrCell("#", 600), hdrCell("問題描述", 3560), hdrCell("影響程度", 1200),
          hdrCell("由誰確認", 1800), hdrCell("預計解決日", 2200),
        ]}),
        new TableRow({ children: [
          valCell("1", 600, { align: AlignmentType.CENTER }), valCell("[問題描述]", 3560),
          valCell("[高/中/低]", 1200, { align: AlignmentType.CENTER }), valCell("[角色]", 1800), valCell("[日期]", 2200),
        ]}),
        new TableRow({ children: [
          valCell("2", 600, { align: AlignmentType.CENTER }), valCell("[問題描述]", 3560),
          valCell("[高/中/低]", 1200, { align: AlignmentType.CENTER }), valCell("[角色]", 1800), valCell("[日期]", 2200),
        ]}),
      ]),

      // 4.2
      h2("4.2 假設條件"),
      body("以下假設若被推翻，可能需要重新評估功能範圍或設計："),
      spacer(60),
      table([600, 3360, 2800, 2600], [
        new TableRow({ children: [
          hdrCell("#", 600), hdrCell("假設描述", 3360), hdrCell("若假設錯誤的影響", 2800), hdrCell("確認狀態", 2600),
        ]}),
        new TableRow({ children: [
          valCell("A1", 600, { align: AlignmentType.CENTER, bold: true }), valCell("[假設描述]", 3360),
          valCell("[會影響什麼]", 2800), valCell("[已確認 / 待確認]", 2600),
        ]}),
      ]),

      // 4.3
      h2("4.3 風險與緩解措施"),
      table([600, 2760, 1200, 2400, 2400], [
        new TableRow({ children: [
          hdrCell("#", 600), hdrCell("風險描述", 2760), hdrCell("等級", 1200),
          hdrCell("緩解措施", 2400), hdrCell("負責人", 2400),
        ]}),
        new TableRow({ children: [
          valCell("R1", 600, { align: AlignmentType.CENTER }), valCell("[風險描述]", 2760),
          valCell("[高]", 1200, { color: C.dangerText, bold: true, align: AlignmentType.CENTER }),
          valCell("[緩解措施]", 2400), valCell("[負責人]", 2400),
        ]}),
      ]),

      pageBreak(),

      // ════════════════════════════════════════════
      // 第五部分 — 正式簽核
      // ════════════════════════════════════════════
      h1("第五部分 — 正式簽核"),
      body("以下簽核代表各方已審閱並同意本文件所載之需求規格。簽核後方可進入技術設計階段。"),
      spacer(100),

      // Confirmation summary
      h2("5.1 確認摘要"),
      body("簽核前，請確認以下各項："),
      spacer(60),
      table([600, 5760, 1200, 1800], [
        new TableRow({ children: [hdrCell("#", 600), hdrCell("確認項目", 5760), hdrCell("狀態", 1200), hdrCell("備註", 1800)] }),
        new TableRow({ children: [valCell("1", 600, { align: AlignmentType.CENTER }), valCell("每個功能的「功能定義」正確反映我的需求", 5760), valCell("[是/否]", 1200, { align: AlignmentType.CENTER }), valCell("", 1800)] }),
        new TableRow({ children: [valCell("2", 600, { align: AlignmentType.CENTER }), valCell("每個功能的「操作流程」符合實際作業方式", 5760), valCell("[是/否]", 1200, { align: AlignmentType.CENTER }), valCell("", 1800)] }),
        new TableRow({ children: [valCell("3", 600, { align: AlignmentType.CENTER }), valCell("「業務規則」的判斷邏輯正確", 5760), valCell("[是/否]", 1200, { align: AlignmentType.CENTER }), valCell("", 1800)] }),
        new TableRow({ children: [valCell("4", 600, { align: AlignmentType.CENTER }), valCell("「邊界情境」的處理方式可接受", 5760), valCell("[是/否]", 1200, { align: AlignmentType.CENTER }), valCell("", 1800)] }),
        new TableRow({ children: [valCell("5", 600, { align: AlignmentType.CENTER }), valCell("「驗收條件」的 P0 項目完整，無遺漏", 5760), valCell("[是/否]", 1200, { align: AlignmentType.CENTER }), valCell("", 1800)] }),
        new TableRow({ children: [valCell("6", 600, { align: AlignmentType.CENTER }), valCell("「範圍外項目」確認排除正確", 5760), valCell("[是/否]", 1200, { align: AlignmentType.CENTER }), valCell("", 1800)] }),
        new TableRow({ children: [valCell("7", 600, { align: AlignmentType.CENTER }), valCell("里程碑時程可接受", 5760), valCell("[是/否]", 1200, { align: AlignmentType.CENTER }), valCell("", 1800)] }),
        new TableRow({ children: [valCell("8", 600, { align: AlignmentType.CENTER }), valCell("開放問題已知悉，同意暫按假設條件推進", 5760), valCell("[是/否]", 1200, { align: AlignmentType.CENTER }), valCell("", 1800)] }),
      ]),

      spacer(200),

      // Signature table
      h2("5.2 簽核欄"),
      spacer(60),
      table([2340, 2340, 2340, 2340], [
        new TableRow({ children: [hdrCell("角色", 2340), hdrCell("姓名", 2340), hdrCell("簽名 / 確認", 2340), hdrCell("日期", 2340)] }),
        new TableRow({ height: { value: 800, rule: "atLeast" }, children: [
          valCell("需求提出者", 2340, { bold: true }), valCell("", 2340), valCell("", 2340), valCell("", 2340),
        ]}),
        new TableRow({ height: { value: 800, rule: "atLeast" }, children: [
          valCell("專案經理", 2340, { bold: true }), valCell("", 2340), valCell("", 2340), valCell("", 2340),
        ]}),
        new TableRow({ height: { value: 800, rule: "atLeast" }, children: [
          valCell("系統分析 / 架構師", 2340, { bold: true }), valCell("", 2340), valCell("", 2340), valCell("", 2340),
        ]}),
      ]),

      spacer(200),
      new Paragraph({
        border: { top: { style: BorderStyle.SINGLE, size: 2, color: C.dangerText, space: 8 } },
        spacing: { before: 200 },
        children: [txt("注意事項：", { bold: true, color: C.dangerText })],
      }),
      body("1. 簽核後如需變更需求，必須執行變更影響評估（CIA）流程。"),
      body("2. 範圍擴大（新增功能 / 新 User Story）需退回需求訪談階段。"),
      body("3. 本文件為 Gate 1 審查的必要輸入之一。"),

      pageBreak(),

      // ════════════════════════════════════════════
      // 附件
      // ════════════════════════════════════════════
      h1("附件"),

      // A
      h2("附件 A — 非功能性需求"),
      table([2400, 4560, 2400], [
        new TableRow({ children: [hdrCell("需求類型", 2400), hdrCell("描述", 4560), hdrCell("目標值", 2400)] }),
        new TableRow({ children: [valCell("效能", 2400, { bold: true }), valCell("[例：頁面載入時間]", 4560), valCell("[< 1 秒]", 2400)] }),
        new TableRow({ children: [valCell("可用性", 2400, { bold: true }), valCell("[例：系統 uptime]", 4560), valCell("[99.9%]", 2400)] }),
        new TableRow({ children: [valCell("安全性", 2400, { bold: true }), valCell("[例：PII 欄位加密方式]", 4560), valCell("[AES-256-GCM]", 2400)] }),
        new TableRow({ children: [valCell("合規", 2400, { bold: true }), valCell("[例：金管會個資保護]", 4560), valCell("[FSC P0]", 2400)] }),
      ]),

      // B
      h2("附件 B — 整合介面規格"),
      table([2000, 2360, 2600, 2400], [
        new TableRow({ children: [hdrCell("外部系統", 2000), hdrCell("介面方式", 2360), hdrCell("說明", 2600), hdrCell("狀態", 2400)] }),
        new TableRow({ children: [valCell("[系統名稱]", 2000), valCell("[REST API]", 2360), valCell("[用途說明]", 2600), valCell("[已確認/待確認]", 2400)] }),
      ]),

      // C
      h2("附件 C — 關聯文件索引"),
      table([2800, 6560], [
        new TableRow({ children: [hdrCell("文件", 2800), hdrCell("路徑 / 說明", 6560)] }),
        new TableRow({ children: [valCell("RFP Brief", 2800, { bold: true }), valCell("02_Specifications/RFP_Brief_[功能].md", 6560)] }),
        new TableRow({ children: [valCell("訪談記錄 (IR)", 2800, { bold: true }), valCell("06_Interview_Records/IR-[日期].md", 6560)] }),
        new TableRow({ children: [valCell("需求規格 (RS)", 2800, { bold: true }), valCell("02_Specifications/US_F##_[功能名].md", 6560)] }),
        new TableRow({ children: [valCell("Prototype", 2800, { bold: true }), valCell("01_Product_Prototype/[功能]_prototype.html", 6560)] }),
      ]),

      spacer(400),
      new Paragraph({ alignment: AlignmentType.CENTER, children: [txt("— 文件結束 —", { size: 18, color: "BFBFBF" })] }),
    ],
  }],
});

// ── Generate ────────────────────────────────────────────────
Packer.toBuffer(doc).then(buffer => {
  fs.writeFileSync(OUTPUT, buffer);
  console.log(`\u2705 Generated: ${OUTPUT}`);
  console.log(`   Project:  ${PROJECT}`);
  console.log(`   Feature:  ${FEATURE} \u2014 ${TITLE}`);
  console.log(`   Version:  ${VERSION}`);
  console.log(`   Structure:`);
  console.log(`     Part 1 \u2014 專案概覽 (1.1~1.4)`);
  console.log(`     Part 2 \u2014 功能規格明細（每個功能含 6 區塊）`);
  console.log(`              - 功能定義 / User Story`);
  console.log(`              - 完整操作流程（步驟表）`);
  console.log(`              - 業務規則（條件→行為）`);
  console.log(`              - 邊界情境與例外處理`);
  console.log(`              - 驗收條件 (AC)`);
  console.log(`              - 畫面參照`);
  console.log(`     Part 3 \u2014 合約條件 (3.1~3.3)`);
  console.log(`     Part 4 \u2014 開放問題與風險 (4.1~4.3)`);
  console.log(`     Part 5 \u2014 正式簽核 (5.1~5.2)`);
  console.log(`     Appendix A~C`);
});

import { getSelectedText, Clipboard, showHUD, launchCommand, LaunchType, getPreferenceValues, environment } from "@raycast/api";
import { exec, execSync } from "child_process";
import { readFileSync, unlinkSync, existsSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";

interface Preferences {
  apiKey: string;
}

interface ClaudeContent {
  type: string;
  text?: string;
  source?: { type: string; media_type: string; data: string };
}

interface ClaudeResponse {
  content: Array<{ text: string }>;
}

const TTS_FILE = `/tmp/ctx-dict-tts.mp3`;

function captureScreenshot(): string | null {
  const screenshotPath = join(tmpdir(), `ctx-dict-${Date.now()}.png`);
  try {
    const helper = join(environment.assetsPath, "capture-screen");
    if (!existsSync(helper)) return null;
    execSync(`"${helper}" "${screenshotPath}"`);
    try {
      execSync(`sips --resampleWidth 1280 "${screenshotPath}" --out "${screenshotPath}" 2>/dev/null`);
    } catch { /* ignore */ }
    if (!existsSync(screenshotPath)) return null;
    const base64 = readFileSync(screenshotPath).toString("base64");
    try { unlinkSync(screenshotPath); } catch { /* ignore */ }
    return base64;
  } catch {
    return null;
  }
}

function preloadTTS(word: string): Promise<boolean> {
  const encoded = encodeURIComponent(word);
  return new Promise((resolve) => {
    exec(
      `curl -s "https://translate.google.com/translate_tts?client=tw-ob&q=${encoded}&tl=en" -o ${TTS_FILE}`,
      (err) => resolve(!err),
    );
  });
}

async function askClaude(apiKey: string, word: string, imageBase64: string | null) {
  const content: ClaudeContent[] = [];

  if (imageBase64) {
    content.push({
      type: "image",
      source: { type: "base64", media_type: "image/png", data: imageBase64 },
    });
  }

  content.push({
    type: "text",
    text: [
      "画面のスクリーンショットを文脈として参照し、以下の単語を説明してください。",
      "必ず以下のJSON形式のみで回答してください。JSON以外のテキストは含めないでください。",
      "",
      "英単語の場合:",
      "```json",
      "{",
      '  "isEnglish": true,',
      '  "pronunciation": "/発音記号/",',
      '  "meaning": "辞書的な基本の意味を日本語で短く（例: 薄れた、色あせた）",',
      '  "contextMeaning": "この画面上でこの単語がどういう意味で使われているかの説明（3〜5文）。「このページでは」「この画面では」のような前置きは不要。いきなり内容を説明すること",',
      '  "nuance": "この単語固有のニュアンス。類語との違いや、どういう場面で使われるかの感覚的な説明",',
      '  "synonyms": ["同義語1", "同義語2", "同義語3"],',
      '  "antonyms": ["対義語1", "対義語2", "対義語3"]',
      "}",
      "```",
      "",
      "日本語の単語の場合:",
      "```json",
      "{",
      '  "isEnglish": false,',
      '  "plainText": "画面の文脈を踏まえた3〜5文の説明"',
      "}",
      "```",
      "",
      `単語: ${word}`,
    ].join("\n"),
  });

  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 1024,
      messages: [{ role: "user", content }],
    }),
  });

  if (!res.ok) {
    throw new Error(`API error ${res.status}: ${await res.text()}`);
  }

  const data = (await res.json()) as ClaudeResponse;
  return data.content[0].text;
}

export default async function ContextCapture() {
  // 1. テキスト取得
  let word: string | undefined;
  try {
    word = (await getSelectedText())?.trim();
  } catch { /* ignore */ }
  if (!word) {
    word = (await Clipboard.readText())?.trim();
  }
  if (!word) {
    await showHUD("テキストが見つかりません");
    return;
  }

  await showHUD(`🔍 ${word}`);

  // 2. スクショ取得
  const screenshotBase64 = captureScreenshot();

  // 3. API呼び出し + TTS事前ダウンロードを並行実行
  const { apiKey } = getPreferenceValues<Preferences>();
  const [rawResponse, ttsReady] = await Promise.all([
    askClaude(apiKey, word, screenshotBase64),
    preloadTTS(word),
  ]);

  // 4. 結果表示コマンドを完成データ付きで起動
  await launchCommand({
    name: "context-result",
    type: LaunchType.UserInitiated,
    context: { word, rawResponse, ttsReady },
  });
}

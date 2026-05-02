import {
  Detail,
  LaunchProps,
  Color,
  Action,
  ActionPanel,
  getPreferenceValues,
  environment,
} from "@raycast/api";
import { useEffect, useState } from "react";
import { exec, execSync, type ChildProcess } from "child_process";
import { readFileSync, unlinkSync, existsSync } from "fs";
import { tmpdir } from "os";
import { join } from "path";

interface Preferences {
  apiKey: string;
  audioRate?: string;
}

interface ClaudeContent {
  type: string;
  text?: string;
  source?: { type: string; media_type: string; data: string };
}

interface ClaudeResponse {
  content: Array<{ text: string }>;
}

interface EnExample {
  en: string;
  ja: string;
}

interface WordData {
  isEnglish: boolean;
  pronunciation: string;
  meaning: string;
  nuance: string;
  contextMeaning: string;
  synonyms: string[];
  antonyms: string[];
  plainText: string;
  examples: EnExample[] | string[];
}

interface LaunchContext {
  word: string;
}

const TTS_FILE = `/tmp/ctx-dict-tts.mp3`;
let currentSpeech: ChildProcess | null = null;

function captureScreenshot(): string | null {
  const screenshotPath = join(tmpdir(), `ctx-dict-${Date.now()}.png`);
  try {
    const helper = join(environment.assetsPath, "capture-screen");
    if (!existsSync(helper)) return null;
    execSync(`"${helper}" "${screenshotPath}"`);
    try {
      execSync(
        `sips --resampleWidth 1280 "${screenshotPath}" --out "${screenshotPath}" 2>/dev/null`,
      );
    } catch {
      /* ignore */
    }
    if (!existsSync(screenshotPath)) return null;
    const base64 = readFileSync(screenshotPath).toString("base64");
    try {
      unlinkSync(screenshotPath);
    } catch {
      /* ignore */
    }
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

async function askClaude(
  apiKey: string,
  word: string,
  imageBase64: string | null,
) {
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
      '  "antonyms": ["対義語1", "対義語2", "対義語3"],',
      '  "examples": [',
      '    {"en": "画面の文脈に合った自然な英文1", "ja": "日本語訳1"},',
      '    {"en": "画面の文脈に合った自然な英文2", "ja": "日本語訳2"},',
      '    {"en": "画面の文脈に合った自然な英文3", "ja": "日本語訳3"}',
      "  ]",
      "}",
      "```",
      "examples は必ず3件、画面のスクリーンショットに映っているドメイン・話題・登場人物を踏まえた自然な英文にすること。汎用的な辞書例文ではなく、その画面で実際に使われそうな文を作ること。",
      "",
      "日本語の単語の場合:",
      "```json",
      "{",
      '  "isEnglish": false,',
      '  "plainText": "画面の文脈を踏まえた3〜5文の説明",',
      '  "examples": ["画面の文脈に合った例文1", "画面の文脈に合った例文2", "画面の文脈に合った例文3"]',
      "}",
      "```",
      "examples は必ず3件、画面のスクリーンショットに映っているドメイン・話題を踏まえた自然な和文にすること。",
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

function parseResponse(raw: string): WordData {
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    try {
      return JSON.parse(jsonMatch[0]) as WordData;
    } catch {
      /* ignore */
    }
  }
  return {
    isEnglish: false,
    pronunciation: "",
    meaning: "",
    nuance: "",
    contextMeaning: "",
    synonyms: [],
    antonyms: [],
    plainText: raw,
    examples: [],
  };
}

function isEnExample(e: EnExample | string): e is EnExample {
  return typeof e === "object" && e !== null && "en" in e;
}

function buildExamplesSection(
  examples: EnExample[] | string[] | undefined,
): string[] {
  if (!examples || examples.length === 0) return [];
  const lines = ["", "---", "", "### 例文"];
  for (const ex of examples) {
    if (isEnExample(ex)) {
      lines.push(`- ${ex.en}`);
      lines.push(`  ${ex.ja}`);
    } else {
      lines.push(`- ${ex}`);
    }
  }
  return lines;
}

function buildMarkdown(word: string, data: WordData): string {
  if (!data.isEnglish) {
    return [
      `## ${word}`,
      "",
      data.plainText,
      ...buildExamplesSection(data.examples),
    ].join("\n");
  }
  return [
    `## ${word}`,
    "",
    data.contextMeaning,
    "",
    "---",
    "",
    "### ニュアンス",
    data.nuance,
    ...buildExamplesSection(data.examples),
  ].join("\n");
}

function stopAudio() {
  if (currentSpeech) {
    currentSpeech.kill();
    currentSpeech = null;
  }
  try {
    execSync("killall say afplay 2>/dev/null");
  } catch {
    /* ignore */
  }
}

function speak(data: WordData, ttsReady: boolean, audioRate: string) {
  if (currentSpeech) {
    currentSpeech.kill();
    currentSpeech = null;
  }
  try {
    execSync("killall say afplay 2>/dev/null");
  } catch {
    /* ignore */
  }

  const text = data.isEnglish
    ? `${data.meaning}。${data.contextMeaning}`
    : data.plainText;
  const escaped = text.replace(/'/g, "'\\''");
  if (data.isEnglish && ttsReady) {
    currentSpeech = exec(
      `afplay -r ${audioRate} ${TTS_FILE} && say -v Kyoko -r 360 '${escaped}'`,
    );
  } else {
    currentSpeech = exec(`say -v Kyoko -r 360 '${escaped}'`);
  }
}

function MetadataPanel({ data }: { data: WordData }) {
  if (!data.isEnglish) return null;
  return (
    <Detail.Metadata>
      <Detail.Metadata.Label title="" text={data.pronunciation} />
      <Detail.Metadata.Label title="意味" text={data.meaning} />
      <Detail.Metadata.Separator />
      {data.synonyms.length > 0 && (
        <Detail.Metadata.TagList title="syn.">
          {data.synonyms.map((s) => (
            <Detail.Metadata.TagList.Item key={s} text={s} color={Color.Blue} />
          ))}
        </Detail.Metadata.TagList>
      )}
      {data.antonyms.length > 0 && (
        <Detail.Metadata.TagList title="ant.">
          {data.antonyms.map((a) => (
            <Detail.Metadata.TagList.Item
              key={a}
              text={a}
              color={Color.Orange}
            />
          ))}
        </Detail.Metadata.TagList>
      )}
    </Detail.Metadata>
  );
}

export default function ContextResult(
  props: LaunchProps<{ launchContext: LaunchContext }>,
) {
  const word = props.launchContext?.word ?? "";
  const [data, setData] = useState<WordData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    if (!word) {
      setError("単語が指定されていません。Context Lookup から起動してください。");
      setIsLoading(false);
      return;
    }
    (async () => {
      try {
        const screenshotBase64 = captureScreenshot();
        const prefs = getPreferenceValues<Preferences>();
        const audioRate = prefs.audioRate || "1.75";

        const [rawResponse, ttsReady] = await Promise.all([
          askClaude(prefs.apiKey, word, screenshotBase64),
          preloadTTS(word),
        ]);

        const parsed = parseResponse(rawResponse);
        setData(parsed);
        setIsLoading(false);
        speak(parsed, ttsReady, audioRate);
      } catch (e) {
        setError(e instanceof Error ? e.message : String(e));
        setIsLoading(false);
      }
    })();
  }, [word]);

  if (error) {
    return <Detail markdown={`## エラー\n\n${error}`} />;
  }

  const markdown = data
    ? buildMarkdown(word, data)
    : `## 🔍 ${word}\n\n_調べています…_`;

  return (
    <Detail
      isLoading={isLoading}
      markdown={markdown}
      metadata={data?.isEnglish ? <MetadataPanel data={data} /> : undefined}
      actions={
        <ActionPanel>
          <Action
            title="Stop Audio"
            shortcut={{ modifiers: ["cmd"], key: "." }}
            onAction={stopAudio}
          />
        </ActionPanel>
      }
    />
  );
}

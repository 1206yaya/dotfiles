import { Detail, LaunchProps, Color } from "@raycast/api";
import { useEffect, useState } from "react";
import { exec, execSync, type ChildProcess } from "child_process";

/** 英単語の構造化レスポンス */
interface WordData {
  isEnglish: boolean;
  pronunciation: string;
  meaning: string;
  nuance: string;
  contextMeaning: string;
  synonyms: string[];
  antonyms: string[];
  plainText: string;
}

interface LaunchContext {
  word: string;
  rawResponse: string;
  ttsReady: boolean;
}

function parseResponse(raw: string): WordData {
  const jsonMatch = raw.match(/\{[\s\S]*\}/);
  if (jsonMatch) {
    try {
      return JSON.parse(jsonMatch[0]) as WordData;
    } catch { /* ignore */ }
  }
  return { isEnglish: false, pronunciation: "", meaning: "", nuance: "", contextMeaning: "", synonyms: [], antonyms: [], plainText: raw };
}

function buildMarkdown(word: string, data: WordData): string {
  if (!data.isEnglish) {
    return `## ${word}\n\n${data.plainText}`;
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
  ].join("\n");
}

const TTS_FILE = `/tmp/ctx-dict-tts.mp3`;
let currentSpeech: ChildProcess | null = null;

function speak(data: WordData, ttsReady: boolean) {
  if (currentSpeech) {
    currentSpeech.kill();
    currentSpeech = null;
  }
  try { execSync("killall say afplay 2>/dev/null"); } catch { /* ignore */ }

  const text = data.isEnglish
    ? `${data.meaning}。${data.contextMeaning}`
    : data.plainText;
  const escaped = text.replace(/'/g, "'\\''");
  if (data.isEnglish && ttsReady) {
    currentSpeech = exec(`afplay ${TTS_FILE} && say -v Kyoko -r 360 '${escaped}'`);
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
            <Detail.Metadata.TagList.Item key={a} text={a} color={Color.Orange} />
          ))}
        </Detail.Metadata.TagList>
      )}
    </Detail.Metadata>
  );
}

export default function ContextResult(props: LaunchProps<{ launchContext: LaunchContext }>) {
  const context = props.launchContext;
  const [wordData, setWordData] = useState<WordData | null>(null);
  const [markdown, setMarkdown] = useState("");

  useEffect(() => {
    if (!context?.word) {
      setMarkdown("Context Lookup から起動してください。");
      return;
    }
    const data = parseResponse(context.rawResponse);
    setWordData(data);
    setMarkdown(buildMarkdown(context.word, data));
    speak(data, context.ttsReady);
  }, []);

  return (
    <Detail
      markdown={markdown}
      metadata={wordData?.isEnglish ? <MetadataPanel data={wordData} /> : undefined}
    />
  );
}

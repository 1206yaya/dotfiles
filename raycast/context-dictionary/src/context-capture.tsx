import {
  getSelectedText,
  Clipboard,
  showHUD,
  launchCommand,
  LaunchType,
} from "@raycast/api";

export default async function ContextCapture() {
  let word: string | undefined;
  try {
    word = (await getSelectedText())?.trim();
  } catch {
    /* selection not available — fall through to clipboard */
  }
  if (!word) {
    word = (await Clipboard.readText())?.trim();
  }
  if (!word) {
    await showHUD("テキストが見つかりません");
    return;
  }

  try {
    await launchCommand({
      name: "context-show",
      type: LaunchType.UserInitiated,
      context: { word },
    });
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    await showHUD(`⚠️ ${msg}`);
  }
}

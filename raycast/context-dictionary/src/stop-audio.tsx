import { showHUD } from "@raycast/api";
import { execSync } from "child_process";

export default async function StopAudio() {
  console.log("[stop-audio] invoked", new Date().toISOString());

  let output = "";
  try {
    output = execSync("killall say afplay 2>&1 || true", {
      stdio: ["ignore", "pipe", "pipe"],
    }).toString();
  } catch (e) {
    output = `exec failed: ${e instanceof Error ? e.message : String(e)}`;
  }
  console.log("[stop-audio] killall output:", JSON.stringify(output));

  // SIGTERM で残った場合の保険
  try {
    execSync("killall -9 say afplay 2>/dev/null || true");
    console.log("[stop-audio] SIGKILL pass done");
  } catch {
    /* ignore */
  }

  await showHUD("🔇 停止");
}

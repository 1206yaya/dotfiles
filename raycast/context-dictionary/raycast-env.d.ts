/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {
  /** Anthropic API Key - Claude API key from console.anthropic.com */
  "apiKey": string,
  /** Audio Speed - 英語TTSの再生速度（倍速） */
  "audioRate": "0.75" | "1.0" | "1.25" | "1.5" | "1.75" | "2.0"
}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `context-capture` command */
  export type ContextCapture = ExtensionPreferences & {}
  /** Preferences accessible in the `context-show` command */
  export type ContextShow = ExtensionPreferences & {}
  /** Preferences accessible in the `stop-audio` command */
  export type StopAudio = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `context-capture` command */
  export type ContextCapture = {}
  /** Arguments passed to the `context-show` command */
  export type ContextShow = {}
  /** Arguments passed to the `stop-audio` command */
  export type StopAudio = {}
}


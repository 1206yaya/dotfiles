/// <reference types="@raycast/api">

/* 🚧 🚧 🚧
 * This file is auto-generated from the extension's manifest.
 * Do not modify manually. Instead, update the `package.json` file.
 * 🚧 🚧 🚧 */

/* eslint-disable @typescript-eslint/ban-types */

type ExtensionPreferences = {
  /** Anthropic API Key - Claude API key from console.anthropic.com */
  "apiKey": string
}

/** Preferences accessible in all the extension's commands */
declare type Preferences = ExtensionPreferences

declare namespace Preferences {
  /** Preferences accessible in the `context-capture` command */
  export type ContextCapture = ExtensionPreferences & {}
  /** Preferences accessible in the `context-result` command */
  export type ContextResult = ExtensionPreferences & {}
}

declare namespace Arguments {
  /** Arguments passed to the `context-capture` command */
  export type ContextCapture = {}
  /** Arguments passed to the `context-result` command */
  export type ContextResult = {}
}


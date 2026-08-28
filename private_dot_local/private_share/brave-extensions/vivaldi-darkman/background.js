/**
 * Enable Dark Reader when darkman is dark; disable it when light.
 * Vivaldi chrome Dark/Zen is applied by vivaldi-darkman-host over CDP,
 * not from this extension (debugger permission made Vivaldi disable it).
 */

const HOST = "com.sungsik.vivaldi_darkman";
const DARK_READER_ID = "eimadpbcbfnmbkopoojfekhnkhdbieeh";

async function applyTheme(theme) {
  if (theme !== "dark" && theme !== "light") {
    return;
  }
  const enable = theme === "dark";
  try {
    const ext = await chrome.management.get(DARK_READER_ID);
    if (ext.enabled === enable) {
      return;
    }
    await chrome.management.setEnabled(DARK_READER_ID, enable);
  } catch {
    // Dark Reader is not installed in this profile.
  }
}

function connect(delayMs) {
  const port = chrome.runtime.connectNative(HOST);
  port.onMessage.addListener((msg) => {
    if (msg && typeof msg.theme === "string") {
      applyTheme(msg.theme);
    }
  });
  port.onDisconnect.addListener(() => {
    const next = Math.min(Math.max(delayMs, 1000) * 2, 15000);
    setTimeout(() => connect(next), delayMs);
  });
}

connect(1000);

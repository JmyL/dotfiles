/**
 * Follow darkman: Dark Reader on in dark / off in light, and set the
 * Vivaldi chrome theme (Dark Vivaldi2 / Zen VivaldiZen). Linux OS theme
 * schedule does not apply portal changes live, so the chrome is set via
 * chrome.debugger → vivaldi.prefs on the UI document.
 */

const HOST = "com.sungsik.vivaldi_darkman";
const DARK_READER_ID = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
const VIVALDI_APP = "mpognobbkildjkofajifpdfhcoklimli";
const THEME_IDS = { dark: "Vivaldi2", light: "VivaldiZen" };

function isUiTarget(target) {
  const url = target.url || "";
  return (
    url.includes(VIVALDI_APP) ||
    url.includes("browser.html") ||
    url.includes("window.html") ||
    url.includes("main.html")
  );
}

function debuggeeFor(target) {
  if (typeof target.tabId === "number") {
    return { tabId: target.tabId };
  }
  return { targetId: target.id };
}

function prefsExpression(themeId) {
  return `(function () {
    const id = ${JSON.stringify(themeId)};
    const prefs = typeof vivaldi !== "undefined" ? vivaldi.prefs : null;
    if (!prefs || typeof prefs.set !== "function") {
      return { ok: false, reason: "no-vivaldi-prefs" };
    }
    prefs.set({ path: "vivaldi.theme.schedule.enabled", value: "off" });
    prefs.set({ path: "vivaldi.themes.current", value: id });
    return { ok: true, id: id };
  })()`;
}

async function applyVivaldiChrome(theme) {
  const themeId = THEME_IDS[theme];
  if (!themeId || !chrome.debugger) {
    return;
  }
  let targets;
  try {
    targets = await chrome.debugger.getTargets();
  } catch {
    return;
  }
  const uiTargets = targets.filter(isUiTarget);
  const expression = prefsExpression(themeId);
  for (const target of uiTargets) {
    const debuggee = debuggeeFor(target);
    let weAttached = false;
    try {
      await chrome.debugger.attach(debuggee, "1.3");
      weAttached = true;
    } catch {
      // Already attached; still try evaluate.
    }
    try {
      const result = await chrome.debugger.sendCommand(
        debuggee,
        "Runtime.evaluate",
        {
          expression,
          returnByValue: true,
          awaitPromise: false,
        }
      );
      const value = result && result.result && result.result.value;
      if (value && value.ok) {
        break;
      }
    } catch {
      // Try the next UI document.
    } finally {
      if (weAttached) {
        try {
          await chrome.debugger.detach(debuggee);
        } catch {
          // Already detached.
        }
      }
    }
  }
}

async function applyDarkReader(theme) {
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

async function applyTheme(theme) {
  if (theme !== "dark" && theme !== "light") {
    return;
  }
  await applyDarkReader(theme);
  await applyVivaldiChrome(theme);
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

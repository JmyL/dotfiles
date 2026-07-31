/**
 * Slack stay in browser — background service worker.
 *
 * - Reuse an existing app.slack.com tab when an archives/messages permalink
 *   opens in another tab (navigate that tab, close the new one, focus it).
 * - Alt+Shift+S (command focus-slack-tab) focuses an open Slack tab.
 */

const ENTRY_PATH = /^\/(archives|messages)\//;
const SUPPRESS_MS = 5000;

// Tabs we just drove ourselves; their own navigation events must not bounce again.
const suppressed = new Map();

function suppress(tabId) {
  suppressed.set(tabId, Date.now() + SUPPRESS_MS);
}

function isSuppressed(tabId) {
  const until = suppressed.get(tabId);
  if (until === undefined) {
    return false;
  }
  if (Date.now() > until) {
    suppressed.delete(tabId);
    return false;
  }
  return true;
}

function isSlackEntryUrl(url) {
  if (!url) {
    return false;
  }
  try {
    const u = new URL(url);
    return u.hostname.endsWith(".slack.com") && ENTRY_PATH.test(u.pathname);
  } catch {
    return false;
  }
}

function isAppSlackTab(tab) {
  return Boolean(tab.url && tab.url.includes("://app.slack.com/"));
}

async function findAppSlackTab(excludeTabId) {
  const tabs = await chrome.tabs.query({ url: "*://app.slack.com/*" });
  return tabs.find((t) => t.id !== excludeTabId && isAppSlackTab(t)) || null;
}

async function focusTab(tab) {
  await chrome.tabs.update(tab.id, { active: true });
  await chrome.windows.update(tab.windowId, { focused: true });
}

async function reuseSlackTab(tabId, url) {
  if (isSuppressed(tabId)) {
    return;
  }

  const existing = await findAppSlackTab(tabId);
  if (!existing) {
    return;
  }

  suppress(tabId);
  suppress(existing.id);

  await chrome.tabs.update(existing.id, { url, active: true });
  await chrome.windows.update(existing.windowId, { focused: true });
  try {
    await chrome.tabs.remove(tabId);
  } catch {
    // Tab may already be gone.
  }
}

chrome.tabs.onCreated.addListener((tab) => {
  // Tabs opened from outside the browser already carry their URL at creation,
  // so onUpdated never reports it as a change.
  const url = tab.pendingUrl || tab.url;
  if (tab.id !== undefined && isSlackEntryUrl(url)) {
    reuseSlackTab(tab.id, url);
  }
});

chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (isSlackEntryUrl(changeInfo.url)) {
    reuseSlackTab(tabId, changeInfo.url);
  }
});

chrome.tabs.onRemoved.addListener((tabId) => {
  suppressed.delete(tabId);
});

chrome.commands.onCommand.addListener(async (command) => {
  if (command !== "focus-slack-tab") {
    return;
  }
  const tab = await findAppSlackTab(-1);
  if (tab) {
    await focusTab(tab);
  }
});

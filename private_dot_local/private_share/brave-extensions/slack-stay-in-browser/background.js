/**
 * Slack stay in browser — background service worker.
 *
 * - Reuse an existing app.slack.com tab when an archives/messages permalink
 *   opens in a new tab (navigate that tab, close the new one, focus it).
 * - Alt+Shift+S (command focus-slack-tab) focuses an open Slack tab.
 */

const ENTRY_PATH = /^\/(archives|messages)\//;

function isSlackEntryUrl(url) {
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
  const tabs = await chrome.tabs.query({
    url: ["*://app.slack.com/*", "*://*.slack.com/*"],
  });
  return tabs.find((t) => t.id !== excludeTabId && isAppSlackTab(t)) || null;
}

async function focusTab(tab) {
  await chrome.tabs.update(tab.id, { active: true });
  await chrome.windows.update(tab.windowId, { focused: true });
}

const handing = new Set();

chrome.tabs.onUpdated.addListener(async (tabId, changeInfo) => {
  if (!changeInfo.url || !isSlackEntryUrl(changeInfo.url)) {
    return;
  }
  if (handing.has(tabId)) {
    return;
  }

  const existing = await findAppSlackTab(tabId);
  if (!existing) {
    return;
  }

  handing.add(tabId);
  handing.add(existing.id);
  try {
    await chrome.tabs.update(existing.id, { url: changeInfo.url, active: true });
    await chrome.windows.update(existing.windowId, { focused: true });
    try {
      await chrome.tabs.remove(tabId);
    } catch {
      // Tab may already be gone.
    }
  } finally {
    handing.delete(tabId);
    handing.delete(existing.id);
  }
});

chrome.commands.onCommand.addListener(async (command) => {
  if (command !== "focus-slack-tab") {
    return;
  }
  const tab = await findAppSlackTab(-1);
  if (!tab) {
    return;
  }
  await focusTab(tab);
});

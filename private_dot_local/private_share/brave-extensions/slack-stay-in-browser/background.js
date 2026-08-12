/**
 * Slack stay in browser — background service worker.
 *
 * Alt+S (command focus-slack-tab) focuses an open Slack tab.
 *
 * Reusing an open tab for incoming permalinks is deliberately not attempted:
 * Slack only renders history entries it created itself, so an injected route
 * changes the URL without moving the view, and a plain navigation reloads the
 * whole client anyway.
 */

async function findAppSlackTab() {
  const tabs = await chrome.tabs.query({ url: "*://app.slack.com/*" });
  return tabs[0] || null;
}

chrome.commands.onCommand.addListener(async (command) => {
  if (command !== "focus-slack-tab") {
    return;
  }
  const tab = await findAppSlackTab();
  if (tab) {
    await chrome.tabs.update(tab.id, { active: true });
    await chrome.windows.update(tab.windowId, { focused: true });
  }
});

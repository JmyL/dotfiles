/**
 * Slack stay in browser — background service worker.
 *
 * Keyboard commands focus an open tab (pinned first):
 *   Alt+S Slack, Alt+C Google Calendar, Alt+G Gmail, Alt+W Jira.
 *
 * Reusing an open tab for incoming Slack permalinks is deliberately not
 * attempted: Slack only renders history entries it created itself, so an
 * injected route changes the URL without moving the view, and a plain
 * navigation reloads the whole client anyway.
 */

const FOCUS_COMMANDS = {
  "focus-slack-tab": {
    url: ["*://app.slack.com/*"],
  },
  "focus-calendar-tab": {
    url: ["*://calendar.google.com/*"],
  },
  "focus-gmail-tab": {
    url: ["*://mail.google.com/*"],
  },
  "focus-jira-tab": {
    url: ["*://*.atlassian.net/*"],
    filter(tab) {
      try {
        return !new URL(tab.url).pathname.startsWith("/wiki");
      } catch {
        return true;
      }
    },
  },
};

async function findTab({ url, filter }) {
  const tabs = await chrome.tabs.query({ url });
  const matched = filter ? tabs.filter(filter) : tabs;
  return matched.find((tab) => tab.pinned) || matched[0] || null;
}

async function focusTab(tab) {
  await chrome.tabs.update(tab.id, { active: true });
  await chrome.windows.update(tab.windowId, { focused: true });
}

chrome.commands.onCommand.addListener(async (command) => {
  const spec = FOCUS_COMMANDS[command];
  if (!spec) {
    return;
  }
  const tab = await findTab(spec);
  if (tab) {
    await focusTab(tab);
  }
});

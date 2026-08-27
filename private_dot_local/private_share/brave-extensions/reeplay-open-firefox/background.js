/**
 * Reeplay open in Firefox — background service worker.
 *
 * Vivaldi/Chromium on Linux cannot play the HEVC Kinesis HLS stream.
 * Intercept main-frame navigations to reeplay.reeinfra.net, hand the URL
 * to the native host (which launches Firefox), then drop the Chromium tab.
 */

const HOST = "com.sungsik.reeplay_open_firefox";
const handing = new Set();

function isReeplayUrl(url) {
  try {
    const parsed = new URL(url);
    return (
      (parsed.protocol === "https:" || parsed.protocol === "http:") &&
      parsed.hostname === "reeplay.reeinfra.net"
    );
  } catch {
    return false;
  }
}

async function dismissTab(tabId, windowId) {
  const tabs = await chrome.tabs.query({ windowId });
  if (tabs.length <= 1) {
    await chrome.tabs.update(tabId, { url: "chrome://newtab/" });
    return;
  }
  await chrome.tabs.remove(tabId);
}

async function openInFirefox(details) {
  if (details.frameId !== 0) {
    return;
  }
  if (!isReeplayUrl(details.url)) {
    return;
  }
  if (handing.has(details.tabId)) {
    return;
  }
  handing.add(details.tabId);
  try {
    const reply = await chrome.runtime.sendNativeMessage(HOST, {
      url: details.url,
    });
    if (!reply || reply.ok !== true) {
      return;
    }
    await dismissTab(details.tabId, details.windowId);
  } catch (err) {
    console.error("reeplay-open-firefox:", err);
  } finally {
    handing.delete(details.tabId);
  }
}

chrome.webNavigation.onBeforeNavigate.addListener(openInFirefox, {
  url: [{ hostEquals: "reeplay.reeinfra.net" }],
});

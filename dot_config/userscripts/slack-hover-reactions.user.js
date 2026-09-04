// ==UserScript==
// @name         Slack hover extra reactions
// @namespace    local.sungsik
// @version      1.0.0
// @description  Add white_check_mark and merged to the Slack message hover reaction bar
// @author       sungsik
// @match        https://app.slack.com/*
// @run-at       document-idle
// ==/UserScript==

(function () {
  "use strict";

  // Slack's standard name is white_check_mark (underscores). There is no
  // workspace custom emoji named white-check-mark; :merged: is custom.
  const EXTRA = [
    {
      name: "white_check_mark",
      fallbackSrc:
        "https://a.slack-edge.com/production-standard-emoji-assets/16.0/google-small/2705@2x.png",
    },
    { name: "merged" },
  ];

  const MARK = "ss-extra-reaction";

  function getTeam() {
    try {
      const cfg = JSON.parse(localStorage.getItem("localConfig_v2") || "{}");
      const id = cfg.lastActiveTeamId;
      return (cfg.teams && (cfg.teams[id] || Object.values(cfg.teams)[0])) || null;
    } catch {
      return null;
    }
  }

  function getToken() {
    const team = getTeam();
    return (team && team.token) || "";
  }

  async function slackApi(method, params) {
    const token = getToken();
    if (!token) throw new Error("no slack token");
    const res = await fetch("https://app.slack.com/api/" + method, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams(Object.assign({ token }, params)),
    });
    return res.json();
  }

  function resolveCustomSrc(emojiMap, name) {
    let v = emojiMap[name];
    const seen = new Set();
    while (typeof v === "string" && v.startsWith("alias:") && !seen.has(v)) {
      seen.add(v);
      v = emojiMap[v.slice(6)];
    }
    return typeof v === "string" && v.startsWith("http") ? v : "";
  }

  function srcFor(name) {
    const extra = EXTRA.find((e) => e.name === name);
    return (extra && (extra.src || extra.fallbackSrc)) || "";
  }

  async function loadCustomSources() {
    try {
      const json = await slackApi("emoji.list", {});
      if (!json.ok || !json.emoji) return;
      for (const extra of EXTRA) {
        const src = resolveCustomSrc(json.emoji, extra.name);
        if (src) extra.src = src;
      }
      document.querySelectorAll("button[data-" + MARK + "] img").forEach((img) => {
        const name = img.getAttribute("data-stringify-emoji");
        const src = srcFor(name);
        if (src) img.src = src;
      });
    } catch {
      // Keep fallback images; clicks still work.
    }
  }

  function messageFromBar(bar) {
    return bar.closest("[data-msg-ts][data-msg-channel-id]");
  }

  function hasUserReaction(msg, name) {
    if (!msg) return false;
    return [...msg.querySelectorAll('[data-qa="reactji"]')].some((btn) => {
      if (!btn.classList.contains("c-reaction--reacted")) return false;
      const img = btn.querySelector("[data-stringify-emoji]");
      const raw = (img && img.getAttribute("data-stringify-emoji")) || "";
      return raw.replace(/^:|:$/g, "") === name;
    });
  }

  function syncPressed(bar) {
    const msg = messageFromBar(bar);
    bar.querySelectorAll("button[data-" + MARK + "]").forEach((btn) => {
      const name = btn.getAttribute("data-" + MARK);
      btn.setAttribute("aria-pressed", hasUserReaction(msg, name) ? "true" : "false");
    });
  }

  async function toggleReaction(name, bar) {
    const msg = messageFromBar(bar);
    if (!msg) return;
    const channel = msg.getAttribute("data-msg-channel-id");
    const timestamp = msg.getAttribute("data-msg-ts");
    if (!channel || !timestamp) return;

    const removeFirst = hasUserReaction(msg, name);
    const method = removeFirst ? "reactions.remove" : "reactions.add";
    const json = await slackApi(method, { name, channel, timestamp });
    if (json.ok) return;
    if (!removeFirst && json.error === "already_reacted") {
      await slackApi("reactions.remove", { name, channel, timestamp });
      return;
    }
    if (removeFirst && json.error === "no_reaction") {
      await slackApi("reactions.add", { name, channel, timestamp });
    }
  }

  function makeButton(extra) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className =
      "c-button-unstyled c-message_actions__button c-message_actions__emoji_button";
    btn.dataset.qa = extra.name;
    btn.setAttribute("data-" + MARK, extra.name);
    btn.setAttribute("aria-label", "React with " + extra.name);
    btn.setAttribute("aria-pressed", "false");

    const img = document.createElement("img");
    img.className = "c-emoji c-emoji__small";
    img.setAttribute("data-qa", "emoji");
    img.setAttribute("data-stringify-type", "emoji");
    img.setAttribute("data-stringify-emoji", extra.name);
    img.setAttribute("aria-label", extra.name + " emoji");
    img.alt = extra.name;
    const src = srcFor(extra.name);
    if (src) img.src = src;
    btn.appendChild(img);

    btn.addEventListener(
      "click",
      (event) => {
        event.preventDefault();
        event.stopPropagation();
        toggleReaction(extra.name, btn.closest('[data-qa="message-actions"]')).catch(
          () => {}
        );
      },
      true
    );
    return btn;
  }

  function enhance(bar) {
    if (!(bar instanceof Element)) return;
    const addBtn = bar.querySelector('[data-qa="add_reaction"]');
    if (!addBtn) return;
    for (const extra of EXTRA) {
      if (bar.querySelector("button[data-" + MARK + '="' + extra.name + '"]')) {
        continue;
      }
      if (
        bar.querySelector(
          'button.c-message_actions__emoji_button[data-qa="' + extra.name + '"]'
        )
      ) {
        continue;
      }
      addBtn.before(makeButton(extra));
    }
    syncPressed(bar);
  }

  function scan(root) {
    const scope = root instanceof Element || root === document ? root : document;
    if (scope instanceof Element && scope.matches('[data-qa="message-actions"]')) {
      enhance(scope);
    }
    const list =
      scope.querySelectorAll && scope.querySelectorAll('[data-qa="message-actions"]');
    if (list) list.forEach(enhance);
  }

  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      for (const node of mutation.addedNodes) {
        if (node.nodeType === 1) scan(node);
      }
    }
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });
  scan(document);
  loadCustomSources();
})();

// ==UserScript==
// @name         CircleCI tab status + notify
// @namespace    local.sungsik
// @version      1.0.0
// @description  Show CircleCI status in the tab title; system notify when a watched run finishes
// @author       sungsik
// @match        https://app.circleci.com/*
// @grant        GM_notification
// @run-at       document-idle
// ==/UserScript==

(function () {
  "use strict";

  const RUNNING = new Set([
    "running",
    "queued",
    "not_run",
    "on_hold",
    "failing",
    "pending",
    "setup",
  ]);
  const TERMINAL = new Set([
    "success",
    "failed",
    "error",
    "canceled",
    "cancelled",
    "unauthorized",
  ]);

  const TITLE_MARK = {
    running: "⏳",
    queued: "…",
    not_run: "…",
    on_hold: "⏸",
    failing: "⚠",
    pending: "…",
    setup: "…",
    success: "✓",
    failed: "✗",
    error: "✗",
    canceled: "■",
    cancelled: "■",
    unauthorized: "✗",
  };

  const DOM_STATUS_RE =
    /\b(Success|Failed|Failing|Error|Running|Queued|On Hold|Canceled|Cancelled|Not run|Unauthorized|Pending)\b/i;

  let lastStatus = null;
  let label = pageLabel();
  let baseTitle = stripStatusTitle(document.title);
  let notifiedFor = null;
  let page = parsePage();

  function normalizeStatus(raw) {
    if (raw == null) return null;
    const s = String(raw).trim().toLowerCase().replace(/\s+/g, "_");
    if (s === "cancelled") return "canceled";
    if (RUNNING.has(s) || TERMINAL.has(s)) return s;
    return null;
  }

  function parsePage() {
    const m = location.pathname.match(
      /\/pipelines\/(?:github|gh|bitbucket|bb)\/([^/]+)\/([^/]+)(?:\/(\d+))?(?:\/workflows\/([^/]+))?(?:\/jobs\/(\d+))?/i
    );
    if (!m) return { org: null, project: null, pipeNum: null, workflowId: null, jobNum: null };
    return {
      org: m[1],
      project: m[2],
      pipeNum: m[3] || null,
      workflowId: m[4] || null,
      jobNum: m[5] || null,
    };
  }

  function pageLabel() {
    const p = parsePage();
    if (!p.org) return "CircleCI";
    if (p.jobNum) return `${p.org}/${p.project} #${p.pipeNum} job ${p.jobNum}`;
    if (p.pipeNum) return `${p.org}/${p.project} #${p.pipeNum}`;
    return `${p.org}/${p.project}`;
  }

  function relevantToPage(obj) {
    if (!obj || typeof obj !== "object") return true;
    if (!page.workflowId && !page.pipeNum) return true;
    const id = obj.id || obj.workflow_id || obj.workflowId;
    const num = obj.pipeline_number || obj.pipelineNumber || obj.number;
    const jobNum = obj.job_number || obj.jobNumber;
    if (page.workflowId && id && String(id) === page.workflowId) return true;
    if (page.jobNum && jobNum && String(jobNum) === page.jobNum) return true;
    if (!page.workflowId && page.pipeNum && num && String(num) === page.pipeNum) return true;
    // Objects without identifying fields are allowed (nested status-only nodes).
    if (!id && !num && !jobNum) return true;
    return false;
  }

  function stripStatusTitle(title) {
    return String(title || "")
      .replace(/^[⏳…⏸⚠✓✗■]\s+\S+\s+[·•|-]\s*/u, "")
      .replace(/^\[(?:running|success|failed|error|canceled|on_hold|queued|failing)\]\s*/i, "")
      .trim();
  }

  function applyTitle(status) {
    const mark = TITLE_MARK[status] || "•";
    const pretty = status.replace(/_/g, " ");
    const rest = baseTitle || label || "CircleCI";
    const next = `${mark} ${pretty} · ${rest}`;
    if (document.title !== next) document.title = next;
  }

  function notifyFinished(status) {
    const key = `${location.pathname}|${status}`;
    if (notifiedFor === key) return;
    notifiedFor = key;

    const ok = status === "success";
    const title = ok ? "CircleCI succeeded" : `CircleCI ${status.replace(/_/g, " ")}`;
    const text = label;

    if (typeof GM_notification === "function") {
      GM_notification({
        title,
        text,
        silent: false,
        timeout: 0,
        onclick: () => window.focus(),
      });
      return;
    }

    if (!("Notification" in window)) return;
    const show = () =>
      new Notification(title, { body: text, tag: key, renotify: true });
    if (Notification.permission === "granted") show();
    else if (Notification.permission !== "denied") {
      Notification.requestPermission().then((p) => {
        if (p === "granted") show();
      });
    }
  }

  function considerStatus(raw, sourceLabel) {
    const status = normalizeStatus(raw);
    if (!status) return;

    if (sourceLabel) label = sourceLabel;
    else label = pageLabel();

    if (!baseTitle) baseTitle = stripStatusTitle(document.title) || label;

    const prev = lastStatus;
    lastStatus = status;
    applyTitle(status);

    if (prev && RUNNING.has(prev) && TERMINAL.has(status)) {
      notifyFinished(status);
    }
  }

  function walkStatus(value, depth) {
    if (depth > 8 || value == null) return;
    if (typeof value !== "object") return;

    if (typeof value.status === "string" && relevantToPage(value)) {
      const name =
        value.name ||
        value.job_name ||
        value.workflow_name ||
        value.project_slug ||
        null;
      const slug = value.project_slug || value.projectSlug;
      const num = value.pipeline_number || value.number;
      let lbl = null;
      if (slug && num) lbl = `${slug} #${num}`;
      else if (name) lbl = String(name);
      considerStatus(value.status, lbl);
    }

    if (Array.isArray(value)) {
      for (const item of value) walkStatus(item, depth + 1);
      return;
    }
    for (const k of Object.keys(value)) {
      if (
        k === "status" ||
        k === "items" ||
        k === "workflows" ||
        k === "jobs" ||
        k === "data" ||
        k === "node" ||
        k === "pipeline"
      ) {
        walkStatus(value[k], depth + 1);
      }
    }
  }

  function scanDom() {
    const nodes = document.querySelectorAll(
      '[data-testid*="status" i], [class*="status" i], [aria-label*="status" i], span, div, button'
    );
    let found = null;
    for (const el of nodes) {
      if (!(el instanceof HTMLElement)) continue;
      if (el.childElementCount > 3) continue;
      const text = (el.textContent || "").trim();
      if (!text || text.length > 32) continue;
      const m = text.match(DOM_STATUS_RE);
      if (!m) continue;
      // Prefer badges near the top of the page.
      const rect = el.getBoundingClientRect();
      if (rect.top < 0 || rect.top > 280) continue;
      found = m[1];
      break;
    }
    if (found) considerStatus(found);
  }

  function hookNetwork() {
    const origFetch = window.fetch;
    window.fetch = async function (...args) {
      const res = await origFetch.apply(this, args);
      try {
        const req = args[0];
        const url = typeof req === "string" ? req : req && req.url;
        if (url && /circleci\.com|\/api\/|graphql|workflow|pipeline|job/i.test(url)) {
          const clone = res.clone();
          clone
            .json()
            .then((data) => walkStatus(data, 0))
            .catch(() => {});
        }
      } catch (_) {
        /* ignore */
      }
      return res;
    };

    const OrigXHR = window.XMLHttpRequest;
    function XHR() {
      const xhr = new OrigXHR();
      const open = xhr.open;
      xhr.open = function (method, url, ...rest) {
        this.__cciUrl = url;
        return open.call(this, method, url, ...rest);
      };
      xhr.addEventListener("load", function () {
        const url = String(this.__cciUrl || "");
        if (!/circleci\.com|\/api\/|graphql|workflow|pipeline|job/i.test(url)) return;
        try {
          walkStatus(JSON.parse(this.responseText), 0);
        } catch (_) {
          /* ignore */
        }
      });
      return xhr;
    }
    XHR.prototype = OrigXHR.prototype;
    window.XMLHttpRequest = XHR;
  }

  // Keep our title if the SPA overwrites it.
  const titleEl = document.querySelector("title");
  if (titleEl) {
    new MutationObserver(() => {
      if (!lastStatus) {
        baseTitle = stripStatusTitle(document.title) || baseTitle;
        return;
      }
      const stripped = stripStatusTitle(document.title);
      if (stripped && stripped !== label) baseTitle = stripped;
      applyTitle(lastStatus);
    }).observe(titleEl, { childList: true, characterData: true, subtree: true });
  }

  hookNetwork();
  scanDom();
  setInterval(scanDom, 2000);

  function resetPage() {
    page = parsePage();
    label = pageLabel();
    lastStatus = null;
    notifiedFor = null;
    baseTitle = stripStatusTitle(document.title) || label;
  }

  window.addEventListener("popstate", resetPage);
  const origPush = history.pushState;
  const origReplace = history.replaceState;
  history.pushState = function (...args) {
    const ret = origPush.apply(this, args);
    resetPage();
    return ret;
  };
  history.replaceState = function (...args) {
    const ret = origReplace.apply(this, args);
    resetPage();
    return ret;
  };
})();

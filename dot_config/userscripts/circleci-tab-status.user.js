// ==UserScript==
// @name         CircleCI tab status + notify
// @namespace    local.sungsik
// @version      1.2.0
// @description  Status-colored CircleCI favicon (C on yellow/green/red); notify when a run finishes
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

  // Favicon badge colors (logo stays white-ish on top).
  const STATUS_COLOR = {
    running: "#eab308", // yellow
    queued: "#eab308",
    not_run: "#eab308",
    pending: "#eab308",
    setup: "#eab308",
    on_hold: "#3b82f6", // blue
    failing: "#f97316", // orange
    success: "#22c55e", // green
    failed: "#ef4444", // red
    error: "#ef4444",
    canceled: "#6b7280", // gray
    cancelled: "#6b7280",
    unauthorized: "#ef4444",
  };

  const DOM_STATUS_RE =
    /\b(Success|Failed|Failing|Error|Running|Queued|On Hold|Canceled|Cancelled|Not run|Unauthorized|Pending)\b/i;

  let lastStatus = null;
  let label = pageLabel();
  let notifiedFor = null;
  let page = parsePage();
  let applyingFavicon = false;

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
    if (!id && !num && !jobNum) return true;
    return false;
  }

  function currentIconLink() {
    return (
      document.querySelector('link[rel="icon"]') ||
      document.querySelector('link[rel="shortcut icon"]') ||
      document.querySelector('link[rel*="icon"]')
    );
  }

  function setFaviconHref(href) {
    applyingFavicon = true;
    let link = currentIconLink();
    if (!link) {
      link = document.createElement("link");
      link.rel = "icon";
      document.head.appendChild(link);
    }
    link.type = "image/png";
    link.href = href;
    // Nudge Chromium to refresh the tab icon.
    const clone = link.cloneNode(true);
    link.parentNode.replaceChild(clone, link);
    queueMicrotask(() => {
      applyingFavicon = false;
    });
  }

  function drawStatusFavicon(status) {
    const color = STATUS_COLOR[status] || "#6b7280";
    const size = 64;
    const canvas = document.createElement("canvas");
    canvas.width = size;
    canvas.height = size;
    const ctx = canvas.getContext("2d");

    ctx.beginPath();
    ctx.arc(size / 2, size / 2, size / 2, 0, Math.PI * 2);
    ctx.fillStyle = color;
    ctx.fill();

    ctx.fillStyle = "#fff";
    ctx.font = "bold 42px system-ui, sans-serif";
    ctx.textAlign = "center";
    ctx.textBaseline = "middle";
    ctx.fillText("C", size / 2, size / 2 + 2);

    setFaviconHref(canvas.toDataURL("image/png"));
  }

  function applyFavicon(status) {
    drawStatusFavicon(status);
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

    const prev = lastStatus;
    if (prev === status) return;
    lastStatus = status;
    applyFavicon(status);

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

  // If the SPA swaps the favicon back, re-apply ours.
  const headObserver = new MutationObserver(() => {
    if (applyingFavicon || !lastStatus) return;
    const link = currentIconLink();
    if (!link) return;
    const href = link.getAttribute("href") || "";
    if (!href.startsWith("data:")) applyFavicon(lastStatus);
  });
  headObserver.observe(document.head, {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ["href"],
  });

  hookNetwork();
  scanDom();
  setInterval(scanDom, 2000);

  function resetPage() {
    page = parsePage();
    label = pageLabel();
    lastStatus = null;
    notifiedFor = null;
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

// @ts-nocheck

import { spawn, spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
import { mkdirSync, renameSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type Attention = {
    target: string;
    sessionName: string;
    lookingAtIt: boolean;
};

function tmuxPane(): string | undefined {
    return process.env.TMUX_PANE || undefined;
}

function inTmux(): boolean {
    return !!process.env.TMUX && !!tmuxPane();
}

function run(command: string, args: string[]): void {
    spawnSync(command, args, { stdio: "ignore" });
}

function setPaneOption(name: string, value?: string): void {
    const pane = tmuxPane();
    if (!pane) {
        return;
    }

    if (value === undefined) {
        run("tmux", ["set-option", "-p", "-u", "-t", pane, name]);
    } else {
        run("tmux", ["set-option", "-p", "-t", pane, name, value]);
    }
}

function commandSucceeds(command: string, args: string[]): boolean {
    return spawnSync(command, args, { stdio: "ignore" }).status === 0;
}

function commandOutput(command: string, args: string[]): string {
    const result = spawnSync(command, args, { encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] });
    return result.status === 0 ? result.stdout.trim() : "";
}

function tmuxSwayConId(sessionId: string): string {
    if (!sessionId) {
        return "";
    }

    const clients = spawnSync("tmux", ["list-clients", "-t", sessionId, "-F", "#{client_activity}\t#{client_tty}\t#{client_pid}"], {
        encoding: "utf8",
        stdio: ["ignore", "pipe", "ignore"],
    });
    if (clients.status !== 0) {
        return "";
    }

    const clientPids = clients.stdout
        .trim()
        .split("\n")
        .filter(Boolean)
        .map((line) => {
            const [activity, , pid] = line.split("\t");
            return { activity: Number(activity || 0), pid: pid || "" };
        })
        .filter((client) => client.pid)
        .sort((a, b) => b.activity - a.activity)
        .map((client) => client.pid);

    for (const pid of clientPids) {
        const conId = commandOutput("sway-process-window", [pid]);
        if (conId) {
            return conId;
        }
    }

    return "";
}

function locateAttention(): Attention | undefined {
    const pane = tmuxPane();
    if (!pane) {
        const segments: string[] = [];
        const conId = commandOutput("sway-process-window", [String(process.pid)]);
        if (conId) {
            segments.push(`sway-window:${conId}`);
        }
        if (process.env.KITTY_WINDOW_ID && /^[0-9]+$/.test(process.env.KITTY_WINDOW_ID)) {
            segments.push(`kitty-window:${process.env.KITTY_WINDOW_ID}`);
        }
        if (segments.length === 0) {
            return undefined;
        }
        return { target: segments.join(","), sessionName: basename(process.cwd()), lookingAtIt: false };
    }

    const display = spawnSync(
        "tmux",
        [
            "display-message",
            "-p",
            "-t",
            pane,
            "#{session_id}\t#{session_name}\t#{pane_active}\t#{window_active}",
        ],
        { encoding: "utf8" },
    );
    if (display.status !== 0) {
        return undefined;
    }

    const [sessionId, sessionName, paneActive, windowActive] = display.stdout.trimEnd().split("\t");
    const conId = tmuxSwayConId(sessionId) || commandOutput("sway-process-window", [String(process.pid)]);
    const target = conId ? `sway-window:${conId},tmux:${pane}` : `tmux:${pane}`;
    let lookingAtIt = false;
    if (paneActive === "1" && windowActive === "1" && conId) {
        lookingAtIt = commandSucceeds("sway-window-focused", [conId]);
    }

    return { target, sessionName, lookingAtIt };
}

function runtimeStateKey(target: string): string {
    for (const segment of target.split(",")) {
        if (segment.startsWith("tmux:")) {
            return `tmux-${segment.slice(5).replace(/[^A-Za-z0-9_.-]/g, "_")}`;
        }
    }
    for (const segment of target.split(",")) {
        if (segment.startsWith("kitty-window:")) {
            return `kitty-window-${segment.slice(13).replace(/[^A-Za-z0-9_.-]/g, "_")}`;
        }
    }
    return `target-${createHash("sha256").update(target).digest("hex").slice(0, 24)}`;
}

function runtimeAgentsDir(): string {
    return `${process.env.XDG_RUNTIME_DIR || tmpdir()}/ai-hook-notify/agents`;
}

function writeRuntimeState(state: string, target: string, cwd: string | undefined, summary = ""): void {
    if (!target) {
        return;
    }
    try {
        const dir = runtimeAgentsDir();
        mkdirSync(dir, { recursive: true, mode: 0o700 });
        const path = `${dir}/${runtimeStateKey(target)}.json`;
        const tmpPath = `${dir}/.tmp-${process.pid}-${Date.now()}.json`;
        writeFileSync(
            tmpPath,
            `${JSON.stringify({
                state,
                agent: "pi",
                target,
                cwd: cwd || process.cwd(),
                summary,
                updated_at: Math.floor(Date.now() / 1000),
            })}\n`,
            { encoding: "utf8", mode: 0o600 },
        );
        renameSync(tmpPath, path);
    } catch {
        // Best effort only; pane options and notifications still work without this file.
    }
}

function removeRuntimeState(target: string): void {
    if (!target) {
        return;
    }
    try {
        rmSync(`${runtimeAgentsDir()}/${runtimeStateKey(target)}.json`, { force: true });
    } catch {
        // Best effort cleanup.
    }
}

function summarizeText(value: unknown): string {
    if (typeof value === "string") {
        return value.replace(/\s+/g, " ").trim();
    }
    if (Array.isArray(value)) {
        return value.map(summarizeText).filter(Boolean).join(" ");
    }
    if (value && typeof value === "object") {
        const record = value as Record<string, unknown>;
        if (typeof record.text === "string") {
            return record.text.replace(/\s+/g, " ").trim();
        }
        if (typeof record.content === "string" || Array.isArray(record.content)) {
            return summarizeText(record.content);
        }
    }
    return "";
}

function lastAssistantSummary(messages: unknown[]): string {
    for (let i = messages.length - 1; i >= 0; i -= 1) {
        const message = messages[i] as Record<string, unknown>;
        if (message?.role !== "assistant") {
            continue;
        }
        const summary = summarizeText(message.content);
        if (summary.length > 0) {
            return summary.length > 140 ? `${summary.slice(0, 137)}...` : summary;
        }
    }
    return "(no summary)";
}

function questionPromptSummary(input: unknown): string {
    if (!input || typeof input !== "object") {
        return "Pi needs your input";
    }

    const questions = (input as Record<string, unknown>).questions;
    if (!Array.isArray(questions)) {
        return "Pi needs your input";
    }

    for (const item of questions) {
        if (!item || typeof item !== "object") {
            continue;
        }
        const question = (item as Record<string, unknown>).question;
        if (typeof question === "string" && question.trim()) {
            const summary = question.replace(/\s+/g, " ").trim();
            return summary.length > 140 ? `${summary.slice(0, 137)}...` : summary;
        }
    }

    return "Pi needs your input";
}

function markBusy(target: string | undefined, cwd: string | undefined): void {
    setPaneOption("@ai_state", "busy");
    if (target) {
        writeRuntimeState("busy", target, cwd, "");
    }
}

function notifyDone(title: string, body: string): void {
    const attention = locateAttention();
    if (!attention) {
        return;
    }

    if (attention.lookingAtIt) {
        setPaneOption("@ai_state");
        writeRuntimeState("idle", attention.target, process.cwd(), "");
        return;
    }

    setPaneOption("@ai_state", "done");
    writeRuntimeState("done", attention.target, process.cwd(), body);
    const child = spawn("ai-notify-and-goto", ["pi", attention.target, title || attention.sessionName, body], {
        detached: true,
        stdio: "ignore",
    });
    child.unref();
}

function notifyBlocked(message: string, cwd: string | undefined): void {
    const attention = locateAttention();
    if (!attention) {
        return;
    }

    if (attention.lookingAtIt) {
        setPaneOption("@ai_state");
        writeRuntimeState("idle", attention.target, cwd, "");
        return;
    }

    setPaneOption("@ai_state", "blocked");
    const title = cwd ? basename(cwd) : attention.sessionName;
    writeRuntimeState("blocked", attention.target, cwd, message || "Pi needs your input");
    const child = spawn("ai-notify-and-goto", ["pi", attention.target, title, message || "Pi needs your input"], {
        detached: true,
        stdio: "ignore",
    });
    child.unref();
}

export default function (pi: ExtensionAPI) {
    let rootSession = false;
    let blockedCount = 0;
    let activeCwd: string | undefined;
    let activeTarget: string | undefined;
    const blockedQuestionToolCalls = new Set<string>();

    pi.on("session_start", (_event, ctx) => {
        if (ctx?.hasUI !== true) {
            return;
        }
        rootSession = true;
        activeCwd = ctx.cwd;
        activeTarget = locateAttention()?.target;
        setPaneOption("@ai_cli", "1");
        setPaneOption("@ai_state");
        setPaneOption("@ai_notif_id");
        if (activeTarget) {
            writeRuntimeState("idle", activeTarget, activeCwd, "");
        }
    });

    pi.on("agent_start", () => {
        if (!rootSession) {
            return;
        }
        blockedCount = 0;
        blockedQuestionToolCalls.clear();
        activeTarget = locateAttention()?.target || activeTarget;
        markBusy(activeTarget, activeCwd);
    });

    pi.events.on("herdr:blocked", (data) => {
        if (!rootSession) {
            return;
        }
        if (!data?.active) {
            blockedCount = Math.max(0, blockedCount - 1);
            if (blockedCount === 0) {
                markBusy(activeTarget, activeCwd);
            }
            return;
        }

        blockedCount += 1;
        notifyBlocked(String(data.label || "Pi needs your input"), activeCwd);
    });

    pi.on("tool_call", (event) => {
        if (!rootSession || event.toolName !== "ask_user_question") {
            return;
        }

        blockedQuestionToolCalls.add(event.toolCallId);
        blockedCount += 1;
        notifyBlocked(questionPromptSummary(event.input), activeCwd);
    });

    pi.on("tool_execution_end", (event) => {
        if (!rootSession || !blockedQuestionToolCalls.delete(event.toolCallId)) {
            return;
        }

        blockedCount = Math.max(0, blockedCount - 1);
        if (blockedCount === 0) {
            activeTarget = locateAttention()?.target || activeTarget;
            markBusy(activeTarget, activeCwd);
        }
    });

    pi.on("agent_end", (event) => {
        if (!rootSession) {
            return;
        }
        if (blockedCount > 0) {
            return;
        }

        blockedCount = 0;
        blockedQuestionToolCalls.clear();
        const folder = activeCwd ? basename(activeCwd) : "Pi";
        notifyDone(folder, lastAssistantSummary(Array.isArray(event.messages) ? event.messages : []));
    });

    pi.on("session_shutdown", () => {
        if (!rootSession) {
            return;
        }
        setPaneOption("@ai_state");
        setPaneOption("@ai_notif_id");
        if (activeTarget) {
            removeRuntimeState(activeTarget);
        }
    });
}

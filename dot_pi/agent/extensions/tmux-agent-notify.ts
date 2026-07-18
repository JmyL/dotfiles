// @ts-nocheck

import { spawn, spawnSync } from "node:child_process";
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

function locateAttention(): Attention | undefined {
    const pane = tmuxPane();
    if (!pane) {
        return undefined;
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
    let lookingAtIt = false;
    if (paneActive === "1" && windowActive === "1" && commandSucceeds("which", ["swaymsg"])) {
        const clients = spawnSync(
            "tmux",
            ["list-clients", "-t", sessionId, "-F", "#{client_activity} #{client_tty}"],
            { encoding: "utf8" },
        );
        const bestTty = clients.stdout
            .trim()
            .split("\n")
            .filter(Boolean)
            .sort((a, b) => Number(b.split(" ")[0]) - Number(a.split(" ")[0]))[0]
            ?.split(" ")[1];
        lookingAtIt = !!bestTty && commandSucceeds("sway-tty-window", ["--is-focused", bestTty]);
    }

    return { target: pane, sessionName, lookingAtIt };
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

function notifyDone(title: string, body: string): void {
    const attention = locateAttention();
    if (!attention) {
        return;
    }

    if (attention.lookingAtIt) {
        setPaneOption("@ai_state");
        return;
    }

    setPaneOption("@ai_state", "done");
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
        return;
    }

    setPaneOption("@ai_state", "blocked");
    const title = cwd ? basename(cwd) : attention.sessionName;
    const child = spawn("ai-notify-and-goto", ["pi", attention.target, title, message || "Pi needs your input"], {
        detached: true,
        stdio: "ignore",
    });
    child.unref();
}

export default function (pi: ExtensionAPI) {
    if (!inTmux()) {
        return;
    }

    let rootSession = false;
    let blockedCount = 0;
    let activeCwd: string | undefined;

    pi.on("session_start", (_event, ctx) => {
        if (ctx?.hasUI !== true) {
            return;
        }
        rootSession = true;
        activeCwd = ctx.cwd;
        setPaneOption("@ai_cli", "1");
    });

    pi.on("agent_start", () => {
        if (!rootSession) {
            return;
        }
        blockedCount = 0;
        setPaneOption("@ai_state", "busy");
    });

    pi.events.on("herdr:blocked", (data) => {
        if (!rootSession) {
            return;
        }
        if (!data?.active) {
            blockedCount = Math.max(0, blockedCount - 1);
            if (blockedCount === 0) {
                setPaneOption("@ai_state", "busy");
            }
            return;
        }

        blockedCount += 1;
        notifyBlocked(String(data.label || "Pi needs your input"), activeCwd);
    });

    pi.on("agent_end", (event) => {
        if (!rootSession) {
            return;
        }
        blockedCount = 0;
        const folder = activeCwd ? basename(activeCwd) : "Pi";
        notifyDone(folder, lastAssistantSummary(Array.isArray(event.messages) ? event.messages : []));
    });

    pi.on("session_shutdown", () => {
        if (!rootSession) {
            return;
        }
        setPaneOption("@ai_state");
        setPaneOption("@ai_notif_id");
    });
}

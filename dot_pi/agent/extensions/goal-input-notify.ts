// @ts-nocheck
// Custom extension — NOT managed by herdr; `herdr integration install pi`
// only rewrites herdr-agent-state.ts, so this file survives reinstalls.
//
// Purpose: pi-goal-x asks the user for input without the agent turn ending
// (goal_question / goal_questionnaire / propose_goal_draft render custom TUI
// dialogs), so neither the done alarm (agent_end) nor herdr's dialog scanner
// notices. This extension publishes "herdr:blocked" on the pi extension event
// bus so the existing alarm pipelines fire without any new notification code:
//
//   - herdr panes:  herdr-agent-state -> pane.report_agent(blocked)
//                   -> herdr-focus-notify desktop notification
//   - other panes:  tmux-agent-notify's "herdr:blocked" listener
//                   -> ai-notify-and-goto (notification + sound)
//
// A goal parked via update_goal({ status: "blocked" }) is reported after the
// turn settles (deferred) so it is not overwritten by herdr-agent-state's
// idle report for the settling turn. In non-herdr panes that case is already
// covered by the agent_end done alarm, so it is only emitted under herdr.

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const GOAL_INPUT_TOOLS = new Set(["goal_question", "goal_questionnaire", "propose_goal_draft"]);

/** herdr-agent-state sends its idle report right after settling; stay behind it. */
const SETTLE_REPORT_DELAY_MS = 300;

function inHerdrPane(): boolean {
    return process.env.HERDR_ENV === "1" && !!process.env.HERDR_PANE_ID;
}

function summarize(value: unknown): string {
    if (typeof value !== "string") {
        return "";
    }
    return value.replace(/\s+/g, " ").trim().slice(0, 140);
}

function blockedLabel(toolName: string, input: unknown): string {
    const fallback = "pi-goal-x needs your input";
    if (!input || typeof input !== "object") {
        return fallback;
    }
    const params = input as Record<string, unknown>;
    const direct = summarize(params.question ?? params.objective ?? params.reason);
    if (direct) {
        return direct;
    }
    if (Array.isArray(params.questions)) {
        for (const item of params.questions) {
            const question = summarize(item && typeof item === "object" ? (item as Record<string, unknown>).question : undefined);
            if (question) {
                return question;
            }
        }
    }
    return fallback;
}

export default function (pi: ExtensionAPI) {
    let rootSession = false;
    let goalBlockedActive = false;
    const pendingInputCalls = new Set<string>();
    const pendingBlockedCalls = new Set<string>();

    function emitBlocked(active: boolean, label?: string): void {
        pi.events.emit("herdr:blocked", active ? { active: true, label: label || "pi-goal-x needs your input" } : { active: false });
    }

    pi.on("session_start", (_event, ctx) => {
        // TUI only, matching herdr-agent-state's gate: RPC/JSON/print modes are headless.
        if (ctx?.mode !== "tui") {
            return;
        }
        rootSession = true;
        goalBlockedActive = false;
        pendingInputCalls.clear();
        pendingBlockedCalls.clear();
    });

    pi.on("agent_start", () => {
        if (!rootSession) {
            return;
        }
        // A new turn means the user answered or resumed; drop the parked-goal blocked state.
        if (goalBlockedActive) {
            goalBlockedActive = false;
            emitBlocked(false);
        }
    });

    pi.on("tool_call", (event) => {
        if (!rootSession) {
            return;
        }
        if (GOAL_INPUT_TOOLS.has(event.toolName)) {
            const first = pendingInputCalls.size === 0;
            pendingInputCalls.add(event.toolCallId);
            if (first) {
                emitBlocked(true, blockedLabel(event.toolName, event.input));
            }
        } else if (event.toolName === "update_goal") {
            if (event.input?.status === "blocked") {
                pendingBlockedCalls.add(event.toolCallId);
            } else {
                // The goal moved on by itself; do not report blocked at settle time.
                goalBlockedActive = false;
            }
        }
    });

    pi.on("tool_execution_end", (event) => {
        if (!rootSession) {
            return;
        }
        if (pendingInputCalls.delete(event.toolCallId) && pendingInputCalls.size === 0) {
            emitBlocked(false);
        } else if (pendingBlockedCalls.delete(event.toolCallId) && !event.isError) {
            goalBlockedActive = true;
        }
    });

    pi.on("agent_settled", (_event, ctx) => {
        if (!rootSession || ctx?.isIdle?.() !== true || !goalBlockedActive) {
            return;
        }
        if (!inHerdrPane()) {
            // tmux-agent-notify already alarmed via agent_end (done); avoid a double notification.
            return;
        }
        setTimeout(() => {
            if (goalBlockedActive) {
                emitBlocked(true, "Goal blocked - needs your input");
            }
        }, SETTLE_REPORT_DELAY_MS);
    });

    pi.on("session_shutdown", () => {
        if (!rootSession) {
            return;
        }
        rootSession = false;
        goalBlockedActive = false;
        pendingInputCalls.clear();
        pendingBlockedCalls.clear();
    });
}

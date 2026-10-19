/**
 * q-prefix — prepend "Q: " to every user message as it is submitted.
 *
 * The prefix is not visible while typing; it is added when the message is
 * sent, so it lands in the pane scrollback and the session log. That makes
 * your questions easy to find later:
 *
 *   herdr copy mode:  ?Q: + Enter (backward), then n / N
 *   session files:    rg "^Q: " <session.jsonl>
 *
 * Slash commands and extension-injected messages are left untouched.
 * Toggle with /q-prefix.
 */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	let enabled = true;

	pi.registerCommand("q-prefix", {
		description: "Toggle the Q: prefix on submitted messages",
		handler: async (_args, ctx) => {
			enabled = !enabled;
			ctx.ui.notify(`Q: prefix ${enabled ? "on" : "off"}`, "info");
		},
	});

	pi.on("input", async (event) => {
		if (!enabled) return { action: "continue" };
		if (event.source === "extension") return { action: "continue" };
		const text = event.text.trim();
		if (!text) return { action: "continue" };
		if (text.startsWith("/")) return { action: "continue" };
		if (text.startsWith("Q:")) return { action: "continue" };
		return { action: "transform", text: `Q: ${event.text}` };
	});
}

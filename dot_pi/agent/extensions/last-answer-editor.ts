import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function textFromContent(content: unknown): string {
	if (!Array.isArray(content)) return "";
	return content
		.map((part: any) => {
			if (part?.type === "text" && typeof part.text === "string") return part.text;
			return "";
		})
		.filter(Boolean)
		.join("\n\n");
}

function findLastAssistantText(ctx: any): string | undefined {
	const branch = ctx.sessionManager.getBranch();
	for (let i = branch.length - 1; i >= 0; i--) {
		const entry = branch[i];
		if (entry?.type !== "message") continue;
		const message = entry.message;
		if (message?.role !== "assistant") continue;
		const text = textFromContent(message.content).trim();
		if (text) return text;
	}
	return undefined;
}

const runAnswerToEditor = async (ctx: any) => {
	const text = findLastAssistantText(ctx);
	if (!text) {
		ctx.ui.notify("No assistant text answer found.", "warning");
		return;
	}

	ctx.ui.setEditorText(text);
	ctx.ui.notify("Last assistant answer loaded into editor. Press Ctrl+G to open it in $VISUAL/$EDITOR.", "info");
};

export default function (pi: ExtensionAPI) {
	pi.registerCommand("answer-to-editor", {
		description: "Put the last assistant text answer into the input editor; press Ctrl+G to open it in $VISUAL/$EDITOR.",
		handler: async (_args, ctx) => {
			await runAnswerToEditor(ctx);
		},
	});

	pi.registerCommand("ate", {
		description: "Alias for /answer-to-editor.",
		handler: async (_args, ctx) => {
			await runAnswerToEditor(ctx);
		},
	});
}

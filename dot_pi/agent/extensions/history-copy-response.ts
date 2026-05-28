import { execFileSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { DynamicBorder, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Key, SelectList, Text, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { homedir } from "node:os";
import { join } from "node:path";

const LABEL_PREVIEW_LIMIT = 70;

const extractTextBlocks = (content: unknown): string[] => {
	if (typeof content === "string") {
		return content.trim().length > 0 ? [content] : [];
	}
	if (!Array.isArray(content)) return [];
	return content.flatMap((block) =>
		block && typeof block === "object" && (block as any).type === "text" && typeof (block as any).text === "string" && (block as any).text.trim().length > 0
			? [(block as any).text]
			: [],
	);
};

const getLatestAssistantResponse = (entries: any[]) => {
	for (let i = entries.length - 1; i >= 0; i--) {
		const entry = entries[i];
		if (entry?.type !== "message" || entry.message?.role !== "assistant") continue;
		const fullText = extractTextBlocks(entry.message.content).join("\n\n");
		if (fullText.trim()) return { fullText };
	}
	return undefined;
};

const countLines = (text: string) => (text.length === 0 ? 1 : text.split("\n").length);

const truncate = (text: string, limit: number) => {
	const compact = text.replace(/\s+/g, " ").trim();
	if (compact.length <= limit) return compact;
	return `${compact.slice(0, Math.max(0, limit - 1))}…`;
};

const previewText = (text: string, limit = LABEL_PREVIEW_LIMIT) => {
	const firstNonEmpty = text
		.split("\n")
		.map((line) => line.trim())
		.find(Boolean);
	return truncate(firstNonEmpty ?? "(empty)", limit);
};

const sanitizeLang = (lang: string | undefined) => {
	if (!lang) return undefined;
	const clean = lang.replace(/[^a-zA-Z0-9_+.-]/g, "").trim();
	return clean.length > 0 ? clean : undefined;
};

const extractCodeBlocks = (text: string) => {
	const lines = text.split("\n");
	const blocks: Array<{ lang?: string; code: string }> = [];
	for (let i = 0; i < lines.length; i++) {
		const open = lines[i].match(/^(`{3,})(.*)$/);
		if (!open) continue;
		const fence = open[1];
		const lang = sanitizeLang(open[2].trim().split(/\s+/)[0]);
		const codeLines: string[] = [];
		let closed = false;
		for (i = i + 1; i < lines.length; i++) {
			if (lines[i].startsWith(fence)) {
				closed = true;
				break;
			}
			codeLines.push(lines[i]);
		}
		if (closed) blocks.push({ lang, code: codeLines.join("\n") });
	}
	return blocks;
};

const buildTargets = (response: { fullText: string }) => {
	const fullText = response.fullText;
	const targets = [
		{
			id: "full",
			label: "Full response",
			description: `${fullText.length} chars, ${countLines(fullText)} lines`,
			text: fullText,
		},
	];
	for (const [i, block] of extractCodeBlocks(fullText).entries()) {
		targets.push({
			id: `code-${i + 1}`,
			label: `Code block ${i + 1}`,
			description: `${block.lang ?? "plain text"} • ${countLines(block.code)} lines • ${previewText(block.code)}`,
			text: block.code,
		});
	}
	return targets;
};

const createCopyTargetPickerComponent = (tui: any, theme: any, targets: any[], done: (value: string | null) => void) => {
	const items = targets.map((target) => ({ value: target.id, label: target.label, description: target.description }));
	const targetsById = new Map(targets.map((target) => [target.id, target]));
	let currentTarget = targets[0];
	const border = new DynamicBorder((s) => theme.fg("border", s));
	const selectList = new SelectList(items, Math.min(items.length, 10), {
		selectedPrefix: (text) => theme.fg("accent", text),
		selectedText: (text) => theme.fg("accent", text),
		description: (text) => theme.fg("muted", text),
		scrollInfo: (text) => theme.fg("dim", text),
		noMatch: (text) => theme.fg("warning", text),
	}, { minPrimaryColumnWidth: 12, maxPrimaryColumnWidth: 32 });
	const initialSelection = selectList.getSelectedItem?.();
	if (initialSelection) currentTarget = targetsById.get(initialSelection.value) ?? currentTarget;
	const padLine = (line: string, width: number) => line + " ".repeat(Math.max(0, width - visibleWidth(line)));
	const clipLines = (lines: string[], maxLines: number) => {
		if (lines.length <= maxLines) return lines;
		const visibleLines = lines.slice(0, Math.max(1, maxLines - 1));
		visibleLines.push(theme.fg("dim", `… ${lines.length - visibleLines.length} more lines`));
		return visibleLines;
	};
	const renderPreview = (width: number) => {
		const preview = new Text(currentTarget.text, 1, 0);
		return clipLines(preview.render(width), Math.max(8, (tui.terminal?.rows ?? 24) - 10));
	};
	selectList.onSelectionChange = (item) => {
		currentTarget = targetsById.get(item.value) ?? currentTarget;
		tui.requestRender();
	};
	selectList.onSelect = (item) => done(item.value);
	selectList.onCancel = () => done(null);
	return {
		render: (width: number) => {
			const lines: string[] = [];
			lines.push(...border.render(width));
			lines.push(...new Text(theme.fg("accent", theme.bold("Select content to copy")), 1, 0).render(width));
			lines.push(...new Text(theme.fg("dim", "Preview shows the exact clipboard contents (wrapped for display)."), 1, 0).render(width));
			if (width >= 96) {
				const gutter = theme.fg("border", " │ ");
				const gutterWidth = visibleWidth(gutter);
				const listWidth = Math.max(28, Math.min(40, Math.floor((width - gutterWidth) * 0.34)));
				const previewWidth = Math.max(24, width - gutterWidth - listWidth);
				lines.push(padLine(theme.fg("accent", theme.bold("Choices")), listWidth) + gutter + padLine(theme.fg("accent", theme.bold(`Preview — ${currentTarget.label}`)), previewWidth));
				const listLines = selectList.render(listWidth);
				const previewLines = renderPreview(previewWidth);
				for (let i = 0; i < Math.max(listLines.length, previewLines.length); i++) lines.push(padLine(listLines[i] ?? "", listWidth) + gutter + padLine(previewLines[i] ?? "", previewWidth));
			} else {
				lines.push(...new Text(theme.fg("accent", theme.bold("Choices")), 1, 0).render(width));
				lines.push(...selectList.render(width));
				lines.push(...border.render(width));
				lines.push(...new Text(theme.fg("accent", theme.bold(`Preview — ${currentTarget.label}`)), 1, 0).render(width));
				lines.push(...renderPreview(width));
			}
			lines.push(...new Text(theme.fg("dim", "  ↑/↓ to change preview · Enter to copy · Esc to cancel"), 0, 0).render(width));
			lines.push(...border.render(width));
			return lines;
		},
		invalidate: () => { border.invalidate(); selectList.invalidate(); },
		handleInput: (data: any) => { selectList.handleInput(data); tui.requestRender(); },
	};
};

const CLIPBOARD_COMMAND_TIMEOUT_MS = 5000;
const HOTKEYS_CONFIG_PATH = join(homedir(), ".pi", "agent", "config", "copy-response-keybindings.json");

type HotkeyConfig = Record<string, string>;

function loadHotkeyConfig(): HotkeyConfig {
	if (!existsSync(HOTKEYS_CONFIG_PATH)) return {};
	try {
		const parsed = JSON.parse(readFileSync(HOTKEYS_CONFIG_PATH, "utf-8"));
		if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return {};
		const config: HotkeyConfig = {};
		for (const [key, value] of Object.entries(parsed)) {
			if (typeof value === "string" && value.trim()) config[key] = value.trim();
		}
		return config;
	} catch {
		return {};
	}
}

function hotkeyOrDefault(config: HotkeyConfig, name: string, fallback: string): string {
	return config[name] ?? fallback;
}

const canUseOsc52Clipboard = (ctx: any) => ctx.hasUI && Boolean(process.stdout.isTTY) && process.env.TERM !== "dumb";

const emitOsc52Clipboard = (text: string, ctx: any) => {
	if (!canUseOsc52Clipboard(ctx)) return false;
	const encoded = Buffer.from(text, "utf8").toString("base64");
	process.stdout.write(`\x1b]52;c;${encoded}\x07`);
	return true;
};

const runClipboardCommand = (command: string, args: string[], text: string) => {
	execFileSync(command, args, {
		input: text,
		stdio: ["pipe", "ignore", "ignore"],
		timeout: CLIPBOARD_COMMAND_TIMEOUT_MS,
	});
	return true;
};

const tryClipboardCommand = (command: string, args: string[], text: string) => {
	try {
		return runClipboardCommand(command, args, text);
	} catch {
		return false;
	}
};

const copyToX11Clipboard = (text: string) =>
	tryClipboardCommand("xclip", ["-selection", "clipboard"], text) || tryClipboardCommand("xsel", ["--clipboard", "--input"], text);

const copyTextToSystemClipboard = (text: string) => {
	if (process.platform === "darwin") {
		return tryClipboardCommand("pbcopy", [], text);
	}

	if (process.platform === "win32") {
		return tryClipboardCommand("clip", [], text);
	}

	if (process.env.TERMUX_VERSION && tryClipboardCommand("termux-clipboard-set", [], text)) {
		return true;
	}

	if (process.env.WAYLAND_DISPLAY && tryClipboardCommand("wl-copy", [], text)) {
		return true;
	}

	if (process.env.DISPLAY) {
		return copyToX11Clipboard(text);
	}

	return false;
};

const copyTextSafely = (text: string, ctx: any) => {
	const usedOsc52 = emitOsc52Clipboard(text, ctx);
	const usedSystemClipboard = copyTextToSystemClipboard(text);

	if (!usedOsc52 && !usedSystemClipboard) {
		throw new Error("No supported clipboard transport is available in this environment.");
	}

	return { usedOsc52, usedSystemClipboard };
};

const notifyCopySuccess = (ctx: any, copyResult: { usedOsc52: boolean; usedSystemClipboard: boolean }, label: string) => {
	if (copyResult.usedSystemClipboard) {
		ctx.ui.notify(`Copied ${label} to clipboard.`, "info");
		return;
	}
	ctx.ui.notify(`Sent ${label} via the terminal clipboard (OSC 52).`, "info");
};

const getMessageText = (content: unknown) => extractTextBlocks(content).join("\n\n").trim();

const formatTimestamp = (timestamp: string) => {
	const date = new Date(timestamp);
	if (Number.isNaN(date.getTime())) return timestamp;
	return date.toLocaleString([], { dateStyle: "short", timeStyle: "short" });
};

const flattenHistoryEntries = (nodes: any[], depth = 0, out: any[] = []): any[] => {
	for (const node of nodes) {
		const entry = node?.entry;
		const children = node?.children ?? [];

		if (entry?.type === "message" && (entry.message?.role === "user" || entry.message?.role === "assistant")) {
			const fullText = getMessageText(entry.message.content);
			if (fullText) {
				out.push({
					id: entry.id,
					role: entry.message.role,
					depth,
					text: fullText,
					node,
					label: previewText(fullText, 72),
					description: `${countLines(fullText)} lines • ${formatTimestamp(entry.timestamp)}`,
				});
			}
		}

		if (Array.isArray(children) && children.length > 0) {
			flattenHistoryEntries(children, depth + 1, out);
		}
	}

	return out;
};

const findFirstAssistantTextInSubtree = (node: any): string | undefined => {
	for (const child of node?.children ?? []) {
		const entry = child?.entry;
		if (entry?.type === "message" && entry.message?.role === "assistant") {
			const text = getMessageText(entry.message.content);
			if (text) return text;
		}

		const nested = findFirstAssistantTextInSubtree(child);
		if (nested) return nested;
	}

	return undefined;
};

const createHistoryPickerComponent = (tui: any, theme: any, responses: any[], done: (value: string | null) => void) => {
	const responsesById = new Map(responses.map((response) => [response.id, response]));
	let currentResponse = responses[0];

	const border = new DynamicBorder((s) => theme.fg("border", s));
	const selectList = new SelectList(
		responses.map((response, index) => ({
			value: response.id,
			label: `${response.role === "user" ? "Q" : "A"}: ${response.label}`,
			description: `#${index + 1} • ${response.role} • ${response.description}`,
		})),
		Math.min(responses.length, 10),
		{
			selectedPrefix: (text) => theme.fg("accent", text),
			selectedText: (text) => theme.fg("accent", text),
			description: (text) => theme.fg("muted", text),
			scrollInfo: (text) => theme.fg("dim", text),
			noMatch: (text) => theme.fg("warning", text),
		},
		{
			minPrimaryColumnWidth: 12,
			maxPrimaryColumnWidth: 44,
		},
	);

	const initialIndex = Math.max(0, responses.length - 1);
	selectList.setSelectedIndex(initialIndex);
	currentResponse = responses[initialIndex] ?? currentResponse;

	const fitLine = (line: string, width: number) => truncateToWidth(line, width, "");
	const padLine = (line: string, width: number) => fitLine(line, width) + " ".repeat(Math.max(0, width - visibleWidth(line)));
	const clipLines = (lines: string[], maxLines: number) => {
		if (lines.length <= maxLines) return lines;
		const visibleLines = lines.slice(0, Math.max(1, maxLines - 1));
		const hiddenCount = lines.length - visibleLines.length;
		visibleLines.push(theme.fg("dim", `… ${hiddenCount} more line${hiddenCount === 1 ? "" : "s"}`));
		return visibleLines;
	};
	const renderPreview = (width: number) => {
		const preview = new Text(currentResponse.text, 1, 0);
		const maxLines = Math.max(8, (tui.terminal?.rows ?? 24) - 10);
		return clipLines(preview.render(width).map((line) => fitLine(line, width)), maxLines);
	};

	selectList.onSelectionChange = (item) => {
		currentResponse = responsesById.get(item.value) ?? currentResponse;
		tui.requestRender();
	};
	selectList.onSelect = (item) => done(item.value);
	selectList.onCancel = () => done(null);

	return {
		render: (width: number) => {
			const lines: string[] = [];
			lines.push(...border.render(width));
			lines.push(fitLine(new Text(theme.fg("accent", theme.bold("Select a past message")), 1, 0).render(width)[0] ?? "", width));
			lines.push(fitLine(new Text(theme.fg("dim", "Pick a question or answer from the session tree, then copy the response or a code block."), 1, 0).render(width)[0] ?? "", width));

			if (width >= 96) {
				const gutter = theme.fg("border", " │ ");
				const gutterWidth = visibleWidth(gutter);
				const listWidth = Math.max(28, Math.min(44, Math.floor((width - gutterWidth) * 0.38)));
				const previewWidth = Math.max(24, width - gutterWidth - listWidth);
				lines.push(
					fitLine(
						padLine(theme.fg("accent", theme.bold("History")), listWidth) +
							gutter +
							padLine(theme.fg("accent", theme.bold(`Preview — ${currentResponse.role === "user" ? "Question" : "Answer"}`)), previewWidth),
						width,
					),
				);
				const listLines = selectList.render(listWidth).map((line) => fitLine(line, listWidth));
				const previewLines = renderPreview(previewWidth);
				const bodyHeight = Math.max(listLines.length, previewLines.length);
				for (let i = 0; i < bodyHeight; i++) {
					lines.push(padLine(listLines[i] ?? "", listWidth) + gutter + padLine(previewLines[i] ?? "", previewWidth));
				}
			} else {
				lines.push(fitLine(new Text(theme.fg("accent", theme.bold("History")), 1, 0).render(width)[0] ?? "", width));
				lines.push(...selectList.render(width).map((line) => fitLine(line, width)));
				lines.push(...border.render(width).map((line) => fitLine(line, width)));
				lines.push(fitLine(new Text(theme.fg("accent", theme.bold(`Preview — ${currentResponse.role === "user" ? "Question" : "Answer"}`)), 1, 0).render(width)[0] ?? "", width));
				lines.push(...renderPreview(width).map((line) => fitLine(line, width)));
			}

			lines.push(fitLine(new Text(theme.fg("dim", "  ↑/↓ to change selection · Enter to continue · Esc to cancel"), 0, 0).render(width)[0] ?? "", width));
			lines.push(...border.render(width).map((line) => fitLine(line, width)));
			return lines;
		},
		invalidate: () => {
			border.invalidate();
			selectList.invalidate();
		},
		handleInput: (data: any) => {
			selectList.handleInput(data);
			tui.requestRender();
		},
	};
};
const copyText = async (ctx: any, text: string, label: string) => {
	try {
		const result = copyTextSafely(text, ctx);
		notifyCopySuccess(ctx, result, label);
	} catch (error) {
		ctx.ui.notify(`Failed to copy ${label}: ${error instanceof Error ? error.message : String(error)}`, "error");
	}
};

const pickResponseFromHistory = async (ctx: any) => {
	const tree = ctx.sessionManager.getTree();
	const responses = flattenHistoryEntries(tree).filter((response) => response.text.trim().length > 0);

	if (responses.length === 0) {
		ctx.ui.notify("No messages with text were found in this session.", "warning");
		return;
	}

	const selectedId = await ctx.ui.custom<string | null>((tui: any, theme: any, _keybindings: any, done: any) =>
		createHistoryPickerComponent(tui, theme, responses, done),
	);

	if (!selectedId) {
		ctx.ui.notify("Copy cancelled.", "info");
		return;
	}

	const selected = responses.find((response) => response.id === selectedId);
	if (!selected) {
		ctx.ui.notify("Selected message not found.", "error");
		return;
	}

	const selectedText = selected.role === "assistant" ? selected.text : findFirstAssistantTextInSubtree(selected.node);
	if (!selectedText) {
		ctx.ui.notify("No assistant answer found for that question.", "warning");
		return;
	}

	const targets = buildTargets({ fullText: selectedText });
	if (targets.length === 0) {
		ctx.ui.notify("No copyable content found in the selected response.", "warning");
		return;
	}

	if (targets.length === 1 || !ctx.hasUI) {
		await copyText(ctx, targets[0].text, selected.role === "user" ? "answer" : "response");
		return;
	}

	const selectedTargetId = await ctx.ui.custom<string | null>((tui: any, theme: any, _keybindings: any, done: any) =>
		createCopyTargetPickerComponent(tui, theme, targets, done),
	);

	if (!selectedTargetId) {
		ctx.ui.notify("Copy cancelled.", "info");
		return;
	}

	const selectedTarget = targets.find((target) => target.id === selectedTargetId);
	if (!selectedTarget) {
		ctx.ui.notify("Copy target not found.", "error");
		return;
	}

	await copyText(ctx, selectedTarget.text, selectedTarget.id === "full" ? "response" : selectedTarget.label.toLowerCase());
};

const copyLatestResponse = async (ctx: any) => {
	const branch = ctx.sessionManager.getBranch();
	for (let i = branch.length - 1; i >= 0; i--) {
		const entry = branch[i];
		if (entry?.type !== "message" || entry.message?.role !== "assistant") continue;
		const fullText = getMessageText(entry.message.content);
		if (!fullText) continue;
		await copyText(ctx, fullText, "latest response");
		return;
	}

	ctx.ui.notify("No assistant answer with text found.", "warning");
};

const runCopyHistory = async (ctx: any) => {
	if (!ctx.hasUI) {
		await copyLatestResponse(ctx);
		return;
	}

	await pickResponseFromHistory(ctx);
};

const runCopyResponse = async (ctx: any) => {
	const response = getLatestAssistantResponse(ctx.sessionManager.getBranch());
	if (!response) {
		ctx.ui.notify("No assistant response with text found.", "warning");
		return;
	}

	const targets = buildTargets(response);
	if (targets.length === 0) {
		ctx.ui.notify("No copyable content found in the latest response.", "warning");
		return;
	}

	if (targets.length === 1 || !ctx.hasUI) {
		await copyText(ctx, targets[0].text, "response");
		return;
	}

	const selectedTargetId = await ctx.ui.custom<string | null>((tui: any, theme: any, _keybindings: any, done: any) =>
		createCopyTargetPickerComponent(tui, theme, targets, done),
	);

	if (!selectedTargetId) {
		ctx.ui.notify("Copy cancelled.", "info");
		return;
	}

	const selectedTarget = targets.find((target) => target.id === selectedTargetId);
	if (!selectedTarget) {
		ctx.ui.notify("Copy target not found.", "error");
		return;
	}

	await copyText(ctx, selectedTarget.text, selectedTarget.id === "full" ? "response" : selectedTarget.label.toLowerCase());
};

export default function (pi: ExtensionAPI) {
	const hotkeys = loadHotkeyConfig();

	pi.registerShortcut(hotkeyOrDefault(hotkeys, "copy-history", Key.altShift("c")), {
		description: "Copy a past answer or code block.",
		handler: async (ctx) => {
			await runCopyHistory(ctx);
		},
	});

	pi.registerShortcut(hotkeyOrDefault(hotkeys, "copy-response", Key.alt("c")), {
		description: "Copy the latest assistant response or code block.",
		handler: async (ctx) => {
			await runCopyResponse(ctx);
		},
	});

	pi.registerCommand("copy-history", {
		description: "Browse messages in the session tree and copy a past answer or code block.",
		handler: async (_args, ctx) => {
			await runCopyHistory(ctx);
		},
	});

	pi.registerCommand("copy-history-response", {
		description: "Alias for /copy-history.",
		handler: async (_args, ctx) => {
			await runCopyHistory(ctx);
		},
	});
}

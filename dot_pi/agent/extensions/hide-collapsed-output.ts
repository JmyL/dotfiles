/**
 * Hide Collapsed Tool Output
 *
 * When tool output is collapsed (default state), render nothing so only the
 * call header line is visible. Ctrl+O expands to the original full output.
 */

import type {
	ExtensionAPI,
	ToolRenderers,
} from "@earendil-works/pi-coding-agent";
import { Container } from "@earendil-works/pi-tui";

export default function (pi: ExtensionAPI) {
	pi.registerToolRenderer((toolName, next) => {
		const base = next();
		// Only override tools that already define a result renderer;
		// leave tools without renderers on pi's built-in fallback.
		if (!base?.renderResult) {
			return base;
		}
		const originalRenderResult = base.renderResult;
		return {
			...base,
			renderResult(result, options, theme, context) {
				if (!options.expanded) {
					return new Container();
				}
				return originalRenderResult(result, options, theme, context);
			},
		};
	});
}

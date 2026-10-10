import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { Component } from "@earendil-works/pi-tui";

// Pi has no setting to stop terminal-title writes: updateTerminalTitle() writes
// OSC 0 on init, reload, and every session_info_changed. Extensions get no
// output hook, but the TUI passes its renderer into ctx.ui.custom factories, so
// patch terminal.setTitle once, set a short title, and drop the overlay.
export default function (pi: ExtensionAPI) {
	pi.on("session_start", async (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		const noop: Component = {
			render: () => [],
			invalidate: () => {},
			handleInput: () => {},
		};
		await ctx.ui.custom<undefined>(
			(tui, _theme, _keybindings, done) => {
				const writeTitle = tui.terminal.setTitle.bind(tui.terminal);
				tui.terminal.setTitle = () => {};
				writeTitle("π agent");
				queueMicrotask(() => done(undefined));
				return noop;
			},
			{ overlay: true, overlayOptions: { anchor: "top-left", width: 1, maxHeight: 1 } },
		);
	});
}

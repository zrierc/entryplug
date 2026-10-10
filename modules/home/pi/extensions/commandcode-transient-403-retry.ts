import { appendFileSync } from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Command Code's gateway intermittently returns 403 permission_error for the
// Muse Spark family: same key, same request, some fraction of calls fail while
// identical calls succeed. pi only auto-retries allowlisted error tokens, so a
// plain 403 ends the turn. Mark only that transient shape retryable; real
// entitlement 403s (MODEL_NOT_IN_PLAN, upgrade_required) must keep surfacing.
const TRANSIENT_403 = /403[\s\S]{0,200}"type"\s*:\s*"permission_error"/i;
const REAL_403 = /MODEL_NOT_IN_PLAN|upgrade_required|not in plan/i;

export default function (pi: ExtensionAPI) {
	pi.on("message_end", async (event) => {
		const m = event.message;
		if (m.role !== "assistant" || m.stopReason !== "error") return;
		if (m.provider !== "commandcode") return;
		const err = m.errorMessage ?? "";
		if (!TRANSIENT_403.test(err) || REAL_403.test(err)) return;
		if (process.env.CC_403_DEBUG) {
			appendFileSync("/tmp/cc-403-retry.log", `${new Date().toISOString()} ${m.model}\n`);
		}
		return {
			message: {
				...m,
				errorMessage: `${err} (transient gateway error - provider returned error, retrying)`,
			},
		};
	});
}

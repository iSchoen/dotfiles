#!/usr/bin/env bun
/**
 * clamshell-suspend.ts
 * Listens for Hyprland monitor disconnect events.
 * If the lid is closed and no external monitors remain, suspends the system.
 */

import { $ } from "bun";

const LID_STATE_PATH = "/proc/acpi/button/lid/LID0/state";
const INTERNAL_DISPLAY = "eDP-2";

function getSocketPath(): string {
	const sig = process.env.HYPRLAND_INSTANCE_SIGNATURE;
	const runtimeDir = process.env.XDG_RUNTIME_DIR ?? `/run/user/${process.getuid()}`;
	return `${runtimeDir}/hypr/${sig}/.socket2.sock`;
}

async function isLidClosed(): Promise<boolean> {
	try {
		const content = await Bun.file(LID_STATE_PATH).text();
		return content.includes("closed");
	} catch {
		return false;
	}
}

async function hasExternalMonitors(): Promise<boolean> {
	try {
		const monitors = await $`hyprctl monitors -j`.json<Array<{ name: string }>>();
		return monitors.some((m) => m.name !== INTERNAL_DISPLAY);
	} catch {
		return true; // Fail safe: assume external monitor exists on error
	}
}

async function main(): Promise<void> {
	const socketPath = getSocketPath();
	let buf = "";

	await Bun.connect({
		unix: socketPath,
		socket: {
			data(_socket, data) {
				buf += data.toString();
				const lines = buf.split("\n");
				buf = lines.pop() ?? "";

				for (const line of lines) {
					if (line.trim().startsWith("monitorremoved")) {
						setTimeout(async () => {
							if ((await isLidClosed()) && !(await hasExternalMonitors())) {
								await $`systemctl suspend`;
							}
						}, 1000);
					}
				}
			},
			error(_socket, error) {
				console.error("Socket error:", error);
				process.exit(1);
			},
			close() {
				console.error("Socket closed");
				process.exit(1);
			},
		},
	});
}

main().catch(console.error);

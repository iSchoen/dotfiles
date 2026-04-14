#!/usr/bin/env bun
/**
 * clamshell.ts
 * Manages internal display state for clamshell mode.
 * Usage: bun clamshell.ts [open|close|check]
 */

import { $ } from "bun";

const INTERNAL_DISPLAY = "eDP-2";
const ICON_LAPTOP = "computer-laptop";
const ICON_MONITOR = "video-display";

async function notify(title: string, body: string, icon: string): Promise<void> {
	await $`notify-send -u low -i ${icon} ${title} ${body}`;
}

async function modeClose(): Promise<void> {
	const output = await $`hyprctl monitors all`.text();
	const monitorCount = (output.match(/^Monitor /gm) ?? []).length;
	if (monitorCount > 1) {
		await $`hyprctl keyword monitor ${INTERNAL_DISPLAY}, disable`;
	}
}

async function modeOpen(): Promise<void> {
	await $`hyprctl keyword monitor ${INTERNAL_DISPLAY}, preferred, auto, 2`;
}

async function main(): Promise<void> {
	const mode = process.argv[2];

	switch (mode) {
		case "close":
			await modeClose();
			await notify("Clamshell Mode", "External monitor active. Laptop screen disabled.", ICON_MONITOR);
			break;
		case "open":
			await modeOpen();
			await notify("Laptop Mode", "Laptop screen enabled.", ICON_LAPTOP);
			break;
		case "check": {
			const lidState = await Bun.file("/proc/acpi/button/lid/LID0/state").text();
			if (lidState.includes("open")) {
				await modeOpen();
			} else {
				await modeClose();
			}
			break;
		}
		default:
			console.error(`Usage: ${process.argv[1]} [open|close|check]`);
			process.exit(1);
	}
}

main().catch(console.error);

// Right Ctrl app menu. rcmd writes $XDG_RUNTIME_DIR/rcmd-menu.json for the
// pressed letter and opens this command; choices are handed back to rcmd,
// which launches or focuses the window. Enter does the obvious thing, Ctrl+B
// opens the remaining actions (specific window, new window, desktop actions).
import { spawn } from "node:child_process";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
	Action,
	ActionPanel,
	Icon,
	List,
	closeMainWindow,
	showToast,
	Toast,
} from "@vicinae/api";

type DesktopAction = { id: string; name: string };
type AppEntry = {
	id: string;
	name: string;
	icon: string | null;
	newWindow: boolean;
	actions: DesktopAction[];
};
type RunningApp = AppEntry & {
	launchable: boolean;
	windows: { id: string; title: string }[];
};
type InstalledApp = AppEntry & { running: boolean };
type Menu = {
	letter: string;
	rcmd: string;
	running: RunningApp[];
	apps: InstalledApp[];
};

function readMenu(): Menu | Error {
	try {
		const dir = process.env.XDG_RUNTIME_DIR ?? `/run/user/${process.getuid?.()}`;
		return JSON.parse(readFileSync(join(dir, "rcmd-menu.json"), "utf8"));
	} catch (error) {
		return error instanceof Error ? error : new Error(String(error));
	}
}

async function run(menu: Menu, args: string[]) {
	if (!menu.rcmd) {
		await showToast({ style: Toast.Style.Failure, title: "rcmd path missing" });
		return;
	}
	await closeMainWindow();
	const child = spawn(menu.rcmd, args, { detached: true, stdio: "ignore" });
	child.unref();
}

const appIcon = (app: AppEntry) => app.icon ?? Icon.AppWindow;

function DesktopActions({ menu, app }: { menu: Menu; app: AppEntry }) {
	return (
		<>
			{app.actions.map((action) => (
				<Action
					key={action.id}
					title={action.name}
					icon={Icon.Bolt}
					onAction={() => run(menu, ["--open", app.id, "--action", action.id])}
				/>
			))}
		</>
	);
}

function RunningItem({ menu, app }: { menu: Menu; app: RunningApp }) {
	const [latest, ...others] = app.windows;
	const count = app.windows.length;
	return (
		<List.Item
			title={app.name}
			subtitle={latest.title !== app.name ? latest.title : undefined}
			icon={appIcon(app)}
			keywords={app.windows.map((w) => w.title)}
			accessories={[{ text: count === 1 ? "1 window" : `${count} windows` }]}
			actions={
				<ActionPanel title={app.name}>
					<Action
						title="Focus"
						icon={Icon.Eye}
						onAction={() => run(menu, ["--focus-window", latest.id])}
					/>
					{app.launchable && (
						<Action
							title="New Window"
							icon={Icon.Plus}
							onAction={() => run(menu, ["--open", app.id])}
						/>
					)}
					{others.length > 0 && (
						<ActionPanel.Section title="Windows">
							{others.map((w) => (
								<Action
									key={w.id}
									title={w.title}
									icon={Icon.AppWindow}
									onAction={() => run(menu, ["--focus-window", w.id])}
								/>
							))}
						</ActionPanel.Section>
					)}
					{app.actions.length > 0 && (
						<ActionPanel.Section title="Actions">
							<DesktopActions menu={menu} app={app} />
						</ActionPanel.Section>
					)}
				</ActionPanel>
			}
		/>
	);
}

function InstalledItem({ menu, app }: { menu: Menu; app: InstalledApp }) {
	return (
		<List.Item
			title={app.name}
			icon={appIcon(app)}
			accessories={app.running ? [{ text: "running" }] : undefined}
			actions={
				<ActionPanel title={app.name}>
					<Action
						title={app.running ? "Open New Instance" : "Launch"}
						icon={Icon.Plus}
						onAction={() => run(menu, ["--open", app.id])}
					/>
					{app.actions.length > 0 && (
						<ActionPanel.Section title="Actions">
							<DesktopActions menu={menu} app={app} />
						</ActionPanel.Section>
					)}
				</ActionPanel>
			}
		/>
	);
}

export default function Command() {
	const menu = readMenu();
	if (menu instanceof Error) {
		return (
			<List>
				<List.EmptyView title="rcmd menu data missing" description={menu.message} />
			</List>
		);
	}
	const letter = menu.letter.toUpperCase();
	return (
		<List
			navigationTitle={`${letter} — apps`}
			searchBarPlaceholder={`Apps starting with ${letter} — Ctrl+B for actions`}
		>
			<List.EmptyView title={`No apps starting with ${letter}`} />
			<List.Section title="Running">
				{menu.running.map((app) => (
					<RunningItem key={`r:${app.id}`} menu={menu} app={app} />
				))}
			</List.Section>
			<List.Section title="Launch">
				{menu.apps.map((app) => (
					<InstalledItem key={`l:${app.id}`} menu={menu} app={app} />
				))}
			</List.Section>
		</List>
	);
}

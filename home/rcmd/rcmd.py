#!/usr/bin/env python3
"""Cycle matching application windows by initial, or choose an installed app."""
import argparse
import fcntl
import glob
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import unicodedata

import gi
gi.require_version("Gio", "2.0")
gi.require_version("GioUnix", "2.0")
from gi.repository import Gio, GioUnix


def initial(text):
    text = unicodedata.normalize('NFKD', text).casefold().strip()
    return text[:1]


def catalog():
    apps = []
    for info in Gio.AppInfo.get_all():
        if not isinstance(info, GioUnix.DesktopAppInfo):
            continue
        desktop_id = info.get_id() or ''
        name = info.get_display_name() or info.get_name()
        aliases = {desktop_id.removesuffix('.desktop').casefold()}
        wmclass = info.get_startup_wm_class()
        if wmclass:
            aliases.add(wmclass.casefold())
        executable = info.get_executable() or ''
        apps.append({'id': desktop_id, 'name': name, 'aliases': aliases,
                     'executable': Path(executable).name.casefold(),
                     'visible': info.should_show(), 'info': info})
    return sorted(apps, key=lambda a: (a['name'].casefold(), a['id']))


def app_for_window(window, apps):
    app_id = (window.get('app_id') or '').casefold()
    exact = [a for a in apps if app_id in a['aliases']]
    if exact:
        return next((a for a in exact if a['visible']), exact[0])
    executable = [a for a in apps if app_id and app_id == a['executable']]
    if executable:
        return next((a for a in executable if a['visible']), executable[0])
    # Unregistered windows can still cycle under the final app-id component.
    return {'id': app_id, 'name': app_id.rsplit('.', 1)[-1]}


def command(args):
    return subprocess.run(args, check=True, capture_output=True, text=True).stdout


class Desktop:
    def __init__(self):
        names = os.environ.get('XDG_CURRENT_DESKTOP', '').casefold().split(':')
        if 'niri' in names:
            self.kind = 'niri'
            if not Path(os.environ.get('NIRI_SOCKET', '/nonexistent')).is_socket():
                sockets = glob.glob(os.environ['XDG_RUNTIME_DIR'] + '/niri.wayland-*.sock')
                if len(sockets) != 1:
                    raise RuntimeError('Cannot identify the active Niri socket')
                os.environ['NIRI_SOCKET'] = sockets[0]
        elif 'mango' in names:
            self.kind = 'mango'
        elif 'umbriel' in names:
            self.kind = 'umbriel'
        else:
            raise RuntimeError('Right Ctrl app switching requires Niri, Umbriel, or Mango')

    def windows(self):
        if self.kind == 'mango':
            return [dict(w, app_id=w.get('appid', '')) for w in json.loads(command(['mmsg', 'get', 'all-clients']))['clients']]
        args = ['niri', 'msg', '--json', 'windows'] if self.kind == 'niri' else ['umbriel', 'windows', '--json']
        return json.loads(command(args))

    def focus(self, window):
        if self.kind == 'mango':
            command(['mmsg', 'dispatch', 'focusid', 'client,' + str(window['id'])])
        elif self.kind == 'niri':
            command(['niri', 'msg', 'action', 'focus-window', '--id', str(window['id'])])
            command(['niri', 'msg', 'action', 'center-column'])
        else:
            command(['umbriel', 'msg', 'window-focus:' + str(window['id'])])
            command(['umbriel', 'msg', 'column-center'])


def timestamp(window):
    stamp = window.get('focus_timestamp') or {}
    return stamp.get('secs', 0), stamp.get('nanos', 0), window['id']


def focused(window):
    return window.get('is_focused', window.get('active', False))


def running_groups(windows, apps, letter):
    groups = {}
    for window in windows:
        app = app_for_window(window, apps)
        if initial(app['name']) == letter:
            group = groups.setdefault(app['id'], {'app': app, 'windows': []})
            group['windows'].append(window)
    return sorted(groups.values(), key=lambda g: (g['app']['name'].casefold(), g['app']['id']))


def cycle(groups, reverse=False):
    # Keep app-name order and stable window IDs. Focus timestamps change after
    # every press; sorting the cycle by recency would skip windows or bounce.
    windows = [window for group in groups
               for window in sorted(group['windows'], key=lambda w: w['id'])]
    current = next((i for i, window in enumerate(windows) if focused(window)), None)
    if current is None:
        return max(windows, key=timestamp)
    return windows[(current + (-1 if reverse else 1)) % len(windows)]


def choose(apps, running, letter):
    # A single chooser across letters prevents repeated chords stacking menus.
    lock_path = Path(os.environ['XDG_RUNTIME_DIR']) / 'rcmd-chooser.lock'
    with lock_path.open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return None
        choices = {}
        matching_apps = [app for app in apps
                         if app['visible'] and initial(app['name']) == letter]
        for app in sorted(matching_apps,
                          key=lambda app: (app['id'] not in running,
                                           app['name'].casefold(), app['id'])):
            window_count = len(running.get(app['id'], ()))
            state = '●' if window_count else '○'
            count = f' — {window_count} window' + ('s' if window_count != 1 else '') if window_count else ''
            label = f"{state} {app['name'].replace('\n', ' ')}{count}"
            # Desktop names are normally unique. Retain both apps if two
            # entries share a name, while keeping the useful state first.
            if label in choices:
                label += f" ({app['id'].removesuffix('.desktop')})"
            choices[label] = app
        result = subprocess.run(
            ['vicinae', 'dmenu', '--format', 'data', '--no-quick-look',
             '--navigation-title', f'{letter.upper()} — choose an app',
             '--placeholder', '● running  •  ○ not running' if choices else f'No installed apps starting with {letter.upper()}',
             '--section-title', 'Installed apps ({count})'],
            input='\n'.join(choices) + ('\n' if choices else ''), text=True, capture_output=True)
        if result.returncode != 0:
            return None  # Esc/cancel does not launch anything.
        return choices.get(result.stdout.rstrip('\n'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('letter', choices=list('abcdefghijklmnopqrstuvwxyz'))
    parser.add_argument('--reverse', action='store_true')
    parser.add_argument('--choose', action='store_true', help='Always show the installed-app chooser')
    parser.add_argument('--list', action='store_true', help='Print installed matches without opening the chooser')
    args = parser.parse_args()
    apps = catalog()
    if args.list:
        print(json.dumps([{'id': a['id'], 'name': a['name']} for a in apps if a['visible'] and initial(a['name']) == args.letter], ensure_ascii=False))
        return
    # One worker at a time for a letter, including while its chooser is open.
    with (Path(os.environ['XDG_RUNTIME_DIR']) / f'rcmd-{args.letter}.lock').open('w') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        desktop = Desktop()
        groups = running_groups(desktop.windows(), apps, args.letter)
        if groups and not args.choose:
            desktop.focus(cycle(groups, args.reverse))
            return
        running = {group['app']['id']: group['windows'] for group in groups}
        app = choose(apps, running, args.letter)
        if app is None:
            return
        # Recheck after the chooser: the app may have opened in the meantime.
        matching = [w for w in desktop.windows() if app_for_window(w, apps)['id'] == app['id']]
        if not matching:
            # A separate scope prevents xremap restarts from killing this app.
            subprocess.Popen(
                ['systemd-run', '--user', '--scope', '--quiet', '--',
                 os.environ['RCMD_GIO'], 'launch', app['info'].get_filename()],
                stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                stderr=None, start_new_session=True)
        for _ in range(80):
            matching = [w for w in desktop.windows() if app_for_window(w, apps)['id'] == app['id']]
            if matching:
                desktop.focus(max(matching, key=timestamp))
                return
            time.sleep(.1)


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError) as error:
        print(f'rcmd: {error}', file=sys.stderr)
        sys.exit(1)

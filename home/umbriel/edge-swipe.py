"""Edge swipes on touchpads, which libinput does not report.

Reads the raw multitouch stream of every touchpad next to libinput (no grab,
so libinput still sees the same touches) and runs a command when a finger
lands in a strip along one edge and moves inward together with a second
finger (two-finger swipes only; one finger never fires). One trigger per touch
sequence: nothing more fires until every finger has lifted. The command runs
mid-swipe; Umbriel drops the rest of a two-finger scroll once the overview
opens or closes under it (patches/umbriel-overview-scroll-handoff.patch).

Usage: edge-swipe [--debug] EDGE=COMMAND...   (EDGE: top, bottom, left, right)
"""

import argparse
import asyncio
import os
import shlex
import subprocess
import time

import evdev
from evdev import ecodes

# Width of the edge strip, as a fraction of the pad's size along that axis.
EDGE_FRACTION = 0.08
# Inward travel that fires, in mm, and the time it must happen in.
TRAVEL_MM = 12.0
MAX_TIME_S = 0.6
# Travel along the edge may be at most this fraction of the inward travel.
MAX_SIDEWAYS = 0.6
# Fingers an edge swipe needs. Only one of them must start in the edge
# strip; the other must move inward too, at least PARTNER_FRACTION of
# TRAVEL_MM, so a thumb resting on the pad does not count. More fingers is
# another gesture (a 3-finger drag, a 4-finger swipe or pinch).
FINGERS = 2
PARTNER_FRACTION = 0.5
RESCAN_S = 3.0

DEBUG = False


def log(message):
    print(message, flush=True)


class Pad:
    def __init__(self, device, commands):
        self.device = device
        self.commands = commands
        absinfo = dict(device.capabilities(absinfo=True)[ecodes.EV_ABS])
        self.x = absinfo[ecodes.ABS_MT_POSITION_X]
        self.y = absinfo[ecodes.ABS_MT_POSITION_Y]
        self.slot = 0
        self.touches = {}  # slot -> touch state
        self.fired = False
        self.max_fingers = 0

    def mm(self, axis, units):
        return units / axis.resolution if axis.resolution else units / 40.0

    def edge_of(self, x, y):
        fx = (x - self.x.min) / (self.x.max - self.x.min)
        fy = (y - self.y.min) / (self.y.max - self.y.min)
        if fy < EDGE_FRACTION:
            return "top"
        if fy > 1 - EDGE_FRACTION:
            return "bottom"
        if fx < EDGE_FRACTION:
            return "left"
        if fx > 1 - EDGE_FRACTION:
            return "right"
        return None

    def travel(self, t, edge):
        """(inward, sideways) travel of touch t since it landed, in mm."""
        x0, y0, _ = t["start"]
        dx = self.mm(self.x, t["x"] - x0)
        dy = self.mm(self.y, t["y"] - y0)
        return {
            "top": (dy, dx),
            "bottom": (-dy, dx),
            "left": (dx, dy),
            "right": (-dx, dy),
        }[edge]

    def touch(self):
        return self.touches.setdefault(self.slot, {"id": -1})

    def handle(self, event):
        if event.type == ecodes.EV_ABS:
            if event.code == ecodes.ABS_MT_SLOT:
                self.slot = event.value
            elif event.code == ecodes.ABS_MT_TRACKING_ID:
                if event.value < 0:
                    self.touches.pop(self.slot, None)
                else:
                    # evdev drops values equal to the slot's last ones, so a
                    # new touch keeps its slot's old position until it moves.
                    old = self.touches.get(self.slot, {})
                    self.touches[self.slot] = {
                        "id": event.value,
                        "new": True,
                        **{k: old[k] for k in ("x", "y") if k in old},
                    }
            elif event.code == ecodes.ABS_MT_POSITION_X:
                self.touch()["x"] = event.value
            elif event.code == ecodes.ABS_MT_POSITION_Y:
                self.touch()["y"] = event.value
        elif event.type == ecodes.EV_SYN and event.code == ecodes.SYN_REPORT:
            self.frame()

    def frame(self):
        active = [t for t in self.touches.values() if t.get("id", -1) >= 0]
        if not active:
            self.fired = False
            self.max_fingers = 0
            return
        self.max_fingers = max(self.max_fingers, len(active))
        now = time.monotonic()
        for t in active:
            if "x" not in t or "y" not in t:
                continue
            if t.pop("new", False):
                t["start"] = (t["x"], t["y"], now)
                t["edge"] = self.edge_of(t["x"], t["y"])
                if DEBUG:
                    log(f"touch {t['id']} at {t['x']},{t['y']} edge={t['edge']}")
            edge = t.get("edge")
            if self.fired or edge is None or edge not in self.commands:
                continue
            if self.max_fingers > FINGERS:
                continue
            if now - t["start"][2] > MAX_TIME_S:
                t["edge"] = None  # Too slow: a rest on the edge, not a swipe.
                continue
            if len(active) != FINGERS:
                continue
            inward, sideways = self.travel(t, edge)
            partners = [p for p in active if p is not t]
            if (
                inward >= TRAVEL_MM
                and abs(sideways) <= MAX_SIDEWAYS * inward
                and all(
                    "start" in p and self.travel(p, edge)[0] >= PARTNER_FRACTION * TRAVEL_MM
                    for p in partners
                )
            ):
                self.fired = True
                log(f"{edge} edge swipe, {self.max_fingers} finger(s): {self.commands[edge]}")
                subprocess.Popen(shlex.split(self.commands[edge]), start_new_session=True)


def is_touchpad(device):
    caps = device.capabilities(absinfo=False)
    abs_codes = caps.get(ecodes.EV_ABS, [])
    keys = caps.get(ecodes.EV_KEY, [])
    return (
        ecodes.ABS_MT_POSITION_X in abs_codes
        and ecodes.ABS_MT_TRACKING_ID in abs_codes
        and ecodes.BTN_TOOL_FINGER in keys
        and ecodes.INPUT_PROP_DIRECT not in device.input_props()
    )


async def read_pad(pad, open_paths):
    try:
        async for event in pad.device.async_read_loop():
            pad.handle(event)
    except OSError:
        pass
    finally:
        log(f"lost {pad.device.name} ({pad.device.path})")
        open_paths.discard(pad.device.path)
        try:
            pad.device.close()
        except OSError:
            pass


async def main(commands):
    open_paths = set()
    while True:
        for path in evdev.list_devices():
            if path in open_paths:
                continue
            try:
                device = evdev.InputDevice(path)
            except OSError:
                continue
            if not is_touchpad(device):
                device.close()
                continue
            open_paths.add(path)
            log(f"watching {device.name} ({path})")
            asyncio.ensure_future(read_pad(Pad(device, commands), open_paths))
        await asyncio.sleep(RESCAN_S)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Run commands on touchpad edge swipes.")
    parser.add_argument("--debug", action="store_true", help="log every touch start")
    parser.add_argument("bindings", nargs="+", metavar="EDGE=COMMAND")
    args = parser.parse_args()
    DEBUG = args.debug or bool(os.environ.get("EDGE_SWIPE_DEBUG"))
    bound = {}
    for binding in args.bindings:
        edge, _, command = binding.partition("=")
        if edge not in ("top", "bottom", "left", "right") or not command:
            parser.error(f"bad binding: {binding}")
        bound[edge] = command
    asyncio.run(main(bound))

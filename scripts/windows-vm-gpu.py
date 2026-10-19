"""Synchronize only the RTX 4090 PCI assignments of the existing domain."""

import datetime
import pathlib
import subprocess
import sys
import xml.etree.ElementTree as ET

ET.register_namespace("qemu", "http://libvirt.org/schemas/domain/qemu/1.0")


def virsh(*args):
    return subprocess.check_output(
        ["virsh", "--connect", "qemu:///system", *args], text=True
    )


def reconcile(xml, enabled):
    root = ET.fromstring(xml)
    devices = root.find("devices")
    assigned = {}
    for device in devices.findall("hostdev"):
        address = device.find("source/address")
        if device.get("type") != "pci" or address is None:
            continue
        pci = tuple(int(address.get(key, "0"), 0) for key in ("domain", "bus", "slot", "function"))
        if pci in ((0, 1, 0, 0), (0, 1, 0, 1)):
            if pci[3] in assigned:
                raise RuntimeError("Duplicate NVIDIA assignment; inspect domain manually")
            assigned[pci[3]] = device
    if set(assigned) == ({0, 1} if enabled else set()):
        return None
    for device in assigned.values():
        devices.remove(device)
    if enabled:
        for function in (0, 1):
            device = ET.SubElement(devices, "hostdev", mode="subsystem", type="pci", managed="no")
            source = ET.SubElement(device, "source")
            ET.SubElement(source, "address", domain="0x0000", bus="0x01", slot="0x00", function=hex(function))
            ET.SubElement(device, "address", type="pci", domain="0x0000", bus=hex(5 + function), slot="0x00", function="0x0")
    return ET.tostring(root, encoding="unicode")


def main():
    if sys.argv[1:] not in (["on"], ["off"]):
        raise SystemExit("Usage: windows-vm-gpu.py on|off")
    if "windows11" not in virsh("list", "--all", "--name").splitlines():
        return
    original = virsh("dumpxml", "windows11", "--inactive")
    updated = reconcile(original, sys.argv[1] == "on")
    if updated is None:
        return
    if virsh("domstate", "windows11").strip() != "shut off":
        raise SystemExit("Shut down windows11 before changing GPU passthrough")
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    backup = pathlib.Path("/var/lib/windows-vm-recovery/gpu-toggle") / stamp
    backup.mkdir(parents=True, mode=0o700)
    (backup / "windows11.xml").write_text(original)
    target = backup / "windows11-updated.xml"
    target.write_text(updated)
    virsh("define", "--validate", str(target))
    if reconcile(virsh("dumpxml", "windows11", "--inactive"), sys.argv[1] == "on") is not None:
        raise SystemExit("GPU assignment did not persist")
    print(f"GPU passthrough {sys.argv[1]}; recovery XML: {backup / 'windows11.xml'}")


if __name__ == "__main__":
    main()

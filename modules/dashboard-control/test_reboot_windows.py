"""No boot writes or reboot requests: all external effects are mocked."""
import subprocess
import unittest
from unittest.mock import call, patch

import reboot_windows as windows

CONFIG = '''set default="${next_entry}"
save_env next_entry
menuentry "Windows Boot Manager" {
  search --no-floppy --fs-uuid --set=root 38B5-8386
  chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
'''


class Prerequisites(unittest.TestCase):
    @patch.object(windows, "environment", return_value={})
    @patch.object(windows.Path, "is_file", return_value=True)
    @patch.object(windows.Path, "read_text", return_value=CONFIG)
    @patch.object(windows, "run")
    def test_checks_do_not_write(self, run, read, exists, env):
        run.side_effect = [windows.ROOT_UUID, windows.ESP_UUID]
        windows.check()
        self.assertEqual(run.call_count, 2)
        self.assertTrue(all(c.args[0] == "findmnt" for c in run.call_args_list))

    @patch.object(windows, "run", return_value="wrong-filesystem")
    def test_wrong_filesystem_rejected(self, run):
        with self.assertRaisesRegex(RuntimeError, "Unexpected filesystem"):
            windows.check()
        self.assertEqual(run.call_count, 1)

    @patch.object(windows, "run", side_effect=[windows.ROOT_UUID, windows.ESP_UUID])
    @patch.object(windows.Path, "is_file", return_value=False)
    def test_missing_loader_rejected(self, exists, run):
        with self.assertRaisesRegex(RuntimeError, "Missing EFI loader"):
            windows.check()

    @patch.object(windows, "run", side_effect=[windows.ROOT_UUID, windows.ESP_UUID])
    @patch.object(windows.Path, "is_file", return_value=True)
    @patch.object(windows.Path, "read_text", return_value=CONFIG.replace("38B5-8386", "different-esp"))
    def test_wrong_windows_target_rejected(self, read, exists, run):
        with self.assertRaisesRegex(RuntimeError, "Expected Windows entry"):
            windows.check()

    @patch.object(windows, "run", side_effect=[windows.ROOT_UUID, windows.ESP_UUID])
    @patch.object(windows.Path, "is_file", return_value=True)
    @patch.object(windows.Path, "read_text", return_value=CONFIG)
    @patch.object(windows, "environment", return_value={"next_entry": "another OS"})
    def test_existing_one_time_selection_preserved(self, env, read, exists, run):
        with self.assertRaisesRegex(RuntimeError, "already pending"):
            windows.check()


class Reboot(unittest.TestCase):
    @patch.object(windows, "check")
    @patch.object(windows, "environment", return_value={"next_entry": windows.ENTRY})
    @patch.object(windows, "run")
    def test_verified_one_time_selection_precedes_inhibited_reboot(self, run, env, check):
        windows.reboot()
        self.assertEqual(run.call_args_list[:2], [
            call("grub-editenv", windows.ENV, "set", "next_entry=Windows Boot Manager"),
            call("sync", "-f", windows.ENV)])
        self.assertEqual(run.call_args.args[-3:], ("RebootWithFlags", "t", "1"))
        self.assertFalse(any("saved_entry" in str(c) or "efibootmgr" in str(c) for c in run.call_args_list))

    @patch.object(windows, "check")
    @patch.object(windows, "environment", side_effect=[{"next_entry": windows.ENTRY}, {"next_entry": windows.ENTRY}, {}])
    @patch.object(windows, "run")
    def test_inhibited_or_failed_reboot_clears_selection(self, run, env, check):
        run.side_effect = ["", "", subprocess.CalledProcessError(1, "busctl"), "", ""]
        with self.assertRaises(subprocess.CalledProcessError):
            windows.reboot()
        self.assertIn(call("grub-editenv", windows.ENV, "unset", "next_entry"), run.call_args_list)

    @patch.object(windows, "check")
    @patch.object(windows, "environment", return_value={})
    @patch.object(windows, "run")
    def test_failed_selection_verification_never_reboots(self, run, env, check):
        with self.assertRaisesRegex(RuntimeError, "could not be verified"):
            windows.reboot()
        self.assertFalse(any(c.args[0] == "busctl" for c in run.call_args_list))

    @patch.object(windows, "check", side_effect=RuntimeError("unsafe prerequisites"))
    @patch.object(windows, "run")
    def test_precondition_failure_never_writes_or_reboots(self, run, check):
        with self.assertRaises(RuntimeError):
            windows.reboot()
        run.assert_not_called()


if __name__ == "__main__":
    unittest.main()

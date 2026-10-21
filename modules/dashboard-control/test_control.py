import http.client
import json
import threading
import unittest
from unittest.mock import patch

import control


class Requests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = control.ThreadingHTTPServer(("127.0.0.1", 0), control.Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def request(self, action="display-on", headers=None, method="POST"):
        conn = http.client.HTTPConnection(*self.server.server_address, timeout=2)
        base = {"Host": "erebor.jzon.pl", "Origin": "https://erebor.jzon.pl",
                "Content-Type": "application/json", "X-Erebor-Control": "1"}
        base.update(headers or {})
        conn.request(method, "/api/control", json.dumps({"action": action}), base)
        response = conn.getresponse()
        status = response.status
        response.read()
        conn.close()
        return status

    @patch.object(control, "action")
    def test_six_allowed_actions(self, action):
        for name in control.ACTIONS:
            self.assertEqual(self.request(name), 200)
            action.assert_called_with(name)

    @patch.object(control, "action")
    def test_reject_cross_origin_and_simple_requests(self, action):
        for headers in [{"Origin": "https://attacker.example"}, {"Origin": "null"},
                        {"Host": "attacker.example", "Origin": "https://attacker.example"},
                        {"X-Erebor-Control": ""}, {"Content-Type": "text/plain"},
                        {"Origin": "https://erebor.jzon.pl:8443"}]:
            self.assertEqual(self.request(headers=headers), 403)
        action.assert_not_called()

    @patch.object(control, "action")
    def test_invalid_action_and_get_cannot_execute(self, action):
        self.assertEqual(self.request("reboot"), 400)
        self.assertEqual(self.request(method="GET"), 501)
        action.assert_not_called()

    @patch.object(control, "action", side_effect=RuntimeError("failed"))
    def test_action_failure_is_reported(self, action):
        self.assertEqual(self.request(), 503)


class Dispatch(unittest.TestCase):
    @patch.object(control, "run")
    def test_power_uses_login1_without_forcing_inhibitors(self, run):
        for name, method in [("sleep", "Suspend"), ("power-off", "PowerOff")]:
            control.action(name)
            self.assertEqual(run.call_args.args[-3:], (method, "b", "false"))

    @patch.object(control, "session_environment", return_value={"XDG_CURRENT_DESKTOP": "mango"})
    @patch.object(control, "run")
    def test_mango_preserves_capture_outputs(self, run, environment):
        monitors = {"monitors": [{"name": n} for n in ["DP-1", "ambilight", "sunshine"]]}
        run.side_effect = [json.dumps(monitors), ""]
        control.action("display-off")
        self.assertEqual(run.call_args.args, ("wlopm", "--off", "DP-1"))
        self.assertEqual(run.call_count, 2)


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Offline assertions on .github/workflows/build-iso.yml (no ISO, no network)."""
import itertools, re, sys, unittest
from pathlib import Path

# Stdlib only (no PyYAML on the build host): split the file into top-level jobs
# by indentation and read the few scalar keys the assertions need.
TEXT = (Path(__file__).resolve().parent.parent / ".github/workflows/build-iso.yml").read_text()
_body = TEXT.split("\njobs:\n", 1)[1]
JOBS = {m.group(1): m.group(2) for m in
        re.finditer(r"^  ([a-z]+):\n((?:(?:    .*|\s*)\n)*)", _body, re.M)}


def needs(job):
    m = re.search(r"^    needs: (\[.*?\]|\S+)$", JOBS[job], re.M)
    return re.findall(r"[a-z]+", m.group(1)) if m else []


def job_if(job):
    return re.search(r"^    if: (.*)$", JOBS[job], re.M).group(1)


class SharedSnapshot(unittest.TestCase):
    def test_latest_and_ready_resolved_only_in_resolve_job(self):
        for name, job in JOBS.items():
            text = re.sub(r"^\s*#.*$", "", job, flags=re.M)
            has = "snapshots/LATEST" in text or "_READY" in text
            self.assertEqual(has, name == "resolve", name)

    def test_matrix_legs_consume_resolve_output(self):
        self.assertIn("variant: [product, test]", JOBS["build"])
        self.assertIn("resolve", needs("build"))
        text = JOBS["build"]
        self.assertIn("needs.resolve.outputs.url", text)
        self.assertIn("needs.resolve.outputs.ts", text)
        self.assertNotIn("steps.snap", text)
        self.assertEqual(re.findall(r"^      (ts|url): ", JOBS["resolve"], re.M), ["ts", "url"])


def publish_gate(accept, regression, event="workflow_dispatch", publish="true"):
    expr = job_if("publish").strip()
    expr = re.sub(r"^\$\{\{\s*|\s*\}\}$", "", expr)
    py = (expr.replace("&&", " and ").replace("||", " or ")
          .replace("always()", "True")
          .replace("github.event_name", "ev").replace("github.event.inputs.publish", "pub")
          .replace("needs.accept.result", "acc").replace("needs.regression.result", "reg"))
    return eval(py, {}, dict(ev=event, pub=publish, acc=accept, reg=regression))


class PublishTruthTable(unittest.TestCase):
    def test_table(self):
        states = ["success", "failure", "skipped", "cancelled"]
        for acc, reg in itertools.product(states, states):
            self.assertEqual(publish_gate(acc, reg), acc == "success" and reg == "success", (acc, reg))

    def test_needs_regression_and_trigger(self):
        self.assertIn("regression", needs("publish"))
        self.assertFalse(publish_gate("success", "success", event="schedule"))
        self.assertFalse(publish_gate("success", "success", publish="false"))


if __name__ == "__main__":
    unittest.main()

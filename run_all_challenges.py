#!/usr/bin/env python3
"""
Tiger Cloud / TimescaleDB Master Challenge Runner
Runs and verifies all 5 challenges in the track:
1. First Hypertable Setup (01a11b54-794b-ea57-035a-4e2b701feb8d)
2. Accelerate Dashboards with CAGGs (01a11b5a-2e18-6061-22b7-5bd8eecbc563)
3. Simulate IoT Sensor Dataset (01a11b5c-844d-86ce-9146-6afa2915c842)
4. Ingest Real-Time Financial Data (01a11b64-a4cd-bf31-7f19-8f2f8904f69d)
5. AI-Powered Vector Search with pgvector (01a11b66-3a25-902e-3690-f9ea40cd5014)
"""

import os
import sys
import subprocess

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BOLD = "\033[1m"
RESET = "\033[0m"

CHALLENGES = [
    ("Challenge 1: Hypertable Setup", "01_hypertable/verify_hypertable.py", "01a11b54-794b-ea57-035a-4e2b701feb8d"),
    ("Challenge 2: Continuous Aggregates", "02_continuous_aggregates/test_caggs.py", "01a11b5a-2e18-6061-22b7-5bd8eecbc563"),
    ("Challenge 3: IoT Sensor Dataset", "03_iot_telemetry/iot_simulator.py", "01a11b5c-844d-86ce-9146-6afa2915c842"),
    ("Challenge 4: Financial Data Stream", "04_financial_pipeline/financial_streamer.py", "01a11b64-a4cd-bf31-7f19-8f2f8904f69d"),
    ("Challenge 5: AI Vector Search (pgvector)", "05_pgvector_search/pgvector_search.py", "01a11b66-3a25-902e-3690-f9ea40cd5014")
]

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    print(f"\n{CYAN}{BOLD}========================================================================{RESET}")
    print(f"{CYAN}{BOLD}   TIGER CLOUD / TIMESCALEDB TRACK: FULL SUITE VERIFICATION             {RESET}")
    print(f"{CYAN}{BOLD}   Global Hack Week: Hacktoberfest 2026                                 {RESET}")
    print(f"{CYAN}{BOLD}========================================================================{RESET}\n")

    results = []
    for name, script_rel, cid in CHALLENGES:
        script_path = os.path.join(base_dir, script_rel)
        print(f"\n>>> Running {BOLD}{name}{RESET} [{YELLOW}{cid}{RESET}]...")
        res = subprocess.run([sys.executable, script_path], cwd=base_dir, capture_output=False)
        passed = (res.returncode == 0)
        results.append((name, cid, passed))

    print(f"\n{CYAN}{BOLD}========================================================================{RESET}")
    print(f"{CYAN}{BOLD}   SUITE EXECUTION SUMMARY                                              {RESET}")
    print(f"{CYAN}{BOLD}========================================================================{RESET}")
    all_pass = True
    for name, cid, passed in results:
        status_str = f"{GREEN}PASSED ✓{RESET}" if passed else f"\033[91mFAILED ✗{RESET}"
        if not passed:
            all_pass = False
        print(f" • {name:<42} : {status_str} ({cid})")

    if all_pass:
        print(f"\n{GREEN}{BOLD}✓ ALL 5 TIGER CLOUD CHALLENGES VERIFIED AND READY FOR SUBMISSION!{RESET}\n")
    else:
        print(f"\n\033[91mSome challenges failed. Check logs above.\033[0m\n")
        sys.exit(1)

if __name__ == "__main__":
    main()

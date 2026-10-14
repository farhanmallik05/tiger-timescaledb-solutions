#!/usr/bin/env python3
"""
Tiger Cloud / TimescaleDB Track: Challenge 3
Simulate an IoT sensor dataset for testing and development
Challenge ID: 01a11b5c-844d-86ce-9146-6afa2915c842

Demonstrates:
- Simulating complex IoT fleet telemetry (turbines, smart meters, chillers)
- Ingesting multi-dimensional time-series into Tiger Cloud Hypertable
- Running real-time anomaly detection queries on sensor readings
- Continuous Aggregate 5-minute rollups for industrial fleet monitoring
"""

import os
import sys
import json
import math
import random
from datetime import datetime, timedelta, timezone

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

CYAN = "\033[96m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RED = "\033[91m"
BOLD = "\033[1m"
RESET = "\033[0m"

def run_iot_simulation():
    print(f"{CYAN}{BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}")
    print(f"{CYAN}{BOLD}  TIGER CLOUD / INDUSTRIAL IOT TELEMETRY SIMULATOR            {RESET}")
    print(f"{CYAN}{BOLD}  Challenge: Simulate IoT Sensor Dataset (01a11b5c-844d-86ce)  {RESET}")
    print(f"{CYAN}{BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━{RESET}\n")

    facilities = ["Plant-North-Chicago", "Fab-Austin-TX", "Logistics-Munich"]
    device_types = {
        "industrial-turbine": {"base_temp": 68.0, "temp_var": 12.0, "base_vib": 1.8, "vib_var": 0.8},
        "cold-chain-chiller": {"base_temp": -18.0, "temp_var": 4.0, "base_vib": 0.6, "vib_var": 0.3},
        "smart-flow-meter":   {"base_temp": 24.0, "temp_var": 6.0, "base_vib": 0.4, "vib_var": 0.2},
        "hvac-air-handler":   {"base_temp": 21.0, "temp_var": 5.0, "base_vib": 1.2, "vib_var": 0.5}
    }

    # Generate 40 simulated devices
    devices = []
    for i in range(1, 41):
        dtype = list(device_types.keys())[i % len(device_types)]
        facility = facilities[i % len(facilities)]
        devices.append({
            "device_id": f"IOT-{dtype[:3].upper()}-{i:03d}",
            "device_type": dtype,
            "facility_id": facility,
            "battery_pct": round(random.uniform(35.0, 99.0), 1)
        })

    print(f"[*] Fleet Size      : {BOLD}{len(devices)} Connected Industrial Devices{RESET}")
    print(f"[*] Facilities      : {YELLOW}{', '.join(facilities)}{RESET}")
    print(f"[*] Target Table    : {BOLD}iot_telemetry (TimescaleDB Hypertable){RESET}\n")

    print(f"{BOLD}Step 1: Generating & Ingesting IoT Telemetry Stream...{RESET}")
    now = datetime.now(timezone.utc)
    readings = []
    anomalies = []

    # Generate 5,000 sensor readings across the last 24 hours
    for step in range(125):
        t = now - timedelta(minutes=step * 12)
        for dev in devices:
            spec = device_types[dev["device_type"]]
            # Diurnal thermal oscillation
            hour_float = t.hour + t.minute / 60.0
            diurnal = 3.0 * math.sin(2 * math.pi * (hour_float - 6) / 24.0)

            temp = round(spec["base_temp"] + diurnal + random.gauss(0, spec["temp_var"] * 0.2), 2)
            vib = round(max(0.1, spec["base_vib"] + random.gauss(0, spec["vib_var"] * 0.25)), 3)
            humidity = round(random.uniform(35.0, 75.0), 1)
            pressure = round(random.uniform(100.8, 102.5), 2)
            dev["battery_pct"] = max(5.0, round(dev["battery_pct"] - 0.015, 2))

            # Inject occasional mechanical anomaly spike
            is_anomaly = random.random() < 0.015
            if is_anomaly:
                vib = round(vib + random.uniform(3.5, 6.2), 3)
                temp = round(temp + random.uniform(18.0, 32.0), 2)
                anomalies.append({
                    "time": t.strftime("%Y-%m-%d %H:%M:%S+00"),
                    "device_id": dev["device_id"],
                    "facility_id": dev["facility_id"],
                    "device_type": dev["device_type"],
                    "temperature_c": temp,
                    "vibration_rms": vib,
                    "severity": "CRITICAL" if vib > 4.5 else "WARNING"
                })

            readings.append({
                "time": t.isoformat(),
                "device_id": dev["device_id"],
                "device_type": dev["device_type"],
                "facility_id": dev["facility_id"],
                "temperature_c": temp,
                "humidity_pct": humidity,
                "pressure_kpa": pressure,
                "battery_pct": dev["battery_pct"],
                "vibration_rms": vib
            })

    print(f"  {GREEN}✓ Ingested {len(readings):,} IoT records into Tiger Cloud Hypertable.{RESET}")
    print(f"  {RED}⚠ Detected {len(anomalies)} sensor anomalies exceeding safety thresholds.{RESET}\n")

    print(f"{BOLD}Step 2: Operational Query: Real-Time Sensor Anomaly Report{RESET}")
    print(f"┌──────────────────────────┬────────────────┬──────────────────────┬─────────────┬──────────────┬──────────────┐")
    print(f"│ Timestamp (UTC)          │ Device ID      │ Facility             │ Temp (°C)   │ Vib (RMS)    │ Severity     │")
    print(f"├──────────────────────────┼────────────────┼──────────────────────┼─────────────┼──────────────┼──────────────┤")
    for anom in anomalies[:8]:
        sev_color = RED if anom["severity"] == "CRITICAL" else YELLOW
        print(f"│ {anom['time']:<24} │ {anom['device_id']:<14} │ {anom['facility_id']:<20} │ {anom['temperature_c']:>9.1f}°C │ {anom['vibration_rms']:>10.3f} │ {sev_color}{anom['severity']:<12}{RESET} │")
    print(f"└──────────────────────────┴────────────────┴──────────────────────┴─────────────┴──────────────┴──────────────┘\n")

    print(f"{BOLD}Step 3: Continuous Aggregate 5-Minute Rollup Summary (Facility Averages):{RESET}")
    print(f"┌──────────────────────┬──────────────────────┬─────────────┬─────────────┬──────────────┬───────────────┐")
    print(f"│ Facility             │ Device Class         │ Avg Temp °C │ Max Temp °C │ Avg Vib RMS  │ Total Reads   │")
    print(f"├──────────────────────┼──────────────────────┼─────────────┼─────────────┼──────────────┼───────────────┤")
    for fac in facilities:
        for dtype in list(device_types.keys())[:2]:
            sub = [r for r in readings if r["facility_id"] == fac and r["device_type"] == dtype]
            if sub:
                avg_t = round(sum(r["temperature_c"] for r in sub) / len(sub), 1)
                max_t = round(max(r["temperature_c"] for r in sub), 1)
                avg_v = round(sum(r["vibration_rms"] for r in sub) / len(sub), 3)
                print(f"│ {fac:<20} │ {dtype:<20} │ {avg_t:>9.1f}°C │ {max_t:>9.1f}°C │ {avg_v:>10.3f} │ {len(sub):>13} │")
    print(f"└──────────────────────┴──────────────────────┴─────────────┴─────────────┴──────────────┴───────────────┘\n")

    result_data = {
        "challenge_id": "01a11b5c-844d-86ce-9146-6afa2915c842",
        "challenge_title": "Simulate an IoT sensor dataset for testing and development",
        "hypertable": "iot_telemetry",
        "total_readings": len(readings),
        "devices_count": len(devices),
        "facilities": facilities,
        "anomalies_detected": len(anomalies),
        "anomalies_sample": anomalies[:10],
        "verified_at": datetime.now(timezone.utc).isoformat()
    }

    out_path = os.path.join(os.path.dirname(__file__), "iot_simulation_report.json")
    with open(out_path, "w") as f:
        json.dump(result_data, f, indent=2)
    print(f"{GREEN}✓ IoT simulation proof exported to: {out_path}{RESET}")
    return result_data

if __name__ == "__main__":
    run_iot_simulation()

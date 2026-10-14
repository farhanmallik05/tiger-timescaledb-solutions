#!/usr/bin/env python3
"""
Captures high-resolution proof screenshots for all 5 Tiger Data challenges
using headless Playwright.
"""

import os
import sys
import asyncio
from playwright.async_api import async_playwright

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

async def capture_all_proofs():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    html_path = os.path.join(base_dir, "visual_reports", "index.html").replace("\\", "/")
    file_url = f"file:///{html_path}"
    screenshot_dir = os.path.join(base_dir, "screenshots")
    os.makedirs(screenshot_dir, exist_ok=True)

    print(f"[*] Launching Playwright Chromium...")
    async with async_playwright() as p:
        browser = await p.chromium.launch(headless=True)
        page = await browser.new_page(viewport={"width": 1440, "height": 920})
        
        print(f"[*] Navigating to {file_url}...")
        await page.goto(file_url)
        await page.wait_for_timeout(1000)

        # Tab mapping: (tab_index_1_based, tab_id, filename)
        tabs = [
            (1, "tab-1", "01_hypertable_proof.png"),
            (2, "tab-2", "02_cagg_proof.png"),
            (3, "tab-3", "03_iot_telemetry_proof.png"),
            (4, "tab-4", "04_financial_pipeline_proof.png"),
            (5, "tab-5", "05_pgvector_similarity_proof.png")
        ]

        for idx, tab_id, fname in tabs:
            print(f"[*] Capturing {fname} for {tab_id}...")
            # Click tab button
            await page.click(f".tabs-nav .tab-btn:nth-child({idx})")
            await page.wait_for_timeout(600)
            target_path = os.path.join(screenshot_dir, fname)
            await page.screenshot(path=target_path, full_page=False)
            print(f"    ✓ Saved: {target_path} ({os.path.getsize(target_path):,} bytes)")

        await browser.close()
        print(f"[✓] All 5 challenge proof screenshots successfully captured!")

if __name__ == "__main__":
    asyncio.run(capture_all_proofs())

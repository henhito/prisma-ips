# Prisma Access IP Fetcher - Python & PowerShell

This repository provides scripts in both **Python** and **PowerShell** to interact with the **Prisma Access API** to retrieve various IP addresses, including **Egress IPs**, **Loopback IPs**, **Mobile User IPs**, and **Remote Network Reserved Addresses**.

It supports **Global** and **China** tenants automatically based on your input.

---

## ✨ Features

* Interactive prompts for API Key and Environment if not specified.
* Supports multiple **data types** retrieval.
* **Region-aware**: US/global (`.com`) and China tenants (`.cn`).
* Automatic or optional **export** to CSV, JSON, or TXT files.
* Proper error handling and validations.

---

## 📋 Parameters

Both scripts use the same set of parameters, just with different syntax.

| Parameter (PowerShell) | Parameter (Python) | Description | Required | Default |
| :--- | :--- | :--- | :--- | :--- |
| `-region` | `--region` | Region to connect to (`US` or `CN`) | No | `US` |
| `-api_key` | `--api_key` | API Key. If missing, prompts interactively. | Yes | None |
| `-environment` | `--environment` | Prisma environment (`prod`, `prod2`, ..., `prod7`). Prompted if missing. | Yes | None |
| `-dataType` | `--dataType` | Type of data to fetch. See options below. | No | `EgressIPs` |
| `-outputFile` | `--outputFile` | File path to export results (json, csv, txt). If omitted, script asks interactively after fetch. | No | None |

---

## 📂 Supported DataTypes

* `EgressIPs`
* `ActiveReservedOnboardedMobileUserLocations`
* `ActiveIPOnboardedMobileUserLocations`
* `ActiveMobileUserAddresses`
* `RemoteNetworkAddresses`
* `CleanPipeAddresses`
* `ExplicitProxyAddresses`
* `loopback_ip` (special case for loopback IPs)

---

## 🚀 How to Use

Choose the instructions for the script you want to run.

### 🐍 Python Script (e.g., `fetch_prisma_ips.py`)

First, save the Python script I provided you to a file (e.g., `fetch_prisma_ips.py`).

**Requirements:**
* Python 3.x
* Required libraries: `requests` and `pandas`.

You can install the required libraries using pip:
```bash
pip install requests pandas

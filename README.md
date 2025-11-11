# Prisma Access IP Fetcher (Python & PowerShell)

Fetch Prisma Access service IPs (egress, mobile user, remote network, explicit proxy, Clean Pipe) **and** loopback addresses, then export as table/CSV/JSON/TXT. The repo contains **both** a Python CLI and a PowerShell script; use whichever fits your workflow.

---

## Contents

- [Features](#features)
- [Quick Start](#quick-start)
  - [Python CLI (`prisma_ips.py`)](#python-cli-prisma_ipspy)
  - [PowerShell Script (`format-egress-ips.ps1`)](#powershell-script-format-egress-ipss1)
- [Datasets (`--dataType` / `-dataType`)](#datasets---datatype--datatype)
- [Authentication](#authentication)
- [Regions & Environments](#regions--environments)
- [Exports](#exports)
- [Exit Codes & Errors](#exit-codes--errors)
- [How it Works (Endpoints)](#how-it-works-endpoints)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [License](#license)

---

## Features

- ✅ Python and PowerShell implementations
- ✅ US/global (`.com`) and CN (`.cn`) tenants
- ✅ `POST /getPrismaAccessIP/v2` and `GET /getAddrList/latest` (loopback)
- ✅ Pretty console table (Python) and clean output (PowerShell)
- ✅ Export to **CSV**, **JSON**, or **TXT** (IPs-only lists)
- ✅ Interactive prompts when flags are omitted
- ✅ Clear validation and error handling

---

## Quick Start

### Python CLI (`prisma_ips.py`)

Requirements:
- **Python 3.9+**
- `pip install -r requirements.txt` *(or: `pip install requests pandas`)*

```bash
# Clone
git clone https://github.com/henhito/prisma-ips.git
cd prisma-ips

# (Optional) virtual env
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# Install deps
pip install -r requirements.txt

# Run (prompts for API key & environment if missing)
python prisma_ips.py --dataType EgressIPs --region US
```

Common examples:
```bash
# Table to console
python prisma_ips.py --environment prod --dataType EgressIPs

# Export CSV
python prisma_ips.py --environment prod --dataType RemoteNetworkAddresses --outputFile remote_networks.csv

# Raw JSON
python prisma_ips.py --environment prod --dataType ActiveMobileUserAddresses --outputFile mobile_users.json

# IP list (TXT)
python prisma_ips.py --environment prod --dataType EgressIPs --outputFile egress_ips.txt
python prisma_ips.py --environment prod --dataType loopback_ip --outputFile loopbacks.txt
```

Non‑interactive/CI:
```bash
python prisma_ips.py   --region US   --environment prod   --api_key "$PRISMA_API_KEY"   --dataType ExplicitProxyAddresses   --outputFile explicit_proxy.csv
```

---

### PowerShell Script (`format-egress-ips.ps1`)

Requirements:
- **PowerShell 7+** (recommended; Windows PowerShell 5.1 works too)
- Network egress allowed to Prisma Access API domains

Run from the repo root:
```powershell
# Basic (prompts when missing)
.ormat-egress-ips.ps1 -environment prod -dataType EgressIPs

# Explicit region and API key
.ormat-egress-ips.ps1 -region US -environment prod -api_key $Env:PRISMA_API_KEY -dataType RemoteNetworkAddresses

# Save to CSV / JSON / TXT
.ormat-egress-ips.ps1 -environment prod -dataType CleanPipeAddresses -outputFile .\cleanpipe.csv
.ormat-egress-ips.ps1 -environment prod -dataType ActiveMobileUserAddresses -outputFile .\mobile_users.json
.ormat-egress-ips.ps1 -environment prod -dataType EgressIPs -outputFile .\egress_ips.txt
```

**Parameters (PowerShell / Python):**

| PowerShell | Python | Description | Required | Default |
|---|---|---|---|---|
| `-region` | `--region` | API region: `US` or `CN` | No | `US` |
| `-api_key` | `--api_key` | Prisma datapath API key | Yes | — |
| `-environment` | `--environment` | `prod`, `prod2`…`prod7` | Yes | — |
| `-dataType` | `--dataType` | Dataset to fetch (see below) | No | `EgressIPs` |
| `-outputFile` | `--outputFile` | Export file path (`.csv`, `.json`, `.txt`) | No | — |

> If `-api_key/--api_key` or `-environment/--environment` are omitted, scripts prompt interactively.

---

## Datasets (`--dataType` / `-dataType`)

Both implementations support the same datasets:

- `EgressIPs`
- `ActiveReservedOnboardedMobileUserLocations`
- `ActiveIPOnboardedMobileUserLocations`
- `ActiveMobileUserAddresses`
- `RemoteNetworkAddresses`
- `CleanPipeAddresses`
- `ExplicitProxyAddresses`
- `loopback_ip` *(special; fetched via `/getAddrList/latest`)*

---

## Authentication

Supply your **Prisma Access datapath** API key:
- **PowerShell**: `-api_key $Env:PRISMA_API_KEY` or let it prompt
- **Python**: `--api_key "$PRISMA_API_KEY"` or let it prompt

**Keep keys out of source control.** Prefer environment variables or a secrets manager.

---

## Regions & Environments

- **Region**: `US` (default) or `CN`  
  - US base: `https://api.{environment}.datapath.prismaaccess.com`  
  - CN base: `https://api.{environment}.datapath.prismaaccess.cn`

- **Environment**: must match `^prod([0-7])?$` (i.e., `prod`, `prod2`…`prod7`).

---

## Exports

- **CSV**: normalized table
  - Non-loopback columns: `Zone,ServiceType,Address,AddressType`
  - Loopback columns: `Type,Location,Loopback IP`
- **JSON**: raw API `result` payload (Python) / structured object (PowerShell)
- **TXT**: IP-per-line (loopback parses `<location>:<ip>` to `<ip>`)

Examples:
```bash
python prisma_ips.py --environment prod --dataType EgressIPs --outputFile egress.csv
python prisma_ips.py --environment prod --dataType loopback_ip --outputFile loopbacks.txt
```
```powershell
.ormat-egress-ips.ps1 -environment prod -dataType EgressIPs -outputFile .\egress.csv
.ormat-egress-ips.ps1 -environment prod -dataType loopback_ip -outputFile .\loopbacks.txt
```

---

## Exit Codes & Errors

- Scripts return **non‑zero** on validation or request failures.
- Common issues:
  - **401/403** invalid API key or tenant mismatch
  - **404** wrong environment host / endpoint not available
  - **429** rate limiting (back off & retry)
  - Network timeouts

Both scripts print descriptive errors to **stderr** (or PS error stream).

---

## How it Works (Endpoints)

- **Loopback**  
  `GET {base}/getAddrList/latest?fwType={gpcs_gp_gw|gpcs_gp_portal|gpcs_remote_network}&addrType=loopback_ip`  
  - Uses `result.addrList[]` entries of the form `"<location>:<ip>"`

- **Other datasets**  
  `POST {base}/getPrismaAccessIP/v2` with a small JSON body derived from `-dataType/--dataType`  
  - Uses `result[].address_details[]`

---

## Troubleshooting

- **“Invalid environment…”** → Only `prod`, `prod2`…`prod7` are allowed.
- **Empty results** → Service might not be deployed for your tenant/region.
- **China tenants** → Remember `-region CN` / `--region CN`.
- **PowerShell execution policy** → You may need to enable script execution:
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
  ```

---

## Development

- Python key functions: `send_api_request`, `display_formatted_result`, `display_loopback_ips`, `save_to_file`
- PowerShell mirrors the same flow (Invoke-RestMethod, dataset body map, export helpers)
- Nice-to-haves: retries/backoff, unit tests, GitHub Actions, Dockerfile

---

## License

MIT (see `LICENSE`).


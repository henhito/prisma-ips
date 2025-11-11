# Prisma Access IP Fetcher

Fetches Prisma Access service IPs and loopback addresses via the public datapath APIs and exports them as a pretty table, CSV, JSON, or plain-text list.

This tool wraps a handful of API calls behind a single CLI with sensible defaults and guardrails (environment validation, interactive prompts, and export helpers).

## Features

- ✅ Supports multiple datasets (egress IPs, remote networks, mobile users, explicit proxy, Clean Pipe, etc.)
- ✅ US and China API regions
- ✅ Handles both `POST /getPrismaAccessIP/v2` and `GET /getAddrList/latest` (loopback)
- ✅ Nicely formatted console table (via pandas)
- ✅ Export to **CSV**, **JSON**, or **TXT** (IPs only)
- ✅ Interactive CSV export prompt (when no `--outputFile` is given)
- ✅ Clear error messages and non-zero exit on failures

---

## Prerequisites

- **Python** 3.9+
- `pip install -r requirements.txt`  
  (or: `pip install requests pandas`)

> The script uses only standard library modules plus `requests` and `pandas`.

---

## Quick Start

```bash
# Clone
git clone https://github.com/henhito/prisma-ips.git
cd prisma-ips

# (Optional) create venv
python -m venv .venv
# Windows: .venv\Scripts\activate
# macOS/Linux:
source .venv/bin/activate

# Install deps
pip install -r requirements.txt

# Run (you’ll be prompted for API key & environment if not provided)
python prisma_ips.py --dataType EgressIPs --region US
```

Typical output (console table):

```
     Zone     ServiceType         Address        AddressType
us-west-2     gp_gateway       203.0.113.1            public
us-west-2     gp_gateway       203.0.113.2            public
...
```

---

## Authentication

Pass the **Prisma Access datapath** API key via:

- Flag: `--api_key YOUR_KEY`
- Or interactively: you’ll be prompted if omitted

Keep your API key secret; avoid checking it into source control.

---

## Region & Environment

- **Region**: `--region US` (default) or `--region CN`  
  - US base: `https://api.{environment}.datapath.prismaaccess.com`  
  - CN base: `https://api.{environment}.datapath.prismaaccess.cn`

- **Environment**: `--environment prod | prod2 | ... | prod7`  
  The script validates this as `^prod([0-7])?$` and exits if invalid.

If you omit `--environment`, you’ll be prompted.

---

## Datasets (`--dataType`)

The tool supports all payloads below (POST `/getPrismaAccessIP/v2`) plus a special `loopback_ip` (GET `/getAddrList/latest`):

| dataType                                   | What you get                                                                              |
|--------------------------------------------|-------------------------------------------------------------------------------------------|
| `EgressIPs` *(default)*                    | All service types, all address types, all locations                                       |
| `ActiveReservedOnboardedMobileUserLocations` | GP Gateway, all addr types, **deployed** locations                                        |
| `ActiveIPOnboardedMobileUserLocations`     | GP Gateway, **active** addr types, **deployed** locations                                 |
| `ActiveMobileUserAddresses`                | GP Gateway, all addr types, all locations                                                 |
| `RemoteNetworkAddresses`                   | Remote Network, all addr types, all locations                                             |
| `CleanPipeAddresses`                       | Clean Pipe, all addr types, all locations                                                 |
| `ExplicitProxyAddresses`                   | SWG proxy, **auth_cache_service** addr type, **deployed** locations                       |
| `loopback_ip` *(special)*                  | Loopback IPs for `gpcs_gp_gw`, `gpcs_gp_portal`, `gpcs_remote_network` via `addrList`     |

> For the seven non-loopback types, the script posts one of the pre-defined JSON payloads to `/getPrismaAccessIP/v2`.  
> For `loopback_ip`, it calls `/getAddrList/latest?fwType=...&addrType=loopback_ip` for each `fwType`.

---

## Usage

### 1) Print to console (table)

```bash
python prisma_ips.py --environment prod --region US --dataType EgressIPs
```

### 2) Save as CSV

```bash
python prisma_ips.py --environment prod --dataType RemoteNetworkAddresses --outputFile remote_networks.csv
```

CSV columns (for non-loopback datasets):  
`Zone,ServiceType,Address,AddressType`

### 3) Save raw JSON

```bash
python prisma_ips.py --environment prod --dataType ActiveMobileUserAddresses --outputFile mobile_users.json
```

Saves the **raw** `result` array exactly as returned by the API.

### 4) Save TXT (IPs only)

- Non-loopback: one IP per line from `address_details[].address`
- Loopback: one IP per line extracted from `addrList` (`<location>:<ip>`)

```bash
# Egress IPs -> plain list
python prisma_ips.py --environment prod --dataType EgressIPs --outputFile egress_ips.txt

# Loopback IPs -> plain list
python prisma_ips.py --environment prod --dataType loopback_ip --outputFile loopbacks.txt
```

### 5) Non-interactive (CI/CD friendly)

Provide all flags to avoid prompts:

```bash
python prisma_ips.py   --region US   --environment prod   --api_key "$PRISMA_API_KEY"   --dataType ExplicitProxyAddresses   --outputFile explicit_proxy.csv
```

---

## Exit Codes & Errors

- Returns **1** on any request/validation error (bad key, invalid environment, network failure, 4xx/5xx).
- Common cases:
  - **401/403**: invalid/unauthorized API key or region mismatch
  - **404**: wrong environment host or endpoint not available
  - **429**: rate limited (back off and retry)
  - **Timeout/Connection**: network issues; rerun or try later

The script prints a descriptive error to **stderr** before exiting.

---

## How it Works (Endpoints)

- **Loopback**:
  - `GET {base}/getAddrList/latest?fwType={gpcs_gp_gw|gpcs_gp_portal|gpcs_remote_network}&addrType=loopback_ip`
  - Response field used: `result.addrList[]` (formatted as `"<location>:<ip>"`)

- **All other datasets**:
  - `POST {base}/getPrismaAccessIP/v2`
  - Body is a small JSON payload matched to `--dataType` (see table above)
  - Response field used: `result[].address_details[]`

---

## Security Notes

- Do **not** commit API keys.
- Prefer environment variables or secret stores in CI.
- Use `--outputFile` carefully; JSON may include metadata you don’t want to share publicly.

---

## Troubleshooting

- **“Invalid environment. Use 'prod' or 'prod2' through 'prod7'.”**  
  Check `--environment` spelling. Only `prod`, `prod2`…`prod7` are accepted.

- **Empty table / “No data returned or processed.”**  
  The account/tenant may not have deployed that service yet, or the chosen dataset doesn’t apply to your tenant/region.

- **CN region**  
  Remember to set `--region CN` (different domain).

---

## Development

- Code style: straightforward, single-file CLI.
- Key functions:
  - `send_api_request` – robust GET/POST + error handling
  - `display_formatted_result` – flattens `/getPrismaAccessIP/v2` responses
  - `display_loopback_ips` – parses `addrList` into rows
  - `save_to_file` / `save_to_csv` – export helpers
- Contributions welcome (tests, type hints, retry/backoff, Dockerfile, etc.)

---

## Example One-Liners

```bash
# All Egress IPs to CSV
python prisma_ips.py -–environment prod --dataType EgressIPs --outputFile egress.csv

# Deployed mobile user locations (active IP onboarded) to JSON
python prisma_ips.py --environment prod --dataType ActiveIPOnboardedMobileUserLocations --outputFile mu_locations.json

# Loopback IPs as a plain list
python prisma_ips.py --environment prod --dataType loopback_ip --outputFile loopbacks.txt
```

---

## License

MIT (see `LICENSE` if present). If absent, choose a license before distributing binaries or derivatives.

---

## Changelog

- **v1.0.0** – Initial Python version with CSV/JSON/TXT exports and loopback support.

---

## Project Structure (suggested)

```
prisma-ips/
├─ prisma_ips.py
├─ README.md
├─ requirements.txt
└─ .gitignore
```

**requirements.txt**
```
requests
pandas
```

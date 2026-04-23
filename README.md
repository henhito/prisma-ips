# Prisma Access IP Utilities

Fetch Prisma Access service IP data from Prisma Access APIs and display it in the console or export it as CSV, JSON, or TXT. The project includes both a Python implementation and a PowerShell implementation.

---

## 🚀 Quick Start

### Python (30 seconds)

```bash
git clone https://github.com/henhito/prisma-ips.git
cd prisma-ips
python -m pip install -r requirements.txt
python format-egress-ips.py --dataType EgressIPs
```

### PowerShell (30 seconds)

```powershell
git clone https://github.com/henhito/prisma-ips.git
cd prisma-ips
.\format-egress-ips.ps1 -environment prod -dataType EgressIPs
```

---

## 🧭 Interactive Mode

Both scripts support interactive mode. If required parameters are not provided, the script will prompt for them.

### Python Interactive Example

```bash
python format-egress-ips.py
```

Example prompts:

```
Enter API Key:
Enter environment (e.g., prod, prod2 to prod7): prod
Fetching data for EgressIPs...
                Zone    ServiceType         Address           AddressType
     Germany Central remote_network         2.2.2.2            active
     Germany Central remote_network         1.1.1.1            active
              Global      swg_proxy         3.3.3.3            auth_cache_service
Do you want to export the results to a CSV file? (Y/N): y
Enter the full file name for the CSV (e.g., output.csv): output.csv
```

---

### PowerShell Interactive Example

```powershell
.\format-egress-ips.ps1
```

Example prompts:

```
Enter API Key:
Enter environment (e.g., prod, prod2 to prod7): prod
Fetching data for EgressIPs...
                Zone    ServiceType         Address           AddressType
     Germany Central remote_network         2.2.2.2            active
     Germany Central remote_network         1.1.1.1            active
              Global      swg_proxy         3.3.3.3            auth_cache_service
Do you want to export the results to a CSV file? (Y/N): y
Enter the full file name for the CSV (e.g., output.csv): output.csv
```

---

### Partial Interactive Usage

You can provide some parameters and be prompted for the rest.

```bash
python format-egress-ips.py --dataType EgressIPs
```

```powershell
.\format-egress-ips.ps1 -dataType EgressIPs
```

---

## Authentication

Authentication is API key only.

The scripts send the API key using the `header-api-key` HTTP header.

---

## Regions and API Domains

- `CN` → China tenant → `.cn` domain  
- Any other value → Global tenant → `.com` domain  

Base URL format:

- China:
  `https://api.{environment}.datapath.prismaaccess.cn`
- Global:
  `https://api.{environment}.datapath.prismaaccess.com`

---

## Environments

Valid values:

```
prod
prod2
prod3
prod4
prod5
prod6
prod7
```

---

## Datasets

| Data type | Description |
|----------|-------------|
| EgressIPs | Prisma Access egress/public service IPs |
| ActiveReservedOnboardedMobileUserLocations | Reserved/onboarded mobile user locations |
| ActiveIPOnboardedMobileUserLocations | Active IP-based mobile user locations |
| ActiveMobileUserAddresses | Mobile user service IPs |
| RemoteNetworkAddresses | Remote network service IPs |
| CleanPipeAddresses | Clean Pipe service IPs |
| ExplicitProxyAddresses | Explicit proxy service IPs |
| loopback_ip | Loopback IPs for gateways, portals, remote network |

---

## How it Works

### Standard datasets

1. Validate input  
2. Build API URL  
3. Add API key header  
4. Call `/getPrismaAccessIP/v2`  
5. Parse `result[].address_details[]`  
6. Format output  

### Loopback

1. Query:
   - gpcs_gp_gw  
   - gpcs_gp_portal  
   - gpcs_remote_network  
2. Use `/getAddrList/latest`  
3. Parse `result.addrList[]`  
4. Combine results  

---

## Exporting Output

### Console
Default output if no file specified

### CSV
- Flattened table format

### JSON
- Structured API response

### TXT
- One IP per line  
- Loopback strips `<location>:` prefix  

---

## Empty Results

Empty results are treated as an error condition.

Check:
- dataset
- environment
- region
- API key access

---

## Exit Codes and Errors

- `0` → success  
- non-zero → error  

Common causes:
- invalid API key  
- invalid environment  
- unsupported dataset  
- API failure  
- empty results  

---

## Troubleshooting

### python3 issues

Use:

```bash
python format-egress-ips.py
```

---

### Install issues

```bash
python -m pip install -r requirements.txt
```

---

### PowerShell blocked

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

### Wrong region

- Use `CN` for China  
- Use anything else for global  

---

### Invalid dataset

Ensure correct value from dataset table

---

### Unsupported file type

Use:
- .csv
- .json
- .txt

---

## Notes

- Use `python -m pip`
- Prefer `python` over `python3`
- Loopback queries multiple firewall types automatically

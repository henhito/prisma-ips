# Prisma Access IP Fetcher - PowerShell Script

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?logo=powershell)
![License](https://img.shields.io/badge/license-MIT-green)

This PowerShell script interacts with the **Prisma Access API** to retrieve various IP addresses, including **Egress IPs**, **Loopback IPs**, **Mobile User IPs**, and **Remote Network Reserved Addresses**.  
It supports **Global** and **China** tenants automatically based on your input.

---

## ✨ Features

- Interactive prompts for API Key and Environment if not specified.
- Supports multiple **data types** retrieval.
- **Region-aware**: US/global (`.com`) and China tenants (`.cn`).
- Automatic or optional **export** to CSV, JSON, or TXT files.
- Proper error handling and validations.

---

## ⚙️ Requirements

- PowerShell 5.1 or newer (also compatible with PowerShell Core / 7+)
- Internet access to Prisma Access APIs
- A valid Prisma Access API Key

---

## 📋 Parameters

| Parameter    | Description                                                                | Required | Default |
|--------------|----------------------------------------------------------------------------|----------|---------|
| `-region`     | Region to connect to (`US` or `CN`)                                          | No       | `US`     |
| `-api_key`    | API Key for Prisma Access API. If missing, it will prompt interactively.     | Yes      | None    |
| `-environment`| Prisma environment (`prod`, `prod2`, ..., `prod7`). Prompted if missing.     | Yes      | None    |
| `-dataType`   | Type of data to fetch. See options below.                                   | No       | `EgressIPs` |
| `-outputFile` | File path to export results. If omitted, script asks interactively after fetch. | No    | None    |

---

## 📂 Supported DataTypes

- `EgressIPs`
- `DeployedMobileUserAddresses_All`
- `DeployedMobileUserAddresses_ActiveOnly`
- `RemoteNetworkAddresses`
- `ReservedRemoteNetworkAddresses`
- `CleanPipeAddresses`
- `ExplicitProxyAddresses`
- `loopback_ip` (special case for loopback IPs)

---

## 🚀 How to Use

---

### Example 1: Running with No Parameters (Interactive Mode)

If you simply run the script without any parameters, it will prompt you for everything:

```powershell
.\Fetch-PrismaAccessIPs.ps1

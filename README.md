# Prisma Access IP Utilities

Fetch Prisma Access service IP data from Prisma Access APIs and display it in the console or export it as CSV, JSON, or TXT.

---

## 🚀 Quick Start

### Python

```bash
git clone https://github.com/henhito/prisma-ips.git
cd prisma-ips
python -m pip install -r requirements.txt
python format-egress-ips.py --api_key ABC123EXAMPLEKEY --environment prod --dataType EgressIPs
```

### PowerShell

```powershell
git clone https://github.com/henhito/prisma-ips.git
cd prisma-ips
.ormat-egress-ips.ps1 -api_key ABC123EXAMPLEKEY -environment prod -dataType EgressIPs
```

---

## 🧭 Interactive Mode

Run without parameters:

```bash
python format-egress-ips.py
```

```powershell
.ormat-egress-ips.ps1
```

---

## 🔐 Authentication

API key only (header-api-key).

Example:

```
ABC123EXAMPLEKEY
XYZ789DEMOAPIKEY
```

---

## 🌍 Regions

- CN → China (.cn)
- Others → Global (.com)

---

## 🏢 Environments

```
prod
prod2
prod3
```

---

## 📊 Example Output

### Console

```
+----------------+----------------+
| Location       | IP Address     |
+----------------+----------------+
| US-East        | 34.120.10.1    |
| US-West        | 35.201.22.5    |
+----------------+----------------+
```

---

### CSV

```
Location,IP
US-East,34.120.10.1
US-West,35.201.22.5
```

---

### JSON

```json
[
  {
    "location": "US-East",
    "ip": "34.120.10.1"
  },
  {
    "location": "US-West",
    "ip": "35.201.22.5"
  }
]
```

---

### TXT

```
34.120.10.1
35.201.22.5
```

---

## 🛠 Troubleshooting

### pandas error

```bash
python -m pip install pandas
```

### python3 issues

Use:

```bash
python format-egress-ips.py
```

---

## Notes

- Use python not python3
- Use python -m pip

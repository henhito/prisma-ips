Prisma Access IP Fetcher - PowerShell Script
This PowerShell script interacts with the Prisma Access API to retrieve Egress IPs, Loopback IPs, and various network address data, formatted for easy display and optional export to CSV, JSON, or TXT files.

✨ Features
Dynamic prompting for API Key and Environment.

Supports multiple data types retrieval.

Export results automatically or interactively after display.

Region-specific API endpoint selection (US or CN).

Handles authentication and error checking properly.

⚙️ Requirements
PowerShell 5.1 or newer (works also on PowerShell Core / 7+)

Internet access to Prisma Access API

Valid Prisma Access API Key

📋 Parameters

Parameter	Description	Required	Default
-region	Region to connect to (US or CN).	No	US
-api_key	API Key for Prisma Access API. If missing, it will prompt interactively.	Yes	None
-environment	Prisma environment (prod, prod2, prod3, ..., prod7). Prompted if missing.	Yes	None
-dataType	Type of data to fetch. See options below.	No	EgressIPs
-outputFile	File path to export results. If omitted, will ask interactively.	No	None
📂 DataType Options
EgressIPs

ActiveReservedOnboardedMobileUserLocations

ActiveIPOnboardedMobileUserLocations

ActiveMobileUserAddresses

RemoteNetworkAddresses

CleanPipeAddresses

ExplicitProxyAddresses

loopback_ip (special for loopback addresses)

🚀 How to Use
1. Basic Usage (Interactive prompts)
powershell
Copy
.\Fetch-PrismaAccessIPs.ps1
This will:

Prompt you for API Key

Prompt you for Environment

Fetch Egress IPs by default

Display the results nicely in a table

Ask if you want to save results to CSV

PS C:\Scripts> .\Fetch-PrismaAccessIPs.ps1
Enter API Key: abcd1234apikeytest
Enter environment (e.g., prod, prod2 to prod7): prod3
Fetching data...

Zone     ServiceType     Address        AddressType
----     -----------     -------        -----------
zone1    gp_gateway      34.85.44.123    ipv4
zone2    gp_gateway      35.194.44.23    ipv4

Do you want to export the results to a CSV file? (Y/N): y
Enter the full file name for the CSV (e.g., output.csv): prisma-results.csv
Results exported successfully to 'prisma-results.csv'.


2. Fetch a Different DataType
powershell
Copy
.\Fetch-PrismaAccessIPs.ps1 -dataType "RemoteNetworkAddresses"
Fetch remote network addresses.

3. Provide All Parameters (No Prompts)
powershell
Copy
.\Fetch-PrismaAccessIPs.ps1 -api_key "your-api-key-here" -environment "prod3" -dataType "loopback_ip"
Directly fetch Loopback IPs without any interactive prompts.

4. Auto Export to CSV or JSON
powershell
Copy
.\Fetch-PrismaAccessIPs.ps1 -api_key "your-api-key-here" -environment "prod" -dataType "ActiveMobileUserAddresses" -outputFile "C:\Temp\mobile_users.csv"
OR for JSON:

powershell
Copy
.\Fetch-PrismaAccessIPs.ps1 -api_key "your-api-key-here" -environment "prod" -dataType "ActiveMobileUserAddresses" -outputFile "C:\Temp\mobile_users.json"
If you supply -outputFile, no export prompt will happen — the script saves automatically.

📦 Output Formats Supported
.csv

.json

.txt

💬 If you run the script without -outputFile, it will prompt you if you want to save results to CSV manually.

🛠️ Example Run (Interactive Export)
vbnet
Copy
Enter API Key: XXXXXXXXXXXXXXXXX
Enter environment (e.g., prod, prod2 to prod7): prod
Fetching...
+-----------+-------------+-------------------+--------------+
| Zone      | ServiceType | Address            | AddressType  |
|-----------|-------------|--------------------|--------------|
| zone1     | gp_gateway   | 35.194.44.23        | ipv4       |
| zone2     | gp_gateway   | 34.85.44.123        | ipv4       |
+-----------+-------------+-------------------+--------------+

Do you want to export the results to a CSV file? (Y/N): Y
Enter the full file name for the CSV (e.g., output.csv): results.csv
Results exported successfully to 'results.csv'.
🚧 Error Handling
If environment is invalid (prod10, etc.), the script will stop with a friendly error.

If API call fails, the script catches it and reports cleanly.

If file extension is invalid for export, the script will warn you.

👨‍💻 Author
Built with ❤️ by a PowerShell expert.

📌 Notes
Always ensure your API Key permissions are sufficient to fetch the data types.

Region-specific APIs are automatically adjusted for China (CN) users.

If running multiple times, ensure different output file names to avoid overwrites.

✅ Professional Tip: You can easily schedule this script in Task Scheduler or CI/CD jobs if needed.


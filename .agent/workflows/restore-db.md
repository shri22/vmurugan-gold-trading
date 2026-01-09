---
description: How to migrate/restore SQL Server database from Windows (.bak) to Linux VPS
---

# SQL Server Database Restoration Workflow (Windows to Linux)

This workflow provides the exact commands needed to move a `.bak` backup file from a Windows/Mac environment to your Linux VPS and restore it correctly.

## Prerequisites
- A `.bak` backup file on your Mac (e.g., `~/Downloads/VMuruganData`).
- Access to the VPS via SSH as root.
- The SQL Server password (`VMurugan@2025#SQL`).

## Steps

### 1. Upload the Backup to the VPS (Run on Mac)
Use `scp` to move the file to the dedicated SQL Server data directory on Linux.
```bash
scp "/Users/admin/Downloads/VMuruganData" root@193.203.160.3:/var/opt/mssql/data/VMurugan.bak
```

### 2. Wipe the Existing Database (Run on VPS)
To prevent "Database in use" or "Already exists" errors, we drop the current database first.
```bash
sqlcmd -S localhost -U sa -P 'VMurugan@2025#SQL' -Q "ALTER DATABASE [VMuruganGoldTrading] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE IF EXISTS [VMuruganGoldTrading];"
```

// turbo
### 3. Restore the Database (Run on VPS)
This command remaps the Windows file paths (C:\...) to Linux file paths (/var/opt/mssql/...).
```bash
sqlcmd -S localhost -U sa -P 'VMurugan@2025#SQL' -Q "RESTORE DATABASE [VMuruganGoldTrading] FROM DISK = N'/var/opt/mssql/data/VMurugan.bak' WITH MOVE 'VMuruganGoldTrading' TO '/var/opt/mssql/data/VMuruganGoldTrading.mdf', MOVE 'VMuruganGoldTrading_log' TO '/var/opt/mssql/data/VMuruganGoldTrading_log.ldf', REPLACE"
```

### 4. Verification & Sync (Run on VPS)
Confirm the tables are successfully restored and restart the API to pick up the new data.
```bash
sqlcmd -S localhost -U sa -P 'VMurugan@2025#SQL' -d VMuruganGoldTrading -Q "SELECT name FROM sys.tables"

# If tables are visible, restart the API
pm2 restart vmurugan-api
```

## Troubleshooting
If the restore fails with **"Logical file name not found"**, check the actual names inside the backup file:
```bash
sqlcmd -S localhost -U sa -P 'VMurugan@2025#SQL' -Q "RESTORE FILELISTONLY FROM DISK = N'/var/opt/mssql/data/VMurugan.bak'"
```
Use the names found in the `LogicalName` column for the `MOVE` parts of the restore command.

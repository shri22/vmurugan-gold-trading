@echo off
REM Monitor backend API requests in real-time
REM Run this on your Windows server

echo ========================================
echo VMurugan API Request Monitor
echo ========================================
echo.
echo Watching for transaction save requests...
echo Press Ctrl+C to stop
echo.

REM Tail the server logs (if using PM2)
pm2 logs vmurugan-api --lines 100 --raw

REM OR if running directly with node, check console output

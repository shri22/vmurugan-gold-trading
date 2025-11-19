# 🌐 Website Upload Instructions for Android App Links

## 📁 File to Upload: assetlinks.json

### 🎯 Upload Location
**Exact URL**: `https://vmuruganjewellery.co.in/.well-known/assetlinks.json`

### 📂 Directory Structure Required
```
vmuruganjewellery.co.in/
├── .well-known/          ← Create this directory
│   └── assetlinks.json   ← Upload the file here
├── index.html
└── other website files...
```

### 📋 Step-by-Step Upload Process

#### Method 1: cPanel File Manager
1. **Login to your hosting cPanel**
2. **Open File Manager**
3. **Navigate to public_html** (or your domain's root directory)
4. **Create folder**: `.well-known` (note the dot at the beginning)
5. **Enter the .well-known folder**
6. **Upload**: `assetlinks.json` file
7. **Set permissions**: 644 (read permissions for all)

#### Method 2: FTP Upload
1. **Connect via FTP** to your hosting
2. **Navigate to domain root** (usually public_html)
3. **Create directory**: `.well-known`
4. **Upload file**: `assetlinks.json` to `.well-known/` folder
5. **Set file permissions**: 644

#### Method 3: SSH/Terminal
```bash
# Connect to your server via SSH
ssh username@vmuruganjewellery.co.in

# Navigate to website root
cd public_html  # or your domain's root directory

# Create .well-known directory
mkdir -p .well-known

# Upload assetlinks.json to .well-known/
# (use scp, rsync, or copy the file content)

# Set proper permissions
chmod 644 .well-known/assetlinks.json
chmod 755 .well-known
```

### ✅ Verification Steps

#### Test 1: Direct URL Access
```bash
# Test the file is accessible
curl https://vmuruganjewellery.co.in/.well-known/assetlinks.json

# Expected response: JSON content with app details
```

#### Test 2: Browser Test
1. **Open browser**
2. **Navigate to**: `https://vmuruganjewellery.co.in/.well-known/assetlinks.json`
3. **Should display**: JSON content (not 404 error)

#### Test 3: Google's Asset Links Tester
1. **Visit**: https://developers.google.com/digital-asset-links/tools/generator
2. **Enter domain**: `vmuruganjewellery.co.in`
3. **Enter package**: `com.vmurugan.digi_gold`
4. **Test verification**

### 🔧 Common Issues & Solutions

#### Issue 1: 404 Not Found
- **Check**: Directory name is `.well-known` (with dot)
- **Check**: File name is exactly `assetlinks.json`
- **Check**: File is in the correct directory

#### Issue 2: Permission Denied
- **Set file permissions**: 644
- **Set directory permissions**: 755
- **Check**: Web server can read the file

#### Issue 3: Wrong Content-Type
- **Ensure**: Server serves .json files with `application/json` content-type
- **Add to .htaccess** if needed:
```apache
<Files "assetlinks.json">
    Header set Content-Type "application/json"
</Files>
```

### 📞 Contact Your Hosting Provider If:
- You can't access cPanel/FTP
- You need help creating directories
- File permissions are restricted
- Server configuration issues

### ⏰ Timeline
- **File upload**: 5-10 minutes
- **DNS propagation**: 0-24 hours
- **Google verification**: 24-48 hours
- **Play Console update**: 1-3 days

### 🎯 Success Indicators
✅ **File accessible via browser**
✅ **JSON content displays correctly**
✅ **Google Asset Links tester passes**
✅ **Play Console shows "Domain verified"**

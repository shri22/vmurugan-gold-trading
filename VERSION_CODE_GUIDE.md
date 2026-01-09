# Version Code Management - Quick Reference

**Current Version:** 1.4.1+32  
**Last Updated:** January 09, 2026, 19:15 IST

---

## ⚠️ Important: Version Codes Cannot Be Deleted

Once a version code is uploaded to Google Play Console (even as a draft), it is **permanently registered** and cannot be removed or reused.

### Version History

| Version Code | Status | Notes |
|--------------|--------|-------|
| 30 | ❌ Used | Already used in Play Console |
| 31 | ❌ Used | Already used in App Store/Play Console |
| **32** | ✅ **Current** | **Ready for upload** |

---

## Current Build Details

- **Version Name:** 1.4.1
- **Version Code:** 32
- **File:** `app-release.aab`
- **Location:** `build/app/outputs/bundle/release/app-release.aab`
- **Size:** 49 MB
- **Build Time:** December 12, 2025, 23:36 IST
- **Features:** ✅ 16 KB page size support, ✅ Release signed, ✅ Optimized

---

## Why Version Codes Cannot Be Removed

Google Play Console maintains a permanent record of all version codes to:

1. **Prevent Conflicts:** Ensures no two builds have the same version code
2. **Track History:** Maintains audit trail of all uploads
3. **User Updates:** Prevents confusion in the update system
4. **Rollback Safety:** Allows safe rollback to previous versions

### What This Means

- ❌ **Cannot delete** version codes from Play Console
- ❌ **Cannot reuse** version codes (even if deleted from draft)
- ✅ **Must increment** version code for each new upload
- ✅ **Can skip** version codes (e.g., jump from 18 to 20 if needed)

---

## How to Increment Version Code

### Method 1: Edit pubspec.yaml (Recommended)

```yaml
# Current
version: 1.3.2+19

# For next release, change to:
version: 1.3.2+20  # or 1.3.3+20 if updating version name
```

### Method 2: Command Line

```bash
# Edit the version
nano pubspec.yaml

# Then rebuild
~/flutter/bin/flutter build appbundle --release
```

---

## Version Naming Convention

Format: `versionName+versionCode`

**Example:** `1.3.2+19`
- **1.3.2** = Version Name (shown to users)
- **19** = Version Code (internal, must always increase)

### Version Name Guidelines

- **Major.Minor.Patch** format (e.g., 1.3.2)
- **Major:** Breaking changes (1.0.0 → 2.0.0)
- **Minor:** New features (1.3.0 → 1.4.0)
- **Patch:** Bug fixes (1.3.2 → 1.3.3)

### Version Code Guidelines

- **Must be an integer**
- **Must always increase** with each upload
- **Cannot skip backwards**
- **Can skip forward** (e.g., 19 → 25 is OK)

---

## Common Scenarios

### Scenario 1: Uploaded Wrong Build
**Problem:** Uploaded version 18 without 16 KB support  
**Solution:** ✅ Increment to 19 and rebuild (what we did)  
**Cannot Do:** ❌ Delete version 18 and reuse it

### Scenario 2: Need to Fix a Bug
**Current:** Version 1.3.2+19  
**Solution:** 
- Fix the bug in code
- Update to `1.3.3+20`
- Rebuild and upload

### Scenario 3: Major Update
**Current:** Version 1.3.2+19  
**Solution:**
- Update to `2.0.0+20`
- Rebuild and upload

---

## Quick Commands

### Check Current Version
```bash
grep "version:" pubspec.yaml
```

### Update to Next Version (Manual)
```bash
# Edit pubspec.yaml and change version line
# Then rebuild:
~/flutter/bin/flutter build appbundle --release
```

### Verify Built Version
```bash
# Check the AAB file timestamp
ls -lh build/app/outputs/bundle/release/app-release.aab
```

---

## Best Practices

### ✅ Do's

1. **Always increment** version code before uploading
2. **Keep track** of which versions are uploaded
3. **Document changes** in release notes
4. **Test thoroughly** before uploading
5. **Use meaningful version names** (1.3.2, not 1.0.0 forever)

### ❌ Don'ts

1. **Don't reuse** version codes
2. **Don't skip testing** just to upload quickly
3. **Don't forget** to update release notes
4. **Don't upload** without checking for warnings
5. **Don't panic** if you upload wrong version - just increment and rebuild

---

## Troubleshooting

### Error: "Version code X has already been used"

**Solution:**
1. Open `pubspec.yaml`
2. Find the line: `version: 1.3.2+X`
3. Change X to X+1 (e.g., 19 → 20)
4. Save file
5. Run: `~/flutter/bin/flutter build appbundle --release`
6. Upload new AAB

### Error: "Version code must be higher than Y"

**Solution:**
- Your version code must be higher than Y
- Update to Y+1 or higher
- Rebuild and upload

---

## Current Status Summary

✅ **Version 1.3.2+19 is ready for upload**

**Includes:**
- ✅ 16 KB page size support
- ✅ Release signing
- ✅ Code optimization
- ✅ ProGuard obfuscation
- ✅ All architectures

**Next Steps:**
1. Upload `app-release.aab` to Play Console
2. Add release notes
3. Publish to production

---

## For Next Release

When you need to create the next release:

1. **Update version in pubspec.yaml:**
   ```yaml
   version: 1.3.3+20  # or appropriate version
   ```

2. **Rebuild:**
   ```bash
   ~/flutter/bin/flutter build appbundle --release
   ```

3. **Upload to Play Console**

---

## Reference Links

- **Current AAB:** `build/app/outputs/bundle/release/app-release.aab`
- **Build Guide:** `PRODUCTION_AAB_BUILD.md`
- **16KB Fix:** `16KB_PAGE_SIZE_FIX.md`
- **Release Notes:** `RELEASE_NOTES.md`

---

**Remember:** Version codes are permanent. Always increment, never reuse! 🚀

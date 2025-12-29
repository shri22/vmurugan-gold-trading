# Security Implementation Plan

## Overview
This document outlines the implementation of 7 critical security fixes for the VMurugan Gold Trading application.

## Fixes to Implement

### ✅ Fix 1: Secure Admin Authentication with JWT
**Status:** Ready to implement
- Remove hardcoded credentials from `index.html`
- Implement JWT-based authentication
- Add token validation middleware on backend
- Store admin credentials in environment variables
- Implement token refresh mechanism

### ✅ Fix 2: Backend Admin Token Validation
**Status:** Ready to implement
- Create middleware to validate admin-token header
- Apply middleware to all admin routes
- Return 401 for invalid/missing tokens
- Log unauthorized access attempts

### ✅ Fix 3: SQL Injection Prevention
**Status:** Ready to implement
- Audit all SQL queries in `server.js`
- Replace string concatenation with parameterized queries
- Use `mssql` library's prepared statements
- Focus on user-input endpoints (search, filters, IDs)

### ✅ Fix 4: Restrict CORS Configuration
**Status:** Ready to implement
- Change from wildcard `*` to specific origins
- Use environment variable for allowed origins
- Support multiple origins (admin portal, customer app)
- Add credentials support for cookies/auth headers

### ✅ Fix 5: Rate Limiting on Critical Endpoints
**Status:** Ready to implement
- Implement rate limiting for payment endpoints
- Add rate limiting for authentication endpoints
- Add rate limiting for OTP generation
- Use `express-rate-limit` library
- Configure different limits per endpoint type

### ✅ Fix 6: Environment Variables for All Secrets
**Status:** Ready to implement
- Create `.env.example` template
- Move all secrets to `.env` file:
  - Database credentials
  - Admin credentials
  - JWT secret
  - API keys
  - CORS origins
- Update code to read from `process.env`
- Add `.env` to `.gitignore`

### ✅ Fix 7: HMAC Request Signing for API Calls
**Status:** Ready to implement
- Generate customer-specific API keys
- Implement HMAC signature generation on Flutter app
- Implement HMAC signature verification on backend
- Add timestamp validation to prevent replay attacks
- Store API keys securely in database

## Implementation Order

1. **Fix 6** - Environment Variables (Foundation)
2. **Fix 1** - Admin Authentication with JWT
3. **Fix 2** - Backend Admin Token Validation
4. **Fix 4** - CORS Configuration
5. **Fix 3** - SQL Injection Prevention
6. **Fix 5** - Rate Limiting
7. **Fix 7** - HMAC Request Signing

## Files to Modify

### Backend (`sql_server_api/`)
- `server.js` - Main API file
- `.env` - New file for secrets
- `.env.example` - Template for environment variables
- `package.json` - Add new dependencies

### Frontend (`admin_portal/`)
- `index.html` - Remove hardcoded credentials, add JWT login

### Flutter App (`lib/`)
- `lib/core/config/api_config.dart` - Add HMAC signing
- `lib/core/services/api_service.dart` - Implement request signing
- `lib/core/utils/hmac_helper.dart` - New file for HMAC utilities

## Dependencies to Add

```json
{
  "jsonwebtoken": "^9.0.2",
  "express-rate-limit": "^7.1.5",
  "dotenv": "^16.3.1"
}
```

## Testing Checklist

- [ ] Admin login with JWT works
- [ ] Invalid admin tokens are rejected
- [ ] CORS only allows specified origins
- [ ] SQL injection attempts are blocked
- [ ] Rate limiting triggers after threshold
- [ ] Environment variables load correctly
- [ ] HMAC signature validation works
- [ ] Invalid signatures are rejected
- [ ] Replay attacks are prevented

## Rollback Plan

1. Keep backup of original `server.js`
2. Keep backup of original `index.html`
3. Test each fix individually before moving to next
4. Document any breaking changes

## Notes

- All changes are backward compatible except HMAC (requires app update)
- Admin portal will require re-login after JWT implementation
- Rate limiting may affect legitimate high-frequency users
- HMAC implementation requires Flutter app update and redeployment

---

**Created:** 2025-12-26
**Last Updated:** 2025-12-26

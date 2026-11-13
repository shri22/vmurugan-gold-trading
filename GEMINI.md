# VMurugan Gold Trading - Production Safety & Operations Guidelines

## ⚠️ ABSOLUTE MANDATORY CONSTRAINTS FOR AI ASSISTANTS & AUTOMATION

1. **PROHIBITION ON DUMMY / TEST DATA IN PRODUCTION:**
   - Real money (INR) and physical gold/silver weights are tracked in this system.
   - NEVER insert, create, modify, or test dummy transactions, schemes, or customer records (e.g., `ORD_TEST`, `ORD_NEW`, `TEST_...`, mock phones) directly in the production database (`VMuruganGoldTrading` on `193.203.160.3`) or via production API endpoints (`prodapi.vmuruganjewellery.co.in`).
   - All testing must be conducted locally using mock test fixtures or separate test environments.

2. **MANDATORY USER CONFIRMATION BEFORE ANY PRODUCTION ACTION:**
   - Production Host: `193.203.160.3` (`srv1236074`) / `prodapi.vmuruganjewellery.co.in`.
   - AI assistants MUST NEVER execute commands against the production server (SSH, SCP, PM2 restarts, database mutations, deployments) autonomously.
   - Every single action affecting the production server REQUIRES explicit prior confirmation from Shrikanth in the chat prompt.
   - Never assume previous permissions apply to new deployments or server alterations.

3. **INVESTIGATE & REPORT FIRST (DO NOT AUTO-FIX):**
   - Whenever an issue, bug, discrepancy, or unexpected behavior occurs:
     1. Perform read-only investigation.
     2. Identify the root cause.
     3. Present a clear root-cause analysis and proposed plan to Shrikanth.
     4. WAIT for Shrikanth's explicit approval before applying fixes to code or databases.

4. **FINANCIAL INTEGRITY & ZERO FAKE CREDITING:**
   - Customer balances (gold grams, silver grams, invested capital) must ALWAYS accurately reflect genuine bank/payment gateway verified receipts.
   - Transactions cannot be marked `SUCCESS` without automated cryptographic gateway webhook/API verification or authenticated admin offline showroom entry.
   - Never execute manual SQL updates that credit gold/silver without verified source-of-truth payment records.

5. **SSH & DEPLOYMENT SECURITY:**
   - The production server access is strictly restricted. Never modify `/root/.ssh/authorized_keys` or bypass authentication without explicit instruction.

# 🔥 FIREBASE SETUP GUIDE FOR VMURUGAN

## Step 1: Create Firebase Project

1. **Go to Firebase Console:**
   ```
   https://console.firebase.google.com/
   ```

2. **Create New Project:**
   - Click "Create a project"
   - Project name: `vmurugan-gold-trading`
   - Enable Google Analytics: Yes (recommended)
   - Choose Analytics account or create new
   - Click "Create project"

## Step 2: Set Up Firestore Database

1. **Navigate to Firestore:**
   - In Firebase console, click "Firestore Database"
   - Click "Create database"

2. **Choose Security Rules:**
   - Select "Start in test mode" (for now)
   - Choose location: `asia-south1` (for India)
   - Click "Done"

3. **Update Security Rules:**
   Go to "Rules" tab and replace with:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Allow read/write for authenticated users
       match /{document=**} {
         allow read, write: if true; // Temporary - will secure later
       }
     }
   }
   ```

## Step 3: Get Configuration

### **Get Project ID:**
1. **Project Settings:** Click gear icon → "Project settings"
2. **Copy Project ID** from the top of the page

### **Get Web API Key (IMPORTANT):**

#### **Option A: Add Web App (Recommended)**
1. **In Project Settings**, scroll to "Your apps" section
2. **If no web app exists**: Click "Add app" → Web icon (</>)
3. **App nickname**: `vmurugan-web`
4. **Don't check** "Also set up Firebase Hosting"
5. **Click "Register app"**
6. **Copy the apiKey** from the config shown:
   ```javascript
   const firebaseConfig = {
     apiKey: "AIzaSyC1234567890abcdefghijklmnopqrstuvwxyz", // ← This is your API Key
     projectId: "vmurugan-gold-trading-12345",
     // ... other config
   };
   ```

#### **Option B: From API Keys Section**
1. **Project Settings** → "General" tab
2. **Scroll to "Web API Key" section**
3. **Copy the key shown**

#### **Option C: Google Cloud Console**
1. **Go to**: https://console.cloud.google.com/
2. **Select your Firebase project**
3. **APIs & Services** → "Credentials"
4. **Copy the "Browser key (auto created by Firebase)"**

## Step 4: Update App Configuration

1. **Open:** `lib/core/services/firebase_service.dart`

2. **Replace these values:**
   ```dart
   static const String projectId = 'YOUR_PROJECT_ID_HERE';
   static const String apiKey = 'YOUR_API_KEY_HERE';
   ```

3. **Example:**
   ```dart
   static const String projectId = 'digi-gold-business-12345';
   static const String apiKey = 'AIzaSyC1234567890abcdefghijklmnopqrstuvwxyz';
   ```

## Step 5: Test Firebase Connection

1. **Build and run app**
2. **Register a test customer**
3. **Make a test transaction**
4. **Check Firestore console** - you should see:
   - `customers` collection with customer data
   - `transactions` collection with transaction data
   - `analytics` collection with events

## Step 6: Set Up Admin Access

1. **Create Admin User:**
   - Go to "Authentication" in Firebase console
   - Click "Get started"
   - Go to "Users" tab
   - Click "Add user"
   - Email: `your-admin-email@example.com`
   - Password: `your-secure-password`
   - Copy the **User UID**

2. **Update Security Rules:**
   Replace `YOUR_ADMIN_UID_HERE` in rules with your actual UID:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // VMUrugan customers data
       match /customers/{customerId} {
         allow read, write: if true; // Open for testing
       }

       // VMUrugan transactions
       match /transactions/{transactionId} {
         allow create: if true;
         allow read: if true;
       }

       // VMUrugan analytics
       match /analytics/{document} {
         allow create: if true;
         allow read: if true;
       }

       // Admin-only access (replace with your admin UID)
       match /{document=**} {
         allow read, write: if request.auth != null &&
                              request.auth.uid == "YOUR_ADMIN_UID_HERE";
       }
     }
   }
   ```

## Step 7: Admin Dashboard Access

1. **In app, go to menu → Admin Dashboard**
2. **Enter admin token:** `DIGI_GOLD_ADMIN_2025`
3. **View your business data:**
   - Customer list
   - Transaction history
   - Business analytics

## Step 8: Production Security (Later)

When ready for production:

1. **Secure Rules:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Customers can only access their own data
       match /customers/{customerId} {
         allow read, write: if request.auth != null && 
                              request.auth.uid == customerId;
       }
       
       // Transactions require authentication
       match /transactions/{transactionId} {
         allow create: if request.auth != null;
         allow read: if request.auth != null && 
                        resource.data.customer_phone == request.auth.token.phone_number;
       }
       
       // Admin access only
       match /{document=**} {
         allow read, write: if request.auth != null && 
                              request.auth.uid == "YOUR_ADMIN_UID";
       }
     }
   }
   ```

2. **Enable Authentication:**
   - Phone number authentication for customers
   - Email authentication for admin

## Troubleshooting

### Common Issues:

1. **"Permission denied" errors:**
   - Check Firestore rules
   - Ensure project ID is correct

2. **"Project not found":**
   - Verify project ID in firebase_service.dart
   - Check if Firestore is enabled

3. **API key errors:**
   - Verify API key in firebase_service.dart
   - Check if Web API is enabled

### Support:
- Firebase Documentation: https://firebase.google.com/docs
- Firestore Rules: https://firebase.google.com/docs/firestore/security/rules-conditions

## Next Steps After Setup:

1. ✅ Test customer registration
2. ✅ Test gold purchase flow
3. ✅ Verify data in Firestore console
4. ✅ Test admin dashboard
5. ✅ Plan migration to custom server (when ready)

**Your Firebase backend is ready for business! 🚀**

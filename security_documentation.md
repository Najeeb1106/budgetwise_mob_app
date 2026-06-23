# Security Hardening Documentation

This document explains the security architecture implemented in BudgetWise to safeguard sensitive financial data and user preferences.

## 1. Database Encryption via SQLCipher

The primary SQLite database (`budgetwise.sqlite`) contains all transactions, categories, savings goals, contributions, and monthly budgets. To prevent unauthorized access to this database file (e.g., via device backups, rooted/jailbroken devices, or physical access), we have encrypted it using **SQLCipher**.

### Key Generation and Storage:
- At startup, the app checks for a cryptographically secure random database key (`secure_db_key`) in **Flutter Secure Storage**.
- If the key does not exist, a cryptographically secure UUID is generated and saved using platform-level keychain APIs (Keystore on Android, Keychain on iOS/macOS).
- The key is passed directly to SQLCipher via a SQLite PRAGMA statement before opening:
  ```sql
  PRAGMA key = '<secure_key>';
  ```

## 2. Secure Local Storage for Sensitive Settings

All user preferences, security preferences, and financial metadata have been moved out of plain-text JSON files (`budgetwise_settings.json`) and into **Flutter Secure Storage**:

- **Estimated Income:** Encrypted at rest.
- **Username:** Encrypted at rest.
- **Biometric Preferences:** Encrypted at rest.
- **Include Salary in Balance:** Encrypted at rest.

### Data Migration:
During startup, the application checks if the legacy plain-text `budgetwise_settings.json` file exists. If found, it reads the settings, migrates them to secure storage, and securely deletes the plain-text file to ensure no plain-text traces of financial settings remain on local storage.

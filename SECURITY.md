# Security Policy & Vulnerability Disclosure

**Document Status:** Official Security Disclosure Policy  
**Maintained by:** GupShupGo Security & Engineering Team  
**Last Updated:** October 31, 2026

---

## 🛡️ Our Commitment to Security

At GupShupGo, we take the security of our users and their communications with extreme seriousness. We welcome reports from independent security researchers, academic cryptographers, and white-hat hackers who help us identify and resolve vulnerabilities.

---

## 📦 Supported Versions

Security updates and patches are actively maintained for the following releases:

| Version | Supported | Status |
| :--- | :---: | :--- |
| **1.2.3 (Build 61)** | ✅ Yes | Current Production Release |
| **1.2.2 (Build 60)** | ✅ Yes | Active Support |
| **1.2.1 (Build 59)** | ⚠️ Deprecated | Please update to 1.2.3 |
| **< 1.2.0** | ❌ No | Unsupported |

We strongly advise all users to remain on the latest version available on Google Play to ensure all cryptographic patches and security mitigations are present.

---

## 🚨 Reporting a Vulnerability

If you believe you have found a security vulnerability in GupShupGo (client app, cryptography implementation, Cloud Functions backend, or mesh protocol), please follow our responsible disclosure process:

### 1. Primary Reporting Channel
* **Email:** Send your report directly to **`support@gupshupgo.app`**
* **Alternative:** You may open a confidential draft advisory via [GitHub Security Advisories](https://github.com/vansh-121/GupShupGo-Public/security/advisories/new).

### 2. What to Include in Your Report
To help us triage and reproduce the issue rapidly, please provide:
* **Description:** A detailed explanation of the vulnerability and its potential security impact.
* **Affected Component:** E.g., Android client, Signal protocol implementation, Cloud Functions endpoint, Firestore security rule.
* **Proof of Concept (PoC):** Step-by-step reproduction instructions, sample payloads, or scripts demonstrating the exploit.
* **Environment:** Device model, OS version (Android/iOS), and GupShupGo build number.
* **Mitigation (Optional):** Any recommended remediation steps.

> ⚠️ **Important:** Please do **NOT** open public GitHub issues or discuss security vulnerabilities publicly on social media or forums until our team has investigated and released a patch.

---

## ⏱️ Response Timeframes & SLOs

We adhere to the following Service Level Objectives (SLOs) for security reports:

* **Initial Acknowledgment:** Within **24 to 48 hours** of report receipt.
* **Triage & Validation:** Within **72 hours**.
* **Remediation & Patching:** High-severity issues are typically patched and deployed within **7 to 14 business days**.
* **Public Disclosure:** Coordinated disclosure after the patch has reached production and users have had sufficient time to update.

---

## 🎯 Scope & Boundaries

### In Scope:
* Cryptographic flaws or weaknesses in key exchange, double ratcheting, or session recovery.
* Authentication bypasses, impersonation, or unauthorized access to user accounts.
* Circumvention of end-to-end encryption or plaintext leakage across network boundaries.
* Remote Code Execution (RCE) or privilege escalation within the client.
* Flaws in Firestore security rules allowing unauthorized cross-user reads or writes.
* Flaws in Cloud Functions endpoints allowing denial of service or push manipulation.

### Out of Scope:
* Attacks requiring physical access to a rooted, unlocked device where the attacker already has root control.
* Social engineering or phishing targeting GupShupGo users or staff.
* Distributed Denial of Service (DDoS) against third-party upstream providers (Firebase, Google Cloud, Agora).
* Vulnerabilities in third-party services outside of our control without a direct, actionable exploit against GupShupGo.
* Automated scanner reports without proof of actual exploitability.

---

## 🏆 Hall of Fame & Acknowledgments

We believe in recognizing researchers who help keep GupShupGo secure. With your consent:
* You will be credited in our **Security Hall of Fame** and release notes.
* For eligible high-impact vulnerabilities, we offer custom swag and honorary recognition from the GupShupGo team.

Thank you for helping us keep private communications private!


# Security Policy

## Supported Versions

We actively support the following versions of Secvault with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 3.1.x   | :white_check_mark: |
| 3.0.x   | :white_check_mark: |
| < 3.0   | :x:                |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please report security vulnerabilities by emailing **unnikrishnan.kp@bigbinary.com**.

You should receive a response within 48 hours. If the issue is confirmed, we will release a patch as soon as possible depending on complexity but typically within 7 days.

### What to Include in Your Report

Please include the following information in your vulnerability report:

- Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit the issue

This information will help us triage your report more quickly.

## Security Best Practices

When using Secvault in your applications, please follow these security best practices:

### 1. File Permissions
- Ensure your secrets files (`config/secrets.yml`, etc.) have restrictive file permissions (600 or 640)
- Never commit secrets files to version control
- Use `.gitignore` to exclude secrets files from your repository

### 2. Environment Separation
- Use different secrets files for different environments (development, staging, production)
- Never use production secrets in development or testing environments
- Implement proper environment-specific configuration

### 3. Secret Management
- Rotate secrets regularly
- Use strong, randomly generated secrets
- Avoid hardcoding secrets in application code
- Consider using external secret management services for production environments

### 4. Access Control
- Limit access to secrets files to only necessary personnel and processes
- Use proper deployment practices that don't expose secrets in logs or process lists
- Implement proper access controls in your deployment infrastructure

### 5. Monitoring and Auditing
- Monitor access to secrets files
- Implement logging for secrets access (without logging the actual secret values)
- Regular security audits of your secrets management practices

## Dependencies and Supply Chain Security

Secvault has minimal dependencies to reduce attack surface:

- **Rails**: We require Rails >= 7.1.0 and stay updated with security patches
- **Zeitwerk**: Used for autoloading, maintained by the Rails core team

We regularly monitor our dependencies for security vulnerabilities and update them promptly when security issues are discovered.

## Security Considerations

### Hot Reload Feature
The hot reload feature (`reload_secrets!`) is designed for development environments only. It should not be enabled in production as it can potentially expose secrets through memory dumps or debugging tools.

### Rails Integration
Secvault integrates deeply with Rails' secrets system. While this provides seamless functionality, it's important to understand that secrets are loaded into memory and may be visible to processes with sufficient privileges.

### File System Security
Secvault reads secrets from the file system. Ensure your deployment environment has proper file system security controls in place.

## Acknowledgments

We appreciate the security research community and responsible disclosure. Contributors who report valid security vulnerabilities will be acknowledged in our release notes (unless they prefer to remain anonymous).

## Contact

For any security-related questions or concerns, please contact:

**Email**: unnikrishnan.kp@bigbinary.com  
**Project**: https://github.com/unnitallman/secvault

---

*This security policy is effective as of the date of the latest commit to this file and applies to all current and future versions of Secvault.*
# Security Policy

## Supported Versions

This repository is a Nix packaging wrapper. The latest commit on the default branch is the only supported version.

## Reporting a Vulnerability

Please report security vulnerabilities privately via GitHub Security Advisories:

1. Go to the repository's **Security** tab.
2. Click **Report a vulnerability**.
3. Provide:
   - A description of the issue
   - Steps to reproduce
   - Potential impact
   - Any suggested mitigations

You will receive an initial response within 7 days. If the report is confirmed, a fix will be prepared privately and released with an advisory.

Please do **not** open public issues for security problems.

## Scope

This repository is a Nix packaging wrapper for third-party Call of Duty client software fetched at runtime from the upstream projects' own servers. Security issues within the Plutonium or t7x clients themselves must be reported to those upstream projects. This repo's security scope covers:

- Build-time supply-chain issues (unpinned inputs, missing hash verification)
- Misconfigured CI secrets or tokens
- Malicious flake output or launcher-wrapper surface

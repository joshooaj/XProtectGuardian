# XProtectGuardian

[![Certificate Tests](https://github.com/joshooaj/XProtectGuardian/actions/workflows/test-certificates.yml/badge.svg)](https://github.com/joshooaj/XProtectGuardian/actions/workflows/test-certificates.yml)
[![Milestone VMS Tests](https://github.com/joshooaj/XProtectGuardian/actions/workflows/test-milestone.yml/badge.svg)](https://github.com/joshooaj/XProtectGuardian/actions/workflows/test-milestone.yml)

## Introduction

This repo is intended to demonstrate a create way to automate your infrastructure
monitoring using GitHub with a self-hosted GitHub Actions runner to execute a
collection of Pester tests written in PowerShell.

Here's a list of the different technologies used in this demonstration...

1. GitHub for source control.
2. Automated script execution using GitHub Actions with a self-hosted runner.
3. Docker for running our GitHub Actions runner in a Windows container.
4. PowerShell as our shell of choice.
5. Pester as our test framework.
6. MilestonePSTools as a means of communicating with a Milestone VMS.

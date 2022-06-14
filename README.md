# XProtectGuardian

[![Milestone VMS Tests](https://github.com/joshooaj/XProtectGuardian/actions/workflows/test-milestone.yml/badge.svg)](https://www.joshooaj.com/XProtectGuardian/)

**Important**: This repository is provided as-is, as a dev connect sample. It
does not represent production-ready code and should be used for inspiration only.
I will not be accepting pull requests or issues, but you are welcome to contact
me for more detail if you'd like to learn more about some aspect of the project
or presentation.

## Introduction

Hi! More and more often I find myself communicating with customers who have an
expectation that all software they deploy and manage can be done in a scalable
way, with some elements of CI/CD or continuous integration / continuous
deployment, and/or IaS or infrastructure-as-code.

We have been building and using the MilestonePSTools PowerShell module for three
years now, and I have found it to be an excellent tool for rapidly building tools
for reporting and bulk configuration. This repository is intended to be an
example of one opinionated way in which you could implement a form of automated
monitoring and reporting of a Milestone VMS and the state of the system and
configuration.

You might implement something similar to this to monitor the health of the VMS
such as when cameras are offline, when video retention expectations are unmet, or
if specific services or components of the system are unexpectedly unavailable. You
might also define configuration expectations such as all cameras should be
assigned to a storage configuration with 90 days retention, all cameras should
have a separate live stream and recorded stream, or only a specific set of users
should be in the Administrator's role.

## What is included in this repo?

As I said above, this repository is an _opinionated_ example of just one way you
might implement a form of automated monitoring and reporting. Alternatives might
include something as simple as setting up a scheduled task in Windows, or as
complex as a Windows Service or a MIP Plugin with administrative/configurable
elements in the Management Client and a background plugin to perform the
monitoring.

I spend a lot of time in PowerShell and I recognize it as a powerful
tool for both developers and system administrators. And in the world of advanced
PowerShell scripting and module development, tools like Pester for testing, and
GitHub for source control and automation are popular, and in the case of GitHub
and GitHub Actions, it is anywhere from free to very inexpensive to use for
something like this.

Here's a list of the different tools used in this repository. But as I said
earier, this is one way you could implement some form of automation against a
Milestone VMS and literally everything in the list below could be substituted
with the technology du jour. I hope you find something useful here, even if it
is nothing more than the _idea_ of implementing a form of automation to monitor
not just the health of a VMS but to also monitor for configuration drift or
unusual activity.

## Tools and technologies used in this repo

1. GitHub for source control.
2. Automated script execution using GitHub Actions with a self-hosted runner.
3. Docker for running our GitHub Actions runner in a Windows container in our
   own private, internet-connected network.
4. PowerShell as our shell of choice.
5. Pester as our test automation framework.
6. [MilestonePSTools](https://www.milestonepstools.com) as a means of communicating with a Milestone VMS from PowerShell.
7. Extent-Framework's [ExtentReports .NET CLI](https://github.com/extent-framework/extentreports-dotnet-cli) to generate a static website from the NUnit XML test results produced by Pester.
8. [MkDocs](https://www.mkdocs.org/) as a tool to deploy our static site to GitHub Pages.

## What I would change, given the time

Something like this should evolve with the environment, and the product over
time, and in that sense, there's no end to the things I would change over time.
But there are a couple specific items on my shortlist of things I would change
right away...

The first thing I would change is to move all PowerShell commands out of the
GitHub Action workflow YAML file, and use something like the [psake](https://github.com/psake/psake)
build automation PowerShell module, such that the YAML file merely invokes psake.
That way the PowerShell code is in a dedicated file which is easier to lint and
maintain. This is what we do with the MilestonePSTools module and the Azure
DevOps build pipeline - simply call `build.ps1 -Task Publish` and the Publish
psake task is executed after all the tasks it depends on automatically.

Second, I would expand on a set of "common sense" tests to validate
assumptions like "if a camera is in a 30 day storage configuration, it should
have 30 days of recordings", or "if a camera is recording on motion, it should
have detected motion in the last 24 hours".

Finally, depending on the environment and if Smart Client is commonly used by
the system administrators, I might consider generating alarms assigned to the
Administrator's role when a test fails. That way nobody is relying on seeing
a GitHub Actions failure email and the errors are displayed prominently in a
Milestone user interface already used by the team maintaining the installation.
Those alarms can be relatively easily produced using the `New-Alarm` and
`Send-Alarm` cmdlets from MilestonePSTools.

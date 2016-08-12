[![Open AS Communication Gateway](https://openas.org/assets/img/logo.png)](https://openas.org) 
## Open AS Communication Gateway

[![Travis CI](https://travis-ci.org/open-as-team/open-as-cgw.svg?branch=master)](https://travis-ci.org/open-as-team/open-as-cgw)
[![Docs](https://img.shields.io/badge/docs-in%20progress-orange.svg)](https://openas.org/docs)
[![Launchpad PPA](https://img.shields.io/badge/launchpad-ppa-green.svg)](https://code.launchpad.net/~open-as-team/+recipe/open-as-cgw-daily)
[![Docker](https://img.shields.io/badge/container-docker-green.svg)](https://hub.docker.com/r/openasteam/open-as-cgw/)

An open, integrated, easy-to-use, GUI-managed SMTP gateway scanning your emails for spam and viruses.

The Open AS Communication Gateway (or short 'AS') aims to be a all-in-one solution of an SMTP gateway: It accepts incoming email, performs various antispam-related processes like blacklisting, virus- and spam-scanning, and relays the mails to pre-defined SMTP servers. It's built upon an Ubuntu Server system, and can be entirely managed via a user-friendly web-frontend.

:warning: This branch is **UNSTABLE**! Support for Ubuntu 16.04 Xenial LTS in progress! :warning:

Main features
----------------------------------------

 * Recipient maps (specified manualy or fetched via LDAP, e.g. from MS AD)
 * White- and black-listing based on e-mail addresses, hostnames, domain-names, network ranges, CIDR ranges, reverse lookups and so on
 * Remote blacklisting (DNSBLs, URI DNSBLs, etc.)
 * Greylisting
 * Spam-scanning and scoring
 * Virus-scanning
 * Attachment scanning
 * Dynamic "Score Matrix", which lets you define what to do with mails from a certain origin, to what extent, at what score, etc.
 * End-User-maintainable email quarantining
 * A very pretty, user-friendly web GUI

Installation
----------------------------------------

Starting with the upcoming 2.2.0 release, we will provide pre-built virtual appliance images.

Please make sure to read the docs at https://wiki.openas.org.

Developers
----------------------------------------

Fork the repo and set-up a local development environment by executing

	/bin/bash ./lib/bin/set_dev_environment.sh

To start the GUI in development mode type:

	/usr/bin/perl ./gui/script/limesgui_server.pl

from within your local copy of the repositoy.

This will start a local webserver for accessing the GUI.
All changes on the code will be visible immediatly.

Resources
----------------------------------------
* Website: https://openas.org
* Docs:    https://openas.org/docs
* Forum:   https://forum.openas.org

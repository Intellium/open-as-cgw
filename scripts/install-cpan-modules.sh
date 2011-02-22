#!/bin/bash

CPAN_MODULES="
	Authen::Htpasswd
	Catalyst::Plugin::Authentication::Store::Htpasswd
	Catalyst::Plugin::FormValidator
	Catalyst::Plugin::FillInForm
	Catalyst::Plugin::Email
"

for MODULE in $CPAN_MODULES; do
	cpanp i $MODULE --notest
done

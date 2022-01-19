#!/usr/bin/bash
# this install script for mac only and uses tfwsitch instead of the tfenv
#
brew install aws-iam-authenticator
brew install jq
brew install tfswitch
brew install terragrunt
brew install warrensbox/tap/tgswitch
brew install direnv
direnv allow .
python3 -m pip install --user virtualenv
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt

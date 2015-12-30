#!/bin/bash

sudo apt-get update -y
sudo apt-get install -y curl
sudo curl -sSL https://get.docker.com/ | sh
sudo usermod -aG docker vagrant
sudo apt-get autoremove -y

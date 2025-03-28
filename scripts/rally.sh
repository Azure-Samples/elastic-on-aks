#!/bin/bash

set -eo pipefail

sudo apt update
sudo apt install -y openjdk-21-jdk python3-pip

pip3 install esrally

echo 'export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc


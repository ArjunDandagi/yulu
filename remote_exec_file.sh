#!/usr/bin/env bash
echo "hi"
echo "#####THE PRIVATE IP#####"
echo $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
echo "#####THE PUBLIC IP#####"
echo  $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

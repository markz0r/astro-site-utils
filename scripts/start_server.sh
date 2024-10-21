#!/bin/bash
set -e

# Check if httpd is running
systemctl is-active httpd || systemctl start httpd

# Check if httpd is enabled
systemctl is-enabled httpd || systemctl enable httpd
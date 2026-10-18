#!/bin/sh
# firewall-setup.sh — the worked example from
# "UFW for Mere Mortals", as a runnable script.
#
# Hardens a small server: default-deny incoming,
# rate-limited SSH, web ports open to everyone,
# a metrics port open to the LAN only, logging on.
#
# Run it as root (sudo sh firewall-setup.sh), and
# read chapter 4 first: it enables the firewall
# as its second-to-last step. Keep the session
# you ran it from open until you have proved you
# can log in from a second one.
set -e

# The defaults: doors closed unless a rule opens
# them; the machine itself may still call out.
ufw default deny incoming
ufw default allow outgoing

# SSH, rate-limited: repeated new connections
# from one address get refused for a while
# (chapter 7 explains how the counting works).
ufw limit 22/tcp

# The web ports, open to the world.
ufw allow 80/tcp
ufw allow 443/tcp

# A metrics endpoint the LAN may read and
# nobody else may (chapter 6).
ufw allow from 192.168.1.0/24 to any port 9100 proto tcp

# Log what gets blocked, at the low level.
ufw logging on

# The point of no easy return. Everything above
# this line only wrote configuration down; this
# line puts it in front of your traffic.
ufw enable

# Prove it: the running rules, numbered.
ufw status numbered

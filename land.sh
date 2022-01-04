#!/bin/sh

wget https://github.com/nkeonkeo/neko-relay-land/releases/latest/download/neko-relay_linux_amd64 -O /usr/bin/neko-relay || curl https://github.com/nkeonkeo/neko-relay-land/releases/latest/download/neko-relay_linux_amd64 -o /usr/bin/neko-relay
chmod +x /usr/bin/neko-relay
neko-relay -g init

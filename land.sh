#!/bin/sh

wget https://github.com/nkeonkeo/neko-relay-land/releases/latest/download/neko-relay_linux_amd64 -O /usr/bin/neko-relay || curl https://github.com/nkeonkeo/neko-relay-land/releases/latest/download/neko-relay_linux_amd64 -o /usr/bin/neko-relay
chmod +x /usr/bin/neko-relay
neko-relay -v && echo "neko-relay自定义隧道落地端安装成功！"
neko-relay -g init

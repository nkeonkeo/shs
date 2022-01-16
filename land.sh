#!/bin/sh
os=`uname -s | tr [:upper:] [:lower:]`
arch=`uname -m`

case ${arch} in
x86)
arch="386"
;;
x86_64)
arch="amd64"
;;
aarch64)
arch="arm64"
;;
esac
url="https://github.com/nkeonkeo/neko-relay-land/releases/latest/download/neko-relay_"${os}"_"${arch}
wget ${url} -O /usr/bin/neko-relay || curl https://github.com/nkeonkeo/neko-relay-land/releases/latest/download/neko-relay_linux_amd64 -o /usr/bin/neko-relay
chmod +x /usr/bin/neko-relay
neko-relay -v && echo "neko-relay自定义隧道落地端安装成功！"
if [ ! -d "/etc/neko-relay" ]; then
  neko-relay -g init
fi

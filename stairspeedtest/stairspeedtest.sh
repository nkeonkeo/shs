#!/bin/sh
wget http://neko.nkeo.top:1314/stairspeedtest/stairspeedtest_reborn_linux64.tar.gz
tar -xzvf stairspeedtest_reborn_linux64.tar.gz
sed -i 's/export_color_style=original/export_color_style=rainbow/g' /root/stairspeedtest/pref.ini
echo "[Unit]
Description=stairspeedtest

[Service]
ExecStart=/root/stairspeedtest/webgui.sh

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/stairspeedtest.service
systemctl daemon-reload
systemctl start stairspeedtest
systemctl enable stairspeedtest
rm stairspeedtest_reborn_linux64.tar.gz

#!/bin/sh
gw=$(ip a | grep inet6 | grep global | awk '{print $2}' | awk '{split($0,t,"::"); print t[1]"::1"}')
curl https://ispip.clang.cn/cmcc_ipv6.txt -Ls > cnv6.zone
curl https://ispip.clang.cn/cernet_ipv6.txt -Ls >> cnv6.zone
curl https://ispip.clang.cn/unicom_cnc_ipv6.txt -Ls >> cnv6.zone
curl https://ispip.clang.cn/chinatelecom_ipv6.txt -Ls >> cnv6.zone
for i in $(cat cnv6.zone ); do
    ip -6 route add $i via $gw
done

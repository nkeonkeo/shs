#!/usr/bin/env bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# RED='\033[0;31m'
# GREEN='\033[0;32m'
# YELLOW='\033[0;33m'
# SKYBLUE='\033[0;36m'
# PLAIN='\033[0m'

sh_ver="1.3.2.89"
github="raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master"

imgurl=""
headurl=""

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Green_font_prefix}[注意]${Font_color_suffix}"

check_kernel() {
  echo -e "${Tip} 鉴于1次人工检查有人不看，下面是2次脚本简易检查内核，开始匹配 /boot/vmlinuz-* 文件"
  ls /boot/vmlinuz-* | grep -v 'rescue' || echo -e "${Error} 没有匹配到 /boot/vmlinuz-* 文件，很有可能没有内核，谨慎重启，在确认没有内核的情况下，你可以尝试切换到不卸载内核选择30安装默认内核救急"
}

#检查系统
check_sys(){
	if [[ -f /etc/redhat-release ]]; then
		release="centos"
	elif cat /etc/issue | grep -q -E -i "debian"; then
		release="debian"
	elif cat /etc/issue | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
	elif cat /proc/version | grep -q -E -i "debian"; then
		release="debian"
	elif cat /proc/version | grep -q -E -i "ubuntu"; then
		release="ubuntu"
	elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
		release="centos"
    fi

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}
get_system_info() {
	cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
	freq=$( awk -F: '/cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	corescache=$( awk -F: '/cache size/ {cache=$2} END {print cache}' /proc/cpuinfo | sed 's/^[ \t]*//;s/[ \t]*$//' )
	tram=$( free -m | awk '/Mem/ {print $2}' )
	uram=$( free -m | awk '/Mem/ {print $3}' )
	bram=$( free -m | awk '/Mem/ {print $6}' )
	swap=$( free -m | awk '/Swap/ {print $2}' )
	uswap=$( free -m | awk '/Swap/ {print $3}' )
	up=$( awk '{a=$1/86400;b=($1%86400)/3600;c=($1%3600)/60} {printf("%d days %d hour %d min\n",a,b,c)}' /proc/uptime )
	load=$( w | head -1 | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//;s/[ \t]*$//' )
	opsy=$( get_opsy )
	arch=$( uname -m )
	lbit=$( getconf LONG_BIT )
	kern=$( uname -r )

	# disk_size1=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $2}' )
	# disk_size2=$( LANG=C df -hPl | grep -wvE '\-|none|tmpfs|overlay|shm|udev|devtmpfs|by-uuid|chroot|Filesystem' | awk '{print $3}' )
	# disk_total_size=$( calc_disk ${disk_size1[@]} )
	# disk_used_size=$( calc_disk ${disk_size2[@]} )

	tcpctrl=$( sysctl net.ipv4.tcp_congestion_control | awk -F ' ' '{print $3}' )

	virt_check
}
virt_check(){
	# if hash ifconfig 2>/dev/null; then
		# eth=$(ifconfig)
	# fi

	virtualx=$(dmesg) 2>/dev/null

    if  [ $(which dmidecode) ]; then
		sys_manu=$(dmidecode -s system-manufacturer) 2>/dev/null
		sys_product=$(dmidecode -s system-product-name) 2>/dev/null
		sys_ver=$(dmidecode -s system-version) 2>/dev/null
	else
		sys_manu=""
		sys_product=""
		sys_ver=""
	fi
	
	if grep docker /proc/1/cgroup -qa; then
	    virtual="Docker"
	elif grep lxc /proc/1/cgroup -qa; then
		virtual="Lxc"
	elif grep -qa container=lxc /proc/1/environ; then
		virtual="Lxc"
	elif [[ -f /proc/user_beancounters ]]; then
		virtual="OpenVZ"
	elif [[ "$virtualx" == *kvm-clock* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *KVM* ]]; then
		virtual="KVM"
	elif [[ "$cname" == *QEMU* ]]; then
		virtual="KVM"
	elif [[ "$virtualx" == *"VMware Virtual Platform"* ]]; then
		virtual="VMware"
	elif [[ "$virtualx" == *"Parallels Software International"* ]]; then
		virtual="Parallels"
	elif [[ "$virtualx" == *VirtualBox* ]]; then
		virtual="VirtualBox"
	elif [[ -e /proc/xen ]]; then
		virtual="Xen"
	elif [[ "$sys_manu" == *"Microsoft Corporation"* ]]; then
		if [[ "$sys_product" == *"Virtual Machine"* ]]; then
			if [[ "$sys_ver" == *"7.0"* || "$sys_ver" == *"Hyper-V" ]]; then
				virtual="Hyper-V"
			else
				virtual="Microsoft Virtual Machine"
			fi
		fi
	else
		virtual="Dedicated母鸡"
	fi
}

if ! type curl >/dev/null 2>&1; then
    echo 'curl 未安装 安装中'
	apt-get update && apt-get install curl -y || yum install curl -y
else
    echo 'curl 已安装，继续'
fi

if ! type wget >/dev/null 2>&1; then
    echo 'wget 未安装 安装中';
	apt-get update && apt-get install wget -y || yum install curl -y
else
    echo 'wget 已安装，继续'
fi

if ! type dmidecode >/dev/null 2>&1; then
    echo 'dmidecode 未安装 安装中';
	apt-get update && apt-get install dmidecode -y || yum install dmidecode -y
else
    echo 'dmidecode 已安装，继续'
fi

#检查依赖
if [[ "${release}" == "centos" ]]; then
		if (yum list installed ca-certificates | grep '202'); then
			echo 'CA证书检查OK'
		else
			echo 'CA证书检查不通过，处理中'
			yum install ca-certificates dmidecode -y
			update-ca-trust force-enable
			fi
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		if (apt list --installed | grep 'ca-certificates' | grep '202');then
			echo 'CA证书检查OK'
		else
			echo 'CA证书检查不通过，处理中'
			apt-get install ca-certificates dmidecode -y
			update-ca-certificates
		fi	
	fi
}

#检查Linux版本
check_version(){
	if [[ -s /etc/redhat-release ]]; then
		version=`grep -oE  "[0-9.]+" /etc/redhat-release | cut -d . -f 1`
	else
		version=`grep -oE  "[0-9.]+" /etc/issue | cut -d . -f 1`
	fi
	bit=`uname -m`
	# if [[ ${bit} = "x86_64" ]]; then
		# bit="x64"
	# else
		# bit="x32"
	# fi
}

#检查安装bbr的系统要求
check_sys_bbr(){
	check_version
	if [[ "${release}" == "centos" ]]; then
		if [[ ${version} = "7" ]]; then
			installbbr
		else
			echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
		fi
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		apt-get --fix-broken install -y && apt-get autoremove -y
		installbbr
	else
		echo -e "${Error} BBR内核不支持当前系统 ${release} ${version} ${bit} !" && exit 1
	fi
}

detele_kernel_head(){
	if [[ "${release}" == "centos" ]]; then
		rpm_total=`rpm -qa | grep kernel-headers | grep -v "${kernel_version}" | grep -v "noarch" | wc -l`
		if [ "${rpm_total}" > "1" ]; then
			echo -e "检测到 ${rpm_total} 个其余head内核，开始卸载..."
			for((integer = 1; integer <= ${rpm_total}; integer++)); do
				rpm_del=`rpm -qa | grep kernel-headers | grep -v "${kernel_version}" | grep -v "noarch" | head -${integer}`
				echo -e "开始卸载 ${rpm_del} headers内核..."
				rpm --nodeps -e ${rpm_del}
				echo -e "卸载 ${rpm_del} 内核卸载完成，继续..."
			done
			echo --nodeps -e "内核卸载完毕，继续..."
		else
			echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
		fi
	elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
		deb_total=`dpkg -l | grep linux-headers | awk '{print $2}' | grep -v "${kernel_version}" | wc -l`
		if [ "${deb_total}" > "1" ]; then
			echo -e "检测到 ${deb_total} 个其余head内核，开始卸载..."
			for((integer = 1; integer <= ${deb_total}; integer++)); do
				deb_del=`dpkg -l|grep linux-headers | awk '{print $2}' | grep -v "${kernel_version}" | head -${integer}`
				echo -e "开始卸载 ${deb_del} headers内核..."
				apt-get purge -y ${deb_del}
				echo -e "卸载 ${deb_del} 内核卸载完成，继续..."
			done
			echo -e "内核卸载完毕，继续..."
		else
			echo -e " 检测到 内核 数量不正确，请检查 !" && exit 1
		fi
	fi
}
installbbr(){
	kernel_version="5.9.6"
	bit=`uname -m`
	rm -rf bbr
	mkdir bbr && cd bbr
	
	if [[ "${release}" == "centos" ]]; then
		if [[ ${version} = "7" ]]; then
			if [[ ${bit} = "x86_64" ]]; then
				detele_kernel_head
				rpm -import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
                rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
                yum -y --enablerepo=elrepo-kernel install kernel-ml.x86_64 kernel-ml-devel.x86_64 kernel-ml-headers
			else
				echo -e "${Error} 不支持x86_64以外的系统 !" && exit 1
			fi
		fi
		
	elif [[ "${release}" == "ubuntu" || "${release}" == "debian" ]]; then
		if [[ ${bit} = "x86_64" || ${bit} = "aarch64" ]]; then
			kernel_version="5.14.9"
			detele_kernel_head
			headurl="http://sh.neko.sbs/bbr/linux-headers-5.14.9_5.14.9-1_amd64.deb"
			imgurl="http://sh.neko.sbs/bbr/linux-image-5.14.9_5.14.9-1_amd64.deb"
			echo -e "正在检查headers下载连接...."
			checkurl $headurl
			echo -e "正在检查内核下载连接...."
			checkurl $imgurl
			wget -N -O linux-headers-d10.deb $headurl
			wget -N -O linux-image-d10.deb $imgurl
			dpkg -i linux-image-d10.deb
			dpkg -i linux-headers-d10.deb
		else
			echo -e "${Error} 不支持x86_64及arm64/aarch64以外的系统 !" && exit 1	
		fi
	fi
	
	cd .. && rm -rf bbr	
	
	BBR_grub
	echo -e "${Tip} 内核安装完毕，请参考上面的信息检查是否安装成功,默认从排第一的高版本内核启动"
	check_kernel
}
BBR_grub(){
	if [[ "${release}" == "centos" ]]; then
        if [[ ${version} = "6" ]]; then
            if [ -f "/boot/grub/grub.conf" ]; then
				sed -i 's/^default=.*/default=0/g' /boot/grub/grub.conf
			elif [ -f "/boot/grub/grub.cfg" ]; then
				grub-mkconfig -o /boot/grub/grub.cfg
				grub-set-default 0
			elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
				grub-mkconfig -o /boot/efi/EFI/centos/grub.cfg
				grub-set-default 0
			elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
				grub-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
				grub-set-default 0	
			else
				echo -e "${Error} grub.conf/grub.cfg 找不到，请检查."
				exit
            fi
        elif [[ ${version} = "7" ]]; then
            if [ -f "/boot/grub2/grub.cfg" ]; then
				grub2-mkconfig -o /boot/grub2/grub.cfg
				grub2-set-default 0
			elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
				grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
				grub2-set-default 0
			elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
				grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
				grub2-set-default 0	
			else
				echo -e "${Error} grub.cfg 找不到，请检查."
				exit
            fi	
		elif [[ ${version} = "8" ]]; then
			if [ -f "/boot/grub2/grub.cfg" ]; then
				grub2-mkconfig -o /boot/grub2/grub.cfg
				grub2-set-default 0
			elif [ -f "/boot/efi/EFI/centos/grub.cfg" ]; then
				grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
				grub2-set-default 0
			elif [ -f "/boot/efi/EFI/redhat/grub.cfg" ]; then
				grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
				grub2-set-default 0	
			else
				echo -e "${Error} grub.cfg 找不到，请检查."
				exit
			fi
			grubby --info=ALL|awk -F= '$1=="kernel" {print i++ " : " $2}'
        fi
    elif [[ "${release}" == "debian" || "${release}" == "ubuntu" ]]; then
        /usr/sbin/update-grub
		#exit 1
    fi
}

#启用BBR+fq
startbbrfq(){
	remove_bbr_lotserver
	echo "net.core.default_qdisc=fq" > /etc/sysctl.d/99-sysctl.conf
	echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.d/99-sysctl.conf
	sysctl --system
	echo -e "${Info}BBR+FQ修改成功，重启生效！"
	check_kernel
}

remove_bbr_lotserver(){
	sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.core.default_qdisc/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.d/99-sysctl.conf
	sed -i '/net.ipv4.tcp_ecn/d' /etc/sysctl.conf
	sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
	sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
	sysctl --system
		
	rm -rf bbrmod
	
	if [[ -e /appex/bin/lotServer.sh ]]; then
		echo | bash <(wget -qO- https://git.io/lotServerInstall.sh) uninstall
	fi
	clear
	# echo -e "${Info}:清除bbr/lotserver加速完成。"
	# sleep 1s
}

check_sys
check_version
[[ ${release} != "debian" ]] && [[ ${release} != "ubuntu" ]] && [[ ${release} != "centos" ]] && echo -e "${Error} 本脚本不支持当前系统 ${release} !" && exit 1
clear
installbbr
startbbrfq
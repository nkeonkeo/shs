#!/bin/bash
# https://github.com/sjlleo/ehco.sh
# Version: 0.1
# Description: Ehco Tunnel configuration script
# Author: sjlleo
# Thank You For Using
#
#                    GNU GENERAL PUBLIC LICENSE
#                       Version 3, 29 June 2007
#
# Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
# Everyone is permitted to copy and distribute verbatim copies
# of this license document, but changing it is not allowed.

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

[[ $EUID -ne 0 ]] && echo -e "[Error]请以root用户或者sudo提权运行本脚本！" && exit 1

ehco_version="1.0.7"
ehco_conf_dir="/usr/local/ehco/"
CPUFrame=$(arch)
SysID=$(cat /etc/os-release | grep ^ID=)



# Color Settings
red_prefix='\033[0;31m'
yellow_prefix='\033[0;33m'
blue_prefix='\033[0;36m'
green_prefix='\033[0;32m'
plain_prefix='\033[0m'

python_model_check()
{
  if python3 -c "import $1" >/dev/null 2>&1
  then
      echo -e "1"
  else
      echo -e "0"
  fi
}

InitialEhco() {
    if [ ! -d $ehco_conf_dir ]; then
	    mkdir $ehco_conf_dir
    fi
    if [ ! -e "/usr/bin/ehco" ]; then
    	url="http://sh.neko.sbs/ehco.sh/ehco_1.1.0_linux_amd64"
    	echo -e "${blue_prefix}[Info]${plain_prefix} 开始下载ehco文件..."
    	wget -O /usr/bin/ehco $url &> /dev/null
    	if [ $? -ne 0 ]; then
    		echo -e "${blue_prefix}[Info]${plain_prefix} wget包缺失，开始安装wget"
    		InstallWget
    		wget -O /usr/bin/ehco $url &> /dev/null
    	fi
    	echo -e "${blue_prefix}[Done]${plain_prefix} 下载完成"
    	chmod +x /usr/bin/ehco
    	InitialEhcoConfigure
    	AddSystemService
	else
	    echo -e "${blue_prefix}[Info]${plain_prefix} 您已安装Ehco，无需重复安装"
    fi
}

InstallWget() {
	case ${SysID} in
	*centos*)
		echo -e "${blue_prefix}[Info]${plain_prefix} 安装wget包..."
		yum install wget -y &> /dev/null
		;;
	*debian*)
		echo -e "${blue_prefix}[Info]${plain_prefix} 更新APT源..."
		apt update &> /dev/null
		echo -e "安装wget包..."
		apt install wget -y &> /dev/null
		;;
	*ubuntu*)
		echo -e "${blue_prefix}[Info]${plain_prefix} 更新APT源..."
		apt update &> /dev/null
		echo -e "${blue_prefix}[Info]${plain_prefix} 安装wget包..."
		apt install wget -y &> /dev/null
		;;
	*)
		echo -e "[Error]未知系统，请自行安装wget"
		exit 1
		;;
	esac
}

InitialEhcoConfigure() {
		echo -e "
{	
	\"web_port\": 9000,
	\"web_token\": \"leo123leo\",
	\"enable_ping\": false,
	\"relay_configs\":[
	]
}" > $ehco_conf_dir/ehco.json

    systemctl restart ehco &> /dev/null

	echo -e "${green_prefix}[Success]${plain_prefix}已初始化配置文件"
}

AddSystemService() {
	case ${SysID} in
	*centos*)
		systemctlDIR="/usr/lib/systemd/system/"
		;;
	*debian*)
		systemctlDIR="/etc/systemd/system/"
		;;
	*ubuntu*)
		systemctlDIR="/etc/systemd/system/"
		;;
	*)
		echo -e "[Error]未知系统，请自行添加Systemctl"
		exit 1
		;;
	esac
	echo -e "[Unit]
Description=Ehco Tunnel Service
After=network.target

[Service]
Type=simple
Restart=always

WoringDirectory=/usr/bin/ehco
ExecStart=/usr/bin/ehco -c /usr/local/ehco/ehco.json

[Install]
WantedBy=multi-user.target" > $systemctlDIR/ehco.service
	systemctl daemon-reload
	systemctl start ehco.service
	systemctl enable ehco.service
}

AddNewRelay() {
    echo "现在添加中转的功能已经和修改删除中转的脚本整合在一起啦！"
    return
    echo -e "${blue_prefix}[Info]${plain_prefix} 正在检测必要组件是否工作正常.."
    netstat -help &> /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${blue_prefix}[Info]${plain_prefix} net-tools包缺失，正在安装..."
        case ${SysID} in
    	*centos*)
    		yum install net-tools -y &> null
    		;;
    	*debian*)
    	    apt-get update &> null
    		apt-get install net-tools -y &> null
    		;;
    	*ubuntu*)
    	    apt-get update &> null
    		apt-get install net-tools -y &> null
    		;;
    	*)
    		echo -e "[Error]未知系统，请自行安装net-tools包"
    		exit 1
    		;;
    	esac
    else
        echo -e "${blue_prefix}[Info]${plain_prefix} 一切正常，继续添加中转..."
    fi
	echo -e "添加新的中转记录"

	if [ $(cat $ehco_conf_dir/ehco.json | grep -c listen) -gt 1 ]; then
		endl=","
	fi
	echo -e -e "请选择当前模式：\n${green_prefix}1.${plain_prefix} 中转模式（通常在${yellow_prefix}国内的流量入口服务器${plain_prefix}上部署）\n${green_prefix}2.${plain_prefix} 落地模式（通常在${yellow_prefix}海外的流量出口服务器${plain_prefix}上部署）"
	read -p "请输入序号：" relayModule
	case {$relayModule} in 
		# 中转模式
		*1*)
		while true; do
			read -p "请输入本机监听端口：" listenPort
			if [ $(netstat -tlpn | grep -c "\b$listenPort\b") -gt 0 ]; then
				echo -e "${red_prefix}[Error]${plain_prefix} 端口已经被占用！"
			else
				break
			fi
		done
		echo -e "${blue_prefix}[Tips]${plain_prefix}  Ehco支持动态域名(DDNS)、IPv4、IPv6的隧道搭建\n\t如需转发IPv6记得在IP两端加上${blue_prefix}[]${plain_prefix}，如${blue_prefix}[2606:4700:4700:]${plain_prefix}"
		read -p "请输入远程IP或者域名：" remoteIP
		read -p "请输入远程主机端口：" remotePort
		echo -e "${blue_prefix}[Tips]${plain_prefix}  Ehco、Gost和其他隧道一样，都需要在中转和落地服务器两端分别部署发送端和接收端才可以连通\n\tEhco也提供单纯的流量转发，${yellow_prefix}raw${plain_prefix}模式就是一种单纯中转，它的作用和${yellow_prefix}iptables、brook${plain_prefix}中转无异"
		echo -e "请选择传输协议（需与落地一致）：\n${green_prefix}1.${plain_prefix} mwss（稳定性极高且延时最低但传输速率最差）\n${green_prefix}2.${plain_prefix} wss（较好的稳定性及较快的传输速率但延时较高）\n${green_prefix}3.${plain_prefix} raw（无隧道直接转发、效率极高但无抗干扰能力）"
		read -p "输入序号：" num
		case {$num} in
			*1*)
				transport_type=mwss
				conf="\n\t{\n\t\t\"listen\": \"0.0.0.0:$listenPort\",\n\t\t\"listen_type\": \"raw\",\n\t\t\"transport_type\": \"$transport_type\",\n\t\t\"tcp_remotes\": [\"wss:\/\/$remoteIP:$remotePort\"],\n\t\t\"udp_remotes\": [\"$remoteIP:$remotePort\"]\n\t}$endl"
				;;
			*2*)
				transport_type=wss
				conf="\n\t{\n\t\t\"listen\": \"0.0.0.0:$listenPort\",\n\t\t\"listen_type\": \"raw\",\n\t\t\"transport_type\": \"$transport_type\",\n\t\t\"tcp_remotes\": [\"wss:\/\/$remoteIP:$remotePort\"],\n\t\t\"udp_remotes\": [\"$remoteIP:$remotePort\"]\n\t}$endl"
				;;
			*3*)
				transport_type=raw
				conf="\n\t{\n\t\t\"listen\": \"0.0.0.0:$listenPort\",\n\t\t\"listen_type\": \"raw\",\n\t\t\"transport_type\": \"$transport_type\",\n\t\t\"tcp_remotes\": [\"$remoteIP:$remotePort\"],\n\t\t\"udp_remotes\": [\"$remoteIP:$remotePort\"]\n\t}$endl"
				;;
		esac
		unset num
		
		sed -i "s/\"relay_configs\"\:\[/&$conf/" $ehco_conf_dir/ehco.json
		echo -e -n "\n需要继续添加中转吗？${blue_prefix}(y/n)${plain_prefix} "
		read continueAddRelay
		if [[ $continueAddRelay == y* || $continueAddRelay == Y* ]]; then
			systemctl restart ehco
			echo -e "${green_prefix}[Success]${plain_prefix} 添加中转成功 $listenPort -> $remoteIP:$remotePort"
			AddNewRelay
		else
			echo -e "${green_prefix}[Success]${plain_prefix} 添加中转成功 $listenPort -> $remoteIP:$remotePort"
			echo -e "${blue_prefix}[Info]${plain_prefix} 保存应用配置中...."
			systemctl restart ehco
		fi
		;;


		# 落地模式
		*2*)
		while true; do
			read -p "请输入本机监听端口：" listenPort
			if [ $(netstat -tlpn | grep -c "\b$listenPort\b") -gt 0 ]; then
				echo -e "${red_prefix}[Error]${plain_prefix} 端口已经被占用！"
			else
				break
			fi
		done
		echo -e "${blue_prefix}[Tips]${plain_prefix} 所谓的流量目标端口就是，流量最终将前往的地方，一般是部署在本机的代理的监听端口"
		read -p "请输入流量目标端口：" remotePort
		echo -e "请选择传输协议（需与中转一致）：\n${green_prefix}1.${plain_prefix} mwss（稳定性极高且延时最低但传输速率最差）\n${green_prefix}2.${plain_prefix} wss（较好的稳定性及较快的传输速率但延时较高）\n${green_prefix}3.${plain_prefix} raw（无隧道直接转发、效率极高但无抗干扰能力）"
		read -p "输入序号：" num
		case {$num} in
			*1*)
				transport_type=mwss
				;;
			*2*)
				transport_type=wss
				;;
			*3*)
				transport_type=raw
				;;
		esac
		unset num
		conf="\n\t{\n\t\t\"listen\": \"0.0.0.0:$listenPort\",\n\t\t\"listen_type\": \"$transport_type\",\n\t\t\"transport_type\": \"raw\",\n\t\t\"tcp_remotes\": [\"0.0.0.0:$remotePort\"],\n\t\t\"udp_remotes\": [\"0.0.0.0:$remotePort\"]\n\t}$endl"
		sed -i "s/\"relay_configs\"\:\[/&$conf/" $ehco_conf_dir/ehco.json
		systemctl restart ehco
		echo -e "${green_prefix}[Success]${plain_prefix} 添加中转成功 $listenPort -> $remoteIP:$remotePort"
		;;
		
		# 中继模式（这个坑以后再填）
		*100*)
		while true; do
			read -p "请输入本机监听端口：" listenPort
			if [ $(netstat -tlpn | grep -c "\b$listenPort\b") -gt 0 ]; then
				echo -e "端口已经被占用！"
			else
				break
			fi
		done
		read -p "请输入下一个链路的IP地址：" remoteIP
		read -p "请输入下一个链路的端口：" remotePort
		echo -e "请选择传输协议（监听端，请与上一个链路的中转传输协议保持一致）：\n1.mwss（稳定性极高且延时最低但传输速率最差）\n2.wss（较好的稳定性及较快的传输速率但延时较高）\n3.raw（无隧道直接转发、效率极高但无抗干扰能力）"
		read -p "输入序号（需与中转一致）：" num
		case {$num} in
			*1*)
				listen_type=mwss
				;;
			*2*)
				listen_type=wss
				;;
			*3*)
				listen_type=raw
				;;
		esac
		unset num
		echo -e "请选择传输协议（发送端，请与下一个链路的中转传输协议保持一致）：\n1.mwss（稳定性极高且延时最低但传输速率最差）\n2.wss（较好的稳定性及较快的传输速率但延时较高）\n3.raw（无隧道直接转发、效率极高但无抗干扰能力）"
		read -p "输入序号（需与中转一致）：" num
		case {$num} in
			*1*)
				transport_type=mwss
				;;
			*2*)
				transport_type=wss
				;;
			*3*)
				transport_type=raw
				;;
		esac
		unset num
	esac
	unset relayModule
	
}

installEhco() {
	case {$CPUFrame} in
		*x86_64*)
			InitialEhco amd64
			;;
		*)
		    InitialEhco arm64
	esac
}

uninstallEhco() {
	systemctl stop ehco
	systemctl disable ehco
	rm -rf /usr/local/ehco/
	rm -f /usr/bin/ehco
	echo -e "${green_prefix}[Success]${plain_prefix} 卸载成功"
}

stopEhco() {
	systemctl stop ehco
	systemctl disable ehco
	echo -e "${green_prefix}[Success]${plain_prefix} Ehco已暂停"
}

startEhco() {
	systemctl start ehco
	systemctl enable ehco
	echo -e "${green_prefix}[Success]${plain_prefix} Ehco已开启"
}

rebootEhco() {
	systemctl restart ehco
	echo -e "${green_prefix}[Success]${plain_prefix} Ehco已重启"
}

ConfPy() {
	case ${SysID} in
	*centos*)
		python3 -h &> null
		if [ $? -ne 0 ]; then
			echo -e "${blue_prefix}[Info]${plain_prefix} 缺少Python3包，正在安装...这可能将花费若干分钟"
			yum install python3 -y &> null
		fi
		;;
	*debian*)
		python3 -h &> null
		if [ $? -ne 0 ]; then
			echo -e "${blue_prefix}[Info]${plain_prefix} 缺少Python3包，正在安装...这可能将花费若干分钟"
			apt-get update &> null
			apt-get install python3 -y &> null
		fi
		;;
	*ubuntu*)
		python3 -h &> null
		if [ $? -ne 0 ]; then
			echo -e "${blue_prefix}[Info]${plain_prefix} 缺少Python3包，正在安装...这可能将花费若干分钟"
			apt-get update &> null
			apt-get install python3 -y &> null
		fi
		;;
	*)
		python3 -h &> null
		if [ $? -ne 0 ]; then
			echo -e "[Error]未知系统，请自行安装Python3包"
			exit 1
		fi
		;;
	esac
	# 检查Python3模块环境
	result=`python_model_check dbus`
	if [ $result == 1 ]
	then
		echo -e "check python3-dbus......${green_prefix}ok${plain_prefix}"
	else
		echo -e "check python3-dbus......${red_prefix}no${plain_prefix}"
	    case ${SysID} in
		*centos*)
			echo -e "${blue_prefix}[Info]${plain_prefix} 添加并更新EPEL源中..."
			yum install epel-release -y &> /dev/null
			echo -e "${blue_prefix}[Info]${plain_prefix} 安装python3-dbus包..."
			yum install python3-dbus -y &> /dev/null
			;;
		*debian*)
			echo -e "${blue_prefix}[Info]${plain_prefix} 更新APT源..."
			apt-get update &> /dev/null
			echo -e "${blue_prefix}[Info]${plain_prefix} 安装python3-dbus包...对于系统性能较差的VPS，可能将花费若干分钟"
			apt-get install python3-dbus -y &> /dev/null
			;;
		*ubuntu*)
			echo -e "${blue_prefix}[Info]${plain_prefix} 更新APT源..."
			apt-get update &> /dev/null
			echo -e "${blue_prefix}[Info]${plain_prefix} 安装python3-dbus包..."
			apt-get install python3-dbus -y &> /dev/null
			;;
		*)
			echo -e "[Error]未知系统，请自行安装python3-dbus"
			exit 1
	    	;;
	  esac
	fi
	result=`python_model_check requests`
	if [ $result == 1 ]
	then
		echo -e "check requests......${green_prefix}ok${plain_prefix}"
	else
		echo -e "check requests......${red_prefix}no${plain_prefix}"
		echo -e "${blue_prefix}[Info]${plain_prefix}  开始安装requests包"
	 	pip3 install requests &> /dev/null
	 	
	 	if [ $? -ne 0 ]; then
	 		echo -e "${blue_prefix}[Info]${plain_prefix} 检测到Minimal精简版系统，未内置pip管理工具"
	 		case ${SysID} in
			*centos*)
				echo -e "${blue_prefix}[Info]${plain_prefix} 开始安装python3-pip包..."
				yum install python3-pip -y &> /dev/null
				;;
			*debian*)
				echo -e "${blue_prefix}[Info]${plain_prefix} 更新APT源..."
				apt update &> /dev/null
				echo -e "${blue_prefix}[Info]${plain_prefix} 开始安装python3-pip包..."
				apt install python3-pip -y &> /dev/null
				;;
			*ubuntu*)
				echo -e "${blue_prefix}[Info]${plain_prefix} 更新APT源..."
				apt update &> /dev/null
				echo -e "${blue_prefix}[Info]${plain_prefix} 开始安装python3-pip包..."
				apt install python3-pip -y &> /dev/null
				;;
			*)
				echo -e "[Error]未知系统，请自行安装python3-pip"
				exit 1
				;;
			esac
			pip3 install requests &> /dev/null
		fi
	fi
	# 脚本文件
	if [ ! -e "/usr/local/ehco/ehcoConfigure_beta01.py" ]; then
		echo -e "${blue_prefix}[Info]${plain_prefix} 下载脚本文件中..."
		wget -O /usr/local/ehco/ehcoConfigure_beta01.py "https://leo.moe/ehco/ehcoConfigure.py" &> null
	fi
	python3 /usr/local/ehco/ehcoConfigure_beta01.py
}

showMenu() {
	clear
	echo -e -e "Ehco 一键配置脚本 ${yellow_prefix}v1.1 Beta${plain_prefix} by ${blue_prefix}@sjlleo${plain_prefix}\n\n${green_prefix}1.${plain_prefix} 安装Ehco\n${green_prefix}2.${plain_prefix} 卸载Ehco\n${green_prefix}3.${plain_prefix} 启动Ehco并加入开机启动\n${green_prefix}4.${plain_prefix} 停止Ehco并移除开机启动\n${green_prefix}5.${plain_prefix} 重启Ehco\n${green_prefix}7.${plain_prefix} 管理中转记录(New!)\n${green_prefix}8.${plain_prefix} 初始化配置文件\n${green_prefix}9.${plain_prefix} 退出脚本\n"
	ProcNumber=`ps -ef|grep -w ehco|grep -v grep|grep -v ehco.sh|wc -l`
	if [ $ProcNumber -le 0 ];then  
		result="Ehco状态： ${yellow_prefix}未在运行${plain_prefix}\n"
	else  
		result="Ehco状态： ${green_prefix}正在运行${plain_prefix}\n"
	fi

	echo -e ${result}

	read -p "请输入选项：" num

	case ${num} in
	1)
		installEhco
		AddNewRelay
		;;
	2)
		uninstallEhco
		;;
	4)
		stopEhco
		;;
	3)
		startEhco
		;;
	5)
		rebootEhco
		;;		
	6)
		AddNewRelay
		;;
	7)
		ConfPy
		;;
	8)
		InitialEhcoConfigure
		systemctl restart ehco
		;;
	9)
		exit 0
		;;
	esac
	echo -e "${blue_prefix}[Info]${plain_prefix} 完成配置，请按任意键回到主菜单"
	read
	showMenu
}


showMenu

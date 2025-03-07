network_manager_tui() {

	DEPENDENCY_01=''

	if [ ! $(command -v nmtui) ]; then
		case "${LINUX_DISTRO}" in
		"debian") DEPENDENCY_02='network-manager' ;;
		"redhat") DEPENDENCY_02='NetworkManager-tui' ;;
		*) DEPENDENCY_02='networkmanager' ;;
		esac
		beta_features_quick_install
	fi

	if [ ! $(command -v ip) ]; then
		DEPENDENCY_02='iproute2'
		printf "%s\n" "${GREEN}${TMOE_INSTALLATION_COMMAND} ${DEPENDENCY_02}${RESET}"
		${TMOE_INSTALLATION_COMMAND} ${DEPENDENCY_02}
	fi

	if grep -q 'managed=false' /etc/NetworkManager/NetworkManager.conf; then
		sed -i 's@managed=false@managed=true@' /etc/NetworkManager/NetworkManager.conf
	fi
	pgrep NetworkManager >/dev/null
	if [ "$?" != "0" ]; then
		if [ "${LINUX_DISTRO}" = "alpine" ]; then
			service networkmanager start
		else
			systemctl start NetworkManager || service NetworkManager start || service networkmanager start
		fi
	fi
	RETURN_TO_WHERE='network_manager_tui'
	NETWORK_MANAGER=$(whiptail --title "NETWORK" --menu \
		"您想要如何配置网络？\n How do you want to configure the network? " 17 50 8 \
		"1" "nmtui:文本用户界面网络管理器" \
		"2" "enable device:启用设备" \
		"3" "WiFi scan:扫描" \
		"4" "device status:设备状态" \
		"5" "driver:网卡驱动" \
		"6" "View ip address:查看ip" \
		"7" "wifi-qr:将WiFi密码转换成二维码" \
		"8" "edit config manually:手动编辑" \
		"9" "systemctl enable NetworkManager开机自启" \
		"10" "blueman(蓝牙管理器,GTK+前端)" \
		"11" "gnome-nettool(网络工具)" \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${NETWORK_MANAGER}" in
	0 | "") beta_features ;;
	1)
		nmtui
		network_manager_tui
		;;
	2)
		enable_netword_card
		;;
	3)
		tmoe_wifi_scan
		;;
	4)
		network_devices_status
		;;
	5)
		install_debian_nonfree_network_card_driver
		;;
	6)
		ip a
		ip -br -c a
		if [ ! -z $(printf '%s\n' "${LANG}" | grep zh) ]; then
			curl -L myip.ipip.net
		else
			curl -L ip.cip.cc
		fi
		;;
	7)
		install_wifi_qr
		;;
	8)
		nano /etc/NetworkManager/system-connections/*
		nano /etc/NetworkManager/NetworkManager.conf
		nano /etc/network/interfaces.d/*
		nano /etc/network/interfaces
		;;
	9)
		if [ "${LINUX_DISTRO}" = "alpine" ]; then
			TMOE_DEPENDENCY_SYSTEMCTL='networkmanager'
		else
			TMOE_DEPENDENCY_SYSTEMCTL='NetworkManager'
		fi

		if (whiptail --title "您想要对这个小可爱做什么" --yes-button "ENABLE启用" --no-button "DISABLE禁用" --yesno "您是否需要启用网络管理器开机自启的功能？♪(^∇^*) " 0 50); then
			printf "%s\n" "${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
			systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}
			if [ "$?" = "0" ]; then
				printf "%s\n" "已添加至自启任务"
			else
				printf "%s\n" "添加自启任务失败"
			fi
		else
			printf "%s\n" "${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
			systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}
		fi
		;;
	10) install_blueman ;;
	11) install_gnome_net_manager ;;
	esac
	##########################
	press_enter_to_return
	network_manager_tui
}
###########
################
install_gnome_net_manager() {
	DEPENDENCY_01="gnome-nettool"
	case "${LINUX_DISTRO}" in
	"debian") DEPENDENCY_02="network-manager-gnome" ;;
	*) DEPENDENCY_02="gnome-network-manager" ;;
	esac

	beta_features_quick_install
}
######################
install_wifi_qr() {
	if [ ! $(command -v wifi-qr) ]; then
		DEPENDENCY_01='wifi-qr'
		DEPENDENCY_02=''
		beta_features_quick_install
	fi
	printf '%s\n' 'You can type wifi-qr to start it.'
	wifi-qr t
}
#################
install_blueman() {
	if [ "${LINUX_DISTRO}" = "alpine" ]; then
		DEPENDENCY_01='gnome-bluetooth'
	else
		DEPENDENCY_01='blueman-manager'
	fi
	DEPENDENCY_02='blueman'
	beta_features_quick_install
}
##################
tmoe_wifi_scan() {
	DEPENDENCY_01=''
	if [ ! $(command -v iw) ]; then
		DEPENDENCY_02='iw'
		beta_features_quick_install
	fi

	if [ ! $(command -v iwlist) ]; then
		if [ "${LINUX_DISTRO}" = "arch" ]; then
			DEPENDENCY_02='wireless_tools'
		else
			DEPENDENCY_02='wireless-tools'
		fi
		beta_features_quick_install
	fi

	if [ "${LINUX_DISTRO}" = "arch" ]; then
		if [ ! $(command -v wifi-menu) ]; then
			DEPENDENCY_01='wpa_supplicant'
			DEPENDENCY_02='netctl'
			beta_features_quick_install
		fi
		if [ ! $(command -v dialog) ]; then
			DEPENDENCY_01=''
			DEPENDENCY_02='dialog'
			beta_features_quick_install
		fi
		wifi-menu
	fi
	printf '%s\n' 'scanning...'
	printf '%s\n' '正在扫描中...'
	cd /tmp
	iwlist scan 2>/dev/null | tee .tmoe_wifi_scan_cache
	printf '%s\n' '-------------------------------'
	cat .tmoe_wifi_scan_cache | grep --color=auto -i 'SSID'
	rm -f .tmoe_wifi_scan_cache
}
##############
network_devices_status() {
	iw phy
	printf '%s\n' '-------------------------------'
	nmcli device show 2>&1 | head -n 100
	printf '%s\n' '-------------------------------'
	nmcli connection show
	printf '%s\n' '-------------------------------'
	iw dev
	printf '%s\n' '-------------------------------'
	nmcli radio
	printf '%s\n' '-------------------------------'
	nmcli device
}
#############

check_debian_nonfree_source() {
	if [ "${LINUX_DISTRO}" = 'debian' ]; then
		if [ "${DEBIAN_DISTRO}" != 'ubuntu' ]; then
			if ! grep -q '^deb.*non-free' /etc/apt/sources.list; then
				printf '%s\n' '是否需要添加debian non-free软件源？'
				printf '%s\n' 'Do you want to add non-free source.list?'
				do_you_want_to_continue
				sed -i '$ a\deb https://mirrors.huaweicloud.com/debian/ stable non-free' /etc/apt/sources.list
				apt update
			fi
		fi
	fi
}
##################
install_debian_nonfree_network_card_driver() {
	RETURN_TO_WHERE='install_debian_nonfree_network_card_driver'
	check_debian_nonfree_source
	DEPENDENCY_01=''
	NETWORK_MANAGER=$(whiptail --title "你想要安装哪个驱动？" --menu \
		"Which driver do you want to install?" 15 50 7 \
		"1" "list devices查看设备列表" \
		"2" "Intel Wireless cards嘤(英)特尔" \
		"3" "Realtek wired/wifi/BT adapters瑞昱" \
		"4" "Marvell wireless cards美满" \
		"5" "TI Connectivity wifi/BT/FM/GPS" \
		"6" "Broadcom博通" \
		"7" "misc(Ralink,etc.)" \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	##########################
	case "${NETWORK_MANAGER}" in
	0 | "") network_manager_tui ;;
	1) list_network_devices ;;
	2) DEPENDENCY_02='firmware-iwlwifi' ;;
	3) DEPENDENCY_02='firmware-realtek' ;;
	4) DEPENDENCY_02='firmware-libertas' ;;
	5) DEPENDENCY_02='firmware-ti-connectivity' ;;
	6) DEPENDENCY_02='firmware-brcm80211' ;;
	7) install_linux_firmware_nonfree ;;
	esac
	##########################
	if (whiptail --title "您想要对这个小可爱做什么" --yes-button "install安装" --no-button "Download下载" --yesno "您是想要直接安装，还是下载驱动安装包? ♪(^∇^*) " 8 50); then
		do_you_want_to_continue
		beta_features_quick_install
	else
		download_network_card_driver
	fi
	press_enter_to_return
	install_debian_nonfree_network_card_driver
}
#############
install_linux_firmware_nonfree() {
	DEPENDENCY_02='firmware-misc-nonfree'
	case "${LINUX_DISTRO}" in
	debian | "") ;;
	*) DEPENDENCY_01='linux-firmware' ;;
	esac
}
###############
download_network_card_driver() {
	mkdir -p cd ${HOME}/sd/Download
	cd ${HOME}/sd/Download
	printf "%s\n" "即将为您下载至${HOME}/sd/Download"
	if [ $(command -v apt-get) ]; then
		apt-cache show ${DEPENDENCY_02}
		apt download ${DEPENDENCY_02}
		THE_LATEST_DEB_VERSION="$(ls | grep "${DEPENDENCY_02}.*deb" | head -n 1)"
	else
		GREP_NAME=${DEPENDENCY_02}
		REPO_URL='https://mirrors.bfsu.edu.cn/debian/pool/non-free/f/firmware-nonfree/'
		THE_LATEST_DEB_VERSION="$(curl -L ${REPO_URL} | grep '\.deb' | grep "${GREP_NAME}" | tail -n 1 | cut -d '=' -f 3 | cut -d '"' -f 2)"
		THE_LATEST_DEB_LINK="${REPO_URL}${THE_LATEST_DEB_VERSION}"
		printf "%s\n" "${THE_LATEST_DEB_LINK}"
		aria2c --no-conf --allow-overwrite=true -s 5 -x 5 -k 1M -o "${THE_LATEST_DEB_VERSION}" "${THE_LATEST_DEB_LINK}"
	fi

	mkdir -p "${DEPENDENCY_02}"
	cd "${DEPENDENCY_02}"
	ar xv ../${THE_LATEST_DEB_VERSION}
	tar -Jxvf ./data.tar.*
	rm *.tar.* debian-binary
	cd ..
	printf "%s\n" "Download completed,文件已保存至${HOME}/sd/Download"

}
###############
list_network_devices() {
	if [ ! $(command -v dmidecode) ]; then
		DEPENDENCY_02='dmidecode'
		beta_features_quick_install
	fi
	dmidecode | less -meQ
	dmidecode | grep --color=auto -Ei 'Wire|Net'
	press_enter_to_return
	install_debian_nonfree_network_card_driver
}
############
enable_netword_card() {
	cd /tmp/
	nmcli d | egrep -v '^lo|^DEVICE' | awk '{print $1}' >.tmoe-linux_cache.01
	nmcli d | egrep -v '^lo|^DEVICE' | awk '{print $2,$3}' | sed 's/ /-/g' >.tmoe-linux_cache.02
	TMOE_NETWORK_CARD_LIST=$(paste -d ' ' .tmoe-linux_cache.01 .tmoe-linux_cache.02 | sed ":a;N;s/\n/ /g;ta")
	rm -f .tmoe-linux_cache.0*
	#TMOE_NETWORK_CARD_LIST=$(nmcli d | egrep -v '^lo|^DEVICE' | awk '{print $2,$3}')
	TMOE_NETWORK_CARD_ITEM=$(whiptail --title "NETWORK DEVICES" --menu \
		"您想要启用哪个网络设备？\nWhich network device do you want to enable?" 0 0 0 \
		${TMOE_NETWORK_CARD_LIST} \
		"0" "🌚 Return to previous menu 返回上级菜单" \
		3>&1 1>&2 2>&3)
	case ${TMOE_NETWORK_CARD_ITEM} in
	0 | "") network_manager_tui ;;
	esac
	ip link set ${TMOE_NETWORK_CARD_ITEM} up
	if [ "$?" = '0' ]; then
		printf "%s\n" "Congratulations,已经启用${TMOE_NETWORK_CARD_ITEM}"
	else
		printf '%s\n' 'Sorry,设备启用失败'
	fi
}
##################
network_manager_tui

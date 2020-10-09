#!/bin/bash
clear
#生成时间
VersionDate=$(git show -s --date=short --format="%cd")
echo "::set-env name=VersionDate::$VersionDate"
echo "::set-env name=DATE::$(date "+%Y-%m-%d %H:%M:%S")"
Build_Date=$(date +%Y.%m.%d)
echo "::set-env name=Build_Date::$(date +%Y.%m.%d)"
rm -f ./feeds.conf.default
wget https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/feeds.conf.default
#remove annoying snapshot tag
sed -i 's,SNAPSHOT,,g' include/version.mk
sed -i 's,snapshots,,g' package/base-files/image-config.in
#scons patch
wget -P include/ https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/include/scons.mk
#更新feed
./scripts/feeds update -a && ./scripts/feeds install -a
#O3
sed -i 's/Os/O2/g' include/target.mk
sed -i 's/O2/O2/g' ./rules.mk
#irqbalance
sed -i 's/0/1/g' feeds/packages/utils/irqbalance/files/irqbalance.config

#patch rk-crypto
patch -p1 < ../patches/kernel_crypto-add-rk3328-crypto-support.patch

#patch i2c0
cp -f ../patches/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch ./target/linux/rockchip/patches-5.4/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch

#patch jsonc
patch -p1 < ../patches/use_json_object_new_int64.patch

#dnsmasq aaaa filter
patch -p1 < ../patches/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../patches/luci-add-filter-aaaa-option.patch
cp -f ../patches/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch

#FullCone Patch
git clone -b master --single-branch https://github.com/QiuSimons/openwrt-fullconenat package/fullconenat
# Patch FireWall for fullcone
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/fullconenat.patch
# Patch LuCI for fullcone
pushd feeds/luci
wget -O- https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/luci.patch | git apply
popd
#Patch Kernel for fullcone
pushd target/linux/generic/hack-5.4
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd

#Patch FireWall for SFE
patch -p1 < ../patches/luci-app-firewall_add_sfe_switch.patch
# SFE kernel patch
pushd target/linux/generic/hack-5.4
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/999-shortcut-fe-support.patch
popd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe package/new/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/new/fast-classifier
#Over Clock to 1.6G
cp -f ../patches/999-unlock-1608mhz-rk3328.patch ./target/linux/rockchip/patches-5.4/999-unlock-1608mhz-rk3328.patch
#rm -f ./target/linux/rockchip/patches-5.4/004-unlock-1512mhz-rk3328.patch

#patch rockchip/config-default
patch -p1 < ../patches/for_r2s_19.07_config-default.patch
#
#update curl
rm -rf ./package/network/utils/curl
svn co https://github.com/openwrt/packages/trunk/net/curl package/network/utils/curl
#replace Node
#rm -rf ./feeds/packages/lang/node
#svn co https://github.com/nxhack/openwrt-node-packages/trunk/node feeds/packages/lang/node
#rm -rf ./feeds/packages/lang/node-arduino-firmata
#svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-arduino-firmata feeds/packages/lang/node-arduino-firmata
#rm -rf ./feeds/packages/lang/node-cylon
#svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-cylon feeds/packages/lang/node-cylon
#rm -rf ./feeds/packages/lang/node-hid
#svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-hid feeds/packages/lang/node-hid
#rm -rf ./feeds/packages/lang/node-homebridge
#svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-homebridge feeds/packages/lang/node-homebridge
#rm -rf ./feeds/packages/lang/node-serialport
#svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport feeds/packages/lang/node-serialport
#rm -rf ./feeds/packages/lang/node-serialport-bindings
#svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport-bindings feeds/packages/lang/node-serialport-bindings
#update GCC
rm -rf ./feeds/packages/devel/gcc
svn co https://github.com/openwrt/packages/trunk/devel/gcc feeds/packages/devel/gcc
#update Golang
#rm -rf ./feeds/packages/lang/golang
#svn co https://github.com/openwrt/packages/trunk/lang/golang feeds/packages/lang/golang
#rm -rf ./feeds/packages/lang/golang/.svn
#rm -rf ./feeds/packages/lang/golang/golang
#svn co https://github.com/project-openwrt/packages/trunk/lang/golang/golang feeds/packages/lang/golang/golang
svn co https://github.com/openwrt/packages/trunk/lang/golang package/feeds/lang/golang/

#add libs
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/nghttp2 package/libs/nghttp2
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libconfig package/libs/libconfig
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/utils/fuse package/utils/fuse
#svn co https://github.com/openwrt/packages/branches/openwrt-19.07/libs/libcap package/libs/libcap

#Additional package
#arpbind
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind package/lean/luci-app-arpbind
#AutoCore
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/autocore package/lean/autocore
#coremark
rm -rf ./feeds/packages/utils/coremark
rm -rf ./package/feeds/packages/coremark
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/coremark package/lean/coremark
sed -i 's,-DMULTIT,-Ofast -DMULTIT,g' package/lean/coremark/Makefile
#DDNS
rm -rf ./feeds/packages/net/ddns-scripts
rm -rf ./feeds/luci/applications/luci-app-ddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_aliyun package/lean/ddns-scripts_aliyun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_dnspod package/lean/ddns-scripts_dnspod
svn co https://github.com/openwrt/packages/branches/openwrt-18.06/net/ddns-scripts feeds/packages/net/ddns-scripts
svn co https://github.com/openwrt/luci/branches/openwrt-18.06/applications/luci-app-ddns feeds/luci/applications/luci-app-ddns

#定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot package/lean/luci-app-autoreboot
#AdGuard
#git clone -b master --single-branch https://github.com/rufengsuixing/luci-app-adguardhome package/new/luci-app-adguardhome
#Adbyby
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-adbyby-plus package/lean/luci-app-adbyby-plus
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/adbyby package/lean/coremark/adbyby
#gost
svn co https://github.com/project-openwrt/openwrt/branches/master/package/ctcgfw/gost package/ctcgfw/gost
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/luci-app-gost package/ctcgfw/luci-app-gost
#svn co https://github.com/project-openwrt/openwrt/branches/master/package/ctcgfw/luci-app-gost package/ctcgfw/luci-app-gost
#SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus package/lean/luci-app-ssr-plus
svn co https://github.com/fw876/helloworld/trunk/tcping package/lean/tcping
svn co https://github.com/fw876/helloworld/trunk/naiveproxy package/lean/naiveproxy
#rm -rf ./package/lean/luci-app-ssr-plus/luasrc/view/shadowsocksr/ssrurl.htm
#wget -P package/lean/luci-app-ssr-plus/luasrc/view/shadowsocksr https://raw.githubusercontent.com/QiuSimons/Others/master/luci-app-ssr-plus/luasrc/view/shadowsocksr/ssrurl.htm
#SSRP依赖
rm -rf ./feeds/packages/net/kcptun
rm -rf ./feeds/packages/net/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt package/lean/pdnsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray package/lean/v2ray
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray-plugin package/lean/v2ray-plugin
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2 package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng package/lean/proxychains-ng
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev package/lean/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan package/lean/trojan

#v2ray-server
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-v2ray-server package/luci-app-v2ray-server
#ssr-server-python
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ssrserver-python package/luci-app-ssrserver-python
#OpenClash
#svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/new/luci-app-openclash
#luci-app-clash
#git clone https://github.com/frainzy1477/luci-app-clash.git package/luci-app-clash
#passwall
#svn co https://github.com/Lienol/openwrt-package/trunk/lienol/luci-app-passwall package/lienol/luci-app-passwall
#git clone -b master --single-branch https://github.com/xnxy2012/luci-app-passwall.git package/lienol/luci-app-passwall
#passwall depends
#svn co https://github.com/Lienol/openwrt-package/trunk/package/chinadns-ng package/lienol/chinadns-ng
#svn co https://github.com/Lienol/openwrt-package/trunk/package/tcping package/lienol/tcping
#svn co https://github.com/Lienol/openwrt-package/trunk/package/trojan-go package/lienol/trojan-go
#svn co https://github.com/Lienol/openwrt-package/trunk/package/dns2socks package/lienol/dns2socks
#svn co https://github.com/Lienol/openwrt-package/trunk/package/v2ray-plugin package/lienol/v2ray-plugin
#svn co https://github.com/Lienol/openwrt-package/trunk/package/pdnsd-alt package/lienol/pdnsd-alt
#svn co https://github.com/Lienol/openwrt-package/trunk/package/openssl1.1 package/lienol/openssl1.1
#svn co https://github.com/Lienol/openwrt-package/trunk/package/simple-obfs package/lienol/simple-obfs
#edge主题
#git clone -b master --single-branch https://github.com/garypang13/luci-theme-edge package/new/luci-theme-edge
#订阅转换
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/subconverter package/new/subconverter
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/jpcre2 package/new/jpcre2
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/rapidjson package/new/rapidjson
#清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree package/lean/luci-app-ramfree
#打印机
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-usb-printer package/lean/luci-app-usb-printer
#流量监视
git clone -b master --single-branch https://github.com/brvphoenix/wrtbwmon package/new/wrtbwmon
git clone -b master --single-branch https://github.com/brvphoenix/luci-app-wrtbwmon package/new/luci-app-wrtbwmon
#流量监管
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-netdata package/lean/luci-app-netdata
#SeverChan
#git clone -b master --single-branch https://github.com/tty228/luci-app-serverchan package/new/luci-app-serverchan
#iputils
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/utils/iputils package/network/utils/iputils
#SmartDNS
svn co https://github.com/pymumu/smartdns/trunk/package/openwrt package/new/smartdns/smartdns
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ntlf9t/luci-app-smartdns package/new/smartdns/luci-app-smartdns

#VSSR
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/luci-app-vssr package/new/luci-app-vssr
git clone -b master --single-branch https://github.com/jerrykuku/luci-app-vssr package/lean/luci-app-vssr
git clone -b master --single-branch https://github.com/jerrykuku/lua-maxminddb package/lean/lua-maxminddb

#上网APP过滤
#git clone -b master --single-branch https://github.com/destan19/OpenAppFilter package/new/OpenAppFilter
#jd-dailybonus
git clone https://github.com/jerrykuku/node-request package/lean/node-request
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus package/lean/luci-app-jd-dailybonus
wget -O package/lean/luci-app-jd-dailybonus/root/usr/share/jd-dailybonus/JD_DailyBonus.js https://github.com/NobyDa/Script/raw/master/JD-DailyBonus/JD_DailyBonus.js
#
#frp
rm -f ./feeds/luci/applications/luci-app-frps
rm -f ./feeds/luci/applications/luci-app-frpc
#rm -rf ./feeds/packages/net/frp
#rm -rf ./package/feeds/packages/frp
git clone https://github.com/lwz322/luci-app-frps.git package/lean/luci-app-frps
git clone https://github.com/kuoruan/luci-app-frpc.git package/lean/luci-app-frpc
svn co https://github.com/project-openwrt/packages/trunk/net/frp package/feeds/packages/frp

#onliner
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/luci-app-onliner package/ctcgfw/luci-app-onliner
#filetransfer
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/lean/luci-app-filetransfer package/lean/luci-app-filetransfer
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/lean/luci-lib-fs package/lean/luci-lib-fs
#tmate
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/tmate package/ctcgfw/tmate
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/msgpack-c package/ctcgfw/msgpack-c
#
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/luci-app-cpufreq package/lean/luci-app-cpufreq
patch -p1 < ../patches/luci-app-freq.patch
#beardropper
git clone https://github.com/NateLol/luci-app-beardropper package/luci-app-beardropper
#trojan server
#svn co https://github.com/Lienol/openwrt-package/trunk/lienol/luci-app-trojan-server package/luci-app-trojan-server
#transmission-web-control
#rm -rf ./feeds/packages/net/transmission*
#rm -rf ./feeds/luci/applications/luci-app-transmission/
#svn co https://github.com/coolsnowwolf/packages/trunk/net/transmission feeds/packages/net/transmission
#svn co https://github.com/coolsnowwolf/packages/trunk/net/transmission-web-control feeds/packages/net/transmission-web-control
#svn co https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-transmission feeds/luci/applications/luci-app-transmission
#Dockerman
#git clone https://github.com/lisaac/luci-app-dockerman.git package/lean/luci-app-dockerman
#git clone https://github.com/lisaac/luci-lib-docker package/lean/luci-lib-docker
#svn co https://github.com/openwrt/packages/trunk/utils/docker-ce package/lean/docker-ce
#svn co https://github.com/openwrt/packages/trunk/utils/cgroupfs-mount package/lean/cgroupfs-mount
#svn co https://github.com/openwrt/packages/trunk/utils/libnetwork package/lean/libnetwork
#svn co https://github.com/openwrt/packages/trunk/utils/tini package/lean/tini
#svn co https://github.com/openwrt/packages/trunk/utils/containerd package/lean/containerd
#svn co https://github.com/openwrt/packages/trunk/utils/runc package/lean/runc
#svn co https://github.com/openwrt/packages/trunk/lang/golang package/lang/golang
#multiwan support
#svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/luci-app-syncdial package/lean/luci-app-syncdial
#rm -rf feeds/packages/net/mwan3
#rm -rf feeds/luci/applications/luci-app-mwan3
#svn co https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-mwan3 feeds/luci/applications/luci-app-mwan3
#svn co https://github.com/coolsnowwolf/packages/trunk/net/mwan3 feeds/packages/net/mwan3
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-mwan3helper package/lean/luci-app-mwan3helper
#Zerotier
#git clone https://github.com/rufengsuixing/luci-app-zerotier package/lean/luci-app-zerotier
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/luci-app-zerotier package/lean/luci-app-zerotier
#svn co https://github.com/coolsnowwolf/packages/trunk/net/zerotier package/lean/zerotier
#OLED display
git clone https://github.com/natelol/luci-app-oled package/natelol/luci-app-oled
#CF811AC wifi driver
#svn co https://github.com/project-openwrt/openwrt/branches/openwrt-18.06-dev/package/ctcgfw/rtl8821cu package/rtl8821cu
#svn co https://github.com/project-openwrt/openwrt/trunk/package/ctcgfw/rtl8821cu package/ctcgfw/rtl8821cu
#mkdir package/base-files/files/etc/hotplug.d/usb
#wget -P package/base-files/files/etc/hotplug.d/usb https://github.com/friendlyarm/friendlywrt/raw/master-v19.07.1/package/base-files/files/etc/hotplug.d/usb/31-usb_wifi
#
#crypto

#fix some depends, useless
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/utils/fuse package/utils/fuse
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/services/samba36 package/network/services/samba36
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libconfig package/libs/libconfig
svn co https://github.com/openwrt/packages/trunk/libs/nghttp2 package/libs/nghttp2
svn co https://github.com/openwrt/packages/trunk/libs/libcap-ng package/libs/libcap-ng
rm -rf ./feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/collectd feeds/packages/utils/collectd

#最大连接
sed -i 's/16384/65536/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
#翻译
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/default-settings package/lean/default-settings
#git clone -b master --single-branch https://github.com/QiuSimons/addition-trans-zh package/lean/lean-translate
wget -O package/lean/default-settings/files/zzz-default-settings https://github.com/quintus-lab/Openwrt-R2S/raw/master/script/zzz-default-settings

#生成默认配置及缓存
rm -rf .config
#修正架构
#sed -i "s,boardinfo.system,'ARMv8',g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
chmod -R 755 ./

exit 0

####################################################################

: "已废弃选项
mkdir -p /data/data/com.termux/files/usr/etc/storage/
wget -O /data/data/com.termux/files/usr/etc/storage/DebianManager.bash 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh' >/dev/null 2>&1
chmod +x /data/data/com.termux/files/usr/etc/storage/DebianManager.bash
cp -pf /data/data/com.termux/files/usr/etc/storage/DebianManager.bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash >/dev/null 


echo '#!/data/data/com.termux/files/usr/bin/bash         '
echo '    if [ ! -d /data/data/com.termux/files/usr/etc/storage/ ]; then'
echo '   mkdir -p /data/data/com.termux/files/usr/etc/storage/'
echo '    fi'
echo ' '
echo '	if [ ! -e $PREFIX/bin/wget ]; then'
echo '		apt update;apt install -y wget ; wget -qO /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh' >/dev/null 2>&1 && bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash || bash /data/data/com.termux/files/usr/etc/storage/DebianManager.bash  || bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash '
echo '	else'
echo '	     LAST_MODIFY_TIMESTAMP=$(stat -c %Y /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash)'
echo ''
echo '         DEBIANMANAGERDATE=$(date '+%d' -d @${LAST_MODIFY_TIMESTAMP})'
echo '         if [ "${DEBIANMANAGERDATE}" ==  "$(date '+%d')" ]; then'
echo '             bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash || bash /data/data/com.termux/files/usr/etc/storage/DebianManager.bash'
echo '               else'
echo '			   	wget -qO /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash 'https://gitee.com/mo2/Termux-Debian/raw/master/debian.sh' >/dev/null 2>&1 && bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash || bash /data/data/com.termux/files/usr/etc/storage/DebianManager.bash  || bash /data/data/com.termux/files/usr/etc/storage/DebianManagerLatest.bash '
echo '             	fi	
echo '	fi
echo '			    
echo '
echo 'EndOfFile
echo '	
#下面的EndOfFile不要加单引号
cat > /data/data/com.termux/files/usr/bin/debian-root <<- EndOfFile

if [ ! -f /data/data/com.termux/files/usr/bin/tsu ]; then
        apt update
		apt install -y tsu
		fi
		
mkdir -p /data/data/com.termux/files/usr/etc/storage/
cd /data/data/com.termux/files/usr/etc/storage/

rm -rf external-tf

tsu -c 'ls /mnt/media_rw/*' 2>/dev/null || mkdir external-tf

TFcardFolder=$(tsu -c 'ls /mnt/media_rw/| head -n 1')

tsudo ln -s /mnt/media_rw/${TFcardFolder}  ./external-tf

sed -i 's:/home/storage/external-1:/usr/etc/storage/external-tf:g' /data/data/com.termux/files/usr/bin/debian


cd $PREFIX/etc/
if [ ! -f profile ]; then
        touch profile
		fi
cp -pf profile profile.bak

grep 'alias debian=' profile >/dev/null 2>&1 || sed -i  '$ a\alias debian="tsudo debian"' profile
grep 'alias debian-rm=' profile >/dev/null 2>&1 || sed -i '$ a\alias debian-rm="tsudo debian-rm"' profile

source profile >/dev/null 2>&1
alias debian="tsudo debian"
alias debian-rm="tsudo debian-rm"

echo "You have modified debian to run with root privileges, this action will destabilize debian."
echo "If you want to restore, please reinstall debian."
echo "您已将debian修改为以root权限运行，如需还原，请重新安装debian。"
echo "The next time you start debian, it will automatically run as root."
echo "下次启动debian，将自动以root权限运行。"

echo 'Debian will start automatically after 2 seconds.'
echp '2s后将为您自动启动debian'
echo 'If you do not need to display the task progress in the login interface, please manually add "#" (comment symbol) before the "ps -e" line in "~/.zshrc" or "~/.bashrc"'
echo '如果您不需要在登录界面显示任务进程，请手动注释掉"~/.zshrc"里的"ps -e"'
sleep 2
rm -f /data/data/com.termux/files/usr/bin/debian-root
tsudo debian
EndOfFile

"
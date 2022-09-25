#!/bin/bash
# v2ray centos系统一键安装脚本
# Author: hijk<https://hijk.art>

red='\033[0;31m'
green="\033[0;32m"
plain='\033[0m'

sites=(
http://www.zhuizishu.com/
http://xs.56dyc.com/
http://www.xiaoshuosk.com/
https://www.quledu.net/
http://www.ddxsku.com/
http://www.biqu6.com/
https://www.wenshulou.cc/
http://www.auutea.com/
http://www.55shuba.com/
http://www.39shubao.com/
https://www.23xsw.cc/
)

function checkSystem()
{
    result=$(id | awk '{print $1}')
    if [ $result != "uid=0(root)" ]; then
        echo "请以root身份执行该脚本"
        exit 1
    fi

    if [ ! -f /etc/centos-release ];then
        res=`which yum`
        if [ "$?" != "0" ]; then
            echo "系统不是CentOS"
            exit 1
         fi
         res=`which systemctl`
         if [ "$?" != "0" ]; then
            echo "系统版本过低，请重装系统到高版本后再使用本脚本！"
            exit 1
         fi
    else
        result=`cat /etc/centos-release|grep -oE "[0-9.]+"`
        main=${result%%.*}
        if [ $main -lt 7 ]; then
            echo "不受支持的CentOS版本"
            exit 1
         fi
    fi
}

RED="\033[31m"      # Error message
GREEN="\033[32m"    # Success message
YELLOW="\033[33m"   # Warning message
BLUE="\033[36m"     # Info message
PLAIN='\033[0m'

colorEcho() {
    echo -e "${1}${@:2}${PLAIN}"
}

slogon() {
    clear
    echo "#############################################################"
    colorEcho $RED "#         CentOS 7/8 v2ray 带伪装一键安装脚本                 #"
    echo -e "# ${GREEN}作者${PLAIN}: 网络跳越(hijk)                                      #"
    echo -e "# ${GREEN}网址${PLAIN}: https://hijk.art                                    #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://hijk.club                                   #"
    echo -e "# ${GREEN}TG群${PLAIN}: https://t.me/hijkclub                               #"
    echo -e "# ${GREEN}Youtube频道${PLAIN}: https://youtube.com/channel/UCYTB--VsObzepVJtc9yvUxQ #"
    echo "#############################################################"
    echo ""
}

function getData()
{
    IP=`curl -s -4 icanhazip.com`
    echo " "
    echo " 本脚本为带伪装的一键脚本，运行之前请确认如下条件已经具备："
     colorEcho ${YELLOW} "  1. 一个域名"
    colorEcho ${YELLOW} "  2. 域名的某个主机名解析指向当前服务器ip（${IP}）"
    colorEcho ${BLUE} "  3. 如果/root目录下有 v2ray.pem 和 v2ray.key 证书密钥文件，无需理会条件2"
    echo " "
    read -p " 确认满足按y，按其他退出脚本：" answer
    if [ "${answer}" != "y" ]; then
        exit 0
    fi
    echo ""

    while true
    do
        read -p " 请输入您的主机名：" domain
        if [ -z "${domain}" ]; then
            echo " 主机名输入错误，请重新输入！"
        else
            break
        fi
    done
    domain=${domain,,}
    colorEcho ${BLUE}  " 主机名(host)：$domain"
    echo ""

    if [[ -f ~/v2ray.pem && -f ~/v2ray.key ]]; then
        colorEcho ${BLUE}  " 检测到自有证书，将使用其部署"
        echo 
        CERT_FILE="/etc/v2ray/${domain}.pem"
        KEY_FILE="/etc/v2ray/${domain}.key"
    else
        resolve=`curl -s https://hijk.art/hostip.php?d=${domain}`
        res=`echo -n ${resolve} | grep ${IP}`
        if [[ -z "${res}" ]]; then
            colorEcho ${BLUE}  "${domain} 解析结果：${resolve}"
            colorEcho ${RED}  " 主机未解析到当前服务器IP(${IP})!"
            exit 1
        fi
    fi

    while true
    do
        read -p " 请输入伪装路径，以/开头：" path
        if [ -z "${path}" ]; then
            echo " 请输入伪装路径，以/开头！"
        elif [ "${path:0:1}" != "/" ]; then
            echo " 伪装路径必须以/开头！"
        elif [ "${path}" = "/" ]; then
            echo  " 不能使用根路径！"
        else
            break
        fi
    done
    colorEcho ${BLUE}  " 伪装路径：$path"
    echo 
    
    read -p " 请输入Nginx端口[100-65535的一个数字，默认443]：" port
    [ -z "${port}" ] && port=443
    if [ "${port:0:1}" = "0" ]; then
        echo -e " ${red}端口不能以0开头${plain}"
        exit 1
    fi
    colorEcho ${BLUE}  " Nginx端口：$port"
    echo ""

    read -p " 是否安装BBR（安装请按y，不安装请输n，默认安装）:" needBBR
    [ -z "$needBBR" ] && needBBR=y
    [ "$needBBR" = "Y" ] && needBBR=y
    
    echo ""
    colorEcho $BLUE " 请选择伪装站类型:" 
    echo "   1) 静态网站(位于/usr/share/nginx/html)"
    echo "   2) 小说站(随机选择)"
    echo "   3) 美女站(https://imeizi.me)"
    echo "   4) VPS优惠博客(https://vpsgongyi.com)"
    echo "   5) 自定义反代站点(需以http或者https开头)"
    read -p "  请选择伪装网站类型[默认:美女站]" answer
    if [[ -z "$answer" ]]; then
        PROXY_URL="https://imeizi.me"
    else
        case $answer in
        1)
            PROXY_URL=""
            ;;
        2)
            len=${#sites[@]}
            ((len--))
            while true
            do
                index=`shuf -i0-${len} -n1`
                PROXY_URL=${sites[$index]}
            done
            ;;
        3)
            PROXY_URL="https://imeizi.me"
            ;;
        4)
            PROXY_URL="https://vpsgongyi.com"
            ;;
        5)
            read -p " 请输入反代站点(以http或者https开头)：" PROXY_URL
            if [[ -z "$PROXY_URL" ]]; then
                colorEcho $RED " 请输入反代网站！"
                exit 1
            elif [[ "${PROXY_URL:0:4}" != "http" ]]; then
                colorEcho $RED " 反代网站必须以http或https开头！"
                exit 1
            fi
            ;;
        *)
            colorEcho $RED " 请输入正确的选项！"
            exit 1
        esac
    fi
}

function preinstall()
{
    ret=`nginx -t`
    if [ "$?" != "0" ]; then
        echo " 更新系统..."
        yum update -y
    fi
    echo " 安装必要软件"
    yum install -y epel-release telnet wget vim net-tools ntpdate unzip
    res=`which wget`
    [ "$?" != "0" ] && yum install -y wget
    res=`which netstat`
    [ "$?" != "0" ] && yum install -y net-tools

    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
        setenforce 0
    fi
}

getCert() {
    if [[ -z ${CERT_FILE+x} ]]; then
        systemctl stop nginx
        systemctl stop v2ray
        res=`netstat -ntlp| grep -E ':80|:443'`
        if [[ "${res}" != "" ]]; then
            colorEcho ${RED}  " 其他进程占用了80或443端口，请先关闭再运行一键脚本"
            echo " 端口占用信息如下："
            echo ${res}
            exit 1
        fi

        res=`which pip3`
        if [[ "$?" != "0" ]]; then
            yum install -y python3 python3-pip
        fi
        res=`which pip3`
        if [[ "$?" != "0" ]]; then
            colorEcho ${RED}  " pip3安装失败，请到 https://hijk.art 反馈"
            exit 1
        fi
        pip3 install --upgrade pip
        pip3 install wheel
        res=`pip3 list | grep crypto | awk '{print $2}'`
        if [[ "$res" < "2.8" ]]; then
            pip3 uninstall -y cryptography
            pip3 install cryptography
        fi
        pip3 install certbot
        res=`which certbot`
        if [[ "$?" != "0" ]]; then
            export PATH=$PATH:/usr/local/bin
        fi
        certbot certonly --standalone --agree-tos --register-unsafely-without-email -d ${domain}
        if [[ "$?" != "0" ]]; then
            colorEcho ${RED}  " 获取证书失败，请到 https://hijk.art 反馈"
            exit 1
        fi

        CERT_FILE="/etc/letsencrypt/live/${domain}/fullchain.pem"
        KEY_FILE="/etc/letsencrypt/live/${domain}/privkey.pem"
    else
        mkdir -p /etc/v2ray
        cp ~/v2ray.pem /etc/v2ray/${domain}.pem
        cp ~/v2ray.key /etc/v2ray/${domain}.key
    fi
}

function installV2ray()
{
    echo 安装v2ray...
    bash <(curl -sL https://raw.githubusercontent.com/hijkpw/scripts/master/goV2.sh)

    if [ ! -f /etc/v2ray/config.json ]; then
        echo " 安装失败，请到 https://hijk.art 网站反馈"
        exit 1
    fi

    #logsetting=`cat /etc/v2ray/config.json|grep loglevel`
    #if [ "${logsetting}" = "" ]; then
    #    sed -i '1a\  "log": {\n    "loglevel": "info",\n    "access": "/var/log/v2ray/access.log",\n    "error": "/var/log/v2ray/error.log"\n  },' /etc/v2ray/config.json
    #fi
    alterid=0
    sed -i -e "s/alterId\":.*[0-9]*/alterId\": ${alterid}/" /etc/v2ray/config.json
    uid=`cat /etc/v2ray/config.json | grep id | cut -d: -f2 | tr -d \",' '`
    v2port=`cat /etc/v2ray/config.json | grep port | cut -d: -f2 | tr -d \",' '`
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    ntpdate -u time.nist.gov
    res=`cat /etc/v2ray/config.json | grep streamSettings`
    if [ "$res" = "" ]; then
        line=`grep -n '}]' /etc/v2ray/config.json  | head -n1 | cut -d: -f1`
        line=`expr ${line} - 1`
        sed -i "${line}s/}/},/" /etc/v2ray/config.json
        sed -i "${line}a\    \"streamSettings\": {\n      \"network\": \"ws\",\n      \"wsSettings\": {\n        \"path\": \"${path}\",\n        \"headers\": {\n          \"Host\": \"${domain}\"\n        }\n      }\n    },\n    \"listen\": \"127.0.0.1\"" /etc/v2ray/config.json
    else
        sed -i -e "s/path\":.*/path\": \"\\${path}\",/" /etc/v2ray/config.json
    fi

    if [ -d /etc/systemd/system/v2ray.service.d ]; then
        rm -rf /etc/systemd/system/v2ray.service.d
    fi
    systemctl enable v2ray
    systemctl restart v2ray
    sleep 3
    res=`ss -ntlp| grep ${v2port} | grep v2ray`
    if [ "${res}" = "" ]; then
        sed -i '/Capabili/d' /etc/systemd/system/v2ray.service
        sed -i '/AmbientCapabilities/d' /etc/systemd/system/v2ray.service
        sed -i '/Capabili/d' /etc/systemd/system/multi-user.target.wants/v2ray.service
        sed -i '/AmbientCapabilities/d' /etc/systemd/system/multi-user.target.wants/v2ray.service
        systemctl daemon-reload
        systemctl restart v2ray
        sleep 3
        res=`ss -ntlp| grep ${v2port} | grep v2ray`
        if [ "${res}" = "" ]; then
            echo " 端口号：${port}，伪装路径：${path}， v2启动失败，请检查端口是否被占用或伪装路径是否有特殊字符！！"
            exit 1
         fi
    fi
    colorEcho $GREEN " v2ray安装成功！"
}

function installNginx()
{
    bt=false
    confpath="/etc/nginx/conf.d/"
    yum install -y nginx
    if [ "$?" != "0" ]; then
        res=`which nginx`
        if [ "$?" != "0" ]; then
            echo " 您安装了宝塔，请在宝塔后台安装nginx后再运行本脚本"
            exit 1
        fi
        bt=true
        confpath="/www/server/panel/vhost/nginx/"
        nginx -s stop
    else
        systemctl stop nginx
    fi
    
    getCert

    if [ "$bt" = "false" ]; then
        if [ ! -f /etc/nginx/nginx.conf.bak ]; then
            mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
        fi
        cat > /etc/nginx/nginx.conf<<-EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    gzip                on;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
}
EOF

        mkdir -p /etc/nginx/conf.d;
    fi
    
    mkdir -p /usr/share/nginx/html;
    echo 'User-Agent: *' > /usr/share/nginx/html/robots.txt
    echo 'Disallow: /' >> /usr/share/nginx/html/robots.txt
    if [[ "$PROXY_URL" = "" ]]; then
        action=""
    else
        if [[ "${PROXY_URL:0:5}" == "https" ]]; then
        action=<<EOF
        proxy_ssl_server_name on;
        proxy_pass $PROXY_URL;
EOF
        else
            action="proxy_pass $PROXY_URL;"
        fi
    fi
    cat > ${confpath}${domain}.conf<<-EOF
server {
    listen 80;
    server_name ${domain};
    return 301 https://\$server_name:${port}\$request_uri;
}
server {
    listen       ${port} ssl http2;
    server_name ${domain};
    charset utf-8;
    # ssl配置
    ssl_protocols TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
    ssl_ecdh_curve secp384r1;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_certificate $CERT_FILE;
    ssl_certificate_key $KEY_FILE;
    
    # placeholder
    # placeholder
    root /usr/share/nginx/html;
    location / {
        $action
    }
    location = /robots.txt {
    }
    location ${path} {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:${v2port};
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      # Show real IP in v2ray access.log
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

    sed -i '/certbot/d' /etc/crontab
    certbotpath=`which certbot`
    if [ "$bt" = "true" ]; then
        echo "0 3 1 */2 0 root nginx -s stop; ${certbotpath} renew ; nginx -c /www/server/nginx/conf/nginx.conf" >> /etc/crontab
    else
        echo "0 3 1 */2 0 root systemctl stop nginx ; ${certbotpath} renew ; systemctl restart nginx" >> /etc/crontab
    fi
    if [ "$bt" = "false" ]; then
        systemctl enable nginx && systemctl restart nginx
    else
        nginx -c /www/server/nginx/conf/nginx.conf
    fi
    systemctl start v2ray
    
    sleep 3
    res=`netstat -nltp | grep ${port} | grep nginx`
    if [ "${res}" = "" ]; then
        echo -e " nginx启动失败！ 请到 ${red}https://www.hijk.pw${plain} 反馈"
        exit 1
    fi
}

function setFirewall()
{
    systemctl status firewalld > /dev/null 2>&1
    if [ $? -eq 0 ];then
        firewall-cmd --permanent --add-service=http
        firewall-cmd --permanent --add-service=https
        firewall-cmd --permanent --add-port=${port}/tcp
        firewall-cmd --reload
    fi
}

function installBBR()
{
    if [ "$needBBR" != "y" ]; then
        bbr=true
        return
    fi
    result=$(lsmod | grep bbr)
    if [ "$result" != "" ]; then
        colorEcho $YELLOW BBR模块已安装
        bbr=true
        echo "3" > /proc/sys/net/ipv4/tcp_fastopen
        echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
        return;
    fi
    res=`hostnamectl | grep -i openvz`
    if [ "$res" != "" ]; then
        colorEcho $YELLOW openvz机器，跳过安装
        bbr=true
        return
    fi
    
    if [ $main -eq 8 ]; then
        echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
        sysctl -p
        bbr=true
        return
    fi

    colorEcho $BLUE 安装BBR模块...
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
    yum --enablerepo=elrepo-kernel install kernel-ml -y
    grub2-set-default 0
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    echo "3" > /proc/sys/net/ipv4/tcp_fastopen
    echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
    bbr=false
}

function info()
{
    if [ ! -f /etc/v2ray/config.json ]; then
        echo -e " ${red}未安装v2ray!${plain}"
        exit 1
    fi
    
    ip=`curl -s -4 icanhazip.com`
    res=`netstat -nltp | grep v2ray`
    [ -z "$res" ] && v2status="${red}已停止${plain}" || v2status="${green}正在运行${plain}"
    
    uid=`cat /etc/v2ray/config.json | grep id | cut -d: -f2 | tr -d \",' '`
    alterid=`cat /etc/v2ray/config.json | grep alterId | cut -d: -f2 | tr -d \",' '`
    network=`cat /etc/v2ray/config.json | grep network | cut -d: -f2 | tr -d \",' '`
    domain=`cat /etc/v2ray/config.json | grep Host | cut -d: -f2 | tr -d \",' '`
    if [ -z "$domain" ]; then
        colorEcho $RED " 不是伪装版本的v2ray"
        exit 1
    fi
    path=`cat /etc/v2ray/config.json | grep path | cut -d: -f2 | tr -d \",' '`
    confpath="/etc/nginx/conf.d/"
    if [ ! -f $confpath${domain}.conf ]; then
        confpath="/www/server/panel/vhost/nginx/"
    fi
    port=`cat ${confpath}${domain}.conf | grep -i ssl | head -n1 | awk '{print $2}'`
    security="auto"
    
    res=`netstat -nltp | grep ${port} | grep nginx`
    [ -z "$res" ] && ngstatus="${red}已停止${plain}" || ngstatus="${green}正在运行${plain}"
    
    raw="{
  \"v\":\"2\",
  \"ps\":\"\",
  \"add\":\"$ip\",
  \"port\":\"${port}\",
  \"id\":\"${uid}\",
  \"aid\":\"$alterid\",
  \"net\":\"${network}\",
  \"type\":\"none\",
  \"host\":\"${domain}\",
  \"path\":\"${path}\",
  \"tls\":\"tls\"
}"
    link=`echo -n ${raw} | base64 -w 0`
    link="vmess://${link}"

    
    echo ============================================
    echo -e " v2ray运行状态：${v2status}"
    echo -e " v2ray配置文件：${red}/etc/v2ray/config.json${plain}"
    echo -e " nginx运行状态：${ngstatus}"
    echo -e " nginx配置文件：${red}${confpath}${domain}.conf${plain}"
    echo ""
    echo -e " ${red}v2ray配置信息：${plain}               "
    echo -e "   IP(address):  ${red}${ip}${plain}"
    echo -e "   端口(port)：${red}${port}${plain}"
    echo -e "   id(uuid)：${red}${uid}${plain}"
    echo -e "   额外id(alterid)： ${red}${alterid}${plain}"
    echo -e "   加密方式(security)： ${red}$security${plain}"
    echo -e "   传输协议(network)： ${red}${network}${plain}" 
    echo -e "   主机名(host)：${red}${domain}${plain}"
    echo -e "   路径(path)：${red}${path}${plain}"
    echo -e "   安全传输(security)：${red}TLS${plain}"
    echo  
    echo " vmess链接: $link"
}

function bbrReboot()
{
    if [ "${bbr}" == "false" ]; then
        echo  
        colorEcho $BLUE  为使BBR模块生效，系统将在30秒后重启
        echo  
        echo -e " 您可以按 ctrl + c 取消重启，稍后输入 ${red}reboot${plain} 重启系统"
        sleep 30
        reboot
    fi
}


function install()
{
    echo -n " 系统版本:  "
    cat /etc/centos-release

    checkSystem
    getData
    preinstall
    installBBR
    installV2ray
    setFirewall
    installNginx
    
    info
    bbrReboot
}

function uninstall()
{
    read -p " 确定卸载v2ray吗？(y/n)" answer
    [ -z ${answer} ] && answer="n"

    if [ "${answer}" == "y" ] || [ "${answer}" == "Y" ]; then
        systemctl stop v2ray
        systemctl disable v2ray
        domain=`cat /etc/v2ray/config.json | grep Host | cut -d: -f2 | tr -d \",' '`
        rm -rf /etc/v2ray/*
        rm -rf /usr/bin/v2ray/*
        rm -rf /var/log/v2ray/*
        rm -rf /etc/systemd/system/v2ray.service
        rm -rf /etc/systemd/system/multi-user.target.wants/v2ray.service

        yum remove -y nginx
        if [ -d /usr/share/nginx/html.bak ]; then
            rm -rf /usr/share/nginx/html
            mv /usr/share/nginx/html.bak /usr/share/nginx/html
        fi
        rm -rf /etc/nginx/conf.d/${domain}.conf
        echo -e " ${red}卸载成功${plain}"
    fi
}

slogon

action=$1
[ -z $1 ] && action=install
case "$action" in
    install|uninstall|info)
        ${action}
        ;;
    *)
        echo " 参数错误"
        echo " 用法: `basename $0` [install|uninstall|info]"
        ;;
esac

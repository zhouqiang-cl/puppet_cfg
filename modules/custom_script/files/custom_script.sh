#!/bin/bash
# 自定义脚本, 用于执行不好写成配置文件的脚本.
 

# 设置一些环境变量
source /etc/profile


# 设置 bashrc
if ! grep 'source /etc/bashrc' /etc/profile >/dev/null
then
cat >> /etc/profile  <<EOF
if [ \$SHELL == /bin/bash ]; then
source /etc/bashrc
fi
EOF
fi


# 历史命令长度和格式
if ! grep "HISTSIZE=10240" /etc/profile
then
    sed -i '/^HISTSIZE=/c\HISTSIZE=10240' /etc/profile
fi

if ! grep 'export HISTTIMEFORMAT="%F %T' /etc/bashrc 
then
    echo 'export HISTTIMEFORMAT="%F %T "' >>/etc/bashrc
fi


# 修改 PS1
if ! grep PS1= /etc/profile |grep '[\u@\H:\w]'
then
cat >> /etc/profile  <<EOF
export PS1='[\u@\H:\w]\\$ '
EOF
fi


# 设置语言
if ! grep 'LANGUAGE=en_US.UTF-8' /etc/profile
then
cat >> /etc/profile  <<EOF
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
EOF
fi


# 关闭 mail
if ! grep "unset MAILCHECK" /etc/profile
then
    echo "unset MAILCHECK" >>/etc/profile
fi


###


# 去掉 alias rm
if test -f /root/.bashrc
then
    sed -i "/alias rm=/s/^/#/" /root/.bashrc
    sed -i "/alias cp=/s/^/#/" /root/.bashrc
    sed -i "/alias mv=/s/^/#/" /root/.bashrc
fi
for i in op work 
do
    sed -i "/alias rm=/s/^/#/" /home/$i/.bashrc
    sed -i "/alias cp=/s/^/#/" /home/$i/.bashrc
    sed -i "/alias mv=/s/^/#/" /home/$i/.bashrc
done


# 修改 vimrc 
if ! grep "set background=dark" /etc/vimrc
then
    echo "set background=dark" >>/etc/vimrc
fi


# 配置 SSHD
if grep -P "PermitRootLogin\s+yes" /etc/ssh/sshd_config
then
    sed -i '/PermitRootLogin/ c\PermitRootLogin no' /etc/ssh/sshd_config
    service sshd reload
fi
if grep -P "UseDNS\s+yes" /etc/ssh/sshd_config
then
    sed -i '/UseDNS/ c\UseDNS no' /etc/ssh/sshd_config
    service sshd reload
fi


# 禁用 gpgcheck
sed -i "/^gpgcheck=1/s/gpgcheck=1/gpgcheck=0/" /etc/yum.conf


# 修改 lvm 权限
sed -i 's/umask = 077/umask = 022/g' /etc/lvm/lvm.conf


# 修改 hashsize
if test -f /sys/module/nf_conntrack/parameters/hashsize
then
    echo 64000 > /sys/module/nf_conntrack/parameters/hashsize
fi


# 修改 sendmail 和 mail 使用的默认 mx 服务器  
if ! ps -ef |grep /usr/libexec/postfix/master |grep -v grep
then
    if ! grep mx.hy01.nosa.me /etc/mail/sendmail.cf 
    then
        if grep ^DS /etc/mail/sendmail.cf
        then
            sed -i "/^DS/s/.*/DSmx.hy01.nosa.me/" /etc/mail/sendmail.cf
            service sendmail restart 
        fi
    fi

    if ! service sendmail status
    then
        service sendmail restart
    fi
fi



# 单用户密码
## Centos6
if test -f /boot/grub/grub.conf &&! grep "^password" /boot/grub/grub.conf
then
    sed -i '/splashimage/a password sre123.nosa.me'  /boot/grub/grub.conf
fi
### Centos7
#if test -f /boot/grub2/grub.cfg &&
#then
#    cp /boot/grub2/grub.cfg /boot/grub2/grub.cfg.orig
#    cp /etc/grub.d/10_linux /tmp/10_linux.orig
#    echo 'set superusers="root" password root sre123.nosa.me' >>/etc/grub.d/10_linux
#    grub2-mkconfig --output=/tmp/grub2.cfg
#    mv /boot/grub2/grub.cfg /boot/grub2/grub.cfg.move
#    mv /tmp/grub2.cfg /boot/grub2/grub.cfg
#fi


# 如果没有 /sbin/MegaCli, 做软链, MegaCli 包由 site.pp 保证安装 
if ! [ -f /sbin/MegaCli ]
then
    [ -f /opt/MegaRAID/MegaCli/MegaCli64 ] && /bin/ln -s /opt/MegaRAID/MegaCli/MegaCli64 /sbin/MegaCli
fi


# 如果是物理机, 设置控制卡密码
if /sbin/lspci |grep NetXtreme |grep -q BCM 
then
    service ipmi status ||service ipmi restart
    /usr/bin/ipmitool user set password 1 nosa.me
    /usr/bin/ipmitool user set password 2 nosa.me
fi


# 增加 ttyS0
if ! grep 'ttyS0' /etc/securetty >/dev/null
then
    echo 'ttyS0' >> /etc/securetty
fi


# 不使用 ipv6
if ! grep NETWORKING_IPV6 /etc/sysconfig/network
then
    echo "NETWORKING_IPV6=no" >>/etc/sysconfig/network
else
    sed -i /NETWORKING_IPV6/cNETWORKING_IPV6=no /etc/sysconfig/network
fi


# 修改 Motd 
for i in motd issue issue.net
do
    if ! grep "Authorized users only.  All activity may be monitored and reported" /etc/"$i" >/dev/null
    then
        echo "Authorized users only.  All activity may be monitored and reported" >> /etc/"$i"
    fi
done


# 启用日志压缩
if grep "^#compress" /etc/logrotate.conf 
then
    sed -i 's/\#compress/compress/' /etc/logrotate.conf
fi


# 资源限制
if ! grep -P "\*\s+soft\s+nofile" /etc/security/limits.conf
then
    echo "*             soft   nofile          655360" >>/etc/security/limits.conf
fi
if ! grep -P "\*\s+hard\s+nofile" /etc/security/limits.conf
then
    echo "*             hard   nofile          655360" >>/etc/security/limits.conf
fi
if ! grep -P "\*\s+soft\s+nproc" /etc/security/limits.conf
then
    echo "*             soft   nproc           8192" >>/etc/security/limits.conf
fi
if ! grep -P "\*\s+hard\s+nproc" /etc/security/limits.conf
then
    echo "*             hard   nproc           8192" >>/etc/security/limits.conf
fi

## Centos6 的 nproc 需修改此文件
if test -f /etc/security/limits.d/90-nproc.conf &&! grep -P "\*\s+soft\s+nproc\s+8192" /etc/security/limits.d/90-nproc.conf 
then
    sed -i "/*          soft    nproc/s/.*/*          soft    nproc     8192/g" /etc/security/limits.d/90-nproc.conf
fi
## Centos7 的 nproc 需修改此文件
if test -f /etc/security/limits.d/20-nproc.conf &&! grep -P "\*\s+soft\s+nproc\s+8192" /etc/security/limits.d/20-nproc.conf
then
    sed -i "/*          soft    nproc/s/.*/*          soft    nproc     8192/g" /etc/security/limits.d/20-nproc.conf
fi


# 打开 core
if ! grep -P "work\s+soft\s+core" /etc/security/limits.conf
then
    echo "work             soft   core            unlimited" >>/etc/security/limits.conf
fi
if ! grep -P "work\s+hard\s+core" /etc/security/limits.conf
then
    echo "work             hard   core            unlimited" >>/etc/security/limits.conf
fi


# core 的路径
if ! cat /proc/sys/kernel/core_pattern |grep '/home/work/coredump/%e.core.%p.%t'
then
    echo '/home/work/coredump/%e.core.%p.%t' >/proc/sys/kernel/core_pattern
fi


# 保证 work 和 op 用户的存在(已经使用配置文件保持, 此处忽略)
#if ! id op
#then
#    useradd op -u 2001 -U -G wheel -K PASS_MAX_DAYS=99999 -K PASS_MIN_DAYS=0
#fi
#if ! id work
#then
#    useradd work -u 2000 -U -G wheel -K PASS_MAX_DAYS=99999 -K PASS_MIN_DAYS=0
#fi


# 保证密码
echo '123456' |passwd root --stdin
echo '123456' |passwd op --stdin
echo '123456' |passwd work --stdin


# 保证 op 和 work 的 .bash_profile, .bash_logout 和 .bashrc 存在
for user in op work
do
  if ! test -f /home/$user/.bash_profile
  then
    /bin/cp -f /etc/skel/.bash_profile /home/$user/.bash_profile
    chown $user:$user /home/$user/.bash_profile
  fi

  if ! test -f /home/$user/.bash_logout
  then
    /bin/cp -f /etc/skel/.bash_logout /home/$user/.bash_logout
    chown $user:$user /home/$user/.bash_logout
  fi

  if ! test -f /home/$user/.bashrc
  then
    /bin/cp -f /etc/skel/.bashrc /home/$user/.bashrc
    chown $user:$user /home/$user/.bashrc
  fi
done


# wheel 可以不用密码 sudo 到 root, 同时修改 op 和 work 不用 tty
# (已经通过配置保持, 此处注释)
#grep "^ *%wheel" /etc/sudoers || echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
#grep "Defaults:op \!requiretty" /etc/sudoers ||echo 'Defaults:op !requiretty' >> /etc/sudoers
#grep "Defaults:work \!requiretty" /etc/sudoers ||echo 'Defaults:work !requiretty' >> /etc/sudoers


# 保证 op 和 work 的信任关系存在(已经通过配置保持, 此处注释)
#common=''
#op=''
#work=''
#
#for i in /home/work/.ssh/ /home/op/.ssh/
#do
#    if ! test -d $i 
#    then
#        mkdir -p $i
#    fi
#done
#
#for i in /home/work/.ssh/authorized_keys /home/op/.ssh/authorized_keys
#do
#    if ! test -f $i 
#    then
#        touch $i
#    fi
#done
#
#for file in /home/work/.ssh/authorized_keys /home/op/.ssh/authorized_keys
#do
#    if ! grep -q "$common" $file
#    then
#        echo "$common" >>$file
#    fi
#done
#
#if ! grep -q "$work" /home/work/.ssh/authorized_keys
#then
#    echo "$work" >>/home/work/.ssh/authorized_keys
#fi
#if ! grep -q "$op" /home/op/.ssh/authorized_keys
#then
#    echo "$op" >>/home/op/.ssh/authorized_keys
#fi
#
#chown op:op -R /home/op/.ssh/
#chown work:work -R /home/work/.ssh/
#chmod 750 /home/work/.ssh/
#chmod 750 /home/op/.ssh/
#chmod 640 /home/work/.ssh/authorized_keys
#chmod 640 /home/op/.ssh/authorized_keys


# 修改权限
if test -f /var/spool/cron/op
then
    chown op:op /var/spool/cron/op
fi
if test -f /var/spool/cron/work
then
    chown work:work /var/spool/cron/work
fi


# 只保留 nosa.repo
for i in `ls /etc/yum.repos.d/*`
do
    if ! echo $i |grep -q /etc/yum.repos.d/nosa.repo
    then
        /bin/rm -f $i
        yum clean all
    fi 
done

 
# 修复 glibc 漏洞
if ! rpm -q glibc |grep -q glibc-2.12-1.149.el6_6.5.x86_64 
then
    yum clean all ;yum -y update glibc
fi 


# 禁用 ipv6
if test -f /proc/sys/net/ipv6/conf/all/disable_ipv6
then
    _x=`cat /proc/sys/net/ipv6/conf/all/disable_ipv6`
    if [[ "${_x}" -eq "0" ]]
    then
        echo 1 >/proc/sys/net/ipv6/conf/all/disable_ipv6
        service sshd restart ||systemctl restart sshd.service
    fi
fi
if test -f /proc/sys/net/ipv6/conf/default/disable_ipv6
then
    _y=`cat /proc/sys/net/ipv6/conf/default/disable_ipv6`
    if [[ "${_y}" -eq "0" ]]
    then
        echo 1 >/proc/sys/net/ipv6/conf/default/disable_ipv6
        service sshd restart ||systemctl restart sshd.service
    fi
fi


# 配置内核, 远程下载脚本
# 如果上面没有 source /etc/profile, 可能会报 ValueError
wget -q -O- http://pxe.hy01.nosa.me/script/kernel_conf.py |python 

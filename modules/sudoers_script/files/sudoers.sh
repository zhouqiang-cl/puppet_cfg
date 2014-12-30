#!/bin/bash


#grep ^wheel /etc/group |grep "op,work" || sed -i "/^wheel/s/$/,op,work/g" /etc/group

grep "^ *%wheel" /etc/sudoers || echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

grep "Defaults:op \!requiretty" /etc/sudoers ||echo 'Defaults:op !requiretty' >> /etc/sudoers

grep "Defaults:work \!requiretty" /etc/sudoers ||echo 'Defaults:work !requiretty' >> /etc/sudoers



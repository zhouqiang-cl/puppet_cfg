#!/bin/bash


common=''
op=''
work=''


if ! test -d /home/work/.ssh/
then
  mkdir -p /home/work/.ssh/
fi

if ! test -d /home/op/.ssh/
then
  mkdir -p /home/op/.ssh/
fi


if ! test -f /home/work/.ssh/authorized_keys
then
  touch /home/work/.ssh/authorized_keys
fi

if ! test -f /home/op/.ssh/authorized_keys
then
  touch /home/op/.ssh/authorized_keys
fi


for file in /home/work/.ssh/authorized_keys /home/op/.ssh/authorized_keys
do
  if ! grep -q "$common" $file
  then
    echo "$common" >> $file
  fi
done


if ! grep -q "$work" /home/work/.ssh/authorized_keys
then
  echo "$work" >> /home/work/.ssh/authorized_keys
fi

if ! grep -q "$op" /home/op/.ssh/authorized_keys
then
  echo "$op" >> /home/op/.ssh/authorized_keys
fi

chown op:op -R /home/op/.ssh/
chown work:work -R /home/work/.ssh/

chmod 750 /home/work/.ssh/
chmod 750 /home/op/.ssh/

chmod 640 /home/work/.ssh/authorized_keys
chmod 640 /home/op/.ssh/authorized_keys



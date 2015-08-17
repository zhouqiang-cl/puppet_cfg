#!/usr/bin/python
#-*- coding: utf-8 -*-

import sys
import re
import json

import requests
import yaml


IDS = {
    "online_ng_external": [
        2394,
        2388,
        2401,
        2397,
        2405
    ],
    "online_ng_internal": [
        2392,
        2389,
        2400,
        2396,
        2404
    ],
    "log_ng": [
        2338
    ],
    "online_cdn_proxy": [
        2169
    ],
    "ntp_server": [
        2574
    ]
}

KEYS = {
    "relay": "relay",
    "vmh": "vmh_common",
    "cobar": "cobar"
}

IGNORE_ID = 2980


def get_hostname_from_loki(node_id):
    url = "http://loki.hy01.internal.wandoujia.com/server/api/servers?"\
            "type=recursive&node_id=%s" % node_id

    ret = requests.get(url)
    return [i["hostname"] for i in json.loads(ret.content)["data"]]


def get_classes_to_nodes():
    classes_to_nodes = {}
    for classes in IDS:
        nodes = []
        for id in IDS[classes]:
            ret = get_hostname_from_loki(id)
            nodes.extend(ret)
        classes_to_nodes[classes] = nodes
    return classes_to_nodes


def main():
    hostname = sys.argv[1].replace(".wandoujia.com", "")

    # 如果 hostname 在 IGNORE_ID 包换的列表里, 啥也不做.
    ignore_hosts = get_hostname_from_loki(IGNORE_ID)
    if hostname in ignore_hosts:
        _conf = {
            "classes":
            ["puppet_class"]
        }
        print yaml.dump(_conf, explicit_start=True, \
            default_flow_style=False)
        return

    # 如果 hostname 匹配 KEYS 里面关键字, 返回相应的配置.
    for i in KEYS:
        if re.match("^%s" % i, hostname):
            _conf = {
                "classes":
                [KEYS[i]]
            }
            print yaml.dump(_conf, explicit_start=True, \
                default_flow_style=False)
            return

    # 从 loki 上获取节点来配置.
    classes_to_nodes = get_classes_to_nodes()
    for classes in classes_to_nodes:
        if hostname in classes_to_nodes[classes]:
            _classes = classes
            break

    if "_classes" not in locals():   # 添加默认配置.
        _classes = "puppet_default"
    _conf = {
        "classes":
        [_classes]
    }
    print yaml.dump(_conf, explicit_start=True, \
        default_flow_style=False)


if __name__ == '__main__':
    main()

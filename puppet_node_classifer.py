#!/usr/bin/python
#-*- coding: utf-8 -*-


import sys
import requests
import json
import re

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

IGNORES = ["ignore0.nosa01"]


def get_hostnames_from_sys(node_id):
    url = "http://sys.hy01.internal.nosa.me/server/api/servers?"\
            "type=recursive&node_id=%s" % node_id

    try:
        ret = requests.get(url)
        data_list = json.loads(ret.content)["data"]
        hostname_list = [i["hostname"] for i in data_list]
        return (True, hostname_list)
    except Exception, e:
        return (False, "%s" % e)


def get_classes_to_nodes():
    _classes_to_nodes = {}
    for classes in IDS:
        nodes = []
        for _id in IDS[classes]:
            _ret = get_hostnames_from_sys(_id)
            if not _ret[0] :
                return (False, _ret[1])
            else:
                nodes.extend(_ret[1])  
        _classes_to_nodes[classes] = nodes
    return (True, _classes_to_nodes)


def main():
    hostname = sys.argv[1].replace(".nosa.me", "")

    # 如果 hostname 在 IGNORES 里面, 啥也不做. 
    if hostname in IGNORES:
        print yaml.dump({})
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

    # 从 sys 上获取节点来配置.
    _ret = get_classes_to_nodes()
    if not _ret[0]:
        print _ret[1]
        sys.exit(1)
    classes_to_nodes = _ret[1]
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

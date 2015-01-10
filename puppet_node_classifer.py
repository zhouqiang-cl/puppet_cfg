#!/usr/bin/python
#-*- coding: utf-8 -*-


import sys
import requests
import json

import yaml


IDS = {
    "ntp_server": [
        2574
    ]
}


def get_hostnames_from_loki(node_id):
    url = "http://api.xxx.com/server/api/servers?"\
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
            _ret = get_hostnames_from_loki(_id)
            if not _ret[0] :
                return (False, _ret[1])
            else:
                nodes.extend(_ret[1])  
        _classes_to_nodes[classes] = nodes
    return (True, _classes_to_nodes)


def main():
    hostname = sys.argv[1].replace(".wandoujia.com", "")
    _ret = get_classes_to_nodes()
    if not _ret[0]:
        print _ret[1]
        sys.exit(1)
    classes_to_nodes = _ret[1]
    for classes in classes_to_nodes:
        if hostname in classes_to_nodes[classes]:
            _classes = classes
            break

    # 设默认值.
    if "_classes" not in locals():
        _classes = "puppet_default" 

    _conf = {
        "classes":
        [_classes]
    }
    print yaml.dump(_conf, explicit_start=True, default_flow_style=False)
    

if __name__ == '__main__':
    main()

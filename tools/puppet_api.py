#!/usr/bin/python
# -*- coding: utf-8 -*-


import json
import requests
from requests import Request, Session


dashboard_host = "puppetdashboard.corp.nosa.me"
certificate_host = "puppetca1.nosa01:8140"


requests.packages.urllib3.disable_warnings()


def hosts_failed():
    """ 查找哪些机器 Puppet 执行失败.

    curl 命令格式如下:
        curl -H "Accept: application/json" http://dashboard_host/nodes/failed

    """
    url = "http://%s/nodes/failed" % dashboard_host
    r = requests.get(url, headers={"Accept":"application/json"})

    return [ i["name"] for i in json.loads(r.text) ]


def certificate_get(hostname):
    """ 查看给定机器的证书信息.

    curl 命令格式如下:
        curl -k -H 'Accept: pson' https://certificate_host/production/certificate_status/hostname

    """
    url = "https://%s/production/certificate_status/%s" % (certificate_host, hostname)
    s = Session()
    req = Request('GET', url,
        headers={"Accept": "pson"}
    )
    prepped = req.prepare()
    r = s.send(prepped,
        verify=False,
    )
    return r.status_code, r.text


def certificate_delete(hostname):
    """ 删除给定机器的证书.

    curl 命令格式如下:
        curl -k -X DELETE -H 'Accept: pson' https://certificate_host/production/certificate_status/hostname

    """
    url = "https://%s/production/certificate_status/%s" % (certificate_host, hostname)
    s = Session()
    req = Request('DELETE', url,
        headers={"Accept": "pson"}
    )
    prepped = req.prepare()
    r = s.send(prepped,
        verify=False,
    )
    return r.status_code, r.text


if __name__ == "__main__":
     hostname = "pxe0.hy01.nosa.me"
     print certificate_get(hostname)
     print certificate_delete(hostname)
     print certificate_get(hostname)

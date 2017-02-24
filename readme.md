## IKEv2 VPN 全自动化配置

### 服务器配置

首先修改脚本，

```
ip=1.1.1.1
nic=eth0

eap_user=myusername
eap_pass=astrongpassword
```

修改你的公网IP、公网NIC、EAP 账号和密码

然后执行 `ipsec-configure.sh` 即可

### 客户端配置

首先需要信任 CA，只信任 IPSec 方式即可

连接使用 IPSec + EAP 方式

### 已知问题

1. 只支持IP方式，如要支持域名方式，请修改脚本里面的 leftid
2. 只支持 Ubuntu 16.04

### 参考文档

[参考了 DO 的文档](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-16-04)

Well，简化了它的命令


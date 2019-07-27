## IKEv2 VPN 全自动化配置（仅支持 Ubuntu 18.04）

安装软件、创建 EAP 随机密码

```bash
bash ipsec-configure.sh -i YOUR_IP -n YOUR_NIC
```

之后在客户端导入 CA，可以用 iCloud、邮件等方式同步到手机

### 已知问题

1. 只支持IP方式，如要支持域名方式，请修改脚本里面的 leftid
2. 重复运行，会重新创建证书

### 参考文档

* [How to Set Up an IKEv2 VPN Server with StrongSwan on Ubuntu 16.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-16-04)




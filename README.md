## Ansible Role JeffWen0105.check_ports

對於網管人員在防火牆設定是否生效，時常需要連線至該主機使用 telnet 或是 nc 方式檢查，有些作業系統沒有內建上述的套件也無法很快地安裝及為了使用更快速的方式檢查，我們會需要透過 Jump 主機(Bastion or Capsule)使用 Ansible 檢查。
此 Role 會依使用者所需產生一個檢測腳本，並避免 coreos 等輕量級作業系統缺少對應的 module 改用 synchronize 方式及執行腳本。

## Requirement

1. ansible core 套件
2. rsync 套件




## Example

範例以一般 Linux 與 CoreOS 說明

### 1. Linux

1. 定義四台受控端機器在 inventory 。

```
[server]
172.25.250.11
172.25.250.12
172.25.250.13
172.25.250.14
```

2. 設置要檢查的主機、通訊埠及TCP/UDP通訊協定在 check_file.yml 內。

*參數詳情請參閱最下方 Role Variables 說明*

**可以設置多台主機及每台主機也能設置多個 port，不過請務必注意縮排 !!** 

```
servers:
  - host: 8.8.8.8
    protocol: udp
    ports:
      - 123
      - 53
  - host: 127.0.0.1
    protocol: tcp
    ports:
      - 22
      - 80
  - host: google.com
    protocol: tcp
    ports:
      - 22
      - 443
```

3. 執行範例 playbook.yml 

*Ansible 最佳實踐直接將 JeffWen0105.check_ports 的 role 加入自定義 playbook內即可。*

```
[student@bastion 03-Ansible_Role_check_Ports]$ ansible-playbook playbook.yml
...output omitted...
TASK [JeffWen0105.check_ports : summary result] *******************************************************
ok: [172.25.250.11] => {
    "msg": [
        "📝 Test port on servera:",
        " 👍 Success at 8.8.8.8:123",
        " 👍 Success at 8.8.8.8:53",
        " 👍 Success at 127.0.0.1:22",
        " 📛 Failure at 127.0.0.1:80",
        " 📛 Failure at google.com:22",
        " 👍 Success at google.com:443"
    ]
}
ok: [172.25.250.12] => {
    "msg": [
        "📝 Test port on serverb:",
        " 👍 Success at 8.8.8.8:123",
        " 👍 Success at 8.8.8.8:53",
        " 👍 Success at 127.0.0.1:22",
        " 📛 Failure at 127.0.0.1:80",
        " 📛 Failure at google.com:22",
        " 👍 Success at google.com:443"
    ]
}
...output omitted...
```

### 2. CoreOS

1. 設定執行參數

囿於 CoreOS 與一般 Linux 有些許差異，需設定下列參數至 ansible.cfg

```
### for coreos example
remote_user        = core
ansible_python_interpreter="PATH=/home/core/bin:$PATH python3"
private_key_file=./<ssh to coreos private key>
```

2. coreos 執行結果

```
[howhow@ocp4 ansible_role_check_ports]$ oc get no
NAME                         STATUS   ROLES                  AGE     VERSION
master-1.ocp4.how64bit.com   Ready    control-plane,master   4h40m   v1.25.4+a34b9e9
worker-1.ocp4.how64bit.com   Ready    worker                 4h25m   v1.25.4+a34b9e9
worker-2.ocp4.how64bit.com   Ready    worker                 4h25m   v1.25.4+a34b9e9
[howhow@ocp4 ansible_role_check_ports]$ ansible-playbook playbook.yml 
...output omitted...
TASK [JeffWen0105.check_ports : summary result] *******************************************
ok: [192.168.122.188] => {
    "msg": [
        "📝 Test port on master-1.ocp4.how64bit.com:",
        " 👍 Success at 8.8.8.8:123",
        " 👍 Success at 8.8.8.8:53",
        " 👍 Success at 127.0.0.1:22",
        " 👍 Success at 127.0.0.1:80",
        " 📛 Failure at google.com:22",
        " 👍 Success at google.com:443"
    ]
}
ok: [192.168.122.171] => {
    "msg": [
        "📝 Test port on worker-1.ocp4.how64bit.com:",
        " 👍 Success at 8.8.8.8:123",
        " 👍 Success at 8.8.8.8:53",
        " 👍 Success at 127.0.0.1:22",
        " 📛 Failure at 127.0.0.1:80",
        " 📛 Failure at google.com:22",
        " 👍 Success at google.com:443"
    ]
}
ok: [192.168.122.29] => {
    "msg": [
        "📝 Test port on worker-2.ocp4.how64bit.com:",
        " 👍 Success at 8.8.8.8:123",
        " 👍 Success at 8.8.8.8:53",
        " 👍 Success at 127.0.0.1:22",
        " 📛 Failure at 127.0.0.1:80",
        " 📛 Failure at google.com:22",
        " 👍 Success at google.com:443"
    ]
}
...output omitted...
```


## Role Variables


| Variable | 用途                     |
| -------- | ------------------------|
| servers  | 預設參數，務必加上        |
| host     | 檢測主機，主機名或是 IP   | 
| protocol | tcp/upd                 |
| ports    | 檢測通訊阜以List陣列延伸  |


## 產生腳本 Example

```
#!/bin/bash


# powered by HowHowWen
# Blog : https://how64bit.com
# Mail : blog@how64bit.com


export TIMEOUT_SECONDS=1
export LOCAL_HOST_NAME="$(hostname)"
export DEVICE_PATH_LIST=(
      "/dev/tcp/127.0.0.1/22"
      "/dev/tcp/127.0.0.1/80"
  )

printf "\U1F4DD Test port on ${LOCAL_HOST_NAME}:\n"
for device_path in "${DEVICE_PATH_LIST[@]}"; do
    export HOST=$(echo "$device_path" | cut -d '/' -f 4)
    export PORT=$(echo "$device_path" | cut -d '/' -f 5)
    timeout $TIMEOUT_SECONDS bash -c "echo 'What is up by howhow ...' >${device_path}" 2>/dev/null && \
    printf " \U1F44D Success at $HOST:$PORT" ||  printf " \U1F4DB Failure at $HOST:$PORT"
    echo 
done
```
# Домашняя работа по занятию "12.1 Компоненты Kubernetes"

>## Задача 1: Установить Minikube

>- проверить версию можно командой minikube version

```
root@test-xu20:~# minikube version
minikube version: v1.24.0
commit: 76b94fb3c4e8ac5062daf70d60cf03ddcc0a741b
```
>- переключаемся на root и запускаем миникуб: minikube start --vm-driver=none
```
root@test-xu20:~# minikube start --vm-driver=none
😄  minikube v1.24.0 on Ubuntu 20.04
✨  Using the none driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🤹  Running on localhost (CPUs=24, Memory=32120MB, Disk=447169MB) ...
ℹ️  OS release is Ubuntu 20.04.3 LTS
🐳  Preparing Kubernetes v1.22.3 on Docker 20.10.8 ...
    ▪ kubelet.resolv-conf=/run/systemd/resolve/resolv.conf
    > kubeadm.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubectl.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubelet.sha256: 64 B / 64 B [--------------------------] 100.00% ? p/s 0s
    > kubeadm: 43.71 MiB / 43.71 MiB [------------] 100.00% 70.57 MiB p/s 800ms
    > kubelet: 115.57 MiB / 115.57 MiB [-----------] 100.00% 88.65 MiB p/s 1.5s
    > kubectl: 44.73 MiB / 44.73 MiB [-------------] 100.00% 16.34 MiB p/s 2.9s
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🤹  Configuring local host environment ...

❗  The 'none' driver is designed for experts who need to integrate with an existing VM
💡  Most users should use the newer 'docker' driver instead, which does not require root!
📘  For more information, see: https://minikube.sigs.k8s.io/docs/reference/drivers/none/

❗  kubectl and minikube configuration will be stored in /root
❗  To use kubectl or minikube commands as your own user, you may need to relocate them. For example, to overwrite your own settings, run:

    ▪ sudo mv /root/.kube /root/.minikube $HOME
    ▪ sudo chown -R $USER $HOME/.kube $HOME/.minikube

💡  This can also be done automatically by setting the env var CHANGE_MINIKUBE_NONE_USER=true
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

> - после запуска стоит проверить статус: minikube status

```
root@test-xu20:~# minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

> - запущенные служебные компоненты можно увидеть командой: kubectl get pods --namespace=kube-system

```
root@test-xu20:~# kubectl get pods --namespace=kube-system
NAME                                READY   STATUS    RESTARTS   AGE
coredns-78fcd69978-lvxv8            1/1     Running   0          24m
etcd-test-xu20                      1/1     Running   3          24m
kube-apiserver-test-xu20            1/1     Running   3          24m
kube-controller-manager-test-xu20   1/1     Running   13         24m
kube-proxy-lcwkf                    1/1     Running   0          24m
kube-scheduler-test-xu20            1/1     Running   13         24m
storage-provisioner                 1/1     Running   0          24m
```

---
> ## Задача 2: Запуск Hello World
> После установки Minikube требуется его проверить. Для этого подойдет стандартное приложение hello world. А для доступа к нему потребуется ingress.

> - развернуть через Minikube тестовое приложение по [туториалу](https://kubernetes.io/ru/docs/tutorials/hello-minikube/#%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5-%D0%BA%D0%BB%D0%B0%D1%81%D1%82%D0%B5%D1%80%D0%B0-minikube)

```
root@test-xu20:~# minikube service hello-node --url
http://176.56.186.111:30612

[mak@mak-ws ~]$ curl http://176.56.186.111:30612
CLIENT VALUES:
client_address=172.17.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://176.56.186.111:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=176.56.186.111:30612
user-agent=curl/7.65.0-DEV
BODY:
-no body in request-

```
- установить аддоны ingress и dashboard

```
root@test-xu20:~# minikube addons enable dashboard
    ▪ Using image kubernetesui/metrics-scraper:v1.0.7
    ▪ Using image kubernetesui/dashboard:v2.3.1
💡  Some dashboard features require the metrics-server addon. To enable all features please run:

	minikube addons enable metrics-server	


🌟  The 'dashboard' addon is enabled
root@test-xu20:~# minikube addons enable ingress
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
    ▪ Using image k8s.gcr.io/ingress-nginx/controller:v1.0.4
    ▪ Using image k8s.gcr.io/ingress-nginx/kube-webhook-certgen:v1.1.1
🔎  Verifying ingress addon...
🌟  The 'ingress' addon is enabled

root@test-xu20:~# minikube addons list 
|-----------------------------|----------|--------------|-----------------------|
|         ADDON NAME          | PROFILE  |    STATUS    |      MAINTAINER       |
|-----------------------------|----------|--------------|-----------------------|
| ambassador                  | minikube | disabled     | unknown (third-party) |
| auto-pause                  | minikube | disabled     | google                |
| csi-hostpath-driver         | minikube | disabled     | kubernetes            |
| dashboard                   | minikube | enabled ✅   | kubernetes            |
| default-storageclass        | minikube | enabled ✅   | kubernetes            |
| efk                         | minikube | disabled     | unknown (third-party) |
| freshpod                    | minikube | disabled     | google                |
| gcp-auth                    | minikube | disabled     | google                |
| gvisor                      | minikube | disabled     | google                |
| helm-tiller                 | minikube | disabled     | unknown (third-party) |
| ingress                     | minikube | enabled ✅   | unknown (third-party) |
| ingress-dns                 | minikube | disabled     | unknown (third-party) |
| istio                       | minikube | disabled     | unknown (third-party) |
| istio-provisioner           | minikube | disabled     | unknown (third-party) |
| kubevirt                    | minikube | disabled     | unknown (third-party) |
| logviewer                   | minikube | disabled     | google                |
| metallb                     | minikube | disabled     | unknown (third-party) |
| metrics-server              | minikube | disabled     | kubernetes            |
| nvidia-driver-installer     | minikube | disabled     | google                |
| nvidia-gpu-device-plugin    | minikube | disabled     | unknown (third-party) |
| olm                         | minikube | disabled     | unknown (third-party) |
| pod-security-policy         | minikube | disabled     | unknown (third-party) |
| portainer                   | minikube | disabled     | portainer.io          |
| registry                    | minikube | disabled     | google                |
| registry-aliases            | minikube | disabled     | unknown (third-party) |
| registry-creds              | minikube | disabled     | unknown (third-party) |
| storage-provisioner         | minikube | enabled ✅   | kubernetes            |
| storage-provisioner-gluster | minikube | disabled     | unknown (third-party) |
| volumesnapshots             | minikube | disabled     | kubernetes            |
|-----------------------------|----------|--------------|-----------------------|

```
---

>## Задача 3: Установить kubectl
>Подготовить рабочую машину для управления корпоративным кластером. Установить клиентское приложение kubectl.
>- подключиться к minikube 
>- проверить работу приложения из задания 2, запустив port-forward до кластера

```
[mak@mak-ws devkub-homeworks]$ kubectl port-forward deployment/hello-node 8080
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080
Handling connection for 8080


[mak@mak-ws ~]$ curl localhost:8080
CLIENT VALUES:
client_address=127.0.0.1
command=GET
real path=/
query=nil
request_version=1.1
request_uri=http://localhost:8080/

SERVER VALUES:
server_version=nginx: 1.10.0 - lua: 10001

HEADERS RECEIVED:
accept=*/*
host=localhost:8080
user-agent=curl/7.65.0-DEV
BODY:
-no body in request-
```

---
> ## Задача 4 (*): собрать через ansible (необязательное)
> Профессионалы не делают одну и ту же задачу два раза. Давайте закрепим полученные навыки, автоматизировав выполнение заданий  ansible-скриптами. При выполнении задания обратите внимание на доступные модули для k8s под ansible.
> - собрать роль для установки minikube на aws сервисе (с установкой ingress)
> - собрать роль для запуска в кластере hello world

[==> Ansible files](ansible/)

```
[mak@mak-ws ansible]$ ansible-playbook -i lserv, site.yml 

PLAY [Install minikube and run a cluster] ******************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [lserv]

TASK [minikube_netology : Get version of latest kubectl] ***************************************************************
ok: [lserv -> localhost]

TASK [minikube_netology : Download & install kubectl] ******************************************************************
changed: [lserv]

TASK [minikube_netology : Download & install minikube] *****************************************************************
changed: [lserv]

TASK [minikube_netology : install docker] ******************************************************************************
ok: [lserv] => (item=docker-ce)
ok: [lserv] => (item=docker-ce-cli)
ok: [lserv] => (item=conntrack)

TASK [minikube_netology : run minikube cluster] ************************************************************************
ok: [lserv]

TASK [k8s_echoserver : install openshift python package] ***************************************************************
ok: [lserv]

TASK [k8s_echoserver : create echoserver deployment] *******************************************************************
changed: [lserv]

TASK [k8s_echoserver : create echoserver service] **********************************************************************
changed: [lserv]

TASK [Get echoserver URL] **********************************************************************************************
ok: [lserv]

TASK [Get echoserver output] *******************************************************************************************
ok: [lserv]

TASK [Show echoserver output] ******************************************************************************************
ok: [lserv] => {
    "echoserver_responce.content": "CLIENT VALUES:\nclient_address=172.17.0.1\ncommand=GET\nreal path=/\nquery=nil\nrequest_version=1.1\nrequest_uri=http://176.56.186.111:8080/\n\nSERVER VALUES:\nserver_version=nginx: 1.10.0 - lua: 10001\n\nHEADERS RECEIVED:\naccept-encoding=identity\nconnection=close\nhost=176.56.186.111:30897\nuser-agent=ansible-httpget\nBODY:\n-no body in request-"
}

PLAY RECAP *************************************************************************************************************
lserv                      : ok=12   changed=4    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

```

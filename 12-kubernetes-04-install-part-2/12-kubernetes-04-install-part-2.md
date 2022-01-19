# Домашняя работа по занятию "12.4 Развертывание кластера на собственных серверах, лекция 2"
Новые проекты пошли стабильным потоком. Каждый проект требует себе несколько кластеров: под тесты и продуктив. Делать все руками — не вариант, поэтому стоит автоматизировать подготовку новых кластеров.

> ## Задание 1: Подготовить инвентарь kubespray
> Новые тестовые кластеры требуют типичных простых настроек. Нужно подготовить инвентарь и проверить его работу. Требования к инвентарю:
> * подготовка работы кластера из 5 нод: 1 мастер и 4 рабочие ноды;
> * в качестве CRI — containerd;
> * запуск etcd производить на мастере.

Развернём необходимую инфраструктуру в Яндекс-облаке терраформом, [c вот таким main.tf](tf-yc/main.tf)

Там немного кривые размеры дисков, для мастер-ноды я попробовал выделить наиболее быстрое хранилище (local ssd), 
у которого размер должен быть кратен 93Gb. А для рабочих нод не получилось, их целых пять, а у Яндекса какие-то лимиты на 
общее количество ресурсов для одного облака. Поэтому HDD, и чтобы уместилось в лимиты.

Чтобы не генерить инвентори ручками-скриптом, воспользуемся проектом [terraform-inventory](https://github.com/adammck/terraform-inventory).
Нам нужно будет сделать специальный output с именем `supplementary_addresses_in_ssl_keys`, который будет преобразован в соответсвующую групповую переменную,
для добавления публичного IP контрол-ноды в сертификат кластера. Туда было бы неплохо ещё DNS-записи добавить, но там надо поразбираться с терраформом, как в output
вывести один массив, объеденённый из нескольких.

Запускаем terraform plan / apply, получаем:
```
Outputs:

Control_nodes = {
  "kb-control-0.kb1.yc.complife.ru." = "62.84.118.177 / 10.128.0.26"
}
Worker_nodes = {
  "kb-worker-0.kb1.yc.complife.ru." = "62.84.114.179 / 10.128.0.20"
  "kb-worker-1.kb1.yc.complife.ru." = "62.84.124.45 / 10.128.0.37"
  "kb-worker-2.kb1.yc.complife.ru." = "62.84.117.95 / 10.128.0.16"
  "kb-worker-3.kb1.yc.complife.ru." = "62.84.126.252 / 10.128.0.9"
  "kb-worker-4.kb1.yc.complife.ru." = "62.84.127.103 / 10.128.0.17"
}
supplementary_addresses_in_ssl_keys = [
  "62.84.118.177",
]
```

Все прочие настройки (включая "запуск etcd производить на мастере") мы укажем во [вспомогательном
inventory](hosts.yml).

Запускаем kubespray такой вот командой:  
`TF_HOSTNAME_KEY_NAME=name TF_STATE=../tf-yc/ ansible-playbook -i inventory/mycluster/ -i ~/go/bin/terraform-inventory -b cluster.yml`

и, через томительных полчасика, получаем:
```
PLAY RECAP *****************************************************************************************************************************
kb-control-0               : ok=687  changed=148  unreachable=0    failed=0    skipped=1134 rescued=0    ignored=3   
kb-worker-0                : ok=479  changed=97   unreachable=0    failed=0    skipped=645  rescued=0    ignored=1   
kb-worker-1                : ok=479  changed=97   unreachable=0    failed=0    skipped=644  rescued=0    ignored=1   
kb-worker-2                : ok=479  changed=97   unreachable=0    failed=0    skipped=644  rescued=0    ignored=1   
kb-worker-3                : ok=479  changed=97   unreachable=0    failed=0    skipped=644  rescued=0    ignored=1   
kb-worker-4                : ok=479  changed=97   unreachable=0    failed=0    skipped=644  rescued=0    ignored=1   
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

Sunday 16 January 2022  10:18:18 +0100 (0:00:00.086)       0:28:22.422 ******** 
=============================================================================== 
kubernetes/preinstall : Install packages requirements ------------------------------------------------------------------------- 117.45s
download : download_container | Download image if required --------------------------------------------------------------------- 80.28s
kubernetes-apps/ansible : Kubernetes Apps | Lay Down CoreDNS templates --------------------------------------------------------- 29.93s
download : download_container | Download image if required --------------------------------------------------------------------- 22.91s
kubernetes-apps/ansible : Kubernetes Apps | Start Resources -------------------------------------------------------------------- 20.79s
kubernetes/kubeadm : Join to cluster ------------------------------------------------------------------------------------------- 20.21s
kubernetes/control-plane : kubeadm | Initialize first master ------------------------------------------------------------------- 19.36s
network_plugin/calico : Calico | Create calico manifests ----------------------------------------------------------------------- 17.98s
container-engine/containerd : containerd | Remove orphaned binary -------------------------------------------------------------- 13.94s
kubernetes/preinstall : Create kubernetes directories -------------------------------------------------------------------------- 13.44s
bootstrap-os : Install libselinux python package ------------------------------------------------------------------------------- 12.19s
policy_controller/calico : Create calico-kube-controllers manifests ------------------------------------------------------------ 12.19s
container-engine/containerd : containerd | Unpack containerd archive ----------------------------------------------------------- 11.55s
network_plugin/calico : Start Calico resources --------------------------------------------------------------------------------- 11.51s
kubernetes/preinstall : Remove search/domain/nameserver options after block ---------------------------------------------------- 11.47s
kubernetes/preinstall : Remove search/domain/nameserver options before block --------------------------------------------------- 11.39s
kubernetes/node : Modprobe Kernel Module for IPVS ------------------------------------------------------------------------------ 11.28s
container-engine/containerd : containerd | Ensure containerd directories exist ------------------------------------------------- 11.18s
kubernetes/preinstall : Remove search/domain/nameserver options before block --------------------------------------------------- 11.14s
download : download_container | Download image if required --------------------------------------------------------------------- 10.92s
```

Настраиваем доступ с локальной машины:
```
[mak@mak-ws kubespray]$ ssh cloud-user@kb-control-0.kb1.yc.complife.ru sudo 'bash -c "cat /home/cloud-user/.ssh/authorized_keys > /root/.ssh/authorized_keys"'
[mak@mak-ws kubespray]$ ssh root@kb-control-0.kb1.yc.complife.ru cat /root/.kube/config |sed -e 's/127.0.0.1/62.84.118.177/' > ~/.kube/config
```

Тестируем доступ, играемся, развлекаемся:
```
[mak@mak-ws kubespray]$ kubectl get nodes -o wide
NAME           STATUS   ROLES                  AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION                CONTAINER-RUNTIME
kb-control-0   Ready    control-plane,master   21m   v1.23.1   10.128.0.26   <none>        CentOS Linux 8   4.18.0-348.7.1.el8_5.x86_64   containerd://1.5.9
kb-worker-0    Ready    <none>                 19m   v1.23.1   10.128.0.20   <none>        CentOS Linux 8   4.18.0-348.7.1.el8_5.x86_64   containerd://1.5.9
kb-worker-1    Ready    <none>                 19m   v1.23.1   10.128.0.37   <none>        CentOS Linux 8   4.18.0-348.7.1.el8_5.x86_64   containerd://1.5.9
kb-worker-2    Ready    <none>                 19m   v1.23.1   10.128.0.16   <none>        CentOS Linux 8   4.18.0-348.7.1.el8_5.x86_64   containerd://1.5.9
kb-worker-3    Ready    <none>                 19m   v1.23.1   10.128.0.9    <none>        CentOS Linux 8   4.18.0-348.7.1.el8_5.x86_64   containerd://1.5.9
kb-worker-4    Ready    <none>                 19m   v1.23.1   10.128.0.17   <none>        CentOS Linux 8   4.18.0-348.7.1.el8_5.x86_64   containerd://1.5.9
```
Работает containerd, как и заказывали. Впрочем, он там по умолчанию.

```
mak@mak-ws kubespray]$ kubectl get pod -A
NAMESPACE     NAME                                     READY   STATUS    RESTARTS      AGE
kube-system   calico-kube-controllers-bd5fc6b6-f4q7h   1/1     Running   2 (18m ago)   18m
kube-system   calico-node-76qzv                        1/1     Running   0             19m
kube-system   calico-node-7xs4d                        1/1     Running   0             19m
kube-system   calico-node-hzbnk                        1/1     Running   0             19m
kube-system   calico-node-mgpts                        1/1     Running   0             19m
kube-system   calico-node-nwhlq                        1/1     Running   0             19m
kube-system   calico-node-tvlsd                        1/1     Running   0             19m
kube-system   coredns-76b4fb4578-9rjd6                 1/1     Running   0             17m
kube-system   coredns-76b4fb4578-c9vcs                 1/1     Running   0             17m
kube-system   dns-autoscaler-7979fb6659-9nwbl          1/1     Running   0             17m
kube-system   kube-apiserver-kb-control-0              1/1     Running   1             21m
kube-system   kube-controller-manager-kb-control-0     1/1     Running   1             21m
kube-system   kube-proxy-7t688                         1/1     Running   0             20m
kube-system   kube-proxy-9l8d6                         1/1     Running   0             20m
kube-system   kube-proxy-kmdfl                         1/1     Running   0             20m
kube-system   kube-proxy-nfr5t                         1/1     Running   0             20m
kube-system   kube-proxy-nnh9g                         1/1     Running   0             20m
kube-system   kube-proxy-v6gpq                         1/1     Running   0             20m
kube-system   kube-scheduler-kb-control-0              1/1     Running   1             21m
kube-system   nginx-proxy-kb-worker-0                  1/1     Running   0             20m
kube-system   nginx-proxy-kb-worker-1                  1/1     Running   0             20m
kube-system   nginx-proxy-kb-worker-2                  1/1     Running   0             20m
kube-system   nginx-proxy-kb-worker-3                  1/1     Running   0             20m
kube-system   nginx-proxy-kb-worker-4                  1/1     Running   0             20m
kube-system   nodelocaldns-42z7f                       1/1     Running   0             17m
kube-system   nodelocaldns-k6hg5                       1/1     Running   0             17m
kube-system   nodelocaldns-kqrs5                       1/1     Running   0             17m
kube-system   nodelocaldns-lrg9f                       1/1     Running   0             17m
kube-system   nodelocaldns-wb2hc                       1/1     Running   0             17m
kube-system   nodelocaldns-z74b6                       1/1     Running   0             17m
```

Развернём приложеньице:
```
[mak@mak-ws kubespray]$ kubectl create deployment hello-world --image=k8s.gcr.io/echoserver:1.4 --replicas=8
deployment.apps/hello-world created

[mak@mak-ws kubespray]$ kubectl get pod,deployment -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE          NOMINATED NODE   READINESS GATES
pod/hello-world-bd79c8b9f-4qwvr   1/1     Running   0          51s   10.233.75.2    kb-worker-4   <none>           <none>
pod/hello-world-bd79c8b9f-4tqcv   1/1     Running   0          51s   10.233.106.2   kb-worker-1   <none>           <none>
pod/hello-world-bd79c8b9f-9rqts   1/1     Running   0          51s   10.233.106.1   kb-worker-1   <none>           <none>
pod/hello-world-bd79c8b9f-k7p2p   1/1     Running   0          51s   10.233.96.1    kb-worker-0   <none>           <none>
pod/hello-world-bd79c8b9f-m9dt2   1/1     Running   0          51s   10.233.105.1   kb-worker-3   <none>           <none>
pod/hello-world-bd79c8b9f-w6lg2   1/1     Running   0          51s   10.233.74.2    kb-worker-2   <none>           <none>
pod/hello-world-bd79c8b9f-wvzrj   1/1     Running   0          51s   10.233.75.1    kb-worker-4   <none>           <none>
pod/hello-world-bd79c8b9f-zph62   1/1     Running   0          51s   10.233.96.2    kb-worker-0   <none>           <none>

NAME                          READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                      SELECTOR
deployment.apps/hello-world   8/8     8            8           51s   echoserver   k8s.gcr.io/echoserver:1.4   app=hello-world
```
Распределилось по всем пяти нодам.

```
[mak@mak-ws kubespray]$ kubectl port-forward deployment/hello-world 8080
...
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

И даже работает.

---
> ## Задание 2 (*): подготовить и проверить инвентарь для кластера в AWS
> Часть новых проектов хотят запускать на мощностях AWS. Требования похожи:
> * разворачивать 5 нод: 1 мастер и 4 рабочие ноды;
> * работать должны на минимально допустимых EC2 — t3.small.

UPD:

Это получилось с развёртыванием инфраструктуры с помощью [contrib/terraform/aws](https://github.com/kubernetes-sigs/kubespray/tree/master/contrib/terraform/aws),
оно создаёт все ноды с приватными адресами, и ещё бастион с публичным. Только обещает сделать SSH-конфиг для доступа 
через бастион, но обманывает и не делает. Но не беда, можно сделать и самим, если подумать. Там же 
по существу просто SSH-прокси.

После создания инфраструктуры немного редактируем получившийся файл инвентори, добавив туда переменную с SSH-подключением:
```
[k8s_cluster:vars]
ansible_ssh_common_args='-A -o ProxyCommand="ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q admin@18.156.69.113"'
```
(это можно было бы пофиксить и в конфигурации терраформа, подредактировав `templates/inventory.tpl` и `create-infrastructure.tf`)

И запустим развёртывание кластера:
```
ansible-playbook -i inventory/hosts -b -e 'cloud_provider=aws' -e 'ansible_user=admin' cluster.yml
...
PLAY RECAP ***************************************************************************************************************************************************************
bastion                    : ok=6    changed=1    unreachable=0    failed=0    skipped=16   rescued=0    ignored=0   
ip-10-250-192-90.eu-central-1.compute.internal : ok=476  changed=97   unreachable=0    failed=0    skipped=645  rescued=0    ignored=1   
ip-10-250-196-25.eu-central-1.compute.internal : ok=476  changed=96   unreachable=0    failed=0    skipped=645  rescued=0    ignored=1   
ip-10-250-202-2.eu-central-1.compute.internal : ok=501  changed=99   unreachable=0    failed=0    skipped=746  rescued=0    ignored=1   
ip-10-250-203-120.eu-central-1.compute.internal : ok=656  changed=145  unreachable=0    failed=0    skipped=1038 rescued=0    ignored=3   
ip-10-250-209-234.eu-central-1.compute.internal : ok=476  changed=97   unreachable=0    failed=0    skipped=645  rescued=0    ignored=1   
ip-10-250-223-104.eu-central-1.compute.internal : ok=476  changed=97   unreachable=0    failed=0    skipped=645  rescued=0    ignored=1   
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

Wednesday 19 January 2022  09:00:50 +0100 (0:00:00.092)       0:19:26.393 ***** 
=============================================================================== 
```

За 20 минуточек создался, если выбрать регион поближе.

```
root@ip-10-250-203-120:~# kubectl get nodes -o wide
NAME                                              STATUS   ROLES                  AGE   VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION          CONTAINER-RUNTIME
ip-10-250-192-90.eu-central-1.compute.internal    Ready    <none>                 20m   v1.23.1   10.250.192.90    <none>        Debian GNU/Linux 10 (buster)   4.19.0-18-cloud-amd64   containerd://1.5.9
ip-10-250-196-25.eu-central-1.compute.internal    Ready    <none>                 20m   v1.23.1   10.250.196.25    <none>        Debian GNU/Linux 10 (buster)   4.19.0-18-cloud-amd64   containerd://1.5.9
ip-10-250-202-2.eu-central-1.compute.internal     Ready    <none>                 20m   v1.23.1   10.250.202.2     <none>        Debian GNU/Linux 10 (buster)   4.19.0-18-cloud-amd64   containerd://1.5.9
ip-10-250-203-120.eu-central-1.compute.internal   Ready    control-plane,master   21m   v1.23.1   10.250.203.120   <none>        Debian GNU/Linux 10 (buster)   4.19.0-18-cloud-amd64   containerd://1.5.9
ip-10-250-209-234.eu-central-1.compute.internal   Ready    <none>                 20m   v1.23.1   10.250.209.234   <none>        Debian GNU/Linux 10 (buster)   4.19.0-18-cloud-amd64   containerd://1.5.9
ip-10-250-223-104.eu-central-1.compute.internal   Ready    <none>                 20m   v1.23.1   10.250.223.104   <none>        Debian GNU/Linux 10 (buster)   4.19.0-18-cloud-amd64   containerd://1.5.9
```

Работает!

---
> Was:
Я к сожалению ниасилил.  
При попытке поступить по аналогии, создать инстансы ([main.tf для AWS](tf-aws/main.tf)) и запустить kubespray, playbook отваливается на разных ошибках. 
То kubelet не может стартовать на мастер-ноде из-за отсутствующего сертификата (очень похоже на https://github.com/kubernetes-sigs/kubespray/issues/4693)  
То рабочие ноды не могут присоедениться к мастеру, то ли кривой сертификат, то ли не могут получить информацию от API сервера, не успел разобраться.  
Последняя ошибка выглядела как ошибка инициализации первого мастера, `error execution phase upload-config/kubelet: Error writing Crisocket information for the control-plane node: nodes "kubernetes-mycluster-master0" not found"`

>Попробовал развернуть инфраструктуру с [contrib/terraform/aws](https://github.com/kubernetes-sigs/kubespray/tree/master/contrib/terraform/aws), оно обещало сгенерить готовый инвентори. Развернуло, сгененерило, но создало ноды (или сеть?) только с приватными адресами, подключиться не удаётся.  
Предполагается, что там надо как-то работать через бастион-сервер, и для него должна создаваться специальная SSH-конфигурация, но она не создаётся, 
и как объяснить кубеспрею чтоб разворачивал через этот единственный бастион с публичным IP.. я так и не понял.

>Некоторая дополнительная мудрость есть в [доке по AWS](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/aws.md), я попробовал ручками создать политики/роли, 
назначить их инстансам и развесить таги, но что-то наверное сделал не так, ошибка просто поменялась на другую.  
Наверное, какая-то специфика AWS, за пару неделек может и разобрался бы. 

# Домашняя работа по занятию "12.5 Сетевые решения CNI"

>## Задание 1: установить в кластер CNI плагин Calico
>Для проверки других сетевых решений стоит поставить отличный от Flannel плагин — например, Calico. Требования: 
>* установка производится через ansible/kubespray;
>* после применения следует настроить политику доступа к hello-world извне. Инструкции [kubernetes.io](https://kubernetes.io/docs/concepts/services-networking/network-policies/), [Calico](https://docs.projectcalico.org/about/about-network-policy)

[Опишем](objects) три деплоймента: `hello-world`, `hello`, `world`. Все они слушают на :80 и :443 порту. 
`hello-world` у нас будет типа сервером, для него мы ещё и service сделаем. `hello` будет доверенным клиентом, а `world` - недоверенным.

```
$ kubectl get po,svc -o wide
NAME                              READY   STATUS    RESTARTS   AGE   IP             NODE                      NOMINATED NODE   READINESS GATES
pod/hello-8dd4bc8b9-kcdxm         1/1     Running   0          45m   10.233.105.6   m4-3.test-kube.iptp.net   <none>           <none>
pod/hello-world-f96c4b6b6-d4cvd   1/1     Running   0          45m   10.233.126.4   m4-4.test-kube.iptp.net   <none>           <none>
pod/world-67cd5c7849-bpdv2        1/1     Running   0          45m   10.233.105.7   m4-3.test-kube.iptp.net   <none>           <none>

NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE   SELECTOR
service/hello-world   ClusterIP   10.233.6.212   <none>        80/TCP,443/TCP   45m   app=hello-world
service/kubernetes    ClusterIP   10.233.0.1     <none>        443/TCP          15h   <none>
```

Попробуем, как оно работает. Зайдём на клиента `world` и попробуем обратиться к серверу `hello-world`:
```
$ kubectl exec -it pod/world-67cd5c7849-bpdv2 -- bash
bash-5.1# curl -m 1 http://hello-world
Praqma Network MultiTool (with NGINX) - hello-world-f96c4b6b6-d4cvd - 10.233.126.4
bash-5.1# curl -m 1 -k https://hello-world
Praqma Network MultiTool (with NGINX) - hello-world-f96c4b6b6-d4cvd - 10.233.126.4
```

Замечательно. Но нам прилетела новая таска: всё запретить и ограничить! Придётся cделать для нашего сервера [network-policy](policy/hello-world.yml).   
Мы разрешим для доверенного клиента `hello` доступ по :443 и :80 порту, а для недоверенного `world` только по :443

Проверяем:
```
$ kubectl apply -f policy/hello-world.yml 
networkpolicy.networking.k8s.io/hello-world created

$ kubectl exec -it pod/world-67cd5c7849-bpdv2 -- bash
bash-5.1# curl -m 1 http://hello-world
curl: (28) Connection timed out after 1001 milliseconds
bash-5.1# curl -m 1 -k https://10.233.126.4
Praqma Network MultiTool (with NGINX) - hello-world-f96c4b6b6-d4cvd - 10.233.126.4
```

Отлично, https работает, http нет, как и было задумано.

Но! Это ж недоверенный клиент, и у нас там завёлся cOoLHAckEr! Он смог подключиться напрямую к клиентскому поду `hello`:  
```
bash-5.1# curl 10.233.105.6
Praqma Network MultiTool (with NGINX) - hello-8dd4bc8b9-kcdxm - 10.233.105.6
```

Придётся [ограничивать](policy/world1.yml) у клиента `world` ещё и исходящие соединения. Разрешим ему ходить только к 
серверу `hello-world` и только по 443 порту. Пробуем:
```
$ kubectl apply -f policy/world1.yml 
networkpolicy.networking.k8s.io/world created

$ kubectl exec -it pod/world-67cd5c7849-bpdv2 -- bash
bash-5.1# curl -m 1 http://10.233.105.6
curl: (28) Connection timed out after 1001 milliseconds
bash-5.1# curl -m 1 -k  https://10.233.105.6
curl: (28) Connection timed out after 1000 milliseconds
```
Обломился проклятый хакер! Ха-ха!

```
bash-5.1# curl -m 1 -k https://hello-world
curl: (28) Resolving timed out after 1000 milliseconds
```
Упс, мы тоже обломились. У нас сломался резолвинг. (Это, кстати, та самая ситуация с лекции, когда у `cache` был 
пустой egress, и у него резолв тоже не работал, и curl недолго висел по таймауту).

[Исправим](policy/world2.yml) нашу сетевую политику, добавив правило для DNS. Пробуем:
```
$ kubectl apply -f policy/world2.yml 
networkpolicy.networking.k8s.io/world configured

$ kubectl exec -it pod/world-67cd5c7849-bpdv2 -- bash
bash-5.1# curl -m 1 -k https://hello-world
Praqma Network MultiTool (with NGINX) - hello-world-f96c4b6b6-d4cvd - 10.233.126.4
bash-5.1# curl -m 1 http://hello-world
curl: (28) Connection timed out after 1001 milliseconds
bash-5.1# curl -m 1 http://10.233.105.6
curl: (28) Connection timed out after 1001 milliseconds
```
Отлично, что мы и хотели получить. А как поживает наш доверенный клиент?
```
$ kubectl exec -it pod/hello-8dd4bc8b9-kcdxm -- bash
bash-5.1# curl -m 1 http://hello-world
Praqma Network MultiTool (with NGINX) - hello-world-f96c4b6b6-d4cvd - 10.233.126.4
bash-5.1# curl -m 1 -k https://hello-world
Praqma Network MultiTool (with NGINX) - hello-world-f96c4b6b6-d4cvd - 10.233.126.4
bash-5.1# curl -m 1 -k https://10.233.105.7
Praqma Network MultiTool (with NGINX) - world-67cd5c7849-bpdv2 - 10.233.105.7
```
Хорошо поживает, доверенно, без всяких ограничений.

---
>## Задание 2: изучить, что запущено по умолчанию
> Самый простой способ — проверить командой calicoctl get <type>. Для проверки стоит получить список нод, ipPool и profile.
Требования: 
>* установить утилиту calicoctl;

```
$ sudo curl -sL https://github.com/projectcalico/calico/releases/download/v3.22.0/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
$ sudo chmod +x /usr/local/bin/calicoctl
```

> * получить 3 вышеописанных типа в консоли.

```
$ calicoctl --allow-version-mismatch get nodesNAME                      
m4-1.test-kube.iptp.net   
m4-2.test-kube.iptp.net   
m4-3.test-kube.iptp.net   
m4-4.test-kube.iptp.net   

$ calicoctl --allow-version-mismatch get ipPool
NAME           CIDR             SELECTOR   
default-pool   10.233.64.0/18   all()      

$ calicoctl --allow-version-mismatch get profile
NAME                                                 
projectcalico-default-allow                          
kns.default                                          
kns.kube-node-lease                                  
kns.kube-public                                      
kns.kube-system                                      
ksa.default.default                                  
ksa.kube-node-lease.default                          
ksa.kube-public.default                              
ksa.kube-system.attachdetach-controller              
ksa.kube-system.bootstrap-signer                     
...
```
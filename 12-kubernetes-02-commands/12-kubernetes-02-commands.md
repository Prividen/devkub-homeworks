# Домашняя работа по занятию "12.2 Команды для работы с Kubernetes"

> ## Задание 1: Запуск пода из образа в деплойменте

> * пример из hello world запущен в качестве deployment
> * количество реплик в deployment установлено в 2
> * наличие deployment можно проверить командой kubectl get deployment
> * наличие подов можно проверить командой kubectl get pods

```
[mak@mak-ws ~]$ kubectl create deployments hello-world --image=k8s.gcr.io/echoserver:1.4 --replicas=2
deployment.apps/hello-world created

[mak@mak-ws ~]$ kubectl get deployments,pods
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-world   2/2     2            2           23s

NAME                               READY   STATUS    RESTARTS   AGE
pod/hello-world-7c4b75bcb9-k64jr   1/1     Running   0          22s
pod/hello-world-7c4b75bcb9-x62dt   1/1     Running   0          22s
```

---
> ## Задание 2: Просмотр логов для разработки
>Разработчикам крайне важно получать обратную связь от штатно работающего приложения и, еще важнее, об ошибках в его работе. 
Требуется создать пользователя и выдать ему доступ на чтение конфигурации и логов подов в app-namespace.
> Требования: 
> * создан новый токен доступа для пользователя
> * пользователь прописан в локальный конфиг (~/.kube/config, блок users)
> * пользователь может просматривать логи подов и их конфигурацию (kubectl logs pod <pod_id>, kubectl describe pod <pod_id>)

```
[mak@mak-ws ~]$ ACCOUNT=razrabotchik
[mak@mak-ws ~]$ NS=app-namespace
[mak@mak-ws ~]$ kubectl create namespace $NS
namespace/app-namespace created
[mak@mak-ws ~]$ kubectl create serviceaccount $ACCOUNT -n $NS
serviceaccount/razrabotchik created
[mak@mak-ws ~]$ SECRET_NAME=$(kubectl get serviceaccounts $ACCOUNT -n $NS -o json |jq -r '.secrets[].name')
[mak@mak-ws ~]$ TOKEN=$(kubectl get secrets $SECRET_NAME -n $NS -o json |jq -r .data.token |base64 -d)
[mak@mak-ws ~]$ kubectl create role pod-info-logs --verb=get --resource=pods --resource=pods/log -n $NS
role.rbac.authorization.k8s.io/pod-info-logs created
[mak@mak-ws ~]$ kubectl create rolebinding ${ACCOUNT}-pod-info-logs --role=pod-info-logs --serviceaccount=${NS}:${ACCOUNT} -n $NS
rolebinding.rbac.authorization.k8s.io/razrabotchik-pod-info-logs created
[mak@mak-ws ~]$ kubectl config set-credentials $ACCOUNT --token=$TOKEN
User "razrabotchik" set.
```

Тестируем. Создадим пару подов, в неймспейсах `app-namespace` и `default`:

```
[mak@mak-ws ~]$ kubectl run test-pod-app-ns --image=hello-world -n $NS
pod/test-pod-app-ns created
[mak@mak-ws ~]$ kubectl run test-pod-def-ns --image=hello-world
pod/test-pod-def-ns created
```

Проверяем разные варианты доступа:

```
[mak@mak-ws ~]$ kubectl --user=$ACCOUNT logs test-pod-app-ns -n $NS |head

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.


[mak@mak-ws ~]$ kubectl --user=$ACCOUNT describe pods test-pod-app-ns -n $NS |head
Name:         test-pod-app-ns
Namespace:    app-namespace
Priority:     0
Node:         test-xu20/176.56.186.111
Start Time:   Sat, 25 Dec 2021 09:41:20 +0100
Labels:       run=test-pod-app-ns
Annotations:  <none>
Status:       Running
IP:           172.17.0.6
IPs:

[mak@mak-ws ~]$ kubectl --user=$ACCOUNT logs test-pod-def-ns
Error from server (Forbidden): pods "test-pod-def-ns" is forbidden: User "system:serviceaccount:app-namespace:razrabotchik" cannot get resource "pods" in API group "" in the namespace "default"

[mak@mak-ws ~]$ kubectl --user=$ACCOUNT describe pods test-pod-def-ns
Error from server (Forbidden): pods "test-pod-def-ns" is forbidden: User "system:serviceaccount:app-namespace:razrabotchik" cannot get resource "pods" in API group "" in the namespace "default"

[mak@mak-ws ~]$ kubectl --user=$ACCOUNT get pods -n $NS 
Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:app-namespace:razrabotchik" cannot list resource "pods" in API group "" in the namespace "app-namespace"

[mak@mak-ws ~]$ kubectl --user=$ACCOUNT delete pods test-pod-app-ns -n $NS 
Error from server (Forbidden): pods "test-pod-app-ns" is forbidden: User "system:serviceaccount:app-namespace:razrabotchik" cannot delete resource "pods" in API group "" in the namespace "app-namespace"
```

---
> ## Задание 3: Изменение количества реплик 
> Поработав с приложением, вы получили запрос на увеличение количества реплик приложения для нагрузки. Необходимо изменить запущенный deployment, увеличив количество реплик до 5. Посмотрите статус запущенных подов после увеличения реплик. 
> Требования:
> * в deployment из задания 1 изменено количество реплик на 5
> * проверить что все поды перешли в статус running (kubectl get pods)

```
[mak@mak-ws ~]$ kubectl scale deployment.apps/hello-world --replicas=5 
deployment.apps/hello-world scaled

[mak@mak-ws ~]$ kubectl get deployments,pods
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hello-world   5/5     5            5           3m18s

NAME                               READY   STATUS    RESTARTS   AGE
pod/hello-world-7c4b75bcb9-c5vzl   1/1     Running   0          12s
pod/hello-world-7c4b75bcb9-k64jr   1/1     Running   0          3m17s
pod/hello-world-7c4b75bcb9-pc6dd   1/1     Running   0          12s
pod/hello-world-7c4b75bcb9-snwqr   1/1     Running   0          12s
pod/hello-world-7c4b75bcb9-x62dt   1/1     Running   0          3m17s
```

Ещё можно попробовать:
* ```kubectl patch deployments hello-world -p '{"spec":{"replicas":5}}'```
* ```kubectl get deployment.apps/hello-world -o json |jq '.spec.replicas = 5' |kubectl apply -f -```
* и даже `kubectl edit deployment.apps/hello-world`

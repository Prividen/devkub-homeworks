# Домашняя работа по занятию "13.4 инструменты для упрощения написания конфигурационных файлов. Helm и Jsonnet"

> ## Задание 1: подготовить helm чарт для приложения
> Необходимо упаковать приложение в чарт для деплоя в разные окружения. Требования:
>* каждый компонент приложения деплоится отдельным deployment’ом/statefulset’ом;
>* в переменных чарта измените образ приложения для изменения версии.

[==> Chart](myapp)  
Версию попробуем менять через .Values.AppVersionOverride, это изменит и версию образов.

---
> ## Задание 2: запустить 2 версии в разных неймспейсах
> Подготовив чарт, необходимо его проверить. Попробуйте запустить несколько копий приложения:
> * одну версию в namespace=app1;
 
Устанавливаем наше приложение:
```
[mak@mak-ws 13-kubernetes-config-04-helm]$ helm install --set namespace=app1 myapp myapp/
NAME: myapp
LAST DEPLOYED: Wed Feb 16 07:09:24 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Please use command:
kubectl -n app1 port-forward service/back-front-0-0-1 8080:80 9000
to connect to our fellow application, and then open your browser with url: http://localhost:8080
```

Проверяем объекты:
```
[mak@mak-ws ~]$ kubectl get -n app1 po,deploy,svc,sts
NAME                                    READY   STATUS    RESTARTS   AGE
pod/back-front-0.0.1-75f98fd4b6-6twhr   2/2     Running   0          17s
pod/postgres-0-0-1-0                    1/1     Running   0          17s

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/back-front-0.0.1   1/1     1            1           17s

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)           AGE
service/back-front-0-0-1   ClusterIP   10.233.51.51    <none>        80/TCP,9000/TCP   17s
service/postgres-0-0-1     ClusterIP   10.233.11.195   <none>        5432/TCP          17s

NAME                              READY   AGE
statefulset.apps/postgres-0-0-1   1/1     17s
```

Пробуем подключиться к приложению:
```
mak@mak-ws ~]$ kubectl port-forward -n app1 service/back-front-0-0-1 8080:80 9000
[1] 18762
[mak@mak-ws ~]$ Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Forwarding from 127.0.0.1:9000 -> 9000
Forwarding from [::1]:9000 -> 9000

[mak@mak-ws ~]$ curl -s localhost:8080 |head -2
Handling connection for 8080
<!DOCTYPE html>
<html lang="ru">

[mak@mak-ws ~]$ curl -s localhost:9000/api/news/1 |jq .title
Handling connection for 9000
"title 0"
[mak@mak-ws ~]$ kill %1
[mak@mak-ws ~]$ [1]+  Terminated              kubectl -n app1 port-forward service/back-front-0-0-1 8080:80 9000
```
Бэк и фронт отвечают, как задумано.

> * вторую версию в том же неймспейсе;

Теперь попробуем установить в тот же неймспейс новую версию. 
```
[mak@mak-ws 13-kubernetes-config-04-helm]$ helm install --set namespace=app1 --set AppVersionOverride=0.0.2 myapp myapp/ 
Error: INSTALLATION FAILED: cannot re-use a name that is still in use
```

Попробуем с другим именем приложения:
```
[mak@mak-ws 13-kubernetes-config-04-helm]$ helm install --set namespace=app1 --set AppVersionOverride=0.0.2 myapp2 myapp/
Error: INSTALLATION FAILED: rendered manifests contain a resource that already exists. Unable to continue with install: Namespace "app1" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata; annotation validation error: key "meta.helm.sh/release-name" must equal "myapp2": current value is "myapp"
```

Вот подлянка! Но мы можем попробовать проапрегрйдить приложение:
```
[mak@mak-ws 13-kubernetes-config-04-helm]$ helm upgrade  --set namespace=app1  --set AppVersionOverride=0.0.2 myapp myapp/ 
Release "myapp" has been upgraded. Happy Helming!
NAME: myapp
LAST DEPLOYED: Wed Feb 16 07:40:47 2022
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
Please use command:
kubectl -n app1 port-forward service/back-front-0-0-2 8080:80 9000
to connect to our fellow application, and then open your browser with url: http://localhost:8080
```

Теперь все наши поды-деплойменты новой версии:
```
[mak@mak-ws ~]$ kubectl get -n app1 po,deploy,svc,sts
NAME                                    READY   STATUS    RESTARTS   AGE
pod/back-front-0.0.2-566667fcd4-pqrdl   2/2     Running   0          22m
pod/postgres-0-0-2-0                    1/1     Running   0          22m

NAME                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/back-front-0.0.2   1/1     1            1           22m

NAME                       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)           AGE
service/back-front-0-0-2   ClusterIP   10.233.16.38   <none>        80/TCP,9000/TCP   22m
service/postgres-0-0-2     ClusterIP   10.233.34.72   <none>        5432/TCP          22m

NAME                              READY   AGE
statefulset.apps/postgres-0-0-2   1/1     22m
```

> * третью версию в namespace=app2.

Пробуем...
```
[mak@mak-ws 13-kubernetes-config-04-helm]$ helm install  --set namespace=app2  --set AppVersionOverride=0.0.3 myapp myapp/ 
Error: INSTALLATION FAILED: cannot re-use a name that is still in use
```
Шо, опять??!

Попробуем поменять имя...
```
[mak@mak-ws 13-kubernetes-config-04-helm]$ helm install  --set namespace=app2  --set AppVersionOverride=0.0.3 myapp2 myapp/ 
NAME: myapp2
LAST DEPLOYED: Wed Feb 16 08:02:35 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Please use command:
kubectl -n app2 port-forward service/back-front-0-0-3 8080:80 9000
to connect to our fellow application, and then open your browser with url: http://localhost:8080
```
Уфф, прокатило.

И чего теперь у нас есть?
```
[mak@mak-ws 13-kubernetes-config-04-helm]$ helm list
NAME      	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART                       	APP VERSION
myapp     	default  	2       	2022-02-16 07:40:47.653705219 +0100 CET	deployed	myapp-0.1.0                 	0.0.1      
myapp2    	default  	1       	2022-02-16 08:02:35.990474101 +0100 CET	deployed	myapp-0.1.0                 	0.0.1     
```
Насчёт неймспейса и app version оно врёт... впрочем, наверняка я их кривовато указывал.


---

>## Задание 3 (*): повторить упаковку на jsonnet
>Для изучения другого инструмента стоит попробовать повторить опыт упаковки из задания 1, только теперь с помощью инструмента jsonnet.

Увы, все силы на борьбу с подлянкой ушли!
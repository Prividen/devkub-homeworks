# Домашняя работа по занятию "13.3 работа с kubectl"

>## Задание 1: проверить работоспособность каждого компонента
>Для проверки работы можно использовать 2 способа: port-forward и exec. Используя оба способа, проверьте каждый компонент:
> * сделайте запросы к бекенду;

Прокинем от пода бекенда порт 9000, на котором слушает API бекенда, и проверим, сделав запрос курлом 
```
[mak@mak-ws ~]$ kubectl port-forward back-65f7ffd78f-9sfvl 9000 &
[1] 15233
[mak@mak-ws ~]$ Forwarding from 127.0.0.1:9000 -> 9000
Forwarding from [::1]:9000 -> 9000

[mak@mak-ws ~]$ curl localhost:9000/api/news/1
Handling connection for 9000
{"id":1,"title":"Joke 0","short_description":"How will Christmas dinner be different after Brexit? No Brussels!","description":"Category: Christmas; Content: How will Christmas dinner be different after Brexit? No Brussels!","preview":"/static/image.png"}[mak@mak-ws ~]$ 
[mak@mak-ws ~]$ kill %1
[mak@mak-ws ~]$ [1]+  Terminated              kubectl port-forward -n 13-02-prod back-65f7ffd78f-9sfvl 9000
```

> * сделайте запросы к фронту;

Прокинем от пода фронтэнда порт 80 (на локальный 8080), и проверим, сделав запрос курлом
```
[mak@mak-ws ~]$ kubectl port-forward front-67d59c676f-k8mhc 8080:80 &
[1] 14416
[mak@mak-ws ~]$ Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80

[mak@mak-ws ~]$ curl localhost:8080
Handling connection for 8080
<!DOCTYPE html>
<html lang="ru">
<head>
    <title>Список</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link href="/build/main.css" rel="stylesheet">
</head>
<body>
    <main class="b-page">
        <h1 class="b-page__title">Список</h1>
        <div class="b-page__content b-items js-list"></div>
    </main>
    <script src="/build/main.js"></script>
</body>
</html>[mak@mak-ws ~]$ 
[mak@mak-ws ~]$ kill %1
[mak@mak-ws ~]$ [1]+  Terminated              kubectl port-forward -n 13-02-prod front-67d59c676f-k8mhc 8080:80
```
Похоже на заглавную страничку нашего фронта


> * подключитесь к базе данных.

Выполним psql внутри контейнера пода postgres:
```
[mak@mak-ws ~]$ kubectl exec postgres-0 -- psql -U postgres -d news -c 'select title from news limit 3;'
 title  
--------
 Joke 0
 Joke 1
 Joke 2
(3 rows)
```

---
>## Задание 2: ручное масштабирование
>При работе с приложением иногда может потребоваться вручную добавить пару копий. 
> Используя команду kubectl scale, попробуйте увеличить количество бекенда и фронта до 3. 
> После уменьшите количество копий до 1. Проверьте, на каких нодах оказались копии после каждого действия (kubectl describe).

Чтобы было удобней смотреть на контейнеры, навесим им (через их деплоймент) специальные метки и сделаем выборку с нодами:
```
[mak@mak-ws ~]$ kubectl patch deployment.apps/front -p '{"spec":{"template":{"metadata":{"labels":{"kind":"back-or-front"}}}}}'
deployment.apps/front patched
[mak@mak-ws ~]$ kubectl patch deployment.apps/back -p '{"spec":{"template":{"metadata":{"labels":{"kind":"back-or-front"}}}}}'
deployment.apps/back patched
[mak@mak-ws ~]$ kubectl get pods -o custom-columns=Name:.metadata.name,Node:.spec.nodeName -l kind=back-or-front
Name                    Node
back-585cdb59c8-lsncr   m4-2.test-kube.iptp.net
front-dc6764d56-2gzmx   m4-3.test-kube.iptp.net
```

Отмасштабируем бекенд и фронтенд до 3 подов и проверим распределение по нодам:
```
[mak@mak-ws ~]$ kubectl scale --replicas=3 deployment.apps/back deployment.apps/front
deployment.apps/back scaled
deployment.apps/front scaled
[mak@mak-ws ~]$ kubectl get pods -o custom-columns=Name:.metadata.name,Node:.spec.nodeName -l kind=back-or-front
Name                    Node
back-585cdb59c8-kvk4l   m4-3.test-kube.iptp.net
back-585cdb59c8-lsncr   m4-2.test-kube.iptp.net
back-585cdb59c8-wvb22   m4-4.test-kube.iptp.net
front-dc6764d56-2gzmx   m4-3.test-kube.iptp.net
front-dc6764d56-96pcg   m4-2.test-kube.iptp.net
front-dc6764d56-j48m5   m4-4.test-kube.iptp.net
```

Равномерненько.  
Отмасштабируем обратно:
```
[mak@mak-ws ~]$ kubectl scale --replicas=1 deployment.apps/back deployment.apps/front
deployment.apps/back scaled
deployment.apps/front scaled
[mak@mak-ws ~]$ kubectl get pods -o custom-columns=Name:.metadata.name,Node:.spec.nodeName -l kind=back-or-front
Name                    Node
back-585cdb59c8-lsncr   m4-2.test-kube.iptp.net
front-dc6764d56-2gzmx   m4-3.test-kube.iptp.net
```
Все вновьсозданные поды были убиты, выжили самые старые по своим старым нодам


# Домашняя работа по занятию "13.5 поддержка нескольких окружений на примере Qbec"

## Задание 1: подготовить приложение для работы через qbec
> Приложение следует упаковать в qbec. Окружения должно быть 2: stage и production. 
> Требования:
> * stage окружение должно поднимать каждый компонент приложения в одном экземпляре;
> * production окружение — каждый компонент в трёх экземплярах;
> * для production окружения нужно добавить endpoint на внешний адрес.

[==> приложение](testapp-13-05)

Проверяем...
```
[mak@mak-ws testapp-13-05]$ qbec component diff stage prod
--- environment: stage
+++ environment: prod
@@ -2,0 +3 @@
+external-api-endpoint          components/external-api-endpoint.jsonnet

[mak@mak-ws testapp-13-05]$ qbec validate stage
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 20ms
2 components evaluated in 3ms
✔ namespaces stage-testapp-13-05 (source 00-namespace) is valid
✔ deployments testapp-13-05 -n stage-testapp-13-05 (source testapp) is valid
✔ configmaps testapp-13-05-staff -n stage-testapp-13-05 (source testapp) is valid
✔ ingresses testapp-13-05 -n stage-testapp-13-05 (source testapp) is valid
✔ services testapp-13-05 -n stage-testapp-13-05 (source testapp) is valid
---
stats:
  valid: 5

command took 130ms
[mak@mak-ws testapp-13-05]$ qbec validate prod
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 24ms
3 components evaluated in 4ms
✔ namespaces prod-testapp-13-05 (source 00-namespace) is valid
✔ ingresses testapp-13-05 -n prod-testapp-13-05 (source testapp) is valid
✔ services testapp-13-05 -n prod-testapp-13-05 (source testapp) is valid
✔ endpoints external-api -n prod-testapp-13-05 (source external-api-endpoint) is valid
✔ configmaps testapp-13-05-staff -n prod-testapp-13-05 (source testapp) is valid
✔ services external-api -n prod-testapp-13-05 (source external-api-endpoint) is valid
✔ deployments testapp-13-05 -n prod-testapp-13-05 (source testapp) is valid
---
stats:
  valid: 7

command took 150ms

```

Применяем:
```
[mak@mak-ws testapp-13-05]$ qbec apply stage --yes
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 24ms
2 components evaluated in 6ms

will synchronize 5 object(s)

2 components evaluated in 3ms
create namespaces stage-testapp-13-05 (source 00-namespace)
create configmaps testapp-13-05-staff -n stage-testapp-13-05 (source testapp)
create ingresses testapp-13-05 -n stage-testapp-13-05 (source testapp)
create deployments testapp-13-05 -n stage-testapp-13-05 (source testapp)
W0220 16:21:17.972853   29571 warnings.go:70] policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v1.25+
I0220 16:21:18.540286   29571 request.go:665] Waited for 1.160580558s due to client-side throttling, not priority and fairness, request: GET:https://m4-1.test-kube.iptp.net:6443/api/v1/namespaces?labelSelector=qbec.io%2Fapplication%3Dtestapp-13-05%2Cqbec.io%2Fenvironment%3Dstage%2C%21qbec.io%2Ftag&limit=1000
create services testapp-13-05 -n stage-testapp-13-05 (source testapp)
server objects load took 1.804s
---
stats:
  created:
  - namespaces stage-testapp-13-05 (source 00-namespace)
  - configmaps testapp-13-05-staff -n stage-testapp-13-05 (source testapp)
  - ingresses testapp-13-05 -n stage-testapp-13-05 (source testapp)
  - deployments testapp-13-05 -n stage-testapp-13-05 (source testapp)
  - services testapp-13-05 -n stage-testapp-13-05 (source testapp)

waiting for readiness of 1 objects
  - deployments testapp-13-05 -n stage-testapp-13-05

✓ 0s    : deployments testapp-13-05 -n stage-testapp-13-05 :: successfully rolled out (0 remaining)

✓ 0s: rollout complete
command took 2.06s
[mak@mak-ws testapp-13-05]$ qbec apply prod --yes
setting cluster to cluster.local
setting context to kubernetes-admin@cluster.local
cluster metadata load took 23ms
3 components evaluated in 5ms

will synchronize 7 object(s)

3 components evaluated in 4ms
create namespaces prod-testapp-13-05 (source 00-namespace)
create configmaps testapp-13-05-staff -n prod-testapp-13-05 (source testapp)
W0220 16:21:26.653787   29585 warnings.go:70] policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v1.25+
I0220 16:21:26.848084   29585 request.go:665] Waited for 1.170747721s due to client-side throttling, not priority and fairness, request: GET:https://m4-1.test-kube.iptp.net:6443/api/v1/persistentvolumes?labelSelector=qbec.io%2Fapplication%3Dtestapp-13-05%2Cqbec.io%2Fenvironment%3Dprod%2C%21qbec.io%2Ftag&limit=1000
create endpoints external-api -n prod-testapp-13-05 (source external-api-endpoint)
create ingresses testapp-13-05 -n prod-testapp-13-05 (source testapp)
create deployments testapp-13-05 -n prod-testapp-13-05 (source testapp)
create services external-api -n prod-testapp-13-05 (source external-api-endpoint)
create services testapp-13-05 -n prod-testapp-13-05 (source testapp)
server objects load took 1.804s
---
stats:
  created:
  - namespaces prod-testapp-13-05 (source 00-namespace)
  - configmaps testapp-13-05-staff -n prod-testapp-13-05 (source testapp)
  - endpoints external-api -n prod-testapp-13-05 (source external-api-endpoint)
  - ingresses testapp-13-05 -n prod-testapp-13-05 (source testapp)
  - deployments testapp-13-05 -n prod-testapp-13-05 (source testapp)
  - services external-api -n prod-testapp-13-05 (source external-api-endpoint)
  - services testapp-13-05 -n prod-testapp-13-05 (source testapp)

waiting for readiness of 1 objects
  - deployments testapp-13-05 -n prod-testapp-13-05

  0s    : deployments testapp-13-05 -n prod-testapp-13-05 :: 0 of 3 updated replicas are available
  1s    : deployments testapp-13-05 -n prod-testapp-13-05 :: 1 of 3 updated replicas are available
  1s    : deployments testapp-13-05 -n prod-testapp-13-05 :: 2 of 3 updated replicas are available
✓ 5s    : deployments testapp-13-05 -n prod-testapp-13-05 :: successfully rolled out (0 remaining)

✓ 5s: rollout complete
command took 8.21s
```

Проверяем деплой:
```
[mak@mak-ws ~]$ kubectl -n stage-testapp-13-05 get deployment,pod,svc,ep,ingress
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/testapp-13-05   1/1     1            1           2m13s

NAME                                READY   STATUS    RESTARTS   AGE
pod/testapp-13-05-bfb487c69-l9f6t   1/1     Running   0          2m13s

NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/testapp-13-05   ClusterIP   10.233.57.149   <none>        80/TCP    2m11s

NAME                      ENDPOINTS         AGE
endpoints/testapp-13-05   10.233.78.23:80   2m11s

NAME                                      CLASS   HOSTS             ADDRESS   PORTS   AGE
ingress.networking.k8s.io/testapp-13-05   nginx   testapp-stage.i             80      2m13s

[mak@mak-ws ~]$ kubectl -n prod-testapp-13-05 get deployment,pod,svc,ep,ingress
NAME                            READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/testapp-13-05   3/3     3            3           111s

NAME                                READY   STATUS    RESTARTS   AGE
pod/testapp-13-05-bfb487c69-cgtwf   1/1     Running   0          111s
pod/testapp-13-05-bfb487c69-gbwm2   1/1     Running   0          111s
pod/testapp-13-05-bfb487c69-rhfqt   1/1     Running   0          111s

NAME                    TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/external-api    ClusterIP   10.233.8.196   <none>        80/TCP    110s
service/testapp-13-05   ClusterIP   10.233.2.215   <none>        80/TCP    110s

NAME                      ENDPOINTS                                          AGE
endpoints/external-api    3.209.99.235:80                                    111s
endpoints/testapp-13-05   10.233.105.14:80,10.233.126.6:80,10.233.78.24:80   110s

NAME                                      CLASS   HOSTS       ADDRESS   PORTS   AGE
ingress.networking.k8s.io/testapp-13-05   nginx   testapp.i             80      111s
```

Тестируем приложение в средах `stage` и `prod`:
```
[mak@mak-ws ~]$ curl testapp-stage.i
<html><body>
<h1>Hello</h1>
<p>This is test HTML</p>
</body></html>

[mak@mak-ws ~]$ curl testapp.i
{
  "args": {}, 
  "headers": {
    "Accept": "*/*", 
    "Host": "external-api", 
    "User-Agent": "curl/7.65.0-DEV", 
    "X-Amzn-Trace-Id": "Root=1-62125dd8-4bdcf6c654849b803f7e789d", 
    "X-Forwarded-Host": "testapp.i", 
    "X-Forwarded-Scheme": "http", 
    "X-Scheme": "http"
  }, 
  "origin": "10.9.41.25, 176.56.186.64", 
  "url": "http://testapp.i/get"
}

```


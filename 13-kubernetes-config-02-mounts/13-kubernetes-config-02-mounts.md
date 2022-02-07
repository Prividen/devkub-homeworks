# Домашняя работа по занятию "13.2 разделы и монтирование"

> Приложение запущено и работает, но время от времени появляется необходимость передавать между бекендами данные. А сам бекенд генерирует статику для фронта. Нужно оптимизировать это.  
> Для настройки NFS сервера можно воспользоваться следующей инструкцией (производить под пользователем на сервере, у которого есть доступ до kubectl):  
> ...

```
$ kubectl get sc
NAME   PROVISIONER                                       RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs    cluster.local/nfs-server-nfs-server-provisioner   Delete          Immediate           true                   3h9m
```

---
> ## Задание 1: подключить для тестового конфига общую папку
> В stage окружении часто возникает необходимость отдавать статику бекенда сразу фронтом. Проще всего сделать это через общую папку. Требования:
> * в поде подключена общая папка между контейнерами (например, /static);
> * после записи чего-либо в контейнере с беком файлы можно получить из контейнера с фронтом.

[==> Манифесты](stage-env)

Добавим в описание каждого контейнера общего пода по секции `volumeMounts` с описанием монтирования тома, и сделаем общеподовую секцию `volumes`:
```diff
--- ../13-kubernetes-config-01-objects/test-env/40-back+front-deployment.yaml	2022-02-03 19:56:04.888274113 +0100
+++ stage-env/40-back+front-deployment.yaml	2022-02-07 03:56:02.612824910 +0100
@@ -25,6 +25,9 @@
       containers:
         - name: back
           image: prividen/some-test-backend:0.1
+          volumeMounts:
+            - name: shared-folder
+              mountPath: /static
           ports:
             - containerPort: 9000
           env:
@@ -32,8 +35,14 @@
               value: postgres://postgres:postgres@postgres:5432/news
         - name: front
           image: prividen/some-test-frontend:latest
+          volumeMounts:
+            - name: shared-folder
+              mountPath: /static
           ports:
             - containerPort: 80
           env:
             - name: BASE_URL
               value: http://localhost:9000
+      volumes:
+        - name: shared-folder
+          emptyDir: {}
```

Запускаем, тестируем: запишем Текст в файл в общей папке в одном контейнере пода, 
прочтём его в другом контейнере и сравним.  

```
$ kubectl apply -f stage-env/
namespace/13-02-stage created
service/postgres created
statefulset.apps/postgres created
deployment.apps/back-front created
service/back-front created

$ FSM="I am the Flying Spaghetti Monster. Thou shalt have no other monsters before Me (Afterwards is OK; just use protection). The only Monster who deserves capitalization is Me! Other monsters are false monsters, undeserving of capitalization. - Suggestions, 1:1"
$ HASH=$(echo $FSM |md5sum)
$ kubectl exec deploy/back-front -n 13-02-stage -c back -- sh -c "echo '$FSM' > /static/fsm.txt"
$ CHECK_HASH=$(kubectl exec deploy/back-front -n 13-02-stage -c front -- cat /static/fsm.txt |md5sum)
$ [ "$HASH" = "$CHECK_HASH" ] && echo "rAmen!"
rAmen!
```
Совпадают.

---
> ## Задание 2: подключить общую папку для прода
> Поработав на stage, доработки нужно отправить на прод. В продуктиве у нас контейнеры крутятся в разных подах, поэтому потребуется PV и связь через PVC. Сам PV должен быть связан с NFS сервером. Требования:
> * все бекенды подключаются к одному PV в режиме ReadWriteMany;
> * фронтенды тоже подключаются к этому же PV с таким же режимом;
> * файлы, созданные бекендом, должны быть доступны фронту.

[==> Манифесты](prod-env)

[Создадим PVC](prod-env/30-shared-folder-pvc.yaml), примерно как рекомендовалось при установке NFS-сервера.  
В описание каждого пода добавим секцию `volumes` с типом `persistentVolumeClaim`, 
для автоматического выделения места на сторадж-классе NFS, 
и для контейнера секцию `volumeMounts` описывающую монтирование этого тома, например:

```diff
--- ../13-kubernetes-config-01-objects/prod-env/40-back-deployment.yaml	2022-02-03 19:56:04.833274924 +0100
+++ prod-env/40-back-deployment.yaml	2022-02-07 03:58:05.758924631 +0100
@@ -25,6 +25,9 @@
       containers:
       - name: back
         image: prividen/some-test-backend:0.2.2
+        volumeMounts:
+          - name: shared-folder
+            mountPath: /static
         ports:
         - containerPort: 9000
         env:
@@ -32,3 +35,7 @@
             value: postgres://postgres:postgres@postgres:5432/news
           - name: JOKES_API_URL
             value: "http://joke-server/joke/any"
+      volumes:
+        - name: shared-folder
+          persistentVolumeClaim:
+            claimName: shared-folder-volume-claim
```

Запускаем, смотрим что получилось...
```
$ kubectl get pod,deployment,sts,pvc -n 13-02-prod -o wide
NAME                         READY   STATUS              RESTARTS   AGE     IP             NODE                      NOMINATED NODE   READINESS GATES
pod/back-65f7ffd78f-9sfvl    0/1     Init:0/1            0          10m     <none>         m4-2.test-kube.iptp.net   <none>           <none>
pod/front-67d59c676f-glnwq   0/1     ContainerCreating   0          5m27s   <none>         m4-3.test-kube.iptp.net   <none>           <none>
pod/postgres-0               1/1     Running             0          10m     10.233.78.26   m4-2.test-kube.iptp.net   <none>           <none>

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES                               SELECTOR
deployment.apps/back    0/1     1            0           10m     back         prividen/some-test-backend:0.2.2     app=back
deployment.apps/front   0/1     1            0           5m27s   front        prividen/some-test-frontend:latest   app=front

NAME                        READY   AGE   CONTAINERS        IMAGES
statefulset.apps/postgres   1/1     10m   postgres-server   postgres:13-alpine

NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/shared-folder-volume-claim   Bound    pvc-4e1e4a5e-27aa-492f-893a-95f5e000e216   100Mi      RWX            nfs            10m   Filesystem
```

Что-то странное получилось. 
```
$ kubectl describe pod/back-65f7ffd78f-9sfvl -n 13-02-prod
...
  Warning  FailedMount       3m47s (x2 over 6m5s)  kubelet            Unable to attach or mount volumes: unmounted volumes=[shared-folder], unattached volumes=[kube-api-access-lv8jp shared-folder]: timed out waiting for the condition
  Warning  FailedMount       116s (x11 over 8m8s)  kubelet            MountVolume.SetUp failed for volume "pvc-4e1e4a5e-27aa-492f-893a-95f5e000e216" : mount failed: exit status 32
Mounting command: mount
Mounting arguments: -t nfs -o vers=3 10.233.14.133:/export/pvc-4e1e4a5e-27aa-492f-893a-95f5e000e216 /var/lib/kubelet/pods/a9a5362c-4ad9-4b24-a310-fabfa60e5e32/volumes/kubernetes.io~nfs/pvc-4e1e4a5e-27aa-492f-893a-95f5e000e216
Output: mount: /var/lib/kubelet/pods/a9a5362c-4ad9-4b24-a310-fabfa60e5e32/volumes/kubernetes.io~nfs/pvc-4e1e4a5e-27aa-492f-893a-95f5e000e216: bad option; for several filesystems (e.g. nfs, cifs) you might need a /sbin/mount.<type> helper program.
```
Наверное, helm был создан для автоматизации, упрощения и сам обо всём заботится. Ладно, поможем ему..

```
# dnf provides "/sbin/mount.nfs*"
nfs-utils-1:2.3.3-46.el8.x86_64 : NFS utilities and supporting clients and daemons for the kernel NFS server
Repo        : baseos
Matched from:
Filename    : /sbin/mount.nfs
Filename    : /sbin/mount.nfs4

$ ansible -i inventory/mycluster/ -m dnf -a "name=nfs-utils state=latest" -b all
...
```

И всё само собой заработало!
```
$ kubectl get pod,deployment,sts,pvc -n 13-02-prod -o wide
NAME                         READY   STATUS    RESTARTS   AGE   IP              NODE                      NOMINATED NODE   READINESS GATES
pod/back-65f7ffd78f-9sfvl    1/1     Running   0          17m   10.233.78.27    m4-2.test-kube.iptp.net   <none>           <none>
pod/front-67d59c676f-glnwq   1/1     Running   0          12m   10.233.105.26   m4-3.test-kube.iptp.net   <none>           <none>
pod/postgres-0               1/1     Running   0          17m   10.233.78.26    m4-2.test-kube.iptp.net   <none>           <none>

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                               SELECTOR
deployment.apps/back    1/1     1            1           17m   back         prividen/some-test-backend:0.2.2     app=back
deployment.apps/front   1/1     1            1           12m   front        prividen/some-test-frontend:latest   app=front

NAME                        READY   AGE   CONTAINERS        IMAGES
statefulset.apps/postgres   1/1     17m   postgres-server   postgres:13-alpine

NAME                                               STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE   VOLUMEMODE
persistentvolumeclaim/shared-folder-volume-claim   Bound    pvc-4e1e4a5e-27aa-492f-893a-95f5e000e216   100Mi      RWX            nfs            17m   Filesystem
```

Наши поды расселись по разным нодам, тем интересней. Тестируем по той же методике:

```
$ kubectl exec deploy/back -n 13-02-prod -c back -- sh -c "echo '$FSM' > /static/fsm.txt"
$ CHECK_HASH=$(kubectl exec deploy/front -n 13-02-prod -c front -- cat /static/fsm.txt |md5sum)
$ [ "$HASH" = "$CHECK_HASH" ] && echo "rAmen!"
rAmen!
```

Замечательно, всё работает даже с NFS.

Финальная проверка:
```
$ echo $HASH |grep -q 42 && echo "Answer matches"
Answer matches
```
Да, это оно!

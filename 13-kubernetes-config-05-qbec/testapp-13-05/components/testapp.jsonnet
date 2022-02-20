local p = import '../params.libsonnet';
local params = p.components.testapp;

[
  {
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: params.appname + '-staff',
    },
    data: {
      'nginx.conf': params.nginx.conf,  //
      'root-location.conf': params.nginx.root_location,
      'index.html': params.nginx.index,
    },
  },
  {
    apiVersion: 'apps/v1',
    kind: 'Deployment',
    metadata: {
      name: params.appname,
    },
    spec: {
      selector: {
        matchLabels: {
          app: params.appname,
        },
      },
      replicas: params.replicas,
      template: {
        metadata: {
          labels: {
            app: params.appname,
          },
        },
        spec: {
          terminationGracePeriodSeconds: 3,
          containers: [
            {
              name: 'nginx',
              image: params.nginx.image,
              ports: [
                {
                  containerPort: 80,
                },
              ],
              volumeMounts: [
                {
                  mountPath: '/etc/nginx',
                  readOnly: true,
                  name: 'nginx-conf',
                },
                {
                  mountPath: '/html',
                  readOnly: true,
                  name: 'html-docs',
                },
              ],
            },
          ],
          volumes: [
            {
              name: 'nginx-conf',
              configMap: {
                name: params.appname + '-staff',
                items: [
                  {
                    key: 'nginx.conf',
                    path: 'nginx.conf',
                  },
                  {
                    key: 'root-location.conf',
                    path: 'root-location.conf',
                  },
                ],
              },
            },
            {
              name: 'html-docs',
              configMap: {
                name: params.appname + '-staff',
                items: [
                  {
                    key: 'index.html',
                    path: 'index.html',  //
                  },
                ],
              },
            },
          ],
        },
      },
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: params.appname,
    },
    spec: {
      type: 'ClusterIP',
      ports: [
        {
          port: 80,
          targetPort: 80,
        },
      ],
      selector: {
        app: params.appname,
      },
    },
  },
  {
    apiVersion: 'networking.k8s.io/v1',
    kind: 'Ingress',
    metadata: {
      name: params.appname,
    },
    spec: {
      ingressClassName: params.ingress_class,
      rules: [
        {
          host: params.hostname,
          http: {
            paths: [
              {
                backend: {
                  service: {
                    name: params.appname,
                    port: {
                      number: 80,
                    },
                  },
                },
                path: '/',
                pathType: 'Prefix',
              },
            ],
          },
        },
      ],
    },
  },
]

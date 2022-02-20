local p = import '../params.libsonnet';
local params = p.components.testapp;

[
  {
    apiVersion: 'v1',
    kind: 'Service',
    metadata: {
      name: 'external-api',
    },
    spec: {
      type: 'ClusterIP',
      ports: [
        {
          protocol: 'TCP',
          port: 80,
          targetPort: 80,
        },
      ],
    },
  },
  {
    apiVersion: 'v1',
    kind: 'Endpoints',
    metadata: {
      name: 'external-api',
    },
    subsets: [
      {
        addresses: [
          {
            ip: params.api_addr,
          },
        ],
        ports: [
          {
            port: 80,  //
          },
        ],
      },
    ],
  },
]

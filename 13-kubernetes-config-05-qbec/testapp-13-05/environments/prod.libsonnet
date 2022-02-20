local base = import './base.libsonnet';

base {
  components+: {
    testapp+: {
      replicas: 3,
      nginx+: {
        root_location: 'location / {proxy_pass http://external-api/get;}\n',
      },
    },
  },
}

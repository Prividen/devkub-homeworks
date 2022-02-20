local base = import './base.libsonnet';

base {
  components+: {
    testapp+: {
      hostname: 'testapp-stage.i',
    },
  },
}

{
  components: {
    testapp: {
      appname: 'testapp-13-05',
      replicas: 1,
      hostname: 'testapp.i',
      api_addr: '3.209.99.235',
      ingress_class: 'nginx',
      nginx: {
        image: 'nginx:stable',
        conf: |||
          user nginx;
          worker_processes  1;
          error_log  /dev/stderr;
          events {
            worker_connections  1024;
          }
          http {
            access_log	/dev/stdout;

            server {
                listen       80;
                server_name  _;
                include root-location.conf;
            }
          }

        |||,
        root_location: 'location / {\n    root   /html;\n    index  index.html index.htm;\n}\n',
        index: '<html><body>\n<h1>Hello</h1>\n<p>This is test HTML</p>\n</body></html>\n',
      },
    },
  },
}

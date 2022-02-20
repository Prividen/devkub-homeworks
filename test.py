#! /usr/bin/env python3

import json

str='{"user":{"login" = vasya}}'
myjs = json.loads(str)

print(myjs['user']['login'])



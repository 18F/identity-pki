#!/usr/bin/env python

import os
import json

users = {}
user_databags = os.listdir(".")
for user_databag in user_databags:
    databag = json.loads(open(user_databag).read())
    if databag["id"] == "deploy":
        continue
    users[databag["id"]] = databag["password"]
print(json.dumps(users))

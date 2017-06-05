#!/bin/bash
for H in {idp1-0,idp2-0,worker,elk,jenkins}{.login.gov.internal,}; do
  ssh-keygen -R $H
done

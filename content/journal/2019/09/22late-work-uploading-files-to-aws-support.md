---
title: "late work uploading files to AWS support"
tags: [ "aws", "support", "elb" ]
author: Rob Nugen
date: 2019-09-22T22:09:56+09:00
---

1. Login at https://admin.ab.redacted.example.com

2. See 502 Bad Gateway

3. In the request, change https to http

4. See 502 Bad Gateway

5. bypass ELB by placing this in local /etc/hosts file

13.23.21.14  admin.ab.redacted.example.com

6. reload the request with http OR https

7. the request works

Those are redacted instructions that showed AWS support that something
seemed amiss with the elastic load balancer.

M helped me activate tcpdump and we captured output while recreating
the error in different capacities.

I have just uploaded the access.log file and tcpdump files and several
log files from ELB.  They are going to dig through them to try to
figure out what is happening.  So so glad to have the support!

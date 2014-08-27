#!/usr/bin/python
# -*- coding: utf-8 -*-

import re, sys

f = open(sys.argv[1])

array = f.read().replace("\n", " ").split(" ")

p = re.compile(r'\\')
s = re.compile(r'DerivedData')
app = re.compile(r'(\.app/)')
app_ = re.compile(r'(/.+app)/')

k = ''
m = ''
for line in array:

     i = ''
     j = ''
     i = s.findall(line)

     if k:
        k = k + ' ' + str(line)

     if i or k:
        m = app.findall(line)
        if m:
          if k:
             print app_.findall(str(k))[0]
          else:
             print app_.findall(line)[0]
          break
#          k = ''
        else:
          j = p.findall(line)
          if j and not k:
            k = line[:-1]
          elif not j and k:
            k = ''


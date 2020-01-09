#!/bin/sh
set -e
dub test $@
dub test :web $@

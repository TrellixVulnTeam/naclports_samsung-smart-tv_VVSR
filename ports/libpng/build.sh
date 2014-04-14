#!/bin/bash

if [ "${TOOLCHAIN}" = "newlib" ]; then
  export NACLPORTS_LDFLAGS="${NACLPORTS_LDFLAGS} -lnosys"
fi

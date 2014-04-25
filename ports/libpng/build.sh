#!/bin/bash

if [ "${TOOLCHAIN}" = "newlib" ]; then
  export NACLPORTS_LDFLAGS="${NACLPORTS_LDFLAGS} -lnosys"
fi

if [ "${TOOLCHAIN}" = "pnacl" ]; then
  export NACLPORTS_LDFLAGS="${NACLPORTS_LDFLAGS} -L${NACLPORTS_LIBDIR} -lnosys"
fi

#!/bin/bash
# Copyright (c) 2014 The Native Client Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

RESULT=0
MESSAGES=

readonly BASE_DIR="$(dirname $0)/.."
cd ${BASE_DIR}

UPLOAD_PATH=nativeclient-mirror/naclports/${PEPPER_DIR}/
if [ -d .git ]; then
  UPLOAD_PATH+=`git number`-`git rev-parse --short HEAD`
else
  UPLOAD_PATH+=${BUILDBOT_GOT_REVISION}
fi

BuildSuccess() {
  echo "naclports: Build SUCCEEDED $1 ($NACL_ARCH)"
}

BuildFailure() {
  MESSAGE="naclports: Build FAILED for $1 ($NACL_ARCH)"
  echo $MESSAGE
  echo "@@@STEP_FAILURE@@@"
  MESSAGES="$MESSAGES\n$MESSAGE"
  RESULT=1
  if [ "${TEST_BUILDBOT:-}" = "1" ]; then
    exit 1
  fi
}

RunCmd() {
  echo $*
  $*
}

BuildPackage() {
  if RunCmd build_tools/naclports.py build ports/$1 -v --ignore-disabled ; then
    BuildSuccess $1
  else
    BuildFailure $1
  fi
}

ARCH_LIST="i686 x86_64 arm pnacl"
TOOLCHAIN_LIST="pnacl newlib glibc"

InstallPackageMultiArch() {
  echo "@@@BUILD_STEP ${TOOLCHAIN} $1@@@"
  export BUILD_FLAGS="-v --ignore-disabled"
  for NACL_ARCH in ${ARCH_LIST}; do
    export NACL_ARCH
    # pnacl only works on pnacl and nowhere else.
    if [ "${TOOLCHAIN}" = "pnacl" -a "${NACL_ARCH}" != "pnacl" ]; then
      continue
    fi
    if [ "${TOOLCHAIN}" != "pnacl" -a "${NACL_ARCH}" = "pnacl" ]; then
      continue
    fi
    # glibc doesn't work on arm for now.
    if [ "${TOOLCHAIN}" = "glibc" -a "${NACL_ARCH}" = "arm" ]; then
      continue
    fi
    # bionic only works on arm for now.
    if [ "${TOOLCHAIN}" = "bionic" -a "${NACL_ARCH}" != "arm" ]; then
      continue
    fi
    if ! RunCmd make $1 ; then
      BuildFailure $1
    fi
  done
  export NACL_ARCH=all
  BuildSuccess $1
}

CleanAll() {
  echo "@@@BUILD_STEP clean all@@@"
  for TC in ${TOOLCHAIN_LIST}; do
    for ARCH in ${ARCH_LIST}; do
      # TODO(bradnelson): reduce the duplication here.
      # pnacl only works on pnacl and nowhere else.
      if [ "${TC}" = "pnacl" -a "${ARCH}" != "pnacl" ]; then
        continue
      fi
      if [ "${TC}" != "pnacl" -a "${ARCH}" = "pnacl" ]; then
        continue
      fi
      # glibc doesn't work on arm for now.
      if [ "${TC}" = "glibc" -a "${ARCH}" = "arm" ]; then
        continue
      fi
      # bionic only works on arm for now.
      if [ "${TC}" = "bionic" -a "${ARCH}" != "arm" ]; then
        continue
      fi
      if ! TOOLCHAIN=${TC} NACL_ARCH=${ARCH} RunCmd \
          build_tools/naclports.py clean --all; then
        BuildFailure clean
      fi
    done
  done
}

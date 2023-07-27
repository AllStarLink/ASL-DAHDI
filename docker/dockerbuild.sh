#!/bin/bash
set -e

while [[ $# -gt 0 ]]; do
  case $1 in
    -c|--check-changelog)
      CHECK_CHANGELOG=YES
      shift
      ;;
    -a|--architectures)
      ARCHS="$2"
      shift
      shift
      ;;
    -t|--targets)
      TARGETS="$2"
      shift
      shift
      ;;
    -r|--commit-versioning)
      COMMIT_VERSIONING=YES
      shift
      ;;
    -o|--operating-systems)
      OPERATING_SYSTEMS="$2"
      shift
      shift
      ;;
    -*|--*|*)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

if [ -z "$ARCHS" ]
then
  ARCHS="amd64 armhf arm64"
fi

if [ -z "$TARGETS" ]
then
  TARGETS="linux tools"
fi

if [ -z "$OPERATING_SYSTEMS" ]
then
  OPERATING_SYSTEMS="buster"
fi

echo "Architectures: $ARCHS"
echo "Targets: $TARGETS"
echo "Operating Systems: $OPERATING_SYSTEMS"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PDIR=$(dirname $DIR)

#get the build targets
cd $PDIR
BUILD_TARGETS=""
ANYCOUNT=0
for t in $TARGETS; do
  if [ -z "$CHECK_CHANGELOG" ] || git diff --name-only HEAD HEAD~1 | grep -q $t/debian/changelog; then
    BUILD_TARGETS+="$t "
    c=$(grep "^Architecture:" $t/debian/control | egrep -v "^Architecture: ?all" | wc -l)
    ANYCOUNT=$((c+ANYCOUNT))
  fi
done
BUILD_TARGETS=$(echo "$BUILD_TARGETS" | xargs)


#if 'any' = 0, only run for one arch (there are no arch specific packages)
if [ "$ANYCOUNT" -eq "0" ] ; then
  set -- $ARCHS
  ARCHS=$1
fi

#run --build=any for following arch's after the first to prevent re-creating 'all' packages
DPKG_BUILDOPTS="-b -uc -us"
for A in $ARCHS; do
  if [ "$A" == "armhf" ]; then
    DA="arm32v7"
  elif [ "$A" == "arm64" ]; then
    DA="arm64v8"
  else
    DA="$A"
  fi
  for O in $OPERATING_SYSTEMS; do
       # The following is a hack to deal with the fact that there is no trixie tag for riscv64/debian.  It will break when trixie is no longer the testing release
       if [ "$A" == "riscv64" && "$O" == "trixie" ]; then
         O="testing"
       fi
       docker build -f $DIR/Dockerfile -t asl-dahdi_builder.$O.$A --build-arg ARCH="$DA" --build-arg OS="$O" --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g) $DIR
       docker run -v $PDIR:/src -e DPKG_BUILDOPTS="$DPKG_BUILDOPTS" -e BUILD_TARGETS="$BUILD_TARGETS" -e COMMIT_VERSIONING="$COMMIT_VERSIONING" asl-dahdi_builder.$O.$A
       docker image rm --force asl-dahdi_builder.$O.$A
       DPKG_BUILDOPTS="--build=any -uc -us"
  done
done

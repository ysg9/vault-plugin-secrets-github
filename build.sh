#!/bin/bash
# build.sh - build script for drone pipeline
set -e
#set -x

APPNAME=vault-plugin-secrets-github
VER=${DRONE_TAG:-$(date '+%s')}
CURDIRNAME=$(basename `pwd`)
WORKDIR=${DRONE_WORKSPACE:-.}

go mod edit -replace github.com/go-ldap/ldap/v3=github.com/go-ldap/ldap/v3@v3.4.2
go mod edit -replace github.com/gogo/protobuf=github.com/gogo/protobuf@v1.3.2
go mod edit -replace github.com/yuin/goldmark=github.com/yuin/goldmark@v1.4.12
go mod tidy

export GOPRIVATE=github.com/sgnus-it**
#export GOARCH=amd64

IFS=',' read -r -a PLATFORM <<< ${PLUGIN_PLATFORMS:-linux/amd64}
for p in "${PLATFORM[@]}"; do
  GOARCH=$(basename $p)
  GOOS=$(dirname $p)
  echo "building for ${GOOS}/${GOARCH}: ${VER}"
  if [[ ${DRONE:-} != "" ]]; then
    BIN="${APPNAME}_${VER}_${GOOS}_${GOARCH}"
  else
    BIN="${APPNAME}"
  fi
  EXE=$BIN
  if [[ $GOOS == "windows" ]]; then
    EXE="${BIN}.exe"
  fi
  make ${CURDIRNAME}-${GOOS}-${GOARCH}
  mv ${CURDIRNAME}-${GOOS}-${GOARCH} ${WORKDIR}/${EXE}
  sha256sum ${WORKDIR}/${EXE} |cut -d' ' -f1 > ${WORKDIR}/${EXE}.sha256
  if [[ ${DRONE:-} != "" ]]; then
    zip -j ${WORKDIR}/${BIN}.zip ${WORKDIR}/${EXE}
  fi
done
echo "build complete"

go list -m all > go.list
echo "go.list generated"
go mod graph > go.graph
echo "go.graph generated"


#!/bin/bash

RELEASE_VERSION=$1
USER_NAME=$2
EMAIL=$3

git config user.name "$USER_NAME"
git config user.email "$EMAIL"
git fetch --all && git checkout main

sudo apt-get install -y protobuf-compiler golang-goprotobuf-dev
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

for service_name in order payment shipping; do
  dir=./golang/${service_name}
  if [ ! -d $dir ]; then
    mkdir -p $dir
  fi

  protoc --go_out=./golang --go_opt=paths=source_relative \
    --go-grpc_out=./golang --go-grpc_opt=paths=source_relative \
   ./${service_name}/*.proto
  cd golang/${service_name}
  go mod init \
    github.com/virezox/microservices-proto/golang/${service_name} || true
  go mod tidy
  cd ../../
done

git add . && git commit -am "ci: proto update, bump to ${RELEASE_VERSION}" || true
git push origin HEAD:main

for service_name in order payment shipping; do
  git tag -fa golang/${service_name}/${RELEASE_VERSION} \
    -m "golang/${service_name}/${RELEASE_VERSION}" 
  git push origin refs/tags/golang/${service_name}/${RELEASE_VERSION}
done

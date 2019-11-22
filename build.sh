#!/bin/bash
# Build and package logstash plugins using logstash-oss docker image

set -eu

plugins='logstash-output-statsd logstash-output-webhdfs'
logstash_version=${LS_VERSION:-7.4.0}

build_dir=$PWD/build
outfile=$build_dir/${logstash_version}-plugins.zip

install -d $build_dir

docker run --mount type=bind,source=$build_dir,target=$build_dir \
  docker.elastic.co/logstash/logstash-oss:$logstash_version \
  bash -c "install -d $build_dir && \
    bin/logstash-plugin install $plugins && \
    bin/logstash-plugin prepare-offline-pack --output $outfile $plugins"

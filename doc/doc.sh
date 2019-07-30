#!/bin/bash

set -eu

DOC_VERSION=5
DOC_PATH=/sdk/js/5

# Used by vuepress
export DOC_DIR=$DOC_VERSION
export SITE_BASE=$DOC_PATH/

# Used to specify --no-cache for example
ARGS=${2:-""}

if [ ! -d "./$DOC_DIR" ]
then
  echo "Cannot find $DOC_DIR/. You must run this script from doc/ directory."
  exit 1
fi

case $1 in
  prepare)
    if [ -d "framework" ]
    then
      echo "Pulling latest framework version"
      bash -c "cd framework && git checkout master && git reset --hard HEAD~ && git pull"
    else
      echo "Clone documentation framework"
      git clone --depth 10 --single-branch --branch master https://github.com/kuzzleio/documentation.git framework/
    fi

    echo "Link local doc for dead links checking"
    rm framework/src$DOC_PATH
    ln -s ../../../../$DOC_VERSION framework/src$DOC_PATH

    echo "Install dependencies"
    npm --prefix framework/ install
  ;;

  dev)
    ./framework/node_modules/.bin/vuepress dev $DOC_VERSION/ $ARGS
  ;;

  build)
    ./framework/node_modules/.bin/vuepress build $DOC_VERSION/ $ARGS
  ;;

  upload)
    aws s3 sync $DOC_VERSION/.vuepress/dist s3://$S3_BUCKET$SITE_BASE --delete
  ;;

  cloudfront)
    aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths $SITE_BASE
  ;;

  *)
    echo "Usage : $0 <prepare|dev|build|upload|cloudfront>"
    exit 1
  ;;
esac

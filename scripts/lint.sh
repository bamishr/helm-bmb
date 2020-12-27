#!/bin/bash
set -eux

SRCROOT="$(cd "$(dirname "$0")/.." && pwd)"

for dir in $(find $SRCROOT/charts -mindepth 1 -maxdepth 1 -type d);
do
    rm -rf $dir/charts
    name=$(basename $dir)
    echo "Running Helm linting for $name"
    docker run \
        -v "$SRCROOT:/workdir" \
        gcr.io/kubernetes-charts-ci/test-image:v3.1.0 \
        ct \
        lint \
        --config .circleci/chart-testing.yaml \
        --lint-conf .circleci/lintconf.yaml \
        --charts "/workdir/charts/${name}"
done
   if [ $(helm dep list $dir 2>/dev/null| wc -l) -gt 1 ]
    then
        # Bug with Helm subcharts with hyphen on them
        # https://github.com/argoproj/argo-helm/pull/270#issuecomment-608695684
        if [ "$name" == "argo-cd" ]
        then
            echo "Restore ArgoCD RedisHA subchart"
            git checkout $dir
        fi
        echo "Processing chart dependencies"
        helm --debug dep build $dir
    fi

    echo "Processing $dir"
    helm --debug package $dir
done

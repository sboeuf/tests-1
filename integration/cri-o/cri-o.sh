#!/bin/bash
#
# Copyright (c) 2017-2018 Intel Corporation
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")
source "${SCRIPT_PATH}/crio_skip_tests.sh"
source "${SCRIPT_PATH}/versions.txt"

crio_repository="github.com/kubernetes-incubator/cri-o"
check_crio_repository="$GOPATH/src/${crio_repository}"

if [ -d ${check_crio_repository} ]; then
	pushd ${check_crio_repository}
	check_version=$(git log -1 --pretty=format:"%H" | grep "${crio_version}")
	if [ $? -ne 0 ]; then
		git fetch
		git checkout "${crio_version}"
	fi
	popd
else
	echo "Obtain CRI-O repository"
	go get -d "${crio_repository}" || true
	pushd ${check_crio_repository}
	git fetch
	git checkout "${crio_version}"
	popd
fi

OLD_IFS=$IFS
IFS=''

# Skip CRI-O tests that currently are not working
pushd $GOPATH/src/${crio_repository}/test/
for i in ${skipCRIOTests[@]}
do
	sed -i '/'${i}'/a skip \"This is not working (Issue https://github.com/kata-containers/agent/issues/138)\"' "$GOPATH/src/${crio_repository}/test/ctr.bats"
done

IFS=$OLD_IFS

export STORAGE_OPTIONS="--storage-driver devicemapper --storage-opt dm.use_deferred_removal=false"
./test_runner.sh ctr.bats
popd

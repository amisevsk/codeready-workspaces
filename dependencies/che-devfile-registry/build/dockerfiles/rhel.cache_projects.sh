#!/bin/bash
#
# Copyright (c) 2018-2020 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation
#

set -x

if [[ ! -f /tmp/devfiles.tgz ]] || [[ ${BOOTSTRAP} == "true" ]]; then
  ./cache_projects.sh devfiles resources
else
  tar -xvf /tmp/devfiles.tgz -C "${WORKDIR}/"
fi

#!/bin/bash

#
# Copyright (C) 2022 GeoPD <geoemmanuelpd2001@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

ccache_download () {
	mkdir -p ~/.config/rclone
	echo "$DRIVE" > ~/.config/rclone/rclone.conf
	rclone copy rom:ccache/$NAME/ccache.tar.zst /tmp -P
	tar -xaf ccache.tar.zst
	rm -rf ccache.tar.zst
        echo "remanants of CCACHE is removed"
}

cd /tmp
ccache_download
echo "CCACHE IS CONFIGURED"

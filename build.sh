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

# User
GIT_USER="greengreen2212"

# Email
GIT_EMAIL="greenhumam@protonmail.com"

# Local manifest
LOCAL_MANIFEST=https://${TOKEN}@github.com/greengreen2212/local_manifest

# ROM Manifest and Branch
rom() {
	case "${NAME}" in
		"AEX-12") MANIFEST=https://github.com/AospExtended/manifest.git BRANCH=12.x
		;;
		"Crdroid-12") MANIFEST=https://github.com/crdroidandroid/android.git BRANCH=12.0
		;;
		"lineage-19.1") MANIFEST=https://github.com/LineageOS/android BRANCH=lineage-19.1
		;;
		"Evox-12") MANIFEST=https://github.com/Evolution-X/manifest.git BRANCH=snow
		;;
		*) echo "Setup Rom manifest and branch name in case function"
 		exit 1
 		;;
	esac
}

# Build command for rom
build_command() {
	case "${NAME}" in
		"AEX-12") lunch aosp_sakura-user && m aex -j20
		;;
		"Crdroid-12") lunch lineage_sakura-user && m bacon -j20
		;;
		"lineage-19.1") mka sepolicy && mka init && mka bootimage && mka bacon -j20
		;;
		"Evox-12") lunch evolution_sakura-user && m evolution -j20
		;;
		*) echo "Build commands need to be added!"
		exit 1
		;;
	esac
}

# Export tree paths
tree_path() {
	# Device,vendor & kernel Tree paths
	DEVICE_TREE=device/xiaomi/beryllium
	COMMON_TREE=device/xiaomi/sdm845-common
	VENDOR_TREE=vendor/xiaomi
	KERNEL_TREE=kernel/xiaomi/sdm845
}



# Setup build dir
build_dir() {
	mkdir -p /tmp/rom
	cd /tmp/rom
}

# Git configuration values
git_setup() {
	git config --global user.name $GIT_USER
	git config --global user.email $GIT_EMAIL
}



# Repo sync and additional configurations
build_configuration() {
	repo init --depth=1 --no-repo-verify -u $MANIFEST  -b $BRANCH -g default,-mips,-darwin,-notdefault
	git clone $LOCAL_MANIFEST -b lin1 .repo/local_manifests
	repo sync -c --no-clone-bundle --no-tags --optimized-fetch --prune --force-sync -j30
}

# Export time, time format for telegram messages
time_sec() {
	export $1=$(date +"%s")
}

time_diff() {
	export $1=$(($3 - $2))
}

# Branch name & Head commit sha for ease of tracking
commit_sha() {
	tree_path
	for repo in ${DEVICE_TREE} ${COMMON_TREE} ${VENDOR_TREE} ${KERNEL_TREE} 
	do
		printf "[$(echo $repo | cut -d'/' -f1 )/$(git -C ./$repo/.git rev-parse --short=10 HEAD)]"
	done
}

# Setup ccache
ccache_configuration() {
        . build/envsetup.sh
        lunch lineage_beryllium-userdebug
	export CCACHE_DIR=/tmp/ccache
	export CCACHE_EXEC=$(which ccache)
	export USE_CCACHE=1
	export CCACHE_COMPRESS=true
	export CCACHE_COMPRESSLEVEL=1
	export CCACHE_LIMIT_MULTIPLE=0.9
	export CCACHE_MAXSIZE=50G
	ccache -z
}

# Setup TG message and build posts
telegram_message() {
	curl -s -X POST "https://api.telegram.org/bot${BOTTOKEN}/sendMessage" -d chat_id="${CHATID}" \
	-d "parse_mode=Markdown" \
	-d text="$1"
}

telegram_build() {
	curl --progress-bar -F document=@"$1" "https://api.telegram.org/bot${BOTTOKEN}/sendDocument" \
	-F chat_id="${CHATID}" \
	-F "disable_web_page_preview=true" \
	-F "parse_mode=Markdown" \
	-F caption="$2"
}

# Send Telegram posts for sync finished, build finished and error logs
telegram_post_sync() {
	telegram_message "
	*🌟 $NAME Build Triggered 🌟*
	*Date:* \`$(date +"%d-%m-%Y %T")\`
	*✅ Sync finished after $((SDIFF / 60)) minute(s) and $((SDIFF % 60)) seconds*"  &> /dev/null
}

telegram_post_build() {
	telegram_message "
	*✅ Build finished after $(($BDIFF / 3600)) hour(s) and $(($BDIFF % 3600 / 60)) minute(s) and $(($BDIFF % 60)) seconds*

	*ROM:* \`${ZIPNAME}\`
	*MD5 Checksum:* \`${MD5CHECK}\`
	*Download Link:* [Tdrive](${DWD})
	*Size:* \`${ZIPSIZE}\`

	*Commit SHA:* \`$(commit_sha)\`

	*Date:*  \`$(date +"%d-%m-%Y %T")\`" &> /dev/null
}

telegram_post_error() {
	telegram_build ${ERROR_LOG} "
	*❌ Build failed to compile after $(($BDIFF / 3600)) hour(s) and $(($BDIFF % 3600 / 60)) minute(s) and $(($BDIFF % 60)) seconds*
	_Date:  $(date +"%d-%m-%Y %T")_" &> /dev/null
}

# Sorting final zip ( commonized considering ota zips, .md5sum etc with similiar names  in diff roms)
compiled_zip() {
	ZIP=$(find $(pwd)/out/target/product/${T_DEVICE}/ -maxdepth 1 -name "*${T_DEVICE}*.zip" | perl -e 'print sort { length($b) <=> length($a) } <>' | head -n 1)
	ZIPNAME=$(basename ${ZIP})
	ZIPSIZE=$(du -sh ${ZIP} |  awk '{print $1}')
	MD5CHECK=$(md5sum ${ZIP} | cut -d' ' -f1)
	echo "${ZIP}"
}

# Post Build finished with Time,duration,md5,size&Tdrive link OR post build_error&trimmed build.log in TG
telegram_post(){
	if [ -f $(pwd)/out/target/product/${T_DEVICE}/${ZIPNAME} ]; then
		rclone copy ${ZIP} rom:rom -P
		DWD=${TDRIVE}${ZIPNAME}
		telegram_post_build
	else
		echo "CHECK BUILD LOG" >> $(pwd)/out/build_error
		ERROR_LOG=$(pwd)/out/build_error
		telegram_post_error
	fi
}


# Compile moments! Yay!
compile_moments() {
	build_dir
	git_setup
	time_sec SYNC_START
	rom
	build_configuration
	ccache_configuration
	time_sec SYNC_END
	time_diff SDIFF SYNC_START SYNC_END
	telegram_post_sync
	time_sec BUILD_START
	build_command
	time_sec BUILD_END
	time_diff BDIFF BUILD_START BUILD_END
	compiled_zip
	telegram_post
	ccache -s
}

compile_moments

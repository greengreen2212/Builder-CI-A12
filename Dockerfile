FROM archlinux
LABEL maintainer="GeoPD <geoemmanuelpd2001@gmail.com>"

WORKDIR /tmp

RUN pacman -S adb autoconf automake axel bc bison build-essential ccache clang cmake curl expat expect fastboot flex g++ g++-multilib gawk gcc gcc-multilib git gnupg gperf htop imagemagick locales libncurses5 lib32ncurses5-dev lib32z1-dev libtinfo5 libc6-dev libcap-dev libexpat1-dev libgmp-dev '^liblz4-.*' '^liblzma.*' libmpc-dev libmpfr-dev libncurses5-dev libnl-route-3-dev libprotobuf-dev libsdl1.2-dev libssl-dev libtool libxml-simple-perl libxml2 libxml2-utils lld lsb-core lzip '^lzma.*' lzop maven nano ncftp ncurses-dev openssh-server patch patchelf pkg-config pngcrush pngquant protobuf-compiler python2.7 python3-apt python-all-dev python re2c rclone rsync schedtool screen squashfs-tools subversion sudo tar texinfo tmate tzdata unzip w3m wget xsltproc zip zlib1g-dev zram-config zstd \
    && curl --create-dirs -L -o /usr/local/bin/repo -O -L https://storage.googleapis.com/git-repo-downloads/repo \
    && chmod a+rx /usr/local/bin/repo \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* \
    && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen \
    && TZ=Asia/Kolkata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
    
RUN git clone https://github.com/mirror/make \
    && cd make && ./bootstrap && ./configure && make CFLAGS="-O3 -Wno-error" \
    && sudo install ./make /usr/bin/make

RUN git clone https://github.com/ninja-build/ninja.git \
    && cd ninja && git reset --hard f404f00 && ./configure.py --bootstrap \
    && sudo install ./ninja /usr/bin/ninja

RUN git clone https://github.com/google/kati.git \
    && cd kati && git reset --hard ac01665 && make ckati \
    && sudo install ./ckati /usr/bin/ckati

RUN git clone https://github.com/google/nsjail.git \
    && cd nsjail && git reset --hard e678c25 && make nsjail \
    && sudo install ./nsjail /usr/bin/nsjail

RUN axel -a -n 10 https://github.com/facebook/zstd/releases/download/v1.5.2/zstd-1.5.2.tar.gz \
    && tar xvzf zstd-1.5.2.tar.gz && cd zstd-1.5.2 \
    && sudo make install

RUN git clone https://github.com/google/brotli.git \
    && cd brotli && mkdir out && cd out && ../configure-cmake --disable-debug \
    && make CFLAGS="-O3" && sudo make install

RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip \
    && unzip rclone-current-linux-amd64.zip && cd rclone-*-linux-amd64 \
    && sudo cp rclone /usr/bin/ && sudo chown root:root /usr/bin/rclone \
    && sudo chmod 755 /usr/bin/rclone

VOLUME [/tmp/rom /tmp/ccache]

ENTRYPOINT ["/bin/bash"]

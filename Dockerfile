FROM ubuntu:14.04

ENV USER=developer
ENV UID=1000

# Development user
RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && useradd -u $UID -G sudo -d /home/$USER --shell /bin/bash -m $USER \
    && echo "secret\nsecret" | passwd $USER

# Basic packages and Java 8
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
                      android-tools-adb \
                      android-tools-adbd \
                      blackbox \
                      build-essential \
                      curl \
                      bison \
                      git \
                      gperf \
                      lib32gcc1 \
                      lib32bz2-1.0 \
                      lib32ncurses5 \
                      lib32stdc++6 \
                      lib32z1 \
                      libc6-i386 \
                      libhardware2 \
                      libxml2-utils \
                      make \
                      software-properties-common \
                      unzip \
                      wget \
                      libxtst6 \
                      libxi6 \
    && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections \
    && add-apt-repository -y ppa:webupd8team/java \
    && apt-get update \
    && apt-get install -y oracle-java8-installer \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/cache/oracle-jdk8-installer

# Set things up using the dev user and reduce the need for `chown`s
USER $USER

# Android SDK
ENV SDK_SHA1 725bb360f0f7d04eaccff5a2d57abdd49061326d
ENV SDK_VERSION 24.4.1
RUN wget -q http://dl.google.com/android/android-sdk_r${SDK_VERSION}-linux.tgz -O /tmp/android-sdk.tar.gz \
    && echo "$SDK_SHA1 /tmp/android-sdk.tar.gz" | sha1sum -c - \
    && echo "installing SDK v $SDK_VERSION" \
    && tar -xzf /tmp/android-sdk.tar.gz -C /home/$USER/ \
    && rm /tmp/android-sdk.tar.gz

# Configure the SDK
ENV ANDROID_HOME=$HOME/android-sdk-linux \
    PATH=$PATH:$HOME/android-sdk-linux/tools:$HOME/android-sdk-linux/platform-tools \
    JAVA_HOME=/usr/lib/jvm/java-8-oracle

# Android Studio
ENV STUDIO_URL https://dl.google.com/dl/android/studio/ide-zips/2.2.0.12/android-studio-ide-145.3276617-linux.zip
ENV STUDIO_SHA1 4eec979ad4d216fd591ebe0112367c746cedb114

RUN cd /opt \
    && sudo mkdir android-studio \
    && sudo chown $USER:$USER android-studio \
    && wget -q ${STUDIO_URL} -O /tmp/android-studio.zip \
    && echo "$STUDIO_SHA1 /tmp/android-studio.zip" | sha1sum -c - \
    && unzip /tmp/android-studio.zip \
    && rm /tmp/android-studio.zip

RUN echo y | android update sdk --all --no-ui --force --filter platform-tools
RUN echo y | android update sdk --all --no-ui --force --filter extra-android-m2repository
RUN echo y | android update sdk --all --no-ui --force --filter extra-google-m2repository
RUN echo y | android update sdk --all --no-ui --force --filter android-23
RUN echo y | android update sdk --all --no-ui --force --filter build-tools-23.0.3


# http://stackoverflow.com/questions/32090832/android-studio-cant-start-after-installation
RUN echo "disable.android.first.run=true" > /opt/android-studio/bin/idea.properties

USER root

# setup connection to real hardware device
ADD 51-android.rules /etc/udev/rules.d/51-android.rules
RUN chmod a+r /etc/udev/rules.d/51-android.rules

USER $USER

# TODO: Merge this into the studio installation step
RUN sudo ln -s /opt/android-studio/bin/studio.sh /bin/studio

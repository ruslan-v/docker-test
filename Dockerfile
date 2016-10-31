#galaxy-android-ssh-base
FROM ubuntu:trusty

MAINTAINER Ruslan Vlasyuk "rvlasyuk@cogniance.com"

# Set the locale
RUN locale-gen en_US.UTF-8

#Install packages
RUN dpkg --add-architecture i386 && \
apt-get update && apt-get install -y \
awscli \
openssh-server \
wget \
tar \
git \
software-properties-common \
python-software-properties \
build-essential \
patch \
libc6-i386 \
lib32stdc++6 \
lib32gcc1 \
lib32ncurses5 \
lib32z1 \
libxml2-dev \
libxslt1-dev \
liblz-dev \
subversion \
zlibc \
zlib1g-dev

#Add repositories and install packeges
RUN \
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java8-installer oracle-java8-set-default && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /var/cache/oracle-jdk8-installer && \
  apt-get autoremove -y && \
  apt-get clean

#Add lets-encrypt certs
ADD isrgrootx1.pem /tmp/isrgrootx1.pem
RUN /usr/bin/keytool -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -import -noprompt -trustcacerts -alias isrgrootx1 -file /tmp/isrgrootx1.pem -storepass changeit
ADD lets-encrypt-x3-cross-signed.pem /tmp/lets-encrypt-x3-cross-signed.pem
RUN /usr/bin/keytool -keystore /usr/lib/jvm/java-8-oracle/jre/lib/security/cacerts -import -noprompt -trustcacerts -alias lets-encrypt-x3-cross-signed -file /tmp/lets-encrypt-x3-cross-signed.pem -storepass changeit

#Config Jenkins user
RUN sed -i 's|session required pam_loginuid.so|session optional pam_loginuid.so|g' /etc/pam.d/sshd
RUN mkdir -p /var/run/sshd
RUN useradd -ms /bin/bash jenkins
RUN echo "jenkins:If[nthXtvgbjy!" | chpasswd
RUN mkdir /home/jenkins/.ssh
ADD authorized_keys /home/jenkins/.ssh/
RUN ssh-keyscan github.com >> /home/jenkins/.ssh/known_hosts

#Set locale
COPY ./default_locale /etc/default/locale
RUN chmod 0755 /etc/default/locale
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ARG CACHE_NUMBER
# Installs Android SDK
ENV ANDROID_SDK_FILENAME android-sdk_r24.4.1-linux.tgz
ENV ANDROID_SDK_URL https://dl.google.com/android/${ANDROID_SDK_FILENAME}
ENV ANDROID_API_LEVELS android-21,android-22,android-23,android-24
ENV ANDROID_BUILD_TOOLS build-tools-21.1.2,build-tools-22.0.1,build-tools-23.0.0,build-tools-23.0.2,build-tools-24.0.0,build-tools-24.0.2,build-tools-24.0.3
ENV GOOGLE_API_LEVELS addon-google_apis-google-21,addon-google_apis-google-22,addon-google_apis-google-23
ENV ANDROID_HOME /home/jenkins/android-sdk-linux
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools
RUN cd /home/jenkins && \
    wget -q ${ANDROID_SDK_URL} && \
    tar -xzf ${ANDROID_SDK_FILENAME} && \
    rm -f ${ANDROID_SDK_FILENAME} && \
    echo y | android update sdk --no-ui -a --filter tools,platform-tools,extra-android-m2repository,extra-android-support,extra-google-google_play_services,extra-google-m2repository,${ANDROID_BUILD_TOOLS},${ANDROID_API_LEVELS},${GOOGLE_API_LEVELS}


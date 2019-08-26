#FROM dockcross/base:latest
FROM ubuntu:16.04
MAINTAINER kinziro

ENV DEFAULT_DOCKCROSS_IMAGE novnc-ssh-container

# apt updateの先を日本ミラーに変更してインストール
RUN sed -i.bak -e 's;http://archive.ubuntu.com;http://jp.archive.ubuntu.com;g' /etc/apt/sources.list \
 && apt-get update \
 && apt-get -y upgrade \
 && apt-get install -y --no-install-recommends software-properties-common \
 && add-apt-repository -y ppa:jonathonf/vim \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
  vim \
  wget \
  git \
  libgl1-mesa-dri \
  menu \
  net-tools \
  openbox \
  python-pip \
  sudo \
  supervisor \
  tint2 \
  x11-xserver-utils \
  x11vnc \
  xinit \
  xserver-xorg-video-dummy \
  xserver-xorg-input-void \
  websockify \
  openssh-server \
  xterm \
  mesa-utils \
  x11-apps \
  && \
  rm -f /usr/share/applications/x11vnc.desktop && \
  apt-get remove -y python-pip && \
  wget https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  pip install supervisor-stdout && \
  apt-get -y clean

RUN echo 'root:P@ssw0rd' | chpasswd

COPY etc/skel/.xinitrc /etc/skel/.xinitrc

RUN useradd -m -s /bin/bash user
RUN echo 'user:P@ssw0rd' | chpasswd
USER user

RUN cp /etc/skel/.xinitrc /home/user/
USER root
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user

RUN git clone https://github.com/kanaka/noVNC.git /opt/noVNC && \
  cd /opt/noVNC && \
  git checkout 6a90803feb124791960e3962e328aa3cfb729aeb && \
  ln -s vnc_auto.html index.html

# noVNC (http server) is on 6080, and the VNC server is on 5900
EXPOSE 6080 5900 22

COPY etc /etc
COPY usr /usr
ENV DISPLAY :0

WORKDIR /root

# sshの設定
# sshサービスの起動とリモートでGPUを使うための設定
RUN ( echo "#!/bin/bash"; \
      echo ""; \
      echo "service ssh start"; \
      echo "tail -f /dev/null"; ) > /root/entrypoint.sh && \
      chmod +x /root/entrypoint.sh && \
      sed -i.bak 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
      echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config && \
      ( echo ""; \
        echo "export PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/opt/conda/bin:$PATH"; \
        echo "export LIBRARY_PATH=/usr/local/cuda/lib64/stubs:"; \
        echo "export LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64"; \
        echo "export DISPLAY=:0"; \
        ) >> /root/.bashrc && \
      mkdir /root/.ssh && chmod 700 /root/.ssh && \
      ( echo "PATH=/usr/local/nvidia/bin:/usr/local/cuda/bin:/opt/conda/bin:$PATH"; \
        echo "LIBRARY_PATH=/usr/local/cuda/lib64/stubs:"; \
        echo "LD_LIBRARY_PATH=/usr/local/nvidia/lib:/usr/local/nvidia/lib64"; \
        echo "DISPLAY=:0"; \
       ) >> /root/.ssh/environment && \
	   cp /root/.bashrc /home/user/.bashrc && \
     mkdir /home/user/.ssh && chmod 700 /home/user/.ssh && \
	   cp /root/.ssh/environment /home/user/.ssh/environment

#CMD ["/root/entrypoint.sh"]
#CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
COPY startup.sh /startup.sh
RUN chmod 744 /startup.sh
CMD ["/startup.sh"]


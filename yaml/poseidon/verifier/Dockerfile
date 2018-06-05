FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04

RUN apt-get update && \
    apt-get install -y cmake git vim software-properties-common && \
    mkdir -p /opt/verifier && \
    cd /opt/verifier && mkdir source && cd source && \
    git clone http://shuangliyue:08224819wdk@gitlab.oceanai.com.cn/verifier/detector.git && \
    cd detector && \
    bash scripts/git-lfs.deb.sh && \
    apt-get update && \
    apt-get install -y git-lfs && \
    git lfs install --skip-smudge && \
    rm .lfsconfig && \
    git lfs pull && \
    # git checkout develop && \
    bash scripts/install_deps.sh && \
    mkdir build && \
    cd build && \
    # RESTFUL
    cmake .. && \
    # ZMQ 
    # cmake -DBUILD_REST=OFF .. && \  
    make -j"$(nproc)"  && \
    cd /opt/verifier && \
    cp /opt/verifier/source/detector/build/bin/verifier . && \
    # ZMQ
    # cp /opt/detector/build/bin/router . && \
    cp -r /opt/verifier/source/detector/model . && \
    cp /opt/verifier/source/detector/build/deps/lib/libcaffe.so.1.0.0 /usr/lib && \
    apt-get -y remove cmake git git-lfs software-properties-common && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    cd /opt/verifier && rm -rf ./source
# ZMQ
# EXPOSE 5559
# RESTFUL
EXPOSE 33388
COPY entrypoint.sh /opt/verifier/
COPY config.json /opt/verifier/
RUN chmod +x /opt/verifier/entrypoint.sh
WORKDIR /opt/verifier/
CMD [ "./entrypoint.sh" ]

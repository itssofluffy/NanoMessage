FROM swiftdocker/swift

RUN apt-get update

RUN apt-get install -y cmake gcc

ENV NANOMSG_VERSION 1.0.0

WORKDIR /src/

ADD https://github.com/nanomsg/nanomsg/archive/$NANOMSG_VERSION.tar.gz nanomsg-$NANOMSG_VERSION.tar.gz

RUN tar -xzf nanomsg-$NANOMSG_VERSION.tar.gz

RUN mkdir -p /src/nanomsg-$NANOMSG_VERSION/build

WORKDIR /src/nanomsg-$NANOMSG_VERSION/build

RUN cmake -DCMAKE_INSTALL_PREFIX=/usr ..

RUN cmake --build . --target install

COPY . /src/nanomessage

WORKDIR /src/nanomessage

RUN swift build

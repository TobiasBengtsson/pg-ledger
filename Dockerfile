# Dockerfile for building a pg-ledger container

FROM postgres:10.3

RUN apt-get update
RUN apt-get -y install build-essential postgresql-server-dev-all postgresql-server-dev-all libpq-dev
RUN cpan TAP::Parser::SourceHandler::pgTAP

RUN mkdir /tmp/pgtap
COPY devdeps/pgtap-a8c7400.tar.gz /tmp/pgtap
RUN tar -zxvf /tmp/pgtap/pgtap-a8c7400.tar.gz -C /tmp/pgtap
RUN rm /tmp/pgtap/pgtap-a8c7400.tar.gz

RUN cd /tmp/pgtap && make && make install

RUN mkdir /tmp/source
COPY . /tmp/source

# Replication package example for ICDE 2021 tutorial
# "Nullius in Verba: Reproducibility for Database Systems Research, Revisited"
# TODO: License
# TODO: Use COPY instead of ADD (unless used with URLs)

# Start off of a long-term maintained base distribution
# TODO: Discuss advantages and disadvantages of using older/newer base versions
FROM ubuntu:18.04

MAINTAINER Wolfgang Mauerer <wolfgang.mauerer@othr.de>
MAINTAINER Stefanie Scherzinger <stefanie.scherzinger@uni-passau.de>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"

# NOTE: Recommended practice: Sort list alphabetically
RUN apt update && apt install -y --no-install-recommends \
	build-essential \
	ca-certificates \
	curl \
	file \
	gawk \
	git \
	joe \
	nano \
	openssh-client \
	sudo \
	tcl-dev \
	time 

RUN useradd -m -G sudo -s /bin/bash repro && echo "repro:repro" | chpasswd
USER repro
WORKDIR /home/repro

# Prepare directory structure
# TODO: Change and implement
## src/             - to store source code implemented by the researchers
## git-repos        - for external git repositories
## build/           - temporary directory for out-of-tree builds
RUN mkdir -p $HOME/git-repos $HOME/src $HOME/build $HOME/bin

# Obtain sqlite sources from a git repo, and check out _one specific, defined state_
# instead of working with a (changing) HEAD
# NOTE: We use an unofficial git mirror of sqlite to avoid working with fossil, which
# as a fairly unusual choice of tool, for the sake of simplicity in this tutorial.
WORKDIR /home/repro/git-repos
# TODO: Temp
RUN git clone https://github.com/lfd/sqlite.git
#RUN git clone git://repo.or.cz/sqlite.git
WORKDIR /home/repro/git-repos/sqlite
# TODO: Can we define the specific commit as a constant on top of the Dockerfile?
# TODO: Temp
#RUN git checkout -b repro a626a139405d9

# Purely technical: Construct manifest file required for building sqlite
# This is an artefact of the way how sqlite is built
RUN git rev-parse --git-dir >/dev/null
RUN echo $(git log -1 --format=format:%H) > manifest.uuid
RUN echo C $(cat manifest.uuid) > manifest
RUN git log -1 --format=format:%ci%n | sed 's/ [-+].*$//;s/ /T/;s/^/D /' >> manifest

# TODO: Integrate research changes (later step)
# NOTE: We deliberately distribute the changes as individual patches outside git
# so reviewers can inspect them without tool interaction. Alternatively, we could
# perform the above clone from a custom git repo that has a branch with all the
# required changes
RUN mkdir -p /home/repro/build/sqlite
WORKDIR /home/repro/build/sqlite

# Configure and build sqlite (NOTE: out-of-tree building is recommended practice
# to avoid inadvertent checkins of binary or other generated artefacts)
RUN ../../git-repos/sqlite/configure --prefix=$HOME
RUN make

# Build an interactive shell
RUN gcc shell.c sqlite3.c -lpthread -ldl -lm -o ~/bin/sqlpolite

# Build the latency measurement tool
RUN gcc $HOME/git-repos/sqlite/src/latency.c -I. -I$HOME/git-repos/sqlite/src sqlite3.o \
                                             -o ~/bin/latency -lm -ldl -lpthread

# Make custom-built binaries in ~/bin binaries available via PATH
ENV PATH $PATH:/home/repro/bin

# Set up TPC-H data and queries for SQLite.
WORKDIR /home/repro/git-repos
RUN git clone --recursive https://github.com/lovasoa/TPCH-sqlite

WORKDIR /home/repro/git-repos/TPCH-sqlite
RUN git checkout -b repro 23e420d8d49a6

COPY patches/TPCH-sqlite.diff .
RUN git apply --ignore-space-change TPCH-sqlite.diff

RUN mkdir -p /home/repro/queries.polite
RUN mkdir -p /home/repro/queries.impolite
COPY queries.polite/* /home/repro/queries.polite/
COPY queries.impolite/* /home/repro/queries.impolite/

# Generate self-contained measurement package that can
# be deployed on the target platform.

WORKDIR /home/repro
COPY scripts/dispatch.sh .
COPY scripts/prepare_data.sh .

RUN tar --transform 's,^,measure/,' -cjhf deliverable.tar.gz queries.*/ git-repos/TPCH-sqlite/ bin/ dispatch.sh prepare_data.sh

WORKDIR /home/repro
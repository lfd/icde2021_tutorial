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

RUN apt update -qq
RUN apt-get install -y gpg-agent
RUN apt install -y --no-install-recommends software-properties-common dirmngr
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
RUN add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran40/"
RUN add-apt-repository ppa:c2d4u.team/c2d4u4.0+

# NOTE: Recommended practice: Sort list alphabetically
RUN apt update && apt install -y --no-install-recommends \
	biber \
	build-essential \
	ca-certificates \
	curl \
	file \
	gawk \
	git \
	joe \
	libpng-dev \
	nano \
	openssh-client \
	r-base \
	r-cran-ggplot2 \
	r-cran-dplyr \
	r-cran-knitr \
	r-cran-stringr \
	r-cran-tinytex \
	r-cran-xtable \
	sudo \
	tcl-dev \
	time \
	texlive-base \
	texlive-bibtex-extra \
	texlive-fonts-recommended \
	texlive-generic-extra \
	texlive-latex-extra \
	texlive-publishers

## We need to manually build the R tikzDevice package
RUN Rscript -e 'install.packages("tikzDevice", repos="https://cloud.r-project.org")'

RUN useradd -m -G sudo -s /bin/bash repro && echo "repro:repro" | chpasswd
USER repro
WORKDIR /home/repro

# Prepare directory structure
## git-repos/       - for external git repositories
## build/           - temporary directory for out-of-tree builds
## bin/             - for generated binary executables
RUN mkdir -p $HOME/git-repos $HOME/build $HOME/bin


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
#ENV SQLITE_HEAD="a626a139405d9"
#RUN git checkout -b repro $SQLITE_HEAD

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
RUN gcc shell.c sqlite3.c -lpthread -ldl -lm -o ~/bin/sqpolite

# Build the latency measurement tool
RUN gcc $HOME/git-repos/sqlite/src/latency.c -I. -I$HOME/git-repos/sqlite/src sqlite3.o \
                                             -o ~/bin/latency -lm -ldl -lpthread
RUN gcc -I. -fPIC -shared $HOME/git-repos/sqlite/ext/please.c -o please.so

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
WORKDIR /home/repro/git-repos/TPCH-sqlite
RUN git archive --format=tar --prefix=TPCH-sqlite/ HEAD > /tmp/tpch.tar

WORKDIR /home/repro
RUN tar xf /tmp/tpch.tar
COPY scripts/dispatch.sh .
COPY scripts/doall.sh .
COPY scripts/prepare_data.sh .

RUN tar --transform 's,^,measure/,' -cjhf deliverable.tar.bz2 queries.*/ TPCH-sqlite/ bin/ dispatch.sh prepare_data.sh

WORKDIR /home/repro

## Clone the associated paper source so contributors can work on it from within the
## container (and also ensure buildability in years to come)
RUN git clone https://github.com/lfd/icde2021_demo_paper.git paper

# Replication Package for "Nullius in Verba" @ ICDE 2021
This site provides the replication package for the ICDE 2021
tutorial *Nullius in Verba*. It does not contain (real) scientific
results as such, but is intended to serve as a blueprint on
how to structure replication pacakges based on an artificial
research effort that addresses the important question of
*how to make interactions with database engined more polite*.

*NOTE:* An archival version of the pre-built docker image, together
with a copy of the git repository and the measured data, are available at
the DOI [10.5281/zenodo.4730023](https://doi.org/10.5281/zenodo.4730023).
Using this version does not require any external ressources. The instructions
below are for re-building the image from scratch, and do rely on the
availability of external ressources on the internet. They are not supposed
to work in the long run.

## Building the Docker image
- Clone the repository
  > git clone https://github.com/lfd/icde2021_tutorial
- Build the Docker image from scratch
  > cd icde2021_tutorial

  > docker build -t icde2021 .

- Run the measurements as described below. 

## Performing measurements on external targets
- To execute a measurement sequence on an external target host (e.g., in the cloud),
  copy `measure.tar.bz2` from the docker container to target, and untar the content: 

  > docker run --rm --entrypoint cat icde2021  /home/repro/deliverable.tar.bz2 > /path/to/deliverable.tar.bz2 

  > scp /path/to/deliverable.tar.bz2 host.domain.tld: 

  > ssh host.domain.tld 

  > host> tar xjf deliverable.tar.bz2 

  > host> cd measure

- The remaining steps are identical to the steps performed in the container.
  Once the measurement is complete, copy the folders `res_*` populated by the
  measurement script into folder `/home/repro/results` in the container. Then,
  proceed with data visualisation and paper generation as decribed below.


## Performing measurements in the Docker container

- For the sake of the tutorial, the measurement can be performed directly inside the container
(this is usually not a recommended scenario for research measurements). Access
the container interactively with

  > docker run -it icde2021

  The following steps are identical for container- and host based runs.

  The measurement is based on the TPC-H dataset, which is produced by a
  deterministic generator included in the tarball. Use the following
  step to bild the generator from source code, and generate two
  sample datasets:

  > ./prepare_data.sh

- Then, execute the measurements proper with the `doall.sh` script. A label
  can be chosen to uniquely identify the measurements. For our example scenario
  in the container, we choose `docker`:

  > ./doall.sh docker

- In real scenarios, `doall.sh` (and probably also `dispatch.sh`) would need to be
  adapted to control which measurement is performed.
- Finally, we need to visualise the results and generate the paper.
  While the paper is, as usual, written in LaTeX, we use knitr to
  produce plots from the data, and integrate them into the LaTeX sources.

  > Rscript -e "require ('knitr'); knit ('paper.Rnw')"

  > pdflatex paper; biber paper; pdflatex paper; pdflatex paper

  (note that we did deliberately not use a build system like latexmk
  to avoid hiding the actual call sequence; knitr and the pdf build
  can be transparently integrated this way in production environments)

## Inspecting changes to SQLite
To perform our exemplary research, we had to modify SQLite in a number of ways.
The repository at https://github.com/lfd/sqlite contains two branches:

- A clean, manually tended history in branch `master` (the default branch),
  which contains properly structured commits including explanations on why
  changes were performed, and includes a trail of responsibility using
  developer certificates of origin (Signed-off-by etc. lines).

- Branch `devel_process` keeps the history as it arose during development,
  including partial and incomplete commits. We show during the tutorial
  how to re-organise and clean up such a series to make it readable by
  others years or decades after research has been performed, or when
  interaction with the original authors is not possible anymore.

## Pre-Built image and measured datasets
For convenience, the DOI archived artefacts are also available at
non-archival locations. The pre-built Docker image (including a stable
copy of all required sources) is available at
https://cdn.lfdr.de/icde2021/icde2021-docker.tar.bz2 (0.6 GiB
compressed/1.9 GiB uncompressed)

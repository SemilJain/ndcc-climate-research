#!/bin/bash

# Define the log file path
LOG_FILE="/local/repository/script_log.txt"

# Function to log a message
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

exec > >(tee -a "$LOG_FILE") 2>&1

log "Starting script..."

cd

export PROJ_DIR=`pwd`
export PROJ_VERSION="4.1.0"
DATASET=$(geni-get manifest | xmllint --xpath "string(//*[local-name()='data_item'])" -)
export CASE_DIR=${PROJ_DIR}/${DATASET}

log "Running Domain"

docker run --rm -it -e LOCAL_USER_ID=`id -u $USER` \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/sandy_20121027:/home/scripts/case \
-v /mydata/data/shapefiles:/home/data/shapefiles \
-v ${CASE_DIR}/pythonprd:/home/pythonprd \
--name run-sandy-python dtcenter/python:${PROJ_VERSION} \
/home/scripts/common/run_python_domain.ksh

log "Running WPS"

docker run --rm -it -e LOCAL_USER_ID=`id -u $USER` \
-v /mydata/data/WPS_GEOG:/data/WPS_GEOG \
-v /mydata/data:/data -v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/sandy_20121027:/home/scripts/case \
-v ${CASE_DIR}/wpsprd:/home/wpsprd --name run-sandy-wps dtcenter/wps_wrf:${PROJ_VERSION} \
/home/scripts/common/run_wps.ksh

log "Running Real"

docker run --rm -it -e LOCAL_USER_ID=`id -u $USER` \
-v /mydata/data:/data -v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/sandy_20121027:/home/scripts/case \
-v ${CASE_DIR}/wpsprd:/home/wpsprd \
-v ${CASE_DIR}/wrfprd:/home/wrfprd --name run-sandy-real dtcenter/wps_wrf:${PROJ_VERSION} \
/home/scripts/common/run_real.ksh

log "Running GSI"

docker run --rm -it -e LOCAL_USER_ID=`id -u $USER` \
-v /mydata/data:/data \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/sandy_20121027:/home/scripts/case \
-v ${CASE_DIR}/gsiprd:/home/gsiprd \
-v ${CASE_DIR}/wrfprd:/home/wrfprd --name run-sandy-gsi dtcenter/gsi:${PROJ_VERSION} /home/scripts/common/run_gsi.ksh

log "Running WRF"

docker run --rm -it -e LOCAL_USER_ID=`id -u $USER` \
 -v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
 -v ${PROJ_DIR}/container-dtc-nwp/components/scripts/sandy_20121027:/home/scripts/case \
 -v ${CASE_DIR}/wpsprd:/home/wpsprd -v ${CASE_DIR}/gsiprd:/home/gsiprd -v ${CASE_DIR}/wrfprd:/home/wrfprd \
 --name run-sandy-wrf dtcenter/wps_wrf:${PROJ_VERSION} /home/scripts/common/run_wrf.ksh

log "Running UPP"

docker run --rm -it -e LOCAL_USER_ID=`id -u $USER` \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/sandy_20121027:/home/scripts/case \
-v ${CASE_DIR}/wrfprd:/home/wrfprd -v ${CASE_DIR}/postprd:/home/postprd \
--name run-sandy-upp dtcenter/upp:${PROJ_VERSION} /home/scripts/common/run_upp.ksh

log "Running Python Graphics"

docker run --rm -it -e LOCAL_USER_ID=`id -u $USER` \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/sandy_20121027:/home/scripts/case \
-v /mydata/data/shapefiles:/home/data/shapefiles \
-v ${CASE_DIR}/postprd:/home/postprd -v ${CASE_DIR}/pythonprd:/home/pythonprd \
--name run-sandy-python dtcenter/python:${PROJ_VERSION} /home/scripts/common/run_python.ksh

log "Running MET"

docker run --rm -it -e LOCAL_USER_ID=`id -u $USER` \
-v /mydata/data:/data \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/sandy_20121027:/home/scripts/case \
-v ${CASE_DIR}/postprd:/home/postprd -v ${CASE_DIR}/metprd:/home/metprd \
--name run-sandy-met dtcenter/nwp-container-met:${PROJ_VERSION} /home/scripts/common/run_met.ksh

log "Seeting up MetViewer"

cd ${PROJ_DIR}/container-dtc-nwp/components/metviewer
sudo chown -R 999:999 ${CASE_DIR}/metviewer/mysql
docker-compose up -d

sleep 90

docker exec -it metviewer /scripts/common/metv_load_all.ksh mv_sandy

log "Script Completed"

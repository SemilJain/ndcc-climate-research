#!/bin/bash

if [[ $# -ne 8 ]]; then
  echo "Usage: $0 -> Must specify initialization time (YYYYMMDDHH), maximum forecast hour, and forecast hour increment."
  exit
fi

INIT_YMDH=$1
MAX_FHR=$2
FHR_INC=$3
DATASET=$4
start_date=$5
end_date=$6
lat=$7
lon=$8

cd /users/geniuser
export PROJ_DIR=$(pwd)
export PROJ_VERSION="4.1.0"
export CASE_DIR=${PROJ_DIR}/${DATASET}
uid=$(id -u $USER)
gid=$(id -g $USER)
sudo chown -R $uid:$gid ${PROJ_DIR}
mkdir -p ${CASE_DIR}
cd ${CASE_DIR}
mkdir -p wpsprd wrfprd gsiprd postprd pythonprd metprd metviewer/mysql data
touch logs.txt

# Define the log file path
LOG_FILE="${CASE_DIR}/logs.txt"

# Function to log a message
log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

exec > >(tee -a "$LOG_FILE") 2>&1

log "Starting process Date script..."
log "Input: $INIT_YMDH, $MAX_FHR, $FHR_INC, $DATASET, $start_date, $end_date, $lat, $lon"
# export PROJ_DIR=$(pwd)
# export PROJ_VERSION="4.1.0"
# # DATASET=$(geni-get manifest | xmllint --xpath "string(//*[local-name()='data_item'])" -)
# export CASE_DIR=${PROJ_DIR}/${DATASET}
# mkdir -p ${CASE_DIR}
# cd ${CASE_DIR}
# mkdir -p wpsprd wrfprd gsiprd postprd pythonprd metprd metviewer/mysql

log "Downloading data..."
cd ${CASE_DIR}/data
cp -r /mydata/data/* ./
mkdir ${CASE_DIR}/data/model_data/${DATASET}
cd ${CASE_DIR}/data/model_data/${DATASET}

bash ${PROJ_DIR}/pull_nomad_gfs.ksh ${INIT_YMDH} ${MAX_FHR} ${FHR_INC}

log "Data download complete"

cd ${PROJ_DIR}
# uid=$(id -u $USER)
# gid=$(id -g $USER)
# sudo chown -R $uid:$gid ${PROJ_DIR}
# # sudo chown -R 9999:9999 ${PROJ_DIR}

log "Modifying files..."

cp -r ${PROJ_DIR}/scripts_template ${CASE_DIR}/scripts_input
cd ${CASE_DIR}/scripts_input

bash sed_script.sh 8 "export case_name=${DATASET}" "set_env.ksh"
bash sed_script.sh 13 "export PREPBUFR=/data/obs_data/prepbufr/2021060106/ndas.t06z.prepbufr.tm06.nr" "set_env.ksh"
bash sed_script.sh 25 "export startdate_d01=${INIT_YMDH}" "set_env.ksh"
bash sed_script.sh 32 "export init_time=${INIT_YMDH}" "set_env.ksh"
bash sed_script.sh 27 "export lastfhr_d01=${MAX_FHR}" "set_env.ksh"
bash sed_script.sh 34 "export fhr_end=${MAX_FHR}" "set_env.ksh"
bash sed_script.sh 39 "export START_TIME=${INIT_YMDH}" "set_env.ksh"

bash sed_script.sh 4 " start_date = '${start_date}','2006-08-16_12:00:00'," "namelist.wps"
bash sed_script.sh 5 " end_date   = '${end_date}','2006-08-16_12:00:00'," "namelist.wps"
# bash sed_script.sh 15 " e_we              = 25, 112," "namelist.wps"
# bash sed_script.sh 16 " e_sn              = 25, 97," "namelist.wps"
bash sed_script.sh 21 " ref_lat   =  ${lat}." "namelist.wps"
bash sed_script.sh 22 " ref_lon   = ${lon}." "namelist.wps"
bash sed_script.sh 23 " truelat1  =  ${lat}," "namelist.wps"
bash sed_script.sh 24 " truelat2  =  ${lat}," "namelist.wps"
bash sed_script.sh 24 " stand_lon = ${lon}," "namelist.wps"

bash sed_script.sh 6 " start_year                          = $(echo "$start_date" | cut -d'-' -f1), 2000, 2000," "namelist.input"
bash sed_script.sh 7 " start_month                         = $(echo "$start_date" | cut -d'-' -f2),   01,   01," "namelist.input"
bash sed_script.sh 8 " start_day                           = $(echo "$start_date" | cut -d'_' -f1 | cut -d'-' -f3),   24,   24," "namelist.input"
bash sed_script.sh 12 " end_year                          = $(echo "$end_date" | cut -d'-' -f1), 2000, 2000," "namelist.input"
bash sed_script.sh 13 " end_month                         = $(echo "$end_date" | cut -d'-' -f2),   01,   01," "namelist.input"
bash sed_script.sh 14 " end_day                           = $(echo "$end_date" | cut -d'_' -f1 | cut -d'-' -f3),   25,   25," "namelist.input"

bash sed_script.sh 5 "        <database>mv_${DATASET}</database>" "metviewer/plot_WIND_Z10.xml"


log "Variables set: $PROJ_DIR, $PROJ_VERSION, $DATASET, $CASE_DIR, $USER, $uid, $gid"

log "Running Domain"

sudo docker run --rm -e LOCAL_USER_ID=`id -u $USER` \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${CASE_DIR}/scripts_input:/home/scripts/case \
-v ${CASE_DIR}/data/shapefiles:/home/data/shapefiles \
-v ${CASE_DIR}/pythonprd:/home/pythonprd \
--name run-${DATASET}-python dtcenter/python:${PROJ_VERSION} \
/home/scripts/common/run_python_domain.ksh

log "Running WPS"

sudo docker run --rm \
-v ${CASE_DIR}/data/WPS_GEOG:/data/WPS_GEOG -e LOCAL_USER_ID=`id -u $USER` \
-v ${CASE_DIR}/data:/data -v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${CASE_DIR}/scripts_input:/home/scripts/case \
-v ${CASE_DIR}/wpsprd:/home/wpsprd --name run-${DATASET}-wps dtcenter/wps_wrf:${PROJ_VERSION} \
/home/scripts/common/run_wps.ksh

log "Running Real"

sudo docker run --rm -e LOCAL_USER_ID=`id -u $USER` \
-v ${CASE_DIR}/data:/data -v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${CASE_DIR}/scripts_input:/home/scripts/case \
-v ${CASE_DIR}/wpsprd:/home/wpsprd \
-v ${CASE_DIR}/wrfprd:/home/wrfprd --name run-${DATASET}-real dtcenter/wps_wrf:${PROJ_VERSION} \
/home/scripts/common/run_real.ksh

log "Running GSI"

sudo docker run --rm -e LOCAL_USER_ID=`id -u $USER` \
-v ${CASE_DIR}/data:/data \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${CASE_DIR}/scripts_input:/home/scripts/case \
-v ${CASE_DIR}/gsiprd:/home/gsiprd \
-v ${CASE_DIR}/wrfprd:/home/wrfprd --name run-${DATASET}-gsi dtcenter/gsi:${PROJ_VERSION} /home/scripts/common/run_gsi.ksh

log "Running WRF"

sudo docker run --rm -e LOCAL_USER_ID=`id -u $USER` \
 -v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
 -v ${CASE_DIR}/scripts_input:/home/scripts/case \
 -v ${CASE_DIR}/wpsprd:/home/wpsprd -v ${CASE_DIR}/gsiprd:/home/gsiprd -v ${CASE_DIR}/wrfprd:/home/wrfprd \
 --name run-${DATASET}-wrf dtcenter/wps_wrf:${PROJ_VERSION} /home/scripts/common/run_wrf.ksh

log "Running UPP"

sudo docker run --rm -e LOCAL_USER_ID=`id -u $USER` \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${CASE_DIR}/scripts_input:/home/scripts/case \
-v ${CASE_DIR}/wrfprd:/home/wrfprd -v ${CASE_DIR}/postprd:/home/postprd \
--name run-${DATASET}-upp dtcenter/upp:${PROJ_VERSION} /home/scripts/common/run_upp.ksh

log "Running Python Graphics"

sudo docker run --rm -e LOCAL_USER_ID=`id -u $USER` \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${CASE_DIR}/scripts_input:/home/scripts/case \
-v ${CASE_DIR}/data/shapefiles:/home/data/shapefiles \
-v ${CASE_DIR}/postprd:/home/postprd -v ${CASE_DIR}/pythonprd:/home/pythonprd \
--name run-${DATASET}-python dtcenter/python:${PROJ_VERSION} /home/scripts/common/run_python.ksh

log "Running MET"

sudo docker run --rm -e LOCAL_USER_ID=`id -u $USER` \
-v ${CASE_DIR}/data:/data \
-v ${PROJ_DIR}/container-dtc-nwp/components/scripts/common:/home/scripts/common \
-v ${CASE_DIR}/scripts_input:/home/scripts/case \
-v ${CASE_DIR}/postprd:/home/postprd -v ${CASE_DIR}/metprd:/home/metprd \
--name run-${DATASET}-met dtcenter/nwp-container-met:${PROJ_VERSION} /home/scripts/common/run_met.ksh

log "Seeting up MetViewer"

cd ${PROJ_DIR}/container-dtc-nwp/components/metviewer
sudo chown -R 999:999 ${CASE_DIR}/metviewer/mysql
sudo docker-compose up -d

sleep 60

sudo docker exec metviewer /scripts/common/metv_load_all.ksh mv_${DATASET}

log "Script Completed"

#!/bin/bash
# Script para ejecutar una compilacion completa del entorno
# para SuriLib

clear 2>/dev/null || cls 

export DO_IMAGE_FORMATS=true
export DO_BASE=true
export DO_HDF5=true
export DO_KML=true
export DO_GDAL=true

time (\
${SHELL} ./build-common.sh "$@" \
&& ${SHELL} ./build-sqlite3.sh "$@" \
&& ${SHELL} ./build-openjpeg.sh "$@" \
&& ${SHELL} ./build-wx.sh "$@"  \
&& ${SHELL} ./build-gdal-huayra-x86_64.sh "$@"  \
&& ${SHELL} ./build-others.sh "$@" \
)

unset DO_BASE
unset DO_HDF5
unset DO_GDAL


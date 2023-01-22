#!/bin/sh

# Variables globales
source build-func.sh

# Funciones de inicializacion que "initialize" espera encontrar (VA SI O SI EN TODOS LOS SCRIPTS)
init_debug() {
   echo -n ""
}

init_release() {
  echo -n ""
}

init_windows() {
   echo -n ""
}

init_linux() {
   echo -n ""
}

# Inicializacion
initialize $* || die

# Opciones de configuracion para el script configure
OPENJPEG_CONFIGURE_FLAGS="-DCMAKE_INSTALL_PREFIX:PATH=$PREFIX"

# Opciones de configuracion para modo RELEASE o DEBUG
OPENJPEG_CPP_FLAGS="-DNDEBUG"

export CPPFLAGS_BU="${CPPFLAGS}"
export CPPFLAGS="${OPENJPEG_CPP_FLAGS}"

OPENJPEG_SRCDIR=""

extract "${SRCDIR}/openjpeg-2.0.1.tar.gz" OPENJPEG_SRCDIR || die

# Directorio donde se descomprime el codigo
build_cmake "${OPENJPEG_SRCDIR}" "${OPENJPEG_CONFIGURE_FLAGS}" || die

# Generacion de archivo .ENV (VA SI O SI EN TODOS LOS SCRIPTS)
echo "Version: $ENVIRONMENT_VERSION" >> "${OPENJPEG_SRCDIR}/${OPENJPEG_SRCDIR}.env"

install_makepackage "${OPENJPEG_SRCDIR}" "" "" || die

# El script deja los binarios generados en la carpeta bin (VA SI O SI EN TODOS LOS SCRIPTS)
move_packages

# Algo de limpieza
export CPPFLAGS="${CPPFLAGS_BU}"

# (VA SI O SI EN TODOS LOS SCRIPTS)
reset_flags

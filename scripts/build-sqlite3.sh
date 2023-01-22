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
SQLITE3_CONFIGURE_FLAGS="--enable-static=no --enable-shared=yes --enable-readline=no --prefix=$PREFIX"

# Opciones de configuracion para modo RELEASE o DEBUG
SQLITE3_CPP_FLAGS="-DNDEBUG"

export CPPFLAGS_BU="${CPPFLAGS}"
export CPPFLAGS="${SQLITE3_CPP_FLAGS}"

SQLITE3_SRCDIR=""

extract "${SRCDIR}/sqlite-autoconf-3080200.tar.gz" SQLITE3_SRCDIR || die

# Directorio donde se descomprime el codigo
build "${SQLITE3_SRCDIR}" "${SQLITE3_CONFIGURE_FLAGS}" || die

# Generacion de archivo .ENV (VA SI O SI EN TODOS LOS SCRIPTS)
echo "Version: $ENVIRONMENT_VERSION" >> "${SQLITE3_SRCDIR}/${SQLITE3_SRCDIR}.env"

install_makepackage "${SQLITE3_SRCDIR}" "" "" || die

# El script deja los binarios generados en la carpeta bin (VA SI O SI EN TODOS LOS SCRIPTS)
move_packages

# Algo de limpieza
export CPPFLAGS="${CPPFLAGS_BU}"

# (VA SI O SI EN TODOS LOS SCRIPTS)
reset_flags

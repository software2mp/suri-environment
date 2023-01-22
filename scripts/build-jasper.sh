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
JASPER_CONFIGURE_FLAGS="--enable-shared --disable-static --prefix=$PREFIX"

# Opciones de configuracion para modo RELEASE o DEBUG
JASPER_CPP_FLAGS="-DNDEBUG"

export CPPFLAGS_BU="${CPPFLAGS}"
export CPPFLAGS="${JASPER_CPP_FLAGS}"

JASPER_SRCDIR=""

extract "${SRCDIR}/jasper-1.900.1.uuid.tar.gz" JASPER_SRCDIR || die

# Directorio donde se descomprime el codigo
build "${JASPER_SRCDIR}" "${JASPER_CONFIGURE_FLAGS}" || die

# Generacion de archivo .ENV (VA SI O SI EN TODOS LOS SCRIPTS)
echo "Version: $ENVIRONMENT_VERSION" >> "${JASPER_SRCDIR}/${JASPER_SRCDIR}.env"

install_makepackage "${JASPER_SRCDIR}" "" "" || die

# El script deja los binarios generados en la carpeta bin (VA SI O SI EN TODOS LOS SCRIPTS)
move_packages

# Algo de limpieza
export CPPFLAGS="${CPPFLAGS_BU}"

# (VA SI O SI EN TODOS LOS SCRIPTS)
reset_flags

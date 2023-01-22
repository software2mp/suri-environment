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
	CMAKE_GENERATOR="MSYS Makefiles"
}

init_linux() {
	echo -n ""
	CMAKE_GENERATOR="Unix Makefiles"
}

# Inicializacion
initialize $* || die

extract "${SRCDIR}/hdf-4.2.10.tar.gz" OUTDIR || die

#Genero directorio donde voy a correr cmake y luego ejecuto cmake con variables modificadas
mkdir -p $OUTDIR/$OUTDIR

# Corrige el nombre de la biblioteca y agrega dependencia con winsock2.
apply_patch "hdf4-cmakelists.patch" "-d $OUTDIR" || die
# Agrega el prefijo lib a las bibliotecas para que gdal las pueda detectar.
# Comentado porque se utiliza un link
# apply_patch "hdf4-lib-prefix.patch" "-d $OUTDIR" || die

cd $OUTDIR/$OUTDIR

echo "Version: $ENVIRONMENT_VERSION" > "$OUTDIR.env"
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
echo cmake ..  -G \"${CMAKE_GENERATOR}\" ${CMAKE_COMMON_FLAGS} -DCMAKE_C_STANDARD_LIBRARIES=\"${CMAKE_COMMON_C_STANDARD_LIBRARIES}\" -DCMAKE_CXX_STANDARD_LIBRARIES="${CMAKE_CXX_STANDARD_LIBRARIES}" -DCMAKE_INSTALL_PREFIX=${PREFIX} -DBUILD_SHARED_LIBS=yes -DHDF4_BUILD_FORTRAN=no -DHDF4_BUILD_XDR_LIB=yes
>> "$OUTDIR.env"
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
cmake ..  -G "${CMAKE_GENERATOR}" ${CMAKE_COMMON_FLAGS} -DCMAKE_CXX_STANDARD_LIBRARIES="${CMAKE_CXX_STANDARD_LIBRARIES}" -DCMAKE_C_STANDARD_LIBRARIES="${CMAKE_COMMON_C_STANDARD_LIBRARIES}" -DCMAKE_INSTALL_PREFIX=${PREFIX} -DBUILD_SHARED_LIBS=yes -DHDF4_BUILD_FORTRAN=no -DHDF4_BUILD_XDR_LIB=yes 2>&1 >> "$OUTDIR.env" || die
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
cat CMakeCache.txt >> "$OUTDIR.env"
cd ..
build "$OUTDIR" "no-configure" "" || die

install_makepackage "$OUTDIR" "" "" || die

# Generacion de archivo .ENV (VA SI O SI EN TODOS LOS SCRIPTS)
echo "Version: $ENVIRONMENT_VERSION" >> "${OUTDIR}/${OUTDIR}.env"

# El script deja los binarios generados en la carpeta bin (VA SI O SI EN TODOS LOS SCRIPTS)
move_packages

if [ $WINDOWS ] ; then
	ln -s ${PREFIX}/lib/df.lib ${PREFIX}/lib/libdf.lib
	ln -s ${PREFIX}/lib/mfhdf.lib ${PREFIX}/lib/libmfhdf.lib
	ln -s ${PREFIX}/lib/xdr.lib ${PREFIX}/lib/libxdr.lib
fi

# Algo de limpieza
export CPPFLAGS="${CPPFLAGS_BU}"

# (VA SI O SI EN TODOS LOS SCRIPTS)
reset_flags

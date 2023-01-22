#!/bin/sh
#

source build-func.sh

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

initialize $* || die

CMAKE_COMMON_FLAGS="${CMAKE_COMMON_FLAGS} -DBUILD_SHARED_LIBS=\"True\""

extract "${SRCDIR}/gtest-1.6.0.zip" OUTDIR || die

#Genero directorio donde voy a correr cmake y luego ejecuto cmake con variables modificadas
mkdir -p $OUTDIR/$OUTDIR
cd $OUTDIR/$OUTDIR

postmessage "Configurando con CMAKE"
# Se carga variable de entorno que indica la version con que generado la biblioteca
# Se reemplace espacios, guiones y puntos por underscore para que las definiciones de variables sean validas
SUFFIX=""
if [ ! -z $PLATFORMID ] ; then
	SUFFIX="_${PLATFORMID}"
fi

echo "export $(echo "${OUTDIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_ENVIRONMENT_VERSION${SUFFIX}='${ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
echo "Version: $ENVIRONMENT_VERSION" > "$OUTDIR.env"
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
echo cmake ..  -G \"${CMAKE_GENERATOR}\" ${CMAKE_COMMON_FLAGS} -DCMAKE_C_STANDARD_LIBRARIES=\"${CMAKE_COMMON_C_STANDARD_LIBRARIES}\" >> "$OUTDIR.env"
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
cmake ..  -G "${CMAKE_GENERATOR}" ${CMAKE_COMMON_FLAGS} -DCMAKE_C_STANDARD_LIBRARIES="${CMAKE_COMMON_C_STANDARD_LIBRARIES}" 2>&1 >> "$OUTDIR.env" || die
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
cat CMakeCache.txt >> "$OUTDIR.env"

# genero e installo la aplicacion, hago cd .. para que el archivo generado tenga nombre correcto
cd ..
build "$OUTDIR" "no-configure" "" || die
# Agrego un target install
echo -e "\ninstall:" >> $OUTDIR/Makefile || die
echo -e "\t-mkdir -p ${PREFIX}/include" >> $OUTDIR/Makefile || die
echo -e "\t-mkdir -p ${PREFIX}/bin" >> $OUTDIR/Makefile || die
echo -e "\t-mkdir -p ${PREFIX}/lib" >> $OUTDIR/Makefile || die
echo -e "\t-cp -Rv ../include ${PREFIX}/" >> $OUTDIR/Makefile || die
echo -e "\t-test \`find ../ -name \"libg*.dll\" | wc -c\` -ne 0 && cp -v ../$OUTDIR/libg*.dll ${PREFIX}/bin" >> $OUTDIR/Makefile || die
echo -e "\t-test \`find ../ -name \"libg*.so*\" | wc -c\` -ne 0 && cp -v ../$OUTDIR/libg*.so* ${PREFIX}/lib" >> $OUTDIR/Makefile || die
echo -e "\t-test \`find ../ -name \"libg*.a\" | wc -c\` -ne 0 && cp -v ../$OUTDIR/libg*.a ${PREFIX}/lib" >> $OUTDIR/Makefile || die

install_makepackage "$OUTDIR" "" "" || die

# retorno a carpeta original
cd ..

extract "${SRCDIR}/gmock-1.6.0.zip" OUTDIR || die

#Genero directorio donde voy a correr cmake y luego ejecuto cmake con variables modificadas
mkdir -p $OUTDIR/$OUTDIR
cd $OUTDIR/$OUTDIR

postmessage "Configurando con CMAKE"

# Se carga variable de entorno que indica la version con que generado la biblioteca
# Se reemplace espacios, guiones y puntos por underscore para que las definiciones de variables sean validas
SUFFIX=""
if [ ! -z $PLATFORMID ] ; then
	SUFFIX="_${PLATFORMID}"
fi
	
echo "export $(echo "${OUTDIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_ENVIRONMENT_VERSION${SUFFIX}='${ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
echo "Version: $ENVIRONMENT_VERSION" > "$OUTDIR.env"
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
echo cmake ..  -G \"${CMAKE_GENERATOR}\" ${CMAKE_COMMON_FLAGS} -DCMAKE_C_STANDARD_LIBRARIES=\"${CMAKE_COMMON_C_STANDARD_LIBRARIES}\" >> "$OUTDIR.env"
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
cmake ..  -G "${CMAKE_GENERATOR}" ${CMAKE_COMMON_FLAGS} -DCMAKE_C_STANDARD_LIBRARIES="${CMAKE_COMMON_C_STANDARD_LIBRARIES}" 2>&1 >> "$OUTDIR.env" || die
echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
cat CMakeCache.txt >> "$OUTDIR.env"

# genero e installo la aplicacion, hago cd .. para que el archivo generado tenga nombre correcto
cd ..
build "$OUTDIR" "no-configure" "" || die
# Agrego un target install
echo -e "\ninstall:" >> $OUTDIR/Makefile || die
echo -e "\t-mkdir -p ${PREFIX}/include" >> $OUTDIR/Makefile || die
echo -e "\t-mkdir -p ${PREFIX}/bin" >> $OUTDIR/Makefile || die
echo -e "\t-mkdir -p ${PREFIX}/lib" >> $OUTDIR/Makefile || die
echo -e "\t-cp -Rv ../include ${PREFIX}/" >> $OUTDIR/Makefile || die
echo -e "\t-test \`find ../ -name \"libg*.dll\" | wc -c\` -ne 0 && cp -v ../$OUTDIR/libg*.dll ${PREFIX}/bin" >> $OUTDIR/Makefile || die
echo -e "\t-test \`find ../ -name \"libg*.so*\" | wc -c\` -ne 0 && cp -v ../$OUTDIR/libg*.so* ${PREFIX}/lib" >> $OUTDIR/Makefile || die
echo -e "\t-test \`find ../ -name \"libg*.a\" | wc -c\` -ne 0 && cp -v ../$OUTDIR/libg*.a ${PREFIX}/lib" >> $OUTDIR/Makefile || die

install_makepackage "$OUTDIR" "" "" || die

# retorno a carpeta original
cd ..

#El script deja los binarios generados en la carpeta bin 
move_packages

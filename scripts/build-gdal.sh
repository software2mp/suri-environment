#!/bin/sh
#

source build-func.sh

init_debug() {
	COMMON_FLAGS="$COMMON_FLAGS --enable-debug"
	HDF_COMMON_FLAGS="$HDF_COMMON_FLAGS --disable-production"
}


init_release() {
	COMMON_FLAGS="$COMMON_FLAGS --disable-debug"
	HDF_COMMON_FLAGS="$HDF_COMMON_FLAGS --enable-production"
	ZIPPREFIX="/usr/lib"
	JPEGPREFIX="/usr/lib"
	TIFFPREFIX="/usr/lib"
	PNGPREFIX="/usr/lib"
	GIFPREFIX="yes"
}

init_windows() {
	# en windows, si compilo con soporte para estas bibliotecas, no puedo
	# tener .dlls => Tengo que habilitar la compilacion estatica
#	if [ $DO_HDF5 -o $DO_HDF4 -o $DO_NETCDF -o $DO_JASPER ] ; then
#		STATIC="--enable-static"
#	fi
	NO_UNDEFINED="-Wl,-no-undefined"
	HDF4_LIBS="-L$PREFIX/lib -lz -lws2_32 -ljpeg"
	GDAL_LIBS="-L$PREFIX/lib -L$PREFIX/bin -lz -lws2_32"
	GEOTIFF_FLAGS="-I$PREFIX/include"
	HDF5_FLAGS="-I$PREFIX/include"
	HDF5_LIBS="-L$PREFIX/lib -lz -lws2_32"
	ZIPPREFIX=$PREFIX
	JPEGPREFIX=$PREFIX
	TIFFPREFIX=$PREFIX
	PNGPREFIX=$PREFIX
	GIFPREFIX="yes"
	CMAKE_COMMON_SHARED_LINKER_FLAGS="-L${PREFIX}/bin -lz -ltiff-3 -lgeotiff-2 -lpng12-0 -lhdf5 -ljpeg-8 -lgeos_c-1 -lkmlbase -lkmlconvenience -lkmldom -lkmlengine -lkmlregionator -lexpat-1 -lcurl-4 -lws2_32"
	CMAKE_COMMON_CXX_STANDARD_LIBRAIRES="-lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32 -lws2_32"
	CMAKE_COMMON_C_STANDARD_LIBRARIES="${CMAKE_COMMON_CXX_STANDARD_LIBRAIRES}"
	CMAKE_GENERATOR="MSYS Makefiles"
	# explicacion de -Wl,-lbfd : http://mingw.5.n7.nabble.com/A-question-about-linking-td6455.html
	GDAL_COMPILER_FLAGS="-I${PREFIX}/include/kml/third_party/boost_1_34_1 -Wl,-lbfd"
	KML_CMAKE_SHARED_LINKER_FLAGS="-L${PREFIX}/bin -lz -lexpat-1 -Wl,--export-all-symbols"
	GDAL_APP_DEPENDENCIES=""
	GDAL_CONFIGURE_FLAGS="--with-expat=$PREFIX --with-libkml=$PREFIX  --with-geos=$PREFIX/bin/geos-config --with-curl=$PREFIX --with-hdf5=$PREFIX/bin --with-hdf4=$PREFIX --with-jpeg=$PREFIX --with-geotiff=$PREFIX --with-libtiff=$PREFIX --with-png=$PREFIX  --with-local=$PREFIX --with-libz=$PREFIX --with-sqlite3=$PREFIX --with-openjpeg=$PREFIX --prefix=$PREFIX"
}

init_linux() {
	HDF4_LIBS="-lm"
	GDAL_CONFIGURE_FLAGS="--with-libkml=$PREFIX/ --with-=/usr/bin/curl-config --with-hdf5=yes --with-hdf4=$PREFIX --with-geotiff=/usr/lib --with-libtiff=/usr/lib --with-png=/lib/x86_64-linux-gnu/ --with-sqlite3=$PREFIX --with-openjpeg=$PREFIX --prefix=$PREFIX --with-local=/usr/local/"
	CMAKE_COMMON_SHARED_LINKER_FLAGS="-L${PREFIX}/lib -lz -ltiff -lgeotiff -lpng12 -lhdf5 -ljpeg -lgeos_c -lkmldom -lkmlbase -lkmlconvenience -lkmlengine -lkmlregionator -lexpat -lcurl -lz"
	GDAL_COMPILER_FLAGS="-I${PREFIX}/include/kml/third_party/boost_1_34_1 -I/usr/include/geotiff -fpermissive"
	KML_CMAKE_SHARED_LINKER_FLAGS="-L${PREFIX}/lib -lz"
	if [ ${DO_BASE:-"false"} = "true" ] ; then
		postmessage "En GNU/Linux no se deben compilar bibliotecas base, se deben usar del sistema"
		unset DO_BASE
	fi
	if [ ${DO_HDF5:-"false"} = "true" ] ; then
		postmessage "En GNU/Linux no se deben compilar libhdf5, se debe usar del sistema"
		unset DO_HDF5
	fi
}

HDF_COMMON_FLAGS="--disable-fortran"

initialize $* || die

CMAKE_COMMON_FLAGS="-DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_SHARED_LIBS=true"

if [ ${DO_BASE:-"false"} = "true" ] ; then
	export LDFLAGS=$NO_UNDEFINED
	export MAKEFLAGS=""
	build_library "${SRCDIR}/proj-4.8.0.tar.gz" "$COMMON_FLAGS $SHARED $STATIC" || die
	reset_flags

	# GEOS no se banca compilar con --static-libgcc
	export CFLAGS="-pipe"
	export CXXFLAGS="-pipe"
	build_library "${SRCDIR}/geos-3.3.8.tar.bz2" "$COMMON_FLAGS $SHARED $STATIC" "" "" "" "" "" "" || die
	reset_flags

	extract "${SRCDIR}/libgeotiff-1.4.0.tar.gz" OUTDIR || die
	apply_patch "geotiff-proj4-4.8-projects_h-cmake.patch" "-d $OUTDIR" || die
	
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
	echo "export $(echo "${OUTDIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_COSMETIC_ENVIRONMENT_VERSION${SUFFIX}='${COSMETIC_ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
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
	install_makepackage "$OUTDIR" "" "" || die

	# retorno a carpeta original
	cd ..
	
	build_library "${SRCDIR}/curl-7.31.0.tar.bz2" "$COMMON_FLAGS $SHARED $STATIC --with-zlib=$PREFIX " "" "" || die
fi

if [ ${DO_HDF5:-"false"} = "true" ] ; then

	extract "${SRCDIR}/hdf5-1.8.11.tar.bz2" OUTDIR
	apply_patch "hdf_cmake.patch" "-d $OUTDIR" || die

	CMAKE_HDF5_ENABLED_FLAGS="-DHDF5_BUILD_TOOLS=true -DHDF5_USE_16_API_DEFAULT=false -DH5_LEGACY_NAMING=false"
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
	echo "export $(echo "${OUTDIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_COSMETIC_ENVIRONMENT_VERSION${SUFFIX}='${COSMETIC_ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
	echo "Version: $ENVIRONMENT_VERSION" > "$OUTDIR.env"
	echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
	echo cmake ..  -G \"${CMAKE_GENERATOR}\" ${CMAKE_COMMON_FLAGS} -DCMAKE_CXX_FLAGS=\"${GDAL_CXX_FLAGS}\" -DCMAKE_C_FLAGS=\"${GDAL_C_FLAGS}\" -DBUILD_SHARED_LIBS=\"True\" -DCMAKE_C_STANDARD_LIBRARIES=\"${CMAKE_COMMON_C_STANDARD_LIBRARIES}\" ${CMAKE_HDF5_ENABLED_FLAGS} >> "$OUTDIR.env"
	echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
	cmake ..  -G "${CMAKE_GENERATOR}" ${CMAKE_COMMON_FLAGS} -DCMAKE_CXX_FLAGS="${GDAL_CXX_FLAGS}" -DCMAKE_C_FLAGS="${GDAL_C_FLAGS}" -DBUILD_SHARED_LIBS=\"True\" -DCMAKE_C_STANDARD_LIBRARIES="${CMAKE_COMMON_C_STANDARD_LIBRARIES}" ${CMAKE_HDF5_ENABLED_FLAGS} 2>&1 >> "$OUTDIR.env" || die
	echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
	cat CMakeCache.txt >> "$OUTDIR.env"

	# genero e installo la aplicacion, hago cd .. para que el archivo generado tenga nombre correcto
	cd ..
	build "$OUTDIR" "no-configure" "" || die
	install_makepackage "$OUTDIR" "" "" || die

	# retorno a carpeta original
	cd ..
fi

if [ ${DO_KML:-"false"} = "true" ] ; then
	extract "${SRCDIR}/libkml-trunk.tar.gz" OUTDIR
	if [ $WINDOWS ] ; then
		apply_patch "kml_cmake.patch" "-d $OUTDIR" || die

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
		echo "export $(echo "${OUTDIR}" | tr [:lower:] [:upper:] | sed -e 's/[ \.-]/_/g')_COSMETIC_ENVIRONMENT_VERSION${SUFFIX}='${COSMETIC_ENVIRONMENT_VERSION}'" >> $PREFIX/share/sur/build_environment.sh	
		echo "Version: $ENVIRONMENT_VERSION" > "$OUTDIR.env"
		echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
		echo cmake .. -G \"${CMAKE_GENERATOR}\" ${CMAKE_COMMON_FLAGS} -DCMAKE_CXX_FLAGS=\"${GDAL_CXX_FLAGS}\" -DCMAKE_C_FLAGS=\"${GDAL_C_FLAGS}\" -DLIBKML_USE_EXTERNAL_EXPAT=true -DCMAKE_SHARED_LINKER_FLAGS=\"${KML_CMAKE_SHARED_LINKER_FLAGS}\" >> "$OUTDIR.env"
			echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
		cmake .. -G "${CMAKE_GENERATOR}" ${CMAKE_COMMON_FLAGS} -DCMAKE_CXX_FLAGS="${GDAL_CXX_FLAGS}" -DCMAKE_C_FLAGS="${GDAL_C_FLAGS}" -DLIBKML_USE_EXTERNAL_EXPAT=true -DCMAKE_SHARED_LINKER_FLAGS="${KML_CMAKE_SHARED_LINKER_FLAGS}" 2>&1 >> "$OUTDIR.env" || die
		echo "--------------------------------------------------------------------------------------" >> "$OUTDIR.env"
		cat CMakeCache.txt >> "$OUTDIR.env"
		# genero e installo la aplicacion, hago cd .. para que el archivo generado tenga nombre correcto
		cd ..
		build "$OUTDIR" "no-configure" "" || die
		install_makepackage "$OUTDIR" "" "" || die

		# retorno a carpeta original
		cd ..
	else
		apply_patch "kml-ld-as-needed.patch" "-d $OUTDIR" || die
		apply_patch "kml-posix-unistd-fix.patch" "-d $OUTDIR" || die
		export CFLAGS="-Wno-long-long"
		export CXXFLAGS="-Wno-long-long"
		build_library "${SRCDIR}/libkml-trunk.tar.gz" "$COMMON_FLAGS $SHARED $STATIC" "" "" || die
		reset_flags
	fi
fi

#if [ ${DO_HDF4:-"false"} = "true" ] ; then
#	export CPPFLAGS=
#	export LIBS=$HDF4_LIBS
#	build_library "HDF4.2r2.tar.gz" "$SHARED $STATIC $COMMON_FLAGS $HDF_COMMON_FLAGS --disable-netcdf --with-zlib=$ZIPPREFIX -with-jpeg=$JPEGPREFIX" "" "" -p hdf4-mingw.patch|| die
#	GDAL_WITH="${GDAL_WITH} --with-hdf4=$PREFIX "
#	export LIBS=
#fi

#export LD_FLAGS=$NO_UNDEFINED
#if [ ${DO_NETCDF:-"false"} = "true" ] ; then
#	mv netcdf.tar.gz netcdf-3.6.2.tar.gz
#	build_library "netcdf-3.6.2.tar.gz" "$COMMON_FLAGS $SHARED $STATIC" "" "" -p netcdf-cstring.patch|| die
#	GDAL_WITH="${GDAL_WITH} --with-netcdf=$PREFIX"
#	mv netcdf-3.6.2.tar.gz netcdf.tar.gz
#fi

if [ ${DO_GDAL:-"false"} = "true" ] ; then
	GDAL_SRC="${SRCDIR}/gdal-1.11.0.tar.gz"
	extract "${GDAL_SRC}" OUTDIR

	apply_patch "gdal-1.x-mingw-dynamic.patch" "-d $OUTDIR" || die
	apply_patch "gdal-VSIStatBufL-no-initializer.patch" "-d $OUTDIR" || die
	apply_patch "gdal-l1b-support_to_conae_noaas.patch" "-d $OUTDIR"  || die
	apply_patch "gdal-alos-changes.patch" "-d $OUTDIR" || die
	apply_patch "gdal-maximum-order.patch" "-d $OUTDIR" || die
	apply_patch "gdal-fastv6.patch" "-d $OUTDIR" 1 || die
	apply_patch "gdal-tms.patch" "-d $OUTDIR" 1 || die
	apply_patch "gdal-enhanced-support-webmercator.patch" "-d $OUTDIR" || die
	apply_patch "gdal-hdf-configure.patch" "-d $OUTDIR" || die
	apply_patch "gdal-fastv6-additional-metadata.patch" "-d $OUTDIR" || die
	apply_patch "gdal-update-gdalserver-define.patch" "-d $OUTDIR" 1 || die
	if [ $WINDOWS ] ; then
		postmessage "Sin patch especial en windows"
	else
		apply_patch "gdal-linux-libkml-link-order.patch" "-d $OUTDIR"  || die
	fi

	export CPPFLAGS="${CPPFLAGS} ${GDAL_COMPILER_FLAGS} -Wno-unused-but-set-variable"
	export CXXFLAGS="${CXXFLAGS} ${GDAL_COMPILER_FLAGS} -Wno-unused-but-set-variable"
	export CFLAGS="${CFLAGS} ${GDAL_COMPILER_FLAGS} -Wno-unused-but-set-variable"
	if [ $WINDOWS ] ; then
		# explicacion de -Wl,-lbfd : http://mingw.5.n7.nabble.com/A-question-about-linking-td6455.html
		export LDFLAGS="${LDFLAGS} -Wl,-lbfd"
	fi
	build_library "${GDAL_SRC}" "$COMMON_FLAGS $SHARED $STATIC ${GDAL_CONFIGURE_FLAGS}" "" "" || die

	reset_flags
fi

#El script deja los binarios generados en la carpeta bin
move_packages


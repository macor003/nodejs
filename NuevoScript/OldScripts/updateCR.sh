#!/bin/bash
USER=svnuser
PASS=svnuser
projectName='CRJARS'
projectLibs='CRLibs'
COMMENT='Auto Sync '`date`
DAY=`date +"%j"`
APPDIR="/opt/CR"
LIBDIR="/opt/CRLibs"
TIPOUPDATE=$1
logFile="$APPDIR/logs/updateCR.log"
INSTALLDIR="/opt/InstaladorCR30"
VERSIONFILE="/opt/version/version.txt"
HVPOSFILE="" #$INSTALLDIR"/Files/vposheaders/ve/"
LOGFILE=$logFile
LOGFILELIBS=$logFile
cmd1="xauth merge /home/cajero/.Xauthority"
cmd2="export DISPLAY=:0.0"
cmd3="xmodmap -e 'keycode 91 = comma'"
VPOSCONFFILE="$APPDIR/vpos/conf/vposconf.ini"
eval $cmd1
eval $cmd2
eval $cmd3
SEQNUMBCK="seqnum=1"
VTIDBCK=""
IDBCK=""
POSUSER="usercr2"
POSPASS="usercr2"
POSBD="CRPOS"
serverResponse=false
today=`date +%Y-%m-%d`
dateToApplyUpdate=`cat dateToUpdate`
hDiff=0
dDiff=0
CHECKSUMFILE="checksum.txt"
REVISIONLOCAL=0
REVISIONSVN=0
DIFFREVISION=0
SVNSERVER="svn"
esPiloto="N"

function verifyVersion(){
	esPiloto=$(mysql -u$POSUSER -p$POSPASS $POSBD -e 'select valor from opcion where id=4\G;' | awk '{printf $2}' FS=": ")
	echo "Caja Piloto -> $esPiloto" 2>&1 | tee -a $logFile
	
	if [[ $esPiloto == "s" || $esPiloto == "S" ]]; then
		VERSIONFILE="/opt/version/versionPiloto.txt"
		echo "Se usa archivo de version Piloto" 2>&1 | tee -a $logFile
	fi	
}


################################################################################
# Limpieza de proyectos

function cleanProjects() {
	echo "Metodo cleanProjects()" 2>&1 | tee -a $logFile
	$(svn cleanup $APPDIR) 2>&1 | tee -a $logFile
	$(svn cleanup $LIBDIR) 2>&1 | tee -a $logFile
	$(svn cleanup $INSTALLDIR) 2>&1 | tee -a $logFile
	$(rm $APPDIR/checksum.txt) 2>&1 | tee -a $logFile
	
	for fileToDelete in `find $APPDIR -type f -iname '*txt.r*'` ; do
		cmd="rm $fileToDelete"
		eval $cmd 2>&1 | tee -a $logFile
	done
	for fileToDelete in `find $APPDIR -type f -iname '*jar.r*'` ; do
		cmd="rm $fileToDelete"
		eval $cmd 2>&1 | tee -a $logFile
	done
	for fileToDelete in `find $APPDIR -type f -iname '*sh.r*'` ; do
		cmd="rm $fileToDelete"
		eval $cmd 2>&1 | tee -a $logFile
	done
	for fileToDelete in `find $APPDIR -type f -iname '*.mine'` ; do
		cmd="rm $fileToDelete"
		eval $cmd 2>&1 | tee -a $logFile
	done
}

function fixPermission() {
	echo "Metodo fixPermission()" 2>&1 | tee -a $logFile
	
	#if [ -d "$APPDIR/tempej" ]; then 
	#	$(sudo smbumount $APPDIR/tempej) 2>&1 | tee -a $logFile
	#fi

	#===========================================================================
	# Copiar el script de iniciarCR
	PACKAGEDIR=$INSTALLDIR"/Files/packages"
	cmd8="cp -vp $PACKAGEDIR/iniciarCR.sh $APPDIR/iniciarCR.sh"
	cmd9="chmod 777 $APPDIR/iniciarCR.sh"
	eval $cmd8 2>&1 | tee -a $logFile
	eval $cmd9 2>&1 | tee -a $logFile

	cmd1="ls -1 $APPDIR/updatedb/*.sql > $APPDIR/updatedb/updatedb.order"
	eval $cmd1 2>&1 | tee -a $logFile
	cmd2="sudo setfacl -Rm u:cajero:rwx $APPDIR"
	eval $cmd2 2>&1 | tee -a $logFile
	cmd3="sudo chmod +x -R $APPDIR/*"
	eval $cmd3 2>&1 | tee -a $logFile
	cmd4="sudo chown -Rf cajero:users $APPDIR"
	eval $cmd4	 2>&1 | tee -a $logFile
	
}

function updateInstallDir() {
	PROYINSTALADOR=$(cat $VERSIONFILE | grep -i instaladorcr30 | awk '{print $1}' FS=",")
	REVINSTALADOR=$(cat $VERSIONFILE | grep -i instaladorcr30 | awk '{print $2}' FS=",")
	
	echo "Metodo updateInstallDir()" 2>&1 | tee -a $logFile
	cmd5="sudo setfacl -Rm u:cajero:rwx $INSTALLDIR"
	eval $cmd5 2>&1 | tee -a $logFile

	cmd6="sudo chmod +x -R $INSTALLDIR/*"
	eval $cmd6 2>&1 | tee -a $logFile

	cmd7="sudo chown -Rf cajero:users $INSTALLDIR"
	eval $cmd7 2>&1 | tee -a $logFile

	cmd="svn sw -r $REVINSTALADOR $PROYINSTALADOR --username $USER --password $USER $INSTALLDIR"
	eval $cmd 2>&1 | tee -a $logFile
}

function updateProject() {
	for proy in $projectName $projectLibs
	do
		echo "Metodo updateProject()" 2>&1 | tee -a $logFile
		#***************************
		# determinar si hay instalacion
		# para hacer checkout o switch
		#***************************
		PROYECTO=$(cat $VERSIONFILE | grep -i $proy | awk '{print $1}' FS=",")
		REVISION=$(cat $VERSIONFILE | grep -i $proy | awk '{print $2}' FS=",")
	
		xmlProjectFile=$APPDIR"/gconf_"$(echo $proy| tr '[:upper:]' '[:lower:]')".xml"
		xmlBackupFile=$APPDIR"/gconf_mod_bkg.xml"
	
		echo "Proyecto $proy" 2>&1 | tee -a $logFile
		echo $PROYECTO
		echo $REVISION

		echo "Descargando version de $proy desde la revision $REVISION" 2>&1 | tee -a $logFile

		case $TIPOUPDATE in
		0)
			#************************************
			#en caso de checkout del repositorio origen
			#************************************
			echo "Instalando paquetes";
			echo "Descargando proyecto "$proy;
			command="svn checkout -r $REVISION --non-interactive $PROYECTO";
			
			if [[ $proy == $projectLibs ]]; then
				command=$command" --username $USER --password $PASS $LIBDIR/";
			else
				command=$command" --username $USER --password $PASS $APPDIR/";
			fi
	
			echo $command
			eval $command
			;;
		1)
			#************************************
			# en caso de switch
			#************************************
			updateInstallDir #<- Se actualiza el instalador
		
			echo "Actualizando paquetes" 2>&1 | tee -a $logFile
			echo "Descargando proyecto $proy" 2>&1 | tee -a $logFile
			command="svn switch -r $REVISION $PROYECTO"
			if [[ $proy == $projectLibs ]]; then
				command=$command" --username $USER --password $PASS $LIBDIR";
			else
				command=$command" --username $USER --password $PASS $APPDIR";
			fi
	
			if [[ $proy == $projectLibs ]]; then
				cmd="sudo cp $VPOSCONFFILE /opt/"
				echo "Ejecutando -> $cmd" 2>&1 | tee -a $logFile
				eval $cmd 2>&1 | tee -a $logFile
				
				#cmd="rm -f $VPOSCONFFILE"
				#echo "Ejecutando -> $cmd" 2>&1 | tee -a $logFile
				#eval $cmd 2>&1 | tee -a $logFile
				
				$(gconftool-2 --load $xmlProjectFile)
				echo $command 2>&1 | tee -a $logFile;
				eval $command 2>&1 | tee -a $logFile;
				$(gconftool-2 --load $xmlBackupFile)
				
				#echo "Ejecutando -> vposConf" 2>&1 | tee -a $logFile
				#vposConf #<- llamada al metodo de configuracion de encabezado y seqnum
				
			else
				$(gconftool-2 --load $xmlProjectFile)
				echo $command 2>&1 | tee -a $logFile;
				eval $command 2>&1 | tee -a $logFile;
				$(gconftool-2 --load $xmlBackupFile)
			fi
			sleep 0.5
			;;
		*)
	
			;;
		esac
	done;
}

###############################################################################
#Metodo que compara la diferencia entre revisiones del checksum.txt
###############################################################################
function compareChecksum() {

	PROYECTO=$(cat $VERSIONFILE | grep -i crjars | awk '{print $1}' FS=",")
	
	REVISIONSVN=$(svn info --username=$USER --password=$PASS $PROYECTO | grep -i 'revisi.n del .ltimo cambio:' | awk '{print $2}' FS=": ")
	echo "Revision SVN: $REVISIONSVN"
	
	REVISIONLOCAL=$(svn info $APPDIR | grep -i 'revisi.n del .ltimo cambio:' | awk '{print $2}' FS=": ")
	echo "Revision local: $REVISIONLOCAL"

	DIFFREVISION=$(expr $REVISIONSVN - $REVISIONLOCAL)
	echo "Diferencia entre revision SVN y local : $DIFFREVISION" 2>&1 | tee -a $logFile
}

###############################################################################
#Metodo que compara la diferencia en dias entre 2 fechas
###############################################################################
function compareTimes() {
	t1=`date --date="$dateToApplyUpdate" +%s`

	t2=`date --date="$today" +%s`

	let "tDiff=$t2-$t1"
	let "hDiff=$tDiff/3600"
	let "dDiff=$hDiff/24"
}

###############################################################################
#Metodo que verifica la conexion con el servidor400
###############################################################################
function checkConnect() {
	echo "Verificando conexion con el servidor" 2>&1 | tee -a $logFile
	PINGCOUNT=1

	PING=$(ping -c $PINGCOUNT $SVNSERVER | grep received | cut -d ',' -f2 | cut -d ' ' -f2)

	if [[ $PING == "connect: Network is unreachable" ]]; then
		echo "El SVN NO responde PING" 2>&1 | tee -a $logFile
		serverResponse=false
	else
		if [[ $PING == "1" ]]; then
			echo "El SVN responde PING" 2>&1 | tee -a $logFile
			serverResponse=true;
			sleep 1;
		fi
	fi
	echo "Conexion con el servidor -> $serverResponse" 2>&1 | tee -a $logFile
}

###############################################################################
#Metodo que verifica que este montada la unidad NFS
###############################################################################
function isVersionFile(){
	if [ -e "$VERSIONFILE" ]; then
		versionFileExist=true;
	else
		versionFileExist=false;
	fi
}

###############################################################################
#Metodo que compara las versiones tanto de jars como de librerias
###############################################################################
function compareVersion(){
	# Version actual de CRJARS
	urlJars=$(svn info $APPDIR | grep -i url)
	versionActualJars=$(echo ${urlJars##*/})
	posicionVersionJars=$(expr $(awk -v a="$urlJars" -v b="${urlJars##*/}" 'BEGIN{print index(a,b)}') - 2)
	urlSinVersionJars=$(echo | awk '{print substr("'"${urlJars}"'",0,"'"${posicionVersionJars}"'")}')
	tipoRamaJars=$(echo ${urlSinVersionJars##*/})
	
	# Cargo la informacion desde version.properties
	echo "Version actual de JARS -> Rama $tipoRamaJars en la version $versionActualJars"  2>&1 | tee -a $logFile
	
	versionJarsActual=$tipoRamaJars$versionActualJars
	
	# Version actual de CRLibs
	urlLibs=$(svn info $LIBDIR | grep -i url)
	versionActualLibs=$(echo ${urlLibs##*/})
	posicionVersionLibs=$(expr $(awk -v a="$urlLibs" -v b="${urlLibs##*/}" 'BEGIN{print index(a,b)}') - 2)
	urlSinVersionLibs=$(echo | awk '{print substr("'"${urlLibs}"'",0,"'"${posicionVersionLibs}"'")}')
	tipoRamaLibs=$(echo ${urlSinVersionLibs##*/})

	echo "Version actual de LIBS -> Rama $tipoRamaLibs en la version $versionActualLibs"  2>&1 | tee -a $logFile

	versionLibsActual=$tipoRamaLibs$versionActualLibs

########################################################################################################################

	# Verifico la informacion de /opt/version.txt para CRJARS
	urlJars=$(cat $VERSIONFILE | grep -i crjars | awk '{print $1}' FS=",")
	versionActualJars=$(echo ${urlJars##*/})
	posicionVersionJars=$(expr $(awk -v a="$urlJars" -v b="${urlJars##*/}" 'BEGIN{print index(a,b)}') - 2)
	urlSinVersionJars=$(echo | awk '{print substr("'"${urlJars}"'",0,"'"${posicionVersionJars}"'")}')
	tipoRamaJars=$(echo ${urlSinVersionJars##*/})

	echo "Version de JARS a actualizar -> Rama $tipoRamaJars en la version $versionActualJars"  2>&1 | tee -a $logFile
	
	versionJarsToUpdate=$tipoRamaJars$versionActualJars
	
	# Verifico la informacion de /opt/version.txt para CRLIBS
	urlLibs=$(cat $VERSIONFILE | grep -i crlibs |  awk '{print $1}' FS=",")
	versionActualLibs=$(echo ${urlLibs##*/})
	posicionVersionLibs=$(expr $(awk -v a="$urlLibs" -v b="${urlLibs##*/}" 'BEGIN{print index(a,b)}') - 2)
	urlSinVersionLibs=$(echo | awk '{print substr("'"${urlLibs}"'",0,"'"${posicionVersionLibs}"'")}')
	tipoRamaLibs=$(echo ${urlSinVersionLibs##*/})

	echo "Version de LIBS a actualizar -> Rama $tipoRamaLibs en la version $versionActualLibs"  2>&1 | tee -a $logFile

	versionLibsToUpdate=$tipoRamaLibs$versionActualLibs
}

###############################################################################
#Metodo que realiza la actualizacion
###############################################################################
function doUpdate() {
	echo -e ${txtblu}
	echo '######################################################' 2>&1 | tee -a $logFile 
	echo '#       Verificando actualizacion de paquetes	     #'  2>&1 | tee -a $logFile
	echo '######################################################' 2>&1 | tee -a $logFile 
	echo 2>&1 | tee -a $logFile
	echo -e ${txtrst}
	
	isVersionFile	#<- llamada al metodo que verifica que exista el archivo de version

	if [[ $serverResponse == "true" && $versionFileExist == "true" ]]; then

		compareVersion #<- funcion para comparar las versiones tanto de jars como de libs

		echo ""  2>&1 | tee -a $logFile
		echo "##################################################################################"  2>&1 | tee -a $logFile
		echo "Resumen"  2>&1 | tee -a $logFile
		echo "$versionJarsActual - $versionJarsToUpdate y $versionLibsActual - $versionLibsToUpdate"  2>&1 | tee -a $logFile
		echo "##################################################################################"  2>&1 | tee -a $logFile

########################################################################################################################

		# Verifico que la version que existe y la version que debe tener son iguales
		if [[ $versionJarsActual != $versionJarsToUpdate || $versionLibsActual != $versionLibsToUpdate ]]; then
			echo '######################################################' 2>&1 | tee -a $logFile 
			echo '#       Existen actualizaciones pendientes	     #'  2>&1 | tee -a $logFile
			echo '#       Aplicando actualizacion de paquetes	     #'  2>&1 | tee -a $logFile
			echo '######################################################' 2>&1 | tee -a $logFile 
			echo 2>&1 | tee -a $logFile
			cmd="rm $APPDIR/checksum*"
			eval $cmd
			cmdrm="rm -f $APPDIR/*.jar"
			eval $cmdrm
			TIPOUPDATE="1"
			
			cleanProjects	#<- Limpia la informacion SVN de los proyectos
			SEQNUMBCK=$(cat $VPOSCONFFILE | grep -i seqnum=)
			
			updateProject	#<- Llamada al metodo que actualiza los proyectos
			eval "$APPDIR/./fixSvnErrorFile.sh $logFile"
		else
			echo '######################################################' 2>&1 | tee -a $logFile 
			echo '# Validando si hay actualizaciones para el mismo dia #'  2>&1 | tee -a $logFile
			echo '######################################################' 2>&1 | tee -a $logFile
			echo 2>&1 | tee -a $logFile
			compareChecksum
		
			if [ $DIFFREVISION -gt 0 ]; then
				echo '######################################################' 2>&1 | tee -a $logFile
				echo "#         Actualizando para el mismo dia           #" 2>&1 | tee -a $logFile
				echo '######################################################' 2>&1 | tee -a $logFile
				cmd="rm $APPDIR/checksum*"
				eval $cmd
				cmdrm="rm -f $APPDIR/*.jar"
				eval $cmdrm
				TIPOUPDATE="1"
				
				cleanProjects	#<- Limpia la informacion SVN de los proyectos
				SEQNUMBCK=$(cat $VPOSCONFFILE | grep -i seqnum=)
				
				updateProject	#<- Llamada al metodo que actualiza los proyectos
				
				eval "$APPDIR/./fixSvnErrorFile.sh $logFile"
			else
				echo '######################################################' 2>&1 | tee -a $logFile 
				echo '#  La caja se encuentra correctamente actualizada  #'  2>&1 | tee -a $logFile
				echo '######################################################' 2>&1 | tee -a $logFile
				echo 2>&1 | tee -a $logFile
			fi
		fi
	else
		echo '######################################################' 2>&1 | tee -a $logFile
		echo '#        No se pudo aplicar actualizacion	       #' 2>&1 | tee -a $logFile
		echo '#      Por falla de conexion con el servidor	     #' 2>&1 | tee -a $logFile  
		echo '#       o falla de acceso al servidor NFS	       #' 2>&1 | tee -a $logFile  
		echo '######################################################' 2>&1 | tee -a $logFile  
		echo  2>&1 | tee -a $logFile
	fi
}

###############################################################################
#Metodo que verifica si hay que realizar una actualizacion
###############################################################################
function checkUpdate() {

	checkConnect #<- llamada al metodo que verifica la conexion con el servidor400
	if [[ $serverResponse == "true" ]]; then
		eval "$APPDIR/./executeFile.sh $logFile" 2>&1 | tee -a $logFile 
	fi
	
	if [ -e "dateToUpdate" ]]; then
		compareTimes
		echo "Diferencia entre $dateToApplyUpdate & $today = $dDiff dias" 2>&1 | tee -a $logFile
	else
	  echo "No tiene fecha de actualizacion" 2>&1 | tee -a $logFile

	fi
}

function main() { 
	echo "Metodo main()" 2>&1 | tee -a $logFile
	verifyVersion   #<- Llamada al metodo que verifica que archivo de version voy a usar.
	checkUpdate #<- llamada al metodo que verifica si hay que aplicar una actualizacion
	
	if [ $dDiff -ge 0 ]; then
		doUpdate
	else
		echo "La proxima actualizacion del sistema se aplicara el $dateToApplyUpdate" 2>&1 | tee -a $logFile
	fi
	
	fixPermission	#<- Llamada al metodo que repara la permisologia de los proyectos
}

main	#<- Llamada al metodo principal

echo "Fin updateCR.sh" 2>&1 | tee -a $logFile

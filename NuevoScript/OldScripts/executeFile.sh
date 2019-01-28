#!/bin/bash 

export LANG=es_VE
cmd1="xauth merge /home/cajero/.Xauthority"
cmd2="export DISPLAY=:0.0"
cmd3="xmodmap -e 'keycode 91 = comma'"
eval $cmd1
eval $cmd2
eval $cmd3

CURRENT_DIR=`pwd`
APPDIR="/opt/CR"
SCRIPTSDIR="$APPDIR/scripts"
logFile=$1
cmd1="chmod +x -R $SCRIPTSDIR"
eval $cmd1

for archivo in `ls $SCRIPTSDIR/*.sh | awk '{print $5}' FS="/"` ; do

	cmd4="$SCRIPTSDIR/./$archivo $logFile";
	echo "Ejecutando "$archivo 2>&1 | tee -a $logFile;

	cmdZenity="($cmd4) 2>&1 | zenity";
	cmdZenity=$cmdZenity" --title='Instalando CR v2.0...'";
	cmdZenity=$cmdZenity" --text='Ejecutando $archivo, espere por favor'";
	cmdZenity=$cmdZenity" --progress --pulsate --auto-close";

	echo $cmdZenity
	eval $cmdZenity
	
#	echo "Eliminando $archivo";
#	cmd5="rm -f $SCRIPTSDIR/$archivo";
#	echo $cmd5;
#	eval $cmd5;

done



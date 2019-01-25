// ######################################################
//      Archivo para instalar o actualizar CRv3
// ######################################################

// Imports
const svnUltimate = require('node-svn-ultimate');
const colors = require('colors');
const connection = require('./db/connection');

let APPDIR = "/opt/CR"
let APPLIBS = "/opt/CRLibs"
let VERSIONFILE;

function main() {
    console.log('####################################### '.green);
    console.log('####### Iniciando actualización ####### '.green);
    console.log('####################################### '.green);

    verifyVersion();

};

function verifyVersion() {
    let esPiloto;
    connection.connect();

    connection.query('select valor from opcion where id=4', (err, results) => {
        if (err) throw err;

        //console.log(results[0].valor);

        esPiloto = results[0].valor;
        if (esPiloto === 's' & esPiloto === 'S') {
            VERSIONFILE = "/opt/version/versionPiloto.txt";
            console.log('Se usa versionPiloto.txt'.yellow);
        } else {
            VERSIONFILE = "/opt/version/version.txt"
            console.log('Se usa version.txt'.yellow);
        }
        checkUpdate();
    });
    connection.end();


}

function checkUpdate() {
    console.log('Verificando si se debe actualizar'.green);
    checkConnectSVN();
}

function checkConnectSVN() {

    svnUltimate.util.getRevision('../pruebaSVN/', {
        username: "eve0018536",
        password: "eve0018536"
    }, (err, response) => {
        if (err) throw err
        console.log('Revisión Local:  ' + response);
    })

    svnUltimate.util.getRevision('svn://svn.epa.com/Snapshots/Ventas/CRv3/INTEL/CRSyncService', {
        username: "eve0018536",
        password: "eve0018536"
    }, (err, response) => {
        if (err) {
            console.log('Ocurrio un Error con el SVN no se actualizara'.red);
            console.log('Error: ' + err);
            return;
        }
        console.log('Revisión Remota: ' + response);
    });

}


main();
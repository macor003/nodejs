// ######################################################
//            Configuración de conexión a BD
// ######################################################

const mysql = require('mysql');

const connection = mysql.createConnection({
    host: '10.1.57.150',
    user: 'usercr2',
    password: 'usercr2',
    database: 'CRPOS'
});

module.exports = connection;
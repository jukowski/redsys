express = require('express');
app = express();

redsys = require('../src/server/redsys.coffee');

vfs = require("vfs-local")({
    root: __dirname+"/../test_files",
    defaultEnv: { CUSTOM: 43 },
    checkSymlinks: true
  });

http = require('http')
async = require("async");
path = require("path")

options =
  db: {type: 'none'},
  browserChannel: {cors: '*'},


server = http.createServer(app);
app.use(express.static('../public'));

redsys.attach(app, options);
redsys.createProject(vfs);


server.listen(8002);

process.title = 'sharejs'
process.on('uncaughtException',  (err) ->
  #console.error('An error has occurred. Please file a ticket here: https://github.com/josephg/ShareJS/issues');
  #console.error('Version '+ err);
)

sharejs = require("share").server;

express = require('express');
app = express();

http = require('http')
async = require("async");
path = require("path")

options =
  db: {type: 'none'},
  browserChannel: {cors: '*'},

model = sharejs.createModel(options)

server = http.createServer(app);
app.use(express.static('../public'));


sharejs.attach(app, options);
server.listen(8002);

process.title = 'sharejs'
process.on('uncaughtException',  (err) ->
  #console.error('An error has occurred. Please file a ticket here: https://github.com/josephg/ShareJS/issues');
  #console.error('Version ' + sharejs.version + ': ' + err.stack);
)

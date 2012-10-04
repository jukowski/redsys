http = require('http');
faye = require('faye');
express = require('express');
app = express();
fs = require('fs');
Schema = require('protobuf').Schema;
hat = require("hat");
schema = new Schema(fs.readFileSync('../api/api.desc'));

bayeux = new faye.NodeAdapter({mount: '/faye', timeout: 45});

protoclient = new require('./protofaye.coffee').proto(bayeux, schema);

server = http.createServer(app);
app.use(express.static('../public'));
bayeux.attach(server);

protoclient.subscribe("/service/register", "redsys.InitClient", (obj) ->
  protoclient.publish("/service/register", "redsys.SessionId", {sessionid : hat()} )
  )

server.listen(8002);


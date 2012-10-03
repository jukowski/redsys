sharejs = require("share").server;
async = require("async");

model = sharejs.createModel({
  db : {type:"none"},
  
  });

async.waterfall([
  (callback) -> model.create("test.stex", "text", {"author":"cjucovschi"}, callback),
  (callback) -> model.listen("test.stex", 0, callback),
  (doc, callback) -> console.log(doc);
], (err, callback) ->
  console.log(err);
  );

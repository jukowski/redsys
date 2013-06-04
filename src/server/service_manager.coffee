service = require("../../stex/nnexus.coffee").service;
async = require("async");

exports.getAvailableServices = () ->
	return {
		nnexus : 
			title: "NNexus", 
	}


exports.enableService = (model, serviceID, file, projectID) ->
	console.log("enabling ",serviceID, " on file ", file, " for project ", projectID);
	async.waterfall [
		(callback) -> model.getSnapshot file, callback,
		(snapshot, callback) ->
			nnexus = new service(snapshot);
			callback();
	], (err) ->
		console.log("Error ", err) if err?
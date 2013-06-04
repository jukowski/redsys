exports.getAvailableServices = () ->
	return {
		nnexus : 
			title: "NNexus", 
	}


exports.enableService = (serviceID, file, projectID) ->
	console.log("enabling ",serviceID, " on file ", file, " for project ", projectID);
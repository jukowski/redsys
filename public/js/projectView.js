(function () { 

var projectFiles;

 // if ($("#createAccountid").hasClass('expandSidebar')) {
 //  $(".view").removeClass('contractSidebar');
 //  $("#createAccountid").removeClass ('expandSidebar').addClass('contractSidebar');
 //  $("#Createsideview").slideDown();

function toggleLeftPane () {
	if ($("#left-pane").hasClass('pane-hidden')) {
		showPane ();
		$("#left-pane").removeClass('pane-hidden').addClass('pane-visible');
	}
	else {
		hidePane ();
		$("#left-pane").removeClass('pane-visible').addClass('pane-hidden');
	}
}

function hidePane () {
	$("#left-pane").animate ({"left": "-=150px"}, "slow");
	$("#editor").animate ({"left": "-=150px"}, "slow");
}

function getProjectFiles () {
	$.get("list?path=&client=18ff66e0cf5101c63a5fba89d5f08e72", function(data) {
		data = JSON.parse(data);
		projectFiles = data['data'];
		if (projectFiles.length > 0) {
			$("#projectsList").append ("<ul id = 'listofFileNames'>");
			for (var x = 0; x < projectFiles.length; x++) {
				$("#projectsList").append ("<li id = 'project-filename'><hr>" + 
					projectFiles[x].name + "</li");
			}
			$("#projectsList").append ("</ul>");
		}
	});
}
function showPane () {
	if (projectFiles == undefined) {
		getProjectFiles();
	}
	$("#left-pane").animate ({"left": "+=150px"}, "slow");
	$("#editor").animate ({"left": "+=150px"}, "slow");
}
	$("#projectls").click(toggleLeftPane);
})();



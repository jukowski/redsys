function serialize(message) {
    var stream = new PROTO.Base64Stream;
    message.SerializeToStream(stream);
    return {"type":message.message_type_,"s":stream.getString()};
}

function unserialize(type, message) {
    classString = type;
    if (classString.match(/^[a-zA-Z\.]+$/)) {
	restMessage = message;
	var stream = new PROTO.Base64Stream(restMessage);
	message = eval("new "+classString);
	message.ParseFromStream(stream);
	return message;
    } else
	return null;
}

function restore(commetmsg) {
	return unserialize(commetmsg.data.type, commetmsg.data.s);
}
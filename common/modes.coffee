AttributePool = require('../../webclient/AttributePool')
etherpad = require('../types/etherpad')
Changeset = require('../../webclient/Changeset')

###

Defines view mode mechanism for parts of text

A text range can have several view modes e.g. a formula
can have the \LaTeX as well as the MathML view modes. 
Each view mode is identified by an id matching [a-zA-Z0-9-_]+.
In a text, a range which has several view modes is called 
a ViewRange. 

A reserved view mode called "default" must be defined for
each range. When a text is saved, all ViewRange will be 
reverted to the default mode and saved. The default mode is
always saved in the document properties and in case a module
stops responding, the text will be reverted to the default mode.

A view Mode is a Range starting with
	range.mode = "termhider"
	range.


Current implementation does not allow a document to have
intersecting ViewRanges.

###

exports.markViewRangesRegExp = (doc, regexp) ->
  

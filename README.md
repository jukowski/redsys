ShareJS Services
================

This branch of [ShareJS](https://github.com/josephg/ShareJS) adds supports
for integrating editing services into editors which are able to communicate
with ShareJS framework. 


Main idea
---------

Imagine you want [Eclipse](wwwww.eclipse.org), [jEdit](jedit.org) and 
[Ace Editor] (http://ace.ajax.org/) to be able to compile, syntax highlight
and autocomplete "CoffeeScript" files. The typical way of achieving this
is to use the extension mechanisms provided by the editors and write Editor 
dependent plugins. Note that 
 * you will need to write about 9 plugins (# of pair from 3 editors and 3 services). 
 * if and editor (jEdit for example) upgrades to a new version and 
  changes it's API you might need to update 3 of the plugins.

This is all very expensive both to develop as well as maintain....

The idea in this project is a bit different. Imagine you writing your "CoffeeScript"
in a Google Docs document. You can share this document with three friends of yours: 
"John the Coffee compiler", "Mary the Coffee Syntax Highlighter" 
and "Bob the Coffee autocompleter". When John sees some compilation error in the 
document, he will underline the parts which don't compile and underline it with red.
Mary will choose colors for each of your characters and Bob will give you autocomplete
suggestions when you need it. Now imagine jEdit, Eclipse and Ace Editor could connect 
to that Google Docs document and display the colors and underlines etc as Google Docs 
can. Then, with the help of the same three friends, you will have syntax highlighting,
compilation and autocompletion for free. 

I use ShareJS as a substritute for the Google Docs and automated services instread
of your 3 friends.

Here is a summary of the advantages of such an architecture:
 * if want to add a new editor to the architeture, you only need to integrate it
 with ShareJS and get the services for free.
 * if want to add a new service you also only need to integrate it with ShareJS 
 and it will work with any other editor.
 * if a service crashes, it does not crash your editor, you just don't get any support
 * if a service start messing with your document, you can undo to a sane state and 
 kill it.
 * a time consuming service can start computing on a certain state of the document.
   Listen to changes done while it is processing and try to integrate the results
   after computation is done. If changes done to the document are too big then it
   can decide to kill the processing. Makes Manangement of Change up to the service.


Installing and running
----------------------

Here are the steps you need to take
 * Install [NodeJS](http://nodejs.org/), [npm](http://npmjs.org/) and [coffee](http://coffeescript.org/)
 * Checkout the source code

        # git clone https://github.com/jucovschi/ShareJS/tree/services ShareJS

 * Install the dependencies

        # npm install active-x-obfuscator charm deep-equal formidable optimist socket.io tap websocket \
        browserchannel coffee-script  difflet     hat         request   socket.io-client  traverse   wordwrap \
        buffer-equal         connect        faye        nodeunit    slide     string            uglify-js  zeparser

 * Run the ShareJS server

        # cd ShareJS/bin
        # ./exampleservice

 * Open your editor at [http://localhost:8000/code_etherpad.html](http://localhost:8000/code_etherpad.html#mCANaUgfrk)
 * Run the available services at

        # cd ShareJS/src/services
        # ./runner.coffee



Supported Languages
===================

The plan is to give the possibility to write editing services in any language. 
Currently you can write realiably such services only using JavaScript. There
are two Java libraries 
  * [jShare](https://github.com/jucovschi/jShare) implements ShareJS protocol
    for Java. 
  * [jeasysync2](https://github.com/jucovschi/jeasysync2) implements the easysync2
    document type
which will soon also give possibility to write services in Java as well as supporting
Java based editors (e.g. jEdit or Eclipse)


Adding your service
===================

1. Embedded in a node.js server app:

    ```javascript
    var connect = require('connect'),
        sharejs = require('share').server;

    var server = connect(
          connect.logger(),
          connect.static(__dirname + '/my_html_files')
        );

    var options = {db: {type: 'memory'}}; // See docs for options. {type: 'redis'} to enable persistance.

    // Attach the sharejs REST and Socket.io interfaces to the server
    sharejs.attach(server, options);

    server.listen(8000);
    console.log('Server running at http://127.0.0.1:8000/');
    ```
    The above script will start up a ShareJS server on port 8000 which hosts static content from the `my_html_files` directory. See [bin/exampleserver](https://github.com/josephg/ShareJS/blob/master/bin/exampleserver) for a more complex configuration example.

    > See the [Connect](http://senchalabs.github.com/connect/) or [Express](http://expressjs.com/) documentation for more complex routing.

2. From the command line:

        # sharejs
    Configuration is pulled from a configuration file that can't be easily edited at the moment. For now, I recommend method #1 above.

3. If you are just mucking around, run:

        # sharejs-exampleserver
  
    This will run a simple server on port 8000, and host all the example code there. Run it and check out http://localhost:8000/ . The example server stores everything in ram, so don't get too attached to your data.

    > If you're running sharejs from source, you can launch the example server by running `bin/exampleserver`.


Putting Share.js on your website
--------------------------------

If you want to get a simple editor working in your webpage with sharejs, here's what you need to do:

First, get an ace editor on your page:

```html
<div id="editor"></div>
```

Your web app will need access to the following JS files:

- Ace (http://ace.ajax.org/)
- Browserchannel
- ShareJS client and ace bindings.

Add these script tags:

```html
<script src="http://ajaxorg.github.com/ace/build/src/ace.js"></script>
<script src="/channel/bcsocket.js"></script>
<script src="/share/share.js"></script>
<script src="/share/ace.js"></script>
```

And add this code:

```html
<script>
    var editor = ace.edit("editor");

    sharejs.open('hello', 'text', function(error, doc) {
        doc.attach_ace(editor);
    });
</script>
```

> **NOTE:** If you're using the current version in npm (0.4) or earler, the argument order is the other way around (`function(doc, error)`).

Thats about it :)

The easiest way to get your code running is to check sharejs out from source and put your html and css files in the `examples/` directory. Run `bin/exampleserver` to launch the demo server and browse to http://localhost:8000/your-app.html .

See the [wiki](https://github.com/josephg/ShareJS/wiki) for documentation.

Its also possible to use sharejs without ace. See the textarea example for details.

Writing a client using node.js
------------------------------

The client API is the same whether you're using the web or nodejs.

Here's an example application which opens a document and inserts some text in it. Every time an op is applied to the document, it'll print out the document's version.

Run this from a couple terminal windows when sharejs is running to see it go.

```javascript
var client = require('share').client;

// Open the 'hello' document, which should have type 'text':
client.open('hello', 'text', 'http://localhost:8000/sjs', function(error, doc) {
    // Insert some text at the start of the document (position 0):
    doc.insert("Hi there!\n", 0);

    // Get the contents of the document for some reason:
    console.log(doc.snapshot);

    doc.on('change', function(op) {
        console.log('Version: ' + doc.version);
    });

    // Close the doc if you want your node app to exit cleanly
    // doc.close();
});
```

> **NOTE:** If you're using the current version in npm (0.4) or earler, the argument order is the other way around (`function(doc, error)`).

See [`the wiki`](https://github.com/josephg/ShareJS/wiki) for API documentation, and `examples/node*` for some more example apps.



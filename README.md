RedSyS
================

RedSyS (Real-Time Document Synchronization and Service Broker) is an architecture
enabling real-time integration of editing services into editors. 

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

The idea in this project is a bit different. Imagine you're writing your "CoffeeScript"
in a Google Docs document. You can share this document with three friends of yours: 
"John the Coffee compiler", "Mary the Coffee Syntax Highlighter" 
and "Bob the Coffee autocompleter". When John sees some compilation error in the 
document, he will underline the parts which don't compile and color them in red.
Mary will choose colors for each of your Coffee-script characters and Bob will give 
you autocomplete suggestions when you need it. Furthermore, imagine jEdit, Eclipse 
and Ace Editor could connect to that Google Docs document and display the colors 
and underlines etc as Google Docs can. Then, with the help of the same three 
friends, you will have syntax highlighting, compilation and autocompletion integrated
in each of the editors -- without rewriting the services for each of the editors. 

Generally, all it takes to integrate these three, quite different editing services, is 
 * a shared document all 4 members can change (you and the 3 services)
 * some type of rich text formatting support (to change color/underline)
 * and some support for private messaging allowing for autocomplete options to be
  transported to the editor.
These are exactly the services provided by the RedSyS architecture:
 - The Shared Document editing is provided by the ShareJS project
 - Rich text formatting is provided by the Etherpad document model
 - Private messaging is yet to be defined...

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

        # git clone https://github.com/jucovschi/redsys redsys

 * Install the ShareJS (you need a specific version adding etherpad support) 

        # npm install git://github.com/jucovschi/ShareJS.git#etherpad_type

 * Install some more dependencies

        # npm install async vfs-local deep-extend express

 * Recompile sharejs
 
        # cd node_modules/share
        # cake webclient
        # cake build
        # cd ../..
        
 * Run the redsys server

        # cd bin
        # coffee redsys.coffee

 * Open your browser at [http://localhost:8002/)
 
 * Run the available services at

        # cd bin
        # coffee runner.coffee



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

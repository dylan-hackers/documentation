Module:   select-viewer-controller
Synopsis: A simple odbc-sql query viewer
Author:   Keith Playford
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

//// Parameters.

define constant $default-select-viewer-database = "Northwind";
define constant $default-select-viewer-width  = 500;
define constant $default-select-viewer-height = 250;

// F9E81C00-1350-11D2-BD36-0000C06AF1D3
define constant $select-viewer-class-id =
  make-GUID(#xF9E81C00, #x1350, #x11D2,
	    #xBD, #x36, #x00, #x00, #xC0, #x6A, #xF1, #xD3);

/*
//// Back-end protocol.

define generic open-database
    (name :: <byte-string>, user-name :: <byte-string>, password :: <byte-string>)
 => (db :: <object>);

define generic query-database
    (db :: <object>, query :: <byte-string>) 
 => (headings :: <sequence>, results :: <sequence>);

define generic close-database (db :: <object>) => ();
*/

//// Select viewer frame.

define frame <select-viewer> (<simple-frame>)
  // I don't seem to able to introspect to find this out from DUIM...
  slot columns-displayed :: <integer> = 0;
  slot select-server :: <LPDISPATCH> = $NULL-interface;
  pane file-menu (frame)
    make(<menu>,
         label: "&File",
         children:
           vector(make(<menu-button>,
                       label: "New Select Viewer",
                       activate-callback: 
                         method (#rest args)
                           spawn-select-viewer();
                         end)));
  menu-bar (frame)
    make(<menu-bar>,
         children: vector(file-menu(frame)));
  pane sql-pane (frame)
    make(<combo-box>, 
         items:             #(),
         activate-callback: sql-entry-callback);
  pane results-pane (frame)
    make(<table-control>, headings: #[], generators: #[], items: #[]);
  layout (frame)
    vertically (spacing: 2)
      make(<separator>);
      horizontally (spacing: 2, y-alignment: #"center")
        make(<label>, label: "Select"); 
        sql-pane(frame);
      end;
      make(<separator>);
      results-pane(frame);
    end;
  status-bar (frame)
    make(<status-bar>);
  keyword title:  = "Select Viewer";
  keyword width:  = $default-select-viewer-width;
  keyword height: = $default-select-viewer-height;
end frame;

define method handle-event
    (frame :: <select-viewer>, event :: <frame-mapped-event>) => ()
  next-method();
  OLE-Initialize();
  frame.select-server := create-dispatch($select-viewer-class-id);
end method;

define method handle-event
    (frame :: <select-viewer>, event :: <frame-destroyed-event>) => ()
  COM/Release(frame.select-server);
  OLE-UnInitialize();
  next-method();
end method;

define method spawn-select-viewer ()
  make-application-thread
    (function: method () start-frame(make(<select-viewer>)) end);
end method;

define constant as-byte-string :: <function> = curry(as, <byte-string>);

define method sql-entry-callback (pane :: <combo-box>) => ()
  let frame = sheet-frame(pane);
  let server = frame.select-server;
  let raw-sql-expr = gadget-value(pane);
  gadget-items(pane) := history-add(gadget-items(pane), raw-sql-expr);
  let sql-expr = concatenate("select ", raw-sql-expr);
  let data = #f;
  block ()
    data := call-simple-method(server, "open-database",
                               $default-select-viewer-database, "", "");
    let headings-then-results
      = call-simple-method(server, "query-database", data, sql-expr);
    let (headings, results) = apply(values, headings-then-results);
    results := map(curry(map, as-byte-string), results);
    headings := map(as-byte-string, headings);
    display-query-results(frame, results-pane(frame), sql-expr, headings, results);
  cleanup
    if (data) call-simple-method(server, "close-database", data) end;
  exception (c :: <error>)
    notify-user(format-to-string("%s", c), title: "Query error");
  end;
end method;

define method display-query-results
    (frame :: <select-viewer>, pane :: <table-control>, query :: <byte-string>,
       headings :: <sequence>, results :: <sequence>) 
 => ()
  // Remove the existing columns.
  for (i from columns-displayed(frame) - 1 to 0 by -1)
    remove-column(pane, i);
  end;
  columns-displayed(frame) := 0;
  if (~empty?(results))
    // Compute the new columns.
    let cols = compute-query-columns(headings);
    for (col in cols, i from 0)
      add-column(pane, col, i);
    finally
      columns-displayed(frame) := i;
    end;
    // Install the items.
    gadget-items(pane) := results;
    gadget-label(frame-status-bar(frame)) 
      := format-to-string("%d records returned for query: \"%s\"", 
                          size(results), query);
  end;
end method;

define method compute-query-columns 
    (headings :: <sequence>) => (columns :: <sequence>)
  map(method (heading, i) 
        make(<table-column>, heading: heading, generator: rcurry(element, i))
      end,
      headings, range(from: 0))
end method;

define method history-add 
    (seq :: <sequence>, entry :: <string>) => (new-seq :: <sequence>)
  // Ugly!
  let seq = remove(seq, entry, test: \=);
  pair(entry, as(<list>, seq));
end method;

// eof


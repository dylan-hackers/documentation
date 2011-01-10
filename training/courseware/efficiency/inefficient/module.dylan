Module:    dylan-user
Synopsis:  An inefficient example program.
Author:    Hugh Greene
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      See License.txt in this distribution for details.
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define module inefficient
  use finalization;
  use functional-dylan;
  use simple-format;
  use simple-random;

  // Add binding exports here.
  export loop;
end module inefficient;

#!bin/bash
cd $TRAVIS_BUILD_DIR
mix test --exclude pending --trace 
     if [ "$?" -eq 0 ]; then
     	 exit 0;
     else 
     	exit 1;
     fi;
mix coveralls.travis --exclude pending 
     if [ "$?" -eq 0 ]; then
     	 exit 0;
     else 
     	exit 1;
     fi;
mix credo --strict
     if [ "$?" -eq 0 ]; then
     	 exit 0;
     else 
     	exit 1;
     fi;
mix dogma 
     if [ "$?" -eq 0 ]; then
     	 exit 0;
     else 
     	exit 1;
     fi;
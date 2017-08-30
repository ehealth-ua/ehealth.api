cd $TRAVIS_BUILD_DIR
mix test --exclude pending --trace 
mix coveralls.travis --exclude pending 
mix credo --strict
mix dogma 
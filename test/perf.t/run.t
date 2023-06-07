  $ merl-an -r 1 -s 1 -p perf.ml --data=test-data
  bind: File exists
  merlin path: /Users/rafal/.opam/default/bin/ocamlmerlin-server
  socket path: /var/folders/99/ktsgp3fs5n5cxlw0syckw9g80000gn/T/build_ed4a66_dune/ocamlmerlin_501_16777235_51720441.socket
  merl-an: internal error, uncaught exception:
           Failure("exception while running [ocamlmerlin server -version]: End_of_file\n")
           
  [125]

  $ cat test-data/performances.json |
  > sed 's/"timings":\[[0-9]*\],/"timings":x,/' |
  > sed 's/"max_timing":[0-9]*,/"max_timing":x,/' |
  > sed 's/"file":".*\/test\/perf\.t\/perf\.ml",/"file":x,/' |
  > sed 's/"loc":"File.*",/"loc":x,/'
  cat: test-data/performances.json: No such file or directory

  $ cat test-data/commands.json |
  > sed 's/-filename.*",/-filename x",/'
  cat: test-data/commands.json: No such file or directory

  $ cat test-data/query_responses.json |
  > sed 's/"clock":[0-9]*,/"clock":x,/' |
  > sed 's/"cpu":[0-9]*,/"cpu":x,/' |
  > sed 's/"query":[0-9]*,/"query":x,/' |
  > sed 's/"reader":[0-9]*,/"reader":x,/' |
  > sed 's/"typer":[0-9]*,/"typer":x,/' |
  > sed 's/"error":[0-9]*/"error":x/'
  cat: test-data/query_responses.json: No such file or directory

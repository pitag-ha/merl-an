  $ merl-an -r 1 -s 1 -p perf.ml --data=test-data

  $ cat test-data/performances.json |
  > sed 's/"timings":\[[0-9]*\],/"timings":x,/' |
  > sed 's/"max_timing":[0-9]*,/"max_timing":x,/' |
  > sed 's/"file":".*\/test\/perf\.t\/perf\.ml",/"file":x,/' |
  > sed 's/"loc":"File.*",/"loc":x,/'
  {"sample_id":6,"timings":x,"max_timing":x,"file":x,"merlin_id":1,"query_type":["Errors"],"loc":x, line 1, characters -1--1:"}
  {"sample_id":6,"timings":x,"max_timing":x,"file":x,"merlin_id":0,"query_type":["Errors"],"loc":x, line 1, characters -1--1:"}
  {"sample_id":1,"timings":x,"max_timing":x,"file":x,"merlin_id":1,"query_type":["Type_enclosing"],"loc":x, line 1, characters 8-9:"}
  {"sample_id":1,"timings":x,"max_timing":x,"file":x,"merlin_id":0,"query_type":["Type_enclosing"],"loc":x, line 1, characters 8-9:"}
  {"sample_id":0,"timings":x,"max_timing":x,"file":x,"merlin_id":1,"query_type":["Case_analysis"],"loc":x, line 1, characters 8-9:"}
  {"sample_id":0,"timings":x,"max_timing":x,"file":x,"merlin_id":0,"query_type":["Case_analysis"],"loc":x, line 1, characters 8-9:"}

  $ cat test-data/commands.json |
  > sed 's/-filename.*",/-filename x",/'
  {"sample_id":6,"cmd":"ocamlmerlin single errors -filename x","merlin_id":1}
  {"sample_id":6,"cmd":"ocamlmerlin server errors -filename x","merlin_id":0}
  {"sample_id":1,"cmd":"ocamlmerlin single type-enclosing -position '1:8' -filename x","merlin_id":1}
  {"sample_id":1,"cmd":"ocamlmerlin server type-enclosing -position '1:8' -filename x","merlin_id":0}
  {"sample_id":0,"cmd":"ocamlmerlin single case-analysis -start '1:8' -end '1:8' -filename x","merlin_id":1}
  {"sample_id":0,"cmd":"ocamlmerlin server case-analysis -start '1:8' -end '1:8' -filename x","merlin_id":0}

  $ cat test-data/query_responses.json |
  > sed 's/"clock":[0-9]*,/"clock":x,/' |
  > sed 's/"cpu":[0-9]*,/"cpu":x,/' |
  > sed 's/"query":[0-9]*,/"query":x,/' |
  > sed 's/"reader":[0-9]*,/"reader":x,/' |
  > sed 's/"typer":[0-9]*,/"typer":x,/' |
  > sed 's/"error":[0-9]*/"error":x/'
  {"sample_id":6,"responses":[{"class":"return","notifications":[],"timing":{"clock":x,"cpu":x,"query":x,"pp":0,"reader":x,"ppx":0,"typer":x,"error":x}}],"merlin_id":1}
  {"sample_id":6,"responses":[{"class":"return","notifications":[],"timing":{"clock":x,"cpu":x,"query":x,"pp":0,"reader":x,"ppx":0,"typer":x,"error":x}}],"merlin_id":0}
  {"sample_id":1,"responses":[{"class":"return","notifications":[],"timing":{"clock":x,"cpu":x,"query":x,"pp":0,"reader":x,"ppx":0,"typer":x,"error":x}}],"merlin_id":1}
  {"sample_id":1,"responses":[{"class":"return","notifications":[],"timing":{"clock":x,"cpu":x,"query":x,"pp":0,"reader":x,"ppx":0,"typer":x,"error":x}}],"merlin_id":0}
  {"sample_id":0,"responses":[{"class":"return","notifications":[],"timing":{"clock":x,"cpu":x,"query":x,"pp":0,"reader":x,"ppx":0,"typer":x,"error":x}}],"merlin_id":1}
  {"sample_id":0,"responses":[{"class":"return","notifications":[],"timing":{"clock":x,"cpu":x,"query":x,"pp":0,"reader":x,"ppx":0,"typer":x,"error":x}}],"merlin_id":0}

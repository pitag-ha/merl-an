  $ merl-an -r 1 -s 1 -p files/nested-dir/perf.ml --data=test-data

  $ cat test-data/performances.json |
  > jq -c '.timings |= 0
  > | .max_timing |= 0'
  {"sample_id":6,"timings":0,"max_timing":0,"file":"files/nested-dir/perf.ml","merlin_id":1,"query_type":["Errors"],"loc":"File \"_none_\", line 1, characters -1--1:"}
  {"sample_id":6,"timings":0,"max_timing":0,"file":"files/nested-dir/perf.ml","merlin_id":0,"query_type":["Errors"],"loc":"File \"_none_\", line 1, characters -1--1:"}
  {"sample_id":1,"timings":0,"max_timing":0,"file":"files/nested-dir/perf.ml","merlin_id":1,"query_type":["Type_enclosing"],"loc":"File \"files/nested-dir/perf.ml\", line 1, characters 8-9:"}
  {"sample_id":1,"timings":0,"max_timing":0,"file":"files/nested-dir/perf.ml","merlin_id":0,"query_type":["Type_enclosing"],"loc":"File \"files/nested-dir/perf.ml\", line 1, characters 8-9:"}
  {"sample_id":0,"timings":0,"max_timing":0,"file":"files/nested-dir/perf.ml","merlin_id":1,"query_type":["Case_analysis"],"loc":"File \"files/nested-dir/perf.ml\", line 1, characters 8-9:"}
  {"sample_id":0,"timings":0,"max_timing":0,"file":"files/nested-dir/perf.ml","merlin_id":0,"query_type":["Case_analysis"],"loc":"File \"files/nested-dir/perf.ml\", line 1, characters 8-9:"}

  $ cat test-data/commands.json
  {"sample_id":6,"cmd":"ocamlmerlin single errors -filename files/nested-dir/perf.ml < files/nested-dir/perf.ml","merlin_id":1}
  {"sample_id":6,"cmd":"ocamlmerlin server errors -filename files/nested-dir/perf.ml < files/nested-dir/perf.ml","merlin_id":0}
  {"sample_id":1,"cmd":"ocamlmerlin single type-enclosing -position '1:8' -index 0 -filename files/nested-dir/perf.ml < files/nested-dir/perf.ml","merlin_id":1}
  {"sample_id":1,"cmd":"ocamlmerlin server type-enclosing -position '1:8' -index 0 -filename files/nested-dir/perf.ml < files/nested-dir/perf.ml","merlin_id":0}
  {"sample_id":0,"cmd":"ocamlmerlin single case-analysis -start '1:8' -end '1:8' -filename files/nested-dir/perf.ml < files/nested-dir/perf.ml","merlin_id":1}
  {"sample_id":0,"cmd":"ocamlmerlin server case-analysis -start '1:8' -end '1:8' -filename files/nested-dir/perf.ml < files/nested-dir/perf.ml","merlin_id":0}

  $ cat test-data/query_responses.json |
  > jq -c '.responses |= map (.timing |=
  > (.clock |= 0
  > | .cpu |= 0
  > | .query |= 0
  > | .reader |= 0
  > | .typer |= 0
  > | .error |= 0)
  > )'
  {"sample_id":6,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":1}
  {"sample_id":6,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":1,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":1}
  {"sample_id":1,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":0,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":1}
  {"sample_id":0,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}

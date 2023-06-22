TODO     stderr:
/bin/sh: -c: line 0: syntax error near unexpected token `('
/bin/sh: -c: line 0: `ocamlmerlin server complete-prefix -prefix ( + -position '3:12' -filename /Users/rafal/Projects/Tarides/merl-an/_build/default/test/error_regression.t/test.ml < /Users/rafal/Projects/Tarides/merl-an/_build/default/test/error_regression.t/test.ml'
/bin/sh: -c: line 0: syntax error near unexpected token `('
/bin/sh: -c: line 0: `ocamlmerlin server expand-prefix -prefix ( + -position '3:12' -filename /Users/rafal/Projects/Tarides/merl-an/_build/default/test/error_regression.t/test.ml < /Users/rafal/Projects/Tarides/merl-an/_build/default/test/error_regression.t/test.ml'

  $ merl-an error-regression -s 1 -p test.ml --data=test-data 2>/dev/null

  $ cat test-data/results.json
  {"sample_id":6,"merlin_id":0,"success":true}
  {"sample_id":5,"merlin_id":0,"success":true}
  {"sample_id":2,"merlin_id":0,"success":true}
  {"sample_id":1,"merlin_id":0,"success":true}
  {"sample_id":0,"merlin_id":0,"success":true}

  $ merl-an error-regression -s 1 -p test.ml,test1.ml --data=test-data

  $ cat test-data/results.json
  {"sample_id":13,"cmd":"ocamlmerlin server errors -filename test1.ml < test1.ml","success":true}
  {"sample_id":12,"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test1.ml < test1.ml","success":true}
  {"sample_id":11,"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml","success":true}
  {"sample_id":10,"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml","success":true}
  {"sample_id":9,"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test1.ml < test1.ml","success":true}
  {"sample_id":8,"cmd":"ocamlmerlin server type-enclosing -position '1:8' -index 0 -filename test1.ml < test1.ml","success":true}
  {"sample_id":7,"cmd":"ocamlmerlin server case-analysis -start '1:8' -end '1:8' -filename test1.ml < test1.ml","success":true}
  {"sample_id":6,"cmd":"ocamlmerlin server errors -filename test.ml < test.ml","success":true}
  {"sample_id":5,"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test.ml < test.ml","success":true}
  {"sample_id":4,"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml","success":true}
  {"sample_id":3,"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml","success":true}
  {"sample_id":2,"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test.ml < test.ml","success":true}
  {"sample_id":1,"cmd":"ocamlmerlin server type-enclosing -position '3:12' -index 0 -filename test.ml < test.ml","success":true}
  {"sample_id":0,"cmd":"ocamlmerlin server case-analysis -start '3:14' -end '3:14' -filename test.ml < test.ml","success":true}

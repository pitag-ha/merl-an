  $ merl-an behavior -s 1 -p test.ml,test1.ml --data=test-data

  $ cat test-data/return_classes.json
  {"sample_id":13,"return":["Return",["Other"]],"cmd":"ocamlmerlin server errors -filename test1.ml < test1.ml"}
  {"sample_id":12,"return":["Return",["Other"]],"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test1.ml < test1.ml"}
  {"sample_id":11,"return":["Return",["Other"]],"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml"}
  {"sample_id":10,"return":["Return",["Other"]],"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml"}
  {"sample_id":9,"return":["Return",["Other"]],"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test1.ml < test1.ml"}
  {"sample_id":8,"return":["Return",["Other"]],"cmd":"ocamlmerlin server type-enclosing -position '1:8' -index 0 -filename test1.ml < test1.ml"}
  {"sample_id":7,"return":["Return",["Other"]],"cmd":"ocamlmerlin server case-analysis -start '1:8' -end '1:8' -filename test1.ml < test1.ml"}
  {"sample_id":6,"return":["Return",["Other"]],"cmd":"ocamlmerlin server errors -filename test.ml < test.ml"}
  {"sample_id":5,"return":["Return",["Other"]],"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test.ml < test.ml"}
  {"sample_id":4,"return":["Return",["Other"]],"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml"}
  {"sample_id":3,"return":["Return",["Other"]],"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml"}
  {"sample_id":2,"return":["Return",["Other"]],"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test.ml < test.ml"}
  {"sample_id":1,"return":["Return",["Other"]],"cmd":"ocamlmerlin server type-enclosing -position '3:12' -index 0 -filename test.ml < test.ml"}
  {"sample_id":0,"return":["Return",["Other"]],"cmd":"ocamlmerlin server case-analysis -start '3:14' -end '3:14' -filename test.ml < test.ml"}

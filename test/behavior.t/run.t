  $ merl-an behavior -s 1 -p test.ml,test1.ml --data=test-data

  $ cat test-data/category_data.json
  {"sample_id":13,"return":["Return",["Other"]],"query_num":13,"cmd":"ocamlmerlin server errors -filename test1.ml < test1.ml"}
  {"sample_id":12,"return":["Return",["Other"]],"query_num":12,"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test1.ml < test1.ml"}
  {"sample_id":11,"return":["Return",["Other"]],"query_num":11,"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml"}
  {"sample_id":10,"return":["Return",["Other"]],"query_num":10,"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test1.ml < test1.ml"}
  {"sample_id":9,"return":["Return",["Other"]],"query_num":9,"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test1.ml < test1.ml"}
  {"sample_id":8,"return":["Return",["Other"]],"query_num":8,"cmd":"ocamlmerlin server type-enclosing -position '1:8' -index 0 -filename test1.ml < test1.ml"}
  {"sample_id":7,"return":["Return",["Other"]],"query_num":7,"cmd":"ocamlmerlin server case-analysis -start '1:8' -end '1:8' -filename test1.ml < test1.ml"}
  {"sample_id":6,"return":["Return",["Other"]],"query_num":6,"cmd":"ocamlmerlin server errors -filename test.ml < test.ml"}
  {"sample_id":5,"return":["Return",["Other"]],"query_num":5,"cmd":" ocamlmerlin server locate -look-for ml -position '3:12' -filename test.ml < test.ml"}
  {"sample_id":4,"return":["Return",["Other"]],"query_num":4,"cmd":"ocamlmerlin server expand-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml"}
  {"sample_id":3,"return":["Return",["Other"]],"query_num":3,"cmd":"ocamlmerlin server complete-prefix -prefix '( +' -position '3:12' -filename test.ml < test.ml"}
  {"sample_id":2,"return":["Return",["Other"]],"query_num":2,"cmd":"ocamlmerlin server occurrences -identifier-at '3:12' -filename test.ml < test.ml"}
  {"sample_id":1,"return":["Return",["Other"]],"query_num":1,"cmd":"ocamlmerlin server type-enclosing -position '3:12' -index 0 -filename test.ml < test.ml"}
  {"sample_id":0,"return":["Return",["Other"]],"query_num":0,"cmd":"ocamlmerlin server case-analysis -start '3:14' -end '3:14' -filename test.ml < test.ml"}

(* FIXME: This is a problem in all tests: The build artefacts aren't found.*)
  $ cat test-data/full_responses.json | sed "/No config found for file/d"
  {"sample_id":12,"responses":[{"class":"return","value":{"file":"stdlib.ml","pos":{"line":94,"col":0}},"notifications":[],"query_num":12}]}
  {"sample_id":11,"responses":[{"class":"return","value":{"entries":[{"name":"()","kind":"Constructor","desc":"","info":"","deprecated":false}],"context":null},"notifications":[],"query_num":11}]}
  {"sample_id":10,"responses":[{"class":"return","value":{"entries":[],"context":["application",{"argument_type":"'a","labels":[]}]},"notifications":[],"query_num":10}]}
  {"sample_id":9,"responses":[{"class":"return","value":[{"start":{"line":3,"col":12},"end":{"line":3,"col":13}}],"notifications":[],"query_num":9}]}
  {"sample_id":8,"responses":[{"class":"return","value":[{"start":{"line":1,"col":8},"end":{"line":1,"col":9},"type":"int","tail":"no"}],"notifications":[],"query_num":8}]}
  {"sample_id":7,"responses":[{"class":"return","value":[{"start":{"line":1,"col":8},"end":{"line":1,"col":9}},"match 1 with | 0 -> _ | _ -> _"],"notifications":[],"query_num":7}]}
  {"sample_id":5,"responses":[{"class":"return","value":{"file":"stdlib.ml","pos":{"line":94,"col":0}},"notifications":[],"query_num":5}]}
  {"sample_id":4,"responses":[{"class":"return","value":{"entries":[{"name":"()","kind":"Constructor","desc":"","info":"","deprecated":false}],"context":null},"notifications":[],"query_num":4}]}
  {"sample_id":3,"responses":[{"class":"return","value":{"entries":[],"context":["application",{"argument_type":"'a","labels":[]}]},"notifications":[],"query_num":3}]}
  {"sample_id":2,"responses":[{"class":"return","value":[{"start":{"line":3,"col":12},"end":{"line":3,"col":13}}],"notifications":[],"query_num":2}]}
  {"sample_id":1,"responses":[{"class":"return","value":[{"start":{"line":3,"col":12},"end":{"line":3,"col":13},"type":"int -> int -> int","tail":"no"},{"start":{"line":3,"col":10},"end":{"line":3,"col":15},"type":1,"tail":"no"},{"start":{"line":3,"col":6},"end":{"line":3,"col":15},"type":2,"tail":"no"}],"notifications":[],"query_num":1}]}
  {"sample_id":0,"responses":[{"class":"return","value":[{"start":{"line":3,"col":14},"end":{"line":3,"col":15}},"(match 3 with | 0 -> _ | _ -> _)"],"notifications":[],"query_num":0}]}

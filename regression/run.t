  $ git clone https://github.com/mirage/irmin.git > /dev/null

  $ cd irmin

  $ opam install . --deps-only --with-test -y > /dev/null
  
  $ dune build > /dev/null

  $ merl-an error-regression -s 1 --data=test-data 2> /dev/null

  $ cat test-data/results.json
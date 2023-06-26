  $ git clone https://github.com/mirage/irmin.git

  $ cd irmin

  $ opam install . --deps-only --with-test -y
  
  $ dune build

  $ merl-an regression -s 1 --data=test-data

  $ cat test-data/results.json
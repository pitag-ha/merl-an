(lang dune 3.2)

(name merl-an)

(cram enable)
(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name")

(maintainers "Maintainer Name")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name merl-an)
 (synopsis "Generates data to analyze merlin")
 (description "A longer description")
 (depends
  ocaml
  dune
  ppxlib
  yojson
  fpath
  bos
  cmdliner
  ppx_deriving_yojson
  ppx_enumerate
  ppx_fields_conv
  (ppx_yojson_conv (<= v0.15.1))
  ptime)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project

# Merl-an

> Tool for [merlin](https://github.com/ocaml/merlin) performance analysis.

Merl-an generates queries to analyze [merlin](https://github.com/ocaml/merlin)
performance and behavior, executes them and gathers the results.

> For each ml and/or mli file in the project, a random (but deterministic) sample set of locations is generated. The different merlin queries are then run on those samples. The analysis results are dumped into json-line files.

## How to use merl-an

### Merl-an inputs
To best use merl-an, it's important to know what it expects as input:

Some of the most common flags you will use with merl-an include:
- `-p, --project`: the paath to the project directory or files to analyze. The default is the current working directory.
- `-m, --merlin`: the path to the `ocamlmerlin` binary.
- `--data`: the directory where merl-an's output files will be stored.
- `-s, --per-file-samples`: the number of sample locations to query per file, by default, this value will be 10.
- `-q, --queries`: tf you will like to run specific query types, you can pass them here comma-separated. The defaul runs all the query types.
- `-r, --repeats`: this is how many times to repeat each query per sample to measure variance. The default value will be 10.
- `--cache`: the caching mechanism to simulate, such as `full-cache` or `no-cache`.

**Note**: for all flags checkout the manpage: `merl-an --help`.

### Merl-an outputs

The results of merl-an are organized inside the following files: 

- `commands.json`: this contains the exact `ocamlmerlin` commands executed for each query.
- `query_responses.json`: this contains the responses returned by merlin for each query sample.
- `distilled_data.json` (*behavior only*): distilled summary of responses for easy diffing.
- `performances.json` (*performance only*): latency timings, sample IDs, query types, and source locations.
- `bench.json` (*benchmarking only*): structured timing metrics.
- `metadata.json`: metadata.
- `logs.json`: warnings or errors encountered during the run.

### Merl-an modes
Merl-an has 3 main usage modes: for behavioural analysis, for performance analysis and for benchmarking.

#### a. Performance

We use this to measure latency, query execution times, and cache hit/miss rates across queries. It preserves detailed timing components and allows us to run repeated queries on each sample to measure the variance.

**Note**: Performance is also the default command merl-an will run if you don't specify another. Also, always ensure to build your project before running merl-an againts it, as merl-an requires the build artificats.

- Example

```sh
merl-an performance -p src/ -q type-enclosing -s 5 -r 3
```

#### b. Behaviour

We use this mode to test whether changes to merlin modify its responses. It is very useful way to check for regressions between two merlin versions.

- Example

Assuming we have two merlin branches; A and B,

```sh

merl-an behavior --merlin=/path/to/ocamlmerlin-branch-A -p /path/to/project --data=data-A

merl-an behavior --merlin=/path/to/ocamlmerlin-branch-B -p /path/to/project --data=data-B
```

With both outputs, you can then diff them to see if there are any changes:

```sh
diff -u data-A/distilled_data.json data-B/distilled_data.json
```

#### c. Benchmarking

Used for benchmarking. It runs queries aggregates the results into a benchmark summary.

- Example

```shell
merl-an benchmark -p src/ -s 5 -r 5 --data=output
```

## Caching modes

The `--cache` flag simulates different cache mechanisms:

- `full-cache` (*default*): warms the typing and caches before measuring.
- `no-cache`: simulates a cold start where a file is opened and queried for the first time without cached data.

## Local development

Since **merl-an** streamlines Merlin's main trunk, we recommend building a local
switch and manually adding the dependency to Merlin:

```shell
opam update
opam switch create . --deps-only --with-doc --with-test --with-dev-setup -y
eval $(opam env)
dune build
```

## Contributing
Please feel free to open issues if you find some buggy behaviour and if you can code, you are also welcomed to submit Pr's.

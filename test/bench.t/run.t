  $ merl-an benchmark -s 2 -p bench.ml --data=test-data

  $ jq '.results |= map( map(.value=0))' test-data/bench.json
  {
    "name": "Merlin benchmark",
    "results": [
      [
        {
          "name": "case-analysis",
          "value": 0,
          "units": "ms",
          "description": "1",
          "trend": null
        },
        {
          "name": "case-analysis",
          "value": 0,
          "units": "ms",
          "description": "0",
          "trend": null
        }
      ],
      [
        {
          "name": "complete-prefix",
          "value": 0,
          "units": "ms",
          "description": "7",
          "trend": null
        },
        {
          "name": "complete-prefix",
          "value": 0,
          "units": "ms",
          "description": "6",
          "trend": null
        }
      ],
      [
        {
          "name": "errors",
          "value": 0,
          "units": "ms",
          "description": "12",
          "trend": null
        }
      ],
      [
        {
          "name": "expand-prefix",
          "value": 0,
          "units": "ms",
          "description": "9",
          "trend": null
        },
        {
          "name": "expand-prefix",
          "value": 0,
          "units": "ms",
          "description": "8",
          "trend": null
        }
      ],
      [
        {
          "name": "locate",
          "value": 0,
          "units": "ms",
          "description": "11",
          "trend": null
        },
        {
          "name": "locate",
          "value": 0,
          "units": "ms",
          "description": "10",
          "trend": null
        }
      ],
      [
        {
          "name": "occurrences",
          "value": 0,
          "units": "ms",
          "description": "5",
          "trend": null
        },
        {
          "name": "occurrences",
          "value": 0,
          "units": "ms",
          "description": "4",
          "trend": null
        }
      ],
      [
        {
          "name": "type-enclosing",
          "value": 0,
          "units": "ms",
          "description": "3",
          "trend": null
        },
        {
          "name": "type-enclosing",
          "value": 0,
          "units": "ms",
          "description": "2",
          "trend": null
        }
      ]
    ]
  }

  $ cat test-data/query_responses.json
  {"sample_id":12,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":11,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":10,"responses":[{"class":"return","notifications":[],"timing":{"clock":1,"cpu":1,"query":0,"pp":0,"reader":0,"ppx":0,"typer":1,"error":0}}],"merlin_id":0}
  {"sample_id":9,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":8,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":7,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":6,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":5,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":4,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":3,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":2,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":1,"responses":[{"class":"error","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}
  {"sample_id":0,"responses":[{"class":"return","notifications":[],"timing":{"clock":0,"cpu":0,"query":0,"pp":0,"reader":0,"ppx":0,"typer":0,"error":0}}],"merlin_id":0}

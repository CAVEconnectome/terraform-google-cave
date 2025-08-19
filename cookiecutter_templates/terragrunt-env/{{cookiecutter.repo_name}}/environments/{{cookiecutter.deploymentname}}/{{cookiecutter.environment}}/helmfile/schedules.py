[
  {
    "name": "Materialized Database Daily (2 Days)",
    "minute": 10,
    "hour": 8,
    "day_of_week": [0,1,2,3,4,5,6],
    "task": "run_periodic_materialization",
    "datastack_params": {
      "days_to_expire": 2,
      "merge_tables": False,
      "datastack": "{{ cookiecutter.materialize_datastack }}"
    }
  },
  {
    "name": "Remove Expired Databases (Midnight)",
    "minute": 0,
    "hour": 8,
    "task": "remove_expired_databases",
    "datastack_params" : {
      "delete_threshold": 3,
      "datastack": "{{ cookiecutter.materialize_datastack }}"
    }
  },
  {
    "name": "Update Live Database",
    "minute": 0,
    "hour": "0-1,17-23",
    "day_of_week": "0-6",
    "task": "run_periodic_database_update",
    "datastack_params": {
      "datastack": "{{ cookiecutter.materialize_datastack }}"
    }
  }
]

# work_schedule
## Problem description
A worker has flexible scheduling at their workplace: every week, they request their off days and preferred time slots, then they get their approved schedule. A day's work can start and end at any time during the day. The worker wants to store their schedule in a program.

## Solution steps
- [x] SQLite table with `date`, `start_hour` and `end_hour` values
- [x] CRUD-like methods to update the DB
  - [x] one method to create/update
  - [x] one method to get a stored value
- [ ] API endpoints (with `wisp`)
- [ ] Frontend (`js` or `lustre`) 

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

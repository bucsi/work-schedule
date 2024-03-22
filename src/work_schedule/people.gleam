import work_schedule/web.{type Context}
import gleam/dynamic.{type Dynamic}
import gleam/http.{Get, Post}
import gleam/json
import gleam/dict
import gleam/result.{try}
import sqlight
import wisp.{type Request, type Response}

// This request handler is used for requests to `/people`.
//
pub fn all(req: Request, ctx: Context) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Get -> list_people(ctx)
    Post -> create_person(req, ctx)
    _ -> wisp.method_not_allowed([Get, Post])
  }
}

// This request handler is used for requests to `/people/:id`.
//
pub fn one(req: Request, ctx: Context, id: String) -> Response {
  // Dispatch to the appropriate handler based on the HTTP method.
  case req.method {
    Get -> read_person(ctx, id)
    _ -> wisp.method_not_allowed([Get])
  }
}

// This handler returns a list of all the people in the database, in JSON
// format.
//
pub fn list_people(ctx: Context) -> Response {
  let result = {
    // Get all the ids from the database.
    let ids = ["aaa", "bbb", "ccc"]

    // Convert the ids into a JSON array of objects.
    Ok(
      json.to_string_builder(
        json.object([
          #(
            "people",
            json.array(ids, fn(id) { json.object([#("id", json.string(id))]) }),
          ),
        ]),
      ),
    )
  }

  case result {
    // When everything goes well we return a 200 response with the JSON.
    Ok(json) -> wisp.json_response(json, 200)

    // In a later example we will see how to return specific errors to the user
    // depending on what went wrong. For now we will just return a 500 error.
    Error(Nil) -> wisp.internal_server_error()
  }
}

pub type Person {
  Person(name: String, favourite_colour: String)
}

pub fn create_person(req: Request, ctx: Context) -> Response {
  // Read the JSON from the request body.
  use json <- wisp.require_json(req)

  let result = {
    // Decode the JSON into a Person record.
    use person <- try(decode_person(json))

    // Save the person to the database.
    use id <- try(save_to_database(ctx.db, person))

    // Construct a JSON payload with the id of the newly created person.
    Ok(json.to_string_builder(json.object([#("id", json.string(id))])))
  }

  // Return an appropriate response depending on whether everything went well or
  // if there was an error.
  case result {
    Ok(json) -> wisp.json_response(json, 201)
    Error(Nil) -> wisp.unprocessable_entity()
  }
}

pub fn read_person(ctx: Context, id: String) -> Response {
  let result = {
    // Construct a JSON payload with the person's details.
    Ok(
      json.to_string_builder(
        json.object([
          #("id", json.string("aaa")),
          #("name", json.string("John")),
          #("favourite-colour", json.string("Green")),
        ]),
      ),
    )
  }

  // Return an appropriate response.
  case result {
    Ok(json) -> wisp.json_response(json, 200)
    Error(Nil) -> wisp.not_found()
  }
}

fn decode_person(json: Dynamic) -> Result(Person, Nil) {
  let decoder =
    dynamic.decode2(
      Person,
      dynamic.field("name", dynamic.string),
      dynamic.field("favourite-colour", dynamic.string),
    )
  let result = decoder(json)

  // In this example we are not going to be reporting specific errors to the
  // user, so we can discard the error and replace it with Nil.
  result
  |> result.nil_error
}

/// Save a person to the database and return the id of the newly created record.
pub fn save_to_database(
  db: sqlight.Connection,
  person: Person,
) -> Result(String, Nil) {
  // In a real application you might use a database client with some SQL here.
  // Instead we create a simple dict and save that.
  let data =
    dict.from_list([
      #("name", person.name),
      #("favourite-colour", person.favourite_colour),
    ])

  Ok("aaa")
}

pub fn read_from_database(
  db: sqlight.Connection,
  id: String,
) -> Result(Person, Nil) {
  // In a real application you might use a database client with some SQL here.
  let data = dict.from_list([#("name", "John"), #("favourite-colour", "Green")])
  use name <- try(dict.get(data, "name"))
  use favourite_colour <- try(dict.get(data, "favourite-colour"))
  Ok(Person(name, favourite_colour))
}

# Vienna

Vienna is an experimental programming language built in Zig.

Below is an example of the language showcasing it's features and syntax:

```
// Constants
const PORT = 3000;
const MAX_USERS = 100;

// Struct with methods
struct User {
  id: int;
  name: string;
  email: Optional<string>;
  isActive: bool;

  func new(id: int, name: string) -> User {
    return User{
      id: id,
      name: name,
      email: null,
      isActive: true
    };
  }

  func fullName(self) -> string {
    return self.name;
  }

  func updateEmail(self, email: string) -> void {
    self.email = email;
  }

  func deactivate(self) -> void {
    self.isActive = false;
  }
}

// Database simulation
struct Database {
  users: JSON;

  func new() -> Database {
    return Database{
      users: JSON.object()
    };
  }

  func findUser(self, id: int) -> Result<User, Error> {
    var user = self.users.get(id);
    if user == null {
      return Err(Error("User not found"));
    }
    return Ok(user);
  }

  func createUser(self, name: string, email: Optional<string>) -> Result<User, Error> {
    var id = self.users.length() + 1;
    var user = User.new(id, name);
    user.email = email;
    self.users.set(id, user);
    return Ok(user);
  }
}

// Global database instance
var db = Database.new();

// Handler functions
func handleGetUser(req: Request) -> Result<Response, Error> {
  var idResult = req.params.get("id");
  if idResult.isErr() {
    return Err(idResult.error());
  }
  var id = idResult.value();

  var userResult = db.findUser(id);
  if userResult.isErr() {
    return Err(userResult.error());
  }
  var user = userResult.value();

  return Ok(Response.json(200, user));
}

func handleCreateUser(req: Request) -> Result<Response, Error> {
  var bodyResult = req.body.json();
  if bodyResult.isErr() {
    return Err(Error("Invalid JSON"));
  }
  var data = bodyResult.value();

  var name = data.get("name");
  var email = data.get("email");

  var userResult = db.createUser(name, email);
  if userResult.isErr() {
    return Err(userResult.error());
  }
  var user = userResult.value();

  return Ok(Response.json(201, user));
}

func handleUpdateUser(req: Request) -> Result<Response, Error> {
  var idResult = req.params.get("id");
  if idResult.isErr() {
    return Err(idResult.error());
  }
  var id = idResult.value();

  var userResult = db.findUser(id);
  if userResult.isErr() {
    return Err(userResult.error());
  }
  var user = userResult.value();

  var bodyResult = req.body.json();
  if bodyResult.isErr() {
    return Err(Error("Invalid JSON"));
  }
  var data = bodyResult.value();

  // Update fields
  var newName = data.get("name");
  if newName != null {
    user.name = newName;
  }

  var newEmail = data.get("email");
  if newEmail != null {
    user.updateEmail(newEmail);
  }

  return Ok(Response.json(200, user));
}

func handleDeleteUser(req: Request) -> Result<Response, Error> {
  var idResult = req.params.get("id");
  if idResult.isErr() {
    return Err(idResult.error());
  }
  var id = idResult.value();

  var userResult = db.findUser(id);
  if userResult.isErr() {
    return Err(userResult.error());
  }
  var user = userResult.value();

  user.deactivate();

  return Ok(Response.json(204, null));
}

func handleListUsers(req: Request) -> Result<Response, Error> {
  var queryResult = req.query.get("active");
  var filterActive = false;

  if queryResult.isOk() {
    var activeValue = queryResult.value();
    if activeValue == "true" {
      filterActive = true;
    }
  }

  // Return all users or filtered
  return Ok(Response.json(200, db.users));
}

// Main application
func main() -> void {
  var app = Server.new();

  // Register routes
  app.get("/users", handleListUsers);
  app.get("/users/:id", handleGetUser);
  app.post("/users", handleCreateUser);
  app.put("/users/:id", handleUpdateUser);
  app.delete("/users/:id", handleDeleteUser);

  // Start server
  app.listen(PORT);
}
```

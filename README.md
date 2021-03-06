# Based on Skelpo's User Manager Service

### Additional Resources
- [Tutorial: How to build Web Auth with Session](https://medium.com/@martinlasek/tutorial-how-to-build-web-auth-with-session-f9f64ba49830)
- [Quickstart: Compose and WordPress](https://docs.docker.com/compose/wordpress/)
- [Docker Compose and App Deployment with MySQL](https://mysqlrelease.com/2017/11/docker-compose-and-app-deployment-with-mysql/)
- [Simple example with docker-compose](https://riptutorial.com/mysql/example/15570/simple-example-with-docker-compose)
- [How to Create a MySql Instance with Docker Compose](https://medium.com/@chrischuck35/how-to-create-a-mysql-instance-with-docker-compose-1598f3cc1bee)
- [Composing the Stack - Simplify Docker Deployment of MySQL Containers](https://severalnines.com/database-blog/composing-stack-simplify-docker-deployment-mysql-containers)
- [Integrating a MySQL Docker container with Docker Compose](https://www.atomicwriting.com/2017/10/01/mysql-container-and-docker-compose/)
- [PostgreSQL vs. MySQL](https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-vs-mysql/)
- [Tutorial: How to build Web Auth with Session](https://medium.com/@martinlasek/tutorial-how-to-build-web-auth-with-session-f9f64ba49830)

### Other User MicroService Examples
- [Typescript - OOTH](https://nmaro.github.io/ooth/)
- [Scala](https://github.com/faubertin/scala-play-rest-example)
- [Go](https://github.com/microservices-demo/user)
- [Python](https://github.com/testdrivenio/flask-microservices-users)

---
# Skelpo User Manager Service

The Skelpo User Service is an application micro-service written using Swift and Vapor, a server side Swift framework. This micro-service can be integrated into most applications to handle the app's users and authentication. It is designed to be easily customizable, whether that is adding additional data points to the user, getting more data with the authentication payload, or creating more routes.

Please note: This is not a project that you should just use _out-of-the-box_. Rather it should serve as a template in your own custom micro-service infrastructure. You may be able to use the service _as is_ for your project, but by no means expect it to cover everything you want by default.

## Getting Started

### MySQL

Clone down the repo and create a MySQL database called `service_users`:

```bash
~$ mysql -u root -p
Enter password:
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 138
Server version: 5.7.21 Homebrew

Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> CREATE DATABASE service_users;
```

Any of the values for the database configuration can be modified as desired.

The configuration for the database use environment variables for the credentials, name, and host of the database:

- `DATABASE_HOSTNAME`: The host of the service. If you are running MySQL locally, this will most likely be `localhost`.
- `DATABASE_USER`: The owner of the database, most likely `root` or your user.
- `DATABASE_PASSWORD` The password for the database. If you don't have a password for the database, you don't need to create this env var.
- `DATABASE_DB`: The name of the database.

The names of the environment variables are the same ones used by Vapor Cloud, so you should be able to connect to a hosted database without an issue.

### JWT

You will also need to create an environment variable named `JWT_PUBLIC` with the `n` value of the JWK to verify access tokens. This service also signs the access tokens, so you will need another environment variable (called `JWT_SECRET` by default, but that can be changed) that contains the `d` value of the JWK.

### Email

This service uses [SendGrid](https://sendgrid.com/) to send account verification and password reset emails. The service accesses your API key through another environment variable called `SENDGRID_API_KEY`. Set that and you should be good to go.

You can run the service and access its routes through localhost!

### Additional Configuration

There are few other things to note when configuring the service:

1. There is a global constant called `emailConfirmation` in the `configure.swift` file. By default, it is set to `false`, which means the user can login and start using the service right away. If you set it to `true`, it requires the user to confirm with an email that is sent to them before they can authenticate with the service.

2. There is a `JWTDataConfig` service registered in the `configure(_:_:_:_)` function. The objects stored in this service (of type `RemoteDataClient`) are used to get data outside the service that needs to be stored in the access token payload.

    The `filters` property is an array of the keys to sub-objects in the JSON returned from the remote service. This works with arrays, so if you have an array of objets, all with an `id` value, you can use `["id"]`, and get an array of the `id`s.
    
    The authentication allowed by this configuration is a bit constrained at this time. It uses an access token generated by the User Service to authenticate with other services, so you can only authenticate with services that use your User Service. The access token that is passed through will only ever contain the basic payload and then will have the additional data added before being returned from the service's authentication route.
    
    When the data is retrieved from the outside service, the JSON is added to the access token payload with the JSON value fetch as the value and the service name as the key.
    
## Authentication

To authenticate in a separate service a request that contains an access token from the user service, you will need to setup the [JWTVapor package](https://github.com/skelpo/JWTVapor) in your project. You can reference the code the register it in the User service configuration if you need help setting it up.

Once you have the JWTVapor provider configured, you will need to add a middleware to your protected routes to verify the access token. If you just want to verify the access token and get the payload, the [JWTMIddleware package](https://github.com/skelpo/JWTMiddleware)'s `JWTVerificationMiddleware` can be used. The JWTMiddleware package also adds a `.payload` helper method to the `Request` class so you can get the access token's payload.

The other option for middleware is the `JWTAuthenticatableMiddleware` that also comes with the JWTMiddleware package. It handles authentication with a certain type (i.e. `User`) that acts as an owner for the rest of the service's models.

## Routes

To add custom routes to your user service, create a controller in the `Sources/App/Controllers` directory. You can make it a `RouteCollection`, or have the route registration work some other way. After you have created all your routes, you can register it in `Sources/Configuration/router.swift` to the `router` object passed into the `routes(_:)` function. If you want the routes to be protected so the client needs to have an access token, You can create a route group with `JWTAuthenticatableMiddlware<User>` middleware.

The routes for the service all start with a wildcard path element. This allows you to run multiple different versions of your API (with paths `/v1/...`, `/v2/...`, etc.) on any given cloud provider using a load balancer to figure out where to send the request to so we get the proper API version, while at the same time letting us ignore the version number. We don't need to know if it is correct or not. The load balancer takes care of that.

## User

You can add additional properties to the `User` model if you want, though if the service is already running, they will have to be optional (unless you want to set the values of the rows in the database, but that is beyond the scope of this document).

Add the property to the model. If you want it to be in the user JSON, then add it to the `UserResponse` struct also.


### Attributes

The `user` database table is connected to another table, called `attributes`. An attribute's row contains the ID of the user that owns it, a key that is unique to the user, and a value stored as a string.

When working in the service, if you want to interact with a user's attributes, there are several methods available:

```swift
/// Create a query that gets all the attributes belonging to a user.
func attributes(on connection: DatabaseConnectable)throws -> QueryBuilder<Attribute, Attribute>

/// Creates a dictionary where the key is the attribute's key and the value is the attribute's text.
func attributesMap(on connection: DatabaseConnectable)throws -> Future<[String:String]> 

/// Creates a profile attribute for the user.
///
/// - parameters:
///   - key: A public identifier for the attribute.
///   - text: The value of the attribute.
func createAttribute(_ key: String, text: String, on connection: DatabaseConnectable)throws -> Future<Attribute>

/// Removed the attribute from the user based on its key.
func removeAttribute(key: String, on connection: DatabaseConnectable)throws -> Future<Void>

/// Remove the attribute from the user based on its database ID.
func removeAttribute(id: Int, on connection: DatabaseConnectable)throws -> Future<Void>
```

If you want to access the user's attributes through an API endpoint, there are the following routes available:

- `GET /*/users/attributes`:
  Gets all the attributes of the currently authenticated user. This route does not require any parameters.

- `POST /*/users/attributes`
  Creates a new attribute, or sets the value of an existing value.
  
  This route requires `attributeText` and `attributeKey` parameters in the request body. If an attribute already exists with the key passed in, then the value will be changed to the one passed in. Otherwise, a new attribute will be created.

- `DELETE /*/users/attributes`:
  Deletes an attribute from a user.
  
  This route requires either an `attributeId` or `attributeKey` parameter in the request body to identify the attribute to delete.
  
## Easy Start

The easiest way to start the service is by using the Dockerfile. The following command _could_ be used as it is, we highly recommend however that you customize your setup to your needs.
```bash
# Note that you still need to setup the database before this step.
docker build . -t users
docker run -e JWT_PUBLIC='n-value-from-jwt' \
-e DATABASE_HOSTNAME='localhost' \
-e DATABASE_USER='users_service' \
-e DATABASE_PASSWORD='users_service' \
-e DATABASE_DB='users_service' \
-e JWT_SECRET='d-value-from-jwt' -p 8080:8080 users
```

If you want to run the server without docker the following summary of ENV variables that are needed may be helpful:
```bash
export JWT_PUBLIC='n-value-from-jwt'
export DATABASE_HOSTNAME='localhost'
export DATABASE_USER='users_service'
export DATABASE_PASSWORD='users_service'
export DATABASE_DB='users_service' 
export JWT_SECRET='d-value-from-jwt'
```

## More Information about JWT and JWKS

You'll notice that this project uses JWT and JWKS for authentication. If you are unfamiliar with the concept the following two links will provide you with an overview:
- [JWKS](https://auth0.com/docs/jwks)
- [JWT](https://jwt.io/)

## Todo & Roadmap
The following features will come at some point soon:
- Admin-Functions: List of all users, Editing of other users based on permission level, Adding new users as an admin
- (open for suggestions)

## Contribution & License

This project is published under MIT and is free for any kind of use. Contributions in forms of PRs are more than welcome, please keep the following simple rules:

- Keep it generic: This user manager should be equally usable for shops, blogs, apps, websites, enterprise systems or any other user system.
- Less is more: There are many features that _could_ be added. Most of them are better suited for additional services though (like e.g. customer related fields etc.)
- Improvements are always great and so are alternatives: If you want this to run with MongoDB, Elastic or anything else - by all means feel free to contribute. Improvements are always great!

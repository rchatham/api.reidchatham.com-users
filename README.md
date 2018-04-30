# Skelpo User Service

The Skelpo User Service is an application micro-service written using Swift and Vapor, a server side Swift framework. This micro-service can be integrated into most applications to handle the app's users and authentication. It is designed to be easily customizable, whether that is adding additional data points to the user, getting more data with the authentication payload, or creating more routes.

## Getting Started

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

You will also need to create an environment variable named `JWT_SECRET` with the `n` value of the JWK to verify access tokens. This service also signs the access tokens, so you will need another environment variable (called `USER_JWT_D` by default, but that can be changed) that contains the `d` value of the JWK.

You can run the service and access its routes through localhost!

### Additional Configuration

There are few other things to note when configuring the service:

1. There is an `emailConfirmation` key in the `app.json` configuration file. By default, it is set to `true`, which requires a user to confirm with an email that is sent to them before they can authenticate with the service.

2. In the `service.json` configuration file, there is a `services` object. The entries of this object are used to get data outside the service that needs to be stored in the access token payload. The structure of the objects that you can place in them will look like this:

    ```json
    "<service_name>": {
        "url": "https://api.myotherservice.io/...",
        
        "//": "All the following keys are optional",
        "//": "The method key is case-insensative. It defaults to 'GET'",
        "method": "GET",
        
        "//": "Defaults to an empty object",
        "body": {...},
        
        "//": "Defaults to an empty object",
        "header": {"Content-Type": "application/json", ...},
        
        "//": "The below key defaults to false",
        "requiresAccessToken": false,
        
        "//": "Defaults to an empty array (will get whole JSON object)",
        "filters": [
            "path",
            "to",
            "json",
            "values"
        ],
        
        "//": "Defaults to nil",
        "default": "Some empty value of any type"
    }
    ```
    
    The `filters` key is an array of the key path to get from the JSON returned from the given URL. This is able to fetch from objects held in arrays.
    
    The authentication allowed by this configuration is a bit constrained at this time. It uses an access token generated by the User Service to authenticate with other services, so you can only authenticate with services that use your User Service. The access token that is passed through will only ever contain the basic payload and then will have the additional data added before being returned froim the service's authentication route.
    
    When the data is retreived from the outside service, the JSON is added to the access token payload with the JSON value fetch as the vlue and the service name as the key.
    
## Authentication

To authenticate in a separate service a request that contains an access token from the user service, you will need to setup the [JWTProvider package](https://github.com/vapor/jwt-provider) in your project. You can read the documentation on it [here](https://docs.vapor.codes/2.0/jwt/package/).

Once you have the JWTProvider configured, you will need to add a middleware to your protected routes to verify the access token. If you just want to verify the access token and get the payload, the [SkelpoMiddleware package](https://github.com/skelpo/SkelpoMiddleware)'s `JWTAuthenticationMiddleware` can be used. The SkelpoMiddleware package also adds a `.payload` helper method to the `Request` class so you can get the access token payload.

The other option for middleware is the `PayloadAuthenticationMiddleware` built into the JWTProvider package. It handles authentication with a certian type (i.e. `User`) that acts as an owner for the rest of the service's models.

**Note:** You will need to use the same JSON in the `jwt.json` configuration file of you service as is present in the User Service.

## Routes

To add custom routes to your user service, create a controller in the `Sources/App/Controllers` directory. You can make it a `RouteCollection`, or have the route registration work some other way. After you have created all your routes, you can register it in `Sources/Routes/Routes.swift`. If the routes are open to the public, you can just register them directly to the droplet. If you want the routes to be protected so the client needs to have an access token, you can register then with the `authed` route group.

The routes for the service all start with a wildcard path element. This allows you to run multiple different versions of your API (with paths `/v1/...`, `/v2/...`, etc.) on AWS using the load balancer to figure out where to send the request to so we get the proper API version, while at the same time letting us ignore the version number (we don't need to know if it is correct or not. AWS takes care of that.)

## User

You can add additional properties to the `User` model if you want, though if the service is already running, they will have to be optional.

Start by adding the property to the model, and to the `Row` and `JSON` methods for serialization. Then we need to prepare the database table, so it has the new columns. If you can wipe the database, or haven't created one yet, you can add the preparation directly to the `User.prepare` method. However, if you already have the service up and running, you will need to modify the current table. This can be done by creating a struct that conforms to `Preparation` and adding it to your config's preparations. It will look something like this:

```swift
struct UserModifier: Preparation {
    static func prepare(_ database: Database) throws {
        try database.modify(User.self) { users in
            user.<type>("<COLUMN_NAME>", optional: nil, default: nil)
        }
    }

    static func revert(_ database: Database) throws {}
}
```

And this:

```swift
private func setupPreparations() throws {
    // Other preparations...
    // Add preparation in `Config.setupPreparations`.
    preparations.append(UserModifier.self)
}
```

### Attributes

The `user` database table is connected to another table, called `attributes`. An attribute's row contains the ID of the user that owns it, a key that is unique to the user, and a value stored as a string.

When working in the service, if you want to interact with a user's attributes, there are several methods availible:

```swift
/// Create a query that gets all the attributes belonging to a user.
func attributes()throws -> Query<Attribute>

/// Creates a dictionary where the key is the attribute's key and the value is the attribute's text.
func attributesMap()throws -> [String:String]

/// Creates a JSON representation of the user's attributes.
func attributesJSON() throws -> JSON

/// Creates a profile attribute for the user.
///
/// - parameters:
///   - key: A public identifier for the attribute.
///   - text: The value of the attribute.
func createAttribute(_ key: String, text: String)throws

/// Removed the attribute from the user based on its key.
func removeAttribute(key: String)throws

/// Remove the attribute from the user based on its database ID.
func removeAttribute(id: Int)throws
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


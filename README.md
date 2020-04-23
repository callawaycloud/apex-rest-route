# apex/:rest/route

A simple library that allows the creation of RESTful API's.

## ✨ Features:

-   supports deeply nested RESTful resource URI
-   allows you to focus on the implementation
-   automatic responses generation
-   error responses to align with Salesforce responses
-   flexibility to override most default functionality
-   hierarchical composition encourages for code reuse and RESTful design
-   lightweight: current implementation is ~ 200LN

## 📦 Install

Via Unlocked Package: [Install Link](https://mydomain.salesforce.com/packaging/installPackage.apexp?p0=04t1C000000goM0QAI) (update `https://mydomain.salesforce.com` for your target org!).

## 🔨 Usage

### Defining Routes

Imagine you wanted to create an API to expose the follow resources `Companies` & `CompanyLocations` & `CompanyEmployees`

[Following RESTful Design](https://hackernoon.com/restful-api-designing-guidelines-the-best-practices-60e1d954e7c9), we might have the following Resource URI definitions:

-   `api/v1/companies`
-   `api/v1/companies/:companyId`

-   `api/v1/companies/:companyId/locations`
-   `api/v1/companies/:companyId/locations/:locationId`

-   `api/v1/companies/:companyId/employees`
-   `api/v1/companies/:companyId/employees/:employeeId`

To implement this, first we will define our "Routes".

If you think of the URI as a tree, each Route should correspond to a branch:

```
      api/v1
        |
     companies
     |      |
locations  employees
```

For this example, we will just define three routes: `CompanyRoute`, `CompanyLocationRoute` & `CompanyEmployeeRoute`.

We could also define a top level route for `api/:versionId`, but for this example we'll just let that be handled by the standard `@RestResource` routing.

`CompanyRoute` will be responsible for providing a response to the following URI:

```
/api/v1/companies
/api/v1/companies/:companyId
```

`CompanyLocationRoute` will respond to:

```
/api/v1/companies/:companyId/locations
/api/v1/companies/:companyId/locations/:locationId
```

And `CompanyEmployeeRoute` will respond to:

```
/api/v1/companies/:companyId/employees
/api/v1/companies/:companyId/employees/:employeeId
```

### Implementation

```java
@RestResource(urlMapping='/v1/companies/*')
global class CompanyAPI{

    private static void handleRequest(){
      CompanyRoute router = new CompanyRoute();
      router.execute();
    }

    @HttpGet
    global static void handleGet() {
        handleRequest();
    }

    @HttpPost
    global static void handlePost() {
        handleRequest();
    }

    @HttpPut
    global static void handlePut() {
        handleRequest();
    }

    @HttpDelete
    global static void handleDelete() {
        handleRequest();
    }
}
```

#### Things to note:

1. This `@RestResource` is pretty much just a hook to call into our `CompanyRoute`.
1. `urlMapping='/api/v1/companies/*'` defines our base route. This should always be the baseUrl for the top level router (`CompanyRoute`), excluding the param. IOW, the `urlMapping` must end with the name of the first route + `/*`.

```java
public class CompanyRoute extends RestRoute {

    protected override Object doGet() {
        if (!String.isEmpty(this.resourceId)) {
           return getCompany(this.resourceId); //implementation not shown
        }
        return getCompanies();
    }

    protected override Object doPost() {
        if (!String.isEmpty(this.param)) {
          throw new RestRouteError.RestException('Create Operation does not support Company Identifier', 'NOT_SUPPORTED', 404);
        } else {
          return createCompany();
        }
    }

   //define downstream route
   protected override Map<String, RestRoute> getNextRouteMap() {
        return new Map<String, RestRoute>{
            'locations' => new CompanyLocationRoute(this.resourceId),
            'employees' => new CompanyEmployeeRoute(this.resourceId)
        };
    }
}
```

#### Things to note:

1. Each `RestRoute` route is initialized with a `resourceId` property (if the URI contains one) and `relativePaths` containing the remaining URL paths from the request.

1. The `doGet` & `doPost` corresponding to our HTTP methods for this route. Any HTTP method not implement will throw an exception. You can also override `doPut`, `doDelete`. Salesforce does not support `patch` at this time :shrug:

1. `getNextRouteMap()` will be used to determine the next RestRoute to call when the URI does not terminate with this Route. The next URI part will be matched against the Map keys. If more advanced routing is needed you can instead override the `next()` method and take full control.

1. We pass `this.resourceId` into the next Routes so they have access to `:employeeId`. This composition makes it easy to provide common functionality as lower level routes much pass through their parents. For example, we could query the "Company" and pass that to the next routes instead of just `this.resourceId`.

```java
public class CompanyLocationRoute extends RestRoute {
    private String companyId;

    public CompanyLocationRoute(String companyId) {
        this.companyId = companyId;
    }

    protected override Object doGet() {
        //filter down by company
        CompanyLocation[] companyLocations = getCompanyLocations(companyId);

        if (!String.isEmpty(this.resourceId)) {
            return getEntityById(this.resourceId, companyLocations);
        }
        return companyLocations;
    }
}
```

#### Things to note:

1. We pass the `companyId` from the above route into the constructor
1. This route does not implement `next()`. Any requests that don't end terminate with this route will result in a 404

### Returning other Content-Types

By default anything your return from the `doGet()|doPost()|...` methods will be serialized to JSON. However, if you need to respond with another format, you can set `this.response` directly and return `null`:

```java
protected override Object doGet() {
    this.response.responseBody = Blob.valueOf('Hello World!');
    this.response.addHeader('Content-Type', 'text/plain');
    return null;
}
```

### Routes without resources...

While it's not exactly "Restful" you may have routes which do not always following the `/:RESOURCE_URI/:RESOURCE_ID` format.

For example, if you wanted to implement the following url:

`/api/v1/other/foo`

Note that `other` is not followed by a resource ID. If you want to implement `foo` as a RestRoute, then you need to tell `other` not to treat the next URL part as a `:resourceId`.

To do so, simply override the `hasResource` method:

```java
  public class OtherRoute extends RestRoute {
      protected override boolean hasResource() {
          return false; //do parse the next url part as resourceId
      }

      protected override Map<String, RestRoute> getNextRouteMap() {
          return new Map<String, RestRoute>{ 'foo' => new FooRoute() };
      }
  }
```

### Error Handling

You can return an Error at anytime by throwing an exception. The `RestError.RestException` allows you to set `StatusCode` and `message` when throwing. There are also build in Errors for common use cases (`RouteNotFoundException` & `RouteNotFoundException`).

The response body will always contain `List<RestRouteError.Response>` as this [follows the best practices for handling REST errors](https://salesforce.stackexchange.com/questions/161429/rest-error-handling-design).

If needed you do change this by overriding `handleException(Exception err)`.

### Expanding Results

With our above example, if we wanted to pull all information about a company we would need to make 3 request:

> GET /companies/c-1

```json
{
    "id": "c-1",
    "name": "Callaway Cloud"
}
```

> GET /companies/123/employees

```json
[
    {
        "id": "e-1",
        "name": "John Doe",
        "role": "Developer"
    },
    {
        "id": "e-2",
        "name": "Billy Jean",
        "role": "PM"
    }
]
```

> GET /companies/123/locations

```json
[
    {
        "id": "l-1",
        "name": "Jackson, Wy"
    }
]
```

One interesting bonus of our design is the ability for this library to "expand" results by calling `expandResource(result)`:

```java
public override Object doGet() {
    Company[] companies = getCompanies();
    if (!String.isEmpty(this.resourceId)) {
        Company c = (Company) getEntityById(this.resourceId, companies);
        if (this.request.params.containsKey('expand')) {
            return expandResource(c);
        }
        return c;
    }
    //... collection
}
```

Doing so will run all downstream routes and return a single response with the next level of data!

```json
{
    "id": "c-1",
    "name": "Callaway Cloud",
    "employees": [
        {
            "id": "e-1",
            "name": "John Doe",
            "role": "Developer"
        },
        {
            "id": "e-2",
            "name": "Billy Jean",
            "role": "PM"
        }
    ],
    "locations": [
        {
            "id": "l-1",
            "name": "Jackson, Wy"
        }
    ]
}
```

This works by just running each of the child routes and merging in their data (the property is assigned based on the route; **warning will overwrite any conflict**).

It is even _possible_ (although a bit more complicated) to expand on collection request.

```java
//... doGet()
if (this.request.params.containsKey('expand')) {
    List<Map<String, Object>> expandedResponse = new List<Map<String, Object>>();
    for (Company c : companies) {
        this.resourceId = c.id;  // we must setup state for
        expandedResponse.add(expandRecord(c));
    }
    return expandedResponse;
}
```

While very cool, expanding collections is generally not advised due it's potential to be highly inefficient. If your downstream routes also support collection expansion, it would recursively continue through the entire tree!

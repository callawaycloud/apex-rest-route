# apex-rest-route

A simple library that allows the creation of RESTful API's.  Handles routing and allows you to focus on the implementation.

## Install
coming soon

## Usage

### Defining Routes

Imagine you wanted to create an API to expose the follow resources `Companies` & `CompanyLocations` & `CompanyEmployees`

[Following RESTful Design](https://hackernoon.com/restful-api-designing-guidelines-the-best-practices-60e1d954e7c9), we might have the following Resource URI definitions:

- `api/v1/companies`
- `api/v1/companies/:companyId`

- `api/v1/companies/:companyId/locations`
- `api/v1/companies/:companyId/locations/:locationId`

- `api/v1/companies/:companyId/employees`
- `api/v1/companies/:companyId/employees/:employeeId`

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

We could also define a top level route for the `v1` of the API, but for this example we'll just let that be handled by the standard `@RestResource` routing.

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
1. `urlMapping='/v1/companies/*'` defines our base route.  This should always be the baseUrl for the top level router (`CompanyRoute`), excluding the param.
1. We call the empty constructor for `CompanyRoute`, which initializes our route state.  This constructor should ONLY be called here.  For any nested routes, you will always PASS DOWN the `relativePaths`.

```java
public class CompanyRoute extends RestRoute {
 
    protected override Object doGet() {
        if (!String.isEmpty(this.param)) {
           return getCompany(this.param); //implementation not show
        } else {
          return getCompanies();
        }
    }

    protected override Object doPost() {
        if (!String.isEmpty(this.param)) {
          throw new RestRouteError.RestException('Create Operation does not support Company Identifier', 'NOT_SUPPORTED', 404);
        } else {
          return createCompany();
        }
    }

    protected override RestRoute next() {
        String nextPath = popNextPath();

        switch on nextPath {
           when 'locations' {
                //companies/:companyId/locations
                return new CompanyLocationRoute(this.param, relativePaths);
            }
            when 'employees' {
                //companies/:companyId/employees
                return new CompanyEmployeeRoute(this.param, relativePaths);
            }
        }

        return null; //responds with 404 standard error
    }
}
```

#### Things to note:

1. Each `RestRoute` route is initialized with a `param` property (if the URI contains one) and `relativePaths` containing the remaining URL paths from the request.

1. The `doGet` & `doPost` corresponding to our HTTP methods for this route.  Any HTTP method not implement will throw an exception.

1. `next()` will be called whenever the URI does not terminate with this Route. This method is responsible for determining the next route and setting the `relativePaths` to the correct point. 

1. We pass `this.param` into the next Routes so they have access to `:employeeId`.  This composition makes it easy to provide common functionality as lower level routes much pass through their parents.  For example, we could query the "Company" and pass that to the next routes instead of just `this.param`.

``` java
public class CompanyLocationRoute extends RestRoute {
    private String companyId;

    public CustomerAccountProductsRoute(String customerId, string[] relativePaths) {
        super(relativePaths);
        this.companyId = companyId;
    }

    protected override Object doGet() {
        if (!String.isEmpty(this.param)) {
            return getLocation(this.param);
        } else {
           return getLocations(this.companyId);
        }
    }
}
```

#### Things to note:

1. We pass the `companyId` from the above route into the constructor
1. This route does not implement `next()`.  Any requests that don't end terminate with this route will result in a 404

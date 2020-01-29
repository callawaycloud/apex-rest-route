/**
 * Author: charlie jonas (charlie@callaway.cloud)
 * Abstract Template for creating hierarchial REST API's.
 * Performs one of the following:
 *   A: Responds when there are no remaining uri parts (relativePaths)
 *   B: Forwards the request to next router in the tree
 *  See: https://github.com/ChuckJonas/apex-rest-route for additional documentation
 */
public abstract class RestRoute {
    protected RestRequest request;
    protected RestResponse response;
    protected String[] relativePaths;
    public string param;

    private static final String CUSTOM_REST_BASE = '/services/apexrest';

    /**
     *  Constructor for top level entry.  Should only be called from @RestResource RestRoute
     *    Setups up initial relativePaths array
     */
    public RestRoute() {
        String basePath = RestContext.request.resourcePath.replace(CUSTOM_REST_BASE, '').replace('*', '');
        this.relativePaths = RestContext.request.requestURI.replace(basePath, '').split('\\/');
        init();
    }

    /**
     *  Constructor to use when forwarding requests
     */
    public RestRoute(String[] relativePaths) {
        this.relativePaths = relativePaths;
        init();
    }

    private void init() {
        this.request = RestContext.request;
        this.response = RestContext.response;
        System.debug(this.relativePaths);
        if (this.relativePaths.size() >= 1) {
            this.param = this.popNextPath();
        }
    }

    /**
     *  Runs the Route Tree and sets the RestResponse
     *    Should ONLY be called from the top level @RestResource RestRoute
     */
    public void execute() {
        try {
            response.addHeader('Content-Type', 'application/json');
            Object resp = this.route();
            if (resp != null) {
                //body may have already been set directly on response object
                response.responseBody = Blob.valueOf(JSON.serialize(resp));
            }
        } catch (RestRouteError.RestException e) {
            response.statusCode = e.statusCode;
            response.responseBody = Blob.valueOf(JSON.serialize(new List<RestRouteError.Response>{ e.errorResp }));
        }
    }

    // === BEGIN TEMPLATE OVERRIDES ===

    /**
     *  Determines the next route to run.
     *    Do not need to override if route is a leaf.
     *    If null is returned, will throw  `RouteNotFoundException`
     */
    protected virtual RestRoute next() {
        throw new RouteNotFoundException(request);
    }

    /**
     *  Determines the next route to run.
     *    Do not need to override if route is a leaf.
     *    If null is returned, will throw  `RouteNotFoundException`
     */
    protected virtual Object doGet() {
        throw new OperationNotSupportException(request);
    }
    protected virtual Object doPost() {
        throw new OperationNotSupportException(request);
    }
    protected virtual Object doDelete() {
        throw new OperationNotSupportException(request);
    }
    protected virtual Object doPut() {
        throw new OperationNotSupportException(request);
    }

    // === END TEMPLATE OVERRIDES ===

    //either responds to the request, or forwards it to the next RestRoute
    protected Object route() {
        System.debug('Entering Route Method: ' + this.relativePaths);
        if (!this.hasNextPath()) {
            return this.respond();
        }
        RestRoute nextRoute = this.next();
        if (nextRoute != null) {
            return nextRoute.route();
        }
        throw new RestRoute.RouteNotFoundException(request);
    }

    // run appropriate HTTP METHOD
    protected Object respond() {
        switch on this.request.httpMethod {
            when 'GET' {
                return this.doGet();
            }
            when 'POST' {
                return this.doPost();
            }
            when 'DELETE' {
                return this.doDelete();
            }
            when 'PUT' {
                return this.doPut();
            }
            when else {
                throw new RouteNotFoundException(request);
            }
        }
    }

    /**
     *  returns true if there are more relative URI paths
     */
    protected Boolean hasNextPath() {
        return relativePaths.size() > 0;
    }

    /**
     *  pops the next relative Uri path
     */
    protected String popNextPath() {
        return relativePaths.remove(0);
    }

    public class RouteNotFoundException extends RestRouteError.RestException {
        public RouteNotFoundException(RestRequest req) {
            super('could not find route for: ' + req.requestURI, 'NOT_FOUND', 404);
        }
    }

    public class OperationNotSupportException extends RestRouteError.RestException {
        public OperationNotSupportException(RestRequest req) {
            super('Method is not supported ' + req.httpMethod, 'NOT_SUPPORTED', 404);
        }
    }

    // useful for stubbing routing
    public class NotImplementedRoute extends RestRoute {
        public NotImplementedRoute(string[] relativePaths) {
            super(relativePaths);
        }
    }
}

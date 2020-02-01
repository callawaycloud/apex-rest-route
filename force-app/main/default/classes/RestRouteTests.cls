@isTest
public class RestRouteTests {
    private static final String RESOURCE_URL = '/v1/companies/*';
    private static final String RESOURCE_PATH = '/services/apexrest' + RESOURCE_URL;

    @isTest
    public static void testBaseRouteCollection() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies/';
        req.httpMethod = 'GET';
        RestContext.Request = req;

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);
        RestRouteTestRoutes.Company[] respData = (RestRouteTestRoutes.Company[]) JSON.deserialize(
            resp.responseBody.toString(),
            List<RestRouteTestRoutes.Company>.class
        );

        System.assertEquals(2, respData.size());
    }

    @isTest
    public static void testBaseRouteCollection2() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies';
        req.httpMethod = 'GET';
        RestContext.Request = req;

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);
        RestRouteTestRoutes.Company[] respData = (RestRouteTestRoutes.Company[]) JSON.deserialize(
            resp.responseBody.toString(),
            List<RestRouteTestRoutes.Company>.class
        );

        System.assertEquals(2, respData.size());
    }

    @isTest
    public static void testBaseRouteSingle() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies/c-1';
        req.httpMethod = 'GET';
        RestContext.Request = req;

        system.debug(RestContext.Request.requestURI);

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);
        RestRouteTestRoutes.Company respData = (RestRouteTestRoutes.Company) JSON.deserialize(
            resp.responseBody.toString(),
            RestRouteTestRoutes.Company.class
        );

        System.assertEquals('c-1', respData.id);
    }

    @isTest
    public static void testSingleExpanded() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies/c-1';
        req.params.put('expand', '1');
        req.httpMethod = 'GET';
        RestContext.Request = req;

        system.debug(RestContext.Request.requestURI);

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);

        // TODO make useful assertions
        // System.assertEquals('', resp.responseBody.toString());
    }

    @isTest
    public static void testCollectionExpanded() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies';
        req.params.put('expand', '1');
        req.httpMethod = 'GET';
        RestContext.Request = req;

        system.debug(RestContext.Request.requestURI);

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);

        // TODO make useful assertions
        // System.assertEquals('', resp.responseBody.toString());
    }

    @isTest
    public static void testNestedRouteCollection() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies/c-2/locations';
        req.httpMethod = 'GET';
        RestContext.Request = req;

        system.debug(RestContext.Request.requestURI);

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);
        RestRouteTestRoutes.CompanyLocation[] respData = (RestRouteTestRoutes.CompanyLocation[]) JSON.deserialize(
            resp.responseBody.toString(),
            List<RestRouteTestRoutes.CompanyLocation>.class
        );

        System.assertEquals(1, respData.size());
        System.assertEquals('LA', respData[0].name);
    }

    @isTest
    public static void testRouteCollectionFilter() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies/c-2/employees';
        req.params.put('role', 'CEO');
        req.httpMethod = 'GET';
        RestContext.Request = req;

        system.debug(RestContext.Request.requestURI);

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);
        RestRouteTestRoutes.CompanyEmployee[] respData = (RestRouteTestRoutes.CompanyEmployee[]) JSON.deserialize(
            resp.responseBody.toString(),
            List<RestRouteTestRoutes.CompanyEmployee>.class
        );

        System.assertEquals(2, respData.size());
        System.assertEquals('Iron Man', respData[0].name);
    }

    @isTest
    public static void testNestedRouteSingle() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies/c-1/employees/e-2';
        req.httpMethod = 'GET';
        RestContext.Request = req;

        system.debug(RestContext.Request.requestURI);

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);
        RestRouteTestRoutes.CompanyEmployee respData = (RestRouteTestRoutes.CompanyEmployee) JSON.deserialize(
            resp.responseBody.toString(),
            RestRouteTestRoutes.CompanyEmployee.class
        );

        System.assertEquals('e-2', respData.id);
    }

    @isTest
    public static void testNestedRouteSingleNotRelated() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies/c-2/employees/e-2';
        req.httpMethod = 'GET';
        RestContext.Request = req;

        system.debug(RestContext.Request.requestURI);

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(404, resp.statusCode);
        RestRouteError.Response[] respData = (RestRouteError.Response[]) JSON.deserialize(
            resp.responseBody.toString(),
            List<RestRouteError.Response>.class
        );

        System.assertEquals(1, respData.size());
        System.assertEquals('NOT_FOUND', respData[0].errorCode);
    }

    @isTest
    public static void testNoRouteFound() {
        RestRequest req = new RestRequest();
        req.resourcePath = RESOURCE_PATH;
        req.requestURI = '/v1/companies/c-2/asdf';
        req.httpMethod = 'GET';
        RestContext.Request = req;

        system.debug(RestContext.Request.requestURI);

        RestResponse resp = new RestResponse();
        RestContext.Response = resp;

        RestRouteTestRoutes.CompanyRoute router = new RestRouteTestRoutes.CompanyRoute();
        router.execute();

        System.assertEquals(404, resp.statusCode);
        RestRouteError.Response[] respData = (RestRouteError.Response[]) JSON.deserialize(
            resp.responseBody.toString(),
            List<RestRouteError.Response>.class
        );

        System.assertEquals(1, respData.size());
        System.assertEquals('NOT_FOUND', respData[0].errorCode);
    }
}

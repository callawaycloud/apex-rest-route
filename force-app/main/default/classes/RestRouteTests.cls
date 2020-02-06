@isTest
public class RestRouteTests {
    private static final String RESOURCE_URL = '/api/*';
    private static final String RESOURCE_PATH = '/services/apexrest' + RESOURCE_URL;

    @isTest
    public static void testEntryRoute() {
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api/v1');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
        router.execute();

        System.assertEquals(400, resp.statusCode);
    }

    @isTest
    public static void testEntryRouteCollections() {
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
        router.execute();

        System.assertEquals(400, resp.statusCode);
    }

    @isTest
    public static void testBaseRouteCollection() {
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api/v1/companies/');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
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
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api/v1/companies');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
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
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api/v1/companies/c-1');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
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
        RestRouteTestUtil.setupRestContext(
            RESOURCE_PATH,
            '/api/v1/companies/c-1',
            new Map<String, String>{ 'expand' => '1' }
        );
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);

        // TODO make useful assertions
        // System.assertEquals('', resp.responseBody.toString());
    }

    @isTest
    public static void testCollectionExpanded() {
        RestRouteTestUtil.setupRestContext(
            RESOURCE_PATH,
            '/api/v1/companies',
            new Map<String, String>{ 'expand' => '1' }
        );
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);

        // TODO make useful assertions
        // System.assertEquals('', resp.responseBody.toString());
    }

    @isTest
    public static void testNestedRouteCollection() {
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api/v1/companies/c-2/locations');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
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
    public static void testAlternateRoute() {
        RestRouteTestUtil.setupRestContext(
            RESOURCE_PATH,
            '/api/v1/employees',
            new Map<String, String>{ 'companyId' => 'c-2' }
        );
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
        router.execute();

        System.assertEquals(200, resp.statusCode);
        RestRouteTestRoutes.CompanyEmployee[] respData = (RestRouteTestRoutes.CompanyEmployee[]) JSON.deserialize(
            resp.responseBody.toString(),
            List<RestRouteTestRoutes.CompanyEmployee>.class
        );

        System.assertEquals(3, respData.size());
        System.assertEquals('Iron Man', respData[0].name);
    }

    @isTest
    public static void testRouteCollectionFilter() {
        RestRouteTestUtil.setupRestContext(
            RESOURCE_PATH,
            '/api/v1/companies/c-2/employees',
            new Map<String, String>{ 'role' => 'CEO' }
        );
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
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
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api/v1/companies/c-1/employees/e-2');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
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
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api/v1/companies/c-2/employees/e-2');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
        router.execute();

        System.assertEquals(404, resp.statusCode);
        RestRouteError.Response[] respData = RestRouteTestUtil.parseResponseErrors(resp);

        System.assertEquals(1, respData.size());
        System.assertEquals('NOT_FOUND', respData[0].errorCode);
    }

    @isTest
    public static void testNoRouteFound() {
        RestRouteTestUtil.setupRestContext(RESOURCE_PATH, '/api/v1/companies/c-2/asdf');
        RestResponse resp = RestContext.Response;

        RestRouteTestRoutes.APIEntryRoute router = new RestRouteTestRoutes.APIEntryRoute();
        router.execute();

        System.assertEquals(404, resp.statusCode);
        RestRouteError.Response[] respData = RestRouteTestUtil.parseResponseErrors(resp);

        System.assertEquals(1, respData.size());
        System.assertEquals('NOT_FOUND', respData[0].errorCode);
    }
}
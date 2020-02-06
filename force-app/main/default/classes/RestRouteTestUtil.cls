// Test helpers for RestRoute
public class RestRouteTestUtil {
    //shorthand simple GET REQUEST
    public static void setupRestContext(String resourcePath, String requestUri) {
        setupRestContext(resourcePath, requestUri, 'GET', null, null);
    }

    //shorthand for GET + URL Params
    public static void setupRestContext(String resourcePath, String requestUri, Map<String, String> query) {
        setupRestContext(resourcePath, requestUri, 'GET', query, null);
    }

    public static void setupRestContext(
        String resourcePath,
        String requestUri,
        String httpMethod,
        Map<String, String> query,
        Blob body
    ) {
        RestRequest req = new RestRequest();
        req.resourcePath = resourcePath;
        req.requestURI = requestUri;
        req.httpMethod = httpMethod;
        if (query != null) {
            req.params.putAll(query);
        }
        if (body != null) {
            req.requestBody = body;
        }

        RestContext.Request = req;
        RestContext.Response = new RestResponse();
    }

    public static RestRouteError.Response[] parseResponseErrors(RestResponse resp) {
        return (RestRouteError.Response[]) JSON.deserialize(
            resp.responseBody.toString(),
            List<RestRouteError.Response>.class
        );
    }
}
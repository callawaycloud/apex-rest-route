public class RestRouteError {
    public class Response {
        public String errorCode;
        public String message;
        public Response(String errorCode, string message) {
            this.errorCode = errorCode;
            this.message = message;
        }
    }

    public virtual class RestException extends Exception {
        public Response errorResp;
        public Integer statusCode;
        public RestException(String message, String errorCode, Integer statusCode) {
            this.setMessage(message);
            this.errorResp = new Response(errorCode, message);
            this.statusCode = statusCode;
        }
    }
}
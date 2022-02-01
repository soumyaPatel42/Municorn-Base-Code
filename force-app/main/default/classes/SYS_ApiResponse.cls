public class SYS_ApiResponse {
    public static Exception error;

    public SYS_ApiResponse() {
        
    }
    public static Integer statusCode {
        get{
            if(error != null) {
                if(error instanceof DmlException){
                    return 400;
                } else {
                    return 500;
                }
            } else { 
                return 200;
            }
        }
    }

    public static Blob successResponse(String msg) {
        SYS_ExceptionHandler response = new SYS_ExceptionHandler('N/A', msg);
        response.type = 'Success';
        return Blob.valueOf(JSON.serialize(response));
    }

    public static Blob failureResponse() {
        SYS_ExceptionHandler response = new SYS_ExceptionHandler('', '');
        if (error instanceof DmlException) {
            response.errorCode = 'BAD_REQUEST';
            response.type = 'Dml Error';
            response.message = error.getMessage();
        } else if (error instanceof AsyncException) {
            response.errorCode = 'BAD_REQUEST';
            response.type = 'Asynchronous call exception';
            response.message = error.getMessage();
        } else if (error instanceof CalloutException) {
            response.errorCode = 'BAD_REQUEST';
            response.type = 'External callout exception';
            response.message = error.getMessage();
        } else if (error instanceof ListException) {
            response.errorCode = 'BAD_REQUEST';
            response.type = 'List index exception';
            response.message = error.getMessage();
        } else if (error instanceof JSONException) { 
            response.errorCode = 'BAD_REQUEST';
            response.type = 'JSON Serialization exception';
            response.message = error.getMessage();
        } else if (error instanceof NullPointerException) {
            response.errorCode = 'BAD_REQUEST';
            response.type = 'Null pointer exception';
            response.message = error.getMessage();
        } else if (error instanceof StringException) {
            response.errorCode = 'BAD_REQUEST';
            response.type = 'String has exceeded heap size exception';
            response.message = error.getMessage();
        } else {
            response.errorCode = 'BAD_REQUEST';
            response.type = 'Some Exception has occured';
            response.message = error.getMessage();
        }
        
        return Blob.valueOf(JSON.serialize(response));
    }
}
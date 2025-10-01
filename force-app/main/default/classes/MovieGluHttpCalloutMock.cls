/**
 * @description Mock class for MovieGlu API HTTP callouts
 * @author Cristiano Filho
 * @date 2025-09-30
 */
@isTest
global class MovieGluHttpCalloutMock implements HttpCalloutMock {
    
    private String responseType;
    private Integer statusCode;
    
    global MovieGluHttpCalloutMock(String responseType, Integer statusCode) {
        this.responseType = responseType;
        this.statusCode = statusCode;
    }
    
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(statusCode);
        
        if (responseType == 'films') {
            res.setBody(getFilmsResponse());
        } else if (responseType == 'cinemas') {
            res.setBody(getCinemasResponse());
        } else if (responseType == 'showtimes') {
            res.setBody(getShowtimesResponse());
        } else {
            res.setBody('{"error":"Unknown response type"}');
        }
        
        return res;
    }
    
    private String getFilmsResponse() {
        return '{"films":[' +
            '{' +
                '"film_id":"12345",' +
                '"film_name":"Test Movie",' +
                '"synopsis_long":"This is a test movie synopsis",' +
                '"duration_mins":120,' +
                '"images":{"poster":{"1":{"medium":"https://test.com/poster.jpg"}}},' +
                '"release_dates":[{"release_date":"2025-10-01"}],' +
                '"age_rating":[{"rating":"PG-13"}]' +
            '},' +
            '{' +
                '"film_id":"67890",' +
                '"film_name":"Another Test Movie",' +
                '"synopsis_long":"Another test synopsis",' +
                '"duration_mins":95' +
            '}' +
        ']}';
    }
    
    private String getCinemasResponse() {
        return '{"cinemas":[' +
            '{' +
                '"cinema_id":"cinema123",' +
                '"cinema_name":"Test Theater",' +
                '"address":"123 Test St",' +
                '"city":"Test City",' +
                '"country":"USA",' +
                '"lat":"40.7128",' +
                '"lng":"-74.0060"' +
            '},' +
            '{' +
                '"cinema_id":"cinema456",' +
                '"cinema_name":"Another Theater",' +
                '"address":"456 Main Ave",' +
                '"city":"Sample City",' +
                '"country":"USA",' +
                '"lat":"34.0522",' +
                '"lng":"-118.2437"' +
            '}' +
        ']}';
    }
    
    private String getShowtimesResponse() {
        return '{"cinemas":[' +
            '{' +
                '"cinema_id":"cinema123",' +
                '"showings":[' +
                    '{' +
                        '"showing_id":"show123",' +
                        '"start_time":"14:30"' +
                    '},' +
                    '{' +
                        '"showing_id":"show456",' +
                        '"start_time":"19:00"' +
                    '}' +
                ']' +
            '}' +
        ']}';
    }
}


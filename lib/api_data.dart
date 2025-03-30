// Data type for API Responses
class ApiData {
  Uri url;
  Map<String, dynamic>? response;    // json response

  ApiData(this.url, this.response);
}
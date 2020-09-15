//Abstract class to return status of the HTTP response message.
abstract class ResponseMsg {
  ResponseMsg(
      this.statusCode, this.reasonPhase, this.errorType, this.errorDescription);

  String errorDescription;
  String errorType;
  String reasonPhase;
  int statusCode;
}

// Hold the OAuth2 Acess Token provided by the server
class AccessToken {
  AccessToken(
      {this.accessToken,
      this.refreshToken,
      this.expiresIn,
      this.scope,
      this.tokenType});
  // To create a new instance of Access Token from JSON message.
  factory AccessToken.fromJson(Map<String, dynamic> json) => AccessToken(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: int.parse(json['expires_in'] ?? 270),
      scope: json['scope'] as String,
      tokenType: json['token_type'] as String);

  String accessToken;
  int expiresIn;
  String refreshToken;
  String scope;
  String tokenType;
}

class TokenResponse implements ResponseMsg {
  AccessToken tokenData;
  bool isSuccess() => statusCode == 200;
  @override
  int statusCode;

  @override
  String reasonPhase;

  @override
  String errorType;

  @override
  String errorDescription;
}

class NewsHeadlinesData {
  NewsHeadlinesData(
      {this.storyId, this.firstCreated, this.versionCreated, this.titleText});

  String firstCreated;
  String storyId;
  String titleText;
  String versionCreated;
}

class NewsStoryData {
  String copyrightHolder;
  String copyrightNotice;
  String language;
  String newsContent;
  String newsTitle;
}

class NewsHeadlineResp implements ResponseMsg {
  List<NewsHeadlinesData> headlinesDatas;
  NewsHeadlineMeta metaInfo;

  @override
  int statusCode;
  
  @override
  String reasonPhase;

  @override
  String errorType;

  @override
  String errorDescription;
}

class NewsStoryResp implements ResponseMsg {
  NewsStoryData newsContent;

  @override
  int statusCode;

  @override
  String reasonPhase;

  @override
  String errorType;

  @override
  String errorDescription;
}

class NewsHeadlineMeta {
  NewsHeadlineMeta({this.count, this.pageLimit, this.next, this.previous});

  factory NewsHeadlineMeta.fromJson(Map<String, dynamic> json) =>
      NewsHeadlineMeta(
          count: json['count'] as int,
          pageLimit: json['pageLimit'] as int,
          next: json['next'] as String,
          previous: json['prev'] as String);

  int count;
  String next;
  int pageLimit;
  String previous;
}

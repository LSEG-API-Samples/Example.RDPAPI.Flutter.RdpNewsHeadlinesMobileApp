import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'rdp_endpoints.dart';
import 'dart:convert';
import 'package:rdp_manager_conosole_app/rdp/rdp_message_data.dart'
    as rdp_message;

class RdpManager {
  String clientId;
  String refreshToken;
  String scope;
  String userName;
  String userPassword;
  rdp_message.AccessToken accessTokenInfo;

  Future<rdp_message.TokenResponse> getAuthenticationInfo(bool useRefreshToken,
      {String userName,
      String userPassword,
      String clientId,
      String refreshToken,
      String scope = 'trapi',
      String url}) async {
    if (userName != null) this.userName = userName;
    if (userPassword != null) this.userPassword = userPassword;
    if (clientId != null) this.clientId = clientId;
    if (refreshToken != null) this.refreshToken = refreshToken;
    if (scope != null) this.scope = scope;
    if (url == null || url.isEmpty) url = RdpEndpoints.authTokenUrl;

    var tokenResp = rdp_message.TokenResponse();
    var headerList = <String, String>{};
    headerList['Content-Type'] = 'application/x-www-form-urlencoded';
    headerList['Accept'] = 'application/json';
    headerList['AllowAutoRedirect'] = 'false';
    var body = {};
    body['username'] = this.userName;
    body['client_id'] = this.clientId;
    if (useRefreshToken) {
      body['grant_type'] = 'refresh_token';
      body['refresh_token'] = this.refreshToken;
    } else {
      body['takeExclusiveSignOnControl'] = 'true';
      body['grant_type'] = 'password';
      body['scope'] = this.scope;
      body['password'] = this.userPassword;
    }
    var client = http.Client();
    try {
      var getTokenUri =
          Uri.https(RdpEndpoints.rdp_hostname, RdpEndpoints.authTokenUrl);
      var httpResponse =
          await client.post(getTokenUri, headers: headerList, body: body);
      if ((httpResponse.headers.containsKey('Transfer-Encoding') &&
              httpResponse.headers['Transfer-Encoding'] == 'chunked') ||
          httpResponse.body.isNotEmpty) {
        tokenResp.statusCode = httpResponse.statusCode;
        tokenResp.reasonPhase = httpResponse.reasonPhrase;
        tokenResp.errorType =
            (json.decode(httpResponse.body) as Map<String, dynamic>)['error'];
        tokenResp.errorDescription = (json.decode(httpResponse.body)
            as Map<String, dynamic>)['error_description'];
        print(json.decode(httpResponse.body));
        if (httpResponse.statusCode == 200 && httpResponse.contentLength > 0) {
          var accessTokenData = rdp_message.AccessToken.fromJson(
              json.decode(httpResponse.body) as Map<String, dynamic>);
          tokenResp.tokenData = accessTokenData;
        }

        switch (httpResponse.statusCode) {
          case 301:
          case 302:
          case 307:
          case 308:
            // Perform URL redirect
            client.close();
            print('${httpResponse.statusCode} ${httpResponse.reasonPhrase}');
            var newHost = httpResponse.headers['Location'];
            if (newHost != null && newHost.isNotEmpty) {
              tokenResp =
                  await getAuthenticationInfo(useRefreshToken, url: newHost);
            }
            break;
        }
      }
    } on SocketException catch (e) {
      print('SocketError Exception ${e.message}');
      tokenResp.errorType = 'SocketException';
      tokenResp.errorDescription = e.message;
    } catch (e) {
      print('Unhandled Exception $e');
      tokenResp.errorType = 'Unhandled Exception';
      tokenResp.errorDescription = 'Unhandled Exception $e';
    } finally {
      client.close();
    }
    accessTokenInfo = tokenResp.tokenData;
    return tokenResp;
  }

  Future<rdp_message.NewsHeadlineResp> getNewsHeadlines(
      rdp_message.AccessToken accessToken,
      {String query,
      String cursor}) async {
    var headlinesResp = rdp_message.NewsHeadlineResp();

    var headerList = <String, String>{};
    //headerList['Content-Type'] = 'application/x-www-form-urlencoded';
    headerList['Accept'] = 'application/json';
    headerList['AllowAutoRedirect'] = 'false';
    headerList['Authorization'] =
        '${accessToken.tokenType} ${accessToken.accessToken}';
    var client = http.Client();
    try {
      //var httpResponse = await client.get(url, headers: headerList);
      var queryParameters = <String, String>{};
      if (query != null) {
        queryParameters['query'] = query;
      } else if (cursor != null) queryParameters['cursor'] = cursor;

      var serverUri = Uri.https(RdpEndpoints.rdp_hostname,
          RdpEndpoints.newsHeadlinesUrl, queryParameters);
      var httpResponse = await client.get(serverUri, headers: headerList);
      headlinesResp.statusCode = httpResponse.statusCode;

      if (httpResponse.statusCode != 200) {
        headlinesResp.reasonPhase = httpResponse.reasonPhrase;
        headlinesResp.errorType =
            (json.decode(httpResponse.body) as Map<String, dynamic>)['error'];
        headlinesResp.errorDescription = (json.decode(httpResponse.body)
            as Map<String, dynamic>)['error_description'];
      }

      if (httpResponse.statusCode == 200 &&
          httpResponse.body != null &&
          httpResponse.body.isNotEmpty) {
        if (httpResponse.statusCode == 200 && httpResponse.contentLength > 0) {
          var headlinesList = (json.decode(httpResponse.body)
              as Map<String, dynamic>)['data'] as List<dynamic>;
          if (headerList != null) {
            var newsHeadlinesDataList = <rdp_message.NewsHeadlinesData>[];
            var metaInfo = (json.decode(httpResponse.body)
                as Map<String, dynamic>)['meta'] as Map<String, dynamic>;
            if (metaInfo != null) {
              var metaData = rdp_message.NewsHeadlineMeta.fromJson(metaInfo);
              headlinesResp.metaInfo = metaData;
            }
            headlinesList.forEach((element) {
              var headlinesJsonData = element as Map<String, dynamic>;
              var newsHeadlines = rdp_message.NewsHeadlinesData();
              headlinesJsonData.forEach((key, value) {
                switch (key) {
                  case 'storyId':
                    newsHeadlines.storyId =
                        headlinesJsonData['storyId'] as String;
                    break;
                  case 'newsItem':
                    {
                      (value as Map<String, dynamic>).forEach((key2, value2) {
                        if (key2 == 'itemMeta') {
                          (value2 as Map<String, dynamic>)
                              .forEach((key3, value3) {
                            switch (key3) {
                              case 'firstCreated':
                                newsHeadlines.firstCreated = (value3
                                    as Map<String, dynamic>)['\$'] as String;
                                break;
                              case 'versionCreated':
                                newsHeadlines.firstCreated = (value3
                                    as Map<String, dynamic>)['\$'] as String;
                                break;
                              case 'title':
                                var contentText = '';
                                (value3 as List<dynamic>).forEach((item) {
                                  item.forEach((key4, value4) {
                                    if (key4 == '\$') {
                                      var content = value4;
                                      contentText +=
                                          (content == null) ? '' : content;
                                    }
                                  });
                                });
                                newsHeadlines.titleText = contentText;
                                break;
                            }
                          });
                        }
                      });
                    }
                    break;
                }
              });
              newsHeadlinesDataList.add(newsHeadlines);
            });
            headlinesResp.headlinesDatas = newsHeadlinesDataList;
          }
        }
      }
    } catch (e) {
      print(e.toString());
      headlinesResp.errorType = 'UnhandledException';
      headlinesResp.errorDescription = 'Exception:$e';
    } finally {
      client.close();
    }
    return headlinesResp;
  }

  Future<rdp_message.NewsStoryResp> getNewsStory(
      rdp_message.AccessToken accessToken, String storyId) async {
    var storyResp = rdp_message.NewsStoryResp();

    var headerList = <String, String>{};
    //headerList['Content-Type'] = 'application/x-www-form-urlencoded';
    headerList['Accept'] = 'application/json';
    headerList['AllowAutoRedirect'] = 'false';
    headerList['Authorization'] =
        '${accessToken?.tokenType} ${accessToken?.accessToken}';
    var client = http.Client();
    try {
      var serverUri = Uri.https(
          RdpEndpoints.rdp_hostname, '${RdpEndpoints.newsStoriesUrl}/$storyId');
      var httpResponse = await client.get(serverUri, headers: headerList);
      storyResp.statusCode = httpResponse.statusCode;

      if (httpResponse.statusCode != 200) {
        storyResp.reasonPhase = httpResponse.reasonPhrase;
        storyResp.errorType =
            (json.decode(httpResponse.body) as Map<String, dynamic>)['error']
                .toString();
        storyResp.errorDescription = (json.decode(httpResponse.body)
            as Map<String, dynamic>)['error_description'];
      }

      if (httpResponse.statusCode == 200 &&
          httpResponse.body != null &&
          httpResponse.body.isNotEmpty) {
        if (httpResponse.statusCode == 200 && httpResponse.contentLength > 0) {
          var newsStoryData = rdp_message.NewsStoryData();

          var newsItemData = (json.decode(httpResponse.body)
              as Map<String, dynamic>)['newsItem'] as Map<String, dynamic>;
          if (newsItemData != null) {
            // Extract language
            ((newsItemData['contentMeta'] as Map<String, dynamic>)['language']
                    as List<dynamic>)
                .forEach((element) {
              if ((element as Map<String, dynamic>).containsKey('_tag')) {
                newsStoryData.newsTitle =
                    (element as Map<String, dynamic>)['\$'];
              }
            });

            // Extract News Title
            ((newsItemData['contentMeta'] as Map<String, dynamic>)['headline']
                    as List<dynamic>)
                .forEach((element) {
              if ((element as Map<String, dynamic>).containsKey('\$')) {
                newsStoryData.newsTitle =
                    (element as Map<String, dynamic>)['\$'];
              }
            });

            // Extract News Title
            ((newsItemData['contentSet'] as Map<String, dynamic>)['inlineData']
                    as List<dynamic>)
                .forEach((element) {
              if ((element as Map<String, dynamic>).containsKey('\$')) {
                newsStoryData.newsContent =
                    (element as Map<String, dynamic>)['\$'];
              }
            });
            storyResp.newsContent = newsStoryData;
          }
        }
      }
    } catch (e) {
      print(e.toString());
      storyResp.errorType = 'UnhandledException';
      storyResp.errorDescription = 'Exception:$e';
    } finally {
      client.close();
    }
    return storyResp;
  }
}

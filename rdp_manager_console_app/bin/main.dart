import 'dart:async';
import 'package:rdp_manager_conosole_app/rdp/rdp_message_data.dart'
    as rdp_message;
import 'package:rdp_manager_conosole_app/rdp/rdp_manager.dart' as rdp_mgr;

int round = 1;
Timer myTimer;
bool runLoop = true;
var rdp = rdp_mgr.RdpManager();
void main(List<String> arguments) async {
  rdp.userName = '<Email or MachineID>';
  rdp.userPassword = '<Your Password>';
  rdp.clientId = '<Client ID>';
  var headlinesQuery = '(Microsoft Xbox Release) and searchIn:FullStory';
  var tokenResp = await rdp.getAuthenticationInfo(false);

  if (tokenResp != null && tokenResp.statusCode == 200) {
    PrintTokenInfo(tokenResp);
    if (runLoop) {
      Timer.periodic(
          Duration(seconds: (tokenResp.tokenData.expiresIn * 0.9).round()),
          (time) async {
        myTimer = time;
        if (tokenResp.statusCode == 200 &&
            tokenResp.tokenData != null &&
            tokenResp.tokenData.refreshToken != null) {
          tokenResp = await GetNewToken(tokenResp.tokenData.refreshToken);
        }
      });
    }

    /// Run the loops to display news headline and fetch healdines
    /// from next page cursor until it reach page cound limit.

    rdp_message.NewsHeadlineResp newsHeadlines;
    var pageIndex = 0;
    var pageCount = 0;
    do {
      if (newsHeadlines == null) {
        newsHeadlines = await rdp.getNewsHeadlines(tokenResp.tokenData,
            query: headlinesQuery);
      } else {
        newsHeadlines = await rdp.getNewsHeadlines(tokenResp.tokenData,
            cursor: newsHeadlines.metaInfo.next);
      }
      if (newsHeadlines.statusCode == 200) {
        if (pageCount == 0) pageCount = newsHeadlines.metaInfo.count;
        print('Headlines Page#${pageIndex + 1}/$pageCount');
        newsHeadlines.headlinesDatas.forEach((element) async {
          print('${element.storyId} ${element.titleText}');
          var storyResp =
              await rdp.getNewsStory(tokenResp.tokenData, element.storyId);
          if (storyResp.statusCode == 200) {
            print('StoryId:${element.storyId}');
            print('Title:${storyResp?.newsContent?.newsTitle}');
            print('=======================================');
            print(storyResp.newsContent.newsContent.replaceAll('\n', '\r\n'));
          }
        });
        print('');
        print('next ===>${newsHeadlines.metaInfo.next}');
      } else {
        print(
            'Error => ${newsHeadlines.statusCode} ${newsHeadlines.errorDescription} Stop');
        break;
      }
    } while (++pageIndex < newsHeadlines.metaInfo.count);

    print('=======================================');
    print('Get Data Complete Quit the app');
    myTimer?.cancel();
  } else {
    print(tokenResp.errorDescription);
  }
}

// Print details of the Acess Token
void PrintTokenInfo(rdp_message.TokenResponse tokenResp) {
  print('\n\nGet Token Round=${round++}');
  print('StatusCode:${tokenResp?.statusCode}');
  print('Token Type:${tokenResp?.tokenData?.tokenType}');
  print('AccessToken:${tokenResp?.tokenData?.accessToken}');
  print('RefreshToken:${tokenResp?.tokenData?.refreshToken}');
  print('Expired in:${tokenResp?.tokenData?.expiresIn} second');
}

// Get new Access Token using a refresh token.
Future<rdp_message.TokenResponse> GetNewToken(String refreshToken) async {
  var tokenResp =
      await rdp.getAuthenticationInfo(true, refreshToken: refreshToken);
  if (tokenResp.statusCode == 200) {
    PrintTokenInfo(tokenResp);
  } else {
    print(
        'HttpResponse Status Code:${tokenResp?.statusCode} ${tokenResp?.errorDescription}');
    print('Stop Timer');
    myTimer?.cancel();
  }
  return tokenResp;
}

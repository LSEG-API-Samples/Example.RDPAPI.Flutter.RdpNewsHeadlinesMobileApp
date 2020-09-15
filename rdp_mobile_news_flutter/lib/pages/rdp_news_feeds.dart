import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rdp_mobile_news_flutter/pages/rdp_news_details.dart';
import 'package:rdp_mobile_news_flutter/rdp/rdp_manager.dart' as rdp;
import 'package:rdp_mobile_news_flutter/rdp/rdp_message_data.dart'
    as rdpMsgData;

typedef cbOnLoadingStory = void Function(bool isLoading);

class NewsHeadlineFeeds extends StatefulWidget {
  NewsHeadlineFeeds(
      {Key key,
      @required this.newsHeadlinesList,
      //@required this.fetchMoreSizeCallback,
      @required this.rdpManager,
      @required this.mainScaffoldKey,
      @required this.onLoadingStory})
      : super(key: key);
  final rdp.RdpManager rdpManager;
  final List<rdpMsgData.NewContents> newsHeadlinesList;
  //final triggerFetchMoreSizeFunc fetchMoreSizeCallback;
  final GlobalKey<ScaffoldState> mainScaffoldKey;
  final cbOnLoadingStory onLoadingStory;
  @override
  _NewsHeadlineFeedsState createState() => _NewsHeadlineFeedsState();
}

class _NewsHeadlineFeedsState extends State<NewsHeadlineFeeds> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: this.widget.newsHeadlinesList.length,
      itemBuilder: (BuildContext context, int index) {
        return Card(
          elevation: 4,
          child: ListTile(
            onTap: () async {
              // Show message on SnackBar
              widget.onLoadingStory(true);
              widget.mainScaffoldKey.currentState.showSnackBar(SnackBar(
                content: Text('Fetch News Story...'),
              ));

              // Get News Story content
              var storyResp = await widget.rdpManager.getNewsStory(
                  widget.rdpManager.accessTokenInfo,
                  widget.newsHeadlinesList[index].storyId);

              // Verify if the response is Ok and then get the news story plain text.
              if (storyResp.statusCode == 200) {
                widget.newsHeadlinesList[index].storyData =
                    storyResp?.newsContent?.newsContent;
              }

              // Generate Html data to display on news detals page.
              var stringHtml = _generateHtmlContent(
                  widget.newsHeadlinesList[index].headlines,
                  widget.newsHeadlinesList[index].storyData);

              // Hide the message on SnackBar
              widget.mainScaffoldKey.currentState.removeCurrentSnackBar();
              widget.onLoadingStory(false);
              // Shows the Story page, passing news headline with news body to the page.
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NewsStory(
                          newsTitle: widget.newsHeadlinesList[index].headlines,
                          newsDetail: stringHtml,
                        )),
              );
            },
            title: Text(
              widget.newsHeadlinesList[index].headlines,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 3,
            ),
            leading: CircleAvatar(
              radius: 30.0,
              backgroundImage: AssetImage('assets/headline.png'),
              backgroundColor: Colors.transparent,
            ),
            subtitle: Container(
              padding: EdgeInsets.all(4),
              child: Text(
                widget.newsHeadlinesList[index].storyData,
                style: TextStyle(fontSize: 15),
                maxLines: 2,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFFB2B2B2),
            ),
          ),
        );
      },
    );
  }

  String _generateHtmlContent(String headline, String storyBody) {
    var htmlData =
        '<div><h1>$headline</h1></div><hr/><div><p>${storyBody?.replaceAll('\n', '</br>')}</br></br></br></br></p></div>';
    return htmlData;
  }
}

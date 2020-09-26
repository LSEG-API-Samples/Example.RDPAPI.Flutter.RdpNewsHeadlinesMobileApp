import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:rdp_mobile_news_flutter/rdp/rdp_manager.dart' as rdp;
import 'package:rdp_mobile_news_flutter/pages/rdp_login_page.dart';
import 'package:rdp_mobile_news_flutter/rdp/rdp_message_data.dart'
    as rdpMsgData;
import 'package:rdp_mobile_news_flutter/styles/stylepack.dart';
import 'package:rdp_mobile_news_flutter/pages/rdp_news_feeds.dart';

class RdpNewsMainPage extends StatefulWidget {
  final Timer myTimer;
  final rdp.RdpManager rdpManager;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  State<StatefulWidget> createState() => _RdpNewsMainPage();
  RdpNewsMainPage(this.myTimer, this.rdpManager);
}

class _RdpNewsMainPage extends State<RdpNewsMainPage> {
  List<rdpMsgData.NewContents> newsContentList =
      new List<rdpMsgData.NewContents>();
  bool isLoading = false;
  final TextEditingController _filter = new TextEditingController();
  Icon _searchIcon = new Icon(Icons.search);
  Widget _appBarTitle = new Text('News');
  String _keyword;
  String nextCursor;
  BottomNavigationBarItem expandMoreItem =
      BottomNavigationBarItem(icon: Icon(Icons.expand_more), label: '');
  bool expandMoreHeadlines = false;
  final FocusNode _searchBarFocusNode = new FocusNode();
  final String _defaultQuery =
      '(R:AAPL.O or R:MSFT.O or R:AMZN.O) and L:EN and searchIn:FullStory';
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
            key: widget._scaffoldKey,
            bottomNavigationBar: _buildBottomNavigationTab(),
            floatingActionButton: Visibility(
                visible: expandMoreHeadlines,
                child: FloatingActionButton(
                    backgroundColor: Color(0xFFFF5000),
                    onPressed: () {
                      if (expandMoreHeadlines) {
                        setState(() {
                          expandMoreHeadlines = false;
                          expandMoreItem = BottomNavigationBarItem(
                              icon: Icon(Icons.expand_more), label: '');
                        });
                        _fetchMoreHeadlines();
                      }
                    },
                    child: Icon(Icons.expand_more))),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            appBar: _buildAppBar(context),
            body: !isLoading
                ? NewsHeadlineFeeds(
                    newsHeadlinesList: this.newsContentList,
                    rdpManager: widget.rdpManager,
                    mainScaffoldKey: widget._scaffoldKey,
                    onLoadingStory: _onLoadingStory,
                  )
                : Center(child: CircularProgressIndicator())));
  }

  void _onLoadingStory(bool isLoadingStory) {
    setState(() {
      expandMoreHeadlines = !isLoadingStory;
    });
  }

  Widget _buildBottomNavigationTab() {
    return new BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        expandMoreItem,
        BottomNavigationBarItem(
          icon: Icon(Icons.exit_to_app),
          label: 'Logout',
        ),
      ],
      backgroundColor: Color(0xFF001EFF),
      selectedItemColor: Color(0xFFFFFFFF),
      unselectedItemColor: Color(0xFFFFFFFF),
      onTap: _bottomTabAction,
    );
  }

  void _bottomTabAction(int index) {
    print('Tab Pressed with index $index');
    switch (index) {
      case 0: // Home
        newsContentList.clear();
        _fetchNewsHeadlines(
            '(R:AAPL.O or R:MSFT.O or R:AMZN.O) and L:EN', true);

        break;
      case 1: // More news

        break;
      case 2: // Logout
        _logoutPressed();
        break;
    }
  }

  void _logoutPressed() {
    widget.myTimer.cancel();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void _showFetchNext() {
    if (!expandMoreHeadlines && nextCursor != null) {
      setState(() {
        expandMoreHeadlines = true;
        expandMoreItem = BottomNavigationBarItem(
          icon: Icon(Icons.expand_more),
          label: 'More Headlines',
        );
      });
    }
  }

  void _fetchMoreHeadlines() {
    if (!isLoading) {
      widget._scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Loading more news...'),
      ));
      print('Next =>${this.nextCursor}');
      _fetchNewsHeadlines(_keyword, false, true, this.nextCursor);
      widget._scaffoldKey.currentState.hideCurrentSnackBar();
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return new AppBar(
      centerTitle: true,
      backgroundColor: Color(0xFF001EFF),
      title: this._appBarTitle,
      leading: new IconButton(
        icon: _searchIcon,
        onPressed: (() {
          _searchPressed(context);
          _searchBarFocusNode.requestFocus();
        }),
      ),
    );
  }

  void _searchPressed(BuildContext context) async {
    setState(() {
      if (this._searchIcon.icon == Icons.search) {
        this._searchIcon = new Icon(Icons.close);
        this._appBarTitle = new TextField(
          style: wbLabelStyle,
          focusNode: _searchBarFocusNode,
          controller: _filter,
          decoration: new InputDecoration(
              prefixIcon: new Icon(Icons.search), hintText: 'Search...'),
          onSubmitted: (data) {
            if (data != null && data.isNotEmpty) {
              _fetchNewsHeadlines(data, true);
              this._searchIcon = new Icon(Icons.search);
              this._appBarTitle = new Text('News Headlines');
              _filter.clear();
            }
          },
        );
      } else {
        this._searchIcon = new Icon(Icons.search);
        this._appBarTitle = new Text('News Headlines');
        _filter.clear();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchNewsHeadlines(_defaultQuery, true);
  }

  void _fetchNewsHeadlines(String keyword, bool clearList,
      [bool useCursor, String nextCursor]) async {
    this._keyword = keyword;
    if (clearList) newsContentList.clear();
    setState(() => {isLoading = true});

    var tokenData = widget.rdpManager.accessTokenInfo;
    if (widget.rdpManager.accessTokenInfo != null) {
      var headlinesResp;
      if (nextCursor != null && useCursor && nextCursor.isNotEmpty)
        headlinesResp = await widget.rdpManager
            .getNewsHeadlines(tokenData, cursor: nextCursor);
      else
        headlinesResp =
            await widget.rdpManager.getNewsHeadlines(tokenData, query: keyword);
      if (headlinesResp.statusCode == 200) {
        // Get next Cursor
        this.nextCursor = headlinesResp.metaInfo.next;
        // Add headlines to the list
        headlinesResp.headlinesDatas.forEach((data) async {
          bool containObj = false;
          // Check if the list contains the storyId if not add it. Otherwise skip
          for (int i = 0; i < newsContentList.length; i++) {
            if (newsContentList[i].storyId == data.storyId) {
              containObj = true;
              break;
            }
          }
          if (!containObj) {
            var content = rdpMsgData.NewContents();
            content.headlines = data.titleText;
            content.storyId = data.storyId;
            print('Add headline:>> ${data.titleText} ${data.storyId}');
            content.storyData = '';
            newsContentList.add(content);
          } else {
            print("Found duplicate storyId: ${data.storyId} skip it");
          }
        });
        // If next cursor is not null or empty show button to get more headlines. Otherwise hide the button.
        if (this.nextCursor != null && this.nextCursor.isNotEmpty) {
          _showFetchNext();
        } else {
          setState(() {
            expandMoreHeadlines = false;
            expandMoreItem =
                BottomNavigationBarItem(icon: Icon(Icons.more_vert), label: '');
          });
        }
      } else {
        print(
            'Status Code is  ${(headlinesResp as rdpMsgData.NewsHeadlineResp)?.statusCode} call _backToLogin ${(headlinesResp as rdpMsgData.NewsHeadlineResp)?.errorDescription}');
        _backToLogin(context);
        return;
      }
      setState(() => {isLoading = false});
    } else {
      print("Access Token is null call _backToLogin");
      _backToLogin(context);
      return;
    }
  }
}

void _backToLogin(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => LoginScreen()),
  );
}

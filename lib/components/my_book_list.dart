import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:seek_book/book_site/book_site.dart';
import 'package:seek_book/components/book_img.dart';
import 'package:seek_book/pages/read_page.dart';
import 'package:seek_book/utils/status_bar.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:seek_book/globals.dart' as Globals;
import 'package:seek_book/utils/screen_adaptation.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyBookList extends StatefulWidget {
  MyBookList({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new MyBookListState();
  }
}

class MyBookListState extends State<MyBookList> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Map loadingMap = Map();

  List bookList = [];

  @override
  void initState() {
    super.initState();
    this.loadData();
  }

  Future<Null> _handleRefresh() async {
//    final Completer<Null> completer = Completer<Null>();
//    Timer(const Duration(seconds: 3), () {
//      completer.complete(null);
//    });
//    _refreshIndicatorKey.currentState.show();
    refreshChapter();
  }

  refreshChapter() async {
    await loadData();
    Iterable requestList = bookList.map((book) {
      loadingMap[book['id']] = true;
      return refreshBook(book);
    }).toList();
    setState(() {});
//    await Future.delayed(Duration(milliseconds: 3000));
    await Future.wait(requestList);
  }

  Future<dynamic> refreshBook(book) async {
//    var bookNewxxx = await BookSiteKenWen().ddd(
//      book['name'],
//      book['author'],
//      book['url'],
//    );
//    return;
    var bookNew = await BookSite().bookDetail(
      book['name'],
      book['author'],
      book['url'],
      BookSite.findSiteRule(book['siteHost']),
    );
    if (bookNew == null) {
      setState(() {
        loadingMap.remove(book['id']);
      });
      return;
    }
//    if (bookNew['updateTime'] != book['updateTime'] || true) {
//    setState(() {
    loadingMap.remove(book['id']);
//    if (bookNew['updateTime'] != book['updateTime'] &&
//        book['chapters'] != null) {
//      book['chapterList'] = json.decode(book['chapters']);
//    }
    book['updateTime'] = bookNew['updateTime'];
    book['hasNew'] = bookNew['hasNew'];
    book['imgUrl'] = bookNew['imgUrl'];
    book['chapters'] = bookNew['chapters'];
    book['chapterList'] = bookNew['chapterList'];
//    });
//    callbackTime = DateTime.now().millisecondsSinceEpoch;
//    print("可以刷了");
//    await Future.delayed(Duration(milliseconds: 500));
//    if (DateTime.now().millisecondsSinceEpoch < callbackTime + 500) {
//      print("中断");
//      return;
//    }
    print('刷新');
    setState(() {});
  }

//  var callbackTime = DateTime.now().millisecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    print("build 书籍列表");
    final ThemeData theme = Theme.of(context);
    bookList.sort((b, a) => (a['updateTime'] ?? 0) - (b['updateTime'] ?? 0));
    print(bookList.length);
    return Container(
      child: RefreshIndicator(
        color: theme.primaryColor,
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        child: ListView.builder(
          itemCount: bookList.length,
          itemBuilder: buildRow,
        ),
      ),
    );
  }

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
//        _scaffoldKey.currentState.showSnackBar(SnackBar(
//            content: Text('You selected: $value')
//        ));
      }
    });
  }

  void showRowChoice(context, Map item) {
    final ThemeData theme = Theme.of(context);
    var title = item['name'];
    print(item['currentChapterIndex']);
    showDemoDialog<String>(
      context: context,
      child: SimpleDialog(
        title: Container(
          padding: EdgeInsets.only(bottom: dp(20)),
          child: Text(
            '$title',
            style: TextStyle(fontSize: dp(17), color: theme.primaryColor),
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey)),
          ),
        ),
        children: <Widget>[
          DialogRowItem(
            icon: Icons.account_circle,
            color: theme.primaryColor,
            text: '置顶',
            onPressed: () {
              Navigator.pop(context, 'username@gmail.com');
            },
          ),
          DialogRowItem(
            icon: Icons.account_circle,
            color: theme.primaryColor,
            text: '书籍详情',
            onPressed: () {
              Navigator.pop(context, 'user02@gmail.com');
            },
          ),
          DialogRowItem(
            icon: Icons.account_circle,
            color: theme.primaryColor,
            text: '删除',
            onPressed: () {
              Navigator.pop(context, 'user02@gmail.com');
              deleteBook(item);
            },
          ),
//              DialogDemoItem(
//                  icon: Icons.add_circle,
//                  text: 'add account',
//                  color: theme.disabledColor
//              )
        ],
      ),
    );
  }

  Widget buildRow(context, index) {
    final ThemeData theme = Theme.of(context);

    var item = bookList[index];
    var latestChapter = '';
    if (item['chapterList'].length > 0) {
      latestChapter =
          item['chapterList'][item['chapterList'].length - 1]['title'];
    }

    var infoRow = <Widget>[
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
//          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Text(
              "${item['name'].trim()}",
              style: TextStyle(
                fontSize: dp(16),
              ),
            ),
            Text(
              "${latestChapter}",
              style: TextStyle(
                fontSize: dp(12),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ];
    var bookInfoRow = <Widget>[
      Container(
        child: BookImg(
          imgUrl: item['imgUrl'],
//          width: dp(60),
        ),
        margin: EdgeInsets.symmetric(horizontal: dp(20)),
      ),
      Expanded(
        child: Container(
//          margin: EdgeInsets.only(left: dp(10)),
          padding: EdgeInsets.only(right: dp(10)),
          child: Row(
            children: infoRow,
          ),
          decoration: BoxDecoration(
//            color: Color(0xFFff0000),
            border: Border(
              bottom: BorderSide(
                color: index == (bookList.length - 1)
                    ? Colors.transparent
                    : Color(0xFFdddddd),
//                width: 1,
              ),
            ),
          ),
        ),
      ),
    ];
//    print("build  ----  ${item['hasNew']}, ${item['name']}");
//    if (item['hasNew'] == 1 || true) {
    if (loadingMap[item['id']] == true) {
      var dotWidth = dp(10);
      infoRow.add(
//        CupertinoActivityIndicator(
//          radius: dp(20),
//        ),
        Container(
          child: FittedBox(
//            child: CircularProgressIndicator(),
            child: CupertinoActivityIndicator(),
          ),
          width: dp(20),
        ),
      );
    } else if (item['hasNew'] == 1) {
      var dotWidth = dp(8);
      infoRow.add(Container(
        width: dp(20),
        height: dp(20),
        alignment: Alignment.center,
        child: Container(
          width: dotWidth,
          height: dotWidth,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.all(Radius.circular(dotWidth / 2)),
          ),
        ),
      ));
    }
    return new GestureDetector(
      onTap: () async {
//        print(item['currentPageIndex']);
//        return;
        await Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ReadPage(bookInfo: item),
          ),
        );
        StatusBar.show();
        await Future.delayed(Duration(milliseconds: 350));
        loadData();
      },
      onLongPress: () {
//        SimpleDialog
        showRowChoice(context, item);
      },
      child: Container(
        height: dp(100),
        color: Color(0x00FFFFFF),
//        width: ScreenAdaptation.screenWidth,
//        color: Colors.green.withOpacity(0.1),
        child: Row(
          children: bookInfoRow,
        ),
      ),
    );
  }

  Future<Null> loadData() async {
//    var database = Globals.database;
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, "seek_book.db");

    var database = await openDatabase(path);
    List<Map> list = await database.rawQuery(
        'SELECT * FROM Book where active=? order by updateTime desc', [1]);
    list = list.map((it) {
      print(it['chapters']);
      return {
        'id': it['id'],
        'name': it['name'],
        'author': it['author'],
        'url': it['url'],
        'updateTime': it['updateTime'],
        'imgUrl': it['imgUrl'],
        'chapterList':
            it['chapters'] == null ? [] : json.decode(it['chapters']),
        'site': it['site'],
        'currentPageIndex': it['currentPageIndex'],
        'currentChapterIndex': it['currentChapterIndex'],
        'active': it['active'],
        'hasNew': it['hasNew'],
        'siteName': it['siteName'],
        'siteHost': it['siteHost'],
      };
    }).toList();
    setState(() {
      bookList = list;
    });
  }

  void deleteBook(Map item) async {
//    await Globals.database.update(
//      'Book',
//      {'active': false},
//      where: 'name=? and author=?',
//      whereArgs: [item['name'], item['author']],
//    );
    await Globals.database.delete(
      'Book',
      where: 'name=? and author=?',
      whereArgs: [item['name'], item['author']],
    );
    this.loadData();
  }
}

class DialogRowItem extends StatelessWidget {
  const DialogRowItem(
      {Key key, this.icon, this.color, this.text, this.onPressed})
      : super(key: key);

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
//          Icon(icon, size: 36.0, color: color),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

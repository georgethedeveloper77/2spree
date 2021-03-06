import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:reddigram/models/models.dart';
import 'package:reddigram/screens/screens.dart';
import 'package:reddigram/store/store.dart';
import 'package:reddigram/widgets/loaders/ColorLoader3.dart';
import 'package:reddigram/widgets/widgets.dart';
import 'package:redux/redux.dart';

class FeedTab extends StatefulWidget {
  final String feedName;
  final Key infiniteListKey;
  final Widget placeholder;

  const FeedTab(
      {Key key,
      @required this.feedName,
      this.infiniteListKey,
      this.placeholder = const SizedBox()})
      : assert(feedName != null),
        assert(placeholder != null),
        super(key: key);

  @override
  _FeedTabState createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  Set<String> _shownNsfwIds = Set();

  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReddigramState, _BodyViewModel>(
      converter: (store) => _BodyViewModel.fromStore(store, widget.feedName),
      builder: (context, vm) {
        return RefreshIndicator(
          onRefresh: () {
            final completer = Completer();
            vm.fetchFresh(completer);

            return completer.future;
          },
          child: vm.photos.isNotEmpty
              ? InfiniteList(
                  key: widget.infiniteListKey,
                  keepAlive: true,
                  fetchMore: vm.fetchMore,
                  itemCount: vm.photos.length + 1,
                  itemBuilder: (context, i) {
                    // Last item is a loading indicator.
                    if (i == vm.photos.length) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 32.0),
                        alignment: Alignment.center,
                        child: ColorLoader3(),
                      );
                    }

                    return _buildPhoto(context, i);
                  },
                )
              : widget.placeholder,
        );
      },
    );
  }

  Widget _buildPhoto(BuildContext context, int index) {
    return StoreConnector<ReddigramState, _PhotoViewModel>(
      converter: (store) =>
          _PhotoViewModel.fromStore(store, widget.feedName, index),
      builder: (context, vm) => PhotoListItem(
        photo: vm.photo,
        subreddit: vm.subreddit,
        upvotingEnabled: vm.authenticated,
        onUpvote: vm.onUpvote,
        onUpvoteCanceled: vm.onUpvoteCanceled,
        onPhotoTap: () =>
            Navigator.push(context, PhotoPreviewScreen.route(vm.photo)),
        onSubredditTap: () => Navigator.push(
            context, SubredditScreen.route(vm.photo.subredditId)),
        showNsfw: _shownNsfwIds.contains(vm.photo.id) ||
            PreferencesProvider.of(context).showNsfw,
        onShowNsfw: () => setState(() => _shownNsfwIds.add(vm.photo.id)),
      ),
    );
  }
}

class _BodyViewModel {
  final List<Photo> photos;
  final void Function(Completer) fetchFresh;
  final void Function(Completer) fetchMore;

  _BodyViewModel(
      {@required this.photos,
      @required this.fetchFresh,
      @required this.fetchMore})
      : assert(photos != null),
        assert(fetchFresh != null),
        assert(fetchMore != null);

  factory _BodyViewModel.fromStore(
      Store<ReddigramState> store, String feedName) {
    return _BodyViewModel(
      photos: store.state.feeds[feedName].photosIds
          .map((photoId) => store.state.photos[photoId])
          .toList(),
      fetchFresh: (completer) =>
          store.dispatch(fetchFreshFeed(feedName, completer: completer)),
      fetchMore: (completer) =>
          store.dispatch(fetchMoreFeed(feedName, completer: completer)),
    );
  }
}

class _PhotoViewModel {
  final bool authenticated;
  final Photo photo;
  final Subreddit subreddit;
  final VoidCallback onUpvote;
  final VoidCallback onUpvoteCanceled;

  _PhotoViewModel(
      {@required this.authenticated,
      @required this.photo,
      @required this.subreddit,
      @required this.onUpvote,
      @required this.onUpvoteCanceled})
      : assert(authenticated != null),
        assert(photo != null);

  factory _PhotoViewModel.fromStore(
      Store<ReddigramState> store, String feedName, int index) {
    final photoId = store.state.feeds[feedName].photosIds[index];
    final photo = store.state.photos[photoId];
    final subreddit = store.state.subreddits[photo.subredditId];

    return _PhotoViewModel(
      authenticated: store.state.authState.status == AuthStatus.authenticated,
      photo: photo,
      subreddit: subreddit,
      onUpvote: () => store.dispatch(upvote(photo)),
      onUpvoteCanceled: () => store.dispatch(cancelUpvote(photo)),
    );
  }
}

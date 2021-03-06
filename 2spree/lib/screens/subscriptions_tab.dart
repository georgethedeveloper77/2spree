import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:reddigram/models/models.dart';
import 'package:reddigram/screens/screens.dart';
import 'package:reddigram/store/store.dart';
import 'package:reddigram/widgets/widgets.dart';
import 'package:redux/redux.dart';

class SubscriptionsTab extends StatefulWidget {
  const SubscriptionsTab({Key key}) : super(key: key);

  @override
  _SubscriptionsTabState createState() => _SubscriptionsTabState();
}

class _SubscriptionsTabState extends State<SubscriptionsTab>
    with AutomaticKeepAliveClientMixin {
  ModalRoute<dynamic> _route;
  bool _searchFocused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route?.removeScopedWillPopCallback(_shouldPopRoute);
    _route = ModalRoute.of(context);
    _route?.addScopedWillPopCallback(_shouldPopRoute);
  }

  @override
  void dispose() {
    _route?.removeScopedWillPopCallback(_shouldPopRoute);
    _route = null;
    super.dispose();
  }

  Future<bool> _shouldPopRoute() async {
    if (_searchFocused) {
      _unfocusSearch();
      return false;
    }

    return true;
  }

  void _focusSearch() {
    setState(() {
      _searchFocused = true;
      updateKeepAlive();
    });
  }

  void _unfocusSearch() {
    setState(() {
      _searchFocused = false;
      updateKeepAlive();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return _searchFocused
        ? _SearchView(onSearchDismiss: _unfocusSearch)
        : _SubscriptionsView(onSearchTap: _focusSearch);
  }

  @override
  bool get wantKeepAlive => !_searchFocused;
}

class _SubscriptionsView extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _SubscriptionsView({Key key, this.onSearchTap}) : super(key: key);

  void _unsubscribe(
      BuildContext context, String subreddit, VoidCallback callback) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsubscribing'),
          content: Text('Do you really want to Unsubscribe from r/$subreddit?'),
          actions: [
            FlatButton(
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.green),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            FlatButton(
              child: const Text('UNSUBSCRIBE'),
              onPressed: () {
                Navigator.of(context).pop();
                callback();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final divider = const SizedBox(height: 32.0);

    return StoreConnector<ReddigramState, _SubredditsViewModel>(
      converter: (store) => _SubredditsViewModel.fromStore(store),
      builder: (context, vm) => ListView(
        children: [
          ListTile(
            onTap: onSearchTap,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                Icons.search,
                color: Theme.of(context).textTheme.body1.color,
              ),
            ),
            title: const Text(
              'Search for anything',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
            ),
          ),
          StoreConnector<ReddigramState, bool>(
            converter: (store) =>
                store.state.authState.status == AuthStatus.authenticated,
            builder: (context, signedIn) => signedIn
                ? ListTile(
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.cloud_download,
                        color: Theme.of(context).textTheme.body1.color,
                      ),
                    ),
                    title: const Text(
                      'Import subscriptions from Reddit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => Navigator.push(
                        context, ImportSubscriptionsScreen.route()),
                  )
                : const SizedBox(),
          ),
          divider,
          ..._buildSubscriptions(context, vm),
          divider,
          _buildSuggestions(context),
        ],
      ),
    );
  }

  List<Widget> _buildSubscriptions(
      BuildContext context, _SubredditsViewModel vm) {
    return [
      const ListTile(
        title: Text(
          'Subscriptions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      ...vm.subreddits
          .map((subredditId) => StoreConnector<ReddigramState, Subreddit>(
                key: Key(subredditId),
                converter: (store) => store.state.subreddits[subredditId],
                builder: (context, subreddit) => subreddit != null
                    ? SubredditListTile(
                        subreddit: subreddit,
                        subscribed: true,
                        onTap: () => Navigator.push(
                            context, SubredditScreen.route(subreddit.id)),
                        onUnsubscribe: () => _unsubscribe(
                          context,
                          subreddit.name,
                          () => vm.unsubscribe(subreddit.id),
                        ),
                      )
                    : const SizedBox(),
              ))
          .toList(),
      if (vm.subreddits.isEmpty)
        const ListTile(
          leading: Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.sentiment_very_dissatisfied),
          ),
          title: Text('No Subscriptions. Join some groups!'),
        ),
    ];
  }

  Widget _buildSuggestions(BuildContext context) {
    return StoreConnector<ReddigramState, _SubredditsViewModel>(
      converter: (store) => _SubredditsViewModel.fromStoreSuggested(store),
      builder: (context, vm) {
        return Column(
          children: [
            const ListTile(
              title: Text(
                '', //You may also like
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            /*if (vm.subreddits.isEmpty)
              const ListTile(
                leading: Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.sentiment_dissatisfied),
                ),
                title: Text('No suggestions available'),
              ),
            ...vm.subreddits
                .map((subredditId) => StoreConnector<ReddigramState, Subreddit>(
                      key: Key('suggestion_$subredditId'),
                      converter: (store) => store.state.subreddits[subredditId],
                      builder: (context, subreddit) => subreddit != null
                          ? SubredditListTile(
                              subreddit: subreddit,
                              subscribed: false,
                              onTap: () => Navigator.push(
                                context,
                                SubredditScreen.route(subreddit.id),
                              ),
                              onSubscribe: () => vm.subscribe(subredditId),
                            )
                          : const SizedBox(),
                    ))
                .toList(),*/
          ],
        );
      },
    );
  }
}

class _SubredditsViewModel {
  final List<String> subreddits;
  final void Function(String) subscribe;
  final void Function(String) unsubscribe;

  _SubredditsViewModel(
      {@required this.subreddits,
      @required this.subscribe,
      @required this.unsubscribe})
      : assert(subreddits != null),
        assert(subscribe != null),
        assert(unsubscribe != null);

  factory _SubredditsViewModel.fromStore(Store<ReddigramState> store) {
    return _SubredditsViewModel(
      subreddits: store.state.subscriptions.toList(),
      subscribe: (subredditId) =>
          store.dispatch(subscribeSubreddit(subredditId)),
      unsubscribe: (subredditId) =>
          store.dispatch(unsubscribeSubreddit(subredditId)),
    );
  }

  factory _SubredditsViewModel.fromStoreSuggested(Store<ReddigramState> store) {
    return _SubredditsViewModel(
      subreddits: store.state.suggestedSubscriptions
          .where(
              (suggestion) => !store.state.subscriptions.contains(suggestion))
          .toList(),
      subscribe: (subredditId) =>
          store.dispatch(subscribeSubreddit(subredditId)),
      unsubscribe: (subredditId) =>
          store.dispatch(unsubscribeSubreddit(subredditId)),
    );
  }
}

class _SearchView extends StatefulWidget {
  final VoidCallback onSearchDismiss;

  const _SearchView({Key key, this.onSearchDismiss}) : super(key: key);

  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _searchFocusNode = FocusNode();
  final _searchController = TextEditingController();

  static const _debounceDuration = const Duration(milliseconds: 500);

  Timer _debounce;
  bool _loading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _searchQueryChanged(String query, Store<ReddigramState> store) {
    if (_debounce?.isActive ?? false) {
      _debounce.cancel();
    }

    _debounce = Timer(_debounceDuration, () {
      if (_lastQuery != query && query.isNotEmpty) {
        setState(() => _loading = true);

        final completer = Completer()
          ..future.then((_) => setState(() => _loading = false));
        store.dispatch(searchSubreddits(query, completer: completer));
        _lastQuery = query;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          autofocus: true,
          focusNode: _searchFocusNode,
          controller: _searchController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Search subreddits',
            hintStyle: const TextStyle(fontWeight: FontWeight.bold),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 1),
              child: Icon(
                Icons.search,
                color: Theme.of(context).textTheme.body1.color,
              ),
            ),
            suffixIcon: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSearchDismiss,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.close),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        _loading
            ? Transform(
                // Scale Y
                transform: Matrix4.diagonal3Values(1, .5, 1),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                ),
              )
            : const SizedBox(height: 6),
        Expanded(
          child: StoreConnector<ReddigramState, _SearchViewModel>(
            onInit: (store) {
              store.dispatch(ClearSearch());

              _searchController.addListener(
                  () => _searchQueryChanged(_searchController.text, store));
            },
            converter: (store) => _SearchViewModel.fromStore(store),
            builder: (context, vm) => ListView.builder(
              itemCount: vm.subreddits.length,
              itemBuilder: (context, i) {
                final subreddit = vm.subreddits[i];

                return StoreConnector<ReddigramState, bool>(
                  converter: (store) => store.state.subscriptions
                      .any((subscription) => subscription == subreddit.id),
                  builder: (context, subscribed) => SubredditListTile(
                    subreddit: subreddit,
                    subscribed: subscribed,
                    onTap: () => Navigator.push(
                      context,
                      SubredditScreen.route(subreddit.id),
                    ),
                    onSubscribe: () => vm.subscribe(subreddit.id),
                    onUnsubscribe: () => vm.unsubscribe(subreddit.id),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchViewModel {
  final SubredditsSearchState state;
  final List<Subreddit> subreddits;
  final Function(String) subscribe;
  final Function(String) unsubscribe;

  _SearchViewModel(
      {@required this.state,
      @required this.subreddits,
      @required this.subscribe,
      @required this.unsubscribe})
      : assert(state != null),
        assert(subreddits != null),
        assert(subscribe != null),
        assert(unsubscribe != null);

  factory _SearchViewModel.fromStore(Store<ReddigramState> store) {
    return _SearchViewModel(
      state: store.state.subredditsSearch,
      subreddits: store.state.subredditsSearch.resultFeedsIds
          .map((subredditId) => store.state.subreddits[subredditId])
          .toList(),
      subscribe: (id) => store.dispatch(subscribeSubreddit(id)),
      unsubscribe: (id) => store.dispatch(unsubscribeSubreddit(id)),
    );
  }
}

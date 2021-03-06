import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:reddigram/store/store.dart';
import 'package:reddigram/widgets/widgets.dart';

class ShowNsfwPreferenceTile extends StatelessWidget {
  const ShowNsfwPreferenceTile({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<ReddigramState, PreferenceViewModel>(
      converter: (store) => PreferenceViewModel<bool>(
        value: store.state.preferences.showNsfw,
        onSwitch: (showNsfw) => store.dispatch(setShowNsfw(showNsfw)),
      ),
      builder: (context, vm) => SwitchListTile(
        title: const Text(
          'Show Adult Content',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
        secondary: const Icon(Icons.block),
        value: vm.value,
        onChanged: vm.onSwitch,
      ),
    );
  }
}

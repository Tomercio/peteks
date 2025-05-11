import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget {
  final String title;
  final List<Widget>? actions;
  final bool showSearchBar;
  final TextEditingController? searchController;
  final Function(String)? onSearch;
  final bool centerTitle;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showSearchBar = false,
    this.searchController,
    this.onSearch,
    this.centerTitle = true,
    this.automaticallyImplyLeading = true,
    this.leading,
  });

  @override
  CustomAppBarState createState() => CustomAppBarState();
}

class CustomAppBarState extends State<CustomAppBar> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      centerTitle: widget.centerTitle,
      automaticallyImplyLeading: widget.automaticallyImplyLeading,
      leading: widget.leading,
      title: _isSearching
          ? _buildSearchField()
          : Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
      actions: [
        if (widget.showSearchBar)
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  widget.searchController?.clear();
                  if (widget.onSearch != null) {
                    widget.onSearch!('');
                  }
                } else {
                  // Focus the search field
                  FocusScope.of(context).requestFocus(FocusNode());
                }
              });
            },
          ),
        if (!_isSearching && widget.actions != null) ...widget.actions!,
      ],
      elevation: 0,
      expandedHeight: 0,
      forceElevated: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: widget.searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search notes...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Theme.of(context).hintColor),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: widget.onSearch,
    );
  }
}

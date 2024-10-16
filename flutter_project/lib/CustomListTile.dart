import 'package:flutter/material.dart';

class CustomListTile extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final VoidCallback? onTap;

  const CustomListTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingIcon,
    this.trailingIcon,
    required this.onTap,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            if (leadingIcon != null) leadingIcon!,  // Show leading icon if not null
            if (leadingIcon != null) SizedBox(width: 16.0),  // Add space only if leading icon is present
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title!,
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 14.0, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (trailingIcon != null) SizedBox(width: 16.0),  // Add space only if trailing icon is present
            if (trailingIcon != null) trailingIcon!,  // Show trailing icon if not null
          ],
        ),
      ),
    );
  }
}
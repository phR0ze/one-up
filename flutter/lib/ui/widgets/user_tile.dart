import 'package:flutter/material.dart';
import '../../const.dart';
import '../../model/user.dart';

/// UserTile is responsible for displaying a user with their points.
/// - includes the user title
/// - aggregate positive and negative points
/// - onTap to trigger the user points editor
class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.user,
    required this.order,
    this.onTap,
  });

  /// User object to use as the data source
  final User user;

  /// Order of the user in the list, used to display medals
  final int order;

  /// Callback used for the onTap event
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pointStyle = theme.textTheme.titleLarge!.copyWith(
        color: theme.colorScheme.onPrimary,
    );
    final userStyle = theme.textTheme.displaySmall;

    var posPoints = user.points.where((x) => x.value > 0).fold(0, (a, v) => a + v.value);
    var negPoints = user.points.where((x) => x.value < 0).fold(0, (a, v) => a + v.value);

    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Const.userTileBorderRadius),
            border: Border.all(color: Const.userTileBorderColor, width: 2),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(Const.userTileBorderRadius),
            child: Row(
              children: [
        
                // User face and star
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.black12, width: 2),
                        ),
                        child: Icon(Icons.person,
                          size: 120,
                          color: Colors.blue[200]
                        ),
                      ),
                      if (order == 0) Positioned(
                        top: Const.userTileGoldMedalTop,
                        left: Const.userTileGoldMedalLeft,
                        child: Const.userTileGoldMedal
                      ),
                      if (order == 1) Positioned(
                        top: Const.userTileSilverMedalTop,
                        left: Const.userTileSilverMedalLeft,
                        child: Const.userTileSilverMedal
                      ),
                      if (order == 2) Positioned(
                        top: Const.userTileBronzeMedalTop,
                        left: Const.userTileBronzeMedalLeft,
                        child: Const.userTileBronzeMedal
                      ),
                    ],
                  ),
                ),
        
                // User name and points
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                  
                      // User name
                      Align(child: Text(user.name, style: userStyle)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                  
                          // Positive points
                          Card(
                            color: Const.posPointsBgColor,
                            child: Padding(
                            padding: const EdgeInsets.all(Const.pointCardPadding),
                            child: SizedBox(
                                width: Const.pointCardWidth,
                                child: Center(
                                    child: Text(posPoints.toString(), style: pointStyle))),
                            )
                          ),
                  
                          // Negative points
                          Card(
                            color: Const.negPointsBgColor,
                            child: Padding(
                              padding: const EdgeInsets.all(Const.pointCardPadding),
                              child: SizedBox(
                                width: Const.pointCardWidth,
                                child: Center(
                                  child: Text(negPoints.toString(), style: pointStyle))),
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ),  
              ],
            ),

            // Activate the user points editor
            onTap: onTap?.call,
          ),
        ),
      ],
    );
  }
}

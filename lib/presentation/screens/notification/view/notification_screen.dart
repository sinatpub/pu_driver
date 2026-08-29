import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart' hide Trans;
import 'package:tara_driver_application/core/routing/app_routes.dart';
import 'package:tara_driver_application/core/routing/route_arguments.dart';
import 'package:tara_driver_application/core/theme/colors.dart';
import 'package:tara_driver_application/core/theme/text_styles.dart';
import 'package:tara_driver_application/presentation/blocs/notification_bloc.dart';
import 'package:tara_driver_application/presentation/widgets/simmer_widget.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final ScrollController _scrollController = ScrollController();
  late NotificationBloc notificationBloc;

  @override
  void initState() {
    super.initState();
    notificationBloc = NotificationBloc();
    notificationBloc.add(FetchPaginatedData());
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        notificationBloc.add(FetchPaginatedData());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: Text("CHANNEL".tr()),
        centerTitle: true,
      ),
      body: Container(
        color: AppColors.light2,
        child: BlocBuilder<NotificationBloc, NotificationState>(
          bloc: notificationBloc,
          builder: (context, state) {
            if (state is NotificationLoading &&
                notificationBloc.allItems.isEmpty) {
              return const ShimmerNotification();
            } else if (state is NotificationError) {
              return Center(child: Text(state.message));
            } else if (state is NotificationLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  notificationBloc.add(RefreshPaginatedData());
                },
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.items.length + (state.hasReachedMax ? 0 : 1),
                  itemBuilder: (context, index) {
                    if (index < state.items.length) {
                      final item = state.items[index];
                      return MaterialButton(
                        elevation: 0,
                        padding: EdgeInsets.all(12),
                        onPressed: () {
                          Get.toNamed(
                            AppRoutes.notificationDetail,
                            arguments: NotificationDetailArgs(
                              notificationId: item.id.toString(),
                              appOpened: true,
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color:
                            item.status == 0 ? AppColors.light4 : Colors.white,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.notifications_active,
                                color: AppColors.success, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title.toString(),
                                          style: ThemeConstands.font16SemiBold,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        item.releaseDate.toString(),
                                        style: ThemeConstands.font14Regular
                                            .copyWith(
                                          color: Colors.grey,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description.toString(),
                                    style:
                                        ThemeConstands.font14Regular.copyWith(
                                      color: Colors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  // Row(
                                  //   children: [
                                  //     if (item.action1.isNotEmpty)
                                  //       TextButton(
                                  //         onPressed: () {},
                                  //         child: Text(item.action1),
                                  //       ),
                                  //     if (item.action2.isNotEmpty)
                                  //       TextButton(
                                  //         onPressed: () {},
                                  //         child: Text(item.action2),
                                  //       ),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Center(
                        child: state.items.length < 10
                            ? Container()
                            : CircularProgressIndicator());
                  },
                ),
              );
            }
            if (state is NotificationError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

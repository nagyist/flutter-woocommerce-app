//  Label StoreMax
//
//  Created by Anthony Gordon.
//  2024, WooSignal Ltd. All rights reserved.
//

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '/app/controllers/product_loader_controller.dart';
import '/bootstrap/helpers.dart';
import '/resources/widgets/cached_image_widget.dart';
import '/resources/widgets/home_drawer_widget.dart';
import '/resources/widgets/no_results_for_products_widget.dart';
import '/resources/widgets/safearea_widget.dart';
import '/resources/widgets/woosignal_ui.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:woosignal/models/response/woosignal_app.dart';
import 'package:woosignal/models/response/product_category.dart' as ws_category;
import 'package:woosignal/models/response/product.dart' as ws_product;

class NoticHomeWidget extends StatefulWidget {
  NoticHomeWidget({super.key, required this.wooSignalApp});

  final WooSignalApp? wooSignalApp;

  @override
  createState() => _NoticHomeWidgetState();
}

class _NoticHomeWidgetState extends NyState<NoticHomeWidget> {
  Widget? activeWidget;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  final ProductLoaderController _productLoaderController =
      ProductLoaderController();
  List<ws_category.ProductCategory> _categories = [];

  bool _shouldStopRequests = false;
  
  @override
  boot() async {
    await _home();
  }

  _home() async {
    await fetchProducts();
    await _fetchCategories();
  }

  _fetchCategories() async {
    _categories =
        await (appWooSignal((api) => api.getProductCategories(perPage: 100)));
  }

  _modalBottomSheetMenu() {
    wsModalBottom(
      context,
      title: trans("Categories"),
      bodyWidget: ListView.separated(
        itemCount: _categories.length,
        separatorBuilder: (cxt, i) => Divider(),
        itemBuilder: (BuildContext context, int index) => ListTile(
          title: Text(parseHtmlString(_categories[index].name)),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/browse-category",
                    arguments: _categories[index])
                .then((value) => setState(() {}));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<ws_product.Product> products = _productLoaderController.getResults();
    return Scaffold(
      drawer: HomeDrawerWidget(wooSignalApp: widget.wooSignalApp),
      appBar: AppBar(
        title: StoreLogo(height: 55),
        centerTitle: true,
        actions: [
          Center(
            child: Container(
              margin: EdgeInsets.only(right: 8),
              child: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: _modalBottomSheetMenu,
                child: Text(
                  trans("Categories"),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeAreaWidget(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: afterLoad(child: () => ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    margin: EdgeInsets.only(bottom: 15),
                    child: Swiper(
                      itemBuilder: (BuildContext context, int index) {
                        return CachedImageWidget(
                          image:
                          widget.wooSignalApp!.bannerImages![index],
                          fit: BoxFit.cover,
                        );
                      },
                      itemCount:
                      widget.wooSignalApp!.bannerImages!.length,
                      viewportFraction: 0.8,
                      scale: 0.9,
                    ),
                    height: MediaQuery.of(context).size.height / 2.5,
                  ),
                  Container(
                    height: 75,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(trans("Must have")),
                        Flexible(
                          child: Text(
                            trans("Our selection of new items"),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: 380,
                    child: SmartRefresher(
                      enablePullDown: true,
                      enablePullUp: true,
                      footer: CustomFooter(
                        builder:
                            (BuildContext context, LoadStatus? mode) {
                          Widget body;
                          if (mode == LoadStatus.idle) {
                            body = Text(trans("pull up load"));
                          } else if (mode == LoadStatus.loading) {
                            body = CupertinoActivityIndicator();
                          } else if (mode == LoadStatus.failed) {
                            body =
                                Text(trans("Load Failed! Click retry!"));
                          } else if (mode == LoadStatus.canLoading) {
                            body = Text(trans("release to load more"));
                          } else {
                            return SizedBox.shrink();
                          }
                          return Container(
                            height: 55.0,
                            child: Center(child: body),
                          );
                        },
                      ),
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      onLoading: _onLoading,
                      child: (products.isNotEmpty
                          ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: false,
                        itemBuilder: (cxt, i) {
                          return Container(
                            width:
                            MediaQuery.of(context).size.width /
                                2.5,
                            child: ProductItemContainer(
                                product: products[i],
                                onTap: _showProduct),
                          );
                        },
                        itemCount: products.length,
                      )
                          : NoResultsForProductsWidget()),
                    ),
                  )
                ],
              ),
            ),flex: 1,),
          ],
        ),
      ),
    );
  }

  _onRefresh() async {
    _productLoaderController.clear();
    await fetchProducts();

    setState(() {
      _shouldStopRequests = false;
      _refreshController.refreshCompleted(resetFooterState: true);
    });
  }

  _onLoading() async {
    await fetchProducts();

    if (mounted) {
      setState(() {});
      if (_shouldStopRequests) {
        _refreshController.loadNoData();
      } else {
        _refreshController.loadComplete();
      }
    }
  }

  Future fetchProducts() async {
    await _productLoaderController.loadProducts(
        hasResults: (result) {
          if (result == false) {
            setState(() {
              _shouldStopRequests = true;
            });
            return false;
          }
          return true;
        },
        didFinish: () => setState(() {}));
  }

  _showProduct(ws_product.Product product) =>
      Navigator.pushNamed(context, "/product-detail", arguments: product);
}

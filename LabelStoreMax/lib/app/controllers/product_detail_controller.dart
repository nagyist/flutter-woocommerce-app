//  Label StoreMax
//
//  Created by Anthony Gordon.
//  2024, WooSignal Ltd. All rights reserved.
//

//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.

import 'package:flutter/material.dart';
import '/app/models/cart.dart';
import '/app/models/cart_line_item.dart';
import '/bootstrap/enums/wishlist_action_enums.dart';
import '/bootstrap/helpers.dart';
import '/resources/widgets/cart_quantity_widget.dart';
import '/resources/widgets/product_quantity_widget.dart';
import 'package:nylo_framework/nylo_framework.dart';
import 'package:woosignal/models/response/product.dart';
import 'package:woosignal/models/response/product_variation.dart'
    as ws_product_variation;

import 'controller.dart';

class ProductDetailController extends Controller {
  int quantity = 1;
  Product? product;

  @override
  construct(BuildContext context) {
    super.construct(context);
    product = data() as Product?;
  }

  viewExternalProduct() {
    if (product!.externalUrl != null && product!.externalUrl!.isNotEmpty) {
      openBrowserTab(url: product!.externalUrl!);
    }
  }

  itemAddToCart(
      {required CartLineItem cartLineItem, Function? onSuccess}) async {
    await Cart.getInstance.addToCart(cartLineItem: cartLineItem);
    showStatusAlert(
      context,
      title: trans("Success"),
      subtitle: trans("Added to cart"),
      duration: 1,
      icon: Icons.add_shopping_cart,
    );
    updateState(CartQuantity.state);
    if (onSuccess != null) {
      onSuccess();
    }
  }

  addQuantityTapped({Function? onSuccess}) {
    if (product!.manageStock != null && product!.manageStock == true) {
      if (quantity >= product!.stockQuantity!) {
        showToastNotification(context!,
            title: trans("Maximum quantity reached"),
            description:
                "${trans("Sorry, only")} ${product!.stockQuantity} ${trans("left")}",
            style: ToastNotificationStyleType.INFO);
        return;
      }
    }
    if (quantity != 0) {
      quantity++;
      if (onSuccess != null) {
        onSuccess();
      }
      updateState(ProductQuantity.state, data: {
        "product_id": product?.id,
        "quantity": quantity
      });
    }
  }

  removeQuantityTapped({Function? onSuccess}) {
    if ((quantity - 1) >= 1) {
      quantity--;
      if (onSuccess != null) {
        onSuccess();
      }
      updateState(ProductQuantity.state, data: {
        "product_id": product?.id,
        "quantity": quantity
      });
    }
  }

  toggleWishList(
      {required Function onSuccess,
      required WishlistAction wishlistAction}) async {
    String subtitleMsg;
    if (wishlistAction == WishlistAction.remove) {
      await removeWishlistProduct(product: product);
      subtitleMsg = trans("This product has been removed from your wishlist");
    } else {
      await saveWishlistProduct(product: product);
      subtitleMsg = trans("This product has been added to your wishlist");
    }
    showStatusAlert(
      context,
      title: trans("Success"),
      subtitle: subtitleMsg,
      icon: Icons.favorite,
      duration: 1,
    );

    onSuccess();
  }

  ws_product_variation.ProductVariation? findProductVariation(
      {required Map<int, dynamic> tmpAttributeObj,
      required List<ws_product_variation.ProductVariation> productVariations}) {
    ws_product_variation.ProductVariation? tmpProductVariation;

    Map<String?, dynamic> tmpSelectedObj = {};
    for (var attributeObj in tmpAttributeObj.values) {
      tmpSelectedObj[attributeObj["name"]] = attributeObj["value"];
    }

    for (var productVariation in productVariations) {
      Map<String?, dynamic> tmpVariations = {};

      for (var attr in productVariation.attributes) {
        tmpVariations[attr.name] = attr.option;
      }

      if (tmpVariations.toString() == tmpSelectedObj.toString()) {
        tmpProductVariation = productVariation;
      }
    }

    return tmpProductVariation;
  }
}

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../data/db_helper.dart';

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  List<MenuItem> _items = [];
  bool _loading = true;
  String _category = 'All';
  int _todayCount = 0;

  final List<CartItem> _cart = [];
  String _orderType = 'Dine-in';
  String _paymentMethod = 'Cash';

  static const _categories = ['All', 'Lomi', 'Pancit', 'Drinks', 'Others'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await DBHelper.instance.getMenuItems(category: _category);
    final count = await DBHelper.instance.getTodayOrderCount();
    if (!mounted) return;
    setState(() {
      _items = items;
      _todayCount = count;
      _loading = false;
    });
  }

  Future<void> _changeCategory(String c) async {
    setState(() {
      _category = c;
      _loading = true;
    });
    await _load();
  }

  void _addToCart(MenuItem item) {
    final existing = _cart.where((c) => c.menuItemId == item.id).toList();
    setState(() {
      if (existing.isNotEmpty) {
        existing.first.qty++;
      } else {
        _cart.add(CartItem(menuItemId: item.id!, name: item.name, price: item.price));
      }
    });
  }

  void _changeQty(CartItem item, int delta) {
    setState(() {
      item.qty += delta;
      if (item.qty <= 0) _cart.remove(item);
    });
  }

  double get _total => _cart.fold(0, (sum, i) => sum + i.subtotal);

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to the order first.')),
      );
      return;
    }
    final total = _total;
    await DBHelper.instance.recordTransaction(
      orderType: _orderType,
      total: total,
      paymentMethod: _paymentMethod,
      items: List.of(_cart),
    );
    if (!mounted) return;
    await _showReceipt(total);
    setState(() => _cart.clear());
    _load();
  }

  Future<void> _showReceipt(double total) async {
    final items = List.of(_cart);
    final now = DateTime.now();
    final timestamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 40),
                const SizedBox(height: 10),
                Text("Filipee's Bistro",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: AppColors.accent)),
                const Text('Poblacion, Bauan, Batangas',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const Divider(height: 24),
                Text('$_orderType  ·  $_paymentMethod',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                Text(timestamp, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                const Divider(height: 24),
                ...items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(child: Text('${i.name} x${i.qty}', style: const TextStyle(fontSize: 13))),
                          Text(peso(i.subtotal),
                              style: const TextStyle(color: AppColors.accent, fontSize: 13)),
                        ],
                      ),
                    )),
                const Divider(height: 24),
                Text('TOTAL: ${peso(total)}',
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 6),
                const Text('Thank you for dining at Filipee\'s!',
                    style: TextStyle(color: AppColors.accent2, fontSize: 12)),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(text: 'Close', onPressed: () => Navigator.pop(context), height: 44),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final menuPanel = _MenuPanel(
      loading: _loading,
      items: _items,
      category: _category,
      categories: _categories,
      todayCount: _todayCount,
      onCategoryChanged: _changeCategory,
      onAdd: _addToCart,
    );
    final cartPanel = _CartPanel(
      cart: _cart,
      orderType: _orderType,
      paymentMethod: _paymentMethod,
      total: _total,
      onOrderType: (v) => setState(() => _orderType = v),
      onPayment: (v) => setState(() => _paymentMethod = v),
      onQtyChange: _changeQty,
      onCheckout: _checkout,
      onClear: () => setState(() => _cart.clear()),
    );

    if (wide) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: menuPanel),
            const SizedBox(width: 16),
            SizedBox(width: 360, child: cartPanel),
          ],
        ),
      );
    }

    // Compact layout: menu on top, floating "view cart" bottom sheet.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          child: menuPanel,
        ),
        if (_cart.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: GradientButton(
              text: '${_cart.length} item(s) · ${peso(_total)} — View Order',
              icon: Icons.shopping_cart,
              onPressed: () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  expand: false,
                  builder: (_, controller) => Container(
                    decoration: const BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: SingleChildScrollView(controller: controller, child: cartPanel),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MenuPanel extends StatelessWidget {
  final bool loading;
  final List<MenuItem> items;
  final String category;
  final List<String> categories;
  final int todayCount;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<MenuItem> onAdd;

  const _MenuPanel({
    required this.loading,
    required this.items,
    required this.category,
    required this.categories,
    required this.todayCount,
    required this.onCategoryChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = isWide(context) ? 3 : (isTablet(context) ? 3 : 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Point of Sale', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22)),
            const Spacer(),
            Text('Today: $todayCount orders',
                style: const TextStyle(color: AppColors.accent2, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories
                .map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: category == c,
                        onSelected: (_) => onCategoryChanged(c),
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.bgInput,
                        labelStyle: TextStyle(
                            color: category == c ? Colors.white : AppColors.textSecondary,
                            fontSize: 12),
                        side: BorderSide.none,
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : GridView.builder(
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final canOrder = item.isAvailable && item.stock > 0;
                    return _MenuPhotoTile(item: item, canOrder: canOrder, onAdd: onAdd);
                  },
                ),
        ),
      ],
    );
  }
}

/// Menu item card for the POS grid — shows the dish's actual photo
/// (same `menuItemImage` mapping used on the public landing page) instead
/// of a generic category icon, with the name / price / stock line laid
/// out under the photo like the landing page's menu cards.
class _MenuPhotoTile extends StatelessWidget {
  final MenuItem item;
  final bool canOrder;
  final ValueChanged<MenuItem> onAdd;
  const _MenuPhotoTile({required this.item, required this.canOrder, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  menuItemImage(item.name, item.category),
                  fit: BoxFit.cover,
                ),
                if (!canOrder)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    alignment: Alignment.center,
                    child: const Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                          color: AppColors.accentRed, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(peso(item.price),
                          style: const TextStyle(
                              color: AppColors.accent2, fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                    Text(
                      canOrder ? '${item.stock} left' : 'Unavailable',
                      style: TextStyle(
                          color: canOrder ? AppColors.textSecondary : AppColors.accentRed,
                          fontSize: 10.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canOrder ? () => onAdd(item) : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      disabledBackgroundColor: AppColors.bgInput,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: Text(canOrder ? '+ Add' : 'Unavailable'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  final List<CartItem> cart;
  final String orderType, paymentMethod;
  final double total;
  final ValueChanged<String> onOrderType, onPayment;
  final void Function(CartItem, int) onQtyChange;
  final VoidCallback onCheckout, onClear;

  const _CartPanel({
    required this.cart,
    required this.orderType,
    required this.paymentMethod,
    required this.total,
    required this.onOrderType,
    required this.onPayment,
    required this.onQtyChange,
    required this.onCheckout,
    required this.onClear,
  });

  static const _orderTypes = ['Walk-in', 'Dine-in', 'Take-out', 'Delivery'];
  static const _paymentMethods = ['Cash', 'GCash', 'Card'];

  @override
  Widget build(BuildContext context) {
    return BistroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Type', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _orderTypes
                .map((o) => ChoiceChip(
                      label: Text(o, style: const TextStyle(fontSize: 11)),
                      selected: orderType == o,
                      onSelected: (_) => onOrderType(o),
                      selectedColor: AppColors.accent,
                      backgroundColor: AppColors.bgInput,
                      labelStyle: TextStyle(color: orderType == o ? Colors.white : AppColors.textSecondary),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Current Order', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Cart is empty', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cart.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final item = cart[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            child: Text(item.name,
                                style: const TextStyle(fontSize: 12.5),
                                overflow: TextOverflow.ellipsis)),
                        _QtyButton(icon: Icons.remove, onTap: () => onQtyChange(item, -1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('${item.qty}',
                              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
                        ),
                        _QtyButton(icon: Icons.add, onTap: () => onQtyChange(item, 1), accent: true),
                        const SizedBox(width: 8),
                        Text(peso(item.subtotal),
                            style: const TextStyle(color: AppColors.accent2, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          const Divider(),
          Align(
            alignment: Alignment.centerRight,
            child: Text('TOTAL: ${peso(total)}',
                style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800, fontSize: 20)),
          ),
          const SizedBox(height: 10),
          const Text('Payment Method', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _paymentMethods
                .map((p) => ChoiceChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      selected: paymentMethod == p,
                      onSelected: (_) => onPayment(p),
                      selectedColor: AppColors.accent2,
                      backgroundColor: AppColors.bgInput,
                      labelStyle: TextStyle(color: paymentMethod == p ? Colors.white : AppColors.textSecondary),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          GradientButton(text: 'Process Payment & Print Receipt', icon: Icons.receipt_long, onPressed: onCheckout),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Clear Order'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;
  const _QtyButton({required this.icon, required this.onTap, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: accent ? AppColors.accent : AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: Colors.white),
      ),
    );
  }
}

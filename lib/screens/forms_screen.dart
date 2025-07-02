import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FormsScreen extends StatefulWidget {
  const FormsScreen({super.key});

  @override
  State<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends State<FormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // To update tab selection UI
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F9FB),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              elevation: 1.5,
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: List.generate(3, (index) {
                    final isSelected = _tabController.index == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(index),
                        child: Container(
                          margin: EdgeInsets.only(
                            left: index == 0 ? 0 : 4,
                            right: index == 2 ? 0 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Form ${index + 1}',
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF7ED957) : Colors.black,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    height: 3,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7ED957),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TabBarView(
                controller: _tabController,
                children: List.generate(3, (tabIndex) => _FormsTab()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      children: [
        const SizedBox(height: 24),
        _FormEditCard(title: 'Form 1'),
        const SizedBox(height: 16),
        _FormEditCard(title: 'Form 2'),
        const SizedBox(height: 16),
        _FormEditCard(title: 'Form 3'),
      ],
    );
  }
}

class _FormEditCard extends StatelessWidget {
  final String title;
  const _FormEditCard({required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1.5,
      color: Colors.white,
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: const Color(0xFF222222),
            fontFamily: 'Poppins',
          ),
        ),
        trailing: SvgPicture.asset(
          'assets/edit-icon.svg',
          height: 28,
          width: 28,
          color: const Color(0xFF7ED957),
        ),
        onTap: () {},
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_layout.dart';
import '../widgets/app_text.dart';
import '../widgets/custom_input.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Bem-vindo ao Garfada Log',
      description: 'O seu diário gastronômico pessoal para registrar as melhores (e piores) experiências.',
      icon: Icons.restaurant,
      color: AppColors.primary,
    ),
    OnboardingData(
      title: 'Registre Restaurantes',
      description: 'Adicione locais, categorize-os e mantenha um histórico de onde você já comeu.',
      icon: Icons.storefront,
      color: AppColors.secondary,
    ),
    OnboardingData(
      title: 'Avalie cada Prato',
      description: 'Dê notas para a comida e o custo-benefício. Nós calculamos se vale a pena voltar!',
      icon: Icons.star_rate,
      color: AppColors.warning,
    ),
    OnboardingData(
      title: 'Sua Localização',
      description: 'Informe sua cidade para que possamos sugerir restaurantes próximos a você.',
      icon: Icons.location_on,
      color: AppColors.success,
      isLocationPage: true,
    ),
  ];

  void _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstRun', false);
    await prefs.setString('userCity', _cityController.text.trim());
    await prefs.setString('userState', _stateController.text.trim());
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              return _buildPage(page);
            },
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => _buildIndicator(index == _currentPage),
                  ),
                ),
                const SizedBox(height: AppLayout.spaceXL),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppLayout.spaceXL),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _onFinish();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _pages[_currentPage].color,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppLayout.borderMedium,
                        ),
                      ),
                      child: AppText(
                        _currentPage == _pages.length - 1 ? 'Começar' : 'Próximo',
                        type: AppTextType.button,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _onFinish,
                  child: const AppText(
                    'Pular',
                    type: AppTextType.detail,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData page) {
    return SingleChildScrollView(
      padding: AppLayout.paddingL,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Container(
            padding: const EdgeInsets.all(35),
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 100, color: page.color),
          ),
          const SizedBox(height: AppLayout.spaceXL),
          AppText.title(
            page.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.spaceM),
          AppText.body(
            page.description,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
          if (page.isLocationPage) ...[
            const SizedBox(height: AppLayout.spaceXL),
            CustomInput(
              controller: _cityController,
              label: 'Cidade (ex: São Paulo)',
              icon: Icons.location_city,
            ),
            const SizedBox(height: AppLayout.spaceM),
            CustomInput(
              controller: _stateController,
              label: 'Estado (ex: SP)',
              icon: Icons.map,
            ),
            const SizedBox(height: 100), // Espaço para não ficar atrás do botão
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        color: isActive ? _pages[_currentPage].color : Colors.grey.shade300,
        borderRadius: AppLayout.borderLarge,
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isLocationPage;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.isLocationPage = false,
  });
}
